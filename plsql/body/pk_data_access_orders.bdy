CREATE OR REPLACE PACKAGE BODY pk_data_access_orders IS

    FUNCTION get_blood_bank
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_blood_products IS
    
        l_table_blood_products t_table_blood_products := t_table_blood_products(NULL);
    
        l_cursor pk_types.cursor_type;
    
        l_sql_header VARCHAR2(32000);
        l_sql_from   VARCHAR2(32000);
        l_sql_inner  VARCHAR2(32000);
        l_sql_footer VARCHAR2(32000);
        l_sql_stmt   CLOB;
        l_curid      INTEGER;
        l_ret        INTEGER;
    
        l_dt_ini      blood_product_det.dt_begin_tstz%TYPE;
        l_dt_end      blood_product_det.dt_begin_tstz%TYPE;
        l_prof        profissional;
        l_institution NUMBER;
        l_lang        sys_config.value%TYPE;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, pk_data_access.k_default_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        pk_data_access.date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        l_curid      := dbms_sql.open_cursor;
        l_sql_header := 'SELECT t_rec_blood_product(id_institution       => id_institution,  ' || --
                        '                           institution_name     => institution_name, ' || --
                        '                           patient_file_number  => patient_file_number, ' || --
                        '                           id_episode           => id_episode, ' || --
                        '                           blood_component      => blood_component, ' || --
                        '                           expiration_date      => expiration_date, ' || --
                        '                           blood_group          => blood_group, ' || --
                        '                           dt_last_update_tstz  => dt_last_update_tstz, ' || --
                        '                           dt_last_update       => dt_last_update) ' || --
                        'FROM (SELECT t.id_episode, ' || --
                        '             t.id_patient, ' || --
                        '             pk_translation.get_translation(id_lang, t.code_hemo_type) blood_component, ' || --
                        '             pk_date_utils.dt_chr_tsz(i_lang => id_lang, ' || --
                        '                                      i_date => t.expiration_date, ' || --
                        '                                      i_inst => l_institution, ' || --
                        '                                      i_soft => 0) expiration_date, ' || --
                        '             (decode(t.blood_group, ' || --
                        '                     NULL, ' || --
                        '                     NULL, ' || --
                        '                     pk_sysdomain.get_domain(id_lang, ' || --
                        '                                             profissional(0, t.id_institution, 0), ' || --
                        '                                             ''PAT_BLOOD_GROUP.FLG_BLOOD_GROUP'', ' || --
                        '                                             t.blood_group, ' || --
                        '                                             NULL)) || '' '' || ' || --
                        '             decode(t.blood_group_rh, ' || --
                        '                     NULL, ' || --
                        '                     NULL, ' || --
                        '                     pk_sysdomain.get_domain(id_lang, ' || --
                        '                                             profissional(0, t.id_institution, 0), ' || --
                        '                                             ''PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS'', ' || --
                        '                                             t.blood_group_rh, ' || --
                        '                                             NULL))) blood_group, ' || --
                        '             t.id_institution, ' || --
                        '             pk_translation.get_translation(id_lang, t.code_institution) institution_name, ' || --
                        '             t.dt_last_update_tstz, ' || --
                        '             pk_date_utils.date_hour_chr(i_lang => id_lang, i_date =>  t.dt_last_update_tstz, i_prof => profissional(0, l_institution, 0)) dt_last_update, ' || --
                        '             pk_data_access.get_process(t.id_patient, t.id_institution) patient_file_number ' || --
                        '        FROM (SELECT bpr.id_blood_product_req, ' || --
                        '                     bpd.id_blood_product_det, ' || --
                        '                     bpr.id_patient, ' || --
                        '                     bpr.id_episode, ' || --
                        '                     bpr.id_institution, ' || --
                        '                     i.code_institution, ' || --
                        '                     ht.code_hemo_type, ' || --
                        '                     bpd.expiration_date, ' || --
                        '                     bpd.blood_group, ' || --
                        '                     bpd.blood_group_rh, ' || --
                        '                     bpd.dt_begin_tstz, ' || --
                        '                     nvl(bpd.update_time, bpd.create_time) dt_last_update_tstz, ' || --
                        '                     :l_lang id_lang, ' || --
                        '                     :l_institution l_institution '; --for date processing
    
        l_sql_from := 'FROM blood_product_det bpd ' || --
                      'JOIN blood_product_req bpr ' || --
                      '  ON bpr.id_blood_product_req = bpd.id_blood_product_req ' || --
                      'JOIN institution i ' || --
                      '  ON i.id_institution = bpr.id_institution ' || --
                      'JOIN blood_product_execution bpe ' || --
                      '  ON bpe.id_blood_product_det = bpd.id_blood_product_det ' || --
                      ' AND bpe.action = ''LAB_SERVICE'' ' || --
                      'JOIN hemo_type ht ' || --
                      '  ON ht.id_hemo_type = bpd.id_hemo_type) t ' || --
                      'WHERE 1 = 1 ';
    
        l_sql_inner := l_sql_inner || 'AND t.dt_begin_tstz >= :l_dt_ini ';
        l_sql_inner := l_sql_inner || 'AND t.dt_begin_tstz <= :l_dt_end ';
    
        IF i_institution IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND id_institution = :i_institution ';
        END IF;
    
        l_sql_footer := l_sql_footer || ' ORDER BY t.dt_begin_tstz) ';
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner || l_sql_footer);
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        dbms_sql.bind_variable(l_curid, 'l_lang', l_lang);
        dbms_sql.bind_variable(l_curid, 'l_institution', l_institution);
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_table_blood_products;
    
        RETURN l_table_blood_products;
    
    END get_blood_bank;

    FUNCTION get_surgery_query
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL,
        i_sql_count   VARCHAR2
    ) RETURN CLOB AS
    
        l_sql_header VARCHAR2(32000);
        l_sql_from   VARCHAR2(32000);
        l_sql_inner  VARCHAR2(32000);
        l_sql_footer VARCHAR2(32000);
        l_sql_stmt   CLOB;
    
    BEGIN
    
        IF i_sql_count = pk_alert_constant.g_no
        THEN
            l_sql_header := 'SELECT t_rec_surgery(id_institution      => t.id_institution, ' || --
                            '                     institution_name    => t.institution_name, ' || --
                            '                     patient_file_number => t.num_clin_record, ' || --
                            '                     id_episode          => t.id_episode, ' || --
                            '                     id_epis_type        => t.id_epis_type, ' || --
                            '                     desc_epis_type      => t.desc_epis_type, ' || --
                            '                     requisition_date    => t.requisition_date, ' || --
                            '                     start_date          => t.start_date, ' || --
                            '                     end_date            => t.end_date, ' || --
                            '                     desc_surgery        => t.desc_surgery, ' || --
                            '                     code_surgery        => t.code_surgery, ' || --
                            '                     desc_room           => t.desc_room, ' || --
                            '                     id_room             => t.id_room, ' || --
                            '                     priority            => t.priority, ' || --
                            '                     code_priority       => t.code_priority, ' || --
                            '                     anesthesia          => t.anesthesia, ' || --
                            '                     code_anesthesia     => t.code_anesthesia, ' || --
                            '                     initial_diagnosis   => t.initial_diagnosis, ' || --
                            '                     secondary_diagnosis => t.secondary_diagnosis, ' || --
                            '                     final_diagnosis     => t.final_diagnosis, ' || --
                            '                     dt_last_update_tstz => t.dt_last_update_tstz, ' || --
                            '                     dt_last_update      => t.dt_last_update) ' || --
                            '  FROM (SELECT DISTINCT ss.id_episode, ' || --
                            '               epis_init.id_epis_type , ' || --
                            '               pk_translation.get_translation(:l_lang, ''EPIS_TYPE.CODE_EPIS_TYPE.'' || epis_init.id_epis_type) desc_epis_type, ' || --      
                            '               pk_date_utils.date_hour_chr(:l_lang, ss.dt_interv_preview_tstz, profissional(0, :l_institution, 0)) requisition_date, ' || --
                            '               pk_date_utils.date_hour_chr(:l_lang, st.dt_interv_start_tstz, profissional(0, :l_institution, 0)) start_date, ' || --
                            '               pk_date_utils.date_hour_chr(:l_lang, et.dt_interv_end_tstz, profissional(0, :l_institution, 0)) end_date, ' || --
                            '               pk_sr_clinical_info.get_proposed_surgery(:l_lang, ' || --
                            '                                                        ss.id_episode, ' || --
                            '                                                        profissional(NULL, ss.id_institution, 0), ' || --
                            '                                                        ''N'') desc_surgery,                ' || --
                            '               intv.id_content code_surgery, ' || --
                            '               pk_translation.get_translation(:l_lang, r.code_room) desc_room, ' || --
                            '               r.id_room, ' || --
                            '               pk_data_access.get_process(ss.id_patient, ss.id_institution) num_clin_record, ' || --
                            '               nvl(wul.desc_wtl_urg_level, pk_sysdomain.get_domain(''SR_SURGERY_RECORD.FLG_URGENCY'', ''U'', :l_lang)) priority, ' || --
                            '               nvl2(wul.desc_wtl_urg_level, wul.code, ''U'') code_priority, ' || --
                            '               pk_touch_option.get_template_value(i_lang            => :l_lang, ' || --
                            '                                                  i_prof            => profissional(NULL, ss.id_institution, 0), ' || --
                            '                                                  i_patient         => ss.id_patient, ' || --
                            '                                                  i_episode         => ss.id_episode, ' || --
                            '                                                  i_doc_area        => 9, ' || --
                            '                                                  i_doc_int_name    => ''anesthesia.1'', ' || --
                            '                                                  i_show_id_content => ''N'', ' || --
                            '                                                  i_show_doc_title  => ''N'') anesthesia, ' || --
                            '               pk_data_access.get_diag_initial_icd_code(epis.id_prev_episode) initial_diagnosis, ' || --
                            '               pk_data_access.get_diag_secondary_icd_code(epis.id_prev_episode) secondary_diagnosis, ' || --
                            '               pk_data_access.get_diag_final_icd_code(epis.id_prev_episode) final_diagnosis, ' || --
                            '               i.id_institution, ' || --
                            '               pk_translation.get_translation(:l_lang, i.code_institution) institution_name, ' || --
                            '               nvl(sei.update_time, sei.create_time) dt_last_update_tstz, ' || --
                            '               pk_date_utils.date_hour_chr(:l_lang, ' || --
                            '                                           nvl(sei.update_time, sei.create_time), ' || --
                            '                                           profissional(0, :l_institution, 0)) dt_last_update, ' || --
                            '               pk_data_access.array_to_var(CAST(MULTISET (SELECT dec.id_content ' || --
                            '                                                   FROM epis_documentation ed ' || --
                            '                                                   JOIN epis_documentation_det edd ' || --
                            '                                                     ON edd.id_epis_documentation = ed.id_epis_documentation ' || --
                            '                                                   JOIN doc_element_crit DEC ' || --
                            '                                                     ON dec.id_doc_element_crit = edd.id_doc_element_crit ' || --
                            '                                                   JOIN documentation d ' || --
                            '                                                     ON d.id_documentation = edd.id_documentation ' || --
                            '                                                    AND d.internal_name = ''anesthesia.1'' ' || --
                            '                                                  WHERE ed.id_episode = ss.id_episode ' || --
                            '                                                    AND ed.id_doc_area = 9 ' || --
                            '                                                    AND ed.flg_status = ''A'') AS table_varchar)) code_anesthesia ';
        ELSE
            l_sql_header := 'SELECT count(*) ';
        
        END IF;
        l_sql_from := '          FROM schedule_sr ss ' || --
                      '          JOIN schedule s ' || --
                      '            ON s.id_schedule = ss.id_schedule ' || --
                      '          JOIN sr_surgery_record srsr ' || --
                      '            ON ss.id_schedule_sr = srsr.id_schedule_sr ' || --
                      '          JOIN patient p ' || --
                      '            ON p.id_patient = ss.id_patient ' || --
                      '          JOIN episode epis ' || --
                      '            ON epis.id_episode = ss.id_episode ' || --
                      '          JOIN epis_info ei ' || --
                      '            ON ei.id_episode = epis.id_episode ' || --
                      '          JOIN sr_epis_interv sei ' || --
                      '            ON sei.id_episode_context = epis.id_episode ' || --
                      '          JOIN episode epis_init ' || --
                      '            ON epis_init.id_episode = sei.id_episode ' || --
                      '          JOIN intervention intv ' || --
                      '            ON sei.id_sr_intervention = intv.id_intervention ' || --
                      '          JOIN institution i ' || --
                      '            ON i.id_institution = ss.id_institution ' || --
                      '          LEFT JOIN wtl_epis we ' || --
                      '            ON we.id_episode = ss.id_episode ' || --
                      '          LEFT JOIN waiting_list wl ' || --
                      '            ON wl.id_waiting_list = we.id_waiting_list ' || --
                      '          LEFT JOIN wtl_urg_level wul ' || --
                      '            ON wul.id_wtl_urg_level = wl.id_wtl_urg_level ' || --
                      '          LEFT JOIN room_scheduled sr ' || --
                      '            ON ss.id_schedule = sr.id_schedule ' || --
                      '          LEFT JOIN room r ' || --
                      '            ON sr.id_room = r.id_room ' || --
                      '          LEFT JOIN (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' || --
                      '                      FROM room r ' || --
                      '                      LEFT JOIN sr_room_status s ' || --
                      '                        ON r.id_room = s.id_room ' || --
                      '                     WHERE s.id_sr_room_state = pk_sr_grid.get_last_room_status(s.id_room, ''R'') ' || --
                      '                        OR s.id_sr_room_state IS NULL) m ' || --
                      '            ON m.id_room = sr.id_room ' || --
                      '          LEFT JOIN sr_surgery_record rec ' || --
                      '            ON ss.id_schedule_sr = rec.id_schedule_sr ' || --
                      '          LEFT JOIN grid_task gt ' || --
                      '            ON epis.id_episode = gt.id_episode ' || --
                      '          LEFT JOIN (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz ' || --
                      '                      FROM sr_surgery_time st, sr_surgery_time_det std ' || --
                      '                     WHERE st.id_sr_surgery_time = std.id_sr_surgery_time ' || --
                      '                       AND st.flg_type = ''IC'' ' || --
                      '                       AND std.flg_status = ''A'') st ' || --
                      '            ON epis.id_episode = st.id_episode ' || --
                      '          LEFT JOIN (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_end_tstz ' || --
                      '                      FROM sr_surgery_time st, sr_surgery_time_det std ' || --
                      '                     WHERE st.id_sr_surgery_time = std.id_sr_surgery_time ' || --
                      '                       AND st.flg_type = ''FC'' ' || --
                      '                       AND std.flg_status = ''A'') et ' || --
                      '            ON epis.id_episode = et.id_episode ' || --
                      '         WHERE (sr.id_room_scheduled = pk_sr_grid.get_last_room_status(ss.id_schedule, ''S'') OR ' || --
                      '               sr.id_room_scheduled IS NULL) ' || --
                      '           AND epis.flg_ehr != ''E'' ';
    
        l_sql_inner := '';
    
        l_sql_inner := l_sql_inner || 'AND ss.dt_interv_preview_tstz >= :l_dt_ini ';
        l_sql_inner := l_sql_inner || 'AND ss.dt_interv_preview_tstz <= :l_dt_end ';
    
        IF i_institution IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND ss.id_institution = :i_institution ';
        END IF;
    
        IF i_data IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND intv.id_content IN (SELECT t.column_value FROM TABLE(:l_data) t)';
        
        END IF;
    
        l_sql_footer := l_sql_footer || ' ) t ';
        l_sql_footer := l_sql_footer || ' ORDER BY t.requisition_date ';
    
        IF i_sql_count = pk_alert_constant.g_no
        THEN
            l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner || l_sql_footer);
        ELSE
            l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner);
        END IF;
    
        RETURN l_sql_stmt;
    
    END get_surgery_query;

    FUNCTION get_surgery
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_surgery AS
    
        l_table_surgery t_table_surgery := t_table_surgery(NULL);
    
        l_cursor pk_types.cursor_type;
    
        l_sql_header VARCHAR2(32000);
        l_sql_from   VARCHAR2(32000);
        l_sql_inner  VARCHAR2(32000);
        l_sql_footer VARCHAR2(32000);
        l_sql_stmt   CLOB;
        l_curid      INTEGER;
        l_ret        INTEGER;
    
        l_dt_ini      schedule_sr.dt_interv_preview_tstz%TYPE;
        l_dt_end      schedule_sr.dt_interv_preview_tstz%TYPE;
        l_prof        profissional;
        l_institution NUMBER;
        l_lang        sys_config.value%TYPE;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, pk_data_access.k_default_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        pk_data_access.date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        l_curid := dbms_sql.open_cursor;
    
        l_sql_stmt := get_surgery_query(i_institution, i_dt_ini, i_dt_end, i_data, pk_alert_constant.g_no);
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        dbms_sql.bind_variable(l_curid, 'l_lang', l_lang);
        dbms_sql.bind_variable(l_curid, 'l_institution', l_institution);
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
    
        IF i_data IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'l_data', i_data);
        END IF;
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_table_surgery;
    
        RETURN l_table_surgery;
    
    END get_surgery;

    FUNCTION get_surgery_count
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN NUMBER AS
    
        l_table_surgery t_table_surgery := t_table_surgery(NULL);
    
        l_cursor pk_types.cursor_type;
    
        l_sql_header VARCHAR2(32000);
        l_sql_from   VARCHAR2(32000);
        l_sql_inner  VARCHAR2(32000);
        l_sql_footer VARCHAR2(32000);
        l_sql_stmt   CLOB;
        l_curid      INTEGER;
        l_ret        INTEGER;
    
        l_dt_ini      schedule_sr.dt_interv_preview_tstz%TYPE;
        l_dt_end      schedule_sr.dt_interv_preview_tstz%TYPE;
        l_prof        profissional;
        l_institution NUMBER;
        l_lang        sys_config.value%TYPE;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, pk_data_access.k_default_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        pk_data_access.date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        l_curid := dbms_sql.open_cursor;
    
        l_sql_stmt := get_surgery_query(i_institution, i_dt_ini, i_dt_end, i_data, pk_alert_constant.g_yes);
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
    
        IF i_data IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'l_data', i_data);
        END IF;
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        dbms_sql.define_column(l_curid, 1, l_ret);
        l_ret := dbms_sql.execute_and_fetch(l_curid);
    
        dbms_sql.column_value(l_curid, 1, l_ret);
    
        RETURN l_ret;
    
    END get_surgery_count;

    FUNCTION get_catheterization
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_surgery AS
    BEGIN
    
        RETURN get_surgery(i_institution => i_institution,
                           i_dt_ini      => i_dt_ini,
                           i_dt_end      => i_dt_end,
                           i_data        => i_data);
    END get_catheterization;

    FUNCTION get_laparoscopy
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_surgery AS
    
    BEGIN
    
        RETURN get_surgery(i_institution => i_institution,
                           i_dt_ini      => i_dt_ini,
                           i_dt_end      => i_dt_end,
                           i_data        => i_data);
    
    END get_laparoscopy;

    FUNCTION get_dialysis
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_dialysis IS
    
        l_table_dialysis t_table_dialysis := t_table_dialysis(NULL);
    
        l_cursor pk_types.cursor_type;
    
        l_sql_header VARCHAR2(32000);
        l_sql_from   VARCHAR2(32000);
        l_sql_inner  VARCHAR2(32000);
        l_sql_footer VARCHAR2(32000);
        l_sql_stmt   CLOB;
        l_curid      INTEGER;
        l_ret        INTEGER;
    
        l_dt_ini      interv_presc_det.dt_begin_tstz%TYPE;
        l_dt_end      interv_presc_det.dt_begin_tstz%TYPE;
        l_prof        profissional;
        l_institution NUMBER;
        l_lang        sys_config.value%TYPE;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, pk_data_access.k_default_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        pk_data_access.date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        l_curid      := dbms_sql.open_cursor;
        l_sql_header := 'SELECT t_rec_dialysis(id_institution        => id_institution, ' || --
                        '                      institution_name      => institution_name, ' || --
                        '                      patient_file_number   => patient_file_number, ' || --
                        '                      id_episode            => id_episode, ' || --
                        '                      start_time            => start_time, ' || --
                        '                      end_time              => end_time, ' || --
                        '                      dialysis_type         => haemo_type, ' || --
                        '                      code_dialysis         => id_content, ' || --
                        '                      dialysis_section      => dialysis_section, ' || --
                        '                      discharge_info        => discharge_info, ' || --
                        '                      code_discharge_status => flg_pat_condition, ' || --
                        '                      dt_last_update_tstz   => dt_last_update_tstz, ' || --
                        '                      dt_last_update        => dt_last_update) ' || --
                        'FROM (SELECT t.id_institution, ' || --
                        '             pk_translation.get_translation(id_lang, t.code_institution) institution_name, ' || --
                        '             t.id_patient, ' || --
                        '             pk_data_access.get_process(t.id_patient, t.id_institution) patient_file_number, ' || --
                        '             t.id_episode, ' || --
                        '             pk_date_utils.date_hour_chr(t.id_lang, ' || --
                        '                                         t.start_time, ' || --
                        '                                         profissional(0, l_institution, 0)) start_time, ' || --
                        '             pk_date_utils.date_hour_chr(t.id_lang, ' || --
                        '                                         t.end_time, ' || --
                        '                                         profissional(0, l_institution, 0)) end_time, ' || --
                        '             pk_translation.get_translation(t.id_lang, t.code_intervention) haemo_type, ' || --
                        '             pk_translation.get_translation(t.id_lang, t.code_dept) dialysis_section, ' || --
                        '             pk_sysdomain.get_domain(t.id_lang, ' || --
                        '                                     profissional(0, t.id_institution, 0), ' || --
                        '                                     ''DISCHARGE_DETAIL.FLG_PAT_CONDITION'', ' || --
                        '                                     t.flg_pat_condition, ' || --
                        '                                     NULL) discharge_info, ' || --
                        '             t.flg_pat_condition, ' || --
                        '             t.dt_last_update_tstz, ' || --
                        '             pk_date_utils.date_hour_chr(id_lang, t.dt_last_update_tstz, profissional(0, l_institution, 0)) dt_last_update, ' || --
                        '             t.id_content ' || --
                        '        FROM (SELECT ipd.id_interv_presc_det, ' || --
                        '                     ip.id_episode, ' || --
                        '                     ip.id_patient, ' || --
                        '                     ipp.start_time, ' || --
                        '                     ipp.end_time, ' || --
                        '                     it.code_intervention, ' || --
                        '                     ipd.flg_location, ' || --
                        '                     ipd.id_exec_institution, ' || --
                        '                     coalesce(d.dt_admin_tstz, d.dt_med_tstz) dt_discharge, ' || --
                        '                     ip.id_institution, ' || --
                        '                     i.code_institution, ' || --
                        '                     :l_lang id_lang, ' || --
                        '                     it.id_content, ' || --
                        '                     ipd.dt_order_tstz, ' || --
                        '                     ipd.dt_begin_tstz, ' || --
                        '                     dpt.code_dept, ' || --
                        '                     dd.flg_pat_condition, ' || --
                        '                     nvl(ipp.update_time, ipp.create_time) dt_last_update_tstz, ' || --
                        '                     :l_institution l_institution '; --for date processing
    
        l_sql_from := 'FROM interv_presc_det ipd ' || --
                      'INNER JOIN interv_presc_plan ipp ' || --
                      '   ON ipp.id_interv_presc_det = ipd.id_interv_presc_det ' || --
                      'INNER JOIN interv_prescription ip ' || --
                      '   ON ip.id_interv_prescription = ipd.id_interv_prescription ' || --
                      'INNER JOIN epis_info ei ' || --
                      '   ON ei.id_episode = ip.id_episode ' || --
                      'LEFT JOIN dep_clin_serv dcs ' || --
                      '  ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv  ' || --
                      'LEFT JOIN department dt ' || --
                      '  ON dt.id_department = dcs.id_department  ' || --
                      'LEFT JOIN dept dpt ' || --
                      '  ON dpt.id_dept = dt.id_dept  ' || --
                      'INNER JOIN institution i ' || --
                      '   ON i.id_institution = ip.id_institution ' || --
                      'INNER JOIN intervention it ' || --
                      '   ON it.id_intervention = ipd.id_intervention ' || --
                      ' LEFT JOIN discharge d ' || --
                      '   ON d.id_episode = ip.id_episode ' || --
                      '  AND d.flg_status = ''A'' ' || --
                      ' LEFT JOIN discharge_detail dd ' || --
                      '   ON dd.id_discharge = d.id_discharge ' || --
                      ' WHERE 1 = 1 ';
    
        l_sql_inner := l_sql_inner || 'AND ipd.dt_begin_tstz >= :l_dt_ini ';
        l_sql_inner := l_sql_inner || 'AND ipd.dt_begin_tstz <= :l_dt_end ';
    
        IF i_institution IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND ip.id_institution = :i_institution ';
        END IF;
    
        IF i_data IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || '  AND it.id_content IN (SELECT column_value FROM TABLE(:l_data)) ';
        END IF;
    
        l_sql_footer := l_sql_footer || ' )t ';
        l_sql_footer := l_sql_footer || ' ORDER BY t.dt_begin_tstz) ';
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner || l_sql_footer);
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        dbms_sql.bind_variable(l_curid, 'l_lang', l_lang);
        dbms_sql.bind_variable(l_curid, 'l_institution', l_institution);
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
    
        IF i_data IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'l_data', i_data);
        END IF;
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_table_dialysis;
    
        RETURN l_table_dialysis;
    
    END get_dialysis;

    FUNCTION get_procedure
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_procedure IS
    
        l_table_procedure t_table_procedure := t_table_procedure(NULL);
    
        l_cursor pk_types.cursor_type;
    
        l_sql_header VARCHAR2(32000);
        l_sql_from   VARCHAR2(32000);
        l_sql_inner  VARCHAR2(32000);
        l_sql_footer VARCHAR2(32000);
        l_sql_stmt   CLOB;
        l_curid      INTEGER;
        l_ret        INTEGER;
    
        l_dt_ini      interv_presc_det.dt_begin_tstz%TYPE;
        l_dt_end      interv_presc_det.dt_begin_tstz%TYPE;
        l_prof        profissional;
        l_institution NUMBER;
        l_lang        sys_config.value%TYPE;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, pk_data_access.k_default_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        pk_data_access.date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        l_curid      := dbms_sql.open_cursor;
        l_sql_header := 'SELECT t_rec_procedure(id_institution        => id_institution, ' || --
                        '                       institution_name      => institution_name, ' || --
                        '                       patient_file_number   => patient_file_number, ' || --
                        '                       id_episode            => id_episode, ' || --
                        '                       start_time            => start_time, ' || --
                        '                       end_time              => end_time, ' || --
                        '                       desc_procedure        => desc_procedure, ' || --
                        '                       code_procedure        => id_content, ' || --
                        '                       dt_last_update_tstz   => dt_last_update_tstz, ' || --
                        '                       dt_last_update        => dt_last_update) ' || --
                        'FROM (SELECT t.id_institution, ' || --
                        '             pk_translation.get_translation(id_lang, t.code_institution) institution_name, ' || --
                        '             t.id_patient, ' || --
                        '             pk_data_access.get_process(t.id_patient, t.id_institution) patient_file_number, ' || --
                        '             t.id_episode, ' || --
                        '             pk_date_utils.date_hour_chr(t.id_lang, ' || --
                        '                                         t.start_time, ' || --
                        '                                         profissional(0, l_institution, 0)) start_time, ' || --
                        '             pk_date_utils.date_hour_chr(t.id_lang, ' || --
                        '                                         t.end_time, ' || --
                        '                                         profissional(0, l_institution, 0)) end_time, ' || --
                        '             pk_translation.get_translation(t.id_lang, t.code_intervention) desc_procedure, ' || --
                        '             t.id_content, ' || --
                        '             t.dt_last_update_tstz, ' || --
                        '             pk_date_utils.date_hour_chr(id_lang, t.dt_last_update_tstz, profissional(0, l_institution, 0)) dt_last_update, ' || --
                        '             t.id_content ' || --
                        '        FROM (SELECT ipd.id_interv_presc_det, ' || --
                        '                     ip.id_episode, ' || --
                        '                     ip.id_patient, ' || --
                        '                     ipp.start_time, ' || --
                        '                     ipp.end_time, ' || --
                        '                     it.code_intervention, ' || --
                        '                     it.id_content, ' || --
                        '                     ipd.id_exec_institution, ' || --
                        '                     ip.id_institution, ' || --
                        '                     i.code_institution, ' || --
                        '                     :l_lang id_lang, ' || --
                        '                     ipd.dt_order_tstz, ' || --
                        '                     ipd.dt_begin_tstz, ' || --
                        '                     nvl(ipp.update_time, ipp.create_time) dt_last_update_tstz, ' || --
                        '                     :l_institution l_institution '; --for date processing
    
        l_sql_from := 'FROM interv_presc_det ipd ' || --
                      'INNER JOIN interv_presc_plan ipp ' || --
                      '   ON ipp.id_interv_presc_det = ipd.id_interv_presc_det ' || --
                      'INNER JOIN interv_prescription ip ' || --
                      '   ON ip.id_interv_prescription = ipd.id_interv_prescription ' || --
                      'INNER JOIN institution i ' || --
                      '   ON i.id_institution = ip.id_institution ' || --
                      'INNER JOIN intervention it ' || --
                      '   ON it.id_intervention = ipd.id_intervention ' || --
                      ' WHERE 1 = 1 ';
    
        l_sql_inner := l_sql_inner || 'AND ipd.dt_begin_tstz >= :l_dt_ini ';
        l_sql_inner := l_sql_inner || 'AND ipd.dt_begin_tstz <= :l_dt_end ';
    
        IF i_institution IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND ip.id_institution = :i_institution ';
        END IF;
    
        l_sql_footer := l_sql_footer || ' )t ';
        l_sql_footer := l_sql_footer || ' ORDER BY t.dt_begin_tstz) ';
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner || l_sql_footer);
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        dbms_sql.bind_variable(l_curid, 'l_lang', l_lang);
        dbms_sql.bind_variable(l_curid, 'l_institution', l_institution);
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_table_procedure;
    
        RETURN l_table_procedure;
    
    END get_procedure;

    FUNCTION get_laboratory_query
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_sql_count   IN VARCHAR2
    ) RETURN CLOB AS
        l_sql_header VARCHAR2(32000);
        l_sql_from   VARCHAR2(32000);
        l_sql_inner  VARCHAR2(32000);
        l_sql_footer VARCHAR2(32000);
        l_sql_stmt   CLOB;
    
    BEGIN
    
        IF i_sql_count = pk_alert_constant.g_no
        THEN
            l_sql_header := ' SELECT t_rec_laboratory(id_institution          => id_institution, ' || --
                            '                         institution_name        => institution_name, ' || --
                            '                         patient_file_number     => patient_file_number, ' || --
                            '                         id_episode              => id_episode, ' || --
                            '                         id_epis_type            => id_epis_type, ' ||
                            '                         desc_epis_type          => desc_epis_type, ' ||
                            '                         lab_test_description    => lab_test_description, ' || --
                            '                         collection_date         => collection_date, ' || --
                            '                         receiving_date          => receiving_date, ' || --
                            '                         request_date            => request_date, ' || --
                            '                         result_date             => result_date, ' || --
                            '                         to_be_performed_date    => to_be_performed_date, ' || --
                            '                         flg_priority            => flg_priority, ' || -- 
                            '                         priority                => priority, ' || --
                            '                         flg_time_harvest   => flg_time_harvest, ' || --
                            '                         desc_flg_time_harvest   => desc_flg_time_harvest, ' || --
                            '                         result                  => result, ' || --
                            '                         result_code             => result_code, ' || --
                            '                         lab_section             => lab_section, ' || --
                            '                         requested_from          => requested_from, ' || --
                            '                         dt_last_update_tstz     => dt_last_update_tstz, ' || --
                            '                         dt_last_update          => dt_last_update) ' || --
                            ' FROM (SELECT t.id_analysis, ' || --
                            '              (SELECT pk_lab_tests_utils.get_alias_translation(t.id_lang, ' || --
                            '                                                               profissional(0, t.id_institution, 0), ' || --
                            '                                                               ''A'', ' || --
                            '                                                               ''ANALYSIS.CODE_ANALYSIS.'' || t.id_analysis,  ' || --
                            '                                                               NULL)  ' || --
                            '                  FROM dual) lab_test_description, ' || --
                            '              t.id_sample_type, ' || --
                            '              pk_date_utils.date_hour_chr(t.id_lang, t.collection_date, profissional(0, l_institution, 0)) collection_date, ' || --
                            '              pk_date_utils.date_hour_chr(t.id_lang, t.receiving_date, profissional(0, l_institution, 0)) receiving_date, ' || --
                            '              pk_date_utils.date_hour_chr(t.id_lang, t.request_date, profissional(0, l_institution, 0)) request_date, ' || --
                            '              pk_date_utils.date_hour_chr(t.id_lang, t.result_date, profissional(0, l_institution, 0)) result_date, ' || --
                            '              pk_date_utils.date_hour_chr(t.id_lang, t.dt_target, profissional(0, l_institution, 0)) to_be_performed_date, ' || --
                            '              t.flg_priority, ' ||
                            '              (SELECT pk_sysdomain.get_domain(t.id_lang, profissional(NULL, t.id_institution, NULL), ''ANALYSIS_REQ.FLG_PRIORITY'',  t.flg_priority, NULL) FROM DUAL) priority, ' || --
                            '              t.flg_time_harvest, ' || --
                            '              (SELECT pk_sysdomain.get_domain(t.id_lang, profissional(NULL, t.id_institution, NULL), ''ANALYSIS_REQ_DET.FLG_TIME_HARVEST'',  t.flg_time_harvest, NULL) FROM DUAL) desc_flg_time_harvest, ' || --
                            '              t.id_episode, ' || --
                            '              t.id_epis_type, ' ||
                            '              pk_translation.get_translation(t.id_lang, ''EPIS_TYPE.CODE_EPIS_TYPE.'' || t.id_epis_type) desc_epis_type, ' ||
                            '              t.id_institution, ' || --
                            '              pk_translation.get_translation(t.id_lang, t.code_institution) institution_name, ' || --
                            '              (SELECT listagg(pk_translation.get_translation(t.id_lang, ap.code_analysis_parameter) || '': '' ' || --
                            '                             || coalesce(to_char(arp.desc_analysis_result), ' || --
                            '                                        to_char(arp.analysis_result_value_1), ' || --
                            '                                         to_char(arp.analysis_result_value_2)) || CASE ' || --
                            '                                    WHEN arp.id_unit_measure IS NOT NULL THEN ' || --
                            '                                     '' '' || pk_translation.get_translation(t.id_lang, um.code_unit_measure) ' || --
                            '                                    ELSE ' || --
                            '                                     NULL ' || --
                            '                                END, ' || --
                            '                               ''; '') within GROUP(ORDER BY pk_lab_tests_utils.get_lab_test_parameter_rank(t.id_lang, profissional(0, t.id_institution, 0), t.id_analysis, t.id_sample_type, ap.id_analysis_parameter) ASC) ' || --
                            '                  FROM analysis_result_par arp ' || --
                            '                  JOIN analysis_result ar ' || --
                            '                    ON ar.id_analysis_result = arp.id_analysis_result ' || --
                            '                  JOIN analysis_parameter ap ' || --
                            '                    ON ap.id_analysis_parameter = arp.id_analysis_parameter ' || --
                            '                  LEFT JOIN unit_measure um ' || --
                            '                    ON um.id_unit_measure = arp.id_unit_measure ' || --
                            '                 WHERE ar.id_analysis_req_det = t.id_analysis_req_det) result, ' || --
                            '               pk_data_access.array_to_var(CAST(MULTISET ' || --
                            '                                                (SELECT coalesce(to_char(arp.desc_analysis_result), ' || --
                            '                                                                 to_char(arp.analysis_result_value_1), ' || --
                            '                                                                 to_char(arp.analysis_result_value_2)) ' || --
                            '                                                   FROM analysis_result_par arp ' || --
                            '                                                   JOIN analysis_result ar ' || --
                            '                                                     ON ar.id_analysis_result = arp.id_analysis_result ' || --
                            '                                                  WHERE ar.id_analysis_req_det = t.id_analysis_req_det ' || --
                            '                                                  ORDER BY pk_lab_tests_utils.get_lab_test_parameter_rank(t.id_lang, ' || --
                            '                                                                                                          profissional(0, ' || --
                            '                                                                                                                       t.id_institution, ' || --
                            '                                                                                                                       0), ' || --
                            '                                                                                                          t.id_analysis, ' || --
                            '                                                                                                          t.id_sample_type, ' || --
                            '                                                                                                          arp.id_analysis_parameter) ASC) AS ' || --
                            '                                                table_varchar)) result_code, ' || --
                            '              (SELECT pk_translation.get_translation(t.id_lang, ''EXAM_CAT.CODE_EXAM_CAT.'' || ' || --
                            '               (SELECT pk_lab_tests_utils.get_lab_test_category(t.id_lang, profissional(NULL, t.id_institution, NULL), ' || --
                            '                                                               t.id_exam_cat) from dual)) ' || --
                            '                 FROM dual) lab_section, ' || --
                            '               (SELECT pk_episode.get_cs_desc(t.id_lang, profissional(NULL, t.id_institution, NULL), t.id_episode) ' || --
                            '                  FROM dual) requested_from, ' || --
                            '              t.dt_last_update_tstz, ' || --
                            '              pk_date_utils.date_hour_chr(id_lang, t.dt_last_update_tstz, profissional(0, l_institution, 0)) dt_last_update, ' || --
                            '              pk_data_access.get_process(t.id_patient, t.id_institution) patient_file_number ' || --
                            '          FROM (SELECT lte.id_analysis_req_det, ' || --
                            '                       lte.id_analysis, ' || --
                            '                       lte.id_sample_type, ' || --
                            '                       lte.id_exam_cat, ' || --
                            '                       CASE ' || --
                            '                            WHEN lte.flg_status_harvest = ''P'' THEN ' || --
                            '                               NULL ' || --
                            '                            ELSE ' || --
                            '                             lte.dt_harvest ' || --
                            '                       END collection_date, ' || --
                            '                       CASE ' || --
                            '                            WHEN ardh.dt_analysis_req_det_hist IS NOT NULL THEN ' || --
                            '                             ardh.dt_analysis_req_det_hist ' || --
                            '                            WHEN lte.flg_status_det = ''E'' THEN ' || --
                            '                             lte.dt_dg_last_update ' || --
                            '                            ELSE ' || --
                            '                             NULL ' || --
                            '                        END receiving_date, ' || --
                            '                       lte.dt_req             request_date, ' || --
                            '                       lte.dt_analysis_result result_date, ' || --
                            '                       lte.flg_priority, ' || --
                            '                       lte.flg_status_det, ' || --
                            '                       lte.flg_time_harvest, ' || --
                            '                       lte.dt_target, ' || --
                            '                       lte.id_episode, ' || --
                            '                       e.id_epis_type, ' || --
                            '                       lte.id_patient, ' || --
                            '                       lte.id_institution, ' || --
                            '                       i.code_institution, ' || --
                            '                       nvl(lte.update_time, lte.create_time) dt_last_update_tstz, ' || --
                            '                       :l_lang id_lang, ' || --
                            '                       :l_institution l_institution '; --for date processing
        ELSE
            l_sql_header := ' SELECT count(*) ';
        END IF;
    
        l_sql_from := '           FROM lab_tests_ea lte ' || --
                      '           JOIN institution i ' || --
                      '             ON i.id_institution = lte.id_institution ' || --
                      '           JOIN episode e ' || --
                      '             ON e.id_episode = lte.id_episode ' || --
                      '           LEFT JOIN analysis_req_det_hist ardh ' || --
                      '             ON ardh.id_analysis_req_det = lte.id_analysis_req_det ' || --
                      '            AND ardh.flg_status = ''E'' ' || --
                      '         WHERE 1 = 1 ';
    
        l_sql_inner := l_sql_inner || 'AND lte.dt_req >= :l_dt_ini ';
        l_sql_inner := l_sql_inner || 'AND lte.dt_req <= :l_dt_end ';
    
        IF i_institution IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND lte.id_institution = :i_institution ';
        END IF;
    
        l_sql_footer := l_sql_footer || ' ) t ';
        l_sql_footer := l_sql_footer || ' ORDER BY t.request_date) ';
    
        IF i_sql_count = pk_alert_constant.g_no
        THEN
            l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner || l_sql_footer);
        ELSE
            l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner);
        END IF;
    
        RETURN l_sql_stmt;
    END get_laboratory_query;

    FUNCTION get_laboratory_count
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER AS
    
        l_sql_stmt CLOB;
        l_curid    INTEGER;
        l_ret      INTEGER;
    
        l_dt_ini      lab_tests_ea.dt_req%TYPE;
        l_dt_end      lab_tests_ea.dt_req%TYPE;
        l_prof        profissional;
        l_institution NUMBER;
        l_lang        sys_config.value%TYPE;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, pk_data_access.k_default_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        pk_data_access.date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        l_curid := dbms_sql.open_cursor;
    
        l_sql_stmt := get_laboratory_query(i_institution, i_dt_ini, i_dt_end, pk_alert_constant.get_yes);
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        dbms_sql.define_column(l_curid, 1, l_ret);
        l_ret := dbms_sql.execute_and_fetch(l_curid);
    
        dbms_sql.column_value(l_curid, 1, l_ret);
    
        RETURN l_ret;
    
    END get_laboratory_count;

    FUNCTION get_laboratory
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_laboratory IS
    
        l_table_laboratory t_table_laboratory := t_table_laboratory(NULL);
    
        l_cursor pk_types.cursor_type;
    
        l_sql_stmt CLOB;
        l_curid    INTEGER;
        l_ret      INTEGER;
    
        l_dt_ini      lab_tests_ea.dt_req%TYPE;
        l_dt_end      lab_tests_ea.dt_req%TYPE;
        l_prof        profissional;
        l_institution NUMBER;
        l_lang        sys_config.value%TYPE;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, pk_data_access.k_default_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        pk_data_access.date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        l_curid := dbms_sql.open_cursor;
    
        l_sql_stmt := get_laboratory_query(i_institution, i_dt_ini, i_dt_end, pk_alert_constant.get_no);
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        dbms_sql.bind_variable(l_curid, 'l_lang', l_lang);
        dbms_sql.bind_variable(l_curid, 'l_institution', l_institution);
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_table_laboratory;
    
        RETURN l_table_laboratory;
    
    END get_laboratory;

    FUNCTION get_radiology_query
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_sql_count   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB AS
        l_sql_header VARCHAR2(32000);
        l_sql_from   VARCHAR2(32000);
        l_sql_inner  VARCHAR2(32000);
        l_sql_footer VARCHAR2(32000);
        l_sql_stmt   CLOB;
    BEGIN
    
        IF i_sql_count = pk_alert_constant.g_no
        THEN
            l_sql_header := 'SELECT t_rec_radiology(id_institution      => id_institution, ' || --
                            '                       institution_name    => institution_name, ' || --
                            '                       patient_file_number => patient_file_number, ' || --
                            '                       id_episode          => id_episode, ' || --
                            '                       id_epis_type        => id_epis_type, ' ||
                            '                       desc_epis_type      => desc_epis_type, ' ||
                            '                       procedure_date      => procedure_date, ' || --
                            '                       report_date         => report_date, ' || --
                            '                       request_date        => request_date, ' || --
                            '                       begin_date          => begin_date, ' || --
                            '                       priority            => priority, ' || --
                            '                       code_priority       => flg_priority , ' || --
                            '                       flg_time            => flg_time, ' || --
                            '                       desc_flg_time       => desc_flg_time, ' || --
                            '                       requested_from      => requested_from, ' || --
                            '                       rad_service         => rad_service, ' || --
                            '                       desc_exam           => desc_exam, ' || --
                            '                       dt_last_update_tstz => dt_last_update_tstz, ' || --
                            '                       dt_last_update      => dt_last_update) ' || --
                            'FROM (SELECT t.id_institution, ' || --
                            '       pk_translation.get_translation(id_lang, t.code_institution) institution_name, ' || --
                            '       pk_date_utils.date_hour_chr(i_lang => id_lang, ' || --
                            '                                   i_date => t.start_time, ' || --
                            '                                   i_prof => profissional(0, l_institution, 0)) procedure_date, ' || --
                            '       pk_date_utils.date_hour_chr(i_lang => id_lang, ' || --
                            '                                   i_date => t.dt_result, ' || --
                            '                                   i_prof => profissional(0, l_institution, 0)) report_date, ' || --
                            '       pk_date_utils.date_hour_chr(i_lang => id_lang, ' || --
                            '                                   i_date => t.dt_req_tstz, ' || --
                            '                                   i_prof => profissional(0, l_institution, 0)) request_date, ' || --
                            '       pk_date_utils.date_hour_chr(i_lang => id_lang, ' || --
                            '                                   i_date => t.dt_begin_tstz, ' || --
                            '                                   i_prof => profissional(0, l_institution, 0)) begin_date, ' || --
                            '       pk_sysdomain.get_domain(t.id_lang, ' || --
                            '                               profissional(NULL, t.id_institution, NULL), ' || --
                            '                               ''EXAM_REQ.PRIORITY'', ' || --
                            '                               t.flg_priority, ' || --
                            '                               NULL) priority, ' || --
                            '       t.flg_priority, ' || --
                            '       t.id_epis_type, ' ||
                            '       pk_translation.get_translation(t.id_lang, ''EPIS_TYPE.CODE_EPIS_TYPE.'' || t.id_epis_type) desc_epis_type, ' ||
                            '       t.flg_time, ' || --
                            '       (SELECT pk_sysdomain.get_domain(t.id_lang, profissional(NULL, t.id_institution, NULL), ''EXAM_REQ.FLG_TIME'',  t.flg_time, NULL) FROM DUAL) desc_flg_time, ' || --                        
                            '       pk_patient.get_alert_process_number(t.id_lang, profissional(NULL, t.id_institution, NULL), t.id_episode) patient_file_number, ' || --
                            '       REPLACE(pk_translation.get_translation(id_lang, ' || --
                            '                                              ''AB_SOFTWARE.CODE_SOFTWARE.'' || ' || --
                            '                                              pk_episode.get_episode_software(t.id_lang, ' || --
                            '                                                                              profissional(NULL, t.id_institution, NULL), ' || --
                            '                                                                              t.id_episode)), ' || --
                            '               ''<br>'', ' || --
                            '               '' '') || '' - '' || ' || --
                            '       pk_episode.get_cs_desc(t.id_lang, profissional(NULL, t.id_institution, NULL), t.id_episode) requested_from, ' || --
                            '       pk_translation.get_translation(id_lang, ''EXAM_CAT.CODE_EXAM_CAT.'' || t.id_exam_cat) rad_service, ' || --
                            '       pk_exam_utils.get_alias_translation(id_lang, profissional(NULL, t.id_institution, NULL), t.code_exam, NULL) desc_exam, ' || --
                            '       t.dt_last_update_tstz, ' || --
                            '       pk_date_utils.date_hour_chr(i_lang => id_lang, i_date =>  t.dt_last_update_tstz, i_prof => profissional(0, l_institution, 0)) dt_last_update, ' || --
                            '       t.id_episode ' || --
                            '  FROM (SELECT :l_lang id_lang, ' || --
                            '               i.id_institution, ' || --
                            '               i.code_institution, ' || --
                            '               er.id_exam_req, ' || --
                            '               nvl(erd.start_time, erd.dt_performed_reg) start_time, ' || --
                            '               eea.dt_result, ' || --
                            '               er.dt_req_tstz, ' || --
                            '               er.dt_begin_tstz, ' || --
                            '               erd.flg_priority, ' || --
                            '               er.flg_time, ' || --
                            '               nvl(eea.id_episode, eea.id_episode_origin) id_episode, ' || --
                            '               e.id_epis_type, ' || --
                            '               eea.id_exam_cat, ' || --
                            '               e.code_exam, ' || --
                            '               nvl(erd.update_time, erd.create_time) dt_last_update_tstz, ' || --
                            '               :l_institution l_institution '; --for date processing
        ELSE
            l_sql_header := ' SELECT count(*) ';
        END IF;
    
        l_sql_from := '          FROM exams_ea eea ' || --
                      '          JOIN exam_req er ' || --
                      '            ON eea.id_exam_req = er.id_exam_req ' || --
                      '          JOIN exam_req_det erd ' || --
                      '            ON eea.id_exam_req_det = erd.id_exam_req_det ' || --
                      '          JOIN exam e ' || --
                      '            ON e.id_exam = erd.id_exam ' || --
                      '          JOIN institution i ' || --
                      '            ON er.id_institution = i.id_institution ' || --
                      '          JOIN episode e ' || --
                      '            ON e.id_episode = nvl(eea.id_episode, eea.id_episode_origin)' || --
                      '         WHERE 1 = 1 ';
    
        l_sql_inner := l_sql_inner || 'AND nvl(erd.start_time, erd.dt_performed_reg) >= :l_dt_ini ';
        l_sql_inner := l_sql_inner || 'AND nvl(erd.start_time, erd.dt_performed_reg) <= :l_dt_end ';
    
        IF i_institution IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND er.id_institution = :i_institution ';
        END IF;
    
        l_sql_footer := l_sql_footer || ' ) t ';
        l_sql_footer := l_sql_footer || ' ORDER BY t.dt_req_tstz) ';
    
        IF i_sql_count = pk_alert_constant.g_no
        THEN
            l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner || l_sql_footer);
        ELSE
            l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner);
        END IF;
        RETURN l_sql_stmt;
    
    END get_radiology_query;

    FUNCTION get_radiology_count
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
    
        l_cursor pk_types.cursor_type;
    
        l_curid       INTEGER;
        l_ret         INTEGER;
        l_sql_stmt    CLOB;
        l_dt_ini      exam_req_det.start_time%TYPE;
        l_dt_end      exam_req_det.start_time%TYPE;
        l_prof        profissional;
        l_institution NUMBER;
        l_lang        sys_config.value%TYPE;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, pk_data_access.k_default_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        pk_data_access.date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        l_curid := dbms_sql.open_cursor;
    
        l_sql_stmt := get_radiology_query(i_institution, i_dt_ini, i_dt_end, pk_alert_constant.g_yes);
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        dbms_sql.define_column(l_curid, 1, l_ret);
        l_ret := dbms_sql.execute_and_fetch(l_curid);
    
        dbms_sql.column_value(l_curid, 1, l_ret);
    
        RETURN l_ret;
    
    END get_radiology_count;

    FUNCTION get_radiology
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_radiology IS
    
        l_table_radiology t_table_radiology := t_table_radiology(NULL);
    
        l_cursor pk_types.cursor_type;
    
        l_curid       INTEGER;
        l_ret         INTEGER;
        l_sql_stmt    CLOB;
        l_dt_ini      exam_req_det.start_time%TYPE;
        l_dt_end      exam_req_det.start_time%TYPE;
        l_prof        profissional;
        l_institution NUMBER;
        l_lang        sys_config.value%TYPE;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, pk_data_access.k_default_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        pk_data_access.date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        l_curid := dbms_sql.open_cursor;
    
        l_sql_stmt := get_radiology_query(i_institution, i_dt_ini, i_dt_end, pk_alert_constant.g_no);
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        dbms_sql.bind_variable(l_curid, 'l_lang', l_lang);
        dbms_sql.bind_variable(l_curid, 'l_institution', l_institution);
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_table_radiology;
    
        RETURN l_table_radiology;
    
    END get_radiology;

END pk_data_access_orders;
/
