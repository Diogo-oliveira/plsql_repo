/*-- Last Change Revision: $Rev: 2027395 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:05 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_on_call_physician IS

    /**********************************************************************************************
    * Returns the ID's of the professionals that are currently on-call.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param o_id_profs           Array with the ID's of the professionals that are on-call
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           2.5.0.7
    * @since             2009/10/27
    **********************************************************************************************/
    FUNCTION get_on_call_physician_id_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_id_profs OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(200) := 'GET_ON_CALL_PHYSICIAN_ID_LIST';
        l_default_period sys_config.value%TYPE;
        l_sysdate        TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'GET ON-CALL PROFESSIONALS';
        pk_alertlog.log_debug(g_error);
        SELECT id_professional
          BULK COLLECT
          INTO o_id_profs
          FROM (SELECT ocp.id_professional
                  FROM on_call_physician ocp
                 WHERE ocp.flg_status = pk_alert_constant.g_on_call_active
                   AND ocp.id_institution = i_prof.institution
                   AND l_sysdate BETWEEN ocp.dt_start AND ocp.dt_end);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_on_call_physician_id_list;

    /**********************************************************************************************
    * Returns the start and end dates of the current on-call period, as well as the 
    * length of the period (number of days).
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param o_default_period     Length of the period (number of days)
    * @param o_start_date         Start date of the period
    * @param o_end_date           End date of the period
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/04/02
    **********************************************************************************************/
    FUNCTION get_on_call_period_dates
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_default_period OUT sys_config.value%TYPE,
        o_start_date     OUT TIMESTAMP WITH TIME ZONE,
        o_end_date       OUT TIMESTAMP WITH TIME ZONE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_invalid_config EXCEPTION;
    BEGIN
        -- Get default period of days to show on the list
        g_error := 'GET CONFIGURATIONS';
        pk_alertlog.log_debug(g_error);
        o_default_period := pk_sysconfig.get_config('ON_CALL_DEFAULT_PERIOD', i_prof);
    
        IF o_default_period IS NULL
           OR o_default_period <= 0 -- Default period must be set to at least one day (val = 1). 
        THEN
            RAISE l_invalid_config;
        END IF;
    
        -- Get start and end dates of the period
        g_error := 'CONFIGURE DATES';
        pk_alertlog.log_debug(g_error);
        o_start_date := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL); -- Today
        o_end_date   := pk_date_utils.add_days_to_tstz(o_start_date, o_default_period); -- Today + Number of days defined in SYS_CONFIG   
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_invalid_config THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_CONFIG_ERROR',
                                              '''ON_CALL_DEFAULT_PERIOD'' UNDEFINED OR INVALID',
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_ON_CALL_PERIOD_DATES',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_ON_CALL_PERIOD_DATES',
                                              o_error);
            RETURN FALSE;
    END get_on_call_period_dates;

    /**********************************************************************************************
    * Returns the list of on-call physicians.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param o_period_title       Text with the start and end dates of the period
    * @param o_list               List of on-call physicians
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/02
    **********************************************************************************************/
    FUNCTION get_on_call_physician_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_period_title OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error EXCEPTION;
    
        -- Dates used to display in ALERT®
        l_dt_start TIMESTAMP WITH TIME ZONE;
        l_dt_end   TIMESTAMP WITH TIME ZONE;
        -- Dates used for operations in the database
        l_dt_start_local TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_local   TIMESTAMP WITH LOCAL TIME ZONE;
        l_default_period sys_config.value%TYPE;
        l_period_desc    sys_domain.desc_val%TYPE;
    
    BEGIN
    
        g_error := 'GET ON-CALL PERIOD DATES';
        pk_alertlog.log_debug(g_error);
        IF NOT get_on_call_period_dates(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        o_default_period => l_default_period, -- Length of the period (number of days)
                                        o_start_date     => l_dt_start, -- On-call period start date
                                        o_end_date       => l_dt_end, -- On-call period end date
                                        o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        l_dt_start_local := l_dt_start;
        l_dt_end_local   := l_dt_end;
    
        -- Return the title with the period we're showing in the list.
        -- Dates are shown in the format DAY-MONTH-YEAR (e.g. 01-Apr-2009)
        IF l_default_period = 1
        THEN
            -- Send only the start date (today)
            g_error := 'CONFIGURE TITLE (1)';
            pk_alertlog.log_debug(g_error);
            o_period_title := pk_date_utils.dt_chr(i_lang, l_dt_start, i_prof.institution, i_prof.software);
        
        ELSE
            -- Send the start and end dates in the format: <START_DATE> - <END_DATE>
            -- Subtract -1 to the end date to display the correct period. For example, if the default period is 2 days,
            -- the end date would be '03-Apr-2009' instead of '02-Apr-2009'.
            g_error := 'CONFIGURE TITLE (2)';
            pk_alertlog.log_debug(g_error);
            o_period_title := pk_date_utils.dt_chr(i_lang, l_dt_start, i_prof.institution, i_prof.software) || ' - ' ||
                              pk_date_utils.dt_chr(i_lang,
                                                   pk_date_utils.add_days_to_tstz(l_dt_end, -1),
                                                   i_prof.institution,
                                                   i_prof.software);
        END IF;
    
        -- Get description for current period
        g_error := 'GET CONFIGURATIONS';
        pk_alertlog.log_debug(g_error);
        l_period_desc := pk_sysdomain.get_domain(i_code_dom => 'ON_CALL_PHYSICIAN_PERIOD_STATUS',
                                                 i_val      => pk_alert_constant.g_oncallperiod_status_c,
                                                 i_lang     => i_lang);
    
        g_error := 'GET LIST';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT ocp.id_on_call_physician,
                   ocp.id_professional,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)
                      FROM dual) name,
                   s.id_speciality,
                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                      FROM dual) desc_spec,
                   decode(ocp.notes, NULL, NULL, '(' || pk_message.get_message(i_lang, i_prof, 'COMMON_M008') || ')') title_notes,
                   pk_date_utils.date_send_tsz(i_lang, ocp.dt_start, i_prof) dt_start,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, ocp.dt_start, i_prof) dt_start_extend,
                   pk_date_utils.date_send_tsz(i_lang, ocp.dt_end, i_prof) dt_end,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, ocp.dt_end, i_prof) dt_end_extend,
                   pk_alert_constant.g_oncallperiod_status_c period_status, -- Current period ONLY
                   l_period_desc period_status_desc
              FROM on_call_physician ocp, professional p, speciality s
             WHERE ocp.id_professional = p.id_professional
               AND p.id_speciality = s.id_speciality
               AND ocp.flg_status = pk_alert_constant.g_on_call_active
               AND ocp.id_institution = i_prof.institution
                  -- Return on-call physicians that START or STARTED the on-call shift within the current period.
                  -- It doesn't matter when the shift ends, so we only compare the START date.
               AND ocp.dt_start >= l_dt_start_local
               AND ocp.dt_start < l_dt_end_local
            --
            UNION ALL
            SELECT ocp.id_on_call_physician,
                   ocp.id_professional,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)
                      FROM dual) name,
                   s.id_speciality,
                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                      FROM dual) desc_spec,
                   decode(ocp.notes, NULL, NULL, '(' || pk_message.get_message(i_lang, i_prof, 'COMMON_M008') || ')') title_notes,
                   pk_date_utils.date_send_tsz(i_lang, ocp.dt_start, i_prof) dt_start,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, ocp.dt_start, i_prof) dt_start_extend,
                   pk_date_utils.date_send_tsz(i_lang, ocp.dt_end, i_prof) dt_end,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, ocp.dt_end, i_prof) dt_end_extend,
                   pk_alert_constant.g_oncallperiod_status_c period_status, -- Current period ONLY
                   l_period_desc period_status_desc
              FROM on_call_physician ocp, professional p, speciality s
             WHERE ocp.id_professional = p.id_professional
               AND p.id_speciality = s.id_speciality
               AND ocp.flg_status = pk_alert_constant.g_on_call_active
               AND ocp.id_institution = i_prof.institution
                  -- Return on-call physicians that FINISH or FINISHED the on-call shift within the current period,
                  -- but started the shift before the beginning of the current period
               AND ocp.dt_end > l_dt_start_local
               AND ocp.dt_start < l_dt_start_local
            --
             ORDER BY dt_start, name DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_ON_CALL_PHYSICIAN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_ON_CALL_PHYSICIAN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_on_call_physician_list;

    /**********************************************************************************************
    * Get on-call physician detail
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_on_call         On-call physician - Record ID
    * @param o_detail             Detailed information about the on-call physician
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/02
    **********************************************************************************************/
    FUNCTION get_on_call_physician_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_on_call IN on_call_physician.id_on_call_physician%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET DETAIL';
        pk_alertlog.log_debug(g_error);
        OPEN o_detail FOR
            SELECT ocp.id_on_call_physician,
                   -- On-call physician info --
                   ocp.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name,
                   p.first_name,
                   p.last_name,
                   s.id_speciality,
                   pk_translation.get_translation(i_lang, s.code_speciality) desc_spec,
                   --
                   p.address,
                   p.city,
                   p.district,
                   p.zip_code,
                   p.id_country,
                   (SELECT pk_translation.get_translation(i_lang, c.code_country)
                      FROM country c
                     WHERE c.id_country = p.id_country) country,
                   --
                   p.work_phone,
                   p.fax,
                   p.email,
                   p.cell_phone,
                   --
                   pk_date_utils.date_send_tsz(i_lang, ocp.dt_start, i_prof) dt_start,
                   pk_date_utils.date_char_tsz(i_lang, ocp.dt_start, i_prof.institution, i_prof.software) dt_start_extend,
                   pk_date_utils.date_send_tsz(i_lang, ocp.dt_end, i_prof) dt_end,
                   pk_date_utils.date_char_tsz(i_lang, ocp.dt_end, i_prof.institution, i_prof.software) dt_end_extend,
                   -- Period dates detailed
                   pk_date_utils.date_char_hour_tsz(i_lang, ocp.dt_start, i_prof.institution, i_prof.software) start_hour,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, ocp.dt_start, i_prof.institution, i_prof.software) start_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, ocp.dt_end, i_prof.institution, i_prof.software) end_hour,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, ocp.dt_end, i_prof.institution, i_prof.software) end_date,
                   -- On-call notes --
                   ocp.notes,
                   -- Information about creation of this record --
                   pk_date_utils.date_send_tsz(i_lang, ocp.dt_creation, i_prof) dt_create,
                   pk_date_utils.date_char_tsz(i_lang, ocp.dt_creation, i_prof.institution, i_prof.software) dt_create_extend,
                   ocp.id_prof_create,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) name_create
              FROM on_call_physician ocp, professional p, professional p1, speciality s
             WHERE ocp.id_professional = p.id_professional
               AND ocp.id_prof_create = p1.id_professional
               AND p.id_speciality = s.id_speciality
               AND ocp.id_on_call_physician = i_id_on_call;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_ON_CALL_PHYSICIAN_DET',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_on_call_physician_det;

    /**********************************************************************************************
    * Cancel on-call physician records.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_on_call         Array of selected record ID's (on-call physician ID's)
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/02
    **********************************************************************************************/
    FUNCTION cancel_on_call_physician
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_on_call IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_invalid_param EXCEPTION;
        l_rowids table_varchar := table_varchar();
    BEGIN
        IF i_id_on_call.count > 0
        THEN
        
            FOR i IN i_id_on_call.first .. i_id_on_call.last
            LOOP
                -- Update to the new state
                g_error := 'SET ON-CALL PHYSICIAN STATUS - ' || i;
                pk_alertlog.log_debug(g_error);
                ts_on_call_physician.upd(id_on_call_physician_in => i_id_on_call(i),
                                         flg_status_in           => pk_alert_constant.g_on_call_cancelled,
                                         id_prof_cancel_in       => i_prof.id,
                                         dt_cancel_in            => current_timestamp,
                                         rows_out                => l_rowids);
            END LOOP;
        
            g_error := 'PROCESS UPDATE - ON_CALL_PHYSICIAN';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ON_CALL_PHYSICIAN',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
            RAISE l_invalid_param;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_invalid_param THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_PARAM_ERROR',
                                              'INVALID ARRAY',
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'CANCEL_ON_CALL_PHYSICIAN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'CANCEL_ON_CALL_PHYSICIAN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_on_call_physician;

    /**********************************************************************************************
    * Set on-call physician data. Used for multiple creation of on-call periods.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_prof            On-call physician - Professional ID
    * @param i_dt_start           Array of start dates of on-call shift
    * @param i_dt_end             Array of end dates of on-call shift
    * @param i_notes              Array of notes
    * @param o_flg_show           (Y) Show error message and stay on the current screen
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/30
    **********************************************************************************************/
    FUNCTION set_on_call_physician
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_prof  IN professional.id_professional%TYPE,
        i_dt_start IN table_varchar,
        i_dt_end   IN table_varchar,
        i_notes    IN table_varchar,
        o_flg_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_args_error     EXCEPTION;
    BEGIN
    
        -- Validate arguments: arrays of data must have the same size
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
        IF (i_dt_start.count <> i_dt_end.count)
           OR (i_dt_start.count <> i_notes.count)
        THEN
            RAISE l_args_error;
        END IF;
    
        -- Create on-call periods for the professional in 'i_id_prof'
        FOR i IN i_dt_start.first .. i_dt_start.last
        LOOP
        
            g_error := 'CALL TO SET_ON_CALL_PHYSICIAN - ' || i;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_on_call_physician.set_on_call_physician(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_id_on_call => NULL,
                                                              i_id_prof    => i_id_prof,
                                                              i_dt_start   => i_dt_start(i),
                                                              i_dt_end     => i_dt_end(i),
                                                              i_notes      => i_notes(i),
                                                              i_flg_action => 'N', -- New
                                                              i_commit     => 'N',
                                                              o_flg_show   => o_flg_show,
                                                              o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_args_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_PARAM_ERROR',
                                              'INVALID_ARRAY_SIZE',
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_ON_CALL_PHYSICIAN',
                                              o_error);
            o_flg_show := pk_alert_constant.g_yes;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN l_internal_error THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   o_error.ora_sqlcode,
                                   o_error.ora_sqlerrm,
                                   g_error,
                                   g_owner,
                                   g_package_name,
                                   'SET_ON_CALL_PHYSICIAN',
                                   o_error.err_action,
                                   'U');
            
                l_ret      := pk_alert_exceptions.process_error(l_error_in, o_error);
                o_flg_show := pk_alert_constant.g_yes;
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_ON_CALL_PHYSICIAN',
                                              o_error);
            o_flg_show := pk_alert_constant.g_yes;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_on_call_physician;

    /**********************************************************************************************
    * Set on-call physician data
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_on_call         On-call physician - Record ID
    * @param i_id_prof            On-call physician - Professional ID
    * @param i_dt_start           Start date of on-call shift
    * @param i_dt_end             End date of on-call shift
    * @param i_notes              Notes
    * @param i_flg_action         (N) New (E) Edit
    * @param i_commit             Commit transaction? (Y) Yes, default; (N) No
    * @param o_flg_show           (Y) Show error message and stay on the current screen
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/02/25
    **********************************************************************************************/
    FUNCTION set_on_call_physician
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_on_call IN on_call_physician.id_on_call_physician%TYPE,
        i_id_prof    IN professional.id_professional%TYPE,
        i_dt_start   IN VARCHAR2,
        i_dt_end     IN VARCHAR2,
        i_notes      IN VARCHAR2,
        i_flg_action IN VARCHAR2,
        i_commit     IN VARCHAR2 DEFAULT 'Y',
        o_flg_show   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_new  VARCHAR2(1) := 'N';
        l_edit VARCHAR2(1) := 'E';
    
        l_invalid_action EXCEPTION;
        l_invalid_dates  EXCEPTION;
        l_overlap_dates  EXCEPTION;
    
        l_sysdate  TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_start on_call_physician.dt_start%TYPE;
        l_dt_end   on_call_physician.dt_end%TYPE;
    
        l_do_commit BOOLEAN;
    
        l_overlap NUMBER(6);
    
        l_rowids table_varchar := table_varchar();
    
        CURSOR c_overlap IS
            SELECT COUNT(*)
              FROM on_call_physician ocp
             WHERE ocp.id_professional = i_id_prof
               AND -- 1) New start date between an existing period
                   ((ocp.dt_start <= l_dt_start AND ocp.dt_end > l_dt_start) OR
                   -- 2) New end date between an existing period
                   (ocp.dt_start < l_dt_end AND ocp.dt_end >= l_dt_end) OR
                   -- 3) New start and end dates between an existing period
                   (ocp.dt_start > l_dt_start AND ocp.dt_end < l_dt_end))
               AND ocp.flg_status = pk_alert_constant.g_on_call_active
               AND ocp.id_institution = i_prof.institution
               AND ((ocp.id_on_call_physician <> i_id_on_call AND i_flg_action = l_edit) OR (i_flg_action = l_new));
    
    BEGIN
    
        g_error := 'CONFIGURE DATES';
        pk_alertlog.log_debug(g_error);
        l_sysdate  := current_timestamp;
        l_dt_start := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
    
        -- Commit transaction only in EDIT mode, since we're updating a single database record.
        g_error := 'CONFIGURE COMMIT TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_do_commit := CASE i_commit
                           WHEN pk_alert_constant.g_yes THEN
                            TRUE
                           ELSE
                            FALSE
                       END;
    
        -- Dates MUST be specified / Start date cannot be after the end date
        IF l_dt_start IS NULL
           OR l_dt_end IS NULL
           OR l_dt_start >= l_dt_end
        THEN
            RAISE l_invalid_dates;
        END IF;
    
        -- Check if the selected period overlaps an existing one
        g_error := 'CHECK DATES OVERLAP';
        pk_alertlog.log_debug(g_error);
        OPEN c_overlap;
        FETCH c_overlap
            INTO l_overlap;
        CLOSE c_overlap;
    
        IF l_overlap > 0
        THEN
            -- Raise exception of overlapping dates, if found
            RAISE l_overlap_dates;
        END IF;
    
        IF i_flg_action = l_new -- New on-call physician
        THEN
            g_error := 'INSERT ON_CALL_PHYSICIAN';
            pk_alertlog.log_debug(g_error);
            ts_on_call_physician.ins(id_on_call_physician_in => ts_on_call_physician.next_key(),
                                     id_professional_in      => i_id_prof,
                                     dt_start_in             => l_dt_start,
                                     dt_end_in               => l_dt_end,
                                     flg_status_in           => pk_alert_constant.g_on_call_active,
                                     notes_in                => i_notes,
                                     id_prof_create_in       => i_prof.id,
                                     dt_creation_in          => l_sysdate,
                                     id_institution_in       => i_prof.institution,
                                     rows_out                => l_rowids);
        
            g_error := 'PROCESS INSERT ON_CALL_PHYSICIAN';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ON_CALL_PHYSICIAN',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSIF i_flg_action = l_edit -- Edit on-call physician
        THEN
        
            IF i_id_on_call IS NULL
            THEN
                -- On-call ID must be specified
                g_error := 'ID_ON_CALL_PHYSICIAN NOT SPECIFIED';
                pk_alertlog.log_debug(g_error);
                RAISE l_invalid_action;
            END IF;
        
            g_error := 'UPDATE ON_CALL_PHYSICIAN';
            pk_alertlog.log_debug(g_error);
            ts_on_call_physician.upd(id_on_call_physician_in => i_id_on_call,
                                     dt_start_in             => l_dt_start,
                                     dt_end_in               => l_dt_end,
                                     notes_in                => i_notes,
                                     notes_nin               => FALSE,
                                     rows_out                => l_rowids);
        
            g_error := 'PROCESS UPDATE ON_CALL_PHYSICIAN';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ON_CALL_PHYSICIAN',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
            -- Not supposed to happen, so we must caught the exception
            g_error := 'INVALID OR NOT SPECIFIED ACTION';
            pk_alertlog.log_debug(g_error);
            RAISE l_invalid_action;
        END IF;
    
        IF l_do_commit
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_invalid_dates THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
                -- Specified dates are not valid
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'ONCALLPHYSICIAN_M001');
            BEGIN
                l_error_message := l_error_message || chr(10) || chr(10) ||
                                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, l_dt_start, i_prof) || ' - ' ||
                                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, l_dt_end, i_prof);
            
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   g_owner,
                                   g_package_name,
                                   'SET_ON_CALL_PHYSICIAN',
                                   NULL,
                                   'U');
            
                l_ret      := pk_alert_exceptions.process_error(l_error_in, o_error);
                o_flg_show := pk_alert_constant.g_yes;
                pk_utils.undo_changes; -- ROLLBACK
                IF l_do_commit
                THEN
                    pk_alert_exceptions.reset_error_state();
                END IF;
                RETURN FALSE;
            END;
        
        WHEN l_overlap_dates THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
                -- The specified time frame overlaps an existing one for the selected professional
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'ONCALLPHYSICIAN_M002');
            BEGIN
                l_error_message := l_error_message || chr(10) || chr(10) ||
                                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, l_dt_start, i_prof) || ' - ' ||
                                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, l_dt_end, i_prof);
            
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   g_owner,
                                   g_package_name,
                                   'SET_ON_CALL_PHYSICIAN',
                                   NULL,
                                   'U');
            
                l_ret      := pk_alert_exceptions.process_error(l_error_in, o_error);
                o_flg_show := pk_alert_constant.g_yes;
                pk_utils.undo_changes; -- ROLLBACK
                IF l_do_commit
                THEN
                    pk_alert_exceptions.reset_error_state();
                END IF;
                RETURN FALSE;
            END;
        
        WHEN l_invalid_action THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_PARAM_ERROR',
                                              'INVALID ACTION',
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_ON_CALL_PHYSICIAN',
                                              o_error);
            o_flg_show := pk_alert_constant.g_yes;
            pk_utils.undo_changes; -- ROLLBACK
            IF l_do_commit
            THEN
                pk_alert_exceptions.reset_error_state();
            END IF;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_ON_CALL_PHYSICIAN',
                                              o_error);
            o_flg_show := pk_alert_constant.g_yes;
            pk_utils.undo_changes; -- ROLLBACK
            IF l_do_commit
            THEN
                pk_alert_exceptions.reset_error_state();
            END IF;
            RETURN FALSE;
    END set_on_call_physician;

    /**********************************************************************************************
    * Returns the list of available specialities in the current institution.
    * NOTE: code based on PK_LIST.GET_SPEC_LIST.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param o_list               Speciality list
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/02
    **********************************************************************************************/
    FUNCTION get_speciality_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
        --
        -- NOTE: If you edit this query, please check the query in CRITERIA.CRIT_MCHOICE_SELECT 
        --       with ID_CRITERIA = 147. It may need to be edited too.
        --
            SELECT s.id_speciality data, pk_translation.get_translation(i_lang, s.code_speciality) label
              FROM speciality s
             WHERE s.flg_available = 'Y'
                  -- Only specialities available in physicians of the current institution
               AND s.id_speciality IN (SELECT p.id_speciality
                                         FROM professional p, prof_institution pi
                                        WHERE p.id_speciality = s.id_speciality
                                          AND p.id_professional = pi.id_professional
                                          AND pi.id_institution = i_prof.institution
                                          AND pi.flg_state = 'A'
                                          AND pi.dt_end_tstz IS NULL)
             ORDER BY label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_SPECIALITY_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_speciality_list;

    /**********************************************************************************************
    * Returns the list of professionals (physicians) for a given speciality.
    * Code optimized for Flash layer.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_spec               Speciality ID
    * @param o_list               List of professionals
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/02
    **********************************************************************************************/
    FUNCTION get_speciality_prof
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_spec  IN speciality.id_speciality%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT p.id_professional data, pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label
              FROM prof_cat pc, professional p, category c, prof_institution pi
             WHERE pc.id_professional = p.id_professional
               AND pc.id_category = c.id_category
               AND pc.id_institution = i_prof.institution
               AND c.flg_type = pk_alert_constant.g_cat_type_doc
               AND p.id_speciality = i_spec
               AND p.flg_state = 'A'
               AND pi.id_professional = p.id_professional
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state = 'A'
               AND pi.dt_end_tstz IS NULL
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
             ORDER BY p.nick_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_SPECIALITY_PROF',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_speciality_prof;

    /**********************************************************************************************
    * Returns the information related to a professional,
    * when creating a new on-call physician record.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_professional    Professional ID
    * @param o_prof_attr          Professional information
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/19
    **********************************************************************************************/
    FUNCTION get_professional_attributes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        o_prof_attr       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET PROFESSIONAL INFO';
        pk_alertlog.log_debug(g_error);
        OPEN o_prof_attr FOR
            SELECT p.id_professional,
                   p.name,
                   p.title,
                   p.nick_name,
                   p.address,
                   p.city,
                   p.district,
                   p.zip_code,
                   (SELECT pk_translation.get_translation(i_lang, c.code_country)
                      FROM country c
                     WHERE c.id_country = p.id_country) country,
                   p.id_country,
                   p.work_phone,
                   p.num_contact,
                   p.cell_phone,
                   p.fax,
                   p.email
              FROM professional p
             WHERE p.id_professional = i_id_professional;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_PROFESSIONAL_ATTRIBUTES',
                                              o_error);
            pk_types.open_my_cursor(o_prof_attr);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_professional_attributes;

BEGIN
    -- Log initialization
    g_owner        := 'ALERT';
    g_package_name := pk_alertlog.who_am_i;

    pk_alertlog.who_am_i(g_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_on_call_physician;
/
