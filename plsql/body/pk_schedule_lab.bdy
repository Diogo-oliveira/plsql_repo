/*-- Last Change Revision: $Rev: 2027680 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:59 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_schedule_lab AS

    /* returns all LAB appointments for TODAY, scheduled for the given profissional's intitution.
    * Only appointments WITHOUT requisition. That means no row in table schedule_analysis.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param o_output                      output is a nested table of records of schema type t_rec_sch_lab_daily_apps
    * @param o_error                       error info, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.3.8
    * @date    03-09-2013
    */
    FUNCTION get_today_lab_appoints
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_day  IN schedule.dt_begin_tstz%TYPE DEFAULT NULL
    ) RETURN t_table_sch_lab_daily_apps IS
        l_func_name VARCHAR2(50) := 'PK_SCHEDULE_LAB.GET_TODAY_LAB_APPOINTS';
        l_ret       t_table_sch_lab_daily_apps;
    BEGIN
        g_error := l_func_name ||
                   ' - BULK COLLECT INTO t_table_sch_lab_daily_apps type collection. i_prof.institution=' ||
                   i_prof.institution;
        SELECT t_rec_sch_lab_daily_apps(s.id_schedule,
                                         sg.id_patient,
                                         s.id_instit_requests,
                                         s.dt_begin_tstz,
                                         s.flg_status,
                                         CASE
                                             WHEN sg.id_cancel_reason IS NULL THEN
                                              'N'
                                             ELSE
                                              'Y'
                                         END,
                                         sa.id_analysis_req)
          BULK COLLECT
          INTO l_ret
          FROM schedule s
          LEFT JOIN schedule_analysis sa
            ON s.id_schedule = sa.id_schedule
          JOIN sch_group sg
            ON s.id_schedule = sg.id_schedule
         WHERE s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_anls
           AND s.dt_begin_tstz >= trunc(nvl(i_day, current_timestamp - 180))
           AND s.dt_begin_tstz < trunc(nvl(i_day, current_timestamp + 180)) + 1
           AND s.id_instit_requested = i_prof.institution
           AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
        --      AND sa.id_analysis_req IS NULL;
    
        RETURN l_ret;
    END get_today_lab_appoints;

    /*
    *  ALERT-303513. Details of a exam/other exams schedule 
    */
    PROCEDURE get_sch_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_detail      OUT pk_types.cursor_type
    ) IS
    
        CURSOR c IS
            SELECT s.flg_status,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_status_domain, s.flg_status) desc_status, --Scheduled, Canceled,...
                   p.name patient_name, -- patient name
                   pk_date_utils.to_char_insttimezone(i_prof, s.dt_begin_tstz, 'mon-DD-YYYY hh24:mi') begin_date, --Scheduling date
                   (SELECT listagg(pk_translation.get_translation(i_lang, a.code_analysis), ', ') within GROUP(ORDER BY sa.id_analysis_req)
                      FROM schedule_analysis sa
                      JOIN analysis_req_det ard
                        ON sa.id_analysis_req = ard.id_analysis_req
                      JOIN analysis a
                        ON a.id_analysis = ard.id_analysis
                     WHERE sa.id_schedule = s.id_schedule) desc_analysis, -- Scheduled test(s)
                   s.id_prof_schedules created_by, -- Creator
                   s.dt_schedule_tstz created_in, -- create date
                   sg.id_cancel_reason, -- hidden field
                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) desc_cancel_reason, -- no-show reason
                   sg.no_show_notes, -- no-show Notes
                   s.schedule_notes -- documentation notes
              FROM schedule s
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              JOIN patient p
                ON sg.id_patient = p.id_patient
              LEFT JOIN cancel_reason cr
                ON cr.id_cancel_reason = sg.id_cancel_reason
             WHERE s.id_schedule = i_id_schedule;
    
        lc          c%ROWTYPE;
        l_upd_info  pk_schedule_common.t_sch_hist_upd_info;
        l_func_name VARCHAR2(30) := g_package_name || '.GET_SCH_DETAIL';
        l_str       VARCHAR2(32767);
    BEGIN
        -- get raw data
        g_error := 'OPEN cursor c';
        OPEN c;
        FETCH c
            INTO lc;
    
        IF c%NOTFOUND
        THEN
            CLOSE c;
            raise_application_error(-20000, l_func_name || ' - no data found for id_schedule ' || i_id_schedule);
        END IF;
    
        CLOSE c;
    
        --Initialization of detail table
        g_error := 'CALL pk_edis_hist.init_vars';
        pk_edis_hist.init_vars;
    
        -- line necessary
        g_error := 'CALL pk_edis_hist.add_line';
        pk_edis_hist.add_line(i_history        => -1,
                              i_dt_hist        => pk_date_utils.get_string_tstz(i_lang => i_lang,
                                                                                i_prof => i_prof,
                                                                                --                                                                       i_timestamp => lc.created_in,
                                                                                i_timezone => NULL),
                              i_record_state   => lc.flg_status,
                              i_desc_rec_state => lc.desc_status,
                              i_professional   => lc.created_by,
                              i_episode        => NULL);
    
        -- header: Encounter (Scheduled/Canceled/No show)
        g_error := 'CALL pk_edis_hist.add_value (title). i_label=' || pk_schedule_common.g_m_encounter;
        pk_edis_hist.add_value(i_lang  => i_lang,
                               i_label => pk_message.get_message(i_lang      => i_lang,
                                                                 i_code_mess => pk_schedule_common.g_m_encounter) || ' (' || CASE
                                              WHEN lc.id_cancel_reason IS NULL THEN
                                               lc.desc_status
                                              ELSE
                                               pk_message.get_message(i_lang      => i_lang,
                                                                      i_code_mess => pk_schedule_common.g_m_no_show)
                                          END || ')',
                               i_value => NULL,
                               i_type  => pk_edis_hist.g_type_title);
    
        g_error := 'CALL pk_schedule_common.add_scheduling_block. i_pat_name=' || lc.patient_name;
        pk_schedule_common.add_scheduling_block(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_pat_name     => lc.patient_name,
                                                i_sch_date     => lc.begin_date,
                                                i_tests        => lc.desc_analysis,
                                                i_created_date => lc.created_in,
                                                i_created_by   => lc.created_by);
    
        -- no-show SECTION
        IF lc.id_cancel_reason IS NOT NULL
        THEN
            -- Empty line
            g_error := 'CALL pk_edis_hist.add_value (empty line)';
            pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
        
            -- header: Not performed 
            g_error := 'CALL pk_edis_hist.add_value (title). i_label=' || pk_schedule_common.g_m_not_perf;
            pk_edis_hist.add_value(i_lang  => i_lang,
                                   i_label => pk_message.get_message(i_lang      => i_lang,
                                                                     i_code_mess => pk_schedule_common.g_m_not_perf),
                                   i_value => NULL,
                                   i_type  => pk_edis_hist.g_type_title);
        
            -- field: Reason
            g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_reason;
            pk_edis_hist.add_value(i_lang     => i_lang,
                                   i_flg_call => pk_edis_hist.g_call_detail,
                                   i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => pk_schedule_common.g_m_reason),
                                   i_value    => lc.desc_cancel_reason,
                                   i_type     => pk_edis_hist.g_type_content);
        
            -- field: Notes
            g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_notes;
            pk_edis_hist.add_value(i_lang     => i_lang,
                                   i_flg_call => pk_edis_hist.g_call_detail,
                                   i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => pk_schedule_common.g_m_notes),
                                   i_value    => lc.no_show_notes,
                                   i_type     => pk_edis_hist.g_type_content);
        
            -- field: signature
            g_error    := 'CALL pk_schedule_common.get_hist_col_last_upd_info. i_table_name=sch_group_hist, i_col_name=id_cancel_reason';
            l_upd_info := pk_schedule_common.get_hist_col_last_upd_info(i_id_sch     => i_id_schedule,
                                                                        i_col_name   => 'id_cancel_reason',
                                                                        i_table_name => 'sch_group_hist');
        
            g_error := 'CALL pk_edis_hist.get_signature';
            l_str   := pk_edis_hist.get_signature(i_lang                   => i_lang,
                                                  i_id_episode             => NULL,
                                                  i_prof                   => i_prof,
                                                  i_date                   => l_upd_info.update_date,
                                                  i_id_prof_last_change    => l_upd_info.update_user,
                                                  i_has_historical_changes => pk_alert_constant.g_no);
        
            g_error := 'CALL pk_edis_hist.add_value (signature). i_value=' || l_str;
            pk_edis_hist.add_value(i_label => NULL,
                                   i_value => l_str,
                                   i_type  => pk_edis_hist.g_type_signature,
                                   i_code  => 'SIGNATURE');
        END IF;
    
        -- Notes documentation SECTION
        IF lc.schedule_notes IS NOT NULL
        THEN
            -- Empty line
            g_error := 'CALL pk_edis_hist.add_value (empty line)';
            pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
        
            -- header: Notes documentation
            g_error := 'CALL pk_edis_hist.add_value (title). i_label=' || pk_schedule_common.g_m_notes_doc;
            pk_edis_hist.add_value(i_lang  => i_lang,
                                   i_label => pk_message.get_message(i_lang      => i_lang,
                                                                     i_code_mess => pk_schedule_common.g_m_notes_doc),
                                   i_value => NULL,
                                   i_type  => pk_edis_hist.g_type_title);
        
            -- field: schedule notes
            g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_notes;
            pk_edis_hist.add_value(i_lang     => i_lang,
                                   i_flg_call => pk_edis_hist.g_call_detail,
                                   i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => pk_schedule_common.g_m_notes),
                                   i_value    => substr(lc.schedule_notes, 1, 32767), --dbms_lob.substr(lc.schedule_notes, 32767, 1),
                                   i_type     => pk_edis_hist.g_type_content);
        
            -- field: signature
            g_error    := 'CALL pk_schedule_common.get_hist_col_last_upd_info. i_table_name=schedule_hist, i_col_name=schedule_notes';
            l_upd_info := pk_schedule_common.get_hist_col_last_upd_info(i_id_sch     => i_id_schedule,
                                                                        i_col_name   => 'schedule_notes',
                                                                        i_table_name => 'schedule_hist');
        
            g_error := 'CALL pk_edis_hist.get_signature';
            l_str   := pk_edis_hist.get_signature(i_lang                   => i_lang,
                                                  i_id_episode             => NULL,
                                                  i_prof                   => i_prof,
                                                  i_date                   => l_upd_info.update_date,
                                                  i_id_prof_last_change    => l_upd_info.update_user,
                                                  i_has_historical_changes => pk_alert_constant.g_no);
        
            g_error := 'CALL pk_edis_hist.add_value (signature). i_value=' || l_str;
            pk_edis_hist.add_value(i_label => NULL,
                                   i_value => l_str,
                                   i_type  => pk_edis_hist.g_type_signature,
                                   i_code  => 'SIGNATURE');
        
        END IF;
    
        -- return output
        g_error := 'OPEN o_detail';
        OPEN o_detail FOR
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
                      FROM TABLE(pk_edis_hist.tf_hist) t)
            -- remove history entries that have no difference from the previous record
            -- this is necessary due to diagnosis replications in the same visit
             WHERE count_elems > 2;
    
    END get_sch_detail;

    FUNCTION get_sch_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_detail      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c IS
            SELECT s.flg_status,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_status_domain, s.flg_status) desc_status, --Scheduled, Canceled,...
                   p.name patient_name, -- patient name
                   pk_date_utils.date_char_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) begin_date, --Scheduling date
                   (SELECT listagg(pk_translation.get_translation(i_lang, a.code_analysis), ', ') within GROUP(ORDER BY sa.id_analysis_req)
                      FROM schedule_analysis sa
                      JOIN analysis_req_det ard
                        ON sa.id_analysis_req = ard.id_analysis_req
                      JOIN analysis a
                        ON a.id_analysis = ard.id_analysis
                     WHERE sa.id_schedule = s.id_schedule) desc_exams, -- Scheduled test(s)
                   s.id_prof_schedules created_by, -- Creator
                   s.dt_schedule_tstz created_in, -- create date
                   sg.id_cancel_reason, -- hidden field
                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) desc_cancel_reason, -- no-show reason
                   sg.no_show_notes, -- no-show Notes
                   s.schedule_notes -- documentation notes
              FROM schedule s
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              JOIN patient p
                ON sg.id_patient = p.id_patient
              LEFT JOIN cancel_reason cr
                ON cr.id_cancel_reason = sg.id_cancel_reason
             WHERE s.id_schedule = i_id_schedule;
    
        lc          c%ROWTYPE;
        l_upd_info  pk_schedule_common.t_sch_hist_upd_info;
        l_func_name VARCHAR2(30) := g_package_name || '.GET_SCH_DETAIL';
    
        l_tab_scheduled_data     t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_no_show_data       t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_documentation_data t_tab_dd_block_data := t_tab_dd_block_data();
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
    
    BEGIN
        -- get raw data
        g_error := 'OPEN cursor c';
        OPEN c;
        FETCH c
            INTO lc;
    
        IF c%NOTFOUND
        THEN
            CLOSE c;
            raise_application_error(-20000, l_func_name || ' - no data found for id_schedule ' || i_id_schedule);
        END IF;
        CLOSE c;
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   ddb.rank,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_scheduled_data
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT t.*
                          FROM (SELECT ' ' AS title,
                                       lc.patient_name,
                                       lc.begin_date AS scheduling_date,
                                       lc.desc_exams AS scheduled_mcdts,
                                       lc.schedule_notes AS notes,
                                       lc.desc_status AS status,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, lc.created_by) ||
                                       decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                               i_prof,
                                                                               lc.created_by,
                                                                               lc.created_in,
                                                                               NULL),
                                              NULL,
                                              '; ',
                                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                       i_prof,
                                                                                       lc.created_by,
                                                                                       lc.created_in,
                                                                                       NULL) || '); ') ||
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   lc.created_in,
                                                                   i_prof.institution,
                                                                   i_prof.software) registry,
                                       ' ' white_line
                                  FROM dual) t) unpivot include NULLS(data_source_val FOR data_source IN(title,
                                                                                                         patient_name,
                                                                                                         scheduling_date,
                                                                                                         scheduled_mcdts,
                                                                                                         notes,
                                                                                                         status,
                                                                                                         registry,
                                                                                                         white_line))) dd
          JOIN dd_block ddb
            ON ddb.area = 'SCHEDULED_MCDT'
           AND ddb.internal_name = 'SCHEDULE'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        IF lc.id_cancel_reason IS NOT NULL
        THEN
            l_upd_info := pk_schedule_common.get_hist_col_last_upd_info(i_id_sch     => i_id_schedule,
                                                                        i_col_name   => 'id_cancel_reason',
                                                                        i_table_name => 'sch_group_hist');
        
            SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                       ddb.rank,
                                       NULL,
                                       NULL,
                                       ddb.condition_val,
                                       NULL,
                                       NULL,
                                       dd.data_source,
                                       dd.data_source_val,
                                       NULL)
              BULK COLLECT
              INTO l_tab_no_show_data
              FROM (SELECT data_source, data_source_val
                      FROM (SELECT t.*
                              FROM (SELECT ' ' AS title,
                                           lc.desc_cancel_reason AS reason,
                                           lc.no_show_notes AS notes,
                                           pk_prof_utils.get_name_signature(i_lang, i_prof, l_upd_info.update_user) ||
                                           decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                   i_prof,
                                                                                   l_upd_info.update_user,
                                                                                   l_upd_info.update_date,
                                                                                   NULL),
                                                  NULL,
                                                  '; ',
                                                  ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                           i_prof,
                                                                                           l_upd_info.update_user,
                                                                                           l_upd_info.update_date,
                                                                                           NULL) || '); ') ||
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       l_upd_info.update_date,
                                                                       i_prof.institution,
                                                                       i_prof.software) registry,
                                           ' ' white_line
                                      FROM dual) t) unpivot include NULLS(data_source_val FOR data_source IN(title,
                                                                                                             reason,
                                                                                                             notes,
                                                                                                             registry,
                                                                                                             white_line))) dd
              JOIN dd_block ddb
                ON ddb.area = 'SCHEDULED_MCDT'
               AND ddb.internal_name = 'NO_SHOW'
               AND ddb.flg_available = pk_alert_constant.g_yes;
        END IF;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  ELSE
                                   NULL
                              END,
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END,
                              flg_type,
                              flg_html,
                              NULL,
                              flg_clob),
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_scheduled_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'SCHEDULED_MCDT'
                   AND ddc.id_dd_block = 1
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L2N'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_no_show_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'SCHEDULED_MCDT'
                   AND ddc.id_dd_block = 2
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L2N'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_documentation_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'SCHEDULED_MCDT'
                   AND ddc.id_dd_block = 3
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L2N')))
         ORDER BY rnk, rank;
    
        g_error := 'OPEN O_DETAIL';
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || decode(d.flg_type, 'LP', NULL, ': ')
                            END descr,
                           d.val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCH_DETAIL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_detail);
            RETURN FALSE;
    END get_sch_detail;

    /*
    * 
    */
    PROCEDURE get_sch_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_detail      OUT pk_types.cursor_type
    ) IS
    
        CURSOR c IS
            SELECT s.flg_status,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_status_domain, s.flg_status) desc_status, --Scheduled, Canceled,...
                   p.name patient_name, -- patient name
                   pk_date_utils.to_char_insttimezone(i_prof, s.dt_begin_tstz, 'mon-DD-YYYY hh24:mi') begin_date, --Scheduling date
                   (SELECT listagg(pk_translation.get_translation(i_lang, a.code_analysis), ', ') within GROUP(ORDER BY sa.id_analysis_req)
                      FROM schedule_analysis sa
                      JOIN analysis_req_det ard
                        ON sa.id_analysis_req = ard.id_analysis_req
                      JOIN analysis a
                        ON a.id_analysis = ard.id_analysis
                     WHERE sa.id_schedule = s.id_schedule) desc_analysis, -- Scheduled test(s)
                   s.id_prof_schedules created_by, -- Creator
                   s.dt_schedule_tstz created_in, -- create date
                   sg.id_cancel_reason, -- hidden field
                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) desc_cancel_reason, -- no-show reason
                   sg.no_show_notes, -- no-show Notes
                   s.schedule_notes -- documentation notes
              FROM schedule s
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              JOIN patient p
                ON sg.id_patient = p.id_patient
              LEFT JOIN cancel_reason cr
                ON cr.id_cancel_reason = sg.id_cancel_reason
             WHERE s.id_schedule = i_id_schedule;
    
        CURSOR c_no_show IS
            SELECT pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || valor) valor,
                   pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || valor_ant) valor_ant,
                   dt_update,
                   id_prof_update,
                   no_show_notes
              FROM (SELECT nvl(CAST(h.id_cancel_reason AS VARCHAR(20)), 'null') valor,
                           lag(nvl(CAST(h.id_cancel_reason AS VARCHAR(20)), 'null'), 1, 'null') over(ORDER BY dt_update) valor_ant,
                           h.dt_update,
                           h.id_prof_update,
                           h.no_show_notes
                      FROM sch_group_hist h
                     WHERE h.id_schedule = i_id_schedule)
             WHERE valor <> valor_ant
             ORDER BY dt_update DESC;
    
        lc             c%ROWTYPE;
        lcns           c_no_show%ROWTYPE;
        l_str          VARCHAR2(32767);
        l_func_name    VARCHAR2(30) := g_package_name || '.GET_SCH_HIST';
        sch_notes_coll pk_schedule_common.tt_sch_hist_upd_info;
        i              PLS_INTEGER;
    BEGIN
        -- get raw data
        g_error := 'OPEN cursor c';
        OPEN c;
        FETCH c
            INTO lc;
    
        IF c%NOTFOUND
        THEN
            CLOSE c;
            raise_application_error(-20000, l_func_name || ' - no data found for id_schedule ' || i_id_schedule);
        END IF;
    
        CLOSE c;
    
        --Initialization of detail table
        g_error := 'CALL pk_edis_hist.init_vars';
        pk_edis_hist.init_vars;
    
        -- schedule notes block
        g_error        := 'CALL pk_schedule_common.get_hist_col_updates. i_table_name=schedule_hist, i_col_name=schedule_notes';
        sch_notes_coll := pk_schedule_common.get_hist_col_updates(i_id_sch     => i_id_schedule,
                                                                  i_table_name => 'schedule_hist',
                                                                  i_col_name   => 'schedule_notes');
    
        IF sch_notes_coll IS NOT empty
        THEN
            -- line necessary
            g_error := 'CALL pk_edis_hist.add_line';
            pk_edis_hist.add_line(i_history        => -1,
                                  i_dt_hist        => pk_date_utils.get_string_tstz(i_lang     => i_lang,
                                                                                    i_prof     => i_prof,
                                                                                    i_timezone => NULL),
                                  i_record_state   => lc.flg_status,
                                  i_desc_rec_state => lc.desc_status,
                                  i_professional   => lc.created_by,
                                  i_episode        => NULL);
        
            -- header: Notes documentation
            g_error := 'CALL pk_edis_hist.add_value (title). i_label=' || pk_schedule_common.g_m_notes_doc;
            pk_edis_hist.add_value(i_lang  => i_lang,
                                   i_label => pk_message.get_message(i_lang      => i_lang,
                                                                     i_code_mess => pk_schedule_common.g_m_notes_doc),
                                   i_value => NULL,
                                   i_type  => pk_edis_hist.g_type_title);
        
            i := sch_notes_coll.first;
            WHILE i IS NOT NULL
            LOOP
                -- field: schedule notes
                g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_notes;
                pk_edis_hist.add_value(i_lang     => i_lang,
                                       i_flg_call => pk_edis_hist.g_call_detail,
                                       i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => pk_schedule_common.g_m_notes),
                                       i_value    => sch_notes_coll(i).valor,
                                       i_type     => pk_edis_hist.g_type_content);
            
                -- field: signature
                g_error := 'CALL pk_edis_hist.get_signature';
                l_str   := pk_edis_hist.get_signature(i_lang                   => i_lang,
                                                      i_id_episode             => NULL,
                                                      i_prof                   => i_prof,
                                                      i_date                   => sch_notes_coll(i).update_date,
                                                      i_id_prof_last_change    => sch_notes_coll(i).update_user,
                                                      i_has_historical_changes => pk_alert_constant.g_no);
            
                g_error := 'CALL pk_edis_hist.add_value (signature). i_value=' || l_str;
                pk_edis_hist.add_value(i_label => NULL,
                                       i_value => l_str,
                                       i_type  => pk_edis_hist.g_type_signature,
                                       i_code  => 'SIGNATURE');
            
                i := sch_notes_coll.next(i);
            END LOOP;
        
        END IF;
    
        -- no show block
        g_error := 'OPEN cursor c_no_show';
        OPEN c_no_show;
        FETCH c_no_show
            INTO lcns;
    
        WHILE c_no_show%FOUND
        LOOP
        
            -- line necessary
            g_error := 'CALL pk_edis_hist.add_line';
            pk_edis_hist.add_line(i_history        => -1,
                                  i_dt_hist        => pk_date_utils.get_string_tstz(i_lang     => i_lang,
                                                                                    i_prof     => i_prof,
                                                                                    i_timezone => NULL),
                                  i_record_state   => lc.flg_status,
                                  i_desc_rec_state => lc.desc_status,
                                  i_professional   => lc.created_by,
                                  i_episode        => NULL);
        
            IF lcns.valor IS NOT NULL
            THEN
                -- header: Not performed
                g_error := 'CALL pk_edis_hist.add_value (title). i_label=' || pk_schedule_common.g_m_not_perf;
                pk_edis_hist.add_value(i_lang  => i_lang,
                                       i_label => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_not_perf),
                                       i_value => NULL,
                                       i_type  => pk_edis_hist.g_type_title);
            
                -- field: status (new record)
                g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_status_n;
                pk_edis_hist.add_value(i_lang  => i_lang,
                                       i_label => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_status_n),
                                       i_value => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_no_show),
                                       i_type  => pk_edis_hist.g_type_content);
            
                -- field: status
                g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_status;
                pk_edis_hist.add_value(i_lang  => i_lang,
                                       i_label => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_status),
                                       i_value => nvl(lcns.valor_ant, lc.desc_status),
                                       i_type  => pk_edis_hist.g_type_content);
            
                -- field: Reason
                g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_reason;
                pk_edis_hist.add_value(i_lang  => i_lang,
                                       i_label => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_reason),
                                       i_value => lcns.valor,
                                       i_type  => pk_edis_hist.g_type_content);
            
                -- field: Notes
                g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_notes;
                pk_edis_hist.add_value(i_lang  => i_lang,
                                       i_label => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_notes),
                                       i_value => lcns.no_show_notes,
                                       i_type  => pk_edis_hist.g_type_content);
            
                -- field: signature
                g_error := 'CALL pk_edis_hist.get_signature';
                l_str   := pk_edis_hist.get_signature(i_lang                   => i_lang,
                                                      i_id_episode             => NULL,
                                                      i_prof                   => i_prof,
                                                      i_date                   => lcns.dt_update,
                                                      i_id_prof_last_change    => lcns.id_prof_update,
                                                      i_has_historical_changes => pk_alert_constant.g_no);
            
                g_error := 'CALL pk_edis_hist.add_value (signature). i_value=' || l_str;
                pk_edis_hist.add_value(i_label => NULL,
                                       i_value => l_str,
                                       i_type  => pk_edis_hist.g_type_signature,
                                       i_code  => 'SIGNATURE');
            
            ELSE
                -- header: undo no show
                g_error := 'CALL pk_edis_hist.add_value (title). i_label=' || pk_schedule_common.g_m_undo_n_s;
                pk_edis_hist.add_value(i_lang  => i_lang,
                                       i_label => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_undo_n_s),
                                       i_value => NULL,
                                       i_type  => pk_edis_hist.g_type_title);
            
                -- field: status (new record)
                g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_status_n;
                pk_edis_hist.add_value(i_lang  => i_lang,
                                       i_label => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_status_n),
                                       i_value => NULL,
                                       i_type  => pk_edis_hist.g_type_content);
            
                -- field: status
                g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_status;
                pk_edis_hist.add_value(i_lang  => i_lang,
                                       i_label => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_status),
                                       i_value => nvl(lcns.valor_ant, lc.desc_status),
                                       i_type  => pk_edis_hist.g_type_content);
            
                -- field: Reason
                g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_reason;
                pk_edis_hist.add_value(i_lang  => i_lang,
                                       i_label => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_reason),
                                       i_value => NULL,
                                       i_type  => pk_edis_hist.g_type_content);
            
                -- field: Notes
                g_error := 'CALL pk_edis_hist.add_value (content). i_label=' || pk_schedule_common.g_m_notes;
                pk_edis_hist.add_value(i_lang  => i_lang,
                                       i_label => pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => pk_schedule_common.g_m_notes),
                                       i_value => NULL,
                                       i_type  => pk_edis_hist.g_type_content);
            
                -- field: signature
                g_error := 'CALL pk_edis_hist.get_signature';
                l_str   := pk_edis_hist.get_signature(i_lang                   => i_lang,
                                                      i_id_episode             => NULL,
                                                      i_prof                   => i_prof,
                                                      i_date                   => lcns.dt_update,
                                                      i_id_prof_last_change    => lcns.id_prof_update,
                                                      i_has_historical_changes => pk_alert_constant.g_no);
            
                g_error := 'CALL pk_edis_hist.add_value (signature). i_value=' || l_str;
                pk_edis_hist.add_value(i_label => NULL,
                                       i_value => l_str,
                                       i_type  => pk_edis_hist.g_type_signature,
                                       i_code  => 'SIGNATURE');
            END IF;
        
            FETCH c_no_show
                INTO lcns;
        END LOOP;
        CLOSE c_no_show;
    
        -- Scheduling block
        -- line necessary
        g_error := 'CALL pk_edis_hist.add_line';
        pk_edis_hist.add_line(i_history        => -1,
                              i_dt_hist        => pk_date_utils.get_string_tstz(i_lang     => i_lang,
                                                                                i_prof     => i_prof,
                                                                                i_timezone => NULL),
                              i_record_state   => lc.flg_status,
                              i_desc_rec_state => lc.desc_status,
                              i_professional   => lc.created_by,
                              i_episode        => NULL);
    
        g_error := 'CALL pk_schedule_common.add_scheduling_block. i_pat_name=' || lc.patient_name;
        pk_schedule_common.add_scheduling_block(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_pat_name     => lc.patient_name,
                                                i_sch_date     => lc.begin_date,
                                                i_tests        => lc.desc_analysis,
                                                i_created_date => lc.created_in,
                                                i_created_by   => lc.created_by);
    
        -- return output
        g_error := 'OPEN cursor o_detail';
        OPEN o_detail FOR
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
                      FROM TABLE(pk_edis_hist.tf_hist) t)
            -- remove history entries that have no difference from the previous record
            -- this is necessary due to diagnosis replications in the same visit
             WHERE count_elems > 2;
    
    END get_sch_hist;

    FUNCTION get_sch_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_detail      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_del sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M106');
    
        CURSOR c(i_tbl_id_schedule IN table_number) IS
            SELECT tt.rn,
                   decode(tt.cnt,
                          tt.rn,
                          decode(tt.flg_status,
                                 NULL,
                                 NULL,
                                 pk_schedule.get_domain_desc(i_lang,
                                                             pk_schedule.g_schedule_flg_status_domain,
                                                             tt.flg_status)),
                          decode(tt.flg_status,
                                 tt.flg_status_old,
                                 NULL,
                                 decode(tt.flg_status_old,
                                        NULL,
                                        NULL,
                                        pk_schedule.get_domain_desc(i_lang,
                                                                    pk_schedule.g_schedule_flg_status_domain,
                                                                    tt.flg_status_old)))) desc_status,
                   decode(tt.flg_status,
                          tt.flg_status_old,
                          NULL,
                          NULL,
                          l_msg_del,
                          pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_status_domain, tt.flg_status)) desc_status_new,
                   CASE
                        WHEN tt.rn = tt.cnt THEN
                         tt.patient_name
                    END patient_name,
                   decode(tt.cnt,
                          tt.rn,
                          decode(tt.dt_begin,
                                 NULL,
                                 NULL,
                                 pk_date_utils.date_char_tsz(i_lang, tt.dt_begin, i_prof.institution, i_prof.software)),
                          decode(tt.dt_begin,
                                 tt.dt_begin_old,
                                 NULL,
                                 decode(tt.dt_begin_old,
                                        NULL,
                                        NULL,
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    tt.dt_begin_old,
                                                                    i_prof.institution,
                                                                    i_prof.software)))) begin_date,
                   decode(tt.dt_begin,
                          tt.dt_begin_old,
                          NULL,
                          NULL,
                          l_msg_del,
                          pk_date_utils.date_char_tsz(i_lang, tt.dt_begin, i_prof.institution, i_prof.software)) begin_date_new,
                   CASE
                        WHEN tt.rn = tt.cnt THEN
                         tt.desc_exams
                    END desc_exams,
                   tt.id_prof_update created_by, -- Creator
                   tt.dt_schedule_hist created_in, -- create date
                   tt.id_cancel_reason, -- hidden field 
                   tt.desc_cancel_reason, -- no-show reason                     
                   tt.no_show_notes,
                   decode(tt.cnt,
                          tt.rn,
                          decode(tt.schedule_notes, NULL, NULL, tt.schedule_notes),
                          decode(tt.schedule_notes,
                                 tt.schedule_notes_old,
                                 NULL,
                                 decode(tt.schedule_notes_old, NULL, NULL, tt.schedule_notes_old))) schedule_notes,
                   decode(tt.schedule_notes, tt.schedule_notes_old, NULL, NULL, l_msg_del, tt.schedule_notes) schedule_notes_new
              FROM (SELECT row_number() over(ORDER BY t.dt_schedule_hist DESC) rn, MAX(rownum) over() cnt, t.*
                      FROM (SELECT sh.flg_status,
                                   first_value(sh.flg_status) over(ORDER BY sh.dt_schedule_hist rows BETWEEN 1 preceding AND CURRENT ROW) flg_status_old,
                                   p.name patient_name, -- patient name
                                   sh.dt_begin,
                                   first_value(sh.dt_begin) over(ORDER BY sh.dt_schedule_hist rows BETWEEN 1 preceding AND CURRENT ROW) dt_begin_old,
                                   (SELECT listagg(pk_translation.get_translation(i_lang, a.code_analysis), ', ') within GROUP(ORDER BY sa.id_analysis_req)
                                      FROM schedule_analysis sa
                                      JOIN analysis_req_det ard
                                        ON sa.id_analysis_req = ard.id_analysis_req
                                      JOIN analysis a
                                        ON a.id_analysis = ard.id_analysis
                                     WHERE sa.id_schedule = sh.id_schedule) desc_exams, -- Scheduled test(s)*/
                                   sh.id_prof_update,
                                   sh.dt_schedule_hist,
                                   sg.id_cancel_reason,
                                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) desc_cancel_reason, -- no-show reason
                                   sg.no_show_notes, -- no-show Notes
                                   to_char(sh.schedule_notes) schedule_notes, -- documentation notes
                                   first_value(to_char(sh.schedule_notes)) over(ORDER BY sh.dt_schedule_hist rows BETWEEN 1 preceding AND CURRENT ROW) schedule_notes_old
                              FROM schedule_hist sh
                              JOIN sch_group sg
                                ON sh.id_schedule = sg.id_schedule
                              JOIN patient p
                                ON sg.id_patient = p.id_patient
                              LEFT JOIN cancel_reason cr
                                ON cr.id_cancel_reason = sg.id_cancel_reason
                             WHERE sh.id_schedule IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                       t.column_value
                                                        FROM TABLE(i_tbl_id_schedule) t)
                               AND (sh.flg_notification_via IS NULL AND
                                   (sh.flg_status NOT IN ('C') OR sh.id_cancel_reason IS NOT NULL))) t) tt;
    
        CURSOR c_no_show IS
            SELECT pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || valor) valor,
                   pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || valor_ant) valor_ant,
                   dt_update,
                   id_prof_update,
                   no_show_notes
              FROM (SELECT nvl(CAST(h.id_cancel_reason AS VARCHAR(20)), 'null') valor,
                           lag(nvl(CAST(h.id_cancel_reason AS VARCHAR(20)), 'null'), 1, 'null') over(ORDER BY dt_update) valor_ant,
                           h.dt_update,
                           h.id_prof_update,
                           to_char(h.no_show_notes) no_show_notes
                      FROM sch_group_hist h
                     WHERE h.id_schedule = i_id_schedule)
             WHERE valor <> valor_ant
             ORDER BY dt_update DESC;
    
        lc             c%ROWTYPE;
        lcns           c_no_show%ROWTYPE;
        l_func_name    VARCHAR2(30) := g_package_name || '.GET_SCH_HIST';
        sch_notes_coll pk_schedule_common.tt_sch_hist_upd_info;
        i              PLS_INTEGER;
        l_area         VARCHAR2(100 CHAR) := 'SCHEDULED_MCDT_HISTORY';
    
        l_tab_scheduled_data     t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_scheduled_data_aux t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_aux                t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_documentation_data t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_no_show_data       t_tab_dd_block_data := t_tab_dd_block_data();
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
        l_index            PLS_INTEGER := 0;
    
        l_func_exception EXCEPTION;
    
        l_tbl_id_schedule table_number := table_number();
    
        FUNCTION get_id_schedule_ref
        (
            i_id_sched      IN schedule.id_schedule%TYPE,
            io_tbl_schedule IN OUT table_number
        ) RETURN BOOLEAN IS
            l_tbl_ids         table_number := table_number();
            l_id_schedule_ref schedule.id_schedule_ref%TYPE;
        BEGIN
        
            SELECT DISTINCT s.id_schedule_ref
              INTO l_id_schedule_ref
              FROM schedule s
             WHERE s.id_schedule = i_id_sched;
        
            IF l_id_schedule_ref IS NOT NULL
            THEN
                io_tbl_schedule.extend();
                io_tbl_schedule(io_tbl_schedule.count) := l_id_schedule_ref;
            
                IF NOT get_id_schedule_ref(i_id_sched => l_id_schedule_ref, io_tbl_schedule => io_tbl_schedule)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            RETURN TRUE;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_id_schedule_ref;
    BEGIN
        l_tbl_id_schedule.extend();
        l_tbl_id_schedule(l_tbl_id_schedule.count) := i_id_schedule;
    
        IF NOT get_id_schedule_ref(i_id_sched => i_id_schedule, io_tbl_schedule => l_tbl_id_schedule)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- get raw data
        g_error := 'OPEN cursor c';
        OPEN c(l_tbl_id_schedule);
        LOOP
            FETCH c
                INTO lc;
            EXIT WHEN c%NOTFOUND;
        
            l_index := l_index + 1;
        
            -- Scheduling block
            SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                       (ddb.rank + 3000) + l_index,
                                       NULL,
                                       NULL,
                                       ddb.condition_val,
                                       NULL,
                                       NULL,
                                       dd.data_source,
                                       dd.data_source_val,
                                       NULL)
              BULK COLLECT
              INTO l_tab_scheduled_data_aux
              FROM (SELECT data_source, data_source_val
                      FROM (SELECT t.*
                              FROM (SELECT ' ' AS title,
                                           lc.patient_name,
                                           lc.begin_date AS scheduling_date,
                                           lc.begin_date_new AS scheduling_date_new,
                                           lc.desc_exams AS scheduled_mcdts,
                                           lc.schedule_notes AS notes,
                                           lc.schedule_notes_new AS notes_new,
                                           lc.desc_status AS status,
                                           lc.desc_status_new AS status_new,
                                           pk_prof_utils.get_name_signature(i_lang, i_prof, lc.created_by) ||
                                           decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                   i_prof,
                                                                                   lc.created_by,
                                                                                   lc.created_in,
                                                                                   NULL),
                                                  NULL,
                                                  '; ',
                                                  ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                           i_prof,
                                                                                           lc.created_by,
                                                                                           lc.created_in,
                                                                                           NULL) || '); ') ||
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       lc.created_in,
                                                                       i_prof.institution,
                                                                       i_prof.software) registry,
                                           ' ' white_line
                                      FROM dual) t) unpivot include NULLS(data_source_val FOR data_source IN(title,
                                                                                                             patient_name,
                                                                                                             scheduling_date,
                                                                                                             scheduling_date_new,
                                                                                                             scheduled_mcdts,
                                                                                                             notes,
                                                                                                             notes_new,
                                                                                                             status,
                                                                                                             status_new,
                                                                                                             registry,
                                                                                                             white_line))) dd
              JOIN dd_block ddb
                ON ddb.area = l_area
               AND ddb.internal_name = 'SCHEDULE'
               AND ddb.flg_available = pk_alert_constant.g_yes;
        
            FOR j IN l_tab_scheduled_data_aux.first .. l_tab_scheduled_data_aux.last
            LOOP
                l_tab_scheduled_data.extend();
                l_tab_scheduled_data(l_tab_scheduled_data.count) := l_tab_scheduled_data_aux(j);
            END LOOP;
        END LOOP;
        CLOSE c;
    
        g_error := 'open cursor c_no_show';
        OPEN c_no_show;
        FETCH c_no_show
            INTO lcns;
    
        l_tab_aux := t_tab_dd_block_data();
        i         := 0;
        WHILE c_no_show%FOUND
        LOOP
            i := i + 1;
            IF lcns.valor IS NOT NULL
            THEN
                SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                           (ddb.rank * i) + 2000,
                                           NULL,
                                           NULL,
                                           ddb.condition_val,
                                           NULL,
                                           NULL,
                                           dd.data_source,
                                           dd.data_source_val,
                                           NULL)
                  BULK COLLECT
                  INTO l_tab_aux
                  FROM (SELECT data_source, data_source_val
                          FROM (SELECT t.*
                                  FROM (SELECT ' ' AS title,
                                               pk_message.get_message(i_lang      => i_lang,
                                                                      i_code_mess => pk_schedule_common.g_m_no_show) status_new,
                                               nvl(lcns.valor_ant, lc.desc_status) AS status,
                                               lcns.valor AS reason,
                                               lcns.no_show_notes notes,
                                               pk_prof_utils.get_name_signature(i_lang, i_prof, lcns.id_prof_update) ||
                                               decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                       i_prof,
                                                                                       lcns.id_prof_update,
                                                                                       lcns.dt_update,
                                                                                       NULL),
                                                      NULL,
                                                      '; ',
                                                      ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                               i_prof,
                                                                                               lcns.id_prof_update,
                                                                                               lcns.dt_update,
                                                                                               NULL) || '); ') ||
                                               pk_date_utils.date_char_tsz(i_lang,
                                                                           lcns.dt_update,
                                                                           i_prof.institution,
                                                                           i_prof.software) registry,
                                               ' ' white_line
                                          FROM dual) t) unpivot include NULLS(data_source_val FOR data_source IN(title,
                                                                                                                 status_new,
                                                                                                                 status,
                                                                                                                 reason,
                                                                                                                 notes,
                                                                                                                 registry,
                                                                                                                 white_line))) dd
                  JOIN dd_block ddb
                    ON ddb.area = l_area
                   AND ddb.internal_name = 'NO_SHOW'
                   AND ddb.flg_available = pk_alert_constant.g_yes;
            
                FOR j IN l_tab_aux.first .. l_tab_aux.last
                LOOP
                    l_tab_no_show_data.extend();
                    l_tab_no_show_data(l_tab_no_show_data.count) := l_tab_aux(j);
                END LOOP;
            ELSE
                --undo no show
                SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                           (ddb.rank * i) + 2000,
                                           NULL,
                                           NULL,
                                           ddb.condition_val,
                                           NULL,
                                           NULL,
                                           dd.data_source,
                                           dd.data_source_val,
                                           NULL)
                  BULK COLLECT
                  INTO l_tab_aux
                  FROM (SELECT data_source, data_source_val
                          FROM (SELECT t.*
                                  FROM (SELECT ' ' AS title,
                                               pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M106') status_new,
                                               nvl(lcns.valor_ant, lc.desc_status) AS status,
                                               NULL AS reason,
                                               NULL notes,
                                               pk_prof_utils.get_name_signature(i_lang, i_prof, lcns.id_prof_update) ||
                                               decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                       i_prof,
                                                                                       lcns.id_prof_update,
                                                                                       lcns.dt_update,
                                                                                       NULL),
                                                      NULL,
                                                      '; ',
                                                      ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                               i_prof,
                                                                                               lcns.id_prof_update,
                                                                                               lcns.dt_update,
                                                                                               NULL) || '); ') ||
                                               pk_date_utils.date_char_tsz(i_lang,
                                                                           lcns.dt_update,
                                                                           i_prof.institution,
                                                                           i_prof.software) registry,
                                               ' ' white_line
                                          FROM dual) t) unpivot include NULLS(data_source_val FOR data_source IN(title,
                                                                                                                 status_new,
                                                                                                                 status,
                                                                                                                 reason,
                                                                                                                 notes,
                                                                                                                 registry,
                                                                                                                 white_line))) dd
                  JOIN dd_block ddb
                    ON ddb.area = l_area
                   AND ddb.internal_name = 'UNDO_NO_SHOW'
                   AND ddb.flg_available = pk_alert_constant.g_yes;
            
                FOR j IN l_tab_aux.first .. l_tab_aux.last
                LOOP
                    l_tab_no_show_data.extend();
                    l_tab_no_show_data(l_tab_no_show_data.count) := l_tab_aux(j);
                END LOOP;
            END IF;
        
            FETCH c_no_show
                INTO lcns;
        END LOOP;
        CLOSE c_no_show;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  ELSE
                                   NULL
                              END,
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END,
                              flg_type,
                              flg_html,
                              NULL,
                              flg_clob),
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_scheduled_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = l_area
                   AND ddc.id_dd_block = 1
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_no_show_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = l_area
                   AND ddc.id_dd_block = 2
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L2N'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_documentation_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = l_area
                   AND ddc.id_dd_block = 3
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L2N')))
         ORDER BY rnk, rank;
    
        -- return output
        g_error := 'OPEN o_detail';
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || decode(d.flg_type, 'LP', NULL, 'L2N', NULL, ': ')
                            END descr,
                           d.val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCH_HIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_detail);
            RETURN FALSE;
    END get_sch_hist;

    /*
    *
    */
    FUNCTION cancel_req_schedules
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_req           IN schedule_analysis.id_analysis_req%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'CANCEL_REQ_SCHEDULES';
        l_ids_sch        table_number;
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
        i PLS_INTEGER;
    BEGIN
        g_error := 'get_req_schedule_ids - do select. i_id_req=' || nvl(to_char(i_id_req), 'null');
        SELECT DISTINCT s.id_schedule
          BULK COLLECT
          INTO l_ids_sch
          FROM schedule s
          JOIN schedule_analysis sa
            ON s.id_schedule = sa.id_schedule
         WHERE sa.id_analysis_req = i_id_req
           AND s.flg_status = pk_schedule.g_status_scheduled;
    
        IF l_ids_sch IS empty
        THEN
            RETURN TRUE;
        END IF;
    
        -- begin remote transaction
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- iterate all ids found...        
        i := l_ids_sch.first;
        WHILE i IS NOT NULL
        LOOP
            -- ...and cancel every one
            g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.CANCEL_SCHEDULE';
            IF NOT pk_schedule_api_upstream.cancel_schedule(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_id_schedule      => l_ids_sch(i),
                                                            i_id_cancel_reason => i_id_cancel_reason,
                                                            i_cancel_notes     => i_cancel_notes,
                                                            i_transaction_id   => l_transaction_id,
                                                            o_error            => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            i := l_ids_sch.next(i);
        END LOOP;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id, i_prof => i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            IF l_transaction_id IS NOT NULL
            THEN
                pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id, i_prof => i_prof);
            END IF;
            RETURN FALSE;
    END cancel_req_schedules;

BEGIN
    -- Log initialization
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_lab;
/
