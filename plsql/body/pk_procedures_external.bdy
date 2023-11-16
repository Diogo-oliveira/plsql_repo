CREATE OR REPLACE PACKAGE BODY pk_procedures_external IS

    FUNCTION tf_procedures_ea
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_visit      IN visit.id_visit%TYPE,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_procedures_ea IS
    
        l_out_rec t_tbl_procedures_ea := t_tbl_procedures_ea(NULL);
    
        l_type_header   VARCHAR2(4000 CHAR);
        l_inner_header  VARCHAR2(2000 CHAR);
        l_inner_header1 VARCHAR2(2000 CHAR);
        l_inner_header2 VARCHAR2(2000 CHAR);
        l_sql_inner1    VARCHAR2(4000 CHAR);
        l_sql_inner2    VARCHAR2(4000 CHAR);
        l_sql_footer1   VARCHAR2(1000 CHAR);
        l_sql_footer2   VARCHAR2(1000 CHAR);
        l_sql_stmt      CLOB;
        l_curid         INTEGER;
        l_ret           INTEGER;
    
        l_cursor pk_types.cursor_type;
    
        l_db_object_name VARCHAR2(30 CHAR) := 'TF_PROCEDURES_EA';
    
    BEGIN
    
        l_curid := dbms_sql.open_cursor;
    
        l_type_header := 'SELECT t_procedures_ea(id_interv_prescription, ' || --
                         '                       id_interv_presc_det, ' || --
                         '                       id_interv_presc_plan, ' || --
                         '                       id_intervention, ' || --
                         '                       flg_status_intervention, ' || --
                         '                       flg_status_req, ' || --
                         '                       flg_status_det, ' || --
                         '                       flg_status_plan, ' || --
                         '                       flg_time, ' || --
                         '                       flg_interv_type, ' || --
                         '                       dt_begin_req, ' || --
                         '                       dt_begin_det, ' || --
                         '                       INTERVAL, ' || --
                         '                       dt_interv_prescription, ' || --
                         '                       dt_plan, ' || --
                         '                       id_professional, ' || --
                         '                       flg_notes, ' || --
                         '                       status_str, ' || --
                         '                       status_msg, ' || --
                         '                       status_icon, ' || --
                         '                       status_flg, ' || --
                         '                       id_prof_order, ' || --
                         '                       code_intervention_alias, ' || --
                         '                       flg_prty, ' || --
                         '                       num_take, ' || --
                         '                       id_episode_origin, ' || --
                         '                       id_visit, ' || --
                         '                       id_episode, ' || --
                         '                       id_patient, ' || --
                         '                       flg_referral, ' || --
                         '                       dt_interv_presc_det, ' || --
                         '                       dt_dg_last_update, ' || --
                         '                       dt_order, ' || --
                         '                       flg_laterality, ' || --
                         '                       flg_clinical_purpose, ' || --
                         '                       flg_prn, ' || --
                         '                       flg_doc, ' || --
                         '                       id_interv_codification, ' || --
                         '                       id_order_recurrence, ' || --
                         '                       id_task_dependency, ' || --
                         '                       flg_req_origin_module, ' || --
                         '                       notes, ' || --
                         '                       notes_cancel, ' || --
                         '                       id_clinical_purpose, ' || --
                         '                       clinical_purpose_notes, ' || --
                         '                       id_epis_type, ' || --
                         '                       id_epis) ' || --
                         '  FROM ( ';
    
        l_inner_header := 'SELECT pea.id_interv_prescription, ' || --
                          '       pea.id_interv_presc_det, ' || --
                          '       pea.id_interv_presc_plan, ' || --
                          '       pea.id_intervention, ' || --
                          '       pea.flg_status_intervention, ' || --
                          '       pea.flg_status_req, ' || --
                          '       pea.flg_status_det, ' || --
                          '       pea.flg_status_plan, ' || --
                          '       pea.flg_time, ' || --
                          '       pea.flg_interv_type, ' || --
                          '       pea.dt_begin_req, ' || --
                          '       pea.dt_begin_det, ' || --
                          '       pea.interval, ' || --
                          '       pea.dt_interv_prescription, ' || --
                          '       pea.dt_plan, ' || --
                          '       pea.id_professional, ' || --
                          '       pea.flg_notes, ' || --
                          '       pea.status_str, ' || --
                          '       pea.status_msg, ' || --
                          '       pea.status_icon, ' || --
                          '       pea.status_flg, ' || --
                          '       pea.id_prof_order, ' || --
                          '       pea.code_intervention_alias, ' || --
                          '       pea.flg_prty, ' || --
                          '       pea.num_take, ' || --
                          '       pea.id_episode_origin, ' || --
                          '       pea.id_visit, ' || --
                          '       pea.id_episode, ' || --
                          '       pea.id_patient, ' || --
                          '       pea.flg_referral, ' || --
                          '       pea.dt_interv_presc_det, ' || --
                          '       pea.dt_dg_last_update, ' || --
                          '       pea.dt_order, ' || --
                          '       pea.flg_laterality, ' || --
                          '       pea.flg_clinical_purpose, ' || --
                          '       pea.flg_prn, ' || --
                          '       pea.flg_doc, ' || --
                          '       pea.id_interv_codification, ' || --
                          '       pea.id_order_recurrence, ' || --
                          '       pea.id_task_dependency, ' || --
                          '       pea.flg_req_origin_module, ' || --
                          '       pea.notes, ' || --
                          '       pea.notes_cancel, ' || --
                          '       pea.id_clinical_purpose, ' || --
                          '       pea.clinical_purpose_notes, ' || --
                          '       e.id_epis_type, ' || --
                          '       e.id_episode id_epis ';
    
        l_inner_header1 := l_inner_header || ' FROM procedures_ea pea ' || --
                           ' LEFT JOIN interv_presc_plan ipd ON pea.id_interv_presc_det = ipd.id_interv_presc_det ' || --
                           ' JOIN episode e ON pea.id_episode = e.id_episode ' || --
                           ' WHERE 1 = 1 ';
    
        --i_patient
        IF i_patient IS NOT NULL
        THEN
            l_sql_inner1 := l_sql_inner1 || ' AND pea.id_patient = :i_patient ';
        END IF;
    
        --i_visit
        IF i_visit IS NOT NULL
        THEN
            l_sql_inner1 := l_sql_inner1 ||
                            ' AND (pea.id_visit = :i_visit OR pk_episode.get_id_visit(pea.id_episode_origin) = :i_visit)';
        END IF;
    
        --i_episode
        IF i_episode IS NOT NULL
        THEN
            l_sql_inner1 := l_sql_inner1 ||
                            ' AND (pea.id_episode = :i_episode OR (pea.flg_time IN (''A'', ''H'') AND (EXISTS (SELECT 1 FROM interv_presc_plan a where a.id_interv_presc_det = pea.id_interv_presc_det and a.id_episode_write = :i_episode))))';
        END IF;
    
        IF i_cancelled = pk_alert_constant.g_no
        THEN
            l_sql_inner1 := l_sql_inner1 || ' AND pea.flg_status_det NOT IN (''' ||
                            pk_procedures_constant.g_interv_cancel || ''', 
            ''' || pk_procedures_constant.g_interv_not_ordered || ''')';
        END IF;
    
        l_sql_inner1 := l_sql_inner1 || ' AND pea.flg_status_det != ''' || pk_procedures_constant.g_interv_draft || '''';
    
        IF i_crit_type IS NOT NULL
           AND i_crit_type = 'A'
        THEN
            l_sql_inner1 := l_sql_inner1 || ' AND ((pea.dt_begin_det >= coalesce(:i_start_date, pea.dt_begin_det) ' || --
                            ' AND pea.dt_begin_det <= coalesce(:i_end_date, pea.dt_begin_det)) ' || --
                            ' OR (pea.dt_begin_det IS NULL AND pea.flg_status_det = ''' || --
                            pk_alert_constant.g_interv_type_sos || ''')) ';
        ELSIF i_crit_type IS NOT NULL
              AND i_crit_type = 'E'
        THEN
            l_sql_inner1 := l_sql_inner1 || ' AND ipd.dt_take_tstz >= nvl(:i_start_date, ipd.dt_take_tstz) ' || --
                            ' AND ipd.dt_take_tstz <= nvl(:i_end_date, ipd.dt_take_tstz)';
        END IF;
    
        l_sql_footer1 := ' UNION ALL ';
    
        l_inner_header2 := l_inner_header || ' FROM procedures_ea pea ' || --
                           ' LEFT JOIN interv_presc_plan ipd ON pea.id_interv_presc_det = ipd.id_interv_presc_det ' || --
                           ' JOIN episode e ON pea.id_episode_origin = e.id_episode ' || --
                           ' WHERE 1 = 1 ';
    
        --i_patient
        IF i_patient IS NOT NULL
        THEN
            l_sql_inner2 := l_sql_inner2 || ' AND pea.id_patient = :i_patient ';
        END IF;
    
        --i_visit
        IF i_visit IS NOT NULL
        THEN
            l_sql_inner2 := l_sql_inner2 ||
                            ' AND  (pea.id_visit = :i_visit OR pk_episode.get_id_visit(pea.id_episode_origin) = :i_visit)';
        END IF;
    
        --i_episode
        IF i_episode IS NOT NULL
        THEN
            l_sql_inner2 := l_sql_inner2 ||
                            ' AND (pea.id_episode_origin = :i_episode OR (pea.flg_time IN (''A'', ''H'') AND (EXISTS (SELECT 1 FROM interv_presc_plan a where a.id_interv_presc_det = pea.id_interv_presc_det and a.id_episode_write = :i_episode))))';
        END IF;
    
        IF i_cancelled = pk_alert_constant.g_no
        THEN
            l_sql_inner2 := l_sql_inner2 || ' AND pea.flg_status_det NOT IN (''' ||
                            pk_procedures_constant.g_interv_cancel || ''', 
            ''' || pk_procedures_constant.g_interv_not_ordered || ''')';
        END IF;
    
        l_sql_inner2 := l_sql_inner2 || ' AND pea.flg_status_det != ''' || pk_procedures_constant.g_interv_draft || '''';
    
        IF i_crit_type IS NOT NULL
           AND i_crit_type = 'A'
        THEN
            l_sql_inner2 := l_sql_inner2 || ' AND ((pea.dt_begin_det >= coalesce(:i_start_date, pea.dt_begin_det) ' || --
                            ' AND pea.dt_begin_det <= coalesce(:i_end_date, pea.dt_begin_det)) ' || --
                            ' OR (pea.dt_begin_det IS NULL AND pea.flg_status_det = ''' || --
                            pk_alert_constant.g_interv_type_sos || ''')) ';
        ELSIF i_crit_type IS NOT NULL
              AND i_crit_type = 'E'
        THEN
            l_sql_inner2 := l_sql_inner2 || ' AND ipd.dt_take_tstz >= nvl(:i_start_date, ipd.dt_take_tstz) ' || --
                            ' AND ipd.dt_take_tstz <= nvl(:i_end_date, ipd.dt_take_tstz)';
        END IF;
    
        l_sql_footer2 := ' )';
    
        l_sql_stmt := to_clob(l_type_header || l_inner_header1 || l_sql_inner1 || l_sql_footer1 || l_inner_header2 ||
                              l_sql_inner2 || l_sql_footer2);
    
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_db_object_name, text => l_sql_stmt);
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        IF i_patient IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_patient', i_patient);
        END IF;
    
        IF i_visit IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_visit', i_visit);
        END IF;
    
        IF i_episode IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_episode', i_episode);
        END IF;
    
        IF i_crit_type IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_start_date', i_start_date);
            dbms_sql.bind_variable(l_curid, 'i_end_date', i_end_date);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_out_rec;
    
        RETURN l_out_rec;
    
    END tf_procedures_ea;

    PROCEDURE dashboards_______________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_last_execution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_status       IN interv_presc_det.flg_status%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_dt_last_exec TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_error := 'SELECT - DATE';
        SELECT MAX(ipp.dt_take_tstz)
          INTO l_dt_last_exec
          FROM interv_presc_det ipd
         INNER JOIN interv_presc_plan ipp
            ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
         WHERE ipd.id_interv_presc_det = i_interv_presc_det
           AND ipd.flg_status = i_flg_status;
    
        RETURN l_dt_last_exec;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_procedure_last_execution;

    PROCEDURE reports___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_listview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_scope            IN NUMBER,
        i_flg_scope        IN VARCHAR2,
        i_start_date       IN VARCHAR2,
        i_end_date         IN VARCHAR2,
        i_cancelled        IN VARCHAR2,
        i_crit_type        IN VARCHAR2,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient   patient.id_patient%TYPE;
        l_cancelled VARCHAR2(1);
        l_visit     visit.id_visit%TYPE;
        l_episode   episode.id_episode%TYPE;
        l_epis_type episode.id_epis_type%TYPE;
    
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_cancelled IS NULL
        THEN
            l_cancelled := pk_alert_constant.g_yes;
        ELSE
            l_cancelled := i_cancelled;
        
        END IF;
    
        g_error      := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_start_date';
        l_start_date := CASE
                            WHEN i_start_date IS NOT NULL THEN
                             pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_start_date)
                            ELSE
                             NULL
                        END;
    
        g_error    := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_end_date';
        l_end_date := CASE
                          WHEN i_end_date IS NOT NULL THEN
                           pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_end_date)
                          ELSE
                           NULL
                      END;
    
        IF i_scope IS NOT NULL
        THEN
            g_error := 'CALL PK_TOUCH_OPTION.GET_SCOPE_VARS';
            IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_scope      => i_scope,
                                                  i_scope_type => i_flg_scope,
                                                  o_patient    => l_patient,
                                                  o_visit      => l_visit,
                                                  o_episode    => l_episode,
                                                  o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        BEGIN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = l_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_type := NULL;
        END;
    
        IF i_interv_presc_det.count IS NULL
           OR i_interv_presc_det.count = 0
        THEN
            OPEN o_list FOR
                SELECT /*+opt_estimate(table pea rows=1)*/
                DISTINCT pea.id_interv_presc_det unique_id,
                         pea.id_intervention,
                         t_ti_log.get_desc_with_origin(i_lang,
                                                       i_prof,
                                                       pk_procedures_api_db.get_alias_translation(i_lang,
                                                                                                  i_prof,
                                                                                                  'INTERVENTION.CODE_INTERVENTION.' ||
                                                                                                  pea.id_intervention,
                                                                                                  NULL),
                                                       l_epis_type,
                                                       pea.flg_status_det,
                                                       pea.id_interv_presc_det,
                                                       pk_procedures_constant.g_interv_type_req) desc_procedure,
                         pk_alert_constant.g_task_procedures flg_type,
                         pea.id_prof_order id_prof_req,
                         pea.flg_status_det flg_status,
                         pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det, i_lang) desc_status,
                         pea.flg_referral,
                         pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_LATERALITY', pea.flg_laterality, i_lang) desc_laterality,
                         decode(ipd.id_presc_plan_task, NULL, pk_procedures_constant.g_no, pk_procedures_constant.g_yes) flg_assoc_drug,
                         (SELECT ic.standard_code
                            FROM interv_codification ic
                           WHERE ic.id_interv_codification = pea.id_interv_codification) standard_code
                  FROM TABLE(tf_procedures_ea(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_patient    => l_patient,
                                              i_episode    => l_episode,
                                              i_visit      => l_visit,
                                              i_cancelled  => l_cancelled,
                                              i_crit_type  => i_crit_type,
                                              i_start_date => l_start_date,
                                              i_end_date   => l_end_date)) pea,
                       interv_presc_det ipd
                 WHERE pea.id_interv_presc_det = ipd.id_interv_presc_det;
        ELSE
            OPEN o_list FOR
                SELECT pea.id_interv_presc_det unique_id,
                       pea.id_intervention,
                       pk_procedures_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  'INTERVENTION.CODE_INTERVENTION.' ||
                                                                  pea.id_intervention,
                                                                  NULL) desc_procedure,
                       pk_alert_constant.g_task_procedures flg_type,
                       pea.id_prof_order id_prof_req,
                       pea.flg_status_det flg_status,
                       pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det, i_lang) desc_status,
                       pea.flg_referral,
                       pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_LATERALITY', pea.flg_laterality, i_lang) desc_laterality,
                       decode(ipd.id_presc_plan_task, NULL, pk_procedures_constant.g_no, pk_procedures_constant.g_yes) flg_assoc_drug,
                       (SELECT ic.standard_code
                          FROM interv_codification ic
                         WHERE ic.id_interv_codification = pea.id_interv_codification) standard_code
                  FROM procedures_ea pea, interv_presc_det ipd
                 WHERE pea.id_interv_presc_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                    *
                                                     FROM TABLE(i_interv_presc_det) t)
                   AND pea.id_interv_presc_det = ipd.id_interv_presc_det;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_listview;

    FUNCTION get_procedure_orders
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_order     OUT pk_types.cursor_type,
        o_interv_execution OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('PROCEDURES_T096',
                                                        'PROCEDURES_T058',
                                                        'PROCEDURES_T081',
                                                        'PROCEDURES_T104',
                                                        'PROCEDURES_T122',
                                                        'PROCEDURES_T082',
                                                        'PROCEDURES_T091',
                                                        'PROCEDURES_T011',
                                                        'PROCEDURES_T143',
                                                        'PROCEDURES_T023',
                                                        'PROCEDURES_T025',
                                                        'PROCEDURES_T130',
                                                        'PROCEDURES_T131',
                                                        'PROCEDURES_T144',
                                                        'SUPPLIES_T076',
                                                        'PROCEDURES_T139',
                                                        'PROCEDURES_T092',
                                                        'PROCEDURES_T090',
                                                        'PROCEDURES_T123',
                                                        'PROCEDURES_T100',
                                                        'PROCEDURES_T138',
                                                        'PROCEDURES_T077',
                                                        'PROCEDURES_T010',
                                                        'PROCEDURES_T038',
                                                        'PROCEDURES_T133',
                                                        'PROCEDURES_T134',
                                                        'PROCEDURES_T135',
                                                        'PROCEDURES_T136',
                                                        'PROCEDURES_T137',
                                                        'PROCEDURES_T164',
                                                        'PROCEDURES_T029',
                                                        'PROCEDURES_T024',
                                                        'PROCEDURES_T036',
                                                        'PROCEDURES_T096',
                                                        'PROCEDURES_T151',
                                                        'PROCEDURES_T148',
                                                        'PROCEDURES_T149',
                                                        'PROCEDURES_T150',
                                                        'PROCEDURES_T152',
                                                        'PROCEDURES_T145');
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := '<b>' || pk_message.get_message(i_lang, va_code_messages(i)) ||
                                                     '</b> ';
        END LOOP;
    
        g_error := 'OPEN O_INTERV_ORDER';
        OPEN o_interv_order FOR
            SELECT ipd.id_interv_presc_det,
                   pk_procedures_utils.get_alias_translation(i_lang,
                                                             i_prof,
                                                             'INTERVENTION.CODE_INTERVENTION.' || ipd.id_intervention,
                                                             NULL) desc_procedure,
                   ip.id_professional id_prof_req,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ip.id_professional) prof_req,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ip.id_professional,
                                                    ip.dt_interv_prescription_tstz,
                                                    ip.id_episode) prof_spec_req,
                   decode(ipd.flg_laterality,
                          NULL,
                          NULL,
                          pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_LATERALITY', ipd.flg_laterality, i_lang)) laterality,
                   decode(ipd.dt_order_tstz,
                          NULL,
                          NULL,
                          pk_date_utils.date_char_tsz(i_lang, ipd.dt_order_tstz, i_prof.institution, i_prof.software)) dt_req,
                   pk_date_utils.date_send_tsz(i_lang, ip.dt_interv_prescription_tstz, i_prof) dt_ord
              FROM interv_presc_det ipd, interv_prescription ip
             WHERE ipd.id_interv_presc_det = i_interv_presc_det
               AND ipd.id_interv_prescription = ip.id_interv_prescription;
    
        g_error := 'OPEN O_INTERV_EXECUTION';
        OPEN o_interv_execution FOR
            SELECT ipp.id_interv_presc_det,
                   ipp.id_interv_presc_plan,
                   decode(ipp.id_prof_performed,
                          NULL,
                          NULL,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, ipp.id_prof_performed)) prof_perform,
                   decode(ipp.id_prof_performed,
                          NULL,
                          NULL,
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           ipp.id_prof_take,
                                                           ipp.dt_take_tstz,
                                                           ipp.id_episode_write)) prof_spec_perform,
                   decode(ipp.start_time,
                          NULL,
                          NULL,
                          pk_date_utils.date_char_tsz(i_lang, ipp.start_time, i_prof.institution, i_prof.software)) dt_perform,
                   pk_date_utils.date_send_tsz(i_lang, ipp.dt_plan_tstz, i_prof) dt_ord
              FROM interv_presc_plan ipp
             WHERE ipp.id_interv_presc_det = i_interv_presc_det
               AND ipp.flg_status = pk_procedures_constant.g_interv_plan_executed
             ORDER BY dt_ord DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_ORDERS',
                                              o_error);
            pk_types.open_my_cursor(o_interv_order);
            pk_types.open_my_cursor(o_interv_execution);
            RETURN FALSE;
    END get_procedure_orders;

    FUNCTION get_procedure_detail
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report                IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_order              t_tbl_procedures_detail;
        l_interv_clinical_questions t_tbl_procedures_cq;
        l_interv_execution          t_tbl_procedures_execution;
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_DETAIL';
        IF NOT pk_procedures_core.get_procedure_detail(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_episode                   => i_episode,
                                                       i_interv_presc_det          => i_interv_presc_det,
                                                       i_flg_report                => i_flg_report,
                                                       o_interv_order              => l_interv_order,
                                                       o_interv_co_sign            => o_interv_co_sign,
                                                       o_interv_clinical_questions => l_interv_clinical_questions,
                                                       o_interv_execution          => l_interv_execution,
                                                       o_interv_execution_images   => o_interv_execution_images,
                                                       o_interv_doc                => o_interv_doc,
                                                       o_interv_review             => o_interv_review,
                                                       o_error                     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_INTERV_ORDER';
        OPEN o_interv_order FOR
            SELECT t.id_interv_presc_det,
                   t.registry,
                   pea.flg_status_det flg_status,
                   pea.id_intervention,
                   t.desc_procedure,
                   t.num_order,
                   t.diagnosis_notes,
                   t.desc_diagnosis,
                   t.clinical_purpose,
                   t.laterality,
                   t.priority,
                   t.desc_status,
                   t.title_order_set,
                   t.task_depend,
                   t.desc_time,
                   t.desc_time_limit,
                   t.order_recurrence,
                   t.prn,
                   t.notes_prn,
                   t.perform_location,
                   '<b>' || pk_message.get_message(i_lang, 'PROCEDURES_T077') || '</b>' ||
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pea.id_professional) prof_req,
                   t.dt_req,
                   t.desc_supplies,
                   t.lab_result,
                   t.weight,
                   t.not_order_reason,
                   t.notes,
                   t.prof_order,
                   t.dt_order,
                   t.order_type,
                   t.financial_entity,
                   t.health_plan,
                   t.insurance_number,
                   t.exemption,
                   t.cancel_reason,
                   t.cancel_notes,
                   t.cancel_prof_order,
                   t.cancel_dt_order,
                   t.cancel_order_type,
                   t.dt_ord
              FROM procedures_ea pea, TABLE(l_interv_order) t
             WHERE pea.id_interv_presc_det = i_interv_presc_det
               AND pea.id_interv_presc_det = t.id_interv_presc_det;
    
        g_error := 'CALL pk_supplies_external_api_db.get_supplies_request';
        IF NOT pk_supplies_external_api_db.get_supplies_request(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_id_context  => i_interv_presc_det,
                                                                i_flg_context => 'P',
                                                                o_supplies    => o_interv_supplies,
                                                                o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_INTERV_CLINICAL_QUESTIONS';
        OPEN o_interv_clinical_questions FOR
            SELECT t.id_interv_presc_det    id_interv_presc_det,
                   t.flg_time               flg_time,
                   t.id_content             id_content,
                   t.desc_clinical_question desc_clinical_question
              FROM TABLE(l_interv_clinical_questions) t;
    
        g_error := 'OPEN O_INTERV_EXECUTION';
        OPEN o_interv_execution FOR
            SELECT t.id_interv_presc_plan id_interv_presc_plan,
                   t.registry registry,
                   ipp.flg_status flg_status,
                   t.desc_procedure desc_procedure,
                   pk_sysdomain.get_domain('INTERV_PRESC_PLAN.FLG_STATUS', ipp.flg_status, i_lang) desc_status,
                   REPLACE(t.registry,
                           pk_message.get_message(i_lang, 'COMMON_M107'),
                           '<b>' || pk_message.get_message(i_lang, 'PROCEDURES_T151') || '</b>') perform,
                   t.prof_perform prof_perform,
                   t.start_time start_time,
                   t.end_time end_time,
                   t.next_perform_date next_perform_date,
                   t.desc_modifiers desc_modifiers,
                   t.desc_supplies desc_supplies,
                   t.desc_time_out desc_time_out,
                   t.desc_perform desc_perform,
                   t.cancel_reason cancel_reason,
                   t.cancel_notes cancel_notes,
                   t.dt_ord dt_ord
              FROM interv_presc_plan ipp, TABLE(l_interv_execution) t
             WHERE ipp.id_interv_presc_plan = t.id_interv_presc_plan;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_interv_order);
            pk_types.open_my_cursor(o_interv_supplies);
            pk_types.open_my_cursor(o_interv_co_sign);
            pk_types.open_my_cursor(o_interv_execution);
            pk_types.open_my_cursor(o_interv_execution_images);
            pk_types.open_my_cursor(o_interv_doc);
            pk_types.open_my_cursor(o_interv_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_procedure_detail;

    FUNCTION get_procedure_detail_history
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report                IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_order              t_tbl_procedures_detail;
        l_interv_clinical_questions t_tbl_procedures_cq;
        l_interv_execution          t_tbl_procedures_execution;
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_DETAIL_HISTORY';
        IF NOT pk_procedures_core.get_procedure_detail_history(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_episode                   => i_episode,
                                                               i_interv_presc_det          => i_interv_presc_det,
                                                               i_flg_report                => i_flg_report,
                                                               o_interv_order              => l_interv_order,
                                                               o_interv_co_sign            => o_interv_co_sign,
                                                               o_interv_clinical_questions => l_interv_clinical_questions,
                                                               o_interv_execution          => l_interv_execution,
                                                               o_interv_execution_images   => o_interv_execution_images,
                                                               o_interv_doc                => o_interv_doc,
                                                               o_interv_review             => o_interv_review,
                                                               o_error                     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_INTERV_ORDER';
        OPEN o_interv_order FOR
            SELECT t.id_interv_presc_det,
                   t.registry,
                   pea.flg_status_det flg_status,
                   pea.id_intervention,
                   t.desc_procedure,
                   t.num_order,
                   t.diagnosis_notes,
                   t.desc_diagnosis,
                   t.clinical_purpose,
                   t.laterality,
                   t.priority,
                   t.desc_status,
                   t.title_order_set,
                   t.task_depend,
                   t.desc_time,
                   t.desc_time_limit,
                   t.order_recurrence,
                   t.prn,
                   t.notes_prn,
                   t.perform_location,
                   '<b>' || pk_message.get_message(i_lang, 'PROCEDURES_T077') || '</b>' ||
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pea.id_professional) prof_req,
                   t.dt_req,
                   t.desc_supplies,
                   t.lab_result,
                   t.weight,
                   t.not_order_reason,
                   t.notes,
                   t.prof_order,
                   t.dt_order,
                   t.order_type,
                   t.financial_entity,
                   t.health_plan,
                   t.insurance_number,
                   t.exemption,
                   t.cancel_reason,
                   t.cancel_notes,
                   t.cancel_prof_order,
                   t.cancel_dt_order,
                   t.cancel_order_type,
                   t.dt_ord
              FROM procedures_ea pea, TABLE(l_interv_order) t
             WHERE pea.id_interv_presc_det = i_interv_presc_det
               AND pea.id_interv_presc_det = t.id_interv_presc_det;
    
        g_error := 'CALL pk_supplies_external_api_db.get_supplies_request';
        IF NOT pk_supplies_external_api_db.get_supplies_request(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_id_context  => i_interv_presc_det,
                                                                i_flg_context => 'P',
                                                                o_supplies    => o_interv_supplies,
                                                                o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_INTERV_CLINICAL_QUESTIONS';
        OPEN o_interv_clinical_questions FOR
            SELECT t.id_interv_presc_det    id_interv_presc_det,
                   t.flg_time               flg_time,
                   t.id_content             id_content,
                   t.desc_clinical_question desc_clinical_question
              FROM TABLE(l_interv_clinical_questions) t
             WHERE t.id_content IS NOT NULL;
    
        g_error := 'OPEN O_INTERV_EXECUTION';
        OPEN o_interv_execution FOR
            SELECT t.id_interv_presc_plan id_interv_presc_plan,
                   t.registry registry,
                   ipp.flg_status flg_status,
                   t.desc_procedure desc_procedure,
                   pk_sysdomain.get_domain('INTERV_PRESC_PLAN.FLG_STATUS', ipp.flg_status, i_lang) desc_status,
                   REPLACE(t.registry,
                           pk_message.get_message(i_lang, 'COMMON_M107'),
                           '<b>' || pk_message.get_message(i_lang, 'PROCEDURES_T151') || '</b>') perform,
                   t.prof_perform prof_perform,
                   t.start_time start_time,
                   t.end_time end_time,
                   t.next_perform_date next_perform_date,
                   t.desc_modifiers desc_modifiers,
                   t.desc_supplies desc_supplies,
                   t.desc_time_out desc_time_out,
                   t.desc_perform desc_perform,
                   t.cancel_reason cancel_reason,
                   t.cancel_notes cancel_notes,
                   t.dt_ord dt_ord
              FROM interv_presc_plan ipp, TABLE(l_interv_execution) t
             WHERE ipp.id_interv_presc_plan = t.id_interv_presc_plan;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_DETAIL_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_interv_order);
            pk_types.open_my_cursor(o_interv_supplies);
            pk_types.open_my_cursor(o_interv_co_sign);
            pk_types.open_my_cursor(o_interv_execution);
            pk_types.open_my_cursor(o_interv_execution_images);
            pk_types.open_my_cursor(o_interv_doc);
            pk_types.open_my_cursor(o_interv_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_procedure_detail_history;

    PROCEDURE co_sign___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
        l_desc CLOB;
    
    BEGIN
        IF i_interv_presc_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        SELECT pk_procedures_utils.get_alias_translation(i_lang,
                                                         i_prof,
                                                         'INTERVENTION.CODE_INTERVENTION.' || ipd.id_intervention,
                                                         NULL) description
          INTO l_desc
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_presc_det = i_interv_presc_det;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_description;

    FUNCTION get_procedure_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
        l_instructions CLOB;
    
    BEGIN
    
        IF i_interv_presc_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        SELECT nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang, i_prof, ipd.id_order_recurrence),
                   pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0'))
          INTO l_instructions
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_presc_det = i_interv_presc_det;
    
        RETURN l_instructions;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_instructions;

    FUNCTION get_procedure_action_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_action           IN co_sign.id_action%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2 IS
    
        l_msg_cosign_action_order  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M146');
        l_msg_cosign_action_cancel sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M147');
        l_msg_action               sys_message.desc_message%TYPE;
    
    BEGIN
    
        SELECT CASE
                   WHEN ipd.id_co_sign_order = i_co_sign_hist THEN
                    l_msg_cosign_action_order
                   WHEN ipd.id_co_sign_cancel = i_co_sign_hist THEN
                    l_msg_cosign_action_cancel
                   ELSE
                    NULL
               END
          INTO l_msg_action
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_presc_det = i_interv_presc_det;
    
        RETURN l_msg_action;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_action_desc;

    FUNCTION get_procedure_date_to_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_interv_presc_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        SELECT nvl(ipp.dt_plan_tstz, pea.dt_begin_req)
          INTO l_date
          FROM procedures_ea pea, interv_presc_plan ipp
         WHERE pea.id_interv_presc_det = i_interv_presc_det
           AND pea.id_interv_presc_det = ipp.id_interv_presc_det(+);
    
        RETURN l_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_date_to_order;

    PROCEDURE cdr_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION check_procedure_cdr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_intervention     IN intervention.id_intervention%TYPE,
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_interv_presc_det OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET INTERV RECORDS';
        SELECT pea.id_interv_presc_det
          BULK COLLECT
          INTO o_interv_presc_det
          FROM procedures_ea pea, episode e
         WHERE pea.id_intervention = i_intervention
           AND pea.id_patient = i_patient
           AND pea.id_episode = e.id_episode
           AND (i_date IS NULL OR pea.dt_begin_det > i_date OR (pea.dt_begin_det IS NULL AND e.dt_begin_tstz > i_date));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'CHECK_PROCEDURE_CDR',
                                                     o_error);
    END check_procedure_cdr;

    PROCEDURE referral___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION update_procedure_laterality
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_laterality   IN interv_presc_det.flg_laterality%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'UPDATE INTERV_PRESC_DET';
        ts_interv_presc_det.upd(id_interv_presc_det_in => i_interv_presc_det,
                                flg_laterality_in      => i_flg_laterality,
                                flg_laterality_nin     => FALSE,
                                id_prof_last_update_in => i_prof.id,
                                dt_last_update_tstz_in => g_sysdate_tstz,
                                rows_out               => l_rows_out);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'INTERV_PRESC_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_PROCEDURE_LATERALITY',
                                              o_error);
            RETURN FALSE;
    END update_procedure_laterality;

    FUNCTION update_procedure_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_exec_institution IN interv_presc_det.id_exec_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'UPDATE INTERV_PRESC_DET';
        ts_interv_presc_det.upd(id_interv_presc_det_in  => i_interv_presc_det,
                                id_exec_institution_in  => i_exec_institution,
                                id_exec_institution_nin => FALSE,
                                id_prof_last_update_in  => i_prof.id,
                                dt_last_update_tstz_in  => g_sysdate_tstz,
                                rows_out                => l_rows_out);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'INTERV_PRESC_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_PROCEDURE_INSTITUTION',
                                              o_error);
            RETURN FALSE;
    END update_procedure_institution;

    FUNCTION update_procedure_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_referral     IN interv_presc_det.flg_referral%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'UPDATE INTERV_PRESC_DET';
        ts_interv_presc_det.upd(id_interv_presc_det_in => i_interv_presc_det,
                                flg_referral_in        => i_flg_referral,
                                flg_referral_nin       => TRUE,
                                id_prof_last_update_in => i_prof.id,
                                dt_last_update_tstz_in => g_sysdate_tstz,
                                rows_out               => l_rows_out);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'INTERV_PRESC_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_PROCEDURE_REFERRAL',
                                              o_error);
            RETURN FALSE;
    END update_procedure_referral;

    FUNCTION get_procedure_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_procedures_external.t_cur_procedure,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit visit.id_visit%TYPE;
    
    BEGIN
    
        l_visit := pk_visit.get_visit(i_episode, o_error);
    
        OPEN o_list FOR
            SELECT pea.id_interv_presc_det,
                   pea.id_intervention,
                   pk_procedures_utils.get_alias_translation(i_lang,
                                                             i_prof,
                                                             'INTERVENTION.CODE_INTERVENTION.' || pea.id_intervention,
                                                             NULL) desc_procedure,
                   pk_date_utils.date_char_tsz(i_lang, pea.dt_interv_prescription, i_prof.institution, i_prof.software) dt_req
              FROM procedures_ea pea, episode e
             WHERE e.id_visit = l_visit
               AND e.id_episode = pea.id_episode
               AND pea.flg_status_det = pk_procedures_constant.g_interv_finished
            UNION ALL
            SELECT pea.id_interv_presc_det,
                   pea.id_intervention,
                   pk_procedures_utils.get_alias_translation(i_lang,
                                                             i_prof,
                                                             'INTERVENTION.CODE_INTERVENTION.' || pea.id_intervention,
                                                             NULL) desc_procedure,
                   pk_date_utils.date_char_tsz(i_lang, pea.dt_interv_prescription, i_prof.institution, i_prof.software) dt_req
              FROM procedures_ea pea, episode e
             WHERE e.id_visit = l_visit
               AND e.id_episode = pea.id_episode_origin
               AND pea.flg_status_det = pk_procedures_constant.g_interv_finished;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_listview;

    FUNCTION get_procedure_notes
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_interv_notes IS
            SELECT ipd.notes, ipd.id_order_recurrence
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_presc_det = i_interv_presc_det;
    
        l_interv_notes c_interv_notes%ROWTYPE;
    
        l_ret VARCHAR2(1000 CHAR);
    
    BEGIN
    
        OPEN c_interv_notes;
        FETCH c_interv_notes
            INTO l_interv_notes;
    
        l_ret := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROCEDURES_T025') ||
                 nvl(pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0'),
                     pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                           i_prof,
                                                                           l_interv_notes.id_order_recurrence));
    
        IF c_interv_notes%FOUND
        THEN
            l_ret := l_ret || chr(10) || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROCEDURES_T096') || ' ' ||
                     l_interv_notes.notes;
        END IF;
    
        CLOSE c_interv_notes;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_notes;

    FUNCTION get_exec_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_institution interv_presc_det.id_exec_institution%TYPE;
        l_in_house       sys_message.code_message%TYPE := 'PROCEDURES_T078';
    
    BEGIN
    
        SELECT ipd.id_exec_institution
          INTO l_id_institution
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_presc_det = i_interv_presc_det;
    
        IF i_prof.id = l_id_institution
        THEN
            RETURN pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => l_in_house);
        ELSE
            RETURN pk_utils.get_institution_name(i_lang => i_lang, i_id_institution => l_id_institution);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exec_institution;

    PROCEDURE cpoe______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION copy_procedure_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_diagnosis_list(l_interv_presc_det interv_presc_det.id_interv_presc_det%TYPE) IS
            SELECT mrd.id_diagnosis, ed.desc_epis_diagnosis desc_diagnosis
              FROM mcdt_req_diagnosis mrd, epis_diagnosis ed
             WHERE mrd.id_interv_presc_det = l_interv_presc_det
               AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled
               AND mrd.id_epis_diagnosis = ed.id_epis_diagnosis;
    
        l_interv_prescription interv_prescription%ROWTYPE;
        l_interv_presc_det    interv_presc_det%ROWTYPE;
    
        l_diagnosis      table_number := table_number();
        l_diagnosis_desc table_varchar := table_varchar();
    
        l_codification codification.id_codification%TYPE;
    
        l_supply        table_number;
        l_supply_set    table_number;
        l_supply_qty    table_number;
        l_dt_return     table_varchar;
        l_dt_begin_tstz interv_presc_det.dt_begin_tstz%TYPE;
        l_supply_loc    table_number;
    
        l_clinical_question       table_number;
        l_response                table_varchar;
        l_clinical_question_notes table_varchar;
    
        l_flg_profile profile_template.flg_profile%TYPE;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        SELECT ipd.*
          INTO l_interv_presc_det
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_presc_det = i_task_request;
    
        SELECT ip.*
          INTO l_interv_prescription
          FROM interv_prescription ip
         WHERE ip.id_interv_prescription = l_interv_presc_det.id_interv_prescription;
    
        IF l_diagnosis IS NULL
           OR l_diagnosis.count = 0
        THEN
            FOR l_diagnosis_list IN c_diagnosis_list(i_task_request)
            LOOP
                l_diagnosis.extend;
                l_diagnosis(l_diagnosis.count) := l_diagnosis_list.id_diagnosis;
            
                l_diagnosis_desc.extend;
                l_diagnosis_desc(l_diagnosis.count) := l_diagnosis_list.desc_diagnosis;
            END LOOP;
        END IF;
    
        BEGIN
            SELECT ic.id_codification
              INTO l_codification
              FROM interv_codification ic
             WHERE ic.id_interv_codification = l_interv_presc_det.id_interv_codification;
        EXCEPTION
            WHEN no_data_found THEN
                l_codification := NULL;
        END;
    
        SELECT sw.id_supply,
               sw.id_supply_set,
               sw.quantity,
               pk_date_utils.date_send_tsz(i_lang, sw.dt_returned, i_prof),
               sw.id_supply_location
          BULK COLLECT
          INTO l_supply, l_supply_set, l_supply_qty, l_dt_return, l_supply_loc
          FROM supply_workflow sw
         WHERE sw.id_context = i_task_request
           AND sw.flg_context = pk_supplies_constant.g_context_procedure_req
         ORDER BY sw.id_supply_workflow;
    
        SELECT iqr.id_questionnaire, iqr.id_response, iqr.notes
          BULK COLLECT
          INTO l_clinical_question, l_response, l_clinical_question_notes
          FROM interv_question_response iqr
         WHERE iqr.id_interv_presc_det = i_task_request;
    
        IF i_task_start_timestamp IS NOT NULL
        THEN
            l_dt_begin_tstz := i_task_start_timestamp;
        ELSE
            IF pk_date_utils.trunc_insttimezone(i_prof, l_interv_presc_det.dt_end_tstz) >
               pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz)
            THEN
                l_dt_begin_tstz := g_sysdate_tstz;
            END IF;
        
        END IF;
    
        -- Note: do not copy the following information: 
        -- co-sing data (id_order_type, id_prof_order, dt_order, id_prof_co_sign, dt_co_sign, flg_co_sign, notes_co_sign)
        -- and cancelling data (id_cancel_reason, notes_cancel)
    
        -- clean data that is not being copied
        -- co-sign data        
    
        g_error := 'CALL PK_PROCEDURES_CORE.CREATE_PROCEDURE_REQUEST';
        IF NOT pk_procedures_core.create_procedure_request(i_lang                    => i_lang,
                                                           i_prof                    => i_prof,
                                                           i_patient                 => l_interv_prescription.id_patient,
                                                           i_episode                 => i_episode,
                                                           i_interv_prescription     => NULL,
                                                           i_intervention            => l_interv_presc_det.id_intervention,
                                                           i_flg_time                => l_interv_prescription.flg_time,
                                                           i_dt_begin                => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                    l_dt_begin_tstz,
                                                                                                                    i_prof),
                                                           i_episode_destination     => l_interv_prescription.id_episode_destination,
                                                           i_order_recurrence        => NULL,
                                                           i_diagnosis_notes         => l_interv_presc_det.diagnosis_notes,
                                                           i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang      => i_lang,
                                                                                                                  i_prof      => i_prof,
                                                                                                                  i_patient   => l_interv_prescription.id_patient,
                                                                                                                  i_episode   => i_episode,
                                                                                                                  i_diagnosis => l_diagnosis,
                                                                                                                  i_desc_diag => l_diagnosis_desc),
                                                           i_clinical_purpose        => l_interv_presc_det.id_clinical_purpose,
                                                           i_clinical_purpose_notes  => l_interv_presc_det.clinical_purpose_notes,
                                                           i_laterality              => l_interv_presc_det.flg_laterality,
                                                           i_priority                => l_interv_presc_det.flg_prty,
                                                           i_flg_prn                 => l_interv_presc_det.flg_prn,
                                                           i_notes_prn               => l_interv_presc_det.prn_notes,
                                                           i_exec_institution        => i_prof.institution,
                                                           i_flg_location            => l_interv_presc_det.flg_location,
                                                           i_supply                  => l_supply,
                                                           i_supply_set              => l_supply_set,
                                                           i_supply_qty              => l_supply_qty,
                                                           i_dt_return               => l_dt_return,
                                                           i_supply_loc              => l_supply_loc,
                                                           i_not_order_reason        => NULL,
                                                           i_notes                   => l_interv_presc_det.notes,
                                                           i_prof_order              => NULL,
                                                           i_dt_order                => l_interv_presc_det.dt_order_tstz,
                                                           i_order_type              => NULL,
                                                           i_codification            => l_codification,
                                                           i_health_plan             => l_interv_presc_det.id_pat_health_plan,
                                                           i_exemption               => l_interv_presc_det.id_pat_exemption,
                                                           i_clinical_question       => l_clinical_question,
                                                           i_response                => l_response,
                                                           i_clinical_question_notes => l_clinical_question_notes,
                                                           i_clinical_decision_rule  => NULL,
                                                           i_flg_origin_req          => pk_alert_constant.g_task_origin_cpoe,
                                                           o_interv_presc            => l_interv_prescription.id_interv_prescription,
                                                           o_interv_presc_det        => o_draft,
                                                           o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
        THEN
            l_sys_alert_event.id_sys_alert    := pk_alert_constant.g_alert_cpoe_draft;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := i_episode;
            l_sys_alert_event.id_patient      := l_interv_prescription.id_patient;
            l_sys_alert_event.id_record       := i_episode;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode, o_error);
            l_sys_alert_event.dt_record       := g_sysdate_tstz;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => i_episode,
                                                                                     o_error      => o_error);
        
            g_error := 'CALL PK_ALERTS.INSERT_SYS_ALERT_EVENT';
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COPY_PROCEDURE_TO_DRAFT',
                                              o_error);
            RETURN FALSE;
    END copy_procedure_to_draft;

    FUNCTION check_procedure_mandatory
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_clinical_purpose sys_config.value%TYPE := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_P', i_prof);
    
        l_flg_prof_need_cosign VARCHAR2(1 CHAR);
    
        l_check VARCHAR(1 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'CALL PK_CO_SIGN_API.CHECK_PROF_NEEDS_COSIGN';
        IF NOT pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                      i_prof                   => i_prof,
                                                      i_episode                => i_episode,
                                                      i_task_type              => pk_alert_constant.g_task_proc_interv,
                                                      i_cosign_def_action_type => pk_co_sign_api.g_cosign_action_def_add,
                                                      o_flg_prof_need_cosign   => l_flg_prof_need_cosign,
                                                      o_error                  => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_clinical_purpose = pk_procedures_constant.g_yes
        THEN
            BEGIN
                SELECT pk_procedures_constant.g_yes
                  INTO l_check
                  FROM interv_presc_det ipd
                 WHERE ipd.id_interv_presc_det = i_id_interv_presc_det
                   AND ipd.id_clinical_purpose IS NOT NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN pk_procedures_constant.g_no;
            END;
        END IF;
    
        IF l_flg_prof_need_cosign = pk_procedures_constant.g_yes
        THEN
            BEGIN
                SELECT pk_procedures_constant.g_yes
                  INTO l_check
                  FROM interv_presc_det ipd
                 WHERE ipd.id_interv_presc_det = i_id_interv_presc_det
                   AND ipd.id_co_sign_order IS NOT NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN pk_procedures_constant.g_no;
            END;
        END IF;
    
        g_error := 'Fetch instructions for i_id_interv_presc_det: ' || i_id_interv_presc_det;
        SELECT decode(ip.flg_time, NULL, pk_procedures_constant.g_no, pk_procedures_constant.g_yes)
          INTO l_check
          FROM interv_prescription ip, interv_presc_det ipd
         WHERE ipd.id_interv_presc_det = i_id_interv_presc_det
           AND ip.id_interv_prescription = ipd.id_interv_prescription;
    
        RETURN l_check;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PROCEDURE_MANDATORY_FIELD',
                                              l_error);
            RETURN pk_procedures_constant.g_no;
    END check_procedure_mandatory;

    FUNCTION check_procedure_draft_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient      patient.id_patient%TYPE;
        l_flg_conflict table_varchar := table_varchar();
        l_msg_title    table_varchar := table_varchar();
        l_msg_body     table_varchar := table_varchar();
        l_msg_template table_varchar := table_varchar();
        l_intervention table_number;
        l_dt_begin     table_timestamp_tz;
    
        l_tmp_flg_conflict VARCHAR2(4000);
        l_tmp_msg_title    VARCHAR2(4000);
        l_tmp_msg_text     VARCHAR2(4000);
    
        l_task_type       task_type.id_task_type%TYPE;
        l_dt_end          table_timestamp_tz;
        l_count_rel_tasks NUMBER;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error   := 'GET ID_PATIENT';
        l_patient := pk_episode.get_id_patient(i_episode => i_episode);
    
        SELECT ipd.id_intervention, ipd.dt_begin_tstz, ipd.dt_end_tstz
          BULK COLLECT
          INTO l_intervention, l_dt_begin, l_dt_end
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_presc_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            t.column_value
                                             FROM TABLE(i_draft) t);
    
        l_task_type := pk_cpoe.g_task_type_procedure;
    
        SELECT COUNT(*)
          INTO l_count_rel_tasks
          FROM cpoe_tasks_relation a
         WHERE a.id_task_dest IN (SELECT column_value
                                    FROM TABLE(i_draft))
           AND a.id_task_type = l_task_type
           AND a.flg_type = 'AD';
    
        IF l_count_rel_tasks > 0
           AND (l_dt_end(1) IS NULL OR (l_dt_end(1) IS NOT NULL AND l_dt_end(1) < g_sysdate_tstz))
        THEN
            l_flg_conflict.extend;
            o_flg_conflict := l_flg_conflict;
            RETURN TRUE;
        END IF;
    
        g_error := 'CHECK FOR CONFLICTS';
    
        l_flg_conflict.extend;
        l_flg_conflict(l_flg_conflict.count) := pk_procedures_utils.get_procedure_request(i_lang         => i_lang,
                                                                                          i_prof         => i_prof,
                                                                                          i_patient      => l_patient,
                                                                                          i_intervention => l_intervention,
                                                                                          o_msg_title    => l_tmp_msg_title,
                                                                                          o_msg_req      => l_tmp_msg_text);
    
        l_msg_template.extend;
        l_msg_template(l_msg_template.count) := pk_alert_constant.g_modal_win_warning_confirm;
        l_msg_title.extend;
        l_msg_title(l_msg_title.count) := l_tmp_msg_title;
        l_msg_body.extend;
        l_msg_body(l_msg_body.count) := l_tmp_msg_text;
    
        o_flg_conflict := l_flg_conflict;
        o_msg_title    := l_msg_title;
        o_msg_body     := l_msg_body;
        o_msg_template := l_msg_template;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PROCEDURE_DRAFT_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_procedure_draft_conflict;

    FUNCTION check_procedure_draft
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_has_draft OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER;
    
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM interv_prescription ip
         WHERE ip.id_episode_destination = i_episode
           AND ip.flg_status = pk_procedures_constant.g_interv_draft;
    
        IF l_count > 0
        THEN
            o_has_draft := pk_procedures_constant.g_yes;
        ELSE
            o_has_draft := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PROCEDURE_DRAFT',
                                              o_error);
            RETURN FALSE;
    END check_procedure_draft;

    FUNCTION set_procedure_draft_activation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        i_id_cdr_call   IN cdr_call.id_cdr_call%TYPE,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_interv_draft IS
            SELECT ip.id_interv_prescription,
                   ipd.id_interv_presc_det,
                   ipp.id_interv_presc_plan,
                   decode(pk_date_utils.compare_dates_tsz(i_prof, ipd.dt_begin_tstz, g_sysdate_tstz),
                          pk_alert_constant.g_date_lower,
                          g_sysdate_tstz,
                          ipd.dt_begin_tstz) dt_begin,
                   ip.flg_time,
                   ipd.flg_prn,
                   nvl(ipd.id_exec_institution, i_prof.institution) id_exec_institution,
                   ipd.id_co_sign_order,
                   ipd.dt_end_tstz
              FROM interv_presc_det ipd
              LEFT JOIN interv_presc_plan ipp
                ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
              JOIN interv_prescription ip
                ON ip.id_interv_prescription = ipd.id_interv_prescription
             WHERE ipd.id_interv_presc_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                *
                                                 FROM TABLE(i_draft) t);
    
        l_next_plan interv_presc_plan.id_interv_presc_plan%TYPE;
    
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
        l_task_type       cpoe_task_type.id_task_type%TYPE;
        l_count_rel_tasks NUMBER;
        l_dt_end          interv_presc_det.dt_end_tstz%TYPE;
        l_draft           table_number;
        l_id_request      interv_presc_det.id_interv_presc_det%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        o_created_tasks := i_draft;
    
        FOR rec IN c_interv_draft
        LOOP
        
            l_task_type := pk_cpoe.g_task_type_procedure;
        
            BEGIN
                SELECT a.id_task_orig
                  INTO l_count_rel_tasks
                  FROM cpoe_tasks_relation a
                 WHERE a.id_task_dest = rec.id_interv_presc_det
                   AND a.id_task_type = l_task_type
                   AND a.flg_type = 'AD';
            EXCEPTION
                WHEN no_data_found THEN
                    l_count_rel_tasks := 0;
            END;
        
            IF l_count_rel_tasks > 0
            THEN
                SELECT a.dt_end_tstz
                  INTO l_dt_end
                  FROM interv_presc_det a
                 WHERE a.id_interv_presc_det = l_count_rel_tasks;
            END IF;
        
            IF l_count_rel_tasks > 0
               AND (l_dt_end IS NULL OR (l_dt_end IS NOT NULL AND l_dt_end > g_sysdate_tstz))
            
            THEN
            
                IF NOT pk_cpoe.sync_active_to_next(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_episode   => i_episode,
                                                   i_task_type => l_task_type,
                                                   i_request   => rec.id_interv_presc_det,
                                                   o_error     => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                l_draft := i_draft;
            
                FOR i IN 1 .. l_draft.count
                LOOP
                    IF l_draft(i) = rec.id_interv_presc_det
                    THEN
                        SELECT a.id_task_orig
                          INTO l_id_request
                          FROM cpoe_tasks_relation a
                         WHERE a.id_task_dest = rec.id_interv_presc_det;
                        l_draft(i) := l_id_request;
                    END IF;
                END LOOP;
            
                IF NOT cancel_procedure_draft(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_episode => i_episode,
                                              i_draft   => table_number(rec.id_interv_presc_det),
                                              o_error   => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
                o_created_tasks := l_draft;
            
                RETURN TRUE;
            END IF;
        
            IF rec.id_co_sign_order IS NOT NULL
            THEN
                g_error := 'CALL PK_CO_SIGN_API.SET_TASK_PENDING';
                IF NOT pk_co_sign_api.set_task_pending(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_episode         => i_episode,
                                                       i_id_co_sign      => NULL,
                                                       i_id_co_sign_hist => rec.id_co_sign_order,
                                                       i_dt_update       => g_sysdate_tstz,
                                                       o_id_co_sign_hist => l_id_co_sign_hist,
                                                       o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        
            g_error := 'UPDATE INTERV_PRESC_DET';
            ts_interv_presc_det.upd(id_interv_presc_det_in => rec.id_interv_presc_det,
                                    flg_status_in          => CASE rec.id_exec_institution
                                                                  WHEN i_prof.institution THEN
                                                                   pk_procedures_constant.g_interv_pending
                                                                  ELSE
                                                                   pk_procedures_constant.g_interv_exterior
                                                              END,
                                    dt_begin_tstz_in       => CASE
                                                                  WHEN rec.flg_time = pk_procedures_constant.g_flg_time_n THEN
                                                                   NULL
                                                                  ELSE
                                                                   rec.dt_begin
                                                              END,
                                    id_co_sign_order_in    => l_id_co_sign_hist,
                                    dt_last_update_tstz_in => g_sysdate_tstz,
                                    id_cdr_event_in        => i_id_cdr_call,
                                    rows_out               => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'INTERV_PRESC_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            l_rows_out := NULL;
        
            --Supplies draft
            g_error := 'UPDATE SUPPLY_REQUEST';
            ts_supply_request.upd(flg_status_in => pk_supplies_constant.g_srt_requested,
                                  where_in      => 'id_context=' || rec.id_interv_presc_det || ' and flg_context=''' ||
                                                   pk_procedures_constant.g_type_interv || '''',
                                  rows_out      => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SUPPLY_REQUEST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            l_rows_out := NULL;
        
            IF rec.flg_time != pk_procedures_constant.g_flg_time_n
            THEN
                IF rec.flg_prn != pk_procedures_constant.g_yes
                THEN
                    --isn't a SOS but can be originated in one and l_interv_presc_plan is null in that case
                    IF rec.id_interv_presc_plan IS NOT NULL
                    THEN
                        g_error := 'UPDATE INTERV_PRESC_PLAN';
                        ts_interv_presc_plan.upd(id_interv_presc_plan_in => rec.id_interv_presc_plan,
                                                 dt_plan_tstz_in         => rec.dt_begin,
                                                 dt_interv_presc_plan_in => g_sysdate_tstz,
                                                 id_prof_last_update_in  => i_prof.id,
                                                 dt_last_update_tstz_in  => g_sysdate_tstz,
                                                 rows_out                => l_rows_out);
                    
                        g_error := 'PROCESS_UPDATE';
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'INTERV_PRESC_PLAN',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => o_error);
                    
                    ELSE
                        g_error     := 'GET NEXT_KEY';
                        l_next_plan := ts_interv_presc_plan.next_key;
                    
                        g_error := 'INSERT INTERV_PRESC_PLAN';
                        ts_interv_presc_plan.ins(id_interv_presc_plan_in => l_next_plan, id_interv_presc_det_in => rec.id_interv_presc_det, dt_plan_tstz_in => CASE rec.flg_time WHEN pk_procedures_constant.g_flg_time_n THEN CAST(NULL AS TIMESTAMP WITH TIME ZONE) ELSE nvl(rec.dt_begin, g_sysdate_tstz) END, flg_status_in => CASE rec.flg_time WHEN pk_procedures_constant.g_flg_time_n THEN pk_procedures_constant.g_interv_plan_pending ELSE CASE sign(extract(DAY FROM(nvl(rec.dt_begin, g_sysdate_tstz) - g_sysdate_tstz))) WHEN 1 THEN pk_procedures_constant.g_interv_plan_pending ELSE pk_procedures_constant.g_interv_plan_req END END, dt_interv_presc_plan_in => g_sysdate_tstz, id_prof_last_update_in => i_prof.id, dt_last_update_tstz_in => g_sysdate_tstz, rows_out => l_rows_out);
                    
                        g_error := 't_data_gov_mnt.process_insert INTERV_PRESC_PLAN';
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'INTERV_PRESC_PLAN',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => o_error);
                    END IF;
                ELSE
                    -- if is SOS and interv_presc_plan is not null then it originated in a normal one and it must be removed
                    IF rec.id_interv_presc_plan IS NOT NULL
                    THEN
                        ts_interv_presc_plan.del(id_interv_presc_plan_in => rec.id_interv_presc_plan);
                    END IF;
                END IF;
            END IF;
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE INTERV_PRESCRIPTION';
            ts_interv_prescription.upd(id_interv_prescription_in      => rec.id_interv_prescription,
                                       dt_interv_prescription_tstz_in => g_sysdate_tstz,
                                       dt_begin_tstz_in               => rec.dt_begin,
                                       id_professional_in             => i_prof.id,
                                       rows_out                       => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'INTERV_PRESCRIPTION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'CALL PK_PROCEDURES_UTILS.CREATE_PROCEDURE_MOVEMENT';
            IF NOT pk_procedures_utils.create_procedure_movement(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_episode          => i_episode,
                                                                 i_interv_presc_det => rec.id_interv_presc_det,
                                                                 o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL PK_VISIT.UPD_EPIS_INFO_INTERV';
            IF NOT pk_visit.upd_epis_info_interv(i_lang                       => i_lang,
                                            i_id_episode                 => i_episode,
                                            i_id_prof                    => i_prof,
                                            i_dt_first_intervention_prsc => CASE
                                                                                WHEN rec.flg_time !=
                                                                                     pk_procedures_constant.g_flg_time_n THEN
                                                                                 pk_date_utils.date_send_tsz(i_lang,
                                                                                                             g_sysdate_tstz,
                                                                                                             i_prof)
                                                                                ELSE
                                                                                 NULL
                                                                            END,
                                            i_dt_first_intervention_take => NULL,
                                            i_prof_cat_type              => pk_prof_utils.get_category(i_lang, i_prof),
                                            o_error                      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => pk_episode.get_id_patient(i_episode),
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL PK_CPOE.SYNC_TASK';
            IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                     i_prof                 => i_prof,
                                     i_episode              => i_episode,
                                     i_task_type            => pk_alert_constant.g_task_type_procedure,
                                     i_task_request         => rec.id_interv_presc_det,
                                     i_task_start_timestamp => rec.dt_begin,
                                     o_error                => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        IF i_flg_commit = pk_procedures_constant.g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROCEDURE_DRAFT_ACTIVATION',
                                              o_error);
            RETURN FALSE;
    END set_procedure_draft_activation;

    FUNCTION cancel_procedure_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_interv_prescription interv_prescription.id_interv_prescription%TYPE;
        l_id_interv_presc_plan   table_number;
    
    BEGIN
    
        g_error := 'DELETE DRAFTS';
        FOR i IN 1 .. i_draft.count
        LOOP
            SELECT id_interv_presc_plan
              BULK COLLECT
              INTO l_id_interv_presc_plan
              FROM interv_presc_plan
             WHERE id_interv_presc_det = i_draft(i);
        
            g_error := 'DELETE INTERV_PRESC_PLAN';
            ts_interv_presc_plan.del_by(where_clause_in => 'id_interv_presc_plan IN (' ||
                                                           pk_utils.concat_table(i_tab   => l_id_interv_presc_plan,
                                                                                 i_delim => ',') || ')');
        
            -- delete interv_question_response
            DELETE FROM interv_question_response
             WHERE id_interv_presc_det = i_draft(i);
        
            g_error := 'DELETE MCDT_REQ_DIAGNOSIS 1';
            DELETE FROM mcdt_req_diagnosis mrd
             WHERE mrd.id_interv_presc_det = i_draft(i);
        
            g_error := 'DELETE INTERV_PRESC_DET_HIST';
            DELETE FROM interv_presc_det_hist ipdh
             WHERE ipdh.id_interv_presc_det = i_draft(i);
        
            g_error := 'DELETE INTERV_PRESC_DET';
            ts_interv_presc_det.del(id_interv_presc_det_in => i_draft(i));
        
            g_error := 'DELETE PROCEDURES_EA';
            ts_procedures_ea.del(id_interv_presc_det_in => i_draft(i));
        
            BEGIN
                g_error := 'GET INTERV_PRESCRIPTION';
                SELECT ipd.id_interv_prescription
                  INTO l_id_interv_prescription
                  FROM interv_presc_det ipd
                 WHERE ipd.id_interv_presc_det != i_draft(i)
                   AND ipd.id_interv_prescription =
                       (SELECT id_interv_prescription
                          FROM interv_presc_det
                         WHERE id_interv_presc_det = i_draft(i));
            
                g_error := 'DELETE MCDT_REQ_DIAGNOSIS 2';
                DELETE FROM mcdt_req_diagnosis mrd
                 WHERE mrd.id_interv_prescription = l_id_interv_prescription;
            
                g_error := 'DELETE INTERV_PRESCRIPTION';
                ts_interv_prescription.del(id_interv_prescription_in => l_id_interv_prescription);
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PROCEDURE_DRAFT',
                                              o_error);
            RETURN FALSE;
    END cancel_procedure_draft;

    FUNCTION cancel_procedure_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_drafts table_number;
    
    BEGIN
    
        g_error := 'Get episode''s draft tasks';
        SELECT pea.id_interv_presc_det
          BULK COLLECT
          INTO l_drafts
          FROM procedures_ea pea
         WHERE pea.id_episode IN (SELECT id_episode
                                    FROM episode
                                   WHERE id_visit = pk_episode.get_id_visit(i_episode))
           AND pea.flg_status_det = pk_procedures_constant.g_interv_draft;
    
        IF l_drafts IS NOT NULL
           AND l_drafts.count > 0
        THEN
            IF NOT pk_procedures_external.cancel_procedure_draft(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_episode,
                                                                 i_draft   => l_drafts,
                                                                 o_error   => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PROCEDURE_ALL_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END cancel_procedure_all_drafts;

    FUNCTION set_procedure_expiration
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_prescription table_number;
        l_interv_presc_det    table_number;
        l_interv_presc_plan   table_number;
    
        l_expired_note sys_message.desc_message%TYPE;
    
        l_movement_list   table_number;
        l_co_sign_order   table_number;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    
        l_supply                 pk_types.cursor_type;
        l_supply_request         supply_request.id_supply_request%TYPE;
        l_supply_request_context supply_request.flg_context%TYPE;
    
        l_count NUMBER;
    
        i PLS_INTEGER;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        -- Sanity check
        IF i_task_requests IS NULL
           OR i_episode IS NULL
        THEN
            g_error := 'Invalid input arguments';
            RETURN TRUE;
        END IF;
    
        -- Text to include as cancellation note: "This patient's prescription (CPOE) has expired."
        l_expired_note := pk_message.get_message(i_lang, 'CPOE_M014');
    
        -- Filter INTERV_PRESC_DET that really meet the requirements for being able to expire 
        -- (ie. cannot expire a task that is completed, canceled, sent to Referral, etc.)
        -- In addition, returns a list of associated movements that are in status pending or request
        g_error := 'SELECT INTERV_PRESCRIPTION';
        SELECT ipd.id_interv_presc_det, mov.id_movement, ipd.id_co_sign_order
          BULK COLLECT
          INTO l_interv_presc_det, l_movement_list, l_co_sign_order
          FROM interv_prescription ip
         INNER JOIN interv_presc_det ipd
            ON ip.id_interv_prescription = ipd.id_interv_prescription
          LEFT JOIN movement mov
            ON ipd.id_movement = mov.id_movement
           AND mov.flg_status IN (pk_alert_constant.g_mov_status_pend, pk_alert_constant.g_mov_status_req)
         WHERE ip.id_episode = i_episode
           AND ipd.id_interv_presc_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            column_value
                                             FROM TABLE(i_task_requests) t)
           AND ipd.flg_status IN (pk_procedures_constant.g_interv_req,
                                  pk_procedures_constant.g_interv_pending,
                                  pk_procedures_constant.g_interv_exterior,
                                  pk_procedures_constant.g_interv_exec)
           AND nvl(ipd.flg_referral, pk_procedures_constant.g_flg_referral_a) NOT IN
               (pk_procedures_constant.g_flg_referral_r,
                pk_procedures_constant.g_flg_referral_s,
                pk_procedures_constant.g_flg_referral_i);
    
        -- So proceed if there are tasks able to expire
        IF l_interv_presc_det.count > 0
        THEN
            -- Filter INTERV_PRESC_PLAN that really meet the requirements for being able to expire 
            g_error := 'SELECT INTERV_PRESC_PLAN';
            SELECT ipp.id_interv_presc_plan
              BULK COLLECT
              INTO l_interv_presc_plan
              FROM interv_presc_plan ipp
             WHERE ipp.id_interv_presc_det IN (SELECT /*+opt_estimate(table t rows=1) */
                                                column_value
                                                 FROM TABLE(l_interv_presc_det) t)
               AND ipp.flg_status IN
                   (pk_procedures_constant.g_interv_plan_req, pk_procedures_constant.g_interv_plan_pending);
        
            -- Filter the INTERV_PRESCRIPTION that really meet the requirements for being able to expire
            g_error := 'SELECT INTERV_PRESCRIPTION';
            SELECT ip.id_interv_prescription
              BULK COLLECT
              INTO l_interv_prescription
              FROM interv_prescription ip
             INNER JOIN interv_presc_det ipd
                ON ip.id_interv_prescription = ipd.id_interv_prescription
             WHERE ip.id_episode = i_episode
               AND ipd.id_interv_presc_det IN (SELECT /*+opt_estimate(table t rows=1) */
                                                column_value
                                                 FROM TABLE(l_interv_presc_det) t)
               AND ip.flg_status IN (pk_procedures_constant.g_interv_pending,
                                     pk_procedures_constant.g_interv_req,
                                     pk_procedures_constant.g_interv_partial);
        
            -- In order to improve performance this code doesn't update entries using TS 
        
            l_rows_out := NULL;
        
            -- Update interventions plan as expired
            g_error := 'UPDATE INTERV_PRESC_PLAN.FLG_STATUS';
            FORALL i IN l_interv_presc_plan.first .. l_interv_presc_plan.last
                UPDATE interv_presc_plan ipp
                   SET ipp.flg_status     = pk_procedures_constant.g_interv_plan_expired,
                       ipp.id_prof_cancel = i_prof.id,
                       ipp.notes_cancel   = l_expired_note,
                       ipp.dt_cancel_tstz = g_sysdate_tstz
                 WHERE ipp.id_interv_presc_plan = l_interv_presc_plan(i)
                RETURNING ROWID BULK COLLECT INTO l_rows_out;
        
            g_error := 'PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'INTERV_PRESC_PLAN',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            l_rows_out := NULL;
        
            -- Update interventions as expired
            g_error := 'UPDATE INTERV_PRESC_DET.FLG_STATUS';
            FORALL i IN l_interv_presc_det.first .. l_interv_presc_det.last
                UPDATE interv_presc_det ipd
                   SET ipd.flg_status          = pk_procedures_constant.g_interv_expired,
                       ipd.id_prof_cancel      = i_prof.id,
                       ipd.notes_cancel        = l_expired_note,
                       ipd.dt_cancel_tstz      = g_sysdate_tstz,
                       ipd.dt_last_update_tstz = g_sysdate_tstz
                 WHERE ipd.id_interv_presc_det = l_interv_presc_det(i)
                RETURNING ROWID BULK COLLECT INTO l_rows_out;
        
            g_error := 'PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'INTERV_PRESC_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            l_rows_out := NULL;
        
            -- Update intervention req as expired
            g_error := 'UPDATE INTERV_PRESCRIPTION.FLG_STATUS';
            FORALL i IN l_interv_prescription.first .. l_interv_prescription.last
                UPDATE interv_prescription ip
                   SET ip.flg_status          = pk_procedures_constant.g_interv_expired,
                       ip.id_prof_cancel      = i_prof.id,
                       ip.notes_cancel        = l_expired_note,
                       ip.dt_cancel_tstz      = g_sysdate_tstz,
                       ip.dt_last_update_tstz = g_sysdate_tstz
                 WHERE ip.id_interv_prescription = l_interv_prescription(i)
                RETURNING ROWID BULK COLLECT INTO l_rows_out;
        
            g_error := 'PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'INTERV_PRESCRIPTION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'Updating the dependencies propagating the status change of each expired procedure';
            i       := l_interv_presc_det.first;
            WHILE i IS NOT NULL
            LOOP
                -- Insert this status change into TI LOG
                g_error := 'CALL T_TI_LOG.INS_LOG';
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => i_episode,
                                        i_flg_status => pk_procedures_constant.g_interv_expired,
                                        i_id_record  => l_interv_presc_det(i),
                                        i_flg_type   => pk_procedures_constant.g_interv_type_req,
                                        o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                BEGIN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM interv_presc_plan ipp
                     WHERE ipp.id_interv_presc_det = l_interv_presc_det(i)
                       AND ipp.flg_status = pk_procedures_constant.g_interv_plan_executed;
                
                    -- Cancel co_sign
                    g_error := 'CALL PK_CO_SIGN_API.SET_TASK_OUTDATED';
                    IF NOT pk_co_sign_api.set_task_outdated(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_episode         => i_episode,
                                                            i_id_co_sign      => NULL,
                                                            i_id_co_sign_hist => l_co_sign_order(i),
                                                            i_dt_update       => g_sysdate_tstz,
                                                            o_id_co_sign_hist => l_id_co_sign_hist,
                                                            o_error           => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
                -- Verify if the procedure has supplies requests
                g_error := 'CALL PK_SUPPLIES_EXTERNAL_API_DB.GET_SUPPLY_BY_CONTEXT';
                IF NOT pk_supplies_external_api_db.get_supply_by_context(i_lang       => i_lang,
                                                                         i_prof       => i_prof,
                                                                         i_id_context => l_interv_presc_det(i),
                                                                         o_supply     => l_supply,
                                                                         o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                g_error := 'CANCELLING SUPPLIES REQUESTS';
                LOOP
                    FETCH l_supply
                        INTO l_supply_request, l_supply_request_context;
                    EXIT WHEN l_supply%NOTFOUND;
                    -- if the request of supplies has been in the context of the request for a procedure then cancels it
                    IF l_supply_request_context = pk_supplies_constant.g_context_procedure_req
                    THEN
                        g_error := 'CALL PK_SUPPLIES_API_DB.CANCEL_REQUEST';
                        IF NOT pk_supplies_api_db.cancel_request(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_supply_request   => l_supply_request,
                                                                 i_notes            => NULL,
                                                                 i_id_cancel_reason => NULL,
                                                                 o_error            => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END LOOP;
                CLOSE l_supply;
            
                i := l_interv_prescription.next(i);
            END LOOP;
        
            -- Cancels all the suggestions requested by the procedures
            g_error := 'CALL PK_ICNP_FO_API_DB.SET_SUGGS_STATUS_CANCEL';
            pk_icnp_fo_api_db.set_suggs_status_cancel(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_request_ids  => l_interv_presc_det,
                                                      i_task_type_id => pk_alert_constant.g_task_procedure,
                                                      i_sysdate_tstz => g_sysdate_tstz);
        
            -- Remove alerts notification for these procedures
            g_error := 'Removing ALERTs notification';
            i       := l_interv_presc_plan.first;
            WHILE i IS NOT NULL
            LOOP
                -- Remove from alert notification "Procedures to be performed"
                l_sys_alert_event.id_sys_alert := 6;
                l_sys_alert_event.id_episode   := i_episode;
                l_sys_alert_event.id_record    := l_interv_presc_plan(i);
            
                g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT (ID_SYS_ALERT=6)';
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                -- Remove from alert notification "Procedures to be performed per profile"
                l_sys_alert_event.id_sys_alert := 41;
                l_sys_alert_event.id_episode   := i_episode;
                l_sys_alert_event.id_record    := l_interv_presc_plan(i);
            
                g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT (ID_SYS_ALERT=41)';
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
                i := l_interv_presc_plan.next(i);
            END LOOP;
        
            l_rows_out := NULL;
        
            -- A distinct range of elements from a collection 
            l_movement_list := SET(l_movement_list);
            i               := l_movement_list.first;
        
            -- Cancels related movements with status "pending" or "required"
            WHILE i IS NOT NULL
            LOOP
                g_error := 'UPDATE MOVEMENT';
                ts_movement.upd(id_movement_in    => l_movement_list(i),
                                flg_status_in     => pk_alert_constant.g_mov_status_cancel,
                                id_prof_cancel_in => i_prof.id,
                                dt_cancel_tstz_in => g_sysdate_tstz,
                                rows_out          => l_rows_out);
            
                g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'MOVEMENT',
                                              i_list_columns => table_varchar('FLG_STATUS',
                                                                              'ID_PROF_CANCEL',
                                                                              'DT_CANCEL_TSTZ'),
                                              i_rowids       => l_rows_out,
                                              o_error        => o_error);
            
                -- Remove from alert notification "Patients to transport"
                l_sys_alert_event.id_sys_alert := 9;
                l_sys_alert_event.id_episode   := i_episode;
                l_sys_alert_event.id_record    := l_movement_list(i);
            
                g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT (id_sys_alert=9)';
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                i := l_movement_list.next(i);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROCEDURE_EXPIRATION',
                                              o_error);
            RETURN FALSE;
    END set_procedure_expiration;

    FUNCTION get_procedure_task_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT 'N',
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_task_list     OUT pk_types.cursor_type,
        o_plan_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancelled_task_filter_interval sys_config.value%TYPE := pk_sysconfig.get_config('CPOE_CANCELLED_TASK_FILTER_INTERVAL',
                                                                                          i_prof);
        l_cancelled_task_filter_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_cancelled_task_filter_tstz := current_timestamp -
                                        numtodsinterval(to_number(l_cancelled_task_filter_interval), 'DAY');
    
        OPEN o_task_list FOR
            WITH cso_table AS
             (SELECT *
                FROM TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang,
                                                                    i_prof,
                                                                    i_episode,
                                                                    pk_alert_constant.g_task_proc_interv)))
            SELECT task_type,
                   t_ti_log.get_desc_with_origin(i_lang,
                                                  i_prof,
                                                  task_description,
                                                  pk_episode.get_epis_type(i_lang, i_episode),
                                                  flg_status,
                                                  id_request,
                                                  pk_procedures_constant.g_interv_type_req) ||
                    (CASE
                         WHEN flg_time IN (pk_procedures_constant.g_flg_time_a, pk_procedures_constant.g_flg_time_h) THEN
                          ', ' || pk_sysdomain.get_domain('INTERV_PRESCRIPTION.FLG_TIME', flg_time, i_lang)
                         ELSE
                          NULL
                     END) AS task_description,
                   id_professional,
                   icon_warning,
                   status_string,
                   id_request,
                   start_date_tstz,
                   end_date_tstz,
                   create_date_tstz,
                   flg_status,
                   flg_cancel,
                   flg_conflict,
                   id_task,
                   task_title,
                   task_instructions,
                   task_notes,
                   drug_dose,
                   drug_route,
                   drug_take_in_case,
                   task_status,
                   NULL AS instr_bg_color,
                   NULL AS instr_bg_alpha,
                   NULL AS task_icon,
                   pk_alert_constant.g_no AS flg_need_ack,
                   NULL AS edit_icon,
                   NULL AS action_desc,
                   NULL AS previous_status,
                   pk_alert_constant.g_task_proc_interv AS id_task_type_source,
                   NULL AS id_task_dependency,
                   decode(flg_status,
                          pk_procedures_constant.g_interv_cancel,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_rep_cancel,
                   flg_prn flg_prn_conditional
              FROM (SELECT pk_alert_constant.g_task_type_procedure task_type,
                           pk_procedures_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'INTERVENTION.CODE_INTERVENTION.' ||
                                                                      pea.id_intervention,
                                                                      NULL) task_description,
                           ipd.id_prof_last_update id_professional,
                           NULL icon_warning,
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      pea.status_str,
                                                      pea.status_msg,
                                                      pea.status_icon,
                                                      pea.status_flg) status_string,
                           pea.id_interv_presc_det id_request,
                           decode(i_flg_report,
                                  pk_alert_constant.g_yes,
                                  pea.dt_begin_det,
                                  nvl(pea.dt_plan, pea.dt_begin_det)) start_date_tstz,
                           NULL end_date_tstz,
                           ipd.dt_last_update_tstz create_date_tstz,
                           pea.flg_status_det flg_status,
                           pk_procedures_utils.get_procedure_permission(i_lang,
                                                                        i_prof,
                                                                        pk_procedures_constant.g_interv_area_procedures,
                                                                        pk_procedures_constant.g_interv_button_cancel,
                                                                        pea.id_episode,
                                                                        pea.id_interv_presc_det,
                                                                        NULL,
                                                                        decode(pea.id_episode,
                                                                               i_episode,
                                                                               pk_procedures_constant.g_yes,
                                                                               pk_procedures_constant.g_no)) flg_cancel,
                           CASE
                                WHEN (pea.flg_status_det = pk_procedures_constant.g_interv_draft AND
                                     pk_procedures_external.check_procedure_mandatory(i_lang,
                                                                                       i_prof,
                                                                                       i_episode,
                                                                                       pea.id_interv_presc_det) =
                                     pk_procedures_constant.g_no) THEN
                                 pk_procedures_constant.g_yes
                                WHEN (pea.flg_status_det = pk_procedures_constant.g_interv_draft AND
                                     ipd.dt_end_tstz IS NOT NULL) THEN
                                 decode(pk_date_utils.compare_dates_tsz(i_prof, ipd.dt_end_tstz, g_sysdate_tstz),
                                        pk_alert_constant.g_date_lower,
                                        pk_procedures_constant.g_yes,
                                        pk_procedures_constant.g_no)
                                ELSE
                                 pk_alert_constant.g_no
                            END flg_conflict,
                           decode(i_flg_report,
                                  pk_procedures_constant.g_yes,
                                  pk_procedures_api_db.get_alias_translation(i_lang,
                                                                             i_prof,
                                                                             'INTERVENTION.CODE_INTERVENTION.' ||
                                                                             pea.id_intervention,
                                                                             NULL)) task_title,
                           decode(i_flg_report,
                                  pk_procedures_constant.g_yes,
                                  decode(pea.flg_prn,
                                         pk_alert_constant.g_yes,
                                         pk_message.get_message(i_lang, 'COMMON_M112'),
                                         nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                                   i_prof,
                                                                                                   ipd.id_order_recurrence),
                                             pk_translation.get_translation(i_lang,
                                                                            'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')))) task_instructions,
                           decode(i_flg_report,
                                  pk_procedures_constant.g_yes,
                                  decode(ipd.notes_cancel,
                                         NULL,
                                         decode(pea.flg_prn,
                                                pk_alert_constant.g_yes,
                                                pk_string_utils.clob_to_varchar2(ipd.prn_notes, 1000),
                                                ipd.notes),
                                         ipd.notes_cancel)) task_notes,
                           pk_procedures_utils.get_procedure_supplies(i_lang,
                                                                      i_prof,
                                                                      pk_utils.concat_table(CAST(MULTISET
                                                                                                 (SELECT sw.id_supply_workflow
                                                                                                    FROM supply_workflow sw
                                                                                                   WHERE sw.id_context =
                                                                                                         ipd.id_interv_presc_det
                                                                                                     AND sw.flg_context =
                                                                                                         pk_supplies_constant.g_context_procedure_req
                                                                                                     AND nvl(sw.flg_status,
                                                                                                             '@') !=
                                                                                                         pk_supplies_constant.g_sww_updated
                                                                                                  UNION ALL
                                                                                                  SELECT sw.id_supply_workflow
                                                                                                    FROM supply_workflow_hist sw
                                                                                                   WHERE NOT EXISTS
                                                                                                   (SELECT 1
                                                                                                            FROM supply_workflow sw1
                                                                                                           WHERE sw1.id_context =
                                                                                                                 ipd.id_interv_presc_det
                                                                                                             AND sw1.flg_context =
                                                                                                                 pk_supplies_constant.g_context_procedure_req
                                                                                                             AND nvl(sw.flg_status,
                                                                                                                     '@') !=
                                                                                                                 pk_supplies_constant.g_sww_updated)
                                                                                                     AND sw.id_context =
                                                                                                         ipd.id_interv_presc_det
                                                                                                     AND sw.flg_context =
                                                                                                         pk_supplies_constant.g_context_procedure_req
                                                                                                     AND nvl(sw.flg_status,
                                                                                                             '@') !=
                                                                                                         pk_supplies_constant.g_sww_updated) AS
                                                                                                 table_number),
                                                                                            ';')) drug_dose,
                           NULL drug_route,
                           NULL drug_take_in_case,
                           decode(i_flg_report,
                                  pk_procedures_constant.g_yes,
                                  pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det, i_lang)) task_status,
                           nvl(pea.dt_plan, pea.dt_begin_det) TIMESTAMP,
                           decode(nvl(pea.flg_referral, 'A'),
                                  'A',
                                  pk_sysdomain.get_rank(i_lang,
                                                        'INTERV_PRESC_DET.FLG_STATUS',
                                                        decode(pea.flg_status_det, 'E', 'D', pea.flg_status_det)),
                                  pk_sysdomain.get_rank(i_lang, 'INTERV_PRESC_DET.FLG_REFERRAL', pea.flg_referral)) rank,
                           nvl(pea.id_episode, pea.id_episode_origin) id_episode,
                           pea.id_intervention id_task,
                           pea.flg_time,
                           pea.flg_prn
                      FROM procedures_ea pea
                      JOIN interv_presc_det ipd
                        ON ipd.id_interv_presc_det = pea.id_interv_presc_det
                      LEFT JOIN cso_table tcs
                        ON ipd.id_co_sign_order = tcs.id_co_sign_hist
                     WHERE pea.id_patient = i_patient
                       AND ((i_flg_report = pk_alert_constant.g_yes AND
                           pea.flg_status_det != pk_procedures_constant.g_interv_exterior) OR
                           i_flg_report = pk_alert_constant.g_no)
                       AND ((pea.id_episode IN
                           (SELECT id_episode
                                FROM episode
                               WHERE id_visit = pk_episode.get_id_visit(i_episode)) OR
                           pea.id_episode_origin IN
                           (SELECT id_episode
                                FROM episode
                               WHERE id_visit = pk_episode.get_id_visit(i_episode))) OR
                           (pea.flg_time IN (pk_procedures_constant.g_flg_time_a, pk_procedures_constant.g_flg_time_h) AND
                           (pea.flg_status_det IN (pk_procedures_constant.g_interv_req,
                                                     pk_procedures_constant.g_interv_pending,
                                                     pk_procedures_constant.g_interv_exec,
                                                     pk_procedures_constant.g_interv_sos) OR
                           (EXISTS (SELECT 1
                                         FROM interv_presc_plan a
                                        WHERE a.id_interv_presc_det = pea.id_interv_presc_det
                                          AND a.id_episode_write = i_episode)))))
                       AND (i_task_request IS NULL OR
                           (pea.id_interv_presc_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                          column_value
                                                           FROM TABLE(i_task_request) t)))
                       AND (pea.flg_status_det NOT IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                        column_value
                                                         FROM TABLE(i_filter_status) t) OR
                           ((ipd.flg_status NOT IN
                           (pk_procedures_constant.g_interv_not_ordered, pk_procedures_constant.g_interv_cancel) AND
                           coalesce(ipd.dt_end_tstz, ipd.dt_cancel_tstz) >= i_filter_tstz) OR
                           (ipd.flg_status = pk_procedures_constant.g_interv_not_ordered AND
                           ipd.dt_interv_presc_det >= i_filter_tstz) OR
                           (ipd.flg_status = pk_procedures_constant.g_interv_cancel AND
                           ipd.dt_cancel_tstz >= l_cancelled_task_filter_tstz))))
             ORDER BY rank, TIMESTAMP;
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
        
            IF NOT get_order_plan_report(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_episode       => i_episode,
                                         i_task_request  => i_task_request,
                                         i_cpoe_dt_begin => i_dt_begin,
                                         i_cpoe_dt_end   => i_dt_end,
                                         o_plan_rep      => o_plan_list,
                                         o_error         => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_TASK_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END get_procedure_task_list;

    FUNCTION get_last_order_plan_executed
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_cpoe_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(30 CHAR);
    
    BEGIN
        SELECT pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => z.dt_take_tstz, i_prof => i_prof)
          INTO l_ret
          FROM (SELECT a.dt_take_tstz
                  FROM interv_presc_plan a
                 WHERE a.flg_status = pk_procedures_constant.g_interv_plan_executed
                   AND a.id_interv_presc_det = i_id_interv_presc_det
                   AND a.dt_take_tstz < i_cpoe_dt_end
                 ORDER BY a.dt_take_tstz DESC) z
         WHERE rownum = 1;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_last_order_plan_executed;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_order_plan_rep       t_tbl_order_recurr_plan;
        l_order_plan_rep_union t_tbl_order_recurr_plan := t_tbl_order_recurr_plan();
        l_tbl_interv_presc_det table_number;
        l_tbl_ipd_dt_begin     table_timestamp_tstz;
        l_last_reached         VARCHAR2(20 CHAR);
        l_order_recurrence     order_recurr_plan.id_order_recurr_plan%TYPE;
        l_t_order_recurr       table_number;
        l_cp_begin             TIMESTAMP WITH LOCAL TIME ZONE;
        l_cp_begin_next        TIMESTAMP WITH LOCAL TIME ZONE;
        l_cp_end               TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_status_ipd       interv_presc_det.flg_status%TYPE;
    
        l_interv_presc_plan_last interv_presc_plan.id_interv_presc_plan%TYPE;
        l_interv_presc_plan_next interv_presc_plan.id_interv_presc_plan%TYPE;
    
        l_order_plan_rep_max interv_presc_plan.exec_number%TYPE := NULL;
    BEGIN
    
        IF i_cpoe_dt_begin IS NULL
        THEN
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_episode,
                                                     o_dt_begin_tstz => l_cp_begin,
                                                     o_error         => o_error)
            THEN
                l_cp_begin := current_timestamp;
            END IF;
        ELSE
            l_cp_begin := i_cpoe_dt_begin;
        END IF;
    
        IF i_cpoe_dt_end IS NULL
        THEN
            l_cp_end := pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
        ELSE
            --l_cp_end :=  pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
            l_cp_end := i_cpoe_dt_end;
        END IF;
    
        IF i_task_request IS NOT NULL
        THEN
            l_cp_end := i_cpoe_dt_end;
        
            FOR i IN 1 .. i_task_request.count
            LOOP
            
                BEGIN
                    SELECT a.id_order_recurrence
                      INTO l_order_recurrence
                      FROM interv_presc_det a
                     WHERE a.id_interv_presc_det = i_task_request(i)
                       AND a.flg_status NOT IN
                           (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_interv_draft);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_order_recurrence := NULL;
                END;
            
                IF l_order_recurrence IS NOT NULL
                THEN
                    SELECT t_rec_order_recurr_plan(l_order_recurrence,
                                                   ipp.exec_number,
                                                   nvl(ipp.dt_take_tstz, ipp.dt_plan_tstz))
                      BULK COLLECT
                      INTO l_order_plan_rep
                      FROM interv_presc_plan ipp
                     WHERE ipp.id_interv_presc_det = i_task_request(i)
                       AND ipp.flg_status != pk_procedures_constant.g_interv_cancel
                     ORDER BY ipp.exec_number;
                
                    l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                
                    IF l_order_plan_rep.count > 0
                    THEN
                        l_cp_begin_next := l_order_plan_rep(l_order_plan_rep.count).exec_timestamp;
                    END IF;
                
                    SELECT ipd.flg_status
                      INTO l_flg_status_ipd
                      FROM interv_presc_det ipd
                     WHERE ipd.id_interv_presc_det = i_task_request(i);
                
                    IF l_flg_status_ipd != pk_procedures_constant.g_interv_interrupted
                    THEN
                        IF NOT pk_order_recurrence_core.get_order_recurr_plan(i_lang                   => i_lang,
                                                                              i_prof                   => i_prof,
                                                                              i_order_plan             => l_order_recurrence,
                                                                              i_plan_start_date        => l_cp_begin,
                                                                              i_plan_end_date          => l_cp_end,
                                                                              i_proc_from_day          => l_cp_begin_next,
                                                                              i_proc_from_exec_nr      => NULL,
                                                                              i_flg_validate_proc_from => pk_alert_constant.g_yes,
                                                                              o_order_plan             => l_order_plan_rep,
                                                                              o_last_exec_reached      => l_last_reached,
                                                                              o_error                  => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    
                        l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                    END IF;
                ELSE
                    SELECT t_rec_order_recurr_plan(a.id_interv_presc_det, NULL, a.dt_begin_tstz)
                      BULK COLLECT
                      INTO l_order_plan_rep
                      FROM interv_presc_det a
                     WHERE a.id_interv_presc_det = i_task_request(i)
                       AND a.flg_status NOT IN ('C', 'Z');
                
                    l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                END IF;
            END LOOP;
        
        ELSE
            SELECT nvl(pea.id_order_recurrence, -1), pea.dt_begin_det, pea.id_interv_presc_det
              BULK COLLECT
              INTO l_t_order_recurr, l_tbl_ipd_dt_begin, l_tbl_interv_presc_det
              FROM procedures_ea pea
              LEFT JOIN order_recurr_plan b
                ON pea.id_order_recurrence = b.id_order_recurr_plan
             WHERE pea.id_episode = i_episode
               AND (pea.dt_begin_req BETWEEN l_cp_begin AND l_cp_end OR
                   (pea.dt_begin_req < l_cp_end AND b.flg_end_by = 'W'))
               AND pea.flg_status_req NOT IN
                   (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_interv_draft);
        
            FOR i IN 1 .. l_t_order_recurr.count
            LOOP
            
                IF l_t_order_recurr(i) != -1
                THEN
                    SELECT t_rec_order_recurr_plan(l_t_order_recurr(i),
                                                   ipp.exec_number,
                                                   nvl(ipp.dt_take_tstz, ipp.dt_plan_tstz))
                      BULK COLLECT
                      INTO l_order_plan_rep
                      FROM interv_presc_plan ipp
                     INNER JOIN interv_presc_det ipd
                        ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
                     WHERE ipd.id_order_recurrence = l_t_order_recurr(i)
                       AND ipp.flg_status NOT IN
                           (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_interv_draft)
                     ORDER BY ipp.exec_number;
                
                    l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                
                    SELECT ipd.flg_status
                      INTO l_flg_status_ipd
                      FROM interv_presc_det ipd
                     WHERE ipd.id_order_recurrence = l_t_order_recurr(i);
                
                    IF l_flg_status_ipd NOT IN
                       (pk_procedures_constant.g_interv_interrupted, pk_procedures_constant.g_interv_finished)
                    THEN
                        SELECT MAX(ipp.exec_number)
                          INTO l_order_plan_rep_max
                          FROM interv_presc_plan ipp
                         INNER JOIN interv_presc_det ipd
                            ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
                         WHERE ipd.id_order_recurrence = l_t_order_recurr(i)
                         ORDER BY ipp.exec_number;
                    
                        IF l_order_plan_rep.count > 0
                        THEN
                            l_cp_begin_next := l_order_plan_rep(l_order_plan_rep.count).exec_timestamp;
                        END IF;
                    
                        IF NOT pk_order_recurrence_core.get_order_recurr_plan(i_lang                   => i_lang,
                                                                         i_prof                   => i_prof,
                                                                         i_order_plan             => l_t_order_recurr(i),
                                                                         i_plan_start_date        => l_cp_begin,
                                                                         i_plan_end_date          => l_cp_end,
                                                                         i_proc_from_day          => CASE
                                                                                                         WHEN l_cp_begin_next < l_cp_begin THEN
                                                                                                          l_cp_begin
                                                                                                         ELSE
                                                                                                          l_cp_begin_next
                                                                                                     END,
                                                                         i_proc_from_exec_nr      => l_order_plan_rep_max,
                                                                         i_flg_validate_proc_from => pk_alert_constant.g_yes,
                                                                         o_order_plan             => l_order_plan_rep,
                                                                         o_last_exec_reached      => l_last_reached,
                                                                         o_error                  => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    
                        l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                    END IF;
                ELSE
                    SELECT t_rec_order_recurr_plan(l_tbl_interv_presc_det(i), NULL, l_tbl_ipd_dt_begin(i))
                      BULK COLLECT
                      INTO l_order_plan_rep
                      FROM dual;
                
                    l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                END IF;
            END LOOP;
        END IF;
    
        OPEN o_plan_rep FOR
            SELECT DISTINCT ipd.id_interv_presc_det AS id_presc,
                            pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                        i_date => nvl(ipp.dt_plan_tstz, p.exec_timestamp),
                                                        i_prof => i_prof) AS dt_plan_send_format,
                            pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => ipp.start_time, i_prof => i_prof) AS dt_take_send_format,
                            pk_string_utils.clob_to_varchar2(ed.notes, 1000) notes,
                            'N' out_of_period
              FROM TABLE(l_order_plan_rep_union) p
             INNER JOIN interv_presc_det ipd
                ON p.id_order_recurrence_plan = ipd.id_order_recurrence
              LEFT JOIN interv_presc_plan ipp
                ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
               AND ipp.exec_number = p.exec_number
              LEFT JOIN epis_documentation ed
                ON ed.id_epis_documentation = ipp.id_epis_documentation
             WHERE p.exec_number IS NOT NULL
               AND p.exec_timestamp IS NOT NULL
               AND ipd.flg_status NOT IN
                   (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_interv_draft)
            UNION ALL
            SELECT ipd.id_interv_presc_det AS id_presc,
                   decode(ipd.flg_prn,
                          pk_alert_constant.g_yes,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => ipp.dt_plan_tstz, i_prof => i_prof)) AS dt_plan_send_format,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => ipp.start_time, i_prof => i_prof) AS dt_take_send_format,
                   pk_string_utils.clob_to_varchar2(ed.notes, 1000) notes,
                   'N' out_of_period
              FROM TABLE(l_order_plan_rep_union) p
             INNER JOIN interv_presc_det ipd
                ON p.id_order_recurrence_plan = ipd.id_interv_presc_det
              LEFT JOIN interv_presc_plan ipp
                ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
              LEFT JOIN epis_documentation ed
                ON ed.id_epis_documentation = ipp.id_epis_documentation
             WHERE p.exec_number IS NULL
               AND ipd.flg_status NOT IN
                   (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_interv_draft)
            UNION ALL
            SELECT DISTINCT ipd.id_interv_presc_det id_presc,
                            NULL dt_plan_send_format,
                            get_last_order_plan_executed(i_lang, i_prof, i_episode, ipd.id_interv_presc_det, l_cp_begin) dt_take_send_format,
                            pk_string_utils.clob_to_varchar2(ed.notes, 1000) notes,
                            'Y' out_of_period
              FROM TABLE(l_order_plan_rep_union) p
             INNER JOIN interv_presc_det ipd
                ON p.id_order_recurrence_plan = ipd.id_order_recurrence
             INNER JOIN order_recurr_plan orp
                ON orp.id_order_recurr_plan = ipd.id_order_recurrence
             INNER JOIN interv_presc_plan ipp
                ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
               AND ipp.exec_number = p.exec_number
              LEFT JOIN epis_documentation ed
                ON ed.id_epis_documentation = ipp.id_epis_documentation
             WHERE ipp.dt_take_tstz < l_cp_begin
               AND ipp.dt_take_tstz IS NOT NULL
               AND (orp.flg_end_by IS NULL OR orp.flg_end_by != 'W')
               AND ipd.flg_status NOT IN
                   (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_interv_draft)
            /*AND NOT EXISTS (SELECT 1
             FROM interv_presc_plan z
            WHERE z.id_interv_presc_det = ipd.id_interv_presc_det
              AND z.exec_number > 1)*/
             ORDER BY dt_plan_send_format;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDER_PLAN_REPORT',
                                              o_error);
            pk_types.open_my_cursor(o_plan_rep);
            RETURN FALSE;
        
    END get_order_plan_report;

    FUNCTION get_procedure_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status          interv_presc_det.flg_status%TYPE;
        l_button_cancel       VARCHAR(1 CHAR);
        l_button_confirmation VARCHAR(1 CHAR);
        l_button_edit         VARCHAR(1 CHAR);
        l_button_ok           VARCHAR(1 CHAR);
        l_button_read         VARCHAR(1 CHAR);
    
    BEGIN
    
        g_error := 'GET PROCEDURES_EA';
        SELECT decode(pea.flg_referral,
                      pk_procedures_constant.g_flg_referral_r,
                      pk_procedures_constant.g_interv_cancel,
                      pk_procedures_constant.g_flg_referral_s,
                      pk_procedures_constant.g_interv_cancel,
                      pk_procedures_constant.g_flg_referral_i,
                      pk_procedures_constant.g_interv_cancel,
                      pea.flg_status_det) flg_status,
               pk_procedures_utils.get_procedure_permission(i_lang,
                                                            i_prof,
                                                            pk_procedures_constant.g_interv_area_procedures,
                                                            pk_procedures_constant.g_interv_button_ok,
                                                            pea.id_episode,
                                                            pea.id_interv_presc_det,
                                                            NULL,
                                                            decode(pea.id_episode,
                                                                   i_episode,
                                                                   pk_procedures_constant.g_yes,
                                                                   pk_procedures_constant.g_no)) avail_button_ok,
               pk_procedures_utils.get_procedure_permission(i_lang,
                                                            i_prof,
                                                            pk_procedures_constant.g_interv_area_procedures,
                                                            pk_procedures_constant.g_interv_button_cancel,
                                                            pea.id_episode,
                                                            pea.id_interv_presc_det,
                                                            NULL,
                                                            decode(pea.id_episode,
                                                                   i_episode,
                                                                   pk_procedures_constant.g_yes,
                                                                   pk_procedures_constant.g_no)) avail_button_cancel,
               pk_procedures_utils.get_procedure_permission(i_lang,
                                                            i_prof,
                                                            pk_procedures_constant.g_interv_area_procedures,
                                                            pk_procedures_constant.g_interv_button_edit,
                                                            pea.id_episode,
                                                            pea.id_interv_presc_det,
                                                            NULL,
                                                            decode(pea.id_episode,
                                                                   i_episode,
                                                                   pk_procedures_constant.g_yes,
                                                                   pk_procedures_constant.g_no)) avail_button_edit,
               pk_procedures_utils.get_procedure_permission(i_lang,
                                                            i_prof,
                                                            pk_procedures_constant.g_interv_area_procedures,
                                                            pk_procedures_constant.g_interv_button_confirmation,
                                                            pea.id_episode,
                                                            pea.id_interv_presc_det,
                                                            NULL,
                                                            decode(pea.id_episode,
                                                                   i_episode,
                                                                   pk_procedures_constant.g_yes,
                                                                   pk_procedures_constant.g_no)) avail_button_confirmation
          INTO l_flg_status, l_button_ok, l_button_cancel, l_button_edit, l_button_confirmation
          FROM procedures_ea pea
         WHERE pea.id_interv_presc_det = i_task_request;
    
        g_error := 'OPEN O_ACTION';
        OPEN o_action FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.level_nr "level",
                   a.from_state,
                   a.to_state,
                   a.desc_action,
                   a.icon,
                   a.flg_default,
                   decode(a.flg_active,
                          pk_procedures_constant.g_active,
                          decode(a.action,
                                 'EDIT',
                                 decode(l_button_edit,
                                        pk_procedures_constant.g_yes,
                                        pk_procedures_constant.g_active,
                                        pk_procedures_constant.g_inactive),
                                 'CONFIRM_REQ',
                                 decode(l_button_confirmation,
                                        pk_procedures_constant.g_yes,
                                        pk_procedures_constant.g_active,
                                        pk_procedures_constant.g_inactive),
                                 'PERFORM',
                                 decode(l_button_ok,
                                        pk_procedures_constant.g_yes,
                                        pk_procedures_constant.g_active,
                                        pk_procedures_constant.g_inactive),
                                 'EXECUTE',
                                 decode(l_button_ok,
                                        pk_procedures_constant.g_yes,
                                        pk_procedures_constant.g_active,
                                        pk_procedures_constant.g_inactive),
                                 'CANCEL',
                                 decode(l_button_cancel,
                                        pk_procedures_constant.g_yes,
                                        pk_procedures_constant.g_active,
                                        pk_procedures_constant.g_inactive),
                                 a.flg_active),
                          a.flg_active) flg_status,
                   a.action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, 'PROCEDURES_CPOE', l_flg_status)) a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_action);
            RETURN FALSE;
    END get_procedure_actions;

    FUNCTION get_procedure_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Open cursor o_task_status';
        OPEN o_task_status FOR
            SELECT pk_alert_constant.g_task_type_procedure id_task_type,
                   pea.id_interv_presc_det                 id_task_request,
                   pea.flg_status_det                      flg_status
              FROM procedures_ea pea
             WHERE pea.id_interv_presc_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                column_value
                                                 FROM TABLE(i_task_request) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_task_status);
            RETURN FALSE;
    END get_procedure_status;

    PROCEDURE order_sets_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_req_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN table_number,
        o_interv_presc_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_interv_presc_det FOR
            SELECT /*+opt_estimate(table t rows=1)*/
             d.id_interv_prescription, d.id_interv_presc_det
              FROM interv_presc_det d
              JOIN TABLE(i_task_request) t
                ON d.id_interv_prescription = t.column_value;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_REQ_DET',
                                              o_error);
            RETURN FALSE;
    END get_procedure_req_det;

    FUNCTION get_procedure_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN interv_prescription.id_interv_prescription%TYPE,
        i_task_request_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Fetch alias_translation for id_interv_prescription: ' || i_task_request;
        BEGIN
            SELECT pk_procedures_api_db.get_alias_translation(i_lang,
                                                              i_prof,
                                                              'INTERVENTION.CODE_INTERVENTION.' || ipd.id_intervention,
                                                              NULL)
              INTO o_task_desc
              FROM interv_presc_det ipd
             WHERE ((ipd.id_interv_prescription = i_task_request AND i_task_request_det IS NULL) OR
                   (ipd.id_interv_presc_det = i_task_request_det AND i_task_request IS NULL));
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_procedure_task_title;

    FUNCTION get_procedure_task_instruction
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN interv_prescription.id_interv_prescription%TYPE,
        i_task_request_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT pk_procedures_constant.g_yes,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('PROCEDURES_T091',
                                                        'PROCEDURES_T023',
                                                        'PROCEDURES_T025',
                                                        'PROCEDURES_T130',
                                                        'PROCEDURES_T130',
                                                        'PROCEDURES_T078');
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i)) || ' ';
        END LOOP;
    
        g_error := 'Fetch instructions for interv_prescription: ' || i_task_request;
        BEGIN
            SELECT DISTINCT decode(ipd.flg_prty,
                                   NULL,
                                   NULL,
                                   aa_code_messages('PROCEDURES_T091') ||
                                   pk_sysdomain.get_domain(i_lang,
                                                           i_prof,
                                                           'INTERV_PRESC_DET.FLG_PRTY',
                                                           ipd.flg_prty,
                                                           NULL) || '; ') ||
                            decode(i_flg_showdate,
                                   pk_alert_constant.g_yes,
                                   aa_code_messages('PROCEDURES_T023') ||
                                   decode(ip.flg_time,
                                          pk_procedures_constant.g_flg_time_e,
                                          pk_sysdomain.get_domain(i_lang,
                                                                  i_prof,
                                                                  'INTERV_PRESCRIPTION.FLG_TIME',
                                                                  ip.flg_time,
                                                                  NULL),
                                          pk_procedures_constant.g_flg_time_b,
                                          pk_sysdomain.get_domain(i_lang,
                                                                  i_prof,
                                                                  'INTERV_PRESCRIPTION.FLG_TIME',
                                                                  ip.flg_time,
                                                                  NULL),
                                          pk_sysdomain.get_domain(i_lang,
                                                                  i_prof,
                                                                  'INTERV_PRESCRIPTION.FLG_TIME',
                                                                  ip.flg_time,
                                                                  NULL)) || '; ') ||
                            aa_code_messages('PROCEDURES_T025') ||
                            nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                      i_prof,
                                                                                      ipd.id_order_recurrence),
                                pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) || '; ' ||
                            decode(ipd.flg_prn,
                                   NULL,
                                   NULL,
                                   aa_code_messages('PROCEDURES_T130') ||
                                   pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_PRN', ipd.flg_prn, i_lang) || '; ') ||
                            aa_code_messages('PROCEDURES_T130') ||
                            decode(ipd.id_exec_institution,
                                   NULL,
                                   NULL,
                                   pk_translation.get_translation(i_lang,
                                                                  'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                  ipd.id_exec_institution)) instructions
              INTO o_task_instructions
              FROM interv_presc_det ipd, interv_prescription ip
             WHERE ((ipd.id_interv_prescription = i_task_request AND i_task_request_det IS NULL) OR
                   (ipd.id_interv_presc_det = i_task_request_det AND i_task_request IS NULL))
               AND ipd.id_interv_prescription = ip.id_interv_prescription;
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_TASK_INSTRUCTION',
                                              o_error);
            RETURN FALSE;
    END get_procedure_task_instruction;

    FUNCTION get_procedure_task_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_desc      OUT VARCHAR2,
        o_task_status_desc OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Fetch  pk_procedures_api_db.get_alias_translation for i_interv_presc_det: ' || i_interv_presc_det;
        SELECT pk_procedures_api_db.get_alias_translation(i_lang,
                                                          i_prof,
                                                          'INTERVENTION.CODE_INTERVENTION.' || id_intervention,
                                                          NULL),
               pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det, i_lang)
          INTO o_interv_desc, o_task_status_desc
          FROM procedures_ea pea
         WHERE pea.id_interv_presc_det = i_interv_presc_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_TASK_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END get_procedure_task_description;

    FUNCTION get_procedure_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN interv_presc_det.id_interv_presc_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET STATUS';
        SELECT pea.flg_status_det flg_status,
               pk_utils.get_status_string(i_lang,
                                          i_prof,
                                          pea.status_str,
                                          pea.status_msg,
                                          pea.status_icon,
                                          pea.status_flg) status_string
          INTO o_flg_status, o_status_string
          FROM procedures_ea pea
         WHERE pea.id_interv_presc_det = i_task_request;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_procedure_status;

    FUNCTION get_procedure_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_intervention intervention.id_intervention%TYPE;
    
    BEGIN
    
        g_error := 'GET PREDEFINED PROCEDURE INFO';
        SELECT ipd.id_intervention AS id_intervention
          INTO l_id_intervention
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_prescription = i_task_request
           AND rownum = 1;
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_QUESTIONNAIRE';
        IF NOT pk_procedures_core.get_procedure_questionnaire(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_patient      => i_patient,
                                                              i_episode      => i_episode,
                                                              i_intervention => l_id_intervention,
                                                              i_flg_time     => pk_procedures_constant.g_interv_cq_on_order,
                                                              o_list         => o_list,
                                                              o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_QUESTIONNAIRE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_questionnaire;

    FUNCTION get_procedure_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT ip.id_interv_prescription, ip.dt_begin_tstz, NULL dt_end
              FROM interv_prescription ip
             WHERE ip.id_interv_prescription IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                  *
                                                   FROM TABLE(i_task_request) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_DATE_LIMITS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_date_limits;

    FUNCTION get_procedure_task_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN interv_prescription.id_interv_prescription%TYPE,
        i_task_request_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_id        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Fetch procedure id for id_interv_prescription: ' || i_task_request;
        SELECT ipd.id_intervention
          INTO o_interv_id
          FROM interv_presc_det ipd, interv_prescription ip
         WHERE ((ipd.id_interv_prescription = i_task_request AND i_task_request_det IS NULL) OR
               (ipd.id_interv_presc_det = i_task_request_det AND i_task_request IS NULL))
           AND ipd.id_interv_prescription = ip.id_interv_prescription;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_TASK_ID',
                                              o_error);
            RETURN FALSE;
    END get_procedure_task_id;

    FUNCTION set_procedure_request_task
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_task_request            IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN interv_presc_det.id_cdr_event%TYPE,
        o_interv_presc            OUT table_number,
        o_interv_presc_det        OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_interv_presc IS
            SELECT ip.*
              FROM interv_prescription ip
             WHERE ip.id_interv_prescription IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                  *
                                                   FROM TABLE(i_task_request) t);
    
        CURSOR c_interv_presc_det(in_interv_prescription interv_prescription.id_interv_prescription%TYPE) IS
            SELECT ipd.*
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_prescription = in_interv_prescription;
    
        TYPE t_interv_presc IS TABLE OF c_interv_presc%ROWTYPE;
        t_tbl_interv_presc t_interv_presc;
    
        TYPE t_interv_presc_det IS TABLE OF c_interv_presc_det%ROWTYPE;
        t_tbl_interv_presc_det t_interv_presc_det;
    
        l_interv_order interv_prescription.id_interv_prescription%TYPE;
        l_dt_begin     VARCHAR2(100 CHAR);
        l_codification codification.id_codification%TYPE;
    
        l_count_out_reqs NUMBER := 0;
        l_req_det_idx    NUMBER;
    
        TYPE t_record_interv_presc_map IS TABLE OF NUMBER INDEX BY VARCHAR2(200 CHAR);
        ibt_interv_presc_map t_record_interv_presc_map;
    
        l_all_interv_presc_det table_number := table_number();
    
        l_interv_presc     interv_prescription.id_interv_prescription%TYPE;
        l_interv_presc_det interv_presc_det.id_interv_presc_det%TYPE;
    
        l_order_recurrence_option order_recurr_plan.id_order_recurr_option%TYPE;
    
        l_order_recurrence order_recurr_plan.id_order_recurr_plan%TYPE;
    
        l_order_recurr_final_array table_number := table_number();
    
        l_tbl_supply     table_number;
        l_tbl_supply_set table_number;
        l_tbl_quantity   table_number;
        l_dt_return      table_varchar := table_varchar();
        l_tbl_supply_loc table_number;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        o_interv_presc     := table_number();
        o_interv_presc_det := table_table_number();
    
        g_error := 'OPEN C_INTERV_PRESC';
        OPEN c_interv_presc;
        FETCH c_interv_presc BULK COLLECT
            INTO t_tbl_interv_presc;
        CLOSE c_interv_presc;
    
        FOR i IN 1 .. t_tbl_interv_presc.count
        LOOP
            OPEN c_interv_presc_det(t_tbl_interv_presc(i).id_interv_prescription);
            FETCH c_interv_presc_det BULK COLLECT
                INTO t_tbl_interv_presc_det;
            CLOSE c_interv_presc_det;
        
            o_interv_presc_det.extend;
            o_interv_presc_det(o_interv_presc_det.count) := table_number();
            --            raise_Application_error(-20001, 'teste');
            -- creating interv_presc_det;
            FOR j IN 1 .. t_tbl_interv_presc_det.count
            LOOP
                BEGIN
                    SELECT sw.id_supply, sw.id_supply_set, 1, sw.id_supply_location
                      BULK COLLECT
                      INTO l_tbl_supply, l_tbl_supply_set, l_tbl_quantity, l_tbl_supply_loc
                      FROM supply_workflow sw
                     WHERE sw.id_context = t_tbl_interv_presc_det(i).id_interv_presc_det
                       AND sw.flg_context = pk_supplies_constant.g_context_procedure_req;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_tbl_supply     := table_number();
                        l_tbl_supply_set := table_number();
                        l_tbl_quantity   := table_number();
                END;
            
                FOR i IN 1 .. l_tbl_supply.count
                LOOP
                    l_dt_return.extend;
                    l_dt_return(i) := NULL;
                END LOOP;
            
                IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                        i_prof                    => i_prof,
                                                                        i_order_recurr_plan       => t_tbl_interv_presc_det(j).id_order_recurrence,
                                                                        o_order_recurr_option     => l_order_recurrence_option,
                                                                        o_final_order_recurr_plan => l_order_recurrence,
                                                                        o_error                   => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                IF pk_date_utils.date_send_tsz(i_lang, t_tbl_interv_presc(i).dt_begin_tstz, i_prof) < g_sysdate_char
                THEN
                    l_dt_begin := g_sysdate_char;
                ELSE
                    l_dt_begin := pk_date_utils.date_send_tsz(i_lang, t_tbl_interv_presc(i).dt_begin_tstz, i_prof);
                END IF;
            
                IF l_interv_presc IS NULL
                THEN
                    l_interv_presc := ts_interv_prescription.next_key();
                ELSE
                    BEGIN
                        g_error := 'GET L_INTERV_ORDER 1';
                        SELECT i.id_interv_prescription
                          INTO l_interv_order
                          FROM (SELECT ipd.id_interv_prescription,
                                       CASE
                                            WHEN ipd.dt_begin < g_sysdate_char THEN
                                             g_sysdate_char
                                            ELSE
                                             ipd.dt_begin
                                        END dt_begin
                                  FROM (SELECT ip.id_interv_prescription,
                                               pk_date_utils.trunc_insttimezone_str(i_prof, ip.dt_begin_tstz, 'MI') dt_begin
                                          FROM interv_presc_det ipd, interv_prescription ip
                                         WHERE ipd.id_interv_presc_det IN
                                               (SELECT /*+opt_estimate (table t rows=1)*/
                                                 *
                                                  FROM TABLE(l_all_interv_presc_det) t)
                                           AND ipd.id_interv_prescription = ip.id_interv_prescription
                                           AND ip.flg_time = t_tbl_interv_presc(i).flg_time
                                           AND ipd.flg_prty = t_tbl_interv_presc_det(j).flg_prty
                                           AND (ipd.id_exec_institution = t_tbl_interv_presc_det(j).id_exec_institution OR
                                               (ipd.id_exec_institution IS NULL AND t_tbl_interv_presc_det(j).id_exec_institution IS NULL))) ipd) i
                         WHERE (i.dt_begin = l_dt_begin OR
                               (l_dt_begin IS NULL AND t_tbl_interv_presc(i)
                               .flg_time NOT IN
                               (pk_procedures_constant.g_flg_time_e, pk_procedures_constant.g_flg_time_b)))
                           AND rownum = 1;
                    
                        IF t_tbl_interv_presc(i).flg_time != pk_procedures_constant.g_flg_time_b
                        THEN
                            l_interv_presc := l_interv_order;
                        END IF;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_interv_presc := ts_interv_prescription.next_key();
                    END;
                END IF;
            
                BEGIN
                    SELECT ic.id_codification
                      INTO l_codification
                      FROM interv_codification ic
                     WHERE ic.id_interv_codification = t_tbl_interv_presc_det(j).id_interv_codification;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_codification := NULL;
                END;
            
                g_error := 'CALL PK_PROCEDURES_CORE.CREATE_PROCEDURE_REQUEST';
                IF NOT pk_procedures_core.create_procedure_request(i_lang                    => i_lang,
                                                                   i_prof                    => i_prof,
                                                                   i_patient                 => t_tbl_interv_presc(i).id_patient,
                                                                   i_episode                 => t_tbl_interv_presc(i).id_episode,
                                                                   i_interv_prescription     => l_interv_presc,
                                                                   i_intervention            => t_tbl_interv_presc_det(j).id_intervention,
                                                                   i_flg_time                => t_tbl_interv_presc(i).flg_time,
                                                                   i_dt_begin                => l_dt_begin,
                                                                   i_episode_destination     => t_tbl_interv_presc(i).id_episode_destination,
                                                                   i_order_recurrence        => l_order_recurrence,
                                                                   i_diagnosis_notes         => t_tbl_interv_presc_det(j).diagnosis_notes,
                                                                   i_diagnosis               => NULL,
                                                                   i_clinical_purpose        => t_tbl_interv_presc_det(j).id_clinical_purpose,
                                                                   i_clinical_purpose_notes  => t_tbl_interv_presc_det(j).clinical_purpose_notes,
                                                                   i_laterality              => t_tbl_interv_presc_det(j).flg_laterality,
                                                                   i_priority                => t_tbl_interv_presc_det(j).flg_prty,
                                                                   i_flg_prn                 => t_tbl_interv_presc_det(j).flg_prn,
                                                                   i_notes_prn               => t_tbl_interv_presc_det(j).prn_notes,
                                                                   i_exec_institution        => t_tbl_interv_presc_det(j).id_exec_institution,
                                                                   i_flg_location            => t_tbl_interv_presc_det(j).flg_location,
                                                                   i_supply                  => l_tbl_supply,
                                                                   i_supply_set              => l_tbl_supply_set,
                                                                   i_supply_qty              => l_tbl_quantity,
                                                                   i_dt_return               => l_dt_return,
                                                                   i_supply_loc              => l_tbl_supply_loc,
                                                                   i_not_order_reason        => t_tbl_interv_presc_det(j).id_not_order_reason,
                                                                   i_notes                   => t_tbl_interv_presc_det(j).notes,
                                                                   i_prof_order              => i_prof_order(i),
                                                                   i_dt_order                => i_dt_order(i),
                                                                   i_order_type              => i_order_type(i),
                                                                   i_codification            => l_codification,
                                                                   i_health_plan             => t_tbl_interv_presc_det(j).id_pat_health_plan,
                                                                   i_exemption               => t_tbl_interv_presc_det(j).id_pat_exemption,
                                                                   i_clinical_question       => i_clinical_question(i),
                                                                   i_response                => i_response(i),
                                                                   i_clinical_question_notes => i_clinical_question_notes(i),
                                                                   i_clinical_decision_rule  => i_clinical_decision_rule,
                                                                   o_interv_presc            => l_interv_presc,
                                                                   o_interv_presc_det        => l_interv_presc_det,
                                                                   o_error                   => o_error)
                THEN
                    IF o_error.err_desc IS NOT NULL
                    THEN
                        g_error_code := o_error.ora_sqlcode;
                        g_error      := o_error.ora_sqlerrm;
                    
                        RAISE g_user_exception;
                    ELSE
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                -- check if interv_presc not exists
                IF NOT ibt_interv_presc_map.exists(to_char(l_interv_presc))
                THEN
                    o_interv_presc.extend;
                    l_count_out_reqs := l_count_out_reqs + 1;
                
                    -- set mapping between interv_presc and its position in the output array
                    ibt_interv_presc_map(to_char(l_interv_presc)) := l_count_out_reqs;
                
                    -- set interv_presc output 
                    o_interv_presc(l_count_out_reqs) := l_interv_presc;
                END IF;
            
                --raise_application_error(-20001, 'Teste - ' || t_tbl_interv_presc_det(j).id_order_recurrence);
                IF l_order_recurrence IS NOT NULL
                THEN
                    l_order_recurr_final_array.extend;
                    l_order_recurr_final_array(1) := t_tbl_interv_presc_det(j).id_order_recurrence;
                
                    g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.PREPARE_ORDER_RECURR_PLAN';
                    IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang       => i_lang,
                                                                                i_prof       => i_prof,
                                                                                i_order_plan => l_order_recurr_final_array,
                                                                                o_error      => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                -- append req det of this procedure request to all req dets array
                l_all_interv_presc_det.extend;
                l_all_interv_presc_det(l_all_interv_presc_det.count) := l_interv_presc_det;
            
                l_req_det_idx := o_interv_presc_det.count;
                o_interv_presc_det(l_req_det_idx).extend;
                o_interv_presc_det(l_req_det_idx)(o_interv_presc_det(l_req_det_idx).count) := l_interv_presc_det;
            END LOOP;
        END LOOP;
    
        FOR i IN 1 .. l_all_interv_presc_det.count
        LOOP
            g_error := 'UPDATE INTERV_PRESC_DET';
            ts_interv_presc_det.upd(id_interv_presc_det_in   => l_all_interv_presc_det(i),
                                    flg_req_origin_module_in => pk_alert_constant.g_task_origin_order_set,
                                    rows_out                 => l_rows_out);
        END LOOP;
    
        g_error := 'CALL TO PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'INTERV_PRESC_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_DELETE_TASK';
        IF NOT pk_procedures_external.set_procedure_delete_task(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_task_request => i_task_request,
                                                                o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROCEDURE_REQUEST_TASK',
                                              o_error);
            RETURN FALSE;
    END set_procedure_request_task;

    FUNCTION set_procedure_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_interv_presc OUT interv_prescription.id_interv_prescription%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_presc     interv_prescription%ROWTYPE;
        l_interv_presc_det interv_presc_det%ROWTYPE;
    
        l_rows_out     table_varchar := table_varchar();
        l_rows_req_out table_varchar := table_varchar();
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc       VARCHAR2(1000 CHAR);
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
        l_flg_time VARCHAR2(1 CHAR);
        error_unexpected EXCEPTION;
    
        l_tbl_supply table_number;
    
        l_tbl_supply_set table_number;
        l_tbl_quantity   table_number;
    
        l_supply_request supply_request.id_supply_request%TYPE;
    
        l_dt_request table_varchar := table_varchar();
        l_dt_return  table_varchar := table_varchar();
    
        -- function that returns the default value for "to be performed" field
        FUNCTION get_default_flg_time
        (
            i_lang  IN language.id_language%TYPE,
            i_prof  IN profissional,
            o_error OUT t_error_out
        ) RETURN VARCHAR2 IS
            l_epis_type   epis_type.id_epis_type%TYPE := pk_episode.get_epis_type(i_lang    => i_lang,
                                                                                  i_id_epis => i_episode);
            c_data        pk_types.cursor_type;
            l_val         sys_domain.val%TYPE;
            l_rank        NUMBER;
            l_desc_val    sys_domain.desc_val%TYPE;
            l_flg_default VARCHAR2(1 CHAR);
        BEGIN
            -- gets default value for "to be performed" field
            IF NOT pk_procedures_core.get_procedure_time_list(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_epis_type => l_epis_type,
                                                              o_list      => c_data,
                                                              o_error     => o_error)
            THEN
                RAISE error_unexpected;
            END IF;
        
            -- loop until fetch default value
            LOOP
                FETCH c_data
                    INTO l_val, l_rank, l_desc_val, l_flg_default;
            
                EXIT WHEN l_flg_default = pk_procedures_constant.g_yes OR c_data%NOTFOUND;
            
            END LOOP;
            CLOSE c_data;
        
            RETURN l_val;
        END;
    
    BEGIN
    
        g_error := 'GET INTERV_PRESCRIPTION';
        SELECT ip.*
          INTO l_interv_presc
          FROM interv_prescription ip
         WHERE ip.id_interv_prescription = i_task_request;
    
        l_interv_presc.id_interv_prescription := ts_interv_prescription.next_key();
        l_interv_presc.dt_begin_tstz          := current_timestamp;
    
        -- gets default value for "to be performed" field
        l_flg_time := get_default_flg_time(i_lang => i_lang, i_prof => i_prof, o_error => o_error);
    
        --Duplicate row to interv_prescription
        g_error := 'INSERT INTERV_PRESCRIPTION';
        ts_interv_prescription.ins(rec_in => l_interv_presc, gen_pky_in => FALSE, rows_out => l_rows_req_out);
    
        IF i_patient IS NOT NULL
           AND i_episode IS NOT NULL
        THEN
            ts_interv_prescription.upd(id_interv_prescription_in => l_interv_presc.id_interv_prescription,
                                       id_patient_in             => i_patient,
                                       id_episode_in             => i_episode,
                                       flg_time_in               => l_flg_time,
                                       rows_out                  => l_rows_req_out);
        END IF;
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'INTERV_PRESCRIPTION',
                                      i_rowids     => l_rows_req_out,
                                      o_error      => o_error);
    
        l_rows_out     := NULL;
        l_rows_req_out := NULL;
    
        FOR rec IN (SELECT ipd.id_interv_presc_det
                      FROM interv_presc_det ipd
                     WHERE ipd.id_interv_prescription = i_task_request)
        LOOP
            g_error := 'GET INTERV_PRESC_DET';
            SELECT ipd.*
              INTO l_interv_presc_det
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_presc_det = rec.id_interv_presc_det;
        
            BEGIN
                SELECT sw.id_supply, sw.id_supply_set, sw.quantity
                  BULK COLLECT
                  INTO l_tbl_supply, l_tbl_supply_set, l_tbl_quantity
                  FROM supply_workflow sw
                 WHERE sw.id_context = l_interv_presc_det.id_interv_presc_det
                   AND sw.flg_context = pk_supplies_constant.g_context_procedure_req;
            EXCEPTION
                WHEN OTHERS THEN
                    l_tbl_supply     := table_number();
                    l_tbl_supply_set := table_number();
                    l_tbl_quantity   := table_number();
            END;
        
            -- check if this interv_presc_det has an order recurrence plan
            IF l_interv_presc_det.id_order_recurrence IS NOT NULL
            THEN
            
                -- copy order recurrence plan
                g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.COPY_FROM_ORDER_RECURR_PLAN';
                IF NOT pk_order_recurrence_api_db.copy_from_order_recurr_plan(i_lang                   => i_lang,
                                                                              i_prof                   => i_prof,
                                                                              i_order_recurr_area      => NULL,
                                                                              i_order_recurr_plan_from => l_interv_presc_det.id_order_recurrence,
                                                                              i_flg_force_temp_plan    => pk_alert_constant.g_no,
                                                                              o_order_recurr_desc      => l_order_recurr_desc,
                                                                              o_order_recurr_option    => l_order_recurr_option,
                                                                              o_start_date             => l_start_date,
                                                                              o_occurrences            => l_occurrences,
                                                                              o_duration               => l_duration,
                                                                              o_unit_meas_duration     => l_unit_meas_duration,
                                                                              o_duration_desc          => l_duration_desc,
                                                                              o_end_date               => l_end_date,
                                                                              o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                              o_order_recurr_plan      => l_interv_presc_det.id_order_recurrence,
                                                                              o_error                  => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
            ELSE
                l_start_date := current_timestamp;
            END IF;
        
            -- update start dates (according to order recurr plan)
            l_interv_presc.dt_begin_tstz := l_start_date;
        
            ts_interv_prescription.upd(id_interv_prescription_in => l_interv_presc.id_interv_prescription,
                                       dt_begin_tstz_in          => l_interv_presc.dt_begin_tstz,
                                       rows_out                  => l_rows_req_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'INTERV_PRESCRIPTION',
                                          i_rowids     => l_rows_req_out,
                                          o_error      => o_error);
        
            l_interv_presc_det.id_interv_prescription := l_interv_presc.id_interv_prescription;
            l_interv_presc_det.id_interv_presc_det    := ts_interv_presc_det.next_key();
        
            --Duplicate row to interv_presc_det
            g_error := 'INSERT INTERV_PRESC_DET';
            ts_interv_presc_det.ins(rec_in => l_interv_presc_det, rows_out => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'INTERV_PRESC_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            IF l_tbl_supply.count > 0
            THEN
            
                FOR i IN 1 .. l_tbl_supply.count
                LOOP
                    l_dt_request.extend;
                    l_dt_request(i) := NULL;
                    l_dt_return.extend;
                    l_dt_return(i) := NULL;
                END LOOP;
                IF NOT pk_supplies_api_db.create_supply_order(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_episode           => i_episode,
                                                              i_supply            => l_tbl_supply,
                                                              i_supply_set        => l_tbl_supply_set,
                                                              i_supply_qty        => l_tbl_quantity,
                                                              i_dt_request        => l_dt_request,
                                                              i_dt_return         => l_dt_return,
                                                              i_id_context        => l_interv_presc_det.id_interv_presc_det,
                                                              i_flg_context       => pk_supplies_constant.g_context_procedure_req,
                                                              i_supply_flg_status => pk_supplies_constant.g_sww_predefined,
                                                              o_supply_request    => l_supply_request,
                                                              o_error             => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END LOOP;
    
        o_interv_presc := l_interv_presc.id_interv_prescription;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROCEDURE_COPY_TASK',
                                              o_error);
            RETURN FALSE;
    END set_procedure_copy_task;

    FUNCTION set_procedure_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_presc_det table_number := table_number();
    
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
            SELECT ipd.id_interv_presc_det
              BULK COLLECT
              INTO l_interv_presc_det
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_prescription = i_task_request(i);
        
            g_error := 'DELETE INTERV_PRESC_PLAN_HIST';
            DELETE interv_presc_plan_hist
             WHERE id_interv_presc_det IN (SELECT /*+opt_estimate(table t rows=1)*/
                                            *
                                             FROM TABLE(l_interv_presc_det) t);
        
            g_error := 'DELETE INTERV_PRESC_PLAN';
            DELETE interv_presc_plan
             WHERE id_interv_presc_det IN (SELECT /*+opt_estimate(table t rows=1)*/
                                            *
                                             FROM TABLE(l_interv_presc_det) t);
        
            g_error := 'DELETE INTERV_PRESC_DET_HIST';
            DELETE interv_presc_det_hist
             WHERE id_interv_prescription = i_task_request(i);
        
            g_error := 'DELETE INTERV_PRESC_DET';
            ts_interv_presc_det.del_by(where_clause_in => 'id_interv_prescription = ' || i_task_request(i));
        
            g_error := 'DELETE INTERV_PRESCRIPTION';
            ts_interv_prescription.del(id_interv_prescription_in => i_task_request(i));
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROCEDURE_DELETE_TASK',
                                              o_error);
            RETURN FALSE;
    END set_procedure_delete_task;

    FUNCTION set_procedure_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_presc_det table_number;
    
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
        
            SELECT ipd.id_interv_presc_det
              BULK COLLECT
              INTO l_interv_presc_det
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_prescription = i_task_request(i);
        
            -- loop through all req dets
            FOR j IN 1 .. l_interv_presc_det.count
            LOOP
            
                g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAG_NO_COMMIT';
                IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_epis             => i_episode,
                                                                i_diag             => i_diagnosis,
                                                                i_exam_req         => NULL,
                                                                i_analysis_req     => NULL,
                                                                i_interv_presc     => i_task_request(i),
                                                                i_exam_req_det     => NULL,
                                                                i_analysis_req_det => NULL,
                                                                i_interv_presc_det => l_interv_presc_det(j),
                                                                o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
            END LOOP;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROCEDURE_DIAGNOSIS',
                                              o_error);
            RETURN FALSE;
    END set_procedure_diagnosis;

    FUNCTION set_procedure_execute_time
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROCEDURE_EXECUTE_TIME',
                                              o_error);
            RETURN FALSE;
    END set_procedure_execute_time;

    FUNCTION check_procedure_mandatory
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_check table_varchar;
    
        l_clinical_purpose sys_config.value%TYPE;
    
    BEGIN
    
        l_clinical_purpose := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_P', i_prof);
    
        g_error := 'Fetch instructions for i_interv_prescription: ' || i_task_request;
        SELECT decode(ipd.flg_prty,
                      NULL,
                      pk_procedures_constant.g_no,
                      decode(ip.flg_time,
                             NULL,
                             pk_procedures_constant.g_no,
                             decode(l_clinical_purpose,
                                    pk_procedures_constant.g_yes,
                                    decode(ipd.id_clinical_purpose,
                                           NULL,
                                           pk_procedures_constant.g_no,
                                           pk_procedures_constant.g_yes),
                                    pk_procedures_constant.g_yes)))
          BULK COLLECT
          INTO l_tbl_check
          FROM interv_prescription ip, interv_presc_det ipd
         WHERE ip.id_interv_prescription = i_task_request
           AND ip.id_interv_prescription = ipd.id_interv_prescription;
    
        -- check if there's no req dets with mandatory fields empty
        FOR i IN 1 .. l_tbl_check.count
        LOOP
            IF l_tbl_check(i) = pk_procedures_constant.g_no
            THEN
                o_check := pk_procedures_constant.g_no;
            
                RETURN TRUE;
            END IF;
        END LOOP;
    
        -- all mandatory fields have a value
        o_check := pk_procedures_constant.g_yes;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PROCEDURE_MANDATORY',
                                              o_error);
            RETURN FALSE;
    END check_procedure_mandatory;

    FUNCTION check_procedure_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_flg_conflict := pk_procedures_constant.g_no;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PROCEDURE_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_procedure_conflict;

    FUNCTION check_procedure_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN interv_presc_det.id_interv_presc_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error      := 'CALL PK_PROCEDURES_UTILS.GET_PROCEDURE_PERMISSION';
        o_flg_cancel := pk_procedures_utils.get_procedure_permission(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_area                => pk_procedures_constant.g_interv_area_procedures,
                                                                     i_button              => pk_procedures_constant.g_interv_button_cancel,
                                                                     i_episode             => i_episode,
                                                                     i_interv_presc_det    => i_task_request,
                                                                     i_interv_presc_plan   => NULL,
                                                                     i_flg_current_episode => pk_procedures_constant.g_yes);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PROCEDURE_CANCEL',
                                              o_error);
            RETURN FALSE;
    END check_procedure_cancel;

    FUNCTION cancel_procedure_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_dt_cancel        IN VARCHAR2,
        i_cancel_reason    IN exam_req_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN exam_req_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_API_DB.CANCEL_PROCEDURE_REQUEST';
        IF NOT pk_procedures_api_db.cancel_procedure_request(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_interv_presc_det => i_interv_presc_det,
                                                             i_dt_cancel        => i_dt_cancel,
                                                             i_cancel_reason    => i_cancel_reason,
                                                             i_cancel_notes     => i_cancel_notes,
                                                             i_prof_order       => NULL,
                                                             i_dt_order         => NULL,
                                                             i_order_type       => NULL,
                                                             i_flg_cancel_event => i_flg_cancel_event,
                                                             o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PROCEDURE_TASK',
                                              o_error);
            RETURN FALSE;
    END cancel_procedure_task;

    PROCEDURE tde_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_ongoing_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
    
        CURSOR c_visit IS
            SELECT v.id_visit, e.id_epis_type
              FROM episode e, visit v
             WHERE v.id_patient = i_patient
               AND v.id_visit = e.id_visit
               AND e.flg_status = pk_alert_constant.g_flg_status_a;
    
        l_tasks_list tf_tasks_list;
    
    BEGIN
    
        g_error := 'OPEN C_VISIT';
        OPEN c_visit;
    
        g_error := 'get_ongoing_tasks_procedures for id_patient=' || i_patient;
        SELECT tr_tasks_list(pea.id_interv_presc_det,
                             pk_translation.get_translation(i_lang, i.code_intervention),
                             pk_translation.get_translation(i_lang, et.code_epis_type),
                             pk_date_utils.dt_chr_date_hour_tsz(i_lang, pea.dt_interv_prescription, i_prof))
          BULK COLLECT
          INTO l_tasks_list
          FROM procedures_ea pea
          JOIN intervention i
            ON i.id_intervention = pea.id_intervention
          JOIN episode e
            ON e.id_episode = nvl(pea.id_episode, pea.id_episode_origin)
          JOIN epis_type et
            ON et.id_epis_type = e.id_epis_type
         WHERE pea.id_patient = i_patient
           AND pea.flg_status_det NOT IN (pk_procedures_constant.g_interv_interrupted,
                                          pk_procedures_constant.g_interv_finished,
                                          pk_procedures_constant.g_interv_exterior)
         ORDER BY pea.dt_interv_prescription DESC;
    
        RETURN l_tasks_list;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_tasks_list;
    END get_procedure_ongoing_tasks;

    FUNCTION suspend_procedure_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_reason       IN VARCHAR2,
        o_msg_error        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_notes_cancel sys_message.desc_message%TYPE;
    
        l_interv_desc pk_translation.t_desc_translation;
    
    BEGIN
    
        l_notes_cancel := pk_message.get_message(i_lang, i_prof, 'PATIENT_DEATH_M001');
    
        g_error := 'suspend_task_procedures for id_interv_presc_det=' || i_interv_presc_det;
        IF NOT pk_procedures_api_db.cancel_procedure_request(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_interv_presc_det => table_number(i_interv_presc_det),
                                                             i_dt_cancel        => NULL,
                                                             i_cancel_reason    => NULL,
                                                             i_cancel_notes     => l_notes_cancel,
                                                             i_prof_order       => NULL,
                                                             i_dt_order         => NULL,
                                                             i_order_type       => NULL,
                                                             o_error            => o_error)
        THEN
            SELECT pk_procedures_api_db.get_alias_translation(i_lang,
                                                              i_prof,
                                                              'INTERVENTION.CODE_INTERVENTION.' || ipd.id_intervention,
                                                              NULL)
              INTO l_interv_desc
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_presc_det = i_interv_presc_det;
        
            -- N?foi poss?l suspender o procedimento
            g_error     := 'get intervention description';
            o_msg_error := REPLACE(pk_message.get_message(i_lang, 'PROCEDURES_M010'), '@1', l_interv_desc);
        
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SUSPEND_PROCEDURE_TASK',
                                              o_error);
            RETURN FALSE;
    END suspend_procedure_task;

    FUNCTION reactivate_procedure_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_msg_error        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_desc pk_translation.t_desc_translation;
    
    BEGIN
    
        SELECT pk_procedures_api_db.get_alias_translation(i_lang,
                                                          i_prof,
                                                          'INTERVENTION.CODE_INTERVENTION.' || ipd.id_intervention,
                                                          NULL)
          INTO l_interv_desc
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_presc_det = i_interv_presc_det;
    
        -- N?foi poss?l reactivar o procedimento
        g_error     := 'NOT IMPLEMENTED';
        o_msg_error := REPLACE(pk_message.get_message(i_lang, 'PROCEDURES_M009'), '@1', l_interv_desc);
    
        RETURN FALSE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'REACTIVATE_PROCEDURE_TASK',
                                              o_error);
            RETURN FALSE;
    END reactivate_procedure_task;

    PROCEDURE medication_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_procedure_with_medication
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_intervention IN table_number,
        i_flg_time     IN interv_prescription.flg_time%TYPE,
        i_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_medication   IN NUMBER,
        i_notes        IN CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_time                table_varchar := table_varchar();
        l_dt_begin                table_varchar := table_varchar();
        l_episode_destination     table_number := table_number();
        l_order_recurrence        table_number := table_number();
        l_priority                table_varchar := table_varchar();
        l_flg_prn                 table_varchar := table_varchar();
        l_notes_prn               table_varchar := table_varchar();
        l_notes                   table_varchar := table_varchar();
        l_laterality              table_varchar := table_varchar();
        l_exec_institution        table_number := table_number();
        l_supply                  table_table_number := table_table_number();
        l_supply_set              table_table_number := table_table_number();
        l_supply_qty              table_table_number := table_table_number();
        l_dt_return               table_table_varchar := table_table_varchar();
        l_supply_soft_inst        table_table_number := table_table_number();
        l_not_order_reason        table_number := table_number();
        l_clinical_purpose        table_number := table_number();
        l_clinical_purpose_notes  table_varchar := table_varchar();
        l_codification            table_number := table_number();
        l_health_plan             table_number := table_number();
        l_exemption               table_number := table_number();
        l_prof_order              table_number := table_number();
        l_dt_order                table_varchar := table_varchar();
        l_order_type              table_number := table_number();
        l_clinical_question       table_table_number := table_table_number();
        l_response                table_table_varchar := table_table_varchar();
        l_clinical_question_notes table_table_varchar := table_table_varchar();
        l_clinical_decision_rule  table_number := table_number();
    
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg_title VARCHAR2(1 CHAR);
        l_msg_req   VARCHAR2(1 CHAR);
    
        l_interv_presc_det_array table_number := table_number();
        l_interv_presc_array     table_number := table_number();
    
        l_tbl_interv_presc_plan ts_interv_presc_plan.interv_presc_plan_tc;
    
        l_interv_presc_plan interv_presc_plan.id_interv_presc_plan%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_intervention.count > 0
           AND i_medication IS NOT NULL
        THEN
            FOR i IN 1 .. i_intervention.count
            LOOP
                l_flg_time.extend;
                l_dt_begin.extend;
                l_episode_destination.extend;
                l_order_recurrence.extend;
                l_priority.extend;
                l_flg_prn.extend;
                l_notes_prn.extend;
                l_notes.extend;
                l_laterality.extend;
                l_exec_institution.extend;
                l_supply.extend;
                l_supply_set.extend;
                l_supply_qty.extend;
                l_dt_return.extend;
                l_supply_soft_inst.extend;
                l_not_order_reason.extend;
                l_clinical_purpose.extend;
                l_clinical_purpose_notes.extend;
                l_codification.extend;
                l_health_plan.extend;
                l_exemption.extend;
                l_prof_order.extend;
                l_dt_order.extend;
                l_order_type.extend;
                l_clinical_question.extend;
                l_response.extend;
                l_clinical_question_notes.extend;
                l_clinical_decision_rule.extend;
            
                l_flg_time(l_flg_time.last) := i_flg_time;
                l_dt_begin(l_dt_begin.last) := pk_date_utils.date_send_tsz(i_lang,
                                                                           nvl(i_dt_begin, g_sysdate_tstz),
                                                                           i_prof);
                l_episode_destination(l_episode_destination.last) := NULL;
                l_order_recurrence(l_order_recurrence.last) := NULL;
                l_priority(l_priority.last) := NULL;
                l_flg_prn(l_flg_prn.last) := NULL;
                l_notes_prn(l_notes_prn.last) := NULL;
                l_notes(l_notes.last) := i_notes;
                l_laterality(l_laterality.last) := NULL;
                l_exec_institution(l_exec_institution.last) := i_prof.institution;
                l_supply(l_supply.last) := table_number();
                l_supply_set(l_supply_set.last) := table_number();
                l_supply_qty(l_supply_qty.last) := table_number();
                l_dt_return(l_dt_return.last) := table_varchar();
                l_supply_soft_inst(l_supply_soft_inst.last) := table_number();
                l_not_order_reason(l_not_order_reason.last) := NULL;
                l_clinical_purpose(l_clinical_purpose.last) := NULL;
                l_clinical_purpose_notes(l_clinical_purpose_notes.last) := NULL;
                l_codification(l_codification.last) := NULL;
                l_health_plan(l_health_plan.last) := NULL;
                l_exemption(l_exemption.last) := NULL;
                l_prof_order(l_prof_order.last) := NULL;
                l_dt_order(l_dt_order.last) := NULL;
                l_order_type(l_order_type.last) := NULL;
                l_clinical_question(l_clinical_question.last) := table_number();
                l_response(l_response.last) := table_varchar();
                l_clinical_question_notes(l_clinical_question_notes.last) := table_varchar();
            
            END LOOP;
        
            g_error := 'CALL PK_PROCEDURES_API_DB.CREATE_PROCEDURE_ORDER';
            IF NOT pk_procedures_api_db.create_procedure_order(i_lang                    => i_lang,
                                                               i_prof                    => i_prof,
                                                               i_patient                 => i_patient,
                                                               i_episode                 => i_episode,
                                                               i_intervention            => i_intervention,
                                                               i_flg_time                => l_flg_time,
                                                               i_dt_begin                => l_dt_begin,
                                                               i_episode_destination     => l_episode_destination,
                                                               i_order_recurrence        => l_order_recurrence,
                                                               i_diagnosis               => NULL,
                                                               i_clinical_purpose        => l_clinical_purpose,
                                                               i_clinical_purpose_notes  => l_clinical_purpose_notes,
                                                               i_laterality              => l_laterality,
                                                               i_priority                => l_priority,
                                                               i_flg_prn                 => l_flg_prn,
                                                               i_notes_prn               => l_notes_prn,
                                                               i_exec_institution        => l_exec_institution,
                                                               i_supply                  => l_supply,
                                                               i_supply_set              => l_supply_set,
                                                               i_supply_qty              => l_supply_qty,
                                                               i_dt_return               => l_dt_return,
                                                               i_not_order_reason        => l_not_order_reason,
                                                               i_notes                   => l_notes,
                                                               i_prof_order              => l_prof_order,
                                                               i_dt_order                => l_dt_order,
                                                               i_order_type              => l_order_type,
                                                               i_codification            => l_codification,
                                                               i_health_plan             => l_health_plan,
                                                               i_exemption               => l_exemption,
                                                               i_clinical_question       => l_clinical_question,
                                                               i_response                => l_response,
                                                               i_clinical_question_notes => l_clinical_question_notes,
                                                               i_clinical_decision_rule  => l_clinical_decision_rule,
                                                               i_flg_origin_req          => 'M',
                                                               i_test                    => pk_procedures_constant.g_no,
                                                               o_flg_show                => l_flg_show,
                                                               o_msg_title               => l_msg_title,
                                                               o_msg_req                 => l_msg_req,
                                                               o_interv_presc_array      => l_interv_presc_array,
                                                               o_interv_presc_det_array  => l_interv_presc_det_array,
                                                               o_error                   => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            FOR i IN 1 .. l_interv_presc_det_array.count
            LOOP
                ts_interv_presc_det.upd(id_interv_presc_det_in => l_interv_presc_det_array(i),
                                        id_presc_plan_task_in  => i_medication);
            END LOOP;
        
            -- Get a list of planned execution for the prescription medication (id_pres_plan_task)
            SELECT ipp.*
              BULK COLLECT
              INTO l_tbl_interv_presc_plan
              FROM interv_presc_det ipd, interv_presc_plan ipp
             WHERE ipd.id_presc_plan_task = i_medication
               AND ipd.id_interv_presc_det = ipp.id_interv_presc_det
               AND ipp.flg_status != pk_procedures_constant.g_interv_cancel;
        
            FOR i IN 1 .. l_tbl_interv_presc_plan.count
            LOOP
                g_error := 'CALL PK_PROCEDURES_API_DB.SET_PROCEDURE_EXECUTION';
                IF NOT pk_procedures_api_db.set_procedure_execution(i_lang                   => i_lang,
                                                                    i_prof                   => i_prof,
                                                                    i_episode                => i_episode,
                                                                    i_interv_presc_det       => l_tbl_interv_presc_plan(i).id_interv_presc_det,
                                                                    i_interv_presc_plan      => l_tbl_interv_presc_plan(i).id_interv_presc_plan,
                                                                    i_dt_next                => l_dt_begin(1),
                                                                    i_prof_performed         => NULL,
                                                                    i_start_time             => NULL,
                                                                    i_end_time               => NULL,
                                                                    i_flg_supplies           => pk_alert_constant.g_no,
                                                                    i_notes                  => NULL,
                                                                    i_epis_documentation     => NULL,
                                                                    i_clinical_decision_rule => NULL,
                                                                    o_interv_presc_plan      => l_interv_presc_plan,
                                                                    o_error                  => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROCEDURE_WITH_MEDICATION',
                                              o_error);
            RETURN FALSE;
    END set_procedure_with_medication;

    PROCEDURE progress_notes_____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_in_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_order   IN VARCHAR2,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_name_sort CONSTANT VARCHAR2(1 CHAR) := 'N';
        l_date_sort CONSTANT VARCHAR2(1 CHAR) := 'D';
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT pk_procedures_api_db.get_alias_translation(i_lang,
                                                              i_prof,
                                                              'INTERVENTION.CODE_INTERVENTION.' || ipd.id_intervention,
                                                              NULL) description,
                   ipd.id_prof_last_update id_professional,
                   ipd.dt_last_update_tstz change_date
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_prescription IN
                   (SELECT ip.id_interv_prescription
                      FROM interv_prescription ip
                     WHERE ip.id_episode = i_episode
                    UNION ALL
                    SELECT ip.id_interv_prescription
                      FROM interv_prescription ip
                     WHERE ip.id_episode_origin = i_episode)
               AND ipd.flg_status NOT IN
                   (pk_procedures_constant.g_interv_draft, pk_procedures_constant.g_interv_cancel)
             ORDER BY decode(i_order, l_name_sort, nlssort(description, 'NLS_SORT=BINARY_AI')) ASC, -- sort order case insensitive and accent insensitive
                      decode(i_order, l_date_sort, change_date) DESC NULLS LAST;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_IN_EPISODE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_in_episode;

    FUNCTION get_procedure_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_interv FOR
            SELECT pea.id_interv_presc_det,
                   pea.flg_status_det flg_status,
                   pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det, i_lang) desc_status,
                   pk_procedures_api_db.get_alias_translation(i_lang,
                                                              i_prof,
                                                              'INTERVENTION.CODE_INTERVENTION.' || pea.id_intervention,
                                                              NULL) desc_procedure,
                   nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang, i_prof, pea.id_order_recurrence),
                       pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) instructions,
                   pea.id_intervention,
                   pk_sysdomain.get_domain('INTERV_PRESCRIPTION.FLG_TIME', pea.flg_time, i_lang) desc_time,
                   pea.notes,
                   (SELECT listagg(pk_date_utils.date_char_tsz(i_lang,
                                                               p.dt_take_tstz,
                                                               i_prof.institution,
                                                               i_prof.software),
                                   ', ') within GROUP(ORDER BY p.exec_number ASC)
                      FROM interv_presc_plan p
                     WHERE p.id_interv_presc_det = i_interv_presc_det
                       AND p.flg_status NOT IN (pk_procedures_constant.g_interv_cancel)) AS exec_date,
                   (SELECT pk_date_utils.date_char_tsz(i_lang, ip.dt_begin_tstz, i_prof.institution, i_prof.software)
                      FROM interv_prescription ip
                     WHERE ip.id_interv_prescription = pea.id_interv_prescription) start_date
              FROM procedures_ea pea
             WHERE pea.id_interv_presc_det = i_interv_presc_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_INFO',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_info;

    FUNCTION check_procedure_revision
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_treatment IN treatment_management.id_treatment%TYPE
    ) RETURN VARCHAR2 IS
    
        l_check VARCHAR2(1 CHAR);
    
    BEGIN
    
        g_error := 'Interventions id_interv_presc_det: ' || i_treatment;
        SELECT pk_procedures_constant.g_yes
          INTO l_check
          FROM interv_presc_det
         WHERE id_interv_presc_det = i_treatment
           AND flg_status IN (pk_procedures_constant.g_interv_finished,
                              pk_procedures_constant.g_interv_exec,
                              pk_procedures_constant.g_interv_interrupted);
    
        RETURN l_check;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_procedures_constant.g_no;
        WHEN OTHERS THEN
            RETURN pk_procedures_constant.g_no;
    END check_procedure_revision;

    PROCEDURE hand_off__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_by_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_interv  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit visit.id_visit%TYPE;
    
    BEGIN
    
        l_visit := pk_visit.get_visit(i_episode, o_error);
    
        g_error := 'OPEN O_INTERV';
        OPEN o_interv FOR
            SELECT pk_utils.concat_table_l(CAST(COLLECT(t.desc_procedure) AS table_varchar), '; ') desc_procedure,
                   t.flg_status
              FROM (SELECT pk_procedures_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'INTERVENTION.CODE_INTERVENTION.' ||
                                                                      pea.id_intervention,
                                                                      NULL) desc_procedure,
                           decode(pea.flg_status_det,
                                  pk_procedures_constant.g_interv_pending,
                                  pk_procedures_constant.g_interv_req,
                                  pea.flg_status_det) flg_status,
                           pk_sysdomain.get_rank(i_lang, 'INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det) rank
                      FROM procedures_ea pea
                     WHERE pea.id_visit = l_visit
                       AND pea.flg_status_det IN
                           (pk_procedures_constant.g_interv_pending, pk_procedures_constant.g_interv_req)) t
             GROUP BY flg_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_BY_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_by_status;

    PROCEDURE discharge_summary__________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_technical_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET TECHNICAL_PROCEDURES';
        OPEN o_list FOR
            SELECT ipd.id_interv_presc_det,
                   ipd.id_interv_prescription,
                   i.id_intervention,
                   pk_procedures_utils.get_alias_translation(i_lang,
                                                             i_prof,
                                                             'INTERVENTION.CODE_INTERVENTION.' || ipd.id_intervention,
                                                             NULL) description,
                   ipd.dt_end_tstz
              FROM interv_prescription ip
             INNER JOIN interv_presc_det ipd
                ON ipd.id_interv_prescription = ip.id_interv_prescription
             INNER JOIN intervention i
                ON i.id_intervention = ipd.id_intervention
             WHERE ip.id_episode = i_episode
               AND ip.id_institution = i_prof.institution
               AND ipd.flg_status = 'F'
               AND i.flg_technical = 'Y'
             ORDER BY ipd.dt_end_tstz ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            ---
            RETURN FALSE;
    END get_technical_procedures;

    FUNCTION check_technical_procedure
    
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_technical exam.flg_technical%TYPE;
    
    BEGIN
    
        SELECT i.flg_technical
          INTO l_flg_technical
          FROM interv_presc_det ipd
         INNER JOIN intervention i
            ON i.id_intervention = ipd.id_intervention
         WHERE ipd.id_interv_presc_det = i_interv_presc_det;
    
        RETURN l_flg_technical;
    
    END check_technical_procedure;

    PROCEDURE flowsheets_____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_flowsheets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER
    ) RETURN t_coll_mcdt_flowsheets IS
    
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE;
        l_visit   visit.id_visit%TYPE;
    
        l_mcdt_flowsheets t_coll_mcdt_flowsheets;
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_id_scope IS NULL
           OR i_type_scope IS NULL
        THEN
            g_error := 'Scope id or type is null';
            RAISE g_other_exception;
        END IF;
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_SCOPE_VARS';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_id_scope,
                                              i_scope_type => i_type_scope,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'SELECT INTO L_MCDT_FLOWSHEETS';
        SELECT t_rec_mcdt_flowsheets(id_alert    => t.id,
                                     id_content  => t.id_content,
                                     description => pk_procedures_api_db.get_alias_translation(i_lang,
                                                                                               i_prof,
                                                                                               t.code_intervention,
                                                                                               NULL),
                                     flg_stattus => t.flg_status)
          BULK COLLECT
          INTO l_mcdt_flowsheets
          FROM (SELECT *
                  FROM (SELECT i.id_intervention id,
                               i.id_content,
                               i.code_intervention,
                               pea.flg_status_det flg_status,
                               nvl(pea.id_episode, pea.id_episode_origin) id_episode,
                               coalesce(pea.dt_begin_det, pea.dt_interv_presc_det, pea.dt_interv_prescription) dt_value,
                               pk_sysdomain.get_rank(i_lang, 'INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det) rank
                          FROM procedures_ea pea
                         INNER JOIN interv_prescription ip
                            ON ip.id_interv_prescription = pea.id_interv_prescription
                         INNER JOIN interv_presc_det ipd
                            ON ipd.id_interv_presc_det = pea.id_interv_presc_det
                         INNER JOIN intervention i
                            ON i.id_intervention = pea.id_intervention
                         WHERE pea.flg_status_det NOT IN
                               (pk_procedures_constant.g_interv_draft,
                                pk_procedures_constant.g_interv_expired,
                                pk_procedures_constant.g_interv_not_ordered,
                                pk_procedures_constant.g_interv_cancel)) p
                 INNER JOIN (SELECT e.id_episode
                              FROM episode e
                             WHERE e.id_episode = l_episode
                               AND e.id_patient = l_patient
                               AND i_type_scope = pk_alert_constant.g_scope_type_episode
                            UNION ALL
                            SELECT e.id_episode
                              FROM episode e
                             WHERE e.id_patient = l_patient
                               AND i_type_scope = pk_alert_constant.g_scope_type_patient
                            UNION ALL
                            SELECT e.id_episode
                              FROM episode e
                             WHERE e.id_visit = l_visit
                               AND e.id_patient = l_patient
                               AND i_type_scope = pk_alert_constant.g_scope_type_visit) e
                    ON e.id_episode = p.id_episode
                 ORDER BY rank, dt_value DESC) t;
    
        RETURN l_mcdt_flowsheets;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_flowsheets;

    PROCEDURE viewer____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_viewer_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M097');
    
        l_patienteducation_icon VARCHAR2(50 CHAR) := 'ContentIcon';
        l_procedures_icon       VARCHAR2(50 CHAR) := 'InterventionsIcon';
        l_icnp_icon             VARCHAR2(50 CHAR) := 'ICNPIcon';
    
        l_flg_patienteducation VARCHAR2(1 CHAR) := 'T';
        l_flg_procedures       VARCHAR2(1 CHAR) := 'P';
        l_flg_icnp             VARCHAR2(1 CHAR) := 'I';
    
    BEGIN
    
        g_error := 'OPEN O_INTERV';
        OPEN o_list FOR
            SELECT l_flg_procedures flg_type,
                   pea.id_interv_presc_det id,
                   l_procedures_icon icon,
                   pk_procedures_api_db.get_alias_translation(i_lang,
                                                              i_prof,
                                                              'INTERVENTION.CODE_INTERVENTION.' || pea.id_intervention,
                                                              NULL) desc_item,
                   decode(pea.notes_cancel, NULL, decode(pea.notes, NULL, NULL, l_msg_notes), l_msg_notes) msg_notes,
                   decode(pea.notes_cancel, NULL, decode(pea.notes, NULL, NULL, pea.notes), pea.notes_cancel) notes,
                   nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang, i_prof, pea.id_order_recurrence),
                       pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) instructions,
                   pea.flg_status_det flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pea.id_prof_order) prof_order,
                   pk_diagnosis.concat_diag(i_lang, NULL, NULL, pea.id_interv_presc_det, i_prof) desc_diagnosis,
                   pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              pea.status_str,
                                              pea.status_msg,
                                              pea.status_icon,
                                              pea.status_flg) status_string,
                   l_flg_procedures viewer_category,
                   pk_message.get_message(i_lang, i_prof, 'ACTION.CODE_ACTION.213818') viewer_category_desc,
                   pea.id_episode viewer_id_epis,
                   pea.id_professional viewer_id_prof,
                   pk_date_utils.date_send_tsz(i_lang, nvl(pea.dt_plan, pea.dt_begin_req), i_prof) viewer_date
              FROM interv_presc_det ipd, procedures_ea pea
             WHERE pea.id_patient = i_patient
               AND pea.id_interv_presc_det = ipd.id_interv_presc_det
               AND (pea.flg_status_det IN
                   (pk_procedures_constant.g_interv_finished, pk_procedures_constant.g_interv_exec) OR
                   (pea.flg_status_det = pk_procedures_constant.g_interv_interrupted AND
                   pea.flg_status_plan = pk_procedures_constant.g_interv_plan_executed))
            UNION
            SELECT l_flg_icnp flg_type,
                   iie.id_icnp_epis_interv id,
                   l_icnp_icon icon,
                   pk_icnp.desc_composition(i_lang, iie.id_composition_interv) desc_item,
                   decode(iie.notes_close, NULL, NULL, l_msg_notes) msg_notes,
                   decode(iie.notes_close, NULL, NULL, iie.notes_close) notes,
                   NULL instructions,
                   iie.flg_status,
                   pk_prof_utils.get_nickname(i_lang, iie.id_prof) prof_order,
                   pk_icnp.desc_composition(i_lang, iie.id_composition_diag) desc_diagnosis,
                   pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              iie.status_str,
                                              iie.status_msg,
                                              iie.status_icon,
                                              iie.status_flg) status_string,
                   l_flg_icnp viewer_category,
                   pk_translation.get_translation(i_lang, 'SYS_CODE_21') viewer_category_desc,
                   iie.id_episode viewer_id_epis,
                   iie.id_prof viewer_id_prof,
                   pk_date_utils.date_send_tsz(i_lang, iie.dt_begin, i_prof) viewer_date
              FROM interv_icnp_ea iie, icnp_epis_intervention iei
             WHERE iie.id_icnp_epis_interv = iei.id_icnp_epis_interv
               AND iie.id_patient = i_patient
               AND iie.flg_status IN
                   (pk_icnp_constant.g_epis_interv_status_executed, pk_icnp_constant.g_epis_interv_status_discont)
            UNION
            SELECT l_flg_patienteducation flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patienteducation_icon icon,
                   decode(ntr.id_nurse_tea_topic,
                          1, --other
                          nvl(ntr.desc_topic_aux,
                              pk_translation.get_translation(i_lang,
                                                             'NURSE_TEA_TOPIC.CODE_NURSE_TEA_TOPIC.' ||
                                                             ntr.id_nurse_tea_topic)),
                          pk_translation.get_translation(i_lang,
                                                         'NURSE_TEA_TOPIC.CODE_NURSE_TEA_TOPIC.' ||
                                                         ntr.id_nurse_tea_topic)) desc_item,
                   decode(ntr.notes_close, NULL, NULL, l_msg_notes) msg_notes,
                   decode(ntr.notes_close, NULL, NULL, ntr.notes_close) notes,
                   pk_message.get_message(i_lang, i_prof, 'PATIENT_EDUCATION_T042') || ' ' ||
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_begin_tstz, i_prof) instructions,
                   ntr.flg_status,
                   pk_prof_utils.get_nickname(i_lang, ntr.id_prof_req) prof_order,
                   pk_patient_education_api_db.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) desc_diagnosis,
                   pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              ntr.status_str,
                                              ntr.status_msg,
                                              ntr.status_icon,
                                              ntr.status_flg) status_string,
                   l_flg_patienteducation viewer_category,
                   pk_message.get_message(i_lang, i_prof, 'ACTION.CODE_ACTION.214093') viewer_category_desc,
                   ntr.id_episode viewer_id_epis,
                   ntr.id_prof_req viewer_id_prof,
                   pk_date_utils.date_send_tsz(i_lang, ntr.dt_begin_tstz, i_prof) viewer_date
              FROM nurse_tea_req ntr
             WHERE ntr.id_patient = i_patient
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_fin;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_VIEWER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_viewer_list;

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_type_interv CONSTANT VARCHAR2(5) := pk_alert_constant.g_flg_type_viewer_proced;
        l_type_icnp   CONSTANT VARCHAR2(5) := 'ICNPI';
        l_type_tea    CONSTANT VARCHAR2(5) := 'NT';
    
        l_records t_table_rec_gen_area_rank_tmp;
    
        l_viewer_lim_tasktime_interv sys_config.value%TYPE := pk_sysconfig.get_config('VIEWER_LIM_TASKTIME_INTERV',
                                                                                      i_prof);
    
        l_episode table_number;
    
        l_task_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EHR_VIEWER_T067');
    
        CURSOR c_episode IS
            SELECT e.id_episode
              FROM episode e
             WHERE e.id_visit = pk_episode.get_id_visit(i_episode);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_episode;
        FETCH c_episode BULK COLLECT
            INTO l_episode;
    
        g_error := 'INSERT ON VARIABLE';
        SELECT t_rec_gen_area_rank_tmp(t.varch1,
                                       t.varch2,
                                       t.varch3,
                                       t.varch4,
                                       t.varch5,
                                       t.varch6,
                                       t.varch7,
                                       t.varch8,
                                       t.varch9,
                                       t.varch10,
                                       t.varch11,
                                       t.varch12,
                                       t.varch13,
                                       t.varch14,
                                       t.varch15,
                                       t.numb1,
                                       t.numb2,
                                       t.numb3,
                                       t.numb4,
                                       t.numb5,
                                       t.numb6,
                                       t.numb7,
                                       t.numb8,
                                       t.numb9,
                                       t.numb10,
                                       t.numb11,
                                       t.numb12,
                                       t.numb13,
                                       t.numb14,
                                       t.numb15,
                                       t.dt_tstz1,
                                       t.dt_tstz2,
                                       t.dt_tstz3,
                                       t.dt_tstz4,
                                       t.dt_tstz5,
                                       t.dt_tstz6,
                                       t.dt_tstz7,
                                       t.dt_tstz8,
                                       t.dt_tstz9,
                                       t.dt_tstz10,
                                       t.dt_tstz11,
                                       t.dt_tstz12,
                                       t.dt_tstz13,
                                       t.dt_tstz14,
                                       t.dt_tstz15,
                                       t.rank)
          BULK COLLECT
          INTO l_records
          FROM (SELECT decode(pea.flg_prn,
                              pk_procedures_constant.g_yes,
                              decode(pea.flg_status_det,
                                     pk_procedures_constant.g_interv_pending,
                                     pk_procedures_constant.g_interv_req,
                                     pea.flg_status_det),
                              pea.flg_status_det) varch1,
                       pea.flg_time varch2,
                       NULL varch3,
                       'INTERVENTION.CODE_INTERVENTION.' || pea.id_intervention varch4,
                       l_type_interv varch5,
                       pea.flg_interv_type varch6,
                       pea.status_str varch7,
                       pea.status_msg varch8,
                       pea.status_icon varch9,
                       pea.status_flg varch10,
                       NULL varch11,
                       NULL varch12,
                       NULL varch13,
                       NULL varch14,
                       NULL varch15,
                       pea.id_episode_origin numb1,
                       pea.id_interv_presc_det numb2,
                       NULL numb3,
                       NULL numb4,
                       NULL numb5,
                       NULL numb6,
                       NULL numb7,
                       NULL numb8,
                       NULL numb9,
                       NULL numb10,
                       NULL numb11,
                       NULL numb12,
                       NULL numb13,
                       NULL numb14,
                       NULL numb15,
                       pea.dt_begin_det dt_tstz1,
                       nvl(pea.dt_interv_presc_det, pea.dt_interv_prescription) dt_tstz2,
                       g_sysdate_tstz dt_tstz3,
                       pea.dt_interv_prescription dt_tstz4,
                       NULL dt_tstz5,
                       NULL dt_tstz6,
                       NULL dt_tstz7,
                       NULL dt_tstz8,
                       NULL dt_tstz9,
                       NULL dt_tstz10,
                       NULL dt_tstz11,
                       NULL dt_tstz12,
                       NULL dt_tstz13,
                       NULL dt_tstz14,
                       NULL dt_tstz15,
                       decode(nvl(pea.flg_referral, pk_procedures_constant.g_flg_referral_a),
                              pk_procedures_constant.g_flg_referral_a,
                              pk_sysdomain.get_rank(i_lang,
                                                    'INTERV_PRESC_DET.FLG_STATUS',
                                                    decode(pea.flg_status_det,
                                                           pk_procedures_constant.g_interv_exec,
                                                           pk_procedures_constant.g_interv_pending,
                                                           pea.flg_status_det)),
                              pk_sysdomain.get_rank(i_lang, 'INTERV_PRESC_DET.FLG_REFERRAL', pea.flg_referral)) rank
                  FROM procedures_ea pea
                 WHERE pea.id_patient = i_patient
                   AND pea.flg_status_det NOT IN (pk_procedures_constant.g_interv_cancel,
                                                  pk_procedures_constant.g_interv_draft,
                                                  pk_procedures_constant.g_interv_interrupted,
                                                  pk_procedures_constant.g_interv_expired,
                                                  pk_procedures_constant.g_interv_not_ordered)
                   AND ((i_viewer_area = pk_hibernate_intf.g_ordered_list_ehr AND
                       pea.flg_status_det = pk_procedures_constant.g_interv_finished) OR
                       (i_viewer_area = pk_hibernate_intf.g_ordered_list_wfl AND
                       pea.flg_status_det NOT IN
                       (pk_procedures_constant.g_interv_finished, pk_procedures_constant.g_interv_cancel)))
                   AND trunc(months_between(SYSDATE, nvl(pea.dt_begin_req, pea.dt_plan)) / 12) <=
                       l_viewer_lim_tasktime_interv
                UNION ALL
                SELECT ntr.flg_status varch1,
                       NULL varch2,
                       decode(ntr.id_nurse_tea_topic,
                              1, --other
                              nvl(ntr.desc_topic_aux,
                                  pk_translation.get_translation(i_lang,
                                                                 (SELECT ntt.code_nurse_tea_topic
                                                                    FROM nurse_tea_topic ntt
                                                                   WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic))),
                              pk_translation.get_translation(i_lang,
                                                             (SELECT ntt.code_nurse_tea_topic
                                                                FROM nurse_tea_topic ntt
                                                               WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic))) varch3,
                       NULL varch4,
                       l_type_tea varch5,
                       NULL varch6,
                       ntr.status_str varch7,
                       ntr.status_msg varch8,
                       ntr.status_icon varch9,
                       ntr.status_flg varch10,
                       NULL varch11,
                       NULL varch12,
                       NULL varch13,
                       NULL varch14,
                       NULL varch15,
                       NULL numb1,
                       ntr.id_nurse_tea_req numb2,
                       NULL numb3,
                       NULL numb4,
                       NULL numb5,
                       NULL numb6,
                       NULL numb7,
                       NULL numb8,
                       NULL numb9,
                       NULL numb10,
                       NULL numb11,
                       NULL numb12,
                       NULL numb13,
                       NULL numb14,
                       NULL numb15,
                       ntr.dt_begin_tstz dt_tstz1,
                       ntr.dt_nurse_tea_req_tstz dt_tstz2,
                       g_sysdate_tstz dt_tstz3,
                       ntr.dt_nurse_tea_req_tstz dt_tstz4,
                       NULL dt_tstz5,
                       NULL dt_tstz6,
                       NULL dt_tstz7,
                       NULL dt_tstz8,
                       NULL dt_tstz9,
                       NULL dt_tstz10,
                       NULL dt_tstz11,
                       NULL dt_tstz12,
                       NULL dt_tstz13,
                       NULL dt_tstz14,
                       NULL dt_tstz15,
                       NULL rank
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_patient = i_patient
                   AND ntr.flg_status NOT IN
                       (pk_patient_education_constant.g_nurse_tea_req_canc,
                        pk_patient_education_constant.g_nurse_tea_req_draft,
                        pk_patient_education_constant.g_nurse_tea_req_expired)
                   AND ((i_viewer_area = pk_hibernate_intf.g_ordered_list_ehr AND
                       ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_fin) OR
                       (i_viewer_area = pk_hibernate_intf.g_ordered_list_wfl AND
                       ntr.id_episode IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                             t.column_value
                                              FROM TABLE(l_episode) t) AND
                       ntr.flg_status NOT IN
                       (pk_patient_education_constant.g_nurse_tea_req_fin,
                          pk_patient_education_constant.g_nurse_tea_req_canc)))
                UNION ALL
                SELECT iie.flg_status varch1,
                       iie.flg_time varch2,
                       NULL varch3,
                       'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || iei.id_composition varch4,
                       l_type_icnp varch5,
                       iie.flg_type varch6,
                       iie.status_str varch7,
                       iie.status_msg varch8,
                       iie.status_icon varch9,
                       iie.status_flg varch10,
                       NULL varch11,
                       NULL varch12,
                       NULL varch13,
                       NULL varch14,
                       NULL varch15,
                       iie.id_episode_origin numb1,
                       iie.id_icnp_epis_interv numb2,
                       NULL numb3,
                       NULL numb4,
                       NULL numb5,
                       NULL numb6,
                       NULL numb7,
                       NULL numb8,
                       NULL numb9,
                       NULL numb10,
                       NULL numb11,
                       NULL numb12,
                       NULL numb13,
                       NULL numb14,
                       NULL numb15,
                       iie.dt_plan dt_tstz1,
                       iie.dt_icnp_epis_interv dt_tstz2,
                       g_sysdate_tstz dt_tstz3,
                       iie.dt_icnp_epis_interv dt_tstz4,
                       NULL dt_tstz5,
                       NULL dt_tstz6,
                       NULL dt_tstz7,
                       NULL dt_tstz8,
                       NULL dt_tstz9,
                       NULL dt_tstz10,
                       NULL dt_tstz11,
                       NULL dt_tstz12,
                       NULL dt_tstz13,
                       NULL dt_tstz14,
                       NULL dt_tstz15,
                       NULL rank
                  FROM interv_icnp_ea iie, icnp_epis_intervention iei
                 WHERE iie.id_icnp_epis_interv = iei.id_icnp_epis_interv
                   AND iie.id_patient = i_patient
                   AND iie.flg_status != pk_icnp_constant.g_epis_interv_status_cancelled
                   AND ((i_viewer_area = pk_hibernate_intf.g_ordered_list_ehr AND
                       iie.flg_status_plan = pk_icnp_constant.g_interv_plan_status_executed) OR
                       (i_viewer_area = pk_hibernate_intf.g_ordered_list_wfl AND
                       iei.id_episode IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                             t.column_value
                                              FROM TABLE(l_episode) t) AND
                       iie.flg_status NOT IN (pk_icnp_constant.g_epis_interv_status_executed,
                                                pk_icnp_constant.g_epis_interv_status_cancelled)))) t;
    
        g_error := 'OPEN CURSOR';
        OPEN o_ordered_list FOR
            SELECT id,
                   code_description,
                   description,
                   dt_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_req_tstz, i_prof) dt_req,
                   flg_status,
                   flg_type,
                   desc_status,
                   rank,
                   rank_order,
                   COUNT(0) over() num_count,
                   l_task_title task_title
              FROM (
                    -- PROCEDURES
                    SELECT /*+opt_estimate(table gart rows=1)*/
                     gart.numb2 id,
                      gart.varch4 code_description,
                      decode(i_translate,
                             pk_procedures_constant.g_no,
                             NULL,
                             pk_procedures_api_db.get_alias_translation(i_lang, i_prof, gart.varch4, NULL)) description,
                      gart.dt_tstz2 dt_req_tstz,
                      gart.varch1 flg_status,
                      gart.varch5 flg_type,
                      pk_utils.get_status_string(i_lang, i_prof, gart.varch7, gart.varch8, gart.varch9, gart.varch10) desc_status,
                      gart.rank rank,
                      gart.numb2 * gart.numb3 rank_order
                      FROM TABLE(l_records) gart, procedures_ea pea
                     WHERE gart.numb2 = pea.id_interv_presc_det
                       AND gart.varch5 = l_type_interv
                    UNION
                    -- ICNP
                    SELECT /*+opt_estimate(table gart rows=1)*/
                     gart.numb2 id,
                      gart.varch4 code_description,
                      decode(i_translate, 'N', NULL, pk_translation.get_translation(i_lang, gart.varch4)) description,
                      gart.dt_tstz2 dt_req_tstz,
                      gart.varch1 flg_status,
                      gart.varch5 flg_type,
                      pk_utils.get_status_string(i_lang, i_prof, gart.varch7, gart.varch8, gart.varch9, gart.varch10) desc_status,
                      gart.rank rank,
                      gart.numb2 * gart.numb3 rank_order
                      FROM TABLE(l_records) gart, interv_icnp_ea iie
                     WHERE gart.numb2 = iie.id_icnp_epis_interv
                       AND gart.varch5 = l_type_icnp
                    UNION
                    -- NURSE_TEA_REQ
                    SELECT /*+opt_estimate(table gart rows=1)*/
                     gart.numb2 id,
                      NULL code_description,
                      gart.varch3 description,
                      gart.dt_tstz2 dt_req_tstz,
                      gart.varch1 flg_status,
                      gart.varch5 flg_type,
                      pk_utils.get_status_string(i_lang, i_prof, gart.varch7, gart.varch8, gart.varch9, gart.varch10) desc_status,
                      gart.rank rank,
                      gart.numb2 * gart.numb3 rank_order
                      FROM TABLE(l_records) gart, nurse_tea_req ntr
                     WHERE gart.numb2 = ntr.id_nurse_tea_req
                       AND gart.varch5 = l_type_tea)
             ORDER BY rank DESC, rank_order DESC, id DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              o_error);
            RETURN FALSE;
    END get_ordered_list;

    FUNCTION get_ordered_list_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_ordered_list_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_ORDERED_LIST_DET';
        OPEN o_ordered_list_det FOR
            SELECT nvl(pk_procedures_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  'INTERVENTION.CODE_INTERVENTION.' ||
                                                                  pea.id_intervention,
                                                                  NULL),
                       'INTERVENTION.CODE_INTERVENTION.' || pea.id_intervention) title,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ip.id_professional) prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pea.id_professional,
                                                    pea.dt_interv_prescription,
                                                    pea.id_episode) prof_spec_reg,
                   pea.flg_time,
                   pea.dt_interv_prescription dt_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, pea.dt_interv_prescription, i_prof) dt_req,
                   pea.dt_begin_req dt_begin_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, pea.dt_begin_req, i_prof) dt_begin,
                   pea.dt_plan dt_plan_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, pea.dt_plan, i_prof) dt_pend_req,
                   pea.flg_status_det flg_status,
                   pea.flg_referral,
                   decode(pea.flg_referral,
                          pk_procedures_constant.g_flg_referral_s,
                          pk_sysdomain.get_img(i_lang, 'INTERV_PRESC_DET.FLG_REFERRAL', pea.flg_referral),
                          pk_procedures_constant.g_flg_referral_r,
                          pk_sysdomain.get_img(i_lang, 'INTERV_PRESC_DET.FLG_REFERRAL', pea.flg_referral),
                          pk_sysdomain.get_img(i_lang, 'INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det)) icon_name,
                   pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || ip.id_institution) institution,
                   pea.id_episode_origin
              FROM procedures_ea pea, interv_prescription ip
             WHERE pea.id_interv_presc_det = i_interv_presc_det
               AND pea.id_interv_prescription = ip.id_interv_prescription;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST_DET',
                                              o_error);
            RETURN FALSE;
    END get_ordered_list_det;

    FUNCTION get_count_and_first
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_viewer_area IN VARCHAR2,
        o_num_occur   OUT NUMBER,
        o_desc_first  OUT VARCHAR2,
        o_code_first  OUT VARCHAR2,
        o_dt_first    OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list       pk_types.cursor_type;
        l_count      NUMBER := 0;
        l_str        VARCHAR2(4000);
        l_task_title sys_message.desc_message%TYPE;
    
    BEGIN
    
        g_error := 'GET ORDERED LIST';
        IF get_ordered_list(i_lang         => i_lang,
                            i_prof         => i_prof,
                            i_patient      => i_patient,
                            i_episode      => i_episode,
                            i_translate    => pk_procedures_constant.g_no,
                            i_viewer_area  => i_viewer_area,
                            o_ordered_list => l_list,
                            o_error        => o_error)
        THEN
            FETCH l_list
                INTO l_str,
                     o_code_first,
                     o_desc_first,
                     o_dt_first,
                     l_str,
                     l_str,
                     l_str,
                     l_str,
                     l_str,
                     l_str,
                     l_count,
                     l_task_title;
        
            o_num_occur := l_count;
        
            RETURN TRUE;
        ELSE
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
        
            RAISE g_user_exception;
        END IF;
    
    EXCEPTION
        WHEN g_user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              'U',
                                              g_error,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_count_and_first;

    FUNCTION get_procedure_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_episode table_number;
    
        l_count NUMBER := 0;
    
    BEGIN
    
        l_episode := pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_patient,
                                          i_episode    => i_episode,
                                          i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM procedures_ea pea
         WHERE pea.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                   *
                                    FROM TABLE(l_episode) t)
           AND pea.flg_time = pk_procedures_constant.g_flg_time_e
           AND pea.flg_status_det NOT IN (pk_procedures_constant.g_interv_exterior,
                                          pk_procedures_constant.g_interv_cancel,
                                          pk_procedures_constant.g_interv_predefined,
                                          pk_procedures_constant.g_interv_draft);
    
        IF l_count > 0
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM procedures_ea pea
             WHERE pea.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND pea.flg_time = pk_procedures_constant.g_flg_time_e
               AND pea.flg_status_det NOT IN (pk_procedures_constant.g_interv_not_ordered,
                                              pk_procedures_constant.g_interv_finished,
                                              pk_procedures_constant.g_interv_exterior,
                                              pk_procedures_constant.g_interv_cancel,
                                              pk_procedures_constant.g_interv_predefined,
                                              pk_procedures_constant.g_interv_draft);
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_ongoing;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_completed;
            END IF;
        ELSE
            RETURN pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_procedure_viewer_checklist;

    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
    
        l_patients table_number;
        l_error    t_error_out;
    
    BEGIN
    
        SELECT id_patient
          BULK COLLECT
          INTO l_patients
          FROM viewer_ehr_ea vee;
    
        IF NOT upd_viewer_ehr_ea_pat(i_lang => i_lang, i_prof => i_prof, i_patient => l_patients, o_error => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
    END upd_viewer_ehr_ea;

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_occur  table_number := table_number();
        l_desc_first table_varchar := table_varchar();
        l_code_first table_varchar := table_varchar();
        l_dt_first   table_varchar := table_varchar();
        l_episode    table_number := table_number();
    
    BEGIN
    
        g_error := 'START UPD_VIEWER_EHR_EA_PAT';
        l_num_occur.extend(i_patient.count);
        l_desc_first.extend(i_patient.count);
        l_code_first.extend(i_patient.count);
        l_dt_first.extend(i_patient.count);
        l_episode.extend(i_patient.count);
    
        FOR i IN i_patient.first .. i_patient.last
        LOOP
            g_error := 'CALL GET_COUNT_AND_FIRST';
            IF NOT get_count_and_first(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_patient     => i_patient(i),
                                       i_episode     => l_episode(i),
                                       i_viewer_area => pk_hibernate_intf.g_ordered_list_ehr,
                                       o_num_occur   => l_num_occur(i),
                                       o_desc_first  => l_desc_first(i),
                                       o_code_first  => l_code_first(i),
                                       o_dt_first    => l_dt_first(i),
                                       o_error       => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        g_error := 'FORALL';
        FORALL i IN i_patient.first .. i_patient.last
            UPDATE viewer_ehr_ea
               SET num_interv  = l_num_occur(i),
                   desc_interv = l_desc_first(i),
                   dt_interv   = l_dt_first(i),
                   code_interv = l_code_first(i)
             WHERE id_patient = i_patient(i) log errors INTO err$_viewer_ehr_ea(to_char(SYSDATE)) reject LIMIT
             unlimited;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPD_VIEWER_EHR_EA_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_viewer_ehr_ea_pat;

    PROCEDURE match____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_procedure_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_episode(i_episode episode.id_episode%TYPE) IS
            SELECT e.id_patient
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE := i_episode;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        IF i_patient IS NULL
        THEN
            g_error := 'OPEN C_EPISODE - i_episode: ' || i_episode;
            OPEN c_episode(i_episode);
            FETCH c_episode
                INTO l_patient;
            CLOSE c_episode;
        
            l_episode := i_episode;
        
            IF l_patient IS NULL
               OR l_episode IS NULL
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'UPDATE INTERV_QUESTION_RESPONSE';
            ts_interv_question_response.upd(id_episode_in  => i_episode,
                                            id_episode_nin => FALSE,
                                            where_in       => 'id_episode = ' || i_episode_temp,
                                            rows_out       => l_rows_out);
        
            g_error := 'UPDATE INTERV_QUESTION_RESPONSE_HIST';
            UPDATE interv_question_response_hist
               SET id_episode = i_episode
             WHERE id_episode = i_episode_temp;
        
            l_rows_out := table_varchar();
        
            g_error := 'UPDATE INTERV_PRESCRIPTION';
            ts_interv_prescription.upd(id_episode_in  => i_episode,
                                       id_episode_nin => FALSE,
                                       where_in       => 'id_episode = ' || i_episode_temp,
                                       rows_out       => l_rows_out);
        
            g_error := 'UPDATE INTERV_PRESCRIPTION (id_episode_origin)';
            ts_interv_prescription.upd(id_episode_origin_in  => i_episode,
                                       id_episode_origin_nin => FALSE,
                                       where_in              => 'id_episode_origin = ' || i_episode_temp,
                                       rows_out              => l_rows_out);
        
            g_error := 'UPDATE INTERV_PRESCRIPTION (id_episode_destination)';
            ts_interv_prescription.upd(id_episode_destination_in  => i_episode,
                                       id_episode_destination_nin => FALSE,
                                       where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                       rows_out                   => l_rows_out);
        
            g_error := 'UPDATE INTERV_PRESCRIPTION (id_prev_episode)';
            ts_interv_prescription.upd(id_prev_episode_in  => i_episode,
                                       id_prev_episode_nin => FALSE,
                                       where_in            => 'id_prev_episode = ' || i_episode_temp,
                                       rows_out            => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE INTERV_PRESCRIPTION';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'INTERV_PRESCRIPTION',
                                          i_list_columns => table_varchar('ID_EPISODE',
                                                                          'ID_EPISODE_ORIGIN',
                                                                          'ID_EPISODE_DESTINATION',
                                                                          'ID_PREV_EPISODE'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            l_rows_out := NULL;
        
            g_error := ' UPDATE INTERV_PRESC_PLAN (id_episode_write)';
            ts_interv_presc_plan.upd(id_episode_write_in  => i_episode,
                                     id_episode_write_nin => FALSE,
                                     where_in             => 'id_episode_write = ' || i_episode_temp,
                                     rows_out             => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE INTERV_PRESC_PLAN';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'INTERV_PRESC_PLAN',
                                          i_list_columns => table_varchar('ID_EPISODE_WRITEE'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            g_error := 'UPDATE INTERV_PRESC_PLAN_HIST';
            UPDATE interv_presc_plan_hist
               SET id_episode_write = i_episode
             WHERE id_episode_write = i_episode_temp;
        ELSE
            g_error := 'OPEN C_EPISODE - i_episode_temp: ' || i_episode_temp;
            OPEN c_episode(i_episode_temp);
            FETCH c_episode
                INTO l_patient;
            CLOSE c_episode;
        
            l_episode := i_episode_temp;
        
            IF l_patient IS NULL
               OR l_episode IS NULL
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'UPDATE INTERV_PRESCRIPTION';
            ts_interv_prescription.upd(id_patient_in  => i_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_episode = ' || i_episode_temp,
                                       rows_out       => l_rows_out);
        
            g_error := 'UPDATE INTERV_PRESCRIPTION (id_prev_episode)';
            ts_interv_prescription.upd(id_patient_in  => i_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_prev_episode = ' || i_episode_temp,
                                       rows_out       => l_rows_out);
        
            g_error := 'UPDATE INTERV_PRESCRIPTION (id_episode_origin)';
            ts_interv_prescription.upd(id_patient_in  => i_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_episode_origin = ' || i_episode_temp,
                                       rows_out       => l_rows_out);
        
            g_error := 'UPDATE INTERV_PRESCRIPTION (id_episode_destination)';
            ts_interv_prescription.upd(id_patient_in  => i_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_episode_destination = ' || i_episode_temp,
                                       rows_out       => l_rows_out);
        
            g_error := 'UPDATE INTERV_PRESCRIPTION';
            ts_interv_prescription.upd(id_patient_in => i_patient,
                                       where_in      => 'id_episode = ' || i_episode_temp,
                                       rows_out      => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'INTERV_PRESCRIPTION',
                                          i_list_columns => table_varchar('ID_PATIENT'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROCEDURE_MATCH',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_procedure_match;

    PROCEDURE cda______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        o_interv     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient   patient.id_patient%TYPE;
        l_cancelled VARCHAR2(1);
        l_visit     visit.id_visit%TYPE;
        l_episode   episode.id_episode%TYPE;
        l_epis_type episode.id_epis_type%TYPE;
    
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_cancelled IS NULL
        THEN
            l_cancelled := pk_alert_constant.g_yes;
        ELSE
            l_cancelled := i_cancelled;
        
        END IF;
    
        g_error      := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_start_date';
        l_start_date := CASE
                            WHEN i_start_date IS NOT NULL THEN
                             pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_start_date)
                            ELSE
                             NULL
                        END;
    
        g_error    := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_end_date';
        l_end_date := CASE
                          WHEN i_end_date IS NOT NULL THEN
                           pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_end_date)
                          ELSE
                           NULL
                      END;
    
        IF i_scope IS NOT NULL
        THEN
            g_error := 'CALL PK_TOUCH_OPTION.GET_SCOPE_VARS';
            IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_scope      => i_scope,
                                                  i_scope_type => i_flg_scope,
                                                  o_patient    => l_patient,
                                                  o_visit      => l_visit,
                                                  o_episode    => l_episode,
                                                  o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        BEGIN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = l_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_type := NULL;
        END;
    
        OPEN o_interv FOR
            SELECT pea.id_interv_presc_det unique_id,
                   pea.id_intervention,
                   t_ti_log.get_desc_with_origin(i_lang,
                                                 i_prof,
                                                 pk_procedures_api_db.get_alias_translation(i_lang,
                                                                                            i_prof,
                                                                                            'INTERVENTION.CODE_INTERVENTION.' ||
                                                                                            pea.id_intervention,
                                                                                            NULL),
                                                 l_epis_type,
                                                 pea.flg_status_det,
                                                 pea.id_interv_presc_det,
                                                 pk_procedures_constant.g_interv_type_req) description,
                   pea.flg_status_det flg_status,
                   pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det, i_lang) desc_status,
                   pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_LATERALITY', pea.flg_laterality, i_lang) desc_laterality,
                   nvl(pea.id_prof_order, pea.id_professional) id_prof_req,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(pea.id_prof_order, pea.id_professional)) prof_order,
                   nvl(ipp.dt_plan_tstz, pea.dt_begin_req) dt_ord_tstz
              FROM TABLE(tf_procedures_ea(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => l_patient,
                                          i_episode    => l_episode,
                                          i_visit      => l_visit,
                                          i_cancelled  => l_cancelled,
                                          i_crit_type  => i_crit_type,
                                          i_start_date => l_start_date,
                                          i_end_date   => l_end_date)) pea,
                   interv_presc_plan ipp
             WHERE pea.id_interv_presc_det = ipp.id_interv_presc_det(+);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_list;

    FUNCTION get_procedure_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_proc_cda   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
    BEGIN
    
        IF i_id_scope IS NULL
           OR i_type_scope IS NULL
        THEN
            g_error := 'Scope id or type is null';
            RAISE g_other_exception;
        END IF;
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_SCOPE_VARS';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_id_scope,
                                              i_scope_type => i_type_scope,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Return pk_touch_option.get_scope_vars: ';
        g_error := g_error || ' o_patient = ' || coalesce(to_char(l_id_patient), '<null>');
        g_error := g_error || ' o_visit = ' || coalesce(to_char(l_id_visit), '<null>');
        g_error := g_error || ' o_episode = ' || coalesce(to_char(l_id_episode), '<null>');
    
        OPEN o_proc_cda FOR
            SELECT t.id,
                   t.id_content,
                   pk_procedures_api_db.get_alias_translation(i_lang, i_prof, t.code_intervention, NULL) description,
                   t.flg_status,
                   pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_STATUS', t.flg_status, i_lang) flg_status_desc,
                   t.dt_value,
                   t.notes,
                   t.flg_laterality,
                   pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_LATERALITY', t.flg_laterality, i_lang) flg_laterality_desc,
                   t.id_prof_performed,
                   t.id_inst_performed
              FROM (SELECT *
                      FROM (SELECT pea.id_interv_presc_det id,
                                   i.id_content,
                                   i.code_intervention,
                                   pea.flg_status_det flg_status,
                                   coalesce(pea.dt_begin_det, pea.dt_interv_presc_det, pea.dt_interv_prescription) dt_value,
                                   ipd.notes,
                                   pea.flg_laterality,
                                   ip.id_professional id_prof_performed,
                                   ip.id_institution id_inst_performed,
                                   nvl(pea.id_episode, pea.id_episode_origin) id_episode,
                                   pk_sysdomain.get_rank(i_lang, 'INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det) rank
                              FROM procedures_ea pea
                             INNER JOIN interv_prescription ip
                                ON ip.id_interv_prescription = pea.id_interv_prescription
                             INNER JOIN interv_presc_det ipd
                                ON ipd.id_interv_presc_det = pea.id_interv_presc_det
                             INNER JOIN intervention i
                                ON i.id_intervention = pea.id_intervention
                             WHERE pea.flg_status_det IN (pk_procedures_constant.g_interv_not_ordered,
                                                          pk_procedures_constant.g_interv_req,
                                                          pk_procedures_constant.g_interv_plan_pending,
                                                          pk_procedures_constant.g_interv_sched,
                                                          pk_procedures_constant.g_interv_partial)) proc
                     INNER JOIN (SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_episode = l_id_episode
                                   AND e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_episode
                                UNION ALL
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_patient
                                UNION ALL
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_visit = l_id_visit
                                   AND e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_visit) epi
                        ON epi.id_episode = proc.id_episode
                     ORDER BY rank, dt_value DESC) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_CDA',
                                              o_error);
            RETURN FALSE;
    END get_procedure_cda;

    FUNCTION get_procedure_detail_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_proc_det   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
        --Content versioned for ALERT-331866 and ALERT-332670
        l_execution_sites table_varchar := table_varchar('EN',
                                                         'FUERA',
                                                         'QUI',
                                                         'UCI',
                                                         'LDRP',
                                                         'PAB_HOSP',
                                                         'CC_AMB',
                                                         'SMU',
                                                         'URG',
                                                         'HOSP_PEN',
                                                         'CUID_CASA',
                                                         'UF_ES');
    
        l_exec_sites_domain VARCHAR2(50) := 'SERVICIO_PROCED_CIRURG';
    
        l_exec_sites_documentation table_varchar := table_varchar('SERV_PROCED', 'SERVICIO_PROCED');
    
    BEGIN
    
        IF i_id_scope IS NULL
           OR i_type_scope IS NULL
        THEN
            g_error := 'Scope id or type is null';
            RAISE g_other_exception;
        END IF;
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_SCOPE_VARS';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_id_scope,
                                              i_scope_type => i_type_scope,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Return pk_touch_option.get_scope_vars: ';
        g_error := g_error || ' o_patient = ' || coalesce(to_char(l_id_patient), '<null>');
        g_error := g_error || ' o_visit = ' || coalesce(to_char(l_id_visit), '<null>');
        g_error := g_error || ' o_episode = ' || coalesce(to_char(l_id_episode), '<null>');
    
        OPEN o_proc_det FOR
            SELECT pea.id_interv_presc_det,
                   pp.id_interv_presc_plan,
                   pea.id_intervention,
                   pk_procedures_api_db.get_alias_translation(i_lang,
                                                              i_prof,
                                                              'INTERVENTION.CODE_INTERVENTION.' || pea.id_intervention,
                                                              NULL) desc_procedure,
                   pk_sysdomain.get_domain('INTERV_PRESCRIPTION.FLG_TIME', pea.flg_time, i_lang) desc_time,
                   pp.dt_take_tstz AS exec_date,
                   (SELECT ic.standard_code
                      FROM interv_codification ic
                     WHERE ic.id_interv_codification = pea.id_interv_codification) AS standard_code,
                   (SELECT c.id_map_set
                      FROM interv_codification ic
                      JOIN codification c
                        ON c.id_codification = ic.id_codification
                     WHERE ic.id_interv_codification = pea.id_interv_codification) AS id_map_set,
                   pp.id_prof_take AS id_exec_prof,
                   prof.num_order AS affiliation_number,
                   prof.first_name AS exec_prof_first_name,
                   prof.middle_name AS exec_prof_middle_name,
                   prof.last_name AS exec_prof_last_name,
                   ed.notes AS exec_notes,
                   dec.id_content AS id_exec_site,
                   ded.val AS val_exec_site,
                   CASE
                        WHEN ded.val IS NOT NULL THEN
                         ded.desc_val
                        WHEN dec.code_element_close IS NOT NULL THEN
                         pk_translation.get_translation(i_lang, dec.code_element_close)
                        ELSE
                         NULL
                    END AS desc_exec_site
              FROM procedures_ea pea
              JOIN interv_presc_plan pp
                ON pp.id_interv_presc_det = pea.id_interv_presc_det
              LEFT JOIN epis_documentation ed
                ON ed.id_epis_documentation = pp.id_epis_documentation
              LEFT JOIN epis_documentation_det edd
                ON edd.id_epis_documentation = ed.id_epis_documentation
              LEFT JOIN doc_element_crit DEC
                ON dec.id_doc_element_crit = edd.id_doc_element_crit
              LEFT JOIN doc_element de
                ON de.id_doc_element = dec.id_doc_element
              LEFT JOIN documentation d
                ON d.id_documentation = de.id_documentation
               AND d.internal_name IN (SELECT *
                                         FROM TABLE(l_exec_sites_documentation))
              LEFT JOIN doc_element_domain ded
                ON ded.val = edd.value
               AND ded.code_element_domain = l_exec_sites_domain
               AND ded.id_language = i_lang
              LEFT JOIN professional prof
                ON prof.id_professional = pp.id_prof_take
             INNER JOIN (SELECT e.id_episode
                           FROM episode e
                          WHERE e.id_episode = l_id_episode
                            AND e.id_patient = l_id_patient
                            AND i_type_scope = pk_alert_constant.g_scope_type_episode
                         UNION ALL
                         SELECT e.id_episode
                           FROM episode e
                          WHERE e.id_patient = l_id_patient
                            AND i_type_scope = pk_alert_constant.g_scope_type_patient
                         UNION ALL
                         SELECT e.id_episode
                           FROM episode e
                          WHERE e.id_visit = l_id_visit
                            AND e.id_patient = l_id_patient
                            AND i_type_scope = pk_alert_constant.g_scope_type_visit) epi
                ON (epi.id_episode = pea.id_episode OR epi.id_episode = pea.id_episode_origin)
             WHERE pp.flg_status NOT IN (pk_procedures_constant.g_interv_cancel)
               AND pp.dt_take_tstz IS NOT NULL
               AND (upper(de.internal_name) IN (SELECT *
                                                  FROM TABLE(l_execution_sites)) OR dec.id_content IS NULL)
             ORDER BY pp.id_interv_presc_det DESC, pp.id_interv_presc_plan DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_DETAIL_CDA',
                                              o_error);
            RETURN FALSE;
        
    END get_procedure_detail_cda;

    PROCEDURE reset_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION reset_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient_count NUMBER;
        l_episode_count NUMBER;
    
        l_id_interv_evaluation     table_number;
        l_id_icf                   table_number;
        l_id_interv_prescription   table_number;
        l_id_interv_presc_det      table_number;
        l_id_epis_interv           table_number;
        l_id_interv_presc_plan     table_number;
        l_id_schedule_intervention table_number;
        l_id_interv_presc_plan2    table_number;
    
    BEGIN
    
        l_patient_count := i_patient.count;
        l_episode_count := i_episode.count;
    
        -- checks if the delete process can be executed
        IF l_patient_count = 0
           AND l_episode_count = 0
        THEN
            g_error := 'EMPTY ARRAYS FOR I_PATIENT AND I_EPISODE';
            RETURN FALSE;
        END IF;
    
        ------------------------------------------------------------------------  
        --INTERV_ICNP_EA
        ------------------------------------------------------------------------  
        -- remove data from INTERV_ICNP_EA
        g_error := 'INTERV_ICNP_EA DELETE ERROR';
        DELETE FROM interv_icnp_ea iiea
         WHERE iiea.id_episode IN (SELECT /*+ opt_estimate(table epis rows = 1)*/
                                    *
                                     FROM TABLE(i_episode) epis)
            OR (iiea.id_episode IS NULL AND
               iiea.id_patient IN (SELECT /*+ opt_estimate(table pat rows = 1)*/
                                     *
                                      FROM TABLE(i_patient) pat));
    
        ------------------------------------------------------------------------    
        --INTERV_EVALUATION
        ------------------------------------------------------------------------
        -- selects the lists of all INTERV_EVALUATION ids to be removed
        g_error := 'INTERV_EVALUATION BULK COLLECT ERROR';
        SELECT ie.id_interv_evaluation
          BULK COLLECT
          INTO l_id_interv_evaluation
          FROM interv_evaluation ie
         WHERE ie.id_episode IN (SELECT /*+ opt_estimate(table epis rows = 1)*/
                                  *
                                   FROM TABLE(i_episode) epis)
            OR (ie.id_episode IS NULL AND
               ie.id_patient IN (SELECT /*+ opt_estimate(table pat rows = 1)*/
                                   *
                                    FROM TABLE(i_patient) pat));
    
        -- selects the lists of all INTERV_EVALUATION_ICF ids to be removed
        g_error := 'INTERV_EVALUATION_ICF BULK COLLECT ERROR';
        SELECT ieif.id_icf
          BULK COLLECT
          INTO l_id_icf
          FROM interv_evaluation_icf ieif
         WHERE ieif.id_interv_evaluation IN (SELECT /*+ opt_estimate(table ie rows = 1)*/
                                              *
                                               FROM TABLE(l_id_interv_evaluation) ie);
    
        -- remove data from INTERV_EVAL_ICF_QUALIF
        g_error := 'INTERV_EVAL_ICF_QUALIF DELETE ERROR';
        DELETE FROM interv_eval_icf_qualif ieiq
         WHERE ieiq.id_icf IN (SELECT /*+ opt_estimate(table icf rows = 1)*/
                                *
                                 FROM TABLE(l_id_icf) icf);
    
        -- remove data from INTERV_EVALUATION_ICF
        g_error := 'INTERV_EVALUATION_ICF DELETE ERROR';
        DELETE FROM interv_evaluation_icf ieif
         WHERE ieif.id_interv_evaluation IN (SELECT /*+ opt_estimate(table ie rows = 1)*/
                                              *
                                               FROM TABLE(l_id_interv_evaluation) ie);
    
        -- remove data from INTERV_EVALUATION
        g_error := 'INTERV_EVALUATION DELETE ERROR';
        DELETE FROM interv_evaluation ie
         WHERE ie.id_interv_evaluation IN (SELECT /*+ opt_estimate(table ie rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_evaluation) ie);
    
        ------------------------------------------------------------------------    
        --INTERV_PRESCRIPTION
        ------------------------------------------------------------------------
        -- selects the lists of all INTERV_PRESCRIPTION ids to be removed
        g_error := 'INTERV_PRESCRIPTION BULK COLLECT ERROR';
        SELECT ip.id_interv_prescription
          BULK COLLECT
          INTO l_id_interv_prescription
          FROM interv_prescription ip
         WHERE ip.id_episode IN (SELECT /*+ opt_estimate(table epis rows = 1)*/
                                  *
                                   FROM TABLE(i_episode) epis)
            OR (ip.id_episode IS NULL AND
               ip.id_patient IN (SELECT /*+ opt_estimate(table pat rows = 1)*/
                                   *
                                    FROM TABLE(i_patient) pat));
    
        -- selects the lists of all INTERV_PRESC_DET ids to be removed
        g_error := 'INTERV_PRESC_DET BULK COLLECT ERROR';
        SELECT ipd.id_interv_presc_det
          BULK COLLECT
          INTO l_id_interv_presc_det
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_prescription IN (SELECT /*+ opt_estimate(table ip rows = 1)*/
                                               *
                                                FROM TABLE(l_id_interv_prescription) ip);
    
        -- selects the lists of all EPIS_INTERV ids to be removed
        g_error := 'EPIS_INTERV BULK COLLECT ERROR';
        SELECT ei.id_epis_interv
          BULK COLLECT
          INTO l_id_epis_interv
          FROM epis_interv ei
         WHERE ei.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                           *
                                            FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from PROF_EPIS_INTERV
        g_error := 'PROF_EPIS_INTERV DELETE ERROR';
        DELETE FROM prof_epis_interv pei
         WHERE pei.id_epis_interv IN (SELECT /*+ opt_estimate(table ei rows = 1)*/
                                       *
                                        FROM TABLE(l_id_epis_interv) ei);
    
        -- remove data from EPIS_INTERV
        g_error := 'EPIS_INTERV DELETE ERROR';
        DELETE FROM epis_interv ei
         WHERE ei.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                           *
                                            FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from INTERV_PAT_PROBLEM
        g_error := 'INTERV_PAT_PROBLEM DELETE ERROR';
        DELETE FROM interv_pat_problem ipp
         WHERE ipp.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from INTERV_PRESC_DET_CONTEXT
        g_error := 'INTERV_PRESC_DET_CONTEXT DELETE ERROR';
        DELETE FROM interv_presc_det_context ipdc
         WHERE ipdc.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                             *
                                              FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from INTERV_QUESTION_RESPONSE_HIST
        g_error := 'INTERV_QUESTION_RESPONSE_HIST DELETE ERROR';
        DELETE FROM interv_question_response_hist iqrh
         WHERE iqrh.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                             *
                                              FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from INTERV_QUESTION_RESPONSE
        g_error := 'INTERV_QUESTION_RESPONSE DELETE ERROR';
        DELETE FROM interv_question_response iqr
         WHERE iqr.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from INTERV_MEDIA_ARCHIVE
        g_error := 'INTERV_MEDIA_ARCHIVE DELETE ERROR';
        DELETE FROM interv_media_archive ima
         WHERE ima.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from INTERV_PRESC_DET_HIST
        g_error := 'INTERV_PRESC_DET_HIST DELETE ERROR';
        DELETE FROM interv_presc_det_hist ipdh
         WHERE ipdh.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                             *
                                              FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- selects the lists of all INTERV_PRESC_PLAN ids to be removed
        g_error := 'INTERV_PRESC_PLAN BULK COLLECT ERROR';
        SELECT ipp.id_interv_presc_plan
          BULK COLLECT
          INTO l_id_interv_presc_plan
          FROM interv_presc_plan ipp
         WHERE ipp.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        g_error := 'INTERV_MEDIA_ARCHIVE DELETE ERROR';
        DELETE FROM interv_media_archive ima
         WHERE ima.id_interv_presc_plan IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                             *
                                              FROM TABLE(l_id_interv_presc_plan) ipd);
    
        -- remove data from INTERV_PRESC_PLAN_HIST
        g_error := 'INTERV_PRESC_PLAN_HIST DELETE ERROR';
        DELETE FROM interv_presc_plan_hist ipph
         WHERE ipph.id_interv_presc_plan IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                              *
                                               FROM TABLE(l_id_interv_presc_plan) ipd);
    
        -- remove data from INTERV_PP_MODIFIERS
        g_error := 'INTERV_PP_MODIFIERS DELETE ERROR';
        DELETE FROM interv_pp_modifiers ippm
         WHERE ippm.id_interv_presc_plan IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                              *
                                               FROM TABLE(l_id_interv_presc_plan) ipd);
    
        -- remove data from INTERV_TIME_OUT
        g_error := 'INTERV_TIME_OUT DELETE ERROR';
        DELETE FROM interv_time_out ito
         WHERE ito.id_interv_presc_plan IN (SELECT /*+ opt_estimate(table ipp rows = 1)*/
                                             *
                                              FROM TABLE(l_id_interv_presc_plan) ipp);
    
        -- remove data from INTERV_TIME_OUT
        g_error := 'INTERV_TIME_OUT DELETE ERROR';
        DELETE FROM interv_time_out ito
         WHERE ito.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from INTERV_PROF_ALLOC
        g_error := 'INTERV_PROF_ALLOC DELETE ERROR';
        DELETE FROM interv_prof_alloc ipa
         WHERE ipa.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from MCDT_REQ_DIAGNOSIS
        g_error := 'MCDT_REQ_DIAGNOSIS DELETE ERROR';
        DELETE FROM mcdt_req_diagnosis mrd
         WHERE mrd.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from P1_EXR_INTERVENTION
        g_error := 'P1_EXR_INTERVENTION DELETE ERROR';
        DELETE FROM p1_exr_intervention p1ei
         WHERE p1ei.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                             *
                                              FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from P1_EXR_TEMP
        g_error := 'P1_EXR_TEMP DELETE ERROR';
        DELETE FROM p1_exr_temp p1et
         WHERE p1et.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                             *
                                              FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from REP_MFR_NOTIFICATION
        g_error := 'REP_MFR_NOTIFICATION DELETE ERROR';
        DELETE FROM rep_mfr_notification rmn
         WHERE rmn.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- selects the lists of all SCHEDULE_INTERVENTION ids to be removed
        g_error := 'SCHEDULE_INTERVENTION BULK COLLECT ERROR';
        SELECT si.id_schedule_intervention
          BULK COLLECT
          INTO l_id_schedule_intervention
          FROM schedule_intervention si
         WHERE si.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                           *
                                            FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- selects the lists of all INTERV_PRESC_PLAN ids to be removed
        g_error := 'INTERV_PRESC_PLAN BULK COLLECT ERROR';
        SELECT ipp.id_interv_presc_plan
          BULK COLLECT
          INTO l_id_interv_presc_plan2
          FROM interv_presc_plan ipp
         WHERE ipp.id_schedule_intervention IN
               (SELECT /*+ opt_estimate(table si rows = 1)*/
                 *
                  FROM TABLE(l_id_schedule_intervention) si);
    
        -- remove data from INTERV_PRESC_PLAN_HIST
        g_error := 'INTERV_PRESC_PLAN_HIST DELETE ERROR';
        DELETE FROM interv_presc_plan_hist ipph
         WHERE ipph.id_interv_presc_plan IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                              *
                                               FROM TABLE(l_id_interv_presc_plan2) ipd);
    
        -- remove data from INTERV_TIME_OUT
        g_error := 'INTERV_TIME_OUT DELETE ERROR';
        DELETE FROM interv_time_out ito
         WHERE ito.id_interv_presc_plan IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                             *
                                              FROM TABLE(l_id_interv_presc_plan2) ipd);
    
        -- remove data from INTERV_PRESC_PLAN
        g_error := 'INTERV_PRESC_PLAN DELETE ERROR';
        DELETE FROM interv_presc_plan ipp
         WHERE ipp.id_schedule_intervention IN
               (SELECT /*+ opt_estimate(table si rows = 1)*/
                 *
                  FROM TABLE(l_id_schedule_intervention) si);
    
        -- remove data from INTERV_PRESC_PLAN
        g_error := 'INTERV_PRESC_PLAN DELETE ERROR';
        DELETE FROM interv_presc_plan ipp
         WHERE ipp.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from SCHEDULE_INTERVENTION
        g_error := 'SCHEDULE_INTERVENTION DELETE ERROR';
        DELETE FROM schedule_intervention si
         WHERE si.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                           *
                                            FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from SUSP_TASK_PHYSIOTHERAPY
        g_error := 'SUSP_TASK_PHYSIOTHERAPY DELETE ERROR';
        DELETE FROM susp_task_physiotherapy stp
         WHERE stp.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from SUSP_TASK_PROCEDURES
        g_error := 'SUSP_TASK_PROCEDURES DELETE ERROR';
        DELETE FROM susp_task_procedures stp
         WHERE stp.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from INTERV_PRESC_DET
        g_error := 'INTERV_PRESC_DET DELETE ERROR';
        DELETE FROM interv_presc_det ip
         WHERE ip.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                           *
                                            FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from PROCEDURES_EA
        g_error := 'PROCEDURES_EA DELETE ERROR';
        DELETE FROM procedures_ea pea
         WHERE pea.id_interv_presc_det IN (SELECT /*+ opt_estimate(table ipd rows = 1)*/
                                            *
                                             FROM TABLE(l_id_interv_presc_det) ipd);
    
        -- remove data from INTERV_PRESC_DET_HIST
        g_error := 'INTERV_PRESC_DET_HIST DELETE ERROR';
        DELETE FROM interv_presc_det_hist ipdh
         WHERE ipdh.id_interv_prescription IN
               (SELECT /*+ opt_estimate(table ip rows = 1)*/
                 *
                  FROM TABLE(l_id_interv_prescription) ip);
    
        -- remove data from MCDT_REQ_DIAGNOSIS
        g_error := 'MCDT_REQ_DIAGNOSIS DELETE ERROR';
        DELETE FROM mcdt_req_diagnosis mrd
         WHERE mrd.id_interv_prescription IN (SELECT /*+ opt_estimate(table ip rows = 1)*/
                                               *
                                                FROM TABLE(l_id_interv_prescription) ip);
    
        -- remove data from INTERV_PRESCRIPTION
        g_error := 'INTERV_PRESCRIPTION DELETE ERROR';
        DELETE FROM interv_prescription ip
         WHERE ip.id_interv_prescription IN (SELECT /*+ opt_estimate(table ip rows = 1)*/
                                              *
                                               FROM TABLE(l_id_interv_prescription) ip);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'RESET_PROCEDURES',
                                              o_error);
            RETURN FALSE;
    END reset_procedures;

    PROCEDURE system__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION inactivate_procedures_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cfg_across_care_settings sys_config.value%TYPE := pk_sysconfig.get_config('INACTIVATE_PROCEDURES_FLG_TIME_ACROSS',
                                                                                    i_prof);
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config('INACTIVATE_CANCEL_REASON', i_prof);
    
        l_descontinued_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_DISCONTINUED_REASON',
                                                                            i_prof    => i_prof);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(NULL,
                                                                                    profissional(0, i_inst, 0),
                                                                                    'PROCEDURES_INACTIVATE');
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_descontinued_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                                    i_prof,
                                                                                                    l_descontinued_cfg);
    
        l_num_takes NUMBER;
        l_reason_id cancel_reason.id_cancel_reason%TYPE;
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_send_cancel_event sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                 i_code_cf => 'SEND_CANCEL_EVENT'),
                                                         pk_alert_constant.g_yes);
    
        l_interv_presc_det table_number;
        l_initial_status   table_varchar;
    
        l_rows_out table_varchar;
    
        l_error t_error_out;
    
        l_tbl_across_cfg table_varchar;
        l_across_time    VARCHAR2(10 CHAR);
        l_across_unit    VARCHAR2(15 CHAR);
    
        l_tbl_error_ids table_number := table_number();
    
        --The cursor will not fetch the records for the ids (id_interv_presc_det) sent in i_ids_exclude
        CURSOR c_interv_req_det(ids_exclude IN table_number) IS
            SELECT *
              FROM (SELECT ipd.id_interv_presc_det, ipd.flg_status
                      FROM interv_prescription ip
                     INNER JOIN interv_presc_det ipd
                        ON ipd.id_interv_prescription = ip.id_interv_prescription
                      LEFT JOIN interv_presc_plan ipp
                        ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
                      LEFT JOIN episode e
                        ON e.id_episode = ip.id_episode
                      LEFT JOIN episode prev_e
                        ON prev_e.id_prev_episode = e.id_episode
                       AND e.id_visit = prev_e.id_visit
                     INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 *
                                  FROM TABLE(l_tbl_config) t) cfg
                        ON cfg.field_01 = ipd.flg_status
                      LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 t.column_value
                                  FROM TABLE(i_ids_exclude) t) t_ids
                        ON t_ids.column_value = ipd.id_interv_presc_det
                     WHERE ip.id_institution = i_inst
                       AND ip.flg_time NOT IN (pk_procedures_constant.g_flg_time_a, pk_procedures_constant.g_flg_time_h)
                       AND ((e.dt_end_tstz IS NOT NULL AND
                           (prev_e.id_episode IS NULL OR prev_e.flg_status = pk_alert_constant.g_inactive) AND
                           pk_date_utils.trunc_insttimezone(i_prof,
                                                              pk_date_utils.add_to_ltstz(e.dt_end_tstz,
                                                                                         cfg.field_02,
                                                                                         cfg.field_03)) <=
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)) OR
                           (e.id_episode IS NULL AND ipd.flg_status = pk_procedures_constant.g_interv_sched AND
                           ip.dt_begin_tstz IS NOT NULL AND
                           pk_date_utils.trunc_insttimezone(i_prof,
                                                              pk_date_utils.add_to_ltstz(ip.dt_begin_tstz,
                                                                                         cfg.field_02,
                                                                                         cfg.field_03)) <=
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)) OR
                           (e.id_episode IS NULL AND ipd.flg_status = pk_procedures_constant.g_interv_tosched AND
                           ip.dt_interv_prescription_tstz IS NOT NULL AND
                           pk_date_utils.trunc_insttimezone(i_prof,
                                                              pk_date_utils.add_to_ltstz(ip.dt_interv_prescription_tstz,
                                                                                         cfg.field_02,
                                                                                         cfg.field_03)) <=
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)) OR
                           (e.dt_end_tstz IS NULL AND e.id_episode IS NOT NULL AND
                           e.id_epis_type = pk_alert_constant.g_epis_type_interv AND
                           pk_date_utils.trunc_insttimezone(i_prof,
                                                              pk_date_utils.add_to_ltstz(ip.dt_begin_tstz,
                                                                                         cfg.field_02,
                                                                                         cfg.field_03)) <=
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)))
                       AND t_ids.column_value IS NULL
                    UNION ALL
                    SELECT ipd.id_interv_presc_det, ipd.flg_status
                      FROM interv_presc_det ipd
                     INNER JOIN interv_prescription ip
                        ON ip.id_interv_prescription = ipd.id_interv_prescription
                     INNER JOIN interv_presc_plan ipp
                        ON ipd.id_interv_presc_det = ipp.id_interv_presc_det
                     INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 *
                                  FROM TABLE(l_tbl_config) t) cfg
                        ON cfg.field_01 = ipd.flg_status
                      LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 t.column_value
                                  FROM TABLE(i_ids_exclude) t) t_ids
                        ON t_ids.column_value = ipd.id_interv_presc_det
                     WHERE ip.flg_time IN (pk_procedures_constant.g_flg_time_a, pk_procedures_constant.g_flg_time_h)
                       AND ipp.flg_status = pk_procedures_constant.g_interv_plan_req
                       AND ipd.flg_status IN (pk_procedures_constant.g_interv_pending,
                                              pk_procedures_constant.g_interv_req,
                                              pk_procedures_constant.g_interv_exec)
                       AND pk_date_utils.trunc_insttimezone(i_prof,
                                                            pk_date_utils.add_to_ltstz(ipp.dt_plan_tstz,
                                                                                       l_across_time,
                                                                                       l_across_unit)) <=
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)
                       AND t_ids.column_value IS NULL) t
             WHERE rownum <= l_max_rows;
    
    BEGIN
    
        l_tbl_across_cfg := pk_string_utils.str_split(i_list => l_cfg_across_care_settings, i_delim => '|');
        l_across_time    := l_tbl_across_cfg(1);
        l_across_unit    := l_tbl_across_cfg(2);
    
        OPEN c_interv_req_det(i_ids_exclude);
        FETCH c_interv_req_det BULK COLLECT
            INTO l_interv_presc_det, l_initial_status;
        CLOSE c_interv_req_det;
    
        o_has_error := FALSE;
    
        IF l_interv_presc_det.count > 0
        THEN
            FOR i IN 1 .. l_interv_presc_det.count
            LOOP
                IF l_initial_status(i) IN (pk_procedures_constant.g_interv_sos, pk_procedures_constant.g_interv_exec)
                THEN
                
                    IF l_initial_status(i) = pk_procedures_constant.g_interv_sos
                    THEN
                        SELECT COUNT(*)
                          INTO l_num_takes
                          FROM interv_presc_plan
                         WHERE id_interv_presc_det = l_interv_presc_det(i)
                           AND flg_status = pk_procedures_constant.g_interv_plan_executed;
                    
                        IF l_num_takes = 0
                        THEN
                            l_reason_id := l_cancel_id;
                        ELSE
                            l_reason_id := l_descontinued_id;
                        END IF;
                    ELSE
                        l_reason_id := l_descontinued_id;
                    END IF;
                ELSE
                    l_reason_id := l_cancel_id;
                END IF;
            
                SAVEPOINT init_cancel;
                IF NOT pk_procedures_external.cancel_procedure_task(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_interv_presc_det => table_number(l_interv_presc_det(i)),
                                                                    i_dt_cancel        => NULL,
                                                                    i_cancel_reason    => l_reason_id,
                                                                    i_cancel_notes     => NULL,
                                                                    i_prof_order       => NULL,
                                                                    i_dt_order         => NULL,
                                                                    i_order_type       => NULL,
                                                                    i_flg_cancel_event => l_send_cancel_event,
                                                                    o_error            => l_error)
                THEN
                    ROLLBACK TO init_cancel;
                
                    --If, for the given id_interv_presc_det, an error is generated, o_has_error is set as TRUE,
                    --this way, the loop cicle may continue, but the system will know that at least one error has happened
                    o_has_error := TRUE;
                
                    --A log for the id_interv_presc_det that raised the error must be generated 
                    pk_alert_exceptions.reset_error_state;
                    g_error := 'ERROR CALLING PK_PROCEDURES_EXTERNAL.CANCEL_PROCEDURE_TASK FOR RECORD ' ||
                               l_interv_presc_det(i);
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'INACTIVATE_PROCEDURES_TASKS',
                                                      o_error);
                
                    --The array for the ids (id_exam_req_det) that raised the error is incremented
                    l_tbl_error_ids.extend();
                    l_tbl_error_ids(l_tbl_error_ids.count) := l_interv_presc_det(i);
                
                    CONTINUE;
                END IF;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_exam_req_det has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_ids.first .. l_tbl_error_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_exam_req_det) that could not
                    --be inactivated with the current call of the function
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_ids(i);
                END LOOP;
            
                --Since no inactivations were performed with the current call, a new call to this function is performed,
                --however, this time, the array i_ids_exclude will include a list of ids that cannot be fetched by the cursor
                --on the next call. The recursion will be perfomed until at least one record is inactivated, or the cursor
                --has no more records to fetch.
                --Note: i_ids_exclude is incremented and is an IN OUT parameter, therefore, 
                --it will hold all the ids that were not inactivated from ALL calls.            
                IF NOT pk_procedures_external.inactivate_procedures_tasks(i_lang        => i_lang,
                                                                          i_prof        => i_prof,
                                                                          i_inst        => i_inst,
                                                                          i_ids_exclude => i_ids_exclude,
                                                                          o_has_error   => o_has_error,
                                                                          o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INACTIVATE_PROCEDURES_TASKS',
                                              o_error);
            RETURN FALSE;
    END inactivate_procedures_tasks;

    FUNCTION set_grid_task_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_grid_task      grid_task%ROWTYPE;
        l_grid_task_betw grid_task_between%ROWTYPE;
    
        l_id_patient patient.id_patient%TYPE;
    
        l_shortcut sys_shortcut.id_sys_shortcut%TYPE;
    
        l_dt_str_1 VARCHAR2(200 CHAR);
        l_dt_str_2 VARCHAR2(200 CHAR);
    
        l_dt_1 VARCHAR2(200 CHAR);
        l_dt_2 VARCHAR2(200 CHAR);
    
        l_error_out t_error_out;
    
    BEGIN
    
        SELECT id_patient
          INTO l_id_patient
          FROM episode
         WHERE id_episode = i_episode;
    
        FOR r_cur IN (SELECT *
                        FROM (SELECT DISTINCT nvl(ip.id_episode, ip.id_episode_origin) id_episode,
                                              ip.id_patient,
                                              ip.flg_time
                                FROM interv_presc_det ipd
                                JOIN interv_prescription ip
                                  ON ipd.id_interv_prescription = ip.id_interv_prescription
                               WHERE ip.id_patient = l_id_patient
                                 AND ip.flg_time IN
                                     (pk_procedures_constant.g_flg_time_a, pk_procedures_constant.g_flg_time_h)
                                 AND ipd.flg_status NOT IN
                                     (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_interv_finished)))
        LOOP
            SELECT MAX(status_string) status_string, MAX(flg_interv) flg_interv
              INTO l_grid_task.intervention, l_grid_task_betw.flg_interv
              FROM (SELECT decode(rank,
                                  1,
                                  pk_utils.get_status_string(i_lang,
                                                             i_prof,
                                                             pk_ea_logic_procedures.get_procedure_status_str(i_lang,
                                                                                                             i_prof,
                                                                                                             id_episode,
                                                                                                             flg_time,
                                                                                                             flg_status_det,
                                                                                                             flg_prn,
                                                                                                             flg_referral,
                                                                                                             dt_req_tstz,
                                                                                                             dt_begin_tstz,
                                                                                                             dt_plan_tstz,
                                                                                                             id_order_recurr_option),
                                                             pk_ea_logic_procedures.get_procedure_status_msg(i_lang,
                                                                                                             i_prof,
                                                                                                             id_episode,
                                                                                                             flg_time,
                                                                                                             flg_status_det,
                                                                                                             flg_prn,
                                                                                                             flg_referral,
                                                                                                             dt_req_tstz,
                                                                                                             dt_begin_tstz,
                                                                                                             dt_plan_tstz,
                                                                                                             id_order_recurr_option),
                                                             pk_ea_logic_procedures.get_procedure_status_icon(i_lang,
                                                                                                              i_prof,
                                                                                                              id_episode,
                                                                                                              flg_time,
                                                                                                              flg_status_det,
                                                                                                              flg_prn,
                                                                                                              flg_referral,
                                                                                                              dt_req_tstz,
                                                                                                              dt_begin_tstz,
                                                                                                              dt_plan_tstz,
                                                                                                              id_order_recurr_option),
                                                             pk_ea_logic_procedures.get_procedure_status_flg(i_lang,
                                                                                                             i_prof,
                                                                                                             id_episode,
                                                                                                             flg_time,
                                                                                                             flg_status_det,
                                                                                                             flg_prn,
                                                                                                             flg_referral,
                                                                                                             dt_req_tstz,
                                                                                                             dt_begin_tstz,
                                                                                                             dt_plan_tstz,
                                                                                                             id_order_recurr_option)),
                                  NULL) status_string,
                           decode(rank,
                                  1,
                                  decode(flg_time, pk_procedures_constant.g_flg_time_b, pk_procedures_constant.g_yes),
                                  NULL) flg_interv
                      FROM (SELECT t.id_interv_presc_det,
                                   t.id_episode,
                                   t.flg_time,
                                   t.flg_prn,
                                   t.flg_status_req,
                                   t.flg_status_det,
                                   t.flg_referral,
                                   t.dt_req_tstz,
                                   t.dt_begin_tstz,
                                   t.dt_plan_tstz,
                                   t.id_order_recurr_option,
                                   row_number() over(ORDER BY t.rank) rank
                              FROM (SELECT t.*,
                                           decode(t.flg_status_det,
                                                  pk_procedures_constant.g_interv_req,
                                                  row_number()
                                                  over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                             'INTERV_PRESC_DET.FLG_STATUS',
                                                                             t.flg_status_det),
                                                       coalesce(t.dt_plan_tstz, t.dt_begin_tstz, t.dt_req_tstz)),
                                                  row_number()
                                                  over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                             'INTERV_PRESC_DET.FLG_STATUS',
                                                                             t.flg_status_det),
                                                       coalesce(t.dt_plan_tstz, t.dt_begin_tstz, t.dt_req_tstz)) + 20000) rank
                                      FROM (SELECT ipd.id_interv_presc_det,
                                                   ip.id_episode,
                                                   ip.flg_time,
                                                   ipd.flg_prn,
                                                   ip.flg_status                  flg_status_req,
                                                   ipd.flg_status                 flg_status_det,
                                                   ipd.flg_referral,
                                                   ip.dt_interv_prescription_tstz dt_req_tstz,
                                                   ip.dt_begin_tstz,
                                                   ipp.dt_plan_tstz,
                                                   orp.id_order_recurr_option
                                              FROM interv_prescription ip,
                                                   interv_presc_det    ipd,
                                                   interv_presc_plan   ipp,
                                                   order_recurr_plan   orp,
                                                   episode             e
                                             WHERE (ip.id_episode = r_cur.id_episode OR
                                                   ip.id_prev_episode = r_cur.id_episode OR
                                                   ip.id_episode_origin = r_cur.id_episode OR
                                                   (ip.id_patient = r_cur.id_patient AND
                                                   r_cur.flg_time IN
                                                   (pk_procedures_constant.g_flg_time_a,
                                                      pk_procedures_constant.g_flg_time_h)))
                                               AND ip.id_interv_prescription = ipd.id_interv_prescription
                                               AND ipd.flg_status IN
                                                   (pk_procedures_constant.g_interv_sos,
                                                    pk_procedures_constant.g_interv_exterior,
                                                    pk_procedures_constant.g_interv_tosched,
                                                    pk_procedures_constant.g_interv_pending,
                                                    pk_procedures_constant.g_interv_req,
                                                    pk_procedures_constant.g_interv_exec,
                                                    pk_procedures_constant.g_interv_partial)
                                               AND (ipd.flg_referral NOT IN
                                                   (pk_procedures_constant.g_flg_referral_r,
                                                     pk_procedures_constant.g_flg_referral_s,
                                                     pk_procedures_constant.g_flg_referral_i) OR ipd.flg_referral IS NULL)
                                               AND ipd.id_interv_presc_det = ipp.id_interv_presc_det
                                               AND ipp.flg_status IN
                                                   (pk_procedures_constant.g_interv_plan_pending,
                                                    pk_procedures_constant.g_interv_plan_req)
                                               AND ipd.id_order_recurrence = orp.id_order_recurr_plan(+)
                                               AND (ip.id_episode = e.id_episode OR ip.id_prev_episode = e.id_episode OR
                                                   ip.id_episode_origin = e.id_episode)) t) t)
                     WHERE rank = 1) t;
        
            IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_intern_name => 'GRID_PROC',
                                             o_id_shortcut => l_shortcut,
                                             o_error       => l_error_out)
            THEN
                l_shortcut := 0;
            END IF;
        
            g_error := 'GET SHORTCUT - DOCTOR';
            IF l_grid_task.intervention IS NOT NULL
            THEN
                IF regexp_like(l_grid_task.intervention, '^\|D')
                THEN
                    l_dt_str_1 := regexp_replace(l_grid_task.intervention,
                                                 '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*',
                                                 '\1');
                    l_dt_str_2 := regexp_replace(l_grid_task.intervention,
                                                 '^\|D\w{0,1}\|\d{14}\|.*\|(\d{14})\|.*',
                                                 '\1');
                
                    l_dt_1 := pk_date_utils.to_char_insttimezone(i_prof,
                                                                 pk_date_utils.get_string_tstz(i_lang,
                                                                                               i_prof,
                                                                                               l_dt_str_1,
                                                                                               NULL),
                                                                 'YYYYMMDDHH24MISS TZR');
                
                    l_dt_2 := pk_date_utils.to_char_insttimezone(i_prof,
                                                                 pk_date_utils.get_string_tstz(i_lang,
                                                                                               i_prof,
                                                                                               l_dt_str_2,
                                                                                               NULL),
                                                                 'YYYYMMDDHH24MISS TZR');
                
                    IF l_dt_str_1 = l_dt_str_2
                    THEN
                        l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_1, l_dt_1);
                    ELSE
                        l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_1, l_dt_1);
                        l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_2, l_dt_2);
                    END IF;
                ELSE
                    l_dt_str_2               := regexp_replace(l_grid_task.intervention,
                                                               '^\|\w{0,2}\|.*\|(\d{14})\|.*',
                                                               '\1');
                    l_dt_2                   := pk_date_utils.to_char_insttimezone(i_prof,
                                                                                   pk_date_utils.get_string_tstz(i_lang,
                                                                                                                 i_prof,
                                                                                                                 l_dt_str_2,
                                                                                                                 NULL),
                                                                                   'YYYYMMDDHH24MISS TZR');
                    l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_2, l_dt_2);
                END IF;
            
                l_grid_task.intervention := l_shortcut || l_grid_task.intervention;
            END IF;
        
            l_grid_task.id_episode := i_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_episode        => l_grid_task.id_episode,
                                                intervention_in  => l_grid_task.intervention,
                                                intervention_nin => FALSE,
                                                o_error          => l_error_out)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                IF l_grid_task.intervention IS NULL
                THEN
                    g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode';
                    IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                         i_episode => l_grid_task.id_episode,
                                                         o_error   => l_error_out)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            END IF;
        
            BEGIN
                g_error := 'SELECT ID_PREV_EPISODE';
                SELECT e.id_prev_episode
                  INTO l_grid_task.id_episode
                  FROM episode e
                 WHERE e.id_episode = r_cur.id_episode;
            
                IF l_grid_task.id_episode IS NOT NULL
                THEN
                    g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_prev_episode';
                    IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_episode        => l_grid_task.id_episode,
                                                    intervention_in  => l_grid_task.intervention,
                                                    intervention_nin => FALSE,
                                                    o_error          => l_error_out)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    IF l_grid_task.intervention IS NULL
                    THEN
                        g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_prev_episode';
                        IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                             i_episode => l_grid_task.id_episode,
                                                             o_error   => l_error_out)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            BEGIN
                g_error := 'SELECT ID_EPISODE_ORIGIN';
                SELECT DISTINCT ip.id_episode_origin
                  INTO l_grid_task.id_episode
                  FROM interv_prescription ip
                 WHERE ip.id_episode_origin IS NOT NULL
                   AND ip.id_episode = r_cur.id_episode;
            
                IF l_grid_task.id_episode IS NOT NULL
                THEN
                    g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode_origin';
                    IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_episode        => l_grid_task.id_episode,
                                                    intervention_in  => l_grid_task.intervention,
                                                    intervention_nin => FALSE,
                                                    o_error          => l_error_out)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    IF l_grid_task.intervention IS NULL
                    THEN
                        g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode_origin';
                        IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                             i_episode => l_grid_task.id_episode,
                                                             o_error   => l_error_out)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
            IF l_grid_task_betw.flg_interv = pk_procedures_constant.g_yes
            THEN
                l_grid_task_betw.id_episode := r_cur.id_episode;
            
                --Actualiza estado da tarefa em GRID_TASK_BETWEEN para o epis? correspondente
                g_error := 'CALL PK_GRID.UPDATE_NURSE_TASK';
                IF NOT
                    pk_grid.update_nurse_task(i_lang => i_lang, i_grid_task => l_grid_task_betw, o_error => l_error_out)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task_procedures;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_procedures_external;
/
