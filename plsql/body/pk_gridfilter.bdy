CREATE OR REPLACE PACKAGE BODY pk_gridfilter IS

    exc_impossible_date EXCEPTION;
    PRAGMA EXCEPTION_INIT(exc_impossible_date, -01878);
    /**
    * Return values to internaly be used by the views, not as parameter of the view
    *
    * @param i_variable     name of the variable that must be processed
    * @param i_lang         Language ID (Optional, based on the variable)
    * @param i_prof         Profissional (Optional, based on the variable)
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */

    FUNCTION get_strings
    (
        i_variable IN VARCHAR2,
        i_lang     IN language.id_language%TYPE := NULL,
        i_prof     IN profissional := NULL
    ) RETURN VARCHAR2 IS
        l_ret    VARCHAR2(250);
        l_dt     VARCHAR2(250);
        l_dt_min TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_max TIMESTAMP WITH LOCAL TIME ZONE;
        g_error  VARCHAR2(3200);
        o_error  t_error_out;
    BEGIN
    
        CASE i_variable
            WHEN 'g_episode_type_interv' THEN
                l_ret := pk_procedures_constant.g_episode_type_interv;
            WHEN 'g_epis_status_inactive' THEN
                l_ret := pk_alert_constant.g_epis_status_inactive;
            WHEN 'g_epis_status_active' THEN
                l_ret := pk_alert_constant.g_epis_status_active;
            WHEN 'g_epis_flg_appointment_type' THEN
                l_ret := pk_grid_amb.g_epis_flg_appointment_type;
            WHEN 'g_null_appointment_type' THEN
                l_ret := 'N';
            WHEN 'l_waiting_room_sys_external' THEN
                l_ret := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', i_prof);
            WHEN 'l_waiting_room_available' THEN
                l_ret := pk_sysconfig.get_config('WL_WAITING_ROOM_AVAILABLE', i_prof);
            WHEN 'l_edis_timelimit' THEN
                l_ret := nvl(pk_sysconfig.get_config('EDIS_GRID_HOURS_LIMIT_SHOW_DISCH', i_prof), 12);
            WHEN 'g_sched_nurse_disch' THEN
                l_ret := pk_grid_amb.g_sched_nurse_disch;
            WHEN 'l_show_nurse_disch' THEN
                l_ret := nvl(pk_sysconfig.get_config('SHOW_NURSE_DISCHARGED_GRID', i_prof), pk_alert_constant.get_no());
            WHEN 'g_flg_ehr_s' THEN
                l_ret := pk_visit.g_flg_ehr_s;
            WHEN 'l_filter_by_dcs' THEN
                l_ret := pk_sysconfig.get_config('AMB_GRID_NURSE_SHOW_BY_DCS', i_prof);
            WHEN 'g_selected' THEN
                l_ret := pk_grid_amb.g_selected;
            WHEN 'l_prof_cat' THEN
                l_ret := pk_edis_list.get_prof_cat(i_prof);
            WHEN 'g_prof_dep_status' THEN
                l_ret := 'S';
            WHEN 'flg_epis_disch' THEN
                l_ret := 'I';
            WHEN 'dish_status' THEN
                l_ret := 'A';
            WHEN 'l_show_med_disch' THEN
                l_ret := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', i_prof),
                             pk_alert_constant.get_yes());
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_ret);
            WHEN 'l_show_resident_physician' THEN
                l_ret := pk_sysconfig.get_config(i_code_cf => 'GRIDS_SHOW_RESIDENT', i_prof => i_prof);
            WHEN 'l_type_appoint_edition' THEN
            
                IF instr(pk_sysconfig.get_config('ALLOW_MY_ROOM_SPECIALITY_GRID_TYPE_APPOINT_EDITION',
                                                 i_prof.institution,
                                                 i_prof.software),
                         '|' || pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof) || '|') > 0
                THEN
                    l_ret := pk_alert_constant.g_yes;
                ELSE
                    l_ret := pk_alert_constant.g_no;
                END IF;
            WHEN 'i_dt' THEN
                l_ret := nvl(sys_context('ALERT_CONTEXT', 'i_dt'),
                             pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof)); --parameter_i_dt;
            WHEN 'g_type_appointment' THEN
                l_ret := sys_context('ALERT_CONTEXT', 'i_type_appointment'); --i_type; -- Parameter_i_type
            WHEN 'g_sysdate_char' THEN
                l_ret := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
            WHEN 'g_domain_sch_presence' THEN
                l_ret := pk_grid_amb.g_domain_sch_presence;
            WHEN 'g_sched_scheduled' THEN
                l_ret := 'A';
            WHEN 'g_domain_pat_gender_abbr' THEN
                l_ret := 'PATIENT.GENDER.ABBR';
            WHEN 'g_schdl_outp_state_domain' THEN
                l_ret := pk_grid_amb.g_schdl_outp_state_domain;
            WHEN 'g_schdl_outp_sched_domain' THEN
                l_ret := pk_grid_amb.g_schdl_outp_sched_domain;
            WHEN 'g_flg_doctor' THEN
                l_ret := pk_grid_amb.g_flg_doctor;
            WHEN 'g_task_analysis' THEN
                l_ret := pk_grid_amb.g_task_analysis;
            WHEN 'i_prof_cat_type' THEN
                l_ret := sys_context('ALERT_CONTEXT', 'i_prof_cat_type'); -- Parameter i_prof_cat_type
            WHEN 'g_task_exam' THEN
                l_ret := 'E';
            WHEN 'g_analysis_exam_icon_grid_rank' THEN
                l_ret := pk_grid_amb.g_analysis_exam_icon_grid_rank;
            WHEN 'g_sched_adm_disch' THEN
                l_ret := pk_grid_amb.g_sched_adm_disch;
            WHEN 'g_sched_med_disch' THEN
                l_ret := pk_grid_amb.g_sched_med_disch;
            WHEN 'l_waiting_room_available' THEN
                l_ret := pk_sysconfig.get_config(pk_grid_amb.g_sys_config_wr, i_prof);
            WHEN 'l_waiting_room_sys_external' THEN
                l_ret := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', i_prof);
            WHEN 'g_active' THEN
                l_ret := pk_alert_constant.g_active;
            WHEN 'l_reasongrid' THEN
                l_ret := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', i_prof);
            WHEN 'l_no_present_patient' THEN
                l_ret := pk_message.get_message(i_lang, 'THERAPEUTIC_DECISION_T017');
            WHEN 'l_handoff_type' THEN
                pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_ret);
            WHEN 'g_cat_type_doc' THEN
                l_ret := pk_alert_constant.g_cat_type_doc;
            WHEN 'g_resident' THEN
                l_ret := pk_hand_off_core.g_resident;
            WHEN 'g_cat_type_nurse' THEN
                l_ret := pk_alert_constant.g_cat_type_nurse;
            WHEN 'g_flg_ehr' THEN
                l_ret := pk_ehr_access.g_flg_ehr_ehr;
            WHEN 'l_sysdate_char_short' THEN
                l_ret := pk_date_utils.to_char_insttimezone(i_prof, current_timestamp, 'YYYYMMDD');
            WHEN 'l_dt_min' THEN
                l_dt := nvl(sys_context('ALERT_CONTEXT', 'i_dt'),
                            pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof));
                get_date_bounds(i_lang   => i_lang,
                                i_prof   => i_prof,
                                i_dt     => l_dt,
                                o_dt_min => l_dt_min,
                                o_dt_max => l_dt_max);
                l_ret := l_dt_min; -- Parameter
            WHEN 'l_dt_max' THEN
                l_dt := nvl(sys_context('ALERT_CONTEXT', 'i_dt'),
                            pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof));
                get_date_bounds(i_lang   => i_lang,
                                i_prof   => i_prof,
                                i_dt     => l_dt,
                                o_dt_min => l_dt_min,
                                o_dt_max => l_dt_max);
                l_ret := l_dt_max; -- Parameter
            WHEN 'g_epis_type_nurse' THEN
                l_ret := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
            WHEN 'g_sched_status_cache' THEN
                l_ret := pk_schedule.g_sched_status_cache;
            WHEN 'g_sched_canc' THEN
                l_ret := 'C';
            WHEN 'g_sch_event_therap_decision' THEN
                l_ret := pk_grid_amb.g_sch_event_therap_decision;
            WHEN 'l_sch_t640' THEN
                l_ret := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
            WHEN 'g_type_room' THEN
                l_ret := 'R';
            WHEN 'flg_interv_start' THEN
                l_ret := 'IC';
            WHEN 'flg_status_a' THEN
                l_ret := 'A';
            WHEN 'g_pat_status_s' THEN
                l_ret := 'S';
            WHEN 'g_pat_status_l' THEN
                l_ret := 'L';
            WHEN 'g_pat_status_pend' THEN
                l_ret := 'A';
            WHEN 'g_type_sch' THEN
                l_ret := 'S';
            WHEN 'k_default_schema' THEN
                l_ret := pk_sysdomain.k_default_schema;
            WHEN 'g_flg_ehr_normal' THEN
                l_ret := 'N';
            WHEN 'l_egoo' THEN
                l_ret := 'EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE';
            WHEN 'ei_flag_status' THEN
                l_ret := 'EPIS_INFO.FLG_STATUS';
            WHEN 'g_flg_nurse' THEN
                l_ret := pk_alert_constant.g_flg_nurse;
            WHEN 'g_desc_grid' THEN
                l_ret := 'G';
            WHEN 'g_ft_color' THEN
                l_ret := '0xFFFFFF';
            WHEN 'g_ft_triage_white' THEN
                l_ret := '0x787864';
            WHEN 'g_ft_status' THEN
                l_ret := 'A';
            WHEN 'g_icon_ft' THEN
                l_ret := 'F';
            WHEN 'g_icon_ft_transfer' THEN
                l_ret := 'T';
            WHEN 'g_discharge_flg_status_pend' THEN
                l_ret := 'P';
            WHEN 'g_domain_nurse_act' THEN
                l_ret := 'NURSE_ACTIVITY_REQ.FLG_STATUS';
            WHEN 'g_sort_type_age' THEN
                l_ret := pk_edis_proc.g_sort_type_age;
            WHEN 'g_sort_type_los' THEN
                l_ret := pk_edis_proc.g_sort_type_los;
            WHEN 'g_soft_outpatient' THEN
                l_ret := to_char(pk_alert_constant.g_soft_outpatient);
            WHEN 'g_epis_type' THEN
                l_ret := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => i_prof);
            WHEN 'l_show_only_epis_resp' THEN
                l_ret := pk_sysconfig.get_config(i_code_cf => pk_hand_off_core.g_config_show_only_epis_resp,
                                                 i_prof    => i_prof);
        END CASE;
        RETURN l_ret;
    
    EXCEPTION
        WHEN case_not_found THEN
            g_error := 'Variable ' || i_variable || ' not expected';
            dbms_output.put_line(g_error);
            pk_alert_exceptions.process_error(nvl(i_lang, 1),
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'pk_gridfilter',
                                              'GET_STRING_VAR',
                                              o_error);
            RETURN NULL;
    END;

    FUNCTION get_tstz
    (
        i_variable IN VARCHAR2,
        i_lang     IN language.id_language%TYPE := NULL,
        i_prof     IN profissional := NULL
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_ret    schedule_outp.dt_target_tstz%TYPE;
        l_dt     VARCHAR2(250);
        l_dt_min schedule_outp.dt_target_tstz%TYPE;
        l_dt_max schedule_outp.dt_target_tstz%TYPE;
        l_bool   BOOLEAN;
        g_error  VARCHAR2(3200);
        o_error  t_error_out;
    BEGIN
    
        CASE i_variable
            WHEN 'l_dt_min' THEN
                l_dt  := nvl(sys_context('ALERT_CONTEXT', 'i_dt'),
                             pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof));
                l_ret := CAST(trunc(to_date(l_dt, 'yyyymmddHH24miss'), 'DD') AS TIMESTAMP);
            WHEN 'l_dt_max' THEN
                l_dt  := nvl(sys_context('ALERT_CONTEXT', 'i_dt'),
                             pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof));
                l_ret := pk_date_utils.add_to_ltstz(i_timestamp => CAST(trunc(to_date(l_dt, 'yyyymmddHH24miss'), 'DD') AS
                                                                        TIMESTAMP),
                                                    i_amount    => 86399,
                                                    i_unit      => 'second');
        END CASE;
        RETURN l_ret;
    END;

    FUNCTION get_filterdate
    (
        i_variable IN VARCHAR2,
        i_vc_date  IN VARCHAR2 := NULL,
        i_lang     IN NUMBER := NULL,
        i_prof     IN profissional := NULL
    ) RETURN VARCHAR2 IS
        l_ret    VARCHAR2(50);
        l_dt     VARCHAR2(50);
        l_mask   VARCHAR2(50) := 'YYYYMMDDHH24MISS';
        l_lang   language.id_language%TYPE;
        l_prof   profissional;
        l_dt_min schedule_outp.dt_target_tstz%TYPE;
        l_dt_max schedule_outp.dt_target_tstz%TYPE;
        o_err    t_error_out;
        l_bol    BOOLEAN;
    BEGIN
        l_lang := nvl(i_lang, sys_context('ALERT_CONTEXT', 'i_lang'));
        l_prof := nvl(l_prof,
                      NEW profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                   sys_context('ALERT_CONTEXT', 'i_institution'),
                                   sys_context('ALERT_CONTEXT', 'i_software')));
        l_dt   := nvl(i_vc_date, nvl(sys_context('ALERT_CONTEXT', 'i_dt'), to_char(SYSDATE, l_mask)));
    
        get_date_bounds(i_lang   => sys_context('ALERT_CONTEXT', 'i_lang'),
                        i_prof   => l_prof,
                        i_dt     => l_dt,
                        o_dt_min => l_dt_min,
                        o_dt_max => l_dt_max);
    
        CASE i_variable
            WHEN 'l_dt_min' THEN
                l_bol := pk_date_utils.trunc_insttimezone(i_lang      => to_char(l_lang),
                                                          i_prof      => l_prof,
                                                          i_timestamp => l_dt_min,
                                                          i_format    => 'SS',
                                                          i_timezone  => NULL,
                                                          o_timestamp => l_dt_min,
                                                          o_error     => o_err);
                l_ret := to_char(l_dt_min, l_mask);
            WHEN 'l_dt_max' THEN
                l_bol := pk_date_utils.trunc_insttimezone(i_lang      => to_char(l_lang),
                                                          i_prof      => l_prof,
                                                          i_timestamp => l_dt_max,
                                                          i_format    => 'SS',
                                                          i_timezone  => NULL,
                                                          o_timestamp => l_dt_max,
                                                          o_error     => o_err);
                l_ret := to_char(l_dt_max, l_mask);
        END CASE;
        RETURN l_ret;
    END;

    /**
    * Return category type of an professional
    *
    * @param i_prof         Profissional (Optional, based on the variable)
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    /*    FUNCTION get_prof_cat(i_prof IN profissional) RETURN VARCHAR2 IS
        l_cat_type category.flg_type%TYPE;
    BEGIN
        SELECT cat.flg_type
          INTO l_cat_type
          FROM category cat, professional prf, prof_cat prc
         WHERE prf.id_professional = i_prof.id
           AND prc.id_professional = prf.id_professional
           AND prc.id_institution = i_prof.institution
           AND cat.id_category = prc.id_category;
        RETURN l_cat_type;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END;*/

    /**
    * Return the reason assigned to an schedule
    *
    * @param i_lang         Language ID
    * @param i_id_schedule  ID Schedule
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    /*FUNCTION get_reason
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_reason VARCHAR2(3000);
    BEGIN
        SELECT substr(concatenate(decode(nvl(ec.id_complaint, decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                         NULL,
                                         ec.patient_complaint,
                                         pk_translation.get_translation(i_lang,
                                                                        'COMPLAINT.CODE_COMPLAINT.' ||
                                                                        nvl(ec.id_complaint,
                                                                            decode(s2.flg_reason_type,
                                                                                   'C',
                                                                                   s2.id_reason,
                                                                                   NULL)))) || '; '),
                      1,
                      length(concatenate(decode(nvl(ec.id_complaint, decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                NULL,
                                                ec.patient_complaint,
                                                pk_translation.get_translation(i_lang,
                                                                               'COMPLAINT.CODE_COMPLAINT.' ||
                                                                               nvl(ec.id_complaint,
                                                                                   decode(s2.flg_reason_type,
                                                                                          'C',
                                                                                          s2.id_reason,
                                                                                          NULL))) || '; '))) -
                      length('; '))
          INTO l_reason
          FROM schedule s2
          LEFT JOIN epis_info ei2
            ON ei2.id_schedule = s2.id_schedule
          LEFT JOIN epis_complaint ec
            ON ec.id_episode = ei2.id_episode
         WHERE s2.id_schedule = i_id_schedule
           AND nvl(ec.flg_status, pk_gridfilter.get_strings('g_active')) = pk_gridfilter.get_strings('g_active');
    
        RETURN l_reason;
    
    END;*/

    /**
    * Calculate and return date min and max to be used as filter of the views
    *
    * @param i_lang         Language ID 
    * @param i_prof         Profissional 
    * @param i_dt           Date base for the process
    * @return o_dt_min
    * @return o_dt_max
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    PROCEDURE get_date_bounds
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_dt     IN VARCHAR2,
        o_dt_min OUT schedule_outp.dt_target_tstz%TYPE,
        o_dt_max OUT schedule_outp.dt_target_tstz%TYPE
    ) IS
        l_day_in_seconds CONSTANT NUMBER := 86399;
    BEGIN
        o_dt_min := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                     i_timestamp => nvl(pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                      i_prof      => i_prof,
                                                                                                      i_timestamp => i_dt,
                                                                                                      i_timezone  => NULL),
                                                                        current_timestamp));
        o_dt_max := pk_date_utils.add_to_ltstz(i_timestamp => o_dt_min,
                                               i_amount    => l_day_in_seconds,
                                               i_unit      => 'SECOND');
    
    END get_date_bounds;

    /**
    * Print the procedure name
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    PROCEDURE showme IS
    BEGIN
        dbms_output.put_line('' || $$PLSQL_UNIT);
    END;

    /**
    * Set the SQL that will be parsed and create the initial structure (custom_filter=0)
    *
    * @param i_sql          Query, based on the view, that must be parsed
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    PROCEDURE setsql(i_sql IN VARCHAR2) IS
    BEGIN
        g_sql := i_sql;
    END;

    /**
    * Print comments to track the execution of the script
    *
    * @param funct          name of the function where the log was called
    * @param itext          message to the showed
    * @param i_brk          break session ( 1 to break session )
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    PROCEDURE logme
    (
        funct IN VARCHAR2,
        itext IN VARCHAR2,
        i_brk IN NUMBER := 0
    ) IS
        l_funct VARCHAR2(250);
    BEGIN
        IF funct = 'MAIN'
        THEN
            dbms_output.put_line('-----------------------------------------');
            l_funct := 'FUNCTION:' || funct;
        ELSE
            IF i_brk = 1
            THEN
                l_funct := lower('.' || funct);
                dbms_output.put_line(l_funct);
            END IF;
        END IF;
        IF funct = 'MAIN'
        THEN
            dbms_output.put_line(itext);
        ELSE
            dbms_output.put_line('...' || itext);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('LOGME Error:' || SQLERRM);
            RAISE;
    END;

    /**
    * Parse the query defined in the method setsql and stored in the g_sql variable
    *
    * @param i_filter_name  Filter name
    * @param i_screen_name  Screen that must be assined to the filter
    * @param i_package_nm   Package that is calling the method
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    PROCEDURE set_source_filter
    (
        i_filter_name IN VARCHAR2,
        i_screen_name IN VARCHAR2,
        i_package_nm  IN VARCHAR2 := $$PLSQL_UNIT,
        i_parse_yn    IN VARCHAR2 := 'Y'
    ) IS
        l_msg      VARCHAR2(250);
        l_chk      NUMBER;
        l_tifilter VARCHAR2(250);
    BEGIN
        IF i_parse_yn = 'Y'
        THEN
            l_msg := 'Parse_Filter_sql for ' || i_filter_name;
            BEGIN
                pk_filter_build.parse_filter_sql(i_filter_name  => i_filter_name,
                                                 i_page_size    => 50,
                                                 i_sql          => g_sql,
                                                 i_generate_all => TRUE);
            EXCEPTION
                WHEN OTHERS THEN
                    dbms_output.enable();
                    dbms_output.put_line('Error in Parsing phase');
                    BEGIN
                        pk_filter_build.parse_filter_sql(i_filter_name  => i_filter_name,
                                                         i_page_size    => 50,
                                                         i_sql          => g_sql,
                                                         i_generate_all => FALSE);
                    EXCEPTION
                        WHEN OTHERS THEN
                            dbms_output.put_line('Error in Parsing phase');
                            ROLLBACK;
                            RAISE;
                    END;
            END;
        END IF;
    
        logme('SET_SOURCE_FILTER', 'SQL Assigned to the filter.' || i_filter_name, 1);
        l_msg := 'Register_on_classes for filter: ' || i_filter_name || ' AND screen: ' || i_screen_name;
    
        SELECT COUNT(1)
          INTO l_chk
          FROM ux_list_class c
         WHERE c.class_name = upper(i_screen_name)
           AND c.filter_name != i_filter_name;
        IF l_chk >= 1
        THEN
            SELECT filter_name
              INTO l_tifilter
              FROM ux_list_class c
             WHERE c.class_name = upper(i_screen_name)
               AND c.filter_name != i_filter_name;
            pk_filter_build.delete_classes(i_filter_name => l_tifilter,
                                           i_lists_class => NEW table_varchar(i_screen_name));
            logme('SET_SOURCE_FILTER', '>>Existent class removed of the filter:' || l_tifilter);
        END IF;
        pk_filter_build.register_on_classes(i_filter_name => i_filter_name,
                                            i_lists_class => NEW table_varchar(i_screen_name));
        logme('SET_SOURCE_FILTER', 'UX Screen assigned to the filter. ' || i_screen_name);
        l_msg := 'Assign_procedure for filter: ' || i_filter_name || ' AND Package: ' || i_package_nm;
        pk_filter_build.register_before_procedure(i_filter_name => i_filter_name,
                                                  i_procedure   => i_package_nm || '.init_params_patient_grids');
        logme('SET_SOURCE_FILTER', 'Package assigned to the filter. ' || i_package_nm || '.init_params_patient_grids');
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('PARSING PHASE failed' || chr(10) || l_msg);
            ROLLBACK;
            RAISE;
    END;

    /**
    * Assign custom filter fields (where clause) to the custom filter
    *
    * @param p_filter_name      Filter name
    * @param p_id_cust_filter   ID Custom Filter - Number
    * @param p_id_field         ID Custom filter field - Number
    * @param p_descr            Description of the field
    * @param p_macros           table_varchar with the macros that must be used
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    PROCEDURE assign_filter
    (
        p_filter_name    IN VARCHAR2,
        p_id_cust_filter IN NUMBER,
        p_id_field       IN NUMBER,
        p_descr          IN VARCHAR2,
        p_macros         IN table_varchar
    ) IS
        l_count NUMBER;
        l_codes table_varchar := NEW table_varchar();
        l_descr table_varchar := NEW table_varchar();
    BEGIN
        l_count := p_macros.count;
        FOR i IN 1 .. l_count
        LOOP
            l_codes.extend();
            l_codes(i) := '';
            l_descr.extend();
            l_descr(i) := p_descr;
        END LOOP;
    
        IF l_count > 0
        THEN
            pk_filter_build.set_field_values(i_filter            => p_filter_name,
                                             i_custom_filter     => p_id_cust_filter,
                                             i_field             => p_id_field,
                                             i_macro_codes       => l_codes,
                                             i_macro_descs       => l_descr,
                                             i_macros            => p_macros,
                                             i_range_macro_codes => NULL,
                                             i_range_macro_descs => NULL,
                                             i_range_macros      => NULL,
                                             i_value_codes       => table_varchar(),
                                             i_value_descs       => table_varchar(),
                                             i_vc2_values        => NULL,
                                             i_num_values        => NULL,
                                             i_id_values         => NULL,
                                             i_tstz_values       => NULL,
                                             i_intd2s_values     => NULL,
                                             i_inty2m_values     => NULL,
                                             i_id_record         => NULL);
        ELSE
            pk_filter_build.set_field_values(i_filter            => p_filter_name,
                                             i_custom_filter     => p_id_cust_filter,
                                             i_field             => p_id_field,
                                             i_macro_codes       => table_varchar(), --l_codes,
                                             i_macro_descs       => table_varchar(), --l_descr,
                                             i_macros            => table_varchar(), --p_macros,
                                             i_range_macro_codes => NULL,
                                             i_range_macro_descs => NULL,
                                             i_range_macros      => NULL,
                                             i_value_codes       => table_varchar(''),
                                             i_value_descs       => table_varchar(p_descr),
                                             i_vc2_values        => table_varchar('Y'),
                                             i_num_values        => NULL,
                                             i_id_values         => NULL,
                                             i_tstz_values       => NULL,
                                             i_intd2s_values     => NULL,
                                             i_inty2m_values     => NULL,
                                             i_id_record         => NULL);
        END IF;
    
    END;

    /**
    * Return the config id that must be used for all markets
    *
    * @param There is no parameters
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    FUNCTION get_config_id RETURN NUMBER IS
    BEGIN
        RETURN pk_core_config.insert_into_config(i_market             => 0,
                                                 i_inst_owner         => 0,
                                                 i_institution        => 0,
                                                 i_category           => 0,
                                                 i_profile_template   => 0,
                                                 i_software           => 0,
                                                 i_professional       => 0,
                                                 i_dep_clin_serv      => 0,
                                                 i_epis_dep_clin_serv => 0,
                                                 i_config_parent      => NULL,
                                                 i_inst_owner_parent  => NULL,
                                                 i_id_config          => NULL);
    END;

    /**
    * Return the id_record of the custom_filter or the next available
    *
    * @param i_id_cust_filter  ID Custom Filter - Number
    * @param i_filter_name     Filter name
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    FUNCTION get_id_record
    (
        i_id_cust_filter IN NUMBER,
        i_filter_name    IN VARCHAR2
    ) RETURN NUMBER IS
        l_id_record NUMBER;
    BEGIN
        SELECT id_record
          INTO l_id_record
          FROM custom_filter cs
         WHERE cs.filter_name = i_filter_name
           AND cs.id_custom_filter = i_id_cust_filter
           AND id_record = (SELECT MIN(id_record)
                              FROM custom_filter
                             WHERE filter_name = cs.filter_name
                               AND id_custom_filter = cs.id_custom_filter);
        RETURN l_id_record;
    EXCEPTION
        WHEN no_data_found THEN
            SELECT MAX(id_record) + 1
              INTO l_id_record
              FROM custom_filter;
            RETURN l_id_record;
    END;

    /**
    * Setup the default configuration for specific custom filter and return the config_id
    *
    * @param i_id_cust_filter  ID Custom Filter - Number
    * @param i_filter_name     Filter name
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    FUNCTION get_custom_filter
    (
        i_id_cust_filter IN NUMBER,
        i_filter_name    IN VARCHAR2,
        i_rank           IN NUMBER := 0
    ) RETURN NUMBER IS
        l_id_record NUMBER;
        l_id_config NUMBER;
    BEGIN
        l_id_record := get_id_record(i_id_cust_filter, i_filter_name);
        logme('get_custom_filter', 'Step1 ID_record:' || l_id_record, 1);
        -- Get id Config
        l_id_config := get_config_id();
        -- Create Config
        pk_core_config.insert_into_config_table(i_config_table   => 'USER_CUSTOM_FILTER',
                                                i_id_record      => l_id_record,
                                                i_id_config      => l_id_config,
                                                i_flg_add_remove => 'A',
                                                i_field_01       => '-1000', -- Parent menu
                                                i_field_02       => i_id_cust_filter, -- id_custom_filter
                                                i_field_03       => 'N', -- Default
                                                i_id_inst_owner  => 0);
        logme('get_custom_filter', 'Step2 ID_record:' || l_id_record || ' , config:' || l_id_config);
        -- Set config types
        pk_filter_build.set_custom_filter_config(i_record              => l_id_record,
                                                 i_config              => l_id_config,
                                                 i_inst_owner          => 0,
                                                 i_flg_highlight       => 'N',
                                                 i_order_rank          => i_rank,
                                                 i_flg_default         => 'N',
                                                 i_id_cst_filter_next  => NULL,
                                                 i_flg_search_required => 'N',
                                                 i_flg_original        => 'Y');
    
        logme('get_custom_filter', 'Step3 ID_record:' || l_id_record || ' , config:' || l_id_config);
        --l_logstep := 0;
        RETURN l_id_config;
    END;

    /**
    * Setup the menu structure and return the respective ID
    *
    * @param i_id_cust_filter  ID Custom Filter - Number
    * @param i_id_config       Config ID (Define the market)
    * @param i_filter_name     Filter name
    * @param i_intern_menu_nm  Intern name that must be assigned to the menu
    * @param i_desc            Description of the menu
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    FUNCTION setup_menu
    (
        i_id_cust_filter IN NUMBER,
        i_id_config      IN NUMBER,
        i_filter_name    IN VARCHAR2,
        i_intern_menu_nm IN VARCHAR2,
        i_desc           IN VARCHAR2
    ) RETURN NUMBER IS
        l_id_menu    NUMBER;
        l_cust_alias VARCHAR2(250);
    BEGIN
        -- Identify id MENU
        BEGIN
            SELECT id_menu
              INTO l_id_menu
              FROM filter_menu fm
             WHERE fm.filter_name = i_filter_name
               AND fm.internal_name = i_intern_menu_nm;
        EXCEPTION
            WHEN no_data_found THEN
                SELECT MAX(id_menu) + 1
                  INTO l_id_menu
                  FROM filter_menu; -- Get higher id_menu
            WHEN too_many_rows THEN
                SELECT id_menu
                  INTO l_id_menu
                  FROM filter_menu fm
                 WHERE fm.filter_name = i_filter_name
                   AND fm.internal_name = i_intern_menu_nm
                   AND fm.id_menu = (SELECT MIN(id_menu)
                                       FROM filter_menu fm2
                                      WHERE fm2.filter_name = fm.filter_name
                                        AND fm2.internal_name = fm.internal_name);
        END;
        -- Menu Active Patient
        pk_filter_menu.ins_filter_menu(i_id_menu       => l_id_menu,
                                       i_filter_name   => i_filter_name,
                                       i_internal_name => i_intern_menu_nm);
    
        pk_filter_build.link_new_menu_2_common(i_config           => i_id_config,
                                               i_id_menu          => l_id_menu,
                                               i_id_custom_filter => i_id_cust_filter,
                                               i_order_rank       => 0,
                                               i_lov_name         => NULL);
    
        SELECT custom_filter_alias
          INTO l_cust_alias
          FROM custom_filter f
         WHERE filter_name = i_filter_name
           AND f.id_custom_filter = i_id_cust_filter;
    
        logme('SETUP_MENU', 'Must be added in the translations');
        logme('SETUP_MENU', l_id_menu || ' - Alias:' || l_cust_alias || ' , description:' || i_desc);
    
        RETURN l_id_menu;
    END;

    /**
    * Create complementar custom filter
    *
    * @param i_lang            ID Language
    * @param i_filter_name     Filter name
    * @param i_id_cflist       List with the IDs to the new custom filters
    * @param i_cflist          List with the names to the new custom filters
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    PROCEDURE create_custom_filter
    (
        i_lang        IN NUMBER,
        i_filter_name IN VARCHAR2,
        i_id_cflist   IN table_number,
        i_cflist      IN table_varchar
    ) IS
        l_id_record      NUMBER;
        l_id_config      NUMBER;
        l_cust_alias     VARCHAR2(500);
        l_id_cust_filter NUMBER;
        l_qty_found      NUMBER;
    BEGIN
        IF i_cflist.count > 0
        THEN
            FOR i IN i_cflist.first .. i_cflist.last
            LOOP
                l_id_record := get_id_record(i_id_cflist(i), i_filter_name);
                l_id_config := get_custom_filter(i_id_cflist(i), i_filter_name, i);
                logme('MAIN',
                      'Set_Custom_Filter, with id_record:' || l_id_record || ' and CustomFilter:' || i_id_cflist(i));
            
                pk_filter_build.set_custom_filter(i_filter_name        => i_filter_name,
                                                  i_id_custom_filter   => i_id_cflist(i),
                                                  i_custom_filter_name => i_cflist(i),
                                                  i_page_size          => 50,
                                                  i_id_row             => l_id_record,
                                                  o_custom_filter      => l_id_cust_filter,
                                                  o_code_custom_filter => l_cust_alias);
            
                SELECT COUNT(1)
                  INTO l_qty_found
                  FROM v_custom_filter_cfg c
                 WHERE c.filter_name = i_filter_name
                   AND c.id_custom_filter = i_id_cflist(i)
                   AND c.id_record = l_id_record;
            
                IF l_qty_found < 1
                THEN
                    logme('Create Custom Filter',
                          'custom_filter not match. for filter_name=' || i_filter_name || ' and id_custom_filter=' ||
                          i_id_cflist(i));
                    UPDATE custom_filter c
                       SET id_record = l_id_record
                     WHERE c.filter_name = i_filter_name
                       AND c.id_custom_filter = i_id_cflist(i);
                END IF;
            
                SELECT 'CUSTOM_FILTER_ALIAS.CODE_CUSTOM_FILTER_ALIAS.' || cs.custom_filter_alias
                  INTO l_cust_alias
                  FROM custom_filter cs
                 WHERE cs.filter_name = i_filter_name
                   AND cs.id_custom_filter = i_id_cflist(i);
                pk_translation.insert_into_translation(i_lang       => i_lang,
                                                       i_code_trans => l_cust_alias,
                                                       i_desc_trans => i_cflist(i));
            END LOOP;
        END IF;
    END;

    /**
    * Update the filter alias, in case a different translation be necessary
    * Usually the parse process create a custom_filter zero, with the alias ALL
    * this methos can be used to rename this alias to be translated for a diferent 
    *
    * @param i_filter_name        Filter name
    * @param i_id_custom_filter   ID Custom filter
    * @param i_new_alias          New alias to be used in the custom filter
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05/02
    */
    PROCEDURE get_new_filter_alias
    (
        i_filter_name      IN VARCHAR2,
        i_id_custom_filter IN NUMBER := 0,
        i_new_alias        IN VARCHAR2
    ) IS
        l_chk       NUMBER := 0;
        l_new_alias VARCHAR2(250);
    BEGIN
        l_new_alias := upper(i_new_alias);
        SELECT COUNT(1)
          INTO l_chk
          FROM custom_filter_alias
         WHERE custom_filter_alias = l_new_alias;
    
        IF l_chk < 1
        THEN
            INSERT INTO custom_filter_alias
                (custom_filter_alias,
                 code_custom_filter_alias,
                 create_time,
                 create_user,
                 create_institution,
                 update_time,
                 update_user,
                 update_institution)
            VALUES
                (l_new_alias,
                 'CUSTOM_FILTER_ALIAS.CODE_CUSTOM_FILTER_ALIAS.' || l_new_alias,
                 NULL,
                 NULL,
                 NULL,
                 current_timestamp,
                 'ALERT',
                 NULL);
        END IF;
    
        UPDATE custom_filter
           SET custom_filter_alias = l_new_alias
         WHERE filter_name = i_filter_name
           AND id_custom_filter = i_id_custom_filter;
    
        /*        pk_filter_build.set_custom_filter_alias(i_filter_name         => i_filter_name,
                                                        i_id_custom_filter    => i_id_custom_filter,
                                                        i_custom_filter_alias => l_new_alias,
                                                        i_code_alias          => NULL);
        */
    END;

    PROCEDURE unassign_filter(i_filter_name IN VARCHAR2) IS
        CURSOR cff IS
            SELECT id_custom_filter, id_filter_field
              FROM custom_filter_field ff
             WHERE ff.filter_name = i_filter_name;
    BEGIN
        FOR i IN cff
        LOOP
            pk_filter_build.del_cust_filter_field(i_filter_name   => i_filter_name,
                                                  i_custom_filter => i.id_custom_filter,
                                                  i_filter_field  => table_number(i.id_filter_field));
        END LOOP i;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    PROCEDURE sequence_menus
    (
        i_filter_name        IN VARCHAR2,
        i_custom_filter_list IN table_number
    ) IS
        l_seq         NUMBER := 0;
        l_id_record   custom_filter.id_record%TYPE;
        l_rec_cfg_tbl config_table%ROWTYPE;
    BEGIN
    
        FOR seqs IN (SELECT column_value id_custom_filter
                       FROM TABLE(i_custom_filter_list))
        LOOP
            --
            SELECT id_record
              INTO l_id_record
              FROM v_filter_menu_cfg c
             WHERE c.filter_name = i_filter_name
               AND c.id_custom_filter = seqs.id_custom_filter
               AND rownum = 1;
            --
            SELECT *
              INTO l_rec_cfg_tbl
              FROM config_table cf
             WHERE cf.id_record = l_id_record
               AND cf.config_table = 'FILTER_MENU';
            --
            pk_filter_menu.ins_filter_menu_cfg(i_config           => l_rec_cfg_tbl.id_config,
                                               i_id_menu          => l_rec_cfg_tbl.id_record,
                                               i_id_menu_prt      => l_rec_cfg_tbl.field_01,
                                               i_id_custom_filter => l_rec_cfg_tbl.field_02,
                                               i_order_rank       => l_seq,
                                               i_lov_name         => l_rec_cfg_tbl.field_04);
        
            logme('sequence_menus',
                  'seqs.id_custom_filter:' || seqs.id_custom_filter || ' - ' || to_char(l_id_record),
                  0);
        
            --
            l_seq := l_seq + 10;
        END LOOP;
    END;

BEGIN
    -- Initialization
    g_owner   := 'ALERT';
    g_package := 'pk_gridfilter';

    g_software_intern_name     := 'ORIS';
    g_epis_flg_status_active   := 'A';
    g_epis_flg_status_inactive := 'I';
    g_epis_flg_status_temp     := 'T';
    g_epis_flg_status_canceled := 'C';
    g_active                   := 'A';

    -- Log initialization.
    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(g_package);
END pk_gridfilter;
/
