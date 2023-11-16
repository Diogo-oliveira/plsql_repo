/*-- Last Change Revision: $Rev: 2047876 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-10-20 11:37:52 +0100 (qui, 20 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_schedule IS
    -- This package provides the core logic for ALERT Scheduler.
    -- @author Nuno Guerreiro
    -- @version alpha 

    ------------------------------ PRIVATE FUNCTIONS --------------------------

    /**
    * This procedure performs error handling and is used internally by other functions in this package,
    * especially by those that are used inside SELECT statements.
    * Private procedure.
    *
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    PROCEDURE error_handling
    (
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_error(text        => i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror,
                              object_name => g_package_name,
                              owner       => g_package_owner);
    END error_handling;

    /*
    * Checks if a number exists inside a table_number.
    * NULL is assumed to be contained inside every table_number.
    * Private function.
    *
    * @param i_number    number
    * @param i_table     table_number
    *
    * @return True if it exists, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/05
    */
    FUNCTION exists_inside_table_number
    (
        i_number NUMBER,
        i_table  table_number
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN := FALSE;
    BEGIN
        g_error := 'EXISTS_INSIDE_TABLE_NUMBER';
        IF (i_number IS NOT NULL AND i_table IS NOT NULL)
        THEN
            -- Check if the element exists inside the collection.
            FOR i IN i_table.first .. i_table.last
            LOOP
                EXIT WHEN l_ret;
                IF i_table(i) = i_number
                THEN
                    l_ret := TRUE;
                END IF;
            END LOOP;
        ELSE
            l_ret := TRUE;
        END IF;
    
        RETURN l_ret;
    END exists_inside_table_number;

    /**
    * This function takes a string with a comma-separated list of values.
    * Each value is replaced by its quoted value (e.g. 1 -> '1'). The quoted string
    * can then be used in an IN clause, for instance.
    * Private function.
    * Note: This function is to be used inside a SELECT and, as such, it does not
    * return a BOOLEAN.
    *
    * @param i_string String with parameters to quote.
    *
    * @return   Quoted parameters string.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/24
    */
    FUNCTION quote(i_string IN VARCHAR2) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'QUOTE';
    BEGIN
        g_error := 'REPLACE i_string WITH regexp';
        -- Replace all items of the list with their quote values.
        RETURN regexp_replace(i_string, '([^,]+){1}', '''\1''');
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN '';
    END;

    /**
    * This function is used to get the clinical service's translated description.
    * Private function.
    *
    * @param   i_lang            Language identifier.
    * @param   i_id_clin_serv    Clinical service identifier
    * @param   o_string          Translated description.
    * @param   o_error           Error message (if an error occurred).
    *
    * @return  True if successful executed, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_clin_serv
    (
        i_lang         IN language.id_language%TYPE,
        i_id_clin_serv IN clinical_service.id_clinical_service%TYPE,
        o_string       OUT pk_translation.t_desc_translation,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'STRING_CLIN_SERV';
    BEGIN
        g_error := 'START';
        IF i_id_clin_serv IS NULL
        THEN
            o_string := NULL;
            RETURN TRUE;
        ELSE
            g_error := 'SELECT';
            BEGIN
                SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                  INTO o_string
                  FROM clinical_service cs
                 WHERE cs.id_clinical_service = i_id_clin_serv
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    o_string := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_CLINICAL_SERVICE = ' ||
                                                        i_id_clin_serv,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            o_string := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
    END string_clin_serv;

    /**
    * Gets the department (based on a dep_clin_serv) description.
    * Private function.
    *
    * @param   i_lang                     Language identifier.
    * @param   i_id_dep_clin_serv         Department-Clinical Service identifier
    * @param   o_string                   Translated description.
    * @param   o_error                    Error message (if an error occurred).
    *
    * @return  True if successful executed, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_department_by_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN clinical_service.id_clinical_service%TYPE,
        o_string           OUT pk_translation.t_desc_translation,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'STRING_DEPARTMENT_BY_DCS';
    BEGIN
        IF i_id_dep_clin_serv IS NULL
        THEN
            o_string := '';
            RETURN TRUE;
        ELSE
            BEGIN
                SELECT pk_translation.get_translation(i_lang, d.code_department)
                  INTO o_string
                  FROM dep_clin_serv dcs, department d
                 WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND dcs.id_department = d.id_department
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    o_string := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_DEP_CLIN_SERV = ' ||
                                                        i_id_dep_clin_serv,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            o_string := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
    END string_department_by_dcs;

    /**
    * Gets the service description based on the dcs
    * INLINE FUNCTION
    *
    * @param   i_lang                     Language identifier.
    * @param   i_id_dep_clin_serv         Department-Clinical Service identifier
    * @param   o_string                   Translated description.
    * @param   o_error                    Error message (if an error occurred).
    *
    * @return  True if successful executed, false otherwise.
    * @author  Telmo
    * @version 2.5.0.5
    * @since   30-07-2009
    */
    FUNCTION string_service
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN clinical_service.id_clinical_service%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'STRING_SERVICE';
        l_res       VARCHAR2(2000);
    BEGIN
        IF i_id_dep_clin_serv IS NULL
        THEN
            RETURN '';
        ELSE
            BEGIN
                SELECT pk_translation.get_translation(i_lang, d.code_department)
                  INTO l_res
                  FROM dep_clin_serv dcs, department d
                 WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND dcs.id_department = d.id_department
                   AND rownum = 1;
            
                RETURN l_res;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_DEP_CLIN_SERV = ' ||
                                                        i_id_dep_clin_serv,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
                    RETURN '';
            END;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN '';
    END string_service;

    /**
    * Returns the department identifier.
    * Private function.
    *
    * @param   i_id_dcs         dep_clin_serv identifier
    *
    * @return  Returns associated clinical service identifier
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/24
    */
    FUNCTION get_id_dep(i_id_dcs IN dep_clin_serv.id_dep_clin_serv%TYPE) RETURN department.id_department%TYPE IS
        l_id_department department.id_department%TYPE;
    BEGIN
        SELECT dcs.id_department
          INTO l_id_department
          FROM dep_clin_serv dcs
         WHERE dcs.id_dep_clin_serv = i_id_dcs;
    
        RETURN l_id_department;
    EXCEPTION
        WHEN OTHERS THEN
            -- Let the caller handle the error.
            RAISE;
    END get_id_dep;

    /**
    * Returns a dep_clin_serv identifier.
    * Private function.
    *
    * @param   i_id_inst         insitution identifier
    * @param   i_id_dep       department identifier
    * @param   i_id_clin_serv    clinical service identifier
    *
    * @return  Returns associated dep_clin_serv identifier
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/24
    */
    FUNCTION get_id_dep_clin_serv
    (
        i_id_dep       IN department.id_department%TYPE DEFAULT NULL,
        i_id_clin_serv IN clinical_service.id_clinical_service%TYPE DEFAULT NULL
    ) RETURN dep_clin_serv.id_dep_clin_serv%TYPE IS
        l_dcs dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL;
    BEGIN
        SELECT id_dep_clin_serv
          INTO l_dcs
          FROM dep_clin_serv dcs, department d
         WHERE d.id_department = i_id_dep
           AND dcs.id_department = d.id_department
           AND dcs.id_clinical_service = i_id_clin_serv;
    
        RETURN l_dcs;
    EXCEPTION
        WHEN OTHERS THEN
            -- Let the caller handle the error.
            RAISE;
    END get_id_dep_clin_serv;

    /**
    * Returns the patient's health plan number for the given health plan type.
    * Private function.
    *
    * @param   i_id_patient     patient identifier
    * @param   i_id_inst        institution identifier
    *
    * @return  returns the patient's health plan number
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/30
    */
    FUNCTION get_health_plan_num
    (
        i_id_patient IN patient.id_patient%TYPE,
        i_id_inst    IN institution.id_institution%TYPE,
        i_flg_type   IN health_plan.id_health_plan%TYPE
    ) RETURN pat_health_plan.num_health_plan%TYPE IS
        l_num_health_plan pat_health_plan.num_health_plan%TYPE;
    BEGIN
        SELECT php.num_health_plan
          INTO l_num_health_plan
          FROM pat_health_plan php, health_plan hp
         WHERE php.id_patient = i_id_patient
           AND php.id_institution = i_id_inst
           AND hp.id_health_plan = php.id_health_plan
           AND hp.flg_type = i_flg_type;
        RETURN l_num_health_plan;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN '';
        WHEN too_many_rows THEN
            RETURN '-';
    END get_health_plan_num;

    /**
    * Returns the patient SNS number if patient has an
    * health plan flaged as (S)ns. It may not be the default health plan.
    * Private function.
    *
    * @param   i_id_patient     patient identifier
    * @param   i_id_inst        institution identifier
    *
    * @return  returns the patient SNS number
    * @author  Ricardo Pinho
    * @version alpha
    * @since   2006/04/24
    */
    FUNCTION get_num_sns
    (
        i_id_patient IN patient.id_patient%TYPE,
        i_id_inst    IN institution.id_institution%TYPE
    ) RETURN pat_health_plan.num_health_plan%TYPE IS
    BEGIN
        RETURN get_health_plan_num(i_id_patient => i_id_patient,
                                   i_id_inst    => i_id_inst,
                                   i_flg_type   => g_health_plan_type_sns);
    END get_num_sns;

    /**
    * Returns the number of the patient default health plan.
    * Private function.
    *
    * @param   i_lang         Language.
    * @param   i_id_patient   Patient identifier.
    * @param   i_id_inst      Institution.
    *
    * @return  returns the patient's number of the default health plan
    * @author  Ricardo Pinho
    * @version alpha
    * @since   2006/04/24
    */
    FUNCTION get_default_health_plan_num
    (
        i_lang       NUMBER,
        i_id_patient patient.id_patient%TYPE,
        i_id_inst    institution.id_institution%TYPE
    ) RETURN pat_health_plan.num_health_plan%TYPE IS
        l_num_health_plan pat_health_plan.num_health_plan%TYPE;
    BEGIN
        SELECT php.num_health_plan
          INTO l_num_health_plan
          FROM pat_health_plan php
         WHERE php.id_patient = i_id_patient
           AND php.flg_default = g_yes
           AND php.id_institution = i_id_inst;
    
        RETURN l_num_health_plan;
    EXCEPTION
        WHEN too_many_rows THEN
            RETURN get_message(i_lang, g_more_than_one_card);
        WHEN no_data_found THEN
            RETURN '';
        WHEN OTHERS THEN
            RETURN '-----';
    END get_default_health_plan_num;

    /*
    * Gets the type of search and identifier for searching for patients.
    * Private function.
    *
    * @param i_lang           Language.
    * @param i_prof           Professional.
    * @param o_type           Type (Document or plan)
    * @param o_identifier     Document or plan identifier
    * @param o_error          Error message (if an error occurred).
    *
    * @return  True if successful executed, false otherwise.
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    */
    FUNCTION get_search_patient_by
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_type       OUT VARCHAR2,
        o_identifier OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_config                sys_config.id_sys_config%TYPE := g_search_pat_by_parameter;
        l_sch_search_patient_by sys_config.value%TYPE;
        l_func_name             VARCHAR2(32);
        l_index                 NUMBER;
        l_sep                   VARCHAR2(1) := '|';
    BEGIN
    
        l_func_name := 'GET_SEARCH_PATIENT_BY';
        g_error     := 'GET ' || l_config || ' FROM SYS_CONFIG';
        IF NOT (pk_sysconfig.get_config(l_config, i_prof, l_sch_search_patient_by))
           OR l_sch_search_patient_by IS NULL
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => g_missing_config || ' ' || l_config || ' (Institution: ' ||
                                                            i_prof.institution || ')',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        ELSE
            -- Get type and identifier
            g_error      := 'GET TYPE';
            l_index      := instr(l_sch_search_patient_by, l_sep);
            o_type       := substr(l_sch_search_patient_by, 1, l_index - 1);
            g_error      := 'GET IDENTIFIER';
            o_identifier := substr(l_sch_search_patient_by, l_index + 1, length(l_sch_search_patient_by));
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_search_patient_by;

    /**
    * Retrieves the patient document or health plan depending on the sys_config parameter.
    *
    * @param      i_lang             Language.
    * @param      i_prof             Professional object which refers the identity of the function caller
    * @param      o_doc_value        Document value or Health Plan Number
    * @param      o_error            Error message (if an error occurred).
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Tiago Ferreira)
    * @version    alpha
    * @since      2006/05/02
    *
    */
    FUNCTION get_patient_doc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient_id IN patient.id_patient%TYPE,
        o_doc_value  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_search_id   sys_config.value%TYPE;
        l_search_type sys_config.value%TYPE;
        l_func_name   VARCHAR2(32);
    BEGIN
        l_func_name := 'GET_PATIENT_DOC';
        g_error     := 'CALL GET_SEARCH_PATIENT_BY';
        -- Retrieving the value and type for the patient search
        IF NOT (get_search_patient_by(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      o_identifier => l_search_id,
                                      o_type       => l_search_type,
                                      o_error      => o_error))
        THEN
            RETURN FALSE;
        ELSE
            -- Searching if it is a document or an health plan
            IF l_search_type = g_search_pat_by_document
            THEN
                SELECT VALUE
                  INTO o_doc_value
                  FROM pat_doc
                 WHERE id_patient = i_patient_id
                   AND id_institution = i_prof.institution
                   AND id_doc_type = l_search_id;
            ELSIF l_search_type = g_search_pat_by_plan
            THEN
                SELECT num_health_plan
                  INTO o_doc_value
                  FROM pat_health_plan
                 WHERE id_patient = i_patient_id
                   AND id_institution = i_prof.institution
                   AND id_health_plan = l_search_id;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            -- No document found
            o_doc_value := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_patient_doc;

    /**
    * Generates random schedules based on the vacancy table. For each used vacant
    * it randoms a patient and schedules it on top of it.
    *
    * @param   i_lang          Language
    * @param   i_initial_date  Start date
    * @param   i_end_date      End date
    * @param   i_id_inst       institution
    * @param   i_id_software   Software
    * @param   o_error         Error message if an error occurred
    *
    * @see     pk_schedule.reset reset
    * @return  boolean type   , "False" on error or "True" if success
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version 0.1
    * @since   2007/07/04
    *
    * UPDATED
    * passa a obter o departamento id a partir do dep_clin_serv e nao da sys_config
    * @author  Telmo Castro
    * @version 0.2
    * @date    15-02-2008
    *
    * UPDATED
    * update na invocacao da funcao pk_schedule_exam.create_schedule_exam. Ver comentarios mais abaixo
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    05-06-2008
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.3.x
    *
    * UPDATED alert-8202. sch_consult_vac_exam demise
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    20-10-2009
    */
    FUNCTION reset_random_schedules
    (
        i_lang           IN language.id_language%TYPE := 1,
        i_initial_date   IN sch_consult_vacancy.dt_begin_tstz%TYPE,
        i_end_date       IN sch_consult_vacancy.dt_end_tstz%TYPE,
        i_id_institution IN sch_consult_vacancy.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'RESET_RANDOM_SCHEDULES';
        l_func_exception EXCEPTION;
    
        l_create_exam     BOOLEAN := TRUE;
        l_create_analysis BOOLEAN := TRUE;
    
        l_admin professional.id_professional%TYPE;
    
        l_id_schedule schedule.id_schedule%TYPE;
        l_occupied    sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
    
        l_id_patient patient.id_patient%TYPE;
    
        l_counter          NUMBER DEFAULT 0;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    
        l_flg_vacancy schedule.flg_vacancy%TYPE;
        l_translator  NUMBER(24) := NULL;
    
        l_trunc_ts TIMESTAMP WITH TIME ZONE;
    
        -- [Telmo Castro] este associative array vai servir para optimizar a obtencao dos id_department a partir dos id_dep_clin_serv
        TYPE l_aa_n_n IS TABLE OF NUMBER INDEX BY VARCHAR2(200);
        l_ids_deps l_aa_n_n;
    
        -- Default vacancies
        CURSOR c_default_vacancies(i_trunc_ts TIMESTAMP WITH TIME ZONE) IS
            SELECT se.flg_schedule_outp_type flg_type,
                   s.id_prof,
                   dt_begin_tstz,
                   nvl(s.used_vacancies, 0) used_vacancies,
                   id_institution,
                   s.max_vacancies,
                   s.id_dep_clin_serv,
                   s.id_sch_event,
                   se.intern_name,
                   se.flg_target_professional,
                   se.flg_target_dep_clin_serv,
                   se.dep_type
              FROM sch_consult_vacancy s, sch_event se, dep_clin_serv dcs, clinical_service cs
             WHERE dt_begin_tstz >= i_initial_date
               AND dt_begin_tstz < i_end_date
               AND used_vacancies > 0
               AND (dt_begin_tstz >= pk_date_utils.add_days_to_tstz(i_trunc_ts, 1) OR dt_begin_tstz < i_trunc_ts)
               AND id_institution = i_id_institution
               AND se.id_sch_event = s.id_sch_event
               AND s.id_sch_consult_vacancy NOT IN (2000, 2001, 2002, 2003)
               AND dcs.id_dep_clin_serv = s.id_dep_clin_serv
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND dcs.flg_available = 'Y'
               AND cs.flg_available = 'Y'
               AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, i_id_institution, i_id_software) =
                   pk_alert_constant.g_yes
             ORDER BY dt_begin_tstz, flg_type;
    
        -- Returns a random administrative
        FUNCTION inner_get_rand_administrative(i_id_department department.id_department%TYPE) RETURN NUMBER IS
            l_ret_prof professional.id_professional%TYPE;
        BEGIN
            g_error := 'INNER_GET_RAND_ADMINISTRATIVE';
            -- Get a random administrative
            SELECT id_professional
              INTO l_ret_prof
              FROM (SELECT a.id_professional
                      FROM prof_dep_clin_serv a, dep_clin_serv b, prof_cat c, category d
                     WHERE b.id_dep_clin_serv = a.id_dep_clin_serv
                       AND a.flg_status = g_selected
                       AND b.id_department = i_id_department
                       AND c.id_professional = a.id_professional
                       AND d.id_category = c.id_category
                       AND d.flg_type = g_administrative_cat
                     ORDER BY dbms_random.value)
             WHERE rownum = 1;
        
            RETURN l_ret_prof;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
            WHEN OTHERS THEN
                -- Handle the exception on the main function
                RAISE;
        END inner_get_rand_administrative;
    
        -- Returns a random patient's identifier
        FUNCTION inner_get_rand_patient RETURN patient.id_patient%TYPE IS
            l_ret_patient patient.id_patient%TYPE;
        BEGIN
            g_error := 'INNER_GET_RAND_PATIENT';
            SELECT id_patient
              INTO l_ret_patient
              FROM (SELECT id_patient
                      FROM patient
                     WHERE flg_status = g_status_active
                       AND dt_deceased IS NULL
                          -- Demo patients
                       AND id_patient NOT IN (82, 83, 84, 85, 86, 87, 88, 89, 111, 99999)
                          -- Usable patients
                       AND id_patient IN (45, 22, 21, 1007, 24, 25, 46, 27, 82, 84, 85, 87, 23, 83, 86, 89, 88, 16)
                     ORDER BY dbms_random.value)
             WHERE rownum = 1;
        
            RETURN l_ret_patient;
        EXCEPTION
            WHEN OTHERS THEN
                -- Handle the exception on the main function
                RAISE;
        END inner_get_rand_patient;
    
        -- Returns a random translator language
        FUNCTION inner_get_rand_translator RETURN language.id_language%TYPE IS
            l_ret_lang language.id_language%TYPE;
        BEGIN
            g_error := 'INNER_GET_RAND_TRANSLATOR';
            -- Get a translator
            BEGIN
                SELECT id_language
                  INTO l_ret_lang
                  FROM (SELECT l.id_language
                          FROM LANGUAGE l
                         WHERE l.flg_available = g_yes
                         ORDER BY dbms_random.value)
                 WHERE rownum = round(dbms_random.value(0, 1));
            EXCEPTION
                WHEN no_data_found THEN
                    l_ret_lang := NULL;
            END;
        
            RETURN l_ret_lang;
        EXCEPTION
            WHEN OTHERS THEN
                -- Handle the exception on the main function
                RAISE;
        END inner_get_rand_translator;
    
        -- [Telmo Castro] returns id_department for this id_dep_clin_serv
        FUNCTION inner_get_department(i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE)
            RETURN dep_clin_serv.id_dep_clin_serv%TYPE IS
            l_ret_id_dep dep_clin_serv.id_dep_clin_serv%TYPE;
        BEGIN
            g_error := 'INNER_GET_DEPARTMENT';
            BEGIN
                l_ret_id_dep := l_ids_deps(i_id_dep_clin_serv);
            
            EXCEPTION
                WHEN no_data_found THEN
                    -- nao encontrou no aa, vai procurar na tabela e inserir no aa
                    SELECT d.id_department
                      INTO l_ret_id_dep
                      FROM dep_clin_serv dcs
                     INNER JOIN department d
                        ON dcs.id_department = d.id_department
                     WHERE id_dep_clin_serv = i_id_dep_clin_serv
                       AND dcs.flg_available = g_yes;
                
                    l_ids_deps(i_id_dep_clin_serv) := l_ret_id_dep;
            END;
        
            RETURN l_ret_id_dep;
        EXCEPTION
            WHEN OTHERS THEN
                -- Handle the exception on the main function
                RAISE;
        END inner_get_department;
    
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL TRUNC_INSTTIMEZONE FOR l_trunc_ts';
        -- Truncate current_timestamp
        IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => profissional(NULL, i_id_institution, i_id_software),
                                                i_timestamp => current_timestamp,
                                                o_timestamp => l_trunc_ts,
                                                o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        g_error := 'ITERATE THROUGH VACANCIES';
        -- Iterate through vacancies, creating the necessary appointments
        FOR c_sch_consult_vacancy IN c_default_vacancies(l_trunc_ts)
        LOOP
            IF (c_sch_consult_vacancy.dep_type IN
               (pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                 pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                 pk_schedule_common.g_sch_dept_flg_dep_type_nut,
                 pk_schedule_common.g_sch_dept_flg_dep_type_as) OR
               (c_sch_consult_vacancy.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_exam AND l_create_exam))
            THEN
                -- Choose the right administrative
                l_admin := inner_get_rand_administrative(inner_get_department(c_sch_consult_vacancy.id_dep_clin_serv));
            
                g_error := 'ITERATE USED VACANCIES';
                -- Create the necessary appointments
                FOR i IN 1 .. c_sch_consult_vacancy.used_vacancies
                LOOP
                    g_error := 'GET RANDOM PATIENT';
                    -- Get a random patient to associate with the appointment
                    l_id_patient := inner_get_rand_patient();
                
                    IF (l_counter > c_sch_consult_vacancy.max_vacancies)
                    THEN
                        -- Unplanned schedule
                        l_flg_vacancy := pk_schedule_common.g_sched_vacancy_unplanned;
                    ELSE
                        -- Routine schedule
                        l_flg_vacancy := pk_schedule_common.g_sched_vacancy_routine;
                    END IF;
                
                    g_error := 'GET TRANSLATOR';
                    -- Get a random translator
                    l_translator := inner_get_rand_translator();
                
                    g_error := 'CREATE SCHEDULE';
                    -- Create main appointment
                    IF NOT pk_schedule_common.create_schedule(i_lang               => i_lang,
                                                              i_id_prof_schedules  => l_admin,
                                                              i_id_institution     => i_id_institution,
                                                              i_id_software        => i_id_software,
                                                              i_id_patient         => table_number(l_id_patient),
                                                              i_id_dep_clin_serv   => c_sch_consult_vacancy.id_dep_clin_serv,
                                                              i_id_sch_event       => c_sch_consult_vacancy.id_sch_event,
                                                              i_id_prof            => c_sch_consult_vacancy.id_prof,
                                                              i_dt_begin           => c_sch_consult_vacancy.dt_begin_tstz,
                                                              i_dt_end             => NULL,
                                                              i_flg_vacancy        => l_flg_vacancy,
                                                              i_flg_status         => g_sched_status_scheduled,
                                                              i_id_lang_translator => l_translator,
                                                              i_id_lang_preferred  => l_translator,
                                                              i_flg_sch_type       => c_sch_consult_vacancy.dep_type,
                                                              i_ignore_vacancies   => TRUE,
                                                              i_id_consult_vac     => NULL,
                                                              o_id_schedule        => l_id_schedule,
                                                              o_occupied           => l_occupied,
                                                              o_error              => o_error)
                    THEN
                        RAISE l_func_exception;
                    END IF;
                
                    IF c_sch_consult_vacancy.dep_type IN
                       (pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                        pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                        pk_schedule_common.g_sch_dept_flg_dep_type_nut,
                        pk_schedule_common.g_sch_dept_flg_dep_type_as)
                    THEN
                        g_error := 'CREATE OUTPATIENT SCHEDULE';
                        -- Create outpatient appointment
                        IF NOT pk_schedule_common.create_schedule_outp(i_lang              => i_lang,
                                                                       i_id_prof_schedules => l_admin,
                                                                       i_id_institution    => i_id_institution,
                                                                       i_id_software       => i_id_software,
                                                                       i_id_schedule       => l_id_schedule,
                                                                       i_id_patient        => l_id_patient,
                                                                       i_id_dep_clin_serv  => l_id_dep_clin_serv,
                                                                       i_id_sch_event      => c_sch_consult_vacancy.id_sch_event,
                                                                       i_id_prof           => c_sch_consult_vacancy.id_prof,
                                                                       i_dt_begin          => c_sch_consult_vacancy.dt_begin_tstz,
                                                                       o_error             => o_error)
                        THEN
                            RAISE l_func_exception;
                        END IF;
                    
                    ELSIF c_sch_consult_vacancy.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_exam
                    THEN
                        g_error := 'CREATE EXAM SCHEDULE';
                        -- Create exam appointment
                    
                    END IF;
                
                    l_counter := l_counter + 1;
                END LOOP;
                l_counter := 0;
            END IF;
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END reset_random_schedules;

    /**
    * Calculates the month availability data.
    * Private function.
    *
    * @param  i_lang                    Language identifier.
    * @param  i_prof                    Professional.
    * @param  i_list_schedules          List of appointments to consider.
    * @param  i_list_dates              List of dates to consider.
    * @param  i_list_dates_str          List of dates to consider (strings).
    * @param  o_days_status             Resulting list of status, for each day.
    * @param  o_days_date               Resulting list of dates.
    * @param  o_days_free               Resulting list of free vacancies, for each day.
    * @param  o_days_sched              Resulting list of appointments, for each day.
    * @param  o_days_conflicts          Resulting list
    * @param  o_error                   Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/09/28
    *
    * UPDATED
    * ALERT-31987 - output da get_vacancies passa a ser a GTT sch_tmptab_vacs em vez do table_number
    * @author  Telmo
    * @date    12-06-2009
    * @version 2.5.0.4
    */
    FUNCTION calculate_month_availability
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_mult           IN BOOLEAN,
        i_list_schedules IN table_number,
        i_list_dates     IN table_timestamp_tz,
        i_list_dates_str IN table_varchar,
        i_events         IN VARCHAR2 DEFAULT NULL,
        o_days_status    OUT table_varchar,
        o_days_date      OUT table_varchar,
        o_days_free      OUT table_number,
        o_days_sched     OUT table_number,
        o_days_conflicts OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'CALCULATE_MONTH_AVAILABILITY';
    
        CURSOR c_vacancies IS
            SELECT stv.dt_begin_trunc tstz,
                   --ALERT-52762
                   nvl(SUM(CASE
                                WHEN stv.max_vacancies > 0 THEN
                                 1
                                ELSE
                                 0
                            END),
                        0) vacancies,
                   nvl(SUM(CASE
                                WHEN stv.used_vacancies > 0 THEN
                                 1
                                ELSE
                                 0
                            END),
                        0) used
            -- end ALERT-52762
              FROM sch_tmptab_vacs stv
             GROUP BY stv.dt_begin_trunc;
    
        CURSOR c_unavailable_vacancies IS
            SELECT stv.dt_begin_trunc tstz, nvl(SUM(scv.max_vacancies - scv.used_vacancies), 0) unavailable
              FROM sch_consult_vacancy scv
              JOIN sch_tmptab_vacs stv
                ON scv.id_sch_consult_vacancy = stv.id_sch_consult_vacancy
             WHERE scv.id_institution = i_prof.institution
               AND scv.id_prof IS NOT NULL
               AND scv.flg_status = pk_schedule_bo.g_status_blocked
             GROUP BY stv.dt_begin_trunc;
    
        CURSOR c_schedules(i_list_schedules table_number) IS
            SELECT /*+ index(s schd_pk) */
             pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz) tstz, COUNT(1) num
              FROM schedule s
             WHERE s.id_schedule IN (SELECT *
                                       FROM TABLE(c_schedules.i_list_schedules))
             GROUP BY pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz);
    
        TYPE t_date_status IS RECORD(
            num         NUMBER(24),
            vacancies   NUMBER(24),
            used        NUMBER(24),
            unavailable NUMBER(24),
            conflicts   NUMBER(24));
    
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
        l_list_event      table_number := pk_schedule.get_list_number_csv(i_events);
    BEGIN
        g_error          := 'INITIALIZE RESULTS';
        o_days_status    := table_varchar();
        o_days_date      := table_varchar();
        o_days_free      := table_number();
        o_days_sched     := table_number();
        o_days_conflicts := table_number();
    
        g_error := 'INITIALIZE STATUS';
        -- Initialize status, using string-represented dates as keys
        FOR idx IN i_list_dates_str.first .. i_list_dates_str.last
        LOOP
            l_ts_string := i_list_dates_str(idx);
            l_status(l_ts_string).num := 0;
            l_status(l_ts_string).vacancies := 0;
            l_status(l_ts_string).used := 0;
            l_status(l_ts_string).unavailable := 0;
            l_status(l_ts_string).conflicts := 0;
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
        -- Get free and used vacancies
        IF l_vacancies.count > 0
        THEN
            FOR vac_idx IN l_vacancies.first .. l_vacancies.last
            LOOP
                l_ts_string := pk_date_utils.date_send_tsz(i_lang, l_vacancies(vac_idx).tstz, i_prof);
                l_status(l_ts_string).used := l_vacancies(vac_idx).used;
                l_status(l_ts_string).vacancies := l_vacancies(vac_idx).vacancies;
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
            -- Get free and used vacancies
            IF l_unav_vacancies.count > 0
            THEN
                FOR vac_idx IN l_unav_vacancies.first .. l_unav_vacancies.last
                LOOP
                    l_ts_string := pk_date_utils.date_send_tsz(i_lang, l_unav_vacancies(vac_idx).tstz, i_prof);
                    l_status(l_ts_string).unavailable := l_unav_vacancies(vac_idx).unavailable;
                END LOOP;
            END IF;
        END IF;
        -- Get appointments
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
                l_status(l_ts_string).num := l_schedules(sch_idx).num;
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
                    l_status(l_ts_string).conflicts := l_schedules(sch_idx).num;
                END LOOP;
            END IF;
        END IF;
        g_error := 'PREPARE RESULTS';
        -- Prepare results
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
        
            o_days_date(l_idx) := l_v_idx;
            IF NOT i_mult
            THEN
                o_days_conflicts.extend;
                o_days_conflicts(l_idx) := l_status_elem.conflicts;
                o_days_free(l_idx) := l_status_elem.vacancies - l_status_elem.used - l_status_elem.unavailable;
            ELSE
                o_days_free(l_idx) := l_status_elem.vacancies - l_status_elem.used;
            END IF;
        
            --l_list_event
            IF (l_list_event.count != 1)
            THEN
                o_days_sched(l_idx) := l_status_elem.num;
            ELSE
                IF (l_list_event(1) = pk_schedule.g_event_group)
                THEN
                    o_days_sched(l_idx) := l_status_elem.used;
                ELSE
                
                    o_days_sched(l_idx) := l_status_elem.num;
                END IF;
            END IF;
        
            --o_days_sched(l_idx) := l_status_elem.num; --l_status_elem.used; 
            CASE
                WHEN l_status_elem.vacancies = 0
                     AND l_status_elem.num = 0 THEN
                    o_days_status(l_idx) := g_day_status_void;
                WHEN l_status_elem.vacancies = l_status_elem.unavailable
                     AND l_status_elem.vacancies > 0 THEN
                    o_days_status(l_idx) := g_day_status_unavailable;
                WHEN (l_status_elem.vacancies = 0 AND l_status_elem.num > 0)
                     OR (l_status_elem.num >= l_status_elem.vacancies AND
                     l_status_elem.used = l_status_elem.vacancies - l_status_elem.unavailable)
                     OR (l_status_elem.used = l_status_elem.vacancies - l_status_elem.unavailable AND
                     l_status_elem.used > 0) THEN
                    o_days_status(l_idx) := g_day_status_full;
                WHEN (l_status_elem.vacancies > 0 AND l_status_elem.used = 0)
                     OR (l_status_elem.vacancies > l_status_elem.used AND l_status_elem.num = 0) THEN
                    o_days_status(l_idx) := g_day_status_empty;
                WHEN l_status_elem.num > 0
                     AND l_status_elem.vacancies > l_status_elem.used THEN
                    o_days_status(l_idx) := g_day_status_half;
                ELSE
                    o_days_status(l_idx) := g_day_status_void;
            END CASE;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END calculate_month_availability;

    /**
    * Returns the list of available vacancies, from a given list of vacancies.
    * Private function
    *
    * @param   i_lang         Language identifier
    * @param   i_prof         Professional
    * @param   i_vacancies    List of vacancies to test
    * @param   i_fulltable    Y = lookup in sch_tmptab_full_vacs  N = lookup in sch_tmptab_vacs
    * @param   o_error        Error message, if an error occurred.
    *
    * @return  True if successful, false otherwise.
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/09/20
    *
    * UPDATED
    * ALERT-31987 - output da get_vacancies passa a ser a GTT sch_tmptab_vacs em vez do table_number
    * @author  Telmo
    * @date    12-06-2009
    * @version 2.5.0.4
    */
    FUNCTION get_available_vacancies
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_vacancies IN table_number,
        i_fulltable IN VARCHAR2 DEFAULT 'N',
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_AVAILABLE_VACANCIES';
        l_unav_vacancies table_number;
    BEGIN
        IF i_fulltable = g_no
        THEN
            g_error := 'GET UNAVAILABLE VACANCIES';
            -- Get vacancies that are unavailable due to professionals' absence periods.
            SELECT scv.id_sch_consult_vacancy
              BULK COLLECT
              INTO l_unav_vacancies
              FROM sch_consult_vacancy scv
              JOIN sch_tmptab_vacs m
                ON scv.id_sch_consult_vacancy = m.id_sch_consult_vacancy
             WHERE scv.id_prof IS NOT NULL
               AND (i_vacancies IS NULL OR
                   (scv.id_sch_consult_vacancy IN (SELECT *
                                                      FROM TABLE(i_vacancies))))
               AND scv.flg_status = pk_schedule_bo.g_status_blocked;
        
            -- substrair a' lista principal de vagas estas que se acabou de determinar. 
            g_error := 'REMOVE UNAVAILABLE VACANCIES';
            DELETE sch_tmptab_vacs mf
             WHERE mf.id_sch_consult_vacancy IN (SELECT *
                                                   FROM TABLE(l_unav_vacancies));
        ELSE
            -- Get vacancies that are unavailable due to professionals' absence periods.
            SELECT scv.id_sch_consult_vacancy
              BULK COLLECT
              INTO l_unav_vacancies
              FROM sch_consult_vacancy scv
              JOIN sch_tmptab_full_vacs m
                ON scv.id_sch_consult_vacancy = m.id_sch_consult_vacancy
             WHERE scv.id_prof IS NOT NULL
               AND (i_vacancies IS NULL OR
                   (scv.id_sch_consult_vacancy IN (SELECT *
                                                      FROM TABLE(i_vacancies))))
               AND scv.flg_status = pk_schedule_bo.g_status_blocked;
        
            -- substrair a' lista principal de vagas estas que se acabou de determinar. 
            g_error := 'REMOVE UNAVAILABLE VACANCIES';
            DELETE sch_tmptab_full_vacs mf
             WHERE mf.id_sch_consult_vacancy IN (SELECT *
                                                   FROM TABLE(l_unav_vacancies));
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_available_vacancies;

    /*
    * Gets the details of the appointments to be put on the clipboard.
    * Private function.
    *
    * @param i_lang
    * @param i_prof
    * @param i_args
    * @param o_schedules
    * @param o_error
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/09/18
    *
    * UPDATED
    * AdiÁ„o de coluna exam_name ao cursor
    * @author   Jose Antunes
    * @version  2.4.3.x
    * @date     20-10-2008
    */
    FUNCTION get_appointments_clip_details
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_list_schedules IN table_number,
        o_schedules      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_APPOINTMENTS_CLIP_DETAILS';
    BEGIN
        g_error := 'OPEN o_schedules FOR';
        -- Open cursor
        OPEN o_schedules FOR
            SELECT /*+ first_rows */
             s.id_schedule,
             pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof) dt_begin,
             pat.name,
             string_clin_serv_by_dcs(i_lang, s.id_dcs_requested) consult_name,
             s.id_sch_event,
             pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) event_name,
             decode(pk_patphoto.check_blob(pat.id_patient), g_no, '', pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
             pk_patient.get_gender(i_lang, pat.gender) AS gender,
             pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) age,
             decode(s.id_sch_event,
                    g_event_exam,
                    pk_schedule_exam.get_exam_desc_by_sch(i_lang, s.id_schedule),
                    g_event_oexam,
                    pk_schedule_exam.get_exam_desc_by_sch(i_lang, s.id_schedule),
                    NULL) exam_name
              FROM schedule s, sch_group sg, sch_event se, patient pat
             WHERE sg.id_schedule(+) = s.id_schedule
               AND pat.id_patient(+) = sg.id_patient
               AND se.id_sch_event = s.id_sch_event
               AND s.id_schedule IN (SELECT *
                                       FROM TABLE(i_list_schedules))
               AND s.flg_status = g_status_scheduled;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_schedules);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_appointments_clip_details;

    /**********************************************************************************************
    * This function returns the first day of the next month
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array   
    * @param i_date                          Input date
    * @param o_date                          Output date    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.4
    * @since                                 2009/06/23
    **********************************************************************************************/
    FUNCTION get_fst_day_next_month
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_date  IN TIMESTAMP,
        o_date  OUT TIMESTAMP,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_date := trunc(i_date, 'MM');
    
        o_date := add_months(o_date, 1);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_FIRST_DAY_OF_MONTH',
                                              o_error    => o_error);
    END get_fst_day_next_month;

    /**********************************************************************************************
    * This function returns the next day of month according to the i_day_of_month and the i_month
    * parameters.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array  
    * @param i_day_of_month                  Day of month
    * @param i_month                         Month nr
    * @param i_date                          Input date
    * @param o_date                          Output date    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.4
    * @since                                 2009/06/23
    **********************************************************************************************/
    FUNCTION get_next_day_month
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_day_of_month IN NUMBER,
        i_month        IN NUMBER,
        i_date         IN TIMESTAMP,
        o_date         OUT TIMESTAMP,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_day       NUMBER;
        l_month     NUMBER;
        l_month_i   NUMBER := i_month;
        l_year      NUMBER;
        l_day_str   VARCHAR2(2);
        l_month_str VARCHAR2(2);
        l_year_str  VARCHAR2(4);
        l_date_str  VARCHAR2(30);
        l_hour_str  VARCHAR2(30);
        l_timezone  VARCHAR2(30);
    BEGIN
        g_error     := 'CALL to_char_insttimezone';
        l_day_str   := to_char(i_date, 'DD');
        l_month_str := to_char(i_date, 'MM');
        l_year_str  := to_char(i_date, 'YYYY');
        l_hour_str  := to_char(i_date, 'HH24MISS');
    
        l_day   := to_number(l_day_str);
        l_month := to_number(l_month_str);
        l_year  := to_number(l_year_str);
    
        IF (l_month_i IS NULL)
        THEN
            l_month_i := l_month;
        END IF;
    
        IF (l_day = i_day_of_month AND l_month = l_month_i)
        THEN
            o_date := i_date;
        ELSE
            IF (l_month > l_month_i)
            THEN
                l_year := l_year + 1;
            END IF;
        
            l_date_str := l_year || CASE
                              WHEN l_month_i < 10 THEN
                               '0' || to_char(l_month_i)
                              ELSE
                               to_char(l_month_i)
                          END || CASE
                              WHEN i_day_of_month < 10 THEN
                               '0' || to_char(i_day_of_month)
                              ELSE
                               to_char(i_day_of_month)
                          END || l_hour_str;
        
            o_date := to_date(l_date_str, 'yyyymmddhh24miss');
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_NEXT_DAY',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_next_day_month;

    /**********************************************************************************************
    * This function returns the next day according to the i_weekday and the i_week
    * parameters.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array  
    * @param i_weekday                       Weekday standard
    * @param i_week                          Week nr
    * @param i_date                          Input date
    * @param o_date                          Output date    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.4
    * @since                                 2009/06/23
    **********************************************************************************************/
    FUNCTION get_next_day
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_weekday IN NUMBER,
        i_week    IN NUMBER,
        i_date    IN TIMESTAMP,
        o_date    OUT TIMESTAMP,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_weekday_std NUMBER;
        l_dt_aux            TIMESTAMP;
        l_week_str          VARCHAR2(30);
        l_week_day_std      NUMBER;
    BEGIN
        l_week_str := to_char(i_date, 'W');
    
        IF (to_number(l_week_str) < i_week)
        THEN
            l_dt_aux := i_date;
        ELSIF (to_number(l_week_str) = i_week)
        THEN
            l_week_day_std := pk_date_utils.week_day_standard(i_date => i_date);
            IF (l_week_day_std < i_weekday)
            THEN
                l_dt_aux := i_date;
            ELSIF (l_week_day_std = i_weekday)
            THEN
                o_date := i_date;
                RETURN TRUE;
            ELSE
                l_dt_aux := i_date; -- + INTERVAL '1' MONTH;
            END IF;
        ELSE
            l_dt_aux := i_date + INTERVAL '1' MONTH;
        END IF;
    
        IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_timestamp => l_dt_aux,
                                                i_format    => 'MM',
                                                o_timestamp => l_dt_aux,
                                                o_error     => o_error)
        THEN
        
            RETURN FALSE;
        END IF;
        -- go to the beggining of the week
        IF (i_week > 1)
        THEN
            l_dt_aux := pk_date_utils.add_days_to_tstz(i_timestamp => l_dt_aux, i_days => g_weekdays * (i_week - 1));
        
            l_dt_aux := trunc(l_dt_aux, 'WW');
        
        END IF;
    
        l_start_weekday_std := pk_date_utils.week_day_standard(l_dt_aux);
        IF (l_start_weekday_std != i_weekday)
        THEN
            g_error := 'CALL next_day_standard';
            o_date  := pk_date_utils.next_day_standard(i_date => l_dt_aux, i_weekday_standard => i_weekday);
        ELSE
            o_date := l_dt_aux;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_NEXT_DAY',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_next_day;

    /**********************************************************************************************
    * This function returns the last day of month.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array     
    * @param i_date                          Input date
    * @param o_date                          Output date    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.4
    * @since                                 2009/06/23
    **********************************************************************************************/
    FUNCTION get_last_day_month
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_date  IN TIMESTAMP,
        o_date  OUT TIMESTAMP,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_aux_month TIMESTAMP;
    BEGIN
        l_dt_aux_month := trunc(i_date, 'MM');
    
        g_error := 'CALL GET_FST_DAY_NEXT_MONTH';
        IF NOT get_fst_day_next_month(i_lang  => i_lang,
                                      i_prof  => i_prof,
                                      i_date  => i_date,
                                      o_date  => l_dt_aux_month,
                                      o_error => o_error)
        THEN
            NULL;
        END IF;
    
        g_error := 'CALL add_days_to_tstz';
        o_date  := pk_date_utils.add_days_to_tstz(i_timestamp => l_dt_aux_month, i_days => -1);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_NEXT_DAY',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_last_day_month;

    ------------------------------ PUBLIC FUNCTIONS ---------------------------

    /*
    *  search for the free vacancy keyword in the given list.
    *  To be used inside sql.
    *
    * @param i_status     string with list of status values in csv form
    * 
    * @return  Y = keyword present  N = not present
    *
    * @author   Telmo
    * @version  2.5
    * @date     25-03-2009
    */
    FUNCTION get_only_vacs(i_status VARCHAR2) RETURN VARCHAR2 IS
        l_list_status table_varchar;
        i             INTEGER;
        l_only_vacs   VARCHAR2(1) := g_no;
    BEGIN
        -- DETERMINE IF ONLY VACANCIES WAS ASKED
        g_error       := 'CALC L_ONLY_VACS';
        l_list_status := pk_schedule.get_list_string_csv(i_status);
        i             := l_list_status.first;
        WHILE i IS NOT NULL
              AND l_only_vacs = g_no
        LOOP
            IF l_list_status(i) = pk_schedule_common.g_onlyfreevacs
            THEN
                l_only_vacs := g_yes;
            END IF;
            i := l_list_status.next(i);
        END LOOP;
    
        RETURN l_only_vacs;
    END get_only_vacs;

    /**
    * This function is used to replace several tokens in a given string.
    * It is used internally by functions/procedures that need to perform
    * token replacement, such as string_date.
    *
    * @param i_lang         Language (just used for error messages).
    * @param i_string       String with all the tokens to replace.
    * @param i_tokens       Nested table that contains the list of tokens to replace.
    * @param i_replacements Nested table that contains the list of replacements.
    * @param o_string       String with all the replacements made (or '' on error).
    * @param o_error        Error description if it exists.
    *
    * @return   True if successful executed, false otherwise.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION replace_tokens
    (
        i_lang         IN language.id_language%TYPE,
        i_string       IN VARCHAR2,
        i_tokens       IN table_varchar,
        i_replacements IN table_varchar,
        o_string       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        e_bad_arguments EXCEPTION;
        l_func_name VARCHAR2(32) := 'REPLACE_TOKENS';
    BEGIN
        g_error := 'CHECK i_tokens AND i_replacements ELEMENT COUNT';
        IF i_tokens.count != i_replacements.count
        THEN
            -- The number of tokens to replace and the number of replacements is different
            g_error := 'CHECK IN i_tokens.COUNT = ' || i_tokens.count || 'i_replacements.COUNT = ' ||
                       i_replacements.count;
            RAISE e_bad_arguments;
        ELSE
            -- Replace all tokens by their replacements.
            g_error  := 'CHECK OUT i_tokens.COUNT = ' || i_tokens.count || 'i_replacements.COUNT = ' ||
                        i_replacements.count;
            o_string := i_string;
            FOR idx IN 1 .. i_tokens.count
            LOOP
                g_error  := 'LOOP idx = ' || idx || ' -- i_tokens.COUNT = ' || i_tokens.count ||
                            'i_replacements.COUNT = ' || i_replacements.count;
                o_string := REPLACE(o_string, i_tokens(idx), i_replacements(idx));
            END LOOP;
        END IF;
        g_error := 'End replace_tokens';
        RETURN TRUE;
    EXCEPTION
        WHEN e_bad_arguments THEN
            -- The arguments were badly created.
            o_string := '';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Bad i_tokens and i_replacements arguments',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            -- Unexpected error
            o_string := '';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END replace_tokens;

    /**
    * Pushes messages into a global message stack.
    *
    * @param    i_message       The message string
    *
    * @author  Ricardo Pinho
    * @version alpha
    * @since   2007/01/17
    *
    * UPDATED
    * added field idx so that one can identify messages
    * @author Telmo Castro
    * @date   29-08-2008
    * @version 2.4.3
    */
    PROCEDURE message_push
    (
        i_message IN VARCHAR2,
        i_idxmsg  IN NUMBER
    ) AS
        l_msg_separator VARCHAR2(90) DEFAULT chr(13) || chr(13) || '--------------------------------------------------------------------------------' || chr(13) || chr(13);
        l_func_name     VARCHAR2(32);
        l_t_msg_stack   t_msg_stack;
    BEGIN
        l_func_name := 'MESSAGE_PUSH';
        g_error     := 'PUSH MESSAGE';
    
        l_t_msg_stack.idxmsg := i_idxmsg;
        l_t_msg_stack.msg := i_message;
        g_msg_stack(g_msg_stack.count) := l_t_msg_stack;
        g_msg_stack.extend;
        l_t_msg_stack.idxmsg := -1;
        l_t_msg_stack.msg := l_msg_separator;
        g_msg_stack(g_msg_stack.count) := l_t_msg_stack;
        g_msg_stack.extend;
    EXCEPTION
        WHEN OTHERS THEN
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
    END message_push;

    /**
    * Pushes messages into global message stack.
    * This one is html ready
    *
    * @param    i_message       The message string
    *
    * @author Telmo Castro
    * @date    27-04-2009
    * @version 2.5
    */
    FUNCTION message_push_html
    (
        i_lang            IN language.id_language%TYPE,
        i_message         IN VARCHAR2,
        i_idxmsg          IN NUMBER,
        i_enclose_tag     IN VARCHAR2,
        i_enclose_tag_end IN VARCHAR2,
        i_breakline_tag   IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'MESSAGE_PUSH_HTML';
        l_t_msg_stack t_msg_stack;
    BEGIN
        g_error := 'COMPOSE STRING';
        l_t_msg_stack.idxmsg := nvl(i_enclose_tag, '') || i_idxmsg || nvl(i_enclose_tag_end, '') ||
                                nvl(i_breakline_tag, '');
        l_t_msg_stack.msg := i_message;
        g_msg_stack(g_msg_stack.count) := l_t_msg_stack;
        g_msg_stack.extend;
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
            RETURN FALSE;
    END message_push_html;

    /**
    * Flushes messages returning them on the output parameter.
    *
    * @param    o_message       The compilation of stack's messages
    *
    * @author  Ricardo Pinho
    * @version alpha
    * @since   2007/01/17
    */
    PROCEDURE message_flush(o_message OUT VARCHAR2) AS
        l_func_name VARCHAR2(32) := 'MESSAGE_FLUSH';
    BEGIN
        g_error := 'CONCAT messages';
        FOR i IN 1 .. g_msg_stack.count - 2
        LOOP
            o_message := o_message || g_msg_stack(i).msg;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
    END message_flush;

    /**
    * This function is used to internally to call pk_message.get_message.
    * It logs a warning if the message does not exist.
    * Note: As it is a mere encapsulation of pk_message.get_message it does not
    * follow the common return type as stated on the best practices.
    *
    * @param i_lang         Language (just used for error messages).
    * @param i_message      Message to get.
    *
    * @return   Message.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION get_message
    (
        i_lang    IN language.id_language%TYPE,
        i_message IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_message sys_message.desc_message%TYPE := NULL;
    BEGIN
        IF i_message IS NOT NULL
        THEN
            l_message := pk_message.get_message(i_lang => i_lang, i_code_mess => i_message);
            IF l_message IS NULL
            THEN
                pk_alertlog.log_warn(text        => g_missing_message || i_message,
                                     object_name => g_package_name,
                                     owner       => g_package_owner);
            END IF;
        END IF;
        RETURN l_message;
    END;

    /**
    * Returns the description of the patient's default health plan.
    * To be used inside a SELECT statement.
    *
    * @param   i_lang         Language.
    * @param   i_id_patient   Patient identifier.
    * @param   i_id_inst      Institution.
    *
    * @return  the description of the patient's default health plan
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/07/06
    */
    FUNCTION get_health_plan
    (
        i_lang       NUMBER,
        i_id_patient patient.id_patient%TYPE,
        i_id_inst    institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_plan_desc VARCHAR2(4000) := NULL;
    BEGIN
        g_error := 'GET_HEALTH_PLAN';
        FOR hps IN (SELECT pk_translation.get_translation(i_lang, hp.code_health_plan) || chr(10) || php.num_health_plan plan_desc
                      FROM health_plan hp, pat_health_plan php
                     WHERE php.id_patient = i_id_patient
                       AND php.id_institution = i_id_inst
                       AND php.flg_default = g_yes
                       AND hp.id_health_plan = php.id_health_plan)
        LOOP
            IF l_plan_desc IS NOT NULL
            THEN
                l_plan_desc := l_plan_desc || chr(10);
            END IF;
            l_plan_desc := l_plan_desc || hps.plan_desc;
        END LOOP;
    
        RETURN l_plan_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '-----';
    END get_health_plan;

    /**
    * This function returns (via output parameters) the begin and end dates
    * for the first compatible vacancy.
    *
    * @param i_lang                     Language identifier.
    * @param i_prof                     Professional.
    * @param i_search_date_begin        Begin date (for searching).
    * @param i_search_date_end          End date (for searching).
    * @param i_dt_begin                 Original schedule's begin date.
    * @param i_flg_sch_type             Type of schedule.
    * @param i_sch_event                Event type.
    * @param i_id_dep_clin_serv         Department's Clinical service.
    * @param i_id_prof                  Target professional.
    * @param i_id_exam                  Exam identifier.
    * @param i_id_analysis              Analysis identifier.
    * @param o_hour_begin               Begin date for the first compatible vacancy.
    * @param o_hour_end                 End date for the first compatible vacancy.
    * @param o_unplanned                1 if the schedule is to be created as unplanned, 0 otherwise.
    * @param o_error                    Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro (Tiago Ferreira)
    * @version alpha
    * @since   2007/04/26
    *
    * UPDATED
    * added check of sch_permission.flg_permission
    * @author  Telmo Castro
    * @date    15-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * new scenario in sch_permission - prof1-prof2-dcs-evento.
    * @author  Telmo Castro
    * @date    16-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * adapted to MFR scheduler
    * @author  Telmo Castro
    * @date    13-01-2009
    * @version 2.4.3.x
    *
    * UPDATED
    * new parameter i_id_institution
    * @author  Sofia Mendes
    * @date    29-07-2009
    * @version 2.5.0.5
    *
    * UPDATED alert-8202. sch_consult_vac_exam demise
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    20-10-2009
    */
    FUNCTION get_first_valid_vacancy
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_search_date_begin IN VARCHAR2,
        i_search_date_end   IN VARCHAR2,
        i_dt_begin          IN VARCHAR2,
        i_flg_sch_type      IN schedule.flg_sch_type%TYPE,
        i_sch_event         IN sch_consult_vacancy.id_sch_event%TYPE,
        i_id_dep_clin_serv  IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_prof           IN sch_consult_vacancy.id_prof%TYPE,
        i_id_physarea       IN sch_consult_vac_mfr.id_physiatry_area%TYPE DEFAULT NULL,
        i_id_institution    IN institution.id_institution%TYPE DEFAULT NULL,
        o_hour_begin        OUT VARCHAR2,
        o_hour_end          OUT VARCHAR2,
        o_unplanned         OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- Vacancies
        CURSOR c_vacancies
        (
            i_id_sch_event   schedule.id_sch_event%TYPE,
            i_date_begin     TIMESTAMP WITH TIME ZONE,
            i_date_end       TIMESTAMP WITH TIME ZONE,
            i_orig_dt_begin  TIMESTAMP WITH TIME ZONE,
            i_id_institution institution.id_institution%TYPE
        ) IS
            SELECT dt_begin_tstz,
                   dt_end_tstz,
                   scv.id_dep_clin_serv id_dep_clin_serv,
                   scv.id_sch_event id_sch_event,
                   NULL id_child,
                   i_flg_sch_type flg_sch_type,
                   0 unplanned,
                   scv.max_vacancies - scv.used_vacancies free
              FROM sch_consult_vacancy scv, sch_permission sp
             WHERE scv.id_sch_event = sp.id_sch_event
               AND sp.id_institution = c_vacancies.i_id_institution --i_prof.institution
               AND sp.id_professional = i_prof.id
               AND scv.id_dep_clin_serv = i_id_dep_clin_serv
               AND scv.id_institution = c_vacancies.i_id_institution --i_prof.institution
               AND scv.id_sch_event = c_vacancies.i_id_sch_event
               AND sp.flg_permission <> g_permission_none
                  -- Telmo 16-05-2008
               AND sp.id_dep_clin_serv = i_id_dep_clin_serv
               AND (i_id_prof IS NULL OR i_id_prof = sp.id_prof_agenda)
               AND scv.dt_begin_tstz >= i_date_begin
               AND scv.dt_begin_tstz < i_date_end
               AND scv.max_vacancies > 0
               AND is_vacancy_available(scv.id_sch_consult_vacancy) = g_yes
               AND scv.flg_status = pk_schedule_bo.g_status_active
            -- Try to maintain the same time of day
             ORDER BY decode(scv.max_vacancies, scv.used_vacancies, 1, 0) ASC,
                      abs((pk_date_utils.get_timestamp_diff(scv.dt_begin_tstz,
                                                            pk_date_utils.trunc_insttimezone(i_prof, scv.dt_begin_tstz))) -
                          (pk_date_utils.get_timestamp_diff(i_orig_dt_begin,
                                                            pk_date_utils.trunc_insttimezone(i_prof, i_orig_dt_begin)))) ASC,
                      scv.dt_begin_tstz ASC;
    
        -- Vacancies
        CURSOR c_vacancies_mfr
        (
            i_id_sch_event  schedule.id_sch_event%TYPE,
            i_date_begin    TIMESTAMP WITH TIME ZONE,
            i_date_end      TIMESTAMP WITH TIME ZONE,
            i_orig_dt_begin TIMESTAMP WITH TIME ZONE
        ) IS
            SELECT dt_begin_tstz,
                   dt_end_tstz,
                   scv.id_dep_clin_serv id_dep_clin_serv,
                   scv.id_sch_event id_sch_event,
                   scvm.id_physiatry_area id_child,
                   i_flg_sch_type flg_sch_type,
                   0 unplanned,
                   (SELECT COUNT(1)
                      FROM sch_consult_vac_mfr_slot sl
                     WHERE sl.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
                       AND sl.flg_status = g_slot_status_permanent
                       AND sl.dt_begin_tstz >= i_date_begin
                       AND sl.dt_begin_tstz < i_date_end) free
              FROM sch_consult_vacancy scv, sch_permission sp, sch_consult_vac_mfr scvm
             WHERE scv.id_sch_event = sp.id_sch_event
               AND sp.id_institution = i_prof.institution
               AND sp.id_professional = i_prof.id
               AND scv.id_dep_clin_serv = i_id_dep_clin_serv
               AND scv.id_institution = i_prof.institution
               AND scv.id_sch_event = c_vacancies_mfr.i_id_sch_event
               AND sp.flg_permission <> g_permission_none
               AND sp.id_dep_clin_serv = i_id_dep_clin_serv
               AND (i_id_prof IS NULL OR i_id_prof = sp.id_prof_agenda)
               AND scv.id_sch_consult_vacancy = scvm.id_sch_consult_vacancy
               AND (i_id_physarea IS NULL OR scvm.id_physiatry_area = i_id_physarea)
               AND scv.dt_begin_tstz >= i_date_begin
               AND scv.dt_begin_tstz < i_date_end
               AND is_vacancy_available(scv.id_sch_consult_vacancy) = g_yes
               AND scv.flg_status = pk_schedule_bo.g_status_active
            -- Try to maintain the same time of day
             ORDER BY abs((pk_date_utils.get_timestamp_diff(scv.dt_begin_tstz,
                                                            pk_date_utils.trunc_insttimezone(i_prof, scv.dt_begin_tstz))) -
                          (pk_date_utils.get_timestamp_diff(i_orig_dt_begin,
                                                            pk_date_utils.trunc_insttimezone(i_prof, i_orig_dt_begin)))) ASC,
                      scv.dt_begin_tstz ASC;
    
        TYPE t_vacancies IS TABLE OF c_vacancies%ROWTYPE INDEX BY BINARY_INTEGER;
    
        -- Checks the temporary table for free vacancies.
        CURSOR c_count_free(i_vacancy c_vacancies%ROWTYPE) IS
            SELECT COUNT(1)
              FROM sch_mult_reschedule_aux smra
             WHERE smra.dt_begin_tstz = i_vacancy.dt_begin_tstz
               AND i_vacancy.free > smra.counter
               AND smra.id_dep_clin_serv = i_vacancy.id_dep_clin_serv
               AND smra.id_sch_event = i_vacancy.id_sch_event
               AND nvl(smra.id_child, g_unknown_id) = nvl(i_vacancy.id_child, g_unknown_id)
               AND smra.flg_sch_type = i_vacancy.flg_sch_type;
    
        -- Checks the temporary table for vacancies.
        CURSOR c_count_total(i_vacancy c_vacancies%ROWTYPE) IS
            SELECT COUNT(1)
              FROM sch_mult_reschedule_aux smra
             WHERE smra.dt_begin_tstz = i_vacancy.dt_begin_tstz
               AND smra.id_dep_clin_serv = i_vacancy.id_dep_clin_serv
               AND smra.id_sch_event = i_vacancy.id_sch_event
               AND nvl(smra.id_child, g_unknown_id) = nvl(i_vacancy.id_child, g_unknown_id)
               AND smra.flg_sch_type = i_vacancy.flg_sch_type;
    
        -- The date with the least number of unplanned vacancies
        CURSOR c_min_unplanned(i_vacancy c_vacancies%ROWTYPE) IS
            SELECT pk_date_utils.date_send_tsz(i_lang, smra_out.dt_begin_tstz, i_prof),
                   pk_date_utils.date_send_tsz(i_lang, smra_out.dt_end_tstz, i_prof)
              FROM sch_mult_reschedule_aux smra_out
             WHERE smra_out.unplanned_counter =
                   (SELECT MIN(smra.unplanned_counter)
                      FROM sch_mult_reschedule_aux smra
                     WHERE smra.id_dep_clin_serv = i_vacancy.id_dep_clin_serv
                       AND smra.id_sch_event = i_vacancy.id_sch_event
                       AND nvl(smra.id_child, g_unknown_id) = nvl(i_vacancy.id_child, g_unknown_id)
                       AND smra.flg_sch_type = i_vacancy.flg_sch_type);
    
        l_func_name VARCHAR2(32);
    
        l_vacancies         t_vacancies;
        l_count_free        NUMBER;
        l_count_total       NUMBER;
        l_date_found        BOOLEAN := FALSE;
        l_dt_begin          TIMESTAMP WITH TIME ZONE;
        l_search_date_begin TIMESTAMP WITH TIME ZONE;
        l_search_date_end   TIMESTAMP WITH TIME ZONE;
        l_hour_begin        TIMESTAMP WITH TIME ZONE;
        l_hour_end          TIMESTAMP WITH TIME ZONE;
        l_id_sch_event      schedule.id_sch_event%TYPE;
        l_id_institution    institution.id_institution%TYPE := i_id_institution;
    BEGIN
        l_func_name  := 'GET_FIRST_VALID_VACANCY';
        o_hour_begin := NULL;
        o_hour_end   := NULL;
        o_unplanned  := 0;
    
        IF (l_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_GENERIC_EVENT';
        -- Get generic event or self
        IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                    i_id_institution => l_id_institution, --i_prof.institution,
                                                    i_id_event       => i_sch_event,
                                                    o_id_event       => l_id_sch_event,
                                                    o_error          => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'GET OLD DATE';
        IF i_dt_begin IS NULL
        THEN
            g_error := 'CALL TRUNC_INSTTIMEZONE';
            -- Get the current timestamp truncated using the preferred time zone
            IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_timestamp => current_timestamp,
                                                    o_timestamp => l_dt_begin,
                                                    o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
            -- Convert string to timestamp
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dt_begin,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_begin,
                                                 o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_search_date_begin';
        -- Convert string to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_search_date_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_search_date_begin,
                                             o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_search_date_end';
        -- Convert string to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_search_date_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_search_date_end,
                                             o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        IF i_flg_sch_type <> pk_schedule_common.g_sch_dept_flg_dep_type_pm
        THEN
            -- Open vacancies cursor
            g_error := 'OPEN c_vacancies';
            OPEN c_vacancies(l_id_sch_event, l_search_date_begin, l_search_date_end, l_dt_begin, l_id_institution);
            -- Fetch vacancies
            g_error := 'FETCH c_vacancies';
            FETCH c_vacancies BULK COLLECT
                INTO l_vacancies;
            -- Close cursor
            g_error := 'CLOSE c_vacancies';
            CLOSE c_vacancies;
        ELSE
            -- Open vacancies cursor
            g_error := 'OPEN c_vacancies_mfr';
            OPEN c_vacancies_mfr(l_id_sch_event, l_search_date_begin, l_search_date_end, l_dt_begin);
            -- Fetch vacancies
            g_error := 'FETCH c_vacancies_mfr';
            FETCH c_vacancies_mfr BULK COLLECT
                INTO l_vacancies;
            -- Close cursor
            g_error := 'CLOSE c_vacancies_mfr';
            CLOSE c_vacancies_mfr;
        END IF;
        g_error := 'ITERATE';
        IF l_vacancies.count > 0
        THEN
            -- Iterate through available vacancies trying to find a valid slot
            FOR idx IN l_vacancies.first .. l_vacancies.last
            LOOP
                EXIT WHEN l_date_found;
                -- Get total number of vacancies
                g_error := 'OPEN c_count_total';
                OPEN c_count_total(l_vacancies(idx));
            
                g_error := 'FETCH c_count_total';
                FETCH c_count_total
                    INTO l_count_total;
            
                g_error := 'CLOSE c_count_total';
                CLOSE c_count_total;
                -- Get number of free vacancy records
                g_error := 'OPEN c_count_free';
                OPEN c_count_free(l_vacancies(idx));
            
                g_error := 'FETCH c_count_free';
                FETCH c_count_free
                    INTO l_count_free;
            
                g_error := 'CLOSE c_count_free';
                CLOSE c_count_free;
            
                IF l_count_free > 0
                   OR (l_count_total = 0 AND l_vacancies(idx).free > 0)
                THEN
                    -- Set date as a return.
                    g_error      := 'GET BEGIN AND END HOURS';
                    o_hour_begin := pk_date_utils.date_send_tsz(i_lang, l_vacancies(idx).dt_begin_tstz, i_prof);
                    o_hour_end   := pk_date_utils.date_send_tsz(i_lang, l_vacancies(idx).dt_end_tstz, i_prof);
                
                    -- Set flag to stop iterating
                    l_date_found := TRUE;
                
                    IF l_vacancies(idx).free = 0
                        AND l_count_total = 0
                    THEN
                        -- No free vacancy was found. And this is the only vacancy available.
                        o_unplanned := 1;
                    ELSE
                    
                        g_error := 'UPDATE TEMPORARY COUNTER';
                    
                        -- Update the temporary table for a further execution of this function.
                        MERGE INTO sch_mult_reschedule_aux a
                        USING (SELECT l_vacancies(idx).dt_begin_tstz dt_begin_tstz,
                                      l_vacancies(idx).dt_end_tstz dt_end_tstz,
                                      l_vacancies(idx).id_dep_clin_serv id_dep_clin_serv,
                                      l_vacancies(idx).id_sch_event id_sch_event,
                                      l_vacancies(idx).id_child id_child,
                                      l_vacancies(idx).flg_sch_type flg_sch_type
                                 FROM dual) b
                        ON (a.dt_begin_tstz = b.dt_begin_tstz AND a.id_dep_clin_serv = b.id_dep_clin_serv AND a.id_sch_event = b.id_sch_event AND nvl(a.id_child, g_unknown_id) = nvl(b.id_child, g_unknown_id) AND a.flg_sch_type = b.flg_sch_type)
                        WHEN MATCHED THEN
                        -- Consume another slot
                            UPDATE
                               SET counter = counter + 1
                        WHEN NOT MATCHED THEN
                        -- Consume the first slot
                            INSERT
                                (dt_begin_tstz,
                                 dt_end_tstz,
                                 id_dep_clin_serv,
                                 id_sch_event,
                                 id_child,
                                 flg_sch_type,
                                 counter,
                                 unplanned_counter)
                            VALUES
                                (l_vacancies(idx).dt_begin_tstz,
                                 l_vacancies(idx).dt_end_tstz,
                                 l_vacancies(idx).id_dep_clin_serv,
                                 l_vacancies(idx).id_sch_event,
                                 l_vacancies(idx).id_child,
                                 l_vacancies(idx).flg_sch_type,
                                 1,
                                 0);
                    
                    END IF;
                
                    SELECT MAX(counter)
                      INTO l_count_total
                      FROM sch_mult_reschedule_aux;
                END IF;
            END LOOP;
        
            -- No date was found. The schedule will eventually be created
            -- as "unplanned". We need to get date of vacancy that has
            -- the least number of unplanned vacancies.
            IF NOT l_date_found
            THEN
                o_unplanned := 1;
                g_error     := 'OPEN c_min_unplanned';
                -- Use the first vacancy (ignoring the dates) to get
                -- a matching vacancy.
                OPEN c_min_unplanned(l_vacancies(l_vacancies.first));
            
                g_error := 'FETCH c_min_unplanned';
                -- Get date of vacancy that has the least number of unplanned vacancies.
                FETCH c_min_unplanned
                    INTO o_hour_begin, o_hour_end;
            
                g_error := 'NO MINIMUM UNPLANNED VACANCY';
                IF c_min_unplanned%NOTFOUND
                   AND l_vacancies.count > 0
                THEN
                    -- No vacancies are stored in the temporary table,
                    -- as the day is full already. Use the first vacancy found.
                    --dbms_output.put_line(l_vacancies(1).dt_begin_tstz);
                    --dbms_output.put_line(l_vacancies(1).dt_end_tstz);
                    o_hour_begin := pk_date_utils.date_send_tsz(i_lang, l_vacancies(1).dt_begin_tstz, i_prof);
                    o_hour_end   := pk_date_utils.date_send_tsz(i_lang, l_vacancies(1).dt_end_tstz, i_prof);
                END IF;
            
                g_error := 'CLOSE c_min_unplanned';
                CLOSE c_min_unplanned;
            
                g_error := 'UPDATE TEMPORARY UNPLANNED COUNTER';
                -- Update the unplanned vacancy counter.
                DECLARE
                    l_id_dep_clin_serv NUMBER := l_vacancies(l_vacancies.first).id_dep_clin_serv;
                    l_id_sch_event     NUMBER := l_vacancies(l_vacancies.first).id_sch_event;
                    l_id_child         NUMBER := l_vacancies(l_vacancies.first).id_child;
                    l_flg_sch_type     VARCHAR2(2) := l_vacancies(l_vacancies.first).flg_sch_type;
                BEGIN
                    g_error := 'CALL GET_STRING_TSTZ FOR l_hour_begin';
                    -- Convert to timestamp
                    IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_timestamp => o_hour_begin,
                                                         i_timezone  => NULL,
                                                         o_timestamp => l_hour_begin,
                                                         o_error     => o_error)
                    THEN
                        pk_date_utils.set_dst_time_check_on;
                        RETURN FALSE;
                    END IF;
                
                    g_error := 'UPDATE UNPLANNED COUNTER';
                    -- Update unplanned counter
                    UPDATE sch_mult_reschedule_aux smra
                       SET unplanned_counter = unplanned_counter + 1
                     WHERE smra.dt_begin_tstz = l_hour_begin
                       AND smra.id_dep_clin_serv = l_id_dep_clin_serv
                       AND smra.id_sch_event = l_id_sch_event
                       AND nvl(smra.id_child, g_unknown_id) = nvl(l_id_child, g_unknown_id)
                       AND smra.flg_sch_type = l_flg_sch_type;
                END;
            END IF;
        
        END IF;
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_on;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_first_valid_vacancy;

    /**
    * This function is used to internally to call pk_sysdomain.get_domain.
    * It logs a warning if the domain description value does not exist.
    * Note: As it is a mere encapsulation of pk_sysdomain.get_domain it does not
    * follow the common return type as stated on the best practices.
    * To be used inside SELECTs, for instance.
    *
    * @param i_lang         Language (just used for error messages).
    * @param i_code_dom     Domain code.
    * @param i_val          Domain value.
    *
    * @return   Domain description value.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION get_domain_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val      IN sys_domain.val%TYPE
    ) RETURN VARCHAR2 IS
        l_desc_val sys_domain.desc_val%TYPE := NULL;
    BEGIN
        IF i_code_dom IS NOT NULL
           AND i_val IS NOT NULL
        THEN
            l_desc_val := pk_sysdomain.get_domain(i_code_dom => i_code_dom, i_val => i_val, i_lang => i_lang);
            IF l_desc_val IS NULL
            THEN
                -- Missing domain desc value.
                pk_alertlog.log_warn(text        => g_missing_domain || '(' || i_code_dom || ', ' || i_val || ', ' ||
                                                    i_lang || ')',
                                     object_name => g_package_name,
                                     owner       => g_package_owner);
            END IF;
        END IF;
        RETURN l_desc_val;
    END get_domain_desc;

    /*
    * Gets a list of numbers from a CSV string.
    *
    * @param i_list CSV List of numbers.
    *
    * @return List (table_number) of numbers.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/05/08
    */
    FUNCTION get_list_number_csv(i_list VARCHAR2) RETURN table_number IS
        l_delimiter     VARCHAR2(1) := ',';
        l_len_delimiter PLS_INTEGER;
        l_idx           PLS_INTEGER;
        l_list          VARCHAR2(4000) := i_list;
        l_aux           VARCHAR2(4000);
        l_ret           table_number := table_number();
        l_ret_idx       PLS_INTEGER := 0;
        l_out           BOOLEAN := FALSE;
    BEGIN
    
        IF (i_list IS NOT NULL)
        THEN
            l_len_delimiter := length(l_delimiter);
            LOOP
                EXIT WHEN l_out;
                l_idx     := instr(l_list, l_delimiter);
                l_ret_idx := l_ret_idx + 1;
                IF l_idx > 0
                THEN
                    l_ret.extend;
                    l_aux := substr(l_list, 1, l_idx - 1);
                    l_ret(l_ret_idx) := trunc(to_number(l_aux,
                                                        translate(l_aux, '1234567890', '9999999999'),
                                                        ' NLS_NUMERIC_CHARACTERS = '',.'''),
                                              g_max_decimal_prec);
                    l_list := substr(l_list, l_idx + l_len_delimiter);
                ELSE
                    l_ret.extend;
                    l_ret(l_ret_idx) := trunc(to_number(l_list,
                                                        translate(l_list, '1234567890', '9999999999'),
                                                        ' NLS_NUMERIC_CHARACTERS = '',.'''),
                                              g_max_decimal_prec);
                
                    l_out := TRUE;
                END IF;
            END LOOP;
        END IF;
        RETURN l_ret;
    END get_list_number_csv;

    /*
    * Gets a list of strings from a CSV string.
    *
    * @param i_list CSV List of strings.
    *
    * @return List (table_varchar) of strings.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/05/08
    */
    FUNCTION get_list_string_csv(i_list VARCHAR2) RETURN table_varchar IS
        l_delimiter     VARCHAR2(1) := ',';
        l_len_delimiter PLS_INTEGER;
        l_idx           PLS_INTEGER;
        l_list          VARCHAR2(4000) := i_list;
        l_ret           table_varchar := table_varchar();
        l_ret_idx       PLS_INTEGER := 0;
        l_out           BOOLEAN := FALSE;
    BEGIN
        IF (i_list IS NOT NULL)
        THEN
            l_len_delimiter := length(l_delimiter);
            LOOP
                EXIT WHEN l_out;
                l_idx     := instr(l_list, l_delimiter);
                l_ret_idx := l_ret_idx + 1;
                IF l_idx > 0
                THEN
                    l_ret.extend;
                    l_ret(l_ret_idx) := substr(l_list, 1, l_idx - 1);
                    l_list := substr(l_list, l_idx + l_len_delimiter);
                ELSE
                    l_ret.extend;
                    l_ret(l_ret_idx) := l_list;
                    l_out := TRUE;
                END IF;
            END LOOP;
        END IF;
        RETURN l_ret;
    END get_list_string_csv;

    /**
    * This function is used inside WHERE clauses to check if a string element is inside a string list.
    *
    * @param i_element      Element
    * @param i_list         List
    *
    * @return   1 if the element is found, 0 otherwise.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/30
    */
    FUNCTION exist_inside_list
    (
        i_element VARCHAR2,
        i_list    VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        IF (i_element = i_list OR instr(i_list, i_element || ',') = 1 OR instr(i_list, ',' || i_element || ',') > 0 OR
           instr(i_list, ',' || i_element, -1) = length(i_list) - length(i_element))
        THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END exist_inside_list;

    /**
    * Gets an event' s translated description.
    * To be used inside SELECTs.
    *
    * @param i_lang               Language identifier
    * @param i_id_sch_event       Event identifier
    * @param o_string             Event's translated description
    * @param o_error              Error message (if an error occurred).
    *
    * @return  True if successful executed, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_sch_event
    (
        i_lang         IN language.id_language%TYPE,
        i_id_sch_event IN sch_event.id_sch_event%TYPE
    ) RETURN VARCHAR2 IS
        l_ret       pk_translation.t_desc_translation;
        l_func_name VARCHAR2(32) := 'STRING_SCH_EVENT';
    BEGIN
        g_error := 'START';
        IF i_id_sch_event IS NULL
        THEN
            l_ret := '';
        ELSE
            g_error := 'SELECT';
            BEGIN
                SELECT pk_schedule_common.get_translation_alias(i_lang,
                                                                profissional(0, 0, 0),
                                                                se.id_sch_event,
                                                                se.code_sch_event)
                  INTO l_ret
                  FROM sch_event se
                 WHERE se.id_sch_event = i_id_sch_event
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    l_ret := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_SCH_EVENT = ' ||
                                                        i_id_sch_event,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_ret := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_ret;
    END string_sch_event;

    /**
    * Gets an institution translated description.
    * To be used inside SELECTs.
    *
    * @param i_lang               Language identifier
    * @param i_id_inst            inst id
    *
    * @return  output string
    *
    * @author  Telmo
    * @version 2.5.0.4
    * @since   26-06-2009
    */
    FUNCTION string_institution
    (
        i_lang    IN language.id_language%TYPE,
        i_id_inst IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_ret       pk_translation.t_desc_translation;
        l_func_name VARCHAR2(32) := 'STRING_INSTITUTION';
    BEGIN
        g_error := 'START';
        IF i_id_inst IS NULL
        THEN
            l_ret := '';
        ELSE
            g_error := 'SELECT';
            BEGIN
                SELECT pk_translation.get_translation(i_lang, i.code_institution)
                  INTO l_ret
                  FROM institution i
                 WHERE i.id_institution = i_id_inst
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    l_ret := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_INSTITUTION = ' ||
                                                        i_id_inst,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            l_ret := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_ret;
    END string_institution;

    /**
    * Gets the scheduling type translated description.
    * To be used inside SELECTs.
    *
    * @param i_lang               Language identifier
    * @param i_id_inst            inst id
    *
    * @return  output string
    *
    * @author  Telmo
    * @version 2.5.0.4
    * @since   26-06-2009
    */
    FUNCTION string_sch_type
    (
        i_lang     IN language.id_language%TYPE,
        i_dep_type IN sch_dep_type.dep_type%TYPE
    ) RETURN VARCHAR2 IS
        l_ret       pk_translation.t_desc_translation;
        l_func_name VARCHAR2(32) := 'string_sch_type';
    BEGIN
        g_error := 'START';
        IF i_dep_type IS NULL
        THEN
            l_ret := '';
        ELSE
            g_error := 'SELECT';
            BEGIN
                SELECT pk_translation.get_translation(i_lang, i.code_dep_type)
                  INTO l_ret
                  FROM sch_dep_type i
                 WHERE i.dep_type = i_dep_type
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    l_ret := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': DEP_TYPE = ' ||
                                                        i_dep_type,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            l_ret := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_ret;
    END string_sch_type;

    /**
    * Gets the department description.
    * To be used inside SELECTs.
    *
    * @param   i_lang            Language identifier.
    * @param   i_id_dep          Department identifier
    *
    * @return  Translated description of the department
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_department
    (
        i_lang   IN language.id_language%TYPE,
        i_id_dep IN clinical_service.id_clinical_service%TYPE
    ) RETURN VARCHAR2 IS
        l_ret       pk_translation.t_desc_translation;
        l_func_name VARCHAR2(32) := 'STRING_DEPARTMENT';
    BEGIN
        g_error := 'START';
        IF i_id_dep IS NULL
        THEN
            l_ret := '';
        ELSE
            g_error := 'SELECT';
            BEGIN
                SELECT pk_translation.get_translation(i_lang, d.code_department)
                  INTO l_ret
                  FROM department d
                 WHERE d.id_department = i_id_dep
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    l_ret := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_DEPARTMENT = ' ||
                                                        i_id_dep,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_ret := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_ret;
    END string_department;

    /**
    * Gets a room' s translated description.
    * To be used inside SELECTs.
    * @param i_lang             Language identifier.
    * @param i_id_room          Room identifier
    *
    * @return  Room description
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_room
    (
        i_lang    IN language.id_language%TYPE,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR2 IS
        l_ret       pk_translation.t_desc_translation;
        l_func_name VARCHAR2(32) := 'STRING_ROOM';
    BEGIN
        g_error := 'START';
        IF i_id_room IS NULL
        THEN
            l_ret := '';
        ELSE
            g_error := 'SELECT';
            BEGIN
                SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
                  INTO l_ret
                  FROM room r
                 WHERE r.id_room = i_id_room
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    l_ret := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_ROOM = ' ||
                                                        i_id_room,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_ret := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_ret;
    END string_room;

    /**
    * Gets an origin' s translated description.
    *
    * @param i_lang                Language identifier.
    * @param i_id_origin           Origin identifier.
    *
    * @return  Translated description.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_origin
    (
        i_lang      IN language.id_language%TYPE,
        i_id_origin IN origin.id_origin%TYPE
    ) RETURN VARCHAR2 IS
        l_ret       pk_translation.t_desc_translation;
        l_func_name VARCHAR2(32) := 'STRING_ORIGIN';
    BEGIN
        g_error := 'START';
        IF i_id_origin IS NULL
        THEN
            l_ret := '';
        ELSE
            g_error := 'SELECT';
            BEGIN
                SELECT pk_translation.get_translation(i_lang, o.code_origin)
                  INTO l_ret
                  FROM origin o
                 WHERE o.id_origin = i_id_origin
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    l_ret := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_ORIGIN = ' ||
                                                        i_id_origin,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_ret := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_ret;
    END string_origin;

    /**
    * Gets the clinical service (based on a dep_clin_serv) description.
    * To be used inside SELECTs.
    *
    * @param   i_lang            Language identifier.
    * @param   i_id_clin_serv    Clinical service identifier
    *
    * @return  Clinical service description
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_clin_serv_by_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
        l_ret       VARCHAR2(4000);
        l_func_name VARCHAR2(32) := 'STRING_CLIN_SERV_BY_DCS';
    BEGIN
        g_error := 'START';
        IF i_id_dep_clin_serv IS NULL
        THEN
            l_ret := '';
        ELSE
            g_error := 'SELECT';
            BEGIN
                SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                  INTO l_ret
                  FROM clinical_service cs, dep_clin_serv dcs
                 WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND cs.id_clinical_service = dcs.id_clinical_service
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    l_ret := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_DEP_CLIN_SERV = ' ||
                                                        i_id_dep_clin_serv,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_ret := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_ret;
    END string_clin_serv_by_dcs;

    /**
    * Gets a reason's translated description
    * To be used inside SELECTs
    * @param i_lang               Language identifier.
    * @param i_id_reason          Reason identifier
    *
    * @return  Reason
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_reason
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_reason IN schedule.id_reason%TYPE,
        i_flg_rtype IN schedule.flg_reason_type%TYPE
    ) RETURN VARCHAR2 IS
        l_ret       pk_translation.t_desc_translation;
        l_func_name VARCHAR2(32) := 'STRING_REASON';
        l_error     t_error_out;
    BEGIN
        IF i_id_reason IS NULL
           OR i_flg_rtype IS NULL
        THEN
            l_ret := '';
        ELSE
            g_error := 'SELECT';
            CASE i_flg_rtype
                WHEN 'R' THEN
                    BEGIN
                        SELECT pk_translation.get_translation(i_lang, st.code_title_sample_text)
                          INTO l_ret
                          FROM sample_text st
                         WHERE st.id_sample_text = i_id_reason
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation ||
                                                                ': ID_SAMPLE_TEXT = ' || i_id_reason,
                                                 object_name => g_package_name,
                                                 owner       => g_package_owner);
                    END;
                WHEN 'RP' THEN
                    BEGIN
                        SELECT pk_string_utils.clob_to_sqlvarchar2(stp.desc_sample_text_prof)
                          INTO l_ret
                          FROM sample_text_prof stp
                         WHERE stp.id_sample_text_prof = i_id_reason
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation ||
                                                                ': ID_SAMPLE_TEXT_PROF = ' || i_id_reason,
                                                 object_name => g_package_name,
                                                 owner       => g_package_owner);
                    END;
                WHEN 'C' THEN
                    BEGIN
                        SELECT pk_translation.get_translation(i_lang, c.code_complaint)
                          INTO l_ret
                          FROM complaint c
                         WHERE c.id_complaint = i_id_reason
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation ||
                                                                ': ID_COMPLAINT = ' || i_id_reason,
                                                 object_name => g_package_name,
                                                 owner       => g_package_owner);
                    END;
                WHEN 'RQ' THEN
                    IF NOT pk_consult_req.get_consult_req_reason(i_lang           => i_lang,
                                                                 i_id_consult_req => i_id_reason,
                                                                 o_reason         => l_ret,
                                                                 o_error          => l_error)
                    THEN
                        pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_CONSULT_REQ = ' ||
                                                            i_id_reason || ' - ' || l_error.ora_sqlerrm,
                                             object_name => g_package_name,
                                             owner       => g_package_owner);
                        l_ret := '';
                    END IF;
                WHEN 'RE' THEN
                    l_ret := pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang        => i_lang,
                                                                                                         i_prof        => i_prof,
                                                                                                         i_id_episode  => i_id_reason,
                                                                                                         i_id_schedule => NULL),
                                                              4000);
            END CASE;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_ret := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_ret;
    END string_reason;

    /**
    * Gets the description for i_id_lang, in the LANGUAGE domain.
    * To be used inside SELECTs.
    *
    * @param   i_lang           Language identifier.
    * @param   i_id_lang        Language domain value.
    *
    * @return  Language
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_language
    (
        i_lang    IN language.id_language%TYPE,
        i_id_lang IN language.id_language%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name   VARCHAR2(32) := 'STRING_LANGUAGE';
        l_language    sys_domain.desc_val%TYPE;
        l_code_domain sys_domain.code_domain%TYPE := 'LANGUAGE';
    BEGIN
        IF i_id_lang IS NULL
        THEN
            RETURN NULL;
        ELSE
            g_error := ' CALL get_domain_desc ';
            -- Get language from sys_domain
            l_language := get_domain_desc(i_code_dom => l_code_domain, i_val => i_id_lang, i_lang => i_lang);
        
            RETURN l_language;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN '';
    END string_language;

    /**
    * Gets the localized date.
    * To be used on SELECT statements.
    *
    * @param   i_lang            Language identifier.
    * @param   i_prof            Professional
    * @param   i_date            Date to localize.
    *
    * @return  Localized date.
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/30
    */
    FUNCTION string_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH TIME ZONE
    ) RETURN VARCHAR2 IS
        l_day          VARCHAR2(2);
        l_month        sys_message.desc_message%TYPE;
        l_year         VARCHAR2(4);
        l_tokens       table_varchar;
        l_replacements table_varchar;
        l_message      sys_message.desc_message%TYPE;
        l_localized    sys_message.desc_message%TYPE;
        l_error_dummy  t_error_out;
        l_func_name    VARCHAR2(32) := 'STRING_DATE';
    BEGIN
        IF i_date IS NULL
        THEN
            RETURN '';
        ELSE
            -- Create replacements for tokens
            g_error        := 'GET DAY';
            l_day          := pk_date_utils.to_char_insttimezone(i_prof, i_date, g_default_day_mask);
            g_error        := 'GET MONTH';
            l_month        := get_message(i_lang    => i_lang,
                                          i_message => 'SCH_MONTH_' ||
                                                       to_number(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                    i_date,
                                                                                                    g_default_month_mask)));
            g_error        := 'GET YEAR';
            l_year         := pk_date_utils.to_char_insttimezone(i_prof, i_date, g_default_year_mask);
            l_replacements := table_varchar(l_day, l_month, l_year);
            -- Set tokens to replace
            l_tokens := table_varchar('@1', '@2', '@3');
            -- Get message to translate
            g_error   := 'GET DAY OF MONTH OF YEAR MESSAGE';
            l_message := get_message(i_lang => i_lang, i_message => g_day_of_month_of_year);
            -- Replace tokens
            IF replace_tokens(i_lang         => i_lang,
                              i_string       => l_message,
                              i_tokens       => l_tokens,
                              i_replacements => l_replacements,
                              o_string       => l_localized,
                              o_error        => l_error_dummy)
            THEN
                RETURN l_localized;
            ELSE
                RETURN '';
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN '';
    END string_date;

    /**
    * Gets the localized birth date.
    * To be used on SELECT statements.
    *
    * @param   i_lang            Language identifier.
    * @param   i_prof            Professional
    * @param   i_date            Date to localize.
    *
    * @return  Localized date.
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/30
    */
    FUNCTION string_dt_birth
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN DATE
    ) RETURN VARCHAR2 IS
        l_day          VARCHAR2(2);
        l_month        sys_message.desc_message%TYPE;
        l_year         VARCHAR2(4);
        l_tokens       table_varchar;
        l_replacements table_varchar;
        l_message      sys_message.desc_message%TYPE;
        l_localized    sys_message.desc_message%TYPE;
        l_error_dummy  t_error_out;
        l_func_name    VARCHAR2(32) := 'STRING_DT_BIRTH';
    BEGIN
        IF i_date IS NULL
        THEN
            RETURN '';
        ELSE
            -- Create replacements for tokens
            g_error        := 'GET DAY';
            l_day          := to_char(i_date, g_default_day_mask);
            g_error        := 'GET MONTH';
            l_month        := get_message(i_lang    => i_lang,
                                          i_message => 'SCH_MONTH_' || to_number(to_char(i_date, g_default_month_mask)));
            g_error        := 'GET YEAR';
            l_year         := to_char(i_date, g_default_year_mask);
            l_replacements := table_varchar(l_day, l_month, l_year);
            -- Set tokens to replace
            l_tokens := table_varchar('@1', '@2', '@3');
            -- Get message to translate
            g_error   := 'GET DAY OF MONTH OF YEAR MESSAGE';
            l_message := get_message(i_lang => i_lang, i_message => g_day_of_month_of_year);
            -- Replace tokens
            IF replace_tokens(i_lang         => i_lang,
                              i_string       => l_message,
                              i_tokens       => l_tokens,
                              i_replacements => l_replacements,
                              o_string       => l_localized,
                              o_error        => l_error_dummy)
            THEN
                RETURN l_localized;
            ELSE
                RETURN '';
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN '';
    END string_dt_birth;

    /**
    * Gets the localized date (including hours and minutes).
    * To be used on SELECT statements.
    *
    * @param   i_lang            Language identifier.
    
    * @param   i_date            Date to localize.
    *
    * @return  Localized date.
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/30
    */
    FUNCTION string_date_hm
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH TIME ZONE
    ) RETURN VARCHAR2 IS
        l_day          VARCHAR2(2);
        l_month        sys_message.desc_message%TYPE;
        l_year         VARCHAR2(4);
        l_minute       VARCHAR2(2);
        l_hour         VARCHAR2(2);
        l_tokens       table_varchar;
        l_replacements table_varchar;
        l_message      sys_message.desc_message%TYPE;
        l_localized    sys_message.desc_message%TYPE;
        l_error_dummy  t_error_out;
        l_func_name    VARCHAR2(32) := 'STRING_DATE';
    BEGIN
        IF i_date IS NULL
        THEN
            RETURN '';
        ELSE
            -- Create replacements for tokens
            g_error := 'GET DAY';
            l_day   := pk_date_utils.to_char_insttimezone(i_prof, i_date, g_default_day_mask);
            g_error := 'GET MONTH';
            l_month := get_message(i_lang    => i_lang,
                                   i_message => 'SCH_MONTH_' ||
                                                to_number(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             i_date,
                                                                                             g_default_month_mask)));
            g_error := 'GET YEAR';
            l_year  := pk_date_utils.to_char_insttimezone(i_prof, i_date, g_default_year_mask);
        
            g_error        := 'GET HOUR';
            l_hour         := pk_date_utils.to_char_insttimezone(i_prof, i_date, g_default_hour_mask);
            g_error        := 'GET MINUTE';
            l_minute       := pk_date_utils.to_char_insttimezone(i_prof, i_date, g_default_minute_mask);
            l_replacements := table_varchar(l_day, l_month, l_year, l_hour, l_minute);
            -- Set tokens to replace
            l_tokens := table_varchar('@1', '@2', '@3', '@4', '@5');
            -- Get message to translate
            g_error   := 'GET DAY OF MONTH OF YEAR MESSAGE';
            l_message := get_message(i_lang => i_lang, i_message => g_day_of_month_of_year_hm);
            -- Replace tokens
            IF replace_tokens(i_lang         => i_lang,
                              i_string       => l_message,
                              i_tokens       => l_tokens,
                              i_replacements => l_replacements,
                              o_string       => l_localized,
                              o_error        => l_error_dummy)
            THEN
                RETURN l_localized;
            ELSE
                RETURN '';
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN '';
    END string_date_hm;

    /**
    * Gets the translated duration between two dates.
    * To be used on SELECT statements.
    *
    * @param i_lang       Language identification
    * @param i_dt_begin   Start date.
    * @param i_dt_end     End date.
    *
    * @return  Translated duration
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_duration
    (
        i_lang     IN NUMBER,
        i_dt_begin IN TIMESTAMP WITH TIME ZONE,
        i_dt_end   IN TIMESTAMP WITH TIME ZONE
    ) RETURN VARCHAR2 IS
        l_duration       VARCHAR2(200);
        l_minutes        NUMBER(8) := NULL;
        l_hours          NUMBER(8) := NULL;
        l_remain_minutes NUMBER(8) := NULL;
        e_bad_dates EXCEPTION;
        l_func_name VARCHAR2(32) := 'STRING_DURATION';
        l_diff      NUMBER;
        l_dummy     t_error_out;
    BEGIN
        IF i_dt_begin IS NULL
           OR i_dt_end IS NULL
        THEN
            -- Invalid dates passed as argument.
            RAISE e_bad_dates;
        END IF;
    
        g_error := 'CALL GET_TIMESTAMP_DIFF';
        -- Calculate duration
        IF NOT pk_date_utils.get_timestamp_diff(i_lang        => i_lang,
                                                i_timestamp_1 => i_dt_end,
                                                i_timestamp_2 => i_dt_begin,
                                                o_days_diff   => l_diff,
                                                o_error       => l_dummy)
        THEN
            RETURN '';
        END IF;
    
        -- Get number of minutes
        l_minutes := (l_diff) * 24 * 60;
        -- Get number of hours
        l_hours := trunc(l_minutes / 60);
        -- Get hours string
        g_error := 'GET HOURS STRING';
        IF (l_hours > 1)
        THEN
            -- <X hours>
            l_duration := l_duration || l_hours || ' ' || get_message(i_lang, g_hours);
        ELSIF (l_hours = 1)
        THEN
            -- <X hour>
            l_duration := l_duration || l_hours || ' ' || get_message(i_lang, g_hour);
        END IF;
        -- Get minutes string
        g_error          := 'GET MINUTES STRING';
        l_remain_minutes := MOD(l_minutes, 60);
        IF (l_remain_minutes > 0 AND l_hours > 0)
        THEN
            -- 'And'
            l_duration := l_duration || ' ' || get_message(i_lang, g_date_and) || ' ';
        END IF;
    
        IF l_remain_minutes > 1
        THEN
            -- <Y minutes>
            l_duration := l_duration || l_remain_minutes || ' ' || get_message(i_lang, g_minutes);
        ELSIF (l_remain_minutes = 1)
        THEN
            -- <Y minute>
            l_duration := l_duration || l_remain_minutes || ' ' || get_message(i_lang, g_minute);
        END IF;
        RETURN l_duration;
    EXCEPTION
        WHEN e_bad_dates THEN
            RETURN '';
        WHEN OTHERS THEN
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN '';
    END string_duration;

    /**
    * Gets the dep_clin_serv translated description.
    * To be used inside a SELECT.
    *
    * @param   i_lang                     Language identifier.
    * @param   i_id_dep_clin_serv         Department-Clinical Service identifier
    *
    * @return  Translated description or NULL if none is found.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/03
    */
    FUNCTION string_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN clinical_service.id_clinical_service%TYPE
    ) RETURN VARCHAR IS
        l_ret       pk_translation.t_desc_translation;
        l_func_name VARCHAR2(32) := 'STRING_DEP_CLIN_SERV';
    BEGIN
        g_error := 'START';
        IF i_id_dep_clin_serv IS NULL
        THEN
            l_ret := '';
        ELSE
            g_error := 'SELECT';
            BEGIN
                SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                  INTO l_ret
                  FROM clinical_service cs, dep_clin_serv dcs
                 WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND cs.id_clinical_service = dcs.id_clinical_service
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    l_ret := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_DEP_CLIN_SERV = ' ||
                                                        i_id_dep_clin_serv,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_ret := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_ret;
    END string_dep_clin_serv;

    /**
    * This function returns the number of the clinical record associated with a patient within an institution.
    * To be used inside SELECTs.
    *
    * @param i_id_patient Patient
    * @param i_id_inst     Institution
    *
    * @return number of the clinical record
    *
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/26
    */
    FUNCTION get_num_clin_record
    (
        i_id_patient IN clin_record.id_patient%TYPE,
        i_id_inst    IN clin_record.id_institution%TYPE
    ) RETURN clin_record.num_clin_record%TYPE IS
        l_num_clin_record clin_record.num_clin_record%TYPE;
    BEGIN
        BEGIN
            SELECT num_clin_record
              INTO l_num_clin_record
              FROM clin_record cr
             WHERE cr.id_patient = i_id_patient
               AND cr.id_institution = i_id_inst;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN '';
            WHEN too_many_rows THEN
                RETURN '-';
        END;
        RETURN l_num_clin_record;
    END get_num_clin_record;

    /**
    * Returns all the schedule status for the multi-choice except for the
    * pending state. Though it exists, it must not be on the multichoice,
    * for readibility sake.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_flg_search       Whether or not the 'All' item should be put on the multi-choice.
    * @param      o_status           List of status
    * @param      o_statusvac        status list with options 'livre' and 'ocupado'
    * @param      o_error            Error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Ricardo Pinho
    * @since      2006/04/10
    *
    * UPDATED
    * ALERT-708 - pesquisa por vagas livres.
    * @author   Telmo Castro
    * @date     25-03-2009
    * @version  2.5
    */
    FUNCTION get_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_search IN VARCHAR2,
        i_sch_type   IN VARCHAR2,
        o_status     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_STATUS';
    BEGIN
        g_error := 'OPEN o_status';
        OPEN o_status FOR
            SELECT data, label, flg_select, order_field
              FROM (SELECT to_char(g_all) data,
                           pk_message.get_message(i_lang, g_msg_all) label,
                           g_no flg_select,
                           1 order_field
                      FROM dual
                     WHERE i_flg_search = g_yes
                    UNION ALL
                    SELECT val data,
                           desc_val label,
                           decode(sd.val, g_status_scheduled, g_yes, g_no) flg_select,
                           4 order_field
                      FROM sys_domain sd
                     WHERE sd.code_domain = 'SCHEDULE.FLG_STATUS'
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val != g_status_pending
                       AND sd.val != g_status_requested
                       AND sd.val != g_status_unknown
                       AND sd.val != g_status_deleted
                    UNION ALL
                    SELECT to_char(pk_schedule_common.g_onlyfreevacs) data,
                           pk_message.get_message(i_lang, pk_schedule_common.g_onlyfreevacsmsg) label,
                           g_no flg_select,
                           9 order_field
                      FROM dual
                     WHERE i_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_cons)
             ORDER BY 4, 2 ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_status);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_status;

    /**
    * Returns a list of schedule cancelation reasons.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      o_actions          list of compatible events
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Ricardo Pinho
    * @version    alpha
    * @since      2006/04/10
    */
    FUNCTION get_cancelation_reasons
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_CANCELATION_REASONS';
        l_count     NUMBER;
    BEGIN
        -- 
        g_error := 'get count';
        SELECT COUNT(1)
          INTO l_count
          FROM sch_cancel_reason cr, sch_cancel_reason_inst scri
         WHERE scri.flg_available = g_yes
           AND scri.id_sch_cancel_reason = cr.id_sch_cancel_reason
           AND scri.id_institution = i_prof.institution
           AND scri.id_software = i_prof.software;
    
        g_error := 'OPEN o_reasons';
        IF l_count > 0
        THEN
            -- havendo configuracao para 
            OPEN o_reasons FOR
                SELECT cr.id_sch_cancel_reason data,
                       pk_translation.get_translation(i_lang, cr.code_cancel_reason) label,
                       NULL flg_select
                  FROM sch_cancel_reason cr, sch_cancel_reason_inst scri
                 WHERE scri.flg_available = g_yes
                   AND scri.id_sch_cancel_reason = cr.id_sch_cancel_reason
                   AND scri.id_institution = i_prof.institution
                   AND scri.id_software = i_prof.software
                 ORDER BY label;
        ELSE
            OPEN o_reasons FOR
                SELECT cr.id_sch_cancel_reason data,
                       pk_translation.get_translation(i_lang, cr.code_cancel_reason) label,
                       NULL flg_select
                  FROM sch_cancel_reason cr, sch_cancel_reason_inst scri
                 WHERE scri.flg_available = g_yes
                   AND scri.id_sch_cancel_reason = cr.id_sch_cancel_reason
                   AND scri.id_institution = 0
                   AND scri.id_software = 0
                 ORDER BY label;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_cancelation_reasons;

    /**
    * Returns description of a cancel reason
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_can_reason       id cancel reason
    * @param      o_desc             output
    * @param      o_error            error info
    *
    * @return     "False" on error or "True" if success
    * @author     Telmo
    * @version    2.5
    * @since      30-04-2009
    */
    FUNCTION get_cancelation_reason
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_can_reason IN sch_cancel_reason.id_sch_cancel_reason% TYPE,
        o_desc       OUT pk_translation.t_desc_translation,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_CANCELATION_REASON';
    BEGIN
        g_error := 'GET TRANSLATION';
        SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
          INTO o_desc
          FROM sch_cancel_reason cr
         WHERE cr.id_sch_cancel_reason = i_can_reason;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_cancelation_reason;

    /**
    * Returns a list of rooms.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_id_dep           Department(s)
    * @param      i_flg_search       Whether or not should the 'All' value be shown
    * @param      o_rooms            Rooms
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Ricardo Pinho)
    * @version    alpha
    * @since      2007/04/26
    */
    FUNCTION get_rooms
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_dep     IN VARCHAR2,
        i_flg_search IN VARCHAR2,
        o_rooms      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_ROOMS';
        l_list_deps table_number := get_list_number_csv(i_id_dep);
    BEGIN
        l_func_name := 'GET_ROOMS';
        g_error     := 'OPEN o_rooms';
        OPEN o_rooms FOR
            SELECT id_room data, desc_room label, g_no flg_select, order_field
              FROM (SELECT g_all id_room,
                           pk_message.get_message(i_lang, g_msg_all) desc_room,
                           g_no flg_select,
                           1 order_field
                      FROM dual
                     WHERE i_flg_search = g_yes
                    UNION ALL
                    SELECT id_room, desc_room, flg_select, order_field
                      FROM (SELECT r.id_room,
                                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                                   g_no flg_select,
                                   9 order_field
                              FROM room r
                             WHERE r.id_department IN (SELECT *
                                                         FROM TABLE(l_list_deps))
                               AND r.flg_available = g_yes)
                     WHERE desc_room IS NOT NULL)
             ORDER BY order_field, label;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rooms);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_rooms;

    /**
    * Returns a list of durations.
    *
    * @param i_lang               Language.
    * @param i_prof               Professional.
    * @param i_flg_search         Whether or not should the 'All' option be returned within the o_durations cursor.
    * @param o_durations          List of durations.
    * @param o_error              Error message (if an error has occurred).
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/04/30
    */
    FUNCTION get_durations
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_search IN VARCHAR2,
        o_durations  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DURATIONS';
    BEGIN
        g_error := 'OPEN o_durations FOR';
        OPEN o_durations FOR
            SELECT data, label, flg_select, order_field
              FROM (SELECT g_all data, pk_message.get_message(i_lang, g_msg_all) label, g_no flg_select, 1 order_field
                      FROM dual
                     WHERE i_flg_search = g_yes
                    UNION ALL
                    -- Get distinct durations from existing schedules
                    SELECT DISTINCT diff data,
                                    string_duration(i_lang, dt_begin_tstz, dt_end_tstz) label,
                                    g_no flg_select,
                                    9 order_field
                      FROM (SELECT s.dt_end_tstz,
                                   s.dt_begin_tstz,
                                   trunc(pk_date_utils.get_timestamp_diff(dt_end_tstz, dt_begin_tstz), g_max_decimal_prec) diff
                              FROM schedule s
                             WHERE s.dt_end_tstz IS NOT NULL
                               AND s.dt_begin_tstz IS NOT NULL
                               AND pk_date_utils.get_timestamp_diff(dt_end_tstz, dt_begin_tstz) > 0))
             ORDER BY order_field, data, label ASC;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_durations);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_durations;

    /**
    * Returns a list of schedule reasons.
    *
    * @param      i_lang                 Language
    * @param      i_prof                 Professional
    * @param      i_id_dep_clin_serv     Department-clinical service
    * @param      i_id_patient           Patient
    * @param      i_flg_search           Whether or not should the 'All' option be returned in o_reasons cursor.
    * @param      o_reasons              Schedule reasons
    * @param      o_error                Error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/04/27
    *
    * UPDATED
    * added COMPLAINTDOCTOR_T012 in result
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    25-09-2008 
    *
    * UPDATED
    * RemoÁ„o de SQL dinamico. Simplificacao de funcao
    * @author   Jose Antunes
    * @version  2.4.3.x
    * @date     23-10-2008  
    */
    FUNCTION get_reasons
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN VARCHAR2,
        i_id_patient       IN patient.id_patient%TYPE,
        i_flg_search       IN VARCHAR2,
        o_reasons          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_REASONS';
        l_gender    patient.gender%TYPE;
        l_age       NUMBER(3);
        l_id_dcs    table_number;
    BEGIN
        BEGIN
            g_error := 'GET PATIENT AGE AND GENDER';
            -- Get patient age and gender
            SELECT gender, months_between(current_timestamp, dt_birth) / 12 age
              INTO l_gender, l_age
              FROM patient
             WHERE id_patient = i_id_patient;
        EXCEPTION
            WHEN no_data_found THEN
                l_age    := NULL;
                l_gender := NULL;
        END;
    
        g_error  := 'CREATE TABLE DCS';
        l_id_dcs := pk_schedule.get_list_number_csv(i_id_dep_clin_serv);
    
        g_error := 'SELECT';
        OPEN o_reasons FOR
            SELECT data, label, flg_select, order_field
              FROM (SELECT g_all data, pk_message.get_message(i_lang, g_msg_all) label, g_no flg_select, 1 order_field
                      FROM dual
                     WHERE i_flg_search = g_yes
                    UNION
                    SELECT -1 data,
                           pk_message.get_message(i_lang, 'COMPLAINTDOCTOR_T012') label,
                           g_no flg_select,
                           2 order_field
                      FROM dual
                    UNION
                    SELECT st.id_sample_text data, --t.desc_translation label, 
                           pk_translation.get_translation(i_lang, st.code_title_sample_text) label,
                           g_no flg_select,
                           9 order_field
                      FROM sample_text_type stt, sample_text st, sample_text_soft_inst stsi --, translation t
                     WHERE upper(stt.intern_name_sample_text_type) = upper(g_complaint_sample_text_type)
                       AND stsi.id_software = i_prof.software
                       AND stsi.id_institution = i_prof.institution
                       AND stsi.id_sample_text_type = stt.id_sample_text_type
                       AND st.flg_available = stt.flg_available
                       AND stsi.flg_available = g_yes
                       AND st.flg_available = g_yes
                       AND stsi.id_sample_text = st.id_sample_text
                          
                       AND pk_translation.get_translation(i_lang, st.code_title_sample_text) IS NOT NULL
                       AND ((l_age IS NULL AND l_gender IS NULL) OR
                            (l_age IS NOT NULL OR
                            l_gender IS NOT NULL AND
                            ((nvl(st.gender, pk_schedule.g_gender_undefined) IN
                            (pk_schedule.g_gender_undefined, l_gender)) OR l_gender = pk_schedule.g_gender_undefined) AND
                            (nvl(l_age, 0) BETWEEN nvl(st.age_min, 0) AND nvl(st.age_max, nvl(l_age, 0)) OR
                            nvl(l_age, 0) = 0))))
             ORDER BY order_field, label ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_reasons;

    /*
    * Returns the number of unplanned schedules for a given vacancy.
    * To be used inside a SELECT statement
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_args                   UI search arguments.
    * @param i_id_sch_vacancy         Vacancy
    *
    * @return     Number of unplanned schedules.
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/05/07
    */
    FUNCTION get_unplanned_sch_count
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_args           IN table_varchar,
        i_id_sch_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE
    ) RETURN NUMBER IS
        l_list_schedules table_number;
        l_count          NUMBER := 0;
        l_func_name      VARCHAR2(32) := 'GET_UNPLANNED_SCH_COUNT';
        l_dummy          t_error_out;
    BEGIN
        g_error := 'CALL GET_SCHEDULES_FOR_VACANCY';
        IF NOT pk_schedule_common.get_schedules_for_vacancy(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_id_sch_vacancy => i_id_sch_vacancy,
                                                            i_args           => i_args,
                                                            o_schedules      => l_list_schedules,
                                                            o_error          => l_dummy)
        THEN
            -- Logging was already performed by get_schedules_for_vacancy.
            RETURN 0;
        END IF;
    
        g_error := 'COUNT SCHEDULES';
        SELECT /*+ first_rows */
         COUNT(1)
          INTO l_count
          FROM schedule s
         WHERE s.id_schedule IN (SELECT *
                                   FROM TABLE(l_list_schedules))
           AND s.flg_vacancy = pk_schedule_common.g_sched_vacancy_unplanned
           AND s.flg_status <> g_sched_status_cancelled;
        RETURN l_count;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN 0;
    END get_unplanned_sch_count;

    /**
    * This function returns the availability for each day on a given period.
    * Each day can be fully scheduled, half scheduled or empty.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                Arguments.
    * @param i_id_patient          Patient.
    * @param i_semester            Whether or not this function is being called to fill the semester calendar.
    * @param o_days_status         List of status per date.
    * @param o_days_date           List of dates.
    * @param o_days_free           List of total free slots per date.
    * @param o_days_sched          List of total schedules per date.
    * @param o_days_conflicts      List of total conflicting appointments per date.
    * @param o_patient_icons       Patient icons for showing the days when the patient has schedules.
    * @param o_dcs_availability     Availability for each day and DCS (for the first N DCSs of the day).
    * @param o_error               Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/26
    *
    * UPDATED
    * ALERT-708 - pesquisa por vagas livres.
    * @author   Telmo Castro
    * @date     25-03-2009
    * @version  2.5
    *
    * UPDATED
    * ALERT-31987 - output da get_vacancies passa a ser a GTT sch_tmptab_vacs em vez do table_number
    * @author  Telmo
    * @date    12-06-2009
    * @version 2.5.0.4
    */
    FUNCTION get_availability
    (
        i_lang             IN language.id_language%TYPE DEFAULT NULL,
        i_prof             IN profissional,
        i_args             IN table_varchar,
        i_id_patient       IN patient.id_patient%TYPE,
        i_semester         IN VARCHAR2,
        o_days_status      OUT table_varchar,
        o_days_date        OUT table_varchar,
        o_days_free        OUT table_number,
        o_days_sched       OUT table_number,
        o_dcs_availability OUT pk_types.cursor_type,
        o_days_conflicts   OUT table_number,
        o_patient_icons    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := 'GET_AVAILABILITY';
        l_use_colors       sys_config.value%TYPE;
        l_max_colors       sys_config.value%TYPE;
        l_schedules        table_number;
        l_dates            table_timestamp_tz := table_timestamp_tz();
        l_dates_str        table_varchar := table_varchar();
        l_pos              NUMBER := 0;
        l_start_date_aux   DATE;
        l_start_date_orig  TIMESTAMP WITH TIME ZONE;
        l_start_date       TIMESTAMP WITH TIME ZONE;
        l_end_date         TIMESTAMP WITH TIME ZONE;
        l_start_date_trunc TIMESTAMP WITH TIME ZONE;
        l_start_date_add   TIMESTAMP WITH TIME ZONE;
        l_list_status      table_varchar;
        i                  INTEGER;
        l_only_vacs        VARCHAR2(1) := g_no;
    
        -- Available Vacancies and booked schedules. (Semester version)
        CURSOR c_vacants_semester IS
            SELECT /*+ first_rows */
             pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
             CASE
                  WHEN vacancies = 0
                       AND used = 0 THEN
                   g_day_status_void
                  WHEN used = 0
                       AND vacancies > 0 THEN
                   g_day_status_empty
                  WHEN vacancies > used THEN
                   g_day_status_half
                  WHEN vacancies = used
                       AND used > 0 THEN
                   g_day_status_full
                  ELSE
                   g_day_status_void
              END status
              FROM (SELECT stv.dt_begin_trunc dt_begin_tstz,
                           SUM(stv.used_vacancies) used,
                           SUM(stv.max_vacancies) vacancies
                      FROM sch_tmptab_vacs stv
                     GROUP BY stv.dt_begin_trunc)
             ORDER BY dt_begin;
    
        l_args table_varchar := i_args;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_VACANCIES';
        -- Get vacancies that match the given criteria
        IF NOT
            pk_schedule_common.get_vacancies(i_lang => i_lang, i_prof => i_prof, i_args => l_args, o_error => o_error)
        THEN
            pk_types.open_my_cursor(o_dcs_availability);
            pk_types.open_my_cursor(o_patient_icons);
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        IF i_semester = g_no
        THEN
            -- Monthly view        
            g_error := 'GET TRUNCATED START DATE';
            -- Get start date 
            IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => l_args(idx_dt_begin),
                                                       o_timestamp => l_start_date,
                                                       o_error     => o_error)
            THEN
                pk_types.open_my_cursor(o_dcs_availability);
                pk_types.open_my_cursor(o_patient_icons);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            l_start_date_orig := l_start_date;
        
            g_error := 'GET TRUNCATED END DATE';
            -- Get start and end dates           
            IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => l_args(idx_dt_end),
                                                       o_timestamp => l_end_date,
                                                       o_error     => o_error)
            THEN
                pk_types.open_my_cursor(o_dcs_availability);
                pk_types.open_my_cursor(o_patient_icons);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            -- Use dates to generate string representations
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
                l_dates_str(l_pos) := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
                l_start_date_add := pk_date_utils.add_days_to_tstz(l_start_date, 1);
                --
                IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_timestamp => pk_date_utils.date_send_tsz(i_lang,
                                                                                                      l_start_date_add,
                                                                                                      i_prof),
                                                           o_timestamp => l_start_date_trunc,
                                                           o_error     => o_error)
                THEN
                    pk_types.open_my_cursor(o_dcs_availability);
                    pk_types.open_my_cursor(o_patient_icons);
                    pk_date_utils.set_dst_time_check_on;
                    RETURN FALSE;
                END IF;
            
                IF (l_start_date_trunc <> l_start_date)
                THEN
                    l_start_date := l_start_date_trunc;
                ELSE
                    --due to DST changes it is required to increment the date to the next day
                    l_start_date_add := pk_date_utils.add_days_to_tstz(l_start_date_add, 1);
                    IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_timestamp => pk_date_utils.date_send_tsz(i_lang,
                                                                                                          l_start_date_add,
                                                                                                          i_prof),
                                                               o_timestamp => l_start_date,
                                                               o_error     => o_error)
                    THEN
                        pk_types.open_my_cursor(o_dcs_availability);
                        pk_types.open_my_cursor(o_patient_icons);
                        pk_date_utils.set_dst_time_check_on;
                        RETURN FALSE;
                    END IF;
                END IF;
                --
            
                l_start_date_aux := l_start_date_aux + 1;
            END LOOP;
        
            -- DCS Colors
            g_error := 'GET DCS COLOR USAGE';
            -- Check if DCS colors are used
            IF NOT get_config(i_lang         => i_lang,
                              i_id_sysconfig => g_config_use_dcs_colors,
                              i_prof         => i_prof,
                              o_config       => l_use_colors,
                              o_error        => o_error)
            THEN
                pk_types.open_my_cursor(o_dcs_availability);
                pk_types.open_my_cursor(o_patient_icons);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            IF l_use_colors = g_yes
            THEN
                g_error := 'GET MAX DCS COLORS';
                -- Get maximum renderable DCS colors
                IF NOT get_config(i_lang         => i_lang,
                                  i_id_sysconfig => g_config_max_dcs_colors,
                                  i_prof         => i_prof,
                                  o_config       => l_max_colors,
                                  o_error        => o_error)
                THEN
                    pk_types.open_my_cursor(o_dcs_availability);
                    pk_types.open_my_cursor(o_patient_icons);
                    pk_date_utils.set_dst_time_check_on;
                    RETURN FALSE;
                END IF;
            
                g_error := 'OPEN o_dcs_availability';
                -- Get DCS availability per day
                OPEN o_dcs_availability FOR
                    SELECT /*+first_rows */
                     pk_date_utils.date_send_tsz(i_lang, dt_begin, i_prof) dt_begin,
                     id_dep_clin_serv,
                     CASE
                          WHEN vacancies > used THEN
                           g_day_status_empty
                          WHEN vacancies = used
                               AND used > 0 THEN
                           g_day_status_full
                          ELSE
                           g_day_status_void
                      END status
                      FROM (SELECT dt_begin,
                                   id_dep_clin_serv,
                                   vacancies,
                                   used,
                                   row_number() over(PARTITION BY dt_begin ORDER BY id_dep_clin_serv) rn
                              FROM (SELECT stv.dt_begin_trunc dt_begin,
                                           scv.id_dep_clin_serv,
                                           SUM(scv.max_vacancies) vacancies,
                                           SUM(scv.used_vacancies) used
                                      FROM sch_consult_vacancy scv
                                      JOIN sch_tmptab_vacs stv
                                        ON scv.id_sch_consult_vacancy = stv.id_sch_consult_vacancy
                                     WHERE scv.dt_begin_tstz <= l_end_date
                                       AND scv.dt_begin_tstz >= l_start_date_orig
                                     GROUP BY stv.dt_begin_trunc, scv.id_dep_clin_serv)
                            
                            )
                     WHERE rn <= to_number(l_max_colors)
                     ORDER BY dt_begin, id_dep_clin_serv;
            ELSE
                g_error := 'CALL OPEN_MY_CURSOR';
                pk_types.open_my_cursor(o_dcs_availability);
            END IF;
        
            g_error := 'CALL GET_SCHEDULES';
            -- Get schedules' identifiers using the selected criteria.
            IF get_only_vacs(i_args(idx_status)) = g_yes
            THEN
                l_schedules := table_number();
            ELSE
                IF NOT pk_schedule_common.get_schedules(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_patient => NULL,
                                                        i_args       => l_args,
                                                        o_schedules  => l_schedules,
                                                        o_error      => o_error)
                THEN
                    pk_types.open_my_cursor(o_patient_icons);
                    pk_date_utils.set_dst_time_check_on;
                    RETURN FALSE;
                END IF;
            END IF;
        
            g_error := 'CALL CALCULATE_MONTH_AVAILABILITY';
            -- Calculate month availability
            pk_date_utils.set_dst_time_check_off;
            IF NOT calculate_month_availability(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_mult           => FALSE,
                                                i_list_schedules => l_schedules,
                                                i_list_dates     => l_dates,
                                                i_list_dates_str => l_dates_str,
                                                i_events         => i_args(idx_event),
                                                o_days_date      => o_days_date,
                                                o_days_status    => o_days_status,
                                                o_days_free      => o_days_free,
                                                o_days_sched     => o_days_sched,
                                                o_days_conflicts => o_days_conflicts,
                                                o_error          => o_error)
            THEN
                pk_types.open_my_cursor(o_patient_icons);
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
            pk_date_utils.set_dst_time_check_on;
        ELSE
            -- Semester calendar
            g_error := 'OPEN c_vacants_semester';
            OPEN c_vacants_semester;
            -- Fetch dates and status per date.
            g_error := 'FETCH c_vacants_semester';
            FETCH c_vacants_semester BULK COLLECT
                INTO o_days_date, o_days_status;
        
            g_error := 'CLOSE c_vacants_semester';
            CLOSE c_vacants_semester;
        
            g_error := 'CALL OPEN_MY_CURSOR SEMESTER';
            pk_types.open_my_cursor(o_dcs_availability);
        END IF;
    
        g_error := 'CALL GET_PATIENT_ICONS';
        -- Get patient icons.
        pk_date_utils.set_dst_time_check_off;
        IF NOT (get_patient_icons(i_lang          => i_lang,
                                  i_prof          => i_prof,
                                  i_args          => l_args,
                                  i_id_patient    => i_id_patient,
                                  o_patient_icons => o_patient_icons,
                                  o_error         => o_error))
        THEN
            pk_types.open_my_cursor(o_patient_icons);
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        ELSE
            pk_date_utils.set_dst_time_check_on;
            RETURN TRUE;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_types.open_my_cursor(o_patient_icons);
            pk_types.open_my_cursor(o_dcs_availability);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        
    END get_availability;

    /**
    * This function returns the availability for each day on a given period.
    * For that, it considers one or more lists of search criteria.
    * Each day can be fully scheduled, half scheduled or empty.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                UI search criteria matrix (each element represent a search criteria set).
    * @param i_id_patient          Patient.
    * @param o_days_status         List of status per date.
    * @param o_days_date           List of dates.
    * @param o_days_free           List of total free slots per date.
    * @param o_days_sched          List of total schedules per date.
    * @param o_patient_icons       Patient icons for showing the days when the patient has schedules.
    * @param o_error               Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/07/19
    *
    * UPDATED 
    * ALERT-28024 - media das vacancies passou a ser a sch_tmptab_full_vacs em vez da table_number
    * @author   Telmo
    * @date     18-06-2009
    * @version  2.5.0.4
    */
    FUNCTION get_availability_mult
    (
        i_lang          IN language.id_language%TYPE DEFAULT NULL,
        i_prof          IN profissional,
        i_args          IN table_table_varchar,
        i_id_patient    IN patient.id_patient%TYPE,
        o_days_status   OUT table_varchar,
        o_days_date     OUT table_varchar,
        o_days_free     OUT table_number,
        o_days_sched    OUT table_number,
        o_patient_icons OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_args           table_varchar;
        l_schedules      table_number;
        l_days_conflicts table_number;
        l_dates          table_timestamp_tz := table_timestamp_tz();
        l_pos            NUMBER := 0;
        l_start_date     TIMESTAMP WITH TIME ZONE;
        l_end_date       TIMESTAMP WITH TIME ZONE;
        l_dates_str      table_varchar := table_varchar();
        l_start_date_aux DATE;
    
        l_func_name VARCHAR2(32) := 'GET_AVAILABILITY_MULT';
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'START';
        IF i_args IS NOT NULL
           AND i_args.count > 0
        THEN
        
            -- clean workbench
            g_error := 'TRUNCATE TABLE SCH_TMPTAB_FULL_VACS';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_FULL_VACS';
        
            g_error := 'CALL GET_VAC_AND_SCH_MULT';
            -- Get vacancies and schedules that match the each of the criteria sets, on the
            -- dates that match all the criteria sets.
            IF NOT pk_schedule_common.get_vac_and_sch_mult(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_args       => i_args,
                                                           i_id_patient => NULL,
                                                           o_schedules  => l_schedules,
                                                           o_error      => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            g_error := 'GET TRUNCATED START DATE';
            -- Get start date
            IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => i_args(1) (idx_dt_begin),
                                                       o_timestamp => l_start_date,
                                                       o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            g_error := 'GET TRUNCATED END DATE';
            -- Get start and end dates
            IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => i_args(1) (idx_dt_end),
                                                       o_timestamp => l_end_date,
                                                       o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
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
                                           i_vacancies => NULL,
                                           i_fulltable => g_yes,
                                           o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            --aqui truncar a sch_tmptab_vacs e copiar para la o conteudo sch_tmptab_full_vacs
            -- isto porque a calculate_month_avail trabalha com a sch_tmptab_vacs
            g_error := 'TRUNCATE VACANCIES TEMPORARY TABLE';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_VACS';
        
            g_error := 'COPY DATA FROM SCH_TMPTAB_FULL_VACS TO SCH_TMPTAB_VACS';
            INSERT INTO sch_tmptab_vacs
                (id_sch_consult_vacancy, dt_begin_trunc, max_vacancies, used_vacancies)
                SELECT id_sch_consult_vacancy, dt_begin_trunc, max_vacancies, used_vacancies
                  FROM sch_tmptab_full_vacs;
        
            g_error := 'CALL CALCULATE_MONTH_AVAILABILITY';
            -- Calculate month availability
            IF NOT calculate_month_availability(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_mult           => TRUE,
                                                i_list_schedules => l_schedules,
                                                i_list_dates     => l_dates,
                                                i_list_dates_str => l_dates_str,
                                                o_days_date      => o_days_date,
                                                o_days_status    => o_days_status,
                                                o_days_free      => o_days_free,
                                                o_days_sched     => o_days_sched,
                                                o_days_conflicts => l_days_conflicts,
                                                o_error          => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            IF i_args IS NOT NULL
               AND i_args.count > 0
            THEN
                g_error := 'CALL GET_PATIENT_ICONS';
                -- Get patient icons, which do not depend on the search criteria sets, but only on the date.
                IF NOT (get_patient_icons(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_args          => i_args(1),
                                          i_id_patient    => i_id_patient,
                                          o_patient_icons => o_patient_icons,
                                          o_error         => o_error))
                THEN
                    pk_date_utils.set_dst_time_check_on;
                    RETURN FALSE;
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
            pk_date_utils.set_dst_time_check_on;
            -- Unexpected error
            pk_types.open_my_cursor(o_patient_icons);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_availability_mult;

    /*
    * Returns the vacancies on a predefined range of days.
    *
    * @param i_lang         Language Identifier
    * @param i_prof         Professional
    * @param i_args         UI Arguments (includes: event, start date (single), institution, department-clinical service and professional lists)
    * @param i_id_event     Table of schedule events
    * @param o_values       Return values
    * @param o_error        Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/30
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    *
    * UDPDATED
    * added MFR scheduler case. Parameter i_args has a new index (9) for physiatry areas.
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     12-01-2009
    *
    * UDPDATED
    * table of id events removed from i_args and added in new parameter to prevent error 
    * @author   Jose Antunes
    * @version  2.5
    * @date     15-05-2009
    *
    * UDPDATED
    * removed i_args 
    * @author   Jose Antunes
    * @version  2.5
    * @date     15-05-2009
    */
    FUNCTION get_proximity_vacants
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_event       IN table_number,
        i_dt_vacant      IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_dcs         IN table_number,
        i_id_prof        IN table_number,
        i_id_exam        IN table_number,
        i_id_analysis    IN table_number, -- not needed yet
        i_id_dep         IN department.id_department%TYPE,
        i_id_physareas   IN table_number,
        o_values         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i_args2            table_varchar := table_varchar(9);
        l_string_events    VARCHAR2(4000);
        l_string_dcs       VARCHAR2(32000);
        l_string_profs     VARCHAR2(32000);
        l_string_exams     VARCHAR2(32000);
        l_string_analysis  VARCHAR2(200);
        l_string_physareas VARCHAR2(200);
        l_func_name        VARCHAR2(32) := 'GET_PROXIMITY_VACANTS';
    
    BEGIN
    
        IF (i_id_event IS NOT NULL AND i_id_event.count > 0)
        THEN
            FOR i IN 1 .. i_id_event.count
            LOOP
                IF l_string_events IS NULL
                THEN
                    l_string_events := i_id_event(1);
                ELSE
                    l_string_events := l_string_events || ',' || i_id_event(i);
                END IF;
            END LOOP;
        END IF;
        IF (i_id_dcs IS NOT NULL AND i_id_dcs.count > 0)
        THEN
            FOR i IN 1 .. i_id_dcs.count
            LOOP
                IF l_string_dcs IS NULL
                THEN
                    l_string_dcs := i_id_dcs(1);
                ELSE
                    l_string_dcs := l_string_dcs || ',' || i_id_dcs(i);
                END IF;
            END LOOP;
        END IF;
        IF (i_id_prof IS NOT NULL AND i_id_prof.count > 0)
        THEN
            FOR i IN 1 .. i_id_prof.count
            LOOP
                IF l_string_profs IS NULL
                THEN
                    l_string_profs := i_id_prof(1);
                ELSE
                    l_string_profs := l_string_profs || ',' || i_id_prof(i);
                END IF;
            END LOOP;
        END IF;
        IF (i_id_exam IS NOT NULL AND i_id_exam.count > 0)
        THEN
            FOR i IN 1 .. i_id_exam.count
            LOOP
                IF l_string_exams IS NULL
                THEN
                    l_string_exams := i_id_exam(1);
                ELSE
                    l_string_exams := l_string_exams || ',' || i_id_exam(i);
                END IF;
            END LOOP;
        END IF;
        IF (i_id_analysis IS NOT NULL AND i_id_analysis.count > 0)
        THEN
            FOR i IN 1 .. i_id_analysis.count
            LOOP
                IF l_string_analysis IS NULL
                THEN
                    l_string_analysis := i_id_analysis(1);
                ELSE
                    l_string_analysis := l_string_analysis || ',' || i_id_analysis(i);
                END IF;
            END LOOP;
        END IF;
        IF (i_id_physareas IS NOT NULL AND i_id_physareas.count > 0)
        THEN
            FOR i IN 1 .. i_id_physareas.count
            LOOP
                IF l_string_physareas IS NULL
                THEN
                    l_string_physareas := i_id_physareas(1);
                ELSE
                    l_string_physareas := l_string_physareas || ',' || i_id_physareas(i);
                END IF;
            END LOOP;
        END IF;
    
        i_args2.extend();
        i_args2(1) := i_id_patient;
        i_args2.extend();
        i_args2(2) := l_string_events;
        i_args2.extend();
        i_args2(3) := i_dt_vacant;
        i_args2.extend();
        i_args2(4) := i_id_institution;
        i_args2.extend();
        i_args2(5) := l_string_dcs;
        i_args2.extend();
        i_args2(6) := l_string_profs;
        i_args2.extend();
        i_args2(7) := l_string_exams;
        i_args2.extend();
        i_args2(8) := i_id_dep;
        i_args2.extend();
        i_args2(9) := l_string_physareas;
    
        IF NOT get_proximity_vacants(i_lang   => i_lang,
                                     i_prof   => i_prof,
                                     i_args   => i_args2,
                                     o_values => o_values,
                                     o_error  => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_values);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_proximity_vacants;

    /*
    * Returns the vacancies on a predefined range of days.
    *
    * @param i_lang         Language Identifier
    * @param i_prof         Professional
    * @param i_args         UI Arguments (includes: event, start date (single), institution, department-clinical service and professional lists)
    * @param o_values       Return values
    * @param o_error        Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/30
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    *
    * UDPDATED
    * added MFR scheduler case. Parameter i_args has a new index (9) for physiatry areas.
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     12-01-2009
    *
    * UPDATED
    * alert-54025 performance improvement
    * @author   Telmo Castro
    * @version  2.5.0.7
    * @date     03-11-2009    
    */
    FUNCTION get_proximity_vacants
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_args   IN table_varchar,
        o_values OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_config           sys_config.id_sys_config%TYPE := 'SCH_RANGE_PROXIMITY_VACANTS';
        l_domain           sys_domain.code_domain%TYPE := g_schedule_status_pat_sch;
        l_days_range       NUMBER(24);
        l_dt_begin         TIMESTAMP WITH TIME ZONE;
        l_dt_end           TIMESTAMP WITH TIME ZONE;
        l_dt_target        TIMESTAMP WITH TIME ZONE;
        l_dt_trunc_curr    TIMESTAMP WITH TIME ZONE;
        l_id_event         VARCHAR2(4000);
        l_id_patient       VARCHAR2(4000);
        l_id_institution   VARCHAR2(4000);
        l_id_prof          VARCHAR2(32000);
        l_id_dep_clin_serv VARCHAR2(32000);
        l_id_exam          VARCHAR2(32000);
        l_id_analysis      VARCHAR2(4000);
        l_dt_vacants       VARCHAR2(4000);
        l_id_dep           VARCHAR2(4000);
        l_id_physarea      VARCHAR2(4000);
        l_func_name        VARCHAR2(32) := 'GET_PROXIMITY_VACANTS';
        l_list_event       table_number;
        l_list_prof        table_number;
        l_list_dcs         table_number;
        l_list_exams       table_number;
        l_list_analysis    table_number;
        l_list_physareas   table_number;
        l_num_records      NUMBER(4);
    BEGIN
        -- Get proximity range
        g_error := 'GET ' || l_config || ' FROM SYS_CONFIG';
        IF NOT (pk_sysconfig.get_config(l_config, i_prof, l_days_range))
           OR l_days_range IS NULL
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Null or inexistent ' || l_config || ' on SYS_CONFIG',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        END IF;
    
        g_error := g_sch_max_rec_vacants;
        IF NOT (get_config(i_lang         => i_lang,
                           i_id_sysconfig => g_sch_max_rec_vacants,
                           i_prof         => i_prof,
                           o_config       => l_config,
                           o_error        => o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        l_num_records := to_number(l_config);
    
        g_error := 'GET ARGUMENTS';
        -- Get arguments
        l_id_patient       := i_args(1); -- Patient identification
        l_id_event         := i_args(2); -- Event type list
        l_dt_vacants       := i_args(3); -- Start vacant date
        l_id_institution   := i_args(4); -- Institution
        l_id_dep_clin_serv := i_args(5); -- Department - Clinical service
        l_id_prof          := i_args(6); -- Professionals list
        l_id_exam          := i_args(7); -- Exam list
        l_id_analysis      := i_args(7); -- Analysis list
        l_id_dep           := i_args(8); -- Department
    
        -- MFR Schedule:  physiatry areas
        IF i_args.exists(9)
        THEN
            l_id_physarea := i_args(9); -- physiatry areas
        END IF;
    
        -- Get lists
        g_error          := 'GET LISTS';
        l_list_event     := get_list_number_csv(l_id_event);
        l_list_prof      := get_list_number_csv(l_id_prof);
        l_list_dcs       := get_list_number_csv(l_id_dep_clin_serv);
        l_list_exams     := get_list_number_csv(l_id_exam);
        l_list_analysis  := get_list_number_csv(l_id_analysis);
        l_list_physareas := get_list_number_csv(l_id_physarea);
    
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_TIMESTAMP_INSTTIMEZONE';
        -- Get the current timestamp at the preferred time zone
        IF NOT pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                        i_inst      => i_prof.institution,
                                                        i_timestamp => current_timestamp,
                                                        o_timestamp => l_dt_trunc_curr,
                                                        o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- Set a default date and range if no data is given.
        g_error := 'GET DEFAULT DATE AND RANGE';
        IF l_dt_vacants IS NULL
        THEN
            l_dt_target  := l_dt_trunc_curr;
            l_days_range := g_range_days_default;
        ELSE
            g_error := 'CALL GET_STRING_TSTZ';
            -- Convert to timestamp
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => l_dt_vacants,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_target,
                                                 o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'TRUNCATE TARGET';
        -- Truncate target date
        IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_timestamp => l_dt_target,
                                                o_timestamp => l_dt_target,
                                                o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- Get begin and end dates.
        g_error    := 'GET begin AND end DATES';
        l_dt_begin := l_dt_target;
        --         pk_date_utils.add_days_to_tstz(l_dt_target, -l_days_range);
        l_dt_end := pk_date_utils.add_days_to_tstz(l_dt_target, l_days_range);
    
        -- Open cursor
        g_error := 'OPEN o_values FOR';
        OPEN o_values FOR
            SELECT *
              FROM (SELECT CASE
                                WHEN rcount > l_num_records THEN
                                 g_yes
                                ELSE
                                 g_no
                            END flg_max_rec,
                           pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                           decode(sch_dt_begin_tstz, NULL, g_no, g_yes) flg_scheduled,
                           string_date(i_lang, i_prof, dt_begin_tstz) desc_dt_begin,
                           pk_date_utils.to_char_insttimezone(i_prof, dt_begin_tstz, g_default_time_mask_msg) hour_begin,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof) nick_prof,
                           string_duration(i_lang, dt_begin_tstz, dt_end_tstz) duration,
                           -- Icons
                           decode(sch_dt_begin_tstz,
                                  NULL,
                                  g_icon_prefix || pk_sysdomain.get_img(i_lang, l_domain, g_status_without_schedule),
                                  g_icon_prefix ||
                                  pk_sysdomain.get_img(i_lang,
                                                       l_domain,
                                                       get_image_name(i_lang, i_prof, l_domain, id_schedule))) img_scheduled,
                           id_prof,
                           id_dep_clin_serv,
                           id_sch_event
                      FROM (SELECT scv.id_sch_consult_vacancy,
                                   scv.dt_begin_tstz,
                                   scv.dt_end_tstz,
                                   scheduled.dt_begin_tstz sch_dt_begin_tstz,
                                   scv.id_prof,
                                   scheduled.id_schedule,
                                   scv.id_dep_clin_serv,
                                   scv.id_sch_event,
                                   COUNT(1) over(PARTITION BY 1 ORDER BY 1) rcount
                              FROM (SELECT /*+no_merge */
                                     *
                                      FROM sch_consult_vacancy scv
                                     WHERE (l_id_prof IS NULL OR
                                           scv.id_prof IN (SELECT /*+cardinality(t 1)*/
                                                             *
                                                              FROM TABLE(l_list_prof) t))
                                       AND (l_id_dep_clin_serv IS NULL OR
                                           scv.id_dep_clin_serv IN (SELECT /*+cardinality(t 1)*/
                                                                      *
                                                                       FROM TABLE(l_list_dcs) t))
                                       AND id_institution = l_id_institution
                                       AND flg_status = pk_schedule_bo.g_status_active
                                       AND scv.dt_begin_tstz >= least(l_dt_begin, l_dt_trunc_curr)) scv,
                                   sch_event se,
                                   sch_department sd,
                                   -- Patient's schedules
                                     (SELECT pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz) dt_begin_tstz,
                                             s.id_schedule
                                        FROM schedule s, sch_group sg
                                       WHERE s.dt_begin_tstz >= l_dt_begin
                                         AND s.dt_begin_tstz < l_dt_end
                                         AND s.dt_begin_tstz >= l_dt_trunc_curr
                                         AND ((l_id_event IS NULL AND
                                             s.id_sch_event IN (SELECT id_sch_event
                                                                    FROM sch_event)) OR
                                             s.id_sch_event IN
                                             (SELECT *
                                                 FROM TABLE(CAST(l_list_event AS table_number))))
                                         AND sg.id_patient = l_id_patient
                                         AND s.id_schedule = sg.id_schedule
                                         AND s.flg_status = g_status_scheduled
                                         AND s.id_instit_requested = (l_id_institution)
                                         AND (l_id_dep_clin_serv IS NULL OR
                                             s.id_dcs_requested IN
                                             (SELECT *
                                                 FROM TABLE(CAST(l_list_dcs AS table_number))))) scheduled
                               WHERE se.id_sch_event = scv.id_sch_event
                                    -- Filter by a department's events.
                               AND se.dep_type = sd.flg_dep_type
                               AND sd.id_department = to_number(l_id_dep)
                                  -- Dates between range
                               AND (l_dt_end IS NULL OR scv.dt_begin_tstz < l_dt_end)
                                  -- event
                               AND (l_id_event IS NULL OR l_id_event = to_char(g_all) OR
                                   scv.id_sch_event IN
                                   (SELECT *
                                       FROM TABLE(CAST(l_list_event AS table_number))))
                                  -- Try to join dates, to get flg_scheduled
                               AND pk_date_utils.trunc_insttimezone(i_prof, scv.dt_begin_tstz) =
                                   scheduled.dt_begin_tstz(+)
                                  -- Permissions
                               AND EXISTS
                             (SELECT id_prof_agenda, id_sch_event
                                      FROM sch_permission
                                     WHERE id_institution = l_id_institution
                                       AND flg_permission = g_permission_schedule
                                       AND id_prof_agenda IS NOT NULL
                                       AND (scv.id_prof = id_prof_agenda OR
                                           scv.id_prof IS NULL AND scv.id_sch_event = sch_permission.id_sch_event))
                                  -- usable vacancies only
                               AND scv.max_vacancies > scv.used_vacancies
                                  -- Get vacants only for the selected exam, analysis, or for all consults.
                               AND (sd.flg_dep_type IN
                                   (pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                                     pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                                     pk_schedule_common.g_sch_dept_flg_dep_type_nut,
                                     pk_schedule_common.g_sch_dept_flg_dep_type_as) OR
                                   (sd.flg_dep_type IN
                                   (pk_schedule_common.g_sch_dept_flg_dep_type_exam,
                                      pk_schedule_common.g_sch_dept_flg_dep_type_oexams) AND
                                   (l_id_exam IS NULL OR
                                   scv.id_sch_consult_vacancy IN
                                   (SELECT scve.id_sch_consult_vacancy
                                         FROM sch_consult_vac_exam scve
                                        WHERE l_id_exam = to_char(g_all)
                                           OR scve.id_exam IN
                                              (SELECT *
                                                 FROM TABLE(CAST(l_list_exams AS table_number)))))) OR
                                   (sd.flg_dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_anls) OR
                                   (sd.flg_dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm AND
                                   (l_id_physarea IS NULL OR
                                   scv.id_sch_consult_vacancy IN
                                   (SELECT scvms.id_sch_consult_vacancy
                                         FROM sch_consult_vac_mfr_slot scvms
                                        WHERE flg_status = g_slot_status_permanent
                                          AND scvms.dt_begin_tstz >= l_dt_begin
                                          AND (l_dt_end IS NULL OR scvms.dt_begin_tstz < l_dt_end)
                                          AND (l_id_physarea = to_char(g_all) OR
                                              scvms.id_physiatry_area IN
                                              (SELECT *
                                                  FROM TABLE(CAST(l_list_physareas AS table_number))))))))
                             ORDER BY scv.dt_begin_tstz)
                     WHERE is_vacancy_available(id_sch_consult_vacancy) = g_yes
                       AND rownum <= l_num_records);
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_values);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_proximity_vacants;

    PROCEDURE open_my_cursor_events(i_cursor IN OUT c_events) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL data,
                   NULL id_sch_event,
                   NULL label_full,
                   NULL label,
                   NULL flg_select,
                   NULL order_field,
                   NULL order_field2,
                   NULL no_prof
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor_events;
    /*
    * Gets the list of events.
    * @param i_lang               Language.
    * @param i_prof               Professional
    * @param i_id_dep             Department.
    * @param i_flg_search         Whether or not should the events be selected based on its type. (in 'N' cases, the first event is the only one selected).
    * @param i_flg_schedule       Whether or not should the events be filtered considering the professional's permission to schedule
    * @param i_flg_dep_type       Events should be filtered by sch_dep_type because the same department may have events with several sch_dep_type(s)
    * @param o_events             List of events.
    * @param o_error              Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    *
    * UPDATED
    * check of sch_event.flg_available was missing
    * @author  Telmo Castro
    * @date     23-04-2008
    * @version  2.4.3
    *
    * REVISED
    * inclusion of new flag sch_event_dcs.flg_available
    * @author  Telmo Castro
    * @date     24-04-2008
    * @version  2.4.3
    *
    * UPDATED
    * added check of sch_permission.flg_permission
    * @author  Telmo Castro
    * @date    15-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * added i_flg_dep_type
    * @author  LuÌs Gaspar
    * @date    28-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * main query updated to cope with the new possibility of having the same department spread out through several dep_type (see sch_department)
    * @author  Telmo Castro
    * @date    11-07-2008
    * @version 2.4.3
    *
    * UPDATED
    * a tabela sch_event_soft nao traz qualquer vantagem neste momento. Como tem de ser configurada manualmente pode impedir o funcionamento
    * correcto da agenda se determinado software nao estiver associado ao evento pretendido.
    * @author  Telmo Castro
    * @date    17-07-2008
    * @version 2.4.3
    *
    * UPDATED
    * added i_flg_event_def and i_flg_prof
    * @author  Jose Antunes
    * @date    27-08-2008
    * @version 2.4.3
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.3.x
    *
    * UPDATED
    * RemoÁ„o de SQL dinamico. Simplificacao de funcao
    * @author   Jose Antunes
    * @version  2.4.3.x
    * @date     17-10-2008
    *
    *
    * UPDATED
    * use the department institution instead of the i_prof institution
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @date     27-07-2009
    */
    FUNCTION get_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_dep        IN VARCHAR2,
        i_flg_search    IN VARCHAR2,
        i_flg_schedule  IN VARCHAR2,
        i_flg_dep_type  IN VARCHAR2,
        i_flg_event_def IN VARCHAR2 DEFAULT NULL,
        i_flg_prof      IN VARCHAR2 DEFAULT NULL,
        o_events        OUT c_events,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_found_professional BOOLEAN := FALSE;
        l_found_dcs          BOOLEAN := FALSE;
        l_sql_clause         VARCHAR2(4000) DEFAULT NULL;
        l_select_clause      VARCHAR2(4000) DEFAULT NULL;
        l_from_clause        VARCHAR2(4000) DEFAULT NULL;
        l_where_clause       VARCHAR2(4000) DEFAULT NULL;
        l_order_clause       VARCHAR2(4000) DEFAULT NULL;
        l_found_prof         VARCHAR(4000) DEFAULT NULL;
        l_func_name          VARCHAR2(32) := 'GET_EVENTS';
        l_flg_schedule       VARCHAR2(1);
        l_def_events         table_number;
        l_id_institution     institution.id_institution%TYPE;
    BEGIN
        g_error := 'GET FLG_SCHEDULE';
        IF i_flg_schedule IS NULL
        THEN
            l_flg_schedule := g_no;
        ELSE
            l_flg_schedule := i_flg_schedule;
        END IF;
    
        SELECT d.id_institution
          INTO l_id_institution
          FROM department d
         WHERE d.id_department = i_id_dep;
    
        -- Find events that will have 'Y' as flg_select.
        g_error      := 'FIND SELECTED EVENTS';
        l_def_events := table_number();
        FOR rec IN (SELECT DISTINCT se.id_sch_event, se.flg_target_dep_clin_serv, se.flg_target_professional
                      FROM sch_permission sp, sch_event se, sch_department sd
                     WHERE sp.id_institution = l_id_institution --i_prof.institution
                       AND sp.id_professional = i_prof.id
                       AND sp.id_sch_event = se.id_sch_event
                       AND sd.id_department = i_id_dep
                       AND sd.flg_dep_type = se.dep_type
                       AND sp.flg_permission <> pk_schedule.g_permission_none
                          --show only events belonging to the selected event type
                       AND sd.flg_dep_type = i_flg_dep_type
                       AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, l_id_institution, i_prof.software) =
                           pk_alert_constant.g_yes
                     ORDER BY decode(se.flg_target_professional, pk_schedule.g_yes, 0, g_no, 1))
        
        LOOP
            IF rec.flg_target_professional = pk_schedule.g_yes
               AND NOT l_found_dcs
            THEN
                l_found_prof := pk_schedule.g_yes;
                l_def_events.extend();
                l_def_events(l_def_events.last) := rec.id_sch_event;
                l_found_professional := TRUE;
            END IF;
        
            IF rec.flg_target_dep_clin_serv = pk_schedule.g_yes
               AND rec.flg_target_professional = g_no
               AND NOT l_found_professional
            THEN
                l_found_dcs  := TRUE;
                l_found_prof := pk_schedule.g_yes;
                l_def_events.extend();
                l_def_events(l_def_events.last) := rec.id_sch_event;
            END IF;
        END LOOP;
    
        g_error := 'SELECT';
        OPEN o_events FOR
            SELECT data, id_sch_event, label_full, label, flg_select, order_field, order_field2, no_prof
              FROM (SELECT DISTINCT a.id_sch_event ||
                                    (SELECT decode(sei.id_sch_event_ref, NULL, '', ',' || sei.id_sch_event_ref)
                                       FROM sch_event_inst sei
                                      WHERE sei.id_institution = l_id_institution --i_prof.institution
                                        AND sei.id_sch_event = a.id_sch_event
                                        AND sei.active = g_yes
                                        AND rownum = 1) data,
                                    a.id_sch_event id_sch_event,
                                    pk_schedule_common.get_translation_alias(i_lang,
                                                                             i_prof,
                                                                             a.id_sch_event,
                                                                             a.code_sch_event) label_full,
                                    pk_translation.get_translation(i_lang, a.code_sch_event_abrv) label,
                                    CASE
                                         WHEN i_flg_event_def IS NOT NULL
                                              AND i_flg_prof IS NOT NULL
                                              AND i_flg_event_def = g_event_occurrence_subs
                                              AND i_flg_prof = g_yes THEN
                                          decode(a.id_sch_event, g_event_subs_med, g_yes, g_no)
                                         WHEN i_flg_event_def IS NOT NULL
                                              AND i_flg_prof IS NOT NULL
                                              AND i_flg_event_def = g_event_occurrence_subs
                                              AND i_flg_prof = g_no THEN
                                          decode(a.id_sch_event, g_event_subs_spec, g_yes, g_no)
                                         WHEN i_flg_event_def IS NOT NULL
                                              AND i_flg_prof IS NOT NULL
                                              AND i_flg_event_def = g_event_occurrence_sub_first
                                              AND i_flg_prof = g_yes THEN
                                          decode(a.id_sch_event, g_event_first_med, g_yes, g_event_subs_med, g_yes, g_no)
                                         WHEN i_flg_event_def IS NOT NULL
                                              AND i_flg_prof IS NOT NULL
                                              AND i_flg_event_def = g_event_occurrence_sub_first
                                              AND i_flg_prof = g_no THEN
                                          decode(a.id_sch_event, g_event_first_spec, g_yes, g_event_subs_spec, g_yes, g_no)
                                         WHEN i_flg_event_def IS NULL
                                              AND i_flg_prof IS NULL
                                              AND i_flg_search = pk_schedule.g_yes
                                              AND l_found_prof = pk_schedule.g_yes
                                              AND pk_utils.search_table_number(l_def_events, a.id_sch_event) > -1 THEN
                                          pk_schedule.g_yes
                                         WHEN i_flg_event_def IS NULL
                                              AND i_flg_prof IS NULL
                                              AND i_flg_search = pk_schedule.g_yes
                                              AND l_found_prof = pk_schedule.g_yes
                                              AND pk_utils.search_table_number(l_def_events, a.id_sch_event) = -1 THEN
                                          g_no
                                         WHEN i_flg_event_def IS NULL
                                              AND i_flg_prof IS NULL
                                              AND i_flg_search = pk_schedule.g_yes THEN
                                          g_no
                                         ELSE
                                          decode(a.id_sch_event, 1, g_yes, g_no)
                                     END flg_select,
                                    9 order_field,
                                    a.rank order_field2,
                                    a.id_sch_event id_event,
                                    decode(a.flg_target_professional, g_yes, g_no, g_no, g_yes) no_prof
                      FROM sch_event a, sch_department sd
                     WHERE a.dep_type = sd.flg_dep_type
                       AND a.flg_available = g_yes
                       AND sd.id_department = i_id_dep
                       AND sd.flg_dep_type = i_flg_dep_type
                       AND a.id_sch_event IN
                           (SELECT b.id_sch_event
                              FROM sch_event_dcs b
                             WHERE b.id_dep_clin_serv IN
                                   (SELECT dcs.id_dep_clin_serv
                                      FROM dep_clin_serv dcs
                                     WHERE dcs.id_department IN (
                                                                 -- Filter events by type of schedule: exams, consults, etc.
                                                                 SELECT sd.id_department
                                                                   FROM sch_event se, sch_department sd
                                                                  WHERE sd.flg_dep_type = se.dep_type
                                                                    AND sd.id_department = i_id_dep
                                                                    AND sd.flg_dep_type = i_flg_dep_type)))
                       AND a.id_sch_event IN
                           (SELECT sp.id_sch_event
                              FROM sch_permission sp
                             WHERE sp.id_professional = i_prof.id
                               AND sp.id_institution = l_id_institution --i_prof.institution
                               AND (sp.flg_permission = pk_schedule.g_permission_schedule OR l_flg_schedule = g_no))
                       AND pk_schedule_common.get_sch_event_avail(a.id_sch_event, l_id_institution, i_prof.software) =
                           pk_alert_constant.g_yes
                    -- This way a FTS is avoided on SCH_EVENT_INST
                    )
             WHERE NOT EXISTS (SELECT 1
                      FROM sch_event_inst
                     WHERE to_char(id_sch_event_ref) = to_char(data)
                       AND id_institution = l_id_institution --i_prof.institution
                       AND active = g_yes
                       AND flg_visible = g_no)
             ORDER BY order_field, order_field2 ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            open_my_cursor_events(o_events);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_events;

    /*
    * Gets the list of languages (including the default language, which is automatically selected).
    * @param i_lang               Language.
    * @param i_prof               Professional
    * @param i_id_patient         Patient.
    * @param i_flg_search         Whether or not should the 'All' option be included.
    * @param o_languages          List of languages.
    * @param o_error              Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    */
    FUNCTION get_languages
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_search IN VARCHAR2,
        o_languages  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_LANGUAGES';
    BEGIN
        g_error := 'OPEN o_languages FOR';
        /* search is made only by department */
        OPEN o_languages FOR
            SELECT id_language data, desc_language label, flg_select, order_field
              FROM (SELECT g_all id_language,
                           pk_message.get_message(i_lang, g_msg_all) desc_language,
                           g_no flg_select,
                           1 order_field
                      FROM dual
                     WHERE i_flg_search = g_yes
                    UNION
                    -- Default language
                    SELECT to_number(val), desc_val, g_yes flg_select, 9 order_field
                      FROM sys_domain s
                     WHERE s.code_domain = g_sched_language_domain
                       AND s.domain_owner = pk_sysdomain.k_default_schema
                       AND s.val IN (SELECT psa.id_language
                                       FROM pat_soc_attributes psa
                                      WHERE psa.id_patient = i_id_patient)
                       AND s.id_language = i_lang
                    UNION
                    -- Other languages
                    SELECT to_number(val), desc_val, g_no flg_select, 9 order_field
                      FROM sys_domain s
                     WHERE s.code_domain = g_sched_language_domain
                       AND s.domain_owner = pk_sysdomain.k_default_schema
                          -- Faster than an IN or EXISTS
                       AND (SELECT COUNT(1)
                              FROM pat_soc_attributes psa
                             WHERE (psa.id_language IS NOT NULL AND psa.id_language = s.val)
                               AND psa.id_patient = i_id_patient) = 0
                          
                       AND s.id_language = i_lang)
             ORDER BY order_field, label ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_languages);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_languages;

    /*
    * Gets the list of origins.
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_flg_search         Whether or not should the 'All' origin be included on the list.
    * @param o_origins            List of origins.
    * @param o_error              Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    *
    * UPDATED
    * Changed query to use origin_soft_inst instead of origin_soft (ALERT-16459)
    * @author   Jose Antunes
    * @version  2.5
    * @date     04-03-2009
    *
    * UPDATED
    * new parameter: i_id_institution
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @date     31-07-2009
    */
    FUNCTION get_origins
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_search     IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE DEFAULT NULL,
        o_origins        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_ORIGINS';
        l_id_institution institution.id_institution%TYPE := i_id_institution;
    BEGIN
        g_error := 'OPEN o_origins FOR';
    
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        OPEN o_origins FOR
            SELECT id data, description label, flg_select, order_field
              FROM (SELECT g_all id,
                           pk_message.get_message(i_lang, g_msg_all) description,
                           g_no flg_select,
                           1 order_field
                      FROM dual
                     WHERE i_flg_search = g_yes
                    UNION
                    SELECT o.id_origin,
                           pk_translation.get_translation(i_lang, o.code_origin) desc_origin,
                           decode(o.id_origin, NULL, g_yes, g_no) flg_select,
                           9 order_field
                      FROM origin o
                     WHERE o.id_origin IN (SELECT osi.id_origin
                                             FROM origin_soft_inst osi
                                            WHERE osi.id_software = i_prof.software
                                              AND osi.id_institution = l_id_institution --i_prof.institution
                                              AND osi.flg_available = g_yes))
             ORDER BY order_field, label ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_origins);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_origins;

    /*
    * Gets the label for search patient by field. (Document or plan)
    *
    * @param i_lang      Language identifier.
    * @param i_prof      Professional.
    * @param o_label     Label.
    * @param o_error     Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    */
    FUNCTION get_search_field_label
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_label OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_type      sys_config.value%TYPE;
        l_search_id sys_config.value%TYPE;
        l_func_name VARCHAR2(32) := 'GET_SEARCH_FIELD_LABEL';
    BEGIN
        g_error := 'CALL GET_SEARCH_PATIENT_BY';
        IF NOT (get_search_patient_by(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      o_type       => l_type,
                                      o_identifier => l_search_id,
                                      o_error      => o_error))
        THEN
            RETURN FALSE;
        ELSE
            IF (l_type = g_search_pat_by_document)
            THEN
                -- Document
                g_error := 'GET DOCUMENT IDENTIFIER';
                SELECT pk_translation.get_translation(i_lang, dt.code_doc_type)
                  INTO o_label
                  FROM doc_type dt
                 WHERE dt.id_doc_type = l_search_id;
            ELSIF (l_type = g_search_pat_by_plan)
            THEN
                -- Plan
                g_error := 'GET PLAN IDENTIFIER';
                SELECT pk_translation.get_translation(i_lang, hp.code_health_plan)
                  INTO o_label
                  FROM health_plan hp
                 WHERE hp.id_health_plan = l_search_id;
            END IF;
            RETURN TRUE;
        END IF;
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_search_field_label;

    /*
    * Gets the patient family physician name.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_patient         Patient identifier.    
    *
    * @return  Professional name.
    * @author  Sofia Mendes
    * @version 2.5.0.7.2
    * @since   2009/11/17    
    */
    FUNCTION get_pat_family_prof
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_prof_name professional.name%TYPE;
    BEGIN
        g_error := 'SELECT family physician';
        SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) --id_professional, nick_name
          INTO l_prof_name
          FROM ((SELECT pfp.id_professional, 1
                   FROM patient pat, pat_family_prof pfp, professional p
                  WHERE pat.id_patient = i_id_patient
                    AND pfp.id_patient = pat.id_patient
                    AND p.id_professional = pfp.id_professional
                 UNION ALL
                 SELECT pfp.id_professional, 2
                   FROM patient pat, pat_family_prof pfp, professional p
                  WHERE pat.id_patient = i_id_patient
                    AND pfp.id_pat_family = pat.id_pat_family
                    AND p.id_professional = pfp.id_professional) ORDER BY 2)
         WHERE rownum = 1;
        RETURN l_prof_name;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN '';
    END get_pat_family_prof;

    /*
    * Gets the list of patients.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_name               Name to search for.
    * @param i_dt_birth           Date of birth.
    * @param i_search_value       Value of the document or plan.
    * @param i_id_patient         Patient identifier.
    * @param o_patients           List of patients.
    * @param o_error              Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    *
    * UPDATED
    * forma de obtencao da dt_birth uniformizada com a da funcao get_patients
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     11-09-2008
    */
    FUNCTION get_patients
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_name         IN patient.name%TYPE DEFAULT NULL,
        i_dt_birth     IN VARCHAR2 DEFAULT NULL,
        i_search_value IN VARCHAR2 DEFAULT NULL,
        i_id_patient   IN patient.id_patient%TYPE,
        o_patients     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_max_results sys_config.id_sys_config%TYPE;
        l_search_type sys_config.id_sys_config%TYPE;
        l_search_id   sys_config.id_sys_config%TYPE;
        l_func_name   VARCHAR2(32) := 'GET_PATIENTS';
    
    BEGIN
        g_error := 'CALL GET_CONFIG FOR ' || g_num_record_search_parameter;
        -- Try to get the maximum number of results
        IF NOT (get_config(i_lang, g_num_record_search_parameter, i_prof, l_max_results, o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_SEARCH_PATIENT_BY';
        -- Try to get the search patient by type and identifier values.
        IF NOT (get_search_patient_by(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      o_type       => l_search_type,
                                      o_identifier => l_search_id,
                                      o_error      => o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_patients FOR';
        -- Open cursor
        OPEN o_patients FOR
            SELECT p.id_patient,
                   pk_patphoto.get_pat_foto(p.id_patient, i_prof) photo,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) age,
                   pk_patient.get_gender(i_lang, p.gender) AS gender,
                   p.name,
                   string_dt_birth(i_lang, i_prof, p.dt_birth) dt_birth,
                   psa.address || chr(13) || psa.zip_code || ' ' || psa.location adress,
                   get_pat_family_prof(i_lang, i_prof, p.id_patient) AS family_prof_name
              FROM patient p, pat_soc_attributes psa
             WHERE p.flg_status = g_status_active
               AND psa.id_patient(+) = p.id_patient
               AND psa.id_institution(+) = i_prof.institution
               AND EXISTS
             (SELECT 1
                      FROM clin_record cr
                     WHERE p.id_patient = cr.id_patient
                       AND cr.id_institution = i_prof.institution)
                  -- Search by patient identifier (if an identifier is passed then nothing else is tested
               AND ((i_id_patient IS NOT NULL AND p.id_patient = i_id_patient) OR
                   (i_id_patient IS NULL AND
                   -- Search by name
                   ((i_name IS NULL OR
                   translate(upper(p.name), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_name), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%') AND
                   -- Search by date of birth
                   (i_dt_birth IS NULL OR p.dt_birth = i_dt_birth) AND
                   -- Search by document
                   (i_search_value IS NULL OR
                   ((l_search_type = g_search_pat_by_document AND
                   p.id_patient IN (SELECT pd.id_patient
                                            FROM pat_doc pd
                                           WHERE pd.id_doc_type = l_search_id
                                             AND pd.value LIKE '%' || i_search_value || '%'
                                             AND pd.flg_status = g_status_active
                                             AND pd.id_institution = i_prof.institution)) OR
                   -- Search by plan
                   (l_search_type = g_search_pat_by_plan AND
                   p.id_patient IN
                   (SELECT php.id_patient
                            FROM pat_health_plan php
                           WHERE php.id_institution = i_prof.institution
                             AND php.id_health_plan = l_search_id
                             AND php.num_health_plan LIKE '%' || i_search_value || '%')))))))
               AND rownum < l_max_results
             ORDER BY p.name ASC;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_patients);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_patients;

    /**
    * Retrieves all patient information
    *
    * @param      i_lang             Language.
    * @param      i_prof             Professional object which refers the identity of the function caller
    * @param      i_id_patient       Patient id
    * @param      o_patient_info     All information about the patient
    * @param      o_error            Error message (if an error occurred).
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Ricardo Pinho)
    * @version    alpha
    * @since      2006/05/02
    *
    * UPDATED
    * forma de obtencao da dt_birth uniformizada com a da funcao get_patients
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     11-09-2008
    */
    FUNCTION get_patient_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        o_patient_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_search_patient_by_value VARCHAR2(200);
        l_num_sns                 pat_health_plan.num_health_plan%TYPE;
        l_func_name               VARCHAR2(32) := 'GET_PATIENT_DETAIL';
    BEGIN
        g_error := 'CALL GET_PATIENT_DOC';
        IF NOT (get_patient_doc(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_patient_id => i_id_patient,
                                o_doc_value  => l_search_patient_by_value,
                                o_error      => o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        -- Get SNS number
        g_error := 'GET SNS NUMBER';
        BEGIN
            SELECT php.num_health_plan
              INTO l_num_sns
              FROM pat_health_plan php, health_plan hp
             WHERE php.id_patient = i_id_patient
               AND php.id_institution = i_prof.institution
               AND hp.id_health_plan = php.id_health_plan
               AND hp.flg_type = g_health_plan_type_sns
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_num_sns := NULL;
        END;
    
        g_error := 'OPEN o_patient_info FOR';
        OPEN o_patient_info FOR
            SELECT p.id_patient,
                   p.name,
                   string_dt_birth(i_lang, i_prof, p.dt_birth) dt_birth,
                   pk_patient.get_gender(i_lang, p.gender) gender,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) age,
                   pk_patphoto.get_pat_foto(p.id_patient, i_prof) photo,
                   psa.address || chr(13) || psa.zip_code || ' ' || psa.location adress,
                   l_search_patient_by_value num_doc,
                   /* sns number */
                   l_num_sns num_sns,
                   /* default health plan */
                   get_health_plan(i_lang, p.id_patient, i_prof.institution) subsistema,
                   mother_name,
                   father_name,
                   psa.id_language,
                   pk_translation.get_translation(i_lang, 'COUNTRY.CODE_COUNTRY.' || psa.id_country_nation) desc_nationality
              FROM patient p, pat_soc_attributes psa
             WHERE p.id_patient = i_id_patient
               AND psa.id_patient(+) = p.id_patient
               AND psa.id_institution(+) = i_prof.institution;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_patient_detail;

    /*
    * Gets the list of months and week days.
    * @param i_lang           Language identifier.
    * @param o_months         List of months.
    * @param o_week_days      List of week days.
    * @param o_error          Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2006/05/02
    */
    FUNCTION get_months_and_days
    (
        i_lang      IN language.id_language%TYPE,
        o_months    OUT pk_types.cursor_type,
        o_week_days OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_MONTHS_AND_DAYS';
    BEGIN
        -- Months
        g_error := 'GET o_months FOR';
        OPEN o_months FOR
            SELECT desc_message month_desc
              FROM sys_message sm
             WHERE sm.id_language = i_lang
               AND (code_message LIKE 'SCH_MONTH__' OR code_message LIKE 'SCH_MONTH___')
             ORDER BY length(code_message) ASC, code_message;
        -- Weekdays
        g_error := 'GET o_week_days FOR';
        OPEN o_week_days FOR
            SELECT desc_message,
                   decode(length(desc_abbr_message), 1, desc_abbr_message, upper(substr(desc_message, 1, 1))) abrv
              FROM (SELECT (SELECT sm.desc_message
                              FROM sys_message sm
                             WHERE sm.id_language = i_lang
                               AND sm.code_message = g_msg_day_prefix || '_' || VALUE(t)) desc_message,
                           (SELECT sm.desc_message
                              FROM sys_message sm
                             WHERE sm.id_language = i_lang
                               AND sm.code_message = g_msg_day_prefix || '_' || VALUE(t) || '_ABBR') desc_abbr_message,
                           rownum order_field
                      FROM TABLE(CAST(g_msg_week_days AS table_varchar)) t)
             ORDER BY order_field;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_months);
            pk_types.open_my_cursor(o_week_days);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_months_and_days;

    PROCEDURE open_my_cursor_dcs(i_cursor IN OUT c_dep_clin_servs) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL data, NULL label, NULL flg_select, NULL order_field
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor_dcs;
    /*
    * Gets the list of clinical services from a department, for a given event, professional or episode.
    * @param i_lang             Language identifier.
    * @param i_prof             Professional who is calling this function.
    * @param i_id_dep           Department identifier.
    * @param i_id_event         Event identifier.
    * @param i_id_episode       Episode identifier.
    * @param i_flg_search       Whether or not should the 'All' option be included
    * @param i_flg_schedule        Whether or not should the events be filtered considering the professional's permission to schedule
    * @param o_dep_clin_servs   List of clinical services.
    * @param o_error            Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2006/05/03
    *
    * UPDATED
    * added check of sch_permission.flg_permission
    * @author  Telmo Castro
    * @date    15-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * RemoÁ„o de SQL dinamico. Simplificacao de funcao
    * @author  Jose Antunes
    * @date    09-10-2008
    * @version 2.4.3
    *
    * UPDATED
    * use the department institution instead of the i_prof institution
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @date     27-07-2009
    */
    FUNCTION get_dep_clin_servs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_dep         IN VARCHAR2,
        i_id_event       IN VARCHAR2,
        i_id_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_flg_search     IN VARCHAR2,
        i_flg_schedule   IN VARCHAR2,
        o_dep_clin_servs OUT c_dep_clin_servs,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sql_clause   VARCHAR2(32000) DEFAULT NULL;
        l_id_dep       department.id_department%TYPE;
        l_id_dcs       dep_clin_serv.id_dep_clin_serv%TYPE := g_none;
        l_func_name    VARCHAR2(32) := 'GET_DEP_CLIN_SERVS';
        l_flg_schedule VARCHAR2(1);
        l_id_events    table_number;
    
        l_id_institution institution.id_institution%TYPE;
    BEGIN
        SELECT d.id_institution
          INTO l_id_institution
          FROM department d
         WHERE d.id_department = i_id_dep;
    
        g_error := 'CHECK EPISODE';
        -- If the episode is not null, try to get the DCS
        IF (i_id_episode IS NOT NULL)
        THEN
            BEGIN
                g_error := 'GET DEFAULT DEP-CLINICAL SERVICE FOR THE EPISODE';
                SELECT dcs.id_dep_clin_serv
                  INTO l_id_dcs
                  FROM episode e, dep_clin_serv dcs
                 WHERE e.id_episode = i_id_episode
                   AND dcs.id_clinical_service = e.id_clinical_service
                   AND dcs.id_department = i_id_dep
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- None found, no problem.
                    NULL;
            END;
        END IF;
    
        IF i_flg_schedule IS NULL
        THEN
            l_flg_schedule := g_no;
        ELSE
            l_flg_schedule := i_flg_schedule;
        END IF;
    
        g_error     := 'CREATE TABLE EVENTS';
        l_id_events := pk_schedule.get_list_number_csv(i_id_event);
    
        g_error := 'SELECT';
        OPEN o_dep_clin_servs FOR
            SELECT data, label, flg_select, order_field
              FROM (SELECT g_all data,
                           pk_message.get_message(i_lang, g_msg_all) label,
                           decode(l_id_dcs, g_none, g_yes, g_no) flg_select,
                           1 order_field
                      FROM dual
                     WHERE i_flg_search = g_yes
                    UNION
                    SELECT id_dcs data,
                           string_dep_clin_serv(i_lang, id_dcs) label,
                           decode(id_dcs, l_id_dcs, g_yes, g_no) flg_select,
                           9 order_field
                      FROM (SELECT pdcs.id_dep_clin_serv id_dcs
                              FROM sch_permission sp, prof_dep_clin_serv pdcs, dep_clin_serv dcs, sch_event se
                             WHERE sp.id_institution = l_id_institution --i_prof.institution
                               AND dcs.flg_available = g_yes
                               AND pdcs.flg_status = g_status_pdcs_selected
                               AND sp.id_professional = i_prof.id
                               AND sp.flg_permission <> g_permission_none
                               AND (i_id_event IS NULL OR
                                   (i_id_event IS NOT NULL AND
                                   sp.id_sch_event IN (SELECT column_value
                                                           FROM TABLE(l_id_events))))
                               AND se.id_sch_event = sp.id_sch_event
                               AND se.flg_target_professional = g_yes
                               AND pdcs.id_professional = sp.id_prof_agenda
                               AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                               AND sp.id_dep_clin_serv = dcs.id_dep_clin_serv
                               AND dcs.id_department IN (i_id_dep)
                               AND pk_schedule_common.get_sch_event_avail(se.id_sch_event,
                                                                          l_id_institution,
                                                                          i_prof.software) = pk_alert_constant.g_yes
                            UNION
                            SELECT dcs.id_dep_clin_serv id_dcs
                              FROM sch_permission sp, dep_clin_serv dcs, sch_event se
                             WHERE sp.id_institution = l_id_institution --i_prof.institution
                               AND sp.id_professional = i_prof.id
                               AND (sp.flg_permission = g_permission_schedule OR l_flg_schedule = g_no)
                               AND (i_id_event IS NULL OR
                                   (i_id_event IS NOT NULL AND
                                   sp.id_sch_event IN (SELECT column_value
                                                           FROM TABLE(l_id_events))))
                               AND se.id_sch_event = sp.id_sch_event
                               AND se.flg_target_professional = g_no
                               AND dcs.flg_available = g_yes
                               AND dcs.id_dep_clin_serv = sp.id_dep_clin_serv
                               AND dcs.id_department IN (i_id_dep)
                               AND pk_schedule_common.get_sch_event_avail(se.id_sch_event,
                                                                          l_id_institution,
                                                                          i_prof.software) = pk_alert_constant.g_yes))
             ORDER BY order_field, label ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            open_my_cursor_dcs(o_dep_clin_servs);
            -- Unexpected error
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_dep_clin_servs;

    PROCEDURE open_my_cursor_sch_prof(i_cursor IN OUT c_sch_prof) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL data, NULL label, NULL flg_select, NULL order_field
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor_sch_prof;

    /*
    * Gets the list of professionals on whose schedules the logged professional
    * has permission to read or schedule.
    *
    * @param i_lang             Language identifier.
    * @param i_prof             Professional identifier.
    * @param i_id_dep           Department identifier.
    * @param i_id_clin_serv     Department-Clinical service identifier.
    * @param i_id_event         Event identifier.
    * @param i_flg_schedule     Whether or not should the events be filtered considering the professional's permission to schedule
    * @param o_professionals    List of processionals.
    * @param o_error            Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2006/05/03
    *
    * UPDATED
    * new sch_permission scenarios: prof1+prof2+dcs OR prof1+dcs
    * @author  Telmo Castro
    * @date    19-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * use the department institution instead of the i_prof institution
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @date     27-07-2009
    */
    FUNCTION get_professionals
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_dep        IN VARCHAR2,
        i_id_clin_serv  IN VARCHAR2,
        i_id_event      IN VARCHAR2,
        i_flg_schedule  IN VARCHAR2,
        o_professionals OUT c_sch_prof,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_PROFESSIONALS';
        l_list_event     table_number;
        l_list_dcs       table_number;
        l_count          NUMBER;
        l_self_count     NUMBER;
        l_flg_schedule   VARCHAR2(1);
        l_id_institution institution.id_institution%TYPE;
    BEGIN
        SELECT d.id_institution
          INTO l_id_institution
          FROM department d
         WHERE d.id_department = i_id_dep;
    
        -- Get lists
        g_error      := 'GET LISTS';
        l_list_event := get_list_number_csv(i_id_event);
        l_list_dcs   := get_list_number_csv(i_id_clin_serv);
    
        SELECT nvl2(i_flg_schedule, i_flg_schedule, g_no)
          INTO l_flg_schedule
          FROM dual;
    
        g_error := 'SELF COUNT';
        -- Check for self permissions
        SELECT COUNT(1)
          INTO l_self_count
          FROM sch_permission sp
          JOIN sch_event se
            ON se.id_sch_event = sp.id_sch_event
         WHERE sp.id_institution = l_id_institution --i_prof.institution
           AND sp.flg_permission <> g_permission_none
           AND se.id_sch_event IN (SELECT *
                                     FROM TABLE(l_list_event))
           AND se.flg_target_professional = g_yes
           AND sp.id_prof_agenda = i_prof.id
           AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, l_id_institution, i_prof.software) =
               pk_alert_constant.g_yes;
    
        -- Count the professionals
        g_error := 'COUNT';
        SELECT COUNT(1)
          INTO l_count
          FROM sch_permission sp
          JOIN sch_event se
            ON se.id_sch_event = sp.id_sch_event
         WHERE sp.id_institution = l_id_institution --i_prof.institution
           AND sp.flg_permission <> g_permission_none
           AND se.id_sch_event IN (SELECT *
                                     FROM TABLE(l_list_event))
           AND se.flg_target_professional = g_yes
           AND (sp.flg_permission = g_permission_schedule OR l_flg_schedule = g_no)
           AND sp.id_dep_clin_serv IN (SELECT *
                                         FROM TABLE(l_list_dcs))
           AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, l_id_institution, i_prof.software) =
               pk_alert_constant.g_yes
           AND rownum <= 1;
    
        IF (l_count > 0)
        THEN
            g_error := 'OPEN o_professionals FOR';
            OPEN o_professionals FOR
                SELECT data, label, flg_select, order_field
                  FROM (SELECT g_all data,
                               pk_message.get_message(i_lang, g_msg_all) label,
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
                          JOIN prof_institution pi
                            ON pi.id_professional = sp.id_prof_agenda
                           AND pi.id_institution = l_id_institution
                           AND pi.dt_end_tstz IS NULL
                           AND pi.flg_state = 'A'
                         WHERE sp.id_institution = l_id_institution --i_prof.institution
                           AND sp.id_professional = i_prof.id
                           AND sp.flg_permission <> g_permission_none
                           AND se.id_sch_event IN (SELECT *
                                                     FROM TABLE(l_list_event))
                           AND se.flg_target_professional = g_yes
                           AND (sp.flg_permission = g_permission_schedule OR l_flg_schedule = g_no)
                           AND sp.id_dep_clin_serv IN (SELECT *
                                                         FROM TABLE(l_list_dcs))
                           AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, l_id_institution, i_prof.software) =
                               pk_alert_constant.g_yes)
                 ORDER BY order_field, label ASC;
        ELSE
            -- Avoid having 'All' as the only option.
            open_my_cursor_sch_prof(o_professionals);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            open_my_cursor_sch_prof(o_professionals);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_professionals;

    /*
    * Gets the list of a professional's permissions for using departments.
    * Only the departments that are associated with the professional on SCH_PERMISSION_DEPT get a 'Y' as flg_select.
    *
    * @param i_lang             Language identifier.
    * @param i_prof             Professional who is logged on.
    * @param i_target_prof      Professional whose permissions are being listed.
    * @param o_permissions      List of permissions.
    * @param o_error            Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise.
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2006/05/04
    *
    * REVISED
    * @author  Telmo Castro
    * @date    21-04-2008
    * @version 2.4.3
    * Now reads: only the departments that are associated to the professional through prof_dep_clin_serv.
    */
    FUNCTION get_permission_depts
    (
        i_lang        language.id_language%TYPE,
        i_prof        profissional,
        i_target_prof professional.id_professional%TYPE,
        o_permissions OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PERMISSION_DEPT';
    BEGIN
        g_error := 'OPEN o_permissions FOR';
        -- Open cursor
        OPEN o_permissions FOR
            SELECT data, label, flg_select
              FROM (SELECT DISTINCT d.id_department data,
                                    pk_translation.get_translation(1, d.code_department) label,
                                    'Y' flg_select
                      FROM prof_dep_clin_serv pdcs
                     INNER JOIN dep_clin_serv dcs
                        ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                     INNER JOIN department d
                        ON dcs.id_department = d.id_department
                     INNER JOIN sch_department de
                        ON dcs.id_department = de.id_department
                     WHERE pdcs.id_professional = i_target_prof
                       AND d.id_institution = i_prof.institution
                       AND dcs.flg_available = g_yes
                       AND d.flg_available = g_yes)
             ORDER BY label;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_permission_depts;

    /*
    * Returns the colors (by name and by DCS) to use on the Scheduler.
    *
    * @param i_lang                    Language identifier.
    * @param i_prof                    Professional
    * @param i_id_dep                  Department
    * @param i_flg_named_colors        Whether or not should the named colors be returned: 'Y', 'N'
    * @param o_named_colors            List of named colors (if i_flg_named_colors = 'Y')
    * @param o_dcs_colors              List of DCS colors (if DCS colors are activated)
    * @param o_use_dcs_colors          Whether or not should the UI used DCS colors.
    * @param o_max_dcs_colors          Maximum number of colors to display per cell.
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since
    *
    * UPDATED
    * use the department institution instead of the i_prof institution
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @date     27-07-2009
    */
    FUNCTION get_colors
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep           IN department.id_department%TYPE,
        i_flg_named_colors IN VARCHAR2,
        o_named_colors     OUT pk_types.cursor_type,
        o_dcs_colors       OUT pk_types.cursor_type,
        o_use_dcs_colors   OUT VARCHAR2,
        o_max_dcs_colors   OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'GET_COLORS';
        l_use_colors sys_config.value%TYPE;
    
        l_id_institution institution.id_institution%TYPE;
    BEGIN
        g_error := 'GET DCS COLOR USAGE';
        -- Check if DCS colors are used
        IF NOT get_config(i_lang         => i_lang,
                          i_id_sysconfig => g_config_use_dcs_colors,
                          i_prof         => i_prof,
                          o_config       => l_use_colors,
                          o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        SELECT d.id_institution
          INTO l_id_institution
          FROM department d
         WHERE d.id_department = i_id_dep;
    
        g_error := 'CHECK NAMED COLORS';
        -- Get named colors
        IF i_flg_named_colors = g_yes
        THEN
            g_error := 'GET NAMED COLORS';
            OPEN o_named_colors FOR
                SELECT color_name, g_color_prefix || color_hex color_hex
                  FROM (SELECT sc_out.color_name, sc_out.color_hex
                          FROM sch_color sc_out
                         WHERE (SELECT COUNT(1)
                                  FROM sch_color sc_in
                                 WHERE sc_in.id_institution = sc_out.id_institution
                                   AND sc_in.id_sch_color = sc_out.id_sch_color) > 0
                           AND id_institution = l_id_institution --i_prof.institution
                           AND flg_type = g_color_type_named
                        UNION
                        SELECT sc_out.color_name, sc_out.color_hex
                          FROM sch_color sc_out
                         WHERE (SELECT COUNT(1)
                                  FROM sch_color sc_in
                                 WHERE sc_in.id_institution = l_id_institution --i_prof.institution
                                   AND sc_in.id_sch_color = sc_out.id_sch_color) = 0
                           AND id_institution = 0
                           AND flg_type = g_color_type_named);
        ELSE
            g_error := 'CALL OPEN_MY_CURSOR FOR o_named_colors';
            -- The UI did not request named colors
            pk_types.open_my_cursor(o_named_colors);
        END IF;
    
        IF l_use_colors = g_yes
        THEN
            g_error := 'CHECK MAX DCS COLORS';
            -- Check which is the maximum number of DCS colors to display per cell.
            IF NOT get_config(i_lang         => i_lang,
                              i_id_sysconfig => g_config_max_dcs_colors,
                              i_prof         => i_prof,
                              o_config       => o_max_dcs_colors,
                              o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'GET DCS COLORS';
            -- Return a cursor containing the colors for all the DCSs of the given department.
            OPEN o_dcs_colors FOR
                SELECT a.id_dep_clin_serv, g_color_prefix || a.color_hex color_hex
                  FROM (SELECT sc_out.id_dep_clin_serv, sc_out.color_hex
                          FROM sch_color sc_out
                         WHERE (SELECT COUNT(1)
                                  FROM sch_color sc_in
                                 WHERE sc_in.id_institution = sc_out.id_institution
                                   AND sc_in.id_sch_color = sc_out.id_sch_color) > 0
                           AND id_institution = l_id_institution --i_prof.institution
                           AND flg_type = g_color_type_specialty
                        UNION
                        SELECT sc_out.id_dep_clin_serv, sc_out.color_hex
                          FROM sch_color sc_out
                         WHERE (SELECT COUNT(1)
                                  FROM sch_color sc_in
                                 WHERE sc_in.id_institution = l_id_institution --i_prof.institution
                                   AND sc_in.id_sch_color = sc_out.id_sch_color) = 0
                           AND id_institution = 0
                           AND flg_type = g_color_type_specialty) a,
                       department d,
                       dep_clin_serv dcs
                 WHERE dcs.id_dep_clin_serv = to_number(a.id_dep_clin_serv)
                   AND dcs.id_department = d.id_department
                   AND d.id_department = to_number(i_id_dep);
            o_use_dcs_colors := l_use_colors;
        ELSE
            g_error := 'CALL OPEN_MY_CURSOR FOR o_dcs_colors';
            -- Return an empty cursor and tell the UI that no colors should be used for DCSs.
            pk_types.open_my_cursor(o_dcs_colors);
            o_use_dcs_colors := g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_colors;

    PROCEDURE open_my_cursor_dep(i_cursor IN OUT c_dep) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL data,
                   NULL label,
                   NULL flg_type,
                   NULL flg_select,
                   NULL data_flag,
                   NULL order_field,
                   NULL dep_type
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor_dep;
    /*
    * Gets the list of departments that a professional has access to.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_flg_search          Whether or not should the 'All' option appear on the list.
    * @param i_flg_schedule        Whether or not should the departments be filtered considering the professional's permission to schedule
    * @param o_departments         List of departments
    * @param o_perm_msg            Error message to be shown if the professional has no permissions
    * @param o_error               Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise.
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2006/05/07
    *
    * UPDATED
    * sch_permission_dept abolished - permission for departments now derived from prof_dep_clin_serv, dep_clin_serv, department
    * @author  Telmo Castro
    * @date    21-04-2008
    * @version 2.4.3
    *
    * UPDATED
    * new sch_permission scenarios: prof1+prof2+dcs OR prof1+dcs
    * @author  Telmo Castro
    * @date    19-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * nurse consult departments description is appended with a message
    * @author  LuÌs Gaspar
    * @date    28-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * main query updated to cope with the new possibility of having the same department spread out through several dep_type (see sch_department)
    * @author  Telmo Castro
    * @date    11-07-2008
    * @version 2.4.3
    *
    * UPDATED
    * added column data_flag to output which is concat of columns data and dep_type
    * @author  Telmo Castro
    * @date    22-07-2008
    * @version 2.4.3
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    * 
    * UPDATED
    * ALERT-10140. AdaptaÁ„o para agenda MFR
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     24-11-2008
    *
    * UPDATED
    * New input parameter: i_id_institution
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @date     27-07-2009
    */
    FUNCTION get_departments
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_search     IN VARCHAR2,
        i_flg_schedule   IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        o_departments    OUT c_dep,
        o_perm_msg       OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DEPARTMENTS';
        l_msg_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang, pk_schedule.g_dep_additional_msg);
    BEGIN
        g_error := 'GET PERMISSION MESSAGE';
        -- Get a message to be shown if the resulting list of services is empty
        IF i_flg_search IS NULL
           OR i_flg_search = g_no
        THEN
            o_perm_msg := pk_schedule.get_message(i_lang, pk_schedule.g_missing_param_rw);
        ELSE
            o_perm_msg := pk_schedule.get_message(i_lang, pk_schedule.g_missing_param_w);
        END IF;
    
        g_error := 'OPEN o_departments FOR';
        -- Open cursor
        OPEN o_departments FOR
            SELECT data, label, flg_type, flg_select, data_flag, order_field, dep_type
              FROM (SELECT 1 x,
                           pk_schedule.g_all data,
                           pk_message.get_message(i_lang, pk_schedule.g_msg_all) label,
                           g_no flg_select,
                           pk_schedule_common.g_sch_dept_flg_dep_type_all flg_type,
                           NULL data_flag,
                           1 order_field,
                           '' dep_type
                      FROM dual
                     WHERE i_flg_search = pk_schedule.g_yes
                    -- ALL is quite faster as it does not sort the table,
                    -- and there must not be a g_all department on department table.
                    UNION ALL
                    SELECT a.*
                      FROM (SELECT SUM(decode(flg_default, pk_schedule.g_yes, 1, 0)) over(PARTITION BY data, label ORDER BY 1) xis,
                                   a.*
                              FROM (
                                    
                                    SELECT DISTINCT sd.id_department data,
                                                     pk_translation.get_translation(i_lang, d.code_department) || ' (' ||
                                                     pk_translation.get_translation(i_lang, sdt.code_dep_type) || ')' label,
                                                     pdcs.flg_default,
                                                     sd.flg_dep_type flg_type,
                                                     sd.id_department || '|' || sd.flg_dep_type data_flag,
                                                     9 order_field,
                                                     pk_translation.get_translation(i_lang, sdt.code_dep_type) AS dep_type
                                      FROM department d
                                      JOIN sch_department sd
                                        ON d.id_department = sd.id_department
                                      JOIN sch_dep_type sdt
                                        ON sd.flg_dep_type = sdt.dep_type
                                      JOIN dep_clin_serv dcs
                                        ON sd.id_department = dcs.id_department
                                      JOIN prof_dep_clin_serv pdcs
                                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                                     WHERE d.id_institution = i_id_institution --i_prof.institution
                                       AND d.flg_available = g_yes
                                       AND dcs.flg_available = g_yes
                                       AND pdcs.id_professional = i_prof.id
                                       AND ( -- check de permissoes para todas agendas menos mfr
                                            (sdt.dep_type <> pk_schedule_common.g_sch_dept_flg_dep_type_pm AND EXISTS
                                             (SELECT 1
                                                FROM sch_permission sp
                                                JOIN sch_event_dcs sed
                                                  ON sp.id_dep_clin_serv = sed.id_dep_clin_serv
                                                 AND sp.id_sch_event = sed.id_sch_event
                                                JOIN sch_event se
                                                  ON sed.id_sch_event = se.id_sch_event
                                               WHERE sp.id_professional = pdcs.id_professional
                                                 AND sp.id_institution = d.id_institution
                                                 AND sp.id_dep_clin_serv = pdcs.id_dep_clin_serv
                                                 AND ((nvl(i_flg_schedule, g_no) = g_no AND
                                                     sp.flg_permission <> pk_schedule.g_permission_none) OR
                                                     (nvl(i_flg_schedule, g_no) = g_yes AND
                                                     sp.flg_permission = pk_schedule.g_permission_schedule))
                                                 AND sed.flg_available = g_yes
                                                 AND se.dep_type = sd.flg_dep_type))
                                           -- check de permissoes para agenda mfr. A logica È: prof tem de ter permissao para 
                                           -- pelo menos uma especialidade que pertenca ao clinical service dado por 
                                           -- pk_schedule_mfr.get_base_clin_serv(i_prof). E o departamento dessa especialidade
                                           -- tem de estar na query principal (d2.id_department = d.id_department)
                                            OR (sdt.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm AND EXISTS
                                             (SELECT 1
                                                   FROM clinical_service cs2
                                                   JOIN dep_clin_serv dcs2
                                                     ON cs2.id_clinical_service = dcs2.id_clinical_service
                                                   JOIN department d2
                                                     ON dcs2.id_department = d2.id_department
                                                   JOIN sch_permission sp2
                                                     ON dcs2.id_dep_clin_serv = sp2.id_dep_clin_serv
                                                   JOIN sch_event_dcs sed2
                                                     ON sp2.id_dep_clin_serv = sed2.id_dep_clin_serv
                                                    AND sp2.id_sch_event = sed2.id_sch_event
                                                   JOIN sch_event se2
                                                     ON sed2.id_sch_event = se2.id_sch_event
                                                  WHERE d2.id_department = d.id_department
                                                    AND sp2.id_institution = i_prof.institution
                                                    AND sp2.id_professional = i_prof.id
                                                    AND sp2.id_sch_event = pk_schedule.g_event_mfr
                                                    AND ((nvl(i_flg_schedule, g_no) = g_no AND
                                                        sp2.flg_permission <> pk_schedule.g_permission_none) OR
                                                        (nvl(i_flg_schedule, g_no) = g_yes AND
                                                        sp2.flg_permission = pk_schedule.g_permission_schedule))
                                                    AND sed2.flg_available = g_yes
                                                    AND se2.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
                                                    AND dcs2.id_clinical_service = pk_schedule_mfr.get_base_clin_serv(i_prof)
                                                    AND pk_schedule_common.get_sch_event_avail(se2.id_sch_event,
                                                                                               i_prof.institution,
                                                                                               i_prof.software) =
                                                        pk_alert_constant.g_yes)))) a) a
                     WHERE xis = 0
                        OR (xis > 0 AND a.flg_default = g_yes))
             ORDER BY order_field, label ASC;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            open_my_cursor_dep(o_departments);
            RETURN FALSE;
        
    END get_departments;

    /**
    * Converts a date into string using for it a mask defined in sys_message.
    * This date is composed by day, month and year.
    * To be used inside SELECTs.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_date             date to convert
    *
    * @return     String date
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/05/014
    */

    FUNCTION get_dmy_string_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_date      sys_message.desc_message%TYPE := '';
        l_dummy_ret BOOLEAN;
        l_dummy     t_error_out;
    BEGIN
        l_dummy_ret := get_dmy_string_date(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_date           => i_date,
                                           o_described_date => l_date,
                                           o_error          => l_dummy);
        RETURN l_date;
    END get_dmy_string_date;

    /**
    * Converts a date into string using for it a mask defined in sys_message.
    * This date is composed by day, month and year.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_date             date to convert
    * @param      o_described_date   date in text mode
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Ricardo Pinho)
    * @version    alpha
    * @since      2007/05/08
    */

    FUNCTION get_dmy_string_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN VARCHAR2,
        o_described_date OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_day          VARCHAR2(2);
        l_month        sys_message.desc_message%TYPE;
        l_year         VARCHAR2(4);
        l_func_name    VARCHAR2(32) := 'GET_DMY_STRING_DATE';
        l_tokens       table_varchar;
        l_replacements table_varchar;
        l_message      sys_message.desc_message%TYPE;
        l_timestamp    TIMESTAMP WITH TIME ZONE;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_timestamp,
                                             o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- Get day
        g_error := 'CALL TO_CHAR_INSTTIMEZONE FOR l_day';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp,
                                                  i_mask      => 'dd',
                                                  o_string    => l_day,
                                                  o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- Get month
        g_error := 'CALL TO_CHAR_INSTTIMEZONE FOR l_month';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp,
                                                  i_mask      => 'mm',
                                                  o_string    => l_month,
                                                  o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        l_month := pk_message.get_message(i_lang, g_msg_month_prefix || '_' || to_number(l_month));
    
        -- Get year
        g_error := 'CALL TO_CHAR_INSTTIMEZONE FOR l_month';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp,
                                                  i_mask      => 'yyyy',
                                                  o_string    => l_year,
                                                  o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        -- Set tokens to replace
        l_tokens       := table_varchar('@1', '@2', '@3');
        l_replacements := table_varchar(l_day, l_month, l_year);
        -- Get message to translate
        g_error   := 'GET DAY OF MONTH OF YEAR MESSAGE';
        l_message := get_message(i_lang => i_lang, i_message => g_day_of_month_of_year);
        -- Replace tokens
        IF NOT replace_tokens(i_lang         => i_lang,
                              i_string       => l_message,
                              i_tokens       => l_tokens,
                              i_replacements => l_replacements,
                              o_string       => o_described_date,
                              o_error        => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_on;
            o_described_date := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_dmy_string_date;

    /**
    * Converts a date into string using for it a mask defined in sys_message.
    * This date is composed by day, month, year, hour and minute.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_date             date to convert
    *
    * @return     varchar type, the writen date
    * @author     Nuno Guerreiro (Tiago Ferreira)
    * @version    alpha
    * @since      2007/05/08
    */
    FUNCTION get_dmyhm_string_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_day          VARCHAR2(2);
        l_month        sys_message.desc_message%TYPE;
        l_year         VARCHAR2(4);
        l_hour         VARCHAR2(2);
        l_minute       VARCHAR2(2);
        l_func_name    VARCHAR2(32) := 'GET_DMYHM_STRING_DATE';
        l_tokens       table_varchar;
        l_replacements table_varchar;
        l_message      sys_message.desc_message%TYPE;
        l_localized    sys_message.desc_message%TYPE;
        l_timestamp    TIMESTAMP WITH TIME ZONE;
        l_error_dummy  t_error_out;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_timestamp,
                                             o_error     => l_error_dummy)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN NULL;
        END IF;
    
        -- Get day
        g_error := 'CALL TO_CHAR_INSTTIMEZONE FOR l_day';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp,
                                                  i_mask      => 'dd',
                                                  o_string    => l_day,
                                                  o_error     => l_error_dummy)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN NULL;
        END IF;
    
        -- Get month
        g_error := 'CALL TO_CHAR_INSTTIMEZONE FOR l_month';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp,
                                                  i_mask      => 'mm',
                                                  o_string    => l_month,
                                                  o_error     => l_error_dummy)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN NULL;
        END IF;
    
        l_month := pk_message.get_message(i_lang, g_msg_month_prefix || '_' || to_number(l_month));
    
        -- Get year
        g_error := 'CALL TO_CHAR_INSTTIMEZONE FOR l_month';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp,
                                                  i_mask      => 'yyyy',
                                                  o_string    => l_year,
                                                  o_error     => l_error_dummy)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN NULL;
        END IF;
    
        -- Get hours
        g_error := 'CALL TO_CHAR_INSTTIMEZONE FOR l_hour';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp,
                                                  i_mask      => 'HH24',
                                                  o_string    => l_hour,
                                                  o_error     => l_error_dummy)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN NULL;
        END IF;
    
        -- Get minutes
        g_error := 'CALL TO_CHAR_INSTTIMEZONE FOR l_minute';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp,
                                                  i_mask      => 'MI',
                                                  o_string    => l_minute,
                                                  o_error     => l_error_dummy)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN NULL;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        -- Set tokens to replace
        l_tokens       := table_varchar('@1', '@2', '@3', '@4', '@5');
        l_replacements := table_varchar(l_day, l_month, l_year, l_hour, l_minute);
        -- Get message to translate
        g_error   := 'GET DAY OF MONTH OF YEAR AT HOURS AND MINUTES MESSAGE';
        l_message := get_message(i_lang => i_lang, i_message => g_day_of_month_of_year_hm);
        -- Replace tokens
        g_error := 'REPLACE TOKENS';
        IF replace_tokens(i_lang         => i_lang,
                          i_string       => l_message,
                          i_tokens       => l_tokens,
                          i_replacements => l_replacements,
                          o_string       => l_localized,
                          o_error        => l_error_dummy)
        THEN
            RETURN l_localized;
        ELSE
            RETURN '';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_on;
            -- Unexpected error
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN '';
    END get_dmyhm_string_date;

    /**
    * Converts a date into string using for it a mask defined in sys_message.
    * This date is composed by month and year.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_date             date to convert
    * @param      o_described_date   date in text mode
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Ricardo Pinho)
    * @version    alpha
    * @since      2007/05/08
    */
    FUNCTION get_my_string_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN VARCHAR2,
        o_described_date OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_month        sys_message.desc_message%TYPE;
        l_year         VARCHAR2(4);
        l_func_name    VARCHAR2(32) := 'GET_MY_STRING_DATE';
        l_tokens       table_varchar;
        l_replacements table_varchar;
        l_message      sys_message.desc_message%TYPE;
        l_timestamp    TIMESTAMP WITH TIME ZONE;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_timestamp,
                                             o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- Get month
        g_error := 'CALL TO_CHAR_INSTTIMEZONE FOR l_month';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp,
                                                  i_mask      => 'mm',
                                                  o_string    => l_month,
                                                  o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        l_month := pk_message.get_message(i_lang, g_msg_month_prefix || '_' || to_number(l_month));
    
        -- Get year
        g_error := 'CALL TO_CHAR_INSTTIMEZONE FOR l_month';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp,
                                                  i_mask      => 'yyyy',
                                                  o_string    => l_year,
                                                  o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        -- Set tokens to replace
        l_tokens       := table_varchar('@1', '@2');
        l_replacements := table_varchar(l_month, l_year);
        -- Get message to translate
        g_error   := 'GET MONTH OF YEAR MESSAGE';
        l_message := get_message(i_lang => i_lang, i_message => g_month_of_year);
        -- Replace tokens
        g_error := 'REPLACE TOKENS';
        RETURN replace_tokens(i_lang         => i_lang,
                              i_string       => l_message,
                              i_tokens       => l_tokens,
                              i_replacements => l_replacements,
                              o_string       => o_described_date,
                              o_error        => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_on;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_my_string_date;

    /**
    * Retrieve statistics for the available and scheduled appointments
    *
    * @param      i_lang             Professional default language
    * @param      i_prof             Professional object which refers the identity of the function caller
    * @param      i_args             Arguments used to retrieve stats
    * @param      o_vacants          Vacants information
    * @param      o_schedules        Schedule information
    * @param      o_titles           Title information
    * @param      o_flg_vancay       Vacancy flags information
    * @param      o_error            Error information if exists
    *
    * @return     boolean type       "False" on error or "True" if success
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/05/11
    *
    * UPDATED
    * ALERT-31987 - output da get_vacancies passa a ser a GTT sch_tmptab_vacs em vez do table_number
    * @author  Telmo
    * @date    12-06-2009
    * @version 2.5.0.4
    */
    FUNCTION get_schedules_statistics
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_args        IN table_varchar,
        o_vacants     OUT pk_types.cursor_type,
        o_schedules   OUT pk_types.cursor_type,
        o_titles      OUT pk_types.cursor_type,
        o_flg_vacancy OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCHEDULES_STATISTICS';
    
        l_list_vacancies table_number;
        l_list_schedules table_number;
    
        l_list_dcs   table_number := get_list_number_csv(i_args(idx_id_dep_clin_serv));
        l_list_event table_number := get_list_number_csv(i_args(idx_event));
        l_list_prof  table_number := get_list_number_csv(i_args(idx_id_prof));
    
        -- Inner function for getting vacants.
        FUNCTION inner_get_vacants RETURN pk_types.cursor_type IS
            c_vacants pk_types.cursor_type;
        BEGIN
            -- Available Vacants
            g_error := 'OPEN c_vacants FOR';
            OPEN c_vacants FOR
                SELECT se.id_sch_event intern_name, SUM(scv.max_vacancies - scv.used_vacancies) vacancies
                  FROM sch_tmptab_vacs stv
                  JOIN sch_consult_vacancy scv
                    ON stv.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
                  JOIN sch_event se
                    ON scv.id_sch_event = se.id_sch_event
                 GROUP BY se.id_sch_event
                 ORDER BY se.id_sch_event;
            RETURN c_vacants;
        END inner_get_vacants;
    
        FUNCTION inner_get_schedules(i_list_schedules table_number) RETURN pk_types.cursor_type IS
            c_schedules pk_types.cursor_type;
        BEGIN
            g_error := 'OPEN c_schedules FOR';
            -- Schedules
        
            OPEN c_schedules FOR
                SELECT *
                  FROM (SELECT /*+ first_rows */
                         se.id_sch_event intern_name, s.flg_vacancy status, COUNT(s.id_schedule) num_schedules
                          FROM schedule s, sch_event se
                         WHERE se.id_sch_event = s.id_sch_event
                           AND s.id_schedule IN (SELECT *
                                                   FROM TABLE(i_list_schedules))
                           AND s.flg_status <> g_sched_status_cancelled
                           AND se.flg_is_group = pk_alert_constant.g_no
                         GROUP BY se.id_sch_event, s.flg_vacancy
                        UNION ALL
                        SELECT /*+ first_rows */
                         se.id_sch_event intern_name, s.flg_vacancy status, SUM(used_vacancies) AS num_schedules
                          FROM schedule s, sch_event se, sch_consult_vacancy scv
                         WHERE se.id_sch_event = s.id_sch_event
                           AND s.id_schedule IN (SELECT *
                                                   FROM TABLE(i_list_schedules))
                           AND s.flg_status <> g_sched_status_cancelled
                           AND s.flg_sch_type = pk_alert_constant.g_yes
                           AND scv.id_sch_consult_vacancy = s.id_sch_consult_vacancy(+)
                         GROUP BY se.id_sch_event, s.flg_vacancy);
        
            RETURN c_schedules;
        END inner_get_schedules;
    
        FUNCTION inner_get_titles RETURN pk_types.cursor_type IS
            c_titles pk_types.cursor_type;
            l_events table_number;
        BEGIN
            l_events := get_list_number_csv(i_args(idx_event));
            g_error  := 'OPEN c_titles FOR';
            OPEN c_titles FOR
                SELECT /*+ first_rows */
                 se.id_sch_event,
                 pk_schedule_common.get_translation_alias(i_lang, i_prof, id_sch_event, code_sch_event) desc_event,
                 pk_translation.get_translation(i_lang, code_sch_event_abrv) desc_abrv_event,
                 (SELECT decode(COUNT(1), 0, g_yes, g_no)
                    FROM sch_event_inst sei
                   WHERE sei.id_institution = i_args(idx_id_inst)
                     AND sei.id_sch_event = se.id_sch_event
                     AND active = g_yes) flg
                  FROM sch_event se, sch_department sd
                
                 WHERE se.id_sch_event IN (SELECT *
                                             FROM TABLE(l_events))
                   AND se.dep_type = sd.flg_dep_type
                   AND sd.id_department = i_args(idx_id_dep);
        
            RETURN c_titles;
        END inner_get_titles;
    
    BEGIN
        -- Get vacancy identifiers.
        g_error := 'CALL GET_VACANCIES';
        IF NOT
            pk_schedule_common.get_vacancies(i_lang => i_lang, i_prof => i_prof, i_args => i_args, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Get vacancies
        g_error   := 'GET VACANTS';
        o_vacants := inner_get_vacants();
    
        -- Get schedule identifiers
        g_error := 'CALL GET_SCHEDULES';
        IF NOT pk_schedule_common.get_schedules(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_patient => NULL,
                                                i_args       => i_args,
                                                o_schedules  => l_list_schedules,
                                                o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Get schedules
        g_error     := 'GET SCHEDULES';
        o_schedules := inner_get_schedules(l_list_schedules);
    
        -- Get title information
        g_error  := 'GET TITLES';
        o_titles := inner_get_titles();
    
        -- Get list of vacancy flags.
        g_error := 'GET FLG_VACANCY LIST';
        RETURN pk_sysdomain.get_domains(i_lang        => i_lang,
                                        i_code_domain => g_schedule_flg_vacancy_domain,
                                        i_prof        => i_prof,
                                        o_domains     => o_flg_vacancy,
                                        o_error       => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_schedules);
            pk_types.open_my_cursor(o_vacants);
            pk_types.open_my_cursor(o_titles);
            pk_types.open_my_cursor(o_flg_vacancy);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_schedules_statistics;

    /*
    * Gets an image's name, according to the functionality type (next vacancies or appointments)
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_next_type      Next vacancies or appointments
    * @param i_schedule       Appointment
    * @param o_error          Error message (if an error occurred).
    *
    * @return     boolean type       "False" on error or "True" if success
    * @author     Tiago Ferreira
    * @version    alpha
    * @since      2007/05/11
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.3.x
    *
    * UPDATED
    * ALERT-9171
    * @author   Jose Antunes
    * @version  2.4.3.x
    * @date     04-11-2008
    */
    FUNCTION get_image_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_next_type IN sys_domain.code_domain%TYPE,
        i_schedule  IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_image_name VARCHAR2(30);
    BEGIN
        g_error := 'GET IMAGE NAME';
        IF (i_next_type = g_schedule_status_prof_vac)
        THEN
            SELECT decode(se.dep_type,
                          pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                          g_with_vacant,
                          pk_schedule_common.g_sch_dept_flg_dep_type_exam,
                          (SELECT decode(e.flg_type, g_image_exam_flg, g_with_vacant_exam, g_with_vacant_other_exams)
                             FROM exam e
                             JOIN schedule_exam sex
                               ON e.id_exam = sex.id_exam
                            WHERE sex.id_schedule = s.id_schedule
                              AND rownum = 1),
                          pk_schedule_common.g_sch_dept_flg_dep_type_oexams,
                          g_with_vacant_exam,
                          pk_schedule_common.g_sch_dept_flg_dep_type_anls,
                          g_with_vacant_analysis,
                          pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                          g_with_vacant_nurse,
                          pk_schedule_common.g_sch_dept_flg_dep_type_nut,
                          g_with_vacant_nutrition,
                          pk_schedule_common.g_sch_dept_flg_dep_type_as,
                          g_with_vacant,
                          pk_schedule_common.g_sch_dept_flg_dep_type_pm,
                          g_with_vacant_pmr)
              INTO l_image_name
              FROM schedule s, sch_event se
             WHERE s.id_schedule = i_schedule
               AND s.id_sch_event = se.id_sch_event;
        
        ELSIF (i_next_type = g_schedule_status_pat_sch)
        THEN
            SELECT decode(se.dep_type,
                          pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                          g_status_with_schedule,
                          pk_schedule_common.g_sch_dept_flg_dep_type_exam,
                          (SELECT decode(e.flg_type, g_image_exam_flg, g_with_vacant_exam, g_with_vacant_other_exams)
                             FROM exam e
                             JOIN schedule_exam sex
                               ON e.id_exam = sex.id_exam
                            WHERE sex.id_schedule = s.id_schedule
                              AND rownum = 1),
                          pk_schedule_common.g_sch_dept_flg_dep_type_anls,
                          g_status_with_schedule_a)
              INTO l_image_name
              FROM schedule s, sch_event se
             WHERE s.id_schedule = i_schedule
               AND s.id_sch_event = se.id_sch_event;
        END IF;
        RETURN l_image_name;
    END get_image_name;

    /*
    * Gets a patient's events that are inside a time range.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_id_patient     Patient identifier.
    * @param i_dt_schedule    Selected date.
    * @param o_future_apps    List of events.
    * @param o_error          Error message (if an error occurred).
    *
    * @return     boolean type       "False" on error or "True" if success
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/05/11
    *
    * REVISED
    * new scenario in sch_permission - prof1-prof2-dcs-evento.
    * @author  Telmo Castro
    * @date    16-05-2008
    * @version 2.4.3
    */
    FUNCTION get_proximity_events
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_dt_schedule IN VARCHAR2,
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
        IF NOT (get_config(i_lang         => i_lang,
                           i_id_sysconfig => g_range_proximity_events,
                           i_prof         => i_prof,
                           o_config       => l_config,
                           o_error        => o_error))
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error      := 'GET NUMERIC RANGE';
        l_days_range := to_number(l_config);
    
        g_error := g_sch_max_rec_events;
        -- Get range for filtering events by the proximity to the current date.
        IF NOT (get_config(i_lang         => i_lang,
                           i_id_sysconfig => g_sch_max_rec_events,
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
                           string_date(i_lang, i_prof, dt_begin_tstz) desc_dt_begin,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) nick_prof,
                           string_clin_serv_by_dcs(i_lang, id_dcs_requested) desc_dcs,
                           get_domain_desc(i_lang, g_schedule_flg_vacancy_domain, flg_vacancy) desc_type,
                           pk_date_utils.to_char_insttimezone(i_prof, dt_begin_tstz, g_default_time_mask_msg) hour_begin,
                           string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                           string_reason(i_lang, i_prof, id_reason, flg_reason_type) desc_reason,
                           nvl(desc_room, pk_translation.get_translation(i_lang, code_room)) desc_room,
                           get_domain_desc(i_lang, g_schedule_flg_status_domain, flg_status) desc_status,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_schedules) desc_author,
                           pk_date_utils.date_char_tsz(i_lang, dt_schedule_tstz, i_prof.institution, i_prof.software) desc_dt_schedule,
                           schedule_notes notes,
                           decode(v_dt_begin, NULL, g_no, g_yes) flg_prof_vacant,
                           g_icon_prefix ||
                           decode(v_dt_begin,
                                  NULL,
                                  pk_sysdomain.get_img(i_lang, g_schedule_status_prof_vac, g_without_vacant),
                                  pk_sysdomain.get_img(i_lang,
                                                       g_schedule_status_prof_vac,
                                                       get_image_name(i_lang,
                                                                      i_prof,
                                                                      g_schedule_status_prof_vac,
                                                                      id_schedule))) img_prof_vacant,
                           string_language(i_lang, id_lang_preferred) desc_lang_preferred,
                           string_language(i_lang, id_lang_translator) desc_lang_translator,
                           get_domain_desc(i_lang, g_sched_flg_notif_status, flg_notification) notification_status,
                           pk_translation.get_translation(i_lang, code_sch_event_abrv) desc_event_abrv,
                           string_origin(i_lang, id_origin) desc_origin
                      FROM (SELECT COUNT(1) over(PARTITION BY 1 ORDER BY 1) rcount,
                                   s.id_schedule,
                                   se.code_sch_event,
                                   s.dt_begin_tstz,
                                   s.dt_end_tstz,
                                   sr.id_professional,
                                   s.id_dcs_requested,
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
                                   se.id_sch_event,
                                   se.code_sch_event_abrv,
                                   s.id_origin,
                                   r.desc_room,
                                   s.flg_reason_type
                              FROM schedule s,
                                   sch_resource sr,
                                   sch_group sg,
                                   sch_event se,
                                   room r,
                                   (SELECT DISTINCT pk_date_utils.trunc_insttimezone(i_prof, dt_begin_tstz) dt_begin
                                      FROM sch_consult_vacancy scv
                                     WHERE scv.id_institution = i_prof.institution
                                       AND scv.id_prof = i_prof.id
                                       AND scv.max_vacancies > scv.used_vacancies
                                       AND scv.dt_begin_tstz >=
                                           pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, -l_days_range)
                                       AND scv.dt_begin_tstz <
                                           pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, l_days_range)
                                       AND scv.dt_begin_tstz >= l_trunc_dt_curr
                                       AND scv.flg_status = pk_schedule_bo.g_status_active) vacants
                             WHERE s.id_room = r.id_room(+)
                               AND sr.id_schedule(+) = s.id_schedule
                               AND sg.id_schedule(+) = s.id_schedule
                               AND se.id_sch_event = s.id_sch_event
                               AND s.dt_begin_tstz >= pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, -l_days_range)
                               AND s.dt_begin_tstz < pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, l_days_range)
                               AND s.flg_status IN (g_status_scheduled, g_status_pending)
                               AND sg.id_patient = i_id_patient
                               AND pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz) = vacants.dt_begin(+)
                               AND s.dt_begin_tstz >= l_trunc_dt_curr
                             ORDER BY s.dt_begin_tstz)
                     WHERE rownum <= l_num_records);
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_future_apps);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_proximity_events;

    /*
    * Gets a professional's schedules that are inside a time range.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_dt_schedule    Selected date
    * @param i_args           UI search arguments
    * @param o_future_apps    List of events.
    * @param o_error          Error message (if an error occurred).
    *
    * @return     boolean type       "False" on error or "True" if success
    * @author     Tiago Ferreira
    * @version    alpha
    * @since      2007/05/11
    *   
    * UPDATED: added the count_and_rank calculation
    * @author    Sofia Mendes 
    * @version    2.5.0.5
    * @since      2009/08/19
    */
    FUNCTION get_proximity_schedules
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_schedule IN VARCHAR2,
        i_args        IN table_varchar,
        o_future_apps OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_PROXIMITY_SCHEDULES';
        l_config        sys_config.value%TYPE;
        l_days_range    NUMBER(24);
        l_num_records   NUMBER(4);
        l_schedules     table_number;
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
        IF NOT (get_config(i_lang         => i_lang,
                           i_id_sysconfig => g_range_proximity_sch,
                           i_prof         => i_prof,
                           o_config       => l_config,
                           o_error        => o_error))
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error      := 'GET NUMERIC RANGE ';
        l_days_range := to_number(l_config);
    
        g_error := g_sch_max_rec_events;
        -- Get range for filtering events by the proximity to the current date.
        IF NOT (get_config(i_lang         => i_lang,
                           i_id_sysconfig => g_sch_max_rec_schedules,
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
    
        IF NOT pk_schedule_common.get_schedules(i_lang, i_prof, NULL, i_args, l_schedules, o_error)
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
        
            SELECT /*+ first_rows */
             *
              FROM (SELECT CASE
                                WHEN rcount > l_num_records THEN
                                 g_yes
                                ELSE
                                 g_no
                            END flg_max_rec,
                           id_schedule,
                           pk_schedule_common.get_translation_alias(i_lang, i_prof, id_sch_event, code_sch_event) desc_event,
                           pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                           string_date(i_lang, i_prof, dt_begin_tstz) desc_dt_begin,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) nick_prof,
                           string_clin_serv_by_dcs(i_lang, id_dcs_requested) desc_dcs,
                           get_domain_desc(i_lang, g_schedule_flg_vacancy_domain, flg_vacancy) desc_type,
                           pk_date_utils.to_char_insttimezone(i_prof, dt_begin_tstz, g_default_time_mask_msg) hour_begin,
                           string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                           string_reason(i_lang, i_prof, id_reason, flg_reason_type) desc_reason,
                           nvl(desc_room, pk_translation.get_translation(i_lang, code_room)) desc_room,
                           get_domain_desc(i_lang, g_schedule_flg_status_domain, flg_status) desc_status,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_schedules) desc_author,
                           string_date(i_lang, i_prof, dt_schedule_tstz) desc_dt_schedule,
                           schedule_notes notes,
                           decode(v_dt_begin, NULL, g_no, g_yes) flg_prof_vacant,
                           g_icon_prefix ||
                           decode(v_dt_begin,
                                  NULL,
                                  pk_sysdomain.get_img(i_lang, g_schedule_status_prof_vac, g_without_vacant),
                                  pk_sysdomain.get_img(i_lang,
                                                       g_schedule_status_prof_vac,
                                                       get_image_name(i_lang,
                                                                      i_prof,
                                                                      g_schedule_status_prof_vac,
                                                                      id_schedule))) img_prof_vacant,
                           string_language(i_lang, id_lang_preferred) desc_lang_preferred,
                           string_language(i_lang, id_lang_translator) desc_lang_translator,
                           get_domain_desc(i_lang, g_sched_flg_notif_status, flg_notification) notification_status,
                           pk_translation.get_translation(i_lang, code_sch_event_abrv) desc_event_abrv,
                           string_origin(i_lang, id_origin) desc_origin,
                           pk_schedule.get_count_and_rank(i_lang, id_schedule) AS count_and_rank
                      FROM (SELECT COUNT(1) over(PARTITION BY 1 ORDER BY 1) rcount,
                                   s.id_schedule,
                                   se.id_sch_event,
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
                                   s.flg_reason_type
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
                                               AND scv.flg_status = pk_schedule_bo.g_status_active
                                               AND scv.dt_begin_tstz >=
                                                   pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, -l_days_range)
                                               AND scv.dt_begin_tstz <
                                                   pk_date_utils.add_days_to_tstz(l_trunc_dt_sch, l_days_range)
                                               AND scv.dt_begin_tstz >= l_trunc_dt_curr)) vacants
                             WHERE s.id_room = r.id_room(+)
                               AND sr.id_schedule(+) = s.id_schedule
                               AND sg.id_schedule(+) = s.id_schedule
                               AND pat.id_patient(+) = sg.id_patient
                               AND se.id_sch_event = s.id_sch_event
                               AND dcs.id_dep_clin_serv = s.id_dcs_requested
                               AND s.id_schedule IN (SELECT *
                                                       FROM TABLE(CAST(l_schedules AS table_number)))
                               AND pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz) = vacants.dt_begin(+)
                               AND s.dt_begin_tstz >= l_trunc_dt_curr
                             ORDER BY s.dt_begin_tstz)
                     WHERE rownum <= l_num_records);
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_future_apps);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_proximity_schedules;

    /**
    * Identifies if the institution uses a generic appointment or not
    *
    * @param    i_lang          Language
    * @param    i_prof          Professional information (future use)
    * @param    i_institution   Institution to be verified
    * @param    o_flag          Flag with true or false result
    * @param    o_error         Error description if anything wrong occurs
    *
    * @author  Tiago Ferreira
    * @version alpha
    * @since   2007/02/13
    */
    FUNCTION get_generic_appoint_flag
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN VARCHAR2,
        o_flag        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_GENERIC_APPOINT_FLAG';
    BEGIN
        g_error := 'CHECK GENERIC';
        IF i_institution IS NOT NULL
        THEN
            SELECT decode(COUNT(1), 0, g_msg_false, g_msg_true)
              INTO o_flag
              FROM sch_event_inst
             WHERE id_institution = i_institution
               AND active = g_yes;
        ELSE
            o_flag := g_msg_false;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_generic_appoint_flag;

    /*
    * Gets the details of the schedules that are dragged, by dragging a full day into the clipboard
    *
    * @param i_lang
    * @param i_prof
    * @param i_args
    * @param o_schedules
    * @param o_error
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/14
    *
    * UPDATED
    * ALERT-708 - pesquisa por vagas livres.
    * @author   Telmo Castro
    * @date     25-03-2009
    * @version  2.5
    */
    FUNCTION get_schedules_to_clipboard
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_SCHEDULES_TO_CLIPBOARD';
        l_list_schedules table_number;
    BEGIN
        g_error := 'CALL GET_SCHEDULES';
        -- Get schedules that match the given criteria.
        IF get_only_vacs(i_args(idx_status)) = g_yes
        THEN
            pk_types.open_my_cursor(o_schedules);
        ELSE
            IF NOT pk_schedule_common.get_schedules(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_patient => NULL,
                                                    i_args       => i_args,
                                                    o_schedules  => l_list_schedules,
                                                    o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL GET_APPOINTMENT_CLIPBOARD_DETAILS';
            -- Get appointments' details to clipboard
            IF NOT get_appointments_clip_details(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_list_schedules => l_list_schedules,
                                                 o_schedules      => o_schedules,
                                                 o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_schedules);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_schedules_to_clipboard;

    /**
    * Gets all the vacancy types for the multi-choice
    *
    * @param      i_lang             Language identifier.
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_flg_search       Whether or not should the 'All' option be listed
    * @param      o_vacancy_types    List of vacancy types
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/05/14
    */
    FUNCTION get_vacancy_types
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_search    IN VARCHAR2,
        o_vacancy_types OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_VACANCY_TYPES';
    BEGIN
        g_error := 'OPEN o_vacancy_types FOR';
    
        OPEN o_vacancy_types FOR
            SELECT data, label, flg_select, order_field
              FROM (SELECT to_char(g_all) data,
                           pk_message.get_message(i_lang, g_msg_all) label,
                           g_no flg_select,
                           1 order_field
                      FROM dual
                     WHERE i_flg_search = g_yes
                    UNION ALL
                    SELECT val data,
                           desc_val label,
                           decode(val, pk_schedule_common.g_sched_vacancy_routine, g_yes, g_no) flg_select,
                           9 order_field
                      FROM sys_domain sd
                     WHERE sd.code_domain = g_schedule_flg_vacancy_domain
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang)
             ORDER BY order_field, label ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_vacancy_types);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_vacancy_types;

    /**
    * Checks if a professional has write access to another professional or some clinical service's schedule
    *
    * @param    i_lang                   Language
    * @param    i_prof                   Professional information
    * @param    i_id_dep_clin_serv       Department-Clinical service
    * @param    i_id_sch_event           Event
    * @param    i_id_prof                Target professional
    *
    * @author  Tiago Ferreira
    * @version alpha
    * @since   2007/02/13
    *
    * UPDATED
    * new sch_permission scenarios: prof1+prof2+dcs OR prof1+dcs
    * @author  Telmo Castro
    * @date    19-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * k.i.s.s.
    * @author  Telmo Castro
    * @date    19-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * Protection of select against data on sch_permission
    * @author  Jose Antunes
    * @date    20-03-2009
    * @version 2.4.3 
    *
    * UPDATED
    * New parameter i_id_institution
    * @author  Sofia Mendes
    * @date    28-07-2009
    * @version 2.5.0.5 
    */
    FUNCTION has_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE DEFAULT NULL,
        i_id_institution   IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_permission     VARCHAR2(10);
        l_func_name      VARCHAR2(32) := 'HAS_PERMISSION';
        l_id_institution institution.id_institution%TYPE;
    BEGIN
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        ELSE
            l_id_institution := i_id_institution;
        END IF;
        -- Retrieve schedule information
        g_error := 'GET PERMISSION BY PROFESSIONAL';
        SELECT decode(flg_permission, g_permission_schedule, g_msg_true, g_msg_false)
          INTO l_permission
          FROM sch_permission
         WHERE id_professional = i_prof.id
           AND id_sch_event = i_id_sch_event
           AND id_institution = l_id_institution --i_prof.institution
           AND (id_prof_agenda IS NULL OR i_id_prof IS NULL OR id_prof_agenda = i_id_prof)
           AND id_dep_clin_serv = i_id_dep_clin_serv
           AND rownum = 1
           AND pk_schedule_common.get_sch_event_avail(i_id_sch_event, i_id_institution, i_prof.software) =
               pk_alert_constant.g_yes
         ORDER BY id_prof_agenda;
    
        RETURN l_permission;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN g_msg_false;
        WHEN OTHERS THEN
            -- Unexpected error
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN g_msg_false;
    END has_permission;

    /*
    * This funtion is a wrappwer to the previous has_permission funtion to be used when 
    * the institution (of the schedule) is the same of the i_prof institution
    * Sofia Mendes 28/07/2009
    */
    FUNCTION has_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_permission VARCHAR2(10);
        l_func_name  VARCHAR2(32) := 'HAS_PERMISSION';
    BEGIN
        l_permission := has_permission(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_dep_clin_serv => i_id_dep_clin_serv,
                                       i_id_sch_event     => i_id_sch_event,
                                       i_id_prof          => i_id_prof,
                                       i_id_institution   => i_prof.institution);
    
        RETURN l_permission;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN g_msg_false;
        WHEN OTHERS THEN
            -- Unexpected error
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN g_msg_false;
    END has_permission;

    /**
    * Checks if a professional list, associated to schedule (SCH_RESOURCE), has write access to another professional or some clinical service's schedule
    *
    * @param    i_lang                   Language
    * @param    i_prof                   Professional information
    * @param    i_id_dep_clin_serv       Department-Clinical service
    * @param    i_id_sch_event           Event
    * @param    i_id_schedule            Schedule ID
    *
    * @author  Nuno Miguel Ferreira
    * @version 2.5.0.4
    * @since   2009/06/23
    *
    * UPDATED: new parameter: i_id_institution
    * @version 2.5.0.5
    * @since   2009/07/31
    */
    FUNCTION has_permission_by_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name      VARCHAR2(32) := 'HAS_PERMISSION_BY_SCHEDULE';
        l_id_prof_list   table_number;
        l_flg_permission BOOLEAN;
        l_idx            NUMBER;
        l_id_institution institution.id_institution%TYPE := i_id_institution;
    BEGIN
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        g_error := 'SELECT SCHEDULE RESOURCES';
        SELECT id_professional
          BULK COLLECT
          INTO l_id_prof_list
          FROM sch_resource schr
         WHERE schr.id_schedule = i_id_schedule;
    
        IF l_id_prof_list.count > 0
        THEN
            l_idx            := 1;
            l_flg_permission := TRUE;
            WHILE l_idx <= l_id_prof_list.last
                  AND l_flg_permission
            LOOP
                l_flg_permission := has_permission(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                   i_id_sch_event     => i_id_sch_event,
                                                   i_id_prof          => l_id_prof_list(l_idx),
                                                   i_id_institution   => l_id_institution) = g_msg_true;
                l_idx            := l_idx + 1;
            END LOOP;
        ELSE
            RETURN g_msg_false;
        END IF;
    
        RETURN CASE WHEN l_flg_permission THEN g_msg_true ELSE g_msg_false END;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN g_msg_false;
    END has_permission_by_schedule;

    /*
    * Gets the schedule's patients.
    *
    * @param i_lang                         Language.
    * @param i_prof                         Professional.
    * @param i_id_schedule                  Schedule identifier.
    * @param o_patients                     Details.
    * @param o_error                        Error message, if an error occurred.
    *
    * @return  True if successful, false otherwise.
    *
    * @author  Sofia Mendes
    * @version 2.5.x
    * @since   2009/06/17
    *    
    */
    FUNCTION get_schedule_patients
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_patients    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCHEDULE_PATIENTS';
    BEGIN
        g_error := 'OPEN o_patients FOR';
        -- Open cursor
        OPEN o_patients FOR
            SELECT sg.id_patient, pk_patient.get_patient_name(i_lang, sg.id_patient) patient_name
              FROM schedule s
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
             WHERE s.id_schedule = i_id_schedule;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_patients);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_schedule_patients;

    /**********************************************************************************************
    * Returns a string containig the event nr and the event date/hour.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_id_schedule            Schedule recursion id
    *
    * @return                         varchar2
    *                        
    * @author                         Sofia Mendes
    * @version                        2.5.0.7.6
    * @since                          2010/01/29
    **********************************************************************************************/
    FUNCTION get_schedule_referral
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN p1_external_request.id_external_request%TYPE IS
        l_error               t_error_out;
        l_id_external_request p1_external_request.id_external_request%TYPE := NULL;
        l_num_req             p1_external_request.num_req%TYPE;
        l_func_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PK_REF_MODULE.GET_REF_SCH_TO_CANCEL';
        IF NOT pk_ref_module.get_ref_sch(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_schedule         => i_id_schedule,
                                         o_id_external_request => l_id_external_request,
                                         o_num_req             => l_num_req,
                                         o_error               => l_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        RETURN l_num_req;
    EXCEPTION
        WHEN no_data_found THEN
            l_num_req := NULL;
            RETURN l_num_req;
        WHEN OTHERS THEN
            l_num_req := NULL;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCHEDULE_REFERRAL',
                                              o_error    => l_error);
            RETURN l_num_req;
    END get_schedule_referral;

    /*
    * Gets the schedule's details.
    *
    * @param i_lang                         Language.
    * @param i_prof                         Professional.
    * @param i_id_schedule                  Schedule identifier.
    * @param o_schedule_details             Details.
    * @param o_error                        Error message, if an error occurred.
    *
    * @return  True if successful, false otherwise.
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/14
    *
    * UPDATED
    * acrescentados campos s.flg_schedule_via e so.flg_sched_request_type e dt.
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     30-04-2008
    * UPDATED
    * acrescentados campos end_time, desc_schedule_via e desc_sched_request_type
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     24-05-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * acrescentadas colunas schedule_time e schedule_Date ao cursor
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * alterado parametro desc_reason do cursor o_schedule_details
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    04-09-2008
    *
    * UPDATED
    * acrescentados campos com IDs e flags da tabela schedule - ALERT-17795 
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    20-02-2009
    */
    FUNCTION get_schedule_details
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        o_schedule_details OUT pk_types.cursor_type,
        o_patients         OUT pk_types.cursor_type,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCHEDULE_DETAILS';
    BEGIN
        g_error := 'OPEN o_schedule_details FOR';
        -- Open cursor
        OPEN o_schedule_details FOR
            SELECT get_domain_desc(i_lang, g_schedule_flg_vacancy_domain, s.flg_vacancy) desc_type,
                   string_date(i_lang, i_prof, s.dt_begin_tstz) || ' ' ||
                   pk_date_utils.to_char_insttimezone(i_prof, s.dt_begin_tstz, g_default_time_mask_msg) desc_time,
                   pk_date_utils.to_char_insttimezone(i_prof, s.dt_end_tstz, g_default_time_mask_msg) end_time,
                   string_duration(i_lang, s.dt_begin_tstz, s.dt_end_tstz) desc_duration,
                   string_room(i_lang, s.id_room) desc_room,
                   get_domain_desc(i_lang, g_schedule_flg_status_domain, s.flg_status) desc_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, s.id_prof_schedules) desc_scheduling_prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    s.id_prof_schedules,
                                                    s.dt_schedule_tstz,
                                                    s.id_episode) desc_spec_sch_prof,
                   string_date(i_lang, i_prof, s.dt_schedule_tstz) dt_schedule,
                   s.schedule_notes notes,
                   string_language(i_lang, s.id_lang_preferred) desc_lang_preferred,
                   string_language(i_lang, s.id_lang_translator) desc_lang_translator,
                   string_origin(i_lang, s.id_origin) desc_origin,
                   string_reason(i_lang, i_prof, s.id_reason, s.flg_reason_type) desc_reason,
                   s.id_cancel_reason,
                   pk_translation.get_translation(1, 'SCH_CANCEL_REASON.CODE_CANCEL_REASON.' || s.id_cancel_reason) ||
                   chr(13) || s.schedule_cancel_notes AS schedule_cancel_notes,
                   s.flg_schedule_via,
                   pk_sysdomain.get_domain(g_sched_flg_sch_via, s.flg_schedule_via, i_lang) desc_schedule_via,
                   s.flg_request_type,
                   pk_sysdomain.get_domain(g_sched_flg_req_type, s.flg_request_type, i_lang) desc_sched_request_type,
                   string_date(i_lang, i_prof, s.dt_cancel_tstz) || ' / ' ||
                   pk_prof_utils.get_name_signature(i_lang, i_prof, s.id_prof_cancel) author_cancel,
                   get_domain_desc(i_lang, g_sched_flg_notif_status, s.flg_notification) notification_status,
                   get_schedule_referral(i_lang, i_prof, s.id_schedule) referral_num,
                   pk_date_utils.dt_chr_tsz(i_lang, s.dt_schedule_tstz, i_prof.institution, i_prof.software) schedule_date,
                   pk_date_utils.to_char_insttimezone(i_prof, s.dt_schedule_tstz, g_default_time_mask_msg) schedule_time,
                   pk_schedule.string_clin_serv_by_dcs(i_lang, s.id_dcs_requested) dcs_description,
                   pk_schedule.string_sch_event(i_lang, s.id_sch_event) event_description,
                   s.id_lang_translator,
                   s.id_lang_preferred,
                   s.id_reason,
                   s.id_origin,
                   s.id_room,
                   s.id_episode,
                   --s.id_complaint,
                   s.flg_vacancy,
                   s.flg_request_type,
                   s.flg_schedule_via,
                   scv.max_vacancies  AS max_vacancies
              FROM schedule s, schedule_outp so, /*referral_ea exr,*/ sch_consult_vacancy scv
             WHERE s.id_schedule = i_id_schedule
                  --AND exr.id_schedule(+) = s.id_schedule
               AND so.id_schedule(+) = s.id_schedule
               AND s.id_sch_consult_vacancy = scv.id_sch_consult_vacancy(+);
    
        g_error := 'CALL GET_SCHEDULE_PATIENTS';
        IF NOT get_schedule_patients(i_lang        => i_lang,
                                     i_prof        => i_prof,
                                     i_id_schedule => i_id_schedule,
                                     o_patients    => o_patients,
                                     o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_schedule_details);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_schedule_details;

    /*
    * returns list of eventual schedules (not yet created) for a single visit.
    * to be used in the popup that open when the user drags the patient into one of the marked vacancies
    * belonging to a combo. 
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_combi           combination id
    * @param i_ids_codes          combo lines to be processed. its a table_table_number with pairs of (id_code, id_vacancy). 
    * @param o_sv_details         output cursor
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     26-06-2009
    *
    * UPDATED alert-8202. sch_consult_vac_exam demise
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    20-10-2009
    */
    FUNCTION get_schedule_sv_details
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_combi   IN sch_combi.id_sch_combi%TYPE,
        i_ids_codes  IN table_table_number,
        o_sv_details OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCHEDULE_SV_DETAILS';
        rec         t_rec_sch_combi;
        tabl        t_tab_sch_combi := t_tab_sch_combi();
        i           INTEGER;
    BEGIN
    
        g_error := 'TRANSFORM table_table_number INTO t_tab_sch_combi';
    
        IF i_ids_codes IS NOT NULL
           AND i_ids_codes.count > 0
        THEN
            i := i_ids_codes.first;
            WHILE i IS NOT NULL
            LOOP
                IF i_ids_codes(i) IS NOT NULL
                   AND i_ids_codes(i).count = 2
                THEN
                    rec := t_rec_sch_combi(i_ids_codes(i) (1), i_ids_codes(i) (2));
                    tabl.extend(1);
                    tabl(tabl.last) := rec;
                    i := i_ids_codes.next(i);
                END IF;
            
            END LOOP;
        END IF;
    
        -- open cursor
        g_error := 'open o_sv_details cursor';
        OPEN o_sv_details FOR
            SELECT t.id_code,
                   t.id_vac,
                   string_clin_serv_by_dcs(i_lang, v.id_dep_clin_serv) desc_dcs,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
                   sdt.dep_type sch_type,
                   pk_translation.get_translation(i_lang, code_dep_type) desc_sch_type,
                   string_room(i_lang, v.id_room) desc_room,
                   string_institution(i_lang, v.id_institution) desc_institution,
                   string_duration(i_lang, v.dt_begin_tstz, v.dt_end_tstz) desc_duration,
                   string_date(i_lang, i_prof, v.dt_begin_tstz) data,
                   pk_date_utils.to_char_insttimezone(i_prof, v.dt_begin_tstz, g_default_time_mask_msg) start_time,
                   pk_date_utils.to_char_insttimezone(i_prof, v.dt_end_tstz, g_default_time_mask_msg) end_time,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, v.id_prof) prof_name
              FROM TABLE(tabl) t
              JOIN sch_consult_vacancy v
                ON t.id_vac = v.id_sch_consult_vacancy
              JOIN sch_event se
                ON v.id_sch_event = se.id_sch_event
              JOIN sch_dep_type sdt
                ON se.dep_type = sdt.dep_type
             ORDER BY t.id_code;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sv_details);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_schedule_sv_details;

    /**
    * Set a new schedule notification.
    *
    * @param    i_lang           Language
    * @param    i_prof           Professional
    * @param    i_id_schedule    Schedule identification
    * @param    i_notification   Notification flag
    * @param    o_error           Error message if something goes wrong
    *
    * @author  Tiago Ferreira
    * @version 1.0
    * @since   2006/12/21
    *
    * UPDATED
    * added call to pk_p1_ext_sys.update_referral_status
    * @author  Jose Antunes
    * @date    04-08-2008
    * @version 2.4.3
    *
    * UPDATED
    * DesnormalizaÁ„o 
    * @author  Joana Barroso
    * @date    26-09-2008
    * @version 2.4.3d
    *
    * UPDATED
    * new parameter: i_id_notification_via 
    * @author  Sofia Mendes
    * @date    03-07-2009
    * @version 2.5.4
    */
    FUNCTION set_schedule_notification
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_schedule   IN schedule.id_schedule%TYPE,
        i_notification  IN schedule.flg_notification%TYPE,
        i_flg_notif_via IN schedule.flg_notification_via%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_notification    schedule.flg_notification%TYPE;
        l_flg_status          schedule.flg_status%TYPE;
        l_id_external_request p1_external_request.id_external_request%TYPE;
        l_func_name           VARCHAR2(32) := 'SET_SCHEDULE_NOTIFICATION';
        l_func_exception EXCEPTION;
        l_flg_notif_via schedule.flg_notification_via%TYPE := i_flg_notif_via;
    BEGIN
        g_error := 'GET FLG_NOTIFICATION';
        -- Check if schedule exists
        SELECT flg_notification, flg_status, flg_notification_via
          INTO l_flg_notification, l_flg_status, l_flg_notif_via
          FROM schedule
         WHERE id_schedule = i_id_schedule;
    
        IF (i_flg_notif_via IS NOT NULL)
        THEN
            l_flg_notif_via := i_flg_notif_via;
        END IF;
    
        UPDATE schedule s
           SET s.flg_notification     = i_notification,
               s.dt_notification_tstz = CASE
                                             WHEN i_notification = g_sched_flg_notif_pending THEN
                                              NULL
                                             ELSE
                                              current_timestamp
                                         END,
               s.id_prof_notification = CASE
                                             WHEN i_notification = g_sched_flg_notif_pending THEN
                                              NULL
                                             ELSE
                                              i_prof.id
                                         END,
               s.flg_notification_via = CASE
                                             WHEN i_notification = g_sched_flg_notif_pending THEN
                                              NULL
                                             ELSE
                                              l_flg_notif_via
                                         END
         WHERE id_schedule = i_id_schedule;
    
        BEGIN
        
            /*g_error := 'CHECK IF SCHEDULE IS MATCHED WITH P1';
            SELECT per.id_external_request
              INTO l_id_external_request
              FROM p1_external_request per
             WHERE per.id_schedule = i_id_schedule
               AND l_flg_status != g_status_canceled;*/
        
            g_error := 'CALL TO pk_ref_module.get_ref_sch_to_cancel with id_schedule=' || i_id_schedule;
            IF NOT pk_ref_module.get_ref_sch_to_cancel(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_schedule         => i_id_schedule,
                                                       o_id_external_request => l_id_external_request,
                                                       o_error               => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            IF i_notification IN (g_notification_conf, g_notification_notif)
               AND l_id_external_request IS NOT NULL
            THEN
                g_error := 'CALL pk_ref_ext_sys.set_ref_notify WITH id_external = ' || l_id_external_request;
                IF NOT pk_ref_ext_sys.set_ref_notify(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_id_ref   => l_id_external_request,
                                                     i_schedule => i_id_schedule,
                                                     i_notes    => NULL,
                                                     o_error    => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- Se nao existe P1, nao tem que actualizar o estado            
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN no_data_found THEN
            RETURN TRUE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_schedule_notification;

    /*
    * integration version
    */
    FUNCTION set_schedule_notification
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_notification   IN schedule.flg_notification%TYPE,
        i_flg_notif_via  IN schedule.flg_notification_via%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_notification    schedule.flg_notification%TYPE;
        l_flg_status          schedule.flg_status%TYPE;
        l_id_external_request p1_external_request.id_external_request%TYPE;
        l_func_name           VARCHAR2(32) := 'SET_SCHEDULE_NOTIFICATION';
        l_func_exception EXCEPTION;
        l_flg_notif_via schedule.flg_notification_via%TYPE := i_flg_notif_via;
        l_id_patient    p1_external_request.id_patient%TYPE;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'GET FLG_NOTIFICATION';
        -- Check if schedule exists
        SELECT s.flg_notification, s.flg_status, s.flg_notification_via
          INTO l_flg_notification, l_flg_status, l_flg_notif_via
          FROM schedule s
         WHERE id_schedule = i_id_schedule;
    
        IF (i_flg_notif_via IS NOT NULL)
        THEN
            l_flg_notif_via := i_flg_notif_via;
        END IF;
    
        -- actualizacao da tabela antiga do scheduler
        g_error := 'UPDATE SCH NOTIFY PERSON';
        CASE l_flg_notification
            WHEN 'N' THEN
                IF NOT pk_schedule_api_upstream.notify_person(i_lang                 => i_lang,
                                                              i_prof                 => i_prof,
                                                              i_id_schedule          => i_id_schedule,
                                                              i_id_patient           => l_id_patient,
                                                              i_flg_notification_via => CASE
                                                                                            WHEN i_notification = g_sched_flg_notif_pending THEN
                                                                                             NULL
                                                                                            ELSE
                                                                                             l_flg_notif_via
                                                                                        END,
                                                              i_id_professional      => CASE
                                                                                            WHEN i_notification = g_sched_flg_notif_pending THEN
                                                                                             NULL
                                                                                            ELSE
                                                                                             i_prof.id
                                                                                        END,
                                                              i_dt_notification      => CASE
                                                                                            WHEN i_notification = g_sched_flg_notif_pending THEN
                                                                                             NULL
                                                                                            ELSE
                                                                                             current_timestamp
                                                                                        END,
                                                              i_transaction_id       => l_transaction_id,
                                                              o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            WHEN 'C' THEN
                IF NOT pk_schedule_api_upstream.confirm_person(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_id_schedule    => i_id_schedule,
                                                               i_id_patient     => l_id_patient,
                                                               i_prof_confirm   => i_prof,
                                                               i_confirm_date   => current_timestamp,
                                                               i_transaction_id => l_transaction_id,
                                                               o_error          => o_error)
                
                THEN
                    RAISE g_exception;
                END IF;
            
        END CASE;
    
        BEGIN
        
            g_error := 'CHECK IF SCHEDULE IS MATCHED WITH P1';
            SELECT per.id_external_request, per.id_patient
              INTO l_id_external_request, l_id_patient
              FROM p1_external_request per
             WHERE per.id_schedule = i_id_schedule
               AND l_flg_status != g_status_canceled;
        
            g_error := 'CALL UPDATE_REFERRAL_STATUS';
            IF i_notification IN (g_notification_conf, g_notification_notif)
            THEN
                IF NOT pk_p1_ext_sys.update_referral_status(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_ext_req    => l_id_external_request,
                                                            i_id_sch     => i_id_schedule,
                                                            i_status     => g_status_mailed,
                                                            i_notes      => NULL,
                                                            i_reschedule => g_no,
                                                            o_error      => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- Se nao existe P1, nao tem que actualizar o estado
        END;
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        IF NOT pk_schedule_api_upstream.notify_person(i_lang                 => i_lang,
                                                 i_prof                 => i_prof,
                                                 i_id_schedule          => i_id_schedule,
                                                 i_id_patient           => l_id_patient,
                                                 i_flg_notification_via => CASE
                                                                               WHEN i_notification = g_sched_flg_notif_pending THEN
                                                                                NULL
                                                                               ELSE
                                                                                l_flg_notif_via
                                                                           END,
                                                 i_id_professional      => CASE
                                                                               WHEN i_notification = g_sched_flg_notif_pending THEN
                                                                                NULL
                                                                               ELSE
                                                                                i_prof.id
                                                                           END,
                                                 i_dt_notification      => CASE
                                                                               WHEN i_notification = g_sched_flg_notif_pending THEN
                                                                                NULL
                                                                               ELSE
                                                                                current_timestamp
                                                                           END,
                                                 i_transaction_id       => l_transaction_id,
                                                 o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        WHEN no_data_found THEN
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_schedule_notification;

    /*
    * Gets a professional's permission to access a given professional's schedule.
    *
    * @param    i_lang                 Language identifier.
    * @param    i_prof                 Professional.
    * @param    i_id_dep_clin_serv     Department-Clinical service identifier.
    * @param    i_id_sch_event         Event identifier.
    * @param    i_id_prof              Professsional identifier (target professional).
    * @param    o_error                Error message if something goes wrong
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/15
    *
    * UPDATED
    * new sch_permission scenarios: prof1+prof2+dcs OR prof1+dcs
    * @author  Telmo Castro
    * @date    19-05-2008
    * @version 2.4.3
    */
    FUNCTION get_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE DEFAULT NULL,
        o_permission       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PERMISSION';
    BEGIN
        BEGIN
            SELECT sp.flg_permission
              INTO o_permission
              FROM sch_permission sp, sch_event se
             WHERE sp.id_institution = i_prof.institution
               AND sp.id_professional = i_prof.id
               AND sp.id_sch_event = i_id_sch_event
               AND se.id_sch_event = sp.id_sch_event
               AND sp.id_dep_clin_serv = i_id_dep_clin_serv
               AND (i_id_prof IS NULL OR sp.id_prof_agenda = i_id_prof)
               AND pk_schedule_common.get_sch_event_avail(i_id_sch_event, i_prof.institution, i_prof.software) =
                   pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                o_permission := NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_permission;

    /*
    * Gets the patient's icons.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            Professional
    * @param i_args            UI args.
    * @param i_id_patient      Patient identifier.
    * @param o_patient_icons   Patient icons.
    * @param o_error           Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    *
    * UPDATED 
    * Adapted for MFR scheduler
    * @author  Telmo Castro 
    * @date    19-01-2009
    * @version 2.4.3.x
    */
    FUNCTION get_patient_icons
    (
        i_lang          language.id_language%TYPE,
        i_prof          profissional,
        i_args          table_varchar,
        i_id_patient    patient.id_patient%TYPE,
        o_patient_icons OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_PATIENT_ICONS';
        l_list_status table_varchar := get_list_string_csv(i_args(idx_status));
        l_dt_begin    TIMESTAMP WITH TIME ZONE;
        l_dt_end      TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'START';
        IF i_args IS NULL
           OR i_args.count = 0
           OR i_id_patient IS NULL
        THEN
            pk_types.open_my_cursor(o_patient_icons);
        ELSE
            pk_date_utils.set_dst_time_check_off;
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
            -- Convert begin date to timestamp
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_args(idx_dt_begin),
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_begin,
                                                 o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
            -- Convert end date to timestamp
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_args(idx_dt_end),
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_end,
                                                 o_error     => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            g_error := 'OPEN o_patient_icons FOR';
            OPEN o_patient_icons FOR
                SELECT DISTINCT dt_begin, img
                  FROM (SELECT pk_date_utils.date_send_tsz(i_lang,
                                                           pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz, 'DD'),
                                                           i_prof) dt_begin,
                               decode(sd.flg_dep_type,
                                      pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                                      g_consult_icon,
                                      pk_schedule_common.g_sch_dept_flg_dep_type_exam,
                                      g_exam_icon,
                                      pk_schedule_common.g_sch_dept_flg_dep_type_anls,
                                      g_exam_icon,
                                      pk_schedule_common.g_sch_dept_flg_dep_type_pm,
                                      g_mfr_icon,
                                      '') img
                          FROM schedule s, sch_group sg, sch_department sd, sch_event se
                         WHERE sg.id_schedule = s.id_schedule
                           AND se.id_sch_event = s.id_sch_event
                           AND sd.flg_dep_type = se.dep_type
                           AND s.id_instit_requested = i_prof.institution
                           AND s.dt_begin_tstz >= l_dt_begin
                           AND (i_args(idx_dt_end) IS NULL OR s.dt_begin_tstz < l_dt_end)
                           AND ((i_args(idx_status) IS NULL AND s.flg_status <> g_sched_status_cancelled) OR
                               s.flg_status IN (SELECT *
                                                   FROM TABLE(l_list_status)))
                           AND (i_id_patient IS NOT NULL AND sg.id_patient = i_id_patient))
                 ORDER BY dt_begin;
        
            pk_date_utils.set_dst_time_check_on;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_patient_icons);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_patient_icons;

    /*
    * Creates a generic schedule (exams, consults, analysis, etc).
    * All other create functions should use this for core functionality.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_flg_vacancy        Vacancy flag.
    * @param i_schedule_notes     Notes.
    * @param i_id_lang_translator Translator's language identifier.
    * @param i_id_lang_preferred  Preferred language identifier.
    * @param i_id_reason          Reason.
    * @param i_id_origin          Origin.
    * @param i_id_schedule_ref    Appointment that this appointment replaces (on reschedules).
    * @param i_id_room            Room.
    * @param i_reason_notes       Reason for appointment in free-text.
    * @param i_show_vacancy_warn  Whether or not should a warning be issued if no vacancies are available.
    * @param i_do_overlap         null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be
    *                             issued with Y or N
    * @param i_id_consult_vac     id da vaga. Pode vir null
    * @param i_sch_option         'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule); 'X'=forÁar o sem vaga
    * @param i_id_episode         episode id
    * @param i_id_sch_combi_detail used in single visit. this id relates this schedule with the combination detail line
    * @param o_id_schedule        Identifier of the new schedule.
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_overlapfound       an overlap was found while trying to save this schedule and no instruction was given on how to decide
    * @param o_error              Error message if something goes wrong
    *
    * @return   True if successful, false otherwise or if overlap found and no do_overlap supplied
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     26-05-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * novo campo id_episode
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    13-06-2008
    *
    * UPDATED
    * a flg_sch_type passa a ser calculada aqui
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    25-08-2008
    *
    * UPDATED
    * novo campo i_id_complaint
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    04-09-2008
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.3.x
    *
    * UPDATED
    * alert-7740. getting vacancy data needs permission check 
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     17-10-2008
    *
    * UPDATED
    * ALERT-10162. updated call to check_vacancy_usage - new parameter i_id_dept. 
    * Also, new message screen to respond to l_vacancy_needed exceptions.
    * @author  Telmo Castro
    * @date    19-11-2008
    * @version 2.4.3.x
    *
    * UPDATED
    * ALERT-11352.
    * Implementation of the 'edit vacancy' option inside the create_schedule. 
    * Such option can arise when the user changes one or more parameters that turn the previous chosen vacancy inadequate.
    * When that happens, there are 2 ways of action. If sch_vacancy configuration says we can edit the vacancy, then that is
    * the preferred action. Otherwise, the schedule is created without a vacancy association.
    * @author  Telmo Castro
    * @date    12-12-2008
    * @version 2.4.3.x
    *
    * UPDATED
    * Change i_id_patient data type from number to table_number (because of group schedules)
    * @author  Sofia Mendes
    * @date     15-06-2009
    * @version  2.5.x
    *
    * UPDATED
    * ALERT-34561. no_data_founds vindos desta funÁao vao directamente para o UI. 
    * a partir de agora passam a ser apresentados como mensagem na popup das validacoes
    * @author  Telmo
    * @version 2.5.0.4
    * @date    15-07-2009
    *
    * UPDATED
    * New parameter i_id_institution: in order to allow to schedule to a institution diferent from i_prof.institution
    * @author  Sofia Mendes
    * @date     29-07-2009
    * @version  2.5.0.5
    *
    * UPDATED alert-8202. deixa de receber o id_exam
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    13-10-2009
    */
    FUNCTION create_schedule
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN table_number,
        i_id_dep_clin_serv      IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event          IN schedule.id_sch_event%TYPE,
        i_id_prof               IN sch_resource.id_professional%TYPE,
        i_dt_begin              IN VARCHAR2,
        i_dt_end                IN VARCHAR2,
        i_flg_vacancy           IN schedule.flg_vacancy%TYPE,
        i_schedule_notes        IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator    IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred     IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason             IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin             IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_schedule_ref       IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_room               IN schedule.id_room%TYPE DEFAULT NULL,
        i_flg_sch_type          IN schedule.flg_sch_type%TYPE,
        i_id_analysis           IN analysis.id_analysis%TYPE DEFAULT NULL,
        i_reason_notes          IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type      IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via      IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_show_vacancy_warn     IN BOOLEAN DEFAULT TRUE,
        i_do_overlap            IN VARCHAR2,
        i_id_consult_vac        IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option            IN VARCHAR2,
        i_id_episode            IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_complaint          IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_flg_present           IN schedule.flg_present%TYPE DEFAULT NULL,
        i_id_prof_leader        IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        i_id_multidisc          IN schedule.id_multidisc%TYPE DEFAULT NULL,
        i_id_sch_combi_detail   IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        i_id_schedule_recursion IN schedule_recursion.id_schedule_recursion%TYPE DEFAULT NULL,
        i_flg_status            IN schedule.flg_status%TYPE DEFAULT NULL,
        i_id_institution        IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule           OUT schedule.id_schedule%TYPE,
        o_flg_proceed           OUT VARCHAR2,
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(18) := 'CREATE_SCHEDULE';
        l_id_inst              department.id_institution%TYPE;
        l_flg_status           schedule.flg_status%TYPE;
        l_schedule_rec         schedule%ROWTYPE;
        l_sch_group_rec        sch_group%ROWTYPE;
        l_sch_resource_rec     sch_resource%ROWTYPE;
        l_id_sch_event         sch_event.id_sch_event%TYPE;
        l_schedule_interface   BOOLEAN;
        l_notification_default sch_dcs_notification.notification_default%TYPE;
        l_occupied             sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_dt_begin             TIMESTAMP WITH TIME ZONE;
        l_dt_end               TIMESTAMP WITH TIME ZONE;
    
        l_vacancy_usage BOOLEAN;
        l_sched_w_vac   BOOLEAN;
        l_edit_vac      BOOLEAN;
        l_vacancy_needed   EXCEPTION;
        l_invalid_option   EXCEPTION;
        l_unexvacfound     EXCEPTION;
        l_overlapfound     EXCEPTION;
        l_no_vacancy_usage EXCEPTION;
        l_overlap      VARCHAR2(1);
        l_vac          sch_consult_vacancy%ROWTYPE;
        l_ignore_vac   BOOLEAN;
        l_flg_sch_type sch_event.dep_type%TYPE := i_flg_sch_type;
        l_hasperm      VARCHAR2(10);
        l_id_dept      dep_clin_serv.id_department%TYPE;
        l_func_exception EXCEPTION;
    
        l_id_institution institution.id_institution%TYPE := i_id_institution;
    BEGIN
        o_flg_show    := g_no;
        o_flg_proceed := g_no;
        l_ignore_vac  := TRUE;
    
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        -- Get the event that is actually associated with the vacancies.
        -- It can be a generic event (if the instution has one) or
        -- the event itself.
        g_error := 'get generic event';
        IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                    i_id_institution => l_id_institution, --i_prof.institution,
                                                    i_id_event       => i_id_sch_event,
                                                    o_id_event       => l_id_sch_event,
                                                    o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- check for permission to schedule for this dep_clin_serv, event and professional
        g_error   := 'CHECK PERMISSION TO SCHEDULE';
        l_hasperm := has_permission(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_dep_clin_serv => i_id_dep_clin_serv,
                                    i_id_sch_event     => i_id_sch_event,
                                    i_id_prof          => i_id_prof,
                                    i_id_institution   => l_id_institution);
        IF l_hasperm = g_msg_false
        THEN
            o_msg_title   := pk_message.get_message(i_lang, g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_no_permission);
            o_button      := g_check_button;
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            RETURN TRUE;
        END IF;
    
        -- calcular o flg_sch_type
        IF l_flg_sch_type IS NULL
        THEN
            g_error := 'fetch dep_type';
            IF NOT pk_schedule_common.get_dep_type(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_id_sch_event => i_id_sch_event,
                                                   o_dep_type     => l_flg_sch_type,
                                                   o_error        => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        -- Obter config geral das vagas
        g_error := 'CALL CHECK_VACANCY_USAGE';
        -- obter primeiro o i_id_dept a partir do id_dcs_requested. Se nao encontrar deve ir para o WHEN OTHERS
        SELECT id_department
          INTO l_id_dept
          FROM dep_clin_serv d
         WHERE d.id_dep_clin_serv = nvl(i_id_dep_clin_serv, -1);
    
        IF NOT pk_schedule_common.check_vacancy_usage(i_lang,
                                                      l_id_institution, --i_prof.institution,
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
                RAISE l_no_vacancy_usage;
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
            RAISE l_func_exception;
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
            RAISE l_func_exception;
        END IF;
    
        -- get vacancy full data
        g_error := 'GET VACANCY DATA';
        IF NOT pk_schedule_common.get_vacancy_data(i_lang               => i_lang,
                                                   i_id_institution     => l_id_institution, --i_prof.institution,
                                                   i_id_sch_event       => l_id_sch_event,
                                                   i_id_professional    => i_id_prof,
                                                   i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                                   i_dt_begin_tstz      => l_dt_begin,
                                                   i_flg_sch_type       => l_flg_sch_type,
                                                   i_id_sch_consult_vac => i_id_consult_vac,
                                                   o_vacancy            => l_vac,
                                                   o_error              => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- opcoes marcar numa vaga e marcar alem-vaga
        g_error := 'evaluate sch_option';
        IF i_sch_option IN
           (g_sch_option_invacancy, g_sch_option_unplanned, g_sch_option_novacancy, g_sch_option_update)
        THEN
        
            -- unexpected vacancy found for a schedule without vacancy
            IF i_sch_option = g_sch_option_novacancy
               AND l_vac.id_sch_consult_vacancy IS NOT NULL
            THEN
                RAISE l_unexvacfound;
            END IF;
        
            --  obteve vaga
            IF i_sch_option IN (g_sch_option_invacancy, g_sch_option_unplanned, g_sch_option_update)
               AND l_vac.id_sch_consult_vacancy IS NOT NULL
            THEN
                l_ignore_vac := FALSE;
            END IF;
        
            -- logica comum a todos os kinds
            IF i_sch_option = g_sch_option_novacancy
               OR (i_sch_option IN (g_sch_option_invacancy, g_sch_option_unplanned, g_sch_option_update) AND
               l_ignore_vac = TRUE)
            THEN
                -- verificar overlapping
                IF NOT
                    get_schedule_overlap(i_lang, i_id_prof, l_id_institution, l_dt_begin, l_dt_end, l_overlap, o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
                -- overlap exists but no permission to do it or unknown permission
                IF l_overlap = g_yes
                   AND nvl(i_do_overlap, g_no) = g_no
                THEN
                    RAISE l_overlapfound;
                
                    -- overlap exists and there is permission to proceed
                ELSIF l_overlap = g_yes
                      AND nvl(i_do_overlap, g_no) = g_yes
                THEN
                    --o_overlapfound := g_yes;
                    l_ignore_vac := TRUE;
                
                    -- no overlap and not possible to schedule without a vacancy
                ELSIF l_overlap = g_no
                      AND NOT l_sched_w_vac
                      AND i_flg_status != pk_schedule.g_sched_status_temporary
                THEN
                    RAISE l_vacancy_needed;
                    -- ALERT-11352. no overlap and we can change the vacancy. 
                    -- This new course of action takes precendence over the 'can schedule without vacancy' action in the next elsif
                ELSIF l_overlap = g_no
                      AND l_edit_vac
                      AND i_id_consult_vac IS NOT NULL
                THEN
                    IF NOT pk_schedule_common.alter_vacancy(i_lang                   => i_lang,
                                                            i_id_sch_consult_vacancy => i_id_consult_vac,
                                                            i_id_prof                => i_id_prof,
                                                            i_id_dep_clin_serv       => i_id_dep_clin_serv,
                                                            i_id_room                => i_id_room,
                                                            i_dt_begin_tstz          => l_dt_begin,
                                                            i_dt_end_tstz            => l_dt_end,
                                                            o_error                  => o_error)
                    THEN
                        RAISE l_func_exception;
                    END IF;
                    l_ignore_vac                 := FALSE;
                    l_vac.id_sch_consult_vacancy := i_id_consult_vac;
                
                    -- no overlap and we can schedule without vacancy
                ELSIF l_overlap = g_no
                      AND l_sched_w_vac
                THEN
                    l_ignore_vac := TRUE;
                END IF;
            
            END IF;
        
            -- forÁar o agendar fora do horario normal
        ELSIF i_sch_option = g_sch_option_force_novacancy
        THEN
            l_vac.id_sch_consult_vacancy := NULL;
            l_ignore_vac                 := TRUE;
        
            -- opcao invalida
        ELSE
            RAISE l_invalid_option;
        END IF;
    
        -- SETUP flg_status
        -- Check if there is an interface with an external system
        g_error := 'CALL EXIST INTERFACE';
        IF NOT pk_schedule_common.exist_interface(i_lang   => i_lang,
                                                  i_prof   => i_prof,
                                                  o_exists => l_schedule_interface,
                                                  o_error  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CHECK SCHEDULE INTERFACE';
        IF NOT l_schedule_interface
           AND l_flg_sch_type <> pk_schedule_common.g_sch_dept_flg_dep_type_cons
        THEN
            -- There isn't an interface and schedules are not managed on ALERT
            -- so a member of the staff must create the schedule manually on the external system.
            l_flg_status := g_status_pending;
        ELSIF (i_flg_status IS NULL)
        THEN
            -- The schedule can be marked successfully as "scheduled"
            l_flg_status := g_status_scheduled;
        ELSE
            l_flg_status := i_flg_status;
        END IF;
    
        g_error := 'CALL CREATE_SCHEDULE';
        -- Create the schedule
        IF NOT pk_schedule_common.create_schedule(i_lang                => i_lang,
                                                  i_id_prof_schedules   => i_prof.id,
                                                  i_id_institution      => l_id_institution, --i_prof.institution,
                                                  i_id_software         => i_prof.software,
                                                  i_id_patient          => i_id_patient,
                                                  i_id_dep_clin_serv    => i_id_dep_clin_serv,
                                                  i_id_sch_event        => i_id_sch_event,
                                                  i_id_prof             => i_id_prof,
                                                  i_dt_begin            => l_dt_begin,
                                                  i_dt_end              => l_dt_end,
                                                  i_flg_vacancy         => i_flg_vacancy,
                                                  i_flg_status          => l_flg_status,
                                                  i_schedule_notes      => i_schedule_notes,
                                                  i_id_lang_translator  => i_id_lang_translator,
                                                  i_id_lang_preferred   => i_id_lang_preferred,
                                                  i_id_reason           => i_id_reason,
                                                  i_id_origin           => i_id_origin,
                                                  i_id_schedule_ref     => i_id_schedule_ref,
                                                  i_id_room             => i_id_room,
                                                  i_flg_sch_type        => l_flg_sch_type,
                                                  i_id_analysis         => i_id_analysis,
                                                  i_reason_notes        => i_reason_notes,
                                                  i_flg_request_type    => i_flg_request_type,
                                                  i_flg_schedule_via    => i_flg_schedule_via,
                                                  i_id_consult_vac      => l_vac.id_sch_consult_vacancy,
                                                  i_id_multidisc        => i_id_multidisc,
                                                  i_id_sch_recursion    => i_id_schedule_recursion,
                                                  o_id_schedule         => o_id_schedule,
                                                  o_occupied            => l_occupied,
                                                  i_ignore_vacancies    => l_ignore_vac,
                                                  i_id_episode          => i_id_episode,
                                                  i_id_complaint        => i_id_complaint,
                                                  i_id_sch_combi_detail => i_id_sch_combi_detail,
                                                  o_error               => o_error)
        THEN
            -- Restore state
            RAISE l_func_exception;
        END IF;
    
        IF i_flg_vacancy <> pk_schedule_common.g_sched_vacancy_urgent
        THEN
            -- nao foi consumida uma vaga. O flg_vacancy passa a unplanned se nao estava em urgent
            IF l_occupied IS NULL
            THEN
                g_error := 'ALTER SCHEDULE TO UNPLANNED';
                -- Alter the schedule's vacancy flag
                IF NOT pk_schedule_common.alter_schedule(i_lang         => i_lang,
                                                         i_id_schedule  => o_id_schedule,
                                                         i_flg_vacancy  => pk_schedule_common.g_sched_vacancy_unplanned,
                                                         o_schedule_rec => l_schedule_rec,
                                                         o_error        => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            ELSE
                -- foi consumida uma vaga. O flg_vacancy passa a routine se nao estava em urgent
                g_error := 'ALTER SCHEDULE TO ROUTINE';
                -- Alter the schedule's vacancy flag
                IF NOT pk_schedule_common.alter_schedule(i_lang         => i_lang,
                                                         i_id_schedule  => o_id_schedule,
                                                         i_flg_vacancy  => pk_schedule_common.g_sched_vacancy_routine,
                                                         o_schedule_rec => l_schedule_rec,
                                                         o_error        => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN l_invalid_option THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'invalid or unknown value in parameter i_sch_option',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN l_vacancy_needed THEN
            o_msg_title   := pk_message.get_message(i_lang, g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_vacancyneeded);
            o_button      := g_cancel_button_code || pk_message.get_message(i_lang, g_sched_msg_goback) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN l_overlapfound THEN
            o_msg_title   := pk_message.get_message(i_lang, g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_overlapfound);
            o_button      := g_cancel_button_code || pk_message.get_message(i_lang, g_sched_msg_goback) || '|' ||
                             g_ok_button_code || pk_message.get_message(i_lang, g_sched_msg_dooverlap) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN l_unexvacfound THEN
            o_msg_title   := pk_message.get_message(i_lang, g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_unexvacfound);
            o_button      := g_cancel_button_code || pk_message.get_message(i_lang, g_sched_msg_goback) || '|' ||
                             g_ok_button_code || pk_message.get_message(i_lang, g_sched_msg_schedwithvac) || '|' ||
                             g_r_button_code || pk_message.get_message(i_lang, g_sched_msg_schedwithoutvac) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN l_no_vacancy_usage THEN
            o_msg_title   := pk_message.get_message(i_lang, g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_no_vac_usage);
            o_button      := g_cancel_button_code || pk_message.get_message(i_lang, g_sched_msg_goback) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            -- Unexpected error
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
        
    END create_schedule;

    /**
    * Creates consult schedules.
    * NOTE: this function is used by PK_RESET only.
    *
    * @param      i_lang               Default language
    * @param      i_patient            Patient
    * @param      i_id_clin_serv       Clinical service (consult type)
    * @param      i_id_prof_schedules  Professional who creates the schedule
    * @param      i_prof_scheduled     Professional who is scheduled
    * @param      i_dep                Department
    * @param      i_dt_target          Target date
    * @param      o_error              Error coming right at you!!!! data to return
    * @param      i_id_sch_event       Event (optional)
    *
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Cl·udia Silva)
    * @version    alpha
    * @since      2007/07/05
    *
    * UPDATED
    * DBImprovements - retirar a sch_event_soft do cursor c_event
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     14-10-2008
    */
    FUNCTION create_schedule_reset
    (
        i_lang              IN language.id_language%TYPE,
        i_patient           IN sch_group.id_patient%TYPE,
        i_id_clin_serv      IN clinical_service.id_clinical_service%TYPE,
        i_id_prof_schedules IN profissional,
        i_prof_scheduled    IN professional.id_professional%TYPE,
        i_dep               IN department.id_department%TYPE,
        i_dt_target         IN schedule_outp.dt_target_tstz%TYPE,
        i_flg_present       IN schedule.flg_present%TYPE DEFAULT NULL,
        i_id_multidisc      IN schedule.id_multidisc%TYPE DEFAULT NULL,
        o_error             OUT t_error_out,
        i_id_sch_event      IN sch_event.id_sch_event%TYPE DEFAULT NULL
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := 'CREATE_SCHEDULE_RESET';
        l_instit           VARCHAR2(50);
        l_next             schedule.id_schedule%TYPE;
        l_next_outp        schedule_outp.id_schedule_outp%TYPE;
        l_next_group       sch_group.id_group%TYPE;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_epis_type        sys_config.value%TYPE;
        l_flg_type         schedule_outp.flg_type%TYPE;
        l_error            VARCHAR2(2000);
        l_flg_sched        schedule_outp.flg_sched%TYPE;
        l_next_prof        sch_prof_outp.id_professional%TYPE;
        l_inst_type        institution.flg_type%TYPE;
        trigger_failure EXCEPTION;
        o_schedule_rec             schedule%ROWTYPE;
        o_sch_group_rec            sch_group%ROWTYPE;
        o_sch_resource_rec         sch_resource%ROWTYPE;
        l_occupied                 sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_id_sch_event             sch_event.id_sch_event%TYPE := NULL;
        l_flg_occurrence           sch_event.flg_occurrence%TYPE;
        l_flg_target_dep_clin_serv sch_event.flg_target_dep_clin_serv%TYPE;
        l_flg_target_professional  sch_event.flg_target_professional%TYPE;
        l_func_exception EXCEPTION;
    
        PRAGMA EXCEPTION_INIT(trigger_failure, -20001);
    
        CURSOR c_dcs IS
            SELECT dcs.id_dep_clin_serv, dep.id_institution
              FROM dep_clin_serv dcs, department dep
             WHERE dcs.id_clinical_service = i_id_clin_serv
               AND dcs.id_department = i_dep
               AND dep.id_department = dcs.id_department
               AND dcs.flg_available = pk_alert_constant.g_yes;
    
        CURSOR c_instit IS
            SELECT flg_type
              FROM institution
             WHERE id_institution = (SELECT id_institution
                                       FROM department
                                      WHERE id_department = i_dep);
    
        CURSOR c_event
        (
            i_software                 software.id_software%TYPE,
            i_flg_occurrence           sch_event.flg_occurrence%TYPE,
            i_flg_target_dep_clin_serv sch_event.flg_target_dep_clin_serv%TYPE,
            i_flg_target_professional  sch_event.flg_target_professional%TYPE
        ) IS
        -- Telmo 18-04-2008. Alteracao decorrente da eliminacao da coluna sch_event.flg_consult
            SELECT DISTINCT id_sch_event, flg_schedule_outp_type
              FROM (SELECT se.id_sch_event, se.flg_schedule_outp_type
                      FROM sch_event se
                     WHERE se.flg_available = g_yes
                       AND se.flg_target_dep_clin_serv = i_flg_target_dep_clin_serv
                       AND se.flg_target_professional = i_flg_target_professional
                       AND se.flg_occurrence = i_flg_occurrence
                       AND se.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_cons
                       AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, 0, i_software) =
                           pk_alert_constant.g_yes);
    
        CURSOR c_event_sched(i_id_sch_event sch_event.id_sch_event%TYPE) IS
            SELECT se.flg_schedule_outp_type
              FROM sch_event se
             WHERE se.id_sch_event = c_event_sched.i_id_sch_event;
    
        l_rows_ei table_varchar;
    BEGIN
        g_sysdate := current_timestamp;
    
        g_error := 'OPEN c_dcs';
        -- Open cursor
        OPEN c_dcs;
    
        g_error := 'FETCH c_dcs';
        -- Get dcs and institution
        FETCH c_dcs
            INTO l_id_dep_clin_serv, l_instit;
    
        g_error := 'CLOSE c_dcs';
        -- Close cursor
        CLOSE c_dcs;
    
        g_error := 'OPEN c_instit';
        -- Open cursor
        OPEN c_instit;
    
        g_error := 'FETCH c_instit';
        -- Get institution type
        FETCH c_instit
            INTO l_inst_type;
    
        g_error := 'CLOSE c_instit';
        -- Close cursor
        CLOSE c_instit;
    
        g_error := 'CALL GET_CONFIG';
        -- Get epis type regarding executing software and institution
        -- LG 2006-09-12
        -- what if we are using a software bo book to another software? then the following code is incorrect..
        l_epis_type := pk_sysconfig.get_config(g_sched_epis_type_config, l_instit, i_id_prof_schedules.software);
    
        g_error := 'CALL GET_FIRST_SUBSEQUENT';
        -- Check if it is a first or subsequent appointment
        IF NOT pk_episode.get_first_subsequent(i_lang         => i_lang,
                                               i_id_pat       => i_patient,
                                               i_id_clin_serv => i_id_clin_serv,
                                               i_institution  => l_instit,
                                               i_epis_type    => l_epis_type,
                                               o_flg          => l_flg_type,
                                               o_error        => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF (i_id_sch_event IS NULL)
        THEN
            g_error := 'GET flg_sched';
            -- Get flg_sched value
            IF l_flg_type = g_event_occurrence_subs
               AND i_prof_scheduled IS NOT NULL
            THEN
                -- Subsequent medical consult
                l_flg_occurrence           := g_event_occurrence_subs;
                l_flg_target_dep_clin_serv := g_yes;
                l_flg_target_professional  := g_yes;
            ELSIF l_flg_type = g_event_occurrence_subs
                  AND i_prof_scheduled IS NULL
            THEN
                -- Subsequent speciality consult
                l_flg_occurrence           := g_event_occurrence_subs;
                l_flg_target_dep_clin_serv := g_yes;
                l_flg_target_professional  := g_no;
            ELSIF l_flg_type = g_1esp
                  AND i_prof_scheduled IS NOT NULL
            THEN
                -- First medical consult
                l_flg_occurrence           := g_event_occurrence_first;
                l_flg_target_dep_clin_serv := g_yes;
                l_flg_target_professional  := g_yes;
            ELSIF l_flg_type = g_1esp
                  AND i_prof_scheduled IS NULL
            THEN
                -- First speciality consult
                l_flg_occurrence           := g_event_occurrence_first;
                l_flg_target_dep_clin_serv := g_yes;
                l_flg_target_professional  := g_no;
            END IF;
        
            g_error := 'OPEN c_event';
            -- Open cursor
            OPEN c_event(i_id_prof_schedules.software,
                         l_flg_occurrence,
                         l_flg_target_dep_clin_serv,
                         l_flg_target_professional);
        
            g_error := 'FETCH c_event';
            -- Get event and flg_sched
            FETCH c_event
                INTO l_id_sch_event, l_flg_sched;
        
            g_error := 'CLOSE c_event';
            -- Close cursor
            CLOSE c_event;
        ELSE
            l_id_sch_event := i_id_sch_event;
        
            -- Get flg_sched
            g_error := 'OPEN c_event_sched';
            -- Open cursor
            OPEN c_event_sched(l_id_sch_event);
        
            g_error := 'FETCH c_event_sched';
            -- Get institution type
            FETCH c_event_sched
                INTO l_flg_sched;
        
            g_error := 'CLOSE c_event_sched';
            -- Close cursor
            CLOSE c_event_sched;
        END IF;
    
        -- create master schedule
        g_error := 'CALL NEW_SCHEDULE';
        IF NOT pk_schedule_common.new_schedule(i_lang                => i_lang,
                                               i_id_instit_requests  => i_id_prof_schedules.institution,
                                               i_id_instit_requested => l_instit,
                                               i_id_dcs_requested    => l_id_dep_clin_serv,
                                               i_id_prof_schedules   => i_id_prof_schedules.id,
                                               i_id_sch_event        => l_id_sch_event,
                                               i_dt_schedule_tstz    => g_sysdate,
                                               i_flg_status          => g_sched_status_scheduled,
                                               i_dt_begin_tstz       => i_dt_target,
                                               i_flg_urgency         => g_no,
                                               i_flg_notification    => g_sched_flg_notif_pending,
                                               i_flg_present         => i_flg_present,
                                               i_id_multidisc        => i_id_multidisc,
                                               o_schedule_rec        => o_schedule_rec,
                                               o_error               => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- bind patient to current schedule
        g_error := 'CALL NEW_SCH_GROUP';
        IF NOT pk_schedule_common.new_sch_group(i_lang          => i_lang,
                                                i_id_schedule   => o_schedule_rec.id_schedule,
                                                i_id_patient    => i_patient,
                                                o_sch_group_rec => o_sch_group_rec,
                                                o_error         => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- Add resource
        g_error := 'CALL NEW_SCH_RESOURCE';
        IF NOT pk_schedule_common.new_sch_resource(i_lang             => i_lang,
                                                   i_id_schedule      => o_schedule_rec.id_schedule,
                                                   i_id_institution   => l_instit,
                                                   i_id_professional  => i_prof_scheduled,
                                                   o_sch_resource_rec => o_sch_resource_rec,
                                                   o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'GET SEQ_SCHEDULE.NEXTVAL';
        SELECT seq_schedule_outp.nextval
          INTO l_next_outp
          FROM dual;
    
        g_error := 'INSERT INTO SCHEDULE_OUTP';
        INSERT INTO schedule_outp
            (id_schedule_outp, id_schedule, flg_state, id_epis_type, dt_target_tstz, flg_type, flg_sched, id_software)
        VALUES
            (l_next_outp,
             o_schedule_rec.id_schedule,
             g_sched_status_scheduled,
             l_epis_type,
             i_dt_target,
             l_flg_type,
             l_flg_sched,
             i_id_prof_schedules.software);
    
        ts_epis_info.upd(id_schedule_outp_in => l_next_outp,
                         where_in            => 'ID_SCHEDULE = ' || o_schedule_rec.id_schedule,
                         rows_out            => l_rows_ei);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_id_prof_schedules,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rows_ei,
                                      o_error      => o_error);
    
        g_error := 'GET SEQ_SCH_PROF_OUTP.NEXTVAL';
        -- if i_prof_scheduled is not defined it's a consulta de especialidade
        --        and as so, table sch_prof_outp is not filled
        IF (i_prof_scheduled IS NOT NULL)
        THEN
            SELECT seq_sch_prof_outp.nextval
              INTO l_next_prof
              FROM dual;
        
            g_error := 'INSERT INTO SCH_PROF_OUTP';
        
            INSERT INTO sch_prof_outp
                (id_sch_prof_outp, id_schedule_outp, id_professional)
            VALUES
                (l_next_prof, l_next_outp, i_prof_scheduled);
        
            ts_epis_info.upd(sch_prof_outp_id_prof_in => i_prof_scheduled,
                             where_in                 => 'ID_SCHEDULE_OUTP = ' || l_next_outp,
                             rows_out                 => l_rows_ei);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_id_prof_schedules,
                                          i_table_name => 'EPIS_INFO',
                                          i_rowids     => l_rows_ei,
                                          o_error      => o_error);
        
        END IF;
    
        g_error := 'USE VACANCY';
        -- Try to use a vacancy for this schedule
        IF NOT pk_schedule_common.set_vacant_occupied(i_lang        => i_lang,
                                                      i_id_schedule => o_schedule_rec.id_schedule,
                                                      o_occupied    => l_occupied,
                                                      o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF l_occupied IS NULL --NOT l_occupied
        THEN
            -- Get generic event associated with this appointment
            IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                        i_id_institution => l_instit,
                                                        i_id_event       => l_id_sch_event,
                                                        o_id_event       => l_id_sch_event,
                                                        o_error          => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- No vacancy was occupied as it did not exist any matching vacancy.
            -- We'll create one and occupy it.
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
                 l_instit,
                 i_prof_scheduled,
                 i_dt_target,
                 1 + round(dbms_random.value(0, 2)),
                 1,
                 NULL,
                 l_id_dep_clin_serv,
                 NULL,
                 l_id_sch_event,
                 pk_schedule_bo.g_status_active);
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_patient,
                                      i_prof                => i_id_prof_schedules,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate,
                                      i_dt_first_obs        => g_sysdate,
                                      o_error               => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN trigger_failure THEN
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
        
    END create_schedule_reset;

    /**
    * This function is used to get configuration parameters.
    * It logs a warning if the message does not exist.
    *
    * @param i_lang            Language (just used for error messages).
    * @param i_id_sysconfig    Parameter identifier.
    * @param i_prof            Professional.
    * @param o_config          Parameter value.
    * @param o_error           Error message (if an error occurred).
    *
    * @return   True if successful, false otherwise.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/05/02
    */
    FUNCTION get_config
    (
        i_lang         IN language.id_language%TYPE,
        i_id_sysconfig IN sys_config.id_sys_config%TYPE,
        i_prof         IN profissional,
        o_config       OUT sys_config.value%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_CONFIG';
    BEGIN
        RETURN pk_schedule_common.get_config(i_lang           => i_lang,
                                             i_id_sysconfig   => i_id_sysconfig,
                                             i_id_institution => i_prof.institution,
                                             i_id_software    => i_prof.software,
                                             o_config         => o_config,
                                             o_error          => o_error);
    END get_config;

    /**
    * Determines if the given schedule information follows this schedule rules :
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Guerreiro (Tiago Ferreira)
    * @version  1.0
    * @since 2007/05/22
    *
    * UPDATED
    * a current_timestamp deixa de ser truncada no time. Passou a usar novo modelo da msg_stack
    * @author Telmo Castro
    * @date 29-08-2008
    * @version 2.4.3
    *
    * UPDATED
    * new input parameter: i_id_institution
    * @author Sofia Mendes
    * @date 28-07-2009
    * @version 2.5.0.5
    */
    FUNCTION validate_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv  IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event      IN schedule.id_sch_event%TYPE,
        i_id_prof           IN sch_resource.id_professional%TYPE,
        i_dt_begin          IN VARCHAR2,
        i_id_institution    IN institution.id_institution%TYPE DEFAULT NULL,
        i_id_physiatry_area IN physiatry_area.id_physiatry_area%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(18) := 'VALIDATE_SCHEDULE';
        l_tokens             table_varchar;
        l_replacements       table_varchar;
        l_message            sys_message.desc_message%TYPE;
        l_msg                VARCHAR2(32000);
        l_curr_date          TIMESTAMP WITH TIME ZONE;
        l_dt_begin           TIMESTAMP WITH TIME ZONE;
        l_prof_dt_end_tstz   TIMESTAMP WITH TIME ZONE;
        l_prof_dt_begin_tstz TIMESTAMP WITH TIME ZONE;
        l_id_institution     institution.id_institution%TYPE;
    BEGIN
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- RULE : Date cannot be null ---------------------------------------------------------------
        g_error := 'RULE : Date cannot be null';
        IF i_dt_begin IS NULL
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Begin date is null',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        END IF;
    
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        ELSE
            l_id_institution := i_id_institution;
        END IF;
    
        -- RULE : The appointment date should be contained inside the professional's contract begin and end dates ------------------------------
        g_error := 'The appointment date should be contained inside the professional''s contract begin and end dates';
        IF i_id_prof IS NOT NULL
        THEN
            SELECT dt_begin_tstz, dt_end_tstz
              INTO l_prof_dt_begin_tstz, l_prof_dt_end_tstz
              FROM (SELECT dt_begin_tstz, nvl(dt_end_tstz, l_dt_begin) dt_end_tstz, 1 rank
                      FROM prof_institution
                     WHERE id_professional = i_id_prof
                       AND id_institution = l_id_institution --i_prof.institution
                       AND flg_state = g_status_active
                       AND dt_begin_tstz = (SELECT MAX(dt_begin_tstz)
                                              FROM prof_institution
                                             WHERE id_professional = i_id_prof
                                               AND id_institution = l_id_institution --i_prof.institution
                                               AND flg_state = 'A'
                                               AND dt_begin_tstz IS NOT NULL)
                       AND rownum = 1
                    UNION
                    SELECT nvl(dt_begin_tstz, l_dt_begin), nvl(dt_end_tstz, l_dt_begin), 2 rank
                      FROM prof_institution
                     WHERE id_professional = i_id_prof
                       AND id_institution = l_id_institution --i_prof.institution
                       AND flg_state = g_status_active
                       AND dt_begin_tstz IS NULL
                       AND dt_end_tstz IS NULL
                       AND rownum = 1
                     ORDER BY rank)
             WHERE rownum = 1;
        
            IF l_dt_begin NOT BETWEEN l_prof_dt_begin_tstz AND l_prof_dt_end_tstz
            THEN
                l_msg := pk_message.get_message(i_lang, g_dt_not_in_contract);
            
                pk_alertlog.log_warn(text        => l_func_name ||
                                                    ': Trying to create a schedule whose date is not contained on the professional-institution association''s begin and end dates',
                                     object_name => g_package_name,
                                     owner       => g_package_owner);
                -- Add warning message
                message_push(l_msg, g_contractdates);
            END IF;
        END IF;
    
        -- RULE : Begin date should not be lower than the current date ------------------------------
        g_error := 'RULE : Begin date should not be lower than the current date';
        IF l_dt_begin < current_timestamp --l_curr_date
        THEN
        
            l_msg := pk_message.get_message(i_lang, g_dt_bg_lw_cr_dt);
        
            pk_alertlog.log_warn(text        => l_func_name ||
                                                ': Trying to create a schedule whose begin date should not be lower than the current date',
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            -- Add warning message
            message_push(l_msg, g_begindatelower);
        END IF;
    
        -- RULE : Patient should not have the same appointment type for the same day ----------------
        -- If exception NO_DATA_FOUND is thrown then this validation is ok otherwise a warning message is created.
        g_error := 'RULE : Patient should not have the same appointment type for the same day';
        DECLARE
            l_patient     patient.name%TYPE;
            l_dep         dep_clin_serv.id_department%TYPE;
            l_event       sch_event.id_sch_event%TYPE;
            l_dcs         dep_clin_serv.id_dep_clin_serv%TYPE;
            l_prof        professional.id_professional%TYPE;
            l_dt_existing TIMESTAMP WITH TIME ZONE;
        
        BEGIN
            IF (i_id_sch_event <> pk_schedule.g_event_mfr)
            THEN
                pk_date_utils.set_dst_time_check_off;
                SELECT pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, NULL) name,
                       dcs.id_department,
                       s.id_sch_event,
                       s.id_dcs_requested,
                       sr.id_professional,
                       s.dt_begin_tstz
                  INTO l_patient, l_dep, l_event, l_dcs, l_prof, l_dt_existing
                  FROM schedule s, sch_group sg, patient pat, sch_resource sr, dep_clin_serv dcs, sch_event se
                 WHERE s.id_dcs_requested = i_id_dep_clin_serv
                   AND s.id_sch_event = i_id_sch_event
                   AND s.flg_status IN (g_status_scheduled, g_status_pending)
                   AND s.dt_begin_tstz >= pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin)
                   AND s.dt_begin_tstz <
                       pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin), 1)
                   AND sg.id_schedule = s.id_schedule
                   AND sg.id_patient = i_id_patient
                   AND pat.id_patient = sg.id_patient
                   AND dcs.id_dep_clin_serv = s.id_dcs_requested
                   AND sr.id_schedule(+) = s.id_schedule
                   AND s.id_sch_event = se.id_sch_event
                   AND s.flg_sch_type <> pk_schedule_common.g_sch_dept_flg_dep_type_cm
                   AND se.flg_is_group = pk_alert_constant.g_no
                   AND rownum = 1;
                pk_date_utils.set_dst_time_check_on;
            
                l_tokens       := table_varchar('@1', '@2', '@3', '@4', '@5', '@6', '@7', '@8', '@9', '@A');
                l_replacements := table_varchar(l_patient,
                                                string_date_hm(i_lang, i_prof, l_dt_existing),
                                                pk_message.get_message(i_lang, g_department_label),
                                                string_department(i_lang, l_dep),
                                                pk_message.get_message(i_lang, g_appt_type_label),
                                                string_clin_serv_by_dcs(i_lang, l_dcs),
                                                pk_message.get_message(i_lang, g_evt_tp_label),
                                                string_sch_event(i_lang, l_event),
                                                pk_message.get_message(i_lang, g_professional_label),
                                                pk_prof_utils.get_name_signature(i_lang, i_prof, l_prof));
                -- Get message to translate
                l_message := get_message(i_lang => i_lang, i_message => g_dup_evt_label);
            
            ELSE
                pk_date_utils.set_dst_time_check_off;
                SELECT pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, NULL) name,
                       dcs.id_department,
                       s.id_sch_event,
                       sr.id_professional,
                       s.dt_begin_tstz
                  INTO l_patient, l_dep, l_event, l_prof, l_dt_existing
                  FROM schedule              s,
                       sch_group             sg,
                       patient               pat,
                       sch_resource          sr,
                       dep_clin_serv         dcs,
                       sch_event             se,
                       schedule_intervention si
                 WHERE s.id_sch_event = i_id_sch_event
                   AND s.flg_status IN (g_status_scheduled, g_status_pending)
                   AND s.dt_begin_tstz >= pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin)
                   AND s.dt_begin_tstz <
                       pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin), 1)
                      
                   AND sg.id_schedule = s.id_schedule
                   AND sg.id_patient = i_id_patient
                   AND pat.id_patient = sg.id_patient
                   AND dcs.id_dep_clin_serv = s.id_dcs_requested
                   AND sr.id_schedule(+) = s.id_schedule
                   AND s.id_sch_event = se.id_sch_event
                   AND s.flg_sch_type <> pk_schedule_common.g_sch_dept_flg_dep_type_cm
                   AND se.flg_is_group = pk_alert_constant.g_no
                   AND s.id_schedule = si.id_schedule
                   AND si.id_physiatry_area = i_id_physiatry_area
                   AND rownum = 1;
                pk_date_utils.set_dst_time_check_on;
            
                l_tokens       := table_varchar('@1', '@2', '@3', '@4', '@7', '@8', '@9', '@A');
                l_replacements := table_varchar(l_patient,
                                                string_date_hm(i_lang, i_prof, l_dt_existing),
                                                pk_message.get_message(i_lang, g_department_label),
                                                string_department(i_lang, l_dep),
                                                pk_message.get_message(i_lang, g_evt_tp_label),
                                                string_sch_event(i_lang, l_event),
                                                pk_message.get_message(i_lang, g_professional_label),
                                                pk_prof_utils.get_name_signature(i_lang, i_prof, l_prof));
                -- Get message to translate
                l_message := get_message(i_lang => i_lang, i_message => 'SCH_T811');
            
            END IF;
            -- Replace special chars
        
            -- Replace tokens
            IF NOT replace_tokens(i_lang         => i_lang,
                                  i_string       => l_message,
                                  i_tokens       => l_tokens,
                                  i_replacements => l_replacements,
                                  o_string       => l_msg,
                                  o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
            -- Add warning message
            message_push(l_msg, g_sameappointment);
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END validate_schedule;

    /**
    * Determines if the given schedule information follows this schedule rules :
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Miguel Ferreira
    * @version  2.5.0.4
    * @since 01-07-2009
    *
    * UPDATED: new parameter: i_id_institution
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @since 31-07-2009
    */
    FUNCTION validate_schedule_multidisc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_id_prof          IN table_number,
        i_dt_begin         IN VARCHAR2,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(18) := 'VALIDATE_SCHEDULE';
        l_tokens             table_varchar;
        l_replacements       table_varchar;
        l_message            sys_message.desc_message%TYPE;
        l_msg                VARCHAR2(32000);
        l_curr_date          TIMESTAMP WITH TIME ZONE;
        l_dt_begin           TIMESTAMP WITH TIME ZONE;
        l_prof_dt_end_tstz   TIMESTAMP WITH TIME ZONE;
        l_prof_dt_begin_tstz TIMESTAMP WITH TIME ZONE;
        l_idx                NUMBER;
        l_exit_loop          BOOLEAN;
    
        l_id_institution institution.id_institution%TYPE := i_id_institution;
    BEGIN
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- RULE : Date cannot be null ---------------------------------------------------------------
        g_error := 'RULE : Date cannot be null';
        IF i_dt_begin IS NULL
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Begin date is null',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        END IF;
    
        -- RULE : The appointment date should be contained inside the professional's contract begin and end dates ------------------------------
        g_error := 'The appointment date should be contained inside the professional''s contract begin and end dates';
        IF i_id_prof.count > 0
        THEN
            l_idx       := 1;
            l_exit_loop := FALSE;
            WHILE l_idx <= i_id_prof.last
                  AND NOT l_exit_loop
            LOOP
                SELECT nvl(dt_end_tstz, l_dt_begin), nvl(dt_begin_tstz, l_dt_begin)
                  INTO l_prof_dt_end_tstz, l_prof_dt_begin_tstz
                  FROM prof_institution
                 WHERE id_professional = i_id_prof(l_idx)
                   AND id_institution = l_id_institution --i_prof.institution
                   AND flg_state = g_status_active
                   AND rownum = 1;
            
                IF l_dt_begin NOT BETWEEN l_prof_dt_begin_tstz AND l_prof_dt_end_tstz
                THEN
                    l_msg := pk_message.get_message(i_lang, g_dt_not_in_contract);
                
                    pk_alertlog.log_warn(text        => l_func_name ||
                                                        ': Trying to create a schedule whose date is not contained on the professional-institution association''s begin and end dates',
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
                    -- Add warning message
                    message_push(l_msg, g_contractdates);
                
                    l_exit_loop := TRUE;
                END IF;
            
                l_idx := l_idx + 1;
            END LOOP;
        END IF;
    
        -- RULE : Begin date should not be lower than the current date ------------------------------
        g_error := 'RULE : Begin date should not be lower than the current date';
        IF l_dt_begin < current_timestamp --l_curr_date
        THEN
        
            l_msg := pk_message.get_message(i_lang, g_dt_bg_lw_cr_dt);
        
            pk_alertlog.log_warn(text        => l_func_name ||
                                                ': Trying to create a schedule whose begin date should not be lower than the current date',
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            -- Add warning message
            message_push(l_msg, g_begindatelower);
        END IF;
    
        -- RULE : Patient should not have the same appointment type for the same day ----------------
        -- If exception NO_DATA_FOUND is thrown then this validation is ok otherwise a warning message is created.
        g_error := 'RULE : Patient should not have the same appointment type for the same day';
        DECLARE
            l_patient     patient.name%TYPE;
            l_dep         dep_clin_serv.id_department%TYPE;
            l_event       sch_event.id_sch_event%TYPE;
            l_dcs         dep_clin_serv.id_dep_clin_serv%TYPE;
            l_prof        professional.id_professional%TYPE;
            l_dt_existing TIMESTAMP WITH TIME ZONE;
        
        BEGIN
            pk_date_utils.set_dst_time_check_off;
            SELECT pat.name, dcs.id_department, s.id_sch_event, s.id_dcs_requested, sr.id_professional, s.dt_begin_tstz
              INTO l_patient, l_dep, l_event, l_dcs, l_prof, l_dt_existing
              FROM schedule s, sch_group sg, patient pat, sch_resource sr, dep_clin_serv dcs, sch_event se
             WHERE s.id_dcs_requested = i_id_dep_clin_serv
               AND s.id_sch_event = i_id_sch_event
               AND s.flg_status IN (g_status_scheduled, g_status_pending)
               AND s.dt_begin_tstz >= pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin)
               AND s.dt_begin_tstz <
                   pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin), 1)
               AND sg.id_schedule = s.id_schedule
               AND sg.id_patient = i_id_patient
               AND pat.id_patient = sg.id_patient
               AND dcs.id_dep_clin_serv = s.id_dcs_requested
               AND sr.id_schedule(+) = s.id_schedule
               AND s.id_sch_event = se.id_sch_event
               AND s.flg_sch_type <> pk_schedule_common.g_sch_dept_flg_dep_type_cm
               AND se.flg_is_group = pk_alert_constant.g_no
               AND rownum = 1;
            pk_date_utils.set_dst_time_check_on;
            -- Replace special chars
            l_tokens       := table_varchar('@1', '@2', '@3', '@4', '@5', '@6', '@7', '@8', '@9', '@A');
            l_replacements := table_varchar(l_patient,
                                            string_date_hm(i_lang, i_prof, l_dt_existing),
                                            pk_message.get_message(i_lang, g_department_label),
                                            string_department(i_lang, l_dep),
                                            pk_message.get_message(i_lang, g_appt_type_label),
                                            string_clin_serv_by_dcs(i_lang, l_dcs),
                                            pk_message.get_message(i_lang, g_evt_tp_label),
                                            string_sch_event(i_lang, l_event),
                                            pk_message.get_message(i_lang, g_professional_label),
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, l_prof));
            -- Get message to translate
            l_message := get_message(i_lang => i_lang, i_message => g_dup_evt_label);
            -- Replace tokens
            IF NOT replace_tokens(i_lang         => i_lang,
                                  i_string       => l_message,
                                  i_tokens       => l_tokens,
                                  i_replacements => l_replacements,
                                  o_string       => l_msg,
                                  o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
            -- Add warning message
            message_push(l_msg, g_sameappointment);
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END validate_schedule_multidisc;

    /**
    * Determines if the given schedule information follow schedule rules :
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *  - First appointment should not exist if a first appointment is being created
    *  - Episode validations
    *
    * @param i_lang                   Language.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Old schedule identifier.
    * @param i_id_dep_clin_serv       Department-Clinical service identifier.
    * @param i_id_sch_event           Event identifier.
    * @param i_id_prof                Professional that carries out the schedule.
    * @param i_dt_begin               Begin date.
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_sv_stop                warning to the caller telling that this reschedule violates dependencies inside a single visit
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Guerreiro (Tiago Ferreira)
    * @version  1.0
    * @since 2007/05/22
    *
    * UPDATED
    * i_id_dep_clin_serv can be null when validating exams reschedule
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    01-09-2008
    *
    * UPDATED
    * single visit order dependency check up
    * @author  Telmo
    * @version 2.5.0.4
    * @date    29-06-2009
    */
    FUNCTION validate_reschedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_old_id_schedule  IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_tab_patients     IN table_number DEFAULT table_number(),
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_proceed      OUT VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_sv_stop          OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(19) := 'VALIDATE_RESCHEDULE';
        l_msg                 sys_message.desc_message%TYPE;
        l_tokens              table_varchar;
        l_replacements        table_varchar;
        l_id_dep_clin_serv    schedule.id_dcs_requested%TYPE;
        l_id_sch_event        schedule.id_sch_event%TYPE;
        l_id_sch_event_new    schedule.id_sch_event%TYPE;
        l_id_sch_combi_detail schedule.id_sch_combi_detail%TYPE;
        l_patient_name        VARCHAR2(4000);
        l_patients            VARCHAR2(4000);
        l_ch                  VARCHAR2(4000);
        l_dt_begin            VARCHAR2(4000);
        l_date                TIMESTAMP WITH TIME ZONE;
        l_id_comb             sch_combi_detail.id_sch_combi%TYPE;
        l_id_cod              sch_combi_detail.id_code%TYPE;
        l_patients_tab        table_varchar := table_varchar();
        l_vacs_tab            table_number := table_number();
        l_dt_begin_old        schedule.dt_begin_tstz%TYPE;
        l_dt_begin_old_str    VARCHAR2(4000);
    
        l_id_institution institution.id_institution%TYPE := i_id_institution;
    
        l_only_read_button VARCHAR2(1) := g_no;
    
        -- verificar dependencia (se existir) em relaÁao ao parent. Devolve false se falhar depend.
        FUNCTION inner_check_dependency(i_id_sch_combi_detail IN sch_combi_detail.id_sch_combi_detail%TYPE) RETURN BOOLEAN IS
            l_id_code_parent sch_combi_detail.id_code_parent%TYPE;
            l_id_combi       sch_combi_detail.id_sch_combi%TYPE;
            l_dt_begin       schedule.dt_begin_tstz%TYPE;
            l_dt_end         schedule.dt_end_tstz%TYPE;
            l_min_time_after sch_combi_detail.min_time_after%TYPE;
            l_max_time_after sch_combi_detail.max_time_after%TYPE;
        BEGIN
            -- get parent id
            g_error := 'GET ID_CODE_PARENT';
            SELECT d.id_code_parent, d.id_sch_combi
              INTO l_id_code_parent, l_id_combi
              FROM sch_combi_detail d
             WHERE d.id_sch_combi_detail = i_id_sch_combi_detail;
        
            -- get parent schedule data
            g_error := 'GET PARENT SCHEDULE DATA';
            SELECT s.dt_begin_tstz, s.dt_end_tstz, nvl(min_time_after, 0), nvl(max_time_after, 1440)
              INTO l_dt_begin, l_dt_end, l_min_time_after, l_max_time_after
              FROM schedule s
              JOIN sch_combi_detail sd
                ON s.id_sch_combi_detail = sd.id_sch_combi_detail
             WHERE sd.id_sch_combi = l_id_combi
               AND sd.id_code = l_id_code_parent;
        
            -- validate if begin date is within the parent post period (min_time_after till max_time_after) 
            RETURN l_date BETWEEN nvl(l_dt_end, l_dt_begin) + numtodsinterval(l_min_time_after, 'MINUTE') AND nvl(l_dt_end,
                                                                                                                  l_dt_begin) + numtodsinterval(l_max_time_after,
                                                                                                                                                'MINUTE');
        END inner_check_dependency;
    
    BEGIN
        o_flg_proceed := g_yes;
        o_flg_show    := g_no;
        o_sv_stop     := g_no;
    
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        g_error := 'Get generic event or self';
        -- Get generic event or self, for the new schedule
        IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                    i_id_institution => l_id_institution, --i_prof.institution,
                                                    i_id_event       => i_id_sch_event,
                                                    o_id_event       => l_id_sch_event_new,
                                                    o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Retrieve old schedule information
        g_error := 'Retrieving information from old schedule [' || i_old_id_schedule || ']';
        SELECT id_dcs_requested, id_sch_event, s.id_sch_combi_detail, s.dt_begin_tstz
          INTO l_id_dep_clin_serv, l_id_sch_event, l_id_sch_combi_detail, l_dt_begin_old
          FROM schedule s
         WHERE id_schedule = i_old_id_schedule;
    
        g_error := 'Get old schedule''s generic event or self';
        -- Get generic event or self, for the new schedule
        IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                    i_id_institution => l_id_institution, --i_prof.institution,
                                                    i_id_event       => l_id_sch_event,
                                                    o_id_event       => l_id_sch_event,
                                                    o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert i_dt_begin to timestamp
        g_error := 'CALL GET_STRING_TSTZ';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Validate event
        IF l_id_sch_event_new <> l_id_sch_event
        THEN
            o_msg_title := pk_message.get_message(i_lang, g_sched_msg_ack_title);
        
            o_msg    := pk_message.get_message(i_lang, g_sched_msg_resched_bad_event);
            o_button := g_ok_button_code || get_message(i_lang, g_msg_ack) || '|';
        
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            RETURN TRUE;
        END IF;
    
        -- Validate department clinical service
        -- Jose Antunes 01-09-2008 adicionado i_id_dep_clin_serv IS NOT NULL - nos exames nao se valida DCS, pode ser diferente
        IF i_id_dep_clin_serv IS NOT NULL
           AND i_id_dep_clin_serv <> l_id_dep_clin_serv
        THEN
            o_msg_title := pk_message.get_message(i_lang, g_sched_msg_ack_title);
        
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_resched_bad_dcs);
            o_button      := g_ok_button_code || get_message(i_lang, g_msg_ack) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            RETURN TRUE;
        END IF;
    
        -- single visits - validate if dependency (if it exists) is kept
        IF l_id_sch_combi_detail IS NOT NULL
        THEN
            -- check dependencies 
            IF NOT inner_check_dependency(l_id_sch_combi_detail)
            THEN
                o_msg_title   := pk_message.get_message(i_lang, g_msg_warning);
                o_msg         := pk_message.get_message(i_lang, g_sched_msg_sv_resched);
                o_button      := g_cancel_button_code || pk_message.get_message(i_lang, g_cancel_button) || '|' ||
                                 g_ok_button_code || get_message(i_lang, g_msg_ack) || '|';
                o_flg_show    := g_yes;
                o_flg_proceed := g_no;
                o_sv_stop     := g_yes;
                RETURN TRUE;
            END IF;
        
            -- do the same for the sons of our schedule being rescheduled
            SELECT id_sch_combi, id_code
              INTO l_id_comb, l_id_cod
              FROM sch_combi_detail
             WHERE id_sch_combi_detail = l_id_sch_combi_detail;
        
            BEGIN
                SELECT scd.id_sch_combi_detail
                  INTO l_id_sch_combi_detail
                  FROM sch_combi_detail scd
                  JOIN schedule s
                    ON scd.id_sch_combi_detail = s.id_sch_combi_detail
                 WHERE scd.id_sch_combi = l_id_comb
                   AND scd.id_code_parent = l_id_cod
                   AND rownum = 1;
            
                IF NOT inner_check_dependency(l_id_sch_combi_detail)
                THEN
                    o_msg_title   := pk_message.get_message(i_lang, g_msg_warning);
                    o_msg         := pk_message.get_message(i_lang, g_sched_msg_sv_resched);
                    o_button      := g_cancel_button_code || pk_message.get_message(i_lang, g_cancel_button) || '|' ||
                                     g_ok_button_code || get_message(i_lang, g_msg_ack) || '|';
                    o_flg_show    := g_yes;
                    o_flg_proceed := g_no;
                    o_sv_stop     := g_yes;
                    RETURN TRUE;
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
        END IF;
    
        IF o_flg_proceed = g_yes
        THEN
            -- i_dt_begin l_date
            l_dt_begin := string_date_hm(i_lang, i_prof, l_date);
        
            -- Everything is OK. Set confirmation message.
            IF (i_id_sch_event <> pk_schedule.g_event_group)
            THEN
                g_error := 'GET CONFIRMATION DATA';
                SELECT pat_name, decode(lower(substr(pat_name, length(pat_name), 1)), 's', '', 's') ch
                  INTO l_patient_name, l_ch
                  FROM (SELECT pk_patient.get_pat_short_name(sg.id_patient) pat_name
                          FROM schedule s, sch_group sg
                         WHERE s.id_schedule = sg.id_schedule
                           AND s.id_schedule = i_old_id_schedule);
            
                o_msg_title := pk_message.get_message(i_lang, g_resched_confirm);
            
                IF (l_date < current_timestamp)
                THEN
                    IF (l_id_sch_event IN (g_event_exam, g_event_oexam, g_event_mfr))
                    THEN
                        l_msg              := pk_message.get_message(i_lang, g_dt_bg_lw_cr_dt);
                        l_only_read_button := g_yes;
                    ELSE
                        l_msg := pk_message.get_message(i_lang, g_single_reschedule_conf_past);
                    END IF;
                ELSE
                    l_msg := pk_message.get_message(i_lang, g_single_reschedule_conf);
                END IF;
                l_tokens       := table_varchar('@1', '@2', '@3');
                l_replacements := table_varchar(l_patient_name, l_dt_begin, l_ch);
            
            ELSE
                -- Everything is OK. Set confirmation message.
                g_error := 'GET GROUP CONFIRMATION DATA';
                SELECT pat_name /*, vac*/
                  BULK COLLECT
                  INTO l_patients_tab --, l_vacs_tab
                  FROM (SELECT pk_patient.get_pat_short_name(sg.id_patient) pat_name, s.id_sch_consult_vacancy vac
                          FROM schedule s, sch_group sg
                         WHERE s.id_schedule = sg.id_schedule
                           AND s.id_schedule = i_old_id_schedule
                           AND sg.id_patient IN (SELECT column_value
                                                   FROM TABLE(i_tab_patients)));
            
                o_msg_title := pk_message.get_message(i_lang, g_resched_confirm);
            
                IF (l_patients_tab.count > 0)
                THEN
                    FOR idx IN l_patients_tab.first .. l_patients_tab.last
                    LOOP
                        IF (i_tab_patients.count = 1)
                        THEN
                            l_patients := l_patients_tab(idx);
                        ELSE
                            l_patients := l_patients || '- ' || l_patients_tab(idx) || chr(13);
                        END IF;
                    END LOOP;
                END IF;
            
                l_dt_begin_old_str := string_date_hm(i_lang, i_prof, l_dt_begin_old);
            
                IF (i_tab_patients.count = 1)
                THEN
                    l_msg := pk_message.get_message(i_lang, g_resched_group_pat);
                    --l_msg := l_msg || chr(13) || pk_message.get_message(i_lang, 'SCH_T718');
                    l_replacements := table_varchar(l_patients, l_dt_begin, l_dt_begin_old_str);
                ELSE
                    l_msg := pk_message.get_message(i_lang, g_resched_group);
                    --l_msg := l_msg || chr(13) || pk_message.get_message(i_lang, 'SCH_T722');
                    l_replacements := table_varchar(l_dt_begin, l_patients, l_dt_begin_old_str);
                END IF;
                l_tokens := table_varchar('@1', '@2', '@3');
                --l_replacements := table_varchar(l_patients, l_dt_begin, l_dt_begin_old_str);
            END IF;
        
            g_error := 'GET CONFIRMATION MESSAGE';
            IF NOT replace_tokens(i_lang         => i_lang,
                                  i_string       => l_msg,
                                  i_tokens       => l_tokens,
                                  i_replacements => l_replacements,
                                  o_string       => o_msg,
                                  o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF (l_only_read_button = g_yes)
            THEN
                o_button := pk_schedule.g_r_button_code || pk_message.get_message(i_lang, pk_schedule.g_sched_msg_read) || '|';
            ELSE
                o_button := g_cancel_button_code || pk_message.get_message(i_lang, g_common_no) || '|' ||
                            g_ok_button_code || pk_message.get_message(i_lang, g_common_yes) || '|';
            END IF;
            o_flg_show    := g_yes;
            o_flg_proceed := g_yes;
        
            -- Replace tokens            
        END IF;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END validate_reschedule;

    /*
    * Cancels an appointment. This overload does what the cancel_schedule used to do before scheduler 3 showed up.
    * IT is still needed for use by pk_sr_grid, pk_schedule_exam and pk_schedule_outp.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo
    * @version  2.6.0.1
    * @date     18-05-2010
    */
    FUNCTION cancel_schedule_old
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCHEDULE';
        l_func_exception EXCEPTION;
        l_id_external_request p1_external_request.id_external_request%TYPE;
        l_id_consult_req      consult_req.id_consult_req%TYPE;
        l_rowids              table_varchar;
        l_error               VARCHAR2(4000);
    BEGIN
        g_error := 'CALL CANCEL_SCHEDULE';
        IF NOT pk_schedule_common.cancel_schedule(i_lang             => i_lang,
                                                  i_id_professional  => i_prof.id,
                                                  i_id_software      => i_prof.software,
                                                  i_id_schedule      => i_id_schedule,
                                                  i_id_cancel_reason => i_id_cancel_reason,
                                                  i_cancel_notes     => i_cancel_notes,
                                                  o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'CALL CANCEL_SCH_EPIS_EHR';
        IF NOT pk_schedule.cancel_sch_epis_ehr(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_schedule  => i_id_schedule,
                                               i_sysdate      => g_sysdate,
                                               i_sysdate_tstz => g_sysdate_tstz,
                                               o_error        => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        BEGIN
        
            g_error := 'CALL TO pk_ref_module.get_ref_sch_to_cancel with id_schedule=' || i_id_schedule;
            IF NOT pk_ref_module.get_ref_sch_to_cancel(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_schedule         => i_id_schedule,
                                                       o_id_external_request => l_id_external_request,
                                                       o_error               => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            IF l_id_external_request IS NOT NULL
            THEN
                g_error := 'CALL PK_REF_EXT_SYS.CANCEL_REF_SCHEDULE WITH ID_EXTERNAL_REQUEST = ' ||
                           l_id_external_request;
                IF NOT pk_ref_ext_sys.cancel_ref_schedule(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_id_ref   => l_id_external_request,
                                                          i_schedule => i_id_schedule,
                                                          i_notes    => NULL,
                                                          o_error    => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- Se nao existe P1, nao tem que actualizar o estado
        END;
    
        --Sofia Mendes (3-11-2009) update consult requisition status
        BEGIN
            SELECT r.id_consult_req
              INTO l_id_consult_req
              FROM consult_req r
             WHERE r.id_schedule = i_id_schedule;
        EXCEPTION
            WHEN too_many_rows THEN
                g_error := 'DUPLICATED CONSULT_REF for with schedule: ' || i_id_schedule;
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
                l_id_consult_req := NULL;
            
            WHEN OTHERS THEN
                l_error          := SQLERRM;
                l_id_consult_req := NULL;
        END;
    
        IF l_id_consult_req IS NOT NULL
        THEN
            ts_consult_req.upd(id_consult_req_in => l_id_consult_req,
                               flg_status_in     => 'P',
                               id_schedule_in    => NULL,
                               rows_out          => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CONSULT_REQ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_schedule_old;

    /*
    * Cancels an appointment. Usado pelo flash
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/23
    *
    * UPDATED
    * added call to pk_p1_ext_sys.update_referral_status
    * @author  Jose Antunes
    * @date    04-08-2008
    * @version 2.4.3
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCHEDULE';
        l_func_exception EXCEPTION;
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    BEGIN
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        IF NOT cancel_schedule(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_schedule      => i_id_schedule,
                               i_id_cancel_reason => i_id_cancel_reason,
                               i_cancel_notes     => i_cancel_notes,
                               i_transaction_id   => l_transaction_id,
                               o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
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
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_schedule;

    /* previous cancel_schedule will call this one. 
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param i_transaction_id     SCH 3 bd transaction id
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.6.0.1
    * @date    17-05-2010
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCHEDULE';
        l_func_exception EXCEPTION;
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        IF NOT pk_schedule_api_upstream.cancel_schedule(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_schedule      => i_id_schedule,
                                                        i_id_cancel_reason => i_id_cancel_reason,
                                                        i_cancel_notes     => i_cancel_notes,
                                                        i_transaction_id   => l_transaction_id,
                                                        o_error            => o_error)
        THEN
        
            RAISE l_func_exception;
        END IF;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END cancel_schedule;

    /*
    * Cancels an appointment.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param io_transaction_id    Transaction ID
    * @param i_cancel_exam_req     Y = for exam schedules also cancels their requisition. 
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/23
    *
    * UPDATED
    * added call to pk_p1_ext_sys.update_referral_status
    * @author  Jose Antunes
    * @date    04-08-2008
    * @version 2.4.3
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        io_transaction_id  IN OUT VARCHAR2,
        i_cancel_exam_req  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCHEDULE';
        l_func_exception EXCEPTION;
        l_id_external_request p1_external_request.id_external_request%TYPE;
        l_id_consult_req      consult_req.id_consult_req%TYPE;
        l_rowids              table_varchar;
    
    BEGIN
        io_transaction_id := pk_schedule_api_upstream.begin_new_transaction(io_transaction_id, i_prof);
    
        IF NOT pk_schedule_api_upstream.cancel_schedule(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_schedule      => i_id_schedule,
                                                        i_id_cancel_reason => i_id_cancel_reason,
                                                        i_cancel_notes     => i_cancel_notes,
                                                        i_transaction_id   => io_transaction_id,
                                                        o_error            => o_error)
        THEN
        
            RAISE l_func_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_schedule_api_upstream.do_rollback(io_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(io_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_schedule;

    /*
    * cancel an entire sv or only one of its schedules
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_cancel_all         Y = cancel all single visit schedules  N = cancel this one schedule
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param o_error              Error message, if an error occurred.
    *
    * return true /false
    *
    * @author  Telmo
    * @version 2.5.0.4
    * @date    29-06-2009
    */
    FUNCTION cancel_schedule_sv
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_cancel_all       IN VARCHAR2 DEFAULT 'N',
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCHEDULE_SV';
        l_id_combi  sch_combi.id_sch_combi%TYPE;
        CURSOR l_cur IS
            SELECT id_schedule
              FROM schedule s
              JOIN sch_combi_detail d
                ON d.id_sch_combi_detail = s.id_sch_combi_detail
             WHERE d.id_sch_combi = l_id_combi;
    
        l_rec l_cur%ROWTYPE;
    BEGIN
    
        IF i_cancel_all = g_no
        THEN
            g_error := 'CANCEL SINGLE SCHEDULE';
            IF NOT cancel_schedule(i_lang             => i_lang,
                                   i_prof             => i_prof,
                                   i_id_schedule      => i_id_schedule,
                                   i_id_cancel_reason => i_id_cancel_reason,
                                   i_cancel_notes     => i_cancel_notes,
                                   o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'GET COMBI ID FROM THIS SCHEDULE';
            SELECT id_sch_combi
              INTO l_id_combi
              FROM sch_combi_detail d
              JOIN schedule s
                ON d.id_sch_combi_detail = s.id_sch_combi_detail
             WHERE s.id_schedule = i_id_schedule;
        
            g_error := 'OPEN CURSOR';
            OPEN l_cur;
            LOOP
                FETCH l_cur
                    INTO l_rec;
                EXIT WHEN l_cur%NOTFOUND;
                g_error := 'CANCEL SINGLE VISIT SCHEDULE ID ' || l_rec.id_schedule;
                IF NOT cancel_schedule(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_schedule      => l_rec.id_schedule,
                                       i_id_cancel_reason => i_id_cancel_reason,
                                       i_cancel_notes     => i_cancel_notes,
                                       o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            END LOOP;
            CLOSE l_cur;
        END IF;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_schedule_sv;

    /**
    * Gets the cancel reason messsage to be used on reschedule operation.
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.    
    * @param i_dt_begin               Start date
    * @param o_schedule_cancel_notes  Output message    
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Sofia Mendes
    * @version  2.5.x
    * @since    2009/06/17
    */
    FUNCTION get_cancel_notes_msg
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_dt_begin              IN VARCHAR2,
        o_schedule_cancel_notes OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_PROFESSIONALS';
        l_tokens       table_varchar;
        l_replacements table_varchar;
        l_message      sys_message.desc_message%TYPE;
    
        l_sysdate  TIMESTAMP WITH TIME ZONE := current_timestamp;
        l_dt_begin TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'CALL GET_STRING_TSTZ FOR current_timestamp';
        -- Convert current date to timestamp
        IF NOT pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                        i_inst      => i_prof.institution,
                                                        i_timestamp => l_sysdate,
                                                        o_timestamp => l_sysdate,
                                                        o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        -- Convert start date to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            --RAISE l_func_exception;
            RETURN FALSE;
        END IF;
    
        g_error := 'GET CANCEL NOTES MESSAGE';
        -- Set tokens to replace
        l_tokens := table_varchar('@1', '@2');
    
        -- Set replacements
        l_replacements := table_varchar(pk_schedule.string_date_hm(i_lang, i_prof, l_sysdate),
                                        string_date_hm(i_lang, i_prof, l_dt_begin));
        -- Get cancel notes message
        l_message := get_message(i_lang => i_lang, i_message => g_rescheduled_from_to);
    
        -- Replace tokens
        IF NOT replace_tokens(i_lang         => i_lang,
                              i_string       => l_message,
                              i_tokens       => l_tokens,
                              i_replacements => l_replacements,
                              o_string       => o_schedule_cancel_notes,
                              o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_cancel_notes_msg;

    /**
    * Reschedules an appointment.
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Identifier of the appointment to be rescheduled.
    * @param i_id_prof                Target professional.
    * @param i_dt_begin               Start date
    * @param i_dt_end                 End date
    * @param i_do_overlap             null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be
    *                                 issued with Y or N
    * @param i_id_consult_vac         id da vaga. Se for <> null significa que se trata de uma marcaÁao normal ou alem-vaga
    * @param i_sch_option             'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule)
    * @param o_id_schedule            Identifier of the new schedule.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Guerreiro (Tiago Ferreira)
    * @version  1.0
    * @since 2007/05/23
    *
    * UPDATED
    * added parameters to cope with new create_schedule
    * @author  Telmo Castro
    * @date    01-07-2008
    * @version 2.4.3
    *
    * UPDATED
    * added call to pk_p1_ext_sys.update_referral_status and removed update to p1_external_request
    * @author  Jose Antunes
    * @date    06-08-2008
    * @version 2.4.3
    *
    * UPDATED
    * get a list of patients associated to the schedule instead of one patient (because of group schedules)
    * @author  Sofia Mendes
    * @date    17-06-2009
    * @version 2.5.x
    *
    * UPDATED
    * new parameter: i_id_institution
    * @author  Sofia Mendes
    * @date    30-07-2009
    * @version 2.5.0.5
    */
    FUNCTION create_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_id_prof         IN professional.id_professional%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_do_overlap      IN VARCHAR2,
        i_id_consult_vac  IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option      IN VARCHAR2,
        i_id_institution  IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_flg_proceed     OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(19) := 'CREATE_RESCHEDULE';
        l_func_exception EXCEPTION;
        l_schedule_cancel_notes schedule.schedule_notes%TYPE;
        l_tokens                table_varchar;
        l_replacements          table_varchar;
        l_message               sys_message.desc_message%TYPE;
        l_sysdate               TIMESTAMP WITH TIME ZONE := current_timestamp;
        l_dt_begin              TIMESTAMP WITH TIME ZONE;
        l_dt_end                TIMESTAMP WITH TIME ZONE;
        l_flg_vacancy           schedule.flg_vacancy%TYPE := pk_schedule_common.g_sched_vacancy_routine;
    
        l_tab_patients table_number := table_number();
    
        l_id_institution institution.id_institution%TYPE := i_id_institution;
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule,
                   --sg.id_patient,
                   s.id_instit_requested,
                   s.id_dcs_requested,
                   s.id_sch_event,
                   sr.id_professional,
                   s.dt_begin_tstz,
                   s.dt_end_tstz,
                   s.flg_vacancy,
                   s.schedule_notes,
                   s.id_lang_translator,
                   s.id_lang_preferred,
                   s.id_reason,
                   s.id_origin,
                   s.id_room,
                   s.flg_sch_type,
                   s.flg_schedule_via,
                   s.flg_request_type,
                   s.id_episode,
                   s.id_sch_combi_detail,
                   s.id_schedule_recursion,
                   s.flg_status
              FROM schedule s, sch_resource sr
             WHERE s.id_schedule = c_sched.i_old_id_schedule
               AND s.id_schedule = sr.id_schedule(+);
    
        l_sched_rec    c_sched%ROWTYPE;
        l_pat_referral p1_external_request.id_external_request%TYPE;
    
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
    
        -- Set associated referral
        PROCEDURE inner_set_pat_referral
        (
            i_id_schedule  schedule.id_schedule%TYPE,
            i_pat_referral p1_external_request.id_external_request%TYPE
        ) IS
        BEGIN
        
            IF i_pat_referral IS NOT NULL
            THEN
                g_error := 'CALL PK_REF_EXT_SYS.SET_REF_SCHEDULE WITH id_external_request = ' || i_pat_referral;
                IF NOT pk_ref_ext_sys.set_ref_schedule(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_id_ref   => i_pat_referral,
                                                       i_schedule => i_id_schedule,
                                                       i_notes    => NULL,
                                                       i_episode  => NULL,
                                                       o_error    => o_error)
                THEN
                    pk_utils.undo_changes;
                END IF;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- Se nao existe P1, nao tem que actualizar o estado
        
        END;
    
        -- Get the old schedule's associated referral
        FUNCTION inner_get_pat_referral(i_old_id_schedule schedule.id_schedule%TYPE)
            RETURN p1_external_request.id_external_request%TYPE IS
            l_pat_referral p1_external_request.id_external_request%TYPE := NULL;
        BEGIN
            --g_error := 'INNER_GET_PAT_REFERRAL';
            /*SELECT exr.id_external_request
             INTO l_pat_referral
             FROM p1_external_request exr
            WHERE exr.id_schedule = inner_get_pat_referral.i_old_id_schedule;*/
            g_error := 'CALL TO pk_ref_module.get_ref_sch_to_cancel with id_schedule=' ||
                       inner_get_pat_referral.i_old_id_schedule;
            IF NOT pk_ref_module.get_ref_sch_to_cancel(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_schedule         => inner_get_pat_referral.i_old_id_schedule,
                                                       o_id_external_request => l_pat_referral,
                                                       o_error               => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            RETURN l_pat_referral;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    BEGIN
        o_flg_proceed := g_no;
        o_flg_show    := g_no;
    
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        -- Convert start date to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        -- Convert start date to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        -- Convert current date to timestamp
        IF NOT pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                        i_inst      => i_prof.institution,
                                                        i_timestamp => l_sysdate,
                                                        o_timestamp => l_sysdate,
                                                        o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET CANCEL NOTES MESSAGE';
        -- Set tokens to replace
        l_tokens := table_varchar('@1', '@2');
    
        -- Set replacements
        l_replacements := table_varchar(string_date_hm(i_lang, i_prof, l_sysdate),
                                        string_date_hm(i_lang, i_prof, l_dt_begin));
        -- Get cancel notes message
        l_message := get_message(i_lang => i_lang, i_message => g_rescheduled_from_to);
    
        -- Replace tokens
        IF NOT replace_tokens(i_lang         => i_lang,
                              i_string       => l_message,
                              i_tokens       => l_tokens,
                              i_replacements => l_replacements,
                              o_string       => l_schedule_cancel_notes,
                              o_error        => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'CALL INNER_GET_PAT_REFERRAL';
        -- Get the associated referral before cancelling.
        l_pat_referral := inner_get_pat_referral(i_old_id_schedule);
    
        g_error := 'GET OLD SCHEDULE';
        -- Get old schedule
        l_sched_rec := inner_get_old_schedule(i_old_id_schedule);
    
        g_error := 'CANCEL SCHEDULE';
        -- Cancel schedule
        IF NOT cancel_schedule(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_schedule      => i_old_id_schedule,
                               i_id_cancel_reason => NULL,
                               i_cancel_notes     => l_schedule_cancel_notes,
                               o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- Try to reschedule unplanned appointments as routine, if there are vacancies available.
        IF l_sched_rec.flg_vacancy = pk_schedule_common.g_sched_vacancy_unplanned
        THEN
            l_flg_vacancy := pk_schedule_common.g_sched_vacancy_routine;
        ELSE
            l_flg_vacancy := l_sched_rec.flg_vacancy;
        END IF;
    
        g_error := 'GET PATIENT LIST';
        SELECT sg.id_patient
          BULK COLLECT
          INTO l_tab_patients
          FROM schedule s
          LEFT JOIN sch_group sg
            ON s.id_schedule = sg.id_schedule
         WHERE s.id_schedule = i_old_id_schedule;
    
        g_error := 'CREATE SCHEDULE';
        -- Create new schedule
        IF NOT create_schedule(i_lang                  => i_lang,
                               i_prof                  => i_prof,
                               i_id_patient            => l_tab_patients,
                               i_id_dep_clin_serv      => l_sched_rec.id_dcs_requested,
                               i_id_sch_event          => l_sched_rec.id_sch_event,
                               i_id_prof               => i_id_prof,
                               i_dt_begin              => i_dt_begin,
                               i_dt_end                => i_dt_end,
                               i_flg_vacancy           => l_flg_vacancy,
                               i_schedule_notes        => l_sched_rec.schedule_notes,
                               i_id_lang_translator    => l_sched_rec.id_lang_translator,
                               i_id_lang_preferred     => l_sched_rec.id_lang_preferred,
                               i_id_reason             => l_sched_rec.id_reason,
                               i_id_origin             => l_sched_rec.id_origin,
                               i_flg_sch_type          => l_sched_rec.flg_sch_type,
                               i_id_schedule_ref       => i_old_id_schedule,
                               i_id_analysis           => NULL,
                               i_show_vacancy_warn     => FALSE,
                               i_flg_schedule_via      => l_sched_rec.flg_schedule_via,
                               i_flg_request_type      => l_sched_rec.flg_request_type,
                               i_do_overlap            => i_do_overlap,
                               i_sch_option            => i_sch_option,
                               i_id_consult_vac        => i_id_consult_vac,
                               i_id_episode            => l_sched_rec.id_episode,
                               i_id_sch_combi_detail   => l_sched_rec.id_sch_combi_detail,
                               i_id_schedule_recursion => l_sched_rec.id_schedule_recursion,
                               i_flg_status            => l_sched_rec.flg_status,
                               o_id_schedule           => o_id_schedule,
                               o_flg_proceed           => o_flg_proceed,
                               o_flg_show              => o_flg_show,
                               o_msg                   => o_msg,
                               o_msg_title             => o_msg_title,
                               o_button                => o_button,
                               o_error                 => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'CALL INNER_SET_PAT_REFERRAL';
        -- Set the associated referral
        inner_set_pat_referral(o_id_schedule, l_pat_referral);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_reschedule;

    /*
    * Validates multiple reschedules.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_schedule           List of schedules (identifiers) to reschedule.
    * @param i_id_prof            Target professional's identifier.
    * @param i_dt_begin           Start date.
    * @param i_dt_end             End date.
    * @param i_id_dep             Selected department's identifier.
    * @param i_id_dep_clin_serv   Selected Department-Clinical Service's identifier.
    * @param i_id_event           Selected event's identifier.
    * @param i_id_exam            Selected exam's identifier.
    * @param i_id_analysis        Selected analysis' identifier.
    * @param o_list_sch_hour      List of schedule identifiers + start date + end date (for schedules that can be rescheduled).
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set to 'Y' if there is a message to show.
    * @param o_msg                Message body.
    * @param o_msg_title          Message title.
    * @param o_button             Buttons to show.
    * @param o_error              Error message if something goes wrong
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/25
    *
    * UPDATED
    * Adaptada para a agenda MFR
    * @author  Telmo
    * @version 2.4.3.x
    * @date    16-01-2009
    */
    FUNCTION validate_mult_reschedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_schedules        IN table_varchar,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_id_dep           IN VARCHAR2 DEFAULT NULL,
        i_id_dep_clin_serv IN VARCHAR2 DEFAULT NULL,
        i_id_event         IN VARCHAR2 DEFAULT NULL,
        i_id_exam          IN VARCHAR2 DEFAULT NULL,
        i_id_analysis      IN VARCHAR2 DEFAULT NULL,
        i_id_phys_area     IN VARCHAR2 DEFAULT NULL,
        o_list_sch_hour    OUT table_varchar,
        o_flg_proceed      OUT VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'VALIDATE_MULT_RESCHEDULE';
        l_hour_begin VARCHAR2(30);
        l_hour_end   VARCHAR2(30);
        l_unplanned  NUMBER;
        l_out_idx    NUMBER := 1;
        l_past       BOOLEAN := FALSE;
        l_msg_idx    NUMBER := 0;
        l_invalid    BOOLEAN;
        l_msg        sch_mult_resched_msg_aux.msg%TYPE;
        l_found_ts   TIMESTAMP WITH TIME ZONE := NULL;
    
        -- These constants are defined here, as they make no sense
        -- outside the scope of this function.
        l_error_type CONSTANT VARCHAR2(1) := 'E';
        l_info_type  CONSTANT VARCHAR2(1) := 'I';
        l_warn_type  CONSTANT VARCHAR2(1) := 'W';
    
        CURSOR c_schedules(i_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule,
                   dcs.id_department,
                   s.id_dcs_requested,
                   s.flg_sch_type,
                   s.id_sch_event,
                   s.dt_begin_tstz,
                   pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof) dt_begin_str,
                   sr.id_professional,
                   pat.name name,
                   string_sch_event(i_lang, s.id_sch_event) event_name,
                   string_date_hm(i_lang, i_prof, s.dt_begin_tstz) desc_date,
                   string_dep_clin_serv(i_lang, s.id_dcs_requested) clin_serv,
                   si.id_physiatry_area
              FROM schedule s, sch_group sg, sch_resource sr, patient pat, dep_clin_serv dcs, schedule_intervention si
             WHERE s.id_schedule = i_id_schedule
               AND dcs.id_dep_clin_serv = s.id_dcs_requested
               AND sg.id_schedule(+) = s.id_schedule
               AND sr.id_schedule(+) = s.id_schedule
               AND si.id_schedule(+) = s.id_schedule
               AND pat.id_patient(+) = sg.id_patient;
    
        l_schedule_rec c_schedules%ROWTYPE;
    
        -- Inner procedure that adds a message to the temporary messages' table.
        PROCEDURE inner_add_message
        (
            i_id_schedule schedule.id_schedule%TYPE,
            i_type        VARCHAR2,
            i_msg         VARCHAR2
        ) IS
        BEGIN
            g_error   := 'INNER_ADD_MESSAGE';
            l_msg_idx := l_msg_idx + 1;
            -- Add a message.
            INSERT INTO sch_mult_resched_msg_aux
                (id_msg, id_schedule, flg_type, msg)
            VALUES
                (l_msg_idx, i_id_schedule, i_type, i_msg);
        END inner_add_message;
    
        -- Checks if the schedule can be rescheduled, that is, if the schedule's data
        -- corresponds to the search criteria.
        -- Note: any schedule can be moved to and kept in the clipboard, but it can only
        -- be rescheduled if it matches the search criteria.
        FUNCTION inner_get_invalid_params_msg
        (
            i_schedule_rec IN c_schedules%ROWTYPE,
            o_invalid      OUT BOOLEAN,
            o_message      OUT sch_mult_resched_msg_aux.msg%TYPE
        ) RETURN BOOLEAN IS
            l_list_dep       table_number;
            l_list_dcs       table_number;
            l_list_event     table_number;
            l_list_analysis  table_number;
            l_list_physareas table_number;
            l_replacements   table_varchar := table_varchar();
            l_tokens         table_varchar := table_varchar();
            l_message        sch_mult_resched_msg_aux.msg%TYPE := NULL;
        BEGIN
            o_invalid := FALSE;
            g_error   := 'INNER_GET_INVALID_PARAMS_MSG: GET LISTS';
            -- Get lists of elements
            l_list_dep := get_list_number_csv(i_id_dep);
        
            IF i_schedule_rec.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
            THEN
                -- OS DCS TEM DE SER CARREGADOS DA FUNCAO GET_BASE_DCS 
                IF NOT pk_schedule_mfr.get_base_id_dcs(i_lang, i_prof, l_list_dcs, o_error)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
                l_list_dcs := get_list_number_csv(i_id_dep_clin_serv);
            END IF;
            l_list_event     := get_list_number_csv(i_id_event);
            l_list_analysis  := get_list_number_csv(i_id_analysis);
            l_list_physareas := get_list_number_csv(i_id_phys_area);
            g_error          := 'INNER_GET_INVALID_PARAMS_MSG: CHECK';
            -- Check if all parameters are correct
            IF NOT (exists_inside_table_number(i_schedule_rec.id_department, l_list_dep) AND
                exists_inside_table_number(i_schedule_rec.id_dcs_requested, l_list_dcs) AND
                exists_inside_table_number(i_schedule_rec.id_sch_event, l_list_event) AND
                exists_inside_table_number(i_schedule_rec.id_physiatry_area, l_list_physareas))
            THEN
                -- The schedule's data does not match the UI's parameters, so it cannot be rescheduled,
                -- so that it does not appear like an inconsistency to the user.
                o_invalid := TRUE;
            
                -- Set replacements
                l_replacements := table_varchar(i_schedule_rec.event_name,
                                                i_schedule_rec.name,
                                                i_schedule_rec.clin_serv,
                                                i_schedule_rec.desc_date);
                -- Set tokens to replace
                l_tokens := table_varchar('@1', '@2', '@3', '@4');
                -- Get message
                g_error   := 'GET ERROR MESSAGE - INVALID PARAMS';
                l_message := get_message(i_lang => i_lang, i_message => g_sch_does_not_match_params);
            
            END IF;
            g_error := 'INNER_GET_INVALID_PARAMS_MSG: REPLACE';
            -- Replace tokens
            IF NOT replace_tokens(i_lang         => i_lang,
                                  i_string       => l_message,
                                  i_tokens       => l_tokens,
                                  i_replacements => l_replacements,
                                  o_string       => o_message,
                                  o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            RETURN TRUE;
        END inner_get_invalid_params_msg;
    
        -- Inner function that returns the full message,
        -- composed by all the partial messages in the right order.
        FUNCTION inner_get_full_message
        (
            i_total  NUMBER,
            i_errors NUMBER,
            i_past   BOOLEAN
        ) RETURN VARCHAR2 IS
            l_message      VARCHAR2(32000);
            l_errors_found BOOLEAN := FALSE;
            CURSOR c_messages IS
                SELECT sm.msg, sm.flg_type
                  FROM sch_mult_resched_msg_aux sm
                 ORDER BY decode(sm.flg_type, l_info_type, 1, l_warn_type, 2, l_error_type, 3) ASC,
                          sm.id_schedule ASC,
                          sm.id_msg ASC;
        BEGIN
            g_error := 'INNER_GET_FULL_MESSAGE';
            IF (i_total > i_errors)
            THEN
                -- Add info/ok separator
                l_message := '<b>' || get_message(i_lang, g_resched_valid_ones) || '</b>' || chr(13);
                -- Start new list
                l_message := l_message || '<ul>';
            END IF;
            -- Iterate through messages
            FOR msg IN c_messages
            LOOP
                IF NOT l_errors_found
                THEN
                    IF (msg.flg_type = l_error_type)
                    THEN
                        IF (i_total > i_errors)
                        THEN
                            -- End unordered list
                            l_message := l_message || '</ul>';
                        END IF;
                        -- Add error separator
                        l_errors_found := TRUE;
                        l_message      := l_message || chr(13) || '<b>' || get_message(i_lang, g_resched_invalid_ones) ||
                                          '</b>' || chr(13);
                        -- Start new list
                        l_message := l_message || '<ul>';
                    END IF;
                END IF;
                l_message := l_message || '<li>' || msg.msg || '</li>' || chr(13);
            END LOOP;
            -- End unordered list
            l_message := l_message || '</ul>';
        
            IF (i_total > i_errors)
            THEN
                -- Add confirmation message
                IF i_past
                THEN
                    l_message := l_message || '<br/>' || get_message(i_lang, g_resched_confirm_msg_past);
                ELSE
                    l_message := l_message || '<br/>' || get_message(i_lang, g_resched_confirm_msg);
                END IF;
            END IF;
            RETURN l_message;
        END;
    
        -- Returns an error message indicating that the appointment will not be created.
        FUNCTION inner_get_no_vacancy_error
        (
            i_schedule_rec IN c_schedules%ROWTYPE,
            o_msg          OUT VARCHAR,
            o_error        OUT t_error_out
        ) RETURN BOOLEAN IS
            l_replacements table_varchar;
            l_tokens       table_varchar;
            l_message      sys_message.desc_message%TYPE;
        BEGIN
            g_error := 'INNER_GET_NO_VACANCY_ERROR';
        
            -- Depending on having the patient's name,
            -- we have different behaviours.
            IF i_schedule_rec.name IS NOT NULL
            THEN
                -- Set replacements
                l_replacements := table_varchar(i_schedule_rec.event_name,
                                                i_schedule_rec.name,
                                                i_schedule_rec.clin_serv,
                                                i_schedule_rec.desc_date);
                -- Set tokens to replace
                l_tokens := table_varchar('@1', '@2', '@3', '@4');
                -- Get message
                g_error   := 'GET ERROR MESSAGE WITH NAME';
                l_message := get_message(i_lang => i_lang, i_message => g_resched_no_vacancy_name);
            ELSE
                -- Set replacements
                l_replacements := table_varchar(i_schedule_rec.event_name,
                                                i_schedule_rec.clin_serv,
                                                i_schedule_rec.desc_date);
                -- Set tokens to replace
                l_tokens := table_varchar('@1', '@2', '@3');
                -- Get message
                g_error   := 'GET ERROR MESSAGE WITHOUT NAME';
                l_message := get_message(i_lang => i_lang, i_message => g_resched_no_vacancy);
            END IF;
            -- Replace tokens
            IF NOT replace_tokens(i_lang         => i_lang,
                                  i_string       => l_message,
                                  i_tokens       => l_tokens,
                                  i_replacements => l_replacements,
                                  o_string       => o_msg,
                                  o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
            RETURN TRUE;
        END inner_get_no_vacancy_error;
    
        -- Returns a warning message indicating that the appointment will be created
        -- as "unplanned".
        FUNCTION inner_get_unplanned_warning
        (
            i_schedule_rec IN c_schedules%ROWTYPE,
            i_new_date     IN VARCHAR2,
            o_msg          OUT VARCHAR,
            o_error        OUT t_error_out
        ) RETURN BOOLEAN IS
            l_replacements table_varchar;
            l_tokens       table_varchar;
            l_message      sys_message.desc_message%TYPE;
        BEGIN
            g_error := 'INNER_GET_UNPLANNED_WARNING';
        
            -- Depending on having the patient's name,
            -- we have different behaviours.
            IF i_schedule_rec.name IS NOT NULL
            THEN
                -- Set replacements
                l_replacements := table_varchar(i_schedule_rec.event_name,
                                                i_schedule_rec.name,
                                                i_schedule_rec.clin_serv,
                                                i_schedule_rec.desc_date,
                                                i_new_date);
                -- Set tokens to replace
                l_tokens := table_varchar('@1', '@2', '@3', '@4', '@5');
                -- Get message
                g_error   := 'GET WARNING MESSAGE WITH NAME';
                l_message := get_message(i_lang => i_lang, i_message => g_resched_unplanned_with_name);
            ELSE
                -- Set replacements
                l_replacements := table_varchar(i_schedule_rec.event_name,
                                                i_schedule_rec.clin_serv,
                                                i_schedule_rec.desc_date,
                                                i_new_date);
                -- Set tokens to replace
                l_tokens := table_varchar('@1', '@2', '@3', '@4');
                -- Get message
                g_error   := 'GET WARNING MESSAGE WITHOUT NAME';
                l_message := get_message(i_lang => i_lang, i_message => g_resched_unplanned);
            END IF;
            -- Replace tokens
            IF NOT replace_tokens(i_lang         => i_lang,
                                  i_string       => l_message,
                                  i_tokens       => l_tokens,
                                  i_replacements => l_replacements,
                                  o_string       => o_msg,
                                  o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
            RETURN TRUE;
        END inner_get_unplanned_warning;
    
        -- Returns a info message indicating when will the appointment be created.
        FUNCTION inner_get_info
        (
            i_schedule_rec IN c_schedules%ROWTYPE,
            i_new_date     IN VARCHAR2,
            o_msg          OUT VARCHAR,
            o_error        OUT t_error_out
        ) RETURN BOOLEAN IS
            l_replacements table_varchar;
            l_tokens       table_varchar;
            l_message      sys_message.desc_message%TYPE;
        BEGIN
            g_error := 'INNER_GET_INFO';
        
            -- Depending on having the patient's name,
            -- we have different behaviours.
            IF i_schedule_rec.name IS NOT NULL
            THEN
                -- Set replacements
                l_replacements := table_varchar(i_schedule_rec.event_name,
                                                i_schedule_rec.name,
                                                i_schedule_rec.clin_serv,
                                                i_schedule_rec.desc_date,
                                                i_new_date);
                -- Set tokens to replace
                l_tokens := table_varchar('@1', '@2', '@3', '@4', '@5');
                -- Get message
                g_error   := 'GET INFO MESSAGE WITH NAME';
                l_message := get_message(i_lang => i_lang, i_message => g_resched_ok_with_name);
            ELSE
                -- Set replacements
                l_replacements := table_varchar(i_schedule_rec.event_name,
                                                i_schedule_rec.clin_serv,
                                                i_schedule_rec.desc_date,
                                                i_new_date);
                -- Set tokens to replace
                l_tokens := table_varchar('@1', '@2', '@3', '@4');
                -- Get message
                g_error   := 'GET INFO MESSAGE WITHOUT NAME';
                l_message := get_message(i_lang => i_lang, i_message => g_resched_ok);
            END IF;
            -- Replace tokens
            IF NOT replace_tokens(i_lang         => i_lang,
                                  i_string       => l_message,
                                  i_tokens       => l_tokens,
                                  i_replacements => l_replacements,
                                  o_string       => o_msg,
                                  o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
            RETURN TRUE;
        END inner_get_info;
    
        -- Inner function that returns a record containing a schedule's data.
        FUNCTION inner_get_schedule_rec(i_id_schedule schedule.id_schedule%TYPE) RETURN c_schedules%ROWTYPE IS
            l_schedule_rec_ret c_schedules%ROWTYPE;
        BEGIN
            g_error := 'INNER_GET_SCHEDULE_REC OPEN';
            OPEN c_schedules(i_id_schedule);
            g_error := 'INNER_GET_SCHEDULE_REC FETCH';
            FETCH c_schedules
                INTO l_schedule_rec_ret;
            IF c_schedules%NOTFOUND
            THEN
                l_schedule_rec_ret := NULL;
            END IF;
            g_error := 'INNER_GET_SCHEDULE_REC CLOSE';
            CLOSE c_schedules;
            RETURN l_schedule_rec_ret;
        END inner_get_schedule_rec;
    
    BEGIN
        g_error         := 'ITERATE THROUGH SCHEDULES';
        o_flg_show      := g_no;
        o_flg_proceed   := g_no;
        o_list_sch_hour := table_varchar();
    
        FOR idx IN i_schedules.first .. i_schedules.last
        LOOP
        
            g_error := 'GET SCHEDULE RECORD';
            -- Get a record with the schedule's data
            l_schedule_rec := inner_get_schedule_rec(i_schedules(idx));
        
            g_error := 'CHECK SEARCH PARAMS';
            -- Check if the schedule matches the UI parameters for selecting vacancies and schedules
            IF NOT inner_get_invalid_params_msg(i_schedule_rec => l_schedule_rec,
                                                o_invalid      => l_invalid,
                                                o_message      => l_msg)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_invalid
            THEN
                -- Add error message
                inner_add_message(l_schedule_rec.id_schedule, l_error_type, l_msg);
            ELSE
                g_error := 'CALL GET_FIRST_VALID_VACANCY';
                -- Get the first valid vacancy for the schedule.
                -- This function uses a temporary table to reserve vacancies.
                IF NOT get_first_valid_vacancy(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_search_date_begin => i_dt_begin,
                                               i_search_date_end   => i_dt_end,
                                               i_flg_sch_type      => l_schedule_rec.flg_sch_type,
                                               i_sch_event         => l_schedule_rec.id_sch_event,
                                               i_id_dep_clin_serv  => l_schedule_rec.id_dcs_requested,
                                               i_id_physarea       => l_schedule_rec.id_physiatry_area,
                                               i_id_prof           => i_id_prof,
                                               i_dt_begin          => l_schedule_rec.dt_begin_str,
                                               o_hour_begin        => l_hour_begin,
                                               o_hour_end          => l_hour_end,
                                               o_unplanned         => l_unplanned,
                                               o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF l_hour_begin IS NOT NULL
                THEN
                    g_error := 'CALL GET_STRING_TSTZ FOR l_hour_begin';
                    -- Convert to timestamp
                    IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_timestamp => l_hour_begin,
                                                         i_timezone  => NULL,
                                                         o_timestamp => l_found_ts,
                                                         o_error     => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
                IF l_hour_begin IS NULL
                THEN
                    -- No date was found. There are no vacancies (neither free or occupied).
                
                    g_error := 'NO DATE FOUND';
                
                    -- Get error message
                    IF NOT inner_get_no_vacancy_error(l_schedule_rec, l_msg, o_error)
                    THEN
                        RETURN FALSE;
                    ELSE
                        -- Add error message
                        inner_add_message(l_schedule_rec.id_schedule, l_error_type, l_msg);
                    END IF;
                ELSIF l_unplanned = 1
                THEN
                    -- The appointment will be created as "unplanned".
                
                    IF l_found_ts < current_timestamp
                    THEN
                        l_past := TRUE;
                    END IF;
                
                    -- Add schedule identifier and date to output collection.
                    g_error := 'ADD SCHEDULE AND DATE AS UNPLANNED';
                    o_list_sch_hour.extend;
                    o_list_sch_hour(l_out_idx) := l_schedule_rec.id_schedule || '|' || l_hour_begin || '|' ||
                                                  l_hour_end;
                    l_out_idx := l_out_idx + 1;
                
                    -- Get warning message
                    IF NOT inner_get_unplanned_warning(l_schedule_rec,
                                                       string_date_hm(i_lang, i_prof, l_found_ts),
                                                       l_msg,
                                                       o_error)
                    THEN
                        RETURN FALSE;
                    ELSE
                        -- Add warning message
                        inner_add_message(l_schedule_rec.id_schedule, l_warn_type, l_msg);
                    END IF;
                ELSE
                    -- The appointment will get a free vacancy.
                
                    IF l_found_ts < current_timestamp
                    THEN
                        l_past := TRUE;
                    END IF;
                
                    g_error := 'ADD SCHEDULE AND DATE';
                    -- Add schedule identifier and date to output collection.
                    o_list_sch_hour.extend;
                    o_list_sch_hour(l_out_idx) := l_schedule_rec.id_schedule || '|' || l_hour_begin || '|' ||
                                                  l_hour_end;
                    l_out_idx := l_out_idx + 1;
                
                    -- Get info message
                    IF NOT inner_get_info(l_schedule_rec, string_date_hm(i_lang, i_prof, l_found_ts), l_msg, o_error)
                    THEN
                        RETURN FALSE;
                    ELSE
                        -- Add warning message
                        inner_add_message(l_schedule_rec.id_schedule, l_info_type, l_msg);
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        o_flg_show := g_yes;
        IF o_list_sch_hour.count = 0
        THEN
            -- It is not possible to reschedule a single appointment
            o_button      := g_ok_button_code || get_message(i_lang, g_msg_ack) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            o_msg_title   := get_message(i_lang, g_sched_msg_ack_title);
            o_msg         := inner_get_full_message(i_schedules.count,
                                                    i_schedules.count - o_list_sch_hour.count,
                                                    l_past);
        ELSE
            -- At least one appointment can be scheduled
            o_button      := g_cancel_button_code || get_message(i_lang, g_common_no) || '|' || g_ok_button_code ||
                             get_message(i_lang, g_common_yes) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_yes;
            o_msg_title   := get_message(i_lang, g_resched_confirm);
            o_msg         := inner_get_full_message(i_schedules.count,
                                                    i_schedules.count - o_list_sch_hour.count,
                                                    l_past);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END validate_mult_reschedule;

    /*
    * Gets the availability for the cross-view.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional.
    * @param i_args         UI args.
    * @param o_vacants      Vacancies.
    * @param o_schedules    Schedules.
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/28
    *
    * UPDATED
    * ALERT-708 - pesquisa por vagas livres.
    * @author   Telmo Castro
    * @date     25-03-2009
    * @version  2.5
    *
    * UPDATED
    * ALERT-31987 - output da get_vacancies passa a ser a GTT sch_tmptab_vacs em vez do table_number
    * @author  Telmo
    * @date    12-06-2009
    * @version 2.5.0.4
    *
    * UPDATED alert-8202
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    13-10-2009
    */
    FUNCTION get_availability_crossview
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        o_vacants   OUT pk_types.cursor_type,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_AVAILABILITY_CROSSVIEW';
        l_vacancies   table_number;
        l_schedules   table_number;
        l_time_grain  VARCHAR2(2) DEFAULT 'DD';
        l_diff_ts     NUMBER;
        l_list_status table_varchar;
        i             INTEGER;
        l_only_vacs   VARCHAR2(1) := g_no;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_TIMESTAMP_DIFF_STR';
        -- Get difference in days, between timestamps
        IF NOT pk_date_utils.get_timestamp_diff_str(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_timestamp_1 => i_args(idx_dt_end),
                                                    i_timestamp_2 => i_args(idx_dt_begin),
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
        IF NOT
            pk_schedule_common.get_vacancies(i_lang => i_lang, i_prof => i_prof, i_args => i_args, o_error => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_AVAILABLE_VACANCIES';
        -- Get available vacancies only (the ones that not clash with any absence period).
        IF NOT get_available_vacancies(i_lang      => i_lang,
                                       i_prof      => i_prof,
                                       i_vacancies => l_vacancies,
                                       i_fulltable => g_no,
                                       o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_vacants FOR';
        -- Get vacants
        OPEN o_vacants FOR
            SELECT /*+ first_rows */
             pk_date_utils.date_send_tsz(i_lang, dt_begin, i_prof) dt_begin,
             id_prof,
             nick_name,
             nvl(SUM(max_vacancies - used_vacancies), 0) num_vacancies,
             id_sch_event,
             id_dep_clin_serv,
             id_dep
              FROM (SELECT pk_date_utils.trunc_insttimezone(i_prof, scv.dt_begin_tstz, l_time_grain) dt_begin,
                           scv.id_prof,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, scv.id_prof) nick_name,
                           scv.max_vacancies,
                           scv.used_vacancies,
                           scv.id_sch_event,
                           scv.id_dep_clin_serv,
                           (SELECT id_department
                              FROM dep_clin_serv
                             WHERE id_dep_clin_serv = scv.id_dep_clin_serv) id_dep
                      FROM sch_consult_vacancy scv, sch_tmptab_vacs stv
                     WHERE scv.id_sch_consult_vacancy = stv.id_sch_consult_vacancy)
             GROUP BY dt_begin, id_prof, id_sch_event, id_dep_clin_serv
             ORDER BY dt_begin, id_prof;
    
        g_error := 'CALL GET_SCHEDULES';
    
        -- DETERMINE IF ONLY VACANCIES WAS ASKED
        g_error       := 'CALC L_ONLY_VACS';
        l_list_status := pk_schedule.get_list_string_csv(i_args(idx_status));
        i             := l_list_status.first;
        WHILE i IS NOT NULL
              AND l_only_vacs = g_no
        LOOP
            IF l_list_status(i) = pk_schedule_common.g_onlyfreevacs
            THEN
                l_only_vacs := g_yes;
            END IF;
            i := l_list_status.next(i);
        END LOOP;
    
        -- Get schedules
        IF get_only_vacs(i_args(idx_status)) = g_yes
        THEN
            l_schedules := table_number();
        ELSE
            IF NOT pk_schedule_common.get_schedules(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_patient => NULL,
                                                    i_args       => i_args,
                                                    o_schedules  => l_schedules,
                                                    o_error      => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'OPEN o_schedules FOR';
        -- Get schedules
        OPEN o_schedules FOR
            SELECT /*+ first_rows */
             pk_date_utils.date_send_tsz(i_lang,
                                         pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz, l_time_grain),
                                         i_prof) dt_begin,
             sr.id_professional id_prof,
             pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional) nick_name,
             s.id_sch_event,
             dcs.id_dep_clin_serv,
             dcs.id_department id_dep
              FROM schedule s, sch_resource sr, dep_clin_serv dcs
             WHERE sr.id_schedule(+) = s.id_schedule
               AND s.id_dcs_requested = dcs.id_dep_clin_serv
               AND s.id_schedule IN (SELECT *
                                       FROM TABLE(l_schedules))
             ORDER BY dt_begin_tstz, id_prof;
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_date_utils.set_dst_time_check_on;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_availability_crossview;

    /*
    * Returns the translation needs for use on the translators' cross-view.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_args           UI Args.
    * @param o_schedules      Translation needs.
    * @param o_error          Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/28
    *
    * UPDATED
    * ALERT-708 - pesquisa por vagas livres.
    * @author   Telmo Castro
    * @date     25-03-2009
    * @version  2.5
    */
    FUNCTION get_translators_crossview
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'GET_TRANSLATORS_CROSSVIEW';
        l_time_grain VARCHAR2(2) DEFAULT 'DD';
    
        l_schedules table_number;
        l_diff_ts   NUMBER;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_TIMESTAMP_DIFF_STR';
        -- Get difference in days, between timestamps
        IF NOT pk_date_utils.get_timestamp_diff_str(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_timestamp_1 => i_args(idx_dt_end),
                                                    i_timestamp_2 => i_args(idx_dt_begin),
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
        IF get_only_vacs(i_args(idx_status)) = g_yes
        THEN
            l_schedules := table_number();
        ELSE
            IF NOT pk_schedule_common.get_schedules(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_patient => NULL,
                                                    i_args       => i_args,
                                                    o_schedules  => l_schedules,
                                                    o_error      => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'OPEN o_schedules FOR';
        -- Get schedules
        OPEN o_schedules FOR
            SELECT /*+ first_rows */
             pk_date_utils.date_send_tsz(i_lang,
                                         pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz, l_time_grain),
                                         i_prof) dt_begin,
             get_domain_desc(i_lang, g_sched_language_domain, s.id_lang_translator) desc_language,
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
            pk_date_utils.set_dst_time_check_on;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_translators_crossview;

    /**
    * Returns all the notification types for the multi-choice
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_flg_search       flag to set if the "all" type is used or not
    * @param      o_notification_types   list of types
    * @param      o_error            Error message
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Tiago Ferreira
    * @version    alpha
    * @since      2006/12/21
    */
    FUNCTION get_notification_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_search         IN VARCHAR2,
        o_notification_types OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                VARCHAR2(32) := 'GET_NOTIFICATION_STATUS';
        l_notification_code_domain sys_domain.code_domain%TYPE := g_sched_flg_notif_status;
    BEGIN
        g_error := 'OPEN o_notification_types FOR';
        -- Loading notification types --------------------------------------------------------------
        OPEN o_notification_types FOR
            SELECT val data,
                   desc_val label,
                   decode(sd.val,
                          pk_schedule_common.g_notification_status_notified,
                          g_yes,
                          pk_schedule_common.g_notification_status_pending,
                          g_yes,
                          g_no) flg_select,
                   sd.img_name icon,
                   9 order_field
              FROM sys_domain sd
             WHERE sd.code_domain = l_notification_code_domain
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
             ORDER BY label ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_notification_status;

    /**
    * Returns all the scheduling ways (meios de marcacao) for the multi-choice
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      o_via_types       list of types
    * @param      o_error            Error message
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Telmo Castro
    * @version    2.4.3
    * @since      12-05-2008
    */
    FUNCTION get_schedule_vias
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_via_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_SCHEDULE_VIA';
        l_code_domain sys_domain.code_domain%TYPE := g_sched_flg_sch_via;
    BEGIN
        -- open cursor
        g_error := 'OPEN cursor';
        OPEN o_via_types FOR
            SELECT val data,
                   desc_val label,
                   decode(sd.val, pk_schedule.g_default_flg_sch_via, g_yes, g_no) flg_select,
                   sd.img_name icon,
                   9 order_field
              FROM sys_domain sd
             WHERE sd.code_domain = l_code_domain
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
             ORDER BY sd.rank, sd.desc_val ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_schedule_vias;

    /**
    * Returns all the request types for the multi-choice
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      o_req_types        list of types
    * @param      o_error            Error message
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Telmo Castro
    * @version    2.4.3
    * @since      12-05-2008
    */
    FUNCTION get_request_types
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_via_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_REQUEST_TYPES';
        l_code_domain sys_domain.code_domain%TYPE := g_sched_flg_req_type;
        l_prof_cat    category.flg_type%TYPE;
    BEGIN
        -- open cursor
    
        l_prof_cat := pk_tools.get_prof_cat(i_prof);
        -- se a categoria profissional for enfermeiro dever· aparecer por defeito o enfermeiro, sen„o ser· o mÈdico
    
        g_error := 'OPEN cursor';
        OPEN o_via_types FOR
            SELECT val data,
                   desc_val label,
                   decode(l_prof_cat,
                          g_prof_cat_nurse,
                          decode(sd.val, g_def_sched_flg_req_type_nurse, g_yes, g_no),
                          decode(sd.val, g_default_sched_flg_req_type, g_yes, g_no)) flg_select,
                   sd.img_name icon,
                   9 order_field
              FROM sys_domain sd
             WHERE sd.code_domain = l_code_domain
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
             ORDER BY sd.rank, sd.desc_val ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_via_types);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_request_types;

    /**
    * It resets the vacancies to the default values for the given institution.
    * Default values are stored in SCH_DEFAULT_CONSULT_VACANCY.
    *
    * @param   i_id_inst      Institution
    * @param   i_id_software  Software
    * @param   i_lang         Language
    * @param   o_error        Error message if an error occurred
    *
    * @return  boolean type   , "False" on error or "True" if success
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version 0.1
    * @since   2007/07/04
    */
    FUNCTION reset
    (
        i_id_inst     IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_lang        IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'RESET';
        l_func_exception EXCEPTION;
        l_trunc_curr_ts TIMESTAMP WITH TIME ZONE;
        l_reset_ret     BOOLEAN := TRUE;
    
        -- Outpatient appointments
        CURSOR rec_schedule IS
            SELECT s.id_schedule
              FROM schedule s, schedule_outp so
             WHERE s.id_instit_requested = i_id_inst
               AND s.id_schedule = so.id_schedule
               AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294);
    
        -- Outpatient consult requests for the selected appointments
        CURSOR rec_consult_reqs(i_list_schedules table_number) IS
            SELECT /*+ first_rows */
             ssr.id_consult_req
              FROM sch_schedule_request ssr
             WHERE ssr.id_schedule IN (SELECT *
                                         FROM TABLE(i_list_schedules))
            UNION
            SELECT /*+ first_rows */
             cr.id_consult_req
              FROM consult_req cr
             WHERE cr.id_schedule IN (SELECT *
                                        FROM TABLE(i_list_schedules));
    
        l_schedule     table_number;
        l_consult_reqs table_number;
    
        l_count   PLS_INTEGER;
        l_rows_ei table_varchar;
    BEGIN
        g_error := 'START';
        pk_alertlog.log_info(text        => 'Deleting schedules from institution [' || i_id_inst || ']',
                             object_name => g_package_name,
                             owner       => g_package_owner);
    
        g_error := 'OPEN rec_schedule';
        -- Open cursor
        OPEN rec_schedule;
    
        g_error := 'FETCH rec_schedule';
        -- Get schedule identifiers
        FETCH rec_schedule BULK COLLECT
            INTO l_schedule;
    
        g_error := 'CLOSE rec_schedule';
        -- Close cursor
        CLOSE rec_schedule;
    
        g_error := 'OPEN rec_consult_reqs';
        -- Open cursor
        OPEN rec_consult_reqs(l_schedule);
    
        g_error := 'FETCH rec_consult_reqs';
        -- Get consult request identifiers
        FETCH rec_consult_reqs BULK COLLECT
            INTO l_consult_reqs;
    
        g_error := 'CLOSE rec_consult_reqs';
        -- Close cursor
        CLOSE rec_consult_reqs;
    
        g_error := 'DELETE FROM schedule';
        -- Delete appointments
        IF i_id_software = 2
        THEN
        
            UPDATE schedule s
               SET s.flg_status = g_status_deleted, s.id_sch_consult_vacancy = NULL
             WHERE s.id_instit_requested = i_id_inst
               AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294)
               AND EXISTS (SELECT 0
                      FROM schedule_sr sr
                     WHERE sr.id_schedule = s.id_schedule);
        
            ts_epis_info.upd(flg_sch_status_in => g_status_deleted,
                             where_in          => 'id_schedule in (select id_schedule from schedule s' ||
                                                  ' WHERE s.id_instit_requested = ' || i_id_inst ||
                                                  ' AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294)' ||
                                                  ' AND EXISTS (SELECT 0 FROM schedule_sr sr' ||
                                                  ' WHERE sr.id_schedule = s.id_schedule))',
                             rows_out          => l_rows_ei);
        ELSE
            UPDATE schedule s
               SET s.flg_status = g_status_deleted, s.id_sch_consult_vacancy = NULL
             WHERE s.id_instit_requested = i_id_inst
               AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294)
               AND EXISTS (SELECT 0
                      FROM schedule_outp so
                     WHERE so.id_schedule = s.id_schedule);
            ts_epis_info.upd(flg_sch_status_in => g_status_deleted,
                             where_in          => 'id_schedule in (select id_schedule from schedule s' ||
                                                  ' WHERE s.id_instit_requested = ' || i_id_inst ||
                                                  ' AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294)' ||
                                                  ' AND EXISTS (SELECT 0 FROM schedule_outp so' ||
                                                  ' WHERE so.id_schedule = s.id_schedule))',
                             rows_out          => l_rows_ei);
        END IF;
    
        UPDATE schedule s
           SET s.flg_status = g_status_deleted, s.id_sch_consult_vacancy = NULL
         WHERE s.id_instit_requested = i_id_inst
           AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294)
           AND NOT EXISTS (SELECT 0
                  FROM schedule_outp so
                 WHERE so.id_schedule = s.id_schedule)
           AND NOT EXISTS (SELECT 0
                  FROM schedule_sr sr
                 WHERE sr.id_schedule = s.id_schedule);
        ts_epis_info.upd(flg_sch_status_in => g_status_deleted,
                         where_in          => 'id_schedule in (select id_schedule from schedule s ' ||
                                              ' WHERE s.id_instit_requested = ' || i_id_inst ||
                                              ' AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294)' ||
                                              ' AND NOT EXISTS (SELECT 0' ||
                                              ' FROM schedule_outp so WHERE so.id_schedule = s.id_schedule)' ||
                                              ' AND NOT EXISTS (SELECT 0' ||
                                              ' FROM schedule_sr sr WHERE sr.id_schedule = s.id_schedule))',
                         rows_out          => l_rows_ei);
    
        g_error := 'DELETE FROM sch_group';
        -- Delete patient-appointment associations
        DELETE FROM sch_group g
         WHERE g.id_schedule IN (SELECT s.id_schedule
                                   FROM schedule s
                                  WHERE s.id_instit_requested = i_id_inst
                                    AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294));
    
        g_error := 'DELETE FROM sch_prof_outp';
        -- Delete professional-appointment associations
        DELETE FROM sch_prof_outp sfo
         WHERE sfo.id_schedule_outp IN
               (SELECT so.id_schedule_outp
                  FROM schedule_outp so
                 WHERE so.id_schedule IN
                       (SELECT s.id_schedule
                          FROM schedule s
                         WHERE s.id_instit_requested = i_id_inst
                           AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294)));
    
        ts_epis_info.upd(sch_prof_outp_id_prof_in  => NULL,
                         sch_prof_outp_id_prof_nin => FALSE,
                         where_in                  => 'id_schedule_outp IN' || '(SELECT so.id_schedule_outp' ||
                                                      'FROM schedule_outp so' || 'WHERE so.id_schedule IN' ||
                                                      '(SELECT s.id_schedule' || 'FROM schedule s' ||
                                                      'WHERE s.id_instit_requested = ' || i_id_inst ||
                                                      'AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294)))',
                         rows_out                  => l_rows_ei);
    
        g_error := 'DELETE FROM sch_resource';
        -- Delete professional-appointment associations
        DELETE FROM sch_resource sr
         WHERE sr.id_schedule IN (SELECT s.id_schedule
                                    FROM schedule s
                                   WHERE s.id_instit_requested = i_id_inst
                                     AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294));
    
        g_error := 'DELETE FROM schedule_outp';
        -- Delete outpatient specific data
        DELETE /*+ first_rows */
        FROM schedule_outp so
         WHERE so.id_schedule IN (SELECT s.id_schedule
                                    FROM schedule s
                                   WHERE s.id_instit_requested = i_id_inst
                                     AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294));
    
        g_error := 'DELETE FROM schedule_analysis';
        -- Delete analysis specific data
        DELETE FROM schedule_analysis sa
         WHERE sa.id_schedule IN (SELECT s.id_schedule
                                    FROM schedule s
                                   WHERE s.id_instit_requested = i_id_inst
                                     AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294));
    
        g_error := 'DELETE FROM schedule_exam';
        -- Delete exam specific data
        DELETE FROM schedule_exam se
         WHERE se.id_schedule IN (SELECT s.id_schedule
                                    FROM schedule s
                                   WHERE s.id_instit_requested = i_id_inst
                                     AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294));
    
        g_error := 'DELETE FROM sch_schedule_request';
        -- Delete appointment request
        DELETE /*+ first_rows */
        FROM sch_schedule_request ssr
         WHERE ssr.id_schedule IN (SELECT s.id_schedule
                                     FROM schedule s
                                    WHERE s.id_instit_requested = i_id_inst
                                      AND s.id_schedule NOT IN (2000, 2001, 2002, 2003, 413294))
            OR ssr.id_consult_req IN (SELECT *
                                        FROM TABLE(l_consult_reqs));
    
        g_error := 'DELETE FROM consult_req_prof';
        -- Delete appointment request-professional associations
        DELETE /*+ first_rows */
        FROM consult_req_prof crp
         WHERE crp.id_consult_req IN (SELECT *
                                        FROM TABLE(l_consult_reqs));
    
        g_error := 'DELETE FROM consult_req';
        -- Delete appointment request
        DELETE /*+ first_rows */
        FROM consult_req cr
         WHERE cr.id_consult_req IN (SELECT *
                                       FROM TABLE(l_consult_reqs));
    
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL TRUNC_INSTTIMEZONE FOR l_trunc_dt_curr';
        -- Truncate current_timestamp
        IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => profissional(NULL, i_id_inst, i_id_software),
                                                i_timestamp => current_timestamp,
                                                o_timestamp => l_trunc_curr_ts,
                                                o_error     => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        COMMIT;
    
        pk_alertlog.log_info(text        => 'Inserting default vacancies into institution [' || i_id_inst || ']',
                             object_name => g_package_name,
                             owner       => g_package_owner);
        g_error := 'INSERT INTO sch_consult_vacancy [' || i_id_inst || ']';
        MERGE INTO sch_consult_vacancy s
        USING (SELECT sdcv.*,
                      CASE
                           WHEN sdcv.dt_begin_tstz BETWEEN l_trunc_curr_ts AND
                                pk_date_utils.add_days_to_tstz(l_trunc_curr_ts, 1) THEN
                            max_vacancies
                           WHEN sdcv.dt_begin_tstz NOT BETWEEN pk_date_utils.add_days_to_tstz(l_trunc_curr_ts, -90) AND
                                pk_date_utils.add_days_to_tstz(l_trunc_curr_ts, 120) THEN
                            1
                           ELSE
                            sdcv.max_vacancies -- l_max_vac
                       END real_max_vac,
                      CASE
                           WHEN sdcv.dt_begin_tstz BETWEEN l_trunc_curr_ts AND
                                pk_date_utils.add_days_to_tstz(l_trunc_curr_ts, 1) THEN
                            0
                           WHEN sdcv.dt_begin_tstz NOT BETWEEN pk_date_utils.add_days_to_tstz(l_trunc_curr_ts, -90) AND
                                pk_date_utils.add_days_to_tstz(l_trunc_curr_ts, 120) THEN
                            0
                           WHEN sdcv.used_vacancies > sdcv.max_vacancies THEN
                            sdcv.max_vacancies -- l_max_vac
                           ELSE
                            sdcv.used_vacancies
                       END real_used_vac
                 FROM sch_default_consult_vacancy sdcv
                WHERE sdcv.id_institution = i_id_inst) t
        ON (s.id_sch_consult_vacancy = t.id_sch_consult_vacancy)
        WHEN MATCHED THEN
            UPDATE
               SET s.dt_sch_consult_vacancy_tstz = t.dt_sch_consult_vacancy_tstz,
                   s.id_institution              = t.id_institution,
                   s.id_prof                     = t.id_prof,
                   s.dt_begin_tstz               = t.dt_begin_tstz,
                   s.dt_end_tstz                 = t.dt_end_tstz,
                   s.max_vacancies               = t.real_max_vac,
                   s.used_vacancies              = t.real_used_vac,
                   s.dt_begin_tstz               = t.dt_begin_tstz,
                   s.dt_end_tstz                 = t.dt_end_tstz,
                   s.id_dep_clin_serv            = t.id_dep_clin_serv,
                   s.id_room                     = t.id_room,
                   s.id_sch_event                = t.id_sch_event
        WHEN NOT MATCHED THEN
            INSERT
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
                (t.id_sch_consult_vacancy,
                 t.dt_sch_consult_vacancy_tstz,
                 t.id_institution,
                 t.id_prof,
                 t.dt_begin_tstz,
                 t.real_max_vac,
                 t.real_used_vac,
                 t.dt_end_tstz,
                 t.id_dep_clin_serv,
                 t.id_room,
                 t.id_sch_event,
                 pk_schedule_bo.g_status_active);
    
        COMMIT;
    
        pk_alertlog.log_info(text        => 'Creating random schedules for institution [' || i_id_inst || ']',
                             object_name => g_package_name,
                             owner       => g_package_owner);
        g_error := 'CALL RESET_RANDOM_SCHEDULES';
        -- Create random schedules
        IF NOT reset_random_schedules(i_lang           => i_lang,
                                      i_initial_date   => pk_date_utils.add_days_to_tstz(l_trunc_curr_ts, -90),
                                      i_end_date       => pk_date_utils.add_days_to_tstz(l_trunc_curr_ts, 120),
                                      i_id_institution => i_id_inst,
                                      i_id_software    => i_id_software,
                                      o_error          => o_error)
        THEN
            -- Unexpected error
            RAISE l_func_exception;
        END IF;
    
        g_error := 'UPDATE schedule UPDATE EVENT';
        -- Update generic event
        UPDATE schedule s
           SET s.id_sch_event = 2
         WHERE s.id_sch_event = 6
           AND s.id_instit_requested = i_id_inst;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
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
        
    END reset;

    /*
    * Sets the permission flag for several tuples of event-target professional-dcs, for a given professional.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Logged professional.
    * @param i_flg_permission      Permission flag ('S' schedule, 'R' read)
    * @param i_to_prof             Professional whose permissions are being altered.
    * @param i_on_profs            Target professionals list.
    * @param i_events              Events list.
    * @param i_on_dep_clin_servs   Department-Clinical service associations list
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/07/10
    */
    FUNCTION set_permission
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_permission    IN sch_permission.flg_permission%TYPE,
        i_to_prof           IN sch_permission.id_prof_agenda%TYPE,
        i_on_profs          IN table_number,
        i_events            IN table_number,
        i_on_dep_clin_servs IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_PERMISSION';
        l_func_exception EXCEPTION;
        l_sch_permission_rec sch_permission%ROWTYPE;
        l_sch_event          sch_event%ROWTYPE;
        l_found              BOOLEAN;
        l_list_dcs           table_number := i_on_dep_clin_servs;
        l_list_profs         table_number := i_on_profs;
    
        -- Returns the event
        FUNCTION inner_get_event
        (
            i_idx   IN NUMBER,
            o_found OUT BOOLEAN
        ) RETURN sch_event%ROWTYPE IS
            l_ret_sch_event sch_event%ROWTYPE := NULL;
        BEGIN
            g_error := 'INNER_GET_EVENT';
            BEGIN
                SELECT se.*
                  INTO l_ret_sch_event
                  FROM sch_event se
                 WHERE se.id_sch_event = i_events(i_idx);
                o_found := TRUE;
            EXCEPTION
                WHEN no_data_found THEN
                    o_found := FALSE;
            END;
        END inner_get_event;
    
        -- Returns a permission record if it exists
        FUNCTION inner_get_permission
        (
            i_idx   IN NUMBER,
            o_found OUT BOOLEAN
        ) RETURN sch_permission%ROWTYPE IS
            l_ret_sch_permission_rec sch_permission%ROWTYPE := NULL;
        BEGIN
            g_error := 'INNER_GET_PERMISSION';
            BEGIN
                SELECT sp.*
                  INTO l_ret_sch_permission_rec
                  FROM sch_permission sp
                 WHERE sp.id_institution = i_prof.institution
                   AND sp.id_professional = i_to_prof
                   AND ((l_list_profs(i_idx) IS NULL AND sp.id_prof_agenda IS NULL) OR
                       sp.id_prof_agenda = l_list_profs(i_idx))
                   AND ((l_list_dcs(i_idx) IS NULL AND sp.id_dep_clin_serv IS NULL) OR
                       sp.id_dep_clin_serv = l_list_dcs(i_idx))
                   AND sp.id_sch_event = i_events(i_idx);
                o_found := TRUE;
            EXCEPTION
                WHEN no_data_found THEN
                    o_found := FALSE;
            END;
            RETURN l_ret_sch_permission_rec;
        END inner_get_permission;
    BEGIN
        g_error := 'CHECK COLLECTIONS LENGTH';
        -- Check if all collections share the same length
        IF i_on_profs.count <> i_events.count
           OR i_events.count <> i_on_dep_clin_servs.count
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Not all collections have the same length',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        END IF;
    
        g_error := 'ITERATE THROUGH EVENTS';
        -- Iterate through the list of events (the only list that is guaranteed to have non-null values
        FOR idx IN i_events.first .. i_events.last
        LOOP
            g_error := 'CALL INNER_GET_EVENT';
            -- Get the event
            l_sch_event := inner_get_event(i_idx => idx, o_found => l_found);
        
            g_error := 'CHECK EVENT';
            -- Issue an error if no event was found
            IF NOT l_found
            THEN
                pk_utils.undo_changes;
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => 'No event found',
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
                RETURN FALSE;
            END IF;
        
            g_error := 'FIX ARGUMENTS';
            -- Fix arguments, in accordance to the event's flags
            IF l_sch_event.flg_target_professional = g_no
            THEN
                l_list_profs(idx) := NULL;
            END IF;
            IF l_sch_event.flg_target_dep_clin_serv = g_no
            THEN
                l_list_dcs(idx) := NULL;
            END IF;
        
            -- Get the permission
            l_sch_permission_rec := inner_get_permission(i_idx => idx, o_found => l_found);
        
            IF l_found
            THEN
                g_error := 'CALL ALTER_SCH_PERMISSION';
                -- A permission was found, so we are going to alter it
                IF NOT pk_schedule_common.alter_sch_permission(i_lang                  => i_lang,
                                                               i_id_consult_permission => l_sch_permission_rec.id_consult_permission,
                                                               i_flg_permission        => i_flg_permission,
                                                               o_sch_permission_rec    => l_sch_permission_rec,
                                                               o_error                 => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            ELSE
                g_error := 'CALL NEW_SCH_PERMISSION';
                -- No permission was found, we need to create one
                IF NOT pk_schedule_common.new_sch_permission(i_lang               => i_lang,
                                                             i_id_institution     => i_prof.institution,
                                                             i_id_professional    => i_to_prof,
                                                             i_id_prof_agenda     => l_list_profs(idx),
                                                             i_id_dep_clin_serv   => l_list_dcs(idx),
                                                             i_id_sch_event       => i_events(idx),
                                                             i_flg_permission     => i_flg_permission,
                                                             o_sch_permission_rec => l_sch_permission_rec,
                                                             o_error              => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
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
        
    END set_permission;

    /**
    * Returns the clinical service identifier.
    *
    * @param   i_id_dcs         dep_clin_serv identifier
    *
    * @return  Returns associated clinical service identifier
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/24
    */
    FUNCTION get_id_clin_serv(i_id_dcs IN dep_clin_serv.id_dep_clin_serv%TYPE)
        RETURN clinical_service.id_clinical_service%TYPE IS
        l_id_clinical_service clinical_service.id_clinical_service%TYPE;
    BEGIN
        SELECT dcs.id_clinical_service
          INTO l_id_clinical_service
          FROM dep_clin_serv dcs
         WHERE dcs.id_dep_clin_serv = i_id_dcs;
    
        RETURN l_id_clinical_service;
    EXCEPTION
        WHEN OTHERS THEN
            -- Let the caller handle the error.
            RAISE;
    END get_id_clin_serv;

    /*
    * Returns data for the multiple search cross-view.
    *
    * @param i_lang   Language identifier.
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since
    *
    * UPDATED 
    * ALERT-28024 - media das vacancies passou a ser a sch_tmptab_full_vacs em vez da table_number
    * @author   Telmo
    * @date     18-06-2009
    * @version  2.5.0.4
    *
    * UPDATED 
    * AdaptaÁ„o para multidisciplinares
    * @author   Sofia Mendes
    * @date     18-07-2009
    * @version  2.5.0.5
    *
    * UPDATED alert-8202
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    20-10-2009
    */
    FUNCTION get_availability_cross_mult
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_table_varchar,
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
                                                    i_timestamp_1 => i_args(1) (idx_dt_end),
                                                    i_timestamp_2 => i_args(1) (idx_dt_begin),
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
    
        -- clean workbench
        g_error := 'TRUNCATE TABLE SCH_TMPTAB_FULL_VACS';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_FULL_VACS';
    
        g_error := 'CALL GET_VAC_AND_SCH_MULT';
        -- Get vacancies and schedules that match the each of the criteria sets, on the
        -- dates that match all the criteria sets.
        IF NOT pk_schedule_common.get_vac_and_sch_mult(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_args       => i_args,
                                                       i_id_patient => NULL,
                                                       o_schedules  => l_schedules,
                                                       o_error      => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_AVAILABLE_VACANCIES';
        -- Get available vacancies only (the ones that not clash with any absence period).
        IF NOT get_available_vacancies(i_lang      => i_lang,
                                       i_prof      => i_prof,
                                       i_vacancies => NULL,
                                       i_fulltable => g_yes,
                                       o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_vacants FOR';
        -- Open cursor containing vacancies' information
        OPEN o_vacants FOR
            SELECT /*+ first_rows */
             id_sch_consult_vacancy,
             pk_date_utils.date_send_tsz(i_lang, dt_begin, i_prof) dt_begin,
             desc_dcs,
             id_dcs,
             to_char(id_sch_event) id_sch_event,
             desc_event,
             id_prof,
             desc_prof,
             SUM(num_vacancies) num_vacancies,
             desc_sch_type
              FROM (SELECT scv.id_sch_consult_vacancy,
                           pk_date_utils.trunc_insttimezone(i_prof, scv.dt_begin_tstz, l_time_grain) dt_begin,
                           scv.id_dep_clin_serv id_dcs,
                           scv.id_sch_event id_sch_event,
                           string_sch_event(i_lang, scv.id_sch_event) desc_event,
                           scv.id_prof id_prof,
                           string_clin_serv_by_dcs(i_lang, scv.id_dep_clin_serv) desc_dcs,
                           decode(scv.id_prof, NULL, NULL, pk_prof_utils.get_name_signature(i_lang, i_prof, scv.id_prof)) desc_prof,
                           scv.max_vacancies - scv.used_vacancies num_vacancies,
                           string_sch_type(i_lang, se.dep_type) desc_sch_type
                      FROM sch_consult_vacancy scv, sch_tmptab_full_vacs fv, sch_event se
                     WHERE scv.id_sch_consult_vacancy = fv.id_sch_consult_vacancy
                       AND scv.id_sch_event = se.id_sch_event)
             GROUP BY id_sch_consult_vacancy,
                      dt_begin,
                      desc_dcs,
                      id_dcs,
                      id_sch_event,
                      desc_event,
                      id_prof,
                      desc_prof,
                      desc_sch_type
             ORDER BY id_sch_event, dt_begin;
    
        g_error := 'OPEN o_schedules FOR';
        -- Open cursor containing schedules' information
        OPEN o_schedules FOR
            SELECT /*+ first_rows */
             s.id_schedule,
             CASE
                  WHEN s.id_sch_consult_vacancy IS NOT NULL THEN
                   s.id_sch_consult_vacancy
                  ELSE
                   sr.id_sch_consult_vacancy
              END AS id_sch_consult_vacancy,
             pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof) dt_begin,
             string_clin_serv_by_dcs(i_lang, s.id_dcs_requested) desc_dcs,
             sr.id_professional id_prof,
             pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional) desc_prof,
             s.id_dcs_requested,
             to_char(s.id_sch_event) id_sch_event,
             string_sch_event(i_lang, s.id_sch_event) desc_event,
             string_sch_type(i_lang, se.dep_type) desc_sch_type
              FROM schedule s, sch_event se, sch_resource sr
             WHERE s.id_schedule = sr.id_schedule(+)
               AND s.id_sch_event = se.id_sch_event
               AND s.id_schedule IN (SELECT *
                                       FROM TABLE(l_schedules))
             ORDER BY id_sch_event, s.dt_begin_tstz;
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_on;
            -- Unexpected error
            pk_types.open_my_cursor(o_vacants);
            pk_types.open_my_cursor(o_schedules);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_availability_cross_mult;

    /*
    * Performs the core validation for creating appointments using the
    * multi-search screens.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                UI search criteria.
    * @param i_sch_args            Appointment criteria.
    * @param i_flg_sch_type        Schedule type
    * @param o_dt_begin            Appointment's start date
    * @param o_dt_end              Appointment's end date
    * @param o_flg_proceed         Whether or not should the screen perform additional processing after this execution
    * @param o_flg_show            Whether or not should a semantic error message be shown to the used
    * @param o_msg                 Semantic error message to show (if invalid parameters were given or an invalid action was attempted)
    * @param o_msg_title           Semantic error title message
    * @param o_button              Buttons to show
    * @param o_flg_vacancy         Vacancy flag
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/07/23
    *
    * Adapted to MFR scheduler
    * @author   Telmo
    * @version  2.4.3.x
    * @date     13-01-2009    
    */
    FUNCTION validate_schedule_mult
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_args         IN table_varchar,
        i_sch_args     IN table_varchar,
        i_flg_sch_type IN VARCHAR2,
        o_dt_begin     OUT VARCHAR2,
        o_dt_end       OUT VARCHAR2,
        o_flg_proceed  OUT VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_flg_vacancy  OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'VALIDATE_SCHEDULE_MULT';
    
        l_unplanned      NUMBER;
        l_replacements   table_varchar;
        l_tokens         table_varchar;
        l_message        VARCHAR2(4000);
        l_event_name     VARCHAR2(4000);
        l_patient_name   VARCHAR2(4000);
        l_clin_serv_name VARCHAR2(4000);
        l_desc_date      VARCHAR2(4000);
        l_message_key    VARCHAR2(4000);
    
        l_id_exam     VARCHAR2(4000) := NULL;
        l_id_analysis VARCHAR2(4000) := NULL;
        l_id_physarea VARCHAR2(4000) := NULL;
    
        l_dt_begin TIMESTAMP WITH TIME ZONE;
    BEGIN
        o_flg_proceed := g_no;
        o_flg_show    := g_no;
    
        g_error := 'GET EXAM AND ANALYSIS IDENTIFIERS';
        -- Get exam and analysis identifiers
        IF i_flg_sch_type IN
           (pk_schedule_common.g_sch_dept_flg_dep_type_exam, pk_schedule_common.g_sch_dept_flg_dep_type_oexams)
        THEN
            l_id_exam := i_sch_args(idx_sch_args_exam);
        ELSIF i_flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_anls
        THEN
            l_id_analysis := i_sch_args(idx_sch_args_analysis);
        ELSIF i_flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
        THEN
            l_id_physarea := i_sch_args(idx_id_phys_area);
        END IF;
    
        g_error := 'VALIDATE ARGUMENTS';
        -- Validate arguments against dragged appointment
        IF i_sch_args(idx_sch_args_dcs) = i_args(idx_id_dep_clin_serv)
           AND i_sch_args(idx_sch_args_event) = i_args(idx_event)
           AND i_sch_args(idx_sch_args_prof) = i_args(idx_id_prof)
        THEN
            -- Everything is OK!
            o_flg_proceed := g_yes;
        ELSIF i_sch_args(idx_sch_args_dcs) != i_args(idx_id_dep_clin_serv)
        THEN
            g_error := 'GENERATE BAD DCS MESSAGE';
            -- The selected slot has a different DCS associated
            o_flg_proceed := g_no;
            o_flg_show    := g_yes;
            -- Generate message
            o_msg_title := get_message(i_lang, g_sched_msg_ack_title);
            o_msg       := get_message(i_lang, g_sched_msg_sched_mult_bad_dcs);
            o_button    := g_ok_button_code || get_message(i_lang, g_msg_ack) || '|';
            RETURN TRUE;
        ELSIF i_sch_args(idx_sch_args_event) != i_args(idx_event)
        THEN
            g_error := 'GENERATE BAD EVENT MESSAGE';
            -- The selected slot has a different event associated
            o_flg_proceed := g_no;
            o_flg_show    := g_yes;
            -- Generate message
            o_msg_title := get_message(i_lang, g_sched_msg_ack_title);
            o_msg       := get_message(i_lang, g_sched_msg_sched_mult_bad_evt);
            o_button    := g_ok_button_code || get_message(i_lang, g_msg_ack) || '|';
            RETURN TRUE;
        ELSIF i_sch_args(idx_sch_args_prof) != i_args(idx_id_prof)
        THEN
            g_error := 'GENERATE BAD PROF MESSAGE';
            -- The selected slot has a different professional associated
            o_flg_proceed := g_no;
            o_flg_show    := g_yes;
            -- Generate message
            o_msg_title := get_message(i_lang, g_sched_msg_ack_title);
            o_msg       := get_message(i_lang, g_sched_msg_sched_mult_bad_prf);
            o_button    := g_ok_button_code || get_message(i_lang, g_msg_ack) || '|';
            RETURN TRUE;
        END IF;
    
        g_error := 'CALL GET_FIRST_VALID_VACANCY';
        -- Get the first valid vacancy for the appointment being created
        IF NOT get_first_valid_vacancy(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_search_date_begin => i_args(idx_dt_begin),
                                       i_search_date_end   => i_args(idx_dt_end),
                                       i_dt_begin          => NULL,
                                       i_flg_sch_type      => i_flg_sch_type,
                                       i_sch_event         => i_sch_args(idx_sch_args_event),
                                       i_id_dep_clin_serv  => i_sch_args(idx_sch_args_dcs),
                                       i_id_prof           => i_sch_args(idx_sch_args_prof),
                                       i_id_physarea       => l_id_physarea,
                                       o_hour_begin        => o_dt_begin,
                                       o_hour_end          => o_dt_end,
                                       o_unplanned         => l_unplanned,
                                       o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert found date to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => o_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET APPOINTMENT INFO';
        -- Get appointment information.
        -- No error handling is performed on purpose.
        SELECT pat.name name,
               string_sch_event(i_lang, i_sch_args(idx_sch_args_event)) event_name,
               decode(o_dt_begin, NULL, NULL, string_date_hm(i_lang, i_prof, l_dt_begin)) desc_date,
               string_dep_clin_serv(i_lang, i_sch_args(idx_sch_args_dcs)) clin_serv
          INTO l_patient_name, l_event_name, l_desc_date, l_clin_serv_name
          FROM patient pat
         WHERE pat.id_patient = to_number(i_sch_args(idx_sch_args_patient));
    
        g_error := 'GET MESSAGE PARAMETERS';
        IF o_dt_begin IS NULL
        THEN
            -- No vacancy was found for the selected period
        
            -- Set UI processing
            o_flg_proceed := g_no;
            o_flg_show    := g_yes;
        
            -- Get message
            l_replacements := table_varchar(l_event_name, l_patient_name, l_clin_serv_name);
            l_tokens       := table_varchar('@1', '@2', '@3');
            l_message_key  := g_sched_mult_no_vacancy;
            o_button       := g_ok_button_code || get_message(i_lang, g_msg_ack) || '|';
            o_msg_title    := get_message(i_lang, g_sched_mult_msg_ack_title);
        ELSE
            -- A vacancy was found for the selected period
        
            -- Set UI processing
            o_flg_proceed := g_yes;
            o_flg_show    := g_yes;
        
            -- Set tokens and replacements
            l_replacements := table_varchar(l_event_name, l_patient_name, l_clin_serv_name, l_desc_date);
            l_tokens       := table_varchar('@1', '@2', '@3', '@4');
        
            -- Set message, title and buttons
            IF l_unplanned = 1
            THEN
                -- There are no slots available
                l_message_key := g_sched_mult_unplanned;
                o_button      := g_cancel_button_code || get_message(i_lang, g_cancel_button) || '|' ||
                                 g_ok_button_code || get_message(i_lang, g_sched_msg_ignore_proceed) || '|';
                o_msg_title   := get_message(i_lang, g_sched_msg_warning_title);
            ELSE
                -- At least one slot is available
                l_message_key := g_sched_mult_ok;
                o_button      := g_cancel_button_code || get_message(i_lang, g_common_no) || '|' || g_ok_button_code ||
                                 get_message(i_lang, g_common_yes) || '|';
                o_msg_title   := get_message(i_lang, g_resched_confirm);
            END IF;
        END IF;
    
        g_error := 'GET MESSAGE';
        -- Get message
        l_message := get_message(i_lang => i_lang, i_message => l_message_key);
    
        g_error := 'REPLACE TOKENS';
        -- Replace tokens
        IF NOT replace_tokens(i_lang         => i_lang,
                              i_string       => l_message,
                              i_tokens       => l_tokens,
                              i_replacements => l_replacements,
                              o_string       => o_msg,
                              o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET VACANCY FLAG';
        -- Get vacancy flag
        IF l_unplanned = 1
        THEN
            o_flg_vacancy := pk_schedule_common.g_sched_vacancy_unplanned;
        ELSE
            o_flg_vacancy := pk_schedule_common.g_sched_vacancy_routine;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END validate_schedule_mult;

    /**
    * Checks if a vacancy is available, taking into account the professional's absence periods
    *
    * @param   i_id_vacancy  Vacancy identifier
    *
    * @return  'Y' if the vacancy is available, 'N' otherwise
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/09/17
    */
    FUNCTION is_vacancy_available(i_id_vac IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'IS_VACANCY_AVAILABLE';
        l_available VARCHAR2(1) := NULL;
        l_dummy     NUMBER;
    BEGIN
        BEGIN
            SELECT 1
              INTO l_dummy
              FROM sch_consult_vacancy scv
             WHERE scv.id_prof IS NOT NULL
               AND scv.id_sch_consult_vacancy = i_id_vac
               AND scv.flg_status = pk_schedule_bo.g_status_blocked
               AND rownum = 1;
        
            -- At least one absence contains the vacancy's start or end date
            l_available := g_no;
        EXCEPTION
            WHEN no_data_found THEN
                l_available := g_yes;
        END;
    
        RETURN l_available;
    EXCEPTION
        WHEN OTHERS THEN
            -- Let the caller handle the error
            RAISE;
    END is_vacancy_available;

    /**
    * Checks if an appointment is on conflict, taking into account the professional's absence periods
    *
    * @param   i_id_sch  Schedule identifier
    *
    * @return  'Y' if the appointment is on conflict, 'N' otherwise
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/09/17
    */
    FUNCTION is_conflicting(i_id_sch IN schedule.id_schedule%TYPE) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'IS_CONFLICTING';
        l_conflict  VARCHAR2(1) := NULL;
        l_dummy     NUMBER;
    BEGIN
        BEGIN
            SELECT 1
              INTO l_dummy
              FROM schedule s, sch_resource sr, sch_absence sa
             WHERE s.id_instit_requested = sa.id_institution
               AND s.id_schedule = sr.id_schedule
               AND s.id_schedule = i_id_sch
               AND sr.id_professional IS NOT NULL
               AND sr.id_professional = sa.id_professional
               AND sa.flg_status = g_status_active
               AND (s.dt_begin_tstz BETWEEN sa.dt_begin_tstz AND sa.dt_end_tstz OR
                   s.dt_end_tstz BETWEEN sa.dt_begin_tstz AND sa.dt_end_tstz)
               AND rownum = 1;
        
            -- At least one absence contains the appointments's start or end date
            l_conflict := g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                l_conflict := g_no;
        END;
    
        RETURN l_conflict;
    EXCEPTION
        WHEN OTHERS THEN
            -- Let the caller handle the error
            RAISE;
    END is_conflicting;

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
               AND sa.flg_status = g_status_active
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
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_conflicting_appointments;

    /*
    * Gets the details of the appointments that are conflicting with some absence period.
    *
    * @param i_lang       Language identifier
    * @param i_prof       Professional
    * @param i_args       UI Search criteria
    * @param o_schedules  Appointments' details
    * @param o_error      Error message, if an error ocurred
    *
    * @return True if successful, false otherwise.
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/09/18
    *
    * UPDATED
    * ALERT-708 - pesquisa por vagas livres.
    * @author   Telmo Castro
    * @date     25-03-2009
    * @version  2.5
    */
    FUNCTION get_conflicts_to_clipboard
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_CONFLICTS_TO_CLIPBOARD';
        l_list_schedules table_number;
    BEGIN
    
        g_error := 'CALL GET_SCHEDULES';
        -- Get the appointments that match the given criteria.
        IF get_only_vacs(i_args(idx_status)) = g_yes
        THEN
            l_list_schedules := table_number();
        ELSE
            IF NOT pk_schedule_common.get_schedules(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_patient => NULL,
                                                    i_args       => i_args,
                                                    o_schedules  => l_list_schedules,
                                                    o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL GET_CONFLICTING_APPOINTMENTS';
        -- Get the appointments that are conflicting with some absence period
        IF NOT get_conflicting_appointments(i_lang     => i_lang,
                                            i_prof     => i_prof,
                                            i_list_sch => l_list_schedules,
                                            o_list_sch => l_list_schedules,
                                            o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_APPOINTMENT_CLIPBOARD_DETAILS';
        -- Get appointments' details to put on the clipboard
        IF NOT get_appointments_clip_details(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_list_schedules => l_list_schedules,
                                             o_schedules      => o_schedules,
                                             o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_schedules);
        
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_conflicts_to_clipboard;

    /*
    * Configuration of vacancies in present institution and software, as given by table sch_vacancy_usage.
    * configuration comprises:
    * flg_use = (Y/N) Indicates whether or not should vacancies be consumed. That is, if a scheduleís creation should mark the vacancy as used
    * flg_sched_without_vac = (Y/N) Indicates if it is possible to create schedules without an associated vacancy. In this case the column
    *                         schedule.id_sch_consult_vacancy stays empty.
    * flg_edit_vac = (Y/N) Indicates that a scheduleís vacancy (if there is one) can be modified if that same schedule is altered.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_dept                  department id
    * @param i_dep_type                 scheduling type
    * @param o_flg_use                  see above
    * @param o_flg_sched_without_vac    see above
    * @param o_flg_edit_vac             see above
    * @param o_error                    Error message, if an error ocurred
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo castro
    * @version 2.4.3
    * @since   24-05-2008
    *
    * UPDATED
    * a query primaria tinha uma condicao rownum = 1 a mais
    * @author  Telmo Castro
    * @version 2.4.3.x
    * @since   02-10-2008
    *
    * UPDATED
    * faltava o dep_type para corretamente escolher a config mais aproximada
    * @author  Telmo Castro
    * @version 2.4.3.x
    * @since   16-10-2008
    */
    FUNCTION get_vacancy_config
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_dept               IN sch_department.id_department%TYPE,
        i_dep_type              IN sch_department.flg_dep_type%TYPE,
        i_id_institution        IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_use               OUT sch_vacancy_usage.flg_use%TYPE,
        o_flg_sched_without_vac OUT sch_vacancy_usage.flg_sched_without_vac%TYPE,
        o_flg_edit_vac          OUT sch_vacancy_usage.flg_edit_vac%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_VACANCY_CONFIG';
        l_id_institution institution.id_institution%TYPE := i_id_institution;
    BEGIN
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        g_error := 'GET SCH_VACANCY_USAGE DATA FOR SCH TYPE ' || nvl(i_dep_type, '?') || ' AND ID_DEP = ' ||
                   nvl(to_char(i_id_dept), '?');
        SELECT flg_use, flg_sched_without_vac, flg_edit_vac
          INTO o_flg_use, o_flg_sched_without_vac, o_flg_edit_vac
          FROM (SELECT svu.flg_use, svu.flg_sched_without_vac, svu.flg_edit_vac
                  FROM sch_vacancy_usage svu
                 INNER JOIN sch_department sd
                    ON svu.flg_sch_type = sd.flg_dep_type
                 WHERE (svu.id_institution = l_id_institution --i_prof.institution
                       OR svu.id_institution = 0)
                   AND (svu.id_software = i_prof.software OR svu.id_software = 0)
                   AND sd.id_department = i_id_dept
                   AND sd.flg_dep_type = i_dep_type
                 ORDER BY svu.id_institution DESC, svu.id_software DESC)
         WHERE rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_vacancy_config;

    /**********************************************************************************************
    *  Inactiva o episÛdio e a visita para o agendamento cancelado (EHR ACCESS)
    *
    * @param i_lang         the id language
    * @param i_prof         profissional
    * @param i_id_schedule  id do agendamento
    * @return               TRUE if sucess, FALSE otherwise
    *
    * @author               Teresa Coutinho
    * @version              1.0
    * @since                2008/05/24
    *
    * UPDATED
    * ALERT-13813. O update visit tinha 2 vezes o campo dt_end_tstz o que e' invalido (em runtime so')
    * @author               Telmo
    * @version              2.4.4
    * @date                 16-01-2009
    **********************************************************************************************/

    FUNCTION cancel_sch_epis_ehr
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        i_sysdate      IN DATE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCH_EPIS_EHR';
        l_epis_sch  episode%ROWTYPE;
        l_rowids    table_varchar;
    BEGIN
        g_error := l_func_name || ' - FETCH ID_EPISODE, ID_VISIT';
        SELECT e.id_episode, e.id_visit
          INTO l_epis_sch.id_episode, l_epis_sch.id_visit
          FROM episode e
          JOIN epis_info ei
            ON ei.id_episode = e.id_episode
         WHERE ei.id_schedule = i_id_schedule
           AND e.flg_status = g_episode_active
           AND e.flg_ehr = g_schedule_ehr
           AND rownum = 1;
    
        g_error := l_func_name || ' - CANCEL EPISODE AND VISIT';
        ts_episode.upd(id_episode_in  => l_epis_sch.id_episode,
                       flg_status_in  => g_episode_inactive,
                       dt_end_tstz_in => i_sysdate_tstz,
                       rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        ts_visit.upd(id_visit_in    => l_epis_sch.id_visit,
                     flg_status_in  => g_episode_inactive,
                     dt_end_tstz_in => i_sysdate_tstz,
                     rows_out       => l_rowids);
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            -- Unexpected error
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
        
    END cancel_sch_epis_ehr;

    /**
    * Checks schedule overlap with existing schedules.
    * Overlap checked against the professional and institution.
    *
    * @param   i_lang              Language
    * @param   i_id_prof              Professional id
    * @param   i_id_institution    institution id
    * @param   i_start_date        Schedule start date
    * @param   i_end_date          Schedule End date
    * @param   o_overlap           Overlap flag. Y - with overlap. N - no overlap
    * @param   o_error             Error message if an error occurred
    *
    * @return  boolean type        "False" on error or "True" if success
    * @author  LuÌs Gaspar
    * @version 0.1
    * @since   2008/05/27
    */
    FUNCTION get_schedule_overlap
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN sch_resource.id_professional%TYPE,
        i_id_institution IN sch_resource.id_institution%TYPE,
        i_start_date     IN schedule.dt_begin_tstz%TYPE,
        i_end_date       IN schedule.dt_end_tstz%TYPE,
        o_overlap        OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_SCHEDULE_OVERLAP';
        l_start_date    sch_consult_vacancy.dt_begin_tstz%TYPE;
        l_end_date      sch_consult_vacancy.dt_end_tstz%TYPE;
        l_overlap_count NUMBER;
    
        -- overlap check by professional and institution
    BEGIN
        g_error := 'count overlaps';
        SELECT COUNT(1)
          INTO l_overlap_count
          FROM schedule s
          JOIN sch_resource r
            ON r.id_schedule = s.id_schedule
           AND r.id_professional = i_id_prof
         WHERE s.id_instit_requested = i_id_institution
              -- overlap date conditions
           AND s.dt_end_tstz > l_start_date
           AND s.dt_begin_tstz < l_end_date;
    
        -- calculate overlap
        g_error := 'calculate overlap';
        IF (l_overlap_count > 0)
        THEN
            o_overlap := pk_schedule.g_yes;
        ELSE
            o_overlap := pk_schedule.g_no;
        END IF;
    
        -- Log overlap result
        pk_alertlog.log_debug(text        => l_func_name || ' : overlap result = ' || o_overlap,
                              object_name => g_package_name,
                              owner       => g_package_owner);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_schedule_overlap;

    /**
    * Checks vacancy overlap with existing vacancies.
    * Overlap checked against the professional and institution and free vacancies don't overlap.
    *
    * @param   i_lang              Language
    * @param   i_prof              Professional.
    * @param   i_start_date        Schedule start date
    * @param   i_end_date          Schedule End date
    * @param   o_overlap           Overlap flag. Y - with overlap. N - no overlap
    * @param   o_error             Error message if an error occurred
    *
    * @return  boolean type        "False" on error or "True" if success
    * @author  LuÌs Gaspar
    * @version 0.1
    * @since   2008/05/26
    */
    FUNCTION get_vac_overlap
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_start_date IN schedule.dt_begin_tstz%TYPE,
        i_end_date   IN schedule.dt_end_tstz%TYPE,
        o_overlap    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_OVERLAP';
        l_start_date    sch_consult_vacancy.dt_begin_tstz%TYPE;
        l_end_date      sch_consult_vacancy.dt_end_tstz%TYPE;
        l_overlap_count NUMBER;
    
    BEGIN
        g_error := 'count overlaps';
        -- overlap check by professional and institution
        SELECT COUNT(1)
          INTO l_overlap_count
          FROM sch_consult_vacancy s
         WHERE s.id_institution = i_prof.institution
           AND s.id_prof = i_prof.id
              -- overlap date conditions
           AND s.dt_end_tstz > l_start_date
           AND s.dt_begin_tstz < l_end_date
              -- free vacancies don't overlap
           AND s.max_vacancies >= s.used_vacancies
           AND s.flg_status = pk_schedule_bo.g_status_active;
    
        -- calculate overlap
        g_error := 'calculate overlap';
        IF (l_overlap_count > 0)
        THEN
            o_overlap := g_yes;
        ELSE
            o_overlap := g_no;
        END IF;
    
        -- Log overlap result
        pk_alertlog.log_debug(text        => l_func_name || ' : overlap result = ' || o_overlap,
                              object_name => g_package_name,
                              owner       => g_package_owner);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_vac_overlap;

    /**
    * Returns a list of schedule reasons, depending on sys_config configuration.
    *
    * @param      i_lang                 Language
    * @param      i_prof                 Professional
    * @param      i_id_dep_clin_serv     Department-clinical service
    * @param      i_id_patient           Patient
    * @param      i_episode              Episode ID
    * @param      i_flg_type             register type: E - edit, N - new
    * @param      i_flg_search           Whether or not should the 'All' option be returned in o_reasons cursor.
     * @param      o_reasons              Schedule reasons
    * @param      o_error                Error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Jose Antunes
    * @version    0.1
    * @since      2008/09/02
    */
    FUNCTION get_schedule_reasons
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN VARCHAR2,
        i_id_patient       IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_flg_type         IN VARCHAR2,
        i_flg_search       IN VARCHAR2,
        o_reasons          OUT pk_types.cursor_type,
        o_value_conf       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_SCHEDULE_REASONS';
        l_config      sys_config.id_sys_config%TYPE := 'SCH_COMPLAINT_ORIGIN';
        l_dummy_table table_number := table_number();
        l_dummy_id    NUMBER(24);
    BEGIN
    
        g_error := 'GET ' || l_config || ' FROM SYS_CONFIG';
        IF NOT (pk_sysconfig.get_config(l_config, i_prof, o_value_conf))
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Null or inexistent ' || l_config || ' on SYS_CONFIG',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        END IF;
    
        IF o_value_conf = g_reason
        THEN
            g_error := 'CALL GET_REASONS';
            RETURN get_reasons(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_dep_clin_serv => i_id_dep_clin_serv,
                               i_id_patient       => i_id_patient,
                               i_flg_search       => i_flg_search,
                               o_reasons          => o_reasons,
                               o_error            => o_error);
        
        ELSE
            g_error := 'CALL GET_REASON_COMPLAINT_EPIS';
        
            RETURN pk_complaint.get_reason_complaint_epis(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_episode    => i_episode,
                                                          i_flg_type   => i_flg_type,
                                                          o_complaints => o_reasons,
                                                          o_dcs_list   => l_dummy_table,
                                                          o_id_event   => l_dummy_id,
                                                          o_error      => o_error);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_schedule_reasons;

    /*
    * Gets a complaint's translated description
    * To be used inside SELECTs
    *
    * @param i_lang
    * @param i_id_complaint
    *
    * @author  Jose Antunes
    * @version 0.1
    * @since   2008/09/04
    */
    FUNCTION string_complaint
    (
        i_lang         IN language.id_language%TYPE,
        i_id_complaint IN schedule.id_reason%TYPE
    ) RETURN VARCHAR2 IS
        l_ret       pk_translation.t_desc_translation;
        l_func_name VARCHAR2(32) := 'STRING_COMPLAINT';
    BEGIN
        g_error := 'START';
        IF i_id_complaint IS NULL
        THEN
            l_ret := '';
        ELSE
            g_error := 'SELECT';
            BEGIN
                SELECT pk_translation.get_translation(i_lang, c.code_complaint)
                  INTO l_ret
                  FROM complaint c
                 WHERE c.id_complaint = i_id_complaint
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    -- Missing translation
                    l_ret := '';
                    pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ': ID_COMPLAINT = ' ||
                                                        i_id_complaint,
                                         object_name => g_package_name,
                                         owner       => g_package_owner);
            END;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_ret := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_ret;
        
    END string_complaint;

    /**
    * Returns a list of schedule reasons, depending on sys_config configuration.
    *
    * @param      i_lang                 Language
    * @param      i_prof                 Professional
    * @param      i_id_dep_clin_serv     Department-clinical service
    * @param      i_id_patient           Patient
    * @param      i_episode              Episode ID
    * @param      i_flg_type             register type: E - edit, N - new
    * @param      i_flg_search           Whether or not should the 'All' option be returned in o_reasons cursor.
    * @param      i_consult_req          id of consult requisition
    * @param      o_reasons              Schedule reasons
    * @param      o_error                Error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Elisabete Bugalho
    * @version    0.1
    * @since      2009/03/25
    */
    FUNCTION get_schedule_reasons
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN VARCHAR2,
        i_id_patient       IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_flg_type         IN VARCHAR2,
        i_flg_search       IN VARCHAR2,
        i_consult_req      IN consult_req.id_consult_req%TYPE,
        o_reasons          OUT pk_types.cursor_type,
        o_value_conf       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_SCHEDULE_REASONS';
        l_config      sys_config.id_sys_config%TYPE := 'SCH_COMPLAINT_ORIGIN';
        l_dummy_table table_number := table_number();
        l_dummy_id    NUMBER(24);
    
        l_gender      patient.gender%TYPE;
        l_age         NUMBER(3);
        l_id_dcs      table_number;
        l_reason      consult_req.reason_for_visit%TYPE;
        l_cat         prof_cat.id_category%TYPE;
        l_sample_text table_varchar;
    
        CURSOR c_cat IS
            SELECT id_category
              FROM prof_cat
             WHERE id_professional = i_prof.id
               AND id_institution = i_prof.institution;
    
        CURSOR c_sample_text IS
            SELECT pk_translation.get_translation(i_lang, st.code_title_sample_text) label
            --t.desc_translation label
              FROM sample_text_type stt, sample_text st, sample_text_soft_inst stsi --, translation t
             WHERE upper(stt.intern_name_sample_text_type) = upper(g_complaint_sample_text_type)
               AND stsi.id_software = i_prof.software
               AND stsi.id_institution = i_prof.institution
               AND stsi.id_sample_text_type = stt.id_sample_text_type
               AND st.flg_available = stt.flg_available
               AND st.flg_available = g_yes
               AND stsi.flg_available = g_yes
               AND stsi.id_sample_text = st.id_sample_text
               AND pk_translation.get_translation(i_lang, st.code_title_sample_text) IS NOT NULL
               AND ((l_age IS NULL AND l_gender IS NULL) OR
                    (l_age IS NOT NULL OR
                    l_gender IS NOT NULL AND
                    ((nvl(st.gender, pk_schedule.g_gender_undefined) IN (pk_schedule.g_gender_undefined, l_gender)) OR
                    l_gender = pk_schedule.g_gender_undefined) AND
                    (nvl(l_age, 0) BETWEEN nvl(st.age_min, 0) AND nvl(st.age_max, nvl(l_age, 0)) OR nvl(l_age, 0) = 0)))
            UNION
            SELECT DISTINCT pk_string_utils.clob_to_sqlvarchar2(desc_sample_text_prof) text
              FROM sample_text_type stt, sample_text_type_cat sttc, sample_text_prof stf
             WHERE upper(stt.intern_name_sample_text_type) = upper(g_complaint_sample_text_type)
               AND stf.id_software = i_prof.software
               AND sttc.id_sample_text_type = stt.id_sample_text_type
               AND sttc.id_category = l_cat
               AND sttc.id_institution IN (0, i_prof.institution)
               AND stf.id_sample_text_type = stt.id_sample_text_type
               AND stf.id_professional = i_prof.id
               AND stf.id_institution = i_prof.institution;
    BEGIN
    
        g_error := 'GET ' || l_config || ' FROM SYS_CONFIG';
        IF NOT (pk_sysconfig.get_config(l_config, i_prof, o_value_conf))
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Null or inexistent ' || l_config || ' on SYS_CONFIG',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        END IF;
    
        IF o_value_conf = g_reason
        THEN
            g_error := 'CALL GET_REASONS';
        
            IF i_consult_req IS NOT NULL
            THEN
                IF NOT pk_consult_req.get_consult_req_reason(i_lang           => i_lang,
                                                             i_id_consult_req => i_consult_req,
                                                             o_reason         => l_reason,
                                                             o_error          => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
                l_reason := pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang        => i_lang,
                                                                                                        i_prof        => i_prof,
                                                                                                        i_id_episode  => i_episode,
                                                                                                        i_id_schedule => NULL),
                                                             4000);
            END IF;
            BEGIN
                g_error := 'GET PATIENT AGE AND GENDER';
                -- Get patient age and gender
                SELECT gender, months_between(current_timestamp, dt_birth) / 12 age
                  INTO l_gender, l_age
                  FROM patient
                 WHERE id_patient = i_id_patient;
            EXCEPTION
                WHEN no_data_found THEN
                    l_age    := NULL;
                    l_gender := NULL;
            END;
            g_error := 'OPEN C_CAT';
            OPEN c_cat;
            FETCH c_cat
                INTO l_cat;
            CLOSE c_cat;
            g_error  := 'CREATE TABLE DCS';
            l_id_dcs := pk_schedule.get_list_number_csv(i_id_dep_clin_serv);
        
            OPEN c_sample_text;
            g_error := 'FETCH c_sample_text';
            FETCH c_sample_text BULK COLLECT
                INTO l_sample_text;
            g_error := 'CLOSE c_sample_text';
            CLOSE c_sample_text;
            g_error := 'SELECT';
            OPEN o_reasons FOR
                SELECT data, label, flg_select, order_field
                  FROM (SELECT g_all data,
                               pk_message.get_message(i_lang, g_msg_all) label,
                               g_no flg_select,
                               1 order_field
                          FROM dual
                         WHERE i_flg_search = g_yes
                        UNION
                        SELECT -1 data,
                               pk_message.get_message(i_lang, 'COMPLAINTDOCTOR_T012') label,
                               g_no flg_select,
                               2 order_field
                          FROM dual
                        UNION
                        SELECT st.id_sample_text data,
                               --t.desc_translation label,
                               pk_translation.get_translation(i_lang, st.code_title_sample_text) label,
                               --decode(t.desc_translation, l_reason, g_yes, g_no) flg_select,
                               decode(pk_translation.get_translation(i_lang, st.code_title_sample_text),
                                      l_reason,
                                      g_yes,
                                      g_no) flg_select,
                               9 order_field
                          FROM sample_text_type stt, sample_text st, sample_text_soft_inst stsi --, translation t
                         WHERE upper(stt.intern_name_sample_text_type) = upper(g_complaint_sample_text_type)
                           AND stsi.id_software = i_prof.software
                           AND stsi.id_institution = i_prof.institution
                           AND stsi.id_sample_text_type = stt.id_sample_text_type
                           AND st.flg_available = stt.flg_available
                           AND st.flg_available = g_yes
                           AND stsi.flg_available = g_yes
                           AND stsi.id_sample_text = st.id_sample_text
                           AND pk_translation.get_translation(i_lang, st.code_title_sample_text) IS NOT NULL
                           AND ((l_age IS NULL AND l_gender IS NULL) OR
                                (l_age IS NOT NULL OR
                                l_gender IS NOT NULL AND ((nvl(st.gender, pk_schedule.g_gender_undefined) IN
                                (pk_schedule.g_gender_undefined, l_gender)) OR
                                l_gender = pk_schedule.g_gender_undefined) AND
                                (nvl(l_age, 0) BETWEEN nvl(st.age_min, 0) AND nvl(st.age_max, nvl(l_age, 0)) OR
                                nvl(l_age, 0) = 0)))
                        UNION
                        SELECT DISTINCT stf.id_sample_text_prof,
                                        pk_string_utils.clob_to_sqlvarchar2(desc_sample_text_prof) text,
                                        decode(pk_string_utils.clob_to_sqlvarchar2(desc_sample_text_prof),
                                               l_reason,
                                               g_yes,
                                               g_no) flg_default,
                                        9 order_field
                          FROM sample_text_type stt, sample_text_type_cat sttc, sample_text_prof stf
                         WHERE upper(stt.intern_name_sample_text_type) = upper(g_complaint_sample_text_type)
                           AND stf.id_software = i_prof.software
                           AND sttc.id_sample_text_type = stt.id_sample_text_type
                           AND sttc.id_category = l_cat
                           AND sttc.id_institution IN (0, i_prof.institution)
                           AND stf.id_sample_text_type = stt.id_sample_text_type
                           AND stf.id_professional = i_prof.id
                           AND stf.id_institution = i_prof.institution
                        UNION
                        SELECT NULL, l_reason, g_yes, 9
                          FROM dual
                         WHERE l_reason IS NOT NULL
                           AND l_reason NOT IN (SELECT *
                                                  FROM TABLE(l_sample_text)))
                 ORDER BY order_field, label ASC;
            /*            RETURN get_reasons(i_lang             => i_lang,
            i_prof             => i_prof,
            i_id_dep_clin_serv => i_id_dep_clin_serv,
            i_id_patient       => i_id_patient,
            i_flg_search       => i_flg_search,
            i_consult_req      => i_consult_req,
            o_reasons          => o_reasons,
            o_error            => o_error);*/
        
        ELSE
            g_error := 'CALL GET_REASON_COMPLAINT_EPIS';
        
            RETURN pk_complaint.get_reason_complaint_epis(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_episode    => i_episode,
                                                          i_flg_type   => i_flg_type,
                                                          o_complaints => o_reasons,
                                                          o_dcs_list   => l_dummy_table,
                                                          o_id_event   => l_dummy_id,
                                                          o_error      => o_error);
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_reasons);
            RETURN FALSE;
        
    END get_schedule_reasons;

    /**
    * builds one of those messages to be displayed in the pre or post validation step, like
    * for example before create_schedules.
    *
    * @param i_lang           lang id
    * @param i_code_msg       code for base message
    * @param i_pkg_name       for warning purpose, its the package calling this function
    * @param i_replacements   values that will replace the tokens. Must be an ordered set, because these will be placed according to their index value
    * @param o_message        output
    * @param o_error          Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.5
    * @date    23-04-2009
    */
    FUNCTION get_validation_msgs
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg     IN sys_message.code_message%TYPE,
        i_pkg_name     IN VARCHAR2,
        i_replacements IN table_varchar,
        o_message      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_VALIDATION_MSGS';
        l_tokens    table_varchar;
        i           INTEGER;
    BEGIN
        IF TRIM(i_code_msg) IS NULL
        THEN
            RETURN TRUE;
        END IF;
        -- load base message from sys_message
        g_error   := 'GET SYS_MESSAGE ' || i_code_msg;
        o_message := pk_message.get_message(i_lang, i_code_msg);
        IF o_message IS NULL
        THEN
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ' ' || i_code_msg || ' : lang=' ||
                                                i_lang,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
        ELSE
            IF i_replacements IS NOT NULL
            THEN
                g_error  := 'REPLACE TOKENS';
                l_tokens := table_varchar();
                i        := i_replacements.first;
                WHILE i IS NOT NULL
                LOOP
                    l_tokens.extend;
                    l_tokens(l_tokens.last) := '@' || i;
                    i := i_replacements.next(i);
                END LOOP;
            
                IF NOT replace_tokens(i_lang         => i_lang,
                                      i_string       => o_message,
                                      i_tokens       => l_tokens,
                                      i_replacements => i_replacements,
                                      o_string       => o_message,
                                      o_error        => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        o_message := nvl(o_message, ' ');
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
            o_message := ' ';
            RETURN FALSE;
    END get_validation_msgs;

    /**
    * returns the repeatition_patterns (to be used on multichoice)
    *
    * @param i_lang     language id    
    * @param i_prof     Profissional identification
    * @param o_data     Cursor with the repeatition patterns   
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.4
    * @date    16-06-2009
    */
    FUNCTION get_repeatition_patterns
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_REPEATITION_PATTERNS';
    BEGIN
        g_error := 'OPEN O_DATA CURSOR';
        OPEN o_data FOR
            SELECT to_char('N') data,
                   pk_message.get_message(i_lang, g_msg_not_repeat) label,
                   g_yes flg_select,
                   1 order_field
              FROM dual
            UNION ALL
            SELECT to_char('D') data, pk_message.get_message(i_lang, g_msg_daily) label, g_no flg_select, 2 order_field
              FROM dual
            UNION ALL
            SELECT to_char('W') data,
                   pk_message.get_message(i_lang, g_msg_weekly) label,
                   g_no flg_select,
                   3 order_field
              FROM dual
            UNION ALL
            SELECT to_char('M') data,
                   pk_message.get_message(i_lang, g_msg_monthly) label,
                   g_no flg_select,
                   4 order_field
              FROM dual
            UNION ALL
            SELECT to_char('Y') data,
                   pk_message.get_message(i_lang, g_msg_yearly) label,
                   g_no flg_select,
                   5 order_field
              FROM dual;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_repeatition_patterns;

    /**
    * returns the monthly repeatition options (to be used on multichoice)
    *
    * @param i_lang     language id    
    * @param i_prof     Profissional identification
    * @param o_data     Cursor with the repeatition patterns   
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.4
    * @date    16-06-2009
    */
    FUNCTION get_repeat_by_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'get_monthly_repeatitions';
    BEGIN
        g_error := 'OPEN O_DATA CURSOR';
        OPEN o_data FOR
            SELECT to_char('W') data,
                   pk_message.get_message(i_lang, g_msg_day_week) label,
                   g_no flg_select,
                   1 order_field
              FROM dual
            UNION ALL
            SELECT to_char('M') data,
                   pk_message.get_message(i_lang, g_msg_day_month) label,
                   g_yes flg_select,
                   2 order_field
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_repeat_by_options;

    /**
    * returns the repeatition options to the on weeks montly option (to be used on multichoice)
    *
    * @param i_lang     language id    
    * @param i_prof     Profissional identification
    * @param o_data     Cursor with the repeatition patterns   
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.4
    * @date    16-06-2009
    */
    FUNCTION get_on_weeks_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_date  IN VARCHAR2,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ON_WEEKS_OPTIONS';
        l_date      TIMESTAMP WITH TIME ZONE;
        l_week      VARCHAR2(30);
    BEGIN
        IF (i_date IS NOT NULL)
        THEN
            g_error := 'CALL GET_STRING_TSTZ FOR i_date';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_date,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL TO_CHAR_INSTTIMEZZONE';
            IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_timestamp => l_date,
                                                      i_mask      => 'W',
                                                      o_string    => l_week,
                                                      o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            l_week := 1;
        END IF;
    
        g_error := 'OPEN O_DATA CURSOR';
        OPEN o_data FOR
            SELECT data,
                   label,
                   CASE
                        WHEN to_number(l_week) = to_number(data) THEN
                         g_yes
                        ELSE
                         g_no
                    END AS flg_select,
                   data AS order_field
              FROM (SELECT to_char(1) data, pk_message.get_message(i_lang, g_msg_day_st_week) label
                      FROM dual
                    UNION ALL
                    SELECT to_char(2) data, pk_message.get_message(i_lang, g_msg_day_nd_week) label
                      FROM dual
                    UNION ALL
                    SELECT to_char(3) data, pk_message.get_message(i_lang, g_msg_day_tr_week) label
                      FROM dual
                    UNION ALL
                    SELECT to_char(4) data, pk_message.get_message(i_lang, g_msg_day_ft_week) label
                      FROM dual
                    UNION ALL
                    SELECT to_char(5) data, pk_message.get_message(i_lang, g_msg_ls_week) label
                      FROM dual);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_on_weeks_options;

    /**
    * returns the the options to the 'end by' multichoice
    *
    * @param i_lang     language id    
    * @param i_prof     Profissional identification
    * @param o_data     Cursor with the repeatition patterns   
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.4
    * @date    16-06-2009
    */
    FUNCTION get_end_by_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'get_monthly_repeatitions';
    BEGIN
        g_error := 'OPEN O_DATA CURSOR';
        OPEN o_data FOR
            SELECT to_char('D') data, pk_message.get_message(i_lang, g_msg_date) label, g_no flg_select, 1 order_field
              FROM dual
            UNION ALL
            SELECT to_char('E') data,
                   pk_message.get_message(i_lang, g_msg_nr_events) label,
                   g_yes flg_select,
                   2 order_field
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_end_by_options;

    /**
    * returns the the options 'yes' and 'no' multichoice
    *
    * @param i_lang     language id    
    * @param i_prof     Profissional identification
    * @param o_data     Cursor with output data  
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.4
    * @date    16-06-2009
    */
    FUNCTION get_yes_no_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'get_monthly_repeatitions';
    BEGIN
        g_error := 'OPEN O_DATA CURSOR';
        OPEN o_data FOR
            SELECT g_yes data, pk_message.get_message(i_lang, g_msg_yes) label, g_no flg_select, 1 order_field
              FROM dual
            UNION ALL
            SELECT g_no data, pk_message.get_message(i_lang, g_msg_no) label, g_yes flg_select, 2 order_field
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_yes_no_options;

    /** crossview availability for a single visit request
    * 
    * @param i_lang         language id    
    * @param i_prof         Profissional id
    * @param i_startdate    if not null this is the date in which to look for availability. Otherwise uses sch_combi.dt_sch_after
    * @param i_id_combi     mandatory combination id needed for fetching data about the visit
    * @param i_id_patient   patient id
    * @param o_vacancies    all vacancies found for i_startdate that comply with one of the combi lines
    * @param o_schedules    all schedules found for i_startdate that comply with one of the combi lines
    * @param o_combos       cursor with columns id_combo | id_sch_consult_vacancy. id_combo is a sinthetic id uniting all vacancies that comply with the plan
    * @param o_error        error data
    *
    * returns       true / false
    *
    * @author   Telmo
    * @date     16-06-2009
    * @version  2.5.0.4
    *
    * UPDATED alert-8202. sch_consult_vac_exam demise
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    20-10-2009
    */
    FUNCTION get_availability_cross_sv
    (
        i_lang       IN language.id_language%TYPE DEFAULT NULL,
        i_prof       IN profissional,
        i_startdate  IN VARCHAR2,
        i_id_combi   IN sch_combi.id_sch_combi%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_vacancies  OUT pk_types.cursor_type,
        o_schedules  OUT pk_types.cursor_type,
        o_combos     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(50) := 'get_availability_cross_sv';
        l_rec_combi        sch_combi%ROWTYPE;
        l_args             table_varchar := table_varchar();
        l_startdate        VARCHAR2(20);
        l_enddate          VARCHAR2(20);
        l_date             TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_dep           dep_clin_serv.id_department%TYPE;
        l_schedules        table_number := table_number();
        l_union_schedules  table_number := table_number();
        l_foist            BOOLEAN := TRUE;
        l_mintimeafter     sch_combi_detail.min_time_after%TYPE;
        l_maxtimeafter     sch_combi_detail.max_time_after%TYPE;
        l_default_duration NUMBER;
    
        CURSOR l_combi_lines IS
            SELECT *
              FROM sch_combi_detail d
             WHERE d.id_sch_combi = i_id_combi
             ORDER BY nvl(d.id_code_parent, -1), id_code;
    
        l_rec_line l_combi_lines%ROWTYPE;
    
        l_rec_line_fv sch_tmptab_full_vacs%ROWTYPE;
    
        FUNCTION inner_get_profs
        (
            i_id_combi sch_combi_profs.id_sch_combi%TYPE,
            i_id_code  sch_combi_profs.id_code%TYPE
        ) RETURN VARCHAR2 IS
            l_out VARCHAR2(2000);
        BEGIN
            g_error := 'FETCH CSV OF PROFS';
            FOR l_cur IN (SELECT id_prof
                            FROM sch_combi_profs
                           WHERE id_sch_combi = i_id_combi
                             AND id_code = i_id_code)
            LOOP
                l_out := nvl(l_out, '') || CASE
                             WHEN l_out IS NULL THEN
                              ''
                             ELSE
                              ','
                         END || l_cur.id_prof;
            END LOOP;
            RETURN l_out;
        END inner_get_profs;
    
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        --fetch combi data and lines. If id_combi is null or nonexistent jumps out with error
        g_error := 'FETCH COMBI DATA';
        SELECT *
          INTO l_rec_combi
          FROM sch_combi
         WHERE id_sch_combi = i_id_combi;
    
        -- calc start date
        g_error     := 'CALC START DATE';
        l_startdate := nvl(i_startdate,
                           nvl(pk_date_utils.date_send_tsz(i_lang,
                                                           pk_date_utils.trunc_insttimezone(i_prof,
                                                                                            l_rec_combi.dt_sch_after),
                                                           i_prof),
                               pk_date_utils.date_send_tsz(i_lang,
                                                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp),
                                                           i_prof)));
    
        -- calc end date
        g_error := 'CALL GET_STRING_TSTZ FOR l_startdate';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => l_startdate,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            pk_types.open_my_cursor(o_vacancies);
            pk_types.open_my_cursor(o_schedules);
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        l_enddate := pk_date_utils.date_send_tsz(i_lang, pk_date_utils.add_days_to_tstz(l_date, 1), i_prof);
    
        -- get config for default_duration to be used when the vacancy doesnt have dt_end_tstz
        g_error            := 'GET DEFAULT_DURATION CONFIG';
        l_default_duration := nvl(pk_sysconfig.get_config(g_default_duration, i_prof), 30);
    
        -- clean workbench
        g_error := 'TRUNCATE TABLE SCH_TMPTAB_FULL_VACS';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_FULL_VACS';
    
        -- loop combi lines and pick vacancies and schedules for each one
        g_error := 'LOOP COMBI LINES';
        OPEN l_combi_lines;
        LOOP
            FETCH l_combi_lines
                INTO l_rec_line;
            EXIT WHEN l_combi_lines%NOTFOUND;
        
            --get department for this dcs
            SELECT id_department
              INTO l_id_dep
              FROM dep_clin_serv
             WHERE id_dep_clin_serv = l_rec_line.id_dep_clin_serv;
        
            -- get vacancies for this line
            g_error := 'GET VACANCIES FOR COMBI LINE';
            l_args  := table_varchar(l_startdate, --idx_dt_begin
                                     l_enddate, --idx_dt_end
                                     l_rec_combi.id_inst_target, --idx_id_inst
                                     l_id_dep, --idx_id_dep
                                     l_rec_line.id_dep_clin_serv, --idx_id_dep_clin_serv
                                     l_rec_line.id_sch_event, --idx_event
                                     inner_get_profs(l_rec_line.id_sch_combi, l_rec_line.id_code), --idx_id_prof
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     g_sched_status_scheduled || ',' || pk_schedule_common.g_onlyfreevacs,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL);
        
            -- esta get_vacancies so funciona para as agendas C, E, X, A, N, U. Nao funciona para as PM, S, IN
            IF NOT pk_schedule_common.get_vacancies(i_lang  => i_lang,
                                                    i_prof  => i_prof,
                                                    i_args  => l_args,
                                                    o_error => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            -- send to the common pool - FAZER UM MERGE NA sch_tmptab_full_vacs
            g_error := 'MERGE INTO sch_tmptab_full_vacs';
            MERGE INTO sch_tmptab_full_vacs g
            USING (SELECT stv.id_sch_consult_vacancy idscv,
                          stv.dt_begin_trunc         dbt,
                          stv.max_vacancies          mv,
                          stv.used_vacancies         uv,
                          scv.id_prof                idprof,
                          scv.id_sch_event           ideve,
                          scv.id_dep_clin_serv       iddcs,
                          scv.id_institution         idinst,
                          scv.dt_begin_tstz          dtbegin,
                          scv.dt_end_tstz            dtend,
                          l_rec_line.id_code         idcode
                     FROM sch_tmptab_vacs stv
                     JOIN sch_consult_vacancy scv
                       ON stv.id_sch_consult_vacancy = scv.id_sch_consult_vacancy) stv2
            ON (g.id_sch_consult_vacancy = stv2.idscv AND g.id_code = stv2.idcode)
            WHEN NOT MATCHED THEN
                INSERT
                    (id_sch_consult_vacancy,
                     dt_begin_trunc,
                     max_vacancies,
                     used_vacancies,
                     id_prof,
                     id_sch_event,
                     dt_begin_tstz,
                     dt_end_tstz,
                     id_dep_clin_serv,
                     id_institution,
                     id_code)
                VALUES
                    (stv2.idscv,
                     stv2.dbt,
                     stv2.mv,
                     stv2.uv,
                     stv2.idprof,
                     stv2.ideve,
                     stv2.dtbegin,
                     stv2.dtend,
                     stv2.iddcs,
                     stv2.idinst,
                     l_rec_line.id_code);
        
            -- Get the list of schedules that match the current criteria set
            g_error := 'GET SCHEDULES FOR COMBI LINE';
            /*            IF pk_schedule.get_only_vacs(l_args(idx_status)) = g_yes
                        THEN
                            l_schedules := table_number();
                        ELSE
            */
            IF NOT pk_schedule_common.get_schedules(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_patient => i_id_patient,
                                                    i_args       => l_args,
                                                    o_schedules  => l_schedules,
                                                    o_error      => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
            --            END IF;
            -- send to the common pool
            g_error           := 'MERGE SCHEDULES INTO POOL';
            l_union_schedules := l_union_schedules MULTISET UNION DISTINCT l_schedules;
        
        END LOOP;
        CLOSE l_combi_lines;
    
        -- clean workbench
        g_error := 'TRUNCATE TABLE SCH_TMPTAB_COMBOS';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_COMBOS';
    
        -- now we have all the necessary data. Lets do some mumbo jumbo with it,
        -- lets find all the combos and fill the o_combos. A combo is a sequence of vacancies that fulfill 
        -- the order and idle periods specified in the combination details
        OPEN l_combi_lines;
        LOOP
            FETCH l_combi_lines
                INTO l_rec_line;
            EXIT WHEN l_combi_lines%NOTFOUND;
        
            g_error := 'INSERT COMBO STARTERS';
            IF l_foist
            THEN
                INSERT INTO sch_tmptab_combos
                    (id_sch_consult_vacancy, id_code, id_combo, id_scv_parent)
                    SELECT fv.id_sch_consult_vacancy, fv.id_code, seq_sch_combos.nextval, -1
                      FROM sch_tmptab_full_vacs fv
                     WHERE fv.id_code = l_rec_line.id_code;
            
                l_foist := FALSE;
            ELSE
                -- INDEPENDENT APPOINTMENT
                g_error := 'INSERT INDEPENDENT COMBO STEP';
                IF l_rec_line.id_code_parent IS NULL
                THEN
                    INSERT INTO sch_tmptab_combos
                        (id_sch_consult_vacancy, id_code, id_combo, id_scv_parent)
                        SELECT DISTINCT fv.id_sch_consult_vacancy, l_rec_line.id_code, c.id_combo, -1
                          FROM sch_tmptab_full_vacs fv
                          JOIN (SELECT id_combo, v1.dt_begin_tstz, v1.dt_end_tstz
                                  FROM sch_tmptab_combos c1
                                  JOIN sch_consult_vacancy v1
                                    ON c1.id_sch_consult_vacancy = v1.id_sch_consult_vacancy) c
                            ON fv.id_sch_consult_vacancy <> -1
                         WHERE fv.id_code = l_rec_line.id_code
                           AND (fv.dt_end_tstz IS NULL OR
                               c.dt_begin_tstz NOT BETWEEN fv.dt_begin_tstz AND fv.dt_end_tstz)
                           AND (fv.dt_end_tstz IS NULL OR c.dt_end_tstz IS NULL OR
                               c.dt_end_tstz NOT BETWEEN fv.dt_begin_tstz AND fv.dt_end_tstz);
                
                ELSE
                    -- DEPENDENT APPOINTMENT
                    g_error := 'GET PARENT MIN TIME AFTER AND MAX TIME AFTER';
                    SELECT nvl(min_time_after, 0), nvl(max_time_after, 1440)
                      INTO l_mintimeafter, l_maxtimeafter
                      FROM sch_combi_detail f
                     WHERE f.id_sch_combi = l_rec_line.id_sch_combi
                       AND f.id_code = l_rec_line.id_code_parent;
                
                    g_error := 'INSERT DEPENDENT COMBO STEP';
                    INSERT INTO sch_tmptab_combos
                        (id_sch_consult_vacancy, id_code, id_combo, id_scv_parent)
                        SELECT DISTINCT fv2.id_sch_consult_vacancy,
                                        fv2.id_code,
                                        parents.id_combo,
                                        parents.id_sch_consult_vacancy vac_parent
                          FROM sch_tmptab_full_vacs fv2
                         CROSS JOIN (SELECT c.id_combo,
                                            c.id_sch_consult_vacancy,
                                            nvl(fv.dt_end_tstz,
                                                fv.dt_begin_tstz + numtodsinterval(l_default_duration, 'MINUTE')) dt_end_tstz
                                       FROM sch_tmptab_combos c
                                       JOIN sch_tmptab_full_vacs fv
                                         ON c.id_sch_consult_vacancy = fv.id_sch_consult_vacancy
                                        AND fv.id_code = c.id_code
                                      WHERE c.id_code = l_rec_line.id_code_parent) parents
                         WHERE fv2.id_code = l_rec_line.id_code
                           AND fv2.dt_begin_tstz BETWEEN
                               parents.dt_end_tstz + numtodsinterval(l_mintimeafter, 'MINUTE') AND
                               parents.dt_end_tstz + numtodsinterval(l_maxtimeafter, 'MINUTE');
                END IF;
            
                -- DELETE COMBOS THAT COULD NOT SUPPLY AT LEAST ONE VACANCY FOR THIS STEP (id_code)
                g_error := 'REMOVE INCOMPLETE COMBOS';
                DELETE sch_tmptab_combos
                 WHERE id_combo NOT IN (SELECT id_combo
                                          FROM sch_tmptab_combos c
                                         WHERE id_code = l_rec_line.id_code
                                         GROUP BY id_combo);
            
                -- DELETE broken COMBOS 
                g_error := 'REMOVE BROKEN COMBOS';
                DELETE sch_tmptab_combos c
                 WHERE c.id_code = l_rec_line.id_code_parent
                   AND NOT EXISTS (SELECT 1
                          FROM sch_tmptab_combos c2
                         WHERE c2.id_code = l_rec_line.id_code
                           AND c2.id_combo = c.id_combo
                           AND c2.id_scv_parent = c.id_sch_consult_vacancy);
            END IF;
        
        END LOOP;
        CLOSE l_combi_lines;
    
        -- pack combos
        g_error := 'OPEN o_combos';
        OPEN o_combos FOR
            SELECT *
              FROM sch_tmptab_combos
             ORDER BY id_sch_consult_vacancy;
    
        -- pack them vacancies
        g_error := 'OPEN o_vacancies';
        OPEN o_vacancies FOR
            SELECT id_sch_consult_vacancy,
                   pk_date_utils.date_send_tsz(i_lang, dt_begin, i_prof) dt_begin,
                   id_prof,
                   desc_prof,
                   nvl(SUM(max_vacancies - used_vacancies), 0) num_vacancies,
                   id_sch_event,
                   id_dcs,
                   id_dep,
                   desc_dcs,
                   desc_event,
                   desc_sch_type
              FROM (SELECT stv.id_sch_consult_vacancy,
                           pk_date_utils.trunc_insttimezone(i_prof, stv.dt_begin_tstz, 'MI') dt_begin,
                           stv.id_prof,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, stv.id_prof) desc_prof,
                           string_clin_serv_by_dcs(i_lang, stv.id_dep_clin_serv) desc_dcs,
                           string_sch_event(i_lang, stv.id_sch_event) desc_event,
                           stv.max_vacancies,
                           stv.used_vacancies,
                           stv.id_sch_event,
                           stv.id_dep_clin_serv id_dcs,
                           (SELECT id_department
                              FROM dep_clin_serv
                             WHERE id_dep_clin_serv = stv.id_dep_clin_serv) id_dep,
                           string_sch_type(i_lang, se.dep_type) desc_sch_type
                      FROM sch_tmptab_full_vacs stv, sch_event se
                     WHERE stv.id_sch_event = se.id_sch_event)
             GROUP BY id_sch_consult_vacancy,
                      dt_begin,
                      id_prof,
                      desc_prof,
                      id_sch_event,
                      id_dcs,
                      id_dep,
                      desc_dcs,
                      desc_event,
                      desc_sch_type
             ORDER BY dt_begin, id_prof;
    
        --pack them schedules
        g_error := 'OPEN o_schedules';
        OPEN o_schedules FOR
            SELECT pk_date_utils.date_send_tsz(i_lang,
                                               pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz, 'MI'),
                                               i_prof) dt_begin,
                   sr.id_professional id_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional) desc_prof,
                   s.id_sch_event,
                   dcs.id_dep_clin_serv id_dcs_requested,
                   dcs.id_department id_dep,
                   string_sch_type(i_lang, s.flg_sch_type) desc_sch_type,
                   string_sch_event(i_lang, s.id_sch_event) desc_event,
                   string_clin_serv_by_dcs(i_lang, dcs.id_dep_clin_serv) desc_dcs
              FROM schedule s, sch_resource sr, dep_clin_serv dcs
             WHERE sr.id_schedule(+) = s.id_schedule
               AND s.id_dcs_requested = dcs.id_dep_clin_serv
               AND s.id_schedule IN (SELECT *
                                       FROM TABLE(l_union_schedules))
             ORDER BY dt_begin_tstz, id_prof;
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_vacancies);
            pk_types.open_my_cursor(o_schedules);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_availability_cross_sv;

    /**********************************************************************************************
    * Schedule for Multidisciplinary Appointments
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param .....
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5.0.4
    * @since                                 2009/06/19
    **********************************************************************************************/
    FUNCTION create_schedule_multidisc
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_patient              IN table_number,
        i_id_dep_clin_serv_list   IN table_number,
        i_id_sch_event            IN schedule.id_sch_event%TYPE,
        i_id_prof_list            IN table_number,
        i_dt_begin                IN VARCHAR2,
        i_dt_end                  IN VARCHAR2,
        i_flg_vacancy             IN schedule.flg_vacancy%TYPE,
        i_schedule_notes          IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator      IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred       IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason               IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin               IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_schedule_ref         IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_room                 IN schedule.id_room%TYPE DEFAULT NULL,
        i_flg_sch_type            IN schedule.flg_sch_type%TYPE DEFAULT 'C',
        i_id_exam                 IN exam.id_exam%TYPE DEFAULT NULL,
        i_id_analysis             IN analysis.id_analysis%TYPE DEFAULT NULL,
        i_reason_notes            IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type        IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via        IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_show_vacancy_warn       IN BOOLEAN DEFAULT TRUE,
        i_do_overlap              IN VARCHAR2,
        i_id_consult_vac_list     IN table_number,
        i_sch_option              IN VARCHAR2,
        i_id_episode              IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_complaint            IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_flg_present             IN schedule.flg_present%TYPE DEFAULT NULL,
        i_id_prof_leader          IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        i_id_dep_clin_serv_leader IN schedule.id_dcs_requested%TYPE,
        i_id_multidisc            IN schedule.id_multidisc%TYPE DEFAULT NULL,
        i_id_sch_combi_detail     IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        i_id_institution          IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule             OUT schedule.id_schedule%TYPE,
        o_flg_proceed             OUT VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg                     OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(30) := 'CREATE_SCHEDULE_MULTIDISC';
        l_id_inst              department.id_institution%TYPE;
        l_flg_status           schedule.flg_status%TYPE;
        l_schedule_rec         schedule%ROWTYPE;
        l_sch_group_rec        sch_group%ROWTYPE;
        l_sch_resource_rec     sch_resource%ROWTYPE;
        l_id_sch_event         sch_event.id_sch_event%TYPE;
        l_schedule_interface   BOOLEAN;
        l_notification_default sch_dcs_notification.notification_default%TYPE;
        l_occupied             sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_dt_begin             TIMESTAMP WITH TIME ZONE;
        l_dt_end               TIMESTAMP WITH TIME ZONE;
    
        l_vacancy_usage BOOLEAN;
        l_sched_w_vac   BOOLEAN;
        l_edit_vac      BOOLEAN;
        l_vacancy_needed EXCEPTION;
        l_invalid_option EXCEPTION;
        l_unexvacfound   EXCEPTION;
        l_overlapfound   EXCEPTION;
        l_no_vac_usage   EXCEPTION;
        l_overlap      VARCHAR2(1);
        l_vac          sch_consult_vacancy%ROWTYPE;
        l_ignore_vac   BOOLEAN;
        l_flg_sch_type sch_event.dep_type%TYPE := i_flg_sch_type;
        l_id_dept      dep_clin_serv.id_department%TYPE;
        l_func_exception EXCEPTION;
    
        l_idx              NUMBER;
        l_flg_permission   BOOLEAN;
        l_id_dep_clin_serv table_number := table_number();
    
        l_id_institution institution.id_institution%TYPE := i_id_institution;
    BEGIN
        o_flg_show    := g_no;
        o_flg_proceed := g_no;
        l_ignore_vac  := TRUE;
    
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        -- Get the event that is actually associated with the vacancies.
        -- It can be a generic event (if the instution has one) or
        -- the event itself.
        g_error := 'get generic event';
        IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                    i_id_institution => l_id_institution, -- i_prof.institution,
                                                    i_id_event       => i_id_sch_event,
                                                    o_id_event       => l_id_sch_event,
                                                    o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- check for permission to schedule for this dep_clin_serv, event and professional
        g_error          := 'CHECK PERMISSION TO SCHEDULE';
        l_flg_permission := TRUE;
        IF i_id_prof_list.count > 0
        THEN
            l_idx            := 1;
            l_flg_permission := TRUE;
            WHILE l_idx <= i_id_prof_list.last
                  AND l_flg_permission
            LOOP
                l_flg_permission := has_permission(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_id_dep_clin_serv => i_id_dep_clin_serv_list(l_idx),
                                                   i_id_sch_event     => l_id_sch_event,
                                                   i_id_prof          => i_id_prof_list(l_idx),
                                                   i_id_institution   => l_id_institution) = g_msg_true;
                l_idx            := l_idx + 1;
            END LOOP;
        ELSE
            RAISE l_func_exception;
        END IF;
    
        IF NOT l_flg_permission
        THEN
            o_msg_title   := pk_message.get_message(i_lang, g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_no_permission);
            o_button      := g_check_button;
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            RETURN TRUE;
        END IF;
    
        -- calcular o flg_sch_type
        IF l_flg_sch_type IS NULL
        THEN
            g_error := 'fetch dep_type';
            IF NOT pk_schedule_common.get_dep_type(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_id_sch_event => i_id_sch_event,
                                                   o_dep_type     => l_flg_sch_type,
                                                   o_error        => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        -- Obter config geral das vagas
        g_error := 'CALL CHECK_VACANCY_USAGE';
        -- obter primeiro o i_id_dept a partir do id_dcs_requested. Se nao encontrar deve ir para o WHEN OTHERS
    
        -- Professional array iteration
        l_idx := 1;
        FOR idx IN i_id_prof_list.first .. i_id_prof_list.last
        LOOP
        
            SELECT id_department
              INTO l_id_dept
              FROM dep_clin_serv d
             WHERE d.id_dep_clin_serv = nvl(i_id_dep_clin_serv_list(idx), -1);
        
            IF NOT pk_schedule_common.check_vacancy_usage(i_lang,
                                                          l_id_institution,
                                                          --i_prof.institution,
                                                          i_prof.software,
                                                          l_id_dept,
                                                          l_flg_sch_type,
                                                          l_vacancy_usage,
                                                          l_sched_w_vac,
                                                          l_edit_vac,
                                                          o_error)
            THEN
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
                RAISE l_func_exception;
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
                RAISE l_func_exception;
            END IF;
        
            -- get vacancy full data
            g_error := 'GET VACANCY DATA';
            IF NOT pk_schedule_common.get_vacancy_data(i_lang               => i_lang,
                                                       i_id_institution     => l_id_institution, -- i_prof.institution,
                                                       i_id_sch_event       => l_id_sch_event,
                                                       i_id_professional    => NULL,
                                                       i_id_dep_clin_serv   => i_id_dep_clin_serv_list(idx),
                                                       i_dt_begin_tstz      => l_dt_begin,
                                                       i_flg_sch_type       => l_flg_sch_type,
                                                       i_id_sch_consult_vac => i_id_consult_vac_list(idx),
                                                       o_vacancy            => l_vac,
                                                       o_error              => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- opcoes marcar numa vaga e marcar alem-vaga
            g_error := 'evaluate sch_option';
            IF i_sch_option IN
               (g_sch_option_invacancy, g_sch_option_unplanned, g_sch_option_novacancy, g_sch_option_update)
            THEN
            
                -- unexpected vacancy found for a schedule without vacancy
                IF i_sch_option = g_sch_option_novacancy
                   AND l_vac.id_sch_consult_vacancy IS NOT NULL
                THEN
                    RAISE l_unexvacfound;
                END IF;
            
                --  obteve vaga
                IF i_sch_option IN (g_sch_option_invacancy, g_sch_option_unplanned, g_sch_option_update)
                   AND l_vac.id_sch_consult_vacancy IS NOT NULL
                THEN
                    l_ignore_vac := FALSE;
                END IF;
            
                -- logica comum a todos os kinds
                IF i_sch_option = g_sch_option_novacancy
                   OR (i_sch_option IN (g_sch_option_invacancy, g_sch_option_unplanned, g_sch_option_update) AND
                   l_ignore_vac = TRUE)
                THEN
                    -- verificar overlapping
                    IF NOT get_schedule_overlap(i_lang,
                                                i_id_prof_list(idx),
                                                l_id_institution,
                                                --i_prof.institution,
                                                l_dt_begin,
                                                l_dt_end,
                                                l_overlap,
                                                o_error)
                    THEN
                        RAISE l_func_exception;
                    END IF;
                
                    -- overlap exists but no permission to do it or unknown permission
                    IF l_overlap = g_yes
                       AND nvl(i_do_overlap, g_no) = g_no
                    THEN
                        RAISE l_overlapfound;
                    
                        -- overlap exists and there is permission to proceed
                    ELSIF l_overlap = g_yes
                          AND nvl(i_do_overlap, g_no) = g_yes
                    THEN
                        --o_overlapfound := g_yes;
                        l_ignore_vac := TRUE;
                    
                        -- no overlap and not possible to schedule without a vacancy
                    ELSIF l_overlap = g_no
                          AND NOT l_sched_w_vac
                    THEN
                        RAISE l_vacancy_needed;
                        -- ALERT-11352. no overlap and we can change the vacancy. 
                        -- This new course of action takes precendence over the 'can schedule without vacancy' action in the next elsif
                    ELSIF l_overlap = g_no
                          AND l_edit_vac
                          AND i_id_consult_vac_list(idx) IS NOT NULL
                    THEN
                        IF NOT pk_schedule_common.alter_vacancy(i_lang                   => i_lang,
                                                                i_id_sch_consult_vacancy => i_id_consult_vac_list(idx),
                                                                i_id_prof                => i_id_prof_list(idx),
                                                                i_id_dep_clin_serv       => i_id_dep_clin_serv_list(idx),
                                                                i_id_room                => i_id_room,
                                                                i_dt_begin_tstz          => l_dt_begin,
                                                                i_dt_end_tstz            => l_dt_end,
                                                                o_error                  => o_error)
                        THEN
                            RAISE l_func_exception;
                        END IF;
                    
                        l_ignore_vac := FALSE;
                        --l_vac.id_sch_consult_vacancy := i_id_consult_vac;
                    
                        -- no overlap and we can schedule without vacancy
                    ELSIF l_overlap = g_no
                          AND l_sched_w_vac
                    THEN
                        l_ignore_vac := TRUE;
                    END IF;
                
                END IF;
            
                -- opcao invalida
            ELSE
                RAISE l_invalid_option;
            END IF;
        
        END LOOP;
    
        -- SETUP flg_status
        -- Check if there is an interface with an external system
        g_error := 'CALL EXIST INTERFACE';
        IF NOT pk_schedule_common.exist_interface(i_lang   => i_lang,
                                                  i_prof   => i_prof,
                                                  o_exists => l_schedule_interface,
                                                  o_error  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CHECK SCHEDULE INTERFACE';
        IF NOT l_schedule_interface
           AND l_flg_sch_type <> pk_schedule_common.g_sch_dept_flg_dep_type_cons
        THEN
            -- There isn't an interface and schedules are not managed on ALERT
            -- so a member of the staff must create the schedule manually on the external system.
            l_flg_status := g_status_pending;
        ELSE
            -- The schedule can be marked successfully as "scheduled"
            l_flg_status := g_status_scheduled;
        END IF;
    
        g_error := 'CALL CREATE_SCHEDULE';
        -- Create the schedule
        IF NOT pk_schedule_common.create_schedule_multidisc(i_lang                    => i_lang,
                                                            i_id_prof_schedules       => i_prof.id,
                                                            i_id_institution          => l_id_institution, -- i_prof.institution,
                                                            i_id_software             => i_prof.software,
                                                            i_id_patient              => i_id_patient,
                                                            i_id_dep_clin_serv_list   => i_id_dep_clin_serv_list,
                                                            i_id_sch_event            => i_id_sch_event,
                                                            i_id_prof_list            => i_id_prof_list,
                                                            i_dt_begin                => l_dt_begin,
                                                            i_dt_end                  => l_dt_end,
                                                            i_flg_vacancy             => i_flg_vacancy,
                                                            i_flg_status              => l_flg_status,
                                                            i_schedule_notes          => i_schedule_notes,
                                                            i_id_lang_translator      => i_id_lang_translator,
                                                            i_id_lang_preferred       => i_id_lang_preferred,
                                                            i_id_reason               => i_id_reason,
                                                            i_id_origin               => i_id_origin,
                                                            i_id_schedule_ref         => i_id_schedule_ref,
                                                            i_id_room                 => i_id_room,
                                                            i_flg_sch_type            => l_flg_sch_type,
                                                            i_id_exam                 => i_id_exam,
                                                            i_id_analysis             => i_id_analysis,
                                                            i_reason_notes            => i_reason_notes,
                                                            i_flg_request_type        => i_flg_request_type,
                                                            i_flg_schedule_via        => i_flg_schedule_via,
                                                            i_id_consult_vac_list     => i_id_consult_vac_list,
                                                            i_id_multidisc            => i_id_multidisc,
                                                            i_id_prof_leader          => i_id_prof_leader,
                                                            i_id_dep_clin_serv_leader => i_id_dep_clin_serv_leader,
                                                            o_id_schedule             => o_id_schedule,
                                                            o_occupied                => l_occupied,
                                                            i_ignore_vacancies        => l_ignore_vac,
                                                            i_id_episode              => i_id_episode,
                                                            i_id_complaint            => i_id_complaint,
                                                            i_id_sch_combi_detail     => i_id_sch_combi_detail,
                                                            o_error                   => o_error)
        THEN
            -- Restore state
            RAISE l_func_exception;
        END IF;
    
        IF i_flg_vacancy <> pk_schedule_common.g_sched_vacancy_urgent
        THEN
            -- nao foi consumida uma vaga. O flg_vacancy passa a unplanned se nao estava em urgent
            IF l_occupied IS NULL
            THEN
                g_error := 'ALTER SCHEDULE TO UNPLANNED';
                IF i_show_vacancy_warn
                   AND i_sch_option = g_sch_option_invacancy
                  --AND l_vac.id_sch_consult_vacancy IS NOT NULL
                   AND NOT i_id_consult_vac_list.count > 0
                THEN
                    -- Schedule this appointment as unplanned and warn the user
                    o_msg_title := pk_message.get_message(i_lang, g_sched_msg_warning_title);
                
                    o_msg    := pk_message.get_message(i_lang, g_sched_msg_warning);
                    o_button := g_check_button;
                
                    o_flg_show    := g_yes;
                    o_flg_proceed := g_no;
                
                    -- Alter the schedule's vacancy flag
                    IF NOT pk_schedule_common.alter_schedule(i_lang         => i_lang,
                                                             i_id_schedule  => o_id_schedule,
                                                             i_flg_vacancy  => pk_schedule_common.g_sched_vacancy_unplanned,
                                                             o_schedule_rec => l_schedule_rec,
                                                             o_error        => o_error)
                    THEN
                        RAISE l_func_exception;
                    END IF;
                END IF;
            
            ELSE
                -- foi consumida uma vaga. O flg_vacancy passa a routine se nao estava em urgent
                g_error := 'ALTER SCHEDULE TO ROUTINE';
                IF i_show_vacancy_warn
                   AND i_flg_vacancy = pk_schedule_common.g_sched_vacancy_unplanned
                THEN
                    o_msg_title := pk_message.get_message(i_lang, g_sched_msg_warning_title);
                
                    o_msg    := pk_message.get_message(i_lang, g_sched_msg_warning_not_occu);
                    o_button := g_check_button;
                
                    o_flg_show    := g_yes;
                    o_flg_proceed := g_no;
                END IF;
                -- Alter the schedule's vacancy flag
                IF NOT pk_schedule_common.alter_schedule(i_lang         => i_lang,
                                                         i_id_schedule  => o_id_schedule,
                                                         i_flg_vacancy  => pk_schedule_common.g_sched_vacancy_routine,
                                                         o_schedule_rec => l_schedule_rec,
                                                         o_error        => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN l_invalid_option THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'invalid or unknown value in parameter i_sch_option',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN l_vacancy_needed THEN
            o_msg_title   := pk_message.get_message(i_lang, g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_vacancyneeded);
            o_button      := g_cancel_button_code || pk_message.get_message(i_lang, g_sched_msg_goback) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN l_overlapfound THEN
            o_msg_title   := pk_message.get_message(i_lang, g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_overlapfound);
            o_button      := g_cancel_button_code || pk_message.get_message(i_lang, g_sched_msg_goback) || '|' ||
                             g_ok_button_code || pk_message.get_message(i_lang, g_sched_msg_dooverlap) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN l_unexvacfound THEN
            o_msg_title   := pk_message.get_message(i_lang, g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_unexvacfound);
            o_button      := g_cancel_button_code || pk_message.get_message(i_lang, g_sched_msg_goback) || '|' ||
                             g_ok_button_code || pk_message.get_message(i_lang, g_sched_msg_schedwithvac) || '|' ||
                             g_r_button_code || pk_message.get_message(i_lang, g_sched_msg_schedwithoutvac) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN l_no_vac_usage THEN
            o_msg_title   := pk_message.get_message(i_lang, g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_no_vac_usage);
            o_button      := g_cancel_button_code || pk_message.get_message(i_lang, g_sched_msg_goback) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            -- Unexpected error
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
        
    END create_schedule_multidisc;

    ------------------------- SERIES APPOINTMENTS FUNCTIONS
    ------------------------- SERIES APPOINTMENTS FUNCTIONS
    ------------------------- SERIES APPOINTMENTS FUNCTIONS
    ------------------------- SERIES APPOINTMENTS FUNCTIONS

    -- FUNCTION INS_SCHEDULE_RECURSION
    /********************************************************************************************    
    * Insert a record on table schedule_recursion
    *
    * @param i_lang                           language ID
    * @param i_prof                           Professional identification    
    * @param i_repeat_frequency               Frequency of repeatition    
    * @param i_flg_unit                       Unit (D-daily, W-weekly, M-monthly, Y-yearly)
    * @param i_weekday                        Weekday
    * @param i_week                           Week number
    * @param i_day_month                      Day of month
    * @param i_month                          Month
    * @param i_begin_date                     Begin date
    * @param i_end_date                       End date
    * @param i_num_serie                      Nr of events
    * @param i_flg_status                     Flag status (E-events, D-date)
    * @param o_id_schedule_recursion        Outuput id
    * @param o_error                          error message
    *
    * @return                 success/fail
    * 
    * @raises                
    *
    * @author                Sofia Mendes
    * @version               V.2.5.4
    * @since                 2009/06/23    
    ********************************************************************************************/
    FUNCTION ins_schedule_recursion
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_schedule_recursion IN schedule_recursion.id_schedule_recursion%TYPE,
        i_flg_regular           IN schedule_recursion.flg_regular%TYPE DEFAULT NULL,
        i_flg_timeunit          IN schedule_recursion.flg_timeunit%TYPE DEFAULT NULL,
        i_num_take              IN schedule_recursion.num_take%TYPE DEFAULT NULL,
        i_num_freq              IN schedule_recursion.num_freq%TYPE DEFAULT NULL,
        i_id_interv_presc_det   IN schedule_recursion.id_interv_presc_det%TYPE DEFAULT NULL,
        i_repeat_frequency      IN schedule_recursion.repeat_frequency%TYPE DEFAULT NULL,
        i_weekdays              IN schedule_recursion.weekdays%TYPE DEFAULT NULL,
        i_week                  IN schedule_recursion.week%TYPE DEFAULT NULL,
        i_day_month             IN schedule_recursion.day_month%TYPE DEFAULT NULL,
        i_month                 IN schedule_recursion.month%TYPE DEFAULT NULL,
        i_begin_date            IN schedule_recursion.dt_begin%TYPE DEFAULT NULL,
        i_end_date              IN schedule_recursion.dt_end%TYPE DEFAULT NULL,
        i_flg_type_rep          IN schedule_recursion.flg_type_rep%TYPE DEFAULT NULL,
        i_flg_type              IN schedule_recursion.flg_type%TYPE DEFAULT NULL,
        o_id_schedule_recursion OUT schedule_recursion.id_schedule_recursion%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'INS_SCHEDULE_RECURSION';
    BEGIN
        g_error := 'INSERT INTO SCHEDULE_RECURSION';
        INSERT INTO schedule_recursion
            (id_schedule_recursion,
             weekdays,
             flg_regular,
             flg_timeunit,
             num_take,
             num_freq,
             id_interv_presc_det,
             repeat_frequency,
             week,
             day_month,
             MONTH,
             dt_begin,
             dt_end,
             flg_type_rep,
             flg_type)
        VALUES
            (nvl(i_id_schedule_recursion, seq_schedule_recursion.nextval),
             i_weekdays,
             i_flg_regular,
             i_flg_timeunit,
             i_num_take,
             i_num_freq,
             i_id_interv_presc_det,
             i_repeat_frequency,
             i_week,
             i_day_month,
             i_month,
             i_begin_date,
             i_end_date,
             i_flg_type_rep,
             i_flg_type)
        RETURNING id_schedule_recursion INTO o_id_schedule_recursion;
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END ins_schedule_recursion;

    -- FUNCTION GET_SCH_SERIES_COMPUTED_DATES
    /********************************************************************************************
    * This function determines proposed schedule dates, based on i_flg_timeunit, i_nr_events,
    * i_repeat_every, i_weekday, i_day_of_month, i_week, i_month, i_sch_start_date and i_sch_end_date
    *      
    *
    * @param i_lang           language ID
    * @param i_prof           Professional identification
    * @param i_flg_timeunit   Flag timeunit ('D' - Day, 'W' - week, 'M' - month, 'Y' -year)
    * @param i_flg_end_by     Flag end by: indicates if the repetition is done by nr of events or date ('D' - date; 'E' - nr of events')
    * @param i_repeat_every   Repeat every (n units [week,day, month,year])
    * @param i_weekday        Day of week
    * @param i_day_of_month   Day of month
    * @param i_week           Month week
    * @param i_sch_start_date Start repeatition date
    * @param i_sch_end_date   End repeatition date
    * @param o_dates          Output dates
    * @param o_flg_irregular  Output parameter: Y-When it is proposed the last day of month instead of the indicated date (ex. day 31)
    *                                           N-All the dates are proposed at the day selected by the user.
    * @param o_error                         error message
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Sofia Mendes
    * @version               V.2.5.4
    * @since                 2009/06/23   
    ********************************************************************************************/
    FUNCTION get_sch_series_computed_dates
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_timeunit   IN VARCHAR2,
        i_flg_end_by     IN VARCHAR2,
        i_nr_events      IN NUMBER,
        i_repeat_every   IN NUMBER,
        i_weekday        IN NUMBER,
        i_day_of_month   IN NUMBER,
        i_week           IN NUMBER,
        i_sch_start_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_sch_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_month          IN NUMBER,
        o_flg_irregular  OUT VARCHAR2,
        o_dates          OUT table_timestamp_tz,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SCH_SERIES_COMPUTED_DATES';
        -- Local variables        
        l_tab_proposed_sch       table_timestamp_tz := table_timestamp_tz();
        l_dt_aux                 TIMESTAMP;
        l_dt_aux_irreg           TIMESTAMP;
        l_tab_proposed_sch_count NUMBER;
        l_count_irregular        NUMBER := 0;
        l_idx                    NUMBER := 1;
        l_rep_factor             NUMBER := 1;
        l_start_weekday_std      NUMBER;
        l_week_str               VARCHAR2(30);
        l_dt_aux_week            TIMESTAMP;
        l_nr_days                NUMBER;
        l_weekday_std            NUMBER;
        l_is_irregular           VARCHAR2(1) := g_no;
    
        l_sch_start_date TIMESTAMP := to_timestamp(to_char(i_sch_start_date, 'yyyymmddhh24miss'), 'yyyymmddhh24miss');
        l_sch_end_date   TIMESTAMP := to_timestamp(to_char(i_sch_end_date, 'yyyymmddhh24miss'), 'yyyymmddhh24miss');
        l_timezone       VARCHAR2(4000);
    
        PROCEDURE irregular_rep
        (
            l_count_irregular IN OUT NUMBER,
            l_dt_aux          IN OUT TIMESTAMP,
            i_nr_of_months    IN NUMBER
        ) IS
            l_dt_aux_month  TIMESTAMP;
            l_repeat_every  NUMBER;
            l_nr            NUMBER;
            l_day           NUMBER;
            l_day_prev_date NUMBER;
        BEGIN
            IF (l_count_irregular != 0)
            THEN
                l_dt_aux_month := l_tab_proposed_sch(1);
                l_repeat_every := l_tab_proposed_sch_count + i_repeat_every;
            ELSE
                l_repeat_every := i_repeat_every;
                l_dt_aux_month := l_dt_aux;
            END IF;
        
            BEGIN
                IF (l_count_irregular != 0)
                THEN
                    g_error        := 'CALL ADD_MONTHS';
                    l_dt_aux_month := add_months(l_dt_aux_month, i_nr_of_months * l_repeat_every);
                ELSE
                    g_error         := 'CALL NON_ANSI_ADD_MONTHS';
                    l_day_prev_date := extract(DAY FROM l_dt_aux_month);
                    l_dt_aux_month  := pk_date_utils.non_ansi_add_months(i_lang         => i_lang,
                                                                         i_prof         => i_prof,
                                                                         i_date         => l_dt_aux_month,
                                                                         i_nr_of_months => i_nr_of_months *
                                                                                           l_repeat_every,
                                                                         o_error        => o_error);
                    l_day           := extract(DAY FROM l_dt_aux_month);
                
                    IF (l_day_prev_date <> l_day)
                    THEN
                        l_is_irregular := g_yes;
                    END IF;
                END IF;
                l_dt_aux := l_dt_aux_month;
            EXCEPTION
                WHEN OTHERS THEN
                    IF NOT get_last_day_month(i_lang  => i_lang,
                                              i_prof  => i_prof,
                                              i_date  => l_dt_aux,
                                              o_date  => l_dt_aux_month,
                                              o_error => o_error)
                    THEN
                        NULL;
                    END IF;
                
                    l_nr     := extract(DAY FROM(l_dt_aux_month - l_dt_aux));
                    l_dt_aux := pk_date_utils.add_days_to_tstz(l_dt_aux, l_nr + 1);
                
                    l_count_irregular := 1;
            END;
        END irregular_rep;
    
        PROCEDURE main_cycle IS
        BEGIN
            IF (i_week IS NOT NULL)
            THEN
                l_dt_aux_week := l_dt_aux;
                g_error       := 'CALL GET_NEXT_DAY';
                IF NOT get_next_day(i_lang    => i_lang,
                                    i_prof    => i_prof,
                                    i_weekday => i_weekday,
                                    i_week    => i_week,
                                    i_date    => l_dt_aux,
                                    o_date    => l_dt_aux,
                                    o_error   => o_error)
                THEN
                    --RETURN FALSE;
                    NULL;
                END IF;
            
                l_nr_days := extract(DAY FROM(l_dt_aux - l_dt_aux_week));
                --l_nr_days := l_dt_aux - l_dt_aux_week;
                l_dt_aux := pk_date_utils.add_days_to_tstz(l_dt_aux_week, l_nr_days);
            
            END IF;
        
            l_tab_proposed_sch_count := l_tab_proposed_sch.count;
            l_tab_proposed_sch.extend;
        
            --l_tab_proposed_sch(l_tab_proposed_sch_count + 1) := l_dt_aux;
        
            l_tab_proposed_sch(l_tab_proposed_sch_count + 1) := to_timestamp_tz(to_char(l_dt_aux, 'yyyymmddhh24miss') || ' ' ||
                                                                                l_timezone,
                                                                                'yyyymmddhh24miss TZR');
        
            IF (i_week IS NOT NULL)
            THEN
                l_dt_aux := l_dt_aux_week;
            END IF;
        
            IF (i_flg_timeunit = g_month_timeunit)
            THEN
                irregular_rep(l_count_irregular, l_dt_aux, 1);
            ELSIF (i_flg_timeunit = g_year_timeunit)
            THEN
                irregular_rep(l_count_irregular, l_dt_aux, 12);
            ELSE
                l_dt_aux := pk_date_utils.add_days_to_tstz(l_dt_aux, l_rep_factor);
            END IF;
        
        END main_cycle;
    
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        l_dt_aux := l_sch_start_date;
    
        SELECT to_char(current_timestamp, 'TZR')
          INTO l_timezone
          FROM dual;
    
        IF i_flg_timeunit = g_day_timeunit
        THEN
            l_rep_factor := i_repeat_every;
        ELSIF i_flg_timeunit = g_week_timeunit
        THEN
            g_error       := 'WEEK REPEATITION';
            l_rep_factor  := g_weekdays * i_repeat_every;
            l_weekday_std := pk_date_utils.week_day_standard(l_dt_aux);
            IF (l_weekday_std != i_weekday)
            THEN
                l_dt_aux := pk_date_utils.next_day_standard(l_dt_aux, i_weekday);
            END IF;
        ELSIF i_flg_timeunit = g_month_timeunit
              OR i_flg_timeunit = g_year_timeunit
        THEN
            g_error := 'MONTH OR YEAR REPEATITION';
            IF (i_day_of_month IS NOT NULL)
            THEN
                g_error := 'CALL GET_NEXT_DAY_MONTH';
                IF NOT get_next_day_month(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_day_of_month => i_day_of_month,
                                          i_month        => i_month,
                                          i_date         => l_dt_aux,
                                          o_date         => l_dt_aux_irreg,
                                          o_error        => o_error)
                THEN
                    g_error := 'CALL GET_LAST_DAY_MONTH';
                    IF NOT get_last_day_month(i_lang  => i_lang,
                                              i_prof  => i_prof,
                                              i_date  => l_dt_aux,
                                              o_date  => l_dt_aux,
                                              o_error => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                    l_count_irregular := 1;
                ELSE
                    l_dt_aux := l_dt_aux_irreg;
                END IF;
            END IF;
        
        END IF;
    
        IF (i_flg_end_by = g_end_by_nr_events)
        THEN
            WHILE l_idx <= i_nr_events
            LOOP
                main_cycle;
                l_idx := l_idx + 1;
            END LOOP;
        ELSIF (i_flg_end_by = g_end_by_date)
        THEN
            WHILE l_dt_aux < l_sch_end_date
            LOOP
                main_cycle;
                l_idx := l_idx + 1;
            END LOOP;
        END IF;
    
        -- Return table with proposed schedule dates    
        o_dates := l_tab_proposed_sch;
    
        o_flg_irregular := l_is_irregular;
        pk_date_utils.set_dst_time_check_on;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_sch_series_computed_dates;

    -- FUNCTION VAL_SCH_SERIES_COMPUTED_DATES - Validate Series Computed Dates
    FUNCTION val_sch_series_computed_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_flg_sch_type     IN schedule.flg_sch_type%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_vacancy          OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error            OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_func_name      VARCHAR2(30) := 'VAL_SCH_SERIES_COMPUTED_DATES';
        l_flg_error      VARCHAR2(1) := 'E';
        l_flg_success    VARCHAR2(1) := 'S';
        l_flg_permission VARCHAR2(1) := 'P';
        l_flg_no_vacancy VARCHAR2(1) := 'V';
        l_flg_conflit    VARCHAR2(1) := 'C';
    
        l_hasperm               VARCHAR2(10);
        l_id_sch_event          sch_event.id_sch_event%TYPE;
        l_vacancy_usage         BOOLEAN;
        l_sched_w_vac           BOOLEAN;
        l_edit_vac              BOOLEAN;
        l_dt_begin              TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end                TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_use               sch_vacancy_usage.flg_use%TYPE;
        l_flg_sched_without_vac sch_vacancy_usage.flg_sched_without_vac%TYPE;
        l_flg_edit_vac          sch_vacancy_usage.flg_edit_vac%TYPE;
        l_vac                   sch_consult_vacancy%ROWTYPE;
        l_flg_sch_type          sch_event.dep_type%TYPE := i_flg_sch_type;
        l_id_dept               dep_clin_serv.id_department%TYPE;
        l_id_schedule_vac       schedule.id_schedule%TYPE;
        l_id_sch_con_vac        sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
    
        l_days           NUMBER;
        l_hours          NUMBER;
        l_minutes        NUMBER;
        l_seconds        NUMBER;
        l_duration       NUMBER;
        l_id_institution institution.id_institution%TYPE := i_id_institution;
    BEGIN
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN l_flg_error;
        END IF;
    
        -- Convert repeatition start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RETURN l_flg_error;
        END IF;
    
        -- Generic Event
        g_error := 'CALL PK_SCHEDULE_COMMON.GET_GENERIC_EVENT';
        IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                    i_id_institution => l_id_institution, --i_prof.institution,
                                                    i_id_event       => i_id_sch_event,
                                                    o_id_event       => l_id_sch_event,
                                                    o_error          => o_error)
        THEN
            RETURN l_flg_error;
        END IF;
    
        -- Permissions
        g_error   := 'CHECK PERMISSION TO SCHEDULE';
        l_hasperm := has_permission(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_dep_clin_serv => i_id_dep_clin_serv,
                                    i_id_sch_event     => i_id_sch_event,
                                    i_id_institution   => l_id_institution,
                                    i_id_prof          => i_id_prof);
        IF l_hasperm = g_msg_false
        THEN
            RETURN l_flg_permission;
        END IF;
    
        -- Dep Type
        /*g_error := 'CALL PK_SCHEDULE_COMMON.GET_DEP_TYPE';
        IF NOT pk_schedule_common.get_dep_type(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_sch_event => i_id_sch_event,
                                               o_dep_type     => l_flg_sch_type,
                                               o_error        => o_error)
        THEN
            RETURN l_flg_error;
        END IF;
        
        -- Obter config geral das vagas
        g_error := 'CALL CHECK_VACANCY_USAGE';
        SELECT id_department
          INTO l_id_dept
          FROM dep_clin_serv d
         WHERE d.id_dep_clin_serv = nvl(i_id_dep_clin_serv, -1);*/
    
        -- Get usage
        /*g_error := 'CALL GET_VACANCY_CONFIG';
        IF NOT get_vacancy_config(i_lang                  => i_lang,
                                  i_prof                  => profissional(-1, i_prof.institution, i_prof.software),
                                  i_id_dept               => l_id_dept,
                                  i_dep_type              => l_flg_sch_type,
                                  o_flg_use               => l_flg_use,
                                  o_flg_sched_without_vac => l_flg_sched_without_vac,
                                  o_flg_edit_vac          => l_flg_edit_vac,
                                  o_error                 => o_error)
        THEN
            RETURN l_flg_error;
        END IF;*/
    
        -- Convert start date to timestamp
        /*g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN l_flg_error;
        END IF;*/
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RETURN l_flg_error;
        END IF;
    
        -- get vacancy full data
        g_error := 'GET VACANCY DATA';
        IF NOT pk_schedule_common.get_vacancy_data(i_lang             => i_lang,
                                                   i_id_institution   => l_id_institution, --i_prof.institution,
                                                   i_id_sch_event     => l_id_sch_event,
                                                   i_id_professional  => i_id_prof,
                                                   i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                   i_dt_begin_tstz    => l_dt_begin,
                                                   i_flg_sch_type     => l_flg_sch_type,
                                                   o_vacancy          => l_vac,
                                                   o_error            => o_error)
        THEN
            RETURN l_flg_error;
        END IF;
    
        /*IF NOT pk_date_utils.get_timestamp_diff_sep(i_lang        => i_lang,
                                                    i_timestamp_1 => i_dt_begin,
                                                    i_timestamp_2 => i_dt_end,
                                                    o_days        => l_days,
                                                    o_hours       => l_hours,
                                                    o_minutes     => l_minutes,
                                                    o_seconds     => l_seconds,
                                                    o_error       => o_error)
        THEN
            RETURN l_flg_error;
        END IF;
        
        l_duration := trunc(l_days * 24 + l_hours * 60 + l_minutes + l_seconds / 60);
        
        BEGIN            
            -- checks if exist a vacancy that fits the expected duration
            g_error := 'SELECT sch_consult_vacancy';
            SELECT scv.id_sch_consult_vacancy
              INTO l_id_sch_con_vac
              FROM sch_consult_vacancy scv
             WHERE scv.id_prof = i_id_prof
               AND scv.id_institution = i_prof.institution
               AND scv.id_dep_clin_serv = i_id_dep_clin_serv
               AND scv.id_sch_event = l_id_sch_event
               AND scv.dt_begin_tstz <= i_dt_begin
               AND scv.dt_end_tstz >= i_dt_begin + (l_duration / 24 / 60)
               AND rownum = 1; -- the first slot found is suficient for the validation
        
        EXCEPTION
            WHEN no_data_found THEN
                RETURN l_flg_no_vacancy;
        END;
        
        o_vacancy := l_id_sch_con_vac;
        -- if has vacancy verify if there is a free vacancy
        BEGIN            
            -- checks if exist a vacancy that fits the expected duration
            g_error := 'SELECT sch_consult_vacancy - free slots';
            SELECT id_sch_consult_vacancy
            INTO l_id_sch_con_vac
            from
            (SELECT scv.id_sch_consult_vacancy, scv.max_vacancies - scv.used_vacancies as num_vacs
              FROM sch_consult_vacancy scv
             WHERE scv.id_prof = i_id_prof
               AND scv.id_institution = i_prof.institution
               AND scv.id_dep_clin_serv = i_id_dep_clin_serv
               AND scv.id_sch_event = l_id_sch_event
               AND scv.dt_begin_tstz <= i_dt_begin
               AND scv.dt_end_tstz >= i_dt_begin + (l_duration / 24 / 60))
            WHERE num_vacs >0
               AND rownum = 1; -- the first slot found is suficient for the validation
        
        EXCEPTION
            WHEN no_data_found THEN
                RETURN l_flg_conflit;
        END;*/
    
        IF (l_vac.id_sch_consult_vacancy IS NULL)
        THEN
            RETURN l_flg_no_vacancy;
        END IF;
    
        o_vacancy := l_vac.id_sch_consult_vacancy; --l_id_sch_con_vac;--l_vac.id_sch_consult_vacancy;
        IF ((l_vac.max_vacancies - l_vac.used_vacancies) = 0)
        THEN
            RETURN l_flg_conflit;
        END IF;
        IF (i_id_schedule IS NULL)
        THEN
            IF ((l_vac.max_vacancies - l_vac.used_vacancies) = 0)
            THEN
                RETURN l_flg_conflit;
            END IF;
        ELSE
            SELECT s.id_schedule
              INTO l_id_schedule_vac
              FROM schedule s
             WHERE s.id_sch_consult_vacancy = l_vac.id_sch_consult_vacancy;
        
            IF (i_id_schedule != l_id_schedule_vac)
            THEN
                RETURN l_flg_conflit;
            END IF;
        END IF;
    
        -- Falta verificar l_vac =ROWTYPE (sch_vacnvy)
        -- verificar se o l_vac    
        RETURN l_flg_success;
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
            RETURN l_flg_error;
    END val_sch_series_computed_dates;

    /*
    * Validates a set of dates 
    *
    * @param   i_lang                       Language identifier.
    * @param   i_prof                       Professional.
    * @param   i_id_profs                   Professioanl identifiers for the validation    
    * @param   i_duration                   Duration of appointment
    * @param   i_dates                      Table with dates previously calculate 
    * @param   o_conflicts                  Table with the conflits of each date presented in i_dates
    * @param   o_error                      Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Sofia Mendes
    * @version 2.5.4
    * @since 2009/06/29    
    */
    FUNCTION validate_sch_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_flg_sch_type     IN schedule.flg_sch_type%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        --i_durations    IN table_number,
        i_dates     IN table_timestamp_tz,
        o_conflicts OUT table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name      VARCHAR2(32) := 'VALIDATE_SCH_DATES';
        l_duration       NUMBER;
        l_flg_conflict   VARCHAR2(1);
        l_desc_no_vac    VARCHAR2(4000);
        l_desc_over_slot VARCHAR2(4000);
    
        l_vacancies table_number := table_number();
    
        l_status VARCHAR2(1);
    
    BEGIN
        g_error     := 'Fill o_conflicts';
        o_conflicts := table_varchar();
        IF (i_dates.count > 0)
        THEN
            l_vacancies.extend(i_dates.count);
        
            FOR i IN i_dates.first .. i_dates.last
            LOOP
                -- validate date                
                l_status := val_sch_series_computed_dates(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_sch_event     => i_id_sch_event,
                                                          i_flg_sch_type     => i_flg_sch_type,
                                                          i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                          i_id_prof          => i_id_prof,
                                                          i_dt_begin         => i_dates(i),
                                                          i_dt_end           => NULL,
                                                          --i_duration        => i_durations(i),
                                                          o_vacancy => l_vacancies(i),
                                                          o_error   => o_error);
            
                o_conflicts.extend();
                o_conflicts(i) := l_status;
            END LOOP;
        END IF;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_sch_dates;

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
    * @author                Sofia Mendes
    * @version               V.2.5.4
    * @since                 2009/06/29    
    ********************************************************************************************/
    FUNCTION validate_before_confirm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_flg_sch_type     IN schedule.flg_sch_type%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_tab_status       IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'VALIDATE_BEFORE_CONFIRM';
        l_dt_begin_tstz         table_timestamp_tz;
        l_dt_end_tstz           table_timestamp_tz;
        l_durations             table_number := table_number();
        l_conflits              table_varchar;
        l_days                  NUMBER;
        l_hours                 NUMBER;
        l_minutes               NUMBER;
        l_seconds               NUMBER;
        l_flg_use               sch_vacancy_usage.flg_use%TYPE;
        l_flg_sched_without_vac sch_vacancy_usage.flg_sched_without_vac%TYPE;
        l_flg_edit_vac          sch_vacancy_usage.flg_edit_vac%TYPE;
        l_flg_sch_type          sch_event.dep_type%TYPE := i_flg_sch_type;
        l_id_dept               dep_clin_serv.id_department%TYPE;
        has_conflict            BOOLEAN := FALSE;
        has_no_vacancy          BOOLEAN := FALSE;
        l_id_institution        institution.id_institution%TYPE := i_id_institution;
    BEGIN
    
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        -- Dep Type
        g_error := 'CALL PK_SCHEDULE_COMMON.GET_DEP_TYPE';
        IF NOT pk_schedule_common.get_dep_type(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_sch_event => i_id_sch_event,
                                               o_dep_type     => l_flg_sch_type,
                                               o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Obter config geral das vagas
        g_error := 'CALL CHECK_VACANCY_USAGE';
        SELECT id_department
          INTO l_id_dept
          FROM dep_clin_serv d
         WHERE d.id_dep_clin_serv = nvl(i_id_dep_clin_serv, -1);
    
        g_error := 'CALL GET_VACANCY_CONFIG';
        IF NOT get_vacancy_config(i_lang                  => i_lang,
                                  i_prof                  => profissional(-1,
                                                                          l_id_institution /*i_prof.institution*/,
                                                                          i_prof.software),
                                  i_id_dept               => l_id_dept,
                                  i_dep_type              => l_flg_sch_type,
                                  i_id_institution        => l_id_institution,
                                  o_flg_use               => l_flg_use,
                                  o_flg_sched_without_vac => l_flg_sched_without_vac,
                                  o_flg_edit_vac          => l_flg_edit_vac,
                                  o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL VALIDATE_SCH_DATES';
    
        FOR idx IN i_tab_status.first .. i_tab_status.last
        LOOP
            IF (i_tab_status(idx) = 'C')
            THEN
                has_conflict := TRUE;
            ELSIF (i_tab_status(idx) = 'V')
            THEN
                has_no_vacancy := TRUE;
            END IF;
        END LOOP;
    
        IF (l_flg_sched_without_vac = g_no AND has_no_vacancy = TRUE)
        THEN
            o_msg      := pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_no_vacancy);
            o_flg_show := g_yes;
        ELSE
            o_flg_show := g_no;
        END IF;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_before_confirm;

    -- FUNCTION GET_SCH_SERIES_APPOINTMENTS - UX Call
    FUNCTION get_sch_series_appointments
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_flg_sch_type     IN schedule.flg_sch_type%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_start_date       IN VARCHAR2,
        i_end_date         IN VARCHAR2,
        -- compute dates arguments
        i_flg_timeunit            IN VARCHAR2,
        i_flg_end_by              IN VARCHAR2,
        i_nr_events               IN NUMBER,
        i_repeat_every            IN NUMBER,
        i_weekday                 IN NUMBER,
        i_day_of_month            IN NUMBER,
        i_week                    IN NUMBER,
        i_rep_start_date          IN VARCHAR2,
        i_rep_end_date            IN VARCHAR2,
        i_month                   IN NUMBER,
        i_id_institution          IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_irregular           OUT VARCHAR2,
        o_sch_series_appointments OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SCH_SERIES_APPOINTMENTS';
        --l_flg_irregular  VARCHAR2(1);
        l_computed_dates table_timestamp_tz := table_timestamp_tz();
        l_vacancy_ids    table_number := table_number();
        l_status         table_varchar := table_varchar();
        l_rep_start_date TIMESTAMP WITH TIME ZONE;
        l_rep_end_date   TIMESTAMP WITH TIME ZONE;
    
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    
        l_dt_start TIMESTAMP;
        l_dt_end   TIMESTAMP;
    
        l_start_truncated_date TIMESTAMP WITH TIME ZONE;
        l_end_truncated_date   TIMESTAMP WITH TIME ZONE;
    
        l_days     NUMBER;
        l_hours    NUMBER;
        l_minutes  NUMBER;
        l_seconds  NUMBER;
        l_duration NUMBER;
    
        l_start_hour         VARCHAR2(6) := '000000';
        l_end_hour           VARCHAR2(6) := '000000';
        l_rep_start_date_str VARCHAR2(8);
        l_rep_end_date_str   VARCHAR2(8);
        l_rep_start_dthr_str VARCHAR2(16);
        l_rep_end_dthr_str   VARCHAR2(16) := NULL;
    BEGIN
        l_start_hour := substr(i_start_date, 9, 14);
    
        l_rep_start_date_str := substr(i_rep_start_date, 1, 8);
        l_rep_start_dthr_str := l_rep_start_date_str || l_start_hour;
    
        IF (i_rep_end_date IS NOT NULL)
        THEN
            l_end_hour         := substr(i_end_date, 9, 14);
            l_rep_end_date_str := substr(i_rep_end_date, 1, 8);
            l_rep_end_dthr_str := l_rep_end_date_str || l_end_hour;
        END IF;
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => l_rep_start_dthr_str,
                                             i_timezone  => NULL,
                                             o_timestamp => l_rep_start_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert repeatition start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => l_rep_end_dthr_str,
                                             i_timezone  => NULL,
                                             o_timestamp => l_rep_end_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert start date to timestamp
        /*g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_start_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;*/
    
        /*IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_timestamp => l_start_date,
                                                o_timestamp => l_start_truncated_date,
                                                o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;*/
    
        l_dt_start := to_timestamp(l_rep_start_dthr_str, 'yyyymmddhh24miss');
        l_dt_end   := to_timestamp(l_rep_end_dthr_str, 'yyyymmddhh24miss');
    
        -- Convert end date to timestamp
        /*g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_end_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
        */
        /*IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_timestamp => l_end_date,
                                                o_timestamp => l_end_truncated_date,
                                                o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;*/
    
        -- Calculate duration
        /*IF NOT pk_date_utils.get_timestamp_diff_sep(i_lang        => i_lang,
                                                    i_timestamp_1 => l_start_date,
                                                    i_timestamp_2 => l_start_truncated_date,
                                                    o_days        => l_days,
                                                    o_hours       => l_hours,
                                                    o_minutes     => l_minutes,
                                                    o_seconds     => l_seconds,
                                                    o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;*/
    
        --l_duration := trunc(l_days * 24 + l_hours * 60 + l_minutes + l_seconds / 60);
    
        --l_rep_start_date := pk_date_utils.add_to_ltstz(i_timestamp => l_rep_start_date,i_amount => l_minutes,i_unit => 'MINUTE');
    
        --l_rep_end_date := pk_date_utils.add_to_ltstz(i_timestamp => l_rep_end_date,i_amount => l_minutes,i_unit => 'MINUTE');
    
        -- Step 1
        g_error := 'CALL get_sch_series_dates';
        IF NOT get_sch_series_computed_dates(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_flg_timeunit   => i_flg_timeunit,
                                             i_flg_end_by     => i_flg_end_by,
                                             i_nr_events      => i_nr_events,
                                             i_repeat_every   => i_repeat_every,
                                             i_weekday        => i_weekday,
                                             i_day_of_month   => i_day_of_month,
                                             i_week           => i_week,
                                             i_sch_start_date => l_rep_start_date,
                                             i_sch_end_date   => l_rep_end_date,
                                             i_month          => i_month,
                                             o_dates          => l_computed_dates,
                                             o_flg_irregular  => o_flg_irregular,
                                             o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Para cada reg do array o_dates, chama a val_sch_series_computed_dates (E-Erro BD; S-Sucesso; 
        l_vacancy_ids.extend(l_computed_dates.count);
        l_status.extend(l_computed_dates.count);
        FOR idx IN l_computed_dates.first .. l_computed_dates.last
        LOOP
            l_status(idx) := val_sch_series_computed_dates(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_id_sch_event     => i_id_sch_event,
                                                           i_flg_sch_type     => i_flg_sch_type,
                                                           i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                           i_id_prof          => i_id_prof,
                                                           i_dt_begin         => pk_date_utils.date_send_tsz(i_lang,
                                                                                                             l_computed_dates(idx),
                                                                                                             i_prof),
                                                           i_dt_end           => NULL,
                                                           i_id_institution   => i_id_institution,
                                                           o_vacancy          => l_vacancy_ids(idx),
                                                           o_error            => o_error);
        END LOOP;
    
        -- Verify Vacancies / Conflits 
        g_error := 'OPEN o_sch_series CURSOR';
        OPEN o_sch_series_appointments FOR
            SELECT scv.id_sch_consult_vacancy,
                   --to_char(d.dt_begin, 'YYYYMMDDHH24MISS') dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, d.dt_begin, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, scv.dt_end_tstz, i_prof) dt_end,
                   pk_date_utils.get_day_label(i_lang, i_prof, d.dt_begin) || ', ' ||
                   --to_char(d.dt_begin, g_series_date_format) AS desc_date,
                    pk_date_utils.to_char_insttimezone(i_lang, i_prof, d.dt_begin, g_series_date_format) AS desc_date,
                   --to_char(d.dt_begin, 'HH24:MI') AS desc_hour,
                   pk_date_utils.to_char_insttimezone(i_lang, i_prof, d.dt_begin, 'HH24:MI') AS desc_hour,
                   d.flg_status
              FROM (SELECT dates.dt_begin,
                           dates.index_comp_dates,
                           vacancies.index_vacancy,
                           vacancies.vacancy_id,
                           status.index_status,
                           status.flg_status
                      FROM (SELECT rownum AS index_comp_dates, column_value AS dt_begin
                              FROM TABLE(l_computed_dates)) dates,
                           (SELECT rownum AS index_vacancy, column_value AS vacancy_id
                              FROM TABLE(l_vacancy_ids)) vacancies,
                           (SELECT rownum AS index_status, column_value AS flg_status
                              FROM TABLE(l_status)) status
                     WHERE dates.index_comp_dates = vacancies.index_vacancy
                       AND vacancies.index_vacancy = status.index_status) d,
                   sch_consult_vacancy scv
             WHERE scv.id_sch_consult_vacancy(+) = d.vacancy_id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sch_series_appointments);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_sch_series_appointments;

    -- FUNCTION CANCEL_SCHEDULE_SERIES
    FUNCTION cancel_schedule_series
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_flg_all_series   IN VARCHAR2 DEFAULT 'N',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name               VARCHAR2(30) := 'CANCEL_SCHEDULE_SERIES';
        l_id_sch_series_recursion schedule.id_schedule_recursion%TYPE;
        l_id_schedules            table_number := table_number();
    BEGIN
    
        IF i_flg_all_series = g_yes
        THEN
            g_error := 'SELECT id_schedule_recursion';
            SELECT id_schedule_recursion
              INTO l_id_sch_series_recursion
              FROM schedule
             WHERE id_schedule = i_id_schedule;
        
            g_error := 'COLLECT INTO COLLECTION OF ID_SCHEDULES';
            SELECT sch.id_schedule
              BULK COLLECT
              INTO l_id_schedules
              FROM schedule sch
             WHERE sch.id_schedule_recursion = l_id_sch_series_recursion;
        ELSE
            l_id_schedules.extend;
            l_id_schedules(1) := i_id_schedule;
        END IF;
    
        g_error := 'ITERATE COLLECTION WITH ID_SCHEDULE';
        IF l_id_schedules.count > 0
        THEN
            FOR idx IN l_id_schedules.first .. l_id_schedules.last
            LOOP
                g_error := 'CALL CANCEL_SCHEDULE - ID_SCHEDULE = ' || l_id_schedules(idx);
                IF NOT cancel_schedule(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_schedule      => l_id_schedules(idx),
                                       i_id_cancel_reason => i_id_cancel_reason,
                                       i_cancel_notes     => i_cancel_notes,
                                       o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END LOOP;
        END IF;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_schedule_series;

    -- FUNCTION GET_SCHEDULE_SERIES
    FUNCTION validate_conflict
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_mode        IN NUMBER DEFAULT 1
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30) := 'GET_SCHEDULE_SERIES';
        o_scheds           table_number;
        l_vacancy          sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_id_sch_recursion schedule.id_schedule_recursion%TYPE;
    BEGIN
        g_error := 'SELECT VACANCY';
        SELECT sch.id_sch_consult_vacancy, sch.id_schedule_recursion
          INTO l_vacancy, l_id_sch_recursion
          FROM schedule sch
         WHERE sch.id_schedule = i_id_schedule;
    
        IF (l_vacancy IS NOT NULL)
        THEN
            g_error := 'SELECT SCHEDULES';
            SELECT s.id_schedule
              BULK COLLECT
              INTO o_scheds
              FROM schedule s
             WHERE s.id_sch_consult_vacancy = l_vacancy
               AND s.flg_status <> pk_schedule.g_status_canceled;
        
            IF (i_mode = 1)
            THEN
                IF (o_scheds.count > 1)
                THEN
                    RETURN 'C';
                ELSE
                    RETURN 'S';
                END IF;
            END IF;
        
            IF (i_mode = 2)
            THEN
                IF (o_scheds.count <= 1)
                THEN
                    RETURN 'C';
                ELSIF (l_id_sch_recursion IS NOT NULL)
                THEN
                    RETURN 'O';
                ELSE
                    RETURN 'S';
                END IF;
            
            END IF;
        
        ELSE
            RETURN 'V';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END validate_conflict;

    FUNCTION get_schedule_series
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_sch_series  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SCHEDULE_SERIES';
    BEGIN
        g_error := 'OPEN o_sch_series CURSOR';
        OPEN o_sch_series FOR
            SELECT sch.id_sch_consult_vacancy,
                   sch.id_schedule,
                   pk_date_utils.date_send_tsz(i_lang, sch.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, sch.dt_end_tstz, i_prof) dt_end,
                   pk_date_utils.get_day_label(i_lang, i_prof, sch.dt_begin_tstz) || ', ' ||
                   pk_date_utils.to_char_insttimezone(i_lang, i_prof, sch.dt_begin_tstz, g_series_date_format) AS desc_date,
                   pk_date_utils.date_hourmin_tsz(i_lang, sch.dt_begin_tstz, i_prof.institution, i_prof.software) AS desc_hour,
                   decode(sch.flg_status, pk_schedule.g_sched_status_temporary, g_yes, g_no) AS flg_temporary,
                   validate_conflict(i_lang, i_prof, sch.id_schedule) AS flg_status,
                   sch.id_sch_event,
                   sch.flg_sch_type
              FROM schedule sch
             WHERE sch.id_schedule_recursion =
                   (SELECT s.id_schedule_recursion
                      FROM schedule s
                      JOIN schedule_recursion sr
                        ON s.id_schedule_recursion = sr.id_schedule_recursion
                     WHERE s.id_schedule = i_id_schedule
                       AND sr.flg_type = g_sch_recursion_series)
               AND sch.flg_status != pk_schedule.g_status_canceled
             ORDER BY sch.dt_begin_tstz;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_schedule_series;

    /**
    * Checks if a schedule is part of a serie of appointments.
    *
    * @param   i_id_schedule  Schedule identifier
    *
    * @return  'Y' if the vacancy is available, 'N' otherwise
    *
    * @author  Sofia MEndes
    * @version 2.5.4
    * @since   2009/06/25
    */
    FUNCTION is_series_appointment(i_id_schedule IN schedule.id_schedule%TYPE) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'IS_SERIES_APPOINTMENT';
        l_available VARCHAR2(1) := NULL;
        l_dummy     NUMBER;
    BEGIN
        BEGIN
            SELECT 1
              INTO l_dummy
              FROM schedule s
              JOIN schedule_recursion sr
                ON s.id_schedule_recursion = sr.id_schedule_recursion
             WHERE s.id_schedule = i_id_schedule
               AND s.id_schedule_recursion IS NOT NULL
               AND sr.flg_type = g_sch_recursion_series
               AND rownum = 1;
        
            l_available := g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                l_available := g_no;
        END;
    
        RETURN l_available;
    EXCEPTION
        WHEN OTHERS THEN
            -- Let the caller handle the error
            RAISE;
    END is_series_appointment;

    /**
    * Returns the repeatition patterns of a series appointment ('D','M','S','Y')
    *
    * @param   i_id_schedule  Schedule identifier
    *
    * @return  'Y' if the vacancy is available, 'N' otherwise
    *
    * @author  Sofia MEndes
    * @version 2.5.4
    * @since   2009/06/25
    */
    FUNCTION get_repeatition_pat(i_id_schedule IN schedule.id_schedule%TYPE) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'GET_REPEATITION_PAT';
        l_available VARCHAR2(1) := NULL;
        l_dummy     schedule_recursion.flg_timeunit%TYPE;
    BEGIN
        BEGIN
            SELECT sr.flg_timeunit
              INTO l_dummy
              FROM schedule s
              JOIN schedule_recursion sr
                ON s.id_schedule_recursion = sr.id_schedule_recursion
             WHERE s.id_schedule = i_id_schedule
               AND s.id_schedule_recursion IS NOT NULL
               AND sr.flg_type = pk_schedule.g_sch_recursion_series
               AND rownum = 1;
        
            RETURN l_dummy;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
        RETURN l_available;
    EXCEPTION
        WHEN OTHERS THEN
            -- Let the caller handle the error
            RAISE;
    END get_repeatition_pat;

    /**
    * special create_schedule for single visits. creates an appointment for each detail
    * line of the combination supplied. APPOINTMENTS CAN BE OF VARIOUS SCHEDULING TYPES,
    * BUT ONLY THOSE WITH THE TRADITIONAL VACANCY TYPE, THAT IS, VACANCIES WITHOUT THE 
    * SLOT CONCEPT.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_combi           combination id
    * @param i_ids_codes          comb. detail lines that are to be processed. table_table_number(table_number(id_code, id_vacancy), ...)
    * @param i_ids_patients       patient ids. Its a table number in order to support group appoints.
    * @param i_id_episode         episode id
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     23-06-2009
    *
    * UPDATED: new parameter: i_id_institution
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @date     30-07-2009
    */
    FUNCTION create_schedule_sv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_combi       IN sch_combi.id_sch_combi%TYPE,
        i_ids_codes      IN table_table_number,
        i_ids_patients   IN table_number,
        i_id_episode     IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_institution IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_proceed    OUT VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(32) := 'CREATE_SCHEDULE_SV';
        l_sch_combi_row        sch_combi%ROWTYPE;
        l_sch_combi_detail_row sch_combi_detail%ROWTYPE;
        l_sch_consult_vacancy  sch_consult_vacancy%ROWTYPE;
        i                      INTEGER;
        l_dep_type             sch_event.dep_type%TYPE;
        l_dummy                schedule.id_schedule%TYPE;
        l_create_exception EXCEPTION;
    BEGIN
    
        -- get combi data. if not found all process ends
        g_error := 'GET COMBINATION DATA';
        SELECT *
          INTO l_sch_combi_row
          FROM sch_combi
         WHERE id_sch_combi = i_id_combi;
    
        -- LOOP THROUGH SUPPLIED DETAIL LINES (i_ids_codes) and their vacancies
        g_error := 'LOOP';
        IF i_ids_codes IS NOT NULL
           AND i_ids_codes.count > 0
        THEN
            i := i_ids_codes.first;
            WHILE i IS NOT NULL
            LOOP
                -- get data to feed this create schedule. if not found all process ends
                g_error := 'GET SCH_COMBI_DETAIL ROWTYPE';
                SELECT *
                  INTO l_sch_combi_detail_row
                  FROM sch_combi_detail d
                 WHERE d.id_sch_combi = i_id_combi
                   AND d.id_code = i_ids_codes(i) (1);
            
                l_dep_type := l_sch_combi_detail_row.dep_type;
            
                -- se nao temos dep_type vamos obte-lo pelo id_event
                g_error := 'GET DEP_TYPE FROM SCH_EVENT';
                IF l_dep_type IS NULL
                THEN
                    SELECT dep_type
                      INTO l_dep_type
                      FROM sch_event
                     WHERE id_sch_event = l_sch_combi_detail_row.id_sch_event;
                END IF;
            
                -- obter dados da vaga
                g_error := 'GET VACANCY DATA';
                SELECT *
                  INTO l_sch_consult_vacancy
                  FROM sch_consult_vacancy
                 WHERE id_sch_consult_vacancy = i_ids_codes(i) (2);
            
                -- ISTO SO FUNCIONA PARA AGENDAS COM VAGAS DO TIPO TRADICIONAL
                IF l_dep_type IN (pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                                  pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                                  pk_schedule_common.g_sch_dept_flg_dep_type_nut,
                                  pk_schedule_common.g_sch_dept_flg_dep_type_as)
                THEN
                    IF NOT pk_schedule_outp.create_schedule(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_patient          => i_ids_patients,
                                                            i_id_dep_clin_serv    => l_sch_combi_detail_row.id_dep_clin_serv,
                                                            i_id_sch_event        => l_sch_combi_detail_row.id_sch_event,
                                                            i_id_prof             => l_sch_consult_vacancy.id_prof,
                                                            i_dt_begin            => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                 l_sch_consult_vacancy.dt_begin_tstz,
                                                                                                                 i_prof),
                                                            i_dt_end              => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                 l_sch_consult_vacancy.dt_end_tstz,
                                                                                                                 i_prof),
                                                            i_flg_vacancy         => pk_schedule_common.g_sched_vacancy_routine,
                                                            i_schedule_notes      => NULL,
                                                            i_id_lang_translator  => NULL,
                                                            i_id_lang_preferred   => NULL,
                                                            i_id_reason           => NULL,
                                                            i_id_origin           => NULL,
                                                            i_id_room             => NULL,
                                                            i_id_schedule_ref     => NULL,
                                                            i_id_episode          => i_id_episode,
                                                            i_reason_notes        => NULL,
                                                            i_flg_request_type    => NULL,
                                                            i_flg_schedule_via    => NULL,
                                                            i_do_overlap          => g_yes,
                                                            i_id_consult_vac      => i_ids_codes(i) (2),
                                                            i_sch_option          => g_sch_option_invacancy,
                                                            i_id_consult_req      => NULL,
                                                            i_id_complaint        => NULL,
                                                            i_id_sch_combi_detail => l_sch_combi_detail_row.id_sch_combi_detail,
                                                            i_id_institution      => i_id_institution,
                                                            o_id_schedule         => l_dummy,
                                                            o_flg_proceed         => o_flg_proceed,
                                                            o_flg_show            => o_flg_show,
                                                            o_msg                 => o_msg,
                                                            o_msg_title           => o_msg_title,
                                                            o_button              => o_button,
                                                            o_error               => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                    -- analisar o output de erros da funcao. se tiver erros abortar
                    IF o_flg_show = g_yes
                    THEN
                        RAISE l_create_exception;
                    END IF;
                
                ELSIF l_dep_type IN (pk_schedule_common.g_sch_dept_flg_dep_type_exam,
                                     pk_schedule_common.g_sch_dept_flg_dep_type_oexams)
                THEN
                    IF NOT pk_schedule_exam.create_schedule(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_patient          => CASE
                                                                                    WHEN i_ids_patients IS NULL THEN
                                                                                     NULL
                                                                                    WHEN i_ids_patients.count = 0 THEN
                                                                                     NULL
                                                                                    ELSE
                                                                                     i_ids_patients(1)
                                                                                END,
                                                       i_id_dep_clin_serv    => l_sch_combi_detail_row.id_dep_clin_serv,
                                                       i_id_sch_event        => l_sch_combi_detail_row.id_sch_event,
                                                       i_id_prof             => l_sch_consult_vacancy.id_prof,
                                                       i_dt_begin            => pk_date_utils.date_send_tsz(i_lang,
                                                                                                            l_sch_consult_vacancy.dt_begin_tstz,
                                                                                                            i_prof),
                                                       i_dt_end              => pk_date_utils.date_send_tsz(i_lang,
                                                                                                            l_sch_consult_vacancy.dt_end_tstz,
                                                                                                            i_prof),
                                                       i_flg_vacancy         => pk_schedule_common.g_sched_vacancy_routine,
                                                       i_schedule_notes      => NULL,
                                                       i_id_lang_translator  => NULL,
                                                       i_id_lang_preferred   => NULL,
                                                       i_id_reason           => NULL,
                                                       i_id_origin           => NULL,
                                                       i_id_room             => NULL,
                                                       i_ids_exams           => table_number(l_sch_combi_detail_row.id_exam),
                                                       i_reason_notes        => NULL,
                                                       i_ids_exam_reqs       => NULL,
                                                       i_id_schedule_ref     => NULL,
                                                       i_flg_request_type    => NULL,
                                                       i_flg_schedule_via    => NULL,
                                                       i_do_overlap          => g_yes,
                                                       i_id_consult_vac      => i_ids_codes(i) (2),
                                                       i_sch_option          => g_sch_option_invacancy,
                                                       i_id_episode          => i_id_episode,
                                                       i_id_sch_combi_detail => l_sch_combi_detail_row.id_sch_combi_detail,
                                                       o_id_schedule         => l_dummy,
                                                       o_id_schedule_exam    => l_dummy,
                                                       o_flg_proceed         => o_flg_proceed,
                                                       o_flg_show            => o_flg_show,
                                                       o_msg                 => o_msg,
                                                       o_msg_title           => o_msg_title,
                                                       o_button              => o_button,
                                                       o_error               => o_error)
                    
                    THEN
                        RETURN FALSE;
                    END IF;
                    -- analisar o output de erros da funcao. se tiver erros abortar
                    IF o_flg_show = g_yes
                    THEN
                        RAISE l_create_exception;
                    END IF;
                
                    --          ELSIF i_dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_anls THEN
                
                END IF;
            
                i := i_ids_codes.next(i);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_create_exception THEN
            pk_utils.undo_changes;
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
            RETURN FALSE;
    END create_schedule_sv;

    /**********************************************************************************************
    * Confirm temporary to permanent schedules
    *
    * @i_lang                                Language ID
    * @i_prof                                Profissional array
    * @i_id_schedule                         Schedule IDs to confirm
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Sofia MEndes
    * @version                               2.5.0.4
    * @since                                 2009/07/06
    **********************************************************************************************/
    FUNCTION confirm_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CONFIRM_SCHEDULE';
    BEGIN
        g_error := 'UPDATE SCHEDULE TEMPORARY FLAG';
    
        UPDATE schedule s
           SET s.flg_status = pk_schedule.g_status_scheduled
         WHERE s.id_schedule = i_id_schedule;
    
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
        
    END confirm_schedule;

    -------------------- NOTIFICATIONS
    /**********************************************************************************************
    * Returns a string containig the event nr and the event date/hour.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_schedule_recursion     Schedule recursion id
    *
    * @return                         number
    *                        
    * @author                         Sofia Mendes
    * @version                        2.5.4
    * @since                          2009/06/02
    **********************************************************************************************/
    FUNCTION get_value_date_schedule
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_schedule_recursion IN schedule_recursion.id_schedule_recursion%TYPE
    ) RETURN VARCHAR2 IS
        l_table_sch_dates table_varchar;
        l_ret             VARCHAR2(4000);
        l_event_msg       VARCHAR2(4000);
    BEGIN
    
        SELECT string_date_hm(i_lang, i_prof, s.dt_begin_tstz) AS sched_sess
          BULK COLLECT
          INTO l_table_sch_dates
          FROM schedule s
          JOIN schedule_recursion sr
            ON s.id_schedule_recursion = sr.id_schedule_recursion
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
         WHERE (s.id_sch_event = pk_schedule.g_event_first_med OR s.id_sch_event = pk_schedule.g_event_subs_med)
           AND s.flg_status NOT IN (pk_schedule.g_sched_status_cancelled, pk_schedule.g_sched_status_temporary)
           AND s.id_schedule_recursion = i_schedule_recursion
         ORDER BY s.dt_begin_tstz;
    
        l_event_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SCH_T736');
    
        FOR i IN 1 .. l_table_sch_dates.count
        LOOP
            l_ret := l_ret || l_event_msg || ' ' || i || ' - ' || l_table_sch_dates(i);
            IF i <> l_table_sch_dates.count
            THEN
                l_ret := l_ret || '; ';
            END IF;
        END LOOP;
    
        RETURN l_ret;
    END get_value_date_schedule;

    /**********************************************************************************************
    * Returns a string containig the event nr and the event date/hour.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_schedule_recursion     Schedule recursion id
    *
    * @return                         number
    *                        
    * @author                         Sofia Mendes
    * @version                        2.5.4
    * @since                          2009/06/02
    **********************************************************************************************/
    FUNCTION get_schedule_profs
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule_recursion.id_schedule_recursion%TYPE
    ) RETURN VARCHAR2 IS
        l_profs         pk_types.cursor_type;
        l_ret           VARCHAR2(4000);
        l_error_dummy   t_error_out;
        l_dummy_sch     table_number;
        l_prof_ids      table_number;
        l_prof_spec     table_varchar;
        l_profs_names   table_varchar;
        l_dummy_leader  table_number;
        l_dummy_vacancy table_number;
    BEGIN
    
        IF NOT pk_schedule_common.get_prof_list(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_schedules => table_number(i_id_schedule),
                                                o_prof_list => l_profs,
                                                o_error     => l_error_dummy)
        THEN
            RETURN '';
        END IF;
    
        FETCH l_profs BULK COLLECT
            INTO l_dummy_sch, l_prof_ids, l_profs_names, l_prof_spec, l_dummy_leader, l_dummy_vacancy;
        CLOSE l_profs;
    
        FOR i IN 1 .. l_profs_names.count
        LOOP
            l_ret := l_ret || l_profs_names(i);
            IF i <> l_profs_names.count
            THEN
                l_ret := l_ret || '; ';
            END IF;
        END LOOP;
    
        RETURN l_ret;
    END get_schedule_profs;

    /**********************************************************************************************
    * Returns the number of scheduled events in a given serie: format: nr scheduled events/total nr of events
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_interv_presc_det       Intervention's ID
    *
    * @return                         number
    *                        
    * @author                         Sofia Mendes
    * @version                        2.5.4
    * @since                          2009/06/02
    **********************************************************************************************/
    FUNCTION get_num_events_schedule
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_schedule_recursion IN schedule.id_schedule_recursion%TYPE
    ) RETURN VARCHAR2 IS
        l_result_sch PLS_INTEGER := 0;
        l_result_all PLS_INTEGER := 0;
    BEGIN
        --scheduled events
        SELECT COUNT(s.id_schedule)
          INTO l_result_sch
          FROM schedule s
          JOIN schedule_recursion sr
            ON s.id_schedule_recursion = sr.id_schedule_recursion
         WHERE s.id_schedule_recursion = i_id_schedule_recursion
           AND s.flg_status NOT IN (pk_schedule.g_sched_status_cancelled, pk_schedule.g_sched_status_temporary)
           AND sr.flg_type = pk_schedule.g_sch_recursion_series;
    
        --all events
        SELECT COUNT(s.id_schedule)
          INTO l_result_all
          FROM schedule s
          JOIN schedule_recursion sr
            ON s.id_schedule_recursion = sr.id_schedule_recursion
         WHERE s.id_schedule_recursion = i_id_schedule_recursion
           AND s.flg_status NOT IN (pk_schedule.g_sched_status_cancelled)
           AND sr.flg_type = pk_schedule.g_sch_recursion_series;
        RETURN l_result_sch || '/' || l_result_all;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END get_num_events_schedule;

    /**********************************************************************************************
    * Auxiliary function to get details on prescription schedule (private function)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_schedule_intervention  Schedule ID
    * @param i_code                   Code corresponding to data
    *
    * @return                         VARCHAR2 with the data
    *                        
    * @author                         Sofia Mendes (adaptaÁ„o da funÁ„o pk_schedule_mfr.get_value_det_schedule)
    * @version                        2.5.4
    * @since                          2009/07/07
    **********************************************************************************************/
    FUNCTION get_value_det_schedule
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_schedule_intervention IN VARCHAR2,
        i_code                  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_temp                  VARCHAR2(4000);
        l_schedule_intervention table_varchar2;
        l_table_ret             table_varchar2;
        l_ret                   VARCHAR2(4000);
    BEGIN
        g_error := 'SORT VALUES';
        IF substr(i_schedule_intervention, 0, 1) = 'C'
        THEN
            l_temp := substr(i_schedule_intervention, 3);
        ELSE
            l_temp := i_schedule_intervention;
        END IF;
    
        SELECT column_value
          BULK COLLECT
          INTO l_schedule_intervention
          FROM TABLE(pk_utils.str_split(l_temp, '|'))
         WHERE column_value IS NOT NULL
         ORDER BY column_value ASC;
    
        CASE i_code
        -- Sessıes agendadas
            WHEN 'PROCEDURES_MFR_T075' THEN
                SELECT decode(s.flg_status,
                              g_flg_status_sched_c,
                              NULL,
                              '(' ||
                              pk_schedule_mfr.get_count_and_rank(i_lang, si.id_schedule, NULL, si.id_interv_presc_det) || ') ') ||
                       string_date_hm(i_lang, i_prof, s.dt_begin_tstz) AS sess
                  BULK COLLECT
                  INTO l_table_ret
                  FROM schedule s, schedule_intervention si, TABLE(l_schedule_intervention) lsi
                 WHERE s.id_schedule = si.id_schedule
                   AND si.id_schedule_intervention = CAST(lsi.column_value AS NUMBER);
            
                FOR i IN 1 .. l_table_ret.count
                LOOP
                    l_ret := l_ret || l_table_ret(i);
                    IF i <> l_table_ret.count
                    THEN
                        l_ret := l_ret || '; ';
                    END IF;
                END LOOP;
                -- Terapeuta
            WHEN 'PROCEDURES_MFR_M031' THEN
                SELECT DISTINCT pk_prof_utils.get_nickname(i_lang, si.id_prof_assigned)
                  INTO l_ret
                  FROM schedule_intervention si, TABLE(l_schedule_intervention) lsi
                 WHERE si.id_schedule_intervention = CAST(lsi.column_value AS NUMBER);
            
            ELSE
                NULL;
        END CASE;
        RETURN l_ret;
    END get_value_det_schedule;

    /**********************************************************************************************
    * Returns data of a mfr serie (to be used on notifications)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_tab_id_schedule        Schedule IDs table
    * @param o_error                         error object
    *
    * @return                         TRUE/FALSE
    *                        
    * @author                         Sofia Mendes 
    * @version                        2.5.4
    * @since                          2009/07/03
    **********************************************************************************************/
    FUNCTION get_notifications_mfr
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_NOTIFICATIONS_MFR';
        l_session      sys_message.desc_message%TYPE;
        l_sessions     sys_message.desc_message%TYPE;
        l_nonavailable sys_message.desc_message%TYPE;
    
    BEGIN
        l_session      := pk_message.get_message(i_lang, 'PROCEDURES_MFR_T065');
        l_sessions     := pk_message.get_message(i_lang, 'PROCEDURES_MFR_T066');
        l_nonavailable := pk_message.get_message(i_lang, 'N/A');
    
        -- Insert prescription details into a temporary table
        g_error := 'OPEN CURSOR - PRESCRIPTION DETAILS';
        INSERT INTO sch_tmptab_notifs
            SELECT pk_translation.get_translation(i_lang, ra.code_rehab_area) desc_sch_type,
                   pk_translation.get_translation(i_lang, i.code_intervention) desc_procedure,
                   pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_T162') || ':' msg_num_sched,
                   (SELECT COUNT(1)
                      FROM rehab_schedule
                     WHERE id_rehab_sch_need = rsn.id_rehab_sch_need
                       AND flg_status <> 'C') || '/' || rsn.sessions || ' ' ||
                   decode(rsn.sessions, 1, l_session, l_sessions) num_sched,
                   
                   pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_T075') || ':' msg_sched_sess,
                   pk_schedule_mfr.get_rank_and_count(i_lang, i_prof, s.id_schedule) sched_sess,
                   NULL AS msg_consult_type,
                   NULL AS consult_type,
                   NULL AS msg_event_type,
                   NULL AS event_type,
                   pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_T071') || ':' msg_prof,
                   CASE
                        WHEN rs.id_professional IS NOT NULL THEN
                         pk_prof_utils.get_name_signature(i_lang, i_prof, rs.id_professional)
                        WHEN rg.id_professional IS NOT NULL THEN
                         pk_prof_utils.get_name_signature(i_lang, i_prof, rg.id_professional)
                    END prof,
                   NULL AS msg_instructions,
                   NULL AS instructions,
                   rp.id_rehab_presc AS id_not,
                   g_notif_mfr AS flg_type,
                   s.id_instit_requested AS id_institution,
                   2 AS order_nr,
                   s.flg_sch_type,
                   '' exams
              FROM schedule s
              JOIN rehab_schedule rs
                ON s.id_schedule = rs.id_schedule
              JOIN rehab_sch_need rsn
                ON rs.id_rehab_sch_need = rsn.id_rehab_sch_need
              JOIN rehab_presc rp
                ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
              JOIN rehab_area_interv rai
                ON rp.id_rehab_area_interv = rai.id_rehab_area_interv
              JOIN rehab_area ra
                ON rai.id_rehab_area = ra.id_rehab_area
              JOIN intervention i
                ON rai.id_intervention = i.id_intervention
              LEFT JOIN sch_rehab_group srg
                ON s.id_schedule = srg.id_schedule
              LEFT JOIN rehab_group rg
                ON srg.id_rehab_group = rg.id_rehab_group
             WHERE s.id_schedule IN (SELECT column_value
                                       FROM TABLE(i_tab_id_schedule))
               AND rs.flg_status <> 'C'
               AND s.flg_status <> pk_schedule.g_status_canceled
               AND rp.flg_status <> 'C';
        /*
                    SELECT pk_interv_mfr.get_physiatry_area(i_lang, pea.id_intervention) desc_sch_type,
                           pk_translation.get_translation(i_lang, pea.code_intervention_alias) desc_procedure,
                           pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_T162') || ':' msg_num_sched,
                           pk_interv_mfr.get_num_sessions_schedule(i_lang, i_prof, pea.id_interv_presc_det) || '/' ||
                           pea.num_take || ' ' || decode(pea.num_take, 1, l_session, l_sessions) num_sched,
                           pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_T075') || ':' msg_sched_sess,
                           get_value_det_schedule(i_lang,
                                                  i_prof,
                                                  concatenate(si.id_schedule_intervention || '|'),
                                                  'PROCEDURES_MFR_T075') sched_sess,
                           NULL AS msg_consult_type,
                           NULL AS consult_type,
                           NULL AS msg_event_type,
                           NULL AS event_type,
                           pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_T071') || ':' msg_prof,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, si.id_prof_assigned) prof,
                           NULL AS msg_instructions,
                           NULL AS instructions,
                           si.id_interv_presc_det AS id_not,
                           g_notif_mfr AS flg_type,
                           s.id_instit_requested AS id_institution,
                           2 AS order_nr,
                           s.flg_sch_type,
                           '' exams
                      FROM procedures_ea pea, schedule_intervention si, schedule s
                     WHERE pea.id_interv_presc_det = si.id_interv_presc_det
                       AND si.id_schedule = s.id_schedule
                       AND s.id_schedule IN (SELECT column_value
                                               FROM TABLE(i_tab_id_schedule))
                     GROUP BY pea.id_intervention,
                              si.id_interv_presc_det,
                              pea.code_intervention_alias,
                              pea.id_interv_presc_det,
                              pea.num_take,
                              si.id_prof_assigned,
                              s.id_instit_requested,
                              s.flg_sch_type;
        */
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
            RETURN FALSE;
    END get_notifications_mfr;

    /**********************************************************************************************
    * Returns data of a serie (to be used on notifications)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_tab_id_schedule        Schedule IDs table
    * @param o_error                         error object
    *
    * @return                         TRUE/FALSE
    *                        
    * @author                         Sofia Mendes 
    * @version                        2.5.4
    * @since                          2009/07/03
    **********************************************************************************************/
    FUNCTION get_notifications_series
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_NOTIFICATIONS_SERIES';
    BEGIN
        g_error := 'OPEN CURSOR O_DATA';
        INSERT INTO sch_tmptab_notifs
            SELECT pk_translation.get_translation(i_lang, sdt.code_dep_type) AS desc_sch_type,
                   NULL AS desc_procedure,
                   pk_message.get_message(i_lang, 'SCH_T731') AS msg_num_sched,
                   pk_schedule.get_num_events_schedule(i_lang, i_prof, s.id_schedule_recursion) || ' ' ||
                   pk_message.get_message(i_lang, 'SCH_T733') AS num_sched,
                   pk_message.get_message(i_lang, 'SCH_T730') AS msg_sched_sess,
                   pk_schedule.get_value_date_schedule(i_lang, i_prof, s.id_schedule_recursion) AS sched_sess,
                   pk_message.get_message(i_lang, 'SCH_T737') AS msg_consult_type,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) AS consult_type,
                   pk_message.get_message(i_lang, 'SCH_T741') AS msg_event_type,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) AS event_type,
                   pk_message.get_message(i_lang, 'SCH_T742') AS msg_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, srs.id_professional) AS prof,
                   NULL AS msg_instructions,
                   NULL AS instructions,
                   s.id_schedule_recursion AS id_not,
                   g_notif_series AS flg_type,
                   s.id_instit_requested AS id_institution,
                   3 AS order_nr,
                   s.flg_sch_type,
                   '' exams
              FROM schedule s
              JOIN schedule_recursion sr
                ON s.id_schedule_recursion = sr.id_schedule_recursion
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              JOIN sch_dep_type sdt
                ON sdt.dep_type = se.dep_type
              JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = s.id_dcs_requested
              JOIN clinical_service cs
                ON cs.id_clinical_service = dcs.id_clinical_service
              JOIN sch_resource srs
                ON s.id_schedule = srs.id_schedule
             WHERE s.flg_status NOT IN (pk_schedule.g_sched_status_cancelled, pk_schedule.g_sched_status_temporary)
               AND s.id_schedule_recursion IN
                   (SELECT s1.id_schedule_recursion
                      FROM schedule s1
                     WHERE s1.id_schedule IN (SELECT column_value
                                                FROM TABLE(i_tab_id_schedule)))
             GROUP BY s.id_schedule_recursion,
                      se.code_sch_event,
                      cs.code_clinical_service,
                      srs.id_professional,
                      sdt.code_dep_type,
                      s.id_instit_requested,
                      s.flg_sch_type;
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
            RETURN FALSE;
    END get_notifications_series;

    /**********************************************************************************************
    * Returns data of schedule (not series nor mfr) (to be used on notifications)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_tab_id_schedule        Schedule IDs table
    * @param o_error                         error object
    *
    * @return                         TRUE/FALSE
    *                        
    * @author                         Sofia Mendes 
    * @version                        2.5.4
    * @since                          2009/07/03
    **********************************************************************************************/
    FUNCTION get_notifications_general
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_NOTIFICATIONS_GENERAL';
    BEGIN
        g_error := 'OPEN CURSOR O_DATA';
        INSERT INTO sch_tmptab_notifs
            SELECT pk_translation.get_translation(i_lang, sdt.code_dep_type) AS desc_sch_type,
                   get_procedure_name(i_lang, i_prof, s.id_schedule, s.flg_sch_type, s.id_sch_event, s.id_dcs_requested) desc_procedure,
                   NULL AS msg_num_sched,
                   NULL AS num_sched,
                   pk_message.get_message(i_lang, 'SCH_T730') AS msg_sched_sess,
                   string_date_hm(i_lang, i_prof, s.dt_begin_tstz) AS sched_sess,
                   pk_message.get_message(i_lang, 'SCH_T737') AS msg_consult_type,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) AS consult_type,
                   pk_message.get_message(i_lang, 'SCH_T741') AS msg_event_type,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) AS event_type,
                   pk_message.get_message(i_lang, 'SCH_T742') AS msg_prof,
                   pk_schedule.get_schedule_profs(i_lang, i_prof, s.id_schedule) AS prof,
                   pk_message.get_message(i_lang, 'SCH_T743') AS msg_instructions,
                   er.notes_patient AS instructions,
                   s.id_schedule AS id_not,
                   g_notif_others AS flg_type,
                   s.id_instit_requested AS id_institution,
                   rownum AS order_nr,
                   s.flg_sch_type AS flg_sch_type,
                   pk_schedule_exam.get_schedule_exams(i_lang, i_prof, s.id_schedule) exams
              FROM schedule s
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              JOIN sch_dep_type sdt
                ON sdt.dep_type = se.dep_type
              JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = s.id_dcs_requested
              JOIN clinical_service cs
                ON cs.id_clinical_service = dcs.id_clinical_service
            --LEFT JOIN schedule_exam sex ON s.id_schedule = sex.id_schedule
              LEFT JOIN exam_req er
                ON s.id_schedule = er.id_schedule
             WHERE s.id_schedule IN (SELECT column_value
                                       FROM TABLE(i_tab_id_schedule));
    
        /*
                    INSERT INTO sch_tmptab_notifs
                    SELECT pk_interv_mfr.get_physiatry_area(i_lang, pea.id_intervention) desc_sch_type,         <-- dif
                           pk_translation.get_translation(i_lang, pea.code_intervention_alias) desc_procedure,  <-- dif
                           pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_T162') || ':' msg_num_sched,
                           pk_interv_mfr.get_num_sessions_schedule(i_lang, i_prof, pea.id_interv_presc_det) || '/' ||
                           pea.num_take || ' ' || decode(pea.num_take, 1, l_session, l_sessions) num_sched,
                           pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_T075') || ':' msg_sched_sess,
                           get_value_det_schedule(i_lang,
                                                  i_prof,
                                                  concatenate(si.id_schedule_intervention || '|'),
                                                  'PROCEDURES_MFR_T075') sched_sess,
                           NULL AS msg_consult_type,
                           NULL AS consult_type,
                           NULL AS msg_event_type,
                           NULL AS event_type,
                           pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_T071') || ':' msg_prof,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, si.id_prof_assigned) prof,
                           NULL AS msg_instructions,
                           NULL AS instructions,
                           si.id_interv_presc_det AS id_not,
                           g_notif_mfr AS flg_type,
                           s.id_instit_requested AS id_institution,
                           2 AS order_nr,
                           s.flg_sch_type,
                           '' exams
                      FROM procedures_ea pea, schedule_intervention si, schedule s
                     WHERE pea.id_interv_presc_det = si.id_interv_presc_det
                       AND si.id_schedule = s.id_schedule
                       AND s.id_schedule IN (SELECT column_value
                                               FROM TABLE(i_tab_id_schedule))
                     GROUP BY pea.id_intervention,
                              si.id_interv_presc_det,
                              pea.code_intervention_alias,
                              pea.id_interv_presc_det,
                              pea.num_take,
                              si.id_prof_assigned,
                              s.id_instit_requested,
                              s.flg_sch_type;
        */
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
            RETURN FALSE;
    END get_notifications_general;

    /**********************************************************************************************
    * Returns schedule ids acoording to the input search criterias
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_id_patient             Patient id
    * @param i_tab_id_sch_event       SCH_events tab
    * @param i_has_recursion          Indicates if there is a serie
    * @param i_id_flg_notification    Notification flag
    * @param i_id_schedule_actual     Schedule id
    * @param o_tab_id_schedules       Output table with the schedule ids
    * @param o_error                  error object
    *
    * @return                         TRUE/FALSE
    *                        
    * @author                         Sofia Mendes 
    * @version                        2.5.4
    * @since                          2009/07/03
    **********************************************************************************************/
    FUNCTION get_schedules_ids
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_tab_id_sch_event    IN table_number,
        i_has_recursion       IN VARCHAR2 DEFAULT g_no,
        i_id_flg_notification IN schedule.flg_notification%TYPE,
        i_id_schedule_actual  IN schedule.id_schedule%TYPE,
        i_excluded_event      IN schedule.id_sch_event%TYPE DEFAULT NULL,
        o_tab_id_schedules    OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'GET_SCHEDULES_IDS';
        l_id_schedule_recursion schedule.id_schedule_recursion%TYPE := NULL;
    BEGIN
    
        SELECT s.id_schedule_recursion
          INTO l_id_schedule_recursion
          FROM schedule s
         WHERE s.id_schedule = i_id_schedule_actual;
    
        g_error := 'SELECT SCHEDULES IDS: ' || i_id_flg_notification;
        SELECT s.id_schedule
          BULK COLLECT
          INTO o_tab_id_schedules
          FROM schedule s
          JOIN sch_group sg
            ON s.id_schedule = sg.id_schedule
         WHERE s.flg_status NOT IN (pk_schedule.g_sched_status_cancelled, pk_schedule.g_sched_status_temporary)
           AND s.flg_notification = i_id_flg_notification
           AND ((i_excluded_event IS NULL AND
               (s.id_sch_event IN (SELECT column_value
                                       FROM TABLE(i_tab_id_sch_event)) OR
               (i_tab_id_sch_event IS NULL AND s.id_schedule_recursion IS NULL))) OR
               s.id_sch_event != i_excluded_event)
           AND (i_has_recursion = g_no OR (i_has_recursion = g_yes AND s.id_schedule_recursion IS NOT NULL))
           AND sg.id_patient = i_id_patient
           AND s.id_schedule <> i_id_schedule_actual
           AND (s.id_schedule_recursion <> l_id_schedule_recursion OR l_id_schedule_recursion IS NULL OR
               s.id_schedule_recursion IS NULL)
           AND s.dt_begin_tstz > current_timestamp;
    
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
            RETURN FALSE;
    END get_schedules_ids;

    /**********************************************************************************************
    * Returns data of the confimed or not confirmed schedules
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_id_patient             Patient id    
    * @param i_id_flg_notification    Notification flag
    * @param i_id_schedule_actual     Schedule id    
    * @param o_error                  error object
    *
    * @return                         TRUE/FALSE
    *                        
    * @author                         Sofia Mendes 
    * @version                        2.5.4
    * @since                          2009/07/03
    **********************************************************************************************/
    FUNCTION get_conf_pend_schs
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_flg_notification IN schedule.flg_notification%TYPE,
        i_id_schedule_actual  IN schedule.id_schedule%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := 'get_conf_pend_schs';
        l_tab_id_schedules table_number;
    BEGIN
        DELETE FROM sch_tmptab_notifs;
        --get mfr pending or confirmed schedules
        g_error := 'get mfr schedules' || i_id_flg_notification;
        IF NOT get_schedules_ids(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_id_patient          => i_id_patient,
                                 i_tab_id_sch_event    => table_number(pk_schedule.g_event_mfr),
                                 i_has_recursion       => g_no,
                                 i_id_flg_notification => i_id_flg_notification,
                                 i_id_schedule_actual  => i_id_schedule_actual,
                                 o_tab_id_schedules    => l_tab_id_schedules,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_NOTIFICATIONS_MFR for ' || i_id_flg_notification;
        IF NOT get_notifications_mfr(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_tab_id_schedule => l_tab_id_schedules,
                                     o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --get series pending  or confirmed schedules
        g_error := 'get series schedules ' || i_id_flg_notification;
        IF NOT get_schedules_ids(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_id_patient          => i_id_patient,
                                 i_tab_id_sch_event    => NULL,
                                 i_has_recursion       => g_yes,
                                 i_id_flg_notification => i_id_flg_notification,
                                 i_id_schedule_actual  => i_id_schedule_actual,
                                 i_excluded_event      => pk_schedule.g_event_mfr,
                                 o_tab_id_schedules    => l_tab_id_schedules,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_notifications_series for schedules ' || i_id_flg_notification;
        IF NOT get_notifications_series(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_tab_id_schedule => l_tab_id_schedules,
                                        o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --get other pending  or confirmed schedules
        g_error := 'get other schedules ' || i_id_flg_notification;
        IF NOT get_schedules_ids(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_id_patient          => i_id_patient,
                                 i_tab_id_sch_event    => NULL,
                                 i_has_recursion       => g_no,
                                 i_id_flg_notification => i_id_flg_notification,
                                 i_id_schedule_actual  => i_id_schedule_actual,
                                 o_tab_id_schedules    => l_tab_id_schedules,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_notifications_general for schedules ' || i_id_flg_notification;
        IF NOT get_notifications_general(i_lang            => i_lang,
                                         i_prof            => i_prof,
                                         i_tab_id_schedule => l_tab_id_schedules,
                                         o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
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
            RETURN FALSE;
    END get_conf_pend_schs;

    FUNCTION get_conf_pend_schs2
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_flg_notification IN schedule.flg_notification%TYPE,
        i_id_schedule_actual  IN schedule.id_schedule%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := 'get_conf_pend_schs';
        l_tab_id_schedules table_number;
    BEGIN
        --get mfr pending or confirmed schedules
        g_error := 'get mfr schedules' || i_id_flg_notification;
        IF NOT get_schedules_ids(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_id_patient          => i_id_patient,
                                 i_tab_id_sch_event    => table_number(pk_schedule.g_event_mfr),
                                 i_has_recursion       => g_no,
                                 i_id_flg_notification => i_id_flg_notification,
                                 i_id_schedule_actual  => i_id_schedule_actual,
                                 o_tab_id_schedules    => l_tab_id_schedules,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_NOTIFICATIONS_MFR for ' || i_id_flg_notification;
        IF NOT get_notifications_mfr(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_tab_id_schedule => l_tab_id_schedules,
                                     o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --get series pending  or confirmed schedules
        g_error := 'get series schedules ' || i_id_flg_notification;
        IF NOT get_schedules_ids(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_id_patient          => i_id_patient,
                                 i_tab_id_sch_event    => NULL,
                                 i_has_recursion       => g_yes,
                                 i_id_flg_notification => i_id_flg_notification,
                                 i_id_schedule_actual  => i_id_schedule_actual,
                                 i_excluded_event      => pk_schedule.g_event_mfr,
                                 o_tab_id_schedules    => l_tab_id_schedules,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_notifications_series for schedules ' || i_id_flg_notification;
        IF NOT get_notifications_series(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_tab_id_schedule => l_tab_id_schedules,
                                        o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --get other pending  or confirmed schedules
        g_error := 'get other schedules ' || i_id_flg_notification;
        IF NOT get_schedules_ids(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_id_patient          => i_id_patient,
                                 i_tab_id_sch_event    => NULL,
                                 i_has_recursion       => g_no,
                                 i_id_flg_notification => i_id_flg_notification,
                                 i_id_schedule_actual  => i_id_schedule_actual,
                                 o_tab_id_schedules    => l_tab_id_schedules,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_notifications_general for schedules ' || i_id_flg_notification;
        IF NOT get_notifications_general(i_lang            => i_lang,
                                         i_prof            => i_prof,
                                         i_tab_id_schedule => l_tab_id_schedules,
                                         o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
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
            RETURN FALSE;
    END get_conf_pend_schs2;

    /**********************************************************************************************
    * Fetch the screen information about procedures' schedule
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional's details
    * @param i_id_schedule              Schedule identification
    * @param i_id_patient               PAtient identification
    * @param o_domain                   tipo de valores para as notificacoes
    * @param o_actual_event             Cursor with the actual event data   
    * @param o_to_notify                Cursor with the events to be notified  
    * @param o_notified                 Cursor with the notified events
    * @param o_error                    Error message
    *
    * @return                           TRUE if success, FALSE otherwise
    *                        
    * @author                           Sofia Mendes
    * @version                          2.5.4
    * @since                            2009/07/02
    **********************************************************************************************/
    FUNCTION get_notifications
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        i_id_patient   IN sch_group.id_patient%TYPE,
        o_domain       OUT pk_types.cursor_type,
        o_actual_event OUT pk_types.cursor_type,
        o_to_notify    OUT pk_types.cursor_type,
        o_notified     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := 'GET_NOTIFICATIONS';
        l_schedule_event   schedule.id_sch_event%TYPE;
        l_tab_id_schedules table_number;
    
    BEGIN
        g_error := 'SELECT SCHEDULE EVENT';
        SELECT s.id_sch_event
          INTO l_schedule_event
          FROM schedule s
          JOIN sch_group sg
            ON s.id_schedule = sg.id_schedule
         WHERE s.id_schedule = i_id_schedule
           AND sg.id_patient = i_id_patient;
    
        -- ACTUAL EVENT
        DELETE FROM sch_tmptab_notifs;
        IF (l_schedule_event = pk_schedule.g_event_mfr)
        THEN
            -- call mfr function
            g_error := 'CALL GET_NOTIFICATIONS_MFR';
            IF NOT get_notifications_mfr(i_lang            => i_lang,
                                         i_prof            => i_prof,
                                         i_tab_id_schedule => table_number(i_id_schedule),
                                         o_error           => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSIF (pk_schedule.is_series_appointment(i_id_schedule => i_id_schedule) = g_yes)
        THEN
            --call series function
            g_error := 'CALL GET_NOTIFICATIONS_SERIES';
            IF NOT get_notifications_series(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_tab_id_schedule => table_number(i_id_schedule),
                                            o_error           => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL get_notifications_general';
            IF NOT get_notifications_general(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_tab_id_schedule => table_number(i_id_schedule),
                                             o_error           => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'OPEN cursor o_actual_event';
        OPEN o_actual_event FOR
            SELECT t.*
              FROM sch_tmptab_notifs t
             ORDER BY order_nr;
    
        -- PENDING EVENTS
        g_error := 'CALL get_conf_pend_schs for pending schedules';
        IF NOT get_conf_pend_schs(i_lang                => i_lang,
                                  i_prof                => i_prof,
                                  i_id_patient          => i_id_patient,
                                  i_id_flg_notification => pk_schedule.g_sched_flg_notif_pending,
                                  i_id_schedule_actual  => i_id_schedule,
                                  o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR o_to_notify';
        OPEN o_to_notify FOR
            SELECT t.*
              FROM sch_tmptab_notifs t
             ORDER BY order_nr;
    
        -- CONFIRMED EVENTS
        g_error := 'CALL get_conf_pend_schs for confirmed schedules';
        IF NOT get_conf_pend_schs(i_lang                => i_lang,
                                  i_prof                => i_prof,
                                  i_id_patient          => i_id_patient,
                                  i_id_flg_notification => pk_schedule.g_sched_flg_notif_notified,
                                  i_id_schedule_actual  => i_id_schedule,
                                  o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR o_notified';
        OPEN o_notified FOR
            SELECT t.*
              FROM sch_tmptab_notifs t
             ORDER BY order_nr;
    
        -- Fetch the possible ways of notifying a patient
        g_error := 'OPEN CURSOR - NOTIFICATION VIA';
        OPEN o_domain FOR
            SELECT sd.img_name icon, sd.desc_val description, sd.rank rank, sd.val val
              FROM sys_domain sd
             WHERE sd.code_domain = pk_schedule.g_notification_via
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
             ORDER BY sd.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_domain);
            pk_types.open_my_cursor(o_actual_event);
            pk_types.open_my_cursor(o_to_notify);
            pk_types.open_my_cursor(o_notified);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_notifications;

    /**
    * Set schedule notification to all the schedules associated to a serie.
    *
    * @param    i_lang                     Language
    * @param    i_prof                     Professional
    * @param    i_id_schedule_recursion    Schedule recursion identification (identifies a serie of appointments)
    * @param    i_notification             Notification flag
    * @param    i_flg_not_via              Notification via
    * @param    o_error                    Error message if something goes wrong
    *
    * @author  Sofia Mendes
    * @version 2.5.0.4
    * @since   2009/07/03    
    */
    /*    FUNCTION set_notification_series
        (
            i_lang                  IN LANGUAGE.id_language%TYPE,
            i_prof                  IN profissional,
            i_id_schedule_recursion IN schedule.id_schedule_recursion%TYPE,
            i_flg_notification      IN schedule.flg_notification%TYPE,
            i_flg_not_via           IN schedule.flg_schedule_via%TYPE,
            o_error                 OUT t_error_out
        ) RETURN BOOLEAN IS
            l_flg_notification schedule.flg_notification%TYPE;
            l_flg_status       schedule.flg_status%TYPE;
            l_func_name        VARCHAR2(32) := 'SET_NOTIFICATION_SERIES';
            l_tab_id_schedules table_number;
        BEGIN
            g_error := 'SELECT id_schedules';
            SELECT s.id_schedule BULK COLLECT
              INTO l_tab_id_schedules
              FROM schedule s
             WHERE s.id_schedule_recursion = i_id_schedule_recursion
               AND s.flg_status NOT IN (pk_schedule.g_sched_status_cancelled, pk_schedule.g_sched_status_temporary)
               AND s.flg_notification = pk_schedule.g_sched_flg_notif_pending;
        
            FOR i IN l_tab_id_schedules.FIRST .. l_tab_id_schedules.LAST
            LOOP
                g_error := 'series iteration: ' || l_tab_id_schedules(i);
                IF NOT set_schedule_notification(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_id_schedule   => l_tab_id_schedules(i),
                                                 i_notification  => i_flg_notification,
                                                 i_flg_notif_via => i_flg_not_via,
                                                 o_error         => o_error)
                THEN
                    ROLLBACK;
                    RETURN TRUE;
                END IF;
            END LOOP;
        
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
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
        END set_notification_series;
    */
    FUNCTION set_notification_series
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_schedule_recursion IN schedule.id_schedule_recursion%TYPE,
        i_flg_notification      IN schedule.flg_notification%TYPE,
        i_flg_not_via           IN schedule.flg_schedule_via%TYPE,
        i_transaction_id        IN VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_notification schedule.flg_notification%TYPE;
        l_flg_status       schedule.flg_status%TYPE;
        l_func_name        VARCHAR2(32) := 'SET_NOTIFICATION_SERIES';
        l_tab_id_schedules table_number;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'SELECT id_schedules';
        SELECT s.id_schedule
          BULK COLLECT
          INTO l_tab_id_schedules
          FROM schedule s
         WHERE s.id_schedule_recursion = i_id_schedule_recursion
           AND s.flg_status NOT IN (pk_schedule.g_sched_status_cancelled, pk_schedule.g_sched_status_temporary)
           AND s.flg_notification = pk_schedule.g_sched_flg_notif_pending;
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        FOR i IN l_tab_id_schedules.first .. l_tab_id_schedules.last
        LOOP
            g_error := 'series iteration: ' || l_tab_id_schedules(i);
            IF NOT set_schedule_notification(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_id_schedule    => l_tab_id_schedules(i),
                                             i_notification   => i_flg_notification,
                                             i_flg_notif_via  => i_flg_not_via,
                                             i_transaction_id => l_transaction_id,
                                             o_error          => o_error)
            THEN
                ROLLBACK;
                RETURN TRUE;
            END IF;
        END LOOP;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
        RETURN TRUE;
    
        pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
        pk_utils.undo_changes;
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_notification_series;

    /**
    * Set schedule notification.
    *
    * @param    i_lang           Language
    * @param    i_prof           Professional
    * @param    i_id_schedule    Schedule identification
    * @param    i_notification   Notification flag
    * @param    o_error           Error message if something goes wrong
    *
    * @author  Sofia Mendes
    * @version 2.5.0.4
    * @since   2009/07/03    
    */
    /*    FUNCTION set_notifications
        (
            i_lang             IN LANGUAGE.id_language%TYPE,
            i_prof             IN profissional,
            i_tab_id_nots      IN table_number,
            i_tab_types        IN table_varchar,
            i_flg_notification IN schedule.flg_notification%TYPE,
            i_flg_not_via      IN schedule.flg_schedule_via%TYPE,
            o_error            OUT t_error_out
        ) RETURN BOOLEAN IS
            l_flg_notification schedule.flg_notification%TYPE;
            l_flg_status       schedule.flg_status%TYPE;
            l_func_name        VARCHAR2(32) := 'SET_NOTIFICATIONS';
        BEGIN
            FOR i IN i_tab_id_nots.FIRST .. i_tab_id_nots.LAST
            LOOP
                g_error := 'ITERATION - id ' || i_tab_id_nots(i) || ' type: ' || i_tab_types(i);
                IF (i_tab_types(i) = g_notif_mfr)
                THEN
                    g_error := 'CALL set_schedule_notification';
                    IF NOT pk_schedule_mfr.set_schedule_notification(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_id_interv_presc_det => table_number(i_tab_id_nots(i)),
                                                                     i_flg_notif           => i_flg_notification,
                                                                     i_flg_notif_via       => i_flg_not_via,
                                                                     o_error               => o_error)
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                
                ELSIF (i_tab_types(i) = g_notif_series)
                THEN
                    g_error := 'CALL set_notification_series';
                    IF NOT set_notification_series(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   i_id_schedule_recursion => i_tab_id_nots(i),
                                                   i_flg_notification      => i_flg_notification,
                                                   i_flg_not_via           => i_flg_not_via,
                                                   o_error                 => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                ELSE
                    g_error := 'CALL set_schedule_notification';
                    IF NOT set_schedule_notification(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_schedule   => i_tab_id_nots(i),
                                                     i_notification  => i_flg_notification,
                                                     i_flg_notif_via => i_flg_not_via,
                                                     o_error         => o_error)
                    THEN
                        ROLLBACK;
                        RETURN TRUE;
                    END IF;
                END IF;
            END LOOP;
        
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
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
        END set_notifications;
    */

    FUNCTION set_notifications
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_tab_id_nots      IN table_number,
        i_tab_types        IN table_varchar,
        i_flg_notification IN schedule.flg_notification%TYPE,
        i_flg_not_via      IN schedule.flg_schedule_via%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_notification schedule.flg_notification%TYPE;
        l_flg_status       schedule.flg_status%TYPE;
        l_func_name        VARCHAR2(32) := 'SET_NOTIFICATIONS';
        l_exception EXCEPTION;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_sch_type       schedule.flg_sch_type%TYPE;
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        FOR i IN i_tab_id_nots.first .. i_tab_id_nots.last
        LOOP
            g_error := 'ITERATION - id ' || i_tab_id_nots(i) || ' type: ' || i_tab_types(i);
            -- notificacoes a la mfr
            IF (i_tab_types(i) = g_notif_mfr)
            THEN
                g_error := 'CALL set_schedule_notification';
                IF NOT pk_schedule_mfr.set_schedule_notification(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_id_interv_presc_det => table_number(i_tab_id_nots(i)),
                                                                 i_flg_notif           => i_flg_notification,
                                                                 i_flg_notif_via       => i_flg_not_via,
                                                                 o_error               => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                -- notificacoes a la series
            ELSIF (i_tab_types(i) = g_notif_series)
            THEN
                g_error := 'CALL set_notification_series';
                IF NOT set_notification_series(i_lang                  => i_lang,
                                               i_prof                  => i_prof,
                                               i_id_schedule_recursion => i_tab_id_nots(i),
                                               i_flg_notification      => i_flg_notification,
                                               i_flg_not_via           => i_flg_not_via,
                                               i_transaction_id        => l_transaction_id,
                                               o_error                 => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                -- notificacoes para tudo o resto
            ELSE
                -- se o agendamento for de oris ou inp usa-se a versao antiga da set_schedule_notification (a que nao tem transaction_id)
                SELECT flg_sch_type
                  INTO l_sch_type
                  FROM schedule
                 WHERE id_schedule = i_tab_id_nots(i);
            
                g_error := 'CALL set_schedule_notification';
                IF l_sch_type IN
                   (pk_schedule_common.g_sch_dept_flg_dep_type_sr, pk_schedule_common.g_sch_dept_flg_dep_type_inp)
                THEN
                    IF NOT set_schedule_notification(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_schedule   => i_tab_id_nots(i),
                                                     i_notification  => i_flg_notification,
                                                     i_flg_notif_via => i_flg_not_via,
                                                     o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                ELSE
                    IF NOT set_schedule_notification(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_schedule    => i_tab_id_nots(i),
                                                     i_notification   => i_flg_notification,
                                                     i_flg_notif_via  => i_flg_not_via,
                                                     i_transaction_id => l_transaction_id,
                                                     o_error          => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
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
            pk_alert_exceptions.reset_error_state;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_notifications;

    /**
    * Returns the locations belonging to a group.
    *
    * @param    i_lang           Language
    * @param    i_prof           Professional
    * @param    o_list           Cursor with output info    
    * @param    o_error           Error message if something goes wrong
    *
    * @author  Sofia Mendes
    * @version 2.5.0.4
    * @since   2009/07/03    
    */
    FUNCTION get_locations
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_LOCATIONS';
        l_institution institution.id_institution%TYPE := i_institution;
    BEGIN
        IF (i_institution IS NULL)
        THEN
            l_institution := i_prof.institution;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT t.id_institution AS data,
                   pk_translation.get_translation(i_lang, t.code_institution) AS label,
                   CASE
                        WHEN t.id_institution = l_institution THEN
                         g_yes
                        ELSE
                         g_no
                    END AS flg_select,
                   1 order_field
              FROM (SELECT inst.id_institution, inst.code_institution
                      FROM institution inst
                      JOIN institution mine
                        ON (mine.id_parent = inst.id_parent)
                     WHERE mine.id_institution = i_prof.institution
                    UNION
                    SELECT i_prof.institution, i.code_institution
                      FROM institution i
                     WHERE i.id_institution = i_prof.institution) t
             WHERE t.id_institution IN (SELECT sp.id_institution
                                          FROM sch_permission sp
                                         WHERE sp.id_professional = i_prof.id)
             ORDER BY label;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_locations;

    /*
    * calculate event icon based on current temporary status, current schedule status 
    * and if there are conflicts. INLINE FUNCTION
    * 
    * @author  Telmo
    * @date    07-07-2009
    * @version 2.5.0.4
    */
    FUNCTION calc_icon
    (
        i_lang        IN language.id_language%TYPE,
        i_id_sched    IN NUMBER,
        i_id_inst     IN schedule.id_instit_requested%TYPE,
        i_id_dcs      IN schedule.id_dcs_requested%TYPE,
        i_id_event    IN schedule.id_sch_event%TYPE,
        i_dt_begin    IN schedule.dt_begin_tstz%TYPE,
        i_dt_end      IN schedule.dt_end_tstz%TYPE,
        i_id_prof     IN sch_resource.id_professional%TYPE,
        i_id_room     IN schedule.id_room%TYPE,
        i_flg_tempor  IN schedule_sr.flg_temporary%TYPE,
        i_flg_status  IN schedule.flg_status%TYPE,
        i_flg_vacancy IN schedule.flg_vacancy%TYPE,
        i_id_vac      IN schedule.id_sch_consult_vacancy%TYPE
    ) RETURN VARCHAR2 IS
        l_res      VARCHAR2(200);
        l_dummy    INTEGER;
        l_conflict INTEGER;
    
        FUNCTION inner_calc_conflicts RETURN NUMBER IS
            res NUMBER;
        BEGIN
            SELECT 1
              INTO res
              FROM schedule s
              JOIN sch_resource sr
                ON s.id_schedule = sr.id_schedule
             WHERE s.id_schedule <> i_id_sched
               AND (i_id_prof IS NULL OR sr.id_professional = i_id_prof) -- importante para a agenda consultas
               AND s.id_instit_requested = i_id_inst
               AND (i_id_room IS NULL OR s.id_room = i_id_room) -- importante para a agenda oris
               AND s.dt_end_tstz IS NOT NULL
               AND ((i_dt_begin >= s.dt_begin_tstz AND i_dt_begin < s.dt_end_tstz) OR
                   (i_dt_end IS NOT NULL AND (i_dt_end > s.dt_begin_tstz AND i_dt_end <= s.dt_end_tstz)))
               AND s.flg_status <> g_sched_status_cancelled
               AND (i_id_vac IS NULL OR s.id_sch_consult_vacancy <> i_id_vac)
               AND rownum = 1;
        
            RETURN res;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN 0;
        END inner_calc_conflicts;
    BEGIN
    
        -- todos os agendamentos finais
        IF i_flg_status = g_sched_status_scheduled
        THEN
            -- final alem-vaga e final urgente
            IF i_flg_vacancy IN
               (pk_schedule_common.g_sched_vacancy_unplanned, pk_schedule_common.g_sched_vacancy_urgent)
            THEN
                l_res := pk_sysdomain.get_img(i_lang, g_sched_flg_sch_status_domain, i_flg_status || i_flg_vacancy);
                -- final rotina. 
            ELSIF i_flg_vacancy = pk_schedule_common.g_sched_vacancy_routine
            THEN
                -- neste caso precisa calcular conflitos para decidir entre o sch_scheduledRoutineIcon e sch_schedulingconflictfinalicon
                IF inner_calc_conflicts > 0
                THEN
                    l_res := g_sched_icon_perm_conflict;
                ELSE
                    l_res := pk_sysdomain.get_img(i_lang, g_schedule_flg_status_domain, i_flg_status);
                END IF;
            END IF;
        
            -- todos os agendamentos temporarios
        ELSIF i_flg_status = g_sched_status_temporary
        THEN
            --temporario alem-vaga e urgente
            IF i_flg_vacancy IN
               (pk_schedule_common.g_sched_vacancy_unplanned, pk_schedule_common.g_sched_vacancy_urgent)
            THEN
                l_res := pk_sysdomain.get_img(i_lang, g_sched_flg_sch_status_domain, i_flg_status || i_flg_vacancy);
                -- temporario rotina. 
            ELSIF i_flg_vacancy = pk_schedule_common.g_sched_vacancy_routine
            THEN
                -- neste caso precisa calcular conflitos para decidir entre o sch_scheduledRoutineIcon e sch_schedulingconflictfinalicon
                IF inner_calc_conflicts > 0
                THEN
                    l_res := g_sched_icon_temp_conflict;
                ELSE
                    l_res := pk_sysdomain.get_img(i_lang, g_schedule_flg_status_domain, i_flg_status);
                END IF;
            END IF;
        
            -- pendentes, cancelados e restantes
        ELSE
            l_res := pk_sysdomain.get_img(i_lang, g_sched_flg_sch_status_domain, i_flg_status || i_flg_vacancy);
        END IF;
    
        RETURN pk_schedule.g_icon_prefix || l_res;
    END calc_icon;

    /********************************************************************************************
    * This function gets the total of scheduled sessions for an Intervention Detail, 
    *   and the rank for schedule ID parameter 
    *
    * @param i_lang                          language ID
    * @param i_id_schedule                   schedule ID        
    * @param o_count                         number of total scheduled sessions
    * @param o_rank                          session rank for i_id_schedule parameter
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Sofia Mendes
    * @version               V.2.5.0.5
    * @since                 2009/08/19    
    ********************************************************************************************/
    FUNCTION get_count_and_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_count       OUT NUMBER,
        o_rank        OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'GET_COUNT_AND_RANK';
        l_id_schedule_recursion schedule.id_schedule_recursion%TYPE;
    BEGIN
        g_error := 'GET ID_SCHEDULE_RECURSION FOR I_ID_SCHEDULE';
        SELECT s.id_schedule_recursion
          INTO l_id_schedule_recursion
          FROM schedule s
         WHERE s.id_schedule = i_id_schedule;
    
        IF (l_id_schedule_recursion IS NULL)
        THEN
            g_error := 'IT IS NOT A SERIES APPOINTMENT';
            o_count := NULL;
            o_rank  := NULL;
            RETURN TRUE;
        ELSE
            -- output value o_count
            g_error := 'GET OUTPUT VALUE O_COUNT';
            SELECT COUNT(1)
              INTO o_count
              FROM schedule s
             WHERE s.id_schedule_recursion = l_id_schedule_recursion
               AND s.flg_status <> g_sched_status_cancelled;
        END IF;
    
        -- output value o_rank    
        g_error := 'GET OUTPUT VALUE O_RANK';
        SELECT rn
          INTO o_rank
          FROM (SELECT rownum rn, subq.id_schedule
                  FROM (SELECT sch.id_schedule
                          FROM schedule sch
                         WHERE sch.id_schedule_recursion = l_id_schedule_recursion
                           AND sch.flg_status <> g_sched_status_cancelled
                         ORDER BY sch.dt_begin_tstz) subq)
         WHERE id_schedule = i_id_schedule;
    
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
            RETURN FALSE;
    END get_count_and_rank;

    /********************************************************************************************
    * Overload da get_count_and_rank para se poder usar dentro de queries
    *
    * @param i_lang                          language ID
    * @param i_id_schedule                   schedule ID
    *
    * @return                                o_rank,o_count (varchar)
    *
    * @author                Sofia Mendes
    * @version               V.2.5.0.5
    * @since                 2009/08/19    
    ********************************************************************************************/
    FUNCTION get_count_and_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_count NUMBER;
        l_rank  NUMBER;
        o_error t_error_out;
        ret_val VARCHAR2(200) := ' ';
    BEGIN
        IF get_count_and_rank(i_lang        => i_lang,
                              i_id_schedule => i_id_schedule,
                              o_count       => l_count,
                              o_rank        => l_rank,
                              o_error       => o_error)
        THEN
            IF (l_count IS NULL OR l_rank IS NULL)
            THEN
                ret_val := NULL;
            ELSE
                ret_val := l_rank || '/' || l_count;
            END IF;
        END IF;
    
        RETURN ret_val;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN ret_val;
        
    END get_count_and_rank;

    /** RETURN THE SCH_TYPE OF A SCHEDULE
    *
    * @param i_lang       language id
    * @param i_prof       professional data
    * @param i_id_sch     schedule id
    * @param o_sch_type   schedule.flg_sch_type
    * @param o_error      error data
    *
    * @return  success / fail   
    *
    * @author    Telmo
    * @version   2.5.0.7
    * @date      05-01-2010
    */
    FUNCTION get_sch_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_sch   IN schedule.id_schedule%TYPE,
        o_sch_type OUT schedule.flg_sch_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCH_TYPE';
    BEGIN
        g_error := 'GET FLG_SCH_TYPE';
        SELECT flg_sch_type
          INTO o_sch_type
          FROM schedule
         WHERE id_schedule = i_id_sch;
    
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
            RETURN FALSE;
    END get_sch_type;

    /** SEZ IF A SCHEDULE IS NOTIFIED (Y) OR NOT (N).
    * INLINE FUNCTION
    *
    * @param i_lang         language id
    * @param i_prof         prof data
    * @param i_id_schedule schedule id
    *
    * @return Y/N
    *
    * @author  Telmo
    * @version 2.5.0.7
    * @date    06-01-2010
    */
    FUNCTION is_notified
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(1);
    BEGIN
        SELECT CASE flg_notification
                   WHEN g_sched_flg_notif_pending THEN
                    g_no
                   ELSE
                    g_yes
               END
          INTO l_result
          FROM schedule
         WHERE id_schedule = i_id_schedule;
    
        RETURN l_result;
    END;

    /* 
    * ALERT-14509. Interruption of workflows due to patient decease. 
    * This function returns the patient ongoing tasks, in this context schedules, that can be canceled.
    * Output is in a special form, the type tr_tasks_list.
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_patient        patient id
    *
    * @return tf_tasks_list      this is a nested table of object tr_tasks_list
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    24-05-2010
    */
    FUNCTION get_ongoing_tasks_scheduler
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN sch_group.id_patient%TYPE
    ) RETURN tf_tasks_list IS
        l_obj        tr_tasks_list := tr_tasks_list(NULL, NULL, NULL, NULL);
        l_tasks_list tf_tasks_list := tf_tasks_list();
    
        CURSOR c IS
            SELECT s.id_schedule,
                   s.dt_begin_tstz,
                   (SELECT pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event)
                      FROM sch_event se
                     WHERE se.id_sch_event = nvl(s.id_sch_event, 14)) || ' - ' ||
                   (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                      FROM dep_clin_serv dcs
                      JOIN clinical_service cs
                        ON dcs.id_clinical_service = cs.id_clinical_service
                     WHERE dcs.id_dep_clin_serv = s.id_dcs_requested) desc_task,
                   ei.id_episode,
                   ei.flg_status,
                   e.id_epis_type,
                   e.flg_ehr
              FROM schedule s
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
             WHERE s.flg_status <> g_sched_status_cancelled
               AND nvl(s.dt_end_tstz, s.dt_begin_tstz) >= g_sysdate_tstz
               AND sg.id_patient = i_id_patient
               AND (SELECT COUNT(1)
                      FROM sch_group
                     WHERE id_schedule = s.id_schedule) = 1 -- se este agend. tiver outros pacientes nao conta
               AND nvl(e.flg_ehr, 'ZIP') <> 'N'
             ORDER BY s.dt_schedule_tstz DESC;
    
        l_c_rec c%ROWTYPE;
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN c;
        LOOP
            FETCH c
                INTO l_c_rec;
            EXIT WHEN c%NOTFOUND;
            -- set up task obj
            g_error         := 'SET UP tr_tasks_list object';
            l_obj.id_task   := l_c_rec.id_schedule;
            l_obj.desc_task := l_c_rec.desc_task;
            l_obj.dt_task   := pk_date_utils.dt_chr_date_hour_tsz(i_lang => i_lang,
                                                                  i_date => l_c_rec.dt_begin_tstz,
                                                                  i_inst => i_prof.institution,
                                                                  i_soft => i_prof.software);
        
            IF l_c_rec.id_epis_type IS NOT NULL
            THEN
                g_error := 'GET EPIS TYPE TRANSLATION';
                SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
                  INTO l_obj.epis_type
                  FROM epis_type et
                 WHERE et.id_epis_type = l_c_rec.id_epis_type;
            ELSE
                -- alternate way to find the epis_type -> find the episode connected to this schedule
                g_error := 'GET EPIS TYPE FROM EPISODE';
                BEGIN
                    SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
                      INTO l_obj.epis_type
                      FROM episode e
                      JOIN epis_type et
                        ON e.id_epis_type = et.id_epis_type
                      JOIN epis_info ef
                        ON e.id_episode = ef.id_episode
                     WHERE ef.id_schedule = l_c_rec.id_schedule;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
            -- append to output coll
            l_tasks_list.extend;
            l_tasks_list(l_tasks_list.last) := l_obj;
        END LOOP;
        CLOSE c;
    
        RETURN l_tasks_list;
    
    END get_ongoing_tasks_scheduler;

    /* 
    * ALERT-14509. Interruption of workflows due to patient decease. 
    * This function cancels the task identified by i_id_task.
    * In case of success, function returns true. Otherwise returns false and o_msg_error is filled.
    * Included the transaction id in the para
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_task           task id (id_schedule). must be one of those coming out of a previous get_ongoing_tasks_scheduler invocation.
    * @param   I_FLG_REASON      Reason for the WF suspension: 'D' (Death)
    * @param i_transaction_id    trans. id for remote scheduler actions. If this function's invoker wants control over transactions must supply one
    * @param o_msg_error         output error msg 
    * @param o_error             error info
    *
    * @return   true/false
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    24-05-2010
    */
    FUNCTION suspend_task_scheduler
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_task        IN NUMBER,
        i_flg_reason     IN VARCHAR2,
        i_transaction_id IN VARCHAR2,
        o_msg_error      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
        l_message sys_message.desc_message%TYPE := NULL;
        l_desc    VARCHAR2(4000);
        l_error   t_error_out;
        l_rt_exception EXCEPTION;
        l_id_sch_cr        sch_cancel_reason.id_sch_cancel_reason%TYPE;
        l_id_sch_event     schedule.id_sch_event%TYPE;
        l_flg_sch_type     schedule.flg_sch_type%TYPE;
        l_id_dcs_requested schedule.id_dcs_requested%TYPE;
    BEGIN
        -- start remote transaction if none was supplied. This condition is checked inside begin_new_transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- get the sch cancel reason configured for this context
        BEGIN
            g_error := 'GET ID_SCH_CANCEL_REASON';
            SELECT scr.id_sch_cancel_reason
              INTO l_id_sch_cr
              FROM sch_cancel_reason scr
              JOIN sch_cancel_reason_inst i
                ON scr.id_sch_cancel_reason = i.id_sch_cancel_reason
             WHERE scr.id_sch_cancel_reason IN (51, 30, 21)
               AND scr.flg_available = pk_alert_constant.g_yes
               AND i.flg_available = pk_alert_constant.g_yes
               AND i.id_institution = i_prof.institution
               AND i.id_software = i_prof.software
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_sch_cr := 21;
        END;
    
        IF NOT pk_schedule_api_upstream.cancel_schedule(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_schedule      => i_id_task,
                                                        i_id_cancel_reason => CASE i_flg_reason
                                                                                  WHEN 'D' THEN
                                                                                   l_id_sch_cr
                                                                                  ELSE
                                                                                   NULL
                                                                              END,
                                                        i_transaction_id   => l_transaction_id,
                                                        o_error            => l_error)
        THEN
            g_error   := 'get message SCH_T817';
            l_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SCH_T817');
        
            g_error := 'get schedule id ' || i_id_task || ' data';
            SELECT id_sch_event, flg_sch_type, id_dcs_requested
              INTO l_id_sch_event, l_flg_sch_type, l_id_dcs_requested
              FROM schedule s
             WHERE s.id_schedule = i_id_task;
        
            g_error := 'call get_procedure_name';
            l_desc  := get_procedure_name(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_id_schedule  => i_id_task,
                                          i_flg_sch_type => l_flg_sch_type,
                                          i_id_sch_event => l_id_sch_event,
                                          i_id_dcs_req   => l_id_dcs_requested);
        
            g_error := 'call replace_tokens';
            IF NOT replace_tokens(i_lang         => i_lang,
                                  i_string       => l_message,
                                  i_tokens       => table_varchar('@1'),
                                  i_replacements => table_varchar(l_desc),
                                  o_string       => o_msg_error,
                                  o_error        => o_error)
            THEN
                RAISE l_rt_exception;
            END IF;
            RAISE l_func_exception;
        END IF;
    
        -- if remote transaction started in this function, then it is closed here
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            o_msg_error := o_msg_error || l_error.ora_sqlerrm;
            o_error     := l_error;
            RETURN FALSE;
        WHEN l_rt_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            o_msg_error := NULL;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SUSPEND_TASK_SCHEDULER',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END suspend_task_scheduler;

    /* 
    * ALERT-14509. Interruption of workflows due to patient decease. 
    * This function reactivates a task identified by i_id_task which was previously cancelled by mistake.
    * It will be done by creating a new schedule using the canceled one's data.
    * In case of success, function returns true. Otherwise returns false and o_msg_error is filled.
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_task           task id (id_schedule). task to reactivate
    * @param i_transaction_id    trans. id for remote scheduler actions. If this function's invoker wants control over transactions must supply one
    * @param o_msg_error         output error msg 
    * @param o_error             error info
    *
    * @return   true/false
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    26-05-2010
    */
    FUNCTION reactivate_task_scheduler
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_task        IN NUMBER,
        i_transaction_id IN VARCHAR2,
        o_msg_error      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_exception EXCEPTION;
        --Scheduler 3.0 variables
        l_transaction_id     VARCHAR2(4000);
        l_id_profissional    sch_resource.id_professional%TYPE;
        l_id_patient         sch_group.id_patient%TYPE;
        l_id_event           schedule.id_sch_event%TYPE;
        l_id_dcs_requested   schedule.id_dcs_requested%TYPE;
        l_dt_begin_tstz      schedule.dt_begin_tstz%TYPE;
        l_dt_end_tstz        schedule.dt_end_tstz%TYPE;
        l_flg_vacancy        schedule.flg_vacancy%TYPE;
        l_id_episode         schedule.id_episode%TYPE;
        l_flg_request_type   schedule.flg_request_type%TYPE;
        l_flg_schedule_via   schedule.flg_schedule_via%TYPE;
        l_schedule_notes     schedule.schedule_notes%TYPE;
        l_id_instit_requests schedule.id_instit_requests%TYPE;
        l_id_dcs_requests    schedule.id_dcs_requests%TYPE;
        l_id_prof_requests   schedule.id_prof_requests%TYPE;
        l_id_prof_schedules  schedule.id_prof_schedules%TYPE;
        l_id_schedule_ref    schedule.id_schedule_ref%TYPE;
        l_ids_schedule       table_number;
        l_id_schedule_ext    sch_api_map_ids.id_schedule_ext%TYPE;
        l_flg_proceed        VARCHAR2(1);
        l_flg_show           VARCHAR2(1);
        l_msg_title          VARCHAR2(200);
        l_msg                VARCHAR2(4000);
        l_button             VARCHAR2(200);
        l_message            sys_message.desc_message%TYPE := NULL;
        l_desc               VARCHAR2(4000);
    BEGIN
    
        -- get canceled schedule data
        g_error := 'GET CANCELED SCHEDULE DATA';
        SELECT s.id_sch_event,
               s.id_dcs_requested,
               s.dt_begin_tstz,
               s.dt_end_tstz,
               flg_vacancy,
               id_episode,
               flg_request_type,
               flg_schedule_via,
               schedule_notes,
               id_instit_requests,
               id_dcs_requests,
               id_prof_requests,
               id_prof_schedules,
               id_schedule_ref
          INTO l_id_event,
               l_id_dcs_requested,
               l_dt_begin_tstz,
               l_dt_end_tstz,
               l_flg_vacancy,
               l_id_episode,
               l_flg_request_type,
               l_flg_schedule_via,
               l_schedule_notes,
               l_id_instit_requests,
               l_id_dcs_requests,
               l_id_prof_requests,
               l_id_prof_schedules,
               l_id_schedule_ref
          FROM schedule s
         WHERE s.id_schedule = i_id_task;
    
        -- get canceled schedule prof data
        g_error := 'GET CANCELED SCHEDULE PROF DATA';
        SELECT sr.id_professional
          INTO l_id_profissional
          FROM sch_resource sr
         WHERE sr.id_schedule = i_id_task
           AND rownum = 1;
    
        -- get canceled schedule patient
        g_error := 'GET CANCELED SCHEDULE PATIENT DATA';
        SELECT id_patient
          INTO l_id_patient
          FROM sch_group sg
         WHERE sg.id_schedule = i_id_task
           AND rownum = 1;
    
        -- start remote transaction if none was supplied. This condition is checked inside begin_new_transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- create new schedule
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.CREATE_SCHEDULE';
        IF NOT pk_schedule_api_upstream.create_schedule(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_event_id          => l_id_event,
                                                        i_professional_id   => l_id_profissional,
                                                        i_id_patient        => l_id_patient,
                                                        i_id_dep_clin_serv  => l_id_dcs_requested,
                                                        i_dt_begin_tstz     => l_dt_begin_tstz,
                                                        i_dt_end_tstz       => l_dt_end_tstz,
                                                        i_flg_vacancy       => l_flg_vacancy,
                                                        i_id_episode        => l_id_episode,
                                                        i_flg_rqst_type     => l_flg_request_type,
                                                        i_flg_sch_via       => l_flg_schedule_via,
                                                        i_sch_notes         => l_schedule_notes,
                                                        i_id_inst_requests  => l_id_instit_requests,
                                                        i_id_dcs_requests   => l_id_dcs_requests,
                                                        i_id_prof_requests  => l_id_prof_requests,
                                                        i_id_prof_schedules => l_id_prof_schedules,
                                                        i_id_sch_ref        => l_id_schedule_ref,
                                                        i_transaction_id    => l_transaction_id,
                                                        o_ids_schedule      => l_ids_schedule,
                                                        o_id_schedule_ext   => l_id_schedule_ext,
                                                        o_flg_proceed       => l_flg_proceed,
                                                        o_flg_show          => l_flg_show,
                                                        o_msg_title         => l_msg_title,
                                                        o_msg               => l_msg,
                                                        o_button            => l_button,
                                                        o_error             => o_error)
        THEN
            l_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SCH_T818');
            SELECT pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) ||
                   ' - ' || (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                               FROM dep_clin_serv dcs
                               JOIN clinical_service cs
                                 ON dcs.id_clinical_service = cs.id_clinical_service
                              WHERE dcs.id_dep_clin_serv = s.id_dcs_requested)
              INTO l_desc
              FROM schedule s
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
             WHERE s.id_schedule = i_id_task;
        
            IF NOT replace_tokens(i_lang         => i_lang,
                                  i_string       => l_message,
                                  i_tokens       => table_varchar('@1'),
                                  i_replacements => table_varchar(l_desc),
                                  o_string       => o_msg_error,
                                  o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
            o_msg_error := o_msg_error || l_msg;
            RAISE l_func_exception;
        END IF;
    
        -- if remote transaction was started in this function, then the function is it's owner. If so the transaction is closed internally.
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN no_data_found THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'REACTIVATE_TASK_SCHEDULER',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END reactivate_task_scheduler;

    FUNCTION get_procedure_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        i_flg_sch_type IN schedule.flg_sch_type%TYPE,
        i_id_sch_event IN schedule.id_sch_event%TYPE,
        i_id_dcs_req   IN schedule.id_dcs_requested%TYPE
    ) RETURN VARCHAR2 IS
        l_retval VARCHAR2(32767);
        c        pk_types.cursor_type;
        l_id_wl  schedule_sr.id_waiting_list%TYPE;
    BEGIN
        g_error := 'GET_PROCEDURE_NAME - i_id_schedule=' || i_id_schedule || ', i_flg_sch_type=' || i_flg_sch_type ||
                   ', i_id_sch_event=' || i_id_sch_event || ', i_id_dcs_req=' || i_id_dcs_req;
    
        CASE pk_schedule_common.get_dep_type_group(i_flg_sch_type)
            WHEN pk_schedule_common.g_sch_dept_flg_dep_type_inp THEN
                l_retval := pk_translation.get_translation(i_lang, 'SCH_DEP_TYPE.CODE_DEP_TYPE.10');
            
            WHEN pk_schedule_common.g_sch_dept_flg_dep_type_sr THEN
                SELECT id_waiting_list
                  INTO l_id_wl
                  FROM schedule_sr sr
                 WHERE sr.id_schedule = i_id_schedule;
                l_retval := pk_wtl_pbl_core.get_surg_proc_string(i_lang, i_prof, l_id_wl);
            
            WHEN pk_schedule_common.g_sch_dept_flg_dep_type_pm THEN
                OPEN c FOR
                    SELECT pk_translation.get_translation(i_lang, i.code_intervention)
                      FROM rehab_schedule rs
                      JOIN rehab_presc rp
                        ON rp.id_rehab_sch_need = rs.id_rehab_sch_need
                      JOIN rehab_area_interv rai
                        ON rp.id_rehab_area_interv = rai.id_rehab_area_interv
                      JOIN intervention i
                        ON rai.id_intervention = i.id_intervention
                     WHERE rs.id_schedule = i_id_schedule;
                l_retval := pk_utils.concatenate_list(c, '; ');
            
            WHEN pk_schedule_common.g_sch_dept_flg_dep_type_exam THEN
                OPEN c FOR
                    SELECT pk_translation.get_translation(i_lang, e.code_exam)
                      FROM schedule_exam se
                      JOIN exam e
                        ON se.id_exam = e.id_exam
                     WHERE se.id_schedule = i_id_schedule;
                l_retval := pk_utils.concatenate_list(c, '; ');
            
            WHEN pk_schedule_common.g_sch_dept_flg_dep_type_cons THEN
                SELECT pk_translation.get_translation(i_lang, code_appointment)
                  INTO l_retval
                  FROM appointment a
                  JOIN dep_clin_serv dcs
                    ON a.id_clinical_service = dcs.id_clinical_service
                 WHERE a.id_sch_event = i_id_sch_event
                   AND dcs.id_dep_clin_serv = i_id_dcs_req;
            
        -- analises: o que deve devolver ?            
            WHEN pk_schedule_common.g_sch_dept_flg_dep_type_anls THEN
                l_retval := '';
        END CASE;
    
        RETURN substr(l_retval, 1, 4000); -- esta funcao e' usada em sql por isso limito ao tamanho maximo do varchar2 em sql
    END get_procedure_name;

    /*
    *
    */
    FUNCTION get_patient_scheds
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN sch_group.id_patient%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PATIENT_SCHEDS';
    BEGIN
        g_error := l_func_name || ' - OPEN cursor. id_patient=' || i_id_patient;
        OPEN o_list FOR
            SELECT DISTINCT sr.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional)
              FROM sch_group sg
              JOIN schedule s
                ON s.id_schedule = sg.id_schedule
              JOIN sch_resource sr
                ON sr.id_schedule = sg.id_schedule
             WHERE sg.id_patient = i_id_patient
               AND s.flg_status <> g_sched_status_cancelled;
    
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
            RETURN FALSE;
    END get_patient_scheds;

    /*
    *
    */
    FUNCTION set_schedule_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_notes       IN schedule.schedule_notes%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_SCHEDULE_NOTES';
    BEGIN
        IF TRIM(i_notes) IS NULL
        THEN
            raise_application_error(-20201, 'empty notes');
        END IF;
    
        IF i_id_schedule IS NULL
        THEN
            raise_application_error(-20202, 'schedule id not supplied');
        END IF;
    
        g_error := l_func_name || ' - CALL TS_SCHEDULE.UPD. i_id_sch=' || i_id_schedule;
        ts_schedule.upd(id_schedule_in => i_id_schedule, schedule_notes_in => i_notes, handle_error_in => FALSE);
    
        g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. i_id_sch=' || i_id_schedule;
        pk_schedule_common.backup_all(i_id_sch    => i_id_schedule,
                                      i_dt_update => current_timestamp,
                                      i_id_prof_u => i_prof.id);
    
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
            RETURN FALSE;
    END set_schedule_notes;

    FUNCTION get_appointment_type
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_sch_event IN sch_event.id_sch_event%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1000 CHAR);
    BEGIN
        SELECT s.dep_type
          INTO l_return
          FROM sch_event s
         WHERE s.id_sch_event = i_id_sch_event;
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_appointment_type;

    FUNCTION get_schedule_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_SCHEDULE_VALUES - SCHEDULE';
    
    BEGIN
        ---------------------------------------------------------------------
        -- processing of i_curr_component specific data
        IF i_episode IS NOT NULL
        THEN
            -- obtain the values of id_epis_out_on_pass when editing a record
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                      id_ds_component    => t.id_ds_component_child,
                                      internal_name      => t.internal_name_child,
                                      VALUE              => t.value,
                                      value_clob         => NULL,
                                      min_value          => NULL,
                                      max_value          => NULL,
                                      desc_value         => t.desc_value,
                                      desc_clob          => NULL,
                                      id_unit_measure    => NULL,
                                      desc_unit_measure  => NULL,
                                      flg_validation     => 'Y',
                                      err_msg            => NULL,
                                      flg_event_type     => t.flg_event_type,
                                      flg_multi_status   => NULL,
                                      idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           CASE dc.internal_name_child
                               WHEN 'DS_LOCATION' THEN
                                to_char(e.id_instit_requested)
                               WHEN 'DS_CLINICAL_SERVICE' THEN
                                to_char(e.id_clinical_service)
                               WHEN 'DS_SCHEDULING_DATE_TIME' THEN
                                (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(dt_target_tstz, dt_begin_tstz), i_prof)
                                   FROM dual)
                               WHEN 'DS_TYPE_OF_VISIT' THEN
                                to_char(e.id_sch_event)
                               WHEN 'DS_PROFESSIONAL' THEN
                                to_char(e.id_professional)
                               WHEN 'DS_REASON_FOR_VISIT' THEN
                                e.reason_notes
                               WHEN 'DS_SCHEDULING_NOTES' THEN
                                e.schedule_notes
                           END VALUE,
                           CASE dc.internal_name_child
                               WHEN 'DS_LOCATION' THEN
                                (SELECT pk_utils.get_institution_name(i_lang, e.id_instit_requested)
                                   FROM dual)
                               WHEN 'DS_CLINICAL_SERVICE' THEN
                                (SELECT pk_translation.get_translation(i_lang, e.code_clinical_service)
                                   FROM dual)
                               WHEN 'DS_SCHEDULING_DATE_TIME' THEN
                                (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(dt_target_tstz, dt_begin_tstz), i_prof)
                                   FROM dual)
                               WHEN 'DS_TYPE_OF_VISIT' THEN
                                (SELECT pk_schedule_common.get_translation_alias(i_lang,
                                                                                 i_prof,
                                                                                 e.id_sch_event,
                                                                                 e.code_sch_event)
                                   FROM dual)
                               WHEN 'DS_PROFESSIONAL' THEN
                                (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional)
                                   FROM dual)
                               WHEN 'DS_REASON_FOR_VISIT' THEN
                                e.reason_notes
                               WHEN 'DS_SCHEDULING_NOTES' THEN
                                e.schedule_notes
                           END desc_value,
                           dc.flg_event_type
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc
                      JOIN (SELECT ei.id_episode,
                                  se.id_sch_event,
                                  se.code_sch_event,
                                  NULL id_professional,
                                  s.reason_notes,
                                  s.schedule_notes,
                                  s.dt_schedule_tstz,
                                  cs.code_clinical_service,
                                  s.id_instit_requested,
                                  cs.id_clinical_service,
                                  so.dt_target_tstz,
                                  e.dt_begin_tstz
                             FROM episode e
                             JOIN epis_info ei
                               ON e.id_episode = ei.id_episode
                             JOIN schedule s
                               ON ei.id_schedule = s.id_schedule
                             LEFT JOIN schedule_outp so
                               ON so.id_schedule = s.id_schedule
                             LEFT JOIN dep_clin_serv dcs
                               ON (dcs.id_dep_clin_serv = s.id_dcs_requested)
                             LEFT JOIN clinical_service cs
                               ON (cs.id_clinical_service = dcs.id_clinical_service)
                             JOIN sch_event se
                               ON s.id_sch_event = se.id_sch_event
                            WHERE ei.id_episode = i_episode
                           UNION ALL
                           SELECT ei.id_episode,
                                  NULL               id_sch_event,
                                  NULL               code_sch_event,
                                  sr.id_professional,
                                  NULL               reason_notes,
                                  NULL               schedule_notes,
                                  NULL               dt_schedule_tstz,
                                  NULL               code_clinical_service,
                                  NULL               id_instit_requested,
                                  NULL               id_clinical_service,
                                  NULL               dt_target_tstz,
                                  NULL               dt_begin_tstz
                             FROM epis_info ei
                             JOIN schedule s
                               ON ei.id_schedule = s.id_schedule
                             LEFT JOIN sch_resource sr
                               ON sr.id_schedule = s.id_schedule
                            WHERE ei.id_episode = i_episode) e
                        ON e.id_episode = i_episode
                     ORDER BY dc.rn) t
             WHERE t.desc_value IS NOT NULL;
        
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_schedule_values;

    FUNCTION get_videoconf_prof(i_id_schedule IN schedule.id_schedule%TYPE) RETURN NUMBER IS
    
        l_id_professional NUMBER;
    
        tbl_prof_first_obs table_number;
        tbl_prof_epis      table_number;
        tbl_prof_sch       table_number;
    
    BEGIN
    
        --get prof id 
        SELECT ei.id_prof_first_obs, ei.id_professional, spo.id_professional
          BULK COLLECT
          INTO tbl_prof_first_obs, tbl_prof_epis, tbl_prof_sch
          FROM schedule s
          JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
          JOIN schedule_outp so
            ON so.id_schedule = s.id_schedule
          JOIN sch_prof_outp spo
            ON spo.id_schedule_outp = so.id_schedule_outp
         WHERE ei.id_schedule = i_id_schedule
           AND s.flg_status NOT IN ('C', 'D');
    
        IF (tbl_prof_first_obs.count > 0 OR tbl_prof_epis.count > 0 OR tbl_prof_sch.count > 0)
        THEN
            l_id_professional := coalesce(tbl_prof_first_obs(1), tbl_prof_epis(1), tbl_prof_sch(1));
        ELSE
            l_id_professional := NULL;
        END IF;
        RETURN l_id_professional;
    
    END get_videoconf_prof;

    /**
    * Returns the average of waiting time for video conferece appointments
    *
    * @param i_lang                language id
    * @param i_institution         institution id
    * @param i_software            software id
    * @param i_speciality          id_dcs_requested
    * @param i_id_professional     Professional id
    * @param i_dt_schedule         appointment schedule date
    * @param o_server_time         server time
    * @param o_waiting_time        average of waiting time for video conferece appointments
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Ana Moita
    * @since                       10-07-2020
    * @version                     2.8.
    */

    FUNCTION get_videoconf_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_schedule        IN sch_api_map_ids.id_schedule_ext%TYPE,
        o_server_time     OUT VARCHAR2,
        o_waiting_time    OUT NUMBER,
        o_speciality_desc OUT VARCHAR2,
        o_id_professional OUT NUMBER,
        o_inst_name       OUT VARCHAR2,
        o_inst_logo       OUT BLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_schedule        schedule.id_schedule%TYPE;
        l_institution     institution.id_institution%TYPE;
        l_software        software.id_software%TYPE;
        l_id_professional professional.id_professional%TYPE;
        l_prof            profissional;
        l_dep_clin_serv   dep_clin_serv.id_dep_clin_serv%TYPE;
        l_dt_begin_tstz   schedule.dt_begin_tstz%TYPE;
    
        l_dt_ini schedule.dt_begin_tstz%TYPE;
        --l_dt_end            schedule.dt_begin_tstz%TYPE;
    
        l_diff_minuts       NUMBER := 0;
        l_appoint_num       NUMBER := 0;
        l_diff_minuts_total NUMBER := 0;
    
        tbl_dt_first_obs  table_timestamp;
        tbl_dt_schedule   table_timestamp;
        tbl_schedule_pfh  table_number;
        l_speciality_desc VARCHAR2(4000);
    
    BEGIN
    
        --map pfh schedule
        tbl_schedule_pfh := pk_schedule_api_downstream.get_pfh_ids(i_id_ext => i_schedule);
        l_schedule       := tbl_schedule_pfh(1);
    
        --get schedule info
        SELECT s.id_instit_requested, ei.id_software, s.id_dcs_requested, s.dt_begin_tstz
          INTO l_institution, l_software, l_dep_clin_serv, l_dt_begin_tstz
          FROM schedule s
          JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
         WHERE s.id_schedule = l_schedule;
    
        --get most recent profissional                                            
        l_id_professional := pk_schedule.get_videoconf_prof(i_id_schedule => l_schedule);
        l_prof            := profissional(l_id_professional, l_institution, l_software);
    
        --get dep clin serv desc
        l_speciality_desc := pk_hea_prv_aux.get_clin_service(i_lang, l_prof, l_dep_clin_serv);
    
        --get init date
        l_dt_ini := CAST(pk_date_utils.trunc_insttimezone(l_prof, l_dt_begin_tstz) AS TIMESTAMP WITH LOCAL TIME ZONE);
    
        --   l_dt_end := l_dt_ini + numtodsinterval(1, 'DAY') - numtodsinterval(1, 'SECOND');              
    
        BEGIN
            SELECT inst_name, img_logo_telemedicine
              INTO o_inst_name, o_inst_logo
              FROM (SELECT pk_translation.get_translation(i_lang, i.code_institution) inst_name,
                           il.img_logo_telemedicine,
                           il.img_banner,
                           il.img_banner_small,
                           il.id_institution_logo
                      FROM institution i
                      LEFT JOIN institution_logo il
                        ON i.id_institution = il.id_institution
                     WHERE i.id_institution = l_institution
                       AND (il.id_dep_clin_serv = l_dep_clin_serv OR il.id_dep_clin_serv IS NULL)
                     ORDER BY il.id_dep_clin_serv NULLS LAST)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_inst_logo := pk_tech_utils.set_empty_blob(o_inst_logo);
                o_inst_name := NULL;
            
        END;
    
        IF l_id_professional IS NOT NULL
        THEN
            SELECT ei.dt_first_obs_tstz, s.dt_begin_tstz
              BULK COLLECT
              INTO tbl_dt_first_obs, tbl_dt_schedule
              FROM epis_info ei
              JOIN schedule s
                ON s.id_schedule = ei.id_schedule
             WHERE ei.id_professional = l_id_professional
               AND s.video_link IS NOT NULL
               AND s.id_instit_requested = l_prof.institution
               AND s.dt_begin_tstz BETWEEN l_dt_ini AND l_dt_begin_tstz
               AND s.flg_status NOT IN ('C', 'D')
             ORDER BY s.dt_begin_tstz ASC;
        
        ELSE
        
            SELECT ei.dt_first_obs_tstz, s.dt_begin_tstz
              BULK COLLECT
              INTO tbl_dt_first_obs, tbl_dt_schedule
              FROM epis_info ei
              JOIN schedule s
                ON s.id_schedule = ei.id_schedule
             WHERE s.id_dcs_requested = l_dep_clin_serv
               AND s.video_link IS NOT NULL
               AND s.id_instit_requested = l_prof.institution
               AND s.dt_begin_tstz BETWEEN l_dt_ini AND l_dt_begin_tstz
               AND s.flg_status NOT IN ('C', 'D')
             ORDER BY s.dt_begin_tstz ASC;
        END IF;
    
        IF tbl_dt_first_obs.count > 0
        THEN
            FOR i IN 1 .. tbl_dt_first_obs.count
            LOOP
                CASE
                    WHEN tbl_dt_first_obs(i) IS NULL THEN
                        l_diff_minuts := 0;
                    ELSE
                        l_diff_minuts := round((CAST(tbl_dt_first_obs(i) AS DATE) - CAST(tbl_dt_schedule(i) AS DATE)) * 24 * 60);
                        l_appoint_num := l_appoint_num + 1;
                END CASE;
                l_diff_minuts_total := l_diff_minuts_total + (CASE
                                           WHEN l_diff_minuts > 0 THEN
                                            l_diff_minuts
                                           ELSE
                                            0
                                       END);
            END LOOP;
        
            IF l_diff_minuts_total > 0
            THEN
                o_waiting_time := round(l_diff_minuts_total / l_appoint_num);
            ELSE
                o_waiting_time := 0;
            END IF;
        ELSE
            o_waiting_time := 0;
        END IF;
    
        o_server_time     := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_speciality_desc := l_speciality_desc;
        o_id_professional := l_id_professional;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_VIDEOCONF_INFO',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_videoconf_info;

    FUNCTION set_videoconf_pat_register
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN sch_api_map_ids.id_schedule_ext%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_schedule        schedule.id_schedule%TYPE;
        l_institution     institution.id_institution%TYPE;
        l_software        software.id_software%TYPE;
        l_id_professional professional.id_professional%TYPE;
        l_id_prof_default professional.id_professional%TYPE;
        l_prof            profissional;
        l_flg_ehr         episode.flg_ehr%TYPE;
        l_epis_type       episode.id_epis_type%TYPE;
        tbl_schedule_pfh  table_number;
        l_episode         NUMBER;
        l_video_link      schedule.video_link%TYPE;
        --
        l_bool           BOOLEAN;
        l_transaction_id VARCHAR2(4000);
        k_epis_type_rehab_treatment   CONSTANT NUMBER := 15;
        k_epis_type_rehab_appointment CONSTANT NUMBER := 25;
    
    BEGIN
    
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        --map pfh schedule
        tbl_schedule_pfh := pk_schedule_api_downstream.get_pfh_ids(i_id_ext => i_schedule);
        l_schedule       := tbl_schedule_pfh(1);
    
        --get schedule info
        SELECT e.id_institution, ei.id_software, e.flg_ehr, e.id_epis_type, s.video_link
          INTO l_institution, l_software, l_flg_ehr, l_epis_type, l_video_link
          FROM schedule s
          JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
          JOIN episode e
            ON e.id_episode = ei.id_episode
         WHERE s.id_schedule = l_schedule
           AND ei.id_patient = i_patient;
    
        --get most recent episode profissional or profissional default                                           
        l_id_professional := pk_schedule.get_videoconf_prof(i_id_schedule => l_schedule);
    
        IF l_id_professional IS NOT NULL
        THEN
            l_prof := profissional(l_id_professional, l_institution, l_software);
        ELSE
            l_prof := profissional(0, l_institution, l_software);
        END IF;
    
        l_bool := (l_flg_ehr <> 'S' OR l_video_link IS NULL);
        IF NOT l_bool
        THEN
        
            l_bool := pk_visit.call_create_visit(i_lang                 => i_lang,
                                                 i_id_pat               => i_patient,
                                                 i_id_institution       => l_institution,
                                                 i_id_sched             => l_schedule,
                                                 i_id_professional      => l_prof,
                                                 i_id_episode           => NULL,
                                                 i_external_cause       => NULL,
                                                 i_health_plan          => NULL,
                                                 i_epis_type            => l_epis_type,
                                                 i_dep_clin_serv        => NULL,
                                                 i_origin               => NULL,
                                                 i_flg_ehr              => 'N',
                                                 i_dt_begin             => current_timestamp,
                                                 i_flg_appointment_type => NULL,
                                                 i_transaction_id       => l_transaction_id,
                                                 o_episode              => l_episode,
                                                 o_error                => o_error);
        
            IF l_bool
            THEN
            
                IF l_epis_type IN (k_epis_type_rehab_treatment, k_epis_type_rehab_appointment)
                THEN
                
                    l_bool := pk_rehab.set_rehab_workflow_change(i_lang              => i_lang,
                                                                 i_prof              => l_prof,
                                                                 i_id_patient        => i_patient,
                                                                 i_workflow_type     => 'A',
                                                                 i_from_state        => 'A',
                                                                 i_to_state          => 'B',
                                                                 i_id_rehab_grid     => NULL,
                                                                 i_id_rehab_presc    => NULL,
                                                                 i_id_epis_origin    => l_episode,
                                                                 i_id_rehab_schedule => NULL,
                                                                 i_id_schedule       => l_schedule,
                                                                 i_id_cancel_reason  => NULL,
                                                                 i_cancel_notes      => NULL,
                                                                 i_transaction_id    => l_transaction_id,
                                                                 o_id_episode        => l_episode,
                                                                 o_error             => o_error);
                END IF;
            END IF;
        
        END IF;
    
        IF l_bool
        THEN
            IF l_transaction_id IS NOT NULL
            THEN
                pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            END IF;
        ELSE
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
        END IF;
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_VIDEOCONF_INFO',
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_videoconf_pat_register;
    --------------------------- PACKAGE INITIALIZATION ------------------------
BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
    -- Message stack.
    g_msg_stack := t_table_msg_stack(NULL);
END pk_schedule;
/
