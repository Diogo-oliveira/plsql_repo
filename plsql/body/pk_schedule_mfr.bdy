/*-- Last Change Revision: $Rev: 2027684 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_schedule_mfr IS
    -- This package provides the MFR scheduling logic for ALERT Scheduler.
    -- @author  varios
    -- @version 2.4.4

    ------------------------------ PRIVATE FUNCTIONS ---------------------------

    /********************************************************************************************
    * This function returns a value from 1 to 7 identifying the day of the week, where
    * Monday is 1 and Sunday is 7.
    * Note: In Oracle, depending on the NLS_Territory setting, different days of the week are 1.
    * Examples:
    *   U.S., Canada, Monday = 2;  Most European countries, Monday = 1;
    *   Most Middle-Eastern countries, Monday = 3.
    *   For Bangladesh, Monday = 4.
    *
    * @param i_date          Input date parameter
    *
    * @return                Return the day of the week
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    ********************************************************************************************/
    FUNCTION week_day_standard(i_date IN DATE) RETURN NUMBER IS
    BEGIN
        RETURN 1 + MOD(to_number(to_char(i_date, 'J')), 7);
    END week_day_standard;

    /*********************************************************************************************
    * Split varchar into mutiple tokens
    * 
    * @param i_string  the input varchar
    * @param i_delim   delimiter
    *
    * @return a table_number which can be used in pl/sql scope
    *
    * @author Jose Antunes
    * @date   2009/01/07
    * @since  2.4.3
    ********************************************************************************************/
    FUNCTION get_table_numbers
    (
        i_string IN VARCHAR2,
        i_delim  IN VARCHAR2
    ) RETURN table_number IS
        l_string       VARCHAR2(4000);
        l_table_idx    INTEGER;
        l_string_len   INTEGER;
        l_split_idx    INTEGER;
        l_ret          table_number := table_number();
        l_number       VARCHAR2(4000);
        l_num_elements INTEGER;
    BEGIN
    
        l_string       := i_string;
        l_string_len   := length(l_string);
        l_num_elements := l_string_len / 2;
    
        l_table_idx := 1;
        l_split_idx := 1;
        WHILE l_table_idx <= l_num_elements
        LOOP
            l_number    := substr(l_string, l_split_idx, 1);
            l_split_idx := l_split_idx + 2;
            l_ret.extend;
            l_ret(l_table_idx) := to_number(l_number);
            l_table_idx := l_table_idx + 1;
        END LOOP;
        RETURN l_ret;
    END get_table_numbers;

    /*
    * returns value of base clinical service
    *
    * @param i_prof               Professional.
    * @param o_exists             True if available, false otherwise.
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.4
    * @date     21-11-2008
    */
    FUNCTION get_base_clin_serv(i_prof IN profissional) RETURN NUMBER IS
        l_cs clinical_service.id_clinical_service%TYPE;
    BEGIN
        SELECT pk_sysconfig.get_config(g_mfr_clin_serv, i_prof)
          INTO l_cs
          FROM dual;
        RETURN l_cs;
    END get_base_clin_serv;

    /*
    * Get the descriptions of a set of days
    *
    * @param   i_lang              Language identifier.
    * @param   i_prof              Professional.
    * @param   i_dates             Dates to get the description
    * @param   o_weekdays          Description of the weekday for each date in i_dates
    * @param   o_error             Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Jose Antunes
    * @version 2.4.4
    * @since 2008/12/18
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_weekdays_description
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dates    IN table_varchar,
        o_weekdays OUT table_varchar,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'GET_WEEKDAYS_DESCRIPTION';
        l_weekday    NUMBER(1);
        l_dates_tstz table_timestamp_tz;
    BEGIN
    
        o_weekdays := table_varchar();
    
        g_error := 'FILL i_dates';
        IF (i_dates.count > 0)
        THEN
            FOR i IN i_dates.first .. i_dates.last
            LOOP
                o_weekdays.extend;
                l_weekday := week_day_standard(to_date(i_dates(i), 'yyyymmddhh24miss'));
            
                IF l_weekday = 1
                THEN
                    o_weekdays(i) := pk_message.get_message(i_lang, g_msg_seg);
                ELSIF l_weekday = 2
                THEN
                    o_weekdays(i) := pk_message.get_message(i_lang, g_msg_ter);
                ELSIF l_weekday = 3
                THEN
                    o_weekdays(i) := pk_message.get_message(i_lang, g_msg_qua);
                ELSIF l_weekday = 4
                THEN
                    o_weekdays(i) := pk_message.get_message(i_lang, g_msg_qui);
                ELSIF l_weekday = 5
                THEN
                    o_weekdays(i) := pk_message.get_message(i_lang, g_msg_sex);
                ELSIF l_weekday = 6
                THEN
                    o_weekdays(i) := pk_message.get_message(i_lang, g_msg_sab);
                ELSIF l_weekday = 7
                THEN
                    o_weekdays(i) := pk_message.get_message(i_lang, g_msg_dom);
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_weekdays_description;

    /*
    * Returns the list of vacancies and schedules that match each one of the criteria sets,
    * and that refer to days that match all the criteria sets.
    * Adapted from the homonymous function in pk_schedule_common
    * 
    * @param i_lang          Language identifier.
    * @param i_prof          Professional
    * @param i_id_patient    Patient (or NULL for all patients)
    * @param i_args          UI search criteria matrix
    * @param i_wizmode       Y = wizard mode
    * @param o_vacancies     List of vacancies
    * @param o_schedules     List of schedules
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author  Telmo
    * @version 2.4.4
    * @date    13-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_vac_and_sch_mult
    (
        i_lang       IN language.id_language%TYPE DEFAULT NULL,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_args       IN table_table_varchar,
        i_wizmode    IN VARCHAR2,
        o_vacancies  OUT table_number,
        o_schedules  OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'GET_VAC_AND_SCH_MULT';
        l_inter_dates     table_timestamp_tz := table_timestamp_tz();
        l_union_schedules table_number := table_number();
        l_union_vacancies table_number := table_number();
        l_schedules       table_number := table_number();
        l_vacancies       table_number := table_number();
        l_dates           table_timestamp_tz := table_timestamp_tz();
        l_args            table_varchar;
        i                 INTEGER;
    BEGIN
        g_error := 'ITERATE THROUGH CRITERIA';
        IF i_args IS NOT NULL
           AND i_args.count > 0
        THEN
            FOR idx IN i_args.first .. i_args.last
            LOOP
                -- Stop looking for vacancies and schedules once the list of common dates is empty (after the first iteration).
                EXIT WHEN l_inter_dates.count = 0 AND idx > 1;
            
                g_error := 'CALL GET_VACANCIES';
                -- Get the list of vacancies that match the current criteria set
                l_args := table_varchar();
                l_args.extend(i_args(idx).count);
                i := i_args(idx).first;
                WHILE i IS NOT NULL
                LOOP
                    l_args(i) := i_args(idx) (i);
                    i := i_args(idx).next(i);
                END LOOP;
            
                IF NOT get_vacancies(i_lang    => i_lang,
                                     i_prof    => i_prof,
                                     i_args    => l_args, --i_args(idx),
                                     i_wizmode => i_wizmode,
                                     o_error   => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'TRANSFORM OUTPUT OF GET_VACANCIES INTO TABLE_NUMBER';
                SELECT id_sch_consult_vacancy
                  BULK COLLECT
                  INTO l_vacancies
                  FROM sch_tmptab_vacs_mfr;
            
                g_error := 'CALL GET_SCHEDULES';
                -- Get the list of schedules that match the current criteria set
                IF NOT get_schedules(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_id_patient => i_id_patient,
                                     i_args       => l_args, --i_args(idx),
                                     i_wizmode    => i_wizmode,
                                     o_schedules  => l_schedules,
                                     o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'UNITE VACANCIES AND SCHEDULES';
                -- Unite all the vacancies and schedules found so far.
                -- Each one is valid for at least one criteria set.
                l_union_vacancies := l_union_vacancies MULTISET UNION DISTINCT l_vacancies;
                l_union_schedules := l_union_schedules MULTISET UNION DISTINCT l_schedules;
            
                g_error := 'GET DAYS FOR VACANCIES AND SCHEDULES';
                -- Get the list of days for the current vacancies and/or schedules
                SELECT dt_begin
                  BULK COLLECT
                  INTO l_dates
                  FROM (SELECT dt_begin_trunc dt_begin
                          FROM sch_tmptab_vacs_mfr
                        UNION
                        SELECT pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz) dt_begin
                          FROM schedule s
                         WHERE s.id_schedule IN (SELECT *
                                                   FROM TABLE(l_schedules)));
            
                g_error := 'INTERSECT DAYS';
                IF idx = 1
                THEN
                    l_inter_dates := l_dates;
                ELSE
                    -- Intersect all the days found so far  
                    -- Multiset does not work with tables of timestamps with time zone.
                    IF NOT pk_schedule_common.get_intersect_table_tz(i_lang,
                                                                     i_prof,
                                                                     l_inter_dates,
                                                                     l_dates,
                                                                     l_inter_dates,
                                                                     o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END LOOP;
        
            g_error := 'CHECK DAYS COUNT';
            IF (l_inter_dates IS NOT NULL AND l_inter_dates.count > 0)
            THEN
                -- Get vacancies and schedules for the valid dates only
                g_error := 'GET VACANCIES';
                SELECT scv.id_sch_consult_vacancy
                  BULK COLLECT
                  INTO o_vacancies
                  FROM sch_consult_vacancy scv,
                       (SELECT *
                          FROM TABLE(l_inter_dates)) dates
                 WHERE scv.id_sch_consult_vacancy IN (SELECT *
                                                        FROM TABLE(l_union_vacancies))
                   AND scv.dt_begin_tstz >= dates.column_value
                   AND scv.dt_begin_tstz < pk_date_utils.add_days_to_tstz(dates.column_value, 1);
            
                g_error := 'GET SCHEDULES';
                SELECT s.id_schedule
                  BULK COLLECT
                  INTO o_schedules
                  FROM schedule s,
                       (SELECT *
                          FROM TABLE(l_inter_dates)) dates
                 WHERE s.id_schedule IN (SELECT *
                                           FROM TABLE(l_union_schedules))
                   AND s.dt_begin_tstz >= dates.column_value
                   AND s.dt_begin_tstz < pk_date_utils.add_days_to_tstz(dates.column_value, 1);
            
            ELSE
                -- No days were found with vacancies or schedules for all the criteria sets.
                o_schedules := table_number();
                o_vacancies := table_number();
            END IF;
        ELSE
            o_schedules := table_number();
            o_vacancies := table_number();
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                o_schedules := NULL;
                o_vacancies := NULL;
            
                RETURN FALSE;
            END;
    END get_vac_and_sch_mult;

    /*
    * retirar ao resultado da get_vacancies que esta na tabela sch_tmptab_vacs_mfr as ausencias do prof
    * Adaptado da funcao homonima em pk_schedule.
    *
    * @param i_lang       Language identifier.
    * @param i_prof       Professional who is using the scheduler. Do not mistake with i_args.idx_id_prof who is the target professional 
    * @param o_error      Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author   Telmo
    * @version  2.4.4
    * @date     13-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_available_vacancies
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_vacancies IN table_number DEFAULT NULL,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_AVAILABLE_VACANCIES';
        l_unav_vacancies table_number;
    BEGIN
        g_error := 'GET UNAVAILABLE VACANCIES';
        -- Get vacancies that are unavailable due to professionals' absence periods.
        SELECT scv.id_sch_consult_vacancy
          BULK COLLECT
          INTO l_unav_vacancies
          FROM sch_consult_vacancy scv
          JOIN sch_tmptab_vacs_mfr m
            ON scv.id_sch_consult_vacancy = m.id_sch_consult_vacancy
         WHERE scv.id_prof IS NOT NULL
           AND (i_vacancies IS NULL OR
               (scv.id_sch_consult_vacancy IN (SELECT *
                                                  FROM TABLE(i_vacancies))))
           AND scv.flg_status = pk_schedule_bo.g_status_blocked;
    
        -- substrair a' lista principal de vagas estas que se acabou de determinar. 
        g_error := 'REMOVE UNAVAILABLE VACANCIES';
        DELETE sch_tmptab_vacs_mfr mf
         WHERE mf.id_sch_consult_vacancy IN (SELECT *
                                               FROM TABLE(l_unav_vacancies));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_available_vacancies;

    /*
    * ALERT-10114
    * Returns the list of vacancies that satisfy a given list of criteria. So the search must be done only in the permanent vacancy universe.
    * The output of this function goes to table sch_tmptab_vacs_mfr (temporary table).
    *
    * important rule:
    * if wizmode = Y
    *   - vacancies which have temporary slots return temporary slots
    *   - vacancies which doesn't have temporary slots return permanent slots
    * if wizmode = N
    *   - return only permanent slots
    * 
    * @param i_lang       Language identifier.
    * @param i_prof       Professional who is using the scheduler. Do not mistake with i_args.idx_id_prof who is the target professional 
    * @param i_args       UI arguments that define the criteria.
    * @param i_wizmode    Y = eventual temporary slots take precedence over their permanent brothers
    * @param o_slots      List of slot identifiers
    * @param o_error      Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author   Telmo
    * @version  2.4.4
    * @date     04-12-2008
    * 
    * OPTIMIZED
    * ALERT-16144 - sql tuning
    * @author  Telmo Castro 
    * @date    04-02-2009
    * @version 2.4.4
    *
    * UPDATED
    * ALERT-17213 - passei o filtro da duracao para o get_schedules
    * @author  Telmo Castro
    * @date    11-02-2009
    * @version 2.4.4
    *
    * @alteration JM 2009/03/10 Exception handling refactoring
    *
    * @alteration JM 2009/03/10 Exception handling refactoring
    * UPDATED
    * ALERT-17702 - reformulacao do calculo da num_schedules_temp e num_schedules_temp_olap
    * @author  Telmo
    * @date    15-05-2009
    * @version 2.5
    */
    FUNCTION get_vacancies
    (
        i_lang    IN language.id_language%TYPE DEFAULT NULL,
        i_prof    IN profissional,
        i_args    IN table_varchar,
        i_wizmode IN VARCHAR2 DEFAULT 'N',
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_VACANCIES';
        l_start_ts  TIMESTAMP WITH TIME ZONE := NULL;
        l_end_ts    TIMESTAMP WITH TIME ZONE := NULL;
    
        l_list_dep       table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule.idx_id_dep));
        l_list_event     table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule.idx_event));
        l_list_prof      table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule.idx_id_prof));
        l_list_dcs       table_number;
        l_list_physareas table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule.idx_id_phys_area));
    
        -- esta funcao faz update nas colunas sch_tmptab_vacs_mfr.num_schedules_temp e sch_tmptab_vacs_mfr.num_schedules_temp_olap
        PROCEDURE inner_upd_scheds_temp
        (
            l_start_ts TIMESTAMP WITH LOCAL TIME ZONE,
            l_end_ts   TIMESTAMP WITH LOCAL TIME ZONE
        ) IS
            CURSOR c_scheds IS
                SELECT id_schedule,
                       id_sch_consult_vacancy,
                       pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz) dt_begin
                  FROM schedule s
                 WHERE s.flg_status = pk_schedule.g_sched_status_temporary
                   AND s.dt_begin_tstz BETWEEN l_start_ts AND l_end_ts
                   AND s.id_sch_event IN
                       (SELECT id_sch_event
                          FROM sch_event
                         WHERE dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm)
                   AND s.id_prof_schedules = i_prof.id;
            rec      c_scheds%ROWTYPE;
            l_id_scv sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        
        BEGIN
            g_error := 'OPEN c_scheds CURSOR';
            OPEN c_scheds;
            LOOP
                FETCH c_scheds
                    INTO rec;
                EXIT WHEN c_scheds%NOTFOUND;
                g_error := 'PROCESS c_scheds RECORD';
                IF rec.id_sch_consult_vacancy IS NOT NULL
                THEN
                    -- este agendamento ocupou uma vaga - nao sobrepoe nada
                    UPDATE sch_tmptab_vacs_mfr
                       SET num_schedules_temp = num_schedules_temp + 1
                     WHERE id_sch_consult_vacancy = rec.id_sch_consult_vacancy;
                ELSE
                    -- este agendamento nao ocupou uma vaga. Verificar se tem uma vaga debaixo mesmo assim.
                    -- se tiver trata-se de um overlap
                    BEGIN
                        g_error := 'FIND HIDDEN VACANCY';
                        SELECT scv.id_sch_consult_vacancy
                          INTO l_id_scv
                          FROM schedule s
                          JOIN schedule_intervention si
                            ON s.id_schedule = si.id_schedule
                          JOIN sch_resource sr
                            ON si.id_schedule = sr.id_schedule
                          JOIN sch_consult_vacancy scv
                            ON s.id_instit_requested = scv.id_institution
                           AND s.id_sch_event = scv.id_sch_event
                          JOIN sch_consult_vac_mfr scvm
                            ON scv.id_sch_consult_vacancy = scvm.id_sch_consult_vacancy
                         WHERE s.id_schedule = rec.id_schedule
                           AND s.dt_begin_tstz BETWEEN scv.dt_begin_tstz AND scv.dt_end_tstz
                           AND s.dt_end_tstz BETWEEN scv.dt_begin_tstz AND scv.dt_end_tstz
                           AND sr.id_professional = scv.id_prof
                           AND si.id_physiatry_area = scvm.id_physiatry_area
                           AND si.flg_original = g_yes
                           AND scv.flg_status = pk_schedule_bo.g_status_active;
                        -- encontrou vaga - incrementa num_schedules_temp_olap
                        UPDATE sch_tmptab_vacs_mfr
                           SET num_schedules_temp_olap = num_schedules_temp_olap + 1
                         WHERE id_sch_consult_vacancy = l_id_scv;
                    EXCEPTION
                        WHEN no_data_found THEN
                            -- nao encontrou vaga - incrementa num_schedules_temp num registo pirata da sch_tmptab_vacs_mfr 
                            g_error := 'MERGE INTO SCH_TMPTAB_VACS_MFR';
                            MERGE INTO sch_tmptab_vacs_mfr g
                            USING (SELECT rec.dt_begin dt_begin
                                     FROM dual) d
                            ON (g.dt_begin_trunc = d.dt_begin AND g.id_sch_consult_vacancy < 0)
                            WHEN MATCHED THEN
                                UPDATE
                                   SET num_schedules_temp = num_schedules_temp + 1
                            WHEN NOT MATCHED THEN
                                INSERT
                                    (id_sch_consult_vacancy,
                                     num_schedules_temp,
                                     num_schedules_perm,
                                     num_slots_temp,
                                     num_slots_perm,
                                     dt_begin_trunc,
                                     num_schedules_temp_olap)
                                VALUES
                                    (-1 * seq_sch_consult_vacancy.nextval, 1, 0, 0, 0, d.dt_begin, 0);
                    END;
                END IF;
            END LOOP;
            CLOSE c_scheds;
        
        EXCEPTION
            WHEN OTHERS THEN
                IF c_scheds%ISOPEN
                THEN
                    CLOSE c_scheds;
                END IF;
        END inner_upd_scheds_temp;
    
    BEGIN
        g_error := 'TRUNCATE TEMPORARY TABLE';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_ARGS';
    
        g_error := 'TRUNCATE VACANCIES TEMPORARY TABLE';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_VACS_MFR';
    
        g_error := 'FILL TEMPORARY TABLE (departments)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule.idx_id_dep, column_value
              FROM TABLE(l_list_dep);
        g_error := 'FILL TEMPORARY TABLE (events)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule.idx_event, column_value
              FROM TABLE(l_list_event);
        g_error := 'FILL TEMPORARY TABLE (profs)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule.idx_id_prof, column_value
              FROM TABLE(l_list_prof);
    
        -- OS DCS TEM DE SER CARREGADOS DA FUNCAO GET_BASE_DCS EM VEZ DA L_LIST_DCS
        IF NOT get_base_id_dcs(i_lang, i_prof, l_list_dcs, o_error)
        THEN
            RETURN FALSE;
        END IF;
        g_error := 'FILL TEMPORARY TABLE (dcs)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule.idx_id_dep_clin_serv, column_value
              FROM TABLE(l_list_dcs);
        g_error := 'FILL TEMPORARY TABLE (phys. areas)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule.idx_id_phys_area, column_value
              FROM TABLE(l_list_physareas);
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_start_ts';
        -- Get start timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_args(pk_schedule_common.idx_dt_begin),
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_ts,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_end_ts';
        -- Get start timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_args(pk_schedule_common.idx_dt_end),
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_ts,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'INSERT INTO SCH_TMPTAB_VACS_MFR';
        INSERT INTO sch_tmptab_vacs_mfr
            (id_sch_consult_vacancy, dt_begin_trunc)
            SELECT DISTINCT scv.id_sch_consult_vacancy, pk_date_utils.trunc_insttimezone(i_prof, scv.dt_begin_tstz)
              FROM sch_consult_vac_mfr_slot scvms
             RIGHT JOIN sch_consult_vac_mfr scvm
                ON scvms.id_sch_consult_vacancy = scvm.id_sch_consult_vacancy
              JOIN sch_consult_vacancy scv
                ON scvm.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
              JOIN sch_event se
                ON scv.id_sch_event = se.id_sch_event
              JOIN sch_department sd
                ON se.dep_type = sd.flg_dep_type
              JOIN sch_permission sp
                ON se.id_sch_event = sp.id_sch_event
            -- o prof target tem de estar com accesso a' physiatry area
              JOIN prof_physiatry_area ppa
                ON sp.id_institution = ppa.id_institution
               AND sp.id_professional = ppa.id_professional
             WHERE sp.id_institution = i_prof.institution
               AND sp.id_professional = i_prof.id
                  -- ONLY PERMANENT SLOTS
               AND (scvms.id_sch_consult_vacancy IS NULL OR scvms.flg_status = g_slot_status_permanent)
                  --join by professionals whose agendas can be seen by our main guy
               AND (scv.id_prof IS NULL OR scv.id_prof = sp.id_prof_agenda)
                  --filter by permissions
               AND sp.flg_permission <> pk_schedule.g_permission_none
                  --filter by permissions to physiatry areas
               AND scvm.id_physiatry_area = ppa.id_physiatry_area
               AND ppa.flg_available = g_yes
                  --filter by institution
               AND scv.id_institution = i_args(pk_schedule.idx_id_inst)
                  --filter by department
               AND EXISTS
             (SELECT /*+NL_SJ*/
                     1
                      FROM sch_tmptab_args
                     WHERE argtype = pk_schedule.idx_id_dep
                       AND id = sd.id_department)
                  --filter by DCS (under permissions)
               AND (i_args(pk_schedule.idx_event) IS NULL OR EXISTS
                    (SELECT /*+NL_SJ*/
                      1
                       FROM sch_tmptab_args
                      WHERE argtype = pk_schedule.idx_id_dep_clin_serv
                        AND id = sp.id_dep_clin_serv))
                  --filter by begin and end date
               AND nvl(scvms.dt_begin_tstz, scv.dt_begin_tstz) >= l_start_ts
               AND (i_args(pk_schedule.idx_dt_end) IS NULL OR (nvl(scvms.dt_begin_tstz, scv.dt_begin_tstz) < l_end_ts))
                  --filter vacancies by DCS. DCS cannot be null. It can be 'All' or a list of DCSs.
               AND (i_args(pk_schedule.idx_event) IS NULL OR EXISTS
                    (SELECT /*+NL_SJ*/
                      1
                       FROM sch_tmptab_args
                      WHERE argtype = pk_schedule.idx_id_dep_clin_serv
                        AND id = scv.id_dep_clin_serv))
                  --Filter by events
               AND (i_args(pk_schedule.idx_event) IS NULL OR EXISTS
                    (SELECT /*+NL_SJ*/
                      1
                       FROM sch_tmptab_args
                      WHERE argtype = pk_schedule.idx_event
                        AND id = scv.id_sch_event))
                  --Filter by Professional. prof can be null or a list of profs
               AND (i_args(pk_schedule.idx_id_prof) IS NULL OR EXISTS
                    (SELECT /*+NL_SJ*/
                      1
                       FROM sch_tmptab_args
                      WHERE argtype = pk_schedule.idx_id_prof
                        AND id = scv.id_prof))
                  --Filter dep type
               AND sd.flg_dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
                  -- only the good vacancies 
               AND scv.flg_status = pk_schedule_bo.g_status_active
                  --Filter by physiatry area
               AND (i_args(pk_schedule.idx_id_phys_area) IS NULL OR EXISTS
                    (SELECT /*+NL_SJ*/
                      1
                       FROM sch_tmptab_args
                      WHERE argtype = pk_schedule.idx_id_phys_area
                        AND id = scvm.id_physiatry_area))
                  --filter by start and end time 
               AND (i_args(pk_schedule_common.idx_time_begin) IS NULL OR
                   pk_date_utils.to_char_insttimezone(i_prof,
                                                       nvl(scvms.dt_begin_tstz, scv.dt_begin_tstz),
                                                       pk_schedule.g_default_time_mask) >=
                   i_args(pk_schedule_common.idx_time_begin))
               AND (i_args(pk_schedule_common.idx_time_end) IS NULL OR
                   pk_date_utils.to_char_insttimezone(i_prof,
                                                       nvl(scvms.dt_end_tstz, scv.dt_end_tstz),
                                                       pk_schedule.g_default_time_mask) <=
                   i_args(pk_schedule_common.idx_time_end));
    
        -- popular resto das colunas.
        -- a sch_tmptab_vacs_mfr foi preenchida com as vagas com slots permanentes que satisfazem a procura.
        -- agora vai-se completar os registos com informacao estatistica. Essa informacao vai dar muito jeito aos consumidores desta funcao.
        g_error := 'UPDATE SCH_TMPTAB_VACS_MFR';
        UPDATE sch_tmptab_vacs_mfr m
           SET num_schedules_temp      = 0,
               num_schedules_temp_olap = 0,
               num_schedules_perm     =
               (SELECT COUNT(1)
                  FROM schedule s
                 WHERE s.id_sch_consult_vacancy = m.id_sch_consult_vacancy
                   AND s.flg_status = pk_schedule.g_status_scheduled),
               num_slots_temp         =
               (SELECT COUNT(1)
                  FROM sch_consult_vac_mfr_slot sl
                 WHERE sl.id_sch_consult_vacancy = m.id_sch_consult_vacancy
                   AND sl.id_professional = i_prof.id
                   AND sl.flg_status = g_slot_status_temporary),
               num_slots_perm         =
               (SELECT COUNT(1)
                  FROM sch_consult_vac_mfr_slot sl
                 WHERE sl.id_sch_consult_vacancy = m.id_sch_consult_vacancy
                   AND sl.flg_status = g_slot_status_permanent);
    
        IF i_wizmode = g_yes
        THEN
            inner_upd_scheds_temp(l_start_ts, l_end_ts);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vacancies;

    /*
    * Returns the list of schedules that satisfy a given list of criteria.
    * 
    * @param i_lang       Language identifier.
    * @param i_prof       Professional.
    * @param i_id_patient Patient identifier.
    * @param i_args       UI arguments that define the criteria.
    * @param i_wizmode    Y = eventual temporary schedules are also shown. N = only permanent schedules
    * @param o_schedules  List of schedule identifiers
    * @param o_error      Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author  Telmo
    * @version 2.4.4
    * @date    28-11-2008
    * 
    * TUNED
    * ALERT-16144 - sql tuning
    * @author  Telmo Castro 
    * @date    04-02-2009
    * @version 2.4.4
    *
    * UPDATED
    * ALERT-17213 - passei o filtro da duracao para o get_schedules
    * @author  Telmo Castro
    * @date    11-02-2009
    * @version 2.4.4
    *
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_schedules
    (
        i_lang       IN language.id_language%TYPE DEFAULT NULL,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_args       IN table_varchar,
        i_wizmode    IN VARCHAR2 DEFAULT 'N',
        o_schedules  OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCHEDULES';
    
        l_list_dep         table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule_common.idx_id_dep));
        l_list_dcs         table_number;
        l_list_event       table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule_common.idx_event));
        l_list_prof        table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule_common.idx_id_prof));
        l_list_duration    table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule_common.idx_duration));
        l_list_pref_langs  table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule_common.idx_preferred_lang));
        l_list_types       table_varchar := pk_schedule.get_list_string_csv(i_args(pk_schedule_common.idx_type));
        l_list_status      table_varchar := pk_schedule.get_list_string_csv(i_args(pk_schedule_common.idx_status));
        l_list_reasons     table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule_common.idx_id_reason));
        l_list_trans_langs table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule_common.idx_translation_needs));
        l_list_origin      table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule_common.idx_id_origin));
        l_list_room        table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule_common.idx_id_room));
        l_list_physareas   table_number := pk_schedule.get_list_number_csv(i_args(pk_schedule.idx_id_phys_area));
    
        l_start_ts TIMESTAMP WITH TIME ZONE := NULL;
        l_end_ts   TIMESTAMP WITH TIME ZONE := NULL;
    
        CURSOR c_schedules
        (
            i_start_ts TIMESTAMP WITH TIME ZONE,
            i_end_ts   TIMESTAMP WITH TIME ZONE
        ) IS
            SELECT id_schedule
              FROM (SELECT s.id_schedule, s.dt_begin_tstz dt_begin, s.dt_end_tstz dt_end
                      FROM schedule s
                      JOIN schedule_intervention si
                        ON s.id_schedule = si.id_schedule
                      LEFT JOIN sch_resource sr
                        ON si.id_schedule = sr.id_schedule
                      JOIN sch_group sg
                        ON si.id_schedule = sg.id_schedule
                      JOIN patient pat
                        ON sg.id_patient = pat.id_patient
                      JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                      JOIN sch_department sd
                        ON se.dep_type = sd.flg_dep_type
                     WHERE s.id_instit_requested = i_prof.institution
                       AND si.flg_original = g_yes
                       AND sd.id_department IN (SELECT DISTINCT id_department
                                                  FROM prof_dep_clin_serv pdcs
                                                 INNER JOIN dep_clin_serv dxs
                                                    ON pdcs.id_dep_clin_serv = dxs.id_dep_clin_serv
                                                 WHERE pdcs.id_professional = i_prof.id)
                          -- exclude temporary schedules if not in wizard mode
                       AND ((i_wizmode = g_no AND
                           s.flg_status IN
                           (pk_schedule.g_sched_status_scheduled, pk_schedule.g_sched_status_cancelled) OR
                           (i_wizmode = g_yes AND
                           s.flg_status IN (pk_schedule.g_sched_status_scheduled,
                                               pk_schedule.g_sched_status_temporary,
                                               pk_schedule.g_sched_status_cancelled))))
                          -- Filter by department
                       AND (i_args(pk_schedule_common.idx_id_dep) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = pk_schedule_common.idx_id_dep
                                AND id = sd.id_department))
                          -- Filter by type
                       AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
                          -- Filter by date
                       AND s.dt_begin_tstz >= i_start_ts
                       AND (i_args(pk_schedule_common.idx_dt_end) IS NULL OR s.dt_begin_tstz < i_end_ts)
                          -- Filter by DCS                             
                       AND EXISTS
                     (SELECT /*+NL_SJ*/
                             1
                              FROM sch_tmptab_args
                             WHERE argtype = pk_schedule_common.idx_id_dep_clin_serv
                               AND id = s.id_dcs_requested)
                          -- Filter by event
                       AND (i_args(pk_schedule_common.idx_event) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = pk_schedule_common.idx_event
                                AND id = s.id_sch_event))
                          -- Filter by professional
                       AND (i_args(pk_schedule_common.idx_id_prof) IS NULL OR sr.id_professional IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = pk_schedule_common.idx_id_prof
                                AND id = sr.id_professional))
                          -- Filter by preferred language
                       AND (i_args(pk_schedule_common.idx_preferred_lang) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = pk_schedule_common.idx_preferred_lang
                                AND id = s.id_lang_preferred))
                          -- Filter by vacancy type
                       AND (i_args(pk_schedule_common.idx_type) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_vargs
                              WHERE argtype = pk_schedule_common.idx_type
                                AND id = s.flg_vacancy))
                          -- Filter by status
                       AND (i_args(pk_schedule_common.idx_status) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_vargs
                              WHERE argtype = pk_schedule_common.idx_status
                                AND id = s.flg_status))
                          -- Filter by reason
                       AND ((i_args(pk_schedule_common.idx_id_reason) IS NOT NULL AND
                           (EXISTS (SELECT /*+NL_SJ*/
                                       1
                                        FROM sch_tmptab_args
                                       WHERE argtype = pk_schedule_common.idx_id_reason
                                         AND id = s.id_reason))) OR
                           (i_args(pk_schedule_common.idx_id_reason) IS NULL AND
                           (i_args(pk_schedule_common.idx_reason_notes) IS NULL OR
                           upper(s.reason_notes) LIKE
                           '%' || upper(i_args(pk_schedule_common.idx_reason_notes)) || '%')))
                          -- Filter by translation needs
                       AND (i_args(pk_schedule_common.idx_translation_needs) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = pk_schedule_common.idx_translation_needs
                                AND id = s.id_lang_translator))
                          -- Filter by origin                           
                       AND (i_args(pk_schedule_common.idx_id_origin) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = pk_schedule_common.idx_id_origin
                                AND id = s.id_origin))
                          -- Filter by room
                       AND (i_args(pk_schedule_common.idx_id_room) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = pk_schedule_common.idx_id_room
                                AND id = s.id_room))
                          --Filter by duration. Alterei de modo a dar as slots com duracao maior ou igual 
                       AND (i_args(pk_schedule.idx_duration) IS NULL OR
                           (s.dt_end_tstz IS NOT NULL AND EXISTS
                            (SELECT /*+NL_SJ*/
                               1
                                FROM sch_tmptab_args
                               WHERE argtype = pk_schedule.idx_duration
                                 AND id = trunc(pk_date_utils.get_timestamp_diff(s.dt_end_tstz, s.dt_begin_tstz),
                                                pk_schedule.g_max_decimal_prec))))
                          -- Filter by patient
                       AND (i_id_patient IS NULL OR sg.id_patient = i_id_patient)
                          -- Filter by physiatry area
                       AND (i_args(pk_schedule.idx_id_phys_area) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = pk_schedule.idx_id_phys_area
                                AND id = si.id_physiatry_area)))
            
            -- Filter by time. This filter is applied on the outside query to prevent
            -- to_char_insttimezone to be called event for records that are not valid.
             WHERE (i_args(pk_schedule_common.idx_time_begin) IS NULL OR
                   pk_date_utils.to_char_insttimezone(i_prof, dt_begin, pk_schedule.g_default_time_mask) >=
                   i_args(pk_schedule_common.idx_time_begin))
               AND (i_args(pk_schedule_common.idx_time_end) IS NULL OR
                   pk_date_utils.to_char_insttimezone(i_prof, dt_end, pk_schedule.g_default_time_mask) <=
                   i_args(pk_schedule_common.idx_time_end));
    BEGIN
    
        g_error := 'TRUNCATE TEMPORARY TABLE';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_ARGS';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_VARGS';
    
        -- fill it up 
        g_error := 'FILL TEMPORARY TABLE (departments)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule_common.idx_id_dep, column_value
              FROM TABLE(l_list_dep);
        -- OS DCS TEM DE SER CARREGADOS DA FUNCAO GET_BASE_DCS EM VEZ DA L_LIST_DCS
        IF NOT get_base_id_dcs(i_lang, i_prof, l_list_dcs, o_error)
        THEN
            RETURN FALSE;
        END IF;
        g_error := 'FILL TEMPORARY TABLE (dcs)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule_common.idx_id_dep_clin_serv, column_value
              FROM TABLE(l_list_dcs);
        g_error := 'FILL TEMPORARY TABLE (events)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule_common.idx_event, column_value
              FROM TABLE(l_list_event);
        g_error := 'FILL TEMPORARY TABLE (profs)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule_common.idx_id_prof, column_value
              FROM TABLE(l_list_prof);
        g_error := 'FILL TEMPORARY TABLE (durations)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule_common.idx_duration, column_value
              FROM TABLE(l_list_duration);
        g_error := 'FILL TEMPORARY TABLE (pref. langs)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule_common.idx_preferred_lang, column_value
              FROM TABLE(l_list_pref_langs);
        g_error := 'FILL TEMPORARY TABLE (types)';
        INSERT INTO sch_tmptab_vargs
            SELECT DISTINCT pk_schedule_common.idx_type, column_value
              FROM TABLE(l_list_types);
        g_error := 'FILL TEMPORARY TABLE (status)';
        INSERT INTO sch_tmptab_vargs
            SELECT DISTINCT pk_schedule_common.idx_status, column_value
              FROM TABLE(l_list_status);
        g_error := 'FILL TEMPORARY TABLE (reasons)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule_common.idx_id_reason, column_value
              FROM TABLE(l_list_reasons);
        g_error := 'FILL TEMPORARY TABLE (trans. langs)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule_common.idx_translation_needs, column_value
              FROM TABLE(l_list_trans_langs);
        g_error := 'FILL TEMPORARY TABLE (origins)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule_common.idx_id_origin, column_value
              FROM TABLE(l_list_origin);
        g_error := 'FILL TEMPORARY TABLE (rooms)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule_common.idx_id_room, column_value
              FROM TABLE(l_list_room);
        g_error := 'FILL TEMPORARY TABLE (phys. areas)';
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT pk_schedule.idx_id_phys_area, column_value
              FROM TABLE(l_list_physareas);
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_start_ts';
        -- Get start timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_args(pk_schedule_common.idx_dt_begin),
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_ts,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_end_ts';
        -- Get start timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_args(pk_schedule_common.idx_dt_end),
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_ts,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN c_schedules';
        OPEN c_schedules(l_start_ts, l_end_ts);
        g_error := 'FETCH c_schedules';
        FETCH c_schedules BULK COLLECT
            INTO o_schedules;
        g_error := 'CLOSE c_schedules';
        CLOSE c_schedules;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                o_schedules := NULL;
            
                RETURN FALSE;
            END;
    END get_schedules;

    /**
    * Gets the list of conflicting appointments, from those passed as argument.
    *
    * @param  i_lang                    Language identifier
    * @param  i_prof                    Professional
    * @param  i_list_sch                List of appointments to test
    * @param  o_list_sch                List of conflicting appointments
    * @param  o_error                   Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/09/17
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_conflicting_appointments
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_list_sch IN table_number,
        o_list_sch OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_CONFLICTING_APPOINTMENTS(1)';
    
        CURSOR c_conflicts IS
            SELECT /*+ first_rows */
             s.id_schedule
              FROM schedule s, sch_resource sr, sch_absence sa
             WHERE s.id_instit_requested = sa.id_institution
               AND s.id_schedule = sr.id_schedule
               AND s.id_schedule IN (SELECT *
                                       FROM TABLE(i_list_sch))
               AND sr.id_professional IS NOT NULL
               AND sr.id_professional = sa.id_professional
               AND sa.flg_status = pk_schedule.g_status_active
               AND (s.dt_begin_tstz BETWEEN sa.dt_begin_tstz AND sa.dt_end_tstz OR
                   s.dt_end_tstz BETWEEN sa.dt_begin_tstz AND sa.dt_end_tstz);
    BEGIN
        -- Get conflicting appointments
        g_error := 'OPEN c_conflicts';
        OPEN c_conflicts;
        g_error := 'FETCH c_conflicts';
        FETCH c_conflicts BULK COLLECT
            INTO o_list_sch;
        CLOSE c_conflicts;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_conflicting_appointments;

    /**
    * Calculates the month availability data.
    * Adaptacao da funcao com o mesmo nome em pk_schedule
    *
    * @param  i_lang                    Language identifier.
    * @param  i_prof                    Professional.
    * @param  i_mult                    
    * @param  i_wizmode                 wizard mode. Means that i_prof is solving conflicts in a mfr prescription. So temporary 
    * @param  i_list_schedules          List of appointments to consider.
    * @param  i_list_dates              List of dates to consider.
    * @param  i_list_dates_str          List of dates to consider (strings).
    * @param  o_days_status             Resulting list of status, for each day.
    * @param  o_days_date               Resulting list of dates.
    * @param  o_days_free               Resulting list of free vacancies, for each day.
    * @param  o_days_sched              Resulting list of appointments, for each day.
    * @param  o_days_conflicts          Resulting list
    * @param  o_days_tempor             Resulting list of temporary schedules, for each day
    * @param  o_error                   Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.4.4
    * @date    04-12-2008
    * 
    * OPTIMIZED
    * ALERT-16144 - sql tuning
    * @author  Telmo Castro 
    * @date    04-02-2009
    * @version 2.4.4
    *
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION calculate_month_availability
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_mult           IN BOOLEAN,
        i_wizmode        IN VARCHAR2,
        i_list_schedules IN table_number,
        i_list_dates     IN table_timestamp_tz,
        i_list_dates_str IN table_varchar,
        o_days_status    OUT table_varchar,
        o_days_date      OUT table_varchar,
        o_days_free      OUT table_number,
        o_days_sched     OUT table_number,
        o_days_conflicts OUT table_number,
        o_days_tempor    OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'CALCULATE_MONTH_AVAILABILITY';
    
        CURSOR c_vacancies IS
            SELECT m.dt_begin_trunc tstz,
                   SUM(m.num_schedules_perm) schedp,
                   SUM(m.num_schedules_temp) schedt,
                   SUM(m.num_slots_perm) slotsp,
                   SUM(m.num_slots_temp) slotst,
                   SUM(m.num_schedules_temp_olap) schedtol, -- temporary schedules with overlap
                   COUNT(1) numvacancies -- numero de vagas (e nao slots) nesse dia
              FROM sch_tmptab_vacs_mfr m
             GROUP BY m.dt_begin_trunc;
    
        CURSOR c_unavailable_vacancies IS
            SELECT tmptab.dt_begin_trunc tstz, COUNT(1) unavailable --nvl(SUM(scv.max_vacancies - scv.used_vacancies), 0) unavailable
              FROM sch_consult_vacancy scv
              JOIN sch_consult_vac_mfr scvm
                ON scv.id_sch_consult_vacancy = scvm.id_sch_consult_vacancy -- para garantir que ha vaga de mfr
              JOIN sch_tmptab_vacs_mfr tmptab
                ON scvm.id_sch_consult_vacancy = tmptab.id_sch_consult_vacancy
              LEFT JOIN sch_consult_vac_mfr_slot scvms
                ON tmptab.id_sch_consult_vacancy = scvms.id_sch_consult_vacancy
             WHERE scv.id_institution = i_prof.institution
               AND scv.id_prof IS NOT NULL
               AND scv.flg_status = pk_schedule_bo.g_status_blocked
             GROUP BY tmptab.dt_begin_trunc;
    
        CURSOR c_schedules(i_list_schedules table_number) IS
            SELECT /*+ index(s schd_pk) */
             pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz) tstz, COUNT(1) numschedules
              FROM schedule s
             WHERE s.id_schedule IN (SELECT *
                                       FROM TABLE(i_list_schedules))
             GROUP BY pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz);
    
        TYPE t_date_status IS RECORD(
            numschedules NUMBER(24),
            numslots     NUMBER(24),
            numslotstemp NUMBER(24),
            unavailable  NUMBER(24),
            conflicts    NUMBER(24),
            tempscheds   NUMBER(24),
            tempschedsol NUMBER(24),
            numvacancies NUMBER(24));
    
        TYPE t_table_date_status IS TABLE OF t_date_status INDEX BY VARCHAR2(4000);
        TYPE t_table_vacancies IS TABLE OF c_vacancies%ROWTYPE;
        TYPE t_table_schedules IS TABLE OF c_schedules%ROWTYPE;
        TYPE t_table_unav_vacancies IS TABLE OF c_unavailable_vacancies%ROWTYPE;
    
        l_status          t_table_date_status;
        l_status_elem     t_date_status;
        l_ts_string       VARCHAR2(4000);
        l_vacancies       t_table_vacancies;
        l_schedules       t_table_schedules;
        l_conflicting_sch table_number;
        l_unav_vacancies  t_table_unav_vacancies;
        l_idx             NUMBER := 0;
        l_v_idx           VARCHAR2(4000);
        c                 INTEGER;
    BEGIN
        g_error          := 'INITIALIZE RESULTS';
        o_days_status    := table_varchar();
        o_days_date      := table_varchar();
        o_days_free      := table_number();
        o_days_sched     := table_number();
        o_days_conflicts := table_number();
        o_days_tempor    := table_varchar();
    
        g_error := 'INITIALIZE STATUS';
        -- Initialize status, using string-represented dates as keys
        FOR idx IN i_list_dates_str.first .. i_list_dates_str.last
        LOOP
            l_ts_string := i_list_dates_str(idx);
            l_status(l_ts_string).numschedules := 0;
            l_status(l_ts_string).numslots := 0;
            l_status(l_ts_string).numslotstemp := 0;
            l_status(l_ts_string).unavailable := 0;
            l_status(l_ts_string).conflicts := 0;
            l_status(l_ts_string).tempscheds := 0;
            l_status(l_ts_string).tempschedsol := 0;
            l_status(l_ts_string).numvacancies := 0;
        END LOOP;
    
        -- Get vacancies
        g_error := 'OPEN c_vacancies';
        OPEN c_vacancies;
        g_error := 'FETCH c_vacancies';
        FETCH c_vacancies BULK COLLECT
            INTO l_vacancies;
        g_error := 'CLOSE c_vacancies';
        CLOSE c_vacancies;
    
        g_error := 'ITERATE THROUGH VACANCIES';
        -- Get free and used slots and temporary scheds
        IF l_vacancies.count > 0
        THEN
            FOR vac_idx IN l_vacancies.first .. l_vacancies.last
            LOOP
                l_ts_string := pk_date_utils.date_send_tsz(i_lang, l_vacancies(vac_idx).tstz, i_prof);
                l_status(l_ts_string).numvacancies := l_vacancies(vac_idx).numvacancies;
                IF i_wizmode = g_no
                THEN
                    l_status(l_ts_string).numslots := l_vacancies(vac_idx).slotsp;
                ELSE
                    l_status(l_ts_string).numslots := l_vacancies(vac_idx).slotst + l_vacancies(vac_idx).slotsp;
                    l_status(l_ts_string).numslotstemp := l_vacancies(vac_idx).slotst;
                    l_status(l_ts_string).tempscheds := l_vacancies(vac_idx).schedt;
                    l_status(l_ts_string).tempschedsol := l_vacancies(vac_idx).schedtol;
                END IF;
            END LOOP;
        END IF;
    
        IF NOT i_mult
        THEN
            -- Get unavailable vacancies
            g_error := 'OPEN c_unavailable_vacancies';
            OPEN c_unavailable_vacancies;
            g_error := 'FETCH c_unavailable_vacancies';
            FETCH c_unavailable_vacancies BULK COLLECT
                INTO l_unav_vacancies;
            g_error := 'CLOSE c_unavailable_vacancies';
            CLOSE c_unavailable_vacancies;
        
            g_error := 'ITERATE THROUGH UNAVAILABLE VACANCIES';
            IF l_unav_vacancies.count > 0
            THEN
                FOR vac_idx IN l_unav_vacancies.first .. l_unav_vacancies.last
                LOOP
                    l_ts_string := pk_date_utils.date_send_tsz(i_lang, l_unav_vacancies(vac_idx).tstz, i_prof);
                    l_status(l_ts_string).unavailable := l_unav_vacancies(vac_idx).unavailable;
                END LOOP;
            END IF;
        END IF;
    
        -- Get appointments. A i_list_schedules ja vem amanhada de acordo com o i_wizmode
        g_error := 'OPEN c_schedules';
        OPEN c_schedules(i_list_schedules);
        g_error := 'FETCH c_schedules';
        FETCH c_schedules BULK COLLECT
            INTO l_schedules;
        g_error := 'CLOSE c_schedules';
        CLOSE c_schedules;
    
        g_error := 'ITERATE THROUGH SCHEDULES';
        -- Get appointments count
        IF l_schedules.first > 0
        THEN
            FOR sch_idx IN l_schedules.first .. l_schedules.last
            LOOP
                l_ts_string := pk_date_utils.date_send_tsz(i_lang, l_schedules(sch_idx).tstz, i_prof);
                l_status(l_ts_string).numschedules := l_schedules(sch_idx).numschedules;
            END LOOP;
        END IF;
    
        IF NOT i_mult
        THEN
            -- Get conflicting appointments' identifiers
            IF NOT get_conflicting_appointments(i_lang     => i_lang,
                                                i_prof     => i_prof,
                                                i_list_sch => i_list_schedules,
                                                o_list_sch => l_conflicting_sch,
                                                o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- Get conflicting appointments' information
            g_error := 'OPEN c_schedules (CONFLICTS)';
            OPEN c_schedules(l_conflicting_sch);
            g_error := 'FETCH c_schedules (CONFLICTS)';
            FETCH c_schedules BULK COLLECT
                INTO l_schedules;
            g_error := 'CLOSE c_schedules (CONFLICTS)';
            CLOSE c_schedules;
        
            g_error := 'ITERATE THROUGH CONFLICTING SCHEDULES';
            -- Get appointments count
            IF l_schedules.first > 0
            THEN
                FOR sch_idx IN l_schedules.first .. l_schedules.last
                LOOP
                    l_ts_string := pk_date_utils.date_send_tsz(i_lang, l_schedules(sch_idx).tstz, i_prof);
                    l_status(l_ts_string).conflicts := l_schedules(sch_idx).numschedules;
                END LOOP;
            END IF;
        END IF;
    
        -- Prepare results
        g_error := 'PREPARE RESULTS';
        LOOP
            EXIT WHEN l_idx = l_status.count;
        
            IF l_idx = 0
            THEN
                l_v_idx := l_status.first;
            ELSE
                l_v_idx := l_status.next(l_v_idx);
            END IF;
        
            -- Get status element
            l_status_elem := l_status(l_v_idx);
        
            l_idx := l_idx + 1;
            o_days_date.extend;
            o_days_free.extend;
            o_days_sched.extend;
            o_days_status.extend;
            o_days_tempor.extend;
        
            o_days_date(l_idx) := l_v_idx;
            IF NOT i_mult
            THEN
                o_days_conflicts.extend;
                o_days_conflicts(l_idx) := l_status_elem.conflicts;
                o_days_free(l_idx) := l_status_elem.numslots - l_status_elem.unavailable;
            ELSE
                o_days_free(l_idx) := l_status_elem.numslots;
            END IF;
        
            o_days_sched(l_idx) := l_status_elem.numschedules;
        
            -- temp schedules and overlapping temp schedules
            IF l_status_elem.tempschedsol > 0
            THEN
                o_days_tempor(l_idx) := pk_schedule.g_mfr_icon_conflict;
            ELSIF l_status_elem.tempscheds > 0
            THEN
                o_days_tempor(l_idx) := pk_schedule.g_mfr_icon_no_conflict;
            ELSE
                o_days_tempor(l_idx) := g_no;
            END IF;
        
            CASE
                WHEN l_status_elem.numvacancies = 0
                     AND l_status_elem.numschedules = 0 THEN
                    o_days_status(l_idx) := pk_schedule.g_day_status_void;
                
                WHEN l_status_elem.numvacancies = l_status_elem.unavailable --aqui pode ser preciso trocar o numvacancies pelo numslots
                     AND l_status_elem.numvacancies > 0 THEN
                    o_days_status(l_idx) := pk_schedule.g_day_status_unavailable;
                
                WHEN (l_status_elem.numvacancies = 0 AND l_status_elem.numschedules > 0)
                     OR (l_status_elem.numvacancies > 0 AND l_status_elem.numslots = 0)
                     OR (i_wizmode = g_yes AND l_status_elem.numschedules > 0 AND l_status_elem.numslotstemp = 0 AND
                     l_status_elem.tempscheds > 0) THEN
                    o_days_status(l_idx) := pk_schedule.g_day_status_full;
                
                WHEN (l_status_elem.numvacancies > 0 AND l_status_elem.numslots > 0 AND l_status_elem.numschedules = 0) THEN
                    o_days_status(l_idx) := pk_schedule.g_day_status_empty;
                
                WHEN l_status_elem.numschedules > 0
                     AND l_status_elem.numslots > 0 THEN
                    o_days_status(l_idx) := pk_schedule.g_day_status_half;
                ELSE
                    o_days_status(l_idx) := pk_schedule.g_day_status_void;
            END CASE;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END calculate_month_availability;

    /*
    * Validates if a professional can schedule an appoitment 
    *
    * @param   i_lang                       Language identifier.
    * @param   i_prof                       Professional.
    * @param   i_id_prof                    Professioanl identifier for the validation
    * @param   i_dt_begin                   Begin date
    * @param   i_id_phys_area               Physiatry area identifier
    * @param   i_duration                   Duration of the intervention in minutes
    * @param   o_id_sch_mfr_slot            Possible slot identifier, if any exists, null otherwise.
    * @param   o_flg_conflict               Flag indicating if exists any conflict
    * @param   o_no_vacancy                 String with the description of the no vacancy conflict
    * @param   o_over_slot                  String with the description of the over slot conflict
    * @param   o_error                      Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Jose Antunes
    * @version 2.4.4
    * @since 2008/11/21
    * 
    * OPTIMIZED
    * ALERT-16144 - sql tuning
    * @author  Telmo Castro 
    * @date    04-02-2009
    * @version 2.4.4
    *
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION validate_sched_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_prof         IN sch_consult_vacancy.id_prof%TYPE,
        i_dt_begin_tstz   IN sch_consult_vacancy.dt_begin_tstz%TYPE,
        i_id_phys_area    IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE,
        i_duration        IN NUMBER,
        o_id_sch_mfr_slot OUT sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE,
        o_flg_conflict    OUT VARCHAR2,
        o_no_vacancy      OUT VARCHAR2,
        o_over_slot       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name      VARCHAR2(32) := 'VALIDATE_SCHED_DATE';
        l_id_sch_con_vac sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        o_dcs_table      table_number;
        l_val_no_access EXCEPTION;
        l_val_dt_null   EXCEPTION;
    BEGIN
    
        -- Checks if professional has access to dep_clin_serv to schedule a MFR appoitment
        g_error := 'CALL GET_PROF_BASE_DCS_PERM';
        IF NOT pk_schedule_mfr.get_prof_base_dcs_perm(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_flg_schedule => g_yes,
                                                      o_dcs          => o_dcs_table,
                                                      o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (o_dcs_table.count < 1)
        THEN
            RAISE l_val_no_access;
        END IF;
    
        -- if the professional has access to a dep_clin_serv...
    
        -- RULE : Date cannot be null 
        g_error := 'RULE : Date cannot be null';
        IF i_dt_begin_tstz IS NULL
        THEN
            RAISE l_val_dt_null;
        END IF;
    
        BEGIN
            -- prof_dep_clin_serv and sch_permission was tested before in get_prof_base_dcs_perm
            -- checks if exist a vacancy
            g_error := 'SELECT sch_consult_vacancy';
            SELECT scv.id_sch_consult_vacancy
              INTO l_id_sch_con_vac
              FROM sch_consult_vacancy scv
             WHERE scv.id_prof = i_id_prof
               AND scv.id_institution = i_prof.institution
               AND scv.id_dep_clin_serv IN (SELECT *
                                              FROM TABLE(o_dcs_table))
               AND scv.id_sch_event = g_mfr_event
               AND scv.dt_begin_tstz <= i_dt_begin_tstz
               AND scv.dt_end_tstz >= i_dt_begin_tstz + (i_duration / 24 / 60)
               AND scv.flg_status = pk_schedule_bo.g_status_active
               AND rownum = 1; -- the first slot found is suficient for the validation
        
        EXCEPTION
            WHEN no_data_found THEN
                o_no_vacancy := pk_message.get_message(i_lang, g_no_vacancy);
        END;
    
        IF o_no_vacancy IS NULL
        THEN
            BEGIN
                -- prof_dep_clin_serv and sch_permission was tested before in get_prof_base_dcs_perm
                -- checks if exist a free slot
                g_error := 'SELECT sch_consult_vac_mfr_slot';
                SELECT scvms.id_sch_consult_vac_mfr_slot
                  INTO o_id_sch_mfr_slot
                  FROM sch_consult_vacancy scv
                  JOIN sch_consult_vac_mfr scvm
                    ON scv.id_sch_consult_vacancy = scvm.id_sch_consult_vacancy
                  JOIN prof_physiatry_area ppa
                    ON scv.id_institution = ppa.id_institution
                   AND scv.id_prof = ppa.id_professional
                   AND scvm.id_physiatry_area = ppa.id_physiatry_area
                  JOIN sch_consult_vac_mfr_slot scvms
                    ON scvm.id_sch_consult_vacancy = scvms.id_sch_consult_vacancy
                 WHERE ppa.id_physiatry_area = i_id_phys_area
                   AND ppa.id_professional = i_id_prof
                   AND scvms.dt_begin_tstz <= i_dt_begin_tstz
                   AND scvms.dt_end_tstz >= i_dt_begin_tstz + (i_duration / 24 / 60)
                   AND scvms.flg_status = pk_schedule_mfr.g_slot_status_permanent
                   AND rownum = 1; -- the first slot found is suficient for the validation
            
            EXCEPTION
                WHEN no_data_found THEN
                    o_over_slot := pk_message.get_message(i_lang, g_over_slot);
            END;
        END IF;
        -- if reasons are null, o_flg_conflict indicating if there is a conflict must be false
        g_error := 'FILL o_flg_conflict';
        IF o_over_slot IS NOT NULL
        THEN
            o_flg_conflict := g_conf_over_slot;
        ELSIF o_no_vacancy IS NOT NULL
        THEN
            o_flg_conflict := g_conf_no_vacancy;
        ELSE
            o_flg_conflict := g_no_conflict;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_val_no_access THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_ret           BOOLEAN;
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'SCH_T218');
            BEGIN
                l_error_in.set_all(i_lang, 'SCH_T218', l_error_message, g_error, 'ALERT', g_package_name, l_func_name);
                l_error_in.set_action(pk_message.get_message(i_lang, 'SCH_T218'), 'U');
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END validate_sched_date;

    /*
    * Validates a set of dates 
    *
    * @param   i_lang                       Language identifier.
    * @param   i_prof                       Professional.
    * @param   i_id_profs                   Professioanl identifiers for the validation
    * @param   i_id_phys_area               Physiatry area identifier
    * @param   i_duration                   Duration of appointment
    * @param   i_dates                      Table with dates previously calculate 
    * @param   o_conflicts                  Table with the conflits of each date presented in i_dates
    * @param   o_error                      Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Jose Antunes
    * @version 2.4.4
    * @since 2008/11/26
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION validate_sch_dates
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_profs     IN table_number,
        i_id_phys_area IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE,
        i_durations    IN table_number,
        i_dates        IN table_timestamp_tz,
        o_conflicts    OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name       VARCHAR2(32) := 'VALIDATE_SCH_DATES';
        l_duration        NUMBER;
        l_id_sch_mfr_slot sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE;
        l_flg_conflict    VARCHAR2(1);
        l_desc_no_vac     VARCHAR2(4000);
        l_desc_over_slot  VARCHAR2(4000);
    
    BEGIN
    
        g_error     := 'Fill o_conflicts';
        o_conflicts := table_table_varchar();
        IF (i_dates.count > 0)
        THEN
            FOR i IN i_dates.first .. i_dates.last
            LOOP
            
                -- validate date
                IF NOT validate_sched_date(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_id_prof         => i_id_profs(i),
                                           i_dt_begin_tstz   => i_dates(i),
                                           i_id_phys_area    => i_id_phys_area,
                                           i_duration        => i_durations(i),
                                           o_id_sch_mfr_slot => l_id_sch_mfr_slot,
                                           o_flg_conflict    => l_flg_conflict,
                                           o_no_vacancy      => l_desc_no_vac,
                                           o_over_slot       => l_desc_over_slot,
                                           o_error           => o_error)
                THEN
                
                    RETURN FALSE;
                END IF;
            
                o_conflicts.extend();
                o_conflicts(i) := table_varchar(pk_date_utils.get_timestamp_str(i_lang, i_prof, i_dates(i), NULL),
                                                l_flg_conflict,
                                                l_desc_no_vac,
                                                l_desc_over_slot);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END validate_sch_dates;

    /********************************************************************************************
    * This function gets the total of scheduled sessions for an Intervention Detail, 
    *   and the rank for schedule ID parameter 
    *
    * @param i_lang                          language ID
    * @param i_id_schedule                   schedule ID
    * @param i_flg_wizard                    wizard flag (Y-Yes -> Scheduled / N-No -> Temporaray)
    * @param i_id_interv_presc_det           intervention prescription ID
    * @param o_count                         number of total scheduled sessions
    * @param o_rank                          session rank for i_id_schedule parameter
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2009/01/08
    * @alteration            Joao Martins 2009/01/29 Added parameter i_id_interv_presc_det
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION get_count_and_rank
    (
        i_lang                IN language.id_language%TYPE,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        i_flg_wizard          IN VARCHAR2 DEFAULT NULL,
        i_id_interv_presc_det IN schedule_intervention.id_interv_presc_det%TYPE DEFAULT NULL,
        o_count               OUT NUMBER,
        o_rank                OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(32) := 'GET_COUNT_AND_RANK';
        l_id_interv_presc_det schedule_intervention.id_interv_presc_det%TYPE;
    BEGIN
        IF i_id_interv_presc_det IS NULL
        THEN
            -- get id_interv_presc_det for i_id_schedule
            g_error := 'GET ID_INTERV_PRESC_DET FOR I_ID_SCHEDULE';
            SELECT id_interv_presc_det
              INTO l_id_interv_presc_det
              FROM schedule_intervention
             WHERE id_schedule = i_id_schedule
               AND flg_original = g_yes;
        ELSE
            -- get id_interv_presc_det for i_id_schedule_intervention
            g_error               := 'SET ID_INTERV_PRESC_DET';
            l_id_interv_presc_det := i_id_interv_presc_det;
        END IF;
    
        -- output value o_count
        g_error := 'GET OUTPUT VALUE O_COUNT';
        SELECT num_take
          INTO o_count
          FROM interv_presc_det
         WHERE id_interv_presc_det = l_id_interv_presc_det;
    
        -- output value o_rank    
        g_error := 'GET OUTPUT VALUE O_RANK';
        SELECT rn
          INTO o_rank
          FROM (SELECT rownum rn, subq.id_schedule
                  FROM (SELECT sch.id_schedule
                          FROM schedule sch
                         INNER JOIN schedule_intervention schi
                            ON sch.id_schedule = schi.id_schedule
                         WHERE schi.id_interv_presc_det = l_id_interv_presc_det
                           AND (schi.flg_original = g_yes OR
                               i_id_interv_presc_det IS NOT NULL AND schi.flg_original = g_no)
                           AND sch.flg_status = CASE
                                   WHEN nvl(i_flg_wizard, g_no) = g_no THEN
                                    pk_schedule.g_sched_status_scheduled
                                   ELSE
                                    sch.flg_status
                               END
                           AND sch.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
                         ORDER BY sch.dt_begin_tstz) subq)
         WHERE id_schedule = i_id_schedule;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_count_and_rank;

    /* for alert v2.6
    *
    * @author                Telmo
    * @version               2.6.1
    * @since                 11-05-2011
    */
    FUNCTION get_rank_and_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'GET_COUNT_AND_RANK';
        ret_val     VARCHAR2(100) := ' ';
        lt          table_varchar;
        l_id_rsn    rehab_schedule.id_rehab_sch_need%TYPE;
        l_sessions  rehab_sch_need.sessions%TYPE;
        --        l_rank      NUMBER;
    BEGIN
        g_error := 'GET_COUNT_AND_RANK - get id_rehab_sch_need and sessions';
        SELECT rsn.id_rehab_sch_need, nvl(to_char(rsn.sessions), '?')
          INTO l_id_rsn, l_sessions
          FROM rehab_schedule rs
          JOIN rehab_sch_need rsn
            ON rs.id_rehab_sch_need = rsn.id_rehab_sch_need
         WHERE rs.id_schedule = i_id_schedule;
    
        g_error := 'GET_COUNT_AND_RANK - get data into table_varchar';
        SELECT '(' || to_char(rownum) || '/' || l_sessions || ') ' ||
               pk_schedule.string_date_hm(i_lang, i_prof, subq.dt_begin_tstz)
          BULK COLLECT
          INTO lt
          FROM (SELECT s.id_schedule, s.dt_begin_tstz
                  FROM schedule s
                  JOIN rehab_schedule rs
                    ON s.id_schedule = rs.id_schedule
                 WHERE rs.id_rehab_sch_need = l_id_rsn
                   AND s.flg_status = pk_schedule.g_sched_status_scheduled
                   AND rs.flg_status <> 'C'
                 ORDER BY s.dt_begin_tstz) subq;
    
        g_error := 'GET_COUNT_AND_RANK - convert table_varchar into varchar';
    
        RETURN pk_utils.concat_table(i_tab => lt, i_delim => '; ');
    
    END get_rank_and_count;
    ------------------------------ PUBLIC FUNCTIONS ---------------------------

    /*
    * Gets the schedules, vacancies and patient icons for the daily view. Based on the function with the same name from pk_schedule_exam
    * 
    * @param i_lang            Language identifier.
    * @param i_prof            Professional.
    * @param i_args            UI args.
    * @param i_id_patient      Patient identifier.
    * @param i_wizmode         wizard mode. Means that i_prof is solving conflicts in a mfr prescription. So temporary 
    * @param o_vacants         Vacancies.
    * @param o_schedule        Schedules.
    * @param o_patient_icons   Patient icons.
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author  Telmo Castro
    * @date    05-12-2008
    * @version 2.4.4
    * 
    * OPTIMIZED
    * ALERT-16144 - sql tuning
    * @author  Telmo Castro 
    * @date    04-02-2009
    * @version 2.4.4
    *
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_hourly_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        i_wizmode   IN VARCHAR2 DEFAULT 'N',
        o_vacants   OUT pk_types.cursor_type,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_HOURLY_DETAIL';
        l_list_schedules table_number;
    
        -- Inner function to retrieve the vacancies.
        FUNCTION inner_get_vacancies RETURN pk_types.cursor_type IS
            l_vacants pk_types.cursor_type;
        BEGIN
            -- o get_vacancies so esta a devolver vagas com slots permanentes. mas esta funcao precisa devolver os slots temporarios se wizmode = Y. 
            -- Open l_vacants
            g_error := 'OPEN l_vacants FOR';
            OPEN l_vacants FOR
                SELECT id_sch_consult_vacancy,
                       id_sch_consult_vac_mfr_slot,
                       pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                       pk_date_utils.date_send_tsz(i_lang, dt_end_tstz, i_prof) dt_end,
                       flg_status,
                       id_prof id_prof,
                       id_dep_clin_serv,
                       id_sch_event,
                       --max_vacancies - used_vacancies num_vacancies,  -- VER SE ELISA PRECISA DISTO
                       pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof) nick_prof,
                       pk_schedule.string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                       pk_schedule.has_permission(i_lang, i_prof, id_dep_clin_serv, id_sch_event, id_prof) has_permission,
                       pk_translation.get_translation(i_lang, code_physiatry_area) desc_phys_area,
                       id_physiatry_area,
                       pk_schedule.is_vacancy_available(id_sch_consult_vacancy) flg_available -- check if professional is absent during this vacancy
                  FROM (SELECT scvms.id_sch_consult_vacancy,
                               scvms.id_sch_consult_vac_mfr_slot,
                               scvms.flg_status,
                               scvms.dt_begin_tstz,
                               scvms.dt_end_tstz,
                               scvms.id_physiatry_area,
                               pa.code_physiatry_area,
                               scv.id_prof,
                               scv.id_dep_clin_serv,
                               scv.id_sch_event,
                               tmptab.num_schedules_temp,
                               tmptab.num_schedules_perm,
                               tmptab.num_slots_temp,
                               tmptab.num_slots_perm,
                               tmptab.num_schedules_temp_olap
                          FROM sch_consult_vacancy scv
                          JOIN sch_consult_vac_mfr scvm
                            ON scv.id_sch_consult_vacancy = scvm.id_sch_consult_vacancy
                          JOIN sch_consult_vac_mfr_slot scvms
                            ON scvm.id_sch_consult_vacancy = scvms.id_sch_consult_vacancy
                          JOIN sch_tmptab_vacs_mfr tmptab
                            ON scvms.id_sch_consult_vacancy = tmptab.id_sch_consult_vacancy
                          JOIN physiatry_area pa
                            ON scvms.id_physiatry_area = pa.id_physiatry_area
                         WHERE (i_wizmode = g_no AND scvms.flg_status = g_slot_status_permanent)
                            OR (i_wizmode = g_yes AND
                               ((num_schedules_temp > 0 AND scvms.flg_status = g_slot_status_temporary AND
                               scvms.id_professional IS NOT NULL AND scvms.id_professional = i_prof.id) OR
                               (num_schedules_temp = 0 AND scvms.flg_status = g_slot_status_permanent))))
                 ORDER BY id_prof, dt_begin_tstz, id_physiatry_area;
        
            RETURN l_vacants;
        END inner_get_vacancies;
    
        -- Inner function to get schedules
        FUNCTION inner_get_schedules(i_list_schedules table_number) RETURN pk_types.cursor_type IS
            l_schedules pk_types.cursor_type;
            l_cv        sys_config.value%TYPE;
        BEGIN
            g_error := 'GET CONFIG VALUE FOR FLG_CANCEL_SCHEDULE';
            IF NOT pk_sysconfig.get_config(pk_schedule_common.g_flg_cancel_schedule, i_prof, l_cv)
            THEN
                ROLLBACK;
                RETURN NULL;
            END IF;
        
            g_error := 'OPEN l_schedules FOR';
            -- Open cursor
            OPEN l_schedules FOR
                SELECT id_schedule,
                       pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                       pk_date_utils.date_send_tsz(i_lang, dt_end_tstz, i_prof) dt_end,
                       id_patient,
                       pk_patient.get_gender(i_lang, gender) AS gender,
                       pk_patient.get_pat_age(i_lang, id_patient, i_prof) age,
                       decode(pk_patphoto.check_blob(id_patient),
                              g_no,
                              '',
                              pk_patphoto.get_pat_foto(id_patient, i_prof)) photo,
                       name,
                       pk_schedule.get_num_clin_record(t1.id_patient, i_args(pk_schedule.idx_id_inst)) num_clin_record,
                       CASE flg_status
                            WHEN pk_schedule.g_sched_status_temporary THEN
                             CASE
                                 WHEN id_sch_consult_vacancy IS NULL THEN
                                  pk_schedule.g_icon_prefix || g_icon_sch_temp_ol
                                 ELSE
                                  pk_schedule.g_icon_prefix ||
                                  get_schedule_conflicts(id_schedule, id_professional, dt_begin_tstz, dt_end_tstz)
                             END
                            ELSE
                             pk_schedule.g_icon_prefix ||
                             pk_sysdomain.get_img(i_lang,
                                                  pk_schedule.g_sched_flg_sch_status_domain,
                                                  flg_status || flg_vacancy)
                        END img_schedule,
                       pk_schedule.g_icon_prefix ||
                       pk_sysdomain.get_img(i_lang, pk_schedule.g_sched_flg_notif_status, flg_notification) img_notification,
                       flg_notification,
                       flg_status,
                       id_sch_consult_vacancy,
                       id_professional id_prof,
                       id_department id_dep,
                       id_sch_event,
                       id_dcs_requested id_dep_clin_serv,
                       pk_schedule.string_language(i_lang, id_lang_translator) desc_lang_translator,
                       pk_schedule.string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                       pk_schedule.string_department(i_lang, id_department) || ' (' ||
                       (SELECT pk_translation.get_translation(i_lang, code_dep_type)
                          FROM sch_dep_type
                         WHERE dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm) || ')' desc_department,
                       (SELECT pk_procedures_api_db.get_alias_translation(i_lang, i_prof, code_intervention, NULL)
                          FROM interv_presc_det ipd
                          JOIN intervention i
                            ON ipd.id_intervention = i.id_intervention
                         WHERE ipd.id_interv_presc_det = t1.id_interv_presc_det) desc_intervention,
                       pk_schedule_mfr.get_count_and_rank(i_lang, t1.id_schedule, i_wizmode) count_and_rank,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) nick_prof,
                       pk_schedule.has_permission(i_lang, i_prof, id_dcs_requested, id_sch_event, id_professional) has_permission,
                       pk_translation.get_translation(i_lang, code_physiatry_area) desc_phys_area,
                       id_physiatry_area,
                       pk_schedule.is_conflicting(id_schedule) flg_conflict,
                       l_cv flg_cancel_schedule,
                       id_interv_presc_det,
                       pk_schedule.string_sch_type(i_lang, t1.flg_sch_type) desc_sch_type
                  FROM (SELECT s.id_schedule,
                               s.dt_begin_tstz,
                               s.dt_end_tstz,
                               s.id_sch_event,
                               s.flg_status,
                               s.flg_vacancy,
                               s.flg_notification,
                               s.id_dcs_requested,
                               s.id_lang_translator,
                               s.id_sch_consult_vacancy,
                               dcs.id_department,
                               si.id_physiatry_area,
                               si.id_interv_presc_det,
                               si.rank,
                               pat.id_patient,
                               pat.gender,
                               pat.name,
                               sr.id_professional,
                               pa.code_physiatry_area,
                               s.flg_sch_type
                          FROM schedule s
                          JOIN dep_clin_serv dcs
                            ON s.id_dcs_requested = dcs.id_dep_clin_serv
                          JOIN schedule_intervention si
                            ON s.id_schedule = si.id_schedule
                          JOIN physiatry_area pa
                            ON si.id_physiatry_area = pa.id_physiatry_area
                          LEFT JOIN sch_resource sr
                            ON si.id_schedule = sr.id_schedule
                          LEFT JOIN sch_group sg
                            ON si.id_schedule = sg.id_schedule
                          LEFT JOIN patient pat
                            ON sg.id_patient = pat.id_patient
                         WHERE si.flg_original = g_yes
                           AND s.id_schedule IN (SELECT *
                                                   FROM TABLE(i_list_schedules))) t1
                 ORDER BY id_professional, dt_begin_tstz, id_dcs_requested, flg_status, flg_vacancy;
        
            RETURN l_schedules;
        END inner_get_schedules;
    
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        -- Get vacancies' identifiers using the selected criteria.
        g_error := 'CALL GET_VACANCIES';
        IF NOT get_vacancies(i_lang    => i_lang,
                             i_prof    => i_prof,
                             i_args    => i_args,
                             i_wizmode => i_wizmode,
                             o_error   => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_vacants);
            pk_types.open_my_cursor(o_schedules);
            RETURN FALSE;
        END IF;
    
        -- fetch additional info with our inner function
        g_error   := 'CALL INNER_GET_VACANCIES';
        o_vacants := inner_get_vacancies();
    
        -- Get schedules' identifiers using the selected criteria.
        g_error := 'CALL GET_SCHEDULES';
        IF NOT get_schedules(i_lang       => i_lang,
                             i_prof       => i_prof,
                             i_id_patient => NULL,
                             i_args       => i_args,
                             i_wizmode    => i_wizmode,
                             o_schedules  => l_list_schedules,
                             o_error      => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_schedules);
            RETURN FALSE;
        END IF;
    
        -- fetch additional info with our inner function
        g_error     := 'CALL INNER_GET_SCHEDULES';
        o_schedules := inner_get_schedules(i_list_schedules => l_list_schedules);
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_vacants);
                pk_types.open_my_cursor(o_schedules);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END;
    END get_hourly_detail;

    /*
    * get list of dep_clin_servs that are under the base clinical service
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional
    * @param o_dcs                output list
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.4
    * @date     24-11-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_base_dcs
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_BASE_DCS';
    BEGIN
        g_error := 'OPEN o_dcs';
        OPEN o_dcs FOR
            SELECT dcs.*
              FROM dep_clin_serv dcs
              JOIN department d
                ON dcs.id_department = d.id_department
             WHERE d.id_institution = i_prof.institution
               AND dcs.id_clinical_service = get_base_clin_serv(i_prof)
               AND dcs.flg_available = g_yes;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_dcs);
            
                RETURN FALSE;
            END;
    END get_base_dcs;

    /*
    * same as get_base_dcs but returns only the primary key id_dep_clin_serv
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional
    * @param o_id_dcs             output list
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.4
    * @date     24-11-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_base_id_dcs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_id_dcs OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PROF_BASE_ID_DCS';
    BEGIN
        g_error := 'OPEN o_id_dcs';
        SELECT dcs.id_dep_clin_serv
          BULK COLLECT
          INTO o_id_dcs
          FROM dep_clin_serv dcs
          JOIN department d
            ON dcs.id_department = d.id_department
         WHERE d.id_institution = i_prof.institution
           AND dcs.id_clinical_service = get_base_clin_serv(i_prof)
           AND dcs.flg_available = g_yes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_base_id_dcs;

    /*
    * get list of dep_clin_servs that are under the base clinical service AND that are connected to the professional.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional
    * @param o_dcs                output list
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.4
    * @date     24-11-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_prof_base_dcs
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PROF_BASE_DCS';
    BEGIN
        g_error := 'OPEN o_dcs';
        OPEN o_dcs FOR
            SELECT dcs.* --, pk_translation.get_translation(i_lang, cs.code_clinical_service)
              FROM clinical_service cs
              JOIN dep_clin_serv dcs
                ON cs.id_clinical_service = dcs.id_clinical_service
              JOIN department d
                ON dcs.id_department = d.id_department
              JOIN prof_dep_clin_serv pdcs
                ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
             WHERE d.id_institution = i_prof.institution
               AND pdcs.id_professional = i_prof.id
               AND pdcs.id_institution = i_prof.institution
               AND dcs.id_clinical_service = pk_schedule_mfr.get_base_clin_serv(i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_dcs);
            
                RETURN FALSE;
            END;
    END get_prof_base_dcs;

    /*
    * get list of dep_clin_servs that are under the base clinical service 
    * AND are connected to the professional
    * AND said professional has permission to schedule in such dep_clin_serv
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional
    * @param i_flg_schedule       Whether the departments should be filtered considering the professional's permission to schedule. needed 
    * @param o_dcs                output list
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.4
    * @date     24-11-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_prof_base_dcs_perm
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_schedule IN VARCHAR2,
        o_dcs          OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PROF_BASE_DCS_PERM';
        CURSOR c_dcs IS
            SELECT dcs.id_dep_clin_serv --, pk_translation.get_translation(i_lang, cs.code_clinical_service)
              FROM clinical_service cs
              JOIN dep_clin_serv dcs
                ON cs.id_clinical_service = dcs.id_clinical_service
              JOIN department d
                ON dcs.id_department = d.id_department
              JOIN prof_dep_clin_serv pdcs
                ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
              JOIN sch_permission sp
                ON dcs.id_dep_clin_serv = sp.id_dep_clin_serv
             WHERE d.id_institution = i_prof.institution
               AND pdcs.id_professional = i_prof.id
               AND pdcs.id_institution = i_prof.institution
               AND sp.id_institution = i_prof.institution
               AND sp.id_professional = i_prof.id
               AND sp.id_sch_event = pk_schedule.g_event_mfr
               AND sp.flg_permission <> pk_schedule.g_permission_none
               AND dcs.id_clinical_service = pk_schedule_mfr.get_base_clin_serv(i_prof);
    BEGIN
        g_error := 'OPEN c_dcs';
        OPEN c_dcs;
        g_error := 'FETCH c_dcs';
        FETCH c_dcs BULK COLLECT
            INTO o_dcs;
        g_error := 'CLOSE c_dcs';
        CLOSE c_dcs;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_prof_base_dcs_perm;

    /*
    * get list of physiatry areas that are under the base clinical service 
    * AND are connected to the professional. 
    *
    * @param i_lang                Language identifier
    * @param i_prof                Professional using the scheduler 
    * @param i_id_interv_presc_det if not null means the scheduler is being part of an intervention prescription workflow
    * @param i_deps                List of departments to restrain the output
    * @param i_flg_search          Whether or not should the 'All' option be included
    * @param o_error               Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.4
    * @date     25-11-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_physiatry_areas
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_deps                IN VARCHAR2,
        i_flg_search          IN VARCHAR2,
        o_physareas           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PHYSIATRY_AREAS';
    BEGIN
        -- open cursor
        g_error := 'GET PHYSIATRY AREAS WITH PRESCRIPTION DET ID';
    
        OPEN o_physareas FOR
            SELECT data, label, flg_select, order_field
              FROM (SELECT pk_schedule.g_all data,
                           pk_message.get_message(i_lang, pk_schedule.g_msg_all) label,
                           g_no flg_select,
                           1 order_field
                      FROM dual
                     WHERE i_flg_search = g_yes
                    UNION
                    SELECT ppa.id_physiatry_area,
                           pk_translation.get_translation(i_lang, pa.code_physiatry_area),
                           ppa.flg_default,
                           2
                      FROM prof_physiatry_area ppa
                      JOIN physiatry_area pa
                        ON ppa.id_physiatry_area = pa.id_physiatry_area
                     WHERE ppa.id_professional = i_prof.id
                       AND ppa.flg_available = g_yes)
             ORDER BY order_field, label ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_physiatry_areas;

    /*
    * Gets the list of professionals on whose schedules the logged professional has permission to read or schedule. 
    * Este get_professionals especifico da agenda mfr e' identificado pelo evento e pela inexistencia de dcs fornecidos como parametro.
    * Os dcs considerados sao todos os que pertencem ao 
    * clinical service configurado na sys_config com a chave MFR_CLIN_SERV. Esses dcs sao obtidos com a pk_schedule_mfr.get_base_dcs
    *
    * @param i_lang             Language identifier.
    * @param i_prof             Professional identifier.
    * @param i_id_dep           Department identifier.
    * @param i_id_clin_serv     Department-Clinical service identifier.
    * @param i_id_event         Event identifier.
    * @param i_flg_schedule     Whether or not should the events be filtered considering the professional's permission to schedule
    * @param i_phys_areas       list of physiatry areas that will also filter the professionals
    * @param o_professionals    List of processionals.
    * @param o_error            Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise
    *
    * @author  Telmo Castro
    * @date    25-11-2008
    * @version 2.4.4
    * @alteration JM 2009/03/10 Exception handling refactoring
    */

    FUNCTION get_professionals
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_dep        IN VARCHAR2,
        i_id_event      IN VARCHAR2,
        i_flg_schedule  IN VARCHAR2,
        i_phys_areas    IN VARCHAR2,
        o_professionals OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_PROFESSIONALS';
        l_list_event   table_number;
        l_list_dcs     table_number := table_number();
        l_list_phareas table_number;
        l_count        NUMBER;
        l_self_count   NUMBER;
        l_flg_schedule VARCHAR2(1);
        i              INTEGER;
        l_exist_ev_mfr BOOLEAN := FALSE;
        l_rsdcs        pk_types.cursor_type;
        l_rowdcs       dep_clin_serv%ROWTYPE;
    BEGIN
        -- Get lists
        g_error        := 'GET LISTS';
        l_list_event   := pk_schedule.get_list_number_csv(i_id_event);
        l_list_phareas := pk_schedule.get_list_number_csv(i_phys_areas);
    
        IF i_flg_schedule IS NULL
        THEN
            l_flg_schedule := g_no;
        ELSE
            l_flg_schedule := i_flg_schedule;
        END IF;
    
        g_error := 'SELF COUNT';
        -- Check for self permissions
        SELECT COUNT(1)
          INTO l_self_count
          FROM sch_permission sp, sch_event se
         WHERE sp.id_institution = i_prof.institution
           AND sp.flg_permission <> pk_schedule.g_permission_none
           AND se.id_sch_event = sp.id_sch_event
           AND se.id_sch_event IN (SELECT *
                                     FROM TABLE(l_list_event))
           AND se.flg_target_professional = g_yes
           AND sp.id_prof_agenda = i_prof.id;
    
        -- procurar pelo evento mfr
        g_error := 'search mfr event';
        i       := l_list_event.first;
        WHILE i IS NOT NULL
              AND NOT l_exist_ev_mfr
        LOOP
            l_exist_ev_mfr := l_list_event(i) = pk_schedule.g_event_mfr;
            i              := l_list_event.next(i);
        END LOOP;
    
        -- se veio esse evento vamos pegar os dcs e junta-los na l_list_dcs
        IF l_exist_ev_mfr
        THEN
            IF NOT get_base_dcs(i_lang => i_lang, i_prof => i_prof, o_dcs => l_rsdcs, o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- iterar e appendar
            g_error := 'append dcs';
            LOOP
                FETCH l_rsdcs
                    INTO l_rowdcs;
                EXIT WHEN l_rsdcs%NOTFOUND;
                l_list_dcs.extend;
                l_list_dcs(l_list_dcs.last) := l_rowdcs.id_dep_clin_serv;
            END LOOP;
            CLOSE l_rsdcs;
        END IF;
    
        -- Count the professionals
        g_error := 'COUNT';
        SELECT COUNT(1)
          INTO l_count
          FROM sch_permission sp
          JOIN sch_event se
            ON sp.id_sch_event = se.id_sch_event
          JOIN prof_physiatry_area ppa
            ON sp.id_professional = ppa.id_professional
         WHERE sp.id_institution = i_prof.institution
           AND sp.id_professional = i_prof.id
           AND sp.flg_permission <> pk_schedule.g_permission_none
           AND se.id_sch_event = sp.id_sch_event
           AND se.id_sch_event IN (SELECT *
                                     FROM TABLE(l_list_event))
           AND se.flg_target_professional = g_yes
           AND (sp.flg_permission = pk_schedule.g_permission_schedule OR l_flg_schedule = g_no)
           AND sp.id_dep_clin_serv IN (SELECT *
                                         FROM TABLE(l_list_dcs))
           AND ppa.id_physiatry_area IN (SELECT *
                                           FROM TABLE(l_list_phareas))
           AND ppa.flg_available = g_yes
           AND rownum <= 1;
        IF (l_count > 0)
        THEN
            g_error := 'OPEN o_professionals FOR';
            OPEN o_professionals FOR
                SELECT data, label, flg_select, order_field
                  FROM (SELECT pk_schedule.g_all data,
                               pk_message.get_message(i_lang, pk_schedule.g_msg_all) label,
                               decode(l_self_count, 0, g_yes, g_no) flg_select,
                               1 order_field
                          FROM dual
                        UNION
                        SELECT sp.id_prof_agenda data,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, sp.id_prof_agenda) label,
                               decode(sp.id_prof_agenda, i_prof.id, g_yes, g_no) flg_select,
                               9 order_field
                          FROM sch_permission sp
                          JOIN sch_event se
                            ON sp.id_sch_event = se.id_sch_event
                          JOIN prof_physiatry_area ppa
                            ON sp.id_professional = ppa.id_professional
                         WHERE sp.id_institution = i_prof.institution
                           AND sp.id_professional = i_prof.id
                           AND sp.flg_permission <> pk_schedule.g_permission_none
                           AND se.id_sch_event IN (SELECT *
                                                     FROM TABLE(l_list_event))
                           AND se.flg_target_professional = g_yes
                           AND (sp.flg_permission = pk_schedule.g_permission_schedule OR l_flg_schedule = g_no)
                           AND sp.id_dep_clin_serv IN (SELECT *
                                                         FROM TABLE(l_list_dcs))
                           AND ppa.id_physiatry_area IN (SELECT *
                                                           FROM TABLE(l_list_phareas))
                           AND ppa.flg_available = g_yes)
                 ORDER BY order_field, label ASC;
        ELSE
            -- Avoid having 'All' as the only option.
            pk_types.open_my_cursor(o_professionals);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_professionals);
            
                RETURN FALSE;
            END;
    END get_professionals;

    /**
    * This function returns the availability for each day on a given period.
    * Each day can be fully scheduled, half scheduled or empty.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                Arguments.
    * @param i_id_patient          Patient.
    * @param i_semester            Whether or not this function is being called to fill the semester calendar.
    * @param i_wizmode             wizard mode. Means that i_prof is solving conflicts in a mfr prescription. So temporary 
    * @param o_days_status         List of status per date.
    * @param o_days_date           List of dates.
    * @param o_days_free           List of total free slots per date
    * @param o_days_sched          List of total schedules per date.
    * @param o_days_conflicts      List of total conflicting appointments per date.
    * @param o_days_tempor         List of flags per date indicating the existence of temporary schedules. Y(tem) | N(nao tem) | S(tem com sobreposicao)
    * @param o_patient_icons       Patient icons for showing the days when the patient has schedules.
    * @param o_error               Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    *
    * @author   Telmo
    * @version  2.4.4
    * @date     02-12-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_availability
    (
        i_lang           IN language.id_language%TYPE DEFAULT NULL,
        i_prof           IN profissional,
        i_args           IN table_varchar,
        i_id_patient     IN patient.id_patient%TYPE,
        i_wizmode        IN VARCHAR2 DEFAULT 'N',
        i_semester       IN VARCHAR2,
        o_days_status    OUT table_varchar,
        o_days_date      OUT table_varchar,
        o_days_free      OUT table_number,
        o_days_sched     OUT table_number,
        o_days_conflicts OUT table_number,
        o_days_tempor    OUT table_varchar,
        o_patient_icons  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'GET_AVAILABILITY';
        l_use_colors      sys_config.value%TYPE;
        l_max_colors      sys_config.value%TYPE;
        l_schedules       table_number;
        l_dates           table_timestamp_tz := table_timestamp_tz();
        l_dates_str       table_varchar := table_varchar();
        l_pos             NUMBER := 0;
        l_start_date_aux  DATE;
        l_start_date_orig TIMESTAMP WITH TIME ZONE;
        l_start_date      TIMESTAMP WITH TIME ZONE;
        l_end_date        TIMESTAMP WITH TIME ZONE;
        c                 NUMBER;
    
        -- Available Vacancies and booked schedules. (Semester version)
        -- importante - manter a ordem dos when
        CURSOR c_vacants_semester IS
            SELECT pk_date_utils.date_send_tsz(i_lang, dt_begin_trunc, i_prof) dt_begin,
                   CASE
                        WHEN i_wizmode = g_no
                             AND schedp = 0
                             AND slotsp > 0 THEN
                         pk_schedule.g_day_status_empty
                        WHEN i_wizmode = g_no
                             AND schedp > 0
                             AND slotsp > 0 THEN
                         pk_schedule.g_day_status_half
                        WHEN i_wizmode = g_no
                             AND schedp > 0
                             AND slotsp = 0 THEN
                         pk_schedule.g_day_status_full
                    -- wizard mode = ON. Preferi separar para ficar mais legivel
                        WHEN i_wizmode = g_yes
                             AND schedp + schedt = 0
                             AND slotsp > 0 THEN
                         pk_schedule.g_day_status_empty
                        WHEN i_wizmode = g_yes
                             AND schedp + schedt > 0
                             AND slotst > 0 THEN
                         pk_schedule.g_day_status_half
                        WHEN i_wizmode = g_yes
                             AND schedp + schedt > 0
                             AND slotst = 0
                             AND schedt > 0 THEN
                         pk_schedule.g_day_status_full
                        WHEN i_wizmode = g_yes
                             AND schedp > 0
                             AND slotsp > 0 THEN
                         pk_schedule.g_day_status_half
                        WHEN i_wizmode = g_yes
                             AND schedp > 0
                             AND slotsp = 0 THEN
                         pk_schedule.g_day_status_full
                        ELSE
                         pk_schedule.g_day_status_void
                    END status,
                   CASE
                        WHEN i_wizmode = g_yes
                             AND schedt > 0 THEN
                         pk_schedule.g_mfr_icon_no_conflict
                        ELSE
                         g_no
                    END temps
              FROM (SELECT m.dt_begin_trunc,
                           SUM(m.num_schedules_perm) schedp,
                           SUM(m.num_slots_perm) slotsp,
                           SUM(m.num_schedules_temp) schedt,
                           SUM(m.num_slots_temp) slotst
                      FROM sch_tmptab_vacs_mfr m
                     GROUP BY m.dt_begin_trunc)
             ORDER BY dt_begin;
    
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_VACANCIES';
        -- Get vacancies that match the given criteria
        IF NOT get_vacancies(i_lang    => i_lang,
                             i_prof    => i_prof,
                             i_args    => i_args,
                             i_wizmode => i_wizmode,
                             o_error   => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_patient_icons);
            RETURN FALSE;
        END IF;
    
        -- CALENDARIO MENSAL PRINCIPAL
        IF i_semester = g_no
        THEN
            -- Get start date
            g_error := 'GET TRUNCATED START DATE';
            IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => i_args(pk_schedule.idx_dt_begin),
                                                       o_timestamp => l_start_date,
                                                       o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                pk_types.open_my_cursor(o_patient_icons);
                RETURN FALSE;
            END IF;
        
            l_start_date_orig := l_start_date;
        
            g_error := 'GET TRUNCATED END DATE';
            -- Get end date
            IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => i_args(pk_schedule.idx_dt_end),
                                                       o_timestamp => l_end_date,
                                                       o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                pk_types.open_my_cursor(o_patient_icons);
                RETURN FALSE;
            END IF;
        
            -- Use dates to generate string representations
            l_start_date_aux := CAST(l_start_date AS DATE);
        
            -- Generate all the dates between start and end dates
            -- 0.5 is used as tolerance due to DST changes.
            g_error := 'GENERATE DATES';
            WHILE (pk_date_utils.get_timestamp_diff(l_end_date, l_start_date) > 0.5)
            LOOP
                l_dates.extend;
                l_dates_str.extend;
                l_pos := l_pos + 1;
                l_dates(l_pos) := l_start_date;
                l_dates_str(l_pos) := pk_date_utils.date_send(i_lang, l_start_date_aux, i_prof);
                l_start_date := pk_date_utils.add_days_to_tstz(l_start_date, 1);
                l_start_date_aux := l_start_date_aux + 1;
            END LOOP;
        
            -- Get schedules' identifiers using the selected criteria.
            g_error := 'CALL GET_SCHEDULES';
            IF NOT get_schedules(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_id_patient => NULL,
                                 i_args       => i_args,
                                 i_wizmode    => i_wizmode,
                                 o_schedules  => l_schedules,
                                 o_error      => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                pk_types.open_my_cursor(o_patient_icons);
                RETURN FALSE;
            END IF;
        
            -- Calculate month availability
            g_error := 'CALL CALCULATE_MONTH_AVAILABILITY';
            IF NOT calculate_month_availability(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_mult           => FALSE,
                                                i_wizmode        => i_wizmode,
                                                i_list_schedules => l_schedules,
                                                i_list_dates     => l_dates,
                                                i_list_dates_str => l_dates_str,
                                                o_days_date      => o_days_date,
                                                o_days_status    => o_days_status,
                                                o_days_free      => o_days_free,
                                                o_days_sched     => o_days_sched,
                                                o_days_conflicts => o_days_conflicts,
                                                o_days_tempor    => o_days_tempor,
                                                o_error          => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                pk_types.open_my_cursor(o_patient_icons);
                RETURN FALSE;
            END IF;
        
        ELSE
            -- CALENDARIO SEMESTRAL
            -- fill up o_days_date, o_Days_status and o_days_tempor at vonce
            g_error := 'OPEN c_vacants_semester';
            OPEN c_vacants_semester;
            g_error := 'FETCH c_vacants_semester';
            FETCH c_vacants_semester BULK COLLECT
                INTO o_days_date, o_days_status, o_days_tempor;
            g_error := 'CLOSE c_vacants_semester';
            CLOSE c_vacants_semester;
        END IF;
    
        -- Get patient icons. comum
        g_error := 'CALL GET_PATIENT_ICONS';
        IF NOT (pk_schedule.get_patient_icons(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_args          => i_args,
                                              i_id_patient    => i_id_patient,
                                              o_patient_icons => o_patient_icons,
                                              o_error         => o_error))
        THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_patient_icons);
            RETURN FALSE;
        END IF;
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_patient_icons);
                pk_date_utils.set_dst_time_check_on;
            
                RETURN FALSE;
            END;
    END get_availability;

    /*
    * Gets the estimated duration for a intervention in minutes.
    *
    * @param   i_lang                       Language identifier.
    * @param   i_prof                       Professional.
    * @param   i_id_interv                  Intervention ID
    * @param   o_duration                   Estimated duration of the intervention in minutes
    * @param   o_error                      Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Jose Antunes
    * @version 2.4.4
    * @since 2008/11/21
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_interv_time
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_interv IN intervention_times.id_intervention%TYPE,
        o_duration  OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_INTERV_TIME';
    BEGIN
        o_duration := 0;
    
        g_error := 'SELECT intervention_times';
    
        SELECT default_duration
          INTO o_duration
          FROM intervention_times it
         WHERE it.id_intervention = i_id_interv
           AND it.flg_available = g_yes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_duration := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_interv_time;

    /*
        * Creates mfr schedule.
        *
        * @param i_lang               Language
        * @param i_prof               Professional who is doing the scheduling
        * @param i_id_patient         Patient id
        * @param i_id_dep_clin_serv   If null, it will be calculated inside based on configuration
        * @param i_id_sch_event       Event type
        * @param i_id_prof            Professional schedule target
        * @param i_dt_begin           Schedule begin date
        * @param i_dt_end             Schedule end date
        * @param i_flg_vacancy        Vacancy flag
        * @param i_schedule_notes     Notes
        * @param i_id_lang_translator Translator's language
        * @param i_id_lang_preferred  Preferred language
        * @param i_id_reason          Appointment reason
        * @param i_id_origin          Patient origin
        * @param i_id_room            Room
        * @param i_id_schedule_ref    old schedule id. Used if this function is called by update_schedule
        * @param i_id_episode         Episode id
        * @param i_reason_notes       Reason for appointment in free-text.
        * @param i_flg_request_type   tipo de pedido
        * @param i_flg_schedule_via   meio do pedido marcacao
        * @param i_id_interv_presc_det prescription id
        * @param i_id_sch_recursion   recursion id. Its the id of the recursion plan generated previously based on user choices
        * @param i_id_phys_area       physiatry area id
        * @param i_wizmode            Y= wizard mode means that schedules created in this mode must be temporary. N= standard mode
        * @param i_id_slot            slot id or null. If not null then its normal scheduling or unplanned. If null then its a fora do horario normal.
                                      Must be a permanent slot. 
        * @param o_id_schedule        Newly generated schedule id 
        * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
        * @param o_flg_show           Set if a message is displayed or not      
        * @param o_msg                Message body to be displayed in flash
        * @param o_msg_title          Message title
        * @param o_button             Buttons to show.
        * @param o_overlapfound       an overlap was found while trying to save this schedule and no instruction was given on how to decide
        * @param o_error              Error message if something goes wrong
        *
        * @author   Telmo Castro
        * @version  2.4.4
        * @date     19-12-2008
        * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION create_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv    IN schedule.id_dcs_requested%TYPE DEFAULT NULL,
        i_id_sch_event        IN schedule.id_sch_event%TYPE,
        i_id_prof             IN sch_resource.id_professional%TYPE,
        i_dt_begin            IN VARCHAR2,
        i_dt_end              IN VARCHAR2,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_schedule_notes      IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator  IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred   IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason           IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin           IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room             IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_schedule_ref     IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_episode          IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes        IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type    IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via    IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_id_interv_presc_det IN schedule_intervention.id_interv_presc_det%TYPE, --NEW
        i_id_sch_recursion    IN schedule.id_schedule_recursion%TYPE DEFAULT NULL, --NEW
        i_id_phys_area        IN schedule_intervention.id_physiatry_area%TYPE, --NEW
        i_wizmode             IN VARCHAR2 DEFAULT 'N', --NEW
        i_id_slot             IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE DEFAULT NULL, --NEW
        --        i_do_overlap          IN VARCHAR2, -- NOT USED
        --        i_sch_option          IN VARCHAR2, -- NOT USED
        i_id_complaint IN complaint.id_complaint%TYPE DEFAULT NULL,
        o_id_schedule  OUT schedule.id_schedule%TYPE,
        o_flg_proceed  OUT VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := 'CREATE_SCHEDULE';
        l_dt_begin         TIMESTAMP WITH TIME ZONE;
        l_dt_end           TIMESTAMP WITH TIME ZONE;
        l_hasperm          VARCHAR2(10);
        l_base_dcs         table_number;
        l_id_dep_clin_serv schedule.id_dcs_requested%TYPE := i_id_dep_clin_serv;
        l_id_dept          dep_clin_serv.id_department%TYPE;
        l_flg_sch_type     sch_event.dep_type%TYPE;
        l_vacancy_usage    BOOLEAN;
        l_sched_w_vac      BOOLEAN;
        l_edit_vac         BOOLEAN;
        l_slot             sch_consult_vac_mfr_slot%ROWTYPE;
        l_flg_vacancy      schedule.flg_vacancy%TYPE := i_flg_vacancy;
        l_overlap          VARCHAR2(1);
        l_flg_status       schedule.flg_status%TYPE;
        l_dummy            sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_vacancy_needed EXCEPTION;
        l_no_permission  EXCEPTION;
        l_no_vac_usage   EXCEPTION;
        l_id_sch_interv schedule_intervention.id_schedule_intervention%TYPE;
    
        -- function to get a suitable dcs for the given data. Remember, in MFR scheduler the dcs is just a nuissance that we must bear
        FUNCTION inner_get_dcs_for_prof
        (
            o_id_dep_clin_serv OUT schedule.id_dcs_requested%TYPE,
            o_id_dept          OUT dep_clin_serv.id_department%TYPE
        ) RETURN BOOLEAN IS
            l_func_name VARCHAR2(32) := 'INNER_GET_DCS_FOR_PROF';
        BEGIN
            -- choose first dcs from list for which both the scheduling and target professionals have permission to schedule
            SELECT sp.id_dep_clin_serv, id_department
              INTO o_id_dep_clin_serv, o_id_dept
              FROM sch_permission sp
              JOIN dep_clin_serv dcs
                ON sp.id_dep_clin_serv = dcs.id_dep_clin_serv
             WHERE sp.id_institution = i_prof.institution
               AND sp.id_professional = i_prof.id
               AND sp.id_prof_agenda = i_id_prof
               AND sp.id_sch_event = i_id_sch_event
               AND sp.flg_permission = pk_schedule.g_permission_schedule
               AND EXISTS (SELECT 1
                      FROM TABLE(l_base_dcs)
                     WHERE column_value = sp.id_dep_clin_serv)
               AND rownum = 1;
            RETURN TRUE;
        END inner_get_dcs_for_prof;
    
        -- get slot data if a suitable one is found. If a slot id is given, try to fetch such slot data but still complying with all
        -- other conditions.
        -- If theres no slot id, or there is but no compliance was achieved, try to find a another slot
        FUNCTION inner_get_slot_data
        (
            i_lang     IN language.id_language%TYPE,
            i_dt_begin IN sch_consult_vac_mfr_slot.dt_begin_tstz%TYPE,
            i_dt_end   IN sch_consult_vac_mfr_slot.dt_end_tstz%TYPE,
            i_id_slot  IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE,
            o_slot     OUT sch_consult_vac_mfr_slot%ROWTYPE,
            o_error    OUT t_error_out
        ) RETURN BOOLEAN IS
            l_func_name VARCHAR2(32) := 'INNER_GET_SLOT_DATA';
        BEGIN
            g_error := 'THE QUEST FOR A SLOT';
        
            IF i_id_slot IS NOT NULL
            THEN
                BEGIN
                    SELECT scvms.*
                      INTO o_slot
                      FROM sch_consult_vacancy scv
                      JOIN sch_consult_vac_mfr_slot scvms
                        ON scv.id_sch_consult_vacancy = scvms.id_sch_consult_vacancy
                     WHERE scv.id_institution = i_prof.institution
                       AND scvms.id_sch_consult_vac_mfr_slot = i_id_slot
                       AND ((i_id_prof IS NOT NULL AND scv.id_prof = i_id_prof) OR scv.id_prof IS NULL)
                       AND scv.id_sch_event = i_id_sch_event
                       AND EXISTS (SELECT 1
                              FROM TABLE(l_base_dcs)
                             WHERE column_value = scv.id_dep_clin_serv)
                       AND scvms.id_physiatry_area = i_id_phys_area
                       AND scvms.flg_status = g_slot_status_permanent
                       AND scvms.dt_begin_tstz <= i_dt_begin
                          -- esta condicao abaixo pode vir a desaparecer para tornar esta quest mais flexivel.
                          -- nesse caso deve aparecer outra do tipo AND scvms.dt_begin_tstz > i_dt_begin_tstz
                       AND scvms.dt_end_tstz >= i_dt_end
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
            IF o_slot.id_sch_consult_vacancy IS NULL
            THEN
                SELECT scvms.*
                  INTO o_slot
                  FROM sch_consult_vacancy scv
                  JOIN sch_consult_vac_mfr_slot scvms
                    ON scv.id_sch_consult_vacancy = scvms.id_sch_consult_vacancy
                 WHERE scv.id_institution = i_prof.institution
                   AND ((i_id_prof IS NOT NULL AND scv.id_prof = i_id_prof) OR scv.id_prof IS NULL)
                   AND scv.id_sch_event = i_id_sch_event
                   AND EXISTS (SELECT 1
                          FROM TABLE(l_base_dcs)
                         WHERE column_value = scv.id_dep_clin_serv)
                   AND scvms.id_physiatry_area = i_id_phys_area
                   AND scvms.flg_status = g_slot_status_permanent
                   AND scvms.dt_begin_tstz <= i_dt_begin
                      -- esta condicao abaixo pode vir a desaparecer para tornar esta quest mais flexivel.
                      -- nesse caso deve aparecer outra do tipo AND scvms.dt_begin_tstz > i_dt_begin_tstz
                   AND scvms.dt_end_tstz >= i_dt_end
                   AND rownum = 1;
            END IF;
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                o_slot.id_sch_consult_vacancy := NULL;
                RETURN TRUE;
            WHEN OTHERS THEN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => 'ALERT',
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
                RETURN FALSE;
        END inner_get_slot_data;
    
    BEGIN
    
        -- load available dcs
        g_error := 'GET POSSIBLE DCS';
        IF NOT get_base_id_dcs(i_lang, i_prof, l_base_dcs, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- obter 1 id_dep_clin_serv valido mesmo que tenha sido fornecido porque preciso sempre do l_id_dept
        g_error := 'GET DEP_CLIN_SERV';
        --        IF l_id_dep_clin_serv IS NULL
        --        THEN
        IF NOT inner_get_dcs_for_prof(l_id_dep_clin_serv, l_id_dept)
        THEN
            RETURN FALSE;
        END IF;
        --        END IF;
        -- check for permission to schedule for this dep_clin_serv, event and professional
        g_error   := 'CHECK PERMISSION TO SCHEDULE';
        l_hasperm := pk_schedule.has_permission(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_id_dep_clin_serv => l_id_dep_clin_serv,
                                                i_id_sch_event     => i_id_sch_event,
                                                i_id_prof          => i_id_prof);
        IF l_hasperm = pk_schedule.g_msg_false
        THEN
            RAISE l_no_permission;
        END IF;
    
        -- calcular o flg_sch_type
        g_error := 'CALC DEP_TYPE';
        SELECT dep_type
          INTO l_flg_sch_type
          FROM sch_event se
         WHERE se.id_sch_event = i_id_sch_event;
    
        -- Obter config geral das vagas
        g_error := 'CALL CHECK_VACANCY_USAGE';
        IF NOT pk_schedule_common.check_vacancy_usage(i_lang,
                                                      i_prof.institution,
                                                      i_prof.software,
                                                      l_id_dept,
                                                      l_flg_sch_type,
                                                      l_vacancy_usage,
                                                      l_sched_w_vac,
                                                      l_edit_vac,
                                                      o_error)
        THEN
            -- se nao encontrou na vacancy_usage deve sair daqui com elegancia
            IF abs(o_error.ora_sqlcode) IN (100, 1403)
            THEN
                RAISE l_no_vac_usage;
            ELSE
                RETURN FALSE;
            END IF;
        END IF;
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- independent check for a slot. Here we try to find an adequate slot without caring to the one given by i_id_slot
        g_error := 'CALL INNER_GET_SLOT_DATA';
        IF NOT inner_get_slot_data(i_lang     => i_lang,
                                   i_dt_begin => l_dt_begin,
                                   i_dt_end   => l_dt_end,
                                   i_id_slot  => i_id_slot,
                                   o_slot     => l_slot,
                                   o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- if no slot was found and there is no permission to schedule without vacancy pull all stops
        IF l_slot.id_sch_consult_vacancy IS NULL
           AND NOT l_sched_w_vac
        THEN
            RAISE l_vacancy_needed;
        END IF;
    
        -- calculo do real valor da flg_vacancy
        IF l_flg_vacancy = pk_schedule_common.g_sched_vacancy_routine
           AND l_slot.id_sch_consult_vacancy IS NULL
           AND l_sched_w_vac
        --           AND l_overlap = g_yes
        THEN
            l_flg_vacancy := pk_schedule_common.g_sched_vacancy_unplanned;
        END IF;
    
        -- calculo do status
        IF i_wizmode = g_yes
        THEN
            l_flg_status := pk_schedule.g_sched_status_temporary;
        ELSE
            l_flg_status := pk_schedule.g_sched_status_scheduled;
        END IF;
    
        -- Create the schedule
        g_error := 'CALL PK_SCHEDULE_COMMON.CREATE_SCHEDULE';
        IF NOT pk_schedule_common.create_schedule(i_lang               => i_lang,
                                                  i_id_prof_schedules  => i_prof.id,
                                                  i_id_institution     => i_prof.institution,
                                                  i_id_software        => i_prof.software,
                                                  i_id_patient         => table_number(i_id_patient),
                                                  i_id_dep_clin_serv   => l_id_dep_clin_serv,
                                                  i_id_sch_event       => i_id_sch_event,
                                                  i_id_prof            => i_id_prof,
                                                  i_dt_begin           => l_dt_begin,
                                                  i_dt_end             => l_dt_end,
                                                  i_flg_vacancy        => l_flg_vacancy,
                                                  i_flg_status         => l_flg_status,
                                                  i_schedule_notes     => i_schedule_notes,
                                                  i_id_lang_translator => i_id_lang_translator,
                                                  i_id_lang_preferred  => i_id_lang_preferred,
                                                  i_id_reason          => i_id_reason,
                                                  i_id_origin          => i_id_origin,
                                                  i_id_schedule_ref    => i_id_schedule_ref,
                                                  i_id_room            => i_id_room,
                                                  i_flg_sch_type       => l_flg_sch_type,
                                                  i_reason_notes       => i_reason_notes,
                                                  i_flg_request_type   => i_flg_request_type,
                                                  i_flg_schedule_via   => i_flg_schedule_via,
                                                  i_id_consult_vac     => l_slot.id_sch_consult_vacancy,
                                                  o_id_schedule        => o_id_schedule,
                                                  o_occupied           => l_dummy,
                                                  i_ignore_vacancies   => FALSE,
                                                  i_id_episode         => i_id_episode,
                                                  i_id_complaint       => i_id_complaint,
                                                  i_id_sch_recursion   => i_id_sch_recursion,
                                                  o_error              => o_error)
        THEN
            -- Restore state
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- create row in schedule_intervention
        g_error := 'CALL INS_SCHEDULE_INTERVENTION';
        IF NOT ins_schedule_intervention(i_lang                       => i_lang,
                                         id_schedule_intervention_in  => NULL,
                                         id_schedule_in               => o_id_schedule,
                                         id_interv_presc_det_in       => i_id_interv_presc_det,
                                         id_prof_assigned_in          => i_id_prof,
                                         flg_state_in                 => 'A',
                                         rank_in                      => NULL,
                                         id_physiatry_area_in         => i_id_phys_area,
                                         flg_original_in              => g_yes,
                                         id_schedule_intervention_out => l_id_sch_interv,
                                         o_error                      => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- rebuild slots
        g_error := 'CALL CREATE_SLOTS';
        IF l_slot.id_sch_consult_vacancy IS NOT NULL
           AND NOT create_slots(i_lang                   => i_lang,
                                i_prof                   => i_prof,
                                i_id_sch_consult_vacancy => l_slot.id_sch_consult_vacancy,
                                i_flg_wizard             => i_wizmode,
                                i_id_physiatry_area      => i_id_phys_area,
                                o_error                  => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_no_permission THEN
            o_msg_title   := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_no_permission);
            o_button      := pk_schedule.g_check_button;
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            ROLLBACK;
            RETURN TRUE;
        
        WHEN l_vacancy_needed THEN
            o_msg_title   := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_vacancyneeded);
            o_button      := pk_schedule.g_cancel_button_code ||
                             pk_message.get_message(i_lang, pk_schedule.g_sched_msg_goback) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            ROLLBACK;
            RETURN TRUE;
        
        WHEN l_no_vac_usage THEN
            o_msg_title   := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_no_vac_usage);
            o_button      := pk_schedule.g_cancel_button_code ||
                             pk_message.get_message(i_lang, pk_schedule.g_sched_msg_goback) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END create_schedule;

    /*
     * reschedule a session, whether its permanent or temporary. 
     * this operation allows changes in the begin/end dates and target professional. 
     * If permanent, the current schedule is cancelled and a new one created. Column id_schedule_ref in the new 
     * record retains link to ancient schedule.
     * If temporary, the old schedule is deleted and a new one created. Also temporary.
     *
     * @param i_lang                   Language identifier
     * @param i_prof                   Professional who is rescheduling
     * @param i_old_id_schedule        Identifier of the appointment to be rescheduled
     * @param i_id_prof                new target professional
     * @param i_dt_begin               new start date
     * @param i_dt_end                 new end date
     * @param i_wizmode                Y= wizard mode  N= standard mode
     * @param i_id_slot                slot id of the new home for this schedule, if one was picked
     * @param o_id_schedule            Identifier of the new schedule.
     * @param o_flg_show               Set to 'Y' if there is a message to show.
     * @param o_msg                    Message body.
     * @param o_msg_title              Message title.
     * @param o_button                 Buttons to show.
     * @param o_error                  Error message if something goes wrong
     *
     * @return   TRUE if process is ok, FALSE otherwise
     *
     * @author  Telmo
     * @date     06-01-2009
     * @version 2.4.4
     * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION create_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_id_prof         IN professional.id_professional%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_wizmode         IN VARCHAR2,
        i_id_slot         IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE DEFAULT NULL,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_flg_proceed     OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(19) := 'CREATE_RESCHEDULE';
        l_schedule_cancel_notes schedule.schedule_notes%TYPE;
        l_tokens                table_varchar;
        l_replacements          table_varchar;
        l_message               sys_message.desc_message%TYPE;
        l_dt_begin              TIMESTAMP WITH TIME ZONE;
        l_dt_end                TIMESTAMP WITH TIME ZONE;
        l_sysdate               TIMESTAMP WITH TIME ZONE := current_timestamp;
        l_flg_vacancy           schedule.flg_vacancy%TYPE := pk_schedule_common.g_sched_vacancy_routine;
        -- l_transaction_id        VARCHAR2(4000); --SCH 3.0 DO NOT REMOVE
        -- l_func_exception EXCEPTION;
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule,
                   sg.id_patient,
                   s.id_instit_requested,
                   s.id_dcs_requested,
                   s.id_sch_event,
                   sr.id_professional,
                   --                   s.dt_begin_tstz,
                   --                   s.dt_end_tstz,
                   s.flg_vacancy,
                   s.schedule_notes,
                   s.id_lang_translator,
                   s.id_lang_preferred,
                   s.id_reason,
                   s.reason_notes,
                   s.id_origin,
                   s.id_room,
                   --                   s.flg_sch_type,
                   s.flg_schedule_via,
                   s.flg_request_type,
                   s.id_episode,
                   s.flg_status,
                   s.id_schedule_recursion,
                   si.id_physiatry_area,
                   si.id_interv_presc_det
              FROM schedule s
              LEFT JOIN sch_resource sr
                ON s.id_schedule = sr.id_schedule
              LEFT JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              LEFT JOIN schedule_intervention si
                ON s.id_schedule = si.id_schedule
             WHERE s.id_schedule = c_sched.i_old_id_schedule
               AND si.flg_original = g_yes;
    
        l_sched_rec c_sched%ROWTYPE;
    
        -- Returns a record containing the old schedule's data
        FUNCTION inner_get_old_schedule(i_old_id_schedule schedule.id_schedule%TYPE) RETURN c_sched%ROWTYPE IS
            l_ret c_sched%ROWTYPE;
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(inner_get_old_schedule.i_old_id_schedule);
            g_error := 'FETCH c_sched';
            FETCH c_sched
                INTO l_ret;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
            RETURN l_ret;
        END inner_get_old_schedule;
    
    BEGIN
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR dt_begin';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- Convert current date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR sysdate';
        IF NOT pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                        i_inst      => i_prof.institution,
                                                        i_timestamp => l_sysdate,
                                                        o_timestamp => l_sysdate,
                                                        o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --        IF i_wizmode = g_no
        --        THEN
        -- Set tokens to replace
        g_error  := 'BUILD CANCEL NOTES MESSAGE';
        l_tokens := table_varchar('@1', '@2');
        -- Set replacements
        l_replacements := table_varchar(pk_schedule.string_date_hm(i_lang, i_prof, l_sysdate),
                                        pk_schedule.string_date_hm(i_lang, i_prof, l_dt_begin));
        -- Get cancel notes message
        l_message := pk_schedule.get_message(i_lang => i_lang, i_message => pk_schedule.g_rescheduled_from_to);
        -- Replace tokens
        IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                          i_string       => l_message,
                                          i_tokens       => l_tokens,
                                          i_replacements => l_replacements,
                                          o_string       => l_schedule_cancel_notes,
                                          o_error        => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --        END IF;
    
        -- Get old schedule. Must be done before cancel_schedule
        g_error     := 'GET OLD SCHEDULE';
        l_sched_rec := inner_get_old_schedule(i_old_id_schedule);
    
        -- Cancel schedule. If temporary, it is deleted. If permanent, its status is updated. 
        -- In both cases, slots are recalculated only if this schedule was attached to a vacancy.
        IF NOT cancel_schedule(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_schedule      => i_old_id_schedule,
                               i_id_cancel_reason => NULL,
                               i_cancel_notes     => l_schedule_cancel_notes,
                               --  i_transaction_id   => l_transaction_id, --SCH 3.0 DO NOT REMOVE
                               o_error => o_error)
        THEN
            -- RAISE l_func_exception; --SCH 3.0 DO NOT REMOVE
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- Try to reschedule unplanned appointments as routine, if there are vacancies available.
        IF l_sched_rec.flg_vacancy = pk_schedule_common.g_sched_vacancy_unplanned
        THEN
            l_flg_vacancy := pk_schedule_common.g_sched_vacancy_routine;
        ELSE
            l_flg_vacancy := l_sched_rec.flg_vacancy;
        END IF;
    
        -- Create new schedule
        g_error := 'CREATE SCHEDULE';
        IF NOT create_schedule(i_lang                => i_lang,
                               i_prof                => i_prof,
                               i_id_patient          => l_sched_rec.id_patient,
                               i_id_dep_clin_serv    => l_sched_rec.id_dcs_requested,
                               i_id_sch_event        => l_sched_rec.id_sch_event,
                               i_id_prof             => i_id_prof,
                               i_dt_begin            => i_dt_begin,
                               i_dt_end              => i_dt_end,
                               i_flg_vacancy         => l_flg_vacancy,
                               i_schedule_notes      => l_sched_rec.schedule_notes,
                               i_id_lang_translator  => l_sched_rec.id_lang_translator,
                               i_id_lang_preferred   => l_sched_rec.id_lang_preferred,
                               i_id_reason           => l_sched_rec.id_reason,
                               i_id_origin           => l_sched_rec.id_origin,
                               i_id_room             => l_sched_rec.id_room,
                               i_id_schedule_ref     => CASE l_sched_rec.flg_status
                                                            WHEN pk_schedule.g_sched_status_scheduled THEN
                                                             i_old_id_schedule
                                                            ELSE
                                                             NULL
                                                        END,
                               i_id_episode          => l_sched_rec.id_episode,
                               i_reason_notes        => l_sched_rec.reason_notes,
                               i_flg_request_type    => l_sched_rec.flg_request_type,
                               i_flg_schedule_via    => l_sched_rec.flg_schedule_via,
                               i_id_interv_presc_det => l_sched_rec.id_interv_presc_det,
                               i_id_sch_recursion    => l_sched_rec.id_schedule_recursion,
                               i_id_phys_area        => l_sched_rec.id_physiatry_area,
                               i_wizmode             => i_wizmode,
                               i_id_complaint        => NULL,
                               i_id_slot             => i_id_slot,
                               o_id_schedule         => o_id_schedule,
                               o_flg_proceed         => o_flg_proceed,
                               o_flg_show            => o_flg_show,
                               o_msg                 => o_msg,
                               o_msg_title           => o_msg_title,
                               o_button              => o_button,
                               o_error               => o_error)
        THEN
            --   RAISE l_func_exception; --SCH 3.0 DO NOT REMOVE
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                --                pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id); --SCH 3.0 DO NOT REMOVE
                RETURN FALSE;
            END;
    END create_reschedule;

    /**
    * Cancel a MFR schedule.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_schedule        The schedule id to be canceled
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes
    * @param o_error              Error message if something goes wrong
    *
    * @author   Josï¿½ Antunes
    * @version  2.4.4
    * @since 2009/01/09
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        -- i_transaction_id   IN VARCHAR2, --SCH 3.0 DO NOT REMOVE
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(32) := 'CANCEL_SCHEDULE';
        l_id_sch_consult_vac  sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_id_physiatry_area   schedule_intervention.id_physiatry_area%TYPE;
        l_status              schedule.flg_status%TYPE;
        l_id_interv_presc_det schedule_intervention.id_interv_presc_det%TYPE;
        l_num_sess_sched      interv_presc_det.num_take%TYPE;
        l_num_sess_presc      interv_presc_det.num_take%TYPE;
        l_flg_ipd_status      interv_presc_det.flg_status%TYPE;
        -- l_transaction_id      VARCHAR2(4000) := i_transaction_id; --SCH 3.0 DO NOT REMOVE
    BEGIN
    
        -- get schedule data
        g_error := 'GET SCHEDULE DATA';
        SELECT s.flg_status, s.id_sch_consult_vacancy, si.id_physiatry_area
          INTO l_status, l_id_sch_consult_vac, l_id_physiatry_area
          FROM schedule s
          JOIN schedule_intervention si
            ON s.id_schedule = si.id_schedule
         WHERE s.id_schedule = i_id_schedule
           AND si.flg_original = g_yes
           AND rownum = 1;
    
        g_error := 'GET ID_INTERV_PRESC_DET';
        SELECT si.id_interv_presc_det
          INTO l_id_interv_presc_det
          FROM schedule_intervention si
         WHERE si.id_schedule = i_id_schedule
           AND si.flg_original = g_yes
           AND rownum = 1;
    
        -- if its temporary, just delete the records  
        IF l_status = pk_schedule.g_sched_status_temporary
        THEN
        
            DELETE sch_group
             WHERE sch_group.id_schedule = i_id_schedule;
            DELETE sch_resource
             WHERE sch_resource.id_schedule = i_id_schedule;
            DELETE schedule_intervention
             WHERE id_schedule = i_id_schedule;
            DELETE schedule
             WHERE id_schedule = i_id_schedule;
        
        ELSE
            g_error := 'CALL CANCEL_SCHEDULE';
            IF NOT pk_schedule_common.cancel_schedule(i_lang             => i_lang,
                                                      i_id_professional  => i_prof.id,
                                                      i_id_software      => i_prof.software,
                                                      i_id_schedule      => i_id_schedule,
                                                      i_id_cancel_reason => i_id_cancel_reason,
                                                      i_cancel_notes     => i_cancel_notes,
                                                      i_ignore_vacancies => FALSE,
                                                      o_error            => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            g_error := 'UPDATE SCHEDULE_INTERVENTION';
            UPDATE schedule_intervention si
               SET si.flg_state = pk_schedule.g_sched_status_cancelled
             WHERE si.id_schedule = i_id_schedule;
        
            g_error := 'CALL CANCEL_SCH_EPIS_EHR';
            IF NOT pk_schedule.cancel_sch_epis_ehr(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_id_schedule  => i_id_schedule,
                                                   i_sysdate      => pk_schedule.g_sysdate,
                                                   i_sysdate_tstz => pk_schedule.g_sysdate_tstz,
                                                   o_error        => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
        END IF;
    
        -- if no vacancy (= no_vacancy/over_slot schedule), just dont call create_slots
    
        g_error := 'CALL RECALCULATE_SLOTS';
        IF l_id_sch_consult_vac IS NOT NULL
           AND NOT create_slots(i_lang                   => i_lang,
                                i_prof                   => i_prof,
                                i_id_sch_consult_vacancy => l_id_sch_consult_vac,
                                i_id_physiatry_area      => l_id_physiatry_area,
                                i_flg_wizard             => CASE l_status
                                                                WHEN pk_schedule.g_sched_status_temporary THEN
                                                                 g_yes
                                                                ELSE
                                                                 g_no
                                                            END,
                                o_error                  => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_INTERV_MFR.UPDATE_INTERV_STATUS';
        IF NOT pk_interv_mfr.update_interv_status(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_interv_presc_det => l_id_interv_presc_det,
                                                  o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END cancel_schedule;

    /**
    * Cancel a set of MFR schedule.
    *
    * @param i_lang                         Language
    * @param i_prof                         Professional identification
    * @param i_id_interv_presc_det          Intervention identifier
    * @param i_id_cancel_reason             Cancel reason
    * @param i_cancel_notes                 Cancel notes
    * @param o_error                        Error message if something goes wrong
    *
    * @author   Josï¿½ Antunes
    * @version  2.4.4
    * @since 2008/11/28
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION cancel_schedules
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_id_cancel_reason    IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes        IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'CANCEL_SCHEDULES';
        o_list_schedules table_number;
    
        --SCH 3.0 DO NOT REMOVE
        -- l_transaction_id VARCHAR2(4000);
        -- l_func_exception EXCEPTION;
    BEGIN
    
        g_error := 'GET o_list_schedules';
        SELECT s.id_schedule
          BULK COLLECT
          INTO o_list_schedules
          FROM schedule s
         INNER JOIN schedule_intervention si
            ON si.id_schedule = s.id_schedule
         WHERE si.id_interv_presc_det = i_id_interv_presc_det
           AND si.flg_original = g_yes
           AND s.flg_status IN (pk_schedule.g_sched_status_temporary,
                                pk_schedule.g_status_scheduled,
                                pk_schedule.g_status_requested,
                                pk_schedule.g_status_pending);
        -- descobrir quais os agendamentos que ainda nao foram efectuados. cancelar os agendados?
    
        g_error := 'CANCEL each schedule';
        IF (o_list_schedules.count > 0)
        THEN
            FOR i IN o_list_schedules.first .. o_list_schedules.last
            LOOP
            
                -- cancel date
                IF NOT cancel_schedule(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_schedule      => o_list_schedules(i),
                                       i_id_cancel_reason => i_id_cancel_reason,
                                       i_cancel_notes     => i_cancel_notes,
                                       -- i_transaction_id   => l_transaction_id, --SCH 3.0 DO NOT REMOVE
                                       o_error => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            END LOOP;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END cancel_schedules;

    /*
    * locate vacancies (not slots) that intersect dt_begin and/or dt_end.
    *
    * @param i_lang               Language
    * @param i_prof               Professional who is doing the scheduling
    * @param i_id_sch_event       Event type
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_id_phys_area       physiatry area
    * @param o_error              Error message if something goes wrong
    *
    * @author   Telmo Castro
    * @version  2.4.4
    * @date     21-12-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_suitable_vacancy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_event IN sch_consult_vacancy.id_sch_event%TYPE,
        i_dt_begin     IN sch_consult_vacancy.dt_begin_tstz%TYPE,
        i_dt_end       IN sch_consult_vacancy.dt_end_tstz%TYPE,
        i_id_phys_area IN sch_consult_vac_mfr.id_physiatry_area%TYPE,
        o_ids_vac      OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SUITABLE_VACANCY';
        l_base_dcs  table_number;
    BEGIN
        -- load available dcs
        g_error := 'GET POSSIBLE DCS';
        IF NOT get_base_id_dcs(i_lang, i_prof, l_base_dcs, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- result
        g_error := 'GET_SUITABLE_VACANCY';
        SELECT scv.id_sch_consult_vacancy
          BULK COLLECT
          INTO o_ids_vac
          FROM sch_consult_vacancy scv
          JOIN sch_consult_vac_mfr scvm
            ON scv.id_sch_consult_vacancy = scvm.id_sch_consult_vacancy
         WHERE scv.id_institution = i_prof.institution
           AND ((i_prof.id IS NOT NULL AND scv.id_prof = i_prof.id) OR scv.id_prof IS NULL)
           AND scv.id_sch_event = i_id_sch_event
           AND EXISTS (SELECT 1
                  FROM TABLE(l_base_dcs)
                 WHERE column_value = scv.id_dep_clin_serv)
           AND scvm.id_physiatry_area = i_id_phys_area
           AND scv.dt_begin_tstz <= i_dt_begin
           AND scv.dt_end_tstz >= i_dt_end
           AND scv.flg_status = pk_schedule_bo.g_status_active;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_suitable_vacancy;

    /**********************************************************************************************
    * API - insert one row on schedule table
    *
    * @param [all schedule table fields]
    * @param id_schedule_out                 output parameter - new inserted id_schedule
    * @param o_error                         descripton error   
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION ins_schedule
    (
        i_lang                    IN language.id_language%TYPE,
        id_schedule_in            IN schedule.id_schedule%TYPE DEFAULT NULL,
        id_instit_requests_in     IN schedule.id_instit_requests%TYPE DEFAULT NULL,
        id_instit_requested_in    IN schedule.id_instit_requested%TYPE DEFAULT NULL,
        id_dcs_requests_in        IN schedule.id_dcs_requests%TYPE DEFAULT NULL,
        id_dcs_requested_in       IN schedule.id_dcs_requested%TYPE DEFAULT NULL,
        id_prof_requests_in       IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        id_prof_schedules_in      IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        flg_status_in             IN schedule.flg_status%TYPE DEFAULT NULL,
        id_prof_cancel_in         IN schedule.id_prof_cancel%TYPE DEFAULT NULL,
        schedule_notes_in         IN schedule.schedule_notes%TYPE DEFAULT NULL,
        id_cancel_reason_in       IN schedule.id_cancel_reason%TYPE DEFAULT NULL,
        id_lang_translator_in     IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        id_lang_preferred_in      IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        id_sch_event_in           IN schedule.id_sch_event%TYPE DEFAULT NULL,
        id_reason_in              IN schedule.id_reason%TYPE DEFAULT NULL,
        id_origin_in              IN schedule.id_origin%TYPE DEFAULT NULL,
        id_room_in                IN schedule.id_room%TYPE DEFAULT NULL,
        flg_urgency_in            IN schedule.flg_urgency%TYPE DEFAULT NULL,
        schedule_cancel_notes_in  IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        flg_notification_in       IN schedule.flg_notification%TYPE DEFAULT NULL,
        id_schedule_ref_in        IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        flg_vacancy_in            IN schedule.flg_vacancy%TYPE DEFAULT NULL,
        flg_sch_type_in           IN schedule.flg_sch_type%TYPE DEFAULT NULL,
        reason_notes_in           IN schedule.reason_notes%TYPE DEFAULT NULL,
        dt_begin_tstz_in          IN schedule.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_in         IN schedule.dt_cancel_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_in            IN schedule.dt_end_tstz%TYPE DEFAULT NULL,
        dt_request_tstz_in        IN schedule.dt_request_tstz%TYPE DEFAULT NULL,
        dt_schedule_tstz_in       IN schedule.dt_schedule_tstz%TYPE DEFAULT NULL,
        id_complaint_in           IN schedule.id_reason%TYPE DEFAULT NULL,
        flg_instructions_in       IN schedule.flg_instructions%TYPE DEFAULT NULL,
        flg_schedule_via_in       IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        id_prof_notification_in   IN schedule.id_prof_notification%TYPE DEFAULT NULL,
        dt_notification_tstz_in   IN schedule.dt_notification_tstz%TYPE DEFAULT NULL,
        flg_notification_via_in   IN schedule.flg_notification_via%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_in IN schedule.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        flg_request_type_in       IN schedule.flg_request_type%TYPE DEFAULT NULL,
        id_episode_in             IN schedule.id_episode%TYPE DEFAULT NULL,
        id_schedule_recursion_in  IN schedule.id_schedule_recursion%TYPE DEFAULT NULL,
        id_schedule_out           OUT schedule.id_schedule%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'INS_SCHEDULE';
    BEGIN
        g_error := 'INSERT INTO SCHEDULE';
        INSERT INTO schedule
            (id_schedule,
             id_instit_requests,
             id_instit_requested,
             id_dcs_requests,
             id_dcs_requested,
             id_prof_requests,
             id_prof_schedules,
             flg_status,
             id_prof_cancel,
             schedule_notes,
             id_cancel_reason,
             id_lang_translator,
             id_lang_preferred,
             id_sch_event,
             id_reason,
             id_origin,
             id_room,
             flg_urgency,
             schedule_cancel_notes,
             flg_notification,
             id_schedule_ref,
             flg_vacancy,
             flg_sch_type,
             reason_notes,
             dt_begin_tstz,
             dt_cancel_tstz,
             dt_end_tstz,
             dt_request_tstz,
             dt_schedule_tstz,
             flg_instructions,
             flg_schedule_via,
             id_prof_notification,
             dt_notification_tstz,
             flg_notification_via,
             id_sch_consult_vacancy,
             flg_request_type,
             id_episode,
             id_schedule_recursion)
        VALUES
            (nvl(id_schedule_in, seq_schedule.nextval),
             id_instit_requests_in,
             id_instit_requested_in,
             id_dcs_requests_in,
             id_dcs_requested_in,
             id_prof_requests_in,
             id_prof_schedules_in,
             flg_status_in,
             id_prof_cancel_in,
             schedule_notes_in,
             id_cancel_reason_in,
             id_lang_translator_in,
             id_lang_preferred_in,
             id_sch_event_in,
             id_reason_in,
             id_origin_in,
             id_room_in,
             flg_urgency_in,
             schedule_cancel_notes_in,
             flg_notification_in,
             id_schedule_ref_in,
             flg_vacancy_in,
             flg_sch_type_in,
             reason_notes_in,
             dt_begin_tstz_in,
             dt_cancel_tstz_in,
             dt_end_tstz_in,
             dt_request_tstz_in,
             dt_schedule_tstz_in,
             flg_instructions_in,
             flg_schedule_via_in,
             id_prof_notification_in,
             dt_notification_tstz_in,
             flg_notification_via_in,
             id_sch_consult_vacancy_in,
             flg_request_type_in,
             id_episode_in,
             id_schedule_recursion_in)
        RETURNING id_schedule INTO id_schedule_out;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END ins_schedule;

    /**********************************************************************************************
    * API - update one row on schedule table by primary key
    *
    * @param id_schedule_in                  schedule ID
    * @param [all schedule table fields]     [new values for update]
    * @param [all schedule table fields]_nin boolean flag to accept null values
    * @param o_error                         descripton error   
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION upd_schedule
    (
        i_lang                     IN language.id_language%TYPE,
        id_schedule_in             IN schedule.id_schedule%TYPE DEFAULT NULL,
        id_instit_requests_in      IN schedule.id_instit_requests%TYPE DEFAULT NULL,
        id_instit_requests_nin     IN BOOLEAN := TRUE,
        id_instit_requested_in     IN schedule.id_instit_requested%TYPE DEFAULT NULL,
        id_instit_requested_nin    IN BOOLEAN := TRUE,
        id_dcs_requests_in         IN schedule.id_dcs_requests%TYPE DEFAULT NULL,
        id_dcs_requests_nin        IN BOOLEAN := TRUE,
        id_dcs_requested_in        IN schedule.id_dcs_requested%TYPE DEFAULT NULL,
        id_dcs_requested_nin       IN BOOLEAN := TRUE,
        id_prof_requests_in        IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        id_prof_requests_nin       IN BOOLEAN := TRUE,
        id_prof_schedules_in       IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        id_prof_schedules_nin      IN BOOLEAN := TRUE,
        flg_status_in              IN schedule.flg_status%TYPE DEFAULT NULL,
        flg_status_nin             IN BOOLEAN := TRUE,
        id_prof_cancel_in          IN schedule.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin         IN BOOLEAN := TRUE,
        schedule_notes_in          IN schedule.schedule_notes%TYPE DEFAULT NULL,
        schedule_notes_nin         IN BOOLEAN := TRUE,
        id_cancel_reason_in        IN schedule.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin       IN BOOLEAN := TRUE,
        id_lang_translator_in      IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        id_lang_translator_nin     IN BOOLEAN := TRUE,
        id_lang_preferred_in       IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        id_lang_preferred_nin      IN BOOLEAN := TRUE,
        id_sch_event_in            IN schedule.id_sch_event%TYPE DEFAULT NULL,
        id_sch_event_nin           IN BOOLEAN := TRUE,
        id_reason_in               IN schedule.id_reason%TYPE DEFAULT NULL,
        id_reason_nin              IN BOOLEAN := TRUE,
        id_origin_in               IN schedule.id_origin%TYPE DEFAULT NULL,
        id_origin_nin              IN BOOLEAN := TRUE,
        id_room_in                 IN schedule.id_room%TYPE DEFAULT NULL,
        id_room_nin                IN BOOLEAN := TRUE,
        flg_urgency_in             IN schedule.flg_urgency%TYPE DEFAULT NULL,
        flg_urgency_nin            IN BOOLEAN := TRUE,
        schedule_cancel_notes_in   IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        schedule_cancel_notes_nin  IN BOOLEAN := TRUE,
        flg_notification_in        IN schedule.flg_notification%TYPE DEFAULT NULL,
        flg_notification_nin       IN BOOLEAN := TRUE,
        id_schedule_ref_in         IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        id_schedule_ref_nin        IN BOOLEAN := TRUE,
        flg_vacancy_in             IN schedule.flg_vacancy%TYPE DEFAULT NULL,
        flg_vacancy_nin            IN BOOLEAN := TRUE,
        flg_sch_type_in            IN schedule.flg_sch_type%TYPE DEFAULT NULL,
        flg_sch_type_nin           IN BOOLEAN := TRUE,
        reason_notes_in            IN schedule.reason_notes%TYPE DEFAULT NULL,
        reason_notes_nin           IN BOOLEAN := TRUE,
        dt_begin_tstz_in           IN schedule.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_begin_tstz_nin          IN BOOLEAN := TRUE,
        dt_cancel_tstz_in          IN schedule.dt_cancel_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_nin         IN BOOLEAN := TRUE,
        dt_end_tstz_in             IN schedule.dt_end_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_nin            IN BOOLEAN := TRUE,
        dt_request_tstz_in         IN schedule.dt_request_tstz%TYPE DEFAULT NULL,
        dt_request_tstz_nin        IN BOOLEAN := TRUE,
        dt_schedule_tstz_in        IN schedule.dt_schedule_tstz%TYPE DEFAULT NULL,
        dt_schedule_tstz_nin       IN BOOLEAN := TRUE,
        id_complaint_in            IN schedule.id_reason%TYPE DEFAULT NULL,
        id_complaint_nin           IN BOOLEAN := TRUE,
        flg_instructions_in        IN schedule.flg_instructions%TYPE DEFAULT NULL,
        flg_instructions_nin       IN BOOLEAN := TRUE,
        flg_schedule_via_in        IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        flg_schedule_via_nin       IN BOOLEAN := TRUE,
        id_prof_notification_in    IN schedule.id_prof_notification%TYPE DEFAULT NULL,
        id_prof_notification_nin   IN BOOLEAN := TRUE,
        dt_notification_tstz_in    IN schedule.dt_notification_tstz%TYPE DEFAULT NULL,
        dt_notification_tstz_nin   IN BOOLEAN := TRUE,
        flg_notification_via_in    IN schedule.flg_notification_via%TYPE DEFAULT NULL,
        flg_notification_via_nin   IN BOOLEAN := TRUE,
        id_sch_consult_vacancy_in  IN schedule.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_nin IN BOOLEAN := TRUE,
        flg_request_type_in        IN schedule.flg_request_type%TYPE DEFAULT NULL,
        flg_request_type_nin       IN BOOLEAN := TRUE,
        id_episode_in              IN schedule.id_episode%TYPE DEFAULT NULL,
        id_episode_nin             IN BOOLEAN := TRUE,
        id_schedule_recursion_in   IN schedule.id_schedule_recursion%TYPE DEFAULT NULL,
        id_schedule_recursion_nin  IN BOOLEAN := TRUE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name                VARCHAR2(32) := 'UPD_SCHEDULE';
        l_id_instit_requests_n     NUMBER := sys.diutil.bool_to_int(id_instit_requests_nin);
        l_id_instit_requested_n    NUMBER := sys.diutil.bool_to_int(id_instit_requested_nin);
        l_id_dcs_requests_n        NUMBER := sys.diutil.bool_to_int(id_dcs_requests_nin);
        l_id_dcs_requested_n       NUMBER := sys.diutil.bool_to_int(id_dcs_requested_nin);
        l_id_prof_requests_n       NUMBER := sys.diutil.bool_to_int(id_prof_requests_nin);
        l_id_prof_schedules_n      NUMBER := sys.diutil.bool_to_int(id_prof_schedules_nin);
        l_flg_status_n             NUMBER := sys.diutil.bool_to_int(flg_status_nin);
        l_id_prof_cancel_n         NUMBER := sys.diutil.bool_to_int(id_prof_cancel_nin);
        l_schedule_notes_n         NUMBER := sys.diutil.bool_to_int(schedule_notes_nin);
        l_id_cancel_reason_n       NUMBER := sys.diutil.bool_to_int(id_cancel_reason_nin);
        l_id_lang_translator_n     NUMBER := sys.diutil.bool_to_int(id_lang_translator_nin);
        l_id_lang_preferred_n      NUMBER := sys.diutil.bool_to_int(id_lang_preferred_nin);
        l_id_sch_event_n           NUMBER := sys.diutil.bool_to_int(id_sch_event_nin);
        l_id_reason_n              NUMBER := sys.diutil.bool_to_int(id_reason_nin);
        l_id_origin_n              NUMBER := sys.diutil.bool_to_int(id_origin_nin);
        l_id_room_n                NUMBER := sys.diutil.bool_to_int(id_room_nin);
        l_flg_urgency_n            NUMBER := sys.diutil.bool_to_int(flg_urgency_nin);
        l_schedule_cancel_notes_n  NUMBER := sys.diutil.bool_to_int(schedule_cancel_notes_nin);
        l_flg_notification_n       NUMBER := sys.diutil.bool_to_int(flg_notification_nin);
        l_id_schedule_ref_n        NUMBER := sys.diutil.bool_to_int(id_schedule_ref_nin);
        l_flg_vacancy_n            NUMBER := sys.diutil.bool_to_int(flg_vacancy_nin);
        l_flg_sch_type_n           NUMBER := sys.diutil.bool_to_int(flg_sch_type_nin);
        l_reason_notes_n           NUMBER := sys.diutil.bool_to_int(reason_notes_nin);
        l_dt_begin_tstz_n          NUMBER := sys.diutil.bool_to_int(dt_begin_tstz_nin);
        l_dt_cancel_tstz_n         NUMBER := sys.diutil.bool_to_int(dt_cancel_tstz_nin);
        l_dt_end_tstz_n            NUMBER := sys.diutil.bool_to_int(dt_end_tstz_nin);
        l_dt_request_tstz_n        NUMBER := sys.diutil.bool_to_int(dt_request_tstz_nin);
        l_dt_schedule_tstz_n       NUMBER := sys.diutil.bool_to_int(dt_schedule_tstz_nin);
        l_id_complaint_n           NUMBER := sys.diutil.bool_to_int(id_complaint_nin);
        l_flg_instructions_n       NUMBER := sys.diutil.bool_to_int(flg_instructions_nin);
        l_flg_schedule_via_n       NUMBER := sys.diutil.bool_to_int(flg_schedule_via_nin);
        l_id_prof_notification_n   NUMBER := sys.diutil.bool_to_int(id_prof_notification_nin);
        l_dt_notification_tstz_n   NUMBER := sys.diutil.bool_to_int(dt_notification_tstz_nin);
        l_flg_notification_via_n   NUMBER := sys.diutil.bool_to_int(flg_notification_via_nin);
        l_id_sch_consult_vacancy_n NUMBER := sys.diutil.bool_to_int(id_sch_consult_vacancy_nin);
        l_flg_request_type_n       NUMBER := sys.diutil.bool_to_int(flg_request_type_nin);
        l_id_episode_n             NUMBER := sys.diutil.bool_to_int(id_episode_nin);
        l_id_schedule_recursion_n  NUMBER := sys.diutil.bool_to_int(id_schedule_recursion_nin);
    
    BEGIN
    
        g_error := 'UPDATE SCHEDULE';
        UPDATE schedule
           SET id_instit_requests = CASE
                                         WHEN l_id_instit_requests_n = 1 THEN
                                          nvl(id_instit_requests_in, id_instit_requests)
                                         ELSE
                                          id_instit_requests_in
                                     END,
               id_instit_requested = CASE
                                          WHEN l_id_instit_requested_n = 1 THEN
                                           nvl(id_instit_requested_in, id_instit_requested)
                                          ELSE
                                           id_instit_requested_in
                                      END,
               id_dcs_requests = CASE
                                      WHEN l_id_dcs_requests_n = 1 THEN
                                       nvl(id_dcs_requests_in, id_dcs_requests)
                                      ELSE
                                       id_dcs_requests_in
                                  END,
               id_dcs_requested = CASE
                                       WHEN l_id_dcs_requested_n = 1 THEN
                                        nvl(id_dcs_requested_in, id_dcs_requested)
                                       ELSE
                                        id_dcs_requested_in
                                   END,
               id_prof_requests = CASE
                                       WHEN l_id_prof_requests_n = 1 THEN
                                        nvl(id_prof_requests_in, id_prof_requests)
                                       ELSE
                                        id_prof_requests_in
                                   END,
               id_prof_schedules = CASE
                                        WHEN l_id_prof_schedules_n = 1 THEN
                                         nvl(id_prof_schedules_in, id_prof_schedules)
                                        ELSE
                                         id_prof_schedules_in
                                    END,
               flg_status = CASE
                                 WHEN l_flg_status_n = 1 THEN
                                  nvl(flg_status_in, flg_status)
                                 ELSE
                                  flg_status_in
                             END,
               id_prof_cancel = CASE
                                     WHEN l_id_prof_cancel_n = 1 THEN
                                      nvl(id_prof_cancel_in, id_prof_cancel)
                                     ELSE
                                      id_prof_cancel_in
                                 END,
               schedule_notes = CASE
                                     WHEN l_schedule_notes_n = 1 THEN
                                      nvl(schedule_notes_in, schedule_notes)
                                     ELSE
                                      schedule_notes_in
                                 END,
               id_cancel_reason = CASE
                                       WHEN l_id_cancel_reason_n = 1 THEN
                                        nvl(id_cancel_reason_in, id_cancel_reason)
                                       ELSE
                                        id_cancel_reason_in
                                   END,
               id_lang_translator = CASE
                                         WHEN l_id_lang_translator_n = 1 THEN
                                          nvl(id_lang_translator_in, id_lang_translator)
                                         ELSE
                                          id_lang_translator_in
                                     END,
               id_lang_preferred = CASE
                                        WHEN l_id_lang_preferred_n = 1 THEN
                                         nvl(id_lang_preferred_in, id_lang_preferred)
                                        ELSE
                                         id_lang_preferred_in
                                    END,
               id_sch_event = CASE
                                   WHEN l_id_sch_event_n = 1 THEN
                                    nvl(id_sch_event_in, id_sch_event)
                                   ELSE
                                    id_sch_event_in
                               END,
               id_reason = CASE
                                WHEN l_id_reason_n = 1 THEN
                                 nvl(id_reason_in, id_reason)
                                ELSE
                                 id_reason_in
                            END,
               id_origin = CASE
                                WHEN l_id_origin_n = 1 THEN
                                 nvl(id_origin_in, id_origin)
                                ELSE
                                 id_origin_in
                            END,
               id_room = CASE
                              WHEN l_id_room_n = 1 THEN
                               nvl(id_room_in, id_room)
                              ELSE
                               id_room_in
                          END,
               flg_urgency = CASE
                                  WHEN l_flg_urgency_n = 1 THEN
                                   nvl(flg_urgency_in, flg_urgency)
                                  ELSE
                                   flg_urgency_in
                              END,
               schedule_cancel_notes = CASE
                                            WHEN l_schedule_cancel_notes_n = 1 THEN
                                             nvl(schedule_cancel_notes_in, schedule_cancel_notes)
                                            ELSE
                                             schedule_cancel_notes_in
                                        END,
               flg_notification = CASE
                                       WHEN l_flg_notification_n = 1 THEN
                                        nvl(flg_notification_in, flg_notification)
                                       ELSE
                                        flg_notification_in
                                   END,
               id_schedule_ref = CASE
                                      WHEN l_id_schedule_ref_n = 1 THEN
                                       nvl(id_schedule_ref_in, id_schedule_ref)
                                      ELSE
                                       id_schedule_ref_in
                                  END,
               flg_vacancy = CASE
                                  WHEN l_flg_vacancy_n = 1 THEN
                                   nvl(flg_vacancy_in, flg_vacancy)
                                  ELSE
                                   flg_vacancy_in
                              END,
               flg_sch_type = CASE
                                   WHEN l_flg_sch_type_n = 1 THEN
                                    nvl(flg_sch_type_in, flg_sch_type)
                                   ELSE
                                    flg_sch_type_in
                               END,
               reason_notes = CASE
                                   WHEN l_reason_notes_n = 1 THEN
                                    nvl(reason_notes_in, reason_notes)
                                   ELSE
                                    reason_notes_in
                               END,
               dt_begin_tstz = CASE
                                    WHEN l_dt_begin_tstz_n = 1 THEN
                                     nvl(dt_begin_tstz_in, dt_begin_tstz)
                                    ELSE
                                     dt_begin_tstz_in
                                END,
               dt_cancel_tstz = CASE
                                     WHEN l_dt_cancel_tstz_n = 1 THEN
                                      nvl(dt_cancel_tstz_in, dt_cancel_tstz)
                                     ELSE
                                      dt_cancel_tstz_in
                                 END,
               dt_end_tstz = CASE
                                  WHEN l_dt_end_tstz_n = 1 THEN
                                   nvl(dt_end_tstz_in, dt_end_tstz)
                                  ELSE
                                   dt_end_tstz_in
                              END,
               dt_request_tstz = CASE
                                      WHEN l_dt_request_tstz_n = 1 THEN
                                       nvl(dt_request_tstz_in, dt_request_tstz)
                                      ELSE
                                       dt_request_tstz_in
                                  END,
               dt_schedule_tstz = CASE
                                       WHEN l_dt_schedule_tstz_n = 1 THEN
                                        nvl(dt_schedule_tstz_in, dt_schedule_tstz)
                                       ELSE
                                        dt_schedule_tstz_in
                                   END,
               flg_instructions = CASE
                                       WHEN l_flg_instructions_n = 1 THEN
                                        nvl(flg_instructions_in, flg_instructions)
                                       ELSE
                                        flg_instructions_in
                                   END,
               flg_schedule_via = CASE
                                       WHEN l_flg_schedule_via_n = 1 THEN
                                        nvl(flg_schedule_via_in, flg_schedule_via)
                                       ELSE
                                        flg_schedule_via_in
                                   END,
               id_prof_notification = CASE
                                           WHEN l_id_prof_notification_n = 1 THEN
                                            nvl(id_prof_notification_in, id_prof_notification)
                                           ELSE
                                            id_prof_notification_in
                                       END,
               dt_notification_tstz = CASE
                                           WHEN l_dt_notification_tstz_n = 1 THEN
                                            nvl(dt_notification_tstz_in, dt_notification_tstz)
                                           ELSE
                                            dt_notification_tstz_in
                                       END,
               flg_notification_via = CASE
                                           WHEN l_flg_notification_via_n = 1 THEN
                                            nvl(flg_notification_via_in, flg_notification_via)
                                           ELSE
                                            flg_notification_via_in
                                       END,
               id_sch_consult_vacancy = CASE
                                             WHEN l_id_sch_consult_vacancy_n = 1 THEN
                                              nvl(id_sch_consult_vacancy_in, id_sch_consult_vacancy)
                                             ELSE
                                              id_sch_consult_vacancy_in
                                         END,
               flg_request_type = CASE
                                       WHEN l_flg_request_type_n = 1 THEN
                                        nvl(flg_request_type_in, flg_request_type)
                                       ELSE
                                        flg_request_type_in
                                   END,
               id_episode = CASE
                                 WHEN l_id_episode_n = 1 THEN
                                  nvl(id_episode_in, id_episode)
                                 ELSE
                                  id_episode_in
                             END,
               id_schedule_recursion = CASE
                                            WHEN l_id_schedule_recursion_n = 1 THEN
                                             nvl(id_schedule_recursion_in, id_schedule_recursion)
                                            ELSE
                                             id_schedule_recursion_in
                                        END
        
         WHERE id_schedule = id_schedule_in;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END upd_schedule;

    /**********************************************************************************************
    * API - insert one row on sch_consult_vac_mfr_slot table
    *
    * @param id_sch_consult_vac_mfr_in       sch_consult_vac_mfr ID
    * @param id_sch_consult_vacancy_in       sch_consult_vacancy ID
    * @param id_physiatry_area_in            physiatry_area ID
    * @param dt_begin_tstz_in                begin date
    * @param dt_end_tstz_in                  end date
    * @param id_professional_in              professional ID
    * @param flg_status_in                   flag status
    * @param id_prof_created_in              created by
    * @param dt_created_in                   creating date
    * @param id_sch_consult_vac_mfr_out      output parameter - new inserted id_sch_consult_vac_mfr_slot
    * @param o_error                         descripton error   
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION ins_sch_consult_vac_mfr_slot
    (
        i_lang                     IN language.id_language%TYPE,
        id_sch_consult_vac_mfr_in  IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_in  IN sch_consult_vac_mfr_slot.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_physiatry_area_in       IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE DEFAULT NULL,
        dt_begin_tstz_in           IN sch_consult_vac_mfr_slot.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_in             IN sch_consult_vac_mfr_slot.dt_end_tstz%TYPE DEFAULT NULL,
        id_professional_in         IN sch_consult_vac_mfr_slot.id_professional%TYPE DEFAULT NULL,
        flg_status_in              IN sch_consult_vac_mfr_slot.flg_status%TYPE DEFAULT NULL,
        id_prof_created_in         IN sch_consult_vac_mfr_slot.id_prof_created%TYPE DEFAULT NULL,
        dt_created_in              IN sch_consult_vac_mfr_slot.dt_created%TYPE DEFAULT NULL,
        id_sch_consult_vac_mfr_out OUT sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'INS_SCH_CONSULT_VAC_MFR_SLOT';
    BEGIN
        g_error := 'INSERT INTO SCH_CONSULT_VAC_MFR_SLOT';
        INSERT INTO sch_consult_vac_mfr_slot
            (id_sch_consult_vac_mfr_slot,
             id_sch_consult_vacancy,
             id_physiatry_area,
             dt_begin_tstz,
             dt_end_tstz,
             id_professional,
             flg_status,
             id_prof_created,
             dt_created)
        VALUES
            (nvl(id_sch_consult_vac_mfr_in, seq_sch_consult_vac_mfr_slot.nextval),
             id_sch_consult_vacancy_in,
             id_physiatry_area_in,
             dt_begin_tstz_in,
             dt_end_tstz_in,
             id_professional_in,
             flg_status_in,
             id_prof_created_in,
             dt_created_in)
        RETURNING id_sch_consult_vac_mfr_slot INTO id_sch_consult_vac_mfr_out;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END ins_sch_consult_vac_mfr_slot;

    /**********************************************************************************************
    * API - update one row on sch_consult_vac_mfr_slot table by primary key
    *
    * @param id_sch_consult_vac_mfr_in       sch_consult_vac_mfr ID
    * @param id_sch_consult_vacancy_in       sch_consult_vacancy ID
    * @param id_sch_consult_vacancy_nin      boolean flag to accept null values    
    * @param id_physiatry_area_in            physiatry_area ID
    * @param id_physiatry_area_nin           boolean flag to accept null values
    * @param dt_begin_tstz_in                begin date
    * @param dt_begin_tstz_nin               boolean flag to accept null values   
    * @param dt_end_tstz_in                  end date
    * @param dt_end_tstz_nin                 boolean flag to accept null values
    * @param id_professional_in              professional ID
    * @param id_professional_nin             boolean flag to accept null values
    * @param flg_status_in                   flag status
    * @param flg_status_nin                  boolean flag to accept null values
    * @param id_prof_created_in              created by
    * @param id_prof_created_nin             boolean flag to accept null values
    * @param dt_created_in                   creating date
    * @param dt_created_nin                  boolean flag to accept null values
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION upd_sch_consult_vac_mfr_slot
    (
        i_lang                     IN language.id_language%TYPE,
        id_sch_consult_vac_mfr_in  IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_in  IN sch_consult_vac_mfr_slot.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_nin IN BOOLEAN := TRUE,
        id_physiatry_area_in       IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE DEFAULT NULL,
        id_physiatry_area_nin      IN BOOLEAN := TRUE,
        dt_begin_tstz_in           IN sch_consult_vac_mfr_slot.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_begin_tstz_nin          IN BOOLEAN := TRUE,
        dt_end_tstz_in             IN sch_consult_vac_mfr_slot.dt_end_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_nin            IN BOOLEAN := TRUE,
        id_professional_in         IN sch_consult_vac_mfr_slot.id_professional%TYPE DEFAULT NULL,
        id_professional_nin        IN BOOLEAN := TRUE,
        flg_status_in              IN sch_consult_vac_mfr_slot.flg_status%TYPE DEFAULT NULL,
        flg_status_nin             IN BOOLEAN := TRUE,
        id_prof_created_in         IN sch_consult_vac_mfr_slot.id_prof_created%TYPE DEFAULT NULL,
        id_prof_created_nin        IN BOOLEAN := TRUE,
        dt_created_in              IN sch_consult_vac_mfr_slot.dt_created%TYPE DEFAULT NULL,
        dt_created_nin             IN BOOLEAN := TRUE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                VARCHAR2(32) := 'UPD_SCH_CONSULT_VAC_MFR_SLOT';
        l_id_sch_consult_vacancy_n NUMBER(1);
        l_id_physiatry_area_n      NUMBER(1);
        l_dt_begin_tstz_n          NUMBER(1);
        l_dt_end_tstz_n            NUMBER(1);
        l_id_professional_n        NUMBER(1);
        l_flg_status_n             NUMBER(1);
        l_id_prof_created_n        NUMBER(1);
        l_dt_created_n             NUMBER(1);
    BEGIN
        g_error                    := 'CONVERT BOOLEAN TO INTEGER';
        l_id_sch_consult_vacancy_n := sys.diutil.bool_to_int(id_sch_consult_vacancy_nin);
        l_id_physiatry_area_n      := sys.diutil.bool_to_int(id_physiatry_area_nin);
        l_dt_begin_tstz_n          := sys.diutil.bool_to_int(dt_begin_tstz_nin);
        l_dt_end_tstz_n            := sys.diutil.bool_to_int(dt_end_tstz_nin);
        l_id_professional_n        := sys.diutil.bool_to_int(id_professional_nin);
        l_flg_status_n             := sys.diutil.bool_to_int(flg_status_nin);
        l_id_prof_created_n        := sys.diutil.bool_to_int(id_prof_created_nin);
        l_dt_created_n             := sys.diutil.bool_to_int(dt_created_nin);
    
        g_error := 'UPDATE SCH_CONSULT_VAC_MFR_SLOT';
        UPDATE sch_consult_vac_mfr_slot
           SET id_sch_consult_vacancy = CASE
                                             WHEN l_id_sch_consult_vacancy_n = 1 THEN
                                              nvl(id_sch_consult_vacancy_in, id_sch_consult_vacancy)
                                             ELSE
                                              id_sch_consult_vacancy_in
                                         END,
               id_physiatry_area = CASE
                                        WHEN l_id_physiatry_area_n = 1 THEN
                                         nvl(id_physiatry_area_in, id_physiatry_area)
                                        ELSE
                                         id_physiatry_area_in
                                    END,
               dt_begin_tstz = CASE
                                    WHEN l_dt_begin_tstz_n = 1 THEN
                                     nvl(dt_begin_tstz_in, dt_begin_tstz)
                                    ELSE
                                     dt_begin_tstz_in
                                END,
               dt_end_tstz = CASE
                                  WHEN l_dt_end_tstz_n = 1 THEN
                                   nvl(dt_end_tstz_in, dt_end_tstz)
                                  ELSE
                                   dt_end_tstz_in
                              END,
               id_professional = CASE
                                      WHEN l_id_professional_n = 1 THEN
                                       nvl(id_professional_in, id_professional)
                                      ELSE
                                       id_professional_in
                                  END,
               flg_status = CASE
                                 WHEN l_flg_status_n = 1 THEN
                                  nvl(flg_status_in, flg_status)
                                 ELSE
                                  flg_status_in
                             END,
               id_prof_created = CASE
                                      WHEN l_id_prof_created_n = 1 THEN
                                       nvl(id_prof_created_in, id_prof_created)
                                      ELSE
                                       id_prof_created_in
                                  END,
               dt_created = CASE
                                 WHEN l_dt_created_n = 1 THEN
                                  nvl(dt_created_in, dt_created)
                                 ELSE
                                  dt_created_in
                             END
         WHERE id_sch_consult_vac_mfr_slot = id_sch_consult_vac_mfr_in;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END upd_sch_consult_vac_mfr_slot;

    /**********************************************************************************************
    * API - insert one row on schedule_recursion table
    *
    * @param id_schedule_recursion_in        sch_consult_vac_mfr ID
    * @param weekdays_in                     list with weekdays, separated by global constant separator
    * @param flg_regular_in                  regular / irregular cycles flag: Y-Yes / N-No
    * @param flg_timeunit_in                 time unit: S-Weekly /  M-Monthly
    * @param num_take_in                     number of takes per session                     
    * @param num_freq_in                     frequency of sessions
    * @param id_interv_presc_det_in          intervention detail ID
    * @param id_schedule_recursion_out       output parameter - new inserted id_schedule_recursion
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION ins_schedule_recursion
    (
        i_lang                    IN language.id_language%TYPE,
        id_schedule_recursion_in  IN schedule_recursion.id_schedule_recursion%TYPE DEFAULT NULL,
        weekdays_in               IN schedule_recursion.weekdays%TYPE DEFAULT NULL,
        flg_regular_in            IN schedule_recursion.flg_regular%TYPE DEFAULT NULL,
        flg_timeunit_in           IN schedule_recursion.flg_timeunit%TYPE DEFAULT NULL,
        num_take_in               IN schedule_recursion.num_take%TYPE DEFAULT NULL,
        num_freq_in               IN schedule_recursion.num_freq%TYPE DEFAULT NULL,
        id_interv_presc_det_in    IN schedule_recursion.id_interv_presc_det%TYPE DEFAULT NULL,
        id_schedule_recursion_out OUT schedule_recursion.id_schedule_recursion%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'INS_SCHEDULE_RECURSION';
    BEGIN
    
        g_error := 'INSERT INTO SCHEDULE_RECURSION';
        INSERT INTO schedule_recursion
            (id_schedule_recursion, weekdays, flg_regular, flg_timeunit, num_take, num_freq, id_interv_presc_det)
        VALUES
            (nvl(id_schedule_recursion_in, seq_schedule_recursion.nextval),
             weekdays_in,
             flg_regular_in,
             flg_timeunit_in,
             num_take_in,
             num_freq_in,
             id_interv_presc_det_in)
        RETURNING id_schedule_recursion INTO id_schedule_recursion_out;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END ins_schedule_recursion;

    /**********************************************************************************************
    * API - update one row on schedule_recursion table by primary key
    *
    * @param id_schedule_recursion_in        id_schedule_recursion ID
    * @param weekdays_in                     list with weekdays, separated by global constant separator
    * @param weekdays_nin                    boolean flag to accept null values
    * @param flg_regular_in                  regular / irregular cycles flag: Y-Yes / N-No
    * @param flg_regular_nin                 boolean flag to accept null values
    * @param flg_timeunit_in                 time unit: S-Weekly /  M-Monthly
    * @param flg_timeunit_nin                boolean flag to accept null values
    * @param num_take_in                     number of takes
    * @param num_take_nin                    boolean flag to accept null values
    * @param num_freq_in                     frequency
    * @param num_freq_nin                    boolean flag to accept null values
    * @param id_interv_presc_det_in          intervention detail ID
    * @param id_interv_presc_det_nin         boolean flag to accept null values
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION upd_schedule_recursion
    (
        i_lang                   IN language.id_language%TYPE,
        id_schedule_recursion_in IN schedule_recursion.id_schedule_recursion%TYPE DEFAULT NULL,
        weekdays_in              IN schedule_recursion.weekdays%TYPE DEFAULT NULL,
        weekdays_nin             IN BOOLEAN := TRUE,
        flg_regular_in           IN schedule_recursion.flg_regular%TYPE DEFAULT NULL,
        flg_regular_nin          IN BOOLEAN := TRUE,
        flg_timeunit_in          IN schedule_recursion.flg_timeunit%TYPE DEFAULT NULL,
        flg_timeunit_nin         IN BOOLEAN := TRUE,
        num_take_in              IN schedule_recursion.num_take%TYPE DEFAULT NULL,
        num_take_nin             IN BOOLEAN := TRUE,
        num_freq_in              IN schedule_recursion.num_freq%TYPE DEFAULT NULL,
        num_freq_nin             IN BOOLEAN := TRUE,
        id_interv_presc_det_in   IN schedule_recursion.id_interv_presc_det%TYPE DEFAULT NULL,
        id_interv_presc_det_nin  IN BOOLEAN := TRUE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'UPD_SCHEDULE_RECURSION';
        l_weekdays_n            NUMBER(1);
        l_flg_regular_n         NUMBER(1);
        l_flg_timeunit_n        NUMBER(1);
        l_num_take_n            NUMBER(1);
        l_num_freq_n            NUMBER(1);
        l_id_interv_presc_det_n NUMBER(1);
    BEGIN
        g_error                 := 'CONVERT BOOLEAN TO INTEGER';
        l_weekdays_n            := sys.diutil.bool_to_int(weekdays_nin);
        l_flg_regular_n         := sys.diutil.bool_to_int(flg_regular_nin);
        l_flg_timeunit_n        := sys.diutil.bool_to_int(flg_timeunit_nin);
        l_num_take_n            := sys.diutil.bool_to_int(num_take_nin);
        l_num_freq_n            := sys.diutil.bool_to_int(num_freq_nin);
        l_id_interv_presc_det_n := sys.diutil.bool_to_int(id_interv_presc_det_nin);
    
        g_error := 'UPDATE SCHEDULE_RECURSION';
        UPDATE schedule_recursion
           SET weekdays = CASE
                               WHEN l_weekdays_n = 1 THEN
                                nvl(weekdays_in, weekdays)
                               ELSE
                                weekdays_in
                           END,
               flg_regular = CASE
                                  WHEN l_flg_regular_n = 1 THEN
                                   nvl(flg_regular_in, flg_regular)
                                  ELSE
                                   flg_regular_in
                              END,
               flg_timeunit = CASE
                                   WHEN l_flg_timeunit_n = 1 THEN
                                    nvl(flg_timeunit_in, flg_timeunit)
                                   ELSE
                                    flg_timeunit_in
                               END,
               num_take = CASE
                               WHEN l_num_take_n = 1 THEN
                                nvl(num_take_in, num_take)
                               ELSE
                                num_take_in
                           END,
               num_freq = CASE
                               WHEN l_num_freq_n = 1 THEN
                                nvl(num_freq_in, num_freq)
                               ELSE
                                num_freq_in
                           END,
               id_interv_presc_det = CASE
                                          WHEN l_id_interv_presc_det_n = 1 THEN
                                           nvl(id_interv_presc_det_in, id_interv_presc_det)
                                          ELSE
                                           id_interv_presc_det_in
                                      END
         WHERE id_schedule_recursion = id_schedule_recursion_in;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END upd_schedule_recursion;

    /**********************************************************************************************
    * API - insert one row on schedule_intervention table
    *
    * @param id_schedule_intervention_in     schedule_intervention ID
    * @param id_schedule_in                  schedule ID
    * @param id_interv_presc_det_in          interv_presc_det ID
    * @param id_prof_assigned_in             professional assigned ID
    * @param flg_state_in                    state
    * @param rank_in                         rank       
    * @param id_physiatry_area_in            physiatry area ID
    * @param o_error                         descripton error
    * @param id_schedule_intervention_out    output parameter - new inserted id_schedule_intervention
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    *
    * UPDATED: ALERT-18965 
    * @author   Telmo
    * @date     13-03-2009
    * @version  2.5
    **********************************************************************************************/
    FUNCTION ins_schedule_intervention
    (
        i_lang                       IN language.id_language%TYPE,
        id_schedule_intervention_in  IN schedule_intervention.id_schedule_intervention%TYPE DEFAULT NULL,
        id_schedule_in               IN schedule_intervention.id_schedule%TYPE DEFAULT NULL,
        id_interv_presc_det_in       IN schedule_intervention.id_interv_presc_det%TYPE DEFAULT NULL,
        id_prof_assigned_in          IN schedule_intervention.id_prof_assigned%TYPE DEFAULT NULL,
        flg_state_in                 IN schedule_intervention.flg_state%TYPE DEFAULT NULL,
        rank_in                      IN schedule_intervention.rank%TYPE DEFAULT NULL,
        id_physiatry_area_in         IN schedule_intervention.id_physiatry_area%TYPE DEFAULT NULL,
        flg_original_in              IN schedule_intervention.flg_original%TYPE DEFAULT NULL,
        id_schedule_intervention_out OUT schedule_intervention.id_schedule_intervention%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'INS_SCHEDULE_INTERVENTION';
    BEGIN
        INSERT INTO schedule_intervention
            (id_schedule_intervention,
             id_schedule,
             id_interv_presc_det,
             id_prof_assigned,
             flg_state,
             rank,
             id_physiatry_area,
             flg_original)
        VALUES
            (nvl(id_schedule_intervention_in, seq_schedule_intervention.nextval),
             id_schedule_in,
             id_interv_presc_det_in,
             id_prof_assigned_in,
             flg_state_in,
             rank_in,
             id_physiatry_area_in,
             flg_original_in)
        RETURNING id_schedule_intervention INTO id_schedule_intervention_out;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END ins_schedule_intervention;

    /**********************************************************************************************
    * API - update one row on schedule_intervention table by primary key
    *
    * @param id_schedule_intervention_in     schedule_intervention ID
    * @param id_schedule_in                  schedule ID
    * @param id_schedule_nin                 boolean flag to accept null values   
    * @param id_interv_presc_det_in          interv_presc_det ID
    * @param id_interv_presc_det_nin         boolean flag to accept null values
    * @param id_prof_assigned_in             professional assigned ID
    * @param id_prof_assigned_nin            boolean flag to accept null values
    * @param flg_state_in                    state
    * @param flg_state_nin                   boolean flag to accept null values
    * @param rank_in                         rank       
    * @param rank_nin                        boolean flag to accept null values
    * @param id_physiatry_area_in            physiatry area ID
    * @param id_physiatry_area_nin           boolean flag to accept null values   
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION upd_schedule_intervention
    (
        i_lang                      IN language.id_language%TYPE,
        id_schedule_intervention_in IN schedule_intervention.id_schedule_intervention%TYPE DEFAULT NULL,
        id_schedule_in              IN schedule_intervention.id_schedule%TYPE DEFAULT NULL,
        id_schedule_nin             IN BOOLEAN := TRUE,
        id_interv_presc_det_in      IN schedule_intervention.id_interv_presc_det%TYPE DEFAULT NULL,
        id_interv_presc_det_nin     IN BOOLEAN := TRUE,
        id_prof_assigned_in         IN schedule_intervention.id_prof_assigned%TYPE DEFAULT NULL,
        id_prof_assigned_nin        IN BOOLEAN := TRUE,
        flg_state_in                IN schedule_intervention.flg_state%TYPE DEFAULT NULL,
        flg_state_nin               IN BOOLEAN := TRUE,
        rank_in                     IN schedule_intervention.rank%TYPE DEFAULT NULL,
        rank_nin                    IN BOOLEAN := TRUE,
        id_physiatry_area_in        IN schedule_intervention.id_physiatry_area%TYPE DEFAULT NULL,
        id_physiatry_area_nin       IN BOOLEAN := TRUE,
        flg_original_in             IN schedule_intervention.flg_original%TYPE DEFAULT NULL,
        flg_original_nin            IN BOOLEAN := TRUE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'UPD_SCHEDULE_INTERVENTION';
        l_id_schedule_n         NUMBER(1);
        l_id_interv_presc_det_n NUMBER(1);
        l_id_prof_assigned_n    NUMBER(1);
        l_flg_state_n           NUMBER(1);
        l_rank_n                NUMBER(1);
        l_id_physiatry_area_n   NUMBER(1);
        l_flg_original_n        NUMBER(1);
    BEGIN
        g_error                 := 'CONVERT BOOLEAN TO INTEGER';
        l_id_schedule_n         := sys.diutil.bool_to_int(id_schedule_nin);
        l_id_interv_presc_det_n := sys.diutil.bool_to_int(id_interv_presc_det_nin);
        l_id_prof_assigned_n    := sys.diutil.bool_to_int(id_prof_assigned_nin);
        l_flg_state_n           := sys.diutil.bool_to_int(flg_state_nin);
        l_rank_n                := sys.diutil.bool_to_int(rank_nin);
        l_id_physiatry_area_n   := sys.diutil.bool_to_int(id_physiatry_area_nin);
        l_flg_original_n        := sys.diutil.bool_to_int(flg_original_nin);
    
        g_error := 'UPDATE SCHEDULE_INTERVENTION';
        UPDATE schedule_intervention
           SET id_schedule = CASE
                                  WHEN l_id_schedule_n = 1 THEN
                                   nvl(id_schedule_in, id_schedule)
                                  ELSE
                                   id_schedule_in
                              END,
               id_interv_presc_det = CASE
                                          WHEN l_id_interv_presc_det_n = 1 THEN
                                           nvl(id_interv_presc_det_in, id_interv_presc_det)
                                          ELSE
                                           id_interv_presc_det_in
                                      END,
               id_prof_assigned = CASE
                                       WHEN l_id_prof_assigned_n = 1 THEN
                                        nvl(id_prof_assigned_in, id_prof_assigned)
                                       ELSE
                                        id_prof_assigned_in
                                   END,
               flg_state = CASE
                                WHEN l_flg_state_n = 1 THEN
                                 nvl(flg_state_in, flg_state)
                                ELSE
                                 flg_state_in
                            END,
               rank = CASE
                           WHEN l_rank_n = 1 THEN
                            nvl(rank_in, rank)
                           ELSE
                            rank_in
                       END,
               id_physiatry_area = CASE
                                        WHEN l_id_physiatry_area_n = 1 THEN
                                         nvl(id_physiatry_area_in, id_physiatry_area)
                                        ELSE
                                         id_physiatry_area_in
                                    END,
               flg_original = CASE
                                   WHEN l_flg_original_n = 1 THEN
                                    nvl(flg_original_in, flg_original)
                                   ELSE
                                    flg_original_in
                               END
         WHERE id_schedule_intervention = id_schedule_intervention_in;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END upd_schedule_intervention;

    /**********************************************************************************************
    * API - insert one row on sch_consult_vacancy table
    *
    * @param id_sch_consult_vacancy_in       consult_vacancy ID
    * @param id_institution_in               institution ID
    * @param id_prof_in                      professional ID
    * @param max_vacancies_in                max vacancies
    * @param used_vacancies_in               used vacancies
    * @param id_dep_clin_serv_in             department/clinical service ID
    * @param id_room_in                      room ID                
    * @param id_sch_event_in                 schedule event ID
    * @param dt_begin_tstz_in                begin date - TSTZ
    * @param dt_end_tstz_in                  end date - TSTZ
    * @param dt_sch_consult_vacancy_tstz_in  consult_vacancy date - TSTZ
    * @param id_sch_consult_vacancy_out      output parameter - new inserted id_sch_consult_vacancy
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION ins_sch_consult_vacancy
    (
        i_lang                         IN language.id_language%TYPE,
        id_sch_consult_vacancy_in      IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_institution_in              IN sch_consult_vacancy.id_institution%TYPE DEFAULT NULL,
        id_prof_in                     IN sch_consult_vacancy.id_prof%TYPE DEFAULT NULL,
        max_vacancies_in               IN sch_consult_vacancy.max_vacancies%TYPE DEFAULT NULL,
        used_vacancies_in              IN sch_consult_vacancy.used_vacancies%TYPE DEFAULT NULL,
        id_dep_clin_serv_in            IN sch_consult_vacancy.id_dep_clin_serv%TYPE DEFAULT NULL,
        id_room_in                     IN sch_consult_vacancy.id_room%TYPE DEFAULT NULL,
        id_sch_event_in                IN sch_consult_vacancy.id_sch_event%TYPE DEFAULT NULL,
        dt_begin_tstz_in               IN sch_consult_vacancy.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_in                 IN sch_consult_vacancy.dt_end_tstz%TYPE DEFAULT NULL,
        dt_sch_consult_vacancy_tstz_in IN sch_consult_vacancy.dt_sch_consult_vacancy_tstz%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_out     OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'INS_SCH_CONSULT_VACANCY';
    BEGIN
        g_error := 'INSERT INTO SCH_CONSULT_VACANCY';
        INSERT INTO sch_consult_vacancy
            (id_sch_consult_vacancy,
             id_institution,
             id_prof,
             max_vacancies,
             used_vacancies,
             id_dep_clin_serv,
             id_room,
             id_sch_event,
             dt_begin_tstz,
             dt_end_tstz,
             dt_sch_consult_vacancy_tstz,
             flg_status)
        VALUES
            (nvl(id_sch_consult_vacancy_in, seq_sch_consult_vacancy.nextval),
             id_institution_in,
             id_prof_in,
             max_vacancies_in,
             used_vacancies_in,
             id_dep_clin_serv_in,
             id_room_in,
             id_sch_event_in,
             dt_begin_tstz_in,
             dt_end_tstz_in,
             dt_sch_consult_vacancy_tstz_in,
             pk_schedule_bo.g_status_active)
        RETURNING id_sch_consult_vacancy INTO id_sch_consult_vacancy_out;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END ins_sch_consult_vacancy;

    /**********************************************************************************************
    * API - update one row on sch_consult_vacancy table by primary key
    *
    * @param id_sch_consult_vacancy_in       consult_vacancy ID
    * @param id_institution_in               institution ID
    * @param id_institution_nin              boolean flag to accept null values   
    * @param id_prof_in                      professional ID
    * @param id_prof_nin                     boolean flag to accept null values   
    * @param dt_begin_in                     begin date
    * @param dt_begin_nin                    boolean flag to accept null values   
    * @param max_vacancies_in                max vacancies
    * @param max_vacancies_nin               boolean flag to accept null values   
    * @param used_vacancies_in               used vacancies
    * @param used_vacancies_nin              boolean flag to accept null values   
    * @param dt_end_in                       end date
    * @param dt_end_nin                      boolean flag to accept null values   
    * @param id_dep_clin_serv_in             department/clinical service ID
    * @param id_dep_clin_serv_nin            boolean flag to accept null values   
    * @param id_room_in                      room ID                
    * @param id_room_nin                     boolean flag to accept null values   
    * @param id_sch_event_in                 schedule event ID
    * @param id_sch_event_nin                boolean flag to accept null values   
    * @param dt_begin_tstz_in                begin date - TSTZ
    * @param dt_begin_tstz_nin               boolean flag to accept null values   
    * @param dt_end_tstz_in                  end date - TSTZ
    * @param dt_end_tstz_nin                 boolean flag to accept null values   
    * @param dt_sch_consult_vacancy_tstz_in  consult_vacancy date - TSTZ
    * @param dt_sch_consult_vacancy_tstz_nin boolean flag to accept null values   
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION upd_sch_consult_vacancy
    (
        i_lang                       IN language.id_language%TYPE,
        id_sch_consult_vacancy_in    IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_institution_in            IN sch_consult_vacancy.id_institution%TYPE DEFAULT NULL,
        id_institution_nin           IN BOOLEAN := TRUE,
        id_prof_in                   IN sch_consult_vacancy.id_prof%TYPE DEFAULT NULL,
        id_prof_nin                  IN BOOLEAN := TRUE,
        max_vacancies_in             IN sch_consult_vacancy.max_vacancies%TYPE DEFAULT NULL,
        max_vacancies_nin            IN BOOLEAN := TRUE,
        used_vacancies_in            IN sch_consult_vacancy.used_vacancies%TYPE DEFAULT NULL,
        used_vacancies_nin           IN BOOLEAN := TRUE,
        id_dep_clin_serv_in          IN sch_consult_vacancy.id_dep_clin_serv%TYPE DEFAULT NULL,
        id_dep_clin_serv_nin         IN BOOLEAN := TRUE,
        id_room_in                   IN sch_consult_vacancy.id_room%TYPE DEFAULT NULL,
        id_room_nin                  IN BOOLEAN := TRUE,
        id_sch_event_in              IN sch_consult_vacancy.id_sch_event%TYPE DEFAULT NULL,
        id_sch_event_nin             IN BOOLEAN := TRUE,
        dt_begin_tstz_in             IN sch_consult_vacancy.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_begin_tstz_nin            IN BOOLEAN := TRUE,
        dt_end_tstz_in               IN sch_consult_vacancy.dt_end_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_nin              IN BOOLEAN := TRUE,
        dt_sch_cons_vacancy_tstz_in  IN sch_consult_vacancy.dt_sch_consult_vacancy_tstz%TYPE DEFAULT NULL,
        dt_sch_cons_vacancy_tstz_nin IN BOOLEAN := TRUE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                  VARCHAR2(32) := 'UPD_SCH_CONSULT_VACANCY';
        l_dt_sch_consult_vacancy_n   NUMBER(1);
        l_id_institution_n           NUMBER(1);
        l_id_prof_n                  NUMBER(1);
        l_dt_begin_n                 NUMBER(1);
        l_max_vacancies_n            NUMBER(1);
        l_used_vacancies_n           NUMBER(1);
        l_dt_end_n                   NUMBER(1);
        l_id_dep_clin_serv_n         NUMBER(1);
        l_id_room_n                  NUMBER(1);
        l_id_sch_event_n             NUMBER(1);
        l_dt_begin_tstz_n            NUMBER(1);
        l_dt_end_tstz_n              NUMBER(1);
        l_dt_sch_cons_vacancy_tstz_n NUMBER(1);
    BEGIN
        l_id_institution_n           := sys.diutil.bool_to_int(id_institution_nin);
        l_id_prof_n                  := sys.diutil.bool_to_int(id_prof_nin);
        l_max_vacancies_n            := sys.diutil.bool_to_int(max_vacancies_nin);
        l_used_vacancies_n           := sys.diutil.bool_to_int(used_vacancies_nin);
        l_id_dep_clin_serv_n         := sys.diutil.bool_to_int(id_dep_clin_serv_nin);
        l_id_room_n                  := sys.diutil.bool_to_int(id_room_nin);
        l_id_sch_event_n             := sys.diutil.bool_to_int(id_sch_event_nin);
        l_dt_begin_tstz_n            := sys.diutil.bool_to_int(dt_begin_tstz_nin);
        l_dt_end_tstz_n              := sys.diutil.bool_to_int(dt_end_tstz_nin);
        l_dt_sch_cons_vacancy_tstz_n := sys.diutil.bool_to_int(dt_sch_cons_vacancy_tstz_nin);
    
        UPDATE sch_consult_vacancy
           SET id_institution = CASE
                                     WHEN l_id_institution_n = 1 THEN
                                      nvl(id_institution_in, id_institution)
                                     ELSE
                                      id_institution_in
                                 END,
               id_prof = CASE
                              WHEN l_id_prof_n = 1 THEN
                               nvl(id_prof_in, id_prof)
                              ELSE
                               id_prof_in
                          END,
               max_vacancies = CASE
                                    WHEN l_max_vacancies_n = 1 THEN
                                     nvl(max_vacancies_in, max_vacancies)
                                    ELSE
                                     max_vacancies_in
                                END,
               used_vacancies = CASE
                                     WHEN l_used_vacancies_n = 1 THEN
                                      nvl(used_vacancies_in, used_vacancies)
                                     ELSE
                                      used_vacancies_in
                                 END,
               id_dep_clin_serv = CASE
                                       WHEN l_id_dep_clin_serv_n = 1 THEN
                                        nvl(id_dep_clin_serv_in, id_dep_clin_serv)
                                       ELSE
                                        id_dep_clin_serv_in
                                   END,
               id_room = CASE
                              WHEN l_id_room_n = 1 THEN
                               nvl(id_room_in, id_room)
                              ELSE
                               id_room_in
                          END,
               id_sch_event = CASE
                                   WHEN l_id_sch_event_n = 1 THEN
                                    nvl(id_sch_event_in, id_sch_event)
                                   ELSE
                                    id_sch_event_in
                               END,
               dt_begin_tstz = CASE
                                    WHEN l_dt_begin_tstz_n = 1 THEN
                                     nvl(dt_begin_tstz_in, dt_begin_tstz)
                                    ELSE
                                     dt_begin_tstz_in
                                END,
               dt_end_tstz = CASE
                                  WHEN l_dt_end_tstz_n = 1 THEN
                                   nvl(dt_end_tstz_in, dt_end_tstz)
                                  ELSE
                                   dt_end_tstz_in
                              END,
               dt_sch_consult_vacancy_tstz = CASE
                                                  WHEN l_dt_sch_cons_vacancy_tstz_n = 1 THEN
                                                   nvl(dt_sch_cons_vacancy_tstz_in, dt_sch_consult_vacancy_tstz)
                                                  ELSE
                                                   dt_sch_cons_vacancy_tstz_in
                                              END
         WHERE id_sch_consult_vacancy = id_sch_consult_vacancy_in;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END upd_sch_consult_vacancy;

    /********************************************************************************************
    * This function determine and inserts on table sch_consult_vac_mfr_slot the free slots for a
    * sch_consult_vacancy ID 
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_id_sch_consult_vacancy        sch_consult_vacancy ID
    * @param i_id_physiatry_area             physiatry_area ID
    * @param i_id_prof_created               professional ID
    * @param i_flg_wizard                    wizard flag (Y-Yes -> Temporary slot / N-No -> Permanent slot)
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/12
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION create_slots
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_id_physiatry_area      IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE,
        i_flg_wizard             IN VARCHAR2 DEFAULT NULL,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_sch_consult_vacancy IS
            SELECT dt_begin_tstz, dt_end_tstz
              FROM sch_consult_vacancy
             WHERE id_sch_consult_vacancy = i_id_sch_consult_vacancy;
    
        CURSOR c_schedule IS
            SELECT dt_begin_tstz, dt_end_tstz
              FROM schedule
             WHERE id_sch_consult_vacancy = i_id_sch_consult_vacancy
               AND flg_status = CASE
                       WHEN nvl(i_flg_wizard, g_no) = g_no THEN
                        pk_schedule.g_sched_status_scheduled
                       ELSE
                        pk_schedule.g_sched_status_temporary
                   END
               AND schedule.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
             ORDER BY dt_begin_tstz ASC;
    
        l_func_name         VARCHAR2(32) := 'CREATE_SLOTS';
        l_dt_begin_scv      sch_consult_vacancy.dt_begin_tstz%TYPE;
        l_dt_end_scv        sch_consult_vacancy.dt_end_tstz%TYPE;
        l_dt_aux            sch_consult_vacancy.dt_end_tstz%TYPE;
        l_min_slot_interval NUMBER;
        l_dummy             sch_consult_vac_mfr.id_sch_consult_vacancy%TYPE;
    
        l_tab_dt_begin table_timestamp_tz;
        l_tab_dt_end   table_timestamp_tz;
    
    BEGIN
        -- Get configuration for minimum time for free slots
        g_error := 'GET CONFIGURATION FOR MINIMUM TIME FOR FREE SLOTS';
        BEGIN
            l_min_slot_interval := nvl(to_number(pk_sysconfig.get_config(g_sch_min_slot_interval, i_prof)), 0);
        EXCEPTION
            WHEN OTHERS THEN
                l_min_slot_interval := 0;
        END;
    
        -- Read dt_begin and dt_end from sch_consult_vacancy
        g_error := 'OPEN CURSOR C_SCH_CONSULT_VACANCY';
        OPEN c_sch_consult_vacancy;
        FETCH c_sch_consult_vacancy
            INTO l_dt_begin_scv, l_dt_end_scv;
        g_found := c_sch_consult_vacancy%FOUND;
        CLOSE c_sch_consult_vacancy;
    
        IF NOT g_found
           OR l_dt_begin_scv IS NULL
           OR l_dt_end_scv IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        -- Delete from sch_consult_vac_mfr_slot, depending i_flg_wizard (Y-Yes / N-No)
        g_error := 'DELETE SCH_CONSULT_VAC_MFR_SLOT';
        IF nvl(i_flg_wizard, g_no) = g_no
        THEN
            DELETE FROM sch_consult_vac_mfr_slot
             WHERE id_sch_consult_vacancy = i_id_sch_consult_vacancy
               AND (flg_status = pk_schedule_mfr.g_slot_status_permanent OR
                   (flg_status = pk_schedule_mfr.g_slot_status_temporary AND id_professional = i_prof.id));
        ELSE
            DELETE FROM sch_consult_vac_mfr_slot
             WHERE id_sch_consult_vacancy = i_id_sch_consult_vacancy
               AND flg_status = pk_schedule_mfr.g_slot_status_temporary
               AND id_professional = i_prof.id;
        END IF;
    
        -- Searching free slots
        l_dt_aux := l_dt_begin_scv;
    
        g_error := 'OPEN CURSOR C_SCHEDULE';
        OPEN c_schedule;
        FETCH c_schedule BULK COLLECT
            INTO l_tab_dt_begin, l_tab_dt_end;
        CLOSE c_schedule;
    
        -- Iteration between begin and end slot dates
        g_error := 'LOOP PK_SCHEDULE_MFR.INS_SCH_CONSULT_VAC_MFR_SLOT';
        FOR idx IN 1 .. l_tab_dt_begin.count
        LOOP
        
            IF (pk_date_utils.get_timestamp_diff(l_tab_dt_begin(idx), l_dt_aux) * 1440) > l_min_slot_interval
            THEN
                IF NOT pk_schedule_mfr.ins_sch_consult_vac_mfr_slot(i_lang                     => i_lang,
                                                                    id_sch_consult_vacancy_in  => i_id_sch_consult_vacancy,
                                                                    id_physiatry_area_in       => i_id_physiatry_area,
                                                                    dt_begin_tstz_in           => l_dt_aux,
                                                                    dt_end_tstz_in             => l_tab_dt_begin(idx),
                                                                    id_professional_in         => i_prof.id,
                                                                    flg_status_in              => CASE
                                                                                                      WHEN nvl(i_flg_wizard, g_no) = g_no THEN
                                                                                                       pk_schedule_mfr.g_slot_status_permanent
                                                                                                      ELSE
                                                                                                       pk_schedule_mfr.g_slot_status_temporary
                                                                                                  END,
                                                                    id_prof_created_in         => i_prof.id,
                                                                    dt_created_in              => current_timestamp,
                                                                    id_sch_consult_vac_mfr_out => l_dummy,
                                                                    o_error                    => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
            l_dt_aux := l_tab_dt_end(idx);
        END LOOP;
    
        -- Time difference between last schedule end date and vacancy end date
        g_error := 'LAST CALL PK_SCHEDULE_MFR.INS_SCH_CONSULT_VAC_MFR_SLOT';
        IF (pk_date_utils.get_timestamp_diff(l_dt_end_scv, l_dt_aux) * 1440) > l_min_slot_interval
        THEN
            IF NOT pk_schedule_mfr.ins_sch_consult_vac_mfr_slot(i_lang                     => i_lang,
                                                           id_sch_consult_vacancy_in  => i_id_sch_consult_vacancy,
                                                           id_physiatry_area_in       => i_id_physiatry_area,
                                                           dt_begin_tstz_in           => l_dt_aux,
                                                           dt_end_tstz_in             => l_dt_end_scv,
                                                           id_professional_in         => i_prof.id,
                                                           flg_status_in              => CASE
                                                                                             WHEN nvl(i_flg_wizard, g_no) = g_no THEN
                                                                                              pk_schedule_mfr.g_slot_status_permanent
                                                                                             ELSE
                                                                                              pk_schedule_mfr.g_slot_status_temporary
                                                                                         END,
                                                           id_prof_created_in         => i_prof.id,
                                                           dt_created_in              => current_timestamp,
                                                           id_sch_consult_vac_mfr_out => l_dummy,
                                                           o_error                    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END create_slots;

    /********************************************************************************************
    * This function close ONE MFR Session by id_schedule
    * and then re-create slots with flg_wizard parameter = N-No
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_id_schedule                   schedule ID
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/22
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION close_mfr_session
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_sch_consult_vacancy IS
            SELECT id_sch_consult_vacancy
              FROM schedule
             WHERE id_schedule = i_id_schedule;
    
        CURSOR c_schedule_intervention IS
            SELECT id_physiatry_area
              FROM schedule_intervention
             WHERE id_schedule = i_id_schedule
               AND flg_original = g_yes
               AND rownum < 2;
    
        l_func_name              VARCHAR2(32) := 'CLOSE_MFR_SESSION';
        l_id_sch_consult_vacancy schedule.id_sch_consult_vacancy%TYPE;
        l_id_physiatry_area      schedule_intervention.id_physiatry_area%TYPE;
        l_val_not_found EXCEPTION;
    
    BEGIN
        -- Get IDs
        g_error := 'OPEN CURSOR C_SCH_CONSULT_VACANCY';
        OPEN c_sch_consult_vacancy;
        FETCH c_sch_consult_vacancy
            INTO l_id_sch_consult_vacancy;
        g_found := c_sch_consult_vacancy%FOUND;
        CLOSE c_sch_consult_vacancy;
    
        IF NOT g_found
        THEN
            RAISE l_val_not_found;
        END IF;
    
        g_error := 'OPEN CURSOR C_SCHEDULE_INTERVENTION';
        OPEN c_schedule_intervention;
        FETCH c_schedule_intervention
            INTO l_id_physiatry_area;
        g_found := c_schedule_intervention%FOUND;
        CLOSE c_schedule_intervention;
    
        IF NOT g_found
        THEN
            RAISE l_val_not_found;
        END IF;
    
        -- Update Sch_consult_vacancy.used_vacancies
        g_error := 'UPDATE SCH_CONSULT_VACANCY.USED_VACANCIES';
        UPDATE sch_consult_vacancy
           SET used_vacancies = nvl(used_vacancies, 0) + 1
         WHERE id_sch_consult_vacancy = l_id_sch_consult_vacancy;
    
        -- Recalculate Slots
        g_error := 'CALL CREATE_SLOTS FUNCTION';
        IF NOT create_slots(i_lang                   => i_lang,
                            i_prof                   => i_prof,
                            i_id_sch_consult_vacancy => l_id_sch_consult_vacancy,
                            i_id_physiatry_area      => l_id_physiatry_area,
                            i_flg_wizard             => g_no,
                            o_error                  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END close_mfr_session;
    /********************************************************************************************
    * This function close MULTIPLE MFR Sessions, using the function <close_mfr_session> for each id_schedule on table parameter
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_tab_id_schedule               schedule ID table
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/22
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION close_mfr_sessions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name           VARCHAR2(32) := 'CLOSE_MFR_SESSIONS';
        l_id_interv_presc_det schedule_intervention.id_interv_presc_det%TYPE;
        l_num_sess_sched      interv_presc_det.num_take%TYPE;
        l_num_sess_presc      interv_presc_det.num_take%TYPE;
        l_rowids              table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'CALL CLOSE_MFR_SESSION FUNCITON TO CLOSE ALL SCHEDULE IDs';
        IF cardinality(i_tab_id_schedule) > 0
        THEN
            FOR idx IN i_tab_id_schedule.first .. i_tab_id_schedule.last
            LOOP
                IF NOT close_mfr_session(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_id_schedule => i_tab_id_schedule(idx),
                                         o_error       => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END LOOP;
        END IF;
    
        -- update prescription status, if all sessions are schedules
        IF (i_tab_id_schedule.count > 0)
        THEN
            g_error := 'GET ID_INTERV_PRESC_DET';
        
            SELECT si.id_interv_presc_det
              INTO l_id_interv_presc_det
              FROM schedule_intervention si
             WHERE si.id_schedule = i_tab_id_schedule(1)
               AND si.flg_original = g_yes
               AND rownum = 1;
        
            g_error := 'CALL PK_INTERV_MFR.UPDATE_INTERV_STATUS';
            IF NOT pk_interv_mfr.update_interv_status(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_interv_presc_det => l_id_interv_presc_det,
                                                      o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END close_mfr_sessions;

    /*
    * Get time units of schedule mechanism to fill keypad
    *
    * @param   i_lang                       Language identifier.
    * @param   i_prof                       Professional
    * @param   o_time_units                 Time units
    * @param   o_error                      Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Jose Antunes
    * @version 2.4.4
    * @since 2008/12/03
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_time_units
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_time_units OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'GET_TIME_UNITS';
        l_desc_week  VARCHAR2(32);
        l_desc_month VARCHAR2(32);
    BEGIN
    
        g_error := 'SELECT';
        SELECT pk_message.get_message(i_lang, g_msg_week), pk_message.get_message(i_lang, g_msg_month)
          INTO l_desc_week, l_desc_month
          FROM dual;
    
        g_error := 'OPEN o_time_units FOR';
        -- Open cursor
        OPEN o_time_units FOR
            SELECT DISTINCT (sr.flg_timeunit) id,
                            decode(sr.flg_timeunit, g_flg_month, l_desc_month, l_desc_week) label,
                            decode(sr.flg_timeunit, g_flg_month, g_yes, g_no) flg_default
              FROM sch_reprules sr
             ORDER BY label ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_time_units;

    /*
    * Gets weekdays by default for a given software and institution
    *
    * @param   i_lang                       Language identifier.
    * @param   i_prof                       Professional
    * @param   i_number_days                Number of days per time unit
    * @param   i_unit                       Time unit (M - month, W - week)
    * @param   i_dt_begin                   Begin date
    * @param   o_weekdays                   Weekdays
    * @param   o_error                      Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Jose Antunes
    * @version 2.4.4
    * @since 2008/11/27
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_weekdays_by_default
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_number_days IN sch_reprules.num_days%TYPE,
        i_unit        IN VARCHAR2,
        i_dt_begin    IN VARCHAR2,
        o_weekdays    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_WEEKDAYS_BY_DEFAULT';
        l_weekdays  sch_reprules.weekdays%TYPE;
        l_week_days VARCHAR2(32);
    BEGIN
    
        g_error := 'SELECT sch_reprules';
        BEGIN
            SELECT sr.weekdays
              INTO l_weekdays
              FROM sch_reprules sr
             WHERE (sr.id_institution = i_prof.institution OR sr.id_institution = 0)
               AND (sr.id_software = i_prof.software OR sr.id_software = 0)
               AND sr.num_days = i_number_days
               AND sr.flg_timeunit = i_unit;
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- nothing to do if there are no value on sch_reprules
        END;
    
        g_error := 'GET DAYS OF WEEK';
        -- IF l_weekdays = 0, the selected weekday must be the same of i_dt_begin
        IF l_weekdays = '0'
        THEN
            l_week_days := to_char(week_day_standard(to_date(i_dt_begin, 'yyyymmddhh24miss')));
        ELSE
            l_week_days := l_weekdays;
        END IF;
    
        g_error := 'OPEN o_weekdays';
        OPEN o_weekdays FOR
            SELECT decode(code_message,
                          'SCH_MONTHVIEW_SEG',
                          1,
                          'SCH_MONTHVIEW_TER',
                          2,
                          'SCH_MONTHVIEW_QUA',
                          3,
                          'SCH_MONTHVIEW_QUI',
                          4,
                          'SCH_MONTHVIEW_SEX',
                          5,
                          'SCH_MONTHVIEW_SAB',
                          6,
                          7) data,
                   a.label,
                   decode(instr(l_week_days,
                                decode(code_message,
                                       'SCH_MONTHVIEW_SEG',
                                       1,
                                       'SCH_MONTHVIEW_TER',
                                       2,
                                       'SCH_MONTHVIEW_QUA',
                                       3,
                                       'SCH_MONTHVIEW_QUI',
                                       4,
                                       'SCH_MONTHVIEW_SEX',
                                       5,
                                       'SCH_MONTHVIEW_SAB',
                                       6,
                                       7)),
                          0,
                          g_no,
                          NULL,
                          g_no,
                          g_yes) flg_select
              FROM (SELECT pk_message.get_message(i_lang, sm.code_message) AS label, code_message
                      FROM sys_message sm
                     WHERE sm.code_message IN ('SCH_MONTHVIEW_SEG',
                                               'SCH_MONTHVIEW_TER',
                                               'SCH_MONTHVIEW_QUA',
                                               'SCH_MONTHVIEW_QUI',
                                               'SCH_MONTHVIEW_SEX',
                                               'SCH_MONTHVIEW_SAB',
                                               'SCH_MONTHVIEW_DOM')
                       AND id_language = i_lang) a
             ORDER BY data;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_weekdays);
            
                RETURN FALSE;
            END;
    END get_weekdays_by_default;

    /**
    * Create and validate a set of temporary schedules
    *
    * @param i_lang                          Language
    * @param i_prof                          Professional identification
    * @param i_id_prof                       Professioanl identifier 
    * @param i_id_patient                    Patient identifier
    * @param i_id_phys_area                  Physiatry area identifier
    * @param i_duration                      Duration of the intervention in minutes
    * @param i_flg_restart                   Flag if is to restart
    * @param i_num_sessions                  Number of sessions to schedule
    * @param i_weekdays                      Weekdays selected 
    * @param i_id_interv_presc_det           Prescription ID
    * @param i_freq                          Frequency selected
    * @param i_num_take                      Number of takes per session
    * @param i_time_unit                     Time unit selected
    * @param i_begin_date                    Date selected in the calendar
    * @param i_next_begin_date               Begin date of subsequent appointments
    * @param i_next_duration                 Duration of subsequent appointments
    * @param i_room                          Room ID
    * @param i_flg_vacancy                   Flag with Vacancy type: U - Urgent, V - Unplanned, R - Routine
    * @param i_notes                         Appointment notes
    * @param i_flg_schedule_via              Flag schedule via: P - Presencial, F - Fax, O - Other, S - SMS, E - Email, T - Telephone, N - Normal
    * @param i_id_reason                     Reason ID
    * @param i_reason_notes                  Free-text for the appointment reason
    * @param i_id_lang_translator            Translator's language identifier
    * @param i_id_lang_preferred             Preferred language identifier
    * @param i_id_slot                       slot id to eventually use in the first session
    * @param i_flg_request_type              Flag request type (U - Utente, M - Médico, E - Enfermeiro, H -  Hospital, O - Outros)
    * @param i_id_origin                     Patient origin
    * @param i_id_complaint                  Complaint ID
    * @param o_error                         Error message if something goes wrong
    *
    * @return True if successful, false otherwise.  
    *
    * @author   Jose Antunes
    * @version  2.4.4
    * @since 2008/12/11
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION create_sugested_sessions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof             IN sch_consult_vacancy.id_prof%TYPE,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_phys_area        IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE,
        i_duration            IN NUMBER,
        i_flg_restart         IN VARCHAR2,
        i_num_sessions        IN NUMBER,
        i_weekdays            IN table_number,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_freq                IN NUMBER,
        i_num_take            IN schedule_recursion.num_take%TYPE,
        i_time_unit           IN VARCHAR2,
        i_begin_date          IN VARCHAR2,
        i_next_begin_date     IN VARCHAR2,
        i_next_duration       IN NUMBER,
        i_room                IN schedule.id_room%TYPE,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE,
        i_notes               IN VARCHAR2,
        i_flg_schedule_via    IN schedule.flg_schedule_via%TYPE,
        i_id_reason           IN schedule.id_reason%TYPE,
        i_reason_notes        IN schedule.reason_notes%TYPE,
        i_id_lang_translator  IN schedule.id_lang_translator%TYPE,
        i_id_lang_preferred   IN schedule.id_lang_preferred%TYPE,
        i_id_slot             IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE DEFAULT NULL,
        i_flg_request_type    IN schedule.flg_request_type%TYPE,
        i_id_origin           IN schedule.id_origin%TYPE,
        i_id_complaint        IN schedule.id_reason%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(32) := 'CREATE_SUGESTED_SESSIONS';
        l_table_count       NUMBER;
        l_str_weekdays      schedule_recursion.weekdays%TYPE;
        l_dates_tstz        table_timestamp_tz;
        l_dt_begin          TIMESTAMP WITH TIME ZONE;
        l_dt_next_begin     TIMESTAMP WITH TIME ZONE;
        l_dt_end_str        VARCHAR2(4000);
        l_dt_next_begin_str VARCHAR2(4000);
        l_dt_next_end_str   VARCHAR2(4000);
        l_regular           VARCHAR2(1) := g_no;
        l_id_sch_recursion  schedule_recursion.id_schedule_recursion%TYPE;
        l_id_schedule       schedule.id_schedule%TYPE;
        l_dummy_str         VARCHAR2(4000);
    BEGIN
    
        g_error := 'BUILD WEEKDAYS STRING';
        -- 1st step: Build string based on i_weekdays table of number
        l_table_count := i_weekdays.count;
        FOR idx IN 1 .. l_table_count
        LOOP
            l_str_weekdays := l_str_weekdays || i_weekdays(idx) || CASE
                                  WHEN idx = l_table_count THEN
                                   ''
                                  ELSE
                                   g_sep_list
                              END;
        END LOOP;
    
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_begin_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_next_begin_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_next_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_sched_dates';
        -- 4th Step: Get date list
        IF NOT pk_schedule_mfr.get_sched_dates(i_lang                => i_lang,
                                               i_id_interv_presc_det => i_id_interv_presc_det,
                                               i_sessions            => i_num_sessions,
                                               i_num_freq            => i_freq,
                                               i_tab_weekdays        => i_weekdays,
                                               i_flg_timeunit        => i_time_unit,
                                               i_sch_date_tstz       => l_dt_next_begin,
                                               i_flg_restart         => i_flg_restart,
                                               o_dates               => l_dates_tstz,
                                               o_flg_regular         => l_regular,
                                               o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CREATE SCHEDULE_RECURSION';
        -- 3nd Step: Insert on table SCHEDULE_RECURSION
        IF i_flg_restart = g_yes
        THEN
            IF NOT ins_schedule_recursion(i_lang                    => i_lang,
                                          weekdays_in               => l_str_weekdays,
                                          flg_regular_in            => l_regular,
                                          flg_timeunit_in           => i_time_unit,
                                          num_take_in               => i_num_take,
                                          num_freq_in               => i_freq,
                                          id_interv_presc_det_in    => i_id_interv_presc_det,
                                          id_schedule_recursion_out => l_id_sch_recursion,
                                          o_error                   => o_error)
            THEN
            
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL GET_TIMESTAMP_STR';
        -- Convert to string    
        l_dt_end_str := pk_date_utils.get_timestamp_str(i_lang,
                                                        i_prof,
                                                        pk_date_utils.add_to_ltstz(l_dt_begin, i_duration, 'MINUTE'),
                                                        NULL);
    
        IF NOT create_schedule(i_lang                => i_lang,
                               i_prof                => i_prof,
                               i_id_patient          => i_id_patient,
                               i_id_sch_event        => g_mfr_event,
                               i_id_prof             => i_id_prof,
                               i_dt_begin            => i_begin_date,
                               i_dt_end              => l_dt_end_str,
                               i_id_interv_presc_det => i_id_interv_presc_det,
                               i_id_phys_area        => i_id_phys_area,
                               --                               i_do_overlap          => g_yes,
                               --                               i_sch_option          => NULL,
                               i_id_room            => i_room,
                               i_flg_vacancy        => i_flg_vacancy,
                               i_schedule_notes     => i_notes,
                               i_flg_schedule_via   => i_flg_schedule_via,
                               i_id_reason          => i_id_reason,
                               i_reason_notes       => i_reason_notes,
                               i_id_lang_translator => i_id_lang_translator,
                               i_id_lang_preferred  => i_id_lang_preferred,
                               i_id_slot            => i_id_slot,
                               i_id_sch_recursion   => l_id_sch_recursion,
                               i_wizmode            => g_yes,
                               i_flg_request_type   => i_flg_request_type,
                               i_id_origin          => i_id_origin,
                               i_id_complaint       => i_id_complaint,
                               o_id_schedule        => l_id_schedule,
                               o_flg_proceed        => l_dummy_str,
                               o_flg_show           => l_dummy_str,
                               o_msg                => l_dummy_str,
                               o_msg_title          => l_dummy_str,
                               o_button             => l_dummy_str,
                               o_error              => o_error)
        THEN
        
            RETURN FALSE;
        END IF;
    
        IF (l_dates_tstz.count > 0)
        THEN
            FOR i IN l_dates_tstz.first .. l_dates_tstz.last
            LOOP
            
                g_error := 'CALL GET_TIMESTAMP_STR2';
                -- Convert to string    
                l_dt_next_begin_str := pk_date_utils.get_timestamp_str(i_lang, i_prof, l_dates_tstz(i), NULL);
                g_error             := 'CALL GET_TIMESTAMP_STR3';
                -- Convert to string    
                l_dt_next_end_str := pk_date_utils.get_timestamp_str(i_lang,
                                                                     i_prof,
                                                                     pk_date_utils.add_to_ltstz(l_dates_tstz(i),
                                                                                                i_next_duration,
                                                                                                'MINUTE'),
                                                                     NULL);
            
                g_error := 'CALL PK_SCHEDULE_MFR.CREATE_SCHEDULE';
                IF NOT create_schedule(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_patient          => i_id_patient,
                                       i_id_sch_event        => g_mfr_event,
                                       i_id_prof             => i_id_prof,
                                       i_dt_begin            => l_dt_next_begin_str,
                                       i_dt_end              => l_dt_next_end_str,
                                       i_id_interv_presc_det => i_id_interv_presc_det,
                                       i_id_phys_area        => i_id_phys_area,
                                       --                                       i_do_overlap          => g_yes,
                                       --                                       i_sch_option          => NULL,
                                       i_id_room            => i_room,
                                       i_flg_vacancy        => i_flg_vacancy,
                                       i_schedule_notes     => i_notes,
                                       i_flg_schedule_via   => i_flg_schedule_via,
                                       i_id_reason          => i_id_reason,
                                       i_reason_notes       => i_reason_notes,
                                       i_id_lang_translator => i_id_lang_translator,
                                       i_id_lang_preferred  => i_id_lang_preferred,
                                       i_id_slot            => NULL,
                                       i_id_sch_recursion   => l_id_sch_recursion,
                                       i_wizmode            => g_yes,
                                       i_flg_request_type   => i_flg_request_type,
                                       i_id_origin          => i_id_origin,
                                       o_id_schedule        => l_id_schedule,
                                       o_flg_proceed        => l_dummy_str,
                                       o_flg_show           => l_dummy_str,
                                       o_msg                => l_dummy_str,
                                       o_msg_title          => l_dummy_str,
                                       o_button             => l_dummy_str,
                                       o_error              => o_error)
                THEN
                
                    RETURN FALSE;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END create_sugested_sessions;

    /**
    * Get a set of schedules associated with an id_interv_presc_det
    *
    * @param i_lang                          Language
    * @param i_prof                          Professional identification
    * @param i_id_phys_area                  Physiatry area identifier
    * @param i_id_interv_presc_det           Prescription ID
    * @param o_weekdays                      Weekdays of each schedule created
    * @param o_dates                         Schedules dates
    * @param o_id_schedule                   Schedules IDs
    * @param o_id_profs                      Professionals assigned to each schedule
    * @param o_nick_profs                    Professionals name assigned to each schedule
    * @param o_is_perm                       Flag indicating if schedules are temporary
    * @param o_has_conflict                  Flag indicating if schedules have conflicts
    * @param o_conf_over                     Description of overlap conflict, if exists
    * @param o_conf_no_vac                   Description of no vacancy conflict, if exists
    * @param o_error                         Error message if something goes wrong
    *
    * @return True if successful, false otherwise.  
    *
    * @author   Josï¿½ Antunes
    * @version  2.4.4
    * @since 2008/12/18
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_sessions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_phys_area        IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_weekdays            OUT table_varchar,
        o_dates               OUT table_varchar,
        o_id_schedule         OUT table_number,
        o_id_profs            OUT table_number,
        o_nick_profs          OUT table_varchar,
        o_is_perm             OUT table_varchar,
        o_has_conflict        OUT table_varchar,
        o_conf_over           OUT table_varchar,
        o_conf_no_vac         OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name  VARCHAR2(32) := 'GET_SESSIONS';
        l_conflicts  table_table_varchar;
        l_durations  table_number;
        l_dates_tstz table_timestamp_tz;
    BEGIN
    
        g_error := 'SELECT schedule_intervention';
        SELECT si.id_schedule,
               to_char(s.dt_begin_tstz, 'yyyymmddhh24miss'),
               s.dt_begin_tstz,
               pk_date_utils.get_timestamp_diff(s.dt_end_tstz, s.dt_begin_tstz) * 24 * 60,
               sr.id_professional,
               pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional),
               decode(s.flg_status, pk_schedule.g_sched_status_temporary, g_no, g_yes)
          BULK COLLECT
          INTO o_id_schedule, o_dates, l_dates_tstz, l_durations, o_id_profs, o_nick_profs, o_is_perm
          FROM schedule_intervention si, schedule s, sch_resource sr
         WHERE s.id_schedule = si.id_schedule
           AND si.id_interv_presc_det = i_id_interv_presc_det
           AND si.flg_original = g_yes
           AND sr.id_schedule = s.id_schedule
           AND s.flg_status != pk_schedule.g_status_canceled
           AND s.id_prof_schedules = CASE
                   WHEN s.flg_status = pk_schedule.g_sched_status_temporary THEN
                    i_prof.id
                   ELSE
                    s.id_prof_schedules
               END
         ORDER BY s.dt_begin_tstz;
    
        g_error := 'FILL o_weekdays';
        IF NOT get_weekdays_description(i_lang     => i_lang,
                                        i_prof     => i_prof,
                                        i_dates    => o_dates,
                                        o_weekdays => o_weekdays,
                                        o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL validate_sch_dates';
        IF NOT validate_sch_dates(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_id_profs     => o_id_profs,
                                  i_id_phys_area => i_id_phys_area,
                                  i_durations    => l_durations,
                                  i_dates        => l_dates_tstz,
                                  o_conflicts    => l_conflicts,
                                  o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_has_conflict := table_varchar();
        o_conf_over    := table_varchar();
        o_conf_no_vac  := table_varchar();
        g_error        := 'FILL  o_has_conflict, o_conf_no_vac and o_conf_over';
        -- If schedule is not temporary, conflicts must be false
        IF (l_conflicts.count > 0)
        THEN
            FOR i IN l_conflicts.first .. l_conflicts.last
            LOOP
                IF o_is_perm(i) = g_yes
                THEN
                    o_has_conflict.extend;
                    o_has_conflict(i) := g_no_conflict;
                    o_conf_no_vac.extend;
                    o_conf_over.extend;
                ELSE
                    o_has_conflict.extend;
                    o_has_conflict(i) := l_conflicts(i) (2);
                    o_conf_no_vac.extend;
                    o_conf_no_vac(i) := l_conflicts(i) (3);
                    o_conf_over.extend;
                    o_conf_over(i) := l_conflicts(i) (4);
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_sessions;

    /********************************************************************************************
    * This function returns a value from 1 to 7 identifying the day of the week, where
    * Monday is 1 and Sunday is 7.
    * Note: In Oracle, depending on the NLS_Territory setting, different days of the week are 1.
    * Examples:
    *   U.S., Canada, Monday = 2;  Most European countries, Monday = 1;
    *   Most Middle-Eastern countries, Monday = 3.
    *   For Bangladesh, Monday = 4.
    *
    * @param i_date          Input date parameter
    *
    * @return                Return the day of the week
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    ********************************************************************************************/
    FUNCTION week_day_standard(i_date IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN NUMBER IS
    BEGIN
        RETURN 1 + MOD(to_number(to_char(i_date, 'J')), 7);
    END week_day_standard;

    /********************************************************************************************
    * This function returns a date with next week day applied to an input date
    *
    * @param i_date          Input date parameter
    * @param i_weekday_standard   Input weekday 
    *
    * @return                Return the date with next week day
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    ********************************************************************************************/
    FUNCTION next_day_standard
    (
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_weekday_standard IN NUMBER
    ) RETURN DATE IS
        l_offset   NUMBER;
        l_next_day TIMESTAMP WITH LOCAL TIME ZONE;
        l_a        NUMBER;
        l_b        NUMBER;
    BEGIN
        l_offset := to_number(to_char(g_ref_date, 'D'));
    
        l_a := i_weekday_standard + l_offset;
    
        l_b := MOD(l_a, 7);
        IF l_b = 0
        THEN
            l_b := 7;
        END IF;
    
        SELECT CAST(next_day(i_date, l_b) AS TIMESTAMP WITH LOCAL TIME ZONE)
          INTO l_next_day
          FROM dual;
        RETURN l_next_day;
    END next_day_standard;

    /********************************************************************************************
    * This function returns a date with previous week day applied to an input date
    *
    * @param i_date          Input date parameter
    * @param i_weekday_standard   Input weekday 
    *
    * @return                Return the date with previous week day
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    ********************************************************************************************/
    FUNCTION previous_day_standard
    (
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_weekday_standard IN NUMBER
    ) RETURN DATE IS
        l_offset       NUMBER;
        l_previous_day TIMESTAMP WITH LOCAL TIME ZONE;
        l_a            NUMBER;
        l_b            NUMBER;
    BEGIN
        l_offset := to_number(to_char(g_ref_date, 'D'));
    
        l_a := i_weekday_standard + l_offset;
    
        l_b := MOD(l_a, 7);
        IF l_b = 0
        THEN
            l_b := 7;
        END IF;
    
        SELECT CAST(next_day(pk_date_utils.add_days_to_tstz(i_date, -8), l_b) AS TIMESTAMP WITH LOCAL TIME ZONE)
          INTO l_previous_day
          FROM dual;
        RETURN l_previous_day;
    END previous_day_standard;

    /********************************************************************************************
    * This function determines proposed schedule dates, based on i_num_freq, i_flg_timeunit and i_tab_weekdays table
    *
    * @param i_lang                          language ID
    * @param i_id_interv_presc_det           Intervention Prescription Detail ID
    * @param i_sessions                      Number of sessions to schedule
    * @param i_num_freq                      Frequency
    * @param i_flg_timeunit                  Frequency Unit (S-Weekly ; M-Monthly)
    * @param i_tab_weekdays                  Table with weekdays (1-Monday..7-Sunday)
    * @param i_sch_date_tstz                 Schedule start date
    * @param i_flg_restart                   Re-start flag: no search back i_sch_date_tstz
    * @param o_dates                         Table of calculated dates
    * @param o_flg_regular                   Output parameter: Y-Regular Cycle; N-Irregular Cycle
    * @param o_error                         error message
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/12
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION get_sched_dates
    (
        i_lang                IN language.id_language%TYPE,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_sessions            IN NUMBER,
        i_num_freq            IN NUMBER,
        i_flg_timeunit        IN VARCHAR2,
        i_tab_weekdays        IN table_number,
        i_sch_date_tstz       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_restart         IN VARCHAR2,
        o_dates               OUT table_timestamp_tz,
        o_flg_regular         OUT schedule_recursion.flg_regular%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- ***************************************************
        -- Local variables
        l_func_name VARCHAR2(32) := 'GET_SCHED_DATES';
    
        l_tab_confirmed_sch table_timestamp_tz := table_timestamp_tz();
        l_tab_proposed_sch  table_timestamp_tz := table_timestamp_tz();
    
        l_dt_aux      TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_ref      TIMESTAMP WITH LOCAL TIME ZONE;
        l_factor      NUMBER;
        l_search_back BOOLEAN;
        l_sessions    NUMBER;
        l_flg_regular BOOLEAN;
    
        -- ***************************************************
        -- Local Auxiliar Procedure - merge dates into collection
        -- ***************************************************
        FUNCTION merge_dates(i_date IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN BOOLEAN IS
            l_found          BOOLEAN := FALSE;
            l_idx            NUMBER;
            l_tab_conf_count NUMBER;
            l_tab_prop_count NUMBER;
        BEGIN
            l_idx            := 1;
            l_tab_conf_count := l_tab_confirmed_sch.count;
            l_tab_prop_count := l_tab_proposed_sch.count;
        
            WHILE NOT l_found
                  AND l_idx <= l_tab_conf_count
            LOOP
                -- Compare timestamps
                l_found := trunc(l_tab_confirmed_sch(l_idx)) = trunc(i_date);
                l_idx   := l_idx + 1;
            END LOOP;
        
            IF NOT l_found
            THEN
                l_tab_proposed_sch.extend;
                l_tab_proposed_sch(l_tab_prop_count + 1) := i_date;
            END IF;
        
            RETURN l_found;
        END merge_dates;
    
        -- ***************************************************
        -- Local Auxiliar Procedure - Process irregular cycle
        -- ***************************************************
        PROCEDURE irregular_cycle IS
            l_idx           NUMBER := 1;
            l_numdays_month NUMBER;
            l_interval      NUMBER;
            l_dt_aux        TIMESTAMP WITH LOCAL TIME ZONE;
        BEGIN
            -- Number of Days and Interval for Irregular Cycle
            l_numdays_month := to_number(to_char(last_day(i_sch_date_tstz), 'DD'));
            l_interval      := round(l_numdays_month / i_num_freq);
        
            l_dt_aux := l_dt_ref;
            WHILE l_idx <= l_sessions
            LOOP
                l_dt_aux := pk_date_utils.add_days_to_tstz(l_dt_aux, l_interval * l_factor);
            
                IF l_dt_aux <= i_sch_date_tstz
                THEN
                    l_factor := 1;
                    l_dt_aux := l_dt_ref;
                ELSIF NOT merge_dates(l_dt_aux)
                THEN
                    l_idx := l_idx + 1;
                END IF;
            
            END LOOP; -- sessions
        
        END irregular_cycle;
    
        -- ***************************************************
        -- Local Auxiliar Procedure - Process regular cycle
        -- ***************************************************
        PROCEDURE regular_cycle IS
            l_dt_aux               TIMESTAMP WITH LOCAL TIME ZONE;
            l_tab_weekdays         table_number := table_number();
            l_tab_weekdays_reverse table_number := table_number();
            l_num_elements         NUMBER;
            l_find                 BOOLEAN;
            l_idx                  NUMBER;
            l_start_idx            NUMBER;
            l_weekday              NUMBER(1);
            l_num_sessions         NUMBER;
        
        BEGIN
            l_num_elements := cardinality(i_tab_weekdays);
            IF l_num_elements = 0
            THEN
                RETURN;
            END IF;
        
            -- Order i_tab_weekdays collection ascending and descending
            l_tab_weekdays.extend(l_num_elements);
        
            SELECT CAST(COLLECT(column_value) AS table_number)
              INTO l_tab_weekdays
              FROM (SELECT column_value
                      FROM TABLE(i_tab_weekdays)
                     ORDER BY 1 ASC);
        
            SELECT CAST(COLLECT(column_value) AS table_number)
              INTO l_tab_weekdays_reverse
              FROM (SELECT column_value
                      FROM TABLE(i_tab_weekdays)
                     ORDER BY 1 DESC);
        
            -- Determine the weekday of main input date (i_sch_date_tstz)
            l_weekday := week_day_standard(i_sch_date_tstz);
        
            -- Init variables
            l_dt_aux       := l_dt_ref;
            l_num_sessions := 0;
        
            -- ************ Loop BACK Algorithm: Begin
            IF l_search_back
            THEN
                l_find := FALSE;
                l_idx  := 1;
                WHILE NOT l_find
                      AND l_idx <= l_num_elements
                LOOP
                    IF l_tab_weekdays(l_idx) < l_weekday
                    THEN
                        l_start_idx := l_idx;
                        l_find      := TRUE;
                    END IF;
                    l_idx := l_idx + 1;
                END LOOP;
                IF NOT l_find
                THEN
                    l_start_idx := 1;
                END IF;
            
                WHILE l_num_sessions < l_sessions
                      AND trunc(l_dt_aux) > trunc(l_tab_confirmed_sch(1))
                LOOP
                    l_dt_aux := previous_day_standard(i_date             => l_dt_aux,
                                                      i_weekday_standard => l_tab_weekdays_reverse(l_start_idx));
                    IF NOT merge_dates(l_dt_aux)
                    THEN
                        l_num_sessions := l_num_sessions + 1;
                    END IF;
                    l_start_idx := l_start_idx + 1;
                    --restart l_start_idx
                    IF l_start_idx > l_num_elements
                    THEN
                        l_start_idx := 1;
                    END IF;
                END LOOP;
            END IF;
            -- ************ Loop BACK Algorithm: End
        
            -- Restart auxiliar variables
            l_dt_aux := l_dt_ref;
        
            -- ************ Loop FRONT Algorithm: Begin
            l_find := FALSE;
            l_idx  := 1;
            WHILE NOT l_find
                  AND l_idx <= l_num_elements
            LOOP
                IF l_tab_weekdays(l_idx) > l_weekday
                THEN
                    l_start_idx := l_idx;
                    l_find      := TRUE;
                END IF;
                l_idx := l_idx + 1;
            END LOOP;
            IF NOT l_find
            THEN
                l_start_idx := 1;
            END IF;
        
            WHILE l_num_sessions < l_sessions
            LOOP
                l_dt_aux := next_day_standard(i_date => l_dt_aux, i_weekday_standard => l_tab_weekdays(l_start_idx));
                IF NOT merge_dates(l_dt_aux)
                THEN
                    l_num_sessions := l_num_sessions + 1;
                END IF;
                l_start_idx := l_start_idx + 1;
                --re-start l_start_idx
                IF l_start_idx > l_num_elements
                THEN
                    l_start_idx := 1;
                END IF;
            END LOOP;
            -- ************ Loop FRONT Algorithm: End
        
        END regular_cycle;
    
        -- ***************************************************
        -- Local Auxiliar Procedure - weekly cycle for 1, 2, 4 days/month and 1 day/week
        -- ***************************************************
        PROCEDURE weekly_cycle IS
            l_idx        NUMBER := 1;
            l_dt_aux     TIMESTAMP WITH LOCAL TIME ZONE;
            l_dt_aux2    TIMESTAMP WITH LOCAL TIME ZONE;
            l_freq       NUMBER;
            l_flg_verify BOOLEAN;
        BEGIN
            IF i_flg_timeunit = g_flg_freq_s
            THEN
                l_freq := i_num_freq;
            ELSIF i_flg_timeunit = g_flg_freq_m
            THEN
                l_freq := CASE i_num_freq
                              WHEN 1 THEN
                               4
                              WHEN 2 THEN
                               2
                              WHEN 4 THEN
                               1
                          END;
            END IF;
        
            l_dt_aux  := l_dt_ref;
            l_dt_aux2 := l_dt_ref;
            WHILE l_idx <= l_sessions
            LOOP
                -- If need in future, validate the num_freq / unit
                l_flg_verify := (MOD(l_idx, i_num_freq) = 0) AND 1 = 2;
            
                IF l_flg_verify
                THEN
                    l_dt_aux2 := l_dt_aux;
                END IF;
            
                l_dt_aux := pk_date_utils.add_days_to_tstz(l_dt_aux, l_freq * g_weekdays * l_factor);
            
                -- Add one more week if.....
                IF l_flg_verify
                   AND to_number(to_char(l_dt_aux, 'MM')) = to_number(to_char(l_dt_aux2, 'MM'))
                THEN
                    l_dt_aux  := pk_date_utils.add_days_to_tstz(l_dt_aux, g_weekdays * l_factor);
                    l_dt_aux2 := l_dt_aux;
                END IF;
            
                IF l_dt_aux <= i_sch_date_tstz
                THEN
                    l_factor := 1;
                    l_dt_aux := l_dt_ref;
                ELSIF NOT merge_dates(l_dt_aux)
                THEN
                    l_idx := l_idx + 1;
                END IF;
            
            END LOOP; -- sessions
        
        END weekly_cycle;
    
    BEGIN
        g_error := 'DETERMINE L_FLG_REGULAR AND O_FLG_REGULAR VARIABLES';
    
        -- Determine if is a regular / irregular cycle    
        l_flg_regular := NOT i_tab_weekdays IS empty;
    
        -- Return Output parameter flg_regular ( Y - Yes; N - No)
        o_flg_regular := CASE
                             WHEN l_flg_regular THEN
                              g_yes
                             ELSE
                              g_no
                         END;
    
        -- **********************************************************************
        -- Collect confirmed schedules dates to verify if calculated date exists on it
        g_error := 'COLLECT CONFIRMED SCHEDULES';
        SELECT sch.dt_begin_tstz
          BULK COLLECT
          INTO l_tab_confirmed_sch
          FROM schedule_intervention schi
         INNER JOIN schedule sch
            ON schi.id_schedule = sch.id_schedule
         WHERE schi.id_interv_presc_det = i_id_interv_presc_det
           AND schi.flg_original = g_yes
           AND sch.flg_status = pk_schedule.g_sched_status_scheduled
         ORDER BY sch.dt_begin_tstz ASC;
    
        -- Reference date: if exists confirmed schedule, then min(date) from schedules;
        --                 else reference date assumes input parameter date
        -- Note: l_search_back - flag that forces search backward on time until l_dt_ref - reference date
        IF nvl(i_flg_restart, g_no) = g_no
        THEN
            l_search_back := (l_tab_confirmed_sch.count > 0);
        
            IF l_search_back
            THEN
                IF trunc(i_sch_date_tstz) < trunc(l_tab_confirmed_sch(1))
                THEN
                    l_search_back := FALSE;
                ELSE
                    l_search_back := TRUE;
                END IF;
            END IF;
        
        ELSE
            l_search_back := FALSE;
        END IF;
    
        IF l_search_back
        THEN
            l_factor := -1;
        ELSE
            l_factor := 1;
        END IF;
    
        -- reference date
        l_dt_ref := i_sch_date_tstz;
    
        -- Determine the number of sessions to be calculated
        l_sessions := i_sessions - l_tab_proposed_sch.count;
    
        -- Determine the workflow procedure
        IF (i_flg_timeunit = g_flg_freq_m AND i_num_freq IN (1, 2, 4))
           OR (i_flg_timeunit = g_flg_freq_s AND i_num_freq IN (1))
        THEN
            g_error := 'CALL WEEKLY_CYCLE LOCAL FUNCTION';
            weekly_cycle;
        ELSIF NOT l_flg_regular
        THEN
            g_error := 'CALL IRREGULAR_CYCLE LOCAL FUNCTION';
            irregular_cycle;
        ELSE
            g_error := 'CALL REGULAR_CYCLE LOCAL FUNCTION';
            regular_cycle;
        END IF;
    
        -- Return table with proposed schedule dates    
        o_dates := l_tab_proposed_sch;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_sched_dates;

    /********************************************************************************************
    * This function validate conflits before save to database
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_id_profs                      scheduled professional IDs
    * @param i_id_phys_area                  physician area ID
    * @param i_tab_id_schedule               schedule IDs table
    * @param i_tab_conflit                   last conflits table: 0-No conflit; 1-No Vacancy Conflict; 2-Over Slot Conflict
    * @param o_has_changes                   flag indicate changes since last calculation 
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/22
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION validate_before_save
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_profs        IN table_number,
        i_id_phys_area    IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE,
        i_tab_id_schedule IN table_number,
        i_tab_conflict    IN table_number, -- 0-No conflit; 1-No Vacancy Conflict; 2-Over Slot Conflict
        o_has_changes     OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'VALIDATE_BEFORE_SAVE';
        l_dt_begin_tstz table_timestamp_tz;
        l_dt_end_tstz   table_timestamp_tz;
        l_durations     table_number := table_number();
        l_conflits      table_table_varchar;
        l_days          NUMBER;
        l_hours         NUMBER;
        l_minutes       NUMBER;
        l_seconds       NUMBER;
    BEGIN
        o_has_changes := g_no;
        g_error       := 'GET DATES';
        SELECT sch.dt_begin_tstz, sch.dt_end_tstz
          BULK COLLECT
          INTO l_dt_begin_tstz, l_dt_end_tstz
          FROM schedule sch
         WHERE sch.id_schedule IN (SELECT column_value
                                     FROM TABLE(i_tab_id_schedule))
         ORDER BY sch.dt_begin_tstz;
        g_error := 'LOOP';
        IF (l_dt_begin_tstz.count > 0)
        THEN
            FOR idx IN l_dt_begin_tstz.first .. l_dt_begin_tstz.last
            LOOP
            
                IF NOT pk_date_utils.get_timestamp_diff_sep(i_lang        => i_lang,
                                                            i_timestamp_1 => l_dt_end_tstz(idx),
                                                            i_timestamp_2 => l_dt_begin_tstz(idx),
                                                            o_days        => l_days,
                                                            o_hours       => l_hours,
                                                            o_minutes     => l_minutes,
                                                            o_seconds     => l_seconds,
                                                            o_error       => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                -- Duration - Minutes
                l_durations.extend;
                l_durations(idx) := trunc(l_days * 24 + l_hours * 60 + l_minutes + l_seconds / 60);
            END LOOP;
        END IF;
    
        g_error := 'CALL VALIDATE_SCH_DATES';
        IF NOT validate_sch_dates(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_id_profs     => i_id_profs,
                                  i_id_phys_area => i_id_phys_area,
                                  i_durations    => l_durations,
                                  i_dates        => l_dt_begin_tstz,
                                  o_conflicts    => l_conflits,
                                  o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Compare values between l_conflicts table and i_tab_no_vacancy / i_tab_over_slot tables
        g_error := 'COMPARE CONFLICTS';
        IF (l_conflits.count > 0)
        THEN
            FOR idx IN l_conflits.first .. l_conflits.last
            LOOP
                IF l_conflits(idx) (2) != i_tab_conflict(idx)
                   AND l_conflits(idx) (2) != '0'
                THEN
                    o_has_changes := g_yes;
                END IF;
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END validate_before_save;

    /********************************************************************************************
    * This function deletes permanently the temporary schedules by professional ID
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_id_interv_presc_det           Prescription ID
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2009/01/05
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION delete_temp_schedules
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name       VARCHAR2(32) := 'DELETE_TEMP_SCHEDULES';
        l_tab_id_schedule table_number;
        l_tab_id_vac      table_number;
        l_id_schedule     schedule.id_schedule%TYPE;
    BEGIN
        g_error := 'COLLECT SCHEDULE IDs';
        SELECT s.id_schedule, s.id_sch_consult_vacancy
          BULK COLLECT
          INTO l_tab_id_schedule, l_tab_id_vac
          FROM schedule s, schedule_intervention si
         WHERE s.id_schedule = si.id_schedule
           AND id_prof_schedules = i_prof.id
           AND si.flg_original = g_yes
           AND flg_status = pk_schedule_mfr.g_slot_status_temporary
           AND flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
           AND (s.dt_schedule_tstz < current_timestamp - 1 OR si.id_interv_presc_det = i_id_interv_presc_det);
    
        -- delete sch_consult_vac_mfr_slot
        g_error := 'DELETE TEMPORARY SLOT FOR PROFESSIONAL ID';
        DELETE sch_consult_vac_mfr_slot
         WHERE flg_status = pk_schedule_mfr.g_slot_status_temporary
           AND id_sch_consult_vacancy IN (SELECT *
                                            FROM TABLE(l_tab_id_vac));
    
        IF cardinality(l_tab_id_schedule) = 0
        THEN
            RETURN TRUE;
        END IF;
    
        FOR i IN l_tab_id_schedule.first .. l_tab_id_schedule.last
        LOOP
            l_id_schedule := l_tab_id_schedule(i);
        
            -- delete sch_group
            g_error := 'DELETE SCH_GROUP';
            DELETE sch_group
             WHERE sch_group.id_schedule = l_id_schedule;
        
            -- delete sch_resource
            g_error := 'DELETE SCH_RESOURCE';
            DELETE sch_resource
             WHERE sch_resource.id_schedule = l_id_schedule;
        
            -- delete schedule_intervention
            g_error := 'DELETE SCHEDULE_INTERVENTION';
            DELETE schedule_intervention
             WHERE id_schedule = l_id_schedule;
        
        END LOOP;
    
        -- delete schedule
        g_error := 'DELETE SCHEDULE - COLLECTED IDs';
        FORALL i IN l_tab_id_schedule.first .. l_tab_id_schedule.last
            DELETE schedule
             WHERE id_schedule = l_tab_id_schedule(i);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END delete_temp_schedules;

    /**
    * Create and validate a set of temporary and dependent schedules
    *
    * @param i_lang                          Language
    * @param i_prof                          Professional identification
    * @param i_id_interv_presc_det           Prescription ID
    * @param i_id_patient                    Patient identifier
    * @param i_num_sessions                  Number of sessions to schedule
    * @param o_error                         Error message if something goes wrong
    *
    * @return True if successful, false otherwise.  
    *
    * @author   Jose Antunes
    * @version  2.4.4
    * @since 2009/01/08
    *
    * UPDATED
    * ALERT-16144 - sql tuning. Tambem corrigi select ... into
    * @author  Telmo Castro 
    * @date    04-02-2009
    * @version 2.4.4
    *
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION create_dependent_sessions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_num_sessions        IN NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(32) := 'CREATE_DEPENDENT_SESSIONS';
        l_dates_tstz         table_timestamp_tz;
        l_dt_next_begin      TIMESTAMP WITH TIME ZONE;
        l_dt_next_begin_str  VARCHAR2(4000);
        l_dt_next_end_str    VARCHAR2(4000);
        l_regular            VARCHAR2(1) := g_no;
        l_id_sch_recursion   schedule_recursion.id_schedule_recursion%TYPE;
        l_id_schedule        schedule.id_schedule%TYPE;
        l_dummy_str          VARCHAR2(4000);
        l_begin_date         schedule.dt_begin_tstz%TYPE;
        l_freq               schedule_recursion.num_freq%TYPE;
        l_weekdays           schedule_recursion.weekdays%TYPE;
        l_flg_time_unit      schedule_recursion.flg_timeunit%TYPE;
        l_table_weekdays     table_number;
        l_id_physiatry_area  schedule_intervention.id_physiatry_area%TYPE;
        l_id_room            schedule.id_room%TYPE;
        l_flg_vacancy        schedule.flg_vacancy%TYPE;
        l_sch_notes          schedule.schedule_notes%TYPE;
        l_flg_sch_via        schedule.flg_schedule_via%TYPE;
        l_id_reason          schedule.id_reason%TYPE;
        l_reason_notes       schedule.reason_notes%TYPE;
        l_id_lang_translator schedule.id_lang_translator%TYPE;
        l_id_lang_preferred  schedule.id_lang_preferred%TYPE;
        l_id_prof            sch_resource.id_professional%TYPE;
        l_duration           NUMBER;
        l_id_sch             schedule.id_schedule%TYPE;
    
    BEGIN
    
        -- Get definitions of first schedule from the last set of id_schedule_recursion of an i_id_interv_presc_det
        g_error := 'CALC SCHEDULE TO GET INFORMATION';
        SELECT id_schedule
          INTO l_id_sch
          FROM (SELECT sch.id_schedule
                  FROM schedule sch
                 WHERE sch.id_sch_event = g_mfr_event
                   AND sch.flg_status != pk_schedule.g_sched_status_temporary
                   AND sch.id_schedule_recursion = (SELECT MAX(s.id_schedule_recursion)
                                                      FROM schedule_intervention si, schedule s
                                                     WHERE s.id_schedule = si.id_schedule
                                                       AND si.id_interv_presc_det = i_id_interv_presc_det
                                                       AND si.flg_original = g_yes)
                 ORDER BY sch.dt_begin_tstz)
         WHERE rownum = 1;
    
        g_error := 'GET INFORMATION' || l_id_sch;
        SELECT sr.weekdays,
               sr.num_freq,
               sr.flg_timeunit,
               sr.id_schedule_recursion,
               si.id_physiatry_area,
               sre.id_professional,
               s.dt_begin_tstz,
               s.id_room,
               s.flg_vacancy,
               s.schedule_notes,
               s.flg_schedule_via,
               s.id_reason,
               s.reason_notes,
               s.id_lang_translator,
               s.id_lang_preferred,
               pk_date_utils.get_timestamp_diff(s.dt_end_tstz, s.dt_begin_tstz) * 24 * 60
          INTO l_weekdays,
               l_freq,
               l_flg_time_unit,
               l_id_sch_recursion,
               l_id_physiatry_area,
               l_id_prof,
               l_begin_date,
               l_id_room,
               l_flg_vacancy,
               l_sch_notes,
               l_flg_sch_via,
               l_id_reason,
               l_reason_notes,
               l_id_lang_translator,
               l_id_lang_preferred,
               l_duration
          FROM schedule_intervention si
          JOIN schedule s
            ON si.id_schedule = s.id_schedule
          LEFT JOIN schedule_recursion sr
            ON s.id_schedule_recursion = sr.id_schedule_recursion
          LEFT JOIN sch_resource sre
            ON s.id_schedule = sre.id_schedule
         WHERE s.id_schedule = l_id_sch
           AND si.flg_original = g_yes;
    
        g_error := 'CALL GET_TABLE_NUMBERS';
        -- create table of weekdays
        l_table_weekdays := get_table_numbers(l_weekdays, pk_schedule_mfr.g_sep_list);
    
        g_error := 'CALC GET_SCHED_DATES';
        IF NOT pk_schedule_mfr.get_sched_dates(i_lang                => i_lang,
                                               i_id_interv_presc_det => i_id_interv_presc_det,
                                               i_sessions            => i_num_sessions,
                                               i_num_freq            => l_freq,
                                               i_tab_weekdays        => l_table_weekdays,
                                               i_flg_timeunit        => l_flg_time_unit,
                                               i_sch_date_tstz       => l_begin_date,
                                               i_flg_restart         => g_no,
                                               o_dates               => l_dates_tstz,
                                               o_flg_regular         => l_regular, -- not needed here
                                               o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'START FOR';
        IF (l_dates_tstz.count > 0)
        THEN
            FOR i IN l_dates_tstz.first .. l_dates_tstz.last
            LOOP
            
                g_error := 'CALL GET_TIMESTAMP_STR2';
                -- Convert to string    
                l_dt_next_begin_str := pk_date_utils.get_timestamp_str(i_lang, i_prof, l_dates_tstz(i), NULL);
                g_error             := 'CALL GET_TIMESTAMP_STR3';
                -- Convert to string    
                l_dt_next_end_str := pk_date_utils.get_timestamp_str(i_lang,
                                                                     i_prof,
                                                                     pk_date_utils.add_to_ltstz(l_dates_tstz(i),
                                                                                                l_duration,
                                                                                                'MINUTE'),
                                                                     NULL);
            
                g_error := 'CALL PK_SCHEDULE_MFR.CREATE_SCHEDULE';
                IF NOT pk_schedule_mfr.create_schedule(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_patient          => i_id_patient,
                                                       i_id_sch_event        => g_mfr_event,
                                                       i_id_prof             => l_id_prof,
                                                       i_dt_begin            => l_dt_next_begin_str,
                                                       i_dt_end              => l_dt_next_end_str,
                                                       i_id_interv_presc_det => i_id_interv_presc_det,
                                                       i_id_phys_area        => l_id_physiatry_area,
                                                       i_id_room             => l_id_room,
                                                       i_flg_vacancy         => l_flg_vacancy,
                                                       i_schedule_notes      => l_sch_notes,
                                                       i_flg_schedule_via    => l_flg_sch_via,
                                                       i_id_reason           => l_id_reason,
                                                       i_reason_notes        => l_reason_notes,
                                                       i_id_lang_translator  => l_id_lang_translator,
                                                       i_id_lang_preferred   => l_id_lang_preferred,
                                                       i_id_slot             => NULL,
                                                       i_id_sch_recursion    => l_id_sch_recursion,
                                                       i_wizmode             => g_yes,
                                                       o_id_schedule         => l_id_schedule,
                                                       o_flg_proceed         => l_dummy_str,
                                                       o_flg_show            => l_dummy_str,
                                                       o_msg                 => l_dummy_str,
                                                       o_msg_title           => l_dummy_str,
                                                       o_button              => l_dummy_str,
                                                       o_error               => o_error)
                THEN
                
                    RETURN FALSE;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END create_dependent_sessions;

    /********************************************************************************************
    * Overload da get_count_and_rank para se poder usar dentro de queries
    *
    * @param i_lang                          language ID
    * @param i_id_schedule                   schedule ID
    * @param i_flg_wizard                    wizard flag (Y-Yes -> Scheduled / N-No -> Temporaray)
    * @param i_id_interv_presc_det           intervention prescription ID
    *
    * @return                                o_rank,o_count (varchar)
    *
    * @author                Telmo
    * @version               V.2.4.3.x
    * @since                 2009/01/08
    * @alteration            Joao Martins 2009/01/29 Added parameter i_id_interv_presc_det
    ********************************************************************************************/
    FUNCTION get_count_and_rank
    (
        i_lang                IN language.id_language%TYPE,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        i_flg_wizard          IN VARCHAR2 DEFAULT NULL,
        i_id_interv_presc_det IN schedule_intervention.id_interv_presc_det%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_count NUMBER;
        l_rank  NUMBER;
        o_error t_error_out;
        ret_val VARCHAR2(200) := ' ';
    BEGIN
        IF get_count_and_rank(i_lang                => i_lang,
                              i_id_schedule         => i_id_schedule,
                              i_flg_wizard          => i_flg_wizard,
                              i_id_interv_presc_det => i_id_interv_presc_det,
                              o_count               => l_count,
                              o_rank                => l_rank,
                              o_error               => o_error)
        THEN
            ret_val := l_rank || '/' || l_count;
        END IF;
    
        RETURN ret_val;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN ret_val;
        
    END get_count_and_rank;

    /**
    * Determines if the given schedule information follow schedule rules : 
    *  general rules: see function pk_schedule.validate_schedule
    *  specific rules: skips the rule begin date cannot be inferior to current date
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type   
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.        
    * @param o_flg_show           Set if a message is displayed or not 
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.    
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Telmo Castro
    * @version  2.4.4
    * @date     08-01-2009
    *
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION validate_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        o_flg_proceed      OUT VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(18) := 'VALIDATE_SCHEDULE';
        i           NUMBER;
        l_exists200 BOOLEAN := FALSE;
        l_msg_stack pk_schedule.t_msg_stack;
    BEGIN
        o_flg_proceed := g_yes;
        o_flg_show    := g_no;
        g_error       := 'CALL PK_SCHEDULE.VALIDATE_SCHEDULE';
    
        -- Perform general validations.
        IF NOT pk_schedule.validate_schedule(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_id_patient       => i_id_patient,
                                             i_id_dep_clin_serv => i_id_dep_clin_serv,
                                             i_id_sch_event     => i_id_sch_event,
                                             i_id_prof          => i_id_prof,
                                             i_dt_begin         => i_dt_begin,
                                             o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        ------- CREATE RETURN MESSAGE ------------------------------------------------------------------------
        g_error := 'Processing return message';
    
        IF pk_schedule.g_msg_stack.count > 1
        THEN
            o_msg_title := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_button    := pk_schedule.g_cancel_button_code ||
                           pk_message.get_message(i_lang, pk_schedule.g_cancel_button) || '|';
        
            -- Telmo 29-08-2008. procura pela mensagem da data de agendamento inferior a' data actual
            i := pk_schedule.g_msg_stack.first;
            WHILE i IS NOT NULL
                  AND l_exists200 = FALSE
            LOOP
                l_msg_stack := pk_schedule.g_msg_stack(i);
                o_msg       := l_msg_stack.msg;
                l_exists200 := l_msg_stack.idxmsg = pk_schedule.g_begindatelower;
                i           := pk_schedule.g_msg_stack.next(i);
            END LOOP;
        
            -- acrescenta o botao de prosseguir se essa mensagem nao esta' na stack
            IF NOT nvl(l_exists200, FALSE)
            THEN
                pk_schedule.message_flush(o_msg);
                o_button := o_button || pk_schedule.g_ok_button_code ||
                            pk_message.get_message(i_lang, pk_schedule.g_sched_msg_ignore_proceed) || '|';
            END IF;
            o_flg_show    := g_yes;
            o_flg_proceed := g_yes;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END validate_schedule;

    /**
    * Determines if the given schedule information follow schedule rules : 
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *  - First appointment should not exist if a first appointment is being created
    *  - Episode validations
    *  - physiatry area must remain the same
    *
    * @param i_lang                   Language.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Old schedule identifier.
    * @param i_id_dep_clin_serv       Department-Clinical service identifier.
    * @param i_id_prof                Professional that carries out the schedule.
    * @param i_dt_begin               Begin date.
    * @param i_id_phys_area           new physiatry area. must be the same
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    *
    * @author   Telmo Castro
    * @version  2.4.4
    * @date     08-01-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION validate_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_id_sch_event    IN schedule.id_sch_event%TYPE,
        i_id_prof         IN sch_resource.id_professional%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_id_phys_area    IN schedule_intervention.id_physiatry_area%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(19) := 'VALIDATE_RESCHEDULE';
        l_id_pa     schedule_intervention.id_physiatry_area%TYPE;
        l_dummy     VARCHAR2(1);
    BEGIN
        o_flg_proceed := g_yes;
        o_flg_show    := g_no;
    
        SELECT id_physiatry_area
          INTO l_id_pa
          FROM schedule_intervention
         WHERE id_schedule = i_old_id_schedule
           AND flg_original = g_yes
           AND rownum = 1;
    
        IF i_id_phys_area <> l_id_pa
        THEN
            o_msg_title := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_ack_title);
        
            o_msg    := pk_message.get_message(i_lang, pk_schedule_mfr.g_sched_msg_resched_bad_proc);
            o_button := pk_schedule.g_ok_button_code || pk_schedule.get_message(i_lang, pk_schedule.g_msg_ack) || '|';
        
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            RETURN TRUE;
        END IF;
    
        RETURN pk_schedule.validate_reschedule(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_old_id_schedule  => i_old_id_schedule,
                                               i_id_dep_clin_serv => NULL,
                                               i_id_sch_event     => i_id_sch_event,
                                               i_id_prof          => i_id_prof,
                                               i_dt_begin         => i_dt_begin,
                                               o_sv_stop          => l_dummy,
                                               o_flg_proceed      => o_flg_proceed,
                                               o_flg_show         => o_flg_show,
                                               o_msg              => o_msg,
                                               o_msg_title        => o_msg_title,
                                               o_button           => o_button,
                                               o_error            => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END validate_reschedule;

    /*
    * Returns the translation needs for use on the translators' cross-view.
    * Adapted from pk_schedule.get_translators_crossview
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_args           UI Args.
    * @param i_wizmode        Y = wizard mode.  N = standard mode. Affects the output of function get_schedules.
    * @param o_schedules      Translation needs.
    * @param o_error          Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo
    * @version  2.4.4
    * @date     12-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_translators_crossview
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        i_wizmode   IN VARCHAR2,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'GET_TRANSLATORS_CROSSVIEW';
        l_time_grain VARCHAR2(2) DEFAULT 'DD';
        l_schedules  table_number;
        l_diff_ts    NUMBER;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_TIMESTAMP_DIFF_STR';
        -- Get difference in days, between timestamps
        IF NOT pk_date_utils.get_timestamp_diff_str(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_timestamp_1 => i_args(pk_schedule_common.idx_dt_end),
                                                    i_timestamp_2 => i_args(pk_schedule_common.idx_dt_begin),
                                                    o_days_diff   => l_diff_ts,
                                                    o_error       => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'GET TIME GRAIN';
        IF l_diff_ts > 1
        THEN
            -- Truncate date to the day.
            l_time_grain := 'DD';
        ELSE
            -- Truncate date to the minute.
            l_time_grain := 'MI';
        END IF;
    
        g_error := 'CALL GET_SCHEDULES';
        -- Get schedules
        IF NOT get_schedules(i_lang       => i_lang,
                             i_prof       => i_prof,
                             i_id_patient => NULL,
                             i_args       => i_args,
                             i_wizmode    => i_wizmode,
                             o_schedules  => l_schedules,
                             o_error      => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_schedules FOR';
        -- Get schedules
        OPEN o_schedules FOR
            SELECT pk_date_utils.date_send_tsz(i_lang,
                                               pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz, l_time_grain),
                                               i_prof) dt_begin,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_sched_language_domain, s.id_lang_translator) desc_language,
                   s.id_lang_translator,
                   COUNT(s.id_lang_translator) num_schedules
              FROM schedule s
             WHERE s.id_schedule IN (SELECT *
                                       FROM TABLE(l_schedules))
             GROUP BY pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz, l_time_grain), s.id_lang_translator
             ORDER BY dt_begin, desc_language;
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END;
    END get_translators_crossview;

    /*
    * Gets the availability for the cross-view.
    * Adapted from homonymous function in pk_schedule.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional.
    * @param i_args         UI args.
    * @param i_wizmode      Y = wizard mode. Means that i_prof is editing some prescription's schedules, therefore temporary schedules are visible
    * @param o_vacants      Vacancies.
    * @param o_schedules    Schedules.
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.4.4
    * @date    19-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_availability_crossview
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        i_wizmode   IN VARCHAR2,
        o_vacants   OUT pk_types.cursor_type,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'GET_AVAILABILITY_CROSSVIEW';
        l_schedules  table_number;
        l_time_grain VARCHAR2(2) DEFAULT 'DD';
        l_diff_ts    NUMBER;
    
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_TIMESTAMP_DIFF_STR';
        -- Get difference in days, between timestamps
        IF NOT pk_date_utils.get_timestamp_diff_str(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_timestamp_1 => i_args(pk_schedule_common.idx_dt_end),
                                                    i_timestamp_2 => i_args(pk_schedule_common.idx_dt_begin),
                                                    o_days_diff   => l_diff_ts,
                                                    o_error       => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'GET TIME GRAIN';
        IF l_diff_ts > 1
        THEN
            -- Truncate date to the day.
            l_time_grain := 'DD';
        ELSE
            -- Truncate date to the minute.
            l_time_grain := 'MI';
        END IF;
    
        g_error := 'CALL GET_VACANCIES';
        -- Get vacancies that match the given criteria
        IF NOT get_vacancies(i_lang    => i_lang,
                             i_prof    => i_prof,
                             i_args    => i_args,
                             i_wizmode => i_wizmode,
                             o_error   => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_vacants);
            pk_types.open_my_cursor(o_schedules);
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_AVAILABLE_VACANCIES';
        -- Get available vacancies only (the ones that not clash with any absence period).
        IF NOT get_available_vacancies(i_lang => i_lang, i_prof => i_prof, o_error => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_vacants);
            pk_types.open_my_cursor(o_schedules);
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_vacants FOR';
        -- Get vacants
        OPEN o_vacants FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, dt_begin, i_prof) dt_begin,
                   id_prof,
                   nick_name,
                   nvl(SUM(numvacancies), 0) num_vacancies,
                   id_sch_event,
                   id_dep_clin_serv,
                   id_dep,
                   id_physiatry_area,
                   desc_phys_area
              FROM (SELECT pk_date_utils.trunc_insttimezone(i_prof, scv.dt_begin_tstz, l_time_grain) dt_begin,
                           scv.id_prof,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, scv.id_prof) nick_name,
                           used_vacancies,
                           scv.id_sch_event,
                           scv.id_dep_clin_serv,
                           (SELECT id_department
                              FROM dep_clin_serv
                             WHERE id_dep_clin_serv = scv.id_dep_clin_serv) id_dep,
                           scvm.id_physiatry_area,
                           pk_translation.get_translation(i_lang, code_physiatry_area) desc_phys_area,
                           (SELECT COUNT(1)
                              FROM sch_consult_vac_mfr_slot sl
                             WHERE sl.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
                               AND sl.flg_status = g_slot_status_permanent) numvacancies
                      FROM sch_consult_vacancy scv
                      JOIN sch_tmptab_vacs_mfr m
                        ON scv.id_sch_consult_vacancy = m.id_sch_consult_vacancy
                      JOIN sch_consult_vac_mfr scvm
                        ON scv.id_sch_consult_vacancy = scvm.id_sch_consult_vacancy
                      JOIN physiatry_area pa
                        ON scvm.id_physiatry_area = pa.id_physiatry_area)
             GROUP BY dt_begin, id_prof, id_sch_event, id_dep_clin_serv, id_physiatry_area, desc_phys_area
             ORDER BY dt_begin, id_prof;
    
        g_error := 'CALL GET_SCHEDULES';
        -- Get schedules
        IF NOT get_schedules(i_lang       => i_lang,
                             i_prof       => i_prof,
                             i_id_patient => NULL,
                             i_args       => i_args,
                             i_wizmode    => i_wizmode,
                             o_schedules  => l_schedules,
                             o_error      => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_schedules);
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_schedules FOR';
        -- Get schedules
        OPEN o_schedules FOR
            SELECT pk_date_utils.date_send_tsz(i_lang,
                                               pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz, l_time_grain),
                                               i_prof) dt_begin,
                   sr.id_professional id_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional) nick_name,
                   s.id_sch_event,
                   dcs.id_dep_clin_serv,
                   dcs.id_department id_dep,
                   si.id_physiatry_area,
                   pk_translation.get_translation(i_lang, code_physiatry_area) desc_phys_area
              FROM schedule s
              LEFT JOIN sch_resource sr
                ON s.id_schedule = sr.id_schedule
              JOIN schedule_intervention si
                ON s.id_schedule = si.id_schedule
              JOIN physiatry_area pa
                ON si.id_physiatry_area = pa.id_physiatry_area
              JOIN dep_clin_serv dcs
                ON s.id_dcs_requested = dcs.id_dep_clin_serv
             WHERE s.id_schedule IN (SELECT *
                                       FROM TABLE(l_schedules))
               AND si.flg_original = g_yes
             ORDER BY dt_begin_tstz, id_prof, id_physiatry_area;
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_vacants);
                pk_types.open_my_cursor(o_schedules);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END;
    END get_availability_crossview;

    /*
    * Gets a patient's events that are inside a time range.
    * Adapted from pk_schedule.get_proximity_events.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_id_patient     Patient identifier.
    * @param i_dt_schedule    Selected date.
    * @param i_wizmode        Y =wizard mode
    * @param o_future_apps    List of events.
    * @param o_error          Error message (if an error occurred).
    *
    * @return     boolean type       "False" on error or "True" if success
    *
    * @author  Telmo Castro
    * @date    12-01-2009
    * @version 2.4.4
    * 
    * OPTIMIZED
    * ALERT-16144 - sql tuning
    * @author  Telmo Castro 
    * @date    04-02-2009
    * @version 2.4.4
    *
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_proximity_events
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_dt_schedule IN VARCHAR2,
        i_wizmode     IN VARCHAR2,
        o_future_apps OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_PROXIMITY_EVENTS';
        l_config        sys_config.value%TYPE;
        l_days_range    NUMBER(24);
        l_num_records   NUMBER(4);
        l_dt_schedule   TIMESTAMP WITH TIME ZONE;
        l_trunc_dt_sch  TIMESTAMP WITH TIME ZONE;
        l_trunc_dt_curr TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        g_error := 'CHECK PATIENT';
        -- If the patient is null, then we jump out of the function.
        IF i_id_patient IS NULL
        THEN
            pk_types.open_my_cursor(o_future_apps);
            RETURN TRUE;
        END IF;
        pk_date_utils.set_dst_time_check_off;
        IF i_dt_schedule IS NOT NULL
        THEN
            g_error := 'CALL GET_STRING_TSTZ';
            -- Convert to timestamp
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dt_schedule,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_schedule,
                                                 o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL GET_TIMESTAMP_INSTTIMEZONE';
            -- Get the current timestamp at the preferred time zone
            IF NOT pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                            i_inst      => i_prof.institution,
                                                            i_timestamp => current_timestamp,
                                                            o_timestamp => l_dt_schedule,
                                                            o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'GET_CONFIG RANGE';
        -- Get range for filtering events by the proximity to the current date.
        IF NOT (pk_schedule.get_config(i_lang         => i_lang,
                                       i_id_sysconfig => pk_schedule.g_range_proximity_events,
                                       i_prof         => i_prof,
                                       o_config       => l_config,
                                       o_error        => o_error))
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error      := 'GET NUMERIC RANGE';
        l_days_range := to_number(l_config);
    
        g_error := pk_schedule.g_sch_max_rec_events;
        -- Get range for filtering events by the proximity to the current date.
        IF NOT (pk_schedule.get_config(i_lang         => i_lang,
                                       i_id_sysconfig => pk_schedule.g_sch_max_rec_events,
                                       i_prof         => i_prof,
                                       o_config       => l_config,
                                       o_error        => o_error))
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error       := 'GET NUMBER OF RECORDS';
        l_num_records := to_number(l_config);
    
        -- Check if the date is valid or not.
        IF i_dt_schedule IS NULL
        THEN
            l_days_range := 365;
        END IF;
    
        g_error := 'CALL TRUNC_INSTTIMEZONE FOR l_trunc_dt_sch';
        -- Truncate dt_schedule
        IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_timestamp => l_dt_schedule,
                                                o_timestamp => l_trunc_dt_sch,
                                                o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TRUNC_INSTTIMEZONE FOR l_trunc_dt_curr';
        -- Truncate current_timestamp
        IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_timestamp => current_timestamp,
                                                o_timestamp => l_trunc_dt_curr,
                                                o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_future_apps FOR';
        -- Open cursor
        OPEN o_future_apps FOR
            SELECT *
              FROM (SELECT CASE
                                WHEN rcount > l_num_records THEN
                                 g_yes
                            
                                ELSE
                                 g_no
                            END flg_max_rec,
                           id_schedule,
                           pk_schedule_common.get_translation_alias(i_lang, i_prof, id_sch_event, code_sch_event) desc_event,
                           pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                           pk_schedule.string_date(i_lang, i_prof, dt_begin_tstz) desc_dt_begin,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) nick_prof,
                           pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_vacancy_domain, flg_vacancy) desc_type,
                           pk_date_utils.to_char_insttimezone(i_prof, dt_begin_tstz, pk_schedule.g_default_time_mask_msg) hour_begin,
                           pk_schedule.string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                           pk_schedule.string_reason(i_lang, i_prof, id_reason, flg_reason_type) desc_reason,
                           nvl(desc_room, pk_translation.get_translation(i_lang, code_room)) desc_room,
                           pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_status_domain, flg_status) desc_status,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_schedules) desc_author,
                           pk_schedule.string_date(i_lang, i_prof, dt_schedule_tstz) desc_dt_schedule,
                           schedule_notes notes,
                           decode(v_dt_begin, NULL, g_no, g_yes) flg_prof_vacant,
                           pk_schedule.g_icon_prefix ||
                           decode(v_dt_begin,
                                  NULL,
                                  pk_sysdomain.get_img(i_lang,
                                                       pk_schedule.g_schedule_status_prof_vac,
                                                       pk_schedule.g_without_vacant),
                                  pk_sysdomain.get_img(i_lang,
                                                       pk_schedule.g_schedule_status_prof_vac,
                                                       pk_schedule.get_image_name(i_lang,
                                                                                  i_prof,
                                                                                  pk_schedule.g_schedule_status_prof_vac,
                                                                                  id_schedule))) img_prof_vacant,
                           pk_schedule.string_language(i_lang, id_lang_preferred) desc_lang_preferred,
                           pk_schedule.string_language(i_lang, id_lang_translator) desc_lang_translator,
                           pk_schedule.get_domain_desc(i_lang, pk_schedule.g_sched_flg_notif_status, flg_notification) notification_status,
                           pk_translation.get_translation(i_lang, code_sch_event_abrv) desc_event_abrv,
                           pk_schedule.string_origin(i_lang, id_origin) desc_origin
                      FROM (SELECT COUNT(1) over(PARTITION BY 1 ORDER BY 1) rcount,
                                   s.id_schedule,
                                   se.code_sch_event,
                                   s.dt_begin_tstz,
                                   s.dt_end_tstz,
                                   sr.id_professional,
                                   s.flg_vacancy,
                                   s.id_reason,
                                   r.code_room,
                                   s.flg_status,
                                   s.id_prof_schedules,
                                   s.dt_schedule_tstz,
                                   s.schedule_notes,
                                   vacants.dt_begin v_dt_begin,
                                   s.id_lang_preferred,
                                   s.id_lang_translator,
                                   s.flg_notification,
                                   se.code_sch_event_abrv,
                                   s.id_origin,
                                   r.desc_room,
                                   s.flg_reason_type,
                                   se.id_sch_event
                              FROM schedule s
                              JOIN sch_event se
                                ON se.id_sch_event = s.id_sch_event
                              LEFT JOIN sch_resource sr
                                ON sr.id_schedule = s.id_schedule
                              LEFT JOIN sch_group sg
                                ON sg.id_schedule = s.id_schedule
                              JOIN patient pat
                                ON pat.id_patient = sg.id_patient
                              LEFT JOIN room r
                                ON s.id_room = r.id_room
                              LEFT JOIN ( --todo o tipo de vagas excepto as de mfr
                                        SELECT pk_date_utils.trunc_insttimezone(i_prof, dt_begin_tstz) dt_begin
                                          FROM sch_consult_vacancy scv
                                          JOIN sch_event sev
                                            ON scv.id_sch_event = sev.id_sch_event
                                         WHERE scv.id_institution = i_prof.institution
                                           AND scv.id_prof = i_prof.id
                                           AND scv.max_vacancies > scv.used_vacancies
                                           AND scv.dt_begin_tstz >=
                                               pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, -l_days_range)
                                           AND scv.dt_begin_tstz <
                                               pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, l_days_range)
                                           AND scv.dt_begin_tstz >= l_trunc_dt_curr
                                           AND sev.dep_type <> pk_schedule_common.g_sch_dept_flg_dep_type_pm
                                           AND scv.flg_status = pk_schedule_bo.g_status_active
                                        UNION
                                        -- vagas mfr
                                        SELECT pk_date_utils.trunc_insttimezone(i_prof, scvms.dt_begin_tstz) dt_begin
                                          FROM sch_consult_vacancy scv
                                          JOIN sch_consult_vac_mfr_slot scvms
                                            ON scv.id_sch_consult_vacancy = scvms.id_sch_consult_vacancy
                                         WHERE scv.id_institution = i_prof.institution
                                           AND scv.id_prof = i_prof.id
                                           AND scvms.dt_begin_tstz >=
                                               pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, -l_days_range)
                                           AND scvms.dt_begin_tstz <
                                               pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, l_days_range)
                                           AND scvms.dt_begin_tstz >= l_trunc_dt_curr
                                           AND scv.flg_status = pk_schedule_bo.g_status_active
                                           AND scvms.flg_status = g_slot_status_permanent) vacants
                                ON pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz) = vacants.dt_begin
                             WHERE s.dt_begin_tstz >= pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, -l_days_range)
                               AND s.dt_begin_tstz < pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, l_days_range)
                               AND s.flg_status IN (pk_schedule.g_status_scheduled, pk_schedule.g_status_pending)
                               AND sg.id_patient = i_id_patient
                               AND s.dt_begin_tstz >= l_trunc_dt_curr
                             ORDER BY s.dt_begin_tstz)
                     WHERE rownum <= l_num_records);
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_future_apps);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END;
    END get_proximity_events;

    /*
    * Returns data for the multiple search cross-view. 
    * Adapted from pk_schedule.get_availability. 
    *
    * @param i_lang      Language identifier.
    * @param i_prof      professional calling this
    * @param i_args      table of i_args. Each i_args is a set of search criteria
    * @param o_vacants   the resulting list of vacancies
    * @param o_schedules the resulting list of schedules
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.4.4
    * @date    13-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */

    FUNCTION get_availability_cross_mult
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_table_varchar,
        i_wizmode   IN VARCHAR2,
        o_vacants   OUT pk_types.cursor_type,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'GET_AVAILABILITY_CROSS_MULT';
        l_vacancies  table_number;
        l_schedules  table_number;
        l_time_grain VARCHAR2(2);
        l_diff_ts    NUMBER;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_TIMESTAMP_DIFF_STR';
        -- Get difference in days, between timestamps
        IF NOT pk_date_utils.get_timestamp_diff_str(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_timestamp_1 => i_args(1) (pk_schedule_common.idx_dt_end),
                                                    i_timestamp_2 => i_args(1) (pk_schedule_common.idx_dt_begin),
                                                    o_days_diff   => l_diff_ts,
                                                    o_error       => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'GET TIME GRAIN';
        -- Get the time grain (days or minutes) depending on the date search gap.
        IF l_diff_ts > 1
        THEN
            l_time_grain := 'DD';
        ELSE
            l_time_grain := 'MI';
        END IF;
    
        g_error := 'CALL GET_VAC_AND_SCH_MULT';
        -- Get vacancies and schedules that match the each of the criteria sets, on the
        -- dates that match all the criteria sets.
        IF NOT get_vac_and_sch_mult(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_args       => i_args,
                                    i_id_patient => NULL,
                                    i_wizmode    => i_wizmode,
                                    o_vacancies  => l_vacancies,
                                    o_schedules  => l_schedules,
                                    o_error      => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_AVAILABLE_VACANCIES';
        -- Get available vacancies only (the ones that not clash with any absence period).
        IF NOT get_available_vacancies(i_lang => i_lang, i_prof => i_prof, o_error => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_vacants FOR';
        -- Open cursor containing vacancies' information
    
        OPEN o_vacants FOR
            SELECT id_sch_consult_vacancy,
                   pk_date_utils.date_send_tsz(i_lang, dt_begin, i_prof) dt_begin,
                   id_dcs,
                   to_char(id_sch_event) id_sch_event,
                   id_prof,
                   id_physiatry_area,
                   desc_phys_area,
                   SUM(numvacancies) num_vacancies
              FROM (SELECT scv.id_sch_consult_vacancy,
                           pk_date_utils.trunc_insttimezone(i_prof, scv.dt_begin_tstz, l_time_grain) dt_begin,
                           scv.id_dep_clin_serv id_dcs,
                           scv.id_sch_event id_sch_event,
                           scv.id_prof id_prof,
                           scvm.id_physiatry_area,
                           pk_translation.get_translation(i_lang, pa.code_physiatry_area) desc_phys_area,
                           (SELECT COUNT(1)
                              FROM sch_consult_vac_mfr_slot sl
                             WHERE sl.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
                               AND sl.flg_status = g_slot_status_permanent) numvacancies
                      FROM sch_consult_vacancy scv
                      JOIN sch_consult_vac_mfr scvm
                        ON scv.id_sch_consult_vacancy = scvm.id_sch_consult_vacancy
                      JOIN physiatry_area pa
                        ON scvm.id_physiatry_area = pa.id_physiatry_area
                     WHERE scv.id_sch_consult_vacancy IN (SELECT *
                                                            FROM TABLE(l_vacancies)))
            
             GROUP BY id_sch_consult_vacancy,
                      dt_begin,
                      id_dcs,
                      id_sch_event,
                      id_prof,
                      id_physiatry_area,
                      desc_phys_area
             ORDER BY id_sch_event, dt_begin;
    
        g_error := 'OPEN o_schedules FOR';
        -- Open cursor containing schedules' information
        OPEN o_schedules FOR
            SELECT s.id_schedule,
                   s.id_sch_consult_vacancy,
                   pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof) dt_begin,
                   pk_schedule.string_clin_serv_by_dcs(i_lang, s.id_dcs_requested) ||
                   decode(sr.id_professional,
                          NULL,
                          NULL,
                          chr(13) || pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional)) desc_dcs,
                   s.id_dcs_requested,
                   to_char(s.id_sch_event) id_sch_event,
                   sr.id_professional id_prof,
                   si.id_physiatry_area,
                   pk_translation.get_translation(i_lang, pa.code_physiatry_area) desc_phys_area
              FROM schedule s
              LEFT JOIN sch_resource sr
                ON s.id_schedule = sr.id_schedule
              JOIN schedule_intervention si
                ON s.id_schedule = si.id_schedule
              JOIN physiatry_area pa
                ON si.id_physiatry_area = pa.id_physiatry_area
             WHERE s.id_schedule IN (SELECT *
                                       FROM TABLE(l_schedules))
               AND si.flg_original = g_yes
             ORDER BY id_sch_event, s.dt_begin_tstz;
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_vacants);
                pk_types.open_my_cursor(o_schedules);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END;
    END get_availability_cross_mult;

    /*
    * Gets a professional's schedules that are inside a time range.
    * Adapted from the homonymous function in pk_schedule.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_dt_schedule    Selected date
    * @param i_args           UI search arguments
    * @param i_wizmode        Y = wizard mode. needed for the get_schedules call.
    * @param o_future_apps    List of events.
    * @param o_error          Error message (if an error occurred).
    *
    * @author     Telmo
    * @version    2.4.4
    * @date       14-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_proximity_schedules
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_schedule IN VARCHAR2,
        i_args        IN table_varchar,
        i_wizmode     IN VARCHAR2,
        o_future_apps OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_PROXIMITY_SCHEDULES';
        l_config        sys_config.value%TYPE;
        l_days_range    NUMBER(24);
        l_num_records   NUMBER(4);
        l_schedules     table_number;
        l_schedules_mfr table_number;
        l_dt_schedule   TIMESTAMP WITH TIME ZONE;
        l_trunc_dt_sch  TIMESTAMP WITH TIME ZONE;
        l_trunc_dt_curr TIMESTAMP WITH TIME ZONE;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        IF i_dt_schedule IS NOT NULL
        THEN
            g_error := 'CALL GET_STRING_TSTZ';
            -- Convert to timestamp
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dt_schedule,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_schedule,
                                                 o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL GET_TIMESTAMP_INSTTIMEZONE';
            -- Get the current timestamp at the preferred time zone
            IF NOT pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                            i_inst      => i_prof.institution,
                                                            i_timestamp => current_timestamp,
                                                            o_timestamp => l_dt_schedule,
                                                            o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'GET_CONFIG RANGE';
        -- Get range for filtering events by the proximity to the current date.
        IF NOT (pk_schedule.get_config(i_lang         => i_lang,
                                       i_id_sysconfig => pk_schedule.g_range_proximity_sch,
                                       i_prof         => i_prof,
                                       o_config       => l_config,
                                       o_error        => o_error))
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error      := 'GET NUMERIC RANGE ';
        l_days_range := to_number(l_config);
    
        g_error := pk_schedule.g_sch_max_rec_events;
        -- Get range for filtering events by the proximity to the current date.
        IF NOT (pk_schedule.get_config(i_lang         => i_lang,
                                       i_id_sysconfig => pk_schedule.g_sch_max_rec_schedules,
                                       i_prof         => i_prof,
                                       o_config       => l_config,
                                       o_error        => o_error))
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        l_num_records := to_number(l_config);
    
        -- Check if the date is valid or not.
        IF i_dt_schedule IS NULL
        THEN
            l_days_range := 365;
        END IF;
    
        -- get compliant non-MFR schedules 
        IF NOT pk_schedule_common.get_schedules(i_lang, i_prof, NULL, i_args, l_schedules, o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- get compliant MFR schedules 
        IF NOT get_schedules(i_lang, i_prof, NULL, i_args, i_wizmode, l_schedules_mfr, o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TRUNC_INSTTIMEZONE FOR l_trunc_dt_sch';
        -- Truncate dt_schedule
        IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_timestamp => l_dt_schedule,
                                                o_timestamp => l_trunc_dt_sch,
                                                o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TRUNC_INSTTIMEZONE FOR l_trunc_dt_curr';
        -- Truncate current_timestamp
        IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_timestamp => current_timestamp,
                                                o_timestamp => l_trunc_dt_curr,
                                                o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_future_apps FOR';
        -- Open cursor
        OPEN o_future_apps FOR
        -- fetch schedules for non-MFR schedulers
            SELECT CASE
                        WHEN rcount > l_num_records THEN
                         g_yes
                        ELSE
                         g_no
                    END flg_max_rec,
                   id_schedule,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, id_sch_event, code_sch_event) desc_event,
                   pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                   pk_schedule.string_date(i_lang, i_prof, dt_begin_tstz) desc_dt_begin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) nick_prof,
                   pk_schedule.string_clin_serv_by_dcs(i_lang, id_dcs_requested) desc_dcs,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_vacancy_domain, flg_vacancy) desc_type,
                   pk_date_utils.to_char_insttimezone(i_prof, dt_begin_tstz, pk_schedule.g_default_time_mask_msg) hour_begin,
                   pk_schedule.string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                   pk_schedule.string_reason(i_lang, i_prof, id_reason, flg_reason_type) desc_reason,
                   nvl(desc_room, pk_translation.get_translation(i_lang, code_room)) desc_room,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_status_domain, flg_status) desc_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_schedules) desc_author,
                   pk_schedule.string_date(i_lang, i_prof, dt_schedule_tstz) desc_dt_schedule,
                   schedule_notes notes,
                   decode(v_dt_begin, NULL, g_no, g_yes) flg_prof_vacant,
                   pk_schedule.g_icon_prefix ||
                   decode(v_dt_begin,
                          NULL,
                          pk_sysdomain.get_img(i_lang,
                                               pk_schedule.g_schedule_status_prof_vac,
                                               pk_schedule.g_without_vacant),
                          pk_sysdomain.get_img(i_lang,
                                               pk_schedule.g_schedule_status_prof_vac,
                                               pk_schedule.get_image_name(i_lang,
                                                                          i_prof,
                                                                          pk_schedule.g_schedule_status_prof_vac,
                                                                          id_schedule))) img_prof_vacant,
                   pk_schedule.string_language(i_lang, id_lang_preferred) desc_lang_preferred,
                   pk_schedule.string_language(i_lang, id_lang_translator) desc_lang_translator,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_sched_flg_notif_status, flg_notification) notification_status,
                   pk_translation.get_translation(i_lang, code_sch_event_abrv) desc_event_abrv,
                   pk_schedule.string_origin(i_lang, id_origin) desc_origin
              FROM (SELECT COUNT(1) over(PARTITION BY 1 ORDER BY 1) rcount,
                           s.id_schedule,
                           se.code_sch_event,
                           sr.id_professional,
                           s.id_dcs_requested,
                           s.flg_vacancy,
                           s.dt_begin_tstz,
                           s.dt_end_tstz,
                           s.id_reason,
                           r.code_room,
                           s.flg_status,
                           s.id_prof_schedules,
                           s.dt_schedule_tstz,
                           s.schedule_notes,
                           vacants.dt_begin v_dt_begin,
                           s.id_lang_preferred,
                           s.id_lang_translator,
                           s.flg_notification,
                           se.code_sch_event_abrv,
                           s.id_origin,
                           r.desc_room,
                           s.flg_reason_type,
                           se.id_sch_event
                      FROM schedule s,
                           sch_resource sr,
                           sch_group sg,
                           sch_event se,
                           patient pat,
                           dep_clin_serv dcs,
                           room r,
                           (SELECT DISTINCT pk_date_utils.trunc_insttimezone(i_prof, dt_begin_tstz) dt_begin
                              FROM (SELECT scv.dt_begin_tstz
                                      FROM sch_consult_vacancy scv
                                     WHERE scv.id_institution = i_prof.institution
                                       AND scv.id_prof = i_prof.id
                                       AND scv.max_vacancies > scv.used_vacancies
                                       AND scv.dt_begin_tstz >=
                                           pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, -l_days_range)
                                       AND scv.dt_begin_tstz <
                                           pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, l_days_range)
                                       AND scv.dt_begin_tstz >= l_trunc_dt_curr
                                       AND scv.flg_status = pk_schedule_bo.g_status_active)) vacants
                     WHERE s.id_room = r.id_room(+)
                       AND sr.id_schedule(+) = s.id_schedule
                       AND sg.id_schedule(+) = s.id_schedule
                       AND pat.id_patient(+) = sg.id_patient
                       AND se.id_sch_event = s.id_sch_event
                       AND dcs.id_dep_clin_serv = s.id_dcs_requested
                       AND s.id_schedule IN (SELECT *
                                               FROM TABLE(l_schedules))
                       AND pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz) = vacants.dt_begin(+)
                       AND s.dt_begin_tstz >= l_trunc_dt_curr
                     ORDER BY s.dt_begin_tstz)
             WHERE rownum <= l_num_records
            UNION
            -- fetch MFR schedules
            SELECT CASE
                       WHEN rcount > l_num_records THEN
                        g_yes
                       ELSE
                        g_no
                   END flg_max_rec,
                   id_schedule,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, id_sch_event, code_sch_event) desc_event,
                   pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                   pk_schedule.string_date(i_lang, i_prof, dt_begin_tstz) desc_dt_begin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) nick_prof,
                   pk_schedule.string_clin_serv_by_dcs(i_lang, id_dcs_requested) desc_dcs,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_vacancy_domain, flg_vacancy) desc_type,
                   pk_date_utils.to_char_insttimezone(i_prof, dt_begin_tstz, pk_schedule.g_default_time_mask_msg) hour_begin,
                   pk_schedule.string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                   pk_schedule.string_reason(i_lang, i_prof, id_reason, flg_reason_type) desc_reason,
                   nvl(desc_room, pk_translation.get_translation(i_lang, code_room)) desc_room,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_status_domain, flg_status) desc_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_schedules) desc_author,
                   pk_schedule.string_date(i_lang, i_prof, dt_schedule_tstz) desc_dt_schedule,
                   schedule_notes notes,
                   decode(id_sch_consult_vacancy, NULL, g_no, g_yes) flg_prof_vacant,
                   pk_schedule.g_icon_prefix ||
                   decode(id_sch_consult_vacancy,
                          NULL,
                          pk_sysdomain.get_img(i_lang,
                                               pk_schedule.g_schedule_status_prof_vac,
                                               pk_schedule.g_without_vacant),
                          pk_sysdomain.get_img(i_lang,
                                               pk_schedule.g_schedule_status_prof_vac,
                                               pk_schedule.get_image_name(i_lang,
                                                                          i_prof,
                                                                          pk_schedule.g_schedule_status_prof_vac,
                                                                          id_schedule))) img_prof_vacant,
                   pk_schedule.string_language(i_lang, id_lang_preferred) desc_lang_preferred,
                   pk_schedule.string_language(i_lang, id_lang_translator) desc_lang_translator,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_sched_flg_notif_status, flg_notification) notification_status,
                   pk_translation.get_translation(i_lang, code_sch_event_abrv) desc_event_abrv,
                   pk_schedule.string_origin(i_lang, id_origin) desc_origin
              FROM (SELECT COUNT(1) over(PARTITION BY 1 ORDER BY 1) rcount,
                           s.id_schedule,
                           se.code_sch_event,
                           sr.id_professional,
                           s.id_dcs_requested,
                           s.flg_vacancy,
                           s.dt_begin_tstz,
                           s.dt_end_tstz,
                           s.id_reason,
                           r.code_room,
                           s.flg_status,
                           s.id_prof_schedules,
                           s.dt_schedule_tstz,
                           s.schedule_notes,
                           s.id_lang_preferred,
                           s.id_lang_translator,
                           s.flg_notification,
                           se.code_sch_event_abrv,
                           s.id_origin,
                           s.id_sch_consult_vacancy,
                           r.desc_room,
                           s.flg_reason_type,
                           se.id_sch_event
                      FROM schedule      s,
                           sch_resource  sr,
                           sch_group     sg,
                           sch_event     se,
                           patient       pat,
                           dep_clin_serv dcs,
                           room          r
                     WHERE s.id_room = r.id_room(+)
                       AND sr.id_schedule(+) = s.id_schedule
                       AND sg.id_schedule(+) = s.id_schedule
                       AND pat.id_patient(+) = sg.id_patient
                       AND se.id_sch_event = s.id_sch_event
                       AND dcs.id_dep_clin_serv = s.id_dcs_requested
                       AND s.id_schedule IN (SELECT *
                                               FROM TABLE(l_schedules_mfr))
                       AND s.dt_begin_tstz >= l_trunc_dt_curr
                     ORDER BY s.dt_begin_tstz)
             WHERE rownum <= l_num_records;
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_future_apps);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END;
    END get_proximity_schedules;

    /**
    * Retrieve statistics for the available and scheduled appointments
    * Adapted from pk_schedule.get_schedules_statistics.
    *
    * @param      i_lang             Professional default language
    * @param      i_prof             Professional object which refers the identity of the function caller
    * @param      i_args             Arguments used to retrieve stats
    * @param      i_wizmode          Y= wizard mode. relevant only in the code that deals with MFR stuff
    * @param      o_vacants          Vacants information
    * @param      o_schedules        Schedule information
    * @param      o_titles           Title information
    * @param      o_flg_vancay       Vacancy flags information
    * @param      o_error            Error information if exists
    *
    * @return     boolean type       "False" on error or "True" if success
    * 
    * @author   Telmo Castro
    * @version  2.4.4
    * @date     19-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_schedules_statistics
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_args        IN table_varchar,
        i_wizmode     IN VARCHAR2,
        o_vacants     OUT pk_types.cursor_type,
        o_schedules   OUT pk_types.cursor_type,
        o_titles      OUT pk_types.cursor_type,
        o_flg_vacancy OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCHEDULES_STATISTICS';
    
        l_list_vacancies  table_number; -- to hold vacancies retrieved with pk_schedule_common.get_vacancies
        l_list_schedules  table_number;
        l_list_schedules2 table_number;
    
        -- Inner function for getting vacants.
        FUNCTION inner_get_vacants(i_list_vacancies table_number) RETURN pk_types.cursor_type IS
            c_vacants pk_types.cursor_type;
        BEGIN
            -- Available Vacants
            g_error := 'OPEN c_vacants FOR';
            OPEN c_vacants FOR
                SELECT se.id_sch_event intern_name, SUM(scv.max_vacancies - scv.used_vacancies) vacancies
                  FROM sch_consult_vacancy scv, sch_event se
                 WHERE se.id_sch_event = scv.id_sch_event
                   AND scv.id_sch_consult_vacancy IN (SELECT *
                                                        FROM TABLE(i_list_vacancies))
                 GROUP BY se.id_sch_event
                UNION
                SELECT se.id_sch_event, SUM(m.num_slots_perm)
                  FROM sch_tmptab_vacs_mfr m
                  JOIN sch_consult_vacancy v
                    ON m.id_sch_consult_vacancy = v.id_sch_consult_vacancy
                  JOIN sch_event se
                    ON v.id_sch_event = se.id_sch_event
                 GROUP BY se.id_sch_event
                 ORDER BY intern_name;
        
            RETURN c_vacants;
        END inner_get_vacants;
    
        FUNCTION inner_get_schedules(i_list_schedules table_number) RETURN pk_types.cursor_type IS
            c_schedules pk_types.cursor_type;
        BEGIN
            g_error := 'OPEN c_schedules FOR';
            -- Schedules
            OPEN c_schedules FOR
                SELECT se.id_sch_event intern_name, s.flg_vacancy status, COUNT(s.id_schedule) num_schedules
                  FROM schedule s, sch_event se
                 WHERE se.id_sch_event = s.id_sch_event
                   AND s.id_schedule IN (SELECT *
                                           FROM TABLE(i_list_schedules))
                   AND s.flg_status <> pk_schedule.g_sched_status_cancelled
                 GROUP BY se.id_sch_event, s.flg_vacancy
                 ORDER BY se.id_sch_event;
            RETURN c_schedules;
        END inner_get_schedules;
    
        FUNCTION inner_get_titles RETURN pk_types.cursor_type IS
            c_titles pk_types.cursor_type;
            l_events table_number;
        BEGIN
            l_events := pk_schedule.get_list_number_csv(i_args(pk_schedule.idx_event));
            g_error  := 'OPEN c_titles FOR';
            OPEN c_titles FOR
                SELECT /*+ first_rows */
                 se.id_sch_event,
                 pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
                 pk_translation.get_translation(i_lang, code_sch_event_abrv) desc_abrv_event,
                 (SELECT decode(COUNT(1), 0, g_yes, g_no)
                    FROM sch_event_inst sei
                   WHERE sei.id_institution = i_args(pk_schedule.idx_id_inst)
                     AND sei.id_sch_event = se.id_sch_event
                     AND active = g_yes) flg
                  FROM sch_event se, sch_department sd
                 WHERE se.id_sch_event IN (SELECT *
                                             FROM TABLE(l_events))
                   AND se.dep_type = sd.flg_dep_type
                   AND sd.id_department = i_args(pk_schedule.idx_id_dep);
        
            RETURN c_titles;
        END inner_get_titles;
    
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        -- Get vacancy identifiers of non-mfr kind
        g_error := 'CALL PK_SCHEDULE_COMMON.GET_VACANCIES';
        IF NOT pk_schedule_common.get_vacancies(i_lang => i_lang,
                                                i_prof => i_prof,
                                                i_args => i_args,
                                                --o_vacancies => l_list_vacancies,
                                                o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- get vacancies ids of mfr kind
        g_error := 'CALL GET_VACANCIES';
        IF NOT get_vacancies(i_lang    => i_lang,
                             i_prof    => i_prof,
                             i_args    => i_args,
                             i_wizmode => i_wizmode,
                             o_error   => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- mix all vacancies and serve chilled
        g_error   := 'GET INNER_GET_VACANTS';
        o_vacants := inner_get_vacants(l_list_vacancies);
    
        -- Get schedule identifiers of non-mfr kind
        g_error := 'CALL PK_SCHEDULE.GET_SCHEDULES';
        IF NOT pk_schedule_common.get_schedules(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_patient => NULL,
                                                i_args       => i_args,
                                                o_schedules  => l_list_schedules,
                                                o_error      => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- Get schedule identifiers of mfr kind
        g_error := 'CALL GET_SCHEDULES';
        IF NOT get_schedules(i_lang       => i_lang,
                             i_prof       => i_prof,
                             i_id_patient => NULL,
                             i_args       => i_args,
                             i_wizmode    => i_wizmode,
                             o_schedules  => l_list_schedules2,
                             o_error      => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- mix and grind
        l_list_schedules := l_list_schedules MULTISET UNION DISTINCT l_list_schedules2;
    
        -- Get schedules
        g_error     := 'GET SCHEDULES';
        o_schedules := inner_get_schedules(l_list_schedules);
    
        -- Get title information
        g_error  := 'GET TITLES';
        o_titles := inner_get_titles();
    
        pk_date_utils.set_dst_time_check_on;
        -- Get list of vacancy flags.
        g_error := 'GET FLG_VACANCY LIST';
        RETURN pk_sysdomain.get_domains(i_lang        => i_lang,
                                        i_code_domain => pk_schedule.g_schedule_flg_vacancy_domain,
                                        i_prof        => i_prof,
                                        o_domains     => o_flg_vacancy,
                                        o_error       => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_schedules);
                pk_types.open_my_cursor(o_vacants);
                pk_types.open_my_cursor(o_titles);
                pk_types.open_my_cursor(o_flg_vacancy);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END;
    END get_schedules_statistics;

    /**
    * This function returns the availability for each day on a given period.
    * For that, it considers one or more lists of search criteria.
    * Each day can be fully scheduled, half scheduled or empty.
    * Adapted from pk_schedule original.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                UI search criteria matrix (each element represent a search criteria set).
    * @param i_id_patient          Patient.
    * @param i_wizmode             Y = wizard mode
    * @param o_days_status         List of status per date.
    * @param o_days_date           List of dates.
    * @param o_days_free           List of total free slots per date.
    * @param o_days_sched          List of total schedules per date.
    * @param o_patient_icons       Patient icons for showing the days when the patient has schedules.
    * @param o_error               Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.4.4
    * @date    21-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_availability_mult
    (
        i_lang          IN language.id_language%TYPE DEFAULT NULL,
        i_prof          IN profissional,
        i_args          IN table_table_varchar,
        i_id_patient    IN patient.id_patient%TYPE,
        i_wizmode       IN VARCHAR2,
        o_days_status   OUT table_varchar,
        o_days_date     OUT table_varchar,
        o_days_free     OUT table_number,
        o_days_sched    OUT table_number,
        o_patient_icons OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_args           table_varchar;
        l_vacancies      table_number;
        l_schedules      table_number;
        l_days_conflicts table_number;
        l_days_tempor    table_varchar;
    
        l_dates          table_timestamp_tz := table_timestamp_tz();
        l_pos            NUMBER := 0;
        l_start_date     TIMESTAMP WITH TIME ZONE;
        l_end_date       TIMESTAMP WITH TIME ZONE;
        l_dates_str      table_varchar := table_varchar();
        l_start_date_aux DATE;
        l_func_name      VARCHAR2(32) := 'GET_AVAILABILITY_MULT';
        l_argsm          table_varchar;
        i                INTEGER;
        curex EXCEPTION;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'START';
        IF i_args IS NOT NULL
           AND i_args.count > 0
        THEN
            g_error := 'CALL GET_VAC_AND_SCH_MULT';
            -- Get vacancies and schedules that match the each of the criteria sets, on the
            -- dates that match all the criteria sets.
            IF NOT get_vac_and_sch_mult(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_patient => NULL,
                                        i_args       => i_args,
                                        i_wizmode    => i_wizmode,
                                        o_vacancies  => l_vacancies,
                                        o_schedules  => l_schedules,
                                        o_error      => o_error)
            THEN
                RAISE curex;
            END IF;
        
            g_error := 'GET TRUNCATED START DATE';
            -- Get start date
            IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => i_args(1) (pk_schedule.idx_dt_begin),
                                                       o_timestamp => l_start_date,
                                                       o_error     => o_error)
            THEN
                RAISE curex;
            END IF;
        
            g_error := 'GET TRUNCATED END DATE';
            -- Get end date
            IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => i_args(1) (pk_schedule.idx_dt_end),
                                                       o_timestamp => l_end_date,
                                                       o_error     => o_error)
            THEN
                RAISE curex;
            END IF;
        
            -- Use dates to generate string representations, due to DST changes.
            -- A 12 hour interval is added to allow the Flash layer to safely ignore
            -- time (DST changes).
            l_start_date_aux := CAST(l_start_date AS DATE);
        
            g_error := 'GENERATE DATES';
            -- Generate all the dates between start and end dates
            -- 0.5 is used as tolerance due to DST changes.
            WHILE (pk_date_utils.get_timestamp_diff(l_end_date, l_start_date) > 0.5)
            LOOP
                l_dates.extend;
                l_dates_str.extend;
                l_pos := l_pos + 1;
                l_dates(l_pos) := l_start_date;
                l_dates_str(l_pos) := pk_date_utils.date_send(i_lang, l_start_date_aux, i_prof);
                l_start_date := pk_date_utils.add_days_to_tstz(l_start_date, 1);
                l_start_date_aux := l_start_date_aux + 1;
            END LOOP;
        
            g_error := 'CALL GET_AVAILABLE_VACANCIES';
            -- Get available vacancies only (the ones that not clash with any absence period).
        
            IF NOT get_available_vacancies(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_vacancies => l_vacancies,
                                           o_error     => o_error)
            THEN
                RAISE curex;
            END IF;
        
            g_error := 'CALL CALCULATE_MONTH_AVAILABILITY';
            -- Calculate month availability
            IF NOT calculate_month_availability(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_mult           => TRUE,
                                                i_wizmode        => i_wizmode,
                                                i_list_schedules => l_schedules,
                                                i_list_dates     => l_dates,
                                                i_list_dates_str => l_dates_str,
                                                o_days_status    => o_days_status,
                                                o_days_date      => o_days_date,
                                                o_days_free      => o_days_free,
                                                o_days_sched     => o_days_sched,
                                                o_days_conflicts => l_days_conflicts,
                                                o_days_tempor    => l_days_tempor,
                                                o_error          => o_error)
            THEN
                RAISE curex;
            END IF;
        
            IF i_args IS NOT NULL
               AND i_args.count > 0
            THEN
                g_error := 'CALL GET_PATIENT_ICONS';
                -- Get patient icons, which do not depend on the search criteria sets, but only on the date.
                l_argsm := table_varchar();
                l_argsm.extend(i_args(1).count);
                i := i_args(1).first;
                WHILE i IS NOT NULL
                LOOP
                    l_argsm(i) := i_args(1) (i);
                    i := i_args(1).next(i);
                END LOOP;
            
                IF NOT (pk_schedule.get_patient_icons(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_args          => l_argsm, --i_args(1),
                                                      i_id_patient    => i_id_patient,
                                                      o_patient_icons => o_patient_icons,
                                                      o_error         => o_error))
                THEN
                    RAISE curex;
                END IF;
            ELSE
                pk_types.open_my_cursor(o_patient_icons);
            END IF;
        ELSE
            pk_types.open_my_cursor(o_patient_icons);
        END IF;
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_patient_icons);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END;
    END get_availability_mult;

    FUNCTION get_schedule_conflicts
    (
        id_sched schedule.id_schedule%TYPE,
        id_prof  sch_resource.id_professional%TYPE,
        dt_begin schedule.dt_begin_tstz%TYPE,
        dt_end   schedule.dt_end_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_dummy NUMBER;
    BEGIN
        SELECT 1
          INTO l_dummy
          FROM schedule s
          JOIN sch_resource sr
            ON s.id_schedule = sr.id_schedule
         WHERE sr.id_professional = id_prof
           AND s.id_schedule <> id_sched
           AND s.flg_status <> pk_schedule.g_sched_status_cancelled
           AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
           AND (dt_begin BETWEEN s.dt_begin_tstz AND s.dt_end_tstz
               -- OR (dt_end IS NOT NULL AND dt_end BETWEEN s.dt_begin_tstz AND s.dt_end_tstz)
               )
           AND rownum = 1;
    
        RETURN g_icon_sch_temp_ol;
    
    EXCEPTION
        -- nao encontrou = nao existe conflito com outros agendamentos deste prof.
        WHEN no_data_found THEN
            RETURN g_icon_sch_temp;
    END get_schedule_conflicts;

    /**
    * Updates mfr schedule. To be used by flash layer in response to option 'change' inside actions button.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_old_id_schedule    The schedule id to be updated
    * @param i_id_sch_event       Event type   
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_flg_vacancy        Vacancy flag
    * @param i_schedule_notes     Notes
    * @param i_id_lang_translator Translator's language
    * @param i_id_lang_preferred  Preferred language
    * @param i_id_reason          Appointment reason
    * @param i_id_origin          Patient origin
    * @param i_id_room            Room
    * @param i_id_episode         Episode 
    * @param i_reason_notes       Reason for appointment in free-text.
    * @param i_flg_request_type   tipo de pedido
    * @param i_flg_schedule_via   meio do pedido marcacao
    * @param i_id_phys_area       new physiatry area 
    * @param i_wizmode            Y=wizard mode, N=standard mode
    * @param o_id_schedule        New schedule
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set if a message is displayed or not      
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.
    * @param o_error              Error message if something goes wrong
    *
    * @author   Telmo
    * @version  2.4.3.x
    * @date     19-02-2009
    *
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION update_schedule
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_old_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_sch_event       IN schedule.id_sch_event%TYPE,
        i_id_prof            IN sch_resource.id_professional%TYPE,
        i_dt_begin           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_flg_vacancy        IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_schedule_notes     IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred  IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason          IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin          IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room            IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_episode         IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes       IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type   IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via   IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_id_complaint       IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_id_phys_area       IN schedule_intervention.id_physiatry_area%TYPE,
        i_wizmode            IN VARCHAR2 DEFAULT 'N',
        o_id_schedule        OUT schedule.id_schedule%TYPE,
        o_flg_proceed        OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'UPDATE_SCHEDULE';
        l_schedule_cancel_notes schedule.schedule_cancel_notes%TYPE;
        l_ret                   BOOLEAN;
        l_cancel_schedule EXCEPTION;
        -- SCH 3.0 DO NOT REMOVE
        -- l_transaction_id VARCHAR2(4000);
    
        -- Cursor with id_interv_presc_det for a given id_schedule
        CURSOR c_interv(i_old_id_schedule IN schedule_intervention.id_schedule%TYPE) IS
            SELECT si.id_interv_presc_det
              FROM schedule_intervention si
             WHERE si.id_schedule = i_old_id_schedule
               AND si.flg_original = g_yes
               AND rownum = 1;
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule, si.id_interv_presc_det, s.id_dcs_requested, sg.id_patient, s.id_schedule_recursion
              FROM schedule s
              JOIN schedule_intervention si
                ON s.id_schedule = si.id_schedule
              LEFT JOIN sch_group sg
                ON si.id_schedule = sg.id_schedule
              LEFT JOIN sch_resource sr
                ON si.id_schedule = sr.id_schedule
             WHERE s.id_schedule = c_sched.i_old_id_schedule
               AND si.flg_original = g_yes;
    
        l_sched_rec c_sched%ROWTYPE;
    
        -- Returns a record containing the old schedule's data
        FUNCTION inner_get_old_schedule(i_old_id_schedule schedule.id_schedule%TYPE) RETURN c_sched%ROWTYPE IS
            l_ret c_sched%ROWTYPE;
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(inner_get_old_schedule.i_old_id_schedule);
            g_error := 'FETCH c_sched';
            FETCH c_sched
                INTO l_ret;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
        
            RETURN l_ret;
        END inner_get_old_schedule;
    
    BEGIN
        -- get cancel notes message
        l_schedule_cancel_notes := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => pk_schedule.g_msg_update_schedule);
    
        -- foist cancel old schedule
        IF NOT cancel_schedule(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_schedule      => i_old_id_schedule,
                               i_id_cancel_reason => NULL,
                               i_cancel_notes     => l_schedule_cancel_notes,
                               o_error            => o_error)
        THEN
            RAISE l_cancel_schedule;
        END IF;
    
        g_error := 'GET OLD SCHEDULE';
        -- Get old schedule
        l_sched_rec := inner_get_old_schedule(i_old_id_schedule);
    
        -- create a new schedule
        g_error := 'CALL PK_SCHEDULE_MFR.CREATE_SCHEDULE';
        IF NOT create_schedule(i_lang                => i_lang,
                               i_prof                => i_prof,
                               i_id_patient          => l_sched_rec.id_patient,
                               i_id_dep_clin_serv    => l_sched_rec.id_dcs_requested,
                               i_id_sch_event        => i_id_sch_event,
                               i_id_prof             => i_id_prof,
                               i_dt_begin            => i_dt_begin,
                               i_dt_end              => i_dt_end,
                               i_flg_vacancy         => i_flg_vacancy,
                               i_schedule_notes      => i_schedule_notes,
                               i_id_lang_translator  => i_id_lang_translator,
                               i_id_lang_preferred   => i_id_lang_preferred,
                               i_id_reason           => i_id_reason,
                               i_id_origin           => i_id_origin,
                               i_id_room             => i_id_room,
                               i_id_schedule_ref     => i_old_id_schedule,
                               i_id_episode          => i_id_episode,
                               i_reason_notes        => i_reason_notes,
                               i_flg_request_type    => i_flg_request_type,
                               i_flg_schedule_via    => i_flg_schedule_via,
                               i_id_interv_presc_det => l_sched_rec.id_interv_presc_det,
                               i_id_sch_recursion    => l_sched_rec.id_schedule_recursion,
                               i_id_phys_area        => i_id_phys_area,
                               i_wizmode             => i_wizmode,
                               i_id_slot             => NULL,
                               i_id_complaint        => i_id_complaint,
                               o_id_schedule         => o_id_schedule,
                               o_flg_proceed         => o_flg_proceed,
                               o_flg_show            => o_flg_show,
                               o_msg                 => o_msg,
                               o_msg_title           => o_msg_title,
                               o_button              => o_button,
                               o_error               => o_error)
        THEN
            RAISE l_cancel_schedule;
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_INTERV_MFR.UPDATE_INTERV_STATUS';
        FOR elem IN c_interv(i_old_id_schedule)
        LOOP
            IF NOT pk_interv_mfr.update_interv_status(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_interv_presc_det => elem.id_interv_presc_det,
                                                      o_error               => o_error)
            THEN
                RAISE l_cancel_schedule;
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END LOOP;
    
        --SCH 3.0 DO NOT REMOVE
        -- pk_schedule_api_upstream.do_commit(l_transaction_id);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_cancel_schedule THEN
            -- SCH 3.0 DO NOT REMOVE
            -- pk_schedule_api_upstream.do_rollback(l_transaction_id); 
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END update_schedule;

    /*
    * Gets the details of the appointments to be put on the clipboard.
    * Private function.
    *
    * @param i_lang       lang id
    * @param i_prof       prof requesting this
    * @param i_args       search criteria
    * @param i_id_inst    institution id needed for getting num_clin_record
    * @param o_schedules  output list
    * @param o_error      Error message if something goes wrong
    *
    * @author  Telmo Castro
    * @version 2.4.3.20
    * @date    23-02-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    *
    * UPDATED: ALERT-39942 
    * @author  Sofia Mendes
    * @version 2.5.0.5
    * @date    25-08-2009
    */
    FUNCTION get_appointments_clip_details
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_list_schedules IN table_number,
        i_wizmode        IN VARCHAR2 DEFAULT 'N',
        i_id_inst        IN NUMBER,
        o_schedules      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_APPOINTMENTS_CLIP_DETAILS';
    BEGIN
        g_error := 'OPEN o_schedules FOR';
        -- Open cursor
        OPEN o_schedules FOR
            SELECT s.id_schedule,
                   pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, s.dt_end_tstz, i_prof) dt_end,
                   pat.name,
                   s.id_sch_event,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) event_name,
                   decode(pk_patphoto.check_blob(pat.id_patient),
                          g_no,
                          '',
                          pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
                   pk_patient.get_gender(i_lang, pat.gender) AS gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) age,
                   s.flg_status,
                   si.id_physiatry_area,
                   CASE s.flg_status
                       WHEN pk_schedule.g_sched_status_temporary THEN
                        pk_schedule.g_icon_prefix ||
                        get_schedule_conflicts(s.id_schedule, sr.id_professional, s.dt_begin_tstz, s.dt_end_tstz)
                       ELSE
                        pk_schedule.g_icon_prefix ||
                        pk_sysdomain.get_img(i_lang,
                                             pk_schedule.g_sched_flg_sch_status_domain,
                                             s.flg_status || s.flg_vacancy)
                   END img_schedule,
                   pk_schedule.g_icon_prefix ||
                   pk_sysdomain.get_img(i_lang, pk_schedule.g_sched_flg_notif_status, s.flg_notification) img_notification,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional) nick_prof,
                   pk_translation.get_translation(i_lang, pa.code_physiatry_area) desc_phys_area,
                   pk_schedule.get_num_clin_record(pat.id_patient, i_id_inst) num_clin_record,
                   sr.id_professional id_prof,
                   get_count_and_rank(i_lang, s.id_schedule, i_wizmode) count_and_rank,
                   (SELECT pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL)
                      FROM interv_presc_det ipd
                      JOIN intervention i
                        ON ipd.id_intervention = i.id_intervention
                     WHERE ipd.id_interv_presc_det = si.id_interv_presc_det) consult_name,
                   s.id_dcs_requested
              FROM sch_event se
              JOIN schedule s
                ON se.id_sch_event = s.id_sch_event
              JOIN schedule_intervention si
                ON s.id_schedule = si.id_schedule
              LEFT JOIN sch_resource sr
                ON si.id_schedule = sr.id_schedule
              LEFT JOIN sch_group sg
                ON si.id_schedule = sg.id_schedule
              LEFT JOIN patient pat
                ON sg.id_patient = pat.id_patient
              JOIN physiatry_area pa
                ON si.id_physiatry_area = pa.id_physiatry_area
             WHERE s.id_schedule IN (SELECT *
                                       FROM TABLE(i_list_schedules))
               AND si.flg_original = g_yes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_schedules);
            
                RETURN FALSE;
            END;
    END get_appointments_clip_details;

    /*
    * Gets the details of the schedules that are dragged, by dragging a full day into the clipboard
    * Adapted from homonymous function in pk_schedule
    *
    * @param i_lang       language id
    * @param i_prof       professional performing this
    * @param i_args       criteria for schedule filtering
    * @param i_wizmode    Y= wizard mode   N = standard moded
    * @param o_schedules  output
    * @param o_error
    *
    * @author  Telmo
    * @version 2.4.3.x
    * @since   20-02-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_schedules_to_clipboard
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        i_wizmode   IN VARCHAR2 DEFAULT 'N',
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_SCHEDULES_TO_CLIPBOARD';
        l_list_schedules table_number;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_SCHEDULES';
        -- Get schedules that match the given criteria.
        IF NOT get_schedules(i_lang       => i_lang,
                             i_prof       => i_prof,
                             i_id_patient => NULL,
                             i_args       => i_args,
                             i_wizmode    => i_wizmode,
                             o_schedules  => l_list_schedules,
                             o_error      => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_APPOINTMENT_CLIPBOARD_DETAILS';
        -- Get appointments' details to clipboard
        IF NOT get_appointments_clip_details(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_list_schedules => l_list_schedules,
                                             i_wizmode        => i_wizmode,
                                             i_id_inst        => i_args(pk_schedule.idx_id_inst),
                                             o_schedules      => o_schedules,
                                             o_error          => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_schedules);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END;
    END get_schedules_to_clipboard;

    /*
    * Reschedules several appointments.
    * Adapted from same function in pk_schedule_outp.
    * 
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_prof            Target professional.
    * @param i_schedules          List of schedules to reschedule.
    * @param i_start_dates        List of new start dates
    * @param i_end_dates          List of new end dates
    * @param i_wizmode            Y=wizard mode  N=standard mode
    * @param i_ids_slot           ids das novas slots. Podem ser null
    * @param o_error              Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author   Telmo
    * @version  2.4.3.x
    * @date     03-03-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION create_mult_reschedule
    (
        i_lang        language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_prof     IN professional.id_professional%TYPE,
        i_schedules   IN table_varchar,
        i_start_dates IN table_varchar,
        i_end_dates   IN table_varchar,
        i_ids_slot    IN table_number,
        i_wizmode     IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'CREATE_MULT_RESCHEDULE';
        l_id_schedule schedule.id_schedule%TYPE;
        l_flg_show    VARCHAR2(1);
        l_flg_proceed VARCHAR2(1);
        l_msg         VARCHAR2(32000);
        l_msg_title   VARCHAR2(32000);
        l_button      VARCHAR2(200);
    BEGIN
        -- Iterate on schedules
        g_error := 'ITERATE ON SCHEDULES';
        FOR idx IN i_schedules.first .. i_schedules.last
        LOOP
            -- Reschedule each appointment
            IF NOT create_reschedule(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_old_id_schedule => i_schedules(idx),
                                     i_id_prof         => i_id_prof,
                                     i_dt_begin        => i_start_dates(idx),
                                     i_dt_end          => i_end_dates(idx),
                                     i_wizmode         => i_wizmode,
                                     i_id_slot         => i_ids_slot(idx),
                                     o_id_schedule     => l_id_schedule,
                                     o_flg_show        => l_flg_show,
                                     o_flg_proceed     => l_flg_proceed,
                                     o_msg             => l_msg,
                                     o_msg_title       => l_msg_title,
                                     o_button          => l_button,
                                     o_error           => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END create_mult_reschedule;

    /**
    * Set a new schedule notification for a set of schedules
    *
    * @param    i_lang                   Language
    * @param    i_prof                   Professional
    * @param    i_id_interv_presc_det    Interventions ID
    * @param    i_flg_notif              Notification flag
    * @param    i_flg_notif_via          Notification via flag
    * @param    o_error                  Error message if something goes wrong
    *
    * @author  Jose Antunes
    * @version  2.5
    * @date     27-03-2009
    * 
    * UPDATED
    * update of i_flg_notif_via is done in the core funtion
    * @author  Sofia Mendes
    * @version  2.5.4
    * @date     03-06-2009
    */
    FUNCTION set_schedule_notification
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN table_number,
        i_flg_notif           IN schedule.flg_notification%TYPE,
        i_flg_notif_via       IN schedule.flg_notification_via%TYPE,
        -- i_transaction_id      IN VARCHAR2, --SCH 3.0 DO NOT REMOVE
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_notification    schedule.flg_notification%TYPE;
        l_flg_status          schedule.flg_status%TYPE;
        l_id_external_request p1_external_request.id_external_request%TYPE;
        l_func_name           VARCHAR2(32) := 'SET_SCHEDULE_NOTIFICATION';
        l_id_schedule         table_number;
    
        --Scheduler 3.0 variables
        --SCH 3.0 DO NOT REMOVE
        --  l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'GET ID SCHEDULES';
    
        SELECT si.id_schedule
          BULK COLLECT
          INTO l_id_schedule
          FROM schedule_intervention si, schedule s
         WHERE si.id_schedule = s.id_schedule
           AND s.flg_status NOT IN (pk_schedule.g_sched_status_temporary, pk_schedule.g_sched_status_cancelled)
           AND si.id_interv_presc_det IN (SELECT *
                                            FROM TABLE(i_id_interv_presc_det));
    
        IF (l_id_schedule.count > 0)
        THEN
            FOR i IN l_id_schedule.first .. l_id_schedule.last
            LOOP
            
                IF NOT pk_schedule.set_schedule_notification(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_id_schedule   => l_id_schedule(i),
                                                             i_notification  => i_flg_notif,
                                                             i_flg_notif_via => i_flg_notif_via,
                                                             --   i_transaction_id => l_transaction_id, --SCH 3.0 DO NOT REMOVE
                                                             o_error => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', g_package_name, l_func_name);
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
        
    END set_schedule_notification;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_mfr;
/
