/*-- Last Change Revision: $Rev: 2053893 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-30 14:20:45 +0000 (sex, 30 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_schedule_exam IS
    -- This package provides the exam scheduling logic for ALERT Scheduler.
    -- @author Nuno Guerreiro
    -- @version alpha

    ------------------------------ PRIVATE FUNCTIONS ---------------------------

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

    /**
    * Creates a new record on schedule_exam.
    * Private function.
    *
    * @param i_lang                            Language identifier
    * @param i_id_schedule_exam                Primary key
    * @param i_id_schedule                     Schedule identifier
    * @param i_id_exam                         Exam identifier
    * @param i_flg_preparation I               ndicates if the exam has preparation instructions
    * @param o_schedule_exam_rec               The record that is inserted into schedule_exam
    * @param o_error                           Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/29
    */
    FUNCTION new_schedule_exam
    (
        i_lang              language.id_language%TYPE DEFAULT NULL,
        i_id_schedule_exam  schedule_exam.id_schedule_exam%TYPE DEFAULT NULL,
        i_id_schedule       schedule_exam.id_schedule%TYPE,
        i_id_exam           schedule_exam.id_exam%TYPE DEFAULT NULL,
        i_flg_preparation   schedule_exam.flg_preparation%TYPE DEFAULT NULL,
        i_exam_req          schedule_exam.id_exam_req%TYPE,
        o_schedule_exam_rec OUT schedule_exam%ROWTYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32);
    BEGIN
        l_func_name := 'NEW_SCHEDULE_EXAM';
        -- If the primary key is passed as a parameter use it,
        -- else take the next value from sequence.
        g_error := 'GET SEQUENCE VALUE';
        IF (i_id_schedule_exam IS NOT NULL)
        THEN
            o_schedule_exam_rec.id_schedule_exam := i_id_schedule_exam;
        ELSE
            SELECT seq_schedule_exam.nextval
              INTO o_schedule_exam_rec.id_schedule_exam
              FROM dual;
        END IF;
        -- Create record
        g_error                             := 'CREATE RECORD';
        o_schedule_exam_rec.id_schedule     := i_id_schedule;
        o_schedule_exam_rec.id_exam         := i_id_exam;
        o_schedule_exam_rec.flg_preparation := i_flg_preparation;
        o_schedule_exam_rec.id_exam_req     := i_exam_req;
        -- Insert record
        g_error := 'INSERT RECORD';
        INSERT INTO schedule_exam
        VALUES o_schedule_exam_rec;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_schedule_exam_rec := NULL;
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
        
    END new_schedule_exam;

    ------------------------------ PUBLIC FUNCTIONS ---------------------------

    /*
    * Checks if an exam requires the patient to perform preparation steps.
    * 
    * @param i_lang              Language identifier.
    * @param i_id_exam           Exam identifier.
    * @param o_flg_prep          'Y' or 'N'.
    * @param o_prep_desc         Translated "yes" or "no"
    * @param o_error             Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/29
    */
    FUNCTION has_preparation
    (
        i_lang      language.id_language%TYPE,
        i_id_exam   exam.id_exam%TYPE,
        o_flg_prep  OUT VARCHAR2,
        o_prep_desc OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'HAS_PREPARATION';
    BEGIN
        g_error := 'GET PREPARATION';
        SELECT g_no, pk_schedule.get_domain_desc(i_lang, pk_schedule.g_yes_no_domain, g_no)
          INTO o_flg_prep, o_prep_desc
          FROM exam e
         WHERE e.id_exam = i_id_exam;
    
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
        
    END has_preparation;

    /*
    * Returns the exam preparation values.
    * 
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_flg_search          Whether or not should the 'All' option be included.
    * @param o_preparations        List of preparation options.
    * @param o_error               Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/30
    */
    FUNCTION get_preparations
    (
        i_lang         language.id_language%TYPE,
        i_prof         profissional,
        i_flg_search   VARCHAR2,
        o_preparations OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PREPARATIONS';
    BEGIN
        g_error := 'OPEN o_preparations FOR';
        -- Open cursor
        OPEN o_preparations FOR
            SELECT data, label, flg_select, order_field
              FROM (SELECT to_char(pk_schedule.g_all) data,
                           pk_schedule.get_message(i_lang, pk_schedule.g_msg_all) label,
                           g_yes flg_select,
                           1 order_field
                      FROM dual
                     WHERE i_flg_search = g_yes
                    UNION ALL
                    SELECT g_yes data,
                           pk_schedule.get_domain_desc(i_lang, pk_schedule.g_yes_no_domain, g_yes) label,
                           g_no flg_select,
                           2 order_field
                      FROM dual
                    UNION ALL
                    SELECT g_yes data,
                           pk_schedule.get_domain_desc(i_lang, pk_schedule.g_yes_no_domain, g_no) label,
                           g_no flg_select,
                           3 order_field
                      FROM dual)
             ORDER BY order_field;
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
        
    END get_preparations;

    /*
    * private function. used to check every schedule requisition's status.
    * If at least one req is executed or in an equivalent status, it is given order to not proceed with 
    * cancelation ou update or reschedule.
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_id_schedule            schedule id 
    * @param o_proceed                N= do not proceed  Y=ok
    * @param o_error                  error data
    * @return True if successful, false otherwise. 
    *
    * @author  Telmo
    * @version 2.5.0.7
    * @date    21-10-2009
    */
    FUNCTION get_reqs_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_proceed     OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_REQS_STATUS';
    BEGIN
        BEGIN
            SELECT g_no
              INTO o_proceed
              FROM (SELECT e.flg_status, flg_referral
                      FROM exam_req_det e
                      JOIN schedule_exam se
                        ON e.id_exam_req = se.id_exam_req
                     WHERE se.id_exam_req IS NOT NULL
                       AND se.id_schedule = i_id_schedule) t
             WHERE (t.flg_status IN
                   (pk_exam_constant.g_exam_read, pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_exec) OR
                   t.flg_referral IN (pk_exam_constant.g_flg_referral_r,
                                       pk_exam_constant.g_flg_referral_s,
                                       pk_exam_constant.g_flg_referral_i))
               AND rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_proceed := g_yes;
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
            RETURN FALSE;
    END get_reqs_status;

    /*
    * Gets the list of exams.
    *
    * @param   i_lang              Language identifier.
    * @param   i_prof              Professional.
    * @param   i_id_dep            Department identifier(s).
    * @param   i_id_dep_clin_serv  Department-Clinical Service identifier(s).
    * @param   i_flg_search        Whether or not should the 'All' option appear on the list of exams.
    * @param   o_exams             List of exams
    * @param   o_error             Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    */
    FUNCTION get_exams
    (
        i_lang             language.id_language%TYPE,
        i_prof             profissional,
        i_id_dep           VARCHAR2,
        i_id_dep_clin_serv VARCHAR2,
        i_flg_search       VARCHAR2,
        o_exams            OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_EXAMS';
        l_list_dcs  table_number;
        l_list_deps table_number;
    BEGIN
        g_error := 'GET LISTS';
        -- Get lists
        l_list_dcs  := pk_schedule.get_list_number_csv(i_id_dep_clin_serv);
        l_list_deps := pk_schedule.get_list_number_csv(i_id_dep);
        g_error     := 'OPEN o_exams FOR';
        -- Open cursor
        OPEN o_exams FOR
            SELECT data, flg_select, label, order_field
              FROM (SELECT pk_schedule.g_all data,
                           pk_schedule.g_yes flg_select,
                           pk_message.get_message(i_lang, pk_schedule.g_msg_all) label,
                           1 order_field
                      FROM dual
                     WHERE i_flg_search = pk_schedule.g_yes
                    UNION
                    SELECT e.id_exam data,
                           pk_schedule.g_no flg_select,
                           pk_exams_api_db.get_alias_translation(i_lang, i_prof, e.code_exam, NULL) label,
                           9 order_field
                      FROM exam               e,
                           exam_cat           ec,
                           exam_cat_dcs       ecd,
                           dep_clin_serv      dcs,
                           clinical_service   cs,
                           department         d,
                           exam_dep_clin_serv edcs
                     WHERE d.id_department = dcs.id_department
                       AND (i_id_dep IS NULL OR i_id_dep = to_char(pk_schedule.g_all) OR
                           d.id_department IN (SELECT *
                                                  FROM TABLE(l_list_deps)))
                       AND cs.id_clinical_service = dcs.id_clinical_service
                       AND dcs.id_dep_clin_serv = ecd.id_dep_clin_serv
                       AND (edcs.id_dep_clin_serv IS NULL OR dcs.id_dep_clin_serv = edcs.id_dep_clin_serv)
                       AND edcs.id_exam = e.id_exam
                       AND edcs.id_institution = i_prof.institution
                       AND edcs.id_software = i_prof.software
                       AND ecd.id_exam_cat = ec.id_exam_cat
                       AND e.id_exam_cat = ec.id_exam_cat
                       AND (i_id_dep_clin_serv IS NULL OR i_id_dep_clin_serv = to_char(pk_schedule.g_all) OR
                           dcs.id_dep_clin_serv IN (SELECT *
                                                       FROM TABLE(l_list_dcs)))
                       AND e.flg_available = g_yes
                       AND edcs.flg_type = pk_exam_constant.g_exam_can_req)
             WHERE label IS NOT NULL
             ORDER BY order_field, label ASC;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_types.open_my_cursor(o_exams);
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
        
    END get_exams;

    /*
    * Gets the schedules, vacancies and patient icons for the daily view.
    * 
    * @param i_lang            Language identifier.
    * @param i_prof            Professional.
    * @param i_args            UI args.
    * @param i_id_patient      Patient identifier.
    * @param o_vacants         Vacancies.
    * @param o_schedule        Schedules.
    * @param o_patient_icons   Patient icons.
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    *
    * UPDATED
    * added column flg_cancel_schedule to output cursor o_schedule
    * @author  Telmo Castro
    * @date    25-07-2008
    * @version 2.4.3
    *
    * UPDATED
    * ALERT-31987 - output da get_vacancies passa a ser a GTT sch_tmptab_vacs em vez do table_number
    * @author  Telmo
    * @date    12-06-2009
    * @version 2.5.0.4
    *
    * alert-8202. exam vacancies are now exam-id-independent
    * @author Telmo
    * @version 2.5.0.7
    * @date    15-10-2009
    *
    * UPDATED
    * alert-8202. new cursor for the exams in each schedule
    * @author  Telmo Castro
    * @date    16-10-2009
    * @version 2.5.0.7
    */
    FUNCTION get_hourly_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_args          IN table_varchar,
        i_id_patient    IN sch_group.id_patient%TYPE,
        o_vacants       OUT pk_types.cursor_type,
        o_schedules     OUT pk_types.cursor_type,
        o_sch_exams     OUT pk_types.cursor_type,
        o_patient_icons OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_HOURLY_DETAIL';
        l_list_vacancies table_number;
        l_list_schedules table_number;
        l_func_exception EXCEPTION;
    
        -- Inner function to retrieve the vacancies.
        FUNCTION inner_get_vacancies RETURN pk_types.cursor_type IS
            l_vacants pk_types.cursor_type;
        BEGIN
            g_error := 'OPEN l_vacants FOR';
            -- Open l_vacants
            OPEN l_vacants FOR
                SELECT /*+ first_rows */
                 id_sch_consult_vacancy,
                 pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                 pk_date_utils.date_send_tsz(i_lang, dt_end_tstz, i_prof) dt_end,
                 id_sch_event,
                 id_prof id_prof,
                 (SELECT dcs.id_department
                    FROM dep_clin_serv dcs
                   WHERE dcs.id_dep_clin_serv = id_dcs) id_dep,
                 id_dcs id_dep_clin_serv,
                 max_vacancies - used_vacancies num_vacancies,
                 decode(flg_img,
                        ' ',
                        NULL,
                        lpad(rank, 6, 0) ||
                        pk_sysdomain.get_img(i_lang, pk_schedule.g_sch_event_flg_img_domain, flg_img)) img_sched,
                 pk_schedule.string_dep_clin_serv(i_lang, id_dcs) desc_dcs,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof) nick_prof,
                 pk_schedule_common.get_translation_alias(i_lang, i_prof, id_sch_event2, code_sch_event) desc_event,
                 pk_schedule.string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                 pk_schedule.string_department(i_lang,
                                               (SELECT dcs.id_department
                                                  FROM dep_clin_serv dcs
                                                 WHERE dcs.id_dep_clin_serv = id_dcs)) desc_department,
                 pk_schedule.has_permission(i_lang, i_prof, id_dcs, id_sch_event2, id_prof) has_permission,
                 NULL flg_prep, -- como deixou de haver exames nas vagas este campo nao tem valor
                 pk_schedule.is_vacancy_available(id_sch_consult_vacancy) flg_available
                  FROM (SELECT scv.id_sch_consult_vacancy,
                               scv.dt_begin_tstz,
                               scv.dt_end_tstz,
                               scv.id_sch_event,
                               scv.id_prof,
                               scv.id_dep_clin_serv       id_dcs,
                               scv.max_vacancies,
                               scv.used_vacancies,
                               se.flg_img,
                               se.rank,
                               se.code_sch_event,
                               se.id_sch_event            id_sch_event2
                          FROM sch_tmptab_vacs stv, sch_consult_vacancy scv, sch_event se
                         WHERE se.id_sch_event = scv.id_sch_event
                           AND stv.id_sch_consult_vacancy = scv.id_sch_consult_vacancy)
                 ORDER BY dt_begin_tstz, id_prof, id_dcs;
            RETURN l_vacants;
        END inner_get_vacancies;
    
        -- Inner function to get schedules
        FUNCTION inner_get_schedules(i_list_schedules table_number) RETURN pk_types.cursor_type IS
            l_schedules pk_types.cursor_type;
            l_cv        sys_config.value%TYPE;
        BEGIN
            -- Telmo 25-07-2008
            g_error := 'GET CONFIG VALUE FOR FLG_CANCEL_SCHEDULE';
            IF NOT pk_sysconfig.get_config(pk_schedule_common.g_flg_cancel_schedule, i_prof, l_cv)
            THEN
                RAISE l_func_exception;
            END IF;
        
            g_error := 'OPEN l_schedules FOR';
            -- Open cursor
            OPEN l_schedules FOR
                SELECT /*+ first_rows */
                 id_schedule,
                 pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                 pk_date_utils.date_send_tsz(i_lang, dt_end_tstz, i_prof) dt_end,
                 id_patient,
                 pk_patient.get_gender(i_lang, gender) AS gender,
                 pk_patient.get_pat_age(i_lang, id_patient, i_prof) age,
                 decode(pk_patphoto.check_blob(id_patient), g_no, '', pk_patphoto.get_pat_foto(id_patient, i_prof)) photo,
                 name,
                 pk_schedule.get_num_clin_record(id_patient, i_args(idx_id_inst)) num_clin_record,
                 lpad(rank, 6, 0) || pk_sysdomain.get_img(i_lang, pk_schedule.g_sch_event_flg_img_domain, flg_img) img_sched,
                 id_sch_event,
                 pk_schedule.calc_icon(i_lang,
                                       id_schedule,
                                       id_instit_requested,
                                       id_dcs_requested,
                                       id_sch_event,
                                       dt_begin_tstz,
                                       dt_end_tstz,
                                       (SELECT id_professional
                                          FROM sch_resource sr
                                         WHERE sr.id_schedule = id_schedule
                                           AND rownum = 1),
                                       NULL,
                                       (CASE flg_status
                                           WHEN pk_schedule.g_sched_status_temporary THEN
                                            g_yes
                                           ELSE
                                            g_no
                                       END),
                                       flg_status,
                                       flg_vacancy,
                                       id_sch_consult_vacancy) img_schedule,
                 pk_schedule.g_icon_prefix ||
                 pk_sysdomain.get_img(i_lang, pk_schedule.g_sched_flg_notif_status, flg_notification) img_notification,
                 flg_notification,
                 flg_status,
                 id_sch_consult_vacancy,
                 id_professional id_prof,
                 (SELECT dcs.id_department
                    FROM dep_clin_serv dcs
                   WHERE dcs.id_dep_clin_serv = id_dcs_requested) id_dep,
                 id_dcs_requested id_dep_clin_serv,
                 pk_schedule.string_language(i_lang, id_lang_translator) desc_lang_translator,
                 pk_schedule.string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                 pk_schedule.string_clin_serv_by_dcs(i_lang, id_dcs_requested) dcs_description,
                 pk_schedule.string_sch_event(i_lang, id_sch_event) event_description,
                 pk_schedule.string_sch_type(i_lang, flg_sch_type) desc_sch_type,
                 pk_schedule.string_department(i_lang,
                                               (SELECT dcs.id_department
                                                  FROM dep_clin_serv dcs
                                                 WHERE dcs.id_dep_clin_serv = id_dcs_requested)) desc_department,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) nick_prof,
                 pk_schedule.has_permission(i_lang, i_prof, id_dcs_requested, id_sch_event, id_professional) has_permission,
                 pk_schedule.is_conflicting(id_schedule) flg_conflict,
                 l_cv flg_cancel_schedule,
                 (CASE
                      WHEN idscd IS NULL THEN
                       NULL
                      ELSE
                       (SELECT d.id_sch_combi
                          FROM sch_combi_detail d
                         WHERE d.id_sch_combi_detail = idscd)
                  END) id_combi
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
                               s.id_instit_requested,
                               s.flg_sch_type,
                               s.id_sch_combi_detail idscd,
                               pat.id_patient,
                               pat.gender,
                               pat.name,
                               se.rank,
                               se.flg_img,
                               sr.id_professional
                          FROM schedule s, sch_resource sr, sch_group sg, sch_event se, patient pat
                         WHERE se.id_sch_event = s.id_sch_event
                           AND sr.id_schedule(+) = s.id_schedule
                           AND sg.id_schedule(+) = s.id_schedule
                           AND pat.id_patient(+) = sg.id_patient
                           AND s.id_schedule IN (SELECT *
                                                   FROM TABLE(i_list_schedules))
                        
                        )
                 ORDER BY dt_begin_tstz, id_professional, id_dcs_requested, flg_status, flg_vacancy;
            RETURN l_schedules;
        END inner_get_schedules;
    
        /* inner function to retrieve all exams from all given schedules */
        FUNCTION inner_get_exams(i_list_schedules table_number) RETURN pk_types.cursor_type IS
            l_cur pk_types.cursor_type;
        BEGIN
            g_error := 'OPEN exams cursor';
            -- Open cursor
            OPEN l_cur FOR
                SELECT s.id_schedule,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, code_exam, NULL) desc_exam,
                       se.id_exam,
                       pk_sysdomain.get_domain(g_yes_no, 'N', i_lang) flg_prep,
                       'N' flg_pat_prep
                  FROM schedule s
                 INNER JOIN schedule_exam se
                    ON s.id_schedule = se.id_schedule
                  JOIN exam e
                    ON se.id_exam = e.id_exam
                 WHERE s.id_schedule IN (SELECT *
                                           FROM TABLE(i_list_schedules))
                 ORDER BY s.id_schedule;
            RETURN l_cur;
        END inner_get_exams;
    
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_VACANCIES';
        -- Get vacancies' identifiers using the selected criteria.
        IF NOT
            pk_schedule_common.get_vacancies(i_lang => i_lang, i_prof => i_prof, i_args => i_args, o_error => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL INNER_GET_VACANCIES';
        -- Get vacancies
        o_vacants := inner_get_vacancies();
    
        g_error := 'CALL GET_SCHEDULES';
        -- Get schedules' identifiers using the selected criteria.
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
    
        g_error := 'CALL INNER_GET_SCHEDULES';
        -- Get schedules
        o_schedules := inner_get_schedules(i_list_schedules => l_list_schedules);
    
        g_error := 'CALL GET_PATIENT_ICONS';
        -- Get patient icons
        IF NOT pk_schedule.get_patient_icons(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_args          => i_args,
                                             i_id_patient    => i_id_patient,
                                             o_patient_icons => o_patient_icons,
                                             o_error         => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- get exams cursor                                     
        g_error     := 'CALL INNER_GET_EXAMS';
        o_sch_exams := inner_get_exams(i_list_schedules => l_list_schedules);
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_date_utils.set_dst_time_check_on;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
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
            pk_types.open_my_cursor(o_vacants);
            pk_types.open_my_cursor(o_schedules);
            pk_types.open_my_cursor(o_patient_icons);
            pk_types.open_my_cursor(o_sch_exams);
            RETURN FALSE;
    END get_hourly_detail;

    /**
    * Determines if the given schedule information follow schedule rules : 
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
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.        
    * @param o_flg_show           Set if a message is displayed or not 
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.    
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Tiago Ferreira
    * @version  1.0
    * @since 2007/05/17
    *
    * UPDATED
    * a current_timestamp deixa de ser truncada no time. Passou a usar novo modelo da msg_stack para se conseguir
    * saber se certa mensagem vem na stack
    * @author Telmo Castro
    * @date 29-08-2008
    * @version 2.4.3
    *
    * FIXED
    * na deteccao da l_Exists200 faltava o nvl para prevenir nulos
    * @author Telmo Castro
    * @date 15-10-2008
    * @version 2.4.3.x  
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
        g_error       := 'CALL VALIDATE_SCHEDULE';
    
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
            pk_schedule.message_flush(o_msg);
            --  o_button := pk_schedule.g_cancel_button_code || pk_message.get_message(i_lang, pk_schedule.g_cancel_button) || '|';
            -- o_button := 'R829664' || /*pk_schedule.g_cancel_button_code*/ 'pk_message.get_message(i_lang, pk_schedule.g_cancel_button)*/ || '|';
        
            -- Telmo 29-08-2008. procura pela mensagem da data de agendamento inferior a' data actual
            i := pk_schedule.g_msg_stack.first;
            WHILE i IS NOT NULL
                  AND l_exists200 = FALSE
            LOOP
                l_msg_stack := pk_schedule.g_msg_stack(i);
                l_exists200 := l_msg_stack.idxmsg = pk_schedule.g_begindatelower;
                i           := pk_schedule.g_msg_stack.next(i);
            END LOOP;
        
            -- omite o botao de prosseguir se essa mensagem esta' na stack
            IF NOT nvl(l_exists200, FALSE)
            THEN
                o_button := pk_schedule.g_cancel_button_code ||
                            pk_message.get_message(i_lang, pk_schedule.g_cancel_button) || '|' ||
                            pk_schedule.g_ok_button_code ||
                            pk_message.get_message(i_lang, pk_schedule.g_sched_msg_ignore_proceed) || '|';
            ELSE
                o_button := pk_schedule.g_r_button_code || pk_message.get_message(i_lang, pk_schedule.g_sched_msg_read) || '|';
            END IF;
            o_flg_show    := g_yes;
            o_flg_proceed := g_yes;
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
        
    END validate_schedule;

    /**
    * Determines if the given schedule information follow schedule rules : 
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
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.        
    * @param o_flg_show           Set if a message is displayed or not 
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.    
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Sofia Mendes
    * @version  1.0
    * @since 2007/05/17    
    */
    FUNCTION validate_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN sch_group.id_patient%TYPE,
        i_dt_begin    IN VARCHAR2,
        o_flg_proceed OUT VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(18) := 'VALIDATE_UPDATE';
        l_dt_begin  TIMESTAMP WITH LOCAL TIME ZONE;
        l_msg       VARCHAR2(4000 CHAR);
    BEGIN
        o_flg_proceed := g_yes;
        o_flg_show    := g_no;
    
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
    
        -- RULE : Begin date should not be lower than the current date ------------------------------
        g_error := 'RULE : Begin date should not be lower than the current date';
        IF l_dt_begin < current_timestamp
        THEN
        
            o_msg := pk_message.get_message(i_lang, pk_schedule.g_dt_bg_lw_cr_dt);
        
            pk_alertlog.log_warn(text        => l_func_name ||
                                                ': Trying to create a schedule whose begin date should not be lower than the current date',
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            -- Add warning message            
            o_msg_title   := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_button      := pk_schedule.g_r_button_code ||
                             pk_message.get_message(i_lang, pk_schedule.g_sched_msg_read) || '|';
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
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
        
    END validate_update;

    /**
    * Determines if the given schedule information follow schedule rules : 
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *
    * @param i_lang                   Language.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Old schedule identifier.
    * @param i_id_dep_clin_serv       Department-Clinical service identifier.
    * @param i_id_sch_event           Event identifier.
    * @param i_id_prof                Professional that carries out the schedule.
    * @param i_dt_begin               Begin date.
    * @param o_sv_stop                warning to the caller telling that this reschedule violates dependencies inside a single visit
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Guerreiro (Tiago Ferreira)
    * @version  1.0
    * @since 2007/05/22
    *
    * UPDATED
    * added i_id_new_exam and removed i_id_dep_clin_serv to validate the type of exam. DCS can be different
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    01-09-2008 
    *
    * UPDATED
    * alert-8202. there can be several exams per schedule
    * @author  Telmo
    * @version 2.5.0.7
    * @date    21-10-2009
    */
    FUNCTION validate_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_id_sch_event    IN schedule.id_sch_event%TYPE,
        i_id_prof         IN sch_resource.id_professional%TYPE,
        i_dt_begin        IN VARCHAR2,
        o_sv_stop         OUT VARCHAR2,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(19) := 'VALIDATE_RESCHEDULE';
        l_old_ids_exams table_number;
        l_proceed       VARCHAR2(1);
    BEGIN
        o_flg_proceed := g_yes;
        o_flg_show    := g_no;
    
        -- check if we can cancel the current schedule
        g_error := 'CALL GET_REQS_STATUS';
        IF NOT get_reqs_status(i_lang, i_prof, i_old_id_schedule, l_proceed, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- no can do    
        IF l_proceed = g_no
        THEN
            o_flg_show    := g_yes;
            o_msg_title   := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_no_cancel);
            o_button      := pk_schedule.g_r_button_code || pk_message.get_message(i_lang, pk_schedule.g_r_button_code);
            o_flg_proceed := g_no;
            o_sv_stop     := g_no;
            RETURN TRUE;
        END IF;
    
        RETURN pk_schedule.validate_reschedule(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_old_id_schedule  => i_old_id_schedule,
                                               i_id_dep_clin_serv => NULL,
                                               i_id_sch_event     => i_id_sch_event,
                                               i_id_prof          => i_id_prof,
                                               i_dt_begin         => i_dt_begin,
                                               o_sv_stop          => o_sv_stop,
                                               o_flg_proceed      => o_flg_proceed,
                                               o_flg_show         => o_flg_show,
                                               o_msg              => o_msg,
                                               o_msg_title        => o_msg_title,
                                               o_button           => o_button,
                                               o_error            => o_error);
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
        
    END validate_reschedule;

    /*
    * Creates exam schedule.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
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
    * @param i_ids_exams          Exam identifiers  
    * @param i_reason_notes       Reason for appointment in free-text
    * @param i_ids_exam_reqs      list of exam requisitions
    * @param i_id_schedule_ref    old schedule id. Used if this function is called by update_schedule
    * @param i_flg_schedule_via   via de agendamento (telefone, email, ...)
    * @param i_do_overlap         null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be 
    *                             issued with Y or N
    * @param i_id_consult_vac     vacancy id. Can be null, depending on the value of i_sch_option
    * @param i_sch_option         'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule)
    * @param i_id_episode         episode id
    * @param i_id_sch_combi_detail used in single visit. This id relates this schedule with the combination detail line
    * @param o_id_schedule        New schedule id 
    * @param o_id_schedule_exam   new schedule exam id
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set if a message is displayed or not      
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.    
    * @param o_error              Error message if something goes wrong
    *       
    * @return   True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     02-06-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * o parametro id_exam_req_det passou a i_id_exam_req (tabela exam_req) para uniformizar com a 
    * create_schedule_exam, create_reschedule, update_schedule
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    20-06-2008
    *
    * UPDATED
    * acrescentado o parametro o_id_schedule_exam
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    29-07-2008    
    *
    * UPDATED
    * a flg_sch_type passa a ser calculada dentro do pk_schedule.create_schedule. Vai daqui a null
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    25-08-2008
    *
    * UPDATED alert-8202. passa a receber uma lista de exames e uma lista de reqs
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    13-10-2009
    */
    FUNCTION create_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv    IN schedule.id_dcs_requested%TYPE,
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
        i_ids_exams           IN table_number DEFAULT NULL,
        i_reason_notes        IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_ids_exam_reqs       IN table_number DEFAULT NULL,
        i_id_schedule_ref     IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_flg_request_type    IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via    IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap          IN VARCHAR2,
        i_id_consult_vac      IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option          IN VARCHAR2,
        i_id_episode          IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_sch_combi_detail IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        o_id_schedule         OUT schedule.id_schedule%TYPE,
        o_id_schedule_exam    OUT schedule_exam.id_schedule_exam%TYPE,
        o_flg_proceed         OUT VARCHAR2,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'CREATE_SCHEDULE';
        l_id_schedule    schedule.id_schedule%TYPE;
        l_retval         BOOLEAN;
        l_func_exception EXCEPTION;
        o_new_ids        table_number;
    BEGIN
        o_flg_proceed := g_no;
        o_flg_show    := g_no;
    
        g_error := 'CALL CREATE_SCHEDULE';
        -- Create the schedule
        l_retval := pk_schedule.create_schedule(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_patient          => table_number(i_id_patient),
                                                i_id_dep_clin_serv    => i_id_dep_clin_serv,
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
                                                i_id_schedule_ref     => i_id_schedule_ref,
                                                i_id_room             => i_id_room,
                                                i_flg_sch_type        => NULL,
                                                i_reason_notes        => i_reason_notes,
                                                i_flg_request_type    => i_flg_request_type,
                                                i_flg_schedule_via    => i_flg_schedule_via,
                                                i_do_overlap          => i_do_overlap,
                                                i_id_consult_vac      => i_id_consult_vac,
                                                i_sch_option          => i_sch_option,
                                                i_id_episode          => i_id_episode,
                                                i_id_sch_combi_detail => i_id_sch_combi_detail,
                                                o_id_schedule         => l_id_schedule,
                                                o_flg_proceed         => o_flg_proceed,
                                                o_flg_show            => o_flg_show,
                                                o_msg                 => o_msg,
                                                o_msg_title           => o_msg_title,
                                                o_button              => o_button,
                                                o_error               => o_error);
        IF l_retval
           AND o_flg_show = g_yes
        THEN
            RETURN TRUE;
        ELSIF NOT l_retval
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'CREATE SCHEDULE EXAM';
        -- Create exam-specific data.
        l_retval := create_schedule_exam(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_schedule   => l_id_schedule,
                                         i_ids_exam_reqs => i_ids_exam_reqs,
                                         i_dt_begin      => i_dt_begin,
                                         i_id_episode    => i_id_episode,
                                         i_ids_exams     => i_ids_exams,
                                         i_id_patient    => i_id_patient,
                                         o_new_ids       => o_new_ids,
                                         o_flg_proceed   => o_flg_proceed,
                                         o_flg_show      => o_flg_show,
                                         o_msg           => o_msg,
                                         o_msg_title     => o_msg,
                                         o_button        => o_button,
                                         o_error         => o_error);
        IF l_retval
           AND o_flg_show = g_yes
        THEN
            pk_utils.undo_changes;
            RETURN TRUE;
        ELSIF NOT l_retval
        THEN
            RAISE l_func_exception;
        END IF;
    
        o_id_schedule := l_id_schedule;
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
        
    END create_schedule;

    /**
    * Reschedules an appointment.
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Identifier of the appointment to be rescheduled.
    * @param i_id_prof                Target professional.
    * @param i_dt_begin               Start date
    * @param i_dt_end                 End date
    * @param o_id_schedule            Identifier of the new schedule.
    * @param o_id_schedule_exam       new schedule exam id
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.    
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
    * incluida invocacao da pk_exams_api_db.set_exam_date para update da data na tabela exam_req
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    20-06-2008
    *
    * UPDATED
    * acrescentado o parametro o_id_schedule_exam
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    29-07-2008 
    */
    FUNCTION create_reschedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_old_id_schedule  IN schedule.id_schedule%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_do_overlap       IN VARCHAR2,
        i_id_consult_vac   IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option       IN VARCHAR2,
        o_id_schedule      OUT schedule.id_schedule%TYPE,
        o_id_schedule_exam OUT schedule_exam.id_schedule_exam%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_flg_proceed      OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(19) := 'CREATE_RESCHEDULE';
        l_ret            BOOLEAN;
        l_func_exception EXCEPTION;
        l_ids_exam_reqs  table_number := table_number();
        l_ids_exams      table_number := table_number();
        l_out_ids        table_number;
        l_retval         BOOLEAN;
        l_id_patient     sch_group.id_patient%TYPE;
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT vse.id_schedule,
                   vse.id_exam,
                   vse.id_exam_req,
                   (SELECT id_patient
                      FROM sch_group sg
                     WHERE sg.id_schedule = vse.id_schedule
                       AND rownum = 1) id_pat
              FROM v_schedule_exam vse
             WHERE vse.id_schedule = c_sched.i_old_id_schedule;
    
        -- Returns a record containing the old schedule's data
        FUNCTION inner_get_old_schedule
        (
            i_old_id_schedule schedule.id_schedule%TYPE,
            o_ids_reqs        OUT table_number,
            o_ids_exams       OUT table_number
        ) RETURN BOOLEAN IS
            l_ret           c_sched%ROWTYPE;
            l_ids_exam_reqs table_number := table_number();
            l_ids_exams     table_number := table_number();
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(inner_get_old_schedule.i_old_id_schedule);
            LOOP
                g_error := 'FETCH c_sched';
                FETCH c_sched
                    INTO l_ret;
                EXIT WHEN c_sched%NOTFOUND;
                l_ids_exam_reqs.extend;
                l_ids_exam_reqs(l_ids_exam_reqs.last) := l_ret.id_exam_req;
                l_ids_exams.extend;
                l_ids_exams(l_ids_exams.last) := l_ret.id_exam;
                l_id_patient := l_ret.id_pat;
            END LOOP;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
        
            --Sofia Mendes (18-11-2009): ALERT-57520
            o_ids_reqs  := l_ids_exam_reqs;
            o_ids_exams := l_ids_exams;
            --
            RETURN TRUE;
        
        END inner_get_old_schedule;
    BEGIN
        o_flg_proceed := g_no;
        o_flg_show    := g_no;
    
        g_error := 'CREATE RESCHEDULE';
        -- Call the generic reschedule function.
        l_retval := pk_schedule.create_reschedule(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_old_id_schedule => i_old_id_schedule,
                                                  i_id_prof         => i_id_prof,
                                                  i_dt_begin        => i_dt_begin,
                                                  i_dt_end          => i_dt_end,
                                                  i_do_overlap      => i_do_overlap,
                                                  i_id_consult_vac  => i_id_consult_vac,
                                                  i_sch_option      => nvl(i_sch_option, pk_schedule.g_sch_option_update),
                                                  o_id_schedule     => o_id_schedule,
                                                  o_flg_show        => o_flg_show,
                                                  o_flg_proceed     => o_flg_proceed,
                                                  o_msg             => o_msg,
                                                  o_msg_title       => o_msg_title,
                                                  o_button          => o_button,
                                                  o_error           => o_error);
        IF l_retval
           AND o_flg_show = g_yes
        THEN
            pk_utils.undo_changes;
            RETURN TRUE;
        ELSIF NOT l_retval
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'GET OLD SCHEDULE';
        -- Get old schedule
        l_ret := inner_get_old_schedule(i_old_id_schedule, l_ids_exam_reqs, l_ids_exams);
    
        g_error := 'CREATE SCHEDULE EXAM';
        -- Create exam-specific data.
        l_retval := create_schedule_exam(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_schedule   => o_id_schedule,
                                         i_ids_exam_reqs => l_ids_exam_reqs,
                                         i_dt_begin      => i_dt_begin,
                                         i_id_episode    => NULL,
                                         i_ids_exams     => l_ids_exams,
                                         i_id_patient    => l_id_patient,
                                         o_new_ids       => l_out_ids,
                                         o_flg_proceed   => o_flg_proceed,
                                         o_flg_show      => o_flg_show,
                                         o_msg           => o_msg,
                                         o_msg_title     => o_msg,
                                         o_button        => o_button,
                                         o_error         => o_error);
        IF l_retval
           AND o_flg_show = g_yes
        THEN
            pk_utils.undo_changes;
            RETURN TRUE;
        ELSIF NOT l_retval
        THEN
            RAISE l_func_exception;
        END IF;
    
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
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_schedule               List of schedules (identifiers) to reschedule.
    * @param i_id_prof                Target professional's identifier.
    * @param i_dt_begin               Start date.
    * @param i_dt_end                 End date.
    * @param i_id_dep                 Selected department's identifier.
    * @param i_id_dep_clin_serv       Selected Department-Clinical Service's identifier.
    * @param i_id_event               Selected event's identifier.
    * @param i_id_exam                Selected exam's identifier.
    * @param o_list_sch_hour          List of schedule identifiers + start date + end date (for schedules that can be rescheduled).
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/25
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
        o_list_sch_hour    OUT table_varchar,
        o_flg_proceed      OUT VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'VALIDATE_MULT_RESCHEDULE';
    BEGIN
        RETURN pk_schedule.validate_mult_reschedule(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_schedules        => i_schedules,
                                                    i_id_prof          => i_id_prof,
                                                    i_dt_begin         => i_dt_begin,
                                                    i_dt_end           => i_dt_end,
                                                    i_id_dep           => i_id_dep,
                                                    i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                    i_id_event         => i_id_event,
                                                    i_id_exam          => i_id_exam,
                                                    o_list_sch_hour    => o_list_sch_hour,
                                                    o_flg_proceed      => o_flg_proceed,
                                                    o_flg_show         => o_flg_show,
                                                    o_msg              => o_msg,
                                                    o_msg_title        => o_msg_title,
                                                    o_button           => o_button,
                                                    o_error            => o_error);
    END validate_mult_reschedule;

    /*
    * Reschedules several appointments.
    * 
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_prof            Target Professional.
    * @param i_schedules          List of schedules.
    * @param i_start_dates        List of start dates.
    * @param i_end_dates          List of end dates.
    * @param o_error              Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/08
    */
    FUNCTION create_mult_reschedule
    (
        i_lang         language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof      IN professional.id_professional%TYPE,
        i_schedules    IN table_varchar,
        i_start_dates  IN table_varchar,
        i_end_dates    IN table_varchar,
        i_do_overlap   IN VARCHAR2,
        i_ids_cons_vac IN table_number,
        i_sch_option   IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'CREATE_MULT_RESCHEDULE';
        l_id_schedule    schedule.id_schedule%TYPE;
        l_id_sched_exam  schedule_exam.id_schedule_exam%TYPE;
        l_flg_show       VARCHAR2(1);
        l_flg_proceed    VARCHAR2(1);
        l_msg            VARCHAR2(32000);
        l_msg_title      VARCHAR2(32000);
        l_button         VARCHAR2(200);
        l_func_exception EXCEPTION;
    BEGIN
        -- Iterate on schedules
        g_error := 'ITERATE ON SCHEDULES';
        FOR idx IN i_schedules.first .. i_schedules.last
        LOOP
            -- Reschedule each appointment
            IF NOT create_reschedule(i_lang             => i_lang,
                                     i_prof             => i_prof,
                                     i_old_id_schedule  => i_schedules(idx),
                                     i_id_prof          => i_id_prof,
                                     i_dt_begin         => i_start_dates(idx),
                                     i_dt_end           => i_end_dates(idx),
                                     i_sch_option       => i_sch_option,
                                     i_id_consult_vac   => i_ids_cons_vac(idx),
                                     i_do_overlap       => i_do_overlap,
                                     o_id_schedule      => l_id_schedule,
                                     o_id_schedule_exam => l_id_sched_exam,
                                     o_flg_show         => l_flg_show,
                                     o_flg_proceed      => l_flg_proceed,
                                     o_msg              => l_msg,
                                     o_msg_title        => l_msg_title,
                                     o_button           => l_button,
                                     o_error            => o_error)
            THEN
                -- Reset state
                RAISE l_func_exception;
            END IF;
        END LOOP;
    
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
        
    END create_mult_reschedule;

    /**
    * Gets the exam description.
    * To be used inside SQL statements.
    *
    * @param   i_lang            Language identifier.
    * @param   i_id_exam         Exam identifier
    *
    * @return  Translated description of the exam
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/07/20
    */
    FUNCTION string_exam
    (
        i_lang    IN language.id_language%TYPE,
        i_id_exam IN clinical_service.id_clinical_service%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        IF i_id_exam IS NULL
        THEN
            RETURN '';
        ELSE
            RETURN pk_schedule_common.string_translation(i_lang   => i_lang,
                                                         i_select => 'e.code_exam',
                                                         i_from   => 'exam e',
                                                         i_where  => 'e.id_exam = ' || nvl(to_char(i_id_exam), 'NULL'));
        END IF;
    END string_exam;

    /*
    * Returns the identifier of the exam associated with the schedule.
    * To be used inside SQL statements.
    * 
    * @param i_id_schedule    Schedule identifier.
    * 
    * @return identifier of the exam associated with the schedule.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/07/20
    *
    * @ UPDATED - alert-8202 now returns all exam ids under a schedule id, csv style
    * @author  Telmo
    * @version 2.5.0.7
    * @date    19-10-2009
    */
    FUNCTION get_exam_id_by_sch(i_id_schedule schedule.id_schedule%TYPE) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'GET_EXAM_ID_BY_SCH';
        l_id_exam   VARCHAR2(2000);
    BEGIN
        g_error := 'GET EXAM IDENTIFIER';
        BEGIN
            -- hi-tech query ahead
            SELECT dd.idez
              INTO l_id_exam
              FROM (WITH data AS (SELECT id_schedule,
                                         id_exam,
                                         row_number() over(PARTITION BY id_schedule ORDER BY id_exam) rn,
                                         COUNT(*) over(PARTITION BY id_schedule) cnt
                                    FROM schedule_exam se
                                   WHERE se.id_schedule = i_id_schedule
                                   GROUP BY id_schedule, id_exam)
                       SELECT ltrim(sys_connect_by_path(id_exam, ','), ',') idez
                         FROM data
                        WHERE rn = cnt
                        START WITH rn = 1
                       CONNECT BY PRIOR id_schedule = id_schedule
                              AND PRIOR rn = rn - 1) dd;
        
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_exam := NULL;
        END;
    
        RETURN l_id_exam;
    EXCEPTION
        WHEN OTHERS THEN
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_id_exam;
    END get_exam_id_by_sch;

    /*
    * Returns the exam's description  
    * 
    * @param i_lang         Language identifier.
    * @param i_id_schedule  Schedule identifier.
    * 
    * @return Exam's description. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/07/20
    *
    * @ UPDATED - alert-8202 now returns all exam descs under a schedule id, csv style
    * @author  Telmo
    * @version 2.5.0.7
    * @date    19-10-2009
    */
    FUNCTION get_exam_desc_by_sch
    (
        i_lang        language.id_language%TYPE,
        i_id_schedule schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'GET_EXAM_DESC_BY_SCH';
        l_exam_desc VARCHAR2(4000) := '';
    BEGIN
    
        g_error := 'GET EXAM DESCRIPTIONS';
        BEGIN
            SELECT dd.descricons
              INTO l_exam_desc
              FROM (WITH data AS (SELECT id_schedule,
                                         translate(pk_translation.get_translation(i_lang, x.code_exam), ';', ',') descricon,
                                         row_number() over(PARTITION BY id_schedule ORDER BY pk_translation.get_translation(i_lang, x.code_exam)) rn,
                                         COUNT(*) over(PARTITION BY id_schedule) cnt
                                    FROM schedule_exam se
                                    JOIN exam x
                                      ON se.id_exam = x.id_exam
                                   WHERE se.id_schedule = i_id_schedule
                                   GROUP BY id_schedule, pk_translation.get_translation(i_lang, x.code_exam))
                       SELECT ltrim(sys_connect_by_path(descricon, '; '), '; ') descricons
                         FROM data
                        WHERE rn = cnt
                        START WITH rn = 1
                       CONNECT BY PRIOR id_schedule = id_schedule
                              AND PRIOR rn = rn - 1) dd;
        
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        RETURN l_exam_desc;
    EXCEPTION
        WHEN OTHERS THEN
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN '';
    END get_exam_desc_by_sch;

    /*
    * Performs the validations for creating exam appointments.
    * 
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                UI search criteria.
    * @param i_sch_args            Appointment criteria.    
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
    */
    FUNCTION validate_schedule_mult
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_args        IN table_varchar,
        i_sch_args    IN table_varchar,
        o_dt_begin    OUT VARCHAR2,
        o_dt_end      OUT VARCHAR2,
        o_flg_proceed OUT VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_flg_vacancy OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'VALIDATE_SCHEDULE_MULT';
        l_msg         VARCHAR2(4000) := NULL;
        l_msg_title   VARCHAR2(4000) := NULL;
        l_button      VARCHAR2(4000) := NULL;
        l_flg_show    VARCHAR2(1) := NULL;
        l_flg_proceed VARCHAR2(1) := NULL;
    BEGIN
        g_error := 'CHECK EXAM';
        -- Check exam specific parameters
        IF i_sch_args(idx_sch_args_exam) <> i_args(idx_id_exam)
        THEN
            g_error := 'GENERATE BAD EXAM MESSAGE';
            -- The selected slot has a different exam associated
            o_flg_proceed := g_no;
            o_flg_show    := g_yes;
            -- Generate message 
            o_msg_title := pk_schedule.get_message(i_lang, pk_schedule.g_sched_msg_ack_title);
            o_msg       := pk_schedule.get_message(i_lang, pk_schedule.g_sched_msg_sched_mult_bad_exm);
            o_button    := pk_schedule.g_ok_button_code || pk_schedule.get_message(i_lang, pk_schedule.g_msg_ack) || '|';
            RETURN TRUE;
        ELSE
            g_error := 'CALL VALIDATE_SCHEDULE_MULT';
            -- Perform validations that are specific to the multi-search creation and get a valid vacancy if possible
            IF NOT pk_schedule.validate_schedule_mult(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_args         => i_args,
                                                      i_sch_args     => i_sch_args,
                                                      i_flg_sch_type => pk_schedule_common.g_sch_dept_flg_dep_type_exam,
                                                      o_dt_begin     => o_dt_begin,
                                                      o_dt_end       => o_dt_end,
                                                      o_flg_proceed  => o_flg_proceed,
                                                      o_flg_show     => o_flg_show,
                                                      o_msg          => o_msg,
                                                      o_msg_title    => o_msg_title,
                                                      o_button       => o_button,
                                                      o_flg_vacancy  => o_flg_vacancy,
                                                      o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF (o_flg_proceed = g_yes)
            THEN
                -- It is possible to create an appointment, that is, a vacancy exists and all search
                -- parameters are valid.
            
                -- Perform additional validations (semantics)
                g_error := 'CALL VALIDATE_SCHEDULE';
                IF NOT validate_schedule(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_patient       => i_sch_args(idx_sch_args_patient),
                                         i_id_dep_clin_serv => i_sch_args(idx_sch_args_dcs),
                                         i_id_sch_event     => i_sch_args(idx_sch_args_event),
                                         i_id_prof          => i_sch_args(idx_sch_args_prof),
                                         i_dt_begin         => o_dt_begin,
                                         o_flg_proceed      => l_flg_proceed,
                                         o_flg_show         => l_flg_show,
                                         o_msg              => l_msg,
                                         o_msg_title        => l_msg_title,
                                         o_button           => l_button,
                                         o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF l_flg_show = g_yes
                   AND l_flg_proceed = g_yes
                THEN
                    -- Combine both messages (some warning needs to be shown)
                    g_error := 'COMBINE BOTH MESSAGES';
                    -- Join messages
                    o_msg_title := pk_schedule.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
                
                    o_msg    := '<b>' || pk_schedule.get_message(i_lang, pk_schedule.g_sched_mult_problems) || '</b>' ||
                                chr(13) || l_msg || chr(13) || chr(13) || '<b>' ||
                                pk_schedule.get_message(i_lang, pk_schedule.g_sched_mult_confirmation) || '</b>' ||
                                chr(13) || o_msg;
                    o_button := pk_schedule.g_cancel_button_code ||
                                pk_schedule.get_message(i_lang, pk_schedule.g_cancel_button) || '|' ||
                                pk_schedule.g_ok_button_code ||
                                pk_schedule.get_message(i_lang, pk_schedule.g_sched_msg_ignore_proceed) || '|';
                
                ELSIF l_flg_proceed = g_yes
                THEN
                    -- Use the multi-search message only as the validate_schedule call did not generate a warning
                    NULL;
                ELSIF l_flg_show = g_yes
                THEN
                    -- Use the last message only as it is a critical error.
                    o_flg_proceed := l_flg_proceed;
                    o_flg_show    := l_flg_show;
                    o_msg         := l_msg;
                    o_button      := l_button;
                    o_msg_title   := l_msg_title;
                END IF;
            END IF;
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

    /*
    * Creates the exam specific data for a schedule or reschedule. 
    * 
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_id_schedule            Schedule identifier
    * @param i_ids_exam_reqs          requesitions ids
    * @param i_dt_begin               date needed for the 20-06-2008 revision 
    * @param i_id_episode             episode id para usar no insert_exam_task
    * @param i_ids_exams              Exams identifiers
    * @param i_id_patient             patient id
    * @param o_new_ids                new schedule_exam ids
    * @param o_error                  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/23
    *
    * UPDATED
    * o parametro id_exam_req_det passou a i_id_exam_req (tabela exam_req) para uniformizar com a 
    * create_schedule_exam, create_reschedule, update_schedule
    * incluida invocacao da pk_exams_api_db.set_exam_date para update da data na tabela exam_req
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    20-06-2008
    *
    * UPDATED
    * passa a devolver o id da schedule_exam
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    29-07-2008
    *
    * UPDATED alert-8202. passa a receber uma lista de exames e lista de reqs
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    13-10-2009
    */
    FUNCTION create_schedule_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_schedule   IN schedule.id_schedule%TYPE,
        i_ids_exam_reqs IN table_number,
        i_dt_begin      IN VARCHAR2,
        i_id_episode    IN episode.id_episode%TYPE,
        i_ids_exams     IN table_number,
        i_id_patient    IN patient.id_patient%TYPE,
        o_new_ids       OUT table_number,
        o_flg_proceed   OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name        VARCHAR2(32) := 'CREATE_SCHEDULE_EXAM';
        l_sched_exam_rec   schedule_exam%ROWTYPE;
        l_flg_preparation  VARCHAR2(1 CHAR); --exam.flg_pat_prep%TYPE;
        l_prep_desc        sys_domain.desc_val%TYPE;
        l_flg_type         category.flg_type%TYPE;
        l_func_exception   EXCEPTION;
        l_ids_exams        table_number := table_number();
        i                  PLS_INTEGER;
        l_examworkflow     sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_WORKFLOW', i_prof);
        l_dummy            VARCHAR2(200);
        l_ids_exam_req     table_number := table_number();
        l_ids_exam_req_det table_number := table_number();
        l_id_sch           schedule.id_schedule%TYPE;
        l_id_sch_exam      schedule_exam.id_schedule_exam%TYPE;
    
        l_id_exam_req     exam_req.id_exam_req%TYPE;
        l_id_exam_req_det exam_req_det.id_exam_req_det%TYPE;
        l_exam            exam_req_det.id_exam%TYPE;
        l_status          exam_req_det.flg_status%TYPE;
    
    BEGIN
        o_flg_proceed := g_no;
        o_flg_show    := g_no;
    
        -- init da table de ids gerados
        o_new_ids := table_number();
    
        BEGIN
            -- get prof cat type
            g_error := 'GET CATEGORY FLG_TYPE';
            SELECT cat.flg_type
              INTO l_flg_type
              FROM category cat, prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND cat.id_category = pc.id_category
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_type := NULL;
        END;
    
        -- if there are requests we obtain the exam id from each one
        IF i_ids_exam_reqs IS NOT NULL
           AND i_ids_exam_reqs.count > 0
        THEN
            i := i_ids_exam_reqs.first;
            WHILE i IS NOT NULL
            LOOP
                -- tenho um select por iteracao para manter a ordem interna da l_ids_exams sincronizada com a ordem da i_ids_exam_reqs
                -- senao fazia bulk collect
                l_ids_exams.extend;
            
                IF i_ids_exam_reqs(i) IS NULL
                THEN
                    l_ids_exams(l_ids_exams.last) := NULL;
                ELSE
                    SELECT id_exam
                      INTO l_exam
                      FROM exam_req_det d
                     WHERE d.id_exam_req = i_ids_exam_reqs(i);
                    l_ids_exams(l_ids_exams.last) := l_exam;
                END IF;
            
                i := i_ids_exam_reqs.next(i);
            END LOOP;
        ELSE
            -- no request means we'll have to create a request per exam
            l_ids_exams := nvl(i_ids_exams, table_number());
        END IF;
    
        --ciclar os exames
        i := l_ids_exams.first;
        WHILE i IS NOT NULL
        LOOP
        
            -- Check if the exam needs the patient to perform any preparation steps.
            g_error := 'CALL HAS_PREPARATION';
            IF NOT has_preparation(i_lang      => i_lang,
                                   i_id_exam   => l_ids_exams(i),
                                   o_flg_prep  => l_flg_preparation,
                                   o_prep_desc => l_prep_desc,
                                   o_error     => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- create request if the exam is orphan
            IF i_ids_exam_reqs IS NULL
               OR i_ids_exam_reqs.count = 0
               OR i_ids_exam_reqs(i) IS NULL
            THEN
                g_error := 'CREATE REQUEST';
                IF NOT pk_exams_api_db.create_exam_order(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
                                                         i_patient                 => i_id_patient,
                                                         i_episode                 => NULL,
                                                         i_exam_req                => NULL,
                                                         i_exam_req_det            => table_number(NULL),
                                                         i_exam                    => table_number(l_ids_exams(i)),
                                                         i_flg_type                => table_varchar('E'),
                                                         i_dt_req                  => table_varchar(NULL),
                                                         i_flg_time                => table_varchar(pk_exam_constant.g_flg_time_e),
                                                         i_dt_begin                => table_varchar(i_dt_begin),
                                                         i_dt_begin_limit          => table_varchar(NULL),
                                                         i_episode_destination     => table_number(NULL),
                                                         i_order_recurrence        => table_number(NULL),
                                                         i_priority                => table_varchar('N'),
                                                         i_flg_prn                 => table_varchar(NULL),
                                                         i_notes_prn               => table_varchar(NULL),
                                                         i_flg_fasting             => table_varchar(NULL),
                                                         i_notes                   => table_varchar(NULL),
                                                         i_notes_scheduler         => table_varchar(NULL),
                                                         i_notes_technician        => table_varchar(NULL),
                                                         i_notes_patient           => table_varchar(NULL),
                                                         i_diagnosis_notes         => table_varchar(NULL),
                                                         i_diagnosis               => NULL,
                                                         i_exec_room               => table_number(NULL),
                                                         i_exec_institution        => table_number(i_prof.institution),
                                                         i_clinical_purpose        => table_number(NULL),
                                                         i_codification            => table_number(NULL),
                                                         i_health_plan             => table_number(NULL),
                                                         i_prof_order              => table_number(NULL),
                                                         i_dt_order                => table_varchar(NULL),
                                                         i_order_type              => table_number(NULL),
                                                         i_clinical_question       => table_table_number(table_number(NULL)),
                                                         i_response                => table_table_varchar(table_varchar('')),
                                                         i_clinical_question_notes => table_table_varchar(table_varchar('')),
                                                         i_clinical_decision_rule  => table_number(NULL),
                                                         i_flg_origin_req          => 'S',
                                                         i_task_dependency         => table_number(NULL),
                                                         i_flg_task_depending      => table_varchar(''),
                                                         i_episode_followup_app    => table_number(NULL),
                                                         i_schedule_followup_app   => table_number(NULL),
                                                         i_event_followup_app      => table_number(NULL),
                                                         i_test                    => g_no,
                                                         o_flg_show                => o_flg_show,
                                                         o_msg_title               => o_msg_title,
                                                         o_msg_req                 => o_msg,
                                                         o_button                  => o_button,
                                                         o_exam_req_array          => l_ids_exam_req,
                                                         o_exam_req_det_array      => l_ids_exam_req_det,
                                                         o_error                   => o_error)
                
                THEN
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
                IF o_flg_show = g_yes
                THEN
                    RETURN TRUE;
                END IF;
            
                l_id_exam_req := l_ids_exam_req(1);
            
            ELSE
                l_id_exam_req := i_ids_exam_reqs(i);
            END IF;
        
            -- Create exam-specific schedule
            g_error := 'NEW SCHEDULE EXAM';
            IF NOT new_schedule_exam(i_lang              => i_lang,
                                     i_id_schedule       => i_id_schedule,
                                     i_id_exam           => l_ids_exams(i),
                                     i_flg_preparation   => l_flg_preparation,
                                     i_exam_req          => l_id_exam_req,
                                     o_schedule_exam_rec => l_sched_exam_rec,
                                     o_error             => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- settar data do agendamento na req.
            g_error := 'SET EXAM DATE';
            IF NOT pk_exams_api_db.set_exam_date(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_exam_req        => l_id_exam_req,
                                                 i_dt_begin        => i_dt_begin,
                                                 i_notes_scheduler => NULL,
                                                 o_error           => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            o_new_ids.extend;
            o_new_ids(o_new_ids.last) := l_sched_exam_rec.id_schedule_exam;
        
            SELECT er.flg_status
              INTO l_status
              FROM exam_req er
             WHERE er.id_exam_req = l_id_exam_req;
        
            IF l_status != 'A'
            THEN
                -- settar status da requisicao
                g_error := 'SET EXAM TASK';
                IF NOT pk_exams_external_api_db.set_exam_status(i_lang     => i_lang,
                                                                i_prof     => i_prof,
                                                                i_exam_req => l_id_exam_req,
                                                                i_status   => 'A',
                                                                o_error    => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            i := l_ids_exams.next(i);
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
    END create_schedule_exam;

    /**
    * Updates exam schedule. Adapted from the pk_schedule_outp version of create_schedule   
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_schedule        The schedule id to be updated
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
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
    * @param i_id_exam            exam id
    * @param i_id_episode         Episode 
    * @param i_reason_notes       Reason for appointment in free-text.
    * @param i_flg_sched_request_type  tipo de pedido
    * @param i_flg_schedule_via   meio do pedido marcacao
    * @param i_do_overlap         null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be 
    *                             issued with Y or N
    * @param i_id_consult_vac     id da vaga. Se for <> null significa que se trata de uma marcaçao normal ou alem-vaga
    * @param i_sch_option         'V' = marcar numa vaga; 'A' = marcar alem-vaga;  'S' = marcar sem vaga (fora do horario normal)
    * @param o_id_schedule        New schedule
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set if a message is displayed or not      
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.
    * @param o_error              Error message if something goes wrong
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     02-06-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * o id_exam e o id_exam_req passam a ser nao editaveis para que a requisicao continue valida (ana matos).
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    26-06-2008
    *
    * UPDATED
    * acrescentado o parametro o_id_schedule_exam
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    29-07-2008 
    *
    * UPDATED
    * alert-8202
    * @author  Telmo
    * @version 2.5.0.7
    * @date    21-10-2009
    */
    FUNCTION update_schedule
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_schedule        IN schedule.id_schedule%TYPE,
        i_id_patient         IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv   IN schedule.id_dcs_requested%TYPE,
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
        i_ids_exams          IN table_number DEFAULT NULL,
        i_id_episode         IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes       IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type   IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via   IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap         IN VARCHAR2,
        i_id_consult_vac     IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option         IN VARCHAR2,
        o_id_schedule        OUT schedule.id_schedule%TYPE,
        o_id_schedule_exam   OUT schedule_exam.id_schedule_exam%TYPE,
        o_flg_proceed        OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'UPDATE_SCHEDULE';
        l_schedule_cancel_notes schedule.schedule_cancel_notes%TYPE;
        l_func_exception        EXCEPTION;
        l_proceed               VARCHAR2(1);
        l_cid                   PLS_INTEGER;
        l_dummy                 VARCHAR2(200);
        l_ids_exam_req          table_number := table_number();
        l_ids_exam_req_det      table_number := table_number();
        l_id_sch                NUMBER;
        l_id_sch_exam           NUMBER;
        l_retval                BOOLEAN;
        l_new_exam_reqs         table_number := table_number();
        i                       PLS_INTEGER;
        l_flg_type              category.flg_type%TYPE;
        l_pat_referral          p1_external_request.id_external_request%TYPE := NULL;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
        TYPE t_duo IS RECORD(
            id_exam     schedule_exam.id_exam%TYPE,
            id_exam_req schedule_exam.id_exam_req%TYPE);
    
        TYPE t_old_exams IS TABLE OF t_duo;
    
        l_old_stuff t_old_exams := t_old_exams();
    
        -- pegar pares actuais id_exam | id_exam_req 
        FUNCTION inner_fill_old_stuff RETURN BOOLEAN IS
            CURSOR c_pares IS
                SELECT id_exam, id_exam_req
                  FROM schedule_exam
                 WHERE id_schedule = i_id_schedule;
            l_par t_duo;
            rec   c_pares%ROWTYPE;
        BEGIN
            g_error := 'OPEN c_pares';
            OPEN c_pares;
        
            LOOP
                FETCH c_pares
                    INTO rec;
                EXIT WHEN c_pares%NOTFOUND;
                l_par.id_exam     := rec.id_exam;
                l_par.id_exam_req := rec.id_exam_req;
                l_old_stuff.extend;
                l_old_stuff(l_old_stuff.last) := l_par;
            END LOOP;
            CLOSE c_pares;
        
            RETURN TRUE;
        END inner_fill_old_stuff;
    
        -- inner function que devolve, se existir, o indice dentro do old_stuff onde esta certo exame e sua req
        -- se nao encontrar devolve -1
        FUNCTION exists_inside_old_stuff(i_id_exam NUMBER) RETURN INTEGER IS
            l_ret INTEGER := -1;
        BEGIN
            g_error := 'EXISTIS_INSIDE_OLD_STUFF';
            IF (i_id_exam IS NOT NULL AND l_old_stuff IS NOT NULL AND l_old_stuff.count > 0)
            THEN
                -- Check if the element exists inside the collection.
                FOR i IN l_old_stuff.first .. l_old_stuff.last
                LOOP
                    EXIT WHEN l_ret > -1;
                    IF l_old_stuff(i).id_exam = i_id_exam
                    THEN
                        l_ret := i;
                    END IF;
                END LOOP;
            END IF;
        
            RETURN l_ret;
        END exists_inside_old_stuff;
    
    BEGIN
    
        -- check if we can cancel the current schedule
        g_error := 'CALL GET_REQS_STATUS';
        IF NOT get_reqs_status(i_lang, i_prof, i_id_schedule, l_proceed, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- no can do
        IF l_proceed = g_no
        THEN
            o_flg_proceed := g_no;
            o_flg_show    := g_yes;
            o_msg_title   := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_sched_msg_no_upd);
            o_button      := pk_schedule.g_check_button;
            RETURN TRUE;
        END IF;
    
        -- get cancel notes message
        g_error                 := 'GET CANCEL NOTES';
        l_schedule_cancel_notes := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => pk_schedule_outp.g_update_schedule);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        --        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        --        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id);
    
        g_error := 'CALL TO pk_ref_module.get_ref_sch_to_cancel with id_schedule=' || i_id_schedule;
        IF NOT pk_ref_module.get_ref_sch_to_cancel(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_id_schedule         => i_id_schedule,
                                                   o_id_external_request => l_pat_referral,
                                                   o_error               => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- cancel schedule
        /*        g_error := 'CALL CANCEL SCHEDULE';
                IF NOT pk_schedule.cancel_schedule(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_id_schedule      => i_id_schedule,
                                                   i_id_cancel_reason => NULL,
                                                   i_cancel_notes     => l_schedule_cancel_notes,
                                                   io_transaction_id  => l_transaction_id,
                                                   o_error            => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
        */
        -- get old stuff
        l_retval := inner_fill_old_stuff;
    
        -- ciclar os novos exames para comparar com antigos.
        -- se id_exame esta' no antes e no depois re-utiliza id_exam_req. 
        -- se nao esta' cria nova req.
        -- objectivo = passar ao create_schedule mais abaixo a lista definitiva dos exames e a lista definitiva dos exam_req
        IF i_ids_exams IS NOT NULL
           AND i_ids_exams.count > 0
        THEN
            i := i_ids_exams.first;
            WHILE i IS NOT NULL
            LOOP
                g_error := 'CALL EXISTS_INSIDE_OLD_STUFF';
                l_cid   := exists_inside_old_stuff(i_ids_exams(i));
                IF l_cid > -1
                THEN
                    l_new_exam_reqs.extend;
                    l_new_exam_reqs(l_new_exam_reqs.last) := l_old_stuff(l_cid).id_exam_req;
                ELSE
                    -- criar nova requisicao
                    g_error := 'CREATE EXAM REQUEST';
                    IF NOT pk_exams_api_db.create_exam_order(i_lang                    => i_lang,
                                                             i_prof                    => i_prof,
                                                             i_patient                 => i_id_patient,
                                                             i_episode                 => NULL,
                                                             i_exam_req                => NULL,
                                                             i_exam_req_det            => table_number(NULL),
                                                             i_exam                    => table_number(i_ids_exams(i)),
                                                             i_flg_type                => table_varchar('E'),
                                                             i_dt_req                  => table_varchar(NULL),
                                                             i_flg_time                => table_varchar(pk_exam_constant.g_flg_time_e),
                                                             i_dt_begin                => table_varchar(i_dt_begin),
                                                             i_dt_begin_limit          => table_varchar(NULL),
                                                             i_episode_destination     => table_number(NULL),
                                                             i_order_recurrence        => table_number(NULL),
                                                             i_priority                => table_varchar('N'),
                                                             i_flg_prn                 => table_varchar(NULL),
                                                             i_notes_prn               => table_varchar(NULL),
                                                             i_flg_fasting             => table_varchar(NULL),
                                                             i_notes                   => table_varchar(NULL),
                                                             i_notes_scheduler         => table_varchar(NULL),
                                                             i_notes_technician        => table_varchar(NULL),
                                                             i_notes_patient           => table_varchar(NULL),
                                                             i_diagnosis_notes         => table_varchar(NULL),
                                                             i_diagnosis               => NULL,
                                                             i_exec_room               => table_number(NULL),
                                                             i_exec_institution        => table_number(i_prof.institution),
                                                             i_clinical_purpose        => table_number(NULL),
                                                             i_codification            => table_number(NULL),
                                                             i_health_plan             => table_number(NULL),
                                                             i_prof_order              => table_number(NULL),
                                                             i_dt_order                => table_varchar(NULL),
                                                             i_order_type              => table_number(NULL),
                                                             i_clinical_question       => table_table_number(table_number(NULL)),
                                                             i_response                => table_table_varchar(table_varchar('')),
                                                             i_clinical_question_notes => table_table_varchar(table_varchar('')),
                                                             i_clinical_decision_rule  => table_number(NULL),
                                                             i_flg_origin_req          => 'S',
                                                             i_task_dependency         => table_number(NULL),
                                                             i_flg_task_depending      => table_varchar(''),
                                                             i_episode_followup_app    => table_number(NULL),
                                                             i_schedule_followup_app   => table_number(NULL),
                                                             i_event_followup_app      => table_number(NULL),
                                                             i_test                    => g_no,
                                                             o_flg_show                => o_flg_show,
                                                             o_msg_title               => o_msg_title,
                                                             o_msg_req                 => o_msg,
                                                             o_button                  => o_button,
                                                             o_exam_req_array          => l_ids_exam_req,
                                                             o_exam_req_det_array      => l_ids_exam_req_det,
                                                             o_error                   => o_error)
                    THEN
                        pk_utils.undo_changes;
                        RETURN FALSE;
                    END IF;
                
                    IF o_flg_show = g_yes
                    THEN
                        pk_utils.undo_changes;
                        RETURN TRUE;
                    END IF;
                
                    l_new_exam_reqs.extend;
                    l_new_exam_reqs(l_new_exam_reqs.last) := l_ids_exam_req(1);
                
                END IF;
            
                i := i_ids_exams.next(i);
            END LOOP;
        END IF;
    
        /*
        -- pk_exams_api_db.cancel_exam_req ceased to exist
        
                -- ciclar agora os antigos exames para comparar com os novos. Parece repeticao mas nao e'.
                -- agora o objectivo e' cancelar as requisicoes dos exames antigos que foram 'dropados'
                i := l_old_stuff.first;
                WHILE i IS NOT NULL
                LOOP
                    IF NOT pk_schedule.exists_inside_table_number(l_old_stuff(i).id_exam, i_ids_exams)
                    THEN
                    
                        -- get prof cat type
                        g_error := 'GET PROF CAT TYPE';
                        BEGIN
                            SELECT cat.flg_type
                              INTO l_flg_type
                              FROM category cat, prof_cat pc
                             WHERE pc.id_professional = i_prof.id
                               AND cat.id_category = pc.id_category
                               AND rownum = 1;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_flg_type := NULL;
                        END;
                    
                        g_error := 'CANCEL EXAM ORDER';
                        IF NOT pk_exams_api_db.cancel_exam_order(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_exam_req       => table_number(l_old_stuff(i).id_exam_req),
                                                                 i_cancel_reason  => NULL,
                                                                 i_cancel_notes   => l_schedule_cancel_notes,
                                                                 i_prof_order     => NULL,
                                                                 i_dt_order       => NULL,
                                                                 i_order_type     => NULL,
                                                                 i_flg_schedule   => g_no,
                                                                 i_transaction_id => l_transaction_id,
                                                                 o_error          => o_error)
                        THEN
                            pk_utils.undo_changes;
                            RETURN FALSE;
                        END IF;
                    
                        IF o_flg_show = g_yes
                        THEN
                            pk_utils.undo_changes;
                            RETURN TRUE;
                        END IF;
                    END IF;
                    i := l_old_stuff.next(i);
                END LOOP;
        */
        -- create a new schedule
        g_error := 'CALL PK_SCHEDULE_OUTP.CREATE_SCHEDULE';
        IF NOT pk_schedule_exam.create_schedule(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_patient         => i_id_patient,
                                                i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                                i_id_sch_event       => i_id_sch_event,
                                                i_id_prof            => i_id_prof,
                                                i_dt_begin           => i_dt_begin,
                                                i_dt_end             => i_dt_end,
                                                i_flg_vacancy        => i_flg_vacancy,
                                                i_schedule_notes     => i_schedule_notes,
                                                i_id_lang_translator => i_id_lang_translator,
                                                i_id_lang_preferred  => i_id_lang_preferred,
                                                i_id_reason          => i_id_reason,
                                                i_id_origin          => i_id_origin,
                                                i_id_room            => i_id_room,
                                                i_ids_exams          => i_ids_exams,
                                                i_reason_notes       => i_reason_notes,
                                                i_ids_exam_reqs      => l_new_exam_reqs,
                                                i_id_schedule_ref    => i_id_schedule,
                                                i_flg_request_type   => i_flg_request_type,
                                                i_flg_schedule_via   => i_flg_schedule_via,
                                                i_do_overlap         => i_do_overlap,
                                                i_id_consult_vac     => i_id_consult_vac,
                                                i_sch_option         => nvl(i_sch_option, pk_schedule.g_sch_option_update),
                                                i_id_episode         => i_id_episode,
                                                o_id_schedule        => o_id_schedule,
                                                o_id_schedule_exam   => o_id_schedule_exam,
                                                o_flg_proceed        => o_flg_proceed,
                                                o_flg_show           => o_flg_show,
                                                o_msg                => o_msg,
                                                o_msg_title          => o_msg_title,
                                                o_button             => o_button,
                                                o_error              => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        --         pk_schedule_api_upstream.do_commit(i_id_transaction => l_transaction_id);
        --         commit;
    
        IF (l_pat_referral IS NOT NULL)
        THEN
            --update referral status           
            g_error := 'CALL TO pk_ref_service.set_ref_schedule with id_schedule=' || i_id_schedule ||
                       ' and id_referral=' || l_pat_referral;
            IF NOT pk_ref_ext_sys.set_ref_schedule(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_id_ref   => l_pat_referral,
                                                   i_schedule => o_id_schedule,
                                                   i_notes    => NULL,
                                                   i_episode  => i_id_episode,
                                                   o_error    => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
        
            --            pk_schedule_api_upstream.do_rollback(l_transaction_id);
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
        
            --            pk_schedule_api_upstream.do_rollback(l_transaction_id);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END update_schedule;

    /*
    * private function. used to check if the requesition was created by the physician.
    *  This function will be used in the cancel_schedule in order to do not cancel the requisition
    * when it was created by the physician. In this case the requisition goes to the state 'before schedule'
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_id_schedule            schedule id 
    * @param o_proceed                N= do not proceed  Y=ok
    * @param o_error                  error data
    * @return True if successful, false otherwise. 
    *
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @date    21-10-2009
    */
    FUNCTION is_requested_by_phys
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_exam_req IN exam_req.id_exam_req%TYPE,
        o_req_by_phy  OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'IS_REQUESTED_BY_PHYS';
    BEGIN
        BEGIN
        
            SELECT g_yes
              INTO o_req_by_phy
              FROM exam_req er
             WHERE er.flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
               AND er.id_episode IS NULL
               AND er.id_episode_origin IS NOT NULL
               AND er.id_exam_req = i_id_exam_req
               AND rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_req_by_phy := g_no;
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
            RETURN FALSE;
    END is_requested_by_phys;

    /* Function cancel_schedule splitted in two function in order to be reused to the API to the interfaces team
    * @author  Sofia Mendes
    * @version 2.5.0.7.4.1
    * @date    08-02-2010
    * 
    */
    FUNCTION cancel_only_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg_req          OUT VARCHAR2,
        o_msg_result       OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'CANCEL_ONLY_SCHEDULE';
        l_func_exception EXCEPTION;
        l_proceed        VARCHAR2(1);
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    BEGIN
    
        -- check if we can cancel the current schedule
        g_error := 'CALL GET_REQS_STATUS';
        IF NOT get_reqs_status(i_lang, i_prof, i_id_schedule, l_proceed, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- no can do
        IF l_proceed = g_no
        THEN
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg_req   := pk_message.get_message(i_lang, g_sched_msg_no_cancel);
            o_button    := pk_schedule.g_check_button;
            RETURN TRUE;
        END IF;
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL PK_SCHEDULE.CANCEL_SCHEDULE: id_Schedule: ' || i_id_schedule;
        IF NOT pk_schedule.cancel_schedule(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_id_schedule      => i_id_schedule,
                                           i_id_cancel_reason => i_id_cancel_reason,
                                           i_cancel_notes     => i_cancel_notes,
                                           io_transaction_id  => l_transaction_id,
                                           i_cancel_exam_req  => pk_alert_constant.g_no,
                                           o_error            => o_error)
        THEN
            RAISE l_func_exception;
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
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END cancel_only_schedule;

    /*
    * Cancels an exam appointment. Also works for Other exams. Previously the cancel_schedule from pk_schedule was used,
    * but now there is a need to call specific exam code, so this step was introduced
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
    * Function cancel_schedule splitted in two function in order to be reused to the API to the interfaces team
    * @author  Sofia Mendes
    * @version 2.5.0.7.4.1
    * @date    08-02-2010
    */
    FUNCTION cancel_only_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_flg_show         OUT VARCHAR2,
        o_msg_req          OUT VARCHAR2,
        o_msg_result       OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'CANCEL_ONLY_SCHEDULE';
        l_func_exception EXCEPTION;
        l_proceed        VARCHAR2(1);
    BEGIN
    
        -- check if we can cancel the current schedule
        g_error := 'CALL GET_REQS_STATUS';
        IF NOT get_reqs_status(i_lang, i_prof, i_id_schedule, l_proceed, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- no can do
        IF l_proceed = g_no
        THEN
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg_req   := pk_message.get_message(i_lang, g_sched_msg_no_cancel);
            o_button    := pk_schedule.g_check_button;
            RETURN TRUE;
        END IF;
    
        g_error := 'CALL PK_SCHEDULE.CANCEL_SCHEDULE: id_Schedule: ' || i_id_schedule;
        IF NOT pk_schedule.cancel_schedule_old(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_schedule      => i_id_schedule,
                                               i_id_cancel_reason => i_id_cancel_reason,
                                               i_cancel_notes     => i_cancel_notes,
                                               o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
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
        
    END cancel_only_schedule;

    /*
    * Cancels an exam appointment. Also works for Other exams. Previously the cancel_schedule from pk_schedule was used,
    * but now there is a need to call specific exam code, so this step was introduced
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
    * @author Telmo Castro
    * @version 2.4.3
    * @date    09-09-2008
    *
    * UPDATED alert-8202. adaptado para a possibilidade de agendamento multi-exame
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    19-10-2009
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_flg_show         OUT VARCHAR2,
        o_msg_req          OUT VARCHAR2,
        o_msg_result       OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := 'CANCEL_SCHEDULE';
        l_func_exception   EXCEPTION;
        l_proceed          VARCHAR2(1);
        l_requested_by_phy VARCHAR2(1);
    
        CURSOR c_cat IS
            SELECT cat.flg_type
              FROM category cat, prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND cat.id_category = pc.id_category;
    
        CURSOR c_idexamreq IS
            SELECT se.id_exam_req
              FROM schedule_exam se
             WHERE se.id_schedule = i_id_schedule
               AND se.id_exam_req IS NOT NULL;
    
        l_cat         category.flg_type%TYPE;
        l_id_exam_req exam_req.id_exam_req%TYPE;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- check if we can cancel the current schedule
        g_error := 'CALL GET_REQS_STATUS';
        IF NOT get_reqs_status(i_lang, i_prof, i_id_schedule, l_proceed, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- no can do
        IF l_proceed = g_no
        THEN
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg_req   := pk_message.get_message(i_lang, g_sched_msg_no_cancel);
            o_button    := pk_schedule.g_check_button;
            RETURN TRUE;
        END IF;
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        g_error := 'CALL PK_SCHEDULE.CANCEL_SCHEDULE';
        IF NOT pk_schedule.cancel_schedule(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_id_schedule      => i_id_schedule,
                                           i_id_cancel_reason => i_id_cancel_reason,
                                           i_cancel_notes     => i_cancel_notes,
                                           io_transaction_id  => l_transaction_id,
                                           o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- get i_prof_cat_type
        OPEN c_cat;
        FETCH c_cat
            INTO l_cat;
        CLOSE c_cat;
    
        -- for each exam found in this schedule cancel its requisition
        OPEN c_idexamreq;
        LOOP
            FETCH c_idexamreq
                INTO l_id_exam_req;
            EXIT WHEN c_idexamreq%NOTFOUND;
        
            g_error := 'CALL IS_REQUESTED_BY_PHYS';
            IF NOT is_requested_by_phys(i_lang        => i_lang,
                                        i_prof        => i_prof,
                                        i_id_exam_req => l_id_exam_req,
                                        o_req_by_phy  => l_requested_by_phy,
                                        o_error       => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- if the request was created by the physician it should go to the state 'ready for schedule'
            -- otherwise the request shall be cancelled   
            /*
            -- pk_exams_api_db.cancel_exam_req no longer exists and this cancel_schedule is obsolete anyway
            
            IF (NOT l_requested_by_phy = g_yes)
            THEN
                -- cancel exam req
                g_error := 'CALL PK_EXAMS_API_DB.CANCEL_EXAM_ORDER';
                IF NOT pk_exams_api_db.cancel_exam_order(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_exam_req       => table_number(l_id_exam_req),
                                                         i_cancel_reason  => NULL,
                                                         i_cancel_notes   => i_cancel_notes,
                                                         i_prof_order     => NULL,
                                                         i_dt_order       => NULL,
                                                         i_order_type     => NULL,
                                                         i_flg_schedule   => g_no,
                                                         i_transaction_id => l_transaction_id,
                                                         o_error          => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
            ELSE
                g_error := 'CALL pk_exams_api_db.cancel_exam_schedule with id_exam_req = ' || l_id_exam_req;
                IF NOT pk_exams_api_db.cancel_exam_schedule(i_lang     => i_lang,
                                                            i_prof     => i_prof,
                                                            i_exam_req => l_id_exam_req,
                                                            o_error    => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
            END IF;*/
            IF o_flg_show = g_yes
            THEN
                RETURN TRUE;
            END IF;
        
        END LOOP;
        CLOSE c_idexamreq;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
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
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END cancel_schedule;

    /*
    * Checks if a professional has the necessary permissions to schedule an exam
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     o_error   Error message
        
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   0.1
    * @since     2008/06/20
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    *
    * MOVED
    * this function moved from pk_exam
    * @author   Telmo Castro
    * @version  2.5.0.4
    * @date     08-07-2009
    */
    FUNCTION get_exam_sch_permissions
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_dept sch_department.id_department%TYPE;
        g_found   BOOLEAN;
    
        CURSOR c_permissions IS
            SELECT sd.id_department
              FROM sch_department sd
             INNER JOIN dep_clin_serv dcs
                ON sd.id_department = dcs.id_department
             INNER JOIN prof_dep_clin_serv pdcs
                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
             INNER JOIN sch_event_dcs sed
                ON sed.id_dep_clin_serv = pdcs.id_dep_clin_serv
             INNER JOIN sch_event se
                ON sed.id_sch_event = se.id_sch_event
             INNER JOIN sch_dep_type sdt
                ON se.dep_type = sdt.dep_type
             WHERE sd.flg_dep_type IN
                   (pk_schedule_common.g_sch_dept_flg_dep_type_exam, pk_schedule_common.g_sch_dept_flg_dep_type_oexams)
               AND sed.flg_available = pk_alert_constant.g_yes
               AND se.flg_available = pk_alert_constant.g_yes
               AND sdt.flg_available = pk_alert_constant.g_yes
               AND sdt.dep_type IN
                   (pk_schedule_common.g_sch_dept_flg_dep_type_exam, pk_schedule_common.g_sch_dept_flg_dep_type_oexams)
               AND pdcs.id_professional = i_prof.id
               AND EXISTS (SELECT 1
                      FROM sch_permission sp
                     WHERE id_institution = pdcs.id_institution
                       AND id_professional = pdcs.id_professional
                       AND id_sch_event = se.id_sch_event
                       AND flg_permission <> pk_schedule.g_permission_none)
               AND pdcs.id_institution = i_prof.institution;
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN c_permissions;
        FETCH c_permissions
            INTO l_id_dept;
        g_found := c_permissions%NOTFOUND;
        CLOSE c_permissions;
    
        RETURN NOT g_found;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_SCH_PERMISSIONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_sch_permissions;

    /* seleccao de exames para a popup de seleccao de exames*/
    FUNCTION get_exam_selection_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_codification  IN codification.id_codification%TYPE,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT *
              FROM TABLE(pk_exam_core.get_exam_selection_list(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_patient       => i_patient,
                                                              i_episode       => NULL,
                                                              i_exam_type     => i_exam_type,
                                                              i_codification  => i_codification,
                                                              i_dep_clin_serv => i_dep_clin_serv));
    
        RETURN TRUE;
    
    END get_exam_selection_list;

    /* pesquisa de exames para a popup de seleccao de exames*/
    FUNCTION get_exam_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_codification  IN codification.id_codification%TYPE,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE,
        i_value         IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_exams_api_db.get_exam_search(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_patient       => i_patient,
                                               i_exam_type     => i_exam_type,
                                               i_codification  => i_codification,
                                               i_dep_clin_serv => i_dep_clin_serv,
                                               i_value         => i_value,
                                               o_flg_show      => o_flg_show,
                                               o_msg           => o_msg,
                                               o_msg_title     => o_msg_title,
                                               o_list          => o_list,
                                               o_error         => o_error);
    
    END get_exam_search;

    FUNCTION get_exam_category_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_codification  IN codification.id_codification%TYPE DEFAULT NULL,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_exams_api_db.get_exam_category_search(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_patient       => i_patient,
                                                        i_exam_type     => i_exam_type,
                                                        i_codification  => i_codification,
                                                        i_dep_clin_serv => i_dep_clin_serv,
                                                        o_list          => o_list,
                                                        o_error         => o_error);
    END get_exam_category_search;

    FUNCTION get_exam_in_category
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_cat     IN exam_cat.id_exam_cat%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_exams_api_db.get_exam_in_category(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    i_exam_cat     => i_exam_cat,
                                                    i_exam_type    => i_exam_type,
                                                    i_codification => i_codification,
                                                    o_list         => o_list,
                                                    o_error        => o_error);
    END get_exam_in_category;

    FUNCTION get_exam_in_group
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_group   IN exam_group.id_exam_group%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_exams_api_db.get_exam_in_group(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_exam_group   => i_exam_group,
                                                 i_codification => i_codification,
                                                 o_list         => o_list,
                                                 o_error        => o_error);
    END get_exam_in_group;

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
    * @since                          2010/01/13
    **********************************************************************************************/
    FUNCTION get_schedule_exams
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_ret   VARCHAR2(4000);
        l_count PLS_INTEGER := 0;
        l_error t_error_out;
    BEGIN
        FOR rec IN (SELECT s.id_schedule,
                           pk_exams_api_db.get_alias_translation(i_lang, i_prof, code_exam, NULL) desc_exam,
                           se.id_exam
                      FROM schedule s
                     INNER JOIN schedule_exam se
                        ON s.id_schedule = se.id_schedule
                      JOIN exam e
                        ON se.id_exam = e.id_exam
                     WHERE s.id_schedule = i_id_schedule)
        LOOP
            IF l_count <> 0
            THEN
                l_ret := l_ret || '; ' || rec.desc_exam;
            ELSE
                l_ret := rec.desc_exam;
            END IF;
        
            l_count := l_count + 1;
        END LOOP;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            l_ret := NULL;
            RETURN l_ret;
        WHEN OTHERS THEN
            l_ret := NULL;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCHEDULE_EXAMS',
                                              o_error    => l_error);
            RETURN l_ret;
    END get_schedule_exams;

    /* returns all exam/other exam appointments for TODAY, scheduled for the given profissional's intitution.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    *
    * @RETURN t_table_sch_exam_daily_apps   nested table of t_rec_sch_exam_daily_apps
    *
    * @author  Telmo
    * @version 2.6.4
    * @date    10-12-2014
    */
    FUNCTION get_today_exam_appoints
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_day  IN schedule.dt_begin_tstz%TYPE DEFAULT NULL
    ) RETURN t_table_sch_exam_daily_apps IS
        l_func_name VARCHAR2(50) := 'PK_SCHEDULE_EXAM.GET_TODAY_EXAM_APPOINTS';
        l_ret       t_table_sch_exam_daily_apps;
    BEGIN
        SELECT t_rec_sch_exam_daily_apps(s.id_schedule,
                                          sg.id_patient,
                                          s.id_instit_requests,
                                          s.dt_begin_tstz,
                                          s.flg_status,
                                          se.id_exam,
                                          se.id_exam_req,
                                          CASE
                                              WHEN sg.id_cancel_reason IS NULL THEN
                                               'N'
                                              ELSE
                                               'Y'
                                          END)
          BULK COLLECT
          INTO l_ret
          FROM schedule s
          JOIN schedule_exam se
            ON s.id_schedule = se.id_schedule
          JOIN sch_group sg
            ON s.id_schedule = sg.id_schedule
         WHERE s.flg_sch_type IN
               (pk_schedule_common.g_sch_dept_flg_dep_type_exam, pk_schedule_common.g_sch_dept_flg_dep_type_oexams)
           AND s.dt_begin_tstz >= trunc(nvl(i_day, current_timestamp - 180))
           AND s.dt_begin_tstz < trunc(nvl(i_day, current_timestamp + 180)) + 1
           AND s.id_instit_requested = i_prof.institution
           AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
        --      group by s.id_schedule, sg.id_patient, s.id_instit_requests, s.dt_begin_tstz, s.flg_status,se.id_exam, se.id_exam_req;
    
        RETURN l_ret;
    END get_today_exam_appoints;

    /*
    *  ALERT-303513. Details of a exam/other exams schedule 
    */
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
                   (SELECT listagg(pk_translation.get_translation(i_lang, 'EXAM.CODE_EXAM.' || se.id_exam), ', ') within GROUP(ORDER BY id_schedule_exam)
                      FROM schedule_exam se
                     WHERE se.id_schedule = s.id_schedule) desc_exams, -- Scheduled test(s)
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
                                   (SELECT listagg(pk_translation.get_translation(i_lang, 'EXAM.CODE_EXAM.' || se.id_exam),
                                                   ', ') within GROUP(ORDER BY id_schedule_exam)
                                      FROM schedule_exam se
                                     WHERE se.id_schedule = sh.id_schedule) desc_exams, -- Scheduled test(s)
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
        i_id_req           IN schedule_exam.id_exam_req%TYPE,
        i_ids_exams        IN table_number DEFAULT NULL,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'CANCEL_REQ_SCHEDULES';
        l_ids_sch        table_number;
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
        i                PLS_INTEGER;
    BEGIN
        g_error := l_func_name || ' - get schedule ids. i_id_req=' || nvl(to_char(i_id_req), 'null');
        SELECT DISTINCT s.id_schedule
          BULK COLLECT
          INTO l_ids_sch
          FROM schedule s
          JOIN schedule_exam se
            ON s.id_schedule = se.id_schedule
         WHERE se.id_exam_req = i_id_req
           AND se.id_exam IN (SELECT *
                                FROM TABLE(CASE
                                                WHEN i_ids_exams IS NOT NULL THEN
                                                 i_ids_exams
                                                ELSE
                                                 table_number(se.id_exam)
                                            END))
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
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_exam;
/
