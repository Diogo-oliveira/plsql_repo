/*-- Last Change Revision: $Rev: 2053893 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-30 14:20:45 +0000 (sex, 30 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_exam IS

    /********************************************************************************************
       * Get Exams List
    *
    * @param i_lang            Prefered language ID
    * @param i_search          Search
    * @param i_flg_image       Exams Type
    * @param o_exams_list      Exams list
    * @param o_error           Error
    *
    * @value i_flg_image       {*} 'Y' Image Exam  {*} 'N' Other Exams
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2008/04/15
    ********************************************************************************************/
    FUNCTION get_exams_list
    (
        i_lang      IN language.id_language%TYPE,
        i_search    IN VARCHAR2,
        i_flg_image IN VARCHAR2,
        o_exam_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_flg_image = 'Y'
        THEN
            g_error := 'GET EXAM_LIST CURSOR';
            IF i_search IS NULL
            THEN
                OPEN o_exam_list FOR
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) ||
                           decode(e.gender,
                                  NULL,
                                  NULL,
                                  ' - <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T034') || ': ' ||
                                  pk_sysdomain.get_domain('PATIENT.GENDER', e.gender, i_lang) || '<\b>') ||
                           decode(e.age_min,
                                  NULL,
                                  NULL,
                                  ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T010') || ': ' ||
                                  e.age_min || '<\b>') ||
                           decode(e.age_max,
                                  NULL,
                                  NULL,
                                  ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T011') || ': ' ||
                                  e.age_max || '<\b>') exam_name,
                           pk_translation.get_translation(i_lang, e.code_exam) exam_name_abrev,
                           decode(e.flg_available, 'Y', 'A', 'I') flg_status
                      FROM exam e
                     WHERE e.flg_type = 'I'
                     ORDER BY flg_status, e.gender, exam_name;
            ELSE
                OPEN o_exam_list FOR
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) ||
                           decode(e.gender,
                                  NULL,
                                  NULL,
                                  ' - <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T034') || ': ' ||
                                  pk_sysdomain.get_domain('PATIENT.GENDER', e.gender, i_lang) || '<\b>') ||
                           decode(e.age_min,
                                  NULL,
                                  NULL,
                                  ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T010') || ': ' ||
                                  e.age_min || '<\b>') ||
                           decode(e.age_max,
                                  NULL,
                                  NULL,
                                  ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T011') || ': ' ||
                                  e.age_max || '<\b>') exam_name,
                           pk_translation.get_translation(i_lang, e.code_exam) exam_name_abrev,
                           decode(e.flg_available, 'Y', 'A', 'I') flg_status
                      FROM exam e
                     WHERE e.flg_type = 'I'
                       AND translate(upper(pk_translation.get_translation(i_lang, e.code_exam)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY flg_status, e.gender, exam_name;
            END IF;
        ELSE
            IF i_search IS NULL
            THEN
                OPEN o_exam_list FOR
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) ||
                           decode(e.gender,
                                  NULL,
                                  NULL,
                                  ' - <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T034') || ': ' ||
                                  pk_sysdomain.get_domain('PATIENT.GENDER', e.gender, i_lang) || '<\b>') ||
                           decode(e.age_min,
                                  NULL,
                                  NULL,
                                  ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T010') || ': ' ||
                                  e.age_min || '<\b>') ||
                           decode(e.age_max,
                                  NULL,
                                  NULL,
                                  ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T011') || ': ' ||
                                  e.age_max || '<\b>') exam_name,
                           pk_translation.get_translation(i_lang, e.code_exam) exam_name_abrev,
                           decode(e.flg_available, 'Y', 'A', 'I') flg_status
                      FROM exam e
                     WHERE e.flg_type <> 'I'
                     ORDER BY flg_status, e.gender, exam_name;
            ELSE
                OPEN o_exam_list FOR
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) ||
                           decode(e.gender,
                                  NULL,
                                  NULL,
                                  ' - <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T034') || ': ' ||
                                  pk_sysdomain.get_domain('PATIENT.GENDER', e.gender, i_lang) || '<\b>') ||
                           decode(e.age_min,
                                  NULL,
                                  NULL,
                                  ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T010') || ': ' ||
                                  e.age_min || '<\b>') ||
                           decode(e.age_max,
                                  NULL,
                                  NULL,
                                  ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T011') || ': ' ||
                                  e.age_max || '<\b>') exam_name,
                           pk_translation.get_translation(i_lang, e.code_exam) exam_name_abrev,
                           decode(e.flg_available, 'Y', 'A', 'I') flg_status
                      FROM exam e
                     WHERE e.flg_type <> 'I'
                       AND translate(upper(pk_translation.get_translation(i_lang, e.code_exam)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY flg_status, e.gender, exam_name;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                pk_types.open_my_cursor(o_exam_list);
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_EXAM', 'GET_EXAM_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_exams_list;

    /********************************************************************************************
    * Get Exams POSSIBLE LIST
    *
    * @param i_lang            Prefered language ID
    * @param o_list            Plus button options
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2008/04/24
    ********************************************************************************************/
    FUNCTION get_exam_poss_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET EXAMS ADD LIST CURSOR';
        OPEN o_list FOR
            SELECT val data, desc_val label
              FROM sys_domain
             WHERE code_domain = 'EXAM_ADD_TASK'
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                pk_types.open_my_cursor(o_list);
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_EXAM',
                                   'GET_EXAM_POSS_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_exam_poss_list;

    /********************************************************************************************
    * Get Exam Information
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Object Profissional (professional ID, institution ID, software ID)
    * @param i_id_exam             Exam ID
    * @param o_exam                Exam
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/15
    ********************************************************************************************/
    FUNCTION get_exam
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_exam IN exam.id_exam%TYPE,
        o_exam    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET EXAM CURSOR';
        OPEN o_exam FOR
            SELECT e.id_exam id,
                   pk_translation.get_translation(i_lang, e.code_exam) name,
                   decode(e.flg_available, 'Y', 'A', 'I') flg_status,
                   e.id_exam_cat,
                   pk_translation.get_translation(i_lang, ec.code_exam_cat) exam_cat_desc,
                   pk_sysdomain.get_domain(g_exam_flg_available, nvl(e.flg_available, g_yes), i_lang) state,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, e.adw_last_update, i_prof) upd_date,
                   e.flg_type,
                   pk_sysdomain.get_domain(g_exam_flg_type, e.flg_type, i_lang) type_desc,
                   e.gender,
                   pk_sysdomain.get_domain(g_patient_gender, nvl(e.gender, NULL), i_lang) genero,
                   e.age_min,
                   e.age_max
              FROM exam e, exam_cat ec
             WHERE e.id_exam = i_id_exam
               AND e.id_exam_cat = ec.id_exam_cat;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                pk_types.open_my_cursor(o_exam);
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_EXAM', 'GET_EXAM');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_exam;

    /********************************************************************************************
    * Get other exams type list
    *
    * @param i_lang                Prefered language ID
    * @param o_type                Other exam type list
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION get_other_exam_type_list
    (
        i_lang  IN language.id_language%TYPE,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET TYPE CURSOR';
        OPEN o_type FOR
            SELECT sd.val, sd.desc_val
              FROM sys_domain sd
             WHERE sd.code_domain = g_exam_flg_type
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND sd.val != 'I';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                pk_types.open_my_cursor(o_type);
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_EXAM',
                                   'GET_OTHER_EXAM_TYPE_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_other_exam_type_list;

    /********************************************************************************************
    * Get Time Unit Measure Information List
    *
    * @param i_lang                Prefered language ID
    * @param o_unit                Unit measures
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION get_unit_measure_time
    (
        i_lang  IN language.id_language%TYPE,
        o_unit  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_unit FOR
            SELECT u.id_unit_measure, pk_translation.get_translation(i_lang, u.code_unit_measure) measure
              FROM unit_measure u
             WHERE u.id_unit_measure IN
                   (g_min_unit_measure, g_hours_unit_measure, g_day_unit_measure, g_week_unit_measure)
             ORDER BY measure;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                pk_types.open_my_cursor(o_unit);
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_EXAM',
                                   'GET_UNIT_MEASURE_TIME');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_unit_measure_time;

    /********************************************************************************************
    * Interval in minutes for a unit_measure
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Object Profissional (professional ID, institution ID, software ID) 
    * @param i_freq                Unit number
    * @param i_unit_freq           Unit measure
    * @param o_interval            Interval in minutes
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION get_interval
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_freq      IN NUMBER,
        i_unit_freq IN NUMBER,
        o_interval  OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_unit_freq = g_hours_unit_measure
        THEN
            o_interval := i_freq * g_hour_min;
        ELSIF i_unit_freq = g_day_unit_measure
        THEN
            o_interval := i_freq * g_day_min;
        ELSIF i_unit_freq = g_week_unit_measure
        THEN
            o_interval := i_freq * g_week_min;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_EXAM', 'GET_INTERVAL');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_interval;

    /********************************************************************************************
    * Insert New Exam OR Update Exam Information
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Object Profissional (professional ID, institution ID, software ID)
    * @param i_id_exam             Exam ID
    * @param i_desc                Exam Name
    * @param i_flg_available       Flag available
    * @param i_flg_type            Exam Type
    * @param i_id_exam_cat         Exam category
    * @param i_gender              Gender
    * @param i_age_min             Minimum age
    * @param i_age_max             Maximum age
    * @param i_mdm_coding          MDM code
    * @param i_cpt_code            CPT code
    * @param i_flg_pat_resp        Term of responsability
    * @param i_flg_pat_prep        Preparation indications
    * @param o_id_exam             Exam ID
    * @param o_error               Error
    *
    * @value i_flg_available       {*} 'Y' Available {*} 'N' Not available
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION set_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_exam       IN exam.id_exam%TYPE,
        i_desc          IN VARCHAR2,
        i_flg_available IN exam.flg_available%TYPE,
        i_flg_type      IN exam.flg_type%TYPE,
        i_id_exam_cat   IN exam.id_exam_cat%TYPE,
        i_gender        IN analysis.gender%TYPE,
        i_age_min       IN analysis.age_min%TYPE,
        i_age_max       IN analysis.age_max%TYPE,
        i_mdm_coding    IN VARCHAR2,
        i_cpt_code      IN VARCHAR2,
        i_flg_pat_resp  IN VARCHAR2,
        i_flg_pat_prep  IN VARCHAR2,
        o_id_exam       OUT exam.id_exam%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_available VARCHAR2(1);
    
        l_rows_out table_varchar;
        l_error    t_error_out;
    BEGIN
    
        SELECT decode(i_flg_available, 'A', 'Y', 'N')
          INTO l_flg_available
          FROM dual;
    
        IF i_id_exam IS NULL
        THEN
            g_error := 'GET SEQ_EXAM.NEXTVAL';
            SELECT seq_exam.nextval
              INTO o_id_exam
              FROM dual;
        
            g_error := 'INSERT INTO EXAM';
            ts_exam.ins(id_exam_in         => o_id_exam,
                        flg_available_in   => l_flg_available,
                        rank_in            => 0,
                        flg_type_in        => i_flg_type,
                        gender_in          => i_gender,
                        age_min_in         => i_age_min,
                        age_max_in         => i_age_max,
                        id_exam_cat_in     => i_id_exam_cat,
                        adw_last_update_in => SYSDATE,
                        rows_out           => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EXAM',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        
            pk_translation.insert_into_translation(i_lang, 'EXAM.CODE_EXAM.' || o_id_exam || '', i_desc);
        
        ELSE
            g_error := 'UPDATE EXAM';
        
            ts_exam.upd(id_exam_in          => i_id_exam,
                        flg_available_in    => l_flg_available,
                        flg_available_nin   => FALSE,
                        rank_in             => 0,
                        rank_nin            => FALSE,
                        adw_last_update_in  => SYSDATE,
                        adw_last_update_nin => FALSE,
                        flg_type_in         => i_flg_type,
                        flg_type_nin        => FALSE,
                        gender_in           => i_gender,
                        gender_nin          => FALSE,
                        age_min_in          => i_age_min,
                        age_min_nin         => FALSE,
                        age_max_in          => i_age_max,
                        age_max_nin         => FALSE,
                        id_exam_cat_in      => i_id_exam_cat,
                        id_exam_cat_nin     => FALSE,
                        rows_out            => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EXAM',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
            o_id_exam := i_id_exam;
        
            pk_translation.insert_into_translation(i_lang, 'EXAM.CODE_EXAM.' || o_id_exam || '', i_desc);
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_EXAM', 'SET_EXAM');
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_exam;

    /********************************************************************************************
    * Update Exam state
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional
    * @param i_id_exam             Exam ID's
    * @param i_flg_available       Flag available
    * @param o_error               Error
    *
    * @value i_flg_available       {*} 'Y' Available {*} 'N' Not available
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION set_exam_state
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_exam       IN table_number,
        i_flg_available IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_available exam.flg_available%TYPE;
    
        l_rows_out table_varchar := table_varchar();
        l_error    t_error_out;
    BEGIN
        FOR i IN 1 .. i_id_exam.count
        LOOP
        
            l_flg_available := CASE i_flg_available(i)
                                   WHEN 'A' THEN
                                    'Y'
                                   ELSE
                                    'N'
                               END;
        
            g_error := 'UPDATE EXAM';
            ts_exam.upd(id_exam_in        => i_id_exam(i),
                        flg_available_in  => l_flg_available,
                        flg_available_nin => FALSE,
                        rows_out          => l_rows_out);
        END LOOP;
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM',
                                      i_rowids     => l_rows_out,
                                      o_error      => l_error);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_EXAM', 'SET_EXAM_STATE');
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_exam_state;

    /** @headcom
    * Public Function. Get Institution Dep. Clinical Service Exams List
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      I_ID_DEP_CLIN_SERV         Department/Clinical service identification
    * @param      I_ID_SOFTWARE              Software identification
    * @param      I_FLG_IMAGE                Exams type
    * @param      O_EXAM_DCS_LIST            Cursor with the most frequent exams list 
    * @param      O_ERROR                    Error
    *
    * @value     I_FLG_IMAGE                 {*} 'Y' Image exams {*} 'N' Other exams  
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/15
    */
    FUNCTION get_exam_dcs_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dept          IN dept.id_dept%TYPE,
        i_id_dep_clin_serv IN exam_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_software      IN exam_dep_clin_serv.id_software%TYPE,
        i_id_institution   IN exam_dep_clin_serv.id_institution%TYPE,
        i_flg_image        IN VARCHAR2,
        o_exam_dcs_list    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET EXAM_DCS_LIST CURSOR';
    
        IF i_flg_image = 'I'
        THEN
            OPEN o_exam_dcs_list FOR
                SELECT e.id_exam, pk_translation.get_translation(i_lang, e.code_exam) exam_name, 'A' flg_status
                  FROM exam e, exam_dep_clin_serv edcs
                 WHERE edcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND edcs.id_software = i_id_software
                   AND edcs.flg_type = 'M'
                   AND edcs.id_exam = e.id_exam
                   AND e.flg_type = 'I'
                UNION
                SELECT e.id_exam, pk_translation.get_translation(i_lang, e.code_exam) exam_name, 'I' flg_status
                  FROM exam e
                 WHERE e.id_exam NOT IN (SELECT e2.id_exam
                                           FROM exam e2, exam_dep_clin_serv edcs2
                                          WHERE edcs2.id_dep_clin_serv = i_id_dep_clin_serv
                                            AND edcs2.id_software = i_id_software
                                            AND edcs2.flg_type = 'M'
                                            AND edcs2.id_exam = e2.id_exam
                                            AND e2.flg_type = 'I')
                   AND e.flg_type = 'I'
                 ORDER BY exam_name;
        ELSIF i_flg_image = 'O'
        THEN
            OPEN o_exam_dcs_list FOR
                SELECT e.id_exam, pk_translation.get_translation(i_lang, e.code_exam) exam_name, 'A' flg_status
                  FROM exam e, exam_dep_clin_serv edcs
                 WHERE edcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND edcs.id_software = i_id_software
                   AND edcs.flg_type = 'M'
                   AND edcs.id_exam = e.id_exam
                   AND e.flg_type != 'I'
                UNION
                SELECT e.id_exam, pk_translation.get_translation(i_lang, e.code_exam) exam_name, 'I' flg_status
                  FROM exam e
                 WHERE e.id_exam NOT IN (SELECT e2.id_exam
                                           FROM exam e2, exam_dep_clin_serv edcs2
                                          WHERE edcs2.id_dep_clin_serv = i_id_dep_clin_serv
                                            AND edcs2.id_software = i_id_software
                                            AND edcs2.flg_type = 'M'
                                            AND edcs2.id_exam = e2.id_exam
                                            AND e2.flg_type != 'I')
                   AND e.flg_type != 'I'
                 ORDER BY exam_name;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_EXAM',
                                   'GET_EXAM_DCS_LIST');
                pk_types.open_my_cursor(o_exam_dcs_list);
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_exam_dcs_list;

    /********************************************************************************************
    * Exam/Dep_clin_serv association
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param i_dep_clin_serv         Array of Department/Clinical Service ID's
    * @param i_exam                  Exam ID's
    * @param i_select                Array (Y - insert; N - delete)
    * @param i_commit_at_end         Commit (Y - Yes; N - No)
    * @param o_id_exam_dep_clin_serv Associations ID's
    * @param o_error                 Error
    *
    *
    * @value i_select                {*} 'Y' Insert {*} 'N' Delete
    * @value i_commit_at_end         {*} 'Y' Yes {*} 'N' No
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/17
    ********************************************************************************************/
    FUNCTION set_exam_dcs
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_software           IN software.id_software%TYPE,
        i_dep_clin_serv         IN table_number,
        i_exam                  IN table_table_number,
        i_select                IN table_table_varchar,
        i_commit_at_end         IN VARCHAR2,
        o_id_exam_dep_clin_serv OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_i    NUMBER := 0;
        c_soft pk_types.cursor_type;
        l_soft NUMBER;
        l_res  BOOLEAN;
    
    BEGIN
        o_id_exam_dep_clin_serv := table_number();
    
        IF i_id_software = -1
        THEN
            OPEN c_soft FOR
                SELECT DISTINCT s.id_software
                  FROM exam_dep_clin_serv edcs, software s
                 WHERE edcs.id_institution = i_id_institution
                   AND edcs.id_software = s.id_software
                   AND s.flg_viewer = 'N'
                   AND s.id_software != 26;
        
            LOOP
                FETCH c_soft
                    INTO l_soft;
                EXIT WHEN c_soft%NOTFOUND;
            
                l_res := set_exam_dcs(i_lang,
                                      i_prof,
                                      i_id_institution,
                                      l_soft,
                                      i_dep_clin_serv,
                                      i_exam,
                                      i_select,
                                      g_no,
                                      o_id_exam_dep_clin_serv,
                                      o_error);
            
            END LOOP;
            CLOSE c_soft;
        ELSE
        
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_exam(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM EXAM_DEP_CLIN_SERV';
                        DELETE FROM exam_dep_clin_serv edcs
                         WHERE edcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND edcs.id_exam = i_exam(i) (j)
                           AND edcs.id_software = i_id_software
                           AND edcs.id_institution = i_id_institution;
                    ELSE
                        o_id_exam_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_EXAM.NEXTVAL';
                        SELECT seq_exam_dep_clin_serv.nextval
                          INTO o_id_exam_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO EXAM_DEP_CLIN_SERV';
                        INSERT INTO exam_dep_clin_serv
                            (id_exam_dep_clin_serv,
                             id_exam,
                             id_dep_clin_serv,
                             flg_type,
                             rank,
                             id_institution,
                             id_software)
                        VALUES
                            (o_id_exam_dep_clin_serv(l_i),
                             i_exam(i) (j),
                             i_dep_clin_serv(i),
                             'M',
                             0,
                             i_id_institution,
                             i_id_software);
                    
                    END IF;
                
                END LOOP;
            END LOOP;
        
        END IF;
    
        IF i_commit_at_end = g_yes
        THEN
            COMMIT;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_EXAM', 'SET_EXAM_DCS');
            
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_exam_dcs;

    /********************************************************************************************
    * Get Exams by Institution and Software
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_flg_imagem          Exams Type: I - Image exams ; O - Other exams
    * @param i_search              Search
    * @param o_inst_soft_exam_list Exams list
    * @param o_error               Error
    *
    * @value i_flg_imagem          {*} 'I' Image exams {*} 'O' Other exams
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/29
    ********************************************************************************************/
    FUNCTION get_inst_soft_exam_list
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN analysis_instit_soft.id_institution%TYPE,
        i_id_software         IN analysis_instit_soft.id_software%TYPE,
        i_flg_image           IN VARCHAR2,
        i_search              IN VARCHAR2,
        o_inst_soft_exam_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF i_flg_image = 'I'
        THEN
            g_error := 'GET EXAM_LIST CURSOR';
            IF i_search IS NULL
            THEN
                OPEN o_inst_soft_exam_list FOR
                    SELECT DISTINCT e.id_exam id,
                                    pk_translation.get_translation(i_lang, e.code_exam) name,
                                    edcs.flg_type flg_status,
                                    pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE',
                                                            decode(edcs.flg_type, 'P', 'E', edcs.flg_type),
                                                            i_lang) status_desc,
                                    pk_backoffice_mcdt.get_missing_data(i_lang,
                                                                        e.id_exam,
                                                                        i_id_institution,
                                                                        edcs.id_software,
                                                                        'E') missing_data
                      FROM exam_dep_clin_serv edcs, exam e
                     WHERE edcs.id_institution = i_id_institution
                       AND edcs.id_software = i_id_software
                       AND edcs.flg_type = 'P'
                       AND edcs.id_exam = e.id_exam
                       AND e.flg_available = g_flg_available
                       AND e.flg_type = 'I'
                     ORDER BY name;
            ELSE
                OPEN o_inst_soft_exam_list FOR
                    SELECT DISTINCT e.id_exam id,
                                    pk_translation.get_translation(i_lang, e.code_exam) name,
                                    edcs.flg_type flg_status,
                                    pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE',
                                                            decode(edcs.flg_type, 'P', 'E', edcs.flg_type),
                                                            i_lang) status_desc,
                                    pk_backoffice_mcdt.get_missing_data(i_lang,
                                                                        e.id_exam,
                                                                        i_id_institution,
                                                                        edcs.id_software,
                                                                        'E') missing_data
                      FROM exam_dep_clin_serv edcs, exam e
                     WHERE edcs.id_institution = i_id_institution
                       AND edcs.id_software = i_id_software
                       AND edcs.flg_type = 'P'
                       AND edcs.id_exam = e.id_exam
                       AND e.flg_available = g_flg_available
                       AND e.flg_type = 'I'
                       AND translate(upper(pk_translation.get_translation(i_lang, e.code_exam)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY name;
            END IF;
        ELSE
            g_error := 'GET EXAM_LIST CURSOR';
            IF i_search IS NULL
            THEN
                OPEN o_inst_soft_exam_list FOR
                    SELECT DISTINCT e.id_exam id,
                                    pk_translation.get_translation(i_lang, e.code_exam) name,
                                    edcs.flg_type flg_status,
                                    pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE',
                                                            decode(edcs.flg_type, 'P', 'E', edcs.flg_type),
                                                            i_lang) status_desc,
                                    pk_backoffice_mcdt.get_missing_data(i_lang,
                                                                        e.id_exam,
                                                                        i_id_institution,
                                                                        edcs.id_software,
                                                                        'E') missing_data
                      FROM exam_dep_clin_serv edcs, exam e
                     WHERE edcs.id_institution = i_id_institution
                       AND edcs.id_software = i_id_software
                       AND edcs.flg_type = 'P'
                       AND edcs.id_exam = e.id_exam
                       AND e.flg_available = g_flg_available
                       AND e.flg_type != 'I'
                     ORDER BY name;
            ELSE
                OPEN o_inst_soft_exam_list FOR
                    SELECT DISTINCT e.id_exam id,
                                    pk_translation.get_translation(i_lang, e.code_exam) name,
                                    edcs.flg_type flg_status,
                                    pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE',
                                                            decode(edcs.flg_type, 'P', 'E', edcs.flg_type),
                                                            i_lang) status_desc,
                                    pk_backoffice_mcdt.get_missing_data(i_lang,
                                                                        e.id_exam,
                                                                        i_id_institution,
                                                                        edcs.id_software,
                                                                        'E') missing_data
                      FROM exam_dep_clin_serv edcs, exam e
                     WHERE edcs.id_institution = i_id_institution
                       AND edcs.id_software = i_id_software
                       AND edcs.flg_type = 'P'
                       AND edcs.id_exam = e.id_exam
                       AND e.flg_available = g_flg_available
                       AND e.flg_type != 'I'
                       AND translate(upper(pk_translation.get_translation(i_lang, e.code_exam)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY name;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_EXAM',
                                   'GET_INST_SOFT_ANALYSIS_LIST');
                pk_types.open_my_cursor(o_inst_soft_exam_list);
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_soft_exam_list;

BEGIN
    g_flg_available := 'Y';
    g_no            := 'N';
    g_yes           := 'Y';

    g_exam_flg_available := 'EXAM.FLG_AVAILABLE';
    g_exam_flg_type      := 'EXAM.FLG_TYPE';
    g_exam_flg_pat_prep  := 'EXAM.FLG_PAT_PREP';
    g_exam_flg_pat_resp  := 'EXAM.FLG_PAT_RESP';

    g_patient_gender := 'PATIENT.GENDER';

    g_min_unit_measure   := 10374;
    g_hours_unit_measure := 1041;
    g_day_unit_measure   := 1039;
    g_week_unit_measure  := 10375;

    g_hour_min := 60;
    g_day_min  := 1440;
    g_week_min := 10080;

END pk_backoffice_exam;
/
