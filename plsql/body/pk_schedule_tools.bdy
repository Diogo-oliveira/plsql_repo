/*-- Last Change Revision: $Rev: 2027695 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:01 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_schedule_tools IS

    /* 
    * Generates the code (using dbms_output) for a function that creates a new record on the given table.
    *
    * @param i_table     Table name.
    * @param i_author    Author.      
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/17
    */
    PROCEDURE generate_new_function
    (
        i_table  VARCHAR2,
        i_author VARCHAR2
    ) IS
        -- Comments
        CURSOR c_comments(p_table VARCHAR2) IS
            SELECT '* @param i_lang Language identifier' comm
              FROM dual
            UNION ALL
            SELECT '* @param ' || 'i_' || lower(column_name) || ' ' || comments comm
              FROM user_col_comments
             WHERE table_name = p_table
            UNION ALL
            SELECT '* @param o_' || lower(p_table) || '_rec The record that is inserted into ' || lower(p_table) comm
              FROM dual
            UNION ALL
            SELECT '* @param o_error Error message (if an error occurred).' comm
              FROM dual;
    
        -- Arguments list
        CURSOR c_arguments(p_table VARCHAR2) IS
            SELECT 'i_lang language.id_language%TYPE DEFAULT NULL, ' args
              FROM dual
            UNION ALL
            SELECT 'i_id_' || lower(p_table) || ' ' || lower(p_table) || '.id_' || lower(p_table) ||
                   '%TYPE DEFAULT NULL, '
              FROM dual
            UNION ALL
            SELECT 'i_' || lower(column_name) || ' ' || lower(p_table) || '.' || lower(column_name) || '%TYPE ' ||
                   decode(nullable, 'Y', ' DEFAULT NULL', '') || ',' args
              FROM user_tab_columns
             WHERE table_name = p_table
               AND lower(column_name) != 'id_' || lower(table_name)
            UNION ALL
            SELECT 'o_' || p_table || '_rec OUT ' || lower(p_table) || '%ROWTYPE, ' assigns
              FROM dual
            UNION ALL
            SELECT 'o_error OUT VARCHAR2)' assigns
              FROM dual;
    
        -- Assignments list
        CURSOR c_assignments(p_table VARCHAR2) IS
            SELECT 'o_' || lower(table_name) || '_rec.' || lower(column_name) || ':= i_' || lower(column_name) || ';' assigns
              FROM user_tab_columns
             WHERE table_name = p_table
               AND lower(column_name) != ('id_' || lower(p_table));
    
        l_table       VARCHAR2(32) := upper(i_table);
        l_author      VARCHAR2(32) := i_author;
        l_lower_table VARCHAR2(32) := lower(l_table);
        l_upper_table VARCHAR2(32) := upper(l_table);
    BEGIN
        -- Comments
        dbms_output.put_line('/**');
        dbms_output.put_line('* Creates a new record on ' || l_lower_table || '.');
        dbms_output.put_line('* Private function.');
        dbms_output.put_line('*');
        -- Parameter comments
        FOR comm IN c_comments(l_table)
        LOOP
            dbms_output.put_line(comm.comm);
        END LOOP;
        dbms_output.put_line('*');
        dbms_output.put_line('* @return True if successful, false otherwise.');
        dbms_output.put_line('*');
        dbms_output.put_line('* @author ' || l_author);
        dbms_output.put_line('* @version alpha');
        dbms_output.put_line('* @since ' || to_char(SYSDATE, 'yyyy/mm/dd'));
        dbms_output.put_line('*/');
    
        -- Function new_<table>
        dbms_output.put_line('FUNCTION new_' || l_lower_table || '(');
        -- Arguments
        FOR args IN c_arguments(l_table)
        LOOP
            dbms_output.put_line(args.args);
        END LOOP;
        dbms_output.put_line('RETURN BOOLEAN IS');
        dbms_output.put_line('  l_func_name VARCHAR2(32);');
        dbms_output.put_line('BEGIN');
        -- Store function name
        dbms_output.put_line('l_func_name := ''NEW_' || l_upper_table || ''';');
        -- Primary key comments
        dbms_output.put_line('-- If the primary key is passed as a parameter use it,');
        dbms_output.put_line('-- else take the next value from sequence.');
        -- Store error message
        dbms_output.put_line('g_error := ''GET SEQUENCE VALUE'';');
        -- Generate primary key
        dbms_output.put_line('IF (i_id_' || l_lower_table || ' IS NOT NULL) THEN ');
        dbms_output.put_line('o_' || l_lower_table || '_rec.id_' || l_lower_table || ' := ' || 'i_id_' ||
                             l_lower_table || ';');
        dbms_output.put_line('ELSE');
        dbms_output.put_line('SELECT seq_' || l_lower_table || '.nextval');
        dbms_output.put_line('INTO o_' || l_lower_table || '_rec.id_' || l_lower_table);
        dbms_output.put_line('FROM dual;');
        dbms_output.put_line('END IF;');
        -- Create record comments
        dbms_output.put_line('-- Create record');
        dbms_output.put_line('g_error := ''CREATE RECORD'';');
        -- Record assignments
        FOR asns IN c_assignments(l_table)
        LOOP
            dbms_output.put_line(asns.assigns);
        END LOOP;
        -- Insert record comment
        dbms_output.put_line('-- Insert record');
        -- Insert error log message
        dbms_output.put_line('g_error := ''INSERT RECORD'';');
        -- Insert statement
        dbms_output.put_line('INSERT INTO ' || l_lower_table || ' VALUES o_' || l_lower_table || '_rec;');
        -- Return
        dbms_output.put_line('RETURN TRUE;');
        -- Exception
        dbms_output.put_line('EXCEPTION WHEN OTHERS THEN');
        dbms_output.put_line('o_' || l_lower_table || '_rec := NULL;');
        dbms_output.put_line('-- Unexpected error');
        dbms_output.put_line('RETURN error_handling(i_lang => i_lang, i_func_proc_name => l_func_name,');
        dbms_output.put_line('i_error => g_error, i_sqlerror => SQLERRM, o_error => o_error);');
        dbms_output.put_line('END new_' || l_lower_table || ';');
    END generate_new_function;

    /* 
    * Generates the code (using dbms_output) for a function that alters a record on the given table.
    *
    * @param i_table     Table name.
    * @param i_author    Author.      
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/17
    */
    PROCEDURE generate_alter_function
    (
        i_table  VARCHAR2,
        i_author VARCHAR2
    ) IS
        -- Comments
        CURSOR c_comments(p_table VARCHAR2) IS
            SELECT '* @param i_lang Language identifier' comm
              FROM dual
            UNION ALL
            SELECT '* @param ' || 'i_' || lower(column_name) || ' ' || comments comm
              FROM user_col_comments
             WHERE table_name = p_table
            UNION ALL
            SELECT '* @param o_' || lower(p_table) || '_rec The record that represents the update on ' ||
                   lower(p_table) comm
              FROM dual
            UNION ALL
            SELECT '* @param o_error Error message (if an error occurred).' comm
              FROM dual;
    
        -- Arguments list
        CURSOR c_arguments(p_table VARCHAR2) IS
            SELECT 'i_lang language.id_language%TYPE, ' args
              FROM dual
            UNION ALL
            SELECT 'i_id_' || lower(p_table) || ' ' || lower(p_table) || '.id_' || lower(p_table) || '%TYPE, '
              FROM dual
            UNION ALL
            SELECT 'i_' || lower(column_name) || ' ' || lower(p_table) || '.' || lower(column_name) || '%TYPE ' ||
                   decode(column_name, 'i_id_' || lower(p_table), '', ' DEFAULT NULL') || ',' args
              FROM user_tab_columns
             WHERE table_name = p_table
               AND lower(column_name) != ('id_' || lower(p_table))
            UNION ALL
            SELECT 'o_' || p_table || '_rec OUT ' || lower(p_table) || '%ROWTYPE, ' assigns
              FROM dual
            UNION ALL
            SELECT 'o_error OUT VARCHAR2)' assigns
              FROM dual;
    
        -- Updates           
        CURSOR c_updates(p_table VARCHAR2) IS
            SELECT column_name || ' = nvl(i_' || column_name || ',' || column_name || ')' upd
              FROM user_tab_columns
             WHERE table_name = p_table;
    
        -- Columns
        CURSOR c_columns(p_table VARCHAR2) IS
            SELECT lower(column_name) AS col
              FROM user_tab_columns
             WHERE table_name = p_table;
    
        l_table       VARCHAR2(32) := upper(i_table);
        l_author      VARCHAR2(32) := i_author;
        l_lower_table VARCHAR2(32) := lower(l_table);
        l_upper_table VARCHAR2(32) := upper(l_table);
        l_cont        NUMBER := 0;
    BEGIN
        -- Comments
        dbms_output.put_line('/**');
        dbms_output.put_line('* Alters a record on ' || l_lower_table || '.');
        dbms_output.put_line('* Private function.');
        dbms_output.put_line('*');
        -- Parameter comments
        FOR comm IN c_comments(l_table)
        LOOP
            dbms_output.put_line(comm.comm);
        END LOOP;
        dbms_output.put_line('*');
        dbms_output.put_line('* @return True if successful, false otherwise.');
        dbms_output.put_line('*');
        dbms_output.put_line('* @author ' || l_author);
        dbms_output.put_line('* @version alpha');
        dbms_output.put_line('* @since ' || to_char(SYSDATE, 'yyyy/mm/dd'));
        dbms_output.put_line('*/');
    
        -- Function new_<table>
        dbms_output.put_line('FUNCTION alter_' || l_lower_table || '(');
        -- Arguments
        FOR args IN c_arguments(l_table)
        LOOP
            dbms_output.put_line(args.args);
        END LOOP;
        dbms_output.put_line('RETURN BOOLEAN IS');
        dbms_output.put_line(' l_func_name VARCHAR2(32); ');
        dbms_output.put_line('BEGIN');
        -- Store function name
        dbms_output.put_line('l_func_name := ''ALTER_' || l_upper_table || ''';');
        -- Insert record comment
        dbms_output.put_line('-- Update record');
        -- Insert error log message
        dbms_output.put_line('g_error := ''UPDATE RECORD'';');
        -- Update statement
        dbms_output.put_line('UPDATE ' || l_lower_table || ' SET ');
        l_cont := 1;
        FOR updates IN c_updates(l_table)
        LOOP
            IF l_cont > 1
            THEN
                dbms_output.put(',');
            END IF;
            dbms_output.put_line(updates.upd);
            l_cont := l_cont + 1;
        END LOOP;
        dbms_output.put_line(' WHERE id_' || l_lower_table || ' = i_id_' || l_lower_table);
        -- Update statement (Returning into)
        dbms_output.put_line(' RETURNING ');
        l_cont := 1;
        FOR cols IN c_columns(l_table)
        LOOP
            IF l_cont > 1
            THEN
                dbms_output.put(',');
            END IF;
            dbms_output.put(cols.col);
            l_cont := l_cont + 1;
        END LOOP;
        dbms_output.put_line(' INTO ');
        l_cont := 1;
        FOR cols IN c_columns(l_table)
        LOOP
            IF l_cont > 1
            THEN
                dbms_output.put(',');
            END IF;
            dbms_output.put('o_' || l_lower_table || '_rec.' || cols.col);
            l_cont := l_cont + 1;
        END LOOP;
        dbms_output.put_line(';');
        -- If the record's key is null then the update performed 
        dbms_output.put_line('IF SQL%ROWCOUNT = 0 THEN');
        dbms_output.put_line('-- No records were updated due to an invalid key');
        dbms_output.put_line('RETURN error_handling(i_lang => i_lang, i_func_proc_name => l_func_name,');
        dbms_output.put_line('i_error => g_error, i_sqlerror => g_invalid_record_key, o_error => o_error);');
        dbms_output.put_line('ELSE');
        dbms_output.put_line('RETURN TRUE;');
        dbms_output.put_line('END IF;');
        -- Exception
        dbms_output.put_line('EXCEPTION WHEN OTHERS THEN');
        dbms_output.put_line('o_' || l_lower_table || '_rec := NULL;');
        dbms_output.put_line('-- Unexpected error');
        dbms_output.put_line('RETURN error_handling(i_lang => i_lang, i_func_proc_name => g_func_name,');
        dbms_output.put_line('i_error => g_error, i_sqlerror => SQLERRM, o_error => o_error);');
        dbms_output.put_line('END alter_' || l_lower_table || ';');
    
    END generate_alter_function;

    /*
    * Generates random consult vacancies.
    * For development purposes only.
    *
    * @param i_prof                       Professional.
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_max_vacancies              Maximum number of vacancies per date/hour.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_dep_clin_serv           Department-Clinical Service identifier.
    * @param i_id_event                   Event identifier.
    * @param i_id_room                    Room identifier.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    */
    PROCEDURE generate_vacancies
    (
        i_prof             profissional,
        i_slot_interval    NUMBER,
        i_max_vacancies    NUMBER,
        i_start_date       TIMESTAMP WITH TIME ZONE,
        i_end_date         TIMESTAMP WITH TIME ZONE,
        i_start_hour       NUMBER,
        i_end_hour         NUMBER,
        i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_event         sch_event.id_sch_event%TYPE,
        i_id_room          room.id_room%TYPE
        
    ) IS
        l_start_date     TIMESTAMP WITH TIME ZONE;
        l_end_date       TIMESTAMP WITH TIME ZONE;
        l_start_hour     NUMBER := greatest(i_start_hour, 0);
        l_end_hour       NUMBER := least(i_end_hour, 24);
        l_slot_interval  NUMBER := i_slot_interval;
        l_professional   profissional := i_prof;
        l_dept_clin_serv sch_consult_vacancy.id_dep_clin_serv%TYPE := i_id_dep_clin_serv;
        l_event          sch_consult_vacancy.id_sch_event%TYPE := i_id_event;
        l_room           room.id_room%TYPE := i_id_room;
        l_max_vacancies  sch_consult_vacancy.max_vacancies%TYPE DEFAULT NULL;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        l_start_date := pk_date_utils.trunc_insttimezone(i_prof, i_start_date);
        l_end_date   := pk_date_utils.trunc_insttimezone(i_prof, i_end_date);
    
        l_start_date := pk_date_utils.add_to_ltstz(l_start_date, l_start_hour, 'HOUR');
        pk_date_utils.set_dst_time_check_on;
        -- Loop until start_date reaches the end_date
        WHILE (l_start_date <= l_end_date)
        LOOP
            -- Generate number of vacancies
            l_max_vacancies := abs(MOD(dbms_random.random, i_max_vacancies)) + 1;
            -- Insert the vacancy record
            INSERT INTO sch_consult_vacancy
                (id_sch_consult_vacancy,
                 dt_sch_consult_vacancy_tstz,
                 id_institution,
                 id_prof,
                 dt_begin_tstz,
                 max_vacancies,
                 used_vacancies,
                 dt_end_tstz,
                 id_dep_clin_serv,
                 id_room,
                 id_sch_event,
                 flg_status)
            VALUES
                (seq_sch_consult_vacancy.nextval,
                 current_timestamp,
                 l_professional.institution,
                 l_professional.id,
                 l_start_date,
                 l_max_vacancies,
                 0,
                 pk_date_utils.add_to_ltstz(l_start_date, i_slot_interval, 'MINUTE'), --NULL,
                 l_dept_clin_serv,
                 l_room,
                 l_event,
                 pk_schedule_bo.g_status_active);
            -- Increment the start_date by the number of minutes of each slot
            l_start_date := pk_date_utils.add_to_ltstz(l_start_date, l_slot_interval, 'MINUTE');
            IF (pk_date_utils.get_timestamp_diff(l_start_date, pk_date_utils.trunc_insttimezone(i_prof, l_start_date)) * 24 >=
               l_end_hour)
            THEN
                l_start_date := pk_date_utils.add_to_ltstz(pk_date_utils.trunc_insttimezone(i_prof, l_start_date),
                                                           24 + l_start_hour,
                                                           'HOUR');
            END IF;
        END LOOP;
        COMMIT;
    END generate_vacancies;

    /*
    * Generates random exam vacancies.
    * For development purposes only.
    *
    * @param i_prof                       Professional.
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_max_vacancies              Maximum number of vacancies per date/hour.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_dep_clin_serv           Department-Clinical Service identifier.
    * @param i_id_event                   Event identifier.
    * @param i_id_exam                    Exam identifier.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    */
    PROCEDURE generate_exam_vacancies
    (
        i_prof             profissional,
        i_slot_interval    NUMBER,
        i_max_vacancies    NUMBER,
        i_start_date       TIMESTAMP WITH TIME ZONE,
        i_end_date         TIMESTAMP WITH TIME ZONE,
        i_start_hour       NUMBER,
        i_end_hour         NUMBER,
        i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_event         sch_event.id_sch_event%TYPE,
        i_id_exam          exam.id_exam%TYPE
    ) IS
        l_start_date             TIMESTAMP WITH TIME ZONE;
        l_end_date               TIMESTAMP WITH TIME ZONE;
        l_start_hour             NUMBER := greatest(0, i_start_hour);
        l_end_hour               NUMBER := least(i_end_hour, 24);
        l_slot_interval          NUMBER := i_slot_interval;
        l_professional           profissional := i_prof;
        l_dept_clin_serv         sch_consult_vacancy.id_dep_clin_serv%TYPE := i_id_dep_clin_serv;
        l_event                  sch_consult_vacancy.id_sch_event%TYPE := i_id_event;
        l_max_vacancies          sch_consult_vacancy.max_vacancies%TYPE DEFAULT NULL;
        l_id_sch_consult_vacancy sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        l_start_date := pk_date_utils.trunc_insttimezone(i_prof, i_start_date);
        l_end_date   := pk_date_utils.trunc_insttimezone(i_prof, i_end_date);
        pk_date_utils.set_dst_time_check_on;
        --        dbms_output.put_line('enddate=' || l_end_date);
    
        l_start_date := pk_date_utils.add_to_ltstz(l_start_date, l_start_hour, 'HOUR');
        -- Loop until start_date reaches the end_date
        WHILE (l_start_date <= l_end_date)
        LOOP
            -- Generate number of vacancies
            l_max_vacancies := abs(MOD(dbms_random.random, i_max_vacancies)) + 1;
        
            -- Insert the vacancy record
            INSERT INTO sch_consult_vacancy
                (id_sch_consult_vacancy,
                 dt_sch_consult_vacancy_tstz,
                 id_institution,
                 id_prof,
                 dt_begin_tstz,
                 max_vacancies,
                 used_vacancies,
                 dt_end_tstz,
                 id_dep_clin_serv,
                 id_room,
                 id_sch_event,
                 flg_status)
            VALUES
                (seq_sch_consult_vacancy.nextval,
                 current_timestamp,
                 l_professional.institution,
                 l_professional.id,
                 l_start_date,
                 l_max_vacancies,
                 0,
                 pk_date_utils.add_to_ltstz(l_start_date, i_slot_interval, 'MINUTE'), --NULL,
                 l_dept_clin_serv,
                 NULL,
                 l_event,
                 pk_schedule_bo.g_status_active)
            RETURNING id_sch_consult_vacancy INTO l_id_sch_consult_vacancy;
        
            -- Insert the exam-specific record
            INSERT INTO sch_consult_vac_exam
                (id_sch_consult_vacancy, id_sch_consult_vac_exam, id_exam)
            VALUES
                (l_id_sch_consult_vacancy, seq_sch_consult_vac_exam.nextval, i_id_exam);
        
            -- Increment the start_date by the number of minutes of each slot
            l_start_date := pk_date_utils.add_to_ltstz(l_start_date, l_slot_interval, 'MINUTE');
            IF (pk_date_utils.get_timestamp_diff(l_start_date, pk_date_utils.trunc_insttimezone(i_prof, l_start_date)) * 24 >=
               l_end_hour)
            THEN
                l_start_date := pk_date_utils.add_to_ltstz(pk_date_utils.trunc_insttimezone(i_prof, l_start_date),
                                                           24 + l_start_hour,
                                                           'HOUR');
            END IF;
        
        --dbms_output.put_line('start=' || l_start_date);
        
        END LOOP;
        COMMIT;
    END generate_exam_vacancies;

    /*
    * Generates random exam vacancies.
    * For development purposes only.
    *
    * @param i_prof                       Professional.
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_max_vacancies              Maximum number of vacancies per date/hour.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_dep_clin_serv           Department-Clinical Service identifier.
    * @param i_id_event                   Event identifier.
    * @param i_weekdays                   list of weekday in csv format in which vacancies should be created. 1=monday, 7=sunday, null=all
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    *
    * alert-8202. exam vacancies are now exam-id-independent. Also, new parameter i_weekdays for creating vacancies only in specified week days
    * @author Telmo
    * @version 2.5.0.7
    * @date    12-10-2009
    */
    PROCEDURE generate_exam_vacancies
    (
        i_prof             profissional,
        i_slot_interval    NUMBER,
        i_max_vacancies    NUMBER,
        i_start_date       TIMESTAMP WITH TIME ZONE,
        i_end_date         TIMESTAMP WITH TIME ZONE,
        i_start_hour       NUMBER,
        i_end_hour         NUMBER,
        i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_event         sch_event.id_sch_event%TYPE DEFAULT pk_schedule.g_event_exam,
        i_weekdays         VARCHAR2 DEFAULT NULL
    ) IS
        l_start_date             TIMESTAMP WITH TIME ZONE;
        l_end_date               TIMESTAMP WITH TIME ZONE;
        l_start_hour             NUMBER := greatest(0, i_start_hour);
        l_end_hour               NUMBER := least(i_end_hour, 24);
        l_slot_interval          NUMBER := i_slot_interval;
        l_professional           profissional := i_prof;
        l_dept_clin_serv         sch_consult_vacancy.id_dep_clin_serv%TYPE := i_id_dep_clin_serv;
        l_event                  sch_consult_vacancy.id_sch_event%TYPE := i_id_event;
        l_max_vacancies          sch_consult_vacancy.max_vacancies%TYPE DEFAULT NULL;
        l_id_sch_consult_vacancy sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_weekday                INTEGER;
        l_weekdays               table_number;
        l_exists                 VARCHAR2(1);
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        l_start_date := pk_date_utils.add_to_ltstz(pk_date_utils.trunc_insttimezone(i_prof, i_start_date),
                                                   l_start_hour,
                                                   'HOUR');
        l_end_date   := pk_date_utils.trunc_insttimezone(i_prof, i_end_date);
        pk_date_utils.set_dst_time_check_on;
    
        l_weekdays := pk_schedule.get_list_number_csv(i_weekdays);
    
        -- Loop until start_date reaches the end_date
        WHILE (l_start_date <= l_end_date)
        LOOP
            -- Generate number of vacancies
            l_max_vacancies := abs(MOD(dbms_random.random, i_max_vacancies)) + 1;
        
            -- obter dia da semana
            l_weekday := 1 + MOD(to_number(to_char(l_start_date, 'J')), 7);
        
            BEGIN
                SELECT 'Y'
                  INTO l_exists
                  FROM dual
                 WHERE i_weekdays IS NULL
                    OR l_weekday IN (SELECT column_value
                                       FROM TABLE(l_weekdays));
            EXCEPTION
                WHEN no_data_found THEN
                    l_exists := 'N';
            END;
        
            -- so insere se o dia da semana da data actual pertencer aos dias da semana fornecidos ou nao haver dias semanais fornecidos
            IF l_exists = 'Y'
            THEN
            
                -- Insert the vacancy record
                INSERT INTO sch_consult_vacancy
                    (id_sch_consult_vacancy,
                     dt_sch_consult_vacancy_tstz,
                     id_institution,
                     id_prof,
                     dt_begin_tstz,
                     max_vacancies,
                     used_vacancies,
                     dt_end_tstz,
                     id_dep_clin_serv,
                     id_room,
                     id_sch_event,
                     flg_status)
                VALUES
                    (seq_sch_consult_vacancy.nextval,
                     current_timestamp,
                     l_professional.institution,
                     l_professional.id,
                     l_start_date,
                     l_max_vacancies,
                     0,
                     pk_date_utils.add_to_ltstz(l_start_date, i_slot_interval, 'MINUTE'), --NULL,
                     l_dept_clin_serv,
                     NULL,
                     l_event,
                     pk_schedule_bo.g_status_active)
                RETURNING id_sch_consult_vacancy INTO l_id_sch_consult_vacancy;
            
            END IF;
        
            -- Increment the start_date by the number of minutes of each slot
            l_start_date := pk_date_utils.add_to_ltstz(l_start_date, l_slot_interval, 'MINUTE');
            IF (pk_date_utils.get_timestamp_diff(l_start_date, pk_date_utils.trunc_insttimezone(i_prof, l_start_date)) * 24 >=
               l_end_hour)
            THEN
                l_start_date := pk_date_utils.add_to_ltstz(pk_date_utils.trunc_insttimezone(i_prof, l_start_date),
                                                           24 + l_start_hour,
                                                           'HOUR');
            END IF;
        
        END LOOP;
        COMMIT;
    END generate_exam_vacancies;

    /*
    * Generates random exam vacancies.
    * For development purposes only.
    *
    * @param i_prof                       Professional.
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_max_vacancies              Maximum number of vacancies per date/hour.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_dep_clin_serv           Department-Clinical Service identifier.
    * @param i_id_event                   Event identifier.
    * @param i_id_analysis                Analysis identifier.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    */
    PROCEDURE generate_analysis_vacancies
    (
        i_prof             profissional,
        i_slot_interval    NUMBER,
        i_max_vacancies    NUMBER,
        i_start_date       TIMESTAMP WITH TIME ZONE,
        i_end_date         TIMESTAMP WITH TIME ZONE,
        i_start_hour       NUMBER,
        i_end_hour         NUMBER,
        i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_event         sch_event.id_sch_event%TYPE,
        i_id_analysis      analysis.id_analysis%TYPE
    ) IS
        l_start_date             TIMESTAMP WITH TIME ZONE;
        l_end_date               TIMESTAMP WITH TIME ZONE;
        l_start_hour             NUMBER := least(i_start_hour, 0);
        l_end_hour               NUMBER := greatest(i_end_hour, 24);
        l_slot_interval          NUMBER := i_slot_interval;
        l_professional           profissional := i_prof;
        l_dept_clin_serv         sch_consult_vacancy.id_dep_clin_serv%TYPE := i_id_dep_clin_serv;
        l_event                  sch_consult_vacancy.id_sch_event%TYPE := i_id_event;
        l_max_vacancies          sch_consult_vacancy.max_vacancies%TYPE DEFAULT NULL;
        l_id_sch_consult_vacancy sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        l_start_date := pk_date_utils.trunc_insttimezone(i_prof, i_start_date);
        l_end_date   := pk_date_utils.trunc_insttimezone(i_prof, i_end_date);
    
        l_start_date := pk_date_utils.add_to_ltstz(l_start_date, l_start_hour, 'HOUR');
        pk_date_utils.set_dst_time_check_on;
        -- Loop until start_date reaches the end_date
        WHILE (l_start_date <= l_end_date)
        LOOP
            -- Generate number of vacancies
            l_max_vacancies := abs(MOD(dbms_random.random, i_max_vacancies)) + 1;
            -- Insert the vacancy record
            INSERT INTO sch_consult_vacancy
                (id_sch_consult_vacancy,
                 dt_sch_consult_vacancy_tstz,
                 id_institution,
                 id_prof,
                 dt_begin_tstz,
                 max_vacancies,
                 used_vacancies,
                 dt_end_tstz,
                 id_dep_clin_serv,
                 id_room,
                 id_sch_event,
                 flg_status)
            VALUES
                (seq_sch_consult_vacancy.nextval,
                 current_timestamp,
                 l_professional.institution,
                 l_professional.id,
                 l_start_date,
                 l_max_vacancies,
                 0,
                 NULL,
                 l_dept_clin_serv,
                 NULL,
                 l_event,
                 pk_schedule_bo.g_status_active)
            RETURNING id_sch_consult_vacancy INTO l_id_sch_consult_vacancy;
        
            -- Insert the analysis-specific record
            INSERT INTO sch_consult_vac_analysis
                (id_sch_consult_vacancy, id_sch_consult_vac_analysis, id_analysis)
            VALUES
                (l_id_sch_consult_vacancy, seq_sch_consult_vac_analysis.nextval, i_id_analysis);
        
            -- Increment the start_date by the number of minutes of each slot
            l_start_date := pk_date_utils.add_to_ltstz(l_start_date, l_slot_interval, 'MINUTE');
            IF (pk_date_utils.get_timestamp_diff(l_start_date, pk_date_utils.trunc_insttimezone(i_prof, l_start_date)) * 24 >=
               l_end_hour)
            THEN
                l_start_date := pk_date_utils.add_to_ltstz(pk_date_utils.trunc_insttimezone(i_prof, l_start_date),
                                                           24 + l_start_hour,
                                                           'HOUR');
            END IF;
        END LOOP;
        COMMIT;
    END generate_analysis_vacancies;

    /*
    * Generates random mfr vacancies and slots.
    * For development purposes only.
    *
    * @param i_prof                       Professional.
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_max_vacancies              Maximum number of vacancies per date/hour.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_phys_area               Physiatry area identifier
    *
    * @author José Antunes
    * @version alpha
    * @since 2008/11/27
    */
    PROCEDURE generate_mfr_vacancies
    (
        i_prof          profissional,
        i_slot_interval NUMBER,
        i_start_date    TIMESTAMP WITH TIME ZONE,
        i_end_date      TIMESTAMP WITH TIME ZONE,
        i_start_hour    NUMBER,
        i_end_hour      NUMBER,
        i_id_event      sch_event.id_sch_event%TYPE,
        i_id_phys_area  physiatry_area.id_physiatry_area%TYPE
    ) IS
    
        l_start_date             TIMESTAMP WITH TIME ZONE;
        l_end_date               TIMESTAMP WITH TIME ZONE;
        l_start_hour             NUMBER := greatest(0, i_start_hour);
        l_end_hour               NUMBER := least(i_end_hour, 24);
        l_slot_interval          NUMBER := i_slot_interval;
        l_professional           profissional := i_prof;
        l_dept_clin_serv         sch_consult_vacancy.id_dep_clin_serv%TYPE;
        l_event                  sch_consult_vacancy.id_sch_event%TYPE := nvl(i_id_event, 11);
        l_max_vacancies          sch_consult_vacancy.max_vacancies%TYPE DEFAULT NULL;
        l_id_sch_consult_vacancy sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        o_dcs_table              table_number;
        RESULT                   BOOLEAN;
        o_error                  t_error_out;
    BEGIN
    
        RESULT := pk_schedule_mfr.get_prof_base_dcs_perm(i_lang         => 1,
                                                         i_prof         => i_prof,
                                                         i_flg_schedule => 'Y',
                                                         o_dcs          => o_dcs_table,
                                                         o_error        => o_error);
    
        IF (o_dcs_table.count > 0)
        THEN
            l_dept_clin_serv := o_dcs_table(1);
        END IF;
    
        pk_date_utils.set_dst_time_check_off;
        l_start_date := pk_date_utils.trunc_insttimezone(i_prof, i_start_date);
        l_end_date   := pk_date_utils.trunc_insttimezone(i_prof, i_end_date);
        pk_date_utils.set_dst_time_check_on;
        --        dbms_output.put_line('enddate=' || l_end_date);
    
        l_start_date := pk_date_utils.add_to_ltstz(l_start_date, l_start_hour, 'HOUR');
        -- Loop until start_date reaches the end_date
        WHILE (l_start_date <= l_end_date)
        LOOP
            -- Generate number of vacancies
            l_max_vacancies := 0; --abs(MOD(dbms_random.random, i_max_vacancies)) + 1;
        
            -- Insert the vacancy record
            INSERT INTO sch_consult_vacancy
                (id_sch_consult_vacancy,
                 dt_sch_consult_vacancy_tstz,
                 id_institution,
                 id_prof,
                 dt_begin_tstz,
                 max_vacancies,
                 used_vacancies,
                 dt_end_tstz,
                 id_dep_clin_serv,
                 id_room,
                 id_sch_event,
                 flg_status)
            VALUES
                (seq_sch_consult_vacancy.nextval,
                 current_timestamp,
                 l_professional.institution,
                 l_professional.id,
                 l_start_date,
                 l_max_vacancies,
                 0,
                 pk_date_utils.add_to_ltstz(l_start_date, i_slot_interval, 'MINUTE'), --l_start_date + (i_slot_interval / 24 / 60),
                 l_dept_clin_serv,
                 NULL,
                 l_event,
                 pk_schedule_bo.g_status_active)
            RETURNING id_sch_consult_vacancy INTO l_id_sch_consult_vacancy;
        
            -- Insert the mfr-specific record
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
                (seq_sch_consult_vac_mfr_slot.nextval,
                 l_id_sch_consult_vacancy,
                 i_id_phys_area,
                 l_start_date,
                 pk_date_utils.add_to_ltstz(l_start_date, i_slot_interval, 'MINUTE'), --l_start_date + (i_slot_interval / 24 / 60),
                 l_professional.id,
                 'P',
                 l_professional.id,
                 current_timestamp);
        
            -- Insert in sch_consult_vac_mfr
            INSERT INTO sch_consult_vac_mfr
                (id_sch_consult_vacancy, id_physiatry_area)
            VALUES
                (l_id_sch_consult_vacancy, i_id_phys_area);
        
            -- Increment the start_date by the number of minutes of each slot
            l_start_date := pk_date_utils.add_to_ltstz(l_start_date, l_slot_interval, 'MINUTE');
            IF (pk_date_utils.get_timestamp_diff(l_start_date, pk_date_utils.trunc_insttimezone(i_prof, l_start_date)) * 24 >=
               l_end_hour)
            THEN
                l_start_date := pk_date_utils.add_to_ltstz(pk_date_utils.trunc_insttimezone(i_prof, l_start_date),
                                                           24 + l_start_hour,
                                                           'HOUR');
            END IF;
        
            dbms_output.put_line('start=' || l_start_date);
        
        END LOOP;
        COMMIT;
    
    END generate_mfr_vacancies;

    /*
    * Generates continuous oris vacancies and their inicial slots.
    *
    * @param i_prof                       Professional to whom these vacancies are for(if i_profless=N). otherwise its used in date funtions
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_dep_clin_serv           Department-Clinical Service identifier.
    * @param i_id_event                   event must be 14 or other proper event created by configurations.
    * @param i_id_room                    Room identifier
    * @param i_flg_urgent                 Y = vacancies are created for emergency surgeries. N = for elective surgeries
    * @param i_weekdays                   list of weekday in csv format in which vacancies should be created. 1=monday, 7=sunday, null=all
    * @param i_id_prof_generator          prof. who's creating the vacancies. Can be null
    * @param i_profless                   Y = generated vacancies are professional-less. N= gen. vacancies are assigned to i_prof
    *
    * @author  Telmo
    * @version 2.5
    * @date    06-04-2009
    */
    PROCEDURE generate_oris_vacancies
    (
        i_prof              profissional,
        i_slot_interval     NUMBER,
        i_start_date        TIMESTAMP WITH TIME ZONE,
        i_end_date          TIMESTAMP WITH TIME ZONE,
        i_start_hour        NUMBER,
        i_end_hour          NUMBER,
        i_id_dep_clin_serv  dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_event          sch_event.id_sch_event%TYPE,
        i_id_room           sch_consult_vacancy.id_room%TYPE,
        i_flg_urgent        sch_consult_vac_oris.flg_urgency%TYPE DEFAULT 'N',
        i_weekdays          VARCHAR2 DEFAULT NULL,
        i_id_prof_generator professional.id_professional%TYPE DEFAULT NULL,
        i_profless          VARCHAR2 DEFAULT 'N'
    ) IS
        l_start_date             TIMESTAMP WITH TIME ZONE;
        l_end_date               TIMESTAMP WITH TIME ZONE;
        l_start_hour             NUMBER := greatest(0, i_start_hour);
        l_end_hour               NUMBER := least(i_end_hour, 24);
        l_id_event               sch_consult_vacancy.id_sch_event%TYPE := nvl(i_id_event, 14);
        l_id_sch_consult_vacancy sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_weekday                INTEGER;
        l_weekdays               table_number;
        l_exists                 VARCHAR2(1);
    BEGIN
        -- parametros obrigatorios
        IF i_prof.institution IS NULL
           OR i_slot_interval IS NULL
           OR i_start_date IS NULL
           OR i_end_date IS NULL
           OR i_start_hour IS NULL
           OR i_end_hour IS NULL
           OR i_id_dep_clin_serv IS NULL
           OR i_id_room IS NULL
           OR i_flg_urgent IS NULL
        THEN
            RETURN;
        END IF;
    
        -- amanhar as datas recebidas
        pk_date_utils.set_dst_time_check_off;
        l_start_date := pk_date_utils.trunc_insttimezone(i_prof, i_start_date);
        l_end_date   := pk_date_utils.trunc_insttimezone(i_prof, i_end_date);
        pk_date_utils.set_dst_time_check_on;
    
        -- converter parametro i_weekdays para table_number
        l_weekdays := pk_schedule.get_list_number_csv(i_weekdays);
    
        -- data inicial do loop
        l_start_date := pk_date_utils.add_to_ltstz(l_start_date, l_start_hour, 'HOUR');
    
        -- Loop until start_date reaches the end_date
        WHILE (l_start_date <= l_end_date)
        LOOP
            -- obter dia da semana
            l_weekday := 1 + MOD(to_number(to_char(l_start_date, 'J')), 7);
        
            BEGIN
                SELECT 'Y'
                  INTO l_exists
                  FROM dual
                 WHERE i_weekdays IS NULL
                    OR l_weekday IN (SELECT column_value
                                       FROM TABLE(l_weekdays));
            EXCEPTION
                WHEN no_data_found THEN
                    l_exists := 'N';
            END;
        
            -- so insere se o dia da semana da data actual pertencer aos dias da semana fornecidos ou nao haver dias semanais fornecidos
            IF l_exists = 'Y'
            THEN
            
                -- Insert the vacancy record
                INSERT INTO sch_consult_vacancy
                    (id_sch_consult_vacancy,
                     dt_sch_consult_vacancy_tstz,
                     id_institution,
                     id_prof,
                     dt_begin_tstz,
                     dt_end_tstz,
                     max_vacancies,
                     used_vacancies,
                     id_dep_clin_serv,
                     id_room,
                     id_sch_event,
                     flg_status)
                VALUES
                    (seq_sch_consult_vacancy.nextval,
                     current_timestamp,
                     i_prof.institution,
                     CASE WHEN nvl(i_profless, 'N') = 'N' THEN i_prof.id ELSE NULL END,
                     l_start_date,
                     pk_date_utils.add_to_ltstz(l_start_date, i_slot_interval, 'MINUTE'), --l_start_date + (i_slot_interval / 24 / 60),
                     0,
                     0,
                     i_id_dep_clin_serv,
                     i_id_room,
                     l_id_event,
                     pk_schedule_bo.g_status_active)
                RETURNING id_sch_consult_vacancy INTO l_id_sch_consult_vacancy;
            
                -- Insert in sch_consult_vac_oris
                INSERT INTO sch_consult_vac_oris
                    (id_sch_consult_vacancy, flg_urgency)
                VALUES
                    (l_id_sch_consult_vacancy, i_flg_urgent);
            
                -- Insert slot
                INSERT INTO sch_consult_vac_oris_slot
                    (id_sch_consult_vac_oris_slot, id_sch_consult_vacancy, dt_begin, dt_end)
                VALUES
                    (seq_sch_consult_vac_oris_slot.nextval,
                     l_id_sch_consult_vacancy,
                     l_start_date,
                     pk_date_utils.add_to_ltstz(l_start_date, i_slot_interval, 'MINUTE') --l_start_date + (i_slot_interval / 24 / 60),
                     );
            END IF;
        
            -- Increment the start_date by the number of minutes of each slot
            l_start_date := pk_date_utils.add_to_ltstz(l_start_date, i_slot_interval, 'MINUTE');
            IF pk_date_utils.get_timestamp_diff(l_start_date, pk_date_utils.trunc_insttimezone(i_prof, l_start_date)) * 24 >=
               l_end_hour
            THEN
                l_start_date := pk_date_utils.add_to_ltstz(pk_date_utils.trunc_insttimezone(i_prof, l_start_date),
                                                           24 + l_start_hour,
                                                           'HOUR');
            END IF;
        END LOOP;
        COMMIT;
    
    END generate_oris_vacancies;

    /*
    * Private procedure. Inserts one or more rows into translation and its affiliate lb_translation.
    * Number of inserted rows depends on the i_cs_ids cardinality.
    */
    PROCEDURE generate_app_translation
    (
        i_id_sch_event  sch_event.id_sch_event%TYPE,
        i_cs_ids        table_number,
        i_upd_lb_transl BOOLEAN DEFAULT TRUE
    ) IS
        l_func_name    VARCHAR2(32) := $$PLSQL_UNIT;
        l_event_trans  alert_core_tech.t_rec_translation;
        l_all_cs_trans alert_core_tech.t_tab_translation := alert_core_tech.t_tab_translation();
        l_prefix_code_event CONSTANT VARCHAR2(200) := 'SCH_EVENT.CODE_SCH_EVENT.';
        l_table_name        CONSTANT VARCHAR2(200) := 'APPOINTMENT';
        l_prefix            CONSTANT VARCHAR2(200) := 'APPOINTMENT.CODE_APPOINTMENT.APP.';
        l_full_prefix       CONSTANT VARCHAR2(200) := 'APPOINTMENT.CODE_APPOINTMENT.APP.';
        l_lb_codes table_varchar := table_varchar();
        i          PLS_INTEGER;
    BEGIN
        g_error := l_func_name || ' - get translation record for i_id_sch_event=' || i_id_sch_event;
        SELECT alert_core_tech.t_rec_translation(t.code_translation,
                                                 NULL, --table_owner. not needed
                                                 NULL, --full_code. not needed
                                                 NULL, --table_name. not needed
                                                 NULL, --module. not needed
                                                 t.desc_lang_1,
                                                 t.desc_lang_2,
                                                 t.desc_lang_3,
                                                 t.desc_lang_4,
                                                 t.desc_lang_5,
                                                 t.desc_lang_6,
                                                 t.desc_lang_7,
                                                 t.desc_lang_8,
                                                 t.desc_lang_9,
                                                 t.desc_lang_10,
                                                 t.desc_lang_11,
                                                 t.desc_lang_12,
                                                 t.desc_lang_13,
                                                 t.desc_lang_14,
                                                 t.desc_lang_15,
                                                 t.desc_lang_16,
                                                 t.desc_lang_17,
                                                 t.desc_lang_18,
                                                 t.desc_lang_19,
                                                 t.desc_lang_20,
                                                 t.desc_lang_21,
                                                 t.desc_lang_22,
                                                 NULL) -- desc_lang_23. not used
          INTO l_event_trans
          FROM translation t
         WHERE t.code_translation = l_prefix_code_event || to_char(i_id_sch_event);
    
        g_error := l_func_name || ' - get translation record for i_id_sch_event=' || i_id_sch_event;
        SELECT alert_core_tech.t_rec_translation(l_prefix || ct, --code_translation
                                                  'ALERT', --table_owner
                                                  l_full_prefix || ct, -- full_code
                                                  l_table_name, --table_name
                                                  'PFH', --module
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_1 IS NOT NULL
                                                           AND d1 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_1 || ': ' || d1
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_2 IS NOT NULL
                                                           AND d2 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_2 || ': ' || d2
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_3 IS NOT NULL
                                                           AND d3 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_3 || ': ' || d3
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_4 IS NOT NULL
                                                           AND d4 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_4 || ': ' || d4
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_5 IS NOT NULL
                                                           AND d5 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_5 || ': ' || d5
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_6 IS NOT NULL
                                                           AND d6 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_6 || ': ' || d6
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_7 IS NOT NULL
                                                           AND d7 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_7 || ': ' || d7
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_8 IS NOT NULL
                                                           AND d8 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_8 || ': ' || d8
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_9 IS NOT NULL
                                                           AND d9 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_9 || ': ' || d9
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_10 IS NOT NULL
                                                           AND d10 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_10 || ': ' || d10
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_11 IS NOT NULL
                                                           AND d11 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_11 || ': ' || d11
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_12 IS NOT NULL
                                                           AND d12 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_12 || ': ' || d12
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_13 IS NOT NULL
                                                           AND d13 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_13 || ': ' || d13
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_14 IS NOT NULL
                                                           AND d14 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_14 || ': ' || d14
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_15 IS NOT NULL
                                                           AND d15 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_15 || ': ' || d15
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_16 IS NOT NULL
                                                           AND d16 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_16 || ': ' || d16
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_17 IS NOT NULL
                                                           AND d17 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_17 || ': ' || d17
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_18 IS NOT NULL
                                                           AND d18 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_18 || ': ' || d18
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_19 IS NOT NULL
                                                           AND d19 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_19 || ': ' || d19
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_20 IS NOT NULL
                                                           AND d20 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_20 || ': ' || d20
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_21 IS NOT NULL
                                                           AND d21 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_21 || ': ' || d21
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_22 IS NOT NULL
                                                           AND d22 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_22 || ': ' || d22
                                                      ELSE
                                                       NULL
                                                  END,
                                                  NULL) -- desc_lang_23. not used
          BULK COLLECT
          INTO l_all_cs_trans
          FROM (SELECT to_char(i_id_sch_event) || '.' || to_char(cs.id_clinical_service) ct,
                       TRIM(desc_lang_1) d1,
                       TRIM(desc_lang_2) d2,
                       TRIM(desc_lang_3) d3,
                       TRIM(desc_lang_4) d4,
                       TRIM(desc_lang_5) d5,
                       TRIM(desc_lang_6) d6,
                       TRIM(desc_lang_7) d7,
                       TRIM(desc_lang_8) d8,
                       TRIM(desc_lang_9) d9,
                       TRIM(desc_lang_10) d10,
                       TRIM(desc_lang_11) d11,
                       TRIM(desc_lang_12) d12,
                       TRIM(desc_lang_13) d13,
                       TRIM(desc_lang_14) d14,
                       TRIM(desc_lang_15) d15,
                       TRIM(desc_lang_16) d16,
                       TRIM(desc_lang_17) d17,
                       TRIM(desc_lang_18) d18,
                       TRIM(desc_lang_19) d19,
                       TRIM(desc_lang_20) d20,
                       TRIM(desc_lang_21) d21,
                       TRIM(desc_lang_22) d22
                  FROM translation t
                  JOIN clinical_service cs
                    ON t.code_translation = cs.code_clinical_service
                 WHERE cs.id_clinical_service IN (SELECT column_value
                                                    FROM TABLE(i_cs_ids)));
    
        -- update translations. Unlike insert_into_translation which is basically a merge, these bulk operations are separate
        g_error := l_func_name || ' - call upd_bulk_translation';
        pk_translation.upd_bulk_translation(i_tab => l_all_cs_trans);
        dbms_output.put_line('updated ' || SQL%ROWCOUNT || ' translation rows');
    
        -- insert translations
        g_error := l_func_name || ' - call ins_bulk_translation';
        pk_translation.ins_bulk_translation(i_tab => l_all_cs_trans, i_ignore_dup => 'Y');
        dbms_output.put_line('inserted ' || SQL%ROWCOUNT || ' translation rows');
    
        -- traducoes na lb_translation.
        -- So' actualiza as existentes, nao insere porque isso e' tarefa exclusiva do backoffice 
        IF nvl(i_upd_lb_transl, TRUE)
        THEN
            generate_lb_translations(1, table_varchar(l_prefix || to_char(i_id_sch_event)));
        END IF;
    END generate_app_translation;

    /*
    * Private procedure. Inserts one or more rows into translation and its affiliate lb_translation.
    * Number of inserted rows depends on the i_cs_ids cardinality.
    */
    PROCEDURE generate_app_alias_translation
    (
        i_id_sch_event_alias sch_event_alias.id_sch_event_alias%TYPE,
        i_id_sch_event       sch_event_alias.id_sch_event%TYPE,
        i_cs_ids             table_number,
        i_upd_lb_transl      BOOLEAN DEFAULT TRUE
    ) IS
        l_func_name    VARCHAR2(32) := $$PLSQL_UNIT;
        l_event_trans  alert_core_tech.t_rec_translation;
        l_all_cs_trans alert_core_tech.t_tab_translation := alert_core_tech.t_tab_translation();
        l_prefix_code_event CONSTANT VARCHAR2(200) := 'SCH_EVENT_ALIAS.CODE_SCH_EVENT_ALIAS.';
        l_table_name        CONSTANT VARCHAR2(30) := 'APPOINTMENT_ALIAS';
        l_prefix            CONSTANT VARCHAR2(50) := 'APPOINTMENT_ALIAS.CODE_APPOINTMENT_ALIAS.APPA_';
        l_full_prefix       CONSTANT VARCHAR2(50) := 'APPOINTMENT_ALIAS.CODE_APPOINTMENT_ALIAS.';
        l_code              CONSTANT VARCHAR2(200) := 'APPOINTMENT_ALIAS.CODE_APPOINTMENT_ALIAS.';
        l_lb_codes table_varchar := table_varchar();
        i          PLS_INTEGER;
    BEGIN
        g_error := l_func_name || ' - get translation record for i_id_sch_event=' || i_id_sch_event;
        SELECT alert_core_tech.t_rec_translation(t.code_translation,
                                                 NULL, --table_owner. not needed
                                                 NULL, --full_code. not needed
                                                 NULL, --table_name. not needed
                                                 NULL, --module. not needed
                                                 t.desc_lang_1,
                                                 t.desc_lang_2,
                                                 t.desc_lang_3,
                                                 t.desc_lang_4,
                                                 t.desc_lang_5,
                                                 t.desc_lang_6,
                                                 t.desc_lang_7,
                                                 t.desc_lang_8,
                                                 t.desc_lang_9,
                                                 t.desc_lang_10,
                                                 t.desc_lang_11,
                                                 t.desc_lang_12,
                                                 t.desc_lang_13,
                                                 t.desc_lang_14,
                                                 t.desc_lang_15,
                                                 t.desc_lang_16,
                                                 t.desc_lang_17,
                                                 t.desc_lang_18,
                                                 t.desc_lang_19,
                                                 t.desc_lang_20,
                                                 t.desc_lang_21,
                                                 t.desc_lang_22,
                                                 NULL) -- desc_lang_23. not used
          INTO l_event_trans
          FROM translation t
         WHERE t.code_translation = l_prefix_code_event || i_id_sch_event_alias;
    
        g_error := l_func_name || ' - get translation record for i_id_sch_event=' || to_char(i_id_sch_event) ||
                   ', i_id_sch_event_alias=' || i_id_sch_event_alias;
        SELECT alert_core_tech.t_rec_translation(l_prefix || ct, --code_translation
                                                  'ALERT', --table_owner
                                                  l_full_prefix || ct, -- full_code
                                                  l_table_name, --table_name
                                                  'PFH', --module
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_1 IS NOT NULL
                                                           AND d1 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_1 || ': ' || d1
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_2 IS NOT NULL
                                                           AND d2 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_2 || ': ' || d2
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_3 IS NOT NULL
                                                           AND d3 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_3 || ': ' || d3
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_4 IS NOT NULL
                                                           AND d4 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_4 || ': ' || d4
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_5 IS NOT NULL
                                                           AND d5 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_5 || ': ' || d5
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_6 IS NOT NULL
                                                           AND d6 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_6 || ': ' || d6
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_7 IS NOT NULL
                                                           AND d7 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_7 || ': ' || d7
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_8 IS NOT NULL
                                                           AND d8 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_8 || ': ' || d8
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_9 IS NOT NULL
                                                           AND d9 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_9 || ': ' || d9
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_10 IS NOT NULL
                                                           AND d10 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_10 || ': ' || d10
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_11 IS NOT NULL
                                                           AND d11 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_11 || ': ' || d11
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_12 IS NOT NULL
                                                           AND d12 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_12 || ': ' || d12
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_13 IS NOT NULL
                                                           AND d13 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_13 || ': ' || d13
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_14 IS NOT NULL
                                                           AND d14 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_14 || ': ' || d14
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_15 IS NOT NULL
                                                           AND d15 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_15 || ': ' || d15
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_16 IS NOT NULL
                                                           AND d16 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_16 || ': ' || d16
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_17 IS NOT NULL
                                                           AND d17 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_17 || ': ' || d17
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_18 IS NOT NULL
                                                           AND d18 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_18 || ': ' || d18
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_19 IS NOT NULL
                                                           AND d19 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_19 || ': ' || d19
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_20 IS NOT NULL
                                                           AND d20 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_20 || ': ' || d20
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_21 IS NOT NULL
                                                           AND d21 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_21 || ': ' || d21
                                                      ELSE
                                                       NULL
                                                  END,
                                                  CASE
                                                      WHEN l_event_trans.desc_lang_22 IS NOT NULL
                                                           AND d22 IS NOT NULL THEN
                                                       l_event_trans.desc_lang_22 || ': ' || d22
                                                      ELSE
                                                       NULL
                                                  END,
                                                  NULL) -- desc_lang_23. not used
          BULK COLLECT
          INTO l_all_cs_trans
          FROM (SELECT i_id_sch_event_alias || '_' || to_char(cs.id_clinical_service) ct,
                       TRIM(desc_lang_1) d1,
                       TRIM(desc_lang_2) d2,
                       TRIM(desc_lang_3) d3,
                       TRIM(desc_lang_4) d4,
                       TRIM(desc_lang_5) d5,
                       TRIM(desc_lang_6) d6,
                       TRIM(desc_lang_7) d7,
                       TRIM(desc_lang_8) d8,
                       TRIM(desc_lang_9) d9,
                       TRIM(desc_lang_10) d10,
                       TRIM(desc_lang_11) d11,
                       TRIM(desc_lang_12) d12,
                       TRIM(desc_lang_13) d13,
                       TRIM(desc_lang_14) d14,
                       TRIM(desc_lang_15) d15,
                       TRIM(desc_lang_16) d16,
                       TRIM(desc_lang_17) d17,
                       TRIM(desc_lang_18) d18,
                       TRIM(desc_lang_19) d19,
                       TRIM(desc_lang_20) d20,
                       TRIM(desc_lang_21) d21,
                       TRIM(desc_lang_22) d22
                  FROM translation t
                  JOIN clinical_service cs
                    ON t.code_translation = cs.code_clinical_service
                 WHERE cs.id_clinical_service IN (SELECT column_value
                                                    FROM TABLE(i_cs_ids)));
    
        -- update translations. Unlike insert_into_translation which is basically a merge, these bulk operations are separate
        g_error := l_func_name || ' - call upd_bulk_translation';
        pk_translation.upd_bulk_translation(i_tab => l_all_cs_trans);
        dbms_output.put_line('updated ' || SQL%ROWCOUNT || ' translation rows');
    
        -- insert translations
        g_error := l_func_name || ' - call ins_bulk_translation';
        pk_translation.ins_bulk_translation(i_tab => l_all_cs_trans, i_ignore_dup => 'Y');
        dbms_output.put_line('inserted ' || SQL%ROWCOUNT || ' translation rows');
    
        -- traducoes na lb_translation.
        -- So' actualiza as existentes, nao insere porque isso e' tarefa exclusiva do backoffice 
        IF nvl(i_upd_lb_transl, TRUE)
        THEN
            generate_lb_translations(1, table_varchar(l_prefix || i_id_sch_event_alias));
        END IF;
    END generate_app_alias_translation;

    /* gerador de registos na appointment. Para ser usado quando se criam novos eventos
    *
    * 20-09-2012 update
    * adaptado para ser igualmente usado quando se altera a traducao de eventos
    *
    * 27-02-2013 update
    * adaptado aos requisitos da 263 -> merge na translation nao permitido
    * 
    * COM O S.A.R.A. E O C.O.E.N, ISTO FICA OBSOLETO. NAO USAR.
    */
    FUNCTION generate_appointments
    (
        i_lang          NUMBER,
        i_ids_sch_event table_number, -- deve conter os ids dos eventos novos
        i_ids_cs        table_number, -- se nao vazia, vai gerar apenas para esta lista
        i_upd_lb_transl BOOLEAN DEFAULT TRUE, -- TRUE = actualiza traducoes das appointments na agenda(tabela lb_translation)
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := $$PLSQL_UNIT;
        l_cs_ids        table_number := i_ids_cs;
        i               PLS_INTEGER;
        l_curr_event_id VARCHAR2(4);
        l_all_cs_trans  alert_core_tech.t_tab_translation := alert_core_tech.t_tab_translation();
        l_event_trans   alert_core_tech.t_rec_translation;
        l_codes         table_varchar := table_varchar();
        l_prefix        VARCHAR2(50) := 'APPOINTMENT.CODE_APPOINTMENT.APP.';
        l_full_prefix   VARCHAR2(50) := 'APPOINTMENT.CODE_APPOINTMENT.APP.';
    
        --error handling
        bulk_errors EXCEPTION;
        err_count INTEGER;
        PRAGMA EXCEPTION_INIT(bulk_errors, -24381);
    BEGIN
        -- fetch clinical service ids if none passed
        IF nvl(cardinality(l_cs_ids), 0) = 0
        THEN
            g_error := 'GET CLINICAL SERVICE IDS';
            SELECT id_clinical_service
              BULK COLLECT
              INTO l_cs_ids
              FROM clinical_service cs
             WHERE cs.flg_available = 'Y';
        END IF;
    
        -- loop through supplied events. Each is going to be crossed with the CS list
        i := i_ids_sch_event.first;
        WHILE i IS NOT NULL
        LOOP
            -- convert event id to varchar
            g_error         := 'CONVERT EVENT ID TO VARCHAR';
            l_curr_event_id := to_char(i_ids_sch_event(i));
        
            -- get this event translations. Pk_translation not friendly for this task
            g_error := 'GET EVENT TRANSLATIONS';
            SELECT alert_core_tech.t_rec_translation(t.code_translation,
                                                     NULL, --table_owner. not needed
                                                     NULL, --full_code. not needed
                                                     NULL, --table_name. not needed
                                                     NULL, --module. not needed
                                                     t.desc_lang_1,
                                                     t.desc_lang_2,
                                                     t.desc_lang_3,
                                                     t.desc_lang_4,
                                                     t.desc_lang_5,
                                                     t.desc_lang_6,
                                                     t.desc_lang_7,
                                                     t.desc_lang_8,
                                                     t.desc_lang_9,
                                                     t.desc_lang_10,
                                                     t.desc_lang_11,
                                                     t.desc_lang_12,
                                                     t.desc_lang_13,
                                                     t.desc_lang_14,
                                                     t.desc_lang_15,
                                                     t.desc_lang_16,
                                                     t.desc_lang_17,
                                                     t.desc_lang_18,
                                                     t.desc_lang_19,
                                                     t.desc_lang_20,
                                                     t.desc_lang_21,
                                                     t.desc_lang_22,
                                                     NULL) -- desc_lang_23. not used
              INTO l_event_trans
              FROM translation t -- isto e' uma view aqui na 263
             WHERE t.code_translation = 'SCH_EVENT.CODE_SCH_EVENT.' || l_curr_event_id;
        
            -- build code to be later used when calling the lb_translation generator
            l_codes.extend;
            l_codes(l_codes.last) := l_prefix || l_curr_event_id;
        
            -- insert into appointment table
            g_error := 'MERGE INTO APPOINTMENT (FORALL)';
            FORALL j IN 1 .. l_cs_ids.count SAVE EXCEPTIONS
                MERGE INTO appointment g
                USING (SELECT i_ids_sch_event(i) id_se, l_cs_ids(j) id_cs
                         FROM dual) d
                ON (g.id_clinical_service = d.id_cs AND g.id_sch_event = d.id_se)
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_appointment, id_clinical_service, id_sch_event, flg_available, code_appointment)
                    VALUES
                        ('APP.' || l_curr_event_id || '.' || to_char(d.id_cs),
                         d.id_cs,
                         d.id_se,
                         'Y',
                         l_prefix || l_curr_event_id || '.' || to_char(d.id_cs));
        
            dbms_output.put_line('inserted ' || SQL%ROWCOUNT || ' appointment rows for event ' || l_curr_event_id);
        
            -- get clinical service translations and at the same time set appointments translations
            g_error := 'GET CLINICAL SERVICE TRANSLATIONS';
            l_all_cs_trans.delete;
        
            SELECT alert_core_tech.t_rec_translation(l_prefix || ct, --code_translation
                                                      'ALERT', --table_owner
                                                      l_full_prefix || ct, -- full_code
                                                      'APPOINTMENT', --table_name
                                                      'PFH', --module
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_1 IS NOT NULL
                                                               AND d1 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_1 || ': ' || d1
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_2 IS NOT NULL
                                                               AND d2 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_2 || ': ' || d2
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_3 IS NOT NULL
                                                               AND d3 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_3 || ': ' || d3
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_4 IS NOT NULL
                                                               AND d4 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_4 || ': ' || d4
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_5 IS NOT NULL
                                                               AND d5 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_5 || ': ' || d5
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_6 IS NOT NULL
                                                               AND d6 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_6 || ': ' || d6
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_7 IS NOT NULL
                                                               AND d7 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_7 || ': ' || d7
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_8 IS NOT NULL
                                                               AND d8 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_8 || ': ' || d8
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_9 IS NOT NULL
                                                               AND d9 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_9 || ': ' || d9
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_10 IS NOT NULL
                                                               AND d10 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_10 || ': ' || d10
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_11 IS NOT NULL
                                                               AND d11 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_11 || ': ' || d11
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_12 IS NOT NULL
                                                               AND d12 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_12 || ': ' || d12
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_13 IS NOT NULL
                                                               AND d13 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_13 || ': ' || d13
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_14 IS NOT NULL
                                                               AND d14 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_14 || ': ' || d14
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_15 IS NOT NULL
                                                               AND d15 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_15 || ': ' || d15
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_16 IS NOT NULL
                                                               AND d16 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_16 || ': ' || d16
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_17 IS NOT NULL
                                                               AND d17 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_17 || ': ' || d17
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_18 IS NOT NULL
                                                               AND d18 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_18 || ': ' || d18
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_19 IS NOT NULL
                                                               AND d19 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_19 || ': ' || d19
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_20 IS NOT NULL
                                                               AND d20 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_20 || ': ' || d20
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_21 IS NOT NULL
                                                               AND d21 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_21 || ': ' || d21
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN l_event_trans.desc_lang_22 IS NOT NULL
                                                               AND d22 IS NOT NULL THEN
                                                           l_event_trans.desc_lang_22 || ': ' || d22
                                                          ELSE
                                                           NULL
                                                      END,
                                                      NULL) -- desc_lang_23. not used
              BULK COLLECT
              INTO l_all_cs_trans
              FROM (SELECT l_curr_event_id || '.' || to_char(cs.id_clinical_service) ct,
                           TRIM(desc_lang_1) d1,
                           TRIM(desc_lang_2) d2,
                           TRIM(desc_lang_3) d3,
                           TRIM(desc_lang_4) d4,
                           TRIM(desc_lang_5) d5,
                           TRIM(desc_lang_6) d6,
                           TRIM(desc_lang_7) d7,
                           TRIM(desc_lang_8) d8,
                           TRIM(desc_lang_9) d9,
                           TRIM(desc_lang_10) d10,
                           TRIM(desc_lang_11) d11,
                           TRIM(desc_lang_12) d12,
                           TRIM(desc_lang_13) d13,
                           TRIM(desc_lang_14) d14,
                           TRIM(desc_lang_15) d15,
                           TRIM(desc_lang_16) d16,
                           TRIM(desc_lang_17) d17,
                           TRIM(desc_lang_18) d18,
                           TRIM(desc_lang_19) d19,
                           TRIM(desc_lang_20) d20,
                           TRIM(desc_lang_21) d21,
                           TRIM(desc_lang_22) d22
                      FROM translation t
                      JOIN clinical_service cs
                        ON t.code_translation = cs.code_clinical_service
                     WHERE cs.id_clinical_service IN (SELECT column_value
                                                        FROM TABLE(l_cs_ids)));
        
            -- update translations. Unlike insert_into_translation which is basically a merge, these bulk operations are separate
            g_error := 'UPDATE TRANSLATION';
            pk_translation.upd_bulk_translation(i_tab => l_all_cs_trans);
            dbms_output.put_line('updated ' || SQL%ROWCOUNT || ' translation rows for event ' || l_curr_event_id);
        
            -- insert translations
            g_error := 'INSERT INTO TRANSLATION';
            pk_translation.ins_bulk_translation(i_tab => l_all_cs_trans, i_ignore_dup => 'Y');
            dbms_output.put_line('inserted ' || SQL%ROWCOUNT || ' translation rows for event ' || l_curr_event_id);
        
            -- virou
            i := i_ids_sch_event.next(i);
        END LOOP;
    
        -- NEW! 19-05-2014 - disable all appointments whose id_clinical_service turned unavailable
        UPDATE (SELECT a.flg_available AS OLD, cs.flg_available AS NEW
                  FROM appointment a
                 INNER JOIN clinical_service cs
                    ON a.id_clinical_service = cs.id_clinical_service
                 WHERE cs.flg_available = 'N'
                   AND a.flg_available = 'Y') t
           SET t.old = t.new;
        dbms_output.put_line('disabled ' || SQL%ROWCOUNT ||
                             ' appointments due to clinical_services having turned unavailable');
    
        -- traducoes na lb_translation
        -- so' actualiza se recebeu ordem para isso. E so' actualiza as existentes, nao insere porque isso e' tarefa exclusiva do backoffice 
        IF nvl(i_upd_lb_transl, TRUE)
        THEN
            g_error := 'MERGE INTO LB_TRANSLATION';
            generate_lb_translations(i_lang, l_codes);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN bulk_errors THEN
            err_count := SQL%bulk_exceptions.count;
            FOR idx IN 1 .. err_count
            LOOP
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => 'Error #' || idx || ' occurred during iteration #' || SQL%BULK_EXCEPTIONS(idx).error_index,
                                                  i_message  => 'Error message is: ' ||
                                                                SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code),
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
            END LOOP;
            --        pk_utils.undo_changes;
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
            --          pk_utils.undo_changes;      
            RETURN FALSE;
    END generate_appointments;

    /* gerador de registo na appointment_alias. 
    * Tambem actualiza traducoes na agenda(tabela lb_translation).
    * Usada por 
    */
    PROCEDURE generate_appt_alias
    (
        i_id_sch_event_alias sch_event_alias.id_sch_event_alias%TYPE,
        i_upd_lb_transl      BOOLEAN DEFAULT TRUE
    ) IS
        l_func_name           VARCHAR2(32) := $$PLSQL_UNIT;
        l_sch_event_alias_rec sch_event_alias%ROWTYPE;
        l_id                  appointment_alias.id_appointment_alias%TYPE := 'APPA_' || i_id_sch_event_alias;
        l_code                appointment_alias.code_appointment_alias%TYPE := 'APPOINTMENT_ALIAS.CODE_APPOINTMENT_ALIAS.';
        l_ids_cs              table_number;
    BEGIN
        g_error := l_func_name || ' - get sch_event_alias data for id_sch_event_alias=' || i_id_sch_event_alias;
        SELECT *
          INTO l_sch_event_alias_rec
          FROM sch_event_alias a
         WHERE a.id_sch_event_alias = i_id_sch_event_alias;
    
        g_error := l_func_name || ' - get all clinical services ids from appointment for id_sch_event=' ||
                   l_sch_event_alias_rec.id_sch_event;
        SELECT DISTINCT a.id_clinical_service
          BULK COLLECT
          INTO l_ids_cs
          FROM appointment a
          JOIN sch_event_dcs sed
            ON a.id_sch_event = sed.id_sch_event
          JOIN dep_clin_serv dcs
            ON sed.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN department d
            ON dcs.id_department = d.id_department
         WHERE a.id_sch_event = l_sch_event_alias_rec.id_sch_event
           AND d.id_institution = l_sch_event_alias_rec.id_institution
           AND dcs.flg_available = pk_alert_constant.g_yes
           AND sed.flg_available = pk_alert_constant.g_yes
           AND a.flg_available = pk_alert_constant.g_yes;
    
        -- insert na appointment_alias 
        g_error := l_func_name || ' - bulk insert into appointment_alias';
        BEGIN
            FORALL j IN 1 .. l_ids_cs.count SAVE EXCEPTIONS -- save exceptions para tolerar inserts que falhem
                INSERT INTO appointment_alias
                    (id_appointment_alias, id_sch_event_alias, id_clinical_service, code_appointment_alias)
                VALUES
                    (l_id || '_' || to_char(l_ids_cs(j)),
                     i_id_sch_event_alias,
                     l_ids_cs(j),
                     l_code || l_id || '_' || to_char(l_ids_cs(j)));
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        -- insert appointment_alias traducoes
        g_error := l_func_name || ' - CALL insert_translations i_code=' || l_sch_event_alias_rec.code_sch_event_alias;
        generate_app_alias_translation(i_id_sch_event_alias => i_id_sch_event_alias,
                                       i_id_sch_event       => l_sch_event_alias_rec.id_sch_event,
                                       i_cs_ids             => l_ids_cs,
                                       i_upd_lb_transl      => TRUE);
    
    END generate_appt_alias;

    /*
    *  insere/actualiza na alert_basecomp.lb_translation as traducoes das chaves presentes em i_codes.
    *  exemplo de chaves: 
    * 'APPOINTMENT.CODE_APPOINTMENT.APP.291.'
    * 'APPOINTMENT.CODE_APPOINTMENT.'
    */
    PROCEDURE generate_lb_translations
    (
        i_lang  NUMBER,
        i_codes table_varchar
    ) IS
        i   PLS_INTEGER;
        now TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
        dbms_output.enable(buffer_size => 10000000);
    
        FOR i IN i_codes.first .. i_codes.last
        LOOP
            MERGE INTO alert_basecomp.lb_translation g
            USING (SELECT t.code_translation,
                          t.desc_lang_1,
                          t.desc_lang_2,
                          t.desc_lang_3,
                          t.desc_lang_4,
                          t.desc_lang_5,
                          t.desc_lang_6,
                          t.desc_lang_7,
                          t.desc_lang_8,
                          t.desc_lang_9,
                          t.desc_lang_10,
                          t.desc_lang_11,
                          t.desc_lang_12,
                          t.desc_lang_13,
                          t.desc_lang_14,
                          t.desc_lang_15,
                          t.desc_lang_16,
                          t.desc_lang_17,
                          t.desc_lang_18,
                          t.desc_lang_19,
                          t.desc_lang_20,
                          t.desc_lang_21,
                          t.desc_lang_22
                     FROM translation t
                    WHERE t.code_translation LIKE i_codes(i) || '%') d
            ON (g.code = d.code_translation)
            WHEN NOT MATCHED THEN
                INSERT
                    (id_lb_translation,
                     code,
                     software_key,
                     module_code,
                     img_name,
                     import_code,
                     record_status,
                     create_time,
                     create_user,
                     create_institution,
                     update_time,
                     update_user,
                     update_institution,
                     desc_lang_1,
                     desc_lang_2,
                     desc_lang_3,
                     desc_lang_4,
                     desc_lang_5,
                     desc_lang_6,
                     desc_lang_7,
                     desc_lang_8,
                     desc_lang_9,
                     desc_lang_10,
                     desc_lang_11,
                     desc_lang_12,
                     desc_lang_13,
                     desc_lang_14,
                     desc_lang_15,
                     desc_lang_16,
                     desc_lang_17,
                     desc_lang_18,
                     desc_lang_19,
                     desc_lang_20,
                     desc_lang_21,
                     desc_lang_22)
                VALUES
                    (seq_lb_translation.nextval,
                     d.code_translation,
                     NULL, -- software_key
                     'SCH-CORE', --module_code
                     NULL, -- img_name
                     NULL, -- import_code
                     'A', -- record_status
                     now, -- create_time
                     'ALERT', -- create_user
                     NULL, --create_institution
                     NULL, -- update
                     NULL, -- update
                     NULL, -- update
                     d.desc_lang_1,
                     d.desc_lang_2,
                     d.desc_lang_3,
                     d.desc_lang_4,
                     d.desc_lang_5,
                     d.desc_lang_6,
                     d.desc_lang_7,
                     d.desc_lang_8,
                     d.desc_lang_9,
                     d.desc_lang_10,
                     d.desc_lang_11,
                     d.desc_lang_12,
                     d.desc_lang_13,
                     d.desc_lang_14,
                     d.desc_lang_15,
                     d.desc_lang_16,
                     d.desc_lang_17,
                     d.desc_lang_18,
                     d.desc_lang_19,
                     d.desc_lang_20,
                     d.desc_lang_21,
                     d.desc_lang_22)
            WHEN MATCHED THEN
                UPDATE
                   SET desc_lang_1        = d.desc_lang_1,
                       desc_lang_2        = d.desc_lang_2,
                       desc_lang_3        = d.desc_lang_3,
                       desc_lang_4        = d.desc_lang_4,
                       desc_lang_5        = d.desc_lang_5,
                       desc_lang_6        = d.desc_lang_6,
                       desc_lang_7        = d.desc_lang_7,
                       desc_lang_8        = d.desc_lang_8,
                       desc_lang_9        = d.desc_lang_9,
                       desc_lang_10       = d.desc_lang_10,
                       desc_lang_11       = d.desc_lang_11,
                       desc_lang_12       = d.desc_lang_12,
                       desc_lang_13       = d.desc_lang_13,
                       desc_lang_14       = d.desc_lang_14,
                       desc_lang_15       = d.desc_lang_15,
                       desc_lang_16       = d.desc_lang_16,
                       desc_lang_17       = d.desc_lang_17,
                       desc_lang_18       = d.desc_lang_18,
                       desc_lang_19       = d.desc_lang_19,
                       desc_lang_20       = d.desc_lang_20,
                       desc_lang_21       = d.desc_lang_21,
                       desc_lang_22       = d.desc_lang_22,
                       update_user        = 'ALERT',
                       update_time        = now,
                       update_institution = NULL;
        
        --          dbms_output.put_line('inserted/updated ' || sql%rowcount || ' lb_translation rows for code ' || i_codes(i));
        END LOOP;
    END generate_lb_translations;

    /* 
    * Usado pelo pk_schedule_bo.set_sch_event_dcs
    */
    FUNCTION generate_appointment
    (
        i_lang          NUMBER,
        i_id_sch_event  appointment.id_sch_event%TYPE,
        i_id_cs         appointment.id_clinical_service%TYPE,
        i_id_inst       institution.id_institution%TYPE,
        i_upd_lb_transl BOOLEAN DEFAULT TRUE, -- TRUE = actualiza traducoes na agenda
        i_flg_avail     appointment.flg_available%TYPE DEFAULT pk_alert_constant.g_yes,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := $$PLSQL_UNIT;
        l_event_trans  alert_core_tech.t_rec_translation;
        l_prefix       VARCHAR2(50) := 'APPOINTMENT.CODE_APPOINTMENT.APP.';
        l_id_app       appointment.id_appointment%TYPE;
        l_id_sch_event VARCHAR2(24) := to_char(i_id_sch_event);
        l_id_cs        VARCHAR2(24) := to_char(i_id_cs);
        l_id_sea       sch_event_alias.id_sch_event_alias%TYPE;
    BEGIN
    
        -- validate input
        g_error := l_func_name || ' - VALIDATE INPUT i_id_sch_event=' || l_id_sch_event || ', i_id_cs=' || l_id_cs;
        IF i_id_sch_event IS NULL
           OR i_id_cs IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        -- check existence
        g_error := l_func_name || ' - CHECK APPOINTMENT EXISTENCE i_id_sch_event=' || l_id_sch_event || ', i_id_cs=' ||
                   l_id_cs;
        BEGIN
            SELECT a.id_appointment
              INTO l_id_app
              FROM appointment a
             WHERE a.id_clinical_service = i_id_cs
               AND a.id_sch_event = i_id_sch_event;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- if positive, update flg_available and leave
        IF l_id_app IS NOT NULL
        THEN
            g_error := l_func_name || ' - UPDATE APPOINTMENT.FLG_AVAILABLE for id_appointment=' || l_id_app;
            UPDATE appointment a
               SET a.flg_available = nvl(i_flg_avail, pk_alert_constant.g_yes)
             WHERE a.id_appointment = l_id_app;
        
            RETURN TRUE;
        END IF;
    
        -- if we got to this point, appointment will be created.         
        g_error := l_func_name || ' - INSERT INTO APPOINTMENT i_id_sch_event=' || l_id_sch_event || ', i_id_cs=' ||
                   l_id_cs;
        INSERT INTO appointment
            (id_appointment, id_clinical_service, id_sch_event, flg_available, code_appointment)
        VALUES
            ('APP.' || l_id_sch_event || '.' || l_id_cs,
             i_id_cs,
             i_id_sch_event,
             pk_alert_constant.g_yes,
             l_prefix || l_id_sch_event || '.' || l_id_cs);
    
        -- insert appointment translations
        g_error := l_func_name || ' - CALL insert_translations ';
        generate_app_translation(i_id_sch_event  => i_id_sch_event,
                                 i_cs_ids        => table_number(i_id_cs),
                                 i_upd_lb_transl => TRUE);
    
        -- NOW LETS DEAL WITH POSSIBLE EVENT ALIAS. IF THEY EXIST, WE NEED TO GENERATE APPOINTMENT ALIAS 
        -- get event alias id
        BEGIN
            g_error := l_func_name || ' - get sch_event_alias id';
            SELECT sea.id_sch_event_alias
              INTO l_id_sea
              FROM sch_event_alias sea
             WHERE sea.id_sch_event = i_id_sch_event
               AND sea.id_institution = i_id_inst;
        
            g_error := l_func_name || ' - CALL generate_appt_alias ';
            generate_appt_alias(i_id_sch_event_alias => l_id_sea, i_upd_lb_transl => TRUE);
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
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
            RETURN FALSE;
    END generate_appointment;

    /*
    *  regenerador de traducoes de appointments. 
    * DEVE-SE CORRER ISTO QUANDO SE ALTERA TRADUCOES DE EVENTOS E/OU CLINICAL SERVICES EM UMA OU MAIS LINGUAS.
    * Nao altera traducoes de eventuais event alias nem seus appointment alias. 
    */
    PROCEDURE regen_app_translations
    (
        i_ids_inst      table_number, -- used to pick events in case i_ids_sch_event is empty
        i_ids_sch_event table_number, -- ids dos eventos a que se alterou o nome...
        i_ids_cs        table_number, -- e/ou ids dos clinical services a que se alterou o nome
        i_upd_lb_transl BOOLEAN DEFAULT TRUE, -- TRUE = actualiza traducoes das appointments na agenda(tabela lb_translation)
        o_error         OUT t_error_out
    ) IS
        l_func_name    VARCHAR2(32) := $$PLSQL_UNIT;
        l_cs_ids       table_number := i_ids_cs;
        l_se_ids       table_number := i_ids_sch_event;
        l_ids_inst     table_number := i_ids_inst MULTISET UNION DISTINCT table_number(0);
        i              PLS_INTEGER;
        l_all_cs_trans alert_core_tech.t_tab_translation := alert_core_tech.t_tab_translation();
        l_event_trans  alert_core_tech.t_rec_translation;
        l_codes        table_varchar := table_varchar();
        l_prefix       VARCHAR2(50) := 'APPOINTMENT.CODE_APPOINTMENT.APP.';
        l_full_prefix  VARCHAR2(50) := 'APPOINTMENT.CODE_APPOINTMENT.APP.';
    BEGIN
        -- fetch event ids if none passed
        IF nvl(cardinality(l_se_ids), 0) = 0
        THEN
            g_error := l_func_name || ' - GET EVENT IDS SINCE NONE WAS SUPPLIED';
            SELECT DISTINCT se.id_sch_event
              BULK COLLECT
              INTO l_se_ids
              FROM sch_event se
              JOIN sch_event_inst_soft seis
                ON se.id_sch_event = seis.id_sch_event
             WHERE se.flg_available = pk_alert_constant.g_yes
               AND seis.flg_available = pk_alert_constant.g_yes
               AND seis.id_institution IN (SELECT column_value
                                             FROM TABLE(l_ids_inst));
        END IF;
    
        -- fetch clinical service ids if none passed
        IF nvl(cardinality(l_cs_ids), 0) = 0
        THEN
            g_error := l_func_name || ' - GET ALL CLINICAL_SERVICE IDS SINCE NONE WAS SUPPLIED';
            SELECT a.id_clinical_service
              BULK COLLECT
              INTO l_cs_ids
              FROM appointment a
              JOIN clinical_service cs
                ON a.id_clinical_service = cs.id_clinical_service
             WHERE a.id_sch_event IN (SELECT column_value
                                        FROM TABLE(l_se_ids));
            -- decidi nao excluir appointments nem clinical services inactivos porque se passarem a activos ficam com traducoes desatualizadas
            --          AND cs.flg_available = pk_alert_constant.g_yes
            --          AND a.flg_available = pk_alert_constant.g_yes;
        END IF;
    
        -- loop through supplied events. Each is going to be crossed with the CS list
        i := l_se_ids.first;
        WHILE i IS NOT NULL
        LOOP
            -- Redo translation
            g_error := l_func_name || ' - CALL generate_app_translation with i_id_sch_event=' || l_se_ids(i);
            generate_app_translation(i_id_sch_event => l_se_ids(i), i_cs_ids => l_cs_ids, i_upd_lb_transl => FALSE); -- will be done later to optimize
        
            -- build code to be later used when calling the lb_translation generator
            l_codes.extend;
            l_codes(l_codes.last) := l_prefix || to_char(l_se_ids(i));
        
            -- virou
            i := l_se_ids.next(i);
        END LOOP;
    
        -- disable all appointments whose id_clinical_service turned unavailable
        g_error := l_func_name || ' - DISABLE APPOINTMENT WHICH HAVE THEIR CLINICAL_SERVICE DISABLED';
        UPDATE (SELECT a.flg_available AS OLD, cs.flg_available AS NEW
                  FROM appointment a
                 INNER JOIN clinical_service cs
                    ON a.id_clinical_service = cs.id_clinical_service
                 WHERE cs.flg_available = pk_alert_constant.g_no
                   AND a.flg_available = pk_alert_constant.g_yes) t
           SET t.old = t.new;
        dbms_output.put_line('disabled ' || SQL%ROWCOUNT ||
                             ' appointments due to clinical_services having turned unavailable');
    
        -- traducoes na lb_translation
        -- so' actualiza se recebeu ordem para isso. E so' actualiza as existentes, nao insere porque isso e' tarefa exclusiva do backoffice 
        IF nvl(i_upd_lb_transl, TRUE)
        THEN
            g_error := l_func_name || ' - GENERATE_LB_TRANSLATIONS';
            generate_lb_translations(1, l_codes);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => 1,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
    END regen_app_translations;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_tools;
/
