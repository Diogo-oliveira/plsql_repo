/*-- Last Change Revision: $Rev: 2053893 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-30 14:20:45 +0000 (sex, 30 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_mcdt IS
    g_num_records CONSTANT NUMBER(24) := 50;

    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @return                        Number of records
    *
    * @author                        RMGM
    * @since                         2011/06/28
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_num_records RETURN NUMBER IS
    BEGIN
        RETURN g_num_records;
    END get_num_records;

    /********************************************************************************************
    * Get Analysis List
    *
    * @param i_lang            Prefered language ID
    * @param i_search_name     Search name
    * @param i_search_sample   Search sample
    * @param o_analysis_list   Analysis
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2007/11/23
    ********************************************************************************************/
    FUNCTION get_analysis_list
    (
        i_lang          IN language.id_language%TYPE,
        i_search_name   IN VARCHAR2,
        i_search_sample IN VARCHAR2,
        o_analysis_list OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS_LIST CURSOR';
        IF i_search_name IS NULL
           AND i_search_sample IS NULL
        THEN
            OPEN o_analysis_list FOR
                SELECT a.id_analysis id,
                       pk_translation.get_translation(i_lang, a.code_analysis) ||
                       decode(a.gender,
                              NULL,
                              NULL,
                              ' - <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T034') || ': ' ||
                              pk_sysdomain.get_domain('PATIENT.GENDER', a.gender, i_lang) || '<\b>') ||
                       decode(a.age_min,
                              NULL,
                              NULL,
                              ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T010') || ': ' ||
                              a.age_min || '<\b>') ||
                       decode(a.age_max,
                              NULL,
                              NULL,
                              ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T011') || ': ' ||
                              a.age_max || '<\b>') analysis_name,
                       pk_translation.get_translation(i_lang, a.code_analysis) analysis_name_abrev,
                       st.id_sample_type,
                       pk_translation.get_translation(i_lang, st.code_sample_type) analysis_type,
                       decode(a.flg_available, 'Y', 'A', 'I') flg_status
                  FROM analysis a, analysis_sample_type ast, sample_type st
                 WHERE a.id_analysis = ast.id_analysis
                   AND ast.id_sample_type = st.id_sample_type
                 ORDER BY flg_status, a.gender, analysis_name;
        ELSIF i_search_name IS NOT NULL
              AND i_search_sample IS NULL
        THEN
            OPEN o_analysis_list FOR
                SELECT a.id_analysis id,
                       pk_translation.get_translation(i_lang, a.code_analysis) ||
                       decode(a.gender,
                              NULL,
                              NULL,
                              ' - <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T034') || ': ' ||
                              pk_sysdomain.get_domain('PATIENT.GENDER', a.gender, i_lang) || '<\b>') ||
                       decode(a.age_min,
                              NULL,
                              NULL,
                              ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T010') || ': ' ||
                              a.age_min || '<\b>') ||
                       decode(a.age_max,
                              NULL,
                              NULL,
                              ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T011') || ': ' ||
                              a.age_max || '<\b>') analysis_name,
                       st.id_sample_type,
                       pk_translation.get_translation(i_lang, st.code_sample_type) analysis_type,
                       decode(a.flg_available, 'Y', 'A', 'I') flg_status
                  FROM analysis a, analysis_sample_type ast, sample_type st
                 WHERE a.id_analysis = ast.id_analysis
                   AND ast.id_sample_type = st.id_sample_type
                   AND translate(upper(pk_translation.get_translation(i_lang, a.code_analysis)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search_name), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY flg_status, a.gender, analysis_name;
        ELSE
            OPEN o_analysis_list FOR
                SELECT a.id_analysis id,
                       pk_translation.get_translation(i_lang, a.code_analysis) ||
                       decode(a.gender,
                              NULL,
                              NULL,
                              ' - <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T034') || ': ' ||
                              pk_sysdomain.get_domain('PATIENT.GENDER', a.gender, i_lang) || '<\b>') ||
                       decode(a.age_min,
                              NULL,
                              NULL,
                              ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T010') || ': ' ||
                              a.age_min || '<\b>') ||
                       decode(a.age_max,
                              NULL,
                              NULL,
                              ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T011') || ': ' ||
                              a.age_max || '<\b>') analysis_name,
                       st.id_sample_type,
                       pk_translation.get_translation(i_lang, st.code_sample_type) analysis_type,
                       decode(a.flg_available, 'Y', 'A', 'I') flg_status
                  FROM analysis a, analysis_sample_type ast, sample_type st
                 WHERE a.id_analysis = ast.id_analysis
                   AND ast.id_sample_type = st.id_sample_type
                   AND translate(upper(pk_translation.get_translation(i_lang, a.code_analysis)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search_name), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND translate(upper(pk_translation.get_translation(i_lang, st.code_sample_type)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' ||
                       translate(upper(i_search_sample), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY flg_status, a.gender, analysis_name;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_analysis_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_analysis_list;

    /********************************************************************************************
    * Get Analysis screen tasks list
    *
    * @param i_lang            Prefered language ID
    * @param o_list            Tasks
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2007/11/26
    ********************************************************************************************/
    FUNCTION get_analysis_possible_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS ADD LIST CURSOR';
        OPEN o_list FOR
        
            SELECT val, desc_val
              FROM sys_domain
             WHERE code_domain = g_analysis_add_task
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_POSSIBLE_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_possible_list;

    /********************************************************************************************
    * Get Analysis status list
    *
    * @param i_lang            Prefered language ID
    * @param o_analysis_state  Status
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2007/11/26
    ********************************************************************************************/
    FUNCTION get_analysis_state_list
    (
        i_lang           IN language.id_language%TYPE,
        o_analysis_state OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET PROFESSIONAL STATE CURSOR';
        OPEN o_analysis_state FOR
            SELECT val, desc_val, img_name icon
              FROM sys_domain
             WHERE code_domain = g_analysis_flg_available
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_analysis_state);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_STATE_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_state_list;

    /********************************************************************************************
    * Update Analysis Status
    *
    * @param i_lang            Prefered language ID
    * @param i_id_analysis     Analysis ID
    * @param i_flg_available   Status
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2007/11/26
    ********************************************************************************************/
    FUNCTION set_analysis_state
    (
        i_lang          IN language.id_language%TYPE,
        i_id_analysis   IN table_number,
        i_flg_available IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN 1 .. i_id_analysis.count
        LOOP
            g_error := 'UPDATE ANALYSIS';
            UPDATE analysis
               SET flg_available = decode(i_flg_available(i), 'A', 'Y', 'N')
             WHERE id_analysis = i_id_analysis(i);
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_ANALYSIS_STATE');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_analysis_state;

    /********************************************************************************************
    * Get Analysis Information
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Object (professional ID, institution ID, software ID)
    * @param i_id_analysis         Analysis ID
    * @param o_analysis            Analysis
    * @param o_analysis_parameter  Analysis parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2007/11/23
    ********************************************************************************************/
    FUNCTION get_analysis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_analysis        IN analysis.id_analysis%TYPE,
        o_analysis           OUT pk_types.cursor_type,
        o_analysis_parameter OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS CURSOR';
        OPEN o_analysis FOR
            SELECT ast.id_analysis id,
                   pk_translation.get_translation(i_lang, 'ANALYSIS.CODE_ANALYSIS.' || ast.id_analysis) name,
                   ast.flg_available,
                   pk_sysdomain.get_domain(g_analysis_flg_available, nvl(ast.flg_available, g_yes), i_lang) state,
                   NULL upd_date,
                   ast.id_sample_type,
                   pk_translation.get_translation(i_lang, 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ast.id_sample_type) sample_type,
                   ast.gender,
                   pk_sysdomain.get_domain(g_patient_gender, nvl(ast.gender, NULL), i_lang) genero,
                   ast.age_min,
                   ast.age_max
              FROM analysis_sample_type ast
             WHERE ast.id_analysis = i_id_analysis;
    
        OPEN o_analysis_parameter FOR
            SELECT bap.id_bo_analysis_param,
                   bap.id_analysis,
                   bap.id_analysis_parameter,
                   pk_translation.get_translation(i_lang, ap.code_analysis_parameter) analysis_parameter_name
              FROM bo_analysis_param bap, analysis_parameter ap
             WHERE bap.id_analysis = i_id_analysis
               AND bap.id_analysis_parameter = ap.id_analysis_parameter;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_analysis);
                pk_types.open_my_cursor(o_analysis_parameter);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_MCDT', 'GET_ANALYSIS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis;

    /********************************************************************************************
    * Find LOINC code
    *
    * @param i_lang           Prefered language ID
    * @param i_prof           Object (professional ID, institution ID, software ID)
    * @param i_loinc_code     LOINC code
    * @param o_loinc_list     LOINC
    * @param o_error          Error
    *
    *
    * @return                 true or false on success or error
    *
    * @author                 JTS
    * @version                0.1
    * @since                  2007/11/23
    ********************************************************************************************/
    FUNCTION find_loinc_code
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_loinc_code IN analysis_loinc_template.loinc_code%TYPE,
        o_loinc_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_counter   NUMBER;
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'SELECT COUNT(*)';
        SELECT COUNT(DISTINCT alt.loinc_code)
          INTO l_counter
          FROM analysis_loinc_template alt
         WHERE upper(alt.loinc_code) LIKE upper('%' || i_loinc_code || '%');
    
        IF l_counter > 150
        THEN
            OPEN o_loinc_list FOR
                SELECT 1
                  FROM dual
                 WHERE 1 = 2;
            g_error := pk_search.get_overlimit_message(i_lang, i_prof, pk_alert_constant.g_yes, NULL);
        
            RAISE l_exception;
        
        ELSIF l_counter = 0
        THEN
            OPEN o_loinc_list FOR
                SELECT 1
                  FROM dual
                 WHERE 1 = 2;
        
            g_error := pk_message.get_message(i_lang, 'COMMON_M015');
        
            RAISE l_exception;
        
        END IF;
    
        OPEN o_loinc_list FOR
            SELECT DISTINCT alt.loinc_code
              FROM analysis_loinc_template alt
             WHERE upper(alt.loinc_code) LIKE upper('%' || i_loinc_code || '%');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_loinc_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_TRIAGE',
                                              'FIND_LOINC_CODE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_loinc_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_MCDT', 'FIND_LOINC_CODE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END find_loinc_code;

    /********************************************************************************************
    * Get Sample Type List
    *
    * @param i_lang                 Prefered language ID
    * @param o_sample_type_list     Cursor with a list of Sample types
    * @param o_error          Error
    *
    *
    * @return                 true or false on success or error
    *
    * @author                 JTS
    * @version                0.1
    * @since                  2007/11/23
    ********************************************************************************************/
    FUNCTION get_sample_type_list
    (
        i_lang             IN language.id_language%TYPE,
        o_sample_type_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SAMPLE_TYPE_LIST CURSOR';
        OPEN o_sample_type_list FOR
            SELECT st.id_sample_type id, pk_translation.get_translation(i_lang, st.code_sample_type) name
              FROM sample_type st
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_sample_type_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SAMPLE_TYPE_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_sample_type_list;

    /********************************************************************************************
    * Get sample recipient list
    *
    * @param i_lang           Prefered language ID
    * @param i_search         Search
    * @param o_recipient_list Sample recipients
    * @param o_error          Error
    *
    *
    * @return                 true or false on success or error
    *
    * @author                 JTS
    * @version                0.1
    * @since                  2007/11/23
    ********************************************************************************************/
    FUNCTION get_sample_recipient_list
    (
        i_lang           IN language.id_language%TYPE,
        i_search         IN VARCHAR2,
        o_recipient_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET RECIPIENT LIST CURSOR';
    
        IF i_search IS NULL
        THEN
            OPEN o_recipient_list FOR
                SELECT sr.id_sample_recipient id,
                       pk_translation.get_translation(i_lang, sr.code_sample_recipient) name,
                       sr.capacity,
                       sr.flg_available,
                       pk_sysdomain.get_domain(g_recipient_flg_available, nvl(sr.flg_available, g_yes), i_lang) state,
                       pk_sysdomain.get_img(i_lang, g_recipient_flg_available, nvl(sr.flg_available, g_yes)) icon
                  FROM sample_recipient sr
                 ORDER BY state, name;
        ELSE
            OPEN o_recipient_list FOR
                SELECT sr.id_sample_recipient id,
                       pk_translation.get_translation(i_lang, sr.code_sample_recipient) name,
                       sr.capacity,
                       sr.flg_available,
                       pk_sysdomain.get_domain(g_recipient_flg_available, nvl(sr.flg_available, g_yes), i_lang) state,
                       pk_sysdomain.get_img(i_lang, g_recipient_flg_available, nvl(sr.flg_available, g_yes)) icon
                  FROM sample_recipient sr
                 WHERE translate(upper(pk_translation.get_translation(i_lang, sr.code_sample_recipient)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY state, name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_recipient_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SAMPLE_RECIPIENT_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_sample_recipient_list;

    /********************************************************************************************
    * Get Software's Analysis Sample Recipient List
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_soft_recipient_list   Sample recipients
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2007/11/27
    ********************************************************************************************/
    FUNCTION get_soft_recipient_list
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN analysis_param.id_institution%TYPE,
        i_id_software         IN table_number,
        o_soft_recipient_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS_SAMPLE_RECIPIENT_LIST CURSOR';
        OPEN o_soft_recipient_list FOR
            SELECT DISTINCT sr.id_sample_recipient,
                            pk_translation.get_translation(i_lang, sr.code_sample_recipient) recipient_name
              FROM analysis_instit_recipient air, analysis_instit_soft ais, sample_recipient sr
             WHERE ais.id_institution = i_id_institution
               AND ais.id_software IN (SELECT column_value
                                         FROM TABLE(CAST(i_id_software AS table_number)))
               AND ais.id_analysis_instit_soft = air.id_analysis_instit_soft
               AND air.id_sample_recipient = sr.id_sample_recipient
             ORDER BY recipient_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_soft_recipient_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SOFT_RECIPIENT_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_soft_recipient_list;

    /********************************************************************************************
    * Public Function. Set New Sample Recipient OR Update Recipient Information
    * 
    * @param      I_LANG                        Prefered language ID
    * @param      I_ID_SAMPLE_RECIPIENT         Sample Recipient Id
    * @param      I_DESC                        Recipient description
    * @param      i_flg_available               Flag available
    * @param      I_CAPACITY                    Recipient capacity
    * @param      I_CODE_CAPACITY_MEASURE       Code capacity measure
    * @param      O_ID_SAMPLE_RECIPIENT         Recipient Id
    * @param      O_ERROR                       Error
    *
    * @return     boolean
    * @author     TÈrcio Soares - JTS
    * @version    0.1
    * @since      2007/11/23
    *********************************************************************************************/
    FUNCTION set_sample_recipient
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_sample_recipient   IN sample_recipient.id_sample_recipient%TYPE,
        i_desc                  IN VARCHAR2,
        i_flg_available         IN sample_recipient.flg_available%TYPE,
        i_capacity              IN sample_recipient.capacity%TYPE,
        i_code_capacity_measure IN sample_recipient.code_capacity_measure%TYPE,
        o_id_sample_recipient   OUT sample_recipient.id_sample_recipient%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
        g_sysdate := SYSDATE;
    
        IF i_desc IS NULL
        THEN
            RAISE l_exception;
        
        ELSIF i_id_sample_recipient IS NULL
        THEN
            g_error := 'GET SEQ_SAMPLE_RECIPIENT.NEXTVAL';
            SELECT seq_sample_recipient.nextval
              INTO o_id_sample_recipient
              FROM dual;
        
            g_error := 'INSERT INTO SAMPLE_RECIPIENT';
            INSERT INTO sample_recipient
                (id_sample_recipient, flg_available, rank, adw_last_update, capacity, code_capacity_measure)
            VALUES
                (o_id_sample_recipient, i_flg_available, 0, g_sysdate, i_capacity, i_code_capacity_measure);
        
            pk_translation.insert_into_translation(i_lang,
                                                   'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' || o_id_sample_recipient || '',
                                                   i_desc);
        ELSE
            g_error := 'UPDATE SAMPLE_RECIPIENT';
            UPDATE sample_recipient
               SET adw_last_update       = g_sysdate,
                   flg_available         = i_flg_available,
                   capacity              = i_capacity,
                   code_capacity_measure = i_code_capacity_measure
             WHERE id_sample_recipient = i_id_sample_recipient;
        
            o_id_sample_recipient := i_id_sample_recipient;
        
            pk_translation.insert_into_translation(i_lang,
                                                   'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' || o_id_sample_recipient || '',
                                                   i_desc);
        
        END IF;
    
        RETURN TRUE;
        COMMIT;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_TRIAGE',
                                              'SET_SAMPLE_RECIPIENT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_SAMPLE_RECIPIENT');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_sample_recipient;

    /********************************************************************************************
    * Public Function. Insert New Analysis OR Update Analysis Information
    *
    * @param      I_LANG                               Prefered language ID
    * @param      I_PROF                               Profissional(id_professional,id_institution,id_software)
    * @param      I_ID_ANALYSIS                        Analysis Id
    * @param      I_DESC                               Analysis description
    * @param      I_FLG_AVAILABLE                      Flag available
    * @param      i_id_sample_type                     Sample Type Id
    * @param      I_GENDER                             Gender
    * @param      I_AGE_MIN                            Minimum age
    * @param      I_AGE_MAX                            Maximum age
    * @param      I_MDM_CODING                         Medical Decision Making coding
    * @param      I_CPT_CODE                           Analysis CPT CODE
    * @param      I_LOINC                              LOINC 
    * @param      i_analysis_parameter                 Analysis parameter   
    * @param      i_analysis_parameter_change          Analysis parameter change
    * @param      O_ID_ANALYSIS                        Analysis Id    
    * @param      I_ANALYSIS_LOINC                     Analysis loinc
    * @param      O_ERROR                              Error 
    *
    * @return     boolean
    * @author     TÈrcio Soares - JTS
    * @version    0.1
    * @since      2007/03/22
    **********************************************************************************************/
    FUNCTION set_analysis
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_analysis               IN analysis.id_analysis%TYPE,
        i_desc                      IN VARCHAR2,
        i_flg_available             IN analysis.flg_available%TYPE,
        i_id_sample_type            IN analysis.id_sample_type%TYPE,
        i_gender                    IN analysis.gender%TYPE,
        i_age_min                   IN analysis.age_min%TYPE,
        i_age_max                   IN analysis.age_max%TYPE,
        i_mdm_coding                IN VARCHAR2,
        i_cpt_code                  IN VARCHAR2,
        i_loinc                     IN table_number,
        i_analysis_parameter        IN table_number,
        i_analysis_parameter_change IN table_varchar,
        o_id_analysis               OUT analysis.id_analysis%TYPE,
        o_analysis_loinc            OUT table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bo_ap NUMBER(24);
    
    BEGIN
        g_sysdate := SYSDATE;
    
        IF i_id_analysis IS NULL
        THEN
            g_error := 'GET SEQ_ANALYSIS.NEXTVAL';
            SELECT seq_analysis.nextval
              INTO o_id_analysis
              FROM dual;
        
            g_error := 'INSERT INTO ANALYSIS';
            INSERT INTO analysis
                (id_analysis, flg_available, rank, adw_last_update, id_sample_type, gender, age_min, age_max)
            VALUES
                (o_id_analysis, i_flg_available, 0, g_sysdate, i_id_sample_type, i_gender, i_age_min, i_age_max);
        
            pk_translation.insert_into_translation(i_lang, 'ANALYSIS.CODE_ANALYSIS.' || o_id_analysis || '', i_desc);
        
            FOR i IN 1 .. i_analysis_parameter.count
            LOOP
                g_error := 'GET SEQ_ANALYSIS_LOINC_TEMPLATE.NEXTVAL';
                SELECT seq_bo_analysis_param.nextval
                  INTO l_bo_ap
                  FROM dual;
            
                g_error := 'INSERT INTO BO_ANALYSIS_PARAM';
                INSERT INTO bo_analysis_param
                    (id_bo_analysis_param, id_analysis, id_analysis_parameter)
                VALUES
                    (l_bo_ap, o_id_analysis, i_analysis_parameter(i));
            
            END LOOP;
        
        ELSE
            g_error := 'UPDATE ANALYSIS';
            UPDATE analysis
               SET flg_available   = i_flg_available,
                   rank            = 0,
                   adw_last_update = g_sysdate,
                   id_sample_type  = i_id_sample_type,
                   gender          = i_gender,
                   age_min         = i_age_min,
                   age_max         = i_age_max
             WHERE analysis.id_analysis = i_id_analysis;
        
            o_id_analysis := i_id_analysis;
        
            pk_translation.insert_into_translation(i_lang, 'ANALYSIS.CODE_ANALYSIS.' || o_id_analysis || '', i_desc);
        
            FOR i IN 1 .. i_analysis_parameter.count
            LOOP
                IF i_analysis_parameter_change(i) = 'N'
                THEN
                    g_error := 'DELETE FROM BO_ANALYSIS_PARAM';
                    DELETE FROM bo_analysis_param bap
                     WHERE bap.id_analysis = i_id_analysis
                       AND bap.id_analysis_parameter = i_analysis_parameter(i);
                ELSE
                    g_error := 'GET SEQ_ANALYSIS_LOINC_TEMPLATE.NEXTVAL';
                    SELECT seq_bo_analysis_param.nextval
                      INTO l_bo_ap
                      FROM dual;
                
                    g_error := 'INSERT INTO BO_ANALYSIS_PARAM';
                    INSERT INTO bo_analysis_param
                        (id_bo_analysis_param, id_analysis, id_analysis_parameter)
                    VALUES
                        (l_bo_ap, i_id_analysis, i_analysis_parameter(i));
                END IF;
            END LOOP;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_MCDT', 'SET_ANALYSIS');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_analysis;

    FUNCTION get_analysis_parameter_count
    (
        i_lang                     IN language.id_language%TYPE,
        i_search                   IN VARCHAR2,
        o_analysis_parameter_count OUT NUMBER,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_search VARCHAR2(4000) := '%' ||
                                   translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN') || '%';
    BEGIN
    
        IF i_search IS NULL
        THEN
            g_error := 'GET ANALYSIS_PARAMETER_COUNT CURSOR';
            SELECT nvl(COUNT(*), 0)
              INTO o_analysis_parameter_count
              FROM TABLE(pk_translation.get_table_translation(i_lang, 'ANALYSIS_PARAMETER', g_no)) t
             WHERE EXISTS (SELECT 0
                      FROM analysis_parameter ap
                     WHERE ap.code_analysis_parameter = t.code_translation
                       AND ap.flg_available = g_yes);
        ELSE
            g_error := 'GET ANALYSIS_PARAMETER_COUNT CURSOR';
            SELECT nvl(COUNT(*), 0)
              INTO o_analysis_parameter_count
              FROM TABLE(pk_translation.get_table_translation(i_lang, 'ANALYSIS_PARAMETER', g_no)) t
             WHERE translate(upper(t.desc_translation), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   l_search
               AND EXISTS (SELECT 0
                      FROM analysis_parameter ap
                     WHERE ap.code_analysis_parameter = t.code_translation
                       AND ap.flg_available = g_yes);
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
                                              i_function => 'GET_ANALYSIS_PARAMETER_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_analysis_parameter_count;

    FUNCTION get_analysis_parameter_list
    (
        i_lang                    IN language.id_language%TYPE,
        i_search                  IN VARCHAR2,
        i_start_record            IN NUMBER DEFAULT NULL,
        i_num_records             IN NUMBER DEFAULT NULL,
        o_analysis_parameter_list OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start NUMBER(24) := 1;
        l_end   NUMBER(24) := 9999999999999999999999;
    
        l_desc_status sys_domain.desc_val%TYPE := pk_sysdomain.get_domain('ACTIVE_INACTIVE', 'A', i_lang);
    
        l_search VARCHAR2(4000) := '%' ||
                                   translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN') || '%';
    
    BEGIN
    
        IF i_start_record IS NOT NULL
           AND i_num_records IS NOT NULL
        THEN
            l_start := i_start_record;
            l_end   := i_start_record + i_num_records - 1;
        END IF;
    
        IF i_search IS NOT NULL
        THEN
            g_error := 'GET ANALYSIS_PARAMETER_LIST CURSOR';
            OPEN o_analysis_parameter_list FOR
                SELECT ord_tbl.id, ord_tbl.analysis_parameter_name, ord_tbl.flg_status, ord_tbl.desc_status
                  FROM (SELECT rownum rn,
                               parm.id,
                               parm.analysis_parameter_name,
                               'A' flg_status,
                               l_desc_status desc_status
                          FROM (SELECT regexp_replace(t.code_translation, '[A-Z_.]') id,
                                       t.desc_translation analysis_parameter_name
                                  FROM TABLE(pk_translation.get_table_translation(i_lang, 'ANALYSIS_PARAMETER', g_yes)) t
                                 WHERE translate(upper(t.desc_translation),
                                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE l_search
                                   AND EXISTS (SELECT 0
                                          FROM analysis_parameter ap
                                         WHERE ap.code_analysis_parameter = t.code_translation
                                           AND ap.flg_available = g_yes)
                                 ORDER BY position) parm) ord_tbl
                 WHERE ord_tbl.rn BETWEEN l_start AND l_end;
        
        ELSE
            g_error := 'GET ANALYSIS_PARAMETER_LIST CURSOR';
            OPEN o_analysis_parameter_list FOR
                SELECT ord_tbl.id, ord_tbl.analysis_parameter_name, ord_tbl.flg_status, ord_tbl.desc_status
                  FROM (SELECT rownum rn, tbl_trl.*
                          FROM (SELECT regexp_replace(t.code_translation, '[A-Z_.]') id,
                                       t.desc_translation analysis_parameter_name,
                                       'A' flg_status,
                                       l_desc_status desc_status
                                  FROM TABLE(pk_translation.get_table_translation(i_lang, 'ANALYSIS_PARAMETER', g_yes)) t
                                 WHERE EXISTS (SELECT 0
                                          FROM analysis_parameter ap
                                         WHERE ap.code_analysis_parameter = t.code_translation
                                           AND ap.flg_available = g_yes)
                                 ORDER BY position) tbl_trl) ord_tbl
                 WHERE ord_tbl.rn BETWEEN l_start AND l_end;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_analysis_parameter_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_PARAMETER');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_parameter_list;
    /********************************************************************************************
    * Public Function. Insert New Analysis Parameter OR Update Analysis Parameter Information
    *
    * @param      I_LANG                               Prefered language ID
    * @param      I_PROF                               Proissional(professional id,id_institution,id_Software)
    * @param      I_ID_ANALYSIS_PARAMETER              Parameter identification
    * @param      I_DESC                               Parameter description
    * @param      I_FLG_AVAILABLE                      Flag available
    * @param      O_ID_ANALYSIS_PARAMETER              Parameter identification 
    * @param      O_ERROR                              Error 
    *
    * @return     boolean
    * @author     TÈrcio Soares - JTS
    * @version    0.1
    * @since      2007/11/23
    */
    FUNCTION set_analysis_parameter
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_desc                  IN VARCHAR2,
        i_flg_available         IN analysis.flg_available%TYPE,
        o_id_analysis_parameter OUT analysis_parameter.id_analysis_parameter%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    BEGIN
        g_sysdate := SYSDATE;
    
        IF i_desc IS NULL
        THEN
            RAISE l_exception;
        ELSIF i_id_analysis_parameter IS NULL
        THEN
            g_error := 'GET SEQ_ANALYSIS_PARAMETER.NEXTVAL';
            SELECT seq_analysis_parameter.nextval
              INTO o_id_analysis_parameter
              FROM dual;
        
            g_error := 'INSERT INTO ANALYSIS_PARAMETER';
            INSERT INTO analysis_parameter
                (id_analysis_parameter, rank, flg_available)
            VALUES
                (o_id_analysis_parameter, 1, i_flg_available);
        
            pk_translation.insert_into_translation(i_lang,
                                                   'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                   o_id_analysis_parameter || '',
                                                   i_desc);
        
        ELSE
            g_error := 'UPDATE ANALYSIS_PARAMETER';
            UPDATE analysis_parameter ap
               SET ap.flg_available = i_flg_available
             WHERE ap.id_analysis_parameter = i_id_analysis_parameter;
        
            pk_translation.insert_into_translation(i_lang,
                                                   'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                   o_id_analysis_parameter || '',
                                                   i_desc);
        
            o_id_analysis_parameter := i_id_analysis_parameter;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_TRIAGE',
                                              'SET_ANALYSIS_PARAMETER',
                                              o_error);
        
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_ANALYSIS_PARAMETER');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_analysis_parameter;

    /********************************************************************************************
    * Public Function. Get Analysis Groups List
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      i_search                   Search
    * @param      O_ANALYSIS_GROUP_LIST      Cursor with a list of analysis group
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/23
    */
    FUNCTION get_analysis_group_list
    (
        i_lang                IN language.id_language%TYPE,
        i_search              IN VARCHAR2,
        o_analysis_group_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF i_search IS NULL
        THEN
            g_error := 'GET ANALYSIS_GROUP_LIST CURSOR';
            OPEN o_analysis_group_list FOR
                SELECT ag.id_analysis_group,
                       pk_translation.get_translation(i_lang, ag.code_analysis_group) analysis_group_name
                  FROM analysis_group ag
                 ORDER BY analysis_group_name;
        ELSE
            g_error := 'GET ANALYSIS_GROUP_LIST CURSOR';
            OPEN o_analysis_group_list FOR
                SELECT ag.id_analysis_group,
                       pk_translation.get_translation(i_lang, ag.code_analysis_group) analysis_group_name
                  FROM analysis_group ag
                 WHERE translate(upper(pk_translation.get_translation(i_lang, ag.code_analysis_group)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY analysis_group_name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_analysis_group_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_GROUP_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_group_list;

    /********************************************************************************************
    * Public Function. Get Analysis Group POSSIBLE LIST
    *
    * @param      I_LANG                     Prefered language ID
    * @param      O_LIST                     Possible task to the add button in the analysis screen
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/26
    */
    FUNCTION get_analysis_group_poss_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS ADD LIST CURSOR';
        OPEN o_list FOR
            SELECT val, desc_val, img_name icon
              FROM sys_domain
             WHERE code_domain = 'ANALYSIS_GROUP_ADD_TASK'
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY val DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_GROUP_POSS_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_group_poss_list;

    /********************************************************************************************
    * Public Function. Get Analysis Groups List
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      I_ID_ANALYSIS_GROUP        Analysis group identification
    * @param      i_search                   Search
    * @param      O_GROUP_ANALYSIS           Cursor with the analysis group information
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/23
    */
    FUNCTION get_group_analysis
    (
        i_lang              IN language.id_language%TYPE,
        i_id_analysis_group IN analysis_group.id_analysis_group%TYPE,
        i_search            IN VARCHAR2,
        o_group_analysis    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF i_search IS NULL
        THEN
            g_error := 'GET GROUP_ANALYSIS CURSOR';
            OPEN o_group_analysis FOR
                SELECT agp.id_analysis,
                       pk_translation.get_translation(i_lang, a.code_analysis) analysis_name,
                       a.flg_available,
                       g_hand_icon analysis_icon
                  FROM analysis_agp agp, analysis a
                 WHERE agp.id_analysis_group = i_id_analysis_group
                   AND agp.id_analysis = a.id_analysis
                   AND a.flg_available = g_flg_available
                 ORDER BY analysis_name;
        ELSE
            g_error := 'GET GROUP_ANALYSIS CURSOR';
            OPEN o_group_analysis FOR
                SELECT agp.id_analysis,
                       pk_translation.get_translation(i_lang, a.code_analysis) analysis_name,
                       a.flg_available,
                       g_hand_icon analysis_icon
                  FROM analysis_agp agp, analysis a
                 WHERE agp.id_analysis_group = i_id_analysis_group
                   AND agp.id_analysis = a.id_analysis
                   AND a.flg_available = g_flg_available
                   AND translate(upper(pk_translation.get_translation(i_lang, a.code_analysis)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY analysis_name;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_group_analysis);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_GROUP_ANALYSIS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_group_analysis;

    /********************************************************************************************
    * Public Function. Insert New Analysis Group OR Update Analysis Group Information
    *
    * @param      I_LANG                               Language identification
    * @param      I_PROF                               Profissional(Professional id,institution id, software id)
    * @param      I_ANALYSIS_GROUP                     Analysis group identification
    * @param      I_DESC_GROUP                         Analysis group description
    * @param      I_GENDER                             Gender
    * @param      I_AGE_MIN                            Minimum age
    * @param      I_AGE_MAX                            Maximum age
    * @param      i_analysis                           Analysis
    * @param      i_analysis_change                    Analysis change
    * @param      O_ANALYSIS_GROUP                     Analysis group 
    * @param      I_ANALYSIS_AGP                       Relation between analysis and analysis group
    * @param      O_ERROR                              Error 
    *
    * @value      i_analysis_change                    {*} 'Y' Insert {*} 'N' Delete                   
    *
    * @return     boolean
    * @author     TÈrcio Soares - JTS
    * @version    0.1
    * @since      2007/11/23
    *************************************************************************************************/
    FUNCTION set_group_analysis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_analysis_group IN analysis_agp.id_analysis_group%TYPE,
        i_desc_group        IN VARCHAR2,
        i_gender            IN analysis_group.gender%TYPE,
        i_age_min           IN analysis_group.age_min%TYPE,
        i_age_max           IN analysis_group.age_max%TYPE,
        i_analysis          IN table_number,
        i_analysis_change   IN table_varchar,
        o_id_analysis_group OUT analysis_group.id_analysis_group%TYPE,
        o_id_analysis_agp   OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate         := SYSDATE;
        o_id_analysis_agp := table_number();
    
        IF i_id_analysis_group IS NULL
        THEN
            g_error := 'GET SEQ_ANALYSIS_GROUP.NEXTVAL';
            SELECT seq_analysis_group.nextval
              INTO o_id_analysis_group
              FROM dual;
        
            g_error := 'INSERT INTO ANALYSIS_GROUP';
            INSERT INTO analysis_group
                (id_analysis_group, rank, adw_last_update, gender, age_min, age_max)
            VALUES
                (o_id_analysis_group, 0, g_sysdate, i_gender, i_age_min, i_age_max);
        
            pk_translation.insert_into_translation(i_lang,
                                                   'ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.' || o_id_analysis_group || '',
                                                   i_desc_group);
        
            FOR j IN 1 .. i_analysis.count
            LOOP
            
                o_id_analysis_agp.extend;
            
                g_error := 'GET SEQ_ANALYSIS_AGP.NEXTVAL';
                SELECT seq_analysis_agp.nextval
                  INTO o_id_analysis_agp(j)
                  FROM dual;
            
                g_error := 'INSERT INTO ANALYSIS_AGP';
                INSERT INTO analysis_agp
                    (id_analysis_agp, id_analysis_group, id_analysis, rank)
                VALUES
                    (o_id_analysis_agp(j), o_id_analysis_group, i_analysis(j), 0);
            
            END LOOP;
        ELSE
            g_error := 'UPDATE ANALYSIS_GROUP';
            UPDATE analysis_group
               SET gender = i_gender, age_min = i_age_min, age_max = i_age_max
             WHERE id_analysis_group = i_id_analysis_group;
        
            pk_translation.insert_into_translation(i_lang,
                                                   'ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.' || i_id_analysis_group || '',
                                                   i_desc_group);
        
            FOR j IN 1 .. i_analysis.count
            LOOP
                o_id_analysis_agp.extend;
            
                IF i_analysis_change(j) = 'Y'
                THEN
                
                    g_error := 'GET SEQ_ANALYSIS_AGP.NEXTVAL';
                    SELECT seq_analysis_agp.nextval
                      INTO o_id_analysis_agp(j)
                      FROM dual;
                
                    g_error := 'INSERT INTO ANALYSIS_AGP';
                    INSERT INTO analysis_agp
                        (id_analysis_agp, id_analysis_group, id_analysis, rank)
                    VALUES
                        (o_id_analysis_agp(j), i_id_analysis_group, i_analysis(j), 0);
                ELSE
                    g_error := 'DELETE FROM ANALYSIS_AGP';
                    DELETE FROM analysis_agp agp
                     WHERE agp.id_analysis_group = i_id_analysis_group
                       AND agp.id_analysis = i_analysis(j);
                END IF;
            
            END LOOP;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_GROUP_ANALYSIS');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_group_analysis;

    /********************************************************************************************
    * Public Function. Get Software Analysis List
    * 
    * @param      I_LANG                     Language identification
    * @param      I_ID_INSTITUTION           Institution identification
    * @param      i_id_software              Software identification
    * @param      i_search                   Search
    * @param      o_list                     Cursor 
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/26
    **********************************************************************************************/
    FUNCTION get_inst_soft_analysis_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_software    IN analysis_instit_soft.id_software%TYPE,
        i_search         IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS_GROUP_LIST CURSOR';
        IF i_search IS NULL
        THEN
            OPEN o_list FOR
                SELECT DISTINCT a.id_analysis id,
                                pk_translation.get_translation(i_lang, a.code_analysis) || ' / ' ||
                                pk_translation.get_translation(i_lang, st.code_sample_type) name,
                                ais.flg_type flg_status,
                                pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE',
                                                        decode(ais.flg_type, 'P', 'E', 'W', 'X', ais.flg_type),
                                                        i_lang) status_desc,
                                get_missing_data(i_lang,
                                                 ais.id_analysis || '|' || ais.id_sample_type,
                                                 i_id_institution,
                                                 ais.id_software,
                                                 'A') missing_data
                  FROM analysis_instit_soft ais, analysis a, analysis_sample_type ast, sample_type st
                 WHERE ais.id_institution = i_id_institution
                   AND ais.id_software = i_id_software
                   AND ais.flg_available = g_flg_available
                   AND ais.id_analysis = ast.id_analysis
                   AND ais.id_sample_type = ast.id_sample_type
                   AND ast.flg_available = g_flg_available
                   AND ast.id_analysis = a.id_analysis
                   AND ast.id_sample_type = st.id_sample_type
                 ORDER BY name;
        ELSE
            OPEN o_list FOR
                SELECT DISTINCT a.id_analysis id,
                                pk_translation.get_translation(i_lang, a.code_analysis) || ' / ' ||
                                pk_translation.get_translation(i_lang, st.code_sample_type) name,
                                ais.flg_type flg_status,
                                pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE', ais.flg_type, i_lang) status_desc,
                                get_missing_data(i_lang,
                                                 ais.id_analysis || '|' || ais.id_sample_type,
                                                 i_id_institution,
                                                 ais.id_software,
                                                 'A') missing_data
                  FROM analysis_instit_soft ais, analysis a, analysis_sample_type ast, sample_type st
                 WHERE ais.id_institution = i_id_institution
                   AND ais.id_software = i_id_software
                   AND ais.flg_available = g_flg_available
                   AND ais.id_analysis = ast.id_analysis
                   AND ais.id_sample_type = ast.id_sample_type
                   AND ast.flg_available = g_flg_available
                   AND ast.id_analysis = a.id_analysis
                   AND ast.id_sample_type = st.id_sample_type
                   AND translate(upper(pk_translation.get_translation(i_lang, a.code_analysis)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY name;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INST_SOFT_ANALYSIS_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_soft_analysis_list;

    /********************************************************************************************
    * Public Function. Get Analysis POSSIBLE LIST
    *
    * @param      I_LANG                     Language identification
    * @param      O_LIST                     Cursor 
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/26
    ********************************************************************************************/
    FUNCTION get_inst_analysis_poss_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS ADD LIST CURSOR';
        OPEN o_list FOR
        
            SELECT val data, desc_val label
              FROM sys_domain
             WHERE code_domain = 'ANALYSIS_INST_ADD_TASK'
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INST_ANALYSIS_POSS_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_analysis_poss_list;

    /********************************************************************************************
    * Public Function. Get Institution Analysis List
    * 
    * @param      I_LANG                     Language identification
    * @param      I_ID_INSTITUTION           Institution identification
    * @param      I_ID_ANALYSIS              Analysis identification
    * @param      i_id_software              Software identification
    * @param      I_PROF                     Profissional identification
    * @param      O_INST_ANALYSIS            Cursor with analysis information
    * @param      o_inst_analysis_param      Cursor with parameters information      
    * @param      o_inst_analysis_recep      Cursor with recipients analysis information      
    * @param      o_inst_analysis_workflow   Cursor with workflow analysis information   
    * @param      o_flg_rec_lab              Cursor 
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/27
    *****************************************************************************************/
    FUNCTION get_inst_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_institution         IN analysis_instit_soft.id_institution%TYPE,
        i_id_analysis            IN analysis_instit_soft.id_analysis%TYPE,
        i_id_software            IN analysis_instit_soft.id_software%TYPE,
        i_prof                   IN profissional,
        o_inst_analysis          OUT pk_types.cursor_type,
        o_inst_analysis_param    OUT pk_types.cursor_type,
        o_inst_analysis_recep    OUT pk_types.cursor_type,
        o_inst_analysis_workflow OUT pk_types.cursor_type,
        o_flg_rec_lab            OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_alias analysis_alias.id_analysis_alias%TYPE;
        l_loinc    analysis_loinc.id_analysis_loinc%TYPE;
    
    BEGIN
    
        SELECT nvl((SELECT aa.id_analysis_alias
                     FROM analysis_alias aa
                    WHERE aa.id_analysis = i_id_analysis
                      AND (aa.id_institution = i_id_institution OR aa.id_institution = 0)
                      AND (aa.id_software = i_id_software OR aa.id_software = 0)),
                   0)
          INTO l_id_alias
          FROM dual;
    
        SELECT nvl((SELECT al.id_analysis_loinc
                     FROM analysis_loinc al
                    WHERE al.id_analysis = i_id_analysis
                      AND (al.id_institution = i_id_institution OR al.id_institution = 0)
                      AND (al.id_software = i_id_software OR al.id_software = 0)),
                   0)
          INTO l_loinc
          FROM dual;
    
        o_flg_rec_lab := pk_sysconfig.get_config('RECIPIENT_DEPENDS_ON_LAB', i_prof);
    
        g_error := 'GET INST_ANALYSIS CURSOR';
        OPEN o_inst_analysis FOR
            SELECT DISTINCT a.id_analysis,
                            pk_translation.get_translation(i_lang, a.code_analysis) analysis_name,
                            a.id_sample_type,
                            pk_translation.get_translation(i_lang,
                                                           (SELECT st.code_sample_type
                                                              FROM sample_type st
                                                             WHERE st.id_sample_type = a.id_sample_type)) sample_type,
                            a.gender,
                            pk_sysdomain.get_domain(g_patient_gender, nvl(a.gender, NULL), i_lang) genero,
                            a.age_min,
                            a.age_max,
                            ais.id_software,
                            s.name ||
                            ('(' || pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE', ais.flg_type, i_lang) || ')') software_name,
                            l_id_alias id_analysis_alias,
                            decode(l_id_alias,
                                   0,
                                   NULL,
                                   (pk_translation.get_translation(i_lang,
                                                                   (SELECT aa.code_analysis_alias
                                                                      FROM analysis_alias aa
                                                                     WHERE aa.id_analysis_alias = l_id_alias)))) analysis_alias_name,
                            
                            l_loinc id_analysis_loinc,
                            decode(l_id_alias,
                                   0,
                                   NULL,
                                   (SELECT al.loinc_code
                                      FROM analysis_loinc al
                                     WHERE al.id_analysis_loinc = l_loinc)) analysis_loinc,
                            ais.id_exam_cat id_spec,
                            pk_translation.get_translation(i_lang, ec.code_exam_cat) spec_name,
                            pk_date_utils.date_hour_chr_extend_tsz(i_lang, a.adw_last_update, i_prof) upd_date
              FROM analysis             a,
                   analysis_sample_type ast,
                   sample_type          st,
                   analysis_instit_soft ais,
                   exam_cat             ec,
                   software             s
             WHERE ais.id_institution = i_id_institution
               AND ais.id_analysis = i_id_analysis
               AND ais.id_analysis = ast.id_analysis
               AND ais.id_sample_type = ast.id_sample_type
               AND ast.id_analysis = a.id_analysis
               AND ast.id_sample_type = st.id_sample_type
               AND ais.id_exam_cat = ec.id_exam_cat
               AND ais.id_software = i_id_software
               AND s.id_software = ais.id_software;
    
        g_error := 'GET INST_ANALYSIS_PARAM CURSOR';
        OPEN o_inst_analysis_param FOR
            SELECT ap.id_analysis_param,
                   apm.id_analysis_parameter,
                   pk_translation.get_translation(i_lang, apm.code_analysis_parameter) analysis_param_name
              FROM analysis_param ap, analysis_parameter apm
             WHERE ap.id_analysis = i_id_analysis
               AND ap.id_institution = i_id_institution
               AND ap.id_analysis_parameter = apm.id_analysis_parameter
               AND ap.id_software = i_id_software;
    
        g_error := 'GET INST_ANALYSIS_RECIPIENT CURSOR';
        OPEN o_inst_analysis_recep FOR
            SELECT air.id_analysis_instit_recipient,
                   sr.id_sample_recipient,
                   pk_translation.get_translation(i_lang, sr.code_sample_recipient) recipient_name
              FROM analysis_instit_soft ais, analysis_instit_recipient air, sample_recipient sr
             WHERE ais.id_analysis = i_id_analysis
               AND ais.id_institution = i_id_institution
               AND ais.id_software = i_id_software
               AND ais.id_analysis_instit_soft = air.id_analysis_instit_soft
               AND air.id_sample_recipient = sr.id_sample_recipient;
    
        g_error := 'GET INST_ANALYSIS_WORKFLOW CURSOR';
        OPEN o_inst_analysis_workflow FOR
            SELECT ais.flg_harvest,
                   pk_sysdomain.get_domain('YES_NO', ais.flg_harvest, i_lang) harvest_desc,
                   ais.flg_mov_pat,
                   pk_sysdomain.get_domain('YES_NO', ais.flg_mov_pat, i_lang) mov_pat_desc,
                   ais.flg_mov_recipient,
                   pk_sysdomain.get_domain('YES_NO', ais.flg_mov_pat, i_lang) mov_recipient_desc,
                   decode(ais.flg_type, 'W', 'Y', 'N') flg_exec,
                   pk_sysdomain.get_domain('YES_NO', (decode(ais.flg_type, 'W', 'Y', 'N')), i_lang) flg_exec_desc,
                   ais.flg_first_result,
                   pk_sysdomain.get_domain('ANALYSIS_INSTIT_SOFT.FLG_FIRST_RESULT', ais.flg_first_result, i_lang) first_resultt_desc
              FROM analysis_instit_soft ais
             WHERE ais.id_institution = i_id_institution
               AND ais.id_software = i_id_software
               AND ais.id_analysis = i_id_analysis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_inst_analysis);
                pk_types.open_my_cursor(o_inst_analysis_param);
                pk_types.open_my_cursor(o_inst_analysis_recep);
                pk_types.open_my_cursor(o_inst_analysis_workflow);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INST_ANALYSIS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_analysis;

    /********************************************************************************************
    * Get Institution Analysis Information
    *
    * @param i_lang                       Prefered language ID
    * @param i_id_institution             Institution ID
    * @param i_id_analysis                Analysis ID
    * @param i_id_software                Software ID
    * @param i_prof                       Object
    * @param o_inst_analysis              Cursor with analysis information                      
    * @param o_inst_analysis_sin          Synonim
    * @param o_inst_analysis_loinc        Loinc Codes
    * @param o_inst_analysis_cat          Categories
    * @param o_inst_analysis_param        Parameterd
    * @param o_inst_analysis_lab          Rooms
    * @param o_inst_analysis_lab_recep    Recipients
    * @param o_inst_analysis_wf_harvest   Harvest
    * @param o_inst_analysis_wf_mv_pat    Move patient
    * @param o_inst_analysis_wf_mv_rec    Move recipient
    * @param o_inst_analysis_wf_exec      Execution
    * @param o_inst_analysis_wf_result    First result
    * @param o_inst_analysis_lab_app_req  Lab approval required
    * @param o_inst_analysis_lab_ap_by    Lab approval by
    * @param o_inst_analysis_lab_exe_by   Lab executed by
    * @param o_inst_analysis_pat_ap_req   Patient approval required
    * @param o_inst_analysis_timing       Timing of questionnaire
    * @param o_inst_analysis_prim_res_vis Primary results visible to requester
    * @param o_inst_analysis_lab_quest    Questionnaire
    * @param o_flg_rec_lab                Recipient dependes on lab
    * @param o_error                      Error
    *
    *
    * @return                           true or false on success or error
    *
    * @author                           JTS
    * @version                          0.1
    * @since                            2008/05/18
    ********************************************************************************************/
    FUNCTION get_inst_analysis_all
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_analysis                IN analysis_instit_soft.id_analysis%TYPE,
        i_id_sample_type             IN analysis_instit_soft.id_sample_type%TYPE,
        i_id_institution             IN analysis_instit_soft.id_institution%TYPE,
        i_id_software                IN analysis_instit_soft.id_software%TYPE,
        o_inst_analysis              OUT pk_types.cursor_type,
        o_inst_analysis_sin          OUT pk_types.cursor_type,
        o_inst_analysis_loinc        OUT pk_types.cursor_type,
        o_inst_analysis_cat          OUT pk_types.cursor_type,
        o_inst_analysis_param        OUT pk_types.cursor_type,
        o_inst_analysis_lab          OUT pk_types.cursor_type,
        o_inst_analysis_lab_recep    OUT pk_types.cursor_type,
        o_inst_analysis_wf_harvest   OUT pk_types.cursor_type,
        o_inst_analysis_wf_mv_pat    OUT pk_types.cursor_type,
        o_inst_analysis_wf_mv_rec    OUT pk_types.cursor_type,
        o_inst_analysis_wf_exec      OUT pk_types.cursor_type,
        o_inst_analysis_wf_result    OUT pk_types.cursor_type,
        o_inst_analysis_room_mv_pat  OUT pk_types.cursor_type,
        o_inst_analysis_dupl_warn    OUT pk_types.cursor_type,
        o_inst_analysis_lab_quest_o  OUT pk_types.cursor_type,
        o_inst_analysis_lab_quest_c  OUT pk_types.cursor_type,
        o_flg_rec_lab                OUT VARCHAR2,
        o_inst_analysis_coll         OUT pk_types.cursor_type,
        o_inst_analysis_coll_int     OUT pk_types.cursor_type,
        o_inst_analysis_coll_def_int OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_inst_alias NUMBER;
        l_id_alias   analysis_sample_type_alias.id_analysis_sample_type_alias%TYPE;
        --l_room_m         room.id_room%TYPE;
        l_room_t         room.id_room%TYPE;
        l_n_room_harvest NUMBER;
    
    BEGIN
    
        g_error := 'ANALYSIS_SAMPLE_TYPE_ALIAS';
        SELECT COUNT(asta.id_analysis_sample_type_alias)
          INTO l_inst_alias
          FROM analysis_sample_type_alias asta
         WHERE asta.id_analysis = i_id_analysis
           AND asta.id_sample_type = i_id_sample_type
           AND asta.id_institution = i_id_institution
           AND asta.id_software = 0;
    
        IF l_inst_alias = 0
        THEN
            SELECT nvl((SELECT asta.id_analysis_sample_type_alias
                         FROM analysis_sample_type_alias asta
                        WHERE asta.id_analysis = i_id_analysis
                          AND asta.id_sample_type = i_id_sample_type
                          AND asta.id_institution = 0
                          AND asta.id_software = 0),
                       0)
              INTO l_id_alias
              FROM dual;
        ELSE
            SELECT nvl((SELECT asta.id_analysis_sample_type_alias
                         FROM analysis_sample_type_alias asta
                        WHERE asta.id_analysis = i_id_analysis
                          AND asta.id_sample_type = i_id_sample_type
                          AND asta.id_institution = i_id_institution
                          AND asta.id_software = 0),
                       0)
              INTO l_id_alias
              FROM dual;
        END IF;
    
        g_error := 'ANALYSIS_ROOM';
        SELECT nvl((SELECT ar.id_room
                     FROM analysis_room ar
                    WHERE ar.id_analysis = i_id_analysis
                      AND ar.id_sample_type = i_id_sample_type
                      AND ar.id_institution = i_id_institution
                      AND ar.flg_type = 'T'
                      AND ar.flg_default = 'Y'
                      AND ar.flg_available = 'Y'),
                   NULL)
          INTO l_room_t
          FROM dual;
    
        o_flg_rec_lab := pk_sysconfig.get_config('RECIPIENT_DEPENDS_ON_LAB', i_prof);
    
        g_error := 'GET INST_ANALYSIS CURSOR';
        OPEN o_inst_analysis FOR
            SELECT DISTINCT ast.id_analysis,
                            pk_translation.get_translation(i_lang, 'ANALYSIS.CODE_ANALYSIS.' || ast.id_analysis) analysis_name,
                            ast.id_sample_type,
                            pk_translation.get_translation(i_lang,
                                                           'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ast.id_sample_type) sample_type,
                            ast.gender,
                            pk_sysdomain.get_domain(g_patient_gender, nvl(ast.gender, NULL), i_lang) genero,
                            ast.age_min,
                            ast.age_max,
                            NULL upd_date
              FROM analysis_sample_type ast
             WHERE ast.id_analysis = i_id_analysis
               AND ast.id_sample_type = i_id_sample_type;
    
        g_error := 'GET INST_ANALYSIS CURSOR';
        OPEN o_inst_analysis_sin FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   l_id_alias id_analysis_alias,
                   decode(l_id_alias,
                          0,
                          NULL,
                          (pk_translation.get_translation(i_lang,
                                                          (SELECT aa.code_analysis_alias
                                                             FROM analysis_alias aa
                                                            WHERE aa.id_analysis_alias = l_id_alias)))) analysis_alias_name,
                   (decode((SELECT COUNT(DISTINCT ais.id_software)
                             FROM analysis_instit_soft ais
                            WHERE ais.id_analysis = i_id_analysis
                              AND ais.id_sample_type = i_id_sample_type
                              AND ais.id_institution = i_id_institution
                              AND ais.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26)),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual;
    
        g_error := 'GET INST_ANALYSIS_LOINC CURSOR';
        OPEN o_inst_analysis_loinc FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL loinc_code,
                   (decode((SELECT COUNT(DISTINCT ais.id_software)
                             FROM analysis_instit_soft ais
                            WHERE ais.id_analysis = i_id_analysis
                              AND ais.id_sample_type = i_id_sample_type
                              AND ais.id_institution = i_id_institution
                              AND ais.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26)),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   al.loinc_code,
                   decode((SELECT COUNT(DISTINCT ais.id_software)
                            FROM analysis_instit_soft ais
                           WHERE ais.id_analysis = i_id_analysis
                             AND ais.id_sample_type = i_id_sample_type
                             AND ais.id_institution = i_id_institution
                             AND ais.id_software = s.id_software),
                          0,
                          'N',
                          'Y') soft_active
              FROM analysis_loinc al, software s
             WHERE al.id_analysis = i_id_analysis
               AND al.id_sample_type = i_id_sample_type
               AND al.id_institution = i_id_institution
               AND al.id_software = s.id_software
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
            UNION
            SELECT s.id_software, s.name software_name, NULL loinc_code, 'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_loinc al, software s3
                                          WHERE al.id_analysis = i_id_analysis
                                            AND al.id_sample_type = i_id_sample_type
                                            AND al.id_institution = i_id_institution
                                            AND al.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software IN (SELECT DISTINCT ais.id_software
                                       FROM analysis_instit_soft ais
                                      WHERE ais.id_institution = i_id_institution
                                        AND ais.id_analysis = i_id_analysis
                                        AND ais.id_sample_type = i_id_sample_type)
            UNION
            SELECT s.id_software, s.name software_name, NULL loinc_code, 'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_loinc al, software s3
                                          WHERE al.id_analysis = i_id_analysis
                                            AND al.id_sample_type = i_id_sample_type
                                            AND al.id_institution = i_id_institution
                                            AND al.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT ais.id_software
                                           FROM analysis_instit_soft ais
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type);
    
        g_error := 'GET INST_ANALYSIS_CAT CURSOR';
        OPEN o_inst_analysis_cat FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL id_exam_cat,
                   NULL exam_cat_name,
                   (decode((SELECT COUNT(DISTINCT ais.id_software)
                             FROM analysis_instit_soft ais
                            WHERE ais.id_analysis = i_id_analysis
                              AND ais.id_sample_type = i_id_sample_type
                              AND ais.id_institution = i_id_institution
                              AND ais.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26)),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   ec.id_exam_cat,
                   pk_translation.get_translation(i_lang, ec.code_exam_cat) exam_cat_name,
                   'Y' soft_active
              FROM analysis_instit_soft ais, software s, exam_cat ec
             WHERE ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_institution = i_id_institution
               AND ais.id_software = s.id_software
               AND ais.id_exam_cat = ec.id_exam_cat
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
            UNION
            SELECT s.id_software, s.name software_name, NULL id_exam_cat, NULL exam_cat_name, 'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3, exam_cat ec
                                          WHERE ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_institution = i_id_institution
                                            AND ais.id_software = s3.id_software
                                            AND ais.id_exam_cat = ec.id_exam_cat
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software IN (SELECT DISTINCT ais.id_software
                                       FROM analysis_instit_soft ais
                                      WHERE ais.id_institution = i_id_institution
                                        AND ais.id_analysis = i_id_analysis
                                        AND ais.id_sample_type = i_id_sample_type)
            UNION
            SELECT s.id_software, s.name software_name, NULL id_exam_cat, NULL exam_cat_name, 'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3, exam_cat ec
                                          WHERE ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_institution = i_id_institution
                                            AND ais.id_software = s3.id_software
                                            AND ais.id_exam_cat = ec.id_exam_cat
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT ais.id_software
                                           FROM analysis_instit_soft ais
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type);
    
        g_error := 'GET INST_ANALYSIS_PARAM CURSOR';
        OPEN o_inst_analysis_param FOR
            SELECT id_software,
                   software_name,
                   decode(id_software,
                          0,
                          NULL,
                          (CAST(COLLECT(decode(to_char(id_analysis_parameter),
                                               '',
                                               NULL,
                                               to_char(id_analysis_parameter) || '; ') ||
                                        decode(analysis_parameter_name, '', NULL, analysis_parameter_name)) AS
                                table_varchar))) id,
                   soft_active
              FROM (SELECT 0 id_software,
                           pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                           NULL id_analysis_parameter,
                           NULL analysis_parameter_name,
                           NULL analysis_parameters,
                           (decode((SELECT COUNT(DISTINCT ais.id_software)
                                     FROM analysis_instit_soft ais
                                    WHERE ais.id_analysis = i_id_analysis
                                      AND ais.id_sample_type = i_id_sample_type
                                      AND ais.id_institution = i_id_institution
                                      AND ais.id_software IN (SELECT s2.id_software
                                                                FROM software_institution si, software s2
                                                               WHERE s2.flg_mni = g_flg_available
                                                                 AND si.id_software = s2.id_software
                                                                 AND si.id_institution = i_id_institution
                                                                 AND s2.id_software != 26)),
                                   0,
                                   'N',
                                   'Y')) soft_active
                      FROM dual
                    UNION
                    SELECT s.id_software,
                           s.name software_name,
                           apm.id_analysis_parameter,
                           pk_translation.get_translation(i_lang, apm.code_analysis_parameter) analysis_parameter_name,
                           pk_utils.query_to_string('SELECT distinct pk_translation.get_translation(' || i_lang || ',
                                                                       apm.code_analysis_parameter) 
                                   FROM software           s,
                                        analysis_param     ap,
                                        analysis_parameter apm
                                  WHERE ap.id_analysis = ' ||
                                                    i_id_analysis || '
                                    AND ap.id_sample_type = ' ||
                                                    i_id_sample_type || '
                                    AND ap.id_institution = ' ||
                                                    i_id_institution || '
                                    AND ap.id_software = ' ||
                                                    s.id_software || '
                                    AND ap.id_analysis_parameter = apm.id_analysis_parameter',
                                                    ', ') analysis_parameters,
                           
                           (decode((SELECT COUNT(DISTINCT ais.id_software)
                                     FROM analysis_instit_soft ais
                                    WHERE ais.id_analysis = i_id_analysis
                                      AND ais.id_sample_type = i_id_sample_type
                                      AND ais.id_institution = i_id_institution
                                      AND ais.id_software = s.id_software),
                                   0,
                                   'N',
                                   'Y')) soft_active
                      FROM software s, analysis_param ap, analysis_parameter apm
                     WHERE ap.id_analysis = i_id_analysis
                       AND ap.id_sample_type = i_id_sample_type
                       AND ap.id_institution = i_id_institution
                       AND ap.id_software = s.id_software
                       AND ap.id_analysis_parameter = apm.id_analysis_parameter
                       AND s.id_software IN (SELECT s2.id_software
                                               FROM software_institution si, software s2
                                              WHERE s2.flg_mni = g_flg_available
                                                AND si.id_software = s2.id_software
                                                AND si.id_institution = i_id_institution
                                                AND s2.id_software != 26)
                    
                    UNION
                    SELECT s.id_software,
                           s.name software_name,
                           NULL id_analysis_parameter,
                           NULL analysis_parameter_name,
                           NULL analysis_parameters,
                           'Y' soft_active
                      FROM software s
                     WHERE s.id_software NOT IN
                           (SELECT s3.id_software
                              FROM software s3, analysis_param ap, analysis_parameter apm
                             WHERE ap.id_analysis = i_id_analysis
                               AND ap.id_sample_type = i_id_sample_type
                               AND ap.id_institution = i_id_institution
                               AND ap.id_software = s3.id_software
                               AND ap.id_analysis_parameter = apm.id_analysis_parameter
                               AND s3.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26))
                       AND s.id_software IN (SELECT s2.id_software
                                               FROM software_institution si, software s2
                                              WHERE s2.flg_mni = g_flg_available
                                                AND si.id_software = s2.id_software
                                                AND si.id_institution = i_id_institution
                                                AND s2.id_software != 26)
                       AND s.id_software IN (SELECT DISTINCT ais.id_software
                                               FROM analysis_instit_soft ais
                                              WHERE ais.id_institution = i_id_institution
                                                AND ais.id_analysis = i_id_analysis
                                                AND ais.id_sample_type = i_id_sample_type)
                    UNION
                    SELECT s.id_software,
                           s.name software_name,
                           NULL id_analysis_parameter,
                           NULL analysis_parameter_name,
                           NULL analysis_parameters,
                           'N' soft_active
                      FROM software s
                     WHERE s.id_software NOT IN
                           (SELECT s3.id_software
                              FROM software s3, analysis_param ap, analysis_parameter apm
                             WHERE ap.id_analysis = i_id_analysis
                               AND ap.id_sample_type = i_id_sample_type
                               AND ap.id_institution = i_id_institution
                               AND ap.id_software = s3.id_software
                               AND ap.id_analysis_parameter = apm.id_analysis_parameter
                               AND s3.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26))
                       AND s.id_software IN (SELECT s2.id_software
                                               FROM software_institution si, software s2
                                              WHERE s2.flg_mni = g_flg_available
                                                AND si.id_software = s2.id_software
                                                AND si.id_institution = i_id_institution
                                                AND s2.id_software != 26)
                       AND s.id_software NOT IN (SELECT DISTINCT ais.id_software
                                                   FROM analysis_instit_soft ais
                                                  WHERE ais.id_institution = i_id_institution
                                                    AND ais.id_analysis = i_id_analysis
                                                    AND ais.id_sample_type = i_id_sample_type)
                     ORDER BY id_software, software_name)
             GROUP BY id_software, software_name, analysis_parameters, soft_active;
    
        IF o_flg_rec_lab = 'N'
        THEN
            g_error := 'GET INST_ANALYSIS_RECIPIENT CURSOR';
            OPEN o_inst_analysis_lab_recep FOR
                SELECT DISTINCT sr.id_sample_recipient id,
                                pk_translation.get_translation(i_lang, sr.code_sample_recipient) name,
                                air.flg_default,
                                decode(air.flg_default, 'Y', pk_message.get_message(i_lang, 'ADMINISTRATOR_T048'), NULL) default_desc
                  FROM analysis_instit_soft ais, software s, analysis_instit_recipient air, sample_recipient sr
                 WHERE ais.id_analysis = i_id_analysis
                   AND ais.id_sample_type = i_id_sample_type
                   AND ais.id_institution = i_id_institution
                   AND ais.id_software = s.id_software
                   AND air.id_analysis_instit_soft = ais.id_analysis_instit_soft
                   AND air.id_sample_recipient = sr.id_sample_recipient
                   AND s.id_software IN (SELECT s2.id_software
                                           FROM software_institution si, software s2
                                          WHERE s2.flg_mni = g_flg_available
                                            AND si.id_software = s2.id_software
                                            AND si.id_institution = i_id_institution
                                            AND s2.id_software != 26);
        ELSE
            g_error := 'GET INST_ANALYSIS_RECIPIENT CURSOR';
            OPEN o_inst_analysis_lab_recep FOR
                SELECT DISTINCT sr.id_sample_recipient id,
                                pk_translation.get_translation(i_lang, sr.code_sample_recipient) name,
                                air.flg_default,
                                r.id_room id_lab
                  FROM analysis_instit_soft ais, software s, analysis_instit_recipient air, sample_recipient sr, room r
                 WHERE ais.id_analysis = i_id_analysis
                   AND ais.id_sample_type = i_id_sample_type
                   AND ais.id_institution = i_id_institution
                   AND ais.id_software = s.id_software
                   AND air.id_analysis_instit_soft = ais.id_analysis_instit_soft
                   AND air.id_sample_recipient = sr.id_sample_recipient
                   AND air.id_room = r.id_room
                   AND s.id_software IN (SELECT s2.id_software
                                           FROM software_institution si, software s2
                                          WHERE s2.flg_mni = g_flg_available
                                            AND si.id_software = s2.id_software
                                            AND si.id_institution = i_id_institution
                                            AND s2.id_software != 26);
        END IF;
    
        g_error := 'GET INST_ANALYSIS_LAB CURSOR';
        OPEN o_inst_analysis_lab FOR
            SELECT DISTINCT r.id_room id_lab,
                            ar.flg_default,
                            nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) lab_name,
                            (SELECT COUNT(*)
                               FROM room_questionnaire rq
                              WHERE rq.id_room = r.id_room) quests_no
              FROM analysis_instit_soft ais, analysis_room ar, room r
             WHERE ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_institution = i_id_institution
               AND ar.id_analysis = ais.id_analysis
               AND ar.id_institution = ais.id_institution
               AND ar.flg_type = 'T'
               AND ar.flg_available = 'Y'
               AND ar.id_room = r.id_room
               AND ais.id_software IN (SELECT s2.id_software
                                         FROM software_institution si, software s2
                                        WHERE s2.flg_mni = g_flg_available
                                          AND si.id_software = s2.id_software
                                          AND si.id_institution = i_id_institution
                                          AND s2.id_software != 26);
    
        g_error := 'GET INST_ANALYSIS_WORKFLOW_HARVEST CURSOR';
        OPEN o_inst_analysis_wf_harvest FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL flg_harvest,
                   NULL harvest_desc,
                   (decode((SELECT COUNT(DISTINCT ais.id_software)
                             FROM analysis_instit_soft ais
                            WHERE ais.id_analysis = i_id_analysis
                              AND ais.id_sample_type = i_id_sample_type
                              AND ais.id_institution = i_id_institution
                              AND ais.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26)),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   ais.flg_harvest,
                   pk_sysdomain.get_domain('BACKOFFICE_ANALYSIS_HARVEST', ais.flg_harvest, i_lang) harvest_desc,
                   'Y' soft_active
              FROM analysis_instit_soft ais, software s
             WHERE ais.id_institution = i_id_institution
               AND ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_software = s.id_software
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_harvest, NULL harvest_desc, 'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
                  
               AND s.id_software IN (SELECT DISTINCT ais.id_software
                                       FROM analysis_instit_soft ais
                                      WHERE ais.id_institution = i_id_institution
                                        AND ais.id_analysis = i_id_analysis
                                        AND ais.id_sample_type = i_id_sample_type)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_harvest, NULL harvest_desc, 'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT ais.id_software
                                           FROM analysis_instit_soft ais
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type);
    
        g_error := 'GET INST_ANALYSIS_WORKFLOW_MOVE_PATIENT CURSOR';
    
        OPEN o_inst_analysis_wf_mv_pat FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL flg_mov_pat,
                   NULL mov_pat_desc,
                   (decode((SELECT COUNT(DISTINCT ais.id_software)
                             FROM analysis_instit_soft ais
                            WHERE ais.id_analysis = i_id_analysis
                              AND ais.id_sample_type = i_id_sample_type
                              AND ais.id_institution = i_id_institution
                              AND ais.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26)),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   ais.flg_mov_pat,
                   pk_sysdomain.get_domain('YES_NO', ais.flg_mov_pat, i_lang) mov_pat_desc,
                   'Y' soft_active
              FROM analysis_instit_soft ais, software s
             WHERE ais.id_institution = i_id_institution
               AND ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_software = s.id_software
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_mov_pat, NULL mov_pat_desc, 'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software IN (SELECT DISTINCT ais.id_software
                                       FROM analysis_instit_soft ais
                                      WHERE ais.id_institution = i_id_institution
                                        AND ais.id_analysis = i_id_analysis
                                        AND ais.id_sample_type = i_id_sample_type)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_mov_pat, NULL mov_pat_desc, 'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT ais.id_software
                                           FROM analysis_instit_soft ais
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type);
        g_error := 'l_n_room_harvest';
        SELECT nvl((SELECT COUNT(ar.id_analysis_room)
                     FROM analysis_room ar
                    WHERE ar.id_analysis = i_id_analysis
                      AND ar.id_sample_type = i_id_sample_type
                      AND ar.id_institution = i_id_institution
                      AND ar.flg_type = 'M'
                      AND ar.flg_available = 'Y'),
                   0)
          INTO l_n_room_harvest
          FROM dual;
    
        IF l_n_room_harvest <= 1
        THEN
            g_error := 'GET INST_ANALYSIS_WORKFLOW_ROOM_MOVE_PATIENT CURSOR';
        
            OPEN o_inst_analysis_room_mv_pat FOR
                SELECT decode(ar.id_room, NULL, NULL, ar.id_room) id_room,
                       decode(ar.id_room,
                              NULL,
                              NULL,
                              (SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
                                 FROM room r
                                WHERE r.id_room = ar.id_room)) room_desc
                  FROM analysis_room ar
                 WHERE ar.id_analysis = i_id_analysis
                   AND ar.id_sample_type = i_id_sample_type
                   AND ar.id_institution = i_id_institution
                   AND ar.flg_type = 'M'
                   AND ar.flg_available = 'Y';
        
        END IF;
    
        IF l_n_room_harvest > 1
        THEN
            g_error := 'GET INST_ANALYSIS_WORKFLOW_ROOM_MOVE_PATIENT CURSOR';
        
            OPEN o_inst_analysis_room_mv_pat FOR
                SELECT ar.id_room id_room,
                       decode(ar.id_room,
                              NULL,
                              NULL,
                              (SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
                                 FROM room r
                                WHERE r.id_room = ar.id_room)) room_desc
                  FROM analysis_room ar
                 WHERE ar.id_analysis = i_id_analysis
                   AND ar.id_sample_type = i_id_sample_type
                   AND ar.id_institution = i_id_institution
                   AND ar.flg_type = 'M'
                   AND ar.flg_available = 'Y'
                   AND ar.adw_last_update = nvl((SELECT MAX(ar.adw_last_update)
                                                  FROM analysis_room ar
                                                 WHERE ar.id_analysis = i_id_analysis
                                                   AND ar.id_sample_type = i_id_sample_type
                                                   AND ar.id_institution = i_id_institution
                                                   AND ar.flg_type = 'M'),
                                                NULL)
                   AND rownum < 2;
        END IF;
    
        g_error := 'GET INST_ANALYSIS_WORKFLOW_MOVE_RECIPIENT CURSOR';
        OPEN o_inst_analysis_wf_mv_rec FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL flg_mov_recipient,
                   NULL mov_recipient_desc,
                   NULL id_room,
                   NULL room_desc,
                   (decode((SELECT COUNT(DISTINCT ais.id_software)
                             FROM analysis_instit_soft ais
                            WHERE ais.id_analysis = i_id_analysis
                              AND ais.id_sample_type = i_id_sample_type
                              AND ais.id_institution = i_id_institution
                              AND ais.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26)),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   ais.flg_mov_recipient,
                   pk_sysdomain.get_domain('YES_NO', ais.flg_mov_recipient, i_lang) mov_recipient_desc,
                   decode(ais.flg_mov_recipient, 'N', NULL, NULL, NULL, l_room_t) id_room,
                   decode(ais.flg_mov_recipient,
                          'N',
                          NULL,
                          NULL,
                          NULL,
                          (decode(l_room_t,
                                  NULL,
                                  NULL,
                                  (SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
                                     FROM room r
                                    WHERE r.id_room = l_room_t)))) room_desc,
                   'Y' soft_active
              FROM analysis_instit_soft ais, software s
             WHERE ais.id_institution = i_id_institution
               AND ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_software = s.id_software
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   NULL flg_mov_recipient,
                   NULL mov_recipient_desc,
                   NULL id_room,
                   NULL room_desc,
                   'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software IN (SELECT DISTINCT ais.id_software
                                       FROM analysis_instit_soft ais
                                      WHERE ais.id_institution = i_id_institution
                                        AND ais.id_analysis = i_id_analysis
                                        AND ais.id_sample_type = i_id_sample_type)
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   NULL flg_mov_recipient,
                   NULL mov_recipient_desc,
                   NULL id_room,
                   NULL room_desc,
                   'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT ais.id_software
                                           FROM analysis_instit_soft ais
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type);
    
        g_error := 'GET INST_ANALYSIS_WORKFLOW_EXEC CURSOR';
        OPEN o_inst_analysis_wf_exec FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL flg_exec,
                   NULL flg_exec_desc,
                   (decode((SELECT COUNT(DISTINCT ais.id_software)
                             FROM analysis_instit_soft ais
                            WHERE ais.id_analysis = i_id_analysis
                              AND ais.id_sample_type = i_id_sample_type
                              AND ais.id_institution = i_id_institution
                              AND ais.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26)),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   decode(ais.flg_type, 'W', 'Y', 'N') flg_exec,
                   pk_sysdomain.get_domain('YES_NO', (decode(ais.flg_type, 'W', 'Y', 'N')), i_lang) flg_exec_desc,
                   'Y' soft_active
              FROM analysis_instit_soft ais, software s
             WHERE ais.id_institution = i_id_institution
               AND ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_software = s.id_software
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_exec, NULL flg_exec_desc, 'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software IN (SELECT DISTINCT ais.id_software
                                       FROM analysis_instit_soft ais
                                      WHERE ais.id_institution = i_id_institution
                                        AND ais.id_analysis = i_id_analysis
                                        AND ais.id_sample_type = i_id_sample_type)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_exec, NULL flg_exec_desc, 'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT ais.id_software
                                           FROM analysis_instit_soft ais
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type);
    
        g_error := 'GET INST_ANALYSIS_WORKFLOW_FIRST_RESULT CURSOR';
        OPEN o_inst_analysis_wf_result FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL flg_first_result,
                   NULL first_result_desc,
                   (decode((SELECT COUNT(DISTINCT ais.id_software)
                             FROM analysis_instit_soft ais
                            WHERE ais.id_analysis = i_id_analysis
                              AND ais.id_institution = i_id_institution
                              AND ais.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26)),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION ALL
            SELECT s.id_software,
                   s.name software_name,
                   ais.flg_first_result,
                   pk_sysdomain.get_domain('ANALYSIS_INSTIT_SOFT.FLG_FIRST_RESULT', ais.flg_first_result, i_lang) first_result_desc,
                   'Y' soft_active
              FROM analysis_instit_soft ais, software s
             WHERE ais.id_institution = i_id_institution
               AND ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_software = s.id_software
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
            UNION ALL
            SELECT s.id_software, s.name software_name, NULL flg_first_result, NULL first_result_desc, 'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software IN (SELECT DISTINCT ais.id_software
                                       FROM analysis_instit_soft ais
                                      WHERE ais.id_institution = i_id_institution
                                        AND ais.id_analysis = i_id_analysis
                                        AND ais.id_sample_type = i_id_sample_type)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_first_result, NULL first_result_desc, 'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT ais.id_software
                                           FROM analysis_instit_soft ais
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type);
    
        g_error := 'GET INST_ANALYSIS_DOUBLE_ORDERED_NOTIFICATION CURSOR';
        OPEN o_inst_analysis_dupl_warn FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL flg_duplicate_warn,
                   NULL duplicate_warn_desc,
                   (decode((SELECT COUNT(DISTINCT ais.id_software)
                             FROM analysis_instit_soft ais
                            WHERE ais.id_analysis = i_id_analysis
                              AND ais.id_sample_type = i_id_sample_type
                              AND ais.id_institution = i_id_institution
                              AND ais.id_software IN (SELECT s2.id_software
                                                        FROM software_institution si, software s2
                                                       WHERE s2.flg_mni = g_flg_available
                                                         AND si.id_software = s2.id_software
                                                         AND si.id_institution = i_id_institution
                                                         AND s2.id_software != 26)),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   ais.flg_duplicate_warn,
                   pk_sysdomain.get_domain('ANALYSIS_INSTIT_SOFT.FLG_DUPLICATE_WARN', ais.flg_duplicate_warn, i_lang) duplicate_warn_desc,
                   'Y' soft_active
              FROM analysis_instit_soft ais, software s
             WHERE ais.id_institution = i_id_institution
               AND ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_software = s.id_software
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   NULL flg_duplicate_warn,
                   NULL duplicate_warn_desc,
                   'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
                  
               AND s.id_software IN (SELECT DISTINCT ais.id_software
                                       FROM analysis_instit_soft ais
                                      WHERE ais.id_institution = i_id_institution
                                        AND ais.id_analysis = i_id_analysis
                                        AND ais.id_sample_type = i_id_sample_type)
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   NULL flg_duplicate_warn,
                   NULL duplicate_warn_desc,
                   'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM analysis_instit_soft ais, software s3
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type
                                            AND ais.id_software = s3.id_software
                                            AND s3.id_software IN (SELECT s2.id_software
                                                                     FROM software_institution si, software s2
                                                                    WHERE s2.flg_mni = g_flg_available
                                                                      AND si.id_software = s2.id_software
                                                                      AND si.id_institution = i_id_institution
                                                                      AND s2.id_software != 26))
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT ais.id_software
                                           FROM analysis_instit_soft ais
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_sample_type = i_id_sample_type);
        -- MFF ALERT-27380
    
        -- Questionnaire
        g_error := 'GET INST_ANALYSIS_QUESTIONARY CURSOR O';
        pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.GET_INST_ANALYSIS_ALL ' || g_error);
        IF NOT pk_backoffice_mcdt.get_analysis_questionnaire(i_lang,
                                                             i_id_analysis,
                                                             i_id_sample_type,
                                                             i_id_institution,
                                                             'O',
                                                             o_inst_analysis_lab_quest_o,
                                                             o_error)
        THEN
            RETURN FALSE;
        END IF;
        g_error := 'GET INST_ANALYSIS_QUESTIONARY CURSOR C';
        pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.GET_INST_ANALYSIS_ALL ' || g_error);
        IF NOT pk_backoffice_mcdt.get_analysis_questionnaire(i_lang,
                                                             i_id_analysis,
                                                             i_id_sample_type,
                                                             i_id_institution,
                                                             'C',
                                                             o_inst_analysis_lab_quest_c,
                                                             o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- ALERT-885
        g_error := 'GET INST_ANALYSIS_COLLECTION CURSOR';
        OPEN o_inst_analysis_coll FOR
            SELECT ais.id_analysis,
                   ac.id_analysis_collection,
                   ac.num_collection num_collection,
                   ac.flg_interval_type,
                   pk_sysdomain.get_domain('ANALYSIS_COLLECTION.FLG_INTERVAL_TYPE', ac.flg_interval_type, i_lang) interval_type
              FROM analysis_instit_soft ais, analysis_collection ac, software s
             WHERE ais.id_analysis_instit_soft = ac.id_analysis_instit_soft
               AND ais.id_institution = i_id_institution
               AND ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_software IN (SELECT s2.id_software
                                         FROM software_institution si, software s2
                                        WHERE s2.flg_mni = g_flg_available
                                          AND si.id_software = s2.id_software
                                          AND si.id_institution = i_id_institution
                                          AND s2.id_software != 26)
               AND ais.id_software = s.id_software
               AND ac.flg_available = g_flg_available;
    
        g_error := 'GET INST_ANALYSIS_COLLECTION_INT CURSOR';
        OPEN o_inst_analysis_coll_int FOR
            SELECT ais.id_analysis, ac.id_analysis_collection, to_char(aci.interval) INTERVAL
              FROM analysis_instit_soft ais, analysis_collection ac, analysis_collection_int aci, software s
             WHERE ais.id_analysis_instit_soft = ac.id_analysis_instit_soft
               AND ac.flg_available = g_flg_available
               AND aci.id_analysis_collection = ac.id_analysis_collection
               AND ais.id_institution = i_id_institution
               AND ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_software IN (SELECT s2.id_software
                                         FROM software_institution si, software s2
                                        WHERE s2.flg_mni = g_flg_available
                                          AND si.id_software = s2.id_software
                                          AND si.id_institution = i_id_institution
                                          AND s2.id_software != 26)
               AND ais.id_software = s.id_software
               AND aci.interval > 0
             ORDER BY aci.id_analysis_collection, aci.order_collection;
    
        o_inst_analysis_coll_def_int := pk_sysconfig.get_config('ANALYSIS_COLLECTION_INTERVAL', i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                pk_types.open_my_cursor(o_inst_analysis);
                pk_types.open_my_cursor(o_inst_analysis_sin);
                pk_types.open_my_cursor(o_inst_analysis_loinc);
                pk_types.open_my_cursor(o_inst_analysis_cat);
                pk_types.open_my_cursor(o_inst_analysis_param);
                pk_types.open_my_cursor(o_inst_analysis_lab);
                pk_types.open_my_cursor(o_inst_analysis_lab_recep);
                pk_types.open_my_cursor(o_inst_analysis_wf_harvest);
                pk_types.open_my_cursor(o_inst_analysis_wf_mv_pat);
                pk_types.open_my_cursor(o_inst_analysis_wf_mv_rec);
                pk_types.open_my_cursor(o_inst_analysis_wf_exec);
                pk_types.open_my_cursor(o_inst_analysis_wf_result);
                pk_types.open_my_cursor(o_inst_analysis_room_mv_pat);
                pk_types.open_my_cursor(o_inst_analysis_dupl_warn);
                pk_types.open_my_cursor(o_inst_analysis_lab_quest_o);
                pk_types.open_my_cursor(o_inst_analysis_lab_quest_c);
                pk_types.open_my_cursor(o_inst_analysis_coll);
                pk_types.open_my_cursor(o_inst_analysis_coll_int);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INST_ANALYSIS_ALL');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_analysis_all;

    /********************************************************************************************
    * Get timing order
    *
    * @param i_lang                     Prefered language ID
    * @param o_timing                   Cursor with all timing order for the institution                      
    * 
    * @param o_error                    Error
    *
    *
    * @return                           true or false on success or error
    *
    * @author                           MARCO FREIRE
    * @version                          0.1
    * @since                            2010/05/18
    ********************************************************************************************/
    FUNCTION get_timing
    (
        i_lang   IN language.id_language%TYPE,
        o_timing OUT pk_types.cursor_type,
        o_error  OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
    BEGIN
    
        OPEN o_timing FOR
            SELECT sd.desc_val, sd.val
              FROM sys_domain sd
             WHERE sd.code_domain = 'ANALYSIS_INSTIT_SOFT.FLG_TIMING'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang;
    
        IF NOT pk_sysdomain.get_domains(i_lang, 'ANALYSIS_INSTIT_SOFT.FLG_TIMING', NULL, o_timing, l_error)
        THEN
            o_error := l_error;
            RETURN FALSE;
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
                                              'GET_TIMING',
                                              o_error);
            RETURN FALSE;
        
    END get_timing;

    /********************************************************************************************
    * GET_ANALYSIS_QUESTIONNAIRE
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_analysis              Analysis ID                      
    * @param i_id_institution           Institution ID
    * @param i_val                      Desc Val on Sys_domain
    * @param o_inst_analysis_lab_quest  Cursor with questions
    * @param o_error                    Error
    *
    *
    * @return                           true or false on success or error
    *
    * @author                           MARCO FREIRE
    * @version                          0.1
    * @since                            2010/06/21
    ********************************************************************************************/
    FUNCTION get_analysis_questionnaire
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_analysis             IN analysis.id_analysis%TYPE,
        i_id_sample_type          IN sample_type.id_sample_type%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_val                     IN sys_domain.desc_val%TYPE,
        o_inst_analysis_lab_quest OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET INST_ANALYSIS_QUESTIONARY CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.GET_ANALYSIS_QUESTIONNAIRE ' || g_error);
        OPEN o_inst_analysis_lab_quest FOR
            SELECT aq.id_analysis_questionnaire,
                   --rq.id_room_questionnaire,
                   pk_translation.get_translation(i_lang, 'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || aq.id_questionnaire) desc_questionnaire,
                   pk_sysdomain.get_domain('ANALYSIS_INSTIT_SOFT.FLG_ACT_QUES', aq.flg_available, i_lang) act_ques,
                   aq.flg_time flg_timing,
                   pk_sysdomain.get_domain('ANALYSIS_INSTIT_SOFT.FLG_TIMING', aq.flg_time, i_lang) timing,
                   rq.id_room
              FROM analysis_questionnaire aq, room_questionnaire rq, questionnaire q
             WHERE aq.id_institution = i_id_institution
               AND aq.id_room = rq.id_room
               AND aq.id_questionnaire = rq.id_questionnaire
               AND rq.id_questionnaire = q.id_questionnaire
               AND aq.id_analysis = i_id_analysis
               AND aq.id_sample_type = i_id_sample_type
               AND aq.flg_available = g_flg_available
               AND aq.flg_time = i_val
               AND rq.id_room IN (SELECT ar.id_room
                                    FROM analysis_room ar
                                   WHERE ar.id_analysis = i_id_analysis
                                     AND ar.id_sample_type = i_id_sample_type
                                     AND ar.flg_type = 'T'
                                     AND ar.id_institution = i_id_institution);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ANALYSIS_QUESTIONNAIRE',
                                              o_error);
            RETURN FALSE;
        
    END get_analysis_questionnaire;

    /********************************************************************************************
    * Public Function. Get Software list
    *
    * @param      I_LANG                     Language identification
    * @param      i_id_institution           Institution identification
    * @param      i_id_analysis              Analysis identification
    * @param      O_LIST                     Aplication list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/27
    *************************************************************************************************/
    FUNCTION get_software_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_analysis    IN analysis.id_analysis%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT -1 id_software,
                   pk_sysdomain.get_domain('ANALYSIS_ADM_SOFT', 'S', i_lang) software_name,
                   g_hand_icon icon,
                   g_no flg_status
              FROM dual
            UNION
            SELECT s.id_software id_software, s.name software_name, g_hand_icon icon, g_yes flg_status
              FROM analysis_instit_soft ais, software s
             WHERE ais.id_institution = i_id_institution
               AND ais.id_analysis = i_id_analysis
               AND ais.id_software = s.id_software
               AND s.flg_viewer = g_no
               AND s.id_software != 26
            UNION
            SELECT s.id_software id_software, s.name software_name, g_hand_icon icon, g_no flg_status
              FROM software s
             WHERE s.flg_mni = g_flg_available
               AND s.flg_viewer = g_no
               AND s.id_software != 26
               AND s.id_software NOT IN (SELECT s.id_software
                                           FROM analysis_instit_soft ais, software s
                                          WHERE ais.id_institution = i_id_institution
                                            AND ais.id_analysis = i_id_analysis
                                            AND ais.id_software = s.id_software
                                            AND s.flg_viewer = g_no
                                            AND s.id_software != 26)
             ORDER BY id_software;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SOFTWARE_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_software_list;

    /********************************************************************************************
    * Public Function. Get Software's Analysis Parameter List
    * 
    * @param      I_LANG                       Language identification
    * @param      I_ID_INSTITUTION             Institution identification
    * @param      I_ID_SOFTWARE                Software identification
    * @param      O_SOFT_PARAMETER_LIST        Cursor with parameter list information 
    * @param      O_ERROR                      Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/27
    ********************************************************************************************/
    FUNCTION get_soft_parameter_list
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN analysis_param.id_institution%TYPE,
        i_id_software         IN table_number,
        o_soft_parameter_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET ANALYSIS_PARAMETER_LIST CURSOR';
        OPEN o_soft_parameter_list FOR
            SELECT DISTINCT apm.id_analysis_parameter,
                            pk_translation.get_translation(i_lang, apm.code_analysis_parameter) analysis_param_name
              FROM analysis_param ap, analysis a, analysis_parameter apm
             WHERE ap.id_institution = i_id_institution
               AND ap.id_software IN (SELECT column_value
                                        FROM TABLE(CAST(i_id_software AS table_number)))
               AND ap.id_analysis = a.id_analysis
               AND ap.id_analysis_parameter = apm.id_analysis_parameter
             ORDER BY analysis_param_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_soft_parameter_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SOFT_PARAMETER_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_soft_parameter_list;

    FUNCTION get_analysis_location_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT s.val data, s.rank, s.desc_val label, NULL flg_default
              FROM sys_domain s
             WHERE s.id_language = i_lang
               AND s.code_domain = 'ANALYSIS_INSTIT_SOFT.FLG_HARVEST'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.val != 'U'
            UNION ALL
            SELECT NULL data, 30 rank, s.desc_message label, NULL flg_default
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'ADMINISTRATOR_T865'
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ANALYSIS_LOCATION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_analysis_location_list;

    /********************************************************************************************
    * Public Function. Get Department Information List
    * 
    * @param      I_LANG                     Language identification
    * @param      I_ID_INSTITUTION           Institution identification
    * @param      i_id_software              Software identification
    * @param      i_context                  Context identification
    * @param      o_dept_list                Cursor with departments list
    * @param      O_ERROR                    Error
    *
    * @value     i_context                   {*} 'A' Analyis {*} 'G' Analyis Group {*} 'I' Image exams {*} 'O' Others Exams 
                                             {*} 'P' Interventions  {*} 'D' Diagnosis {*} 'ME' External Medication 
                                             {*} 'MI' Internal Medication {*} 'MA' Manipulated {*} 'DE' Dietary 
                                             {*} 'S' Simple Parenteric Solutions {*} 'SC' Constructed Parenteric Solutions 
                                             {*} 'TP' Terapeutic Protocols
    *
    * @return     boolean
    * @author     TÈrcio Soares - JTS
    * @version    0.1
    * @since      2008/01/09
    ******************************************************************************************/
    FUNCTION get_dept_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_context        IN VARCHAR2,
        o_dept_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_context = 'A'
        THEN
            g_error := 'GET DEPT CURSOR';
            OPEN o_dept_list FOR
                SELECT DISTINCT d.id_dept,
                                pk_translation.get_translation(i_lang, d.code_dept) name,
                                g_status_a flg_status
                  FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs, department s, dept d
                 WHERE adcs.id_software = i_id_software
                   AND adcs.id_analysis IS NOT NULL
                   AND dcs.id_dep_clin_serv = adcs.id_dep_clin_serv
                   AND s.id_department = dcs.id_department
                   AND s.id_dept = d.id_dept
                   AND s.id_dept IN (SELECT d2.id_dept id
                                       FROM dept d2, software_dept sd
                                      WHERE d2.id_institution = i_id_institution
                                        AND d2.flg_available = g_flg_available
                                        AND sd.id_dept = d2.id_dept
                                        AND sd.id_software = i_id_software)
                
                UNION
                SELECT DISTINCT d3.id_dept,
                                pk_translation.get_translation(i_lang, d3.code_dept) name,
                                g_status_i flg_status
                  FROM dept d3, software_dept sd
                 WHERE d3.id_institution = i_id_institution
                   AND d3.flg_available = g_flg_available
                   AND sd.id_dept = d3.id_dept
                   AND sd.id_software = i_id_software
                   AND d3.id_dept NOT IN
                       (SELECT DISTINCT d.id_dept
                          FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs, department s, dept d
                         WHERE adcs.id_software = i_id_software
                           AND adcs.id_analysis IS NOT NULL
                           AND dcs.id_dep_clin_serv = adcs.id_dep_clin_serv
                           AND s.id_department = dcs.id_department
                           AND s.id_dept = d.id_dept
                           AND s.id_dept IN (SELECT d2.id_dept id
                                               FROM dept d2
                                              WHERE d2.id_institution = i_id_institution
                                                AND d2.flg_available = g_flg_available));
        ELSIF i_context = 'G'
        THEN
            g_error := 'GET DEPT CURSOR';
            OPEN o_dept_list FOR
                SELECT DISTINCT d.id_dept,
                                pk_translation.get_translation(i_lang, d.code_dept) name,
                                g_status_a flg_status
                  FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs, department s, dept d
                 WHERE adcs.id_software = i_id_software
                   AND adcs.id_analysis_group IS NOT NULL
                   AND dcs.id_dep_clin_serv = adcs.id_dep_clin_serv
                   AND s.id_department = dcs.id_department
                   AND s.id_dept = d.id_dept
                   AND s.id_dept IN (SELECT d2.id_dept id
                                       FROM dept d2, software_dept sd
                                      WHERE d2.id_institution = i_id_institution
                                        AND d2.flg_available = g_flg_available
                                        AND sd.id_dept = d2.id_dept
                                        AND sd.id_software = i_id_software)
                
                UNION
                SELECT DISTINCT d3.id_dept,
                                pk_translation.get_translation(i_lang, d3.code_dept) name,
                                g_status_i flg_status
                  FROM dept d3, software_dept sd
                 WHERE d3.id_institution = i_id_institution
                   AND sd.id_dept = d3.id_dept
                   AND sd.id_software = i_id_software
                   AND d3.flg_available = g_flg_available
                   AND d3.id_dept NOT IN
                       (SELECT DISTINCT d.id_dept
                          FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs, department s, dept d
                         WHERE adcs.id_software = i_id_software
                           AND adcs.id_analysis_group IS NOT NULL
                           AND dcs.id_dep_clin_serv = adcs.id_dep_clin_serv
                           AND s.id_department = dcs.id_department
                           AND s.id_dept = d.id_dept
                           AND s.id_dept IN (SELECT d2.id_dept id
                                               FROM dept d2
                                              WHERE d2.id_institution = i_id_institution
                                                AND d2.flg_available = g_flg_available));
        ELSIF i_context = 'I'
        THEN
            g_error := 'GET DEPT CURSOR';
            OPEN o_dept_list FOR
                SELECT DISTINCT d.id_dept,
                                pk_translation.get_translation(i_lang, d.code_dept) name,
                                g_status_a flg_status
                  FROM exam_dep_clin_serv edcs, exam e, dep_clin_serv dcs, department s, dept d
                 WHERE edcs.id_software = i_id_software
                   AND edcs.flg_type = 'M'
                   AND edcs.id_exam IS NOT NULL
                   AND edcs.id_exam = e.id_exam
                   AND e.flg_type = 'I'
                   AND e.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv = edcs.id_dep_clin_serv
                   AND s.id_department = dcs.id_department
                   AND s.id_dept = d.id_dept
                   AND s.id_dept IN (SELECT d2.id_dept id
                                       FROM dept d2, software_dept sd
                                      WHERE d2.id_institution = i_id_institution
                                        AND d2.flg_available = g_flg_available
                                        AND sd.id_dept = d2.id_dept
                                        AND sd.id_software = i_id_software)
                
                UNION
                SELECT DISTINCT d3.id_dept,
                                pk_translation.get_translation(i_lang, d3.code_dept) name,
                                g_status_i flg_status
                  FROM dept d3, software_dept sd
                 WHERE d3.id_institution = i_id_institution
                   AND sd.id_dept = d3.id_dept
                   AND sd.id_software = i_id_software
                   AND d3.flg_available = g_flg_available
                   AND d3.id_dept NOT IN
                       (SELECT DISTINCT d.id_dept
                          FROM exam_dep_clin_serv edcs, exam e, dep_clin_serv dcs, department s, dept d
                         WHERE edcs.id_software = i_id_software
                           AND edcs.flg_type = 'M'
                           AND edcs.id_exam IS NOT NULL
                           AND edcs.id_exam = e.id_exam
                           AND e.flg_type = 'I'
                           AND e.flg_available = 'Y'
                           AND dcs.id_dep_clin_serv = edcs.id_dep_clin_serv
                           AND s.id_department = dcs.id_department
                           AND s.id_dept = d.id_dept
                           AND s.id_dept IN (SELECT d2.id_dept id
                                               FROM dept d2
                                              WHERE d2.id_institution = i_id_institution
                                                AND d2.flg_available = g_flg_available));
        ELSIF i_context = 'O'
        THEN
            g_error := 'GET DEPT CURSOR';
            OPEN o_dept_list FOR
                SELECT DISTINCT d.id_dept,
                                pk_translation.get_translation(i_lang, d.code_dept) name,
                                g_status_a flg_status
                  FROM exam_dep_clin_serv edcs, exam e, dep_clin_serv dcs, department s, dept d
                 WHERE edcs.id_software = i_id_software
                   AND edcs.flg_type = 'M'
                   AND edcs.id_exam IS NOT NULL
                   AND edcs.id_exam = e.id_exam
                   AND e.flg_type != 'I'
                   AND e.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv = edcs.id_dep_clin_serv
                   AND s.id_department = dcs.id_department
                   AND s.id_dept = d.id_dept
                   AND s.id_dept IN (SELECT d2.id_dept id
                                       FROM dept d2, software_dept sd
                                      WHERE d2.id_institution = i_id_institution
                                        AND d2.flg_available = g_flg_available
                                        AND sd.id_dept = d2.id_dept
                                        AND sd.id_software = i_id_software)
                
                UNION
                SELECT DISTINCT d3.id_dept,
                                pk_translation.get_translation(i_lang, d3.code_dept) name,
                                g_status_i flg_status
                  FROM dept d3, software_dept sd
                 WHERE d3.id_institution = i_id_institution
                   AND sd.id_dept = d3.id_dept
                   AND sd.id_software = i_id_software
                   AND d3.flg_available = g_flg_available
                   AND d3.id_dept NOT IN
                       (SELECT DISTINCT d.id_dept
                          FROM exam_dep_clin_serv edcs, exam e, dep_clin_serv dcs, department s, dept d
                         WHERE edcs.id_software = i_id_software
                           AND edcs.flg_type = 'M'
                           AND edcs.id_exam IS NOT NULL
                           AND edcs.id_exam = e.id_exam
                           AND e.flg_type != 'I'
                           AND e.flg_available = 'Y'
                           AND dcs.id_dep_clin_serv = edcs.id_dep_clin_serv
                           AND s.id_department = dcs.id_department
                           AND s.id_dept = d.id_dept
                           AND s.id_dept IN (SELECT d2.id_dept id
                                               FROM dept d2
                                              WHERE d2.id_institution = i_id_institution
                                                AND d2.flg_available = g_flg_available));
        ELSIF i_context = 'P'
        THEN
            g_error := 'GET DEPT CURSOR';
            OPEN o_dept_list FOR
                SELECT DISTINCT d.id_dept,
                                pk_translation.get_translation(i_lang, d.code_dept) name,
                                g_status_a flg_status
                  FROM interv_dep_clin_serv idcs, intervention i, dep_clin_serv dcs, department s, dept d
                 WHERE idcs.id_software = i_id_software
                   AND idcs.flg_type = 'M'
                   AND idcs.id_intervention IS NOT NULL
                   AND idcs.id_intervention = i.id_intervention
                   AND i.flg_status = 'A'
                   AND dcs.id_dep_clin_serv = idcs.id_dep_clin_serv
                   AND s.id_department = dcs.id_department
                   AND s.id_dept = d.id_dept
                   AND s.id_dept IN (SELECT d2.id_dept id
                                       FROM dept d2, software_dept sd
                                      WHERE d2.id_institution = i_id_institution
                                        AND d2.flg_available = g_flg_available
                                        AND sd.id_dept = d2.id_dept
                                        AND sd.id_software = i_id_software)
                
                UNION
                SELECT DISTINCT d3.id_dept,
                                pk_translation.get_translation(i_lang, d3.code_dept) name,
                                g_status_i flg_status
                  FROM dept d3, software_dept sd
                 WHERE d3.id_institution = i_id_institution
                   AND sd.id_dept = d3.id_dept
                   AND sd.id_software = i_id_software
                   AND d3.flg_available = g_flg_available
                   AND d3.id_dept NOT IN
                       (SELECT DISTINCT d.id_dept
                          FROM interv_dep_clin_serv idcs, intervention i, dep_clin_serv dcs, department s, dept d
                         WHERE idcs.id_software = i_id_software
                           AND idcs.flg_type = 'M'
                           AND idcs.id_intervention IS NOT NULL
                           AND idcs.id_intervention = i.id_intervention
                           AND i.flg_status = 'A'
                           AND dcs.id_dep_clin_serv = idcs.id_dep_clin_serv
                           AND s.id_department = dcs.id_department
                           AND s.id_dept = d.id_dept
                           AND s.id_dept IN (SELECT d2.id_dept id
                                               FROM dept d2
                                              WHERE d2.id_institution = i_id_institution
                                                AND d2.flg_available = g_flg_available));
        ELSIF i_context = 'D'
        THEN
        
            g_error := 'GET DEPT CURSOR';
            OPEN o_dept_list FOR
                SELECT DISTINCT d.id_dept,
                                pk_translation.get_translation(i_lang, d.code_dept) name,
                                g_status_a flg_status
                  FROM diagnosis_dep_clin_serv ddcs, diagnosis di, dep_clin_serv dcs, department s, dept d
                 WHERE ddcs.id_software = i_id_software
                   AND ddcs.flg_type = 'M'
                   AND ddcs.id_diagnosis IS NOT NULL
                   AND ddcs.id_diagnosis = di.id_diagnosis
                   AND di.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv = ddcs.id_dep_clin_serv
                   AND s.id_department = dcs.id_department
                   AND s.id_dept = d.id_dept
                   AND s.id_dept IN (SELECT d2.id_dept id
                                       FROM dept d2, software_dept sd
                                      WHERE d2.id_institution = i_id_institution
                                        AND d2.flg_available = g_flg_available
                                        AND sd.id_dept = d2.id_dept
                                        AND sd.id_software = i_id_software)
                
                UNION
                SELECT DISTINCT d3.id_dept,
                                pk_translation.get_translation(i_lang, d3.code_dept) name,
                                g_status_i flg_status
                  FROM dept d3, software_dept sd
                 WHERE d3.id_institution = i_id_institution
                   AND sd.id_dept = d3.id_dept
                   AND sd.id_software = i_id_software
                   AND d3.flg_available = g_flg_available
                   AND d3.id_dept NOT IN
                       (SELECT DISTINCT d.id_dept
                          FROM diagnosis_dep_clin_serv ddcs, diagnosis di, dep_clin_serv dcs, department s, dept d
                         WHERE ddcs.id_software = i_id_software
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_diagnosis IS NOT NULL
                           AND ddcs.id_diagnosis = di.id_diagnosis
                           AND di.flg_available = 'Y'
                           AND dcs.id_dep_clin_serv = ddcs.id_dep_clin_serv
                           AND s.id_department = dcs.id_department
                           AND s.id_dept = d.id_dept
                           AND s.id_dept IN (SELECT d2.id_dept id
                                               FROM dept d2
                                              WHERE d2.id_institution = i_id_institution
                                                AND d2.flg_available = g_flg_available));
        ELSIF i_context = 'ME'
        THEN
            g_error := 'GET DEPT CURSOR';
            OPEN o_dept_list FOR
                SELECT DISTINCT d.id_dept,
                                pk_translation.get_translation(i_lang, d.code_dept) name,
                                g_status_a flg_status
                  FROM emb_dep_clin_serv edcs, me_med mm, dep_clin_serv dcs, department s, dept d
                 WHERE edcs.id_software = i_id_software
                   AND edcs.flg_type = 'M'
                   AND edcs.emb_id IS NOT NULL
                   AND edcs.emb_id = mm.emb_id
                   AND mm.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv = edcs.id_dep_clin_serv
                   AND s.id_department = dcs.id_department
                   AND s.id_dept = d.id_dept
                   AND s.id_dept IN (SELECT d2.id_dept id
                                       FROM dept d2, software_dept sd
                                      WHERE d2.id_institution = i_id_institution
                                        AND d2.flg_available = g_flg_available
                                        AND sd.id_dept = d2.id_dept
                                        AND sd.id_software = i_id_software)
                
                UNION
                SELECT DISTINCT d3.id_dept,
                                pk_translation.get_translation(i_lang, d3.code_dept) name,
                                g_status_i flg_status
                  FROM dept d3, software_dept sd
                 WHERE d3.id_institution = i_id_institution
                   AND sd.id_dept = d3.id_dept
                   AND sd.id_software = i_id_software
                   AND d3.flg_available = g_flg_available
                   AND d3.id_dept NOT IN
                       (SELECT DISTINCT d.id_dept
                          FROM emb_dep_clin_serv edcs, me_med mm, dep_clin_serv dcs, department s, dept d
                         WHERE edcs.id_software = i_id_software
                           AND edcs.flg_type = 'M'
                           AND edcs.emb_id IS NOT NULL
                           AND edcs.emb_id = mm.emb_id
                           AND mm.flg_available = 'Y'
                           AND dcs.id_dep_clin_serv = edcs.id_dep_clin_serv
                           AND s.id_department = dcs.id_department
                           AND s.id_dept = d.id_dept
                           AND s.id_dept IN (SELECT d2.id_dept id
                                               FROM dept d2
                                              WHERE d2.id_institution = i_id_institution
                                                AND d2.flg_available = g_flg_available));
        ELSIF i_context = 'MI'
        THEN
            g_error := 'GET DEPT CURSOR';
            OPEN o_dept_list FOR
                SELECT DISTINCT d.id_dept,
                                pk_translation.get_translation(i_lang, d.code_dept) name,
                                g_status_a flg_status
                  FROM drug_dep_clin_serv ddcs, mi_med mm, dep_clin_serv dcs, department s, dept d
                 WHERE ddcs.id_software = i_id_software
                   AND ddcs.flg_type = 'M'
                   AND ddcs.id_drug IS NOT NULL
                   AND ddcs.id_drug = mm.id_drug
                   AND mm.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv = ddcs.id_dep_clin_serv
                   AND s.id_department = dcs.id_department
                   AND s.id_dept = d.id_dept
                   AND s.id_dept IN (SELECT d2.id_dept id
                                       FROM dept d2, software_dept sd
                                      WHERE d2.id_institution = i_id_institution
                                        AND d2.flg_available = g_flg_available
                                        AND sd.id_dept = d2.id_dept
                                        AND sd.id_software = i_id_software)
                
                UNION
                SELECT DISTINCT d3.id_dept,
                                pk_translation.get_translation(i_lang, d3.code_dept) name,
                                g_status_i flg_status
                  FROM dept d3, software_dept sd
                 WHERE d3.id_institution = i_id_institution
                   AND sd.id_dept = d3.id_dept
                   AND sd.id_software = i_id_software
                   AND d3.flg_available = g_flg_available
                   AND d3.id_dept NOT IN
                       (SELECT DISTINCT d.id_dept
                          FROM drug_dep_clin_serv ddcs, mi_med mm, dep_clin_serv dcs, department s, dept d
                         WHERE ddcs.id_software = i_id_software
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_drug IS NOT NULL
                           AND ddcs.id_drug = mm.id_drug
                           AND mm.flg_available = 'Y'
                           AND dcs.id_dep_clin_serv = ddcs.id_dep_clin_serv
                           AND s.id_department = dcs.id_department
                           AND s.id_dept = d.id_dept
                           AND s.id_dept IN (SELECT d2.id_dept id
                                               FROM dept d2
                                              WHERE d2.id_institution = i_id_institution
                                                AND d2.flg_available = g_flg_available));
        ELSIF i_context = 'MA'
        THEN
            NULL;
        ELSIF i_context = 'DE'
        THEN
            NULL;
        ELSIF i_context = 'SP'
        THEN
            NULL;
        ELSIF i_context = 'S'
        THEN
            NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_dept_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_MCDT', 'GET_DEPT_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_dept_list;

    /********************************************************************************************
    * Public Function. Get Department Information List
    * 
    * @param      I_LANG                     Language identification
    * @param      I_ID_INSTITUTION           Institution identification
    * @param      i_id_software              Software identification 
    * @param      o_dept_list                Cursor with departments list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     TÈrcio Soares - JTS
    * @version    0.1
    * @since      2008/01/24
    ********************************************************************************************/
    FUNCTION get_dept_group_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_dept_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DEPT CURSOR';
        OPEN o_dept_list FOR
            SELECT DISTINCT d.id_dept, pk_translation.get_translation(i_lang, d.code_dept) name, g_status_a flg_status
              FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs, department s, dept d
             WHERE adcs.id_software = i_id_software
               AND adcs.id_analysis_group IS NOT NULL
               AND dcs.id_dep_clin_serv = adcs.id_dep_clin_serv
               AND s.id_department = dcs.id_department
               AND s.id_dept = d.id_dept
               AND d.id_dept IN (SELECT d2.id_dept id
                                   FROM dept d2
                                  WHERE d2.id_institution = i_id_institution
                                    AND d2.flg_available = g_flg_available)
            UNION
            SELECT DISTINCT d3.id_dept,
                            pk_translation.get_translation(i_lang, d3.code_dept) name,
                            g_status_i flg_status
              FROM dept d3
             WHERE d3.id_institution = i_id_institution
               AND d3.flg_available = g_flg_available
               AND d3.id_dept NOT IN
                   (SELECT DISTINCT d.id_dept
                      FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs, department s, dept d
                     WHERE adcs.id_software = i_id_software
                       AND adcs.id_analysis_group IS NOT NULL
                       AND dcs.id_dep_clin_serv = adcs.id_dep_clin_serv
                       AND s.id_department = dcs.id_department
                       AND s.id_dept = d.id_dept
                       AND d.id_dept IN (SELECT d2.id_dept id
                                           FROM dept d2
                                          WHERE d2.id_institution = i_id_institution
                                            AND d2.flg_available = g_flg_available));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_dept_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_DEPT_GROUP_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_dept_group_list;

    /********************************************************************************************
    * Public Function. Get Software's Analysis Parameter List
    * 
    * @param      I_LANG                       Language identification
    * @param      I_ID_DEPT                    Department identification
    * @param      I_ID_INSTITUTION             Institution identification
    * @param      i_id_software                Software identification
    * @param      i_context                    Context identification
    * @param      O_SERVICE_LIST               Cursor with service list information
    * @param      O_ERROR                      Error
    *
    * @value     i_context                     {*} 'A' Analyis {*} 'G' Analyis Group {*} 'I' Image exams {*} 'O' Others Exams 
                                               {*} 'P' Interventions  {*} 'D' Diagnosis {*} 'ME' External Medication 
                                               {*} 'MI' Internal Medication {*} 'MA' Manipulated {*} 'DE' Dietary 
                                               {*} 'S' Simple Parenteric Solutions {*} 'SC' Constructed Parenteric Solutions 
                                               {*} 'TP' Terapeutic Protocols
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/27
    ************************************************************************************************/
    FUNCTION get_dept_dcs_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_dept        IN department.id_dept%TYPE,
        i_id_institution IN department.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_context        IN VARCHAR2,
        i_prof           IN profissional,
        o_service_list   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version VARCHAR2(10) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
        IF i_context = 'A'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(a.id_analysis)
                          FROM analysis a, analysis_dep_clin_serv adcs, analysis_instit_soft ais
                         WHERE adcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND adcs.id_software = i_id_software
                           AND adcs.id_analysis = a.id_analysis
                           AND a.flg_available = 'Y'
                           AND ais.id_analysis = adcs.id_analysis
                           AND adcs.flg_available = 'Y'
                           AND ais.flg_available = 'Y'
                           AND ais.id_software = i_id_software
                           AND ais.flg_type IN ('P', 'W')
                           AND ais.id_institution = i_id_institution) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN (SELECT DISTINCT adcs.id_dep_clin_serv
                                                  FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs2, department s2
                                                 WHERE adcs.id_analysis IS NOT NULL
                                                   AND adcs.id_software = i_id_software
                                                   AND adcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                                                   AND dcs2.id_department = s2.id_department
                                                   AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT adcs.id_dep_clin_serv
                          FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs2, department s2
                         WHERE adcs.id_analysis IS NOT NULL
                           AND adcs.id_software = i_id_software
                           AND adcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'G'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(ag.id_analysis_group)
                          FROM analysis_dep_clin_serv adcs, analysis_group ag, analysis_instit_soft ais
                         WHERE adcs.id_analysis_group = ag.id_analysis_group
                           AND adcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND adcs.id_analysis_group IN
                               (SELECT ais.id_analysis_group
                                  FROM analysis_instit_soft ais
                                 WHERE ais.id_analysis_group IS NOT NULL
                                   AND ais.id_institution = i_id_institution
                                   AND ais.id_software = i_id_software)
                           AND adcs.id_software = i_id_software
                           AND ais.id_analysis_group = adcs.id_analysis_group -- Changed by Susana Silva (2009/02/04)
                           AND ais.flg_type IN ('P', 'W')
                           AND ais.flg_available = 'Y'
                           AND adcs.flg_available = 'Y'
                           AND ais.id_institution = i_id_institution
                           AND ais.id_software = i_id_software) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN (SELECT DISTINCT adcs.id_dep_clin_serv
                                                  FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs2, department s2
                                                 WHERE adcs.id_analysis_group IS NOT NULL
                                                   AND adcs.id_software = i_id_software
                                                   AND adcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                                                   AND dcs2.id_department = s2.id_department
                                                   AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT adcs.id_dep_clin_serv
                          FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs2, department s2
                         WHERE adcs.id_analysis_group IS NOT NULL
                           AND adcs.id_software = i_id_software
                           AND adcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'I'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(e.id_exam)
                          FROM exam_dep_clin_serv edcs, exam e
                         WHERE edcs.id_exam = e.id_exam
                           AND edcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND edcs.id_software = i_id_software
                           AND e.flg_type = 'I'
                           AND e.flg_available = 'Y'
                           AND edcs.flg_type = 'M'
                           AND edcs.id_exam IN (SELECT DISTINCT e.id_exam
                                                  FROM exam_dep_clin_serv edcs, exam e
                                                 WHERE edcs.id_exam = e.id_exam
                                                   AND edcs.flg_type = 'P'
                                                   AND edcs.id_software = i_id_software
                                                   AND e.flg_available = 'Y'
                                                   AND edcs.id_institution = i_id_institution)) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN
                       (SELECT DISTINCT edcs.id_dep_clin_serv
                          FROM exam_dep_clin_serv edcs, exam e, dep_clin_serv dcs2, department s2
                         WHERE edcs.id_exam IS NOT NULL
                           AND edcs.id_exam = e.id_exam
                           AND edcs.flg_type = 'M'
                           AND e.flg_type = 'I'
                           AND e.flg_available = 'Y'
                           AND edcs.id_software = i_id_software
                           AND edcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT edcs.id_dep_clin_serv
                          FROM exam_dep_clin_serv edcs, exam e, dep_clin_serv dcs2, department s2
                         WHERE edcs.id_exam IS NOT NULL
                           AND edcs.id_exam = e.id_exam
                           AND edcs.flg_type = 'M'
                           AND e.flg_type = 'I'
                           AND e.flg_available = 'Y'
                           AND edcs.id_software = i_id_software
                           AND edcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'O'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(e.id_exam)
                          FROM exam_dep_clin_serv edcs, exam e
                         WHERE edcs.id_exam = e.id_exam
                           AND edcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND edcs.id_software = i_id_software
                           AND e.flg_type != 'I'
                           AND e.flg_available = 'Y'
                           AND edcs.flg_type = 'M'
                           AND edcs.id_exam IN (SELECT DISTINCT e.id_exam
                                                  FROM exam_dep_clin_serv edcs, exam e
                                                 WHERE edcs.id_exam = e.id_exam
                                                   AND edcs.flg_type = 'P'
                                                   AND edcs.id_software = i_id_software
                                                   AND e.flg_available = 'Y'
                                                   AND edcs.id_institution = i_id_institution)) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN
                       (SELECT DISTINCT edcs.id_dep_clin_serv
                          FROM exam_dep_clin_serv edcs, exam e, dep_clin_serv dcs2, department s2
                         WHERE edcs.id_exam IS NOT NULL
                           AND edcs.id_exam = e.id_exam
                           AND edcs.flg_type = 'M'
                           AND e.flg_type != 'I'
                           AND e.flg_available = 'Y'
                           AND edcs.id_software = i_id_software
                           AND edcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT edcs.id_dep_clin_serv
                          FROM exam_dep_clin_serv edcs, exam e, dep_clin_serv dcs2, department s2
                         WHERE edcs.id_exam IS NOT NULL
                           AND edcs.id_exam = e.id_exam
                           AND edcs.flg_type = 'M'
                           AND e.flg_type != 'I'
                           AND e.flg_available = 'Y'
                           AND edcs.id_software = i_id_software
                           AND edcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'P'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(i.id_intervention)
                          FROM interv_dep_clin_serv idcs, intervention i
                         WHERE idcs.id_intervention = i.id_intervention
                           AND i.flg_status = 'A'
                           AND idcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND idcs.id_software = i_id_software
                           AND idcs.flg_type = 'M'
                           AND idcs.id_intervention IN
                               (SELECT DISTINCT idcs.id_intervention
                                  FROM interv_dep_clin_serv idcs, intervention i
                                 WHERE idcs.id_intervention = i.id_intervention
                                   AND idcs.flg_type = 'P'
                                   AND idcs.id_software = i_id_software
                                   AND i.flg_status = 'A'
                                   AND idcs.id_institution = i_id_institution)) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN
                       (SELECT DISTINCT idcs.id_dep_clin_serv
                          FROM interv_dep_clin_serv idcs, intervention i, dep_clin_serv dcs2, department s2
                         WHERE idcs.id_intervention IS NOT NULL
                           AND idcs.id_intervention = i.id_intervention
                           AND i.flg_status = 'A'
                           AND idcs.flg_type = 'M'
                           AND idcs.id_software = i_id_software
                           AND idcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT idcs.id_dep_clin_serv
                          FROM interv_dep_clin_serv idcs, intervention i, dep_clin_serv dcs2, department s2
                         WHERE idcs.id_intervention IS NOT NULL
                           AND idcs.id_intervention = i.id_intervention
                           AND i.flg_status = 'A'
                           AND idcs.flg_type = 'M'
                           AND idcs.id_software = i_id_software
                           AND idcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'D'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(di.id_diagnosis)
                          FROM diagnosis_dep_clin_serv ddcs, diagnosis di
                         WHERE ddcs.id_diagnosis = di.id_diagnosis
                           AND di.flg_available = 'Y'
                           AND ddcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND ddcs.id_software = i_id_software
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_diagnosis IN (SELECT ddcs.id_diagnosis
                                                       FROM diagnosis di, diagnosis_dep_clin_serv ddcs
                                                      WHERE di.id_diagnosis = ddcs.id_diagnosis
                                                        AND ddcs.flg_type = 'P'
                                                        AND ddcs.id_institution = i_id_institution
                                                        AND ddcs.id_software = i_id_software
                                                        AND di.flg_available = 'Y')) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN
                       (SELECT DISTINCT ddcs.id_dep_clin_serv
                          FROM diagnosis_dep_clin_serv ddcs, diagnosis di, dep_clin_serv dcs2, department s2
                         WHERE ddcs.id_diagnosis IS NOT NULL
                           AND ddcs.id_diagnosis = di.id_diagnosis
                           AND di.flg_available = 'Y'
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_software = i_id_software
                           AND ddcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT ddcs.id_dep_clin_serv
                          FROM diagnosis_dep_clin_serv ddcs, diagnosis di, dep_clin_serv dcs2, department s2
                         WHERE ddcs.id_diagnosis IS NOT NULL
                           AND ddcs.id_diagnosis = di.id_diagnosis
                           AND di.flg_available = 'Y'
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_software = i_id_software
                           AND ddcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'ME'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(mm.emb_id)
                          FROM emb_dep_clin_serv edcs, me_med mm
                         WHERE edcs.emb_id = mm.emb_id
                           AND mm.flg_available = 'Y'
                           AND edcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND edcs.id_software = i_id_software
                           AND edcs.flg_type = 'M'
                           AND mm.vers = l_version
                           AND edcs.emb_id IN (SELECT DISTINCT edcs.emb_id
                                                 FROM emb_dep_clin_serv edcs, me_med mm
                                                WHERE mm.emb_id = edcs.emb_id
                                                  AND edcs.id_software = i_id_software
                                                  AND edcs.id_institution = i_id_institution
                                                  AND edcs.flg_type = 'P'
                                                  AND mm.flg_available = 'Y')) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN
                       (SELECT DISTINCT edcs.id_dep_clin_serv
                          FROM emb_dep_clin_serv edcs, me_med mm, dep_clin_serv dcs2, department s2
                         WHERE edcs.emb_id IS NOT NULL
                           AND edcs.emb_id = mm.emb_id
                           AND mm.flg_available = 'Y'
                           AND edcs.flg_type = 'M'
                           AND edcs.id_software = i_id_software
                           AND edcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT edcs.id_dep_clin_serv
                          FROM emb_dep_clin_serv edcs, me_med mm, dep_clin_serv dcs2, department s2
                         WHERE edcs.emb_id IS NOT NULL
                           AND edcs.emb_id = mm.emb_id
                           AND mm.flg_available = 'Y'
                           AND edcs.flg_type = 'M'
                           AND edcs.id_software = i_id_software
                           AND edcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'MI'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(mm.id_drug)
                          FROM drug_dep_clin_serv ddcs, mi_med mm
                         WHERE ddcs.id_drug = mm.id_drug
                           AND mm.flg_available = 'Y'
                           AND mm.flg_type = 'M'
                           AND ddcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND ddcs.id_software = i_id_software
                           AND ddcs.flg_type = 'M'
                           AND mm.vers = l_version
                           AND ddcs.id_drug IN (SELECT DISTINCT mm.id_drug
                                                  FROM drug_dep_clin_serv ddcs, mi_med mm
                                                 WHERE mm.id_drug = ddcs.id_drug
                                                   AND ddcs.flg_type = 'P'
                                                   AND ddcs.id_institution = i_id_institution
                                                   AND ddcs.id_software = i_id_software
                                                   AND mm.flg_available = 'Y')) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN
                       (SELECT DISTINCT ddcs.id_dep_clin_serv
                          FROM drug_dep_clin_serv ddcs, mi_med mm, dep_clin_serv dcs2, department s2
                         WHERE ddcs.id_drug IS NOT NULL
                           AND ddcs.id_drug = mm.id_drug
                           AND mm.flg_type = 'M'
                           AND mm.flg_available = 'Y'
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_software = i_id_software
                           AND ddcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT ddcs.id_dep_clin_serv
                          FROM drug_dep_clin_serv ddcs, mi_med mm, dep_clin_serv dcs2, department s2
                         WHERE ddcs.id_drug IS NOT NULL
                           AND ddcs.id_drug = mm.id_drug
                           AND mm.flg_type = 'M'
                           AND mm.flg_available = 'Y'
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_software = i_id_software
                           AND ddcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'MA'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(mm.id_manipulated)
                          FROM emb_dep_clin_serv edcs, me_manip mm
                         WHERE edcs.id_manipulated = mm.id_manipulated
                           AND mm.flg_available = 'Y'
                           AND edcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND edcs.id_software = i_id_software
                           AND edcs.flg_type = 'M') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN
                       (SELECT DISTINCT edcs.id_dep_clin_serv
                          FROM emb_dep_clin_serv edcs, me_manip mm, dep_clin_serv dcs2, department s2
                         WHERE edcs.id_manipulated IS NOT NULL
                           AND edcs.id_manipulated = mm.id_manipulated
                           AND mm.flg_available = 'Y'
                           AND edcs.flg_type = 'M'
                           AND edcs.id_software = i_id_software
                           AND edcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT edcs.id_dep_clin_serv
                          FROM emb_dep_clin_serv edcs, me_manip mm, dep_clin_serv dcs2, department s2
                         WHERE edcs.id_manipulated IS NOT NULL
                           AND edcs.id_manipulated = mm.id_manipulated
                           AND mm.flg_available = 'Y'
                           AND edcs.flg_type = 'M'
                           AND edcs.id_software = i_id_software
                           AND edcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'DE'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(md.id_dietary_drug)
                          FROM emb_dep_clin_serv edcs, me_dietary md
                         WHERE edcs.id_dietary_drug = md.id_dietary_drug
                           AND md.flg_available = 'Y'
                           AND edcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND edcs.id_software = i_id_software
                           AND md.id_dietary_drug != -1
                           AND md.dietary_descr IS NOT NULL
                           AND md.vers = l_version
                           AND edcs.id_dietary_drug IN (SELECT DISTINCT md.id_dietary_drug
                                                          FROM me_dietary md
                                                         WHERE md.flg_available = 'Y')) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN
                       (SELECT DISTINCT edcs.id_dep_clin_serv
                          FROM emb_dep_clin_serv edcs, me_dietary md, dep_clin_serv dcs2, department s2
                         WHERE edcs.id_dietary_drug IS NOT NULL
                           AND edcs.id_dietary_drug = md.id_dietary_drug
                           AND md.flg_available = 'Y'
                           AND edcs.flg_type = 'M'
                           AND edcs.id_software = i_id_software
                           AND edcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT edcs.id_dep_clin_serv
                          FROM emb_dep_clin_serv edcs, me_dietary md, dep_clin_serv dcs2, department s2
                         WHERE edcs.id_dietary_drug IS NOT NULL
                           AND edcs.id_dietary_drug = md.id_dietary_drug
                           AND md.flg_available = 'Y'
                           AND edcs.flg_type = 'M'
                           AND edcs.id_software = i_id_software
                           AND edcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'S'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(mm.id_drug)
                          FROM drug_dep_clin_serv ddcs, mi_med mm
                         WHERE mm.flg_type = 'F'
                           AND mm.flg_available = 'Y'
                           AND ddcs.id_drug = mm.id_drug
                           AND ddcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND ddcs.id_software = i_id_software
                           AND ddcs.flg_type = 'M'
                           AND mm.vers = l_version
                           AND ddcs.id_drug IN (SELECT DISTINCT ddcs.id_drug
                                                  FROM drug_dep_clin_serv ddcs, mi_med mm
                                                 WHERE ddcs.id_institution = i_id_institution
                                                   AND ddcs.id_software = i_id_software
                                                   AND ddcs.id_drug = mm.id_drug
                                                   AND mm.flg_available = 'Y'
                                                   AND ddcs.flg_type = 'P')
                        
                        ) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN
                       (SELECT DISTINCT ddcs.id_dep_clin_serv
                          FROM drug_dep_clin_serv ddcs, mi_med mm, dep_clin_serv dcs2, department s2
                         WHERE ddcs.id_drug IS NOT NULL
                           AND ddcs.id_drug = mm.id_drug
                           AND mm.flg_type = 'F'
                           AND mm.flg_available = 'Y'
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_software = i_id_software
                           AND ddcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT ddcs.id_dep_clin_serv
                          FROM drug_dep_clin_serv ddcs, mi_med mm, dep_clin_serv dcs2, department s2
                         WHERE ddcs.id_drug IS NOT NULL
                           AND ddcs.id_drug = mm.id_drug
                           AND mm.flg_type = 'F'
                           AND mm.flg_available = 'Y'
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_software = i_id_software
                           AND ddcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'SC'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(mm.id_drug)
                          FROM drug_dep_clin_serv ddcs, mi_med mm
                         WHERE mm.flg_type = 'C'
                           AND mm.flg_available = 'Y'
                           AND ddcs.id_drug = mm.id_drug
                           AND ddcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND ddcs.id_software = i_id_software
                           AND ddcs.flg_type = 'M'
                           AND mm.vers = l_version
                           AND ddcs.id_drug IN (SELECT DISTINCT ddcs.id_drug
                                                  FROM drug_dep_clin_serv ddcs, mi_med mm
                                                 WHERE ddcs.id_institution = i_id_institution
                                                   AND ddcs.id_software = i_id_software
                                                   AND ddcs.id_drug = mm.id_drug
                                                   AND mm.flg_available = 'Y'
                                                   AND ddcs.flg_type = 'P')
                        
                        ) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN
                       (SELECT DISTINCT ddcs.id_dep_clin_serv
                          FROM drug_dep_clin_serv ddcs, mi_med mm, dep_clin_serv dcs2, department s2
                         WHERE ddcs.id_drug IS NOT NULL
                           AND ddcs.id_drug = mm.id_drug
                           AND mm.flg_type = 'C'
                           AND mm.flg_available = 'Y'
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_software = i_id_software
                           AND ddcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN
                       (SELECT DISTINCT ddcs.id_dep_clin_serv
                          FROM drug_dep_clin_serv ddcs, mi_med mm, dep_clin_serv dcs2, department s2
                         WHERE ddcs.id_drug IS NOT NULL
                           AND ddcs.id_drug = mm.id_drug
                           AND mm.flg_type = 'C'
                           AND mm.flg_available = 'Y'
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_software = i_id_software
                           AND ddcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                           AND dcs2.id_department = s2.id_department
                           AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        ELSIF i_context = 'TP'
        THEN
            g_error := 'GET SERVICE_LIST CURSOR';
            OPEN o_service_list FOR
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_a flg_status,
                       (SELECT COUNT(tp.id_therapeutic_protocols)
                          FROM therapeutic_protocols_dcs tpdcs, therapeutic_protocols tp
                         WHERE tp.flg_available = 'Y'
                           AND tpdcs.id_therapeutic_protocols = tp.id_therapeutic_protocols
                           AND tpdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND tpdcs.id_software = i_id_software
                           AND tpdcs.flg_type = 'M'
                           AND tpdcs.id_therapeutic_protocols IN
                               (SELECT DISTINCT tpdcs.id_therapeutic_protocols
                                  FROM therapeutic_protocols_dcs tpdcs, therapeutic_protocols tp
                                 WHERE tpdcs.id_therapeutic_protocols = tp.id_therapeutic_protocols
                                   AND tpdcs.flg_type = 'P'
                                   AND tpdcs.id_institution = i_id_institution
                                   AND tpdcs.id_software = i_id_software
                                   AND tp.flg_available = 'Y')
                        
                        ) assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv IN (SELECT DISTINCT tpdcs.id_dep_clin_serv
                                                  FROM therapeutic_protocols_dcs tpdcs,
                                                       therapeutic_protocols     tp,
                                                       dep_clin_serv             dcs2,
                                                       department                s2
                                                 WHERE tpdcs.id_therapeutic_protocols IS NOT NULL
                                                   AND tpdcs.id_therapeutic_protocols = tp.id_therapeutic_protocols
                                                   AND tp.flg_available = 'Y'
                                                   AND tpdcs.flg_type = 'M'
                                                   AND tpdcs.id_software = i_id_software
                                                   AND tpdcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                                                   AND dcs2.id_department = s2.id_department
                                                   AND s2.id_dept = i_id_dept)
                UNION
                SELECT dcs.id_dep_clin_serv,
                       s.id_department,
                       pk_translation.get_translation(i_lang, s.code_department) service_name,
                       cs.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                       g_status_i flg_status,
                       to_number('0') assoc_number
                  FROM department s, dep_clin_serv dcs, clinical_service cs
                 WHERE s.id_dept = i_id_dept
                   AND s.id_institution = i_id_institution
                   AND s.id_department = dcs.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND s.flg_available = 'Y'
                   AND cs.flg_available = 'Y'
                   AND dcs.flg_available = 'Y'
                   AND dcs.id_dep_clin_serv NOT IN (SELECT DISTINCT tpdcs.id_dep_clin_serv
                                                      FROM therapeutic_protocols_dcs tpdcs,
                                                           therapeutic_protocols     tp,
                                                           dep_clin_serv             dcs2,
                                                           department                s2
                                                     WHERE tpdcs.id_therapeutic_protocols IS NOT NULL
                                                       AND tpdcs.id_therapeutic_protocols = tp.id_therapeutic_protocols
                                                       AND tp.flg_available = 'Y'
                                                       AND tpdcs.flg_type = 'M'
                                                       AND tpdcs.id_software = i_id_software
                                                       AND tpdcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                                                       AND dcs2.id_department = s2.id_department
                                                       AND s2.id_dept = i_id_dept)
                 ORDER BY service_name, spec_name;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_service_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_DEPT_DCS_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_dept_dcs_list;

    /********************************************************************************************
    * Public Function. Get Institution Dep. Clinical Service Analysis List
    * 
    * @param      I_LANG                     Language identification
    * @param      I_ID_DEP_CLIN_SERV         Department / Clinical Service identification
    * @param      I_ID_SOFTWARE              Software identification
    * @param      i_id_institution           Institution identification
    * @param      O_ANALYSIS_DCS_LIST        Cursor with the most frequent analysis 
    * @param      o_group_dcs_list           Cursor with the most frequent analysis group
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/26
    *******************************************************************************************/
    FUNCTION get_analysis_dcs_list
    (
        i_lang              IN language.id_language%TYPE,
        i_id_dep_clin_serv  IN analysis_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_software       IN analysis_dep_clin_serv.id_software%TYPE,
        i_id_institution    IN analysis_instit_soft.id_institution%TYPE,
        o_analysis_dcs_list OUT pk_types.cursor_type,
        o_group_dcs_list    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS_GROUP_LIST CURSOR';
        OPEN o_analysis_dcs_list FOR
            SELECT a.id_analysis,
                   pk_translation.get_translation(i_lang, a.code_analysis) analysis_name,
                   g_hand_icon icon,
                   g_status_a flg_status
              FROM analysis a, analysis_dep_clin_serv adcs
             WHERE adcs.id_dep_clin_serv = i_id_dep_clin_serv
               AND adcs.id_software = i_id_software
               AND adcs.id_analysis = a.id_analysis
            UNION
            SELECT a.id_analysis,
                   pk_translation.get_translation(i_lang, a.code_analysis) analysis_name,
                   
                   NULL       icon,
                   g_status_i flg_status
              FROM analysis a, analysis_instit_soft ais
             WHERE a.id_analysis NOT IN (SELECT a.id_analysis
                                           FROM analysis a, analysis_dep_clin_serv adcs
                                          WHERE adcs.id_dep_clin_serv = i_id_dep_clin_serv
                                            AND adcs.id_software = i_id_software
                                            AND adcs.id_analysis = a.id_analysis)
               AND a.id_analysis = ais.id_analysis
               AND ais.id_institution = i_id_institution
               AND ais.id_software = i_id_software
               AND ais.flg_type = 'P'
             ORDER BY analysis_name;
    
        g_error := 'GET GROUP_LIST CURSOR';
        OPEN o_group_dcs_list FOR
            SELECT ag.id_analysis_group,
                   pk_translation.get_translation(i_lang, ag.code_analysis_group) group_name,
                   g_hand_icon icon,
                   g_status_a flg_status
              FROM analysis_dep_clin_serv adcs, analysis_group ag
             WHERE adcs.id_analysis_group = ag.id_analysis_group
               AND adcs.id_dep_clin_serv = i_id_dep_clin_serv
               AND adcs.id_software = i_id_software
            UNION
            SELECT ag.id_analysis_group,
                   pk_translation.get_translation(i_lang, ag.code_analysis_group) group_name,
                   g_hand_icon icon,
                   g_status_i flg_status
              FROM analysis_group ag
             WHERE ag.id_analysis_group NOT IN (SELECT adcs.id_analysis_group
                                                  FROM analysis_dep_clin_serv adcs, analysis_group ag
                                                 WHERE adcs.id_analysis_group = ag.id_analysis_group
                                                   AND adcs.id_dep_clin_serv = i_id_dep_clin_serv
                                                   AND adcs.id_software = i_id_software)
             ORDER BY group_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_analysis_dcs_list);
                pk_types.open_my_cursor(o_group_dcs_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_DCS_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_dcs_list;

    /********************************************************************************************
    * Public Function. Get Relation(Department/Clinical Service) Information
    * 
    * @param      I_LANG                     Language identification
    * @param      I_ID_INSTITUTION           Institution identification
    * @param      I_ID_ANALYSIS              Analysis identification
    * @param      O_REL                      Cursor with the department / clinical service information
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     TÈrcio Soares - JTS
    * @version    0.1
    * @since      2007/11/30
    *********************************************************************************************/
    FUNCTION get_dep_clin_serv
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_analysis    IN analysis_instit_soft.id_analysis%TYPE,
        o_rel            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DEP_CLIN_SERV CURSOR';
        OPEN o_rel FOR
            SELECT DISTINCT dcs.id_dep_clin_serv,
                            d.id_department id_service,
                            pk_translation.get_translation(i_lang, d.code_department) service_name,
                            cs.id_clinical_service,
                            pk_translation.get_translation(i_lang, cs.code_clinical_service) clinical_service_name,
                            g_yes flg_selected
              FROM analysis_instit_soft   ais,
                   analysis_dep_clin_serv adcs,
                   dep_clin_serv          dcs,
                   department             d,
                   clinical_service       cs
             WHERE ais.id_institution = i_id_analysis
               AND ais.id_analysis = i_id_analysis
               AND ais.id_analysis = adcs.id_analysis
               AND adcs.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND dcs.flg_available = g_flg_available
               AND dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
            UNION
            SELECT DISTINCT dcs.id_dep_clin_serv,
                            d.id_department id_service,
                            pk_translation.get_translation(i_lang, d.code_department) service_name,
                            cs.id_clinical_service,
                            pk_translation.get_translation(i_lang, cs.code_clinical_service) clinical_service_name,
                            g_no flg_selected
              FROM analysis_instit_soft   ais,
                   analysis_dep_clin_serv adcs,
                   dep_clin_serv          dcs,
                   department             d,
                   clinical_service       cs
             WHERE ais.id_institution = i_id_analysis
               AND adcs.id_analysis = ais.id_analysis
               AND adcs.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND dcs.flg_available = g_flg_available
               AND dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND adcs.id_dep_clin_serv NOT IN
                   (SELECT DISTINCT adcs.id_dep_clin_serv
                      FROM analysis_instit_soft   ais,
                           analysis_dep_clin_serv adcs,
                           dep_clin_serv          dcs,
                           department             d,
                           clinical_service       cs
                     WHERE ais.id_institution = i_id_analysis
                       AND ais.id_analysis = i_id_analysis
                       AND ais.id_analysis = adcs.id_analysis
                       AND adcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                       AND dcs.flg_available = g_flg_available
                       AND dcs.id_department = d.id_department
                       AND dcs.id_clinical_service = cs.id_clinical_service)
             ORDER BY service_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_rel);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_DEP_CLIN_SERV');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_dep_clin_serv;

    /********************************************************************************************
    * Public Function. Get Exam Category list
    *
    * @param      I_LANG                     Language identification
    * @param      O_LIST                     Aplications list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/27
    ***********************************************************************************************/
    FUNCTION get_exam_cat_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT ec.id_exam_cat, pk_translation.get_translation(i_lang, ec.code_exam_cat) exam_cat_name
              FROM exam_cat ec
             ORDER BY exam_cat_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_EXAM_CAT_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_exam_cat_list;

    /********************************************************************************************
    * Public Function. Insert New Analysis Group OR Update Analysis Group Information
    *
    * @param      I_LANG                               Language identification
    * @param      I_PROF                               Profissional (Professional Id,Institution ID, Software ID)
    * @param      i_id_institution                     Institution Id
    * @param      I_ID_SOFTWARE                        Software Id
    * @param      I_DEP_CLIN_SERV                      Array of Dep_Clin_Serv 
    * @param      I_ANALYSIS                           Array of arrays of Analysis identification
    * @param      I_PANELS                             Array of arrays of Analysis group identification
    * @param      I_SELECT                             Array of arrays of Insert or Remove identification
    * @param      i_commit_at_end                      Commit at the end
    * @param      O_ID_ANALYSIS_DEP_CLIN_SERV          Dep_clin_Serv relations identification
    * @param      O_ERROR                              Error 
    *
    * @return     boolean
    * @author     TÈrcio Soares - JTS
    * @version    0.1
    * @since      2007/12/13
    **************************************************************************************************/
    FUNCTION set_analysis_dcs
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_institution            IN institution.id_institution%TYPE,
        i_id_software               IN software.id_software%TYPE,
        i_dep_clin_serv             IN table_number,
        i_analysis                  IN table_table_number,
        i_panels                    IN table_table_number,
        i_select                    IN table_table_varchar,
        i_commit_at_end             IN VARCHAR2,
        o_id_analysis_dep_clin_serv OUT table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_i    NUMBER := 0;
        c_soft pk_types.cursor_type;
        l_soft NUMBER;
        l_res  BOOLEAN;
    
    BEGIN
        g_sysdate                   := SYSDATE;
        o_id_analysis_dep_clin_serv := table_number();
    
        IF i_id_software = -1
        THEN
            OPEN c_soft FOR
                SELECT DISTINCT s.id_software
                  FROM analysis_instit_soft ais, software s
                 WHERE ais.id_institution = i_id_institution
                   AND ais.id_software = s.id_software
                   AND s.flg_viewer = g_no
                   AND s.id_software != 26;
        
            LOOP
                FETCH c_soft
                    INTO l_soft;
                EXIT WHEN c_soft%NOTFOUND;
            
                l_res := set_analysis_dcs(i_lang,
                                          i_prof,
                                          i_id_institution,
                                          l_soft,
                                          i_dep_clin_serv,
                                          i_analysis,
                                          i_panels,
                                          i_select,
                                          g_no,
                                          o_id_analysis_dep_clin_serv,
                                          o_error);
            
            END LOOP;
            CLOSE c_soft;
        ELSE
        
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                IF i_analysis.count != 0
                THEN
                    FOR j IN 1 .. i_analysis(i).count
                    LOOP
                    
                        IF i_select(i) (j) = 'N'
                        THEN
                            g_error := 'DELETE FROM ANALYSIS_DEP_CLIN_SERV';
                            DELETE FROM analysis_dep_clin_serv adcs
                             WHERE adcs.id_dep_clin_serv = i_dep_clin_serv(i)
                               AND adcs.id_analysis = i_analysis(i) (j)
                               AND adcs.id_software = i_id_software;
                        ELSE
                            o_id_analysis_dep_clin_serv.extend;
                            l_i := l_i + 1;
                        
                            g_error := 'GET SEQ_ANALYSIS_GROUP.NEXTVAL';
                            SELECT seq_analysis_dep_clin_serv.nextval
                              INTO o_id_analysis_dep_clin_serv(l_i)
                              FROM dual;
                        
                            g_error := 'INSERT INTO ANALYSIS_DEP_CLIN_SERV';
                            INSERT INTO analysis_dep_clin_serv
                                (id_analysis_dep_clin_serv, id_analysis, id_dep_clin_serv, rank, id_software)
                            VALUES
                                (o_id_analysis_dep_clin_serv(l_i),
                                 i_analysis(i) (j),
                                 i_dep_clin_serv(i),
                                 0,
                                 i_id_software);
                        
                        END IF;
                    
                    END LOOP;
                ELSE
                    FOR j IN 1 .. i_panels(i).count
                    LOOP
                    
                        IF i_select(i) (j) = 'N'
                        THEN
                            g_error := 'DELETE FROM ANALYSIS_DEP_CLIN_SERV';
                            DELETE FROM analysis_dep_clin_serv adcs
                             WHERE adcs.id_dep_clin_serv = i_dep_clin_serv(i)
                               AND adcs.id_analysis_group = i_panels(i) (j)
                               AND adcs.id_software = i_id_software;
                        ELSE
                            o_id_analysis_dep_clin_serv.extend;
                            l_i := l_i + 1;
                        
                            g_error := 'GET SEQ_ANALYSIS_GROUP.NEXTVAL';
                            SELECT seq_analysis_dep_clin_serv.nextval
                              INTO o_id_analysis_dep_clin_serv(l_i)
                              FROM dual;
                        
                            g_error := 'INSERT INTO ANALYSIS_DEP_CLIN_SERV';
                            INSERT INTO analysis_dep_clin_serv
                                (id_analysis_dep_clin_serv, id_dep_clin_serv, rank, id_software, id_analysis_group)
                            VALUES
                                (o_id_analysis_dep_clin_serv(l_i),
                                 i_dep_clin_serv(i),
                                 0,
                                 i_id_software,
                                 i_panels(i) (j));
                        
                        END IF;
                    
                    END LOOP;
                
                END IF;
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
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_ANALYSIS_DCS');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_analysis_dcs;

    /********************************************************************************************
    * Public Function. Update Sample Recipient State
    *
    * @param      I_LANG                               Language identification
    * @param      I_ID_SAMPLE_RECIPIENT                Recipient identification
    * @param      I_FLG_AVAILABLE                      Status: Active /Inactive
    * @param      O_ERROR                              Error 
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/13
    ***********************************************************************************************/
    FUNCTION set_recipient_state
    (
        i_lang                IN language.id_language%TYPE,
        i_id_sample_recipient IN table_number,
        i_flg_available       IN table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN 1 .. i_id_sample_recipient.count
        LOOP
            g_error := 'UPDATE SAMPLE_RECIPIETN';
            UPDATE sample_recipient
               SET flg_available = decode(i_flg_available(i), 'A', 'Y', 'N')
             WHERE id_sample_recipient = i_id_sample_recipient(i);
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_RECIPIENT_STATE');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_recipient_state;

    /********************************************************************************************
    * Public Function. Get Sample Recipient POSSIBLE LIST
    *
    * @param      I_LANG                     Language identification
    * @param      O_LIST                     Add button possible task in the recipient screen
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/13
    **********************************************************************************************/
    FUNCTION get_recipient_poss_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS ADD LIST CURSOR';
        OPEN o_list FOR
        
            SELECT val data, desc_val label
              FROM sys_domain
             WHERE code_domain = 'SAMPLE_RECIPIENT_ADD_TASK'
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY data DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_RECIPIENT_POSS_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_recipient_poss_list;

    /********************************************************************************************
    * Public Function. Get Recipient State List
    *
    * @param      I_LANG                     Language identification
    * @param      O_RECIPIENT_STATE          Cursor with the recipient status information
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/13
    ***********************************************************************************************/
    FUNCTION get_recipient_state_list
    (
        i_lang            IN language.id_language%TYPE,
        o_recipient_state OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SAMPLE_RECIPIENT STATE CURSOR';
        OPEN o_recipient_state FOR
            SELECT val, desc_val, img_name icon
              FROM sys_domain
             WHERE code_domain = g_recipient_flg_available
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_recipient_state);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_RECIPIENT_STATE_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_recipient_state_list;

    /********************************************************************************************
    * Public Function. Get Sample Recipient Information
    * 
    * @param      I_LANG                        Language identification
    * @param      I_ID_SAMPLE_RECIPIENT         Recipient identification
    * @param      O_RECIPIENT                   Cursor With the recipient information
    * @param      O_ERROR                       Error
    *
    * @return     boolean
    * @author     TÈrcio Soares - JTS
    * @version    0.1
    * @since      2007/12/13
    ***********************************************************************************************/
    FUNCTION get_sample_recipient
    (
        i_lang                IN language.id_language%TYPE,
        i_id_sample_recipient IN sample_recipient.id_sample_recipient%TYPE,
        o_recipient           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SAMPLE RECIPIENT CURSOR';
        OPEN o_recipient FOR
            SELECT rec.id_sample_recipient,
                   pk_translation.get_translation(i_lang, rec.code_sample_recipient) recipient_name,
                   rec.flg_available,
                   pk_sysdomain.get_domain(g_recipient_flg_available, rec.flg_available, i_lang) state,
                   rec.adw_last_update,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, rec.adw_last_update, profissional(0, 0, 0)) upd_date,
                   rec.capacity
              FROM sample_recipient rec
             WHERE id_sample_recipient = i_id_sample_recipient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_recipient);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SAMPLE_RECIPIENT');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_sample_recipient;

    /********************************************************************************************
    * Public Function. Get Analysis Group State LIST
    *
    * @param      I_LANG                     Language identification
    * @param      O_LIST                     Possible status in the analysis group
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/14
    ************************************************************************************************/
    FUNCTION get_analysis_group_state_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS ADD LIST CURSOR';
        OPEN o_list FOR
        
            SELECT val, desc_val, img_name icon
              FROM sys_domain
             WHERE code_domain = 'ANALYSIS_GROUP_STATE'
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_GROUP_STATE_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_group_state_list;

    /********************************************************************************************
    * Public Function. Find Analysis Alias
    *
    * @param      I_LANG                     Language identification
    * @param      I_PROF                     Profissional (Professional Id, Institution Id, Software ID)
    * @param      I_ID_INSTITUTION           Institution id
    * @param      I_ID_ANALYSIS              Analysis id
    * @param      O_ALIAS_LIST               Alias 
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/18
    *************************************************************************************************/
    FUNCTION find_analysis_alias
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN analysis_alias.id_institution%TYPE,
        i_id_analysis    IN analysis_alias.id_analysis%TYPE,
        o_alias_list     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_counter NUMBER;
    
    BEGIN
    
        g_error := 'SELECT COUNT(*)';
        SELECT COUNT(DISTINCT aa.id_analysis_alias)
          INTO l_counter
          FROM analysis_alias aa
         WHERE aa.id_analysis = i_id_analysis
           AND (aa.id_institution = i_id_institution OR aa.id_institution = 0);
    
        OPEN o_alias_list FOR
            SELECT aa.id_analysis_alias,
                   aa.id_analysis,
                   pk_translation.get_translation(i_lang, aa.code_analysis_alias) analysis_alias,
                   aa.id_software
              FROM analysis_alias aa
             WHERE aa.id_analysis = i_id_analysis
               AND (aa.id_institution = i_id_institution OR aa.id_institution = 0);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_alias_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'FIND_ANALYSIS_ALIAS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END find_analysis_alias;

    /********************************************************************************************
    * Public Function. Get Analysis Groups List
    * 
    * @param      I_LANG                     Language identification
    * @param      I_ID_ANALYSIS_GROUP        Analysis group identification
    * @param      I_GENDER                   Gender
    * @param      I_AGE_MIN                  Minimum age
    * @param      I_AGE_MAX                  Maximum age
    * @param      i_search                   Search
    * @param      O_LITS                     Cursor with analysis information
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/18
    **********************************************************************************************/
    FUNCTION get_agp_criteria_list
    (
        i_lang              IN language.id_language%TYPE,
        i_id_analysis_group IN analysis_group.id_analysis_group%TYPE,
        i_gender            IN analysis_group.gender%TYPE,
        i_age_min           IN analysis_group.age_min%TYPE,
        i_age_max           IN analysis_group.age_max%TYPE,
        i_search            IN VARCHAR2,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_search IS NOT NULL
        THEN
        
            g_error := 'GET GROUP_ANALYSIS CURSOR';
            OPEN o_list FOR
            -- Analysis in the group
                SELECT agp.id_analysis,
                       pk_translation.get_translation(i_lang, a.code_analysis) analysis_name,
                       g_status_a flg_select,
                       g_hand_icon analysis_icon,
                       agp.id_analysis_group,
                       a.gender,
                       a.age_min,
                       a.age_max
                  FROM analysis_agp agp, analysis a
                 WHERE agp.id_analysis_group = i_id_analysis_group
                   AND agp.id_analysis = a.id_analysis
                   AND a.flg_available = g_flg_available
                   AND translate(upper(pk_translation.get_translation(i_lang, a.code_analysis)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                UNION
                -- Analysis in criteria
                SELECT a.id_analysis,
                       pk_translation.get_translation(i_lang, a.code_analysis) analysis_name,
                       NULL flg_select,
                       NULL analysis_icon,
                       NULL id_analysis_group,
                       a.gender,
                       a.age_min,
                       a.age_max
                  FROM analysis a
                 WHERE (a.gender = i_gender OR a.gender IS NULL)
                   AND (a.age_min >= i_age_min OR a.age_min IS NULL)
                   AND (a.age_max <= i_age_max OR a.age_max IS NULL)
                   AND a.flg_available = g_flg_available
                   AND a.id_analysis NOT IN (SELECT agp2.id_analysis
                                               FROM analysis_agp agp2, analysis a2
                                              WHERE agp2.id_analysis_group = i_id_analysis_group
                                                AND agp2.id_analysis = a2.id_analysis
                                                AND a2.flg_available = g_flg_available)
                   AND translate(upper(pk_translation.get_translation(i_lang, a.code_analysis)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY flg_select, analysis_name;
        
        ELSE
            g_error := 'GET GROUP_ANALYSIS CURSOR';
            OPEN o_list FOR
            -- Analysis in the group    
                SELECT agp.id_analysis,
                       pk_translation.get_translation(i_lang, a.code_analysis) analysis_name,
                       g_status_a flg_select,
                       g_hand_icon analysis_icon,
                       agp.id_analysis_group,
                       a.gender,
                       a.age_min,
                       a.age_max
                  FROM analysis_agp agp, analysis a
                 WHERE agp.id_analysis_group = i_id_analysis_group
                   AND agp.id_analysis = a.id_analysis
                   AND a.flg_available = g_flg_available
                
                UNION
                -- Analysis in criteria
                SELECT a.id_analysis,
                       pk_translation.get_translation(i_lang, a.code_analysis) analysis_name,
                       NULL flg_select,
                       NULL analysis_icon,
                       NULL id_analysis_group,
                       a.gender,
                       a.age_min,
                       a.age_max
                  FROM analysis a
                 WHERE (a.gender = i_gender OR a.gender IS NULL)
                   AND (a.age_min >= i_age_min OR a.age_min IS NULL)
                   AND (a.age_max <= i_age_max OR a.age_max IS NULL)
                   AND a.flg_available = g_flg_available
                   AND a.id_analysis NOT IN (SELECT agp2.id_analysis
                                               FROM analysis_agp agp2, analysis a2
                                              WHERE agp2.id_analysis_group = i_id_analysis_group
                                                AND agp2.id_analysis = a2.id_analysis
                                                AND a2.flg_available = g_flg_available)
                 ORDER BY flg_select, analysis_name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_AGP_CRITERIA_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_agp_criteria_list;

    /********************************************************************************************
    * Public Function. Get Analysis Group Information
    * 
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      I_ID_ANALYSIS_GROUP        Analysis group
    * @param      O_ANALYSIS_GROUP           Cursor with analysis group information
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/18
    *********************************************************************************************/
    FUNCTION get_analysis_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_analysis_group IN analysis_group.id_analysis_group%TYPE,
        o_analysis_group    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET GROUP_ANALYSIS CURSOR';
        OPEN o_analysis_group FOR
            SELECT ag.id_analysis_group,
                   pk_translation.get_translation(i_lang, ag.code_analysis_group) analysis_group,
                   ag.gender,
                   pk_sysdomain.get_domain(g_patient_gender, ag.gender, i_lang) gender_desc,
                   ag.age_min,
                   ag.age_max,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, ag.adw_last_update, i_prof) upd_date
              FROM analysis_group ag
             WHERE ag.id_analysis_group = i_id_analysis_group;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_analysis_group);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_GROUP');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_group;

    /********************************************************************************************
    * Public Function. Get Gender List
    * 
    * @param      I_LANG                     Language identification
    * @param      O_GENDER                   Cursor with gender information
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/20
    *********************************************************************************************/
    FUNCTION get_gender_list
    (
        i_lang   IN language.id_language%TYPE,
        o_gender OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_gender FOR
            SELECT sd.val, sd.desc_val
              FROM sys_domain sd
             WHERE sd.code_domain = g_domain_gender
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.val NOT LIKE 'I'
               AND sd.id_language = i_lang
            UNION
            SELECT NULL val, pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T060') desc_val
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_gender);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_MCDT', 'GET_GENDER_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_gender_list;

    /********************************************************************************************
    * Public Function. Update Parameter State
    *
    * @param      I_LANG                               Language identification
    * @param      I_ID_PARAMETER                       Parameter identification
    * @param      I_FLG_AVAILABLE                      Status: Active/Inactive
    * @param      O_ERROR                              Error 
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/24
    *********************************************************************************************/
    FUNCTION set_parameter_state
    (
        i_lang          IN language.id_language%TYPE,
        i_id_parameter  IN table_number,
        i_flg_available IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN 1 .. i_id_parameter.count
        LOOP
            g_error := 'UPDATE ANALYSIS';
            UPDATE analysis_parameter
               SET flg_available = decode(i_flg_available(i), 'A', 'Y', 'N')
             WHERE id_analysis_parameter = i_id_parameter(i);
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_PARAMETER_STATE');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_parameter_state;

    /********************************************************************************************
    * Public Function. Get Institution Type List
    *
    * @param      I_LANG                     Language identification
    * @param      o_parameter_state          Cursor           
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/24
    ***********************************************************************************************/
    FUNCTION get_parameter_state_list
    (
        i_lang            IN language.id_language%TYPE,
        o_parameter_state OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET PROFESSIONAL STATE CURSOR';
        OPEN o_parameter_state FOR
            SELECT val, desc_val, img_name icon
              FROM sys_domain
             WHERE code_domain = g_parameter_flg_available
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_parameter_state);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_PARAMETER_STATE_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_parameter_state_list;

    /******************************************************************************************************
    * Public Function. Get Parameter POSSIBLE LIST
    *
    * @param      I_LANG                     Language identification
    * @param      O_LIST                     Possible tasks to the add button in the parameter screen
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/24
    *****************************************************************************************************/
    FUNCTION get_parameter_poss_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET PARAMETER ADD LIST CURSOR';
        OPEN o_list FOR
        
            SELECT val data, desc_val label
              FROM sys_domain
             WHERE code_domain = 'PARAMETER_ADD_TASK'
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY data DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_PARAMETER_POSS_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_parameter_poss_list;

    /********************************************************************************************
    * Public Function. Get Analysis Parameter Information
    *
    * @param      I_LANG                     Language identification
    * @param      I_PROF                     Professional identification
    * @param      I_ID_PARAMETER             Parameter identification
    * @param      O_PARAMETER                Cursor with parameter information
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/24
    *********************************************************************************************/
    FUNCTION get_parameter_details
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        o_parameter    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ANALYSIS CURSOR';
        OPEN o_parameter FOR
            SELECT ap.id_analysis_parameter,
                   pk_translation.get_translation(i_lang, ap.code_analysis_parameter) analysis_parameter,
                   ap.flg_available,
                   pk_sysdomain.get_domain(g_parameter_flg_available, nvl(ap.flg_available, g_yes), i_lang) state,
                   ap.adw_last_update,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, ap.adw_last_update, i_prof) upd_date
              FROM analysis_parameter ap
             WHERE ap.id_analysis_parameter = i_id_parameter;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_parameter);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_PARAMETER_DETAILS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_parameter_details;

    /********************************************************************************************
    * Public Function. Get Dep_clin_serv List
    * 
    * @param      I_LANG                       Language identification
    * @param      I_ID_DEPT                    Department identification
    * @param      I_ID_INSTITUTION             Institution identification
    * @param      i_id_software                Software identification
    * @param      O_SERVICE_LIST               Cursor with service list information
    * @param      O_ERROR                      Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/01/24
    **********************************************************************************************/
    FUNCTION get_dept_dcs_group_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_dept        IN department.id_dept%TYPE,
        i_id_institution IN department.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_service_list   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SERVICE_LIST CURSOR';
        OPEN o_service_list FOR
            SELECT dcs.id_dep_clin_serv,
                   s.id_department,
                   pk_translation.get_translation(i_lang, s.code_department) service_name,
                   cs.id_clinical_service,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                   g_status_a flg_status
              FROM department s, dep_clin_serv dcs, clinical_service cs
             WHERE s.id_dept = i_id_dept
               AND s.id_institution = i_id_institution
               AND s.id_department = dcs.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND dcs.id_dep_clin_serv IN (SELECT DISTINCT adcs.id_dep_clin_serv
                                              FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs2, department s2
                                             WHERE adcs.id_analysis_group IS NOT NULL
                                               AND adcs.id_software = i_id_software
                                               AND adcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                                               AND dcs2.id_department = s2.id_department
                                               AND s2.id_dept = i_id_dept)
            UNION
            SELECT dcs.id_dep_clin_serv,
                   s.id_department,
                   pk_translation.get_translation(i_lang, s.code_department) service_name,
                   cs.id_clinical_service,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                   g_status_i flg_status
              FROM department s, dep_clin_serv dcs, clinical_service cs
             WHERE s.id_dept = i_id_dept
               AND s.id_institution = i_id_institution
               AND s.id_department = dcs.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND dcs.id_dep_clin_serv NOT IN (SELECT DISTINCT adcs.id_dep_clin_serv
                                                  FROM analysis_dep_clin_serv adcs, dep_clin_serv dcs2, department s2
                                                 WHERE adcs.id_analysis_group IS NOT NULL
                                                   AND adcs.id_software = i_id_software
                                                   AND adcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
                                                   AND dcs2.id_department = s2.id_department
                                                   AND s2.id_dept = i_id_dept)
             ORDER BY service_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_service_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_DEPT_DCS_GROUP_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_dept_dcs_group_list;

    /********************************************************************************************
    * Interventions list
    *
    * @param i_lang                  Prefered language ID
    * @param i_search                Search
    * @param o_interv_list           Interventions
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/23
    ********************************************************************************************/
    FUNCTION get_intervention_list
    (
        i_lang        IN language.id_language%TYPE,
        i_search      IN VARCHAR2,
        o_interv_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET INTERV_LIST CURSOR';
        IF i_search IS NULL
        THEN
            OPEN o_interv_list FOR
                SELECT i.id_intervention id,
                       pk_translation.get_translation(i_lang, i.code_intervention) ||
                       decode(i.gender,
                              NULL,
                              NULL,
                              ' - <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T034') || ': ' ||
                              pk_sysdomain.get_domain('PATIENT.GENDER', i.gender, i_lang) || '<\b>') ||
                       decode(i.age_min,
                              NULL,
                              NULL,
                              ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T010') || ': ' ||
                              i.age_min || '<\b>') ||
                       decode(i.age_max,
                              NULL,
                              NULL,
                              ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T011') || ': ' ||
                              i.age_max || '<\b>') interv_name,
                       pk_translation.get_translation(i_lang, i.code_intervention) interv_name_abbrev,
                       i.gender,
                       i.age_min,
                       i.age_max,
                       i.flg_status,
                       pk_sysdomain.get_domain('ACTIVE_INACTIVE', nvl(i.flg_status, 'A'), i_lang) state
                  FROM intervention i
                 ORDER BY state, gender, interv_name;
        ELSE
            OPEN o_interv_list FOR
                SELECT i.id_intervention id,
                       pk_translation.get_translation(i_lang, i.code_intervention) ||
                       decode(i.gender,
                              NULL,
                              NULL,
                              ' - <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T034') || ': ' ||
                              pk_sysdomain.get_domain('PATIENT.GENDER', i.gender, i_lang) || '<\b>') ||
                       decode(i.age_min,
                              NULL,
                              NULL,
                              ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T010') || ': ' ||
                              i.age_min || '<\b>') ||
                       decode(i.age_max,
                              NULL,
                              NULL,
                              ', <b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_ANALYSIS_T011') || ': ' ||
                              i.age_max || '<\b>') interv_name,
                       pk_translation.get_translation(i_lang, i.code_intervention) interv_name_abbrev,
                       i.gender,
                       i.age_min,
                       i.age_max,
                       i.flg_status,
                       pk_sysdomain.get_domain('ACTIVE_INACTIVE', nvl(i.flg_status, 'A'), i_lang) state
                  FROM intervention i
                 WHERE translate(upper(pk_translation.get_translation(i_lang, i.code_intervention)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY state, gender, interv_name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_interv_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INTERVENTION_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_intervention_list;

    /********************************************************************************************
    * Update Interventions state
    *
    * @param i_lang                Prefered language ID
    * @param i_id_interv           Interventions ID's
    * @param i_flg_available       A - available ; I - not available
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION set_interventions_state
    (
        i_lang          IN language.id_language%TYPE,
        i_id_interv     IN table_number,
        i_flg_available IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        FOR i IN 1 .. i_id_interv.count
        LOOP
            g_error := 'UPDATE INTERVENTION';
            UPDATE intervention
               SET flg_status = i_flg_available(i)
             WHERE id_intervention = i_id_interv(i);
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_INTERVENTIONS_STATE');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_interventions_state;

    /********************************************************************************************
    * Get POSSIBLE LIST
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param o_list                Options
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_poss_list
    (
        i_lang        IN language.id_language%TYPE,
        i_code_domain sys_domain.code_domain%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET OPTIONS LIST CURSOR';
        OPEN o_list FOR
        
            SELECT val data, desc_val label
              FROM sys_domain
             WHERE code_domain = i_code_domain
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY data DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_MCDT', 'GET_POSS_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_poss_list;

    /********************************************************************************************
    * Get Intervention information
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Object (professional ID, institution ID, software ID)
    * @param i_id_intervention     Intervention ID
    * @param o_intervention        Intervention information
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_intervention
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE,
        o_intervention    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET INTERVENTION CURSOR';
        OPEN o_intervention FOR
            SELECT i.id_intervention,
                   pk_translation.get_translation(i_lang, i.code_intervention) interv_name,
                   i.id_intervention_parent,
                   decode(i.id_intervention_parent,
                          NULL,
                          NULL,
                          (SELECT pk_translation.get_translation(i_lang, ip.code_intervention)
                             FROM intervention ip
                            WHERE ip.id_intervention = i.id_intervention_parent)) interv_parent_name,
                   i.flg_status,
                   pk_sysdomain.get_domain('ACTIVE_INACTIVE', nvl(i.flg_status, 'A'), i_lang) status,
                   i.adw_last_update,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, i.adw_last_update, i_prof) upd_date,
                   (SELECT ic.id_interv_category
                      FROM interv_int_cat iic, interv_category ic
                     WHERE iic.id_intervention = i.id_intervention
                       AND iic.id_interv_category = ic.id_interv_category
                       AND ic.flg_available = g_flg_available) interv_cat,
                   (pk_translation.get_translation(i_lang,
                                                   (SELECT ic.code_interv_category
                                                      FROM interv_int_cat iic, interv_category ic
                                                     WHERE iic.id_intervention = i.id_intervention
                                                       AND iic.id_interv_category = ic.id_interv_category
                                                       AND ic.flg_available = g_flg_available))) interv_cat_desc,
                   
                   i.gender,
                   pk_sysdomain.get_domain('PATIENT.GENDER', nvl(i.gender, NULL), i_lang) genero,
                   i.age_min,
                   i.age_max,
                   i.mdm_coding,
                   i.cpt_code,
                   i.flg_mov_pat,
                   pk_sysdomain.get_domain('YES_NO', nvl(i.flg_mov_pat, NULL), i_lang) mov_pat_desc
              FROM intervention i
             WHERE i.id_intervention = i_id_intervention;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_intervention);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INTERVENTION');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_intervention;

    /********************************************************************************************
    * Get Body Parts
    *
    * @param i_lang                Prefered language ID
    * @param o_body_part           Body Part List
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_body_part_list
    (
        i_lang      IN language.id_language%TYPE,
        o_body_part OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET BODY_PART CURSOR';
        OPEN o_body_part FOR
            SELECT bp.id_body_part, pk_translation.get_translation(i_lang, bp.code_body_part) body_aprt_name
              FROM body_part bp
             WHERE bp.flg_available = 'Y';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_body_part);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_BODY_PART_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_body_part_list;

    /********************************************************************************************
    * Get Specialties System Appar
    *
    * @param i_lang                Prefered language ID
    * @param o_spec_sys_appar      Spec_sys_appr List
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_spec_sys_appar_list
    (
        i_lang           IN language.id_language%TYPE,
        o_spec_sys_appar OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SPEC_SYS_APPR CURSOR';
        OPEN o_spec_sys_appar FOR
            SELECT ssa.id_spec_sys_appar,
                   pk_translation.get_translation(i_lang, sa.code_system_apparati) || ' - ' ||
                   pk_translation.get_translation(i_lang, s.code_speciality) sys_spec
              FROM spec_sys_appar ssa, system_apparati sa, speciality s
             WHERE ssa.id_system_apparati = sa.id_system_apparati
               AND ssa.id_speciality = s.id_speciality
             ORDER BY s.id_speciality;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_spec_sys_appar);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SPEC_SYS_APPAR_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_spec_sys_appar_list;

    /********************************************************************************************
    * Get Intervention Phys. Area
    *
    * @param i_lang                Prefered language ID
    * @param o_interv_phys_area    Intervention Phys. Areas
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_interv_phys_area_list
    (
        i_lang             IN language.id_language%TYPE,
        o_interv_phys_area OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SPEC_SYS_APPR CURSOR';
        OPEN o_interv_phys_area FOR
            SELECT ipa.id_interv_physiatry_area,
                   pk_translation.get_translation(i_lang, ipa.code_interv_physiatry_area) interv_physiatry_area_name
              FROM interv_physiatry_area ipa
             ORDER BY interv_physiatry_area_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_interv_phys_area);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INTERV_PHYS_AREA_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_interv_phys_area_list;

    /********************************************************************************************
    * Get State List
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param o_list                List od states
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_state_list
    (
        i_lang        IN language.id_language%TYPE,
        i_code_domain sys_domain.code_domain%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET LIST CURSOR';
        OPEN o_list FOR
        
            SELECT val, desc_val, img_name icon
              FROM sys_domain
             WHERE code_domain = i_code_domain
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_MCDT', 'GET_STATE_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_state_list;

    /********************************************************************************************
    * Public Function. Get Institution Dep. Clinical Service Interventions List
    * 
    * @param      I_LANG                     Language identification
    * @param      I_ID_DEP_CLIN_SERV         Department / clinical service identification
    * @param      I_ID_SOFTWARE              Software identification
    * @param      i_id_institution           Institution identification
    * @param      O_INTERV_DCS_LIST          Cursor with the most frequent interventions
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/22
    **********************************************************************************************/
    FUNCTION get_interv_dcs_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_software      IN interv_dep_clin_serv.id_software%TYPE,
        i_id_institution   IN interv_dep_clin_serv.id_institution%TYPE,
        o_interv_dcs_list  OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET INTERV_DCS_LIST CURSOR';
        OPEN o_interv_dcs_list FOR
            SELECT i.id_intervention,
                   pk_translation.get_translation(i_lang, i.code_intervention) interv_name,
                   'A' flg_status
              FROM intervention i, interv_dep_clin_serv idcs
             WHERE idcs.id_dep_clin_serv = i_id_dep_clin_serv
               AND idcs.id_software = i_id_software
               AND idcs.flg_type = 'M'
               AND idcs.id_intervention = i.id_intervention
            UNION
            SELECT i.id_intervention,
                   pk_translation.get_translation(i_lang, i.code_intervention) interv_name,
                   'I' flg_status
              FROM intervention i
             WHERE i.id_intervention NOT IN
                   (SELECT i2.id_intervention
                      FROM intervention i2, interv_dep_clin_serv idcs2
                     WHERE idcs2.id_dep_clin_serv = i_id_dep_clin_serv
                       AND idcs2.id_software = i_id_software
                       AND idcs2.flg_type = 'M'
                       AND idcs2.id_intervention = i2.id_intervention)
             ORDER BY interv_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_interv_dcs_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INTERV_DCS_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_interv_dcs_list;

    /********************************************************************************************
    * Interventions/Dep_clin_serv association
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param i_dep_clin_serv         Array of Department/Clinical Service ID's
    * @param i_interv                Arrya of array of Interventions ID's
    * @param i_select                Array of array of Flags(Y - insert; N - delete)
    * @param i_commit_at_end         Commit 
    * @param o_id_interv_dep_clin_serv Associations ID's
    * @param o_error                 Error
    *
    * @value i_commit_at_end         {*} 'Y' Yes {*} 'N' No
    * 
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/23
    ********************************************************************************************/
    FUNCTION set_interv_dcs
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_dep_clin_serv           IN table_number,
        i_interv                  IN table_table_number,
        i_select                  IN table_table_varchar,
        i_commit_at_end           IN VARCHAR2,
        o_id_interv_dep_clin_serv OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_i            NUMBER := 0;
        c_soft         pk_types.cursor_type;
        l_soft         NUMBER;
        l_res          BOOLEAN;
        l_rows_delidcs table_varchar;
        l_rows_insidcs table_varchar;
        l_rows_aux     table_varchar;
        l_error        t_error_out;
    BEGIN
        o_id_interv_dep_clin_serv := table_number();
    
        IF i_id_software = -1
        THEN
            OPEN c_soft FOR
                SELECT DISTINCT s.id_software
                  FROM interv_dep_clin_serv idcs, software s
                 WHERE idcs.id_institution = i_id_institution
                   AND idcs.id_software = s.id_software
                   AND s.flg_viewer = 'N'
                   AND s.id_software != 26;
        
            LOOP
                FETCH c_soft
                    INTO l_soft;
                EXIT WHEN c_soft%NOTFOUND;
            
                l_res := set_interv_dcs(i_lang,
                                        i_prof,
                                        i_id_institution,
                                        l_soft,
                                        i_dep_clin_serv,
                                        i_interv,
                                        i_select,
                                        g_no,
                                        o_id_interv_dep_clin_serv,
                                        o_error);
            
            END LOOP;
            CLOSE c_soft;
        ELSE
        
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_interv(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM INTERV_DEP_CLIN_SERV';
                        ts_interv_dep_clin_serv.del_by(where_clause_in => 'id_dep_clin_serv = ' || i_dep_clin_serv(i) || '
                           AND id_intervention = ' ||
                                                                          i_interv(i) (j) || '
                           AND id_software = ' ||
                                                                          i_id_software || '
                           AND id_institution = ' ||
                                                                          i_id_institution,
                                                       rows_out        => l_rows_aux);
                        l_rows_delidcs := l_rows_delidcs MULTISET UNION l_rows_aux;
                    ELSE
                        o_id_interv_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_INTERV_DEP_CLIN_SERV.NEXTVAL';
                        SELECT seq_interv_dep_clin_serv.nextval
                          INTO o_id_interv_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO INTERV_DEP_CLIN_SERV';
                        ts_interv_dep_clin_serv.ins(id_interv_dep_clin_serv_out => o_id_interv_dep_clin_serv(l_i),
                                                    id_intervention_in          => i_interv(i) (j),
                                                    id_dep_clin_serv_in         => i_dep_clin_serv(i),
                                                    flg_type_in                 => 'M',
                                                    rank_in                     => 0,
                                                    id_institution_in           => i_id_institution,
                                                    id_software_in              => i_id_software,
                                                    rows_out                    => l_rows_aux);
                        l_rows_insidcs := l_rows_insidcs MULTISET UNION l_rows_aux;
                    
                    END IF;
                
                END LOOP;
            END LOOP;
            t_data_gov_mnt.process_delete(i_lang, i_prof, 'INTERV_DEP_CLIN_SERV', l_rows_delidcs, l_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'INTERV_DEP_CLIN_SERV', l_rows_insidcs, l_error);
        
        END IF;
    
        IF i_commit_at_end = g_yes
        THEN
            COMMIT;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error || ' / ' || l_error.err_desc,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_INTERV_DCS');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_interv_dcs;

    /********************************************************************************************
    * Most Frequent software list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param o_software              Software List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_software_dcs
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_software FOR
            SELECT DISTINCT s.id_software id, s.name name
              FROM software_institution si, software s, software_dept sd, dept d
             WHERE s.flg_mni = 'Y'
               AND si.id_software = s.id_software
               AND si.id_institution = i_id_institution
               AND s.id_software != 26
               AND s.id_software = sd.id_software
               AND sd.id_dept = d.id_dept
               AND d.id_institution = i_id_institution
               AND d.flg_available = 'Y'
             ORDER BY name;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_software);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SOFTWARE_DCS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_software_dcs;

    /********************************************************************************************
    * New Intervention OR Update Intervention Information
    *
    * @param i_lang                     Prefered language ID
    * @param i_prof                     Object
    * @param i_id_intervention          Intervention ID
    * @param i_desc                     Intervention Name
    * @param i_flg_status               Flag status
    * @param i_id_intervention_parent   Parent Intervention ID
    * @param i_interv_cat               Intervention category identification             
    * @param i_id_interv_physiatry_area Physiatry area ID
    * @param i_mdm_coding               MDM code
    * @param i_cpt_code                 CPT code
    * @param i_gender                   Gender
    * @param i_age_min                  Minimum age
    * @param i_age_max                  Maximum age
    * @param i_flg_mov_pat              Move patient?
    * @param o_id_intervention          Intervention ID
    * @param o_error                    Error
    *
    * @value i_flg_status               {*} 'A' Available {*} 'I' Not available
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/29
    ********************************************************************************************/
    FUNCTION set_intervention
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_intervention        IN intervention.id_intervention%TYPE,
        i_desc                   IN VARCHAR2,
        i_flg_status             IN intervention.flg_status%TYPE,
        i_id_intervention_parent IN intervention.id_intervention_parent%TYPE,
        i_interv_cat             IN interv_category.id_interv_category%TYPE,
        i_mdm_coding             IN intervention.mdm_coding%TYPE,
        i_cpt_code               IN intervention.cpt_code%TYPE,
        i_gender                 IN intervention.gender%TYPE,
        i_age_min                IN intervention.age_min%TYPE,
        i_age_max                IN intervention.age_max%TYPE,
        i_flg_mov_pat            IN intervention.flg_mov_pat%TYPE,
        o_id_intervention        OUT intervention.id_intervention%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_intervention IS NULL
        THEN
        
            g_error := 'GET SEQ_INTERVENTION.NEXTVAL';
            SELECT seq_intervention.nextval
              INTO o_id_intervention
              FROM dual;
        
            g_error := 'INSERT INTO INTERVENTION';
            INSERT INTO intervention
                (id_intervention,
                 id_intervention_parent,
                 flg_status,
                 rank,
                 adw_last_update,
                 flg_mov_pat,
                 gender,
                 age_min,
                 age_max,
                 mdm_coding,
                 cpt_code)
            VALUES
                (o_id_intervention,
                 i_id_intervention_parent,
                 i_flg_status,
                 0,
                 SYSDATE,
                 i_flg_mov_pat,
                 i_gender,
                 i_age_min,
                 i_age_max,
                 i_mdm_coding,
                 i_cpt_code);
        
            pk_translation.insert_into_translation(i_lang,
                                                   'INTERVENTION.CODE_INTERVENTION.' || o_id_intervention || '',
                                                   i_desc);
        
            INSERT INTO interv_int_cat
                (id_interv_category, id_intervention, adw_last_update)
            VALUES
                (i_interv_cat, o_id_intervention, SYSDATE);
        
        ELSE
            g_error := 'UPDATE INTERVENTION';
            UPDATE intervention
               SET id_intervention_parent = i_id_intervention_parent,
                   flg_status             = i_flg_status,
                   adw_last_update        = SYSDATE,
                   gender                 = i_gender,
                   age_min                = i_age_min,
                   age_max                = i_age_max,
                   mdm_coding             = i_mdm_coding,
                   cpt_code               = i_cpt_code,
                   flg_mov_pat            = i_flg_mov_pat
             WHERE intervention.id_intervention = i_id_intervention;
        
            UPDATE interv_int_cat
               SET id_interv_category = i_interv_cat
             WHERE id_intervention = i_id_intervention;
        
            o_id_intervention := i_id_intervention;
        
            pk_translation.insert_into_translation(i_lang,
                                                   'INTERVENTION.CODE_INTERVENTION.' || o_id_intervention || '',
                                                   i_desc);
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_INTERVENTION');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_intervention;

    /********************************************************************************************
    * Get Interventions by Institution and Software
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param i_search                Search                        
    * @param o_list                  List of search interventions in the institution 
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/29
    ********************************************************************************************/
    FUNCTION get_inst_soft_interv_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_software    IN analysis_instit_soft.id_software%TYPE,
        i_search         IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET EXAM_LIST CURSOR';
        IF i_search IS NULL
        THEN
            OPEN o_list FOR
                SELECT DISTINCT i.id_intervention id,
                                pk_translation.get_translation(i_lang, i.code_intervention) name,
                                idcs.flg_type flg_status,
                                pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE',
                                                        decode(idcs.flg_type, 'P', 'E', idcs.flg_type),
                                                        i_lang) status_desc,
                                get_missing_data(i_lang, i.id_intervention, i_id_institution, idcs.id_software, 'P') missing_data
                  FROM interv_dep_clin_serv idcs, intervention i
                 WHERE idcs.id_institution = i_id_institution
                   AND idcs.id_software = i_id_software
                   AND idcs.flg_type = 'P'
                   AND idcs.id_intervention = i.id_intervention
                   AND i.flg_status = 'A'
                 ORDER BY name;
        ELSE
            OPEN o_list FOR
                SELECT DISTINCT i.id_intervention id,
                                pk_translation.get_translation(i_lang, i.code_intervention) name,
                                idcs.flg_type flg_status,
                                pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE',
                                                        decode(idcs.flg_type, 'P', 'E', idcs.flg_type),
                                                        i_lang) status_desc,
                                get_missing_data(i_lang, i.id_intervention, i_id_institution, idcs.id_software, 'P') missing_data
                  FROM interv_dep_clin_serv idcs, intervention i
                 WHERE idcs.id_institution = i_id_institution
                   AND idcs.id_software = i_id_software
                   AND idcs.flg_type = 'P'
                   AND idcs.id_intervention = i.id_intervention
                   AND i.flg_status = 'A'
                   AND translate(upper(pk_translation.get_translation(i_lang, i.code_intervention)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY name;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INST_SOFT_INTERV_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_soft_interv_list;

    /********************************************************************************************
    * Get My Alert Association
    *
    * @param i_lang                  Prefered language ID
    * @param i_dep_clin_serv         Service/Clinical Service ID
    * @param i_id_software           Software ID
    * @param i_id_institution        Institution ID
    * @param i_context               Context (A - Analysis, G - Analysis Groups, ...)
    * @param i_search                Filtro de pesquisa
    * @param i_id_diagnosis          Diagnosis ID
    * @param o_dcs_list              My Alert list
    * @param o_error                 Error
    *
    * @value     i_context           {*} 'A' Analyis {*} 'G' Analyis Group {*} 'I' Image exams {*} 'O' Others Exams 
                                     {*} 'P' Interventions  {*} 'D' Diagnosis {*} 'ME' External Medication 
                                     {*} 'MI' Internal Medication {*} 'MA' Manipulated {*} 'DE' Dietary 
                                     {*} 'S' Simple Parenteric Solutions {*} 'SC' Constructed Parenteric Solutions 
                                     {*} 'TP' Terapeutic Protocols
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/30
    ********************************************************************************************/
    FUNCTION get_my_alert_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN NUMBER,
        i_id_software      IN NUMBER,
        i_id_institution   IN NUMBER,
        i_context          IN VARCHAR2,
        i_search           IN VARCHAR2,
        i_id_diagnosis     IN diagnosis.id_diagnosis%TYPE,
        o_dcs_list         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_config VARCHAR2(1);
        l_dept   dept.id_dept%TYPE;
    
    BEGIN
    
        SELECT s.id_dept
          INTO l_dept
          FROM dep_clin_serv dcs, department s
         WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
           AND dcs.id_department = s.id_department;
    
        g_error := 'GET DCS_LIST CURSOR';
    
        IF i_context = 'A'
        THEN
            IF i_search IS NULL
            THEN
                OPEN o_dcs_list FOR
                --Most Frequent Analysis
                    SELECT ast.id_analysis || '|' || ast.id_sample_type id,
                           pk_translation.get_translation(i_lang, 'ANALYSIS.CODE_ANALYSIS.' || ast.id_analysis) || ', ' ||
                           lower(pk_translation.get_translation(i_lang,
                                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ast.id_sample_type)) name,
                           g_status_a flg_status
                      FROM analysis_dep_clin_serv adcs, analysis_sample_type ast, analysis_instit_soft ais
                     WHERE adcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND adcs.id_software = i_id_software
                       AND adcs.flg_available = 'Y'
                       AND adcs.id_analysis = ast.id_analysis
                       AND adcs.id_sample_type = ast.id_sample_type
                       AND ast.flg_available = 'Y'
                       AND ast.id_analysis = ais.id_analysis
                       AND ast.id_sample_type = ais.id_sample_type
                       AND ais.flg_type IN ('P', 'W')
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_id_software
                       AND ais.flg_available = 'Y'
                    UNION
                    --Analysis not Most Frequent
                    SELECT ast.id_analysis || '|' || ast.id_sample_type id,
                           pk_translation.get_translation(i_lang, 'ANALYSIS.CODE_ANALYSIS.' || ast.id_analysis) || ', ' ||
                           lower(pk_translation.get_translation(i_lang,
                                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ast.id_sample_type)) name,
                           g_status_i flg_status
                      FROM analysis_sample_type ast, analysis_instit_soft ais
                     WHERE ast.id_analysis NOT IN (SELECT ast.id_analysis
                                                     FROM analysis_sample_type ast, analysis_dep_clin_serv adcs
                                                    WHERE adcs.id_dep_clin_serv = i_id_dep_clin_serv
                                                      AND adcs.id_software = i_id_software
                                                      AND adcs.flg_available = 'Y'
                                                      AND adcs.id_analysis = ast.id_analysis
                                                      AND adcs.id_sample_type = ast.id_sample_type
                                                      AND ast.flg_available = 'Y')
                       AND ast.flg_available = 'Y'
                       AND ast.id_analysis = ais.id_analysis
                       AND ast.id_sample_type = ais.id_sample_type
                       AND ais.flg_type IN ('P', 'W')
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_id_software
                       AND ais.flg_available = 'Y'
                     ORDER BY flg_status, name;
            ELSE
                OPEN o_dcs_list FOR
                --Most Frequent Analysis
                    SELECT a.id_analysis id,
                           pk_translation.get_translation(i_lang, a.code_analysis) name,
                           g_status_a flg_status
                      FROM analysis a, analysis_dep_clin_serv adcs, analysis_instit_soft ais1
                     WHERE adcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND adcs.id_software = i_id_software
                       AND adcs.id_analysis = a.id_analysis
                       AND ais1.id_analysis = a.id_analysis
                       AND ais1.flg_type IN ('P', 'W')
                       AND ais1.id_institution = i_id_institution
                       AND ais1.id_software = i_id_software
                       AND translate(upper(pk_translation.get_translation(i_lang, a.code_analysis)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                       AND a.flg_available = 'Y'
                       AND adcs.flg_available = 'Y'
                       AND ais1.flg_available = 'Y'
                    UNION
                    --Analysis not Most Frequent
                    SELECT a.id_analysis id,
                           pk_translation.get_translation(i_lang, a.code_analysis) name,
                           
                           g_status_i flg_status
                      FROM analysis a, analysis_instit_soft ais
                     WHERE a.id_analysis NOT IN (SELECT a.id_analysis
                                                   FROM analysis a, analysis_dep_clin_serv adcs
                                                  WHERE adcs.id_dep_clin_serv = i_id_dep_clin_serv
                                                    AND adcs.id_software = i_id_software
                                                    AND adcs.id_analysis = a.id_analysis)
                       AND a.id_analysis = ais.id_analysis
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_id_software
                       AND ais.flg_type IN ('P', 'W')
                       AND translate(upper(pk_translation.get_translation(i_lang, a.code_analysis)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                       AND a.flg_available = 'Y'
                       AND ais.flg_available = 'Y'
                     ORDER BY flg_status, name;
            END IF;
        
        ELSIF i_context = 'G'
        THEN
            IF i_search IS NULL
            THEN
            
                OPEN o_dcs_list FOR
                --Most frequent Analysis Group
                    SELECT ag.id_analysis_group id,
                           pk_translation.get_translation(i_lang, ag.code_analysis_group) name,
                           g_status_a flg_status
                      FROM analysis_dep_clin_serv adcs, analysis_group ag, analysis_instit_soft ais1
                     WHERE adcs.id_analysis_group = ag.id_analysis_group
                       AND adcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND adcs.id_software = i_id_software
                       AND adcs.flg_available = 'Y'
                       AND ais1.id_analysis_group = ag.id_analysis_group
                       AND ais1.flg_type IN ('P', 'W')
                       AND ais1.id_institution = i_id_institution
                       AND ais1.id_software = i_id_software
                       AND ais1.flg_available = 'Y'
                    
                    UNION
                    --Analyis Group not Most Frequent
                    SELECT ag.id_analysis_group id,
                           pk_translation.get_translation(i_lang, ag.code_analysis_group) name,
                           g_status_i flg_status
                      FROM analysis_group ag, analysis_instit_soft ais
                     WHERE ag.id_analysis_group NOT IN
                           (SELECT adcs.id_analysis_group
                              FROM analysis_dep_clin_serv adcs, analysis_group ag
                             WHERE adcs.id_analysis_group = ag.id_analysis_group
                               AND adcs.id_dep_clin_serv = i_id_dep_clin_serv
                               AND adcs.id_software = i_id_software)
                       AND ag.id_analysis_group = ais.id_analysis_group
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_id_software
                       AND ais.flg_type IN ('P', 'W')
                       AND ais.flg_available = 'Y'
                     ORDER BY flg_status, name;
            ELSE
                OPEN o_dcs_list FOR
                --Most frequent Analysis Group
                    SELECT ag.id_analysis_group id,
                           pk_translation.get_translation(i_lang, ag.code_analysis_group) name,
                           g_status_a flg_status
                      FROM analysis_dep_clin_serv adcs, analysis_group ag, analysis_instit_soft ais1
                     WHERE adcs.id_analysis_group = ag.id_analysis_group
                       AND adcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND adcs.id_software = i_id_software
                       AND ais1.id_analysis_group = ag.id_analysis_group
                       AND ais1.flg_type IN ('P', 'W')
                       AND ais1.id_institution = i_id_institution
                       AND ais1.id_software = i_id_software
                          
                       AND translate(upper(pk_translation.get_translation(i_lang, ag.code_analysis_group)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                       AND adcs.flg_available = 'Y'
                       AND ais1.flg_available = 'Y'
                    UNION
                    --Analyis Group not Most Frequent
                    SELECT ag.id_analysis_group id,
                           pk_translation.get_translation(i_lang, ag.code_analysis_group) name,
                           g_status_i flg_status
                      FROM analysis_group ag, analysis_instit_soft ais
                     WHERE ag.id_analysis_group NOT IN
                           (SELECT adcs.id_analysis_group
                              FROM analysis_dep_clin_serv adcs, analysis_group ag
                             WHERE adcs.id_analysis_group = ag.id_analysis_group
                               AND adcs.id_dep_clin_serv = i_id_dep_clin_serv
                               AND adcs.id_software = i_id_software)
                       AND ag.id_analysis_group = ais.id_analysis_group
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_id_software
                       AND ais.flg_type IN ('P', 'W')
                       AND translate(upper(pk_translation.get_translation(i_lang, ag.code_analysis_group)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                       AND ais.flg_available = 'Y'
                     ORDER BY flg_status, name;
            
            END IF;
        
        ELSIF i_context = 'I'
        THEN
            IF i_search IS NULL
            THEN
                OPEN o_dcs_list FOR
                --Most Frequent Image Exams
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) name,
                           g_status_a flg_status
                      FROM exam e, exam_dep_clin_serv edcs, exam_dep_clin_serv edcs1
                     WHERE edcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND edcs.id_software = i_id_software
                       AND edcs.flg_type = 'M'
                       AND edcs.id_exam = e.id_exam
                       AND e.flg_type = 'I'
                       AND e.flg_available = 'Y'
                       AND edcs1.id_exam = e.id_exam
                       AND edcs1.flg_type = 'P'
                       AND edcs1.id_institution = i_id_institution
                       AND edcs1.id_software = i_id_software
                    UNION
                    --Image Exams not Most Frequent
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) name,
                           g_status_i flg_status
                      FROM exam e, exam_dep_clin_serv edcs
                     WHERE e.id_exam NOT IN (SELECT e2.id_exam
                                               FROM exam e2, exam_dep_clin_serv edcs2
                                              WHERE edcs2.id_dep_clin_serv = i_id_dep_clin_serv
                                                AND edcs2.id_software = i_id_software
                                                AND edcs2.flg_type = 'M'
                                                AND edcs2.id_exam = e2.id_exam
                                                AND e2.flg_type = 'I')
                       AND e.flg_type = 'I'
                       AND e.flg_available = 'Y'
                       AND e.id_exam = edcs.id_exam
                       AND edcs.flg_type = 'P'
                       AND edcs.id_institution = i_id_institution
                       AND edcs.id_software = i_id_software
                     ORDER BY flg_status, name;
            ELSE
                OPEN o_dcs_list FOR
                --Most Frequent Image Exams
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) name,
                           g_status_a flg_status
                      FROM exam e, exam_dep_clin_serv edcs, exam_dep_clin_serv edcs1
                     WHERE edcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND edcs.id_software = i_id_software
                       AND edcs.flg_type = 'M'
                       AND edcs.id_exam = e.id_exam
                       AND e.flg_type = 'I'
                       AND e.flg_available = 'Y'
                       AND edcs1.id_exam = e.id_exam
                       AND edcs1.flg_type = 'P'
                       AND edcs1.id_institution = i_id_institution
                       AND edcs1.id_software = i_id_software
                       AND translate(upper(pk_translation.get_translation(i_lang, e.code_exam)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                    UNION
                    --Image Exams not Most Frequent
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) name,
                           g_status_i flg_status
                      FROM exam e, exam_dep_clin_serv edcs
                     WHERE e.id_exam NOT IN (SELECT e2.id_exam
                                               FROM exam e2, exam_dep_clin_serv edcs2
                                              WHERE edcs2.id_dep_clin_serv = i_id_dep_clin_serv
                                                AND edcs2.id_software = i_id_software
                                                AND edcs2.flg_type = 'M'
                                                AND edcs2.id_exam = e2.id_exam
                                                AND e2.flg_type = 'I')
                       AND e.flg_type = 'I'
                       AND e.flg_available = 'Y'
                       AND e.id_exam = edcs.id_exam
                       AND edcs.flg_type = 'P'
                       AND edcs.id_institution = i_id_institution
                       AND edcs.id_software = i_id_software
                       AND translate(upper(pk_translation.get_translation(i_lang, e.code_exam)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY flg_status, name;
            END IF;
        
        ELSIF i_context = 'O'
        THEN
            IF i_search IS NULL
            THEN
                OPEN o_dcs_list FOR
                --Other Exams Most Frequent
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) name,
                           g_status_a flg_status
                      FROM exam e, exam_dep_clin_serv edcs, exam_dep_clin_serv edcs1
                     WHERE edcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND edcs.id_software = i_id_software
                       AND edcs.flg_type = 'M'
                       AND edcs.id_exam = e.id_exam
                       AND e.flg_type != 'I'
                       AND e.flg_available = 'Y'
                       AND edcs1.id_exam = e.id_exam
                       AND edcs1.flg_type = 'P'
                       AND edcs1.id_institution = i_id_institution
                       AND edcs1.id_software = i_id_software
                    
                    UNION
                    --Other Exams not Most Frequent
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) name,
                           g_status_i flg_status
                      FROM exam e, exam_dep_clin_serv edcs
                     WHERE e.id_exam NOT IN (SELECT e2.id_exam
                                               FROM exam e2, exam_dep_clin_serv edcs2
                                              WHERE edcs2.id_dep_clin_serv = i_id_dep_clin_serv
                                                AND edcs2.id_software = i_id_software
                                                AND edcs2.flg_type = 'M'
                                                AND edcs2.id_exam = e2.id_exam
                                                AND e2.flg_type != 'I'
                                                AND e.flg_available = 'Y')
                       AND e.flg_type != 'I'
                       AND e.flg_available = 'Y'
                       AND e.id_exam = edcs.id_exam
                       AND edcs.flg_type = 'P'
                       AND edcs.id_institution = i_id_institution
                       AND edcs.id_software = i_id_software
                     ORDER BY flg_status, name;
            ELSE
                OPEN o_dcs_list FOR
                --Other Exams Most Frequent
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) name,
                           g_status_a flg_status
                      FROM exam e, exam_dep_clin_serv edcs, exam_dep_clin_serv edcs1
                     WHERE edcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND edcs.id_software = i_id_software
                       AND edcs.flg_type = 'M'
                       AND edcs.id_exam = e.id_exam
                       AND e.flg_type != 'I'
                       AND e.flg_available = 'Y'
                       AND edcs1.id_exam = e.id_exam
                       AND edcs1.flg_type = 'P'
                       AND edcs1.id_institution = i_id_institution
                       AND edcs1.id_software = i_id_software
                       AND translate(upper(pk_translation.get_translation(i_lang, e.code_exam)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                    UNION
                    --Other Exams not Most Frequent
                    SELECT e.id_exam id,
                           pk_translation.get_translation(i_lang, e.code_exam) name,
                           g_status_i flg_status
                      FROM exam e, exam_dep_clin_serv edcs
                     WHERE e.id_exam NOT IN (SELECT e2.id_exam
                                               FROM exam e2, exam_dep_clin_serv edcs2
                                              WHERE edcs2.id_dep_clin_serv = i_id_dep_clin_serv
                                                AND edcs2.id_software = i_id_software
                                                AND edcs2.flg_type = 'M'
                                                AND edcs2.id_exam = e2.id_exam
                                                AND e2.flg_type != 'I'
                                                AND e.flg_available = 'Y')
                       AND e.flg_type != 'I'
                       AND e.id_exam = edcs.id_exam
                       AND e.flg_available = 'Y'
                       AND edcs.flg_type = 'P'
                       AND edcs.id_institution = i_id_institution
                       AND edcs.id_software = i_id_software
                       AND translate(upper(pk_translation.get_translation(i_lang, e.code_exam)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY flg_status, name;
            END IF;
        
        ELSIF i_context = 'P'
        THEN
            IF i_search IS NULL
            THEN
                OPEN o_dcs_list FOR
                --Interventions Most Frequent
                    SELECT i.id_intervention id,
                           pk_translation.get_translation(i_lang, i.code_intervention) name,
                           g_status_a flg_status
                      FROM intervention i, interv_dep_clin_serv idcs, interv_dep_clin_serv idcs1
                     WHERE idcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND idcs.id_software = i_id_software
                       AND idcs.flg_type = 'M'
                       AND idcs.id_intervention = i.id_intervention
                       AND i.flg_status = 'A'
                       AND idcs1.id_intervention = i.id_intervention
                       AND idcs1.flg_type = 'P'
                       AND idcs1.id_institution = i_id_institution
                       AND idcs1.id_software = i_id_software
                    
                    UNION
                    --Interventions not Most Frequent
                    SELECT i.id_intervention id,
                           pk_translation.get_translation(i_lang, i.code_intervention) name,
                           g_status_i flg_status
                      FROM intervention i, interv_dep_clin_serv idcs
                     WHERE i.id_intervention NOT IN (SELECT i2.id_intervention
                                                       FROM intervention i2, interv_dep_clin_serv idcs2
                                                      WHERE idcs2.id_dep_clin_serv = i_id_dep_clin_serv
                                                        AND idcs2.id_software = i_id_software
                                                        AND idcs2.flg_type = 'M'
                                                        AND idcs2.id_intervention = i2.id_intervention
                                                        AND i2.flg_status = 'A')
                       AND i.flg_status = 'A'
                       AND i.id_intervention = idcs.id_intervention
                       AND idcs.flg_type = 'P'
                       AND idcs.id_institution = i_id_institution
                       AND idcs.id_software = i_id_software
                     ORDER BY flg_status, name;
            ELSE
                OPEN o_dcs_list FOR
                --Interventions Most Frequent
                    SELECT i.id_intervention id,
                           pk_translation.get_translation(i_lang, i.code_intervention) name,
                           g_status_a flg_status
                      FROM intervention i, interv_dep_clin_serv idcs, interv_dep_clin_serv idcs1
                     WHERE idcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND idcs.id_software = i_id_software
                       AND idcs.flg_type = 'M'
                       AND idcs.id_intervention = i.id_intervention
                       AND i.flg_status = 'A'
                       AND idcs1.id_intervention = i.id_intervention
                       AND idcs1.flg_type = 'P'
                       AND idcs1.id_institution = i_id_institution
                       AND idcs1.id_software = i_id_software
                          
                       AND translate(upper(pk_translation.get_translation(i_lang, i.code_intervention)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                    UNION
                    --Interventions not Most Frequent
                    SELECT i.id_intervention id,
                           pk_translation.get_translation(i_lang, i.code_intervention) name,
                           g_status_i flg_status
                      FROM intervention i, interv_dep_clin_serv idcs
                     WHERE i.id_intervention NOT IN (SELECT i2.id_intervention
                                                       FROM intervention i2, interv_dep_clin_serv idcs2
                                                      WHERE idcs2.id_dep_clin_serv = i_id_dep_clin_serv
                                                        AND idcs2.id_software = i_id_software
                                                        AND idcs2.flg_type = 'M'
                                                        AND idcs2.id_intervention = i2.id_intervention
                                                        AND i2.flg_status = 'A')
                       AND i.flg_status = 'A'
                       AND i.id_intervention = idcs.id_intervention
                       AND idcs.flg_type = 'P'
                       AND idcs.id_institution = i_id_institution
                       AND idcs.id_software = i_id_software
                       AND translate(upper(pk_translation.get_translation(i_lang, i.code_intervention)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY flg_status, name;
            END IF;
        
        ELSIF i_context = 'D'
        THEN
            IF i_id_diagnosis IS NULL
            THEN
                IF i_search IS NULL
                THEN
                    OPEN o_dcs_list FOR
                    -- Most Frequent Diagnoses
                        SELECT aux.id_diagnosis id,
                               pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                          i_prof               => profissional(id          => -1,
                                                                                               institution => i_id_institution,
                                                                                               software    => i_id_software),
                                                          i_id_alert_diagnosis => aux.id_alert_diagnosis,
                                                          i_id_diagnosis       => aux.id_diagnosis,
                                                          i_code               => aux.code_icd,
                                                          i_flg_other          => aux.flg_other,
                                                          i_flg_std_diag       => aux.flg_icd9) name,
                               g_status_a flg_status,
                               aux.flg_select
                          FROM (SELECT dc1.id_diagnosis,
                                       dc1.id_alert_diagnosis,
                                       dc1.code_icd,
                                       dc1.flg_other,
                                       dc1.flg_icd9,
                                       dc1.flg_select
                                  FROM diagnosis_content dc1
                                 WHERE dc1.id_dep_clin_serv = i_id_dep_clin_serv
                                   AND dc1.code_alert_diagnosis IS NOT NULL
                                   AND dc1.id_software = i_id_software
                                   AND dc1.flg_type_dep_clin = 'M'
                                   AND dc1.flg_available = pk_alert_constant.g_yes
                                   AND dc1.flg_select != 'M') aux
                          JOIN diagnosis d
                            ON d.id_diagnosis = aux.id_diagnosis
                         WHERE d.id_diagnosis_parent IS NULL
                        UNION
                        -- Searchable Diagnoses
                        SELECT dc2.id_diagnosis id,
                               pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                          i_prof               => profissional(id          => -1,
                                                                                               institution => i_id_institution,
                                                                                               software    => i_id_software),
                                                          i_id_alert_diagnosis => dc2.id_alert_diagnosis,
                                                          i_id_diagnosis       => dc2.id_diagnosis,
                                                          i_code               => dc2.code_icd,
                                                          i_flg_other          => dc2.flg_other,
                                                          i_flg_std_diag       => dc2.flg_icd9) name,
                               g_status_i flg_status,
                               dc2.flg_select
                          FROM diagnosis_content dc2
                         WHERE dc2.flg_type_dep_clin = 'P'
                           AND dc2.id_institution = i_id_institution
                           AND dc2.id_software = i_id_software
                           AND dc2.flg_select != 'M'
                           AND dc2.code_alert_diagnosis IS NOT NULL
                         ORDER BY flg_status, name;
                ELSE
                    OPEN o_dcs_list FOR
                        SELECT id, name, flg_status, flg_select
                          FROM ( --Diagnosis Most Frequent
                                SELECT aux.id_diagnosis id,
                                        pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                   i_prof               => profissional(id          => -1,
                                                                                                        institution => i_id_institution,
                                                                                                        software    => i_id_software),
                                                                   i_id_alert_diagnosis => aux.id_alert_diagnosis,
                                                                   i_id_diagnosis       => aux.id_diagnosis,
                                                                   i_code               => aux.code_icd,
                                                                   i_flg_other          => aux.flg_other,
                                                                   i_flg_std_diag       => aux.flg_icd9) name,
                                        g_status_a flg_status,
                                        aux.flg_select
                                  FROM (SELECT dc1.id_diagnosis,
                                                dc1.id_alert_diagnosis,
                                                dc1.code_icd,
                                                dc1.flg_other,
                                                dc1.flg_icd9,
                                                dc1.flg_select
                                           FROM diagnosis_content dc1
                                          WHERE dc1.id_dep_clin_serv = i_id_dep_clin_serv
                                            AND dc1.code_alert_diagnosis IS NOT NULL
                                            AND dc1.id_software = i_id_software
                                            AND dc1.flg_type_dep_clin = 'M'
                                            AND dc1.flg_available = pk_alert_constant.g_yes
                                            AND dc1.flg_select != 'M') aux
                                  JOIN diagnosis d
                                    ON d.id_diagnosis = aux.id_diagnosis
                                 WHERE d.id_diagnosis_parent IS NULL
                                UNION
                                -- Searchable Diagnoses
                                SELECT dc2.id_diagnosis id,
                                        pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                   i_prof               => profissional(id          => -1,
                                                                                                        institution => i_id_institution,
                                                                                                        software    => i_id_software),
                                                                   i_id_alert_diagnosis => dc2.id_alert_diagnosis,
                                                                   i_id_diagnosis       => dc2.id_diagnosis,
                                                                   i_code               => dc2.code_icd,
                                                                   i_flg_other          => dc2.flg_other,
                                                                   i_flg_std_diag       => dc2.flg_icd9) name,
                                        g_status_i flg_status,
                                        dc2.flg_select
                                  FROM diagnosis_content dc2
                                 WHERE dc2.flg_type_dep_clin = 'P'
                                   AND dc2.id_institution = i_id_institution
                                   AND dc2.id_software = i_id_software
                                   AND dc2.flg_select != 'M'
                                   AND dc2.code_alert_diagnosis IS NOT NULL) diags
                         WHERE translate(upper(diags.name), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                         ORDER BY flg_status, name;
                END IF;
            
            ELSE
                IF i_search IS NULL
                THEN
                    OPEN o_dcs_list FOR
                        SELECT aux.id_diagnosis id,
                               pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                          i_prof               => profissional(id          => -1,
                                                                                               institution => i_id_institution,
                                                                                               software    => i_id_software),
                                                          i_id_alert_diagnosis => aux.id_alert_diagnosis,
                                                          i_id_diagnosis       => aux.id_diagnosis,
                                                          i_code               => aux.code_icd,
                                                          i_flg_other          => aux.flg_other,
                                                          i_flg_std_diag       => aux.flg_icd9) name,
                               g_status_a flg_status,
                               aux.flg_select
                          FROM (SELECT dc1.id_diagnosis,
                                       dc1.id_alert_diagnosis,
                                       dc1.code_icd,
                                       dc1.flg_other,
                                       dc1.flg_icd9,
                                       dc1.flg_select
                                  FROM diagnosis_content dc1
                                 WHERE dc1.id_dep_clin_serv = i_id_dep_clin_serv
                                   AND dc1.code_alert_diagnosis IS NOT NULL
                                   AND dc1.id_software = i_id_software
                                   AND dc1.flg_type_dep_clin = 'M'
                                   AND dc1.flg_available = pk_alert_constant.g_yes
                                   AND dc1.flg_select != 'M') aux
                          JOIN diagnosis d
                            ON d.id_diagnosis = aux.id_diagnosis
                         WHERE d.id_diagnosis_parent = i_id_diagnosis
                        UNION
                        -- Searchable Diagnoses
                        SELECT dc2.id_diagnosis id,
                               pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                          i_prof               => profissional(id          => -1,
                                                                                               institution => i_id_institution,
                                                                                               software    => i_id_software),
                                                          i_id_alert_diagnosis => dc2.id_alert_diagnosis,
                                                          i_id_diagnosis       => dc2.id_diagnosis,
                                                          i_code               => dc2.code_icd,
                                                          i_flg_other          => dc2.flg_other,
                                                          i_flg_std_diag       => dc2.flg_icd9) name,
                               g_status_i flg_status,
                               dc2.flg_select
                          FROM diagnosis_content dc2
                         WHERE dc2.flg_type_dep_clin = 'P'
                           AND dc2.id_institution = i_id_institution
                           AND dc2.id_software = i_id_software
                           AND dc2.flg_select != 'M'
                           AND dc2.code_alert_diagnosis IS NOT NULL
                           AND dc2.id_diagnosis_parent = i_id_diagnosis
                         ORDER BY flg_status, name;
                ELSE
                    OPEN o_dcs_list FOR
                        SELECT id, name, flg_status, flg_select
                          FROM ( --Diagnosis Most Frequent
                                SELECT aux.id_diagnosis id,
                                        pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                   i_prof               => profissional(id          => -1,
                                                                                                        institution => i_id_institution,
                                                                                                        software    => i_id_software),
                                                                   i_id_alert_diagnosis => aux.id_alert_diagnosis,
                                                                   i_id_diagnosis       => aux.id_diagnosis,
                                                                   i_code               => aux.code_icd,
                                                                   i_flg_other          => aux.flg_other,
                                                                   i_flg_std_diag       => aux.flg_icd9) name,
                                        g_status_a flg_status,
                                        aux.flg_select
                                  FROM (SELECT dc1.id_diagnosis,
                                                dc1.id_alert_diagnosis,
                                                dc1.code_icd,
                                                dc1.flg_other,
                                                dc1.flg_icd9,
                                                dc1.flg_select
                                           FROM diagnosis_content dc1
                                          WHERE dc1.id_dep_clin_serv = i_id_dep_clin_serv
                                            AND dc1.code_alert_diagnosis IS NOT NULL
                                            AND dc1.id_software = i_id_software
                                            AND dc1.flg_type_dep_clin = 'M'
                                            AND dc1.flg_available = pk_alert_constant.g_yes
                                            AND dc1.flg_select != 'M') aux
                                  JOIN diagnosis d
                                    ON d.id_diagnosis = aux.id_diagnosis
                                 WHERE d.id_diagnosis_parent = i_id_diagnosis
                                UNION
                                -- Searchable Diagnoses
                                SELECT dc2.id_diagnosis id,
                                        pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                   i_prof               => profissional(id          => -1,
                                                                                                        institution => i_id_institution,
                                                                                                        software    => i_id_software),
                                                                   i_id_alert_diagnosis => dc2.id_alert_diagnosis,
                                                                   i_id_diagnosis       => dc2.id_diagnosis,
                                                                   i_code               => dc2.code_icd,
                                                                   i_flg_other          => dc2.flg_other,
                                                                   i_flg_std_diag       => dc2.flg_icd9) name,
                                        g_status_i flg_status,
                                        dc2.flg_select
                                  FROM diagnosis_content dc2
                                 WHERE dc2.flg_type_dep_clin = 'P'
                                   AND dc2.id_institution = i_id_institution
                                   AND dc2.id_software = i_id_software
                                   AND dc2.flg_select != 'M'
                                   AND dc2.id_diagnosis_parent = i_id_diagnosis
                                   AND dc2.code_alert_diagnosis IS NOT NULL) diags
                         WHERE translate(upper(diags.name), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                         ORDER BY flg_status, name;
                END IF;
            
            END IF;
        
        ELSIF i_context = 'ME'
        THEN
            --External Medication
            OPEN o_dcs_list FOR
                SELECT mm.emb_id id
                  FROM me_med mm, emb_dep_clin_serv edcs
                 WHERE edcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND edcs.id_software = i_id_software
                   AND edcs.flg_type = 'M'
                   AND edcs.emb_id = mm.emb_id
                   AND mm.flg_available = 'Y'
                 ORDER BY id;
        ELSIF i_context = 'MI'
        THEN
            --Internal Medication
            OPEN o_dcs_list FOR
                SELECT mm.id_drug id
                  FROM mi_med mm, drug_dep_clin_serv ddcs
                 WHERE ddcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND ddcs.id_software = i_id_software
                   AND ddcs.flg_type = 'M'
                   AND ddcs.id_drug = mm.id_drug
                   AND mm.flg_type = 'M'
                   AND mm.flg_available = 'Y'
                 ORDER BY id;
        ELSIF i_context = 'MA'
        THEN
            --Manipulated 
            OPEN o_dcs_list FOR
                SELECT mm.id_manipulated id
                  FROM me_manip mm, emb_dep_clin_serv edcs
                 WHERE edcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND edcs.id_software = i_id_software
                   AND edcs.flg_type = 'M'
                   AND edcs.id_manipulated = mm.id_manipulated
                   AND mm.flg_available = 'Y'
                 ORDER BY id;
        ELSIF i_context = 'DE'
        THEN
            -- Dietary
            OPEN o_dcs_list FOR
            
                SELECT DISTINCT md.id_dietary_drug id
                  FROM me_dietary md, emb_dep_clin_serv edcs
                 WHERE edcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND edcs.id_dietary_drug = md.id_dietary_drug
                   AND md.flg_available = 'Y'
                   AND md.id_dietary_drug != -1
                   AND md.dietary_descr IS NOT NULL
                   AND edcs.id_software = i_id_software
                 ORDER BY id;
        
        ELSIF i_context = 'S'
        THEN
            --Simple Parenteric Solutions
            OPEN o_dcs_list FOR
                SELECT mm.id_drug id
                  FROM mi_med mm, drug_dep_clin_serv ddcs
                 WHERE ddcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND ddcs.id_software = i_id_software
                   AND ddcs.flg_type = 'M'
                   AND ddcs.id_drug = mm.id_drug
                   AND mm.flg_type = 'F'
                      
                   AND mm.flg_available = 'Y'
                 ORDER BY id;
        
        ELSIF i_context = 'SC'
        THEN
            --Parenteric Solutions most frequent constructed
            OPEN o_dcs_list FOR
                SELECT mm.id_drug id
                  FROM mi_med mm, drug_dep_clin_serv ddcs
                 WHERE ddcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND ddcs.id_software = i_id_software
                   AND ddcs.flg_type = 'M'
                   AND ddcs.id_drug = mm.id_drug
                   AND mm.flg_type = 'C'
                   AND mm.flg_available = 'Y'
                 ORDER BY id;
        ELSIF i_context = 'TP'
        THEN
            IF i_search IS NULL
            THEN
                OPEN o_dcs_list FOR
                --Therapeutic Protocols most Frequent
                    SELECT tp.id_therapeutic_protocols id,
                           pk_translation.get_translation(i_lang, tp.code_therapeutic_protocols) name,
                           g_status_a flg_status
                      FROM therapeutic_protocols tp, therapeutic_protocols_dcs tpdcs, therapeutic_protocols_dcs tpdcs1
                     WHERE tpdcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND tpdcs.id_software = i_id_software
                       AND tpdcs.flg_type = 'M'
                       AND tpdcs.id_therapeutic_protocols = tp.id_therapeutic_protocols
                       AND tp.flg_available = 'Y'
                       AND tpdcs1.flg_type = 'P'
                       AND tpdcs1.id_therapeutic_protocols = tp.id_therapeutic_protocols
                       AND tpdcs1.id_institution = i_id_institution
                       AND tpdcs1.id_software = i_id_software
                    UNION
                    --Therapeutic Protocols not most Frequent
                    SELECT tp.id_therapeutic_protocols id,
                           pk_translation.get_translation(i_lang, tp.code_therapeutic_protocols) name,
                           g_status_i flg_status
                      FROM therapeutic_protocols tp, therapeutic_protocols_dcs tpdcs
                     WHERE tp.id_therapeutic_protocols NOT IN
                           (SELECT tp2.id_therapeutic_protocols
                              FROM therapeutic_protocols tp2, therapeutic_protocols_dcs tpdcs2
                             WHERE tpdcs2.id_dep_clin_serv = i_id_dep_clin_serv
                               AND tpdcs2.id_software = i_id_software
                               AND tpdcs2.flg_type = 'M'
                               AND tpdcs2.id_therapeutic_protocols = tp2.id_therapeutic_protocols
                               AND tp2.flg_available = 'Y')
                       AND tp.flg_available = 'Y'
                       AND tpdcs.id_therapeutic_protocols = tp.id_therapeutic_protocols
                       AND tpdcs.flg_type = 'P'
                       AND tpdcs.id_institution = i_id_institution
                       AND tpdcs.id_software = i_id_software
                     ORDER BY flg_status, name;
            ELSE
                OPEN o_dcs_list FOR
                --Therapeutic Protocols most Frequent
                    SELECT tp.id_therapeutic_protocols id,
                           pk_translation.get_translation(i_lang, tp.code_therapeutic_protocols) name,
                           g_status_a flg_status
                      FROM therapeutic_protocols tp, therapeutic_protocols_dcs tpdcs, therapeutic_protocols_dcs tpdcs1
                     WHERE tpdcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND tpdcs.id_software = i_id_software
                       AND tpdcs.flg_type = 'M'
                       AND tpdcs.id_therapeutic_protocols = tp.id_therapeutic_protocols
                       AND tp.flg_available = 'Y'
                       AND tpdcs1.flg_type = 'P'
                       AND tpdcs1.id_therapeutic_protocols = tp.id_therapeutic_protocols
                       AND tpdcs1.id_institution = i_id_institution
                       AND tpdcs1.id_software = i_id_software
                       AND translate(upper(pk_translation.get_translation(i_lang, tp.code_therapeutic_protocols)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                    UNION
                    --Therapeutic Protocols not most Frequent
                    SELECT tp.id_therapeutic_protocols id,
                           pk_translation.get_translation(i_lang, tp.code_therapeutic_protocols) name,
                           g_status_i flg_status
                      FROM therapeutic_protocols tp, therapeutic_protocols_dcs tpdcs
                     WHERE tp.id_therapeutic_protocols NOT IN
                           (SELECT tp2.id_therapeutic_protocols
                              FROM therapeutic_protocols tp2, therapeutic_protocols_dcs tpdcs2
                             WHERE tpdcs2.id_dep_clin_serv = i_id_dep_clin_serv
                               AND tpdcs2.id_software = i_id_software
                               AND tpdcs2.flg_type = 'M'
                               AND tpdcs2.id_therapeutic_protocols = tp2.id_therapeutic_protocols
                               AND tp2.flg_available = 'Y')
                       AND tp.flg_available = 'Y'
                       AND tpdcs.id_therapeutic_protocols = tp.id_therapeutic_protocols
                       AND tpdcs.flg_type = 'P'
                       AND tpdcs.id_institution = i_id_institution
                       AND tpdcs.id_software = i_id_software
                       AND translate(upper(pk_translation.get_translation(i_lang, tp.code_therapeutic_protocols)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY flg_status, name;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_dcs_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_MY_ALERT_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_my_alert_list;

    /********************************************************************************************
    * My alert association
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param i_dep_clin_serv         Array of Department/Clinical Service ID's
    * @param i_context               Context
    * @param i_my_alert_id           Array of array of My Alert ID's
    * @param i_select                Array of array of Flags(Y - insert; N - delete)
    * @param o_error                 Error
    *
    *
    * @value     i_context          {*} 'A' Analyis {*} 'G' Analyis Group {*} 'I' Image exams {*} 'O' Others Exams 
                                     {*} 'P' Interventions  {*} 'D' Diagnosis {*} 'ME' External Medication 
                                     {*} 'MI' Internal Medication {*} 'MA' Manipulated {*} 'DE' Dietary 
                                     {*} 'S' Simple Parenteric Solutions {*} 'SC' Constructed Parenteric Solutions 
                                     {*} 'TP' Terapeutic Protocols
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/30
    ********************************************************************************************/
    FUNCTION set_my_alert
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_dep_clin_serv  IN table_number,
        i_context        IN VARCHAR2,
        i_my_alert_id    IN table_table_varchar,
        i_select         IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_my_alert_dep_clin_serv table_number := table_number();
        l_i                         NUMBER := 0;
    
        l_mcdt_analysis table_varchar2;
    
        l_rows_delidcs table_varchar;
        l_rows_insidcs table_varchar;
        l_rows_aux     table_varchar;
        l_error        t_error_out;
    BEGIN
    
        IF i_context = 'A'
        THEN
            --Analysis
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                    l_mcdt_analysis := pk_utils.str_split(i_my_alert_id(i) (j), '|');
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM ANALYSIS_DEP_CLIN_SERV';
                        DELETE FROM analysis_dep_clin_serv adcs
                         WHERE adcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND adcs.id_analysis = to_number(l_mcdt_analysis(1))
                           AND adcs.id_sample_type = to_number(l_mcdt_analysis(2))
                           AND adcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_ANALYSIS_GROUP.NEXTVAL';
                        SELECT seq_analysis_dep_clin_serv.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO ANALYSIS_DEP_CLIN_SERV';
                        INSERT INTO analysis_dep_clin_serv
                            (id_analysis_dep_clin_serv,
                             id_analysis,
                             id_sample_type,
                             id_dep_clin_serv,
                             rank,
                             id_software,
                             flg_available)
                        VALUES
                            (l_id_my_alert_dep_clin_serv(l_i),
                             to_number(l_mcdt_analysis(1)),
                             to_number(l_mcdt_analysis(2)),
                             i_dep_clin_serv(i),
                             0,
                             i_id_software,
                             'Y');
                    END IF;
                END LOOP;
            END LOOP;
        ELSIF i_context = 'G'
        THEN
            --Analysis Group
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM ANALYSIS_DEP_CLIN_SERV';
                        DELETE FROM analysis_dep_clin_serv adcs
                         WHERE adcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND adcs.id_analysis_group = to_number(i_my_alert_id(i) (j))
                           AND adcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_ANALYSIS_GROUP.NEXTVAL';
                        SELECT seq_analysis_dep_clin_serv.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO ANALYSIS_DEP_CLIN_SERV';
                        INSERT INTO analysis_dep_clin_serv
                            (id_analysis_dep_clin_serv,
                             id_dep_clin_serv,
                             rank,
                             id_software,
                             id_analysis_group,
                             flg_available)
                        VALUES
                            (l_id_my_alert_dep_clin_serv(l_i),
                             i_dep_clin_serv(i),
                             0,
                             i_id_software,
                             to_number(i_my_alert_id(i) (j)),
                             'Y');
                    
                    END IF;
                END LOOP;
            END LOOP;
        ELSIF i_context = 'I'
        THEN
            --Image Exams
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM EXAM_DEP_CLIN_SERV';
                        DELETE FROM exam_dep_clin_serv edcs
                         WHERE edcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND edcs.flg_type = 'M'
                           AND edcs.id_exam = to_number(i_my_alert_id(i) (j))
                           AND edcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_EXAM.NEXTVAL';
                        SELECT seq_exam_dep_clin_serv.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
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
                            (l_id_my_alert_dep_clin_serv(l_i),
                             to_number(i_my_alert_id(i) (j)),
                             i_dep_clin_serv(i),
                             'M',
                             0,
                             i_id_institution,
                             i_id_software);
                    
                    END IF;
                END LOOP;
            END LOOP;
        ELSIF i_context = 'O'
        THEN
            --Other Exams
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM EXAM_DEP_CLIN_SERV';
                        DELETE FROM exam_dep_clin_serv edcs
                         WHERE edcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND edcs.flg_type = 'M'
                           AND edcs.id_exam = to_number(i_my_alert_id(i) (j))
                           AND edcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_EXAM.NEXTVAL';
                        SELECT seq_exam_dep_clin_serv.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
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
                            (l_id_my_alert_dep_clin_serv(l_i),
                             to_number(i_my_alert_id(i) (j)),
                             i_dep_clin_serv(i),
                             'M',
                             0,
                             i_id_institution,
                             i_id_software);
                    
                    END IF;
                END LOOP;
            END LOOP;
        ELSIF i_context = 'P'
        THEN
            --Interventions
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM INTERV_DEP_CLIN_SERV';
                        ts_interv_dep_clin_serv.del_by(where_clause_in => 'id_dep_clin_serv = ' || i_dep_clin_serv(i) || '
                           AND flg_type = ''M''
                           AND id_intervention = ' ||
                                                                          to_number(i_my_alert_id(i) (j)) || '
                           AND id_software = ' ||
                                                                          i_id_software,
                                                       rows_out        => l_rows_aux);
                        l_rows_delidcs := l_rows_delidcs MULTISET UNION l_rows_aux;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'INSERT INTO INTERV_DEP_CLIN_SERV';
                        ts_interv_dep_clin_serv.ins(id_interv_dep_clin_serv_out => l_id_my_alert_dep_clin_serv(l_i),
                                                    id_intervention_in          => to_number(i_my_alert_id(i) (j)),
                                                    id_dep_clin_serv_in         => i_dep_clin_serv(i),
                                                    flg_type_in                 => 'M',
                                                    rank_in                     => 0,
                                                    id_institution_in           => i_id_institution,
                                                    id_software_in              => i_id_software,
                                                    rows_out                    => l_rows_aux);
                        l_rows_insidcs := l_rows_insidcs MULTISET UNION l_rows_aux;
                    
                    END IF;
                END LOOP;
            END LOOP;
            t_data_gov_mnt.process_delete(i_lang, i_prof, 'INTERV_DEP_CLIN_SERV', l_rows_delidcs, l_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'INTERV_DEP_CLIN_SERV', l_rows_insidcs, l_error);
        ELSIF i_context = 'D'
        THEN
            --Diagnosis
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM MSI_CONCEPT_TERM : CONCEPT_VERSION = ' ||
                                   to_number(i_my_alert_id(i) (j));
                        IF NOT pk_api_pfh_diagnosis_conf.del_msi_concept_term(i_institution     => i_id_institution,
                                                                              i_software        => i_id_software,
                                                                              i_concept_version => to_number(i_my_alert_id(i) (j)),
                                                                              i_concept_term    => NULL,
                                                                              i_dep_clin_serv   => i_dep_clin_serv(i),
                                                                              i_professional    => i_prof.id,
                                                                              i_flg_type        => 'M',
                                                                              i_flg_delete      => NULL)
                        THEN
                            RETURN FALSE;
                        END IF;
                    ELSE
                        g_error := 'INSERT INTO MSI_CONCEPT_TERM : CONCEPT_VERSION = ' ||
                                   to_number(i_my_alert_id(i) (j));
                        IF NOT pk_api_pfh_diagnosis_conf.ins_msi_concept_term(i_institution     => i_id_institution,
                                                                              i_software        => i_id_software,
                                                                              i_concept_version => to_number(i_my_alert_id(i) (j)),
                                                                              i_concept_term    => NULL,
                                                                              i_dep_clin_serv   => i_dep_clin_serv(i),
                                                                              i_professional    => i_prof.id,
                                                                              i_gender          => NULL,
                                                                              i_age_min         => NULL,
                                                                              i_age_max         => NULL,
                                                                              i_rank            => 0,
                                                                              i_flg_type        => 'M')
                        THEN
                            RETURN FALSE;
                        END IF;
                    END IF;
                END LOOP;
            END LOOP;
        ELSIF i_context = 'ME'
        THEN
            --External Medication
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM EMB_DEP_CLIN_SERV';
                        DELETE FROM emb_dep_clin_serv edcs
                         WHERE edcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND edcs.flg_type = 'M'
                           AND edcs.emb_id = i_my_alert_id(i) (j)
                           AND edcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_EMB_DEP_CLIN_SERV.NEXTVAL';
                        SELECT seq_emb_dep_clin_serv.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO EMB_DEP_CLIN_SERV';
                        INSERT INTO emb_dep_clin_serv
                            (id_emb_dep_clin_serv,
                             id_dep_clin_serv,
                             emb_id,
                             rank,
                             flg_type,
                             id_institution,
                             id_software)
                        VALUES
                            (l_id_my_alert_dep_clin_serv(l_i),
                             i_dep_clin_serv(i),
                             i_my_alert_id(i) (j),
                             0,
                             'M',
                             i_id_institution,
                             i_id_software);
                    
                    END IF;
                END LOOP;
            END LOOP;
        ELSIF i_context = 'MI'
        THEN
            --Internal Medication
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM DRUG_DEP_CLIN_SERV';
                        DELETE FROM drug_dep_clin_serv ddcs
                         WHERE ddcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_drug = i_my_alert_id(i) (j)
                           AND ddcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_DRUG_DEP_CLIN_SERV.NEXTVAL';
                        SELECT seq_drug_dep_clin_serv.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO DRUG_DEP_CLIN_SERV';
                        INSERT INTO drug_dep_clin_serv
                            (id_drug_dep_clin_serv,
                             id_dep_clin_serv,
                             id_drug,
                             rank,
                             flg_type,
                             id_institution,
                             id_software)
                        VALUES
                            (l_id_my_alert_dep_clin_serv(l_i),
                             i_dep_clin_serv(i),
                             i_my_alert_id(i) (j),
                             0,
                             'M',
                             i_id_institution,
                             i_id_software);
                    
                    END IF;
                END LOOP;
            END LOOP;
        
        ELSIF i_context = 'MA'
        THEN
            --Manipulated
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM EMB_DEP_CLIN_SERV';
                        DELETE FROM emb_dep_clin_serv edcs
                         WHERE edcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND edcs.flg_type = 'M'
                           AND edcs.id_manipulated = i_my_alert_id(i) (j)
                           AND edcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_EMB_DEP_CLIN_SERV.NEXTVAL';
                        SELECT seq_emb_dep_clin_serv.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO EMB_DEP_CLIN_SERV';
                        INSERT INTO emb_dep_clin_serv
                            (id_emb_dep_clin_serv,
                             id_dep_clin_serv,
                             id_manipulated,
                             rank,
                             flg_type,
                             id_institution,
                             id_software)
                        VALUES
                            (l_id_my_alert_dep_clin_serv(l_i),
                             i_dep_clin_serv(i),
                             i_my_alert_id(i) (j),
                             0,
                             'M',
                             i_id_institution,
                             i_id_software);
                    
                    END IF;
                END LOOP;
            END LOOP;
        
        ELSIF i_context = 'DE'
        THEN
            --Dietary
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM EMB_DEP_CLIN_SERV';
                        DELETE FROM emb_dep_clin_serv edcs
                         WHERE edcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND edcs.flg_type = 'M'
                           AND edcs.id_dietary_drug = i_my_alert_id(i) (j)
                           AND edcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_EMB_DEP_CLIN_SERV.NEXTVAL';
                        SELECT seq_emb_dep_clin_serv.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO EMB_DEP_CLIN_SERV';
                        INSERT INTO emb_dep_clin_serv
                            (id_emb_dep_clin_serv,
                             id_dep_clin_serv,
                             id_dietary_drug,
                             rank,
                             flg_type,
                             id_institution,
                             id_software)
                        VALUES
                            (l_id_my_alert_dep_clin_serv(l_i),
                             i_dep_clin_serv(i),
                             i_my_alert_id(i) (j),
                             0,
                             'M',
                             i_id_institution,
                             i_id_software);
                    
                    END IF;
                END LOOP;
            END LOOP;
        
        ELSIF i_context = 'S'
        THEN
            --Simple Parenteric Solutions
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM DRUG_DEP_CLIN_SERV';
                        DELETE FROM drug_dep_clin_serv ddcs
                         WHERE ddcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_drug = i_my_alert_id(i) (j)
                           AND ddcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_DRUG_DEP_CLIN_SERV.NEXTVAL';
                        SELECT seq_drug_dep_clin_serv.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO DRUG_DEP_CLIN_SERV';
                        INSERT INTO drug_dep_clin_serv
                            (id_drug_dep_clin_serv,
                             id_dep_clin_serv,
                             id_drug,
                             rank,
                             flg_type,
                             id_institution,
                             id_software)
                        VALUES
                            (l_id_my_alert_dep_clin_serv(l_i),
                             i_dep_clin_serv(i),
                             i_my_alert_id(i) (j),
                             0,
                             'M',
                             i_id_institution,
                             i_id_software);
                    
                    END IF;
                END LOOP;
            END LOOP;
        
        ELSIF i_context = 'SC'
        THEN
            --Parenteric Solutions most frequent constructed
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM DRUG_DEP_CLIN_SERV';
                        DELETE FROM drug_dep_clin_serv ddcs
                         WHERE ddcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_drug = i_my_alert_id(i) (j)
                           AND ddcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_DRUG_DEP_CLIN_SERV.NEXTVAL';
                        SELECT seq_drug_dep_clin_serv.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO DRUG_DEP_CLIN_SERV';
                        INSERT INTO drug_dep_clin_serv
                            (id_drug_dep_clin_serv,
                             id_dep_clin_serv,
                             id_drug,
                             rank,
                             flg_type,
                             id_institution,
                             id_software)
                        VALUES
                            (l_id_my_alert_dep_clin_serv(l_i),
                             i_dep_clin_serv(i),
                             i_my_alert_id(i) (j),
                             0,
                             'M',
                             i_id_institution,
                             i_id_software);
                    
                    END IF;
                END LOOP;
            END LOOP;
        ELSIF i_context = 'TP'
        THEN
            --Terapeutic Protocols
            FOR i IN 1 .. i_dep_clin_serv.count
            LOOP
                FOR j IN 1 .. i_my_alert_id(i).count
                LOOP
                
                    IF i_select(i) (j) = 'N'
                    THEN
                        g_error := 'DELETE FROM THERAPEUTIC_PROTOCOLS_DCS';
                        DELETE FROM therapeutic_protocols_dcs tpdcs
                         WHERE tpdcs.id_dep_clin_serv = i_dep_clin_serv(i)
                           AND tpdcs.flg_type = 'M'
                           AND tpdcs.id_therapeutic_protocols = to_number(i_my_alert_id(i) (j))
                           AND tpdcs.id_software = i_id_software;
                    ELSE
                        l_id_my_alert_dep_clin_serv.extend;
                        l_i := l_i + 1;
                    
                        g_error := 'GET SEQ_THERAPEUTIC_PROTOCOLS_DCS.NEXTVAL';
                        SELECT seq_therapeutic_protocols_dcs.nextval
                          INTO l_id_my_alert_dep_clin_serv(l_i)
                          FROM dual;
                    
                        g_error := 'INSERT INTO THERAPEUTIC_PROTOCOLS_DCS';
                        INSERT INTO therapeutic_protocols_dcs
                            (id_therapeutic_protocols_dcs,
                             id_dep_clin_serv,
                             id_therapeutic_protocols,
                             rank,
                             flg_type,
                             id_institution,
                             id_software)
                        VALUES
                            (l_id_my_alert_dep_clin_serv(l_i),
                             i_dep_clin_serv(i),
                             to_number(i_my_alert_id(i) (j)),
                             0,
                             'M',
                             i_id_institution,
                             i_id_software);
                    
                    END IF;
                END LOOP;
            END LOOP;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error || ' / ' || l_error.err_desc,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_MY_ALERT');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_my_alert;

    /********************************************************************************************
    * Get Institution Searchable List
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_software              Software ID's
    * @param i_context               Context
    * @param i_search                Search filter
    * @param o_inst_pesq_list        List
    * @param o_error                 Error
    *
    *
    * @value     i_context          {*} 'A' Analyis {*} 'I' Image exams {*} 'O' Others Exams {*} 'P' Interventions   
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/06
    ********************************************************************************************/
    FUNCTION get_inst_pesq_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_context        IN VARCHAR2,
        i_search         IN VARCHAR2,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market NUMBER(24);
    
    BEGIN
    
        SELECT decode((SELECT i.id_market
                        FROM institution i
                       WHERE i.id_institution = i_id_institution),
                      NULL,
                      (nvl((SELECT cm.id_market
                             FROM country_market cm
                            WHERE cm.id_country = (SELECT ia.id_country
                                                     FROM inst_attributes ia
                                                    WHERE ia.id_institution = i_id_institution)
                              AND cm.flg_active = 'Y'),
                           0)),
                      (SELECT i.id_market
                         FROM institution i
                        WHERE i.id_institution = i_id_institution))
          INTO l_id_market
          FROM dual;
    
        IF i_context = 'A'
        THEN
            g_error := 'GET INST_ANALYSIS_LIST CURSOR';
            OPEN o_inst_pesq_list FOR
                SELECT /*+use_nl (t aux)*/
                 aux.id_analysis id,
                 pk_translation.get_translation(i_lang, aux.code_analysis) name_aux,
                 pk_translation.get_translation(i_lang, aux.code_analysis) || ' / ' ||
                 pk_translation.get_translation(i_lang, aux.code_sample_type) name,
                 get_inst_pesq_state(i_lang, i_id_institution, aux.id_analysis, i_software, i_context) values_desc,
                 decode((get_missing_data(i_lang, aux.id_analysis, i_id_institution, 0, i_context)), NULL, 'N', 'Y') flg_missing_data
                  FROM (SELECT /*+no_merge*/
                         *
                          FROM analysis a
                          JOIN sample_type st
                            ON a.id_sample_type = st.id_sample_type
                         WHERE a.flg_available = g_flg_available
                           AND st.flg_available = g_flg_available) aux
                 WHERE pk_translation.get_translation(i_lang, aux.code_analysis) IS NOT NULL
                 ORDER BY name;
        
        ELSIF i_context = 'I'
        THEN
        
            g_error := 'GET INST_IMAGE_EXAM_LIST CURSOR';
            OPEN o_inst_pesq_list FOR
                SELECT /*+use_nl (t aux)*/
                 aux.id_exam id,
                 pk_translation.get_translation(i_lang, aux.code_exam) name,
                 get_inst_pesq_state(i_lang, i_id_institution, aux.id_exam, i_software, i_context) values_desc,
                 decode((get_missing_data(i_lang, aux.id_exam, i_id_institution, 0, i_context)), NULL, 'N', 'Y') flg_missing_data
                  FROM (SELECT /*+no_merge*/
                         *
                          FROM exam e
                         WHERE e.flg_available = g_flg_available
                           AND e.flg_type = 'I') aux
                 WHERE pk_translation.get_translation(i_lang, aux.code_exam) IS NOT NULL
                 ORDER BY name;
        
        ELSIF i_context = 'O'
        THEN
            g_error := 'GET INST_OTHER_EXAM_LIST CURSOR';
            OPEN o_inst_pesq_list FOR
                SELECT /*+use_nl (t aux)*/
                 aux.id_exam id,
                 pk_translation.get_translation(i_lang, aux.code_exam) name,
                 get_inst_pesq_state(i_lang, i_id_institution, aux.id_exam, i_software, i_context) values_desc,
                 decode((get_missing_data(i_lang, aux.id_exam, i_id_institution, 0, i_context)), NULL, 'N', 'Y') flg_missing_data
                  FROM (SELECT /*+no_merge*/
                         *
                          FROM exam e
                         WHERE e.flg_available = g_flg_available
                           AND e.flg_type != 'I') aux
                 WHERE pk_translation.get_translation(i_lang, aux.code_exam) IS NOT NULL
                 ORDER BY name;
        
        ELSIF i_context = 'P'
        THEN
            g_error := 'GET INST_INTERVENTION_LIST CURSOR';
            OPEN o_inst_pesq_list FOR
                SELECT /*+use_nl (t aux)*/
                 aux.id_intervention id,
                 pk_translation.get_translation(i_lang, aux.code_intervention) name,
                 get_inst_pesq_state(i_lang, i_id_institution, aux.id_intervention, i_software, i_context) values_desc,
                 decode((get_missing_data(i_lang, aux.id_intervention, i_id_institution, 0, i_context)), NULL, 'N', 'Y') flg_missing_data
                  FROM (SELECT /*+no_merge*/
                         *
                          FROM intervention i
                         WHERE i.flg_status = 'A') aux
                 WHERE pk_translation.get_translation(i_lang, aux.code_intervention) IS NOT NULL
                 ORDER BY name;
        
            --MFR Interventions
        ELSIF i_context = 'M'
        THEN
            g_error := 'GET INST_INTERVENTION_LIST CURSOR';
            OPEN o_inst_pesq_list FOR
                SELECT /*+use_nl (t aux)*/
                 aux.id_intervention id,
                 pk_translation.get_translation(i_lang, aux.code_intervention) name,
                 get_inst_pesq_state(i_lang, i_id_institution, aux.id_intervention, i_software, i_context) values_desc,
                 decode((get_missing_data(i_lang, aux.id_intervention, i_id_institution, 0, i_context)), NULL, 'N', 'Y') flg_missing_data
                  FROM (SELECT /*+no_merge*/
                         *
                          FROM intervention i
                         WHERE i.flg_status = 'A') aux
                 WHERE pk_translation.get_translation(i_lang, aux.code_intervention) IS NOT NULL
                 ORDER BY name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_inst_pesq_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INST_PESQ_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_pesq_list;

    /*********************************************************************************************************
    * Get state in the parametrization table for local prescriptions. The state can be:searchable or inactive.
    *  
    *                                                                                                         
    * @return                                                                                                 
    *                                                                                                         
    * @author                         Orlando Antunes                                                         
    * @version                         1.0                                                                    
    * @since                          2009/04/13                                                              
    **********************************************************************************************************/
    FUNCTION get_lab_test_state
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_lab_test       IN analysis.id_analysis%TYPE,
        i_softs          IN table_number
    ) RETURN table_varchar IS
    
        l_drug_state VARCHAR2(1);
        l_error      t_error_out;
    
        l_drug_state_cur pk_types.cursor_type;
    
        l_data table_varchar;
    BEGIN
    
        --Get from the parametrization table
        OPEN l_drug_state_cur FOR
            SELECT to_char(id_software) || ',' || ais.flg_type || ',Pesquis·vel'
              FROM analysis_instit_soft ais
             WHERE ais.id_analysis = i_lab_test
               AND ais.id_institution = i_id_institution
                  --AND ddcs.vers = l_version
               AND ais.id_software IN (SELECT column_value
                                         FROM TABLE(CAST(i_softs AS table_number)));
    
        FETCH l_drug_state_cur BULK COLLECT
            INTO l_data;
    
        CLOSE l_drug_state_cur;
    
        RETURN l_data;
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_API',
                                              i_function => 'GET_PHARM_GROUP_EXT',
                                              o_error    => l_error);
            RETURN l_data;
    END get_lab_test_state;

    /********************************************************************************************
    * Get Analysis Category List
    *
    * @param i_lang                  Prefered language ID
    * @param o_list                  List of analysis categories
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/07
    ********************************************************************************************/
    FUNCTION get_analysis_cat_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT ec.id_exam_cat, pk_translation.get_translation(i_lang, ec.code_exam_cat) analysis_cat_name
              FROM exam_cat ec
             WHERE ec.flg_lab = g_yes
               AND ec.flg_available = g_flg_available
             ORDER BY analysis_cat_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_CAT_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_cat_list;

    /********************************************************************************************
    * Set Analysis Types in different softwares
    *
    * @param i_lang            Prefered language ID
    * @param i_id_institution  Institution ID
    * @param i_software        Softwares ID's
    * @param i_analysis        Analysis ID's
    * @param i_flg_type        Analysis Types
    * @param o_error           Error
    *
    * @param i_flg_type        {*} 'P' Searchable - insert record {*} 'W' Executable - insert record {*} 'I' Inactive - delete record
    
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2008/05/08
    ********************************************************************************************/
    FUNCTION set_inst_soft_analysis_state
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_analysis       IN table_table_number,
        i_sample_type    IN table_table_number,
        i_flg_type       IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis analysis_instit_soft.id_analysis_instit_soft%TYPE;
        l_type     analysis_instit_soft.flg_type%TYPE;
    
        CURSOR c_analysis_inst_soft
        (
            c_id_software    IN analysis_instit_soft.id_software%TYPE,
            c_id_analysis    IN analysis_instit_soft.id_analysis%TYPE,
            c_id_sample_type IN analysis_instit_soft.id_sample_type%TYPE
        ) IS
            SELECT ais.flg_type
              FROM analysis_instit_soft ais
             WHERE ais.id_institution = i_id_institution
               AND ais.id_software = c_id_software
               AND ais.id_analysis = c_id_analysis
               AND ais.id_sample_type = c_id_sample_type;
    
    BEGIN
    
        FOR i IN 1 .. i_software.count
        LOOP
            FOR j IN 1 .. i_analysis(i).count
            LOOP
                IF i_flg_type(i) (j) = 'P'
                THEN
                    OPEN c_analysis_inst_soft(i_software(i), i_analysis(i) (j), i_sample_type(i) (j));
                    FETCH c_analysis_inst_soft
                        INTO l_type;
                    CLOSE c_analysis_inst_soft;
                
                    IF l_type IS NULL
                    THEN
                        g_error := 'GET SEQ_ANALYSIS_INSTIT_SOFT.NEXTVAL';
                        SELECT seq_analysis_instit_soft.nextval
                          INTO l_analysis
                          FROM dual;
                    
                        g_error := 'INSERT INTO ANALYSIS_INST_SOFT';
                        INSERT INTO analysis_instit_soft
                            (id_analysis_instit_soft,
                             id_analysis,
                             id_sample_type,
                             flg_type,
                             id_institution,
                             id_software,
                             flg_available)
                        VALUES
                            (l_analysis,
                             i_analysis(i) (j),
                             i_sample_type(i) (j),
                             i_flg_type(i) (j),
                             i_id_institution,
                             i_software(i),
                             'Y');
                    ELSIF l_type = 'W'
                    THEN
                        g_error := 'UPDATE ANALYSIS_INST_SOFT';
                        UPDATE analysis_instit_soft ais
                           SET ais.flg_type = 'P'
                         WHERE ais.id_analysis = i_analysis(i) (j)
                           AND ais.id_sample_type = i_sample_type(i) (j)
                           AND ais.id_institution = i_id_institution
                           AND ais.id_software = i_software(i);
                    END IF;
                ELSIF i_flg_type(i) (j) = 'W'
                THEN
                    OPEN c_analysis_inst_soft(i_software(i), i_analysis(i) (j), i_sample_type(i) (j));
                    FETCH c_analysis_inst_soft
                        INTO l_type;
                    CLOSE c_analysis_inst_soft;
                
                    IF l_type IS NULL
                    THEN
                        g_error := 'GET SEQ_ANALYSIS_INSTIT_SOFT.NEXTVAL';
                        SELECT seq_analysis_instit_soft.nextval
                          INTO l_analysis
                          FROM dual;
                    
                        g_error := 'INSERT INTO ANALYSIS_INST_SOFT';
                        INSERT INTO analysis_instit_soft
                            (id_analysis_instit_soft,
                             id_analysis,
                             id_sample_type,
                             flg_type,
                             id_institution,
                             id_software,
                             flg_available)
                        VALUES
                            (l_analysis,
                             i_analysis(i) (j),
                             i_sample_type(i) (j),
                             i_flg_type(i) (j),
                             i_id_institution,
                             i_software(i),
                             'Y');
                    ELSIF l_type = 'P'
                    THEN
                        g_error := 'UPDATE ANALYSIS_INST_SOFT';
                        UPDATE analysis_instit_soft ais
                           SET ais.flg_type = 'W'
                         WHERE ais.id_analysis = i_analysis(i) (j)
                           AND ais.id_sample_type = i_sample_type(i) (j)
                           AND ais.id_institution = i_id_institution
                           AND ais.id_software = i_software(i);
                    END IF;
                ELSIF i_flg_type(i) (j) = 'I'
                THEN
                
                    g_error := 'DELETE FROM ANALYSIS_INST_SOFT';
                    DELETE FROM analysis_instit_soft ais
                     WHERE ais.id_analysis = i_analysis(i) (j)
                       AND ais.id_sample_type = i_sample_type(i) (j)
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_software(i);
                
                    g_error := 'DELETE FROM ANALYSIS_DEP_CLIN_SERV';
                    DELETE FROM analysis_dep_clin_serv adcs
                     WHERE adcs.id_analysis = i_analysis(i) (j)
                       AND adcs.id_sample_type = i_sample_type(i) (j)
                       AND adcs.id_software = i_software(i)
                       AND adcs.id_dep_clin_serv IN
                           (SELECT dcs.id_dep_clin_serv
                              FROM dep_clin_serv dcs, department s
                             WHERE dcs.id_department = s.id_department
                               AND s.id_institution = i_id_institution);
                
                END IF;
            END LOOP;
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_ANALYSIS_STATE');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_inst_soft_analysis_state;

    /********************************************************************************************
    * Most Frequent dept list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_dept_list             Dept List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/09
    ********************************************************************************************/
    FUNCTION get_software_dept_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_dept_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DEPT CURSOR';
        OPEN o_dept_list FOR
            SELECT DISTINCT d3.id_dept, pk_translation.get_translation(i_lang, d3.code_dept) name
              FROM dept d3, software_dept sd
             WHERE d3.id_institution = i_id_institution
               AND d3.flg_available = g_flg_available
               AND sd.id_dept = d3.id_dept
               AND sd.id_software = i_id_software
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_dept_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SOFTWARE_DEPT_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_software_dept_list;

    /********************************************************************************************
    * Service Room list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_department         Service ID
    * @param o_room_list             Room List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/13
    ********************************************************************************************/
    FUNCTION get_department_room_list
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        o_room_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DEPT CURSOR';
        OPEN o_room_list FOR
            SELECT DISTINCT r.id_room, nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) name
              FROM room r
             WHERE r.id_department = i_id_department
               AND r.flg_available = g_flg_available
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_room_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_DEPARTMENT_ROOM_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_department_room_list;

    /********************************************************************************************
    * Labs list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_software           Software ID
    * @param i_id_analysis           Analysis ID
    * @param o_room_list             Room List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/13
    ********************************************************************************************/
    FUNCTION get_lab_room_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_analysis    IN analysis.id_analysis%TYPE,
        i_id_sample_type IN sample_type.id_sample_type%TYPE,
        o_room_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DEPT CURSOR';
        OPEN o_room_list FOR
            SELECT DISTINCT r.id_room,
                            nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name,
                            g_status_a flg_status,
                            ar.flg_default
              FROM analysis_room ar, room r, department s, software_dept sd
             WHERE ar.id_analysis = i_id_analysis
               AND ar.id_sample_type = i_id_sample_type
               AND ar.id_room = r.id_room
               AND sd.id_software = i_id_software
               AND sd.id_dept = s.id_dept
               AND r.id_department = s.id_department
               AND r.flg_lab = g_yes
            UNION
            SELECT DISTINCT r.id_room,
                            nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name,
                            g_status_i flg_status,
                            'N' flg_default
              FROM room r, department s, software_dept sd
             WHERE sd.id_software = i_id_software
               AND sd.id_dept = s.id_dept
               AND r.id_department = s.id_department
               AND r.flg_lab = g_yes
               AND r.id_room NOT IN (SELECT DISTINCT r2.id_room
                                       FROM analysis_room ar2, room r2, department s2, software_dept sd2
                                      WHERE ar2.id_analysis = i_id_analysis
                                        AND ar2.id_sample_type = i_id_sample_type
                                        AND ar2.id_room = r2.id_room
                                        AND sd2.id_software = i_id_software
                                        AND sd2.id_dept = s2.id_dept
                                        AND r2.id_department = s2.id_department
                                        AND r2.flg_lab = g_yes)
             ORDER BY room_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_room_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_LAB_ROOM_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_lab_room_list;

    /********************************************************************************************
    * Analysis Labs list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_analysis           Analysis ID
    * @param i_search                Search
    * @param o_lab_list              Lab List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/19
    ********************************************************************************************/
    FUNCTION get_analysis_lab_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_analysis    IN analysis.id_analysis%TYPE,
        i_id_sample_type IN sample_type.id_sample_type%TYPE,
        i_search         IN VARCHAR2,
        o_lab_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_search IS NULL
        THEN
            g_error := 'GET DEPT CURSOR';
            OPEN o_lab_list FOR
                SELECT DISTINCT r.id_room id_lab,
                                nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) lab_name,
                                (SELECT COUNT(*)
                                   FROM room_questionnaire rq
                                  WHERE rq.id_room = r.id_room) quests_no
                  FROM analysis_room ar, room r
                 WHERE ar.id_analysis = i_id_analysis
                   AND ar.id_sample_type = i_id_sample_type
                   AND ar.flg_type = 'T'
                   AND ar.id_institution = i_id_institution
                   AND ar.id_room = r.id_room
                   AND ar.flg_available = g_flg_available
                   AND r.flg_available = g_flg_available
                UNION
                SELECT DISTINCT r.id_room id_lab,
                                nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) lab_name,
                                (SELECT COUNT(*)
                                   FROM room_questionnaire rq
                                  WHERE rq.id_room = r.id_room) quests_no
                  FROM room r, department s
                 WHERE r.flg_lab = g_yes
                   AND r.id_department = s.id_department
                   AND s.id_institution = i_id_institution
                   AND s.flg_available = g_flg_available
                   AND r.id_room NOT IN (SELECT DISTINCT r2.id_room
                                           FROM analysis_room ar2, room r2
                                          WHERE ar2.id_analysis = i_id_analysis
                                            AND ar2.id_sample_type = i_id_sample_type
                                            AND ar2.flg_type = 'T'
                                            AND ar2.id_institution = i_id_institution
                                            AND ar2.id_room = r2.id_room
                                            AND ar2.flg_available = g_flg_available
                                            AND r2.flg_available = g_flg_available)
                 ORDER BY lab_name;
        ELSE
            g_error := 'GET DEPT CURSOR';
            OPEN o_lab_list FOR
                SELECT DISTINCT r.id_room id_lab,
                                nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) lab_name
                  FROM analysis_room ar, room r
                 WHERE ar.id_analysis = i_id_analysis
                   AND ar.flg_type = 'T'
                   AND ar.id_institution = i_id_institution
                   AND ar.id_room = r.id_room
                   AND ar.flg_available = g_flg_available
                   AND r.flg_available = g_flg_available
                   AND translate(upper(nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                UNION
                SELECT DISTINCT r.id_room id_lab,
                                nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) lab_name
                  FROM room r, department s
                 WHERE r.flg_lab = g_yes
                   AND r.id_department = s.id_department
                   AND s.id_institution = i_id_institution
                   AND s.flg_available = g_flg_available
                   AND r.id_room NOT IN (SELECT DISTINCT r2.id_room
                                           FROM analysis_room ar2, room r2
                                          WHERE ar2.id_analysis = i_id_analysis
                                            AND ar2.flg_type = 'T'
                                            AND ar2.id_institution = i_id_institution
                                            AND ar2.id_room = r2.id_room
                                            AND ar2.flg_available = g_flg_available
                                            AND r2.flg_available = g_flg_available)
                   AND translate(upper(nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY lab_name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_lab_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_LAB_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_lab_list;

    /********************************************************************************************
    * Get Analysis sample recipient list
    *
    * @param i_lang           Prefered language ID
    * @param i_id_institution Institution ID
    * @param i_id_software    Software ID
    * @param i_id_analysis    Analysis ID
    * @param i_id_room        Room ID
    * @param i_search         Search
    * @param o_recipient_list Sample recipients
    * @param o_error          Error
    *
    *
    * @return                 true or false on success or error
    *
    * @author                 JTS
    * @version                0.1
    * @since                  2008/05/13
    ********************************************************************************************/
    FUNCTION get_analysis_recipient_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_software    IN analysis_instit_soft.id_software%TYPE,
        i_id_analysis    IN analysis_instit_soft.id_analysis%TYPE,
        i_id_sample_type IN sample_type.id_sample_type%TYPE,
        i_id_room        IN analysis_room.id_room%TYPE,
        i_search         IN VARCHAR2,
        o_recipient_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET RECIPIENT LIST CURSOR';
    
        IF i_id_room IS NOT NULL
        THEN
            IF i_search IS NULL
            THEN
                OPEN o_recipient_list FOR
                    SELECT sr.id_sample_recipient id,
                           pk_translation.get_translation(i_lang, sr.code_sample_recipient) sample_recipient_name,
                           air.flg_default
                      FROM analysis_instit_soft ais, analysis_instit_recipient air, sample_recipient sr
                     WHERE ais.id_institution = i_id_institution
                       AND ais.id_software = i_id_software
                       AND ais.id_analysis = i_id_analysis
                       AND ais.id_sample_type = i_id_sample_type
                       AND ais.id_analysis_instit_soft = air.id_analysis_instit_soft
                       AND air.id_sample_recipient = sr.id_sample_recipient
                       AND sr.flg_available = g_flg_available
                       AND air.id_room = i_id_room
                    UNION
                    SELECT sr.id_sample_recipient id,
                           pk_translation.get_translation(i_lang, sr.code_sample_recipient) sample_recipient_name,
                           g_no flg_default
                      FROM sample_recipient sr
                     WHERE sr.id_sample_recipient NOT IN
                           (SELECT sr2.id_sample_recipient id
                              FROM analysis_instit_soft ais2, analysis_instit_recipient air2, sample_recipient sr2
                             WHERE ais2.id_institution = i_id_institution
                               AND ais2.id_software = i_id_software
                               AND ais2.id_analysis = i_id_analysis
                               AND ais2.id_sample_type = i_id_sample_type
                               AND ais2.id_analysis_instit_soft = air2.id_analysis_instit_soft
                               AND air2.id_sample_recipient = sr2.id_sample_recipient
                               AND sr2.flg_available = g_flg_available
                               AND air2.id_room = i_id_room)
                       AND sr.flg_available = g_flg_available
                     ORDER BY sample_recipient_name;
            ELSE
                OPEN o_recipient_list FOR
                    SELECT sr.id_sample_recipient id,
                           pk_translation.get_translation(i_lang, sr.code_sample_recipient) sample_recipient_name,
                           air.flg_default
                      FROM analysis_instit_soft ais, analysis_instit_recipient air, sample_recipient sr
                     WHERE ais.id_institution = i_id_institution
                       AND ais.id_software = i_id_software
                       AND ais.id_analysis = i_id_analysis
                       AND ais.id_sample_type = i_id_sample_type
                       AND ais.id_analysis_instit_soft = air.id_analysis_instit_soft
                       AND air.id_sample_recipient = sr.id_sample_recipient
                       AND sr.flg_available = g_flg_available
                       AND air.id_room = i_id_room
                       AND translate(upper(pk_translation.get_translation(i_lang, sr.code_sample_recipient)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                    UNION
                    SELECT sr.id_sample_recipient id,
                           pk_translation.get_translation(i_lang, sr.code_sample_recipient) sample_recipient_name,
                           g_no flg_default
                      FROM sample_recipient sr
                     WHERE sr.id_sample_recipient NOT IN
                           (SELECT sr2.id_sample_recipient id
                              FROM analysis_instit_soft ais2, analysis_instit_recipient air2, sample_recipient sr2
                             WHERE ais2.id_institution = i_id_institution
                               AND ais2.id_software = i_id_software
                               AND ais2.id_analysis = i_id_analysis
                               AND ais2.id_sample_type = i_id_sample_type
                               AND ais2.id_analysis_instit_soft = air2.id_analysis_instit_soft
                               AND air2.id_sample_recipient = sr2.id_sample_recipient
                               AND sr2.flg_available = g_flg_available
                               AND air2.id_room = i_id_room)
                       AND sr.flg_available = g_flg_available
                       AND translate(upper(pk_translation.get_translation(i_lang, sr.code_sample_recipient)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY sample_recipient_name;
            END IF;
        ELSE
            IF i_search IS NULL
            THEN
                OPEN o_recipient_list FOR
                    SELECT sr.id_sample_recipient id,
                           pk_translation.get_translation(i_lang, sr.code_sample_recipient) sample_recipient_name,
                           air.flg_default
                      FROM analysis_instit_soft ais, analysis_instit_recipient air, sample_recipient sr
                     WHERE ais.id_institution = i_id_institution
                       AND ais.id_software = i_id_software
                       AND ais.id_analysis = i_id_analysis
                       AND ais.id_sample_type = i_id_sample_type
                       AND ais.id_analysis_instit_soft = air.id_analysis_instit_soft
                       AND air.id_sample_recipient = sr.id_sample_recipient
                       AND sr.flg_available = g_flg_available
                    UNION
                    SELECT sr.id_sample_recipient id,
                           pk_translation.get_translation(i_lang, sr.code_sample_recipient) sample_recipient_name,
                           g_no flg_default
                      FROM sample_recipient sr
                     WHERE sr.id_sample_recipient NOT IN
                           (SELECT sr2.id_sample_recipient id
                              FROM analysis_instit_soft ais2, analysis_instit_recipient air2, sample_recipient sr2
                             WHERE ais2.id_institution = i_id_institution
                               AND ais2.id_software = i_id_software
                               AND ais2.id_analysis = i_id_analysis
                               AND ais2.id_sample_type = i_id_sample_type
                               AND ais2.id_analysis_instit_soft = air2.id_analysis_instit_soft
                               AND air2.id_sample_recipient = sr2.id_sample_recipient
                               AND sr2.flg_available = g_flg_available)
                       AND sr.flg_available = g_flg_available
                     ORDER BY sample_recipient_name;
            ELSE
                OPEN o_recipient_list FOR
                    SELECT sr.id_sample_recipient id,
                           pk_translation.get_translation(i_lang, sr.code_sample_recipient) sample_recipient_name,
                           air.flg_default
                      FROM analysis_instit_soft ais, analysis_instit_recipient air, sample_recipient sr
                     WHERE ais.id_institution = i_id_institution
                       AND ais.id_software = i_id_software
                       AND ais.id_analysis = i_id_analysis
                       AND ais.id_sample_type = i_id_sample_type
                       AND ais.id_analysis_instit_soft = air.id_analysis_instit_soft
                       AND air.id_sample_recipient = sr.id_sample_recipient
                       AND sr.flg_available = g_flg_available
                       AND translate(upper(pk_translation.get_translation(i_lang, sr.code_sample_recipient)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                    UNION
                    SELECT sr.id_sample_recipient id,
                           pk_translation.get_translation(i_lang, sr.code_sample_recipient) sample_recipient_name,
                           g_no flg_default
                      FROM sample_recipient sr
                     WHERE sr.id_sample_recipient NOT IN
                           (SELECT sr2.id_sample_recipient id
                              FROM analysis_instit_soft ais2, analysis_instit_recipient air2, sample_recipient sr2
                             WHERE ais2.id_institution = i_id_institution
                               AND ais2.id_software = i_id_software
                               AND ais2.id_analysis = i_id_analysis
                               AND ais2.id_sample_type = i_id_sample_type
                               AND ais2.id_analysis_instit_soft = air2.id_analysis_instit_soft
                               AND air2.id_sample_recipient = sr2.id_sample_recipient
                               AND sr2.flg_available = g_flg_available)
                       AND sr.flg_available = g_flg_available
                       AND translate(upper(pk_translation.get_translation(i_lang, sr.code_sample_recipient)),
                                     '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY sample_recipient_name;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_recipient_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_RECIPIENT_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_recipient_list;

    /********************************************************************************************
    * Loinc list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_analysis           Analysis ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param i_search                Search
    * @param o_loinc_list            Loinc List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/21
    ********************************************************************************************/
    FUNCTION get_analysis_loinc_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_analysis    IN analysis_instit_soft.id_analysis%TYPE,
        i_id_sample_type IN analysis_instit_soft.id_sample_type%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_software    IN analysis_instit_soft.id_software%TYPE,
        i_search         IN VARCHAR2,
        o_loinc_list     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_loinc_count NUMBER;
    
    BEGIN
    
        IF i_id_software = 0
        THEN
            SELECT COUNT(al.id_analysis_loinc)
              INTO l_loinc_count
              FROM analysis_loinc al
             WHERE al.id_analysis = i_id_analysis
               AND al.id_analysis = i_id_sample_type
               AND al.id_institution = i_id_institution
               AND al.id_software = i_id_software;
        
            g_error := 'GET LOINC CURSOR';
            IF l_loinc_count = 0
            THEN
                OPEN o_loinc_list FOR
                    SELECT alt.loinc_code
                      FROM analysis_loinc_template alt
                     WHERE alt.id_analysis = i_id_analysis
                     ORDER BY loinc_code;
            ELSE
                OPEN o_loinc_list FOR
                    SELECT al.loinc_code
                      FROM analysis_loinc al
                     WHERE al.id_analysis = i_id_analysis
                       AND al.id_analysis = i_id_sample_type
                       AND al.id_institution = i_id_institution
                       AND al.id_software = i_id_software
                    UNION
                    SELECT alt.loinc_code
                      FROM analysis_loinc_template alt
                     WHERE alt.id_analysis = i_id_analysis
                     ORDER BY loinc_code;
            END IF;
        ELSE
            OPEN o_loinc_list FOR
                SELECT alt.loinc_code
                  FROM analysis_loinc_template alt
                 WHERE alt.id_analysis = i_id_analysis
                 ORDER BY loinc_code;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_loinc_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_LOINC_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_loinc_list;

    /********************************************************************************************
    * Service lab list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_department         Service ID
    * @param o_lab_list              Lab List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/23
    ********************************************************************************************/
    FUNCTION get_service_lab_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institutiton IN institution.id_institution%TYPE,
        i_id_department   IN department.id_department%TYPE,
        o_lab_list        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_LAB_LIST CURSOR';
        OPEN o_lab_list FOR
            SELECT 0 id_lab, pk_message.get_message(i_lang, 'ADMINISTRATOR_T053') lab_name
              FROM dual
            UNION
            SELECT r.id_room id_lab, nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) lab_name
              FROM room r, department d
             WHERE r.id_department = d.id_department
               AND d.id_institution = i_id_institutiton
               AND d.id_department = i_id_department
               AND r.flg_lab = g_yes
               AND r.flg_available = g_flg_available
             ORDER BY lab_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_lab_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SERVICE_LAB_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_service_lab_list;

    /********************************************************************************************
    * Get Institution Interventions Information
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution           Institution ID
    * @param i_id_intervention          Intervention ID
    * @param i_id_software              Software ID
    * @param i_prof                     Object
    * @param o_inst_interv              Intervention information
    * @param o_inst_analysis_wf_bandaid Bandaid
    * @param o_inst_analysis_wf_charge  Chargeble intervention?
    * @param o_inst_interv_int_cat    
    * @param o_error                    Error
    *
    *
    * @return                           true or false on success or error
    *
    * @author                           JTS
    * @version                          0.1
    * @since                            2008/05/24
    ********************************************************************************************/
    FUNCTION get_inst_interv_all
    (
        i_lang                      IN language.id_language%TYPE,
        i_id_institution            IN interv_dep_clin_serv.id_institution%TYPE,
        i_id_intervention           IN interv_dep_clin_serv.id_intervention%TYPE,
        i_id_software               IN interv_dep_clin_serv.id_software%TYPE,
        i_prof                      IN profissional,
        o_inst_interv               OUT pk_types.cursor_type,
        o_inst_interv_wf_bandaid    OUT pk_types.cursor_type,
        o_inst_interv_wf_chargeable OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET INST_INTERV CURSOR';
        OPEN o_inst_interv FOR
            SELECT i.id_intervention,
                   pk_translation.get_translation(i_lang, i.code_intervention) interv_name,
                   i.id_intervention_parent,
                   decode(i.id_intervention_parent,
                          NULL,
                          NULL,
                          (SELECT pk_translation.get_translation(i_lang, ip.code_intervention)
                             FROM intervention ip
                            WHERE ip.id_intervention = i.id_intervention_parent)) interv_parent_name,
                   i.adw_last_update,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, i.adw_last_update, i_prof) upd_date,
                   pk_utils.concat_table(CAST(MULTISET (SELECT ic.id_interv_category
                                                 FROM interv_int_cat iic, interv_category ic
                                                WHERE iic.id_intervention = i.id_intervention
                                                  AND iic.id_interv_category = ic.id_interv_category
                                                  AND ic.flg_available = g_flg_available) AS table_varchar),
                                         ', ') interv_cat,
                   pk_utils.concat_table(CAST(MULTISET
                                              (SELECT pk_translation.get_translation(i_lang, ic.code_interv_category)
                                                 FROM interv_int_cat iic, interv_category ic
                                                WHERE iic.id_intervention = i.id_intervention
                                                  AND iic.id_interv_category = ic.id_interv_category
                                                  AND ic.flg_available = g_flg_available) AS table_varchar),
                                         ', ') interv_cat_desc,
                   i.gender,
                   pk_sysdomain.get_domain('PATIENT.GENDER', nvl(i.gender, NULL), i_lang) genero,
                   i.age_min,
                   i.age_max,
                   i.mdm_coding,
                   i.cpt_code,
                   i.flg_mov_pat,
                   pk_sysdomain.get_domain('YES_NO', nvl(i.flg_mov_pat, NULL), i_lang) mov_pat_desc
              FROM intervention i
             WHERE i.id_intervention = i_id_intervention;
    
        g_error := 'GET INST_INTERV_WF_BANDAID CURSOR';
        OPEN o_inst_interv_wf_bandaid FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL flg_bandaid,
                   NULL bandaid_desc,
                   (decode((SELECT COUNT(DISTINCT idcs.id_software)
                             FROM interv_dep_clin_serv idcs
                            WHERE idcs.id_intervention = i_id_intervention
                              AND idcs.id_institution = i_id_institution
                              AND idcs.flg_type IN ('P', 'E', 'C')
                              AND idcs.id_dep_clin_serv IS NULL),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   idcs.flg_bandaid,
                   pk_sysdomain.get_domain('YES_NO', idcs.flg_bandaid, i_lang) bandaid_desc,
                   'Y' soft_active
              FROM interv_dep_clin_serv idcs, software s
             WHERE idcs.id_institution = i_id_institution
               AND idcs.id_intervention = i_id_intervention
               AND idcs.id_software = s.id_software
               AND idcs.flg_type IN ('P', 'E', 'C')
               AND idcs.id_dep_clin_serv IS NULL
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_bandaid, NULL bandaid_desc, 'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM interv_dep_clin_serv idcs, software s3
                                          WHERE idcs.id_institution = i_id_institution
                                            AND idcs.id_intervention = i_id_intervention
                                            AND idcs.id_software = s3.id_software
                                            AND idcs.flg_type IN ('P', 'E', 'C')
                                            AND idcs.id_dep_clin_serv IS NULL)
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software IN (SELECT DISTINCT idcs.id_software
                                       FROM interv_dep_clin_serv idcs
                                      WHERE idcs.id_intervention = i_id_intervention
                                        AND idcs.id_institution = i_id_institution
                                        AND idcs.flg_type IN ('P', 'E', 'C')
                                        AND idcs.id_dep_clin_serv IS NULL)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_bandaid, NULL bandaid_desc, 'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM interv_dep_clin_serv idcs, software s3
                                          WHERE idcs.id_institution = i_id_institution
                                            AND idcs.id_intervention = i_id_intervention
                                            AND idcs.id_software = s3.id_software
                                            AND idcs.flg_type IN ('P', 'E', 'C')
                                            AND idcs.id_dep_clin_serv IS NULL)
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT idcs.id_software
                                           FROM interv_dep_clin_serv idcs
                                          WHERE idcs.id_intervention = i_id_intervention
                                            AND idcs.id_institution = i_id_institution
                                            AND idcs.flg_type IN ('P', 'E', 'C')
                                            AND idcs.id_dep_clin_serv IS NULL);
    
        g_error := 'GET INST_INTERV_WF_CHARGEABLE CURSOR';
        OPEN o_inst_interv_wf_chargeable FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL flg_chargeable,
                   NULL chargeable_desc,
                   (decode((SELECT COUNT(DISTINCT idcs.id_software)
                             FROM interv_dep_clin_serv idcs
                            WHERE idcs.id_intervention = i_id_intervention
                              AND idcs.id_institution = i_id_institution
                              AND idcs.flg_type IN ('P', 'E', 'C')
                              AND idcs.id_dep_clin_serv IS NULL),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   idcs.flg_chargeable,
                   pk_sysdomain.get_domain('YES_NO', idcs.flg_chargeable, i_lang) chargeable_desc,
                   'Y' soft_active
              FROM interv_dep_clin_serv idcs, software s
             WHERE idcs.id_institution = i_id_institution
               AND idcs.id_intervention = i_id_intervention
               AND idcs.id_software = s.id_software
               AND idcs.flg_type IN ('P', 'E', 'C')
               AND idcs.id_dep_clin_serv IS NULL
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_chargeable, NULL chargeable_desc, 'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM interv_dep_clin_serv idcs, software s3
                                          WHERE idcs.id_institution = i_id_institution
                                            AND idcs.id_intervention = i_id_intervention
                                            AND idcs.id_software = s3.id_software)
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software IN (SELECT DISTINCT idcs.id_software
                                       FROM interv_dep_clin_serv idcs
                                      WHERE idcs.id_intervention = i_id_intervention
                                        AND idcs.id_institution = i_id_institution
                                        AND idcs.flg_type IN ('P', 'E', 'C')
                                        AND idcs.id_dep_clin_serv IS NULL)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_chargeable, NULL chargeable_desc, 'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM interv_dep_clin_serv idcs, software s3
                                          WHERE idcs.id_institution = i_id_institution
                                            AND idcs.id_intervention = i_id_intervention
                                            AND idcs.id_software = s3.id_software
                                            AND idcs.flg_type IN ('P', 'E', 'C')
                                            AND idcs.id_dep_clin_serv IS NULL)
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
                  
               AND s.id_software NOT IN (SELECT DISTINCT idcs.id_software
                                           FROM interv_dep_clin_serv idcs
                                          WHERE idcs.id_intervention = i_id_intervention
                                            AND idcs.id_institution = i_id_institution
                                            AND idcs.flg_type IN ('P', 'E', 'C')
                                            AND idcs.id_dep_clin_serv IS NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_inst_interv);
                pk_types.open_my_cursor(o_inst_interv_wf_bandaid);
                pk_types.open_my_cursor(o_inst_interv_wf_chargeable);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INST_INTERV_ALL');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_interv_all;

    /********************************************************************************************
    * Institution intervention parametrization
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_intervention       Intervention ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID's
    * @param i_flg_bandais           Bandaid flags
    * @param i_flg_chargeable        Chargeable flags
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/24
    ********************************************************************************************/
    FUNCTION set_inst_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN interv_dep_clin_serv.id_intervention%TYPE,
        i_id_institution  IN interv_dep_clin_serv.id_institution%TYPE,
        i_id_software     IN table_number,
        i_flg_bandaid     IN table_varchar,
        i_flg_chargeable  IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_soft pk_types.cursor_type;
    
        l_idcs_flg_type interv_dep_clin_serv.flg_type%TYPE;
        l_rows          table_varchar;
        l_error         t_error_out;
    BEGIN
    
        FOR i IN 1 .. i_id_software.count
        LOOP
            SELECT decode(idcs.flg_type, 'E', 'P', 'P', 'P', 'C', 'C')
              INTO l_idcs_flg_type
              FROM interv_dep_clin_serv idcs
             WHERE idcs.id_intervention = i_id_intervention
               AND idcs.id_institution = i_id_institution
               AND idcs.id_software = i_id_software(i)
               AND idcs.id_dep_clin_serv IS NULL
               AND idcs.flg_type IN ('P', 'E', 'C')
               FOR UPDATE;
        
            g_error := 'UPDATE INTERV_DEP_CLIN_SERV';
            ts_interv_dep_clin_serv.upd(flg_bandaid_in    => i_flg_bandaid(i),
                                        flg_chargeable_in => i_flg_chargeable(i),
                                        flg_type_in       => l_idcs_flg_type,
                                        where_in          => 'id_intervention = ' || i_id_intervention || '
                                                      and  id_institution = ' ||
                                                             i_id_institution || '
                                                      and  id_software = ' ||
                                                             i_id_software(i) || '
                                                      and  id_dep_clin_serv IS NULL
                                                      and  flg_type IN (''P'', ''E'', ''C'')',
                                        rows_out          => l_rows);
        
        END LOOP;
    
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'INTERV_DEP_CLIN_SERV',
                                      l_rows,
                                      l_error,
                                      table_varchar('FLG_BANDAID', 'FLG_CHARGEABLE', 'FLG_TYPE'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_MCDT', 'SET_INST_INTERV');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_inst_interv;

    /********************************************************************************************
    * Institution analysis parametrization
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_analysis           Analysis ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID's
    * @param i_syn                   Analysis synonim
    * @param i_id_exam_cat           Analysis categories
    * @param i_loinc                 Loinc codes
    * @param i_loinc_default         Default Loinc
    * @param i_loinc_select          Loinc selection indication
    * @param i_parameters            Parameters
    * @param i_parameters_select     Parameters selection indication
    * @param i_lab                   Lab ID's
    * @param i_lab_default           Default lab
    * @param i_lab_select            Labs selection indication
    * @param i_flg_rec_lab           Recipient depends on lab?
    * @param i_recipient             Recipient ID's
    * @param i_recipient_default     Default recipient
    * @param i_recipient_select      Recipient selection indication
    * @param i_recipient_room        Recipient rooms
    * @param i_room_mov_pat          Room to move patient
    * @param i_flg_mov_pat           Move patient flags
    * @param i_flg_mov_rec           Move recipient flags
    * @param i_flg_harvest           Harvest flags
    * @param i_flg_first_res         First result flags
    * @param o_error                 Error
    *
    * @value i_loinc_select          {*} 'Y' Yes {*} 'N' No
    * @value i_parameters_select     {*} 'Y' Yes {*} 'N' No
    * @value i_lab_select            {*} 'Y' Yes {*} 'N' No
    * @value i_recipient_select      {*} 'Y' Yes {*} 'N' No
    * @value i_flg_rec_lab           {*} 'Y' Yes {*} 'N' No
    * @value i_recipient_select      {*} 'Y' Yes {*} 'N' No
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/24
    ********************************************************************************************/
    FUNCTION set_inst_analysis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_analysis        IN analysis_instit_soft.id_analysis%TYPE,
        i_id_sample_type     IN analysis_instit_soft.id_sample_type%TYPE,
        i_id_institution     IN analysis_instit_soft.id_institution%TYPE,
        i_id_software        IN table_number,
        i_syn                IN table_varchar,
        i_id_exam_cat        IN table_number,
        i_loinc              IN table_table_varchar,
        i_loinc_default      IN table_table_varchar,
        i_loinc_select       IN table_table_varchar,
        i_parameters         IN table_table_number,
        i_parameters_select  IN table_table_varchar,
        i_lab                IN table_table_number,
        i_lab_default        IN table_table_varchar,
        i_lab_select         IN table_table_varchar,
        i_flg_rec_lab        IN VARCHAR2,
        i_recipient          IN table_table_number,
        i_recipient_default  IN table_table_varchar,
        i_recipient_select   IN table_table_varchar,
        i_recipient_room     IN table_table_number,
        i_room_mov_pat       IN analysis_room.id_room%TYPE,
        i_flg_mov_pat        IN table_varchar,
        i_flg_mov_rec        IN table_varchar,
        i_flg_harvest        IN analysis_instit_soft.flg_harvest%TYPE,
        i_flg_first_res      IN table_varchar,
        i_flg_duplicate_warn IN table_varchar,
        i_tbl_id_room_quest  IN table_number,
        i_tbl_timing         IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_mov_pat                     NUMBER := 0;
        l_mov_rec                     NUMBER := 0;
        l_move_lab                    analysis_room.id_room%TYPE;
        l_alias                       NUMBER := 0;
        l_analysis_alias              analysis_alias.id_analysis_alias%TYPE;
        l_analysis_alias_code         analysis_alias.code_analysis_alias%TYPE;
        l_analysis_loinc              analysis_loinc.id_analysis_loinc%TYPE;
        l_analysis_loinc_exist        NUMBER := 0;
        l_analysis_param              analysis_param.id_analysis_param%TYPE;
        l_analysis_lab                analysis_room.id_room%TYPE;
        l_analysis_lab_exist          NUMBER := 0;
        l_analysis_lab_default        VARCHAR2(1);
        l_analysis_soft_inst          analysis_instit_soft.id_analysis_instit_soft%TYPE;
        l_analysis_instit_recipient   analysis_instit_recipient.id_analysis_instit_recipient%TYPE;
        l_analysis_inst_recip_exist   NUMBER := 0;
        l_analysis_param_funcionality analysis_param_funcionality.id_analysis_param_funcionality%TYPE;
        l_ais_flg_type                analysis_instit_soft.flg_type%TYPE;
        l_flg_harvest                 analysis_instit_soft.flg_harvest%TYPE;
    
        CURSOR c_analysis_soft_inst IS
            SELECT DISTINCT ais.id_analysis_instit_soft
              FROM analysis_instit_soft ais
             WHERE ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type
               AND ais.id_institution = i_id_institution;
    
        l_id_analysis_inst_soft    analysis_instit_soft.id_analysis_instit_soft%TYPE;
        l_cur_analysis_instit_soft pk_types.cursor_type;
    
        --
        l_tbl_id_room_quest table_number;
        l_tbl_timing        table_varchar;
    
    BEGIN
    
        g_error             := 'Initialize Tables';
        l_tbl_id_room_quest := table_number();
        l_tbl_timing        := table_varchar();
    
        g_error             := 'Copying Tables';
        l_tbl_id_room_quest := i_tbl_id_room_quest;
        l_tbl_timing        := i_tbl_timing;
    
        IF i_room_mov_pat IS NOT NULL
        THEN
            g_error := 'l_mov_pat';
            SELECT COUNT(ar.id_room)
              INTO l_mov_pat
              FROM analysis_room ar
             WHERE ar.id_analysis = i_id_analysis
               AND ar.id_sample_type = i_id_sample_type
               AND ar.id_institution = i_id_institution
               AND ar.flg_type = 'M'
               AND ar.flg_available = 'Y'
               AND ar.flg_default = 'Y';
        
            IF l_mov_pat = 0
            THEN
                g_error := 'GET SEQ_ANALYSIS_ROOM.NEXTVAL';
                SELECT seq_analysis_room.nextval
                  INTO l_move_lab
                  FROM dual;
            
                g_error := 'INSERT INTO ANALYSIS_ROOM';
                INSERT INTO analysis_room
                    (id_analysis_room,
                     id_analysis,
                     id_room,
                     rank,
                     flg_type,
                     flg_available,
                     flg_default,
                     id_institution,
                     id_sample_type)
                VALUES
                    (l_move_lab, i_id_analysis, i_room_mov_pat, 0, 'M', 'Y', 'Y', i_id_institution, i_id_sample_type);
            
                l_flg_harvest := 'Y';
            
            ELSE
                g_error := 'l_mov_pat';
                SELECT nvl((SELECT COUNT(ar.id_room)
                             FROM analysis_room ar
                            WHERE ar.id_analysis = i_id_analysis
                              AND ar.id_sample_type = i_id_sample_type
                              AND ar.id_institution = i_id_institution
                              AND ar.flg_type = 'M'
                              AND ar.flg_available = 'Y'
                              AND ar.flg_default = 'Y'),
                           0)
                  INTO l_mov_pat
                  FROM dual;
            
                IF l_mov_pat >= 1
                THEN
                
                    g_error := 'DELETE FROM analysis_room';
                    DELETE FROM analysis_room ar
                     WHERE ar.id_analysis = i_id_analysis
                       AND ar.id_sample_type = i_id_sample_type
                       AND ar.id_institution = i_id_institution
                       AND ar.flg_type = 'M';
                
                    g_error := 'GET SEQ_ANALYSIS_ROOM.NEXTVAL';
                    SELECT seq_analysis_room.nextval
                      INTO l_move_lab
                      FROM dual;
                
                    g_error := 'INSERT INTO ANALYSIS_ROOM teste 2';
                    INSERT INTO analysis_room
                        (id_analysis_room,
                         id_analysis,
                         id_room,
                         rank,
                         flg_type,
                         flg_available,
                         flg_default,
                         id_institution,
                         id_sample_type)
                    VALUES
                        (l_move_lab,
                         i_id_analysis,
                         i_room_mov_pat,
                         0,
                         'M',
                         'Y',
                         'Y',
                         i_id_institution,
                         i_id_sample_type);
                
                    l_flg_harvest := 'Y';
                
                END IF;
            END IF;
        END IF;
    
        FOR i IN 1 .. i_id_software.count
        LOOP
            SELECT nvl((SELECT decode(ais.flg_type, 'E', 'P', 'P', 'P', 'X', 'W', 'W', 'W', 'C', 'C')
                         FROM analysis_instit_soft ais
                        WHERE ais.id_analysis = i_id_analysis
                          AND ais.id_sample_type = i_id_sample_type
                          AND ais.id_institution = i_id_institution
                          AND ais.id_software = i_id_software(i)),
                       'R')
              INTO l_ais_flg_type
              FROM dual;
        
            IF l_ais_flg_type != 'R'
            THEN
            
                g_error := 'UPDATE ANALYSIS_INSTIT_SOFT 1';
                UPDATE analysis_instit_soft ais
                   SET ais.flg_mov_pat        = i_flg_mov_pat(i),
                       ais.flg_mov_recipient  = i_flg_mov_rec(i),
                       ais.flg_harvest        = nvl(l_flg_harvest, i_flg_harvest),
                       ais.flg_first_result   = i_flg_first_res(i),
                       ais.id_exam_cat        = i_id_exam_cat(i),
                       ais.flg_type           = l_ais_flg_type,
                       ais.flg_duplicate_warn = i_flg_duplicate_warn(i)
                 WHERE ais.id_analysis = i_id_analysis
                   AND ais.id_sample_type = i_id_sample_type
                   AND ais.id_institution = i_id_institution
                   AND ais.id_software = i_id_software(i);
            
            END IF;
        
            SELECT COUNT(asta.id_analysis_sample_type_alias)
              INTO l_alias
              FROM analysis_sample_type_alias asta
             WHERE asta.id_analysis = i_id_analysis
               AND asta.id_analysis = i_id_sample_type
               AND asta.id_institution = i_id_institution
               AND asta.id_software = 0;
        
            IF l_alias = 0
               AND i_syn(i) IS NOT NULL
            THEN
                g_error := 'GET SEQ_ANALYSIS_SAMPLE_TYPE_ALIAS.NEXTVAL';
                SELECT seq_analysis_sample_type_alias.nextval
                  INTO l_analysis_alias
                  FROM dual;
            
                g_error := 'INSERT INTO ANALYSIS_SAMPLE_TYPE_ALIAS';
                INSERT INTO analysis_sample_type_alias
                    (id_analysis_sample_type_alias,
                     id_analysis,
                     id_sample_type,
                     code_ast_alias,
                     id_institution,
                     id_software,
                     id_professional)
                VALUES
                    (l_analysis_alias,
                     i_id_analysis,
                     i_id_sample_type,
                     'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' || l_analysis_alias,
                     i_id_institution,
                     0,
                     NULL);
            
                g_error := 'GET ANALYSIS_ALIAS_CODE';
                SELECT asta.code_ast_alias
                  INTO l_analysis_alias_code
                  FROM analysis_sample_type_alias asta
                 WHERE asta.id_analysis = i_id_analysis
                   AND asta.id_analysis = i_id_sample_type
                   AND asta.id_institution = i_id_institution
                   AND asta.id_software = 0;
            
                pk_translation.insert_into_translation(i_lang, l_analysis_alias_code, i_syn(i));
            
            ELSE
                IF i_syn(i) IS NOT NULL
                THEN
                    g_error := 'GET CODE_AST_ALIAS';
                    SELECT asta.code_ast_alias
                      INTO l_analysis_alias_code
                      FROM analysis_sample_type_alias asta
                     WHERE asta.id_analysis = i_id_analysis
                       AND asta.id_analysis = i_id_sample_type
                       AND asta.id_institution = i_id_institution
                       AND asta.id_software = 0;
                
                    g_error := 'UPDATE TRANSLATION';
                    pk_translation.insert_into_translation(i_lang       => i_lang,
                                                           i_code_trans => l_analysis_alias_code,
                                                           i_desc_trans => i_syn(i));
                ELSE
                    g_error := 'DELETE ANALYSIS_SAMPLE_TYPE_ALIAS';
                    DELETE FROM analysis_sample_type_alias asta
                     WHERE asta.id_analysis = i_id_analysis
                       AND asta.id_analysis = i_id_sample_type
                       AND asta.id_institution = i_id_institution;
                
                END IF;
            
            END IF;
            FOR j IN 1 .. i_loinc(i).count
            LOOP
                IF i_loinc_select(i) (j) = 'Y'
                   AND i_loinc(i) (j) IS NOT NULL
                THEN
                
                    SELECT COUNT(al.id_analysis_loinc)
                      INTO l_analysis_loinc_exist
                      FROM analysis_loinc al
                     WHERE al.id_analysis = i_id_analysis
                       AND al.id_sample_type = i_id_sample_type
                       AND al.id_institution = i_id_institution
                       AND al.id_software = i_id_software(i)
                       AND al.loinc_code = i_loinc(i) (j);
                
                    IF l_analysis_loinc_exist = 0
                    THEN
                    
                        g_error := 'DELETE FROM ANALYSIS_LOINC';
                        DELETE FROM analysis_loinc al
                         WHERE al.id_analysis = i_id_analysis
                           AND al.id_sample_type = i_id_sample_type
                           AND al.id_institution = i_id_institution
                           AND al.id_software = i_id_software(i);
                    
                        g_error := 'GET SEQ_ANALYSIS_LOINC.NEXTVAL';
                        SELECT seq_analysis_loinc.nextval
                          INTO l_analysis_loinc
                          FROM dual;
                    
                        g_error := 'INSERT INTO ANALYSIS_LOINC';
                        INSERT INTO analysis_loinc
                            (id_analysis_loinc,
                             id_analysis,
                             loinc_code,
                             id_institution,
                             id_software,
                             flg_default,
                             id_sample_type)
                        VALUES
                            (l_analysis_loinc,
                             i_id_analysis,
                             i_loinc(i) (j),
                             i_id_institution,
                             i_id_software(i),
                             i_loinc_default(i) (j),
                             i_id_sample_type);
                    
                    ELSE
                        UPDATE analysis_loinc al
                           SET al.flg_default = i_loinc_default(i) (j)
                         WHERE al.id_analysis = i_id_analysis
                           AND al.id_sample_type = i_id_sample_type
                           AND al.id_institution = i_id_institution
                           AND al.id_software = i_id_software(i)
                           AND al.loinc_code = i_loinc(i) (j);
                    END IF;
                
                ELSIF i_loinc_select(i) (j) = 'N'
                      AND i_loinc(i) (j) IS NOT NULL
                THEN
                    g_error := 'DELETE FROM ANALYSIS_LOINC';
                    DELETE FROM analysis_loinc al
                     WHERE al.id_analysis = i_id_analysis
                       AND al.id_sample_type = i_id_sample_type
                       AND al.id_institution = i_id_institution
                       AND al.id_software = i_id_software(i)
                       AND al.loinc_code = i_loinc(i) (j);
                
                END IF;
            
            END LOOP;
            FOR k IN 1 .. i_parameters(i).count
            LOOP
                IF i_parameters_select(i) (k) = 'Y'
                THEN
                    g_error := 'GET SEQ_ANALYSIS_PARAM.NEXTVAL';
                    SELECT seq_analysis_param.nextval
                      INTO l_analysis_param
                      FROM dual;
                
                    g_error := 'INSERT INTO ANALYSIS_PARAM';
                    INSERT INTO analysis_param
                        (id_analysis_param,
                         id_analysis,
                         flg_available,
                         id_institution,
                         id_software,
                         id_analysis_parameter,
                         id_sample_type)
                    VALUES
                        (l_analysis_param,
                         i_id_analysis,
                         'Y',
                         i_id_institution,
                         i_id_software(i),
                         i_parameters(i) (k),
                         i_id_sample_type);
                
                    g_error := 'GET SEQ_ANALYSIS_PARAM_FUNCIONALITY.NEXTVAL';
                
                    SELECT seq_analysis_param_func.nextval
                      INTO l_analysis_param_funcionality
                      FROM dual;
                
                    INSERT INTO analysis_param_funcionality
                        (id_analysis_param_funcionality,
                         flg_type,
                         adw_last_update,
                         id_analysis_param,
                         flg_fill_type,
                         rank)
                    VALUES
                        (l_analysis_param_funcionality, 'S', SYSDATE, l_analysis_param, '', 0);
                
                ELSIF i_parameters_select(i) (k) = 'N'
                THEN
                
                    SELECT ap.id_analysis_param
                      INTO l_analysis_param
                      FROM analysis_param ap
                     WHERE ap.id_analysis = i_id_analysis
                       AND ap.id_sample_type = i_id_sample_type
                       AND ap.id_institution = i_id_institution
                       AND ap.id_software = i_id_software(i)
                       AND ap.id_analysis_parameter = i_parameters(i) (k);
                
                    g_error := 'DELETE FROM ANALYSIS_PARAM_FUNCIONALITY';
                    DELETE FROM analysis_param_funcionality apf
                     WHERE apf.id_analysis_param = l_analysis_param;
                
                    g_error := 'DELETE FROM ANALYSIS_PARAM';
                    DELETE FROM analysis_param ap
                     WHERE ap.id_analysis = i_id_analysis
                       AND ap.id_sample_type = i_id_sample_type
                       AND ap.id_institution = i_id_institution
                       AND ap.id_software = i_id_software(i)
                       AND ap.id_analysis_parameter = i_parameters(i) (k);
                
                END IF;
            END LOOP;
        
            FOR l IN 1 .. i_lab(i).count
            LOOP
                IF i_lab_select(i) (l) = 'Y'
                   AND i_lab(i) (l) IS NOT NULL
                THEN
                    SELECT COUNT(ar.id_room)
                      INTO l_analysis_lab_exist
                      FROM analysis_room ar
                     WHERE ar.id_analysis = i_id_analysis
                       AND ar.id_sample_type = i_id_sample_type
                       AND ar.id_institution = i_id_institution
                       AND ar.flg_type = 'T'
                       AND ar.flg_available = 'Y'
                       AND ar.id_room = i_lab(i) (l);
                
                    IF l_analysis_lab_exist = 0
                    THEN
                        g_error := 'GET SEQ_ANALYSIS_ROOM.NEXTVAL';
                        SELECT seq_analysis_room.nextval
                          INTO l_analysis_lab
                          FROM dual;
                    
                        g_error := 'INSERT INTO ANALYSIS_ROOM 1';
                        INSERT INTO analysis_room
                            (id_analysis_room,
                             id_analysis,
                             id_room,
                             rank,
                             flg_type,
                             flg_available,
                             flg_default,
                             id_institution,
                             adw_last_update,
                             id_sample_type)
                        VALUES
                            (l_analysis_lab,
                             i_id_analysis,
                             i_lab(i) (l),
                             0,
                             'T',
                             'Y',
                             i_lab_default(i) (l),
                             i_id_institution,
                             SYSDATE,
                             i_id_sample_type);
                    
                    ELSE
                        SELECT COUNT(ar.id_room)
                          INTO l_analysis_lab_exist
                          FROM analysis_room ar
                         WHERE ar.id_analysis = i_id_analysis
                           AND ar.id_sample_type = i_id_sample_type
                           AND ar.id_institution = i_id_institution
                           AND ar.flg_type = 'T'
                           AND ar.flg_available = 'Y';
                    
                        IF l_analysis_lab_exist = 0
                        THEN
                            SELECT ar.flg_default
                              INTO l_analysis_lab_exist
                              FROM analysis_room ar
                             WHERE ar.id_analysis = i_id_analysis
                               AND ar.id_sample_type = i_id_sample_type
                               AND ar.id_institution = i_id_institution
                               AND ar.flg_type = 'T'
                               AND ar.flg_available = 'Y'
                               AND ar.id_room = i_lab(i) (l);
                        
                            IF l_analysis_lab_default != i_lab_default(i) (l)
                            THEN
                                g_error := 'UPDATE ANALYSIS_ROOM';
                                UPDATE analysis_room ar
                                   SET ar.flg_default = i_lab_default(i) (l)
                                 WHERE ar.id_analysis = i_id_analysis
                                   AND ar.id_sample_type = i_id_sample_type
                                   AND ar.id_institution = i_id_institution
                                   AND ar.id_room = i_lab(i) (l)
                                   AND ar.flg_type = 'T'
                                   AND ar.flg_available = g_flg_available;
                            END IF;
                        END IF;
                    END IF;
                ELSIF i_lab_select(i) (l) = 'N'
                      AND i_lab(i) (l) IS NOT NULL
                THEN
                    g_error := 'DELETE FROM ANALYSIS_ROOM';
                    DELETE FROM analysis_room ar
                     WHERE ar.id_analysis = i_id_analysis
                       AND ar.id_sample_type = i_id_sample_type
                       AND ar.id_institution = i_id_institution
                       AND ar.id_room = i_lab(i) (l)
                       AND ar.flg_type = 'T';
                END IF;
            END LOOP;
        
            IF i_flg_rec_lab = 'N'
            THEN
                FOR m IN 1 .. i_recipient(i).count
                LOOP
                    OPEN c_analysis_soft_inst;
                
                    LOOP
                        FETCH c_analysis_soft_inst
                            INTO l_analysis_soft_inst;
                        EXIT WHEN c_analysis_soft_inst%NOTFOUND;
                    
                        IF i_recipient_select(i) (m) = 'Y'
                        THEN
                        
                            SELECT COUNT(air.id_analysis_instit_recipient)
                              INTO l_analysis_inst_recip_exist
                              FROM analysis_instit_recipient air
                             WHERE air.id_analysis_instit_soft = l_analysis_soft_inst
                               AND air.id_sample_recipient = i_recipient(i) (m)
                               AND air.id_room IS NULL;
                        
                            IF l_analysis_inst_recip_exist = 0
                            THEN
                                g_error := 'GET SEQ_ANALYSIS_ROOM.NEXTVAL';
                                SELECT seq_analysis_instit_recipient.nextval
                                  INTO l_analysis_instit_recipient
                                  FROM dual;
                            
                                g_error := 'INSERT INTO ANALYSIS_INSTIT_RECIPIENT';
                                INSERT INTO analysis_instit_recipient
                                    (id_analysis_instit_recipient,
                                     id_analysis_instit_soft,
                                     id_sample_recipient,
                                     flg_default,
                                     id_room)
                                VALUES
                                    (l_analysis_instit_recipient,
                                     l_analysis_soft_inst,
                                     i_recipient(i) (m),
                                     i_recipient_default(i) (m),
                                     NULL);
                            ELSE
                                g_error := 'UPDATE ANALYSIS_INSTIT_RECIPIENT';
                                UPDATE analysis_instit_recipient air
                                   SET air.flg_default = i_recipient_default(i) (m)
                                 WHERE air.id_analysis_instit_soft = l_analysis_soft_inst
                                   AND air.id_sample_recipient = i_recipient(i) (m)
                                   AND air.id_room IS NULL;
                            END IF;
                        
                        ELSE
                            g_error := 'DELETE FROM ANALYSIS_INSTIT_RECIPIENT';
                            DELETE FROM analysis_instit_recipient air
                             WHERE air.id_analysis_instit_soft = l_analysis_soft_inst
                               AND air.id_sample_recipient = i_recipient(i) (m)
                               AND air.id_room IS NULL;
                        END IF;
                    
                    END LOOP;
                
                    CLOSE c_analysis_soft_inst;
                
                END LOOP;
            ELSE
                FOR m IN 1 .. i_recipient(i).count
                LOOP
                    OPEN c_analysis_soft_inst;
                
                    LOOP
                        FETCH c_analysis_soft_inst
                            INTO l_analysis_soft_inst;
                        EXIT WHEN c_analysis_soft_inst%NOTFOUND;
                    
                        IF i_recipient_select(i) (m) = 'Y'
                        THEN
                            SELECT COUNT(air.id_analysis_instit_recipient)
                              INTO l_analysis_inst_recip_exist
                              FROM analysis_instit_recipient air
                             WHERE air.id_analysis_instit_soft = l_analysis_soft_inst
                               AND air.id_sample_recipient = i_recipient(i) (m)
                               AND air.id_room = i_lab(i) (m);
                        
                            IF l_analysis_inst_recip_exist = 0
                            THEN
                                g_error := 'GET SEQ_ANALYSIS_ROOM.NEXTVAL';
                                SELECT seq_analysis_instit_recipient.nextval
                                  INTO l_analysis_instit_recipient
                                  FROM dual;
                            
                                g_error := 'INSERT INTO ANALYSIS_INSTIT_RECIPIENT';
                                INSERT INTO analysis_instit_recipient
                                    (id_analysis_instit_recipient,
                                     id_analysis_instit_soft,
                                     id_sample_recipient,
                                     flg_default,
                                     id_room)
                                VALUES
                                    (l_analysis_instit_recipient,
                                     l_analysis_soft_inst,
                                     i_recipient(i) (m),
                                     i_recipient_default(i) (m),
                                     i_lab(i) (m));
                            ELSE
                                g_error := 'UPDATE ANALYSIS_INSTIT_RECIPIENT';
                                UPDATE analysis_instit_recipient air
                                   SET air.flg_default = i_recipient_default(i) (m)
                                 WHERE air.id_analysis_instit_soft = l_analysis_soft_inst
                                   AND air.id_sample_recipient = i_recipient(i) (m)
                                   AND air.id_room = i_lab(i) (m);
                            END IF;
                        
                        ELSE
                            g_error := 'DELETE FROM ANALYSIS_INSTIT_RECIPIENT';
                            DELETE FROM analysis_instit_recipient air
                             WHERE air.id_analysis_instit_soft = l_analysis_soft_inst
                               AND air.id_sample_recipient = i_recipient(i) (m)
                               AND air.id_room = i_lab(i) (m);
                        END IF;
                    
                    END LOOP;
                
                    CLOSE c_analysis_soft_inst;
                
                END LOOP;
            END IF;
        
        END LOOP;
    
        -- MFF [ALERT-27380]
        IF l_tbl_id_room_quest.count > 0
        THEN
        
            g_error := 'Deleting old values';
            DELETE FROM analysis_questionnaire aq
             WHERE aq.id_analysis = i_id_analysis
               AND aq.id_sample_type = i_id_sample_type;
        
            FOR idx IN l_tbl_id_room_quest.first .. l_tbl_id_room_quest.last
            LOOP
                IF NOT pk_backoffice_mcdt.set_lab_questionnaire(i_lang,
                                                                i_id_analysis,
                                                                i_id_sample_type,
                                                                i_id_institution,
                                                                l_tbl_id_room_quest(idx),
                                                                l_tbl_timing(idx),
                                                                o_error)
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
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_INST_ANALYSIS');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_inst_analysis;

    /********************************************************************************************
    * Get Institution Exams Information
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution           Institution ID
    * @param i_id_exam                  Exam ID
    * @param i_id_software              Software ID
    * @param i_prof                     Object
    * @param o_inst_exam                Exam information
    * @param o_inst_exam_wf_mv_pat      Move patient?
    * @param o_inst_exam_wf_result      First result
    * @param o_inst_exam_room           Exam room
    * @param o_error                    Error
    *
    *
    * @return                           true or false on success or error
    *
    * @author                           JTS
    * @version                          0.1
    * @since                            2008/05/24
    ********************************************************************************************/
    FUNCTION get_inst_exam_all
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN interv_dep_clin_serv.id_institution%TYPE,
        i_id_exam             IN exam_dep_clin_serv.id_exam%TYPE,
        i_id_software         IN interv_dep_clin_serv.id_software%TYPE,
        i_prof                IN profissional,
        o_inst_exam           OUT pk_types.cursor_type,
        o_inst_exam_wf_mv_pat OUT pk_types.cursor_type,
        o_inst_exam_wf_result OUT pk_types.cursor_type,
        o_inst_exam_room      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET INST_EXAM CURSOR';
        OPEN o_inst_exam FOR
            SELECT DISTINCT e.id_exam id,
                            pk_translation.get_translation(i_lang, e.code_exam) name,
                            decode(e.flg_available, 'Y', 'A', 'I') flg_status,
                            e.id_exam_cat,
                            pk_translation.get_translation(i_lang, ec.code_exam_cat) exam_cat_desc,
                            pk_sysdomain.get_domain('EXAM.FLG_AVAILABLE', nvl(e.flg_available, g_yes), i_lang) state,
                            pk_date_utils.date_hour_chr_extend_tsz(i_lang, e.adw_last_update, i_prof) upd_date,
                            e.flg_type,
                            pk_sysdomain.get_domain('EXAM.FLG_TYPE', e.flg_type, i_lang) type_desc,
                            e.gender,
                            pk_sysdomain.get_domain('PATIENT.GENDER', nvl(e.gender, NULL), i_lang) genero,
                            e.age_min,
                            e.age_max
              FROM exam e, exam_cat ec
             WHERE e.id_exam = i_id_exam
               AND e.id_exam_cat = ec.id_exam_cat;
    
        g_error := 'GET INST_EXAM_WORKFLOW_MOVE_PATIENT CURSOR';
        OPEN o_inst_exam_wf_mv_pat FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL flg_mov_pat,
                   NULL mov_pat_desc,
                   (decode((SELECT COUNT(DISTINCT edcs.id_software)
                             FROM exam_dep_clin_serv edcs
                            WHERE edcs.id_exam = i_id_exam
                              AND edcs.id_institution = i_id_institution
                              AND edcs.flg_type IN ('P', 'E', 'C')
                              AND edcs.id_dep_clin_serv IS NULL),
                           0,
                           'N',
                           'Y')) soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   edcs.flg_mov_pat,
                   pk_sysdomain.get_domain('YES_NO', edcs.flg_mov_pat, i_lang) mov_pat_desc,
                   'Y' soft_active
              FROM exam_dep_clin_serv edcs, software s
             WHERE edcs.id_institution = i_id_institution
               AND edcs.id_exam = i_id_exam
               AND edcs.flg_type IN ('P', 'E', 'C')
               AND edcs.id_dep_clin_serv IS NULL
               AND edcs.id_software = s.id_software
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_mov_pat, NULL mov_pat_desc, 'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM exam_dep_clin_serv edcs, software s3
                                          WHERE edcs.id_institution = i_id_institution
                                            AND edcs.id_exam = i_id_exam
                                            AND edcs.flg_type IN ('P', 'E', 'C')
                                            AND edcs.id_dep_clin_serv IS NULL
                                            AND edcs.id_software = s3.id_software)
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software IN (SELECT DISTINCT edcs2.id_software
                                       FROM exam_dep_clin_serv edcs2
                                      WHERE edcs2.id_institution = i_id_institution
                                        AND edcs2.id_exam = i_id_exam
                                        AND edcs2.flg_type IN ('P', 'E', 'C')
                                        AND edcs2.id_dep_clin_serv IS NULL)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_mov_pat, NULL mov_pat_desc, 'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM exam_dep_clin_serv edcs, software s3
                                          WHERE edcs.id_institution = i_id_institution
                                            AND edcs.id_exam = i_id_exam
                                            AND edcs.flg_type IN ('P', 'E', 'C')
                                            AND edcs.id_dep_clin_serv IS NULL
                                            AND edcs.id_software = s3.id_software)
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT edcs2.id_software
                                           FROM exam_dep_clin_serv edcs2
                                          WHERE edcs2.id_institution = i_id_institution
                                            AND edcs2.id_exam = i_id_exam
                                            AND edcs2.flg_type IN ('P', 'E', 'C')
                                            AND edcs2.id_dep_clin_serv IS NULL);
    
        g_error := 'GET INST_EXAM_WORKFLOW_FIRST_RESULT CURSOR';
        OPEN o_inst_exam_wf_result FOR
            SELECT 0 id_software,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T047') software_name,
                   NULL flg_first_result,
                   NULL first_result_desc,
                   decode((SELECT COUNT(DISTINCT edcs.id_software)
                            FROM exam_dep_clin_serv edcs
                           WHERE edcs.id_exam = i_id_exam
                             AND edcs.id_institution = i_id_institution
                             AND edcs.flg_type IN ('P', 'E', 'C')
                             AND edcs.id_dep_clin_serv IS NULL),
                          0,
                          'N',
                          'Y') soft_active
              FROM dual
            UNION
            SELECT s.id_software,
                   s.name software_name,
                   edcs.flg_first_result,
                   pk_sysdomain.get_domain('EXAM_DEP_CLIN_SERV.FLG_FIRST_RESULT', edcs.flg_first_result, i_lang) first_result_desc,
                   'Y' soft_active
              FROM exam_dep_clin_serv edcs, software s
             WHERE edcs.id_institution = i_id_institution
               AND edcs.id_exam = i_id_exam
               AND edcs.flg_type IN ('P', 'E', 'C')
               AND edcs.id_dep_clin_serv IS NULL
               AND edcs.id_software = s.id_software
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_first_result, NULL first_result_desc, 'Y' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM exam_dep_clin_serv edcs, software s3
                                          WHERE edcs.id_institution = i_id_institution
                                            AND edcs.id_exam = i_id_exam
                                            AND edcs.flg_type IN ('P', 'E', 'C')
                                            AND edcs.id_dep_clin_serv IS NULL
                                            AND edcs.id_software = s3.id_software)
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software IN (SELECT DISTINCT edcs2.id_software
                                       FROM exam_dep_clin_serv edcs2
                                      WHERE edcs2.id_institution = i_id_institution
                                        AND edcs2.id_exam = i_id_exam
                                        AND edcs2.flg_type IN ('P', 'E', 'C')
                                        AND edcs2.id_dep_clin_serv IS NULL)
            UNION
            SELECT s.id_software, s.name software_name, NULL flg_first_result, NULL first_result_desc, 'N' soft_active
              FROM software s
             WHERE s.id_software NOT IN (SELECT s3.id_software
                                           FROM exam_dep_clin_serv edcs, software s3
                                          WHERE edcs.id_institution = i_id_institution
                                            AND edcs.id_exam = i_id_exam
                                            AND edcs.flg_type IN ('P', 'E', 'C')
                                            AND edcs.id_dep_clin_serv IS NULL
                                            AND edcs.id_software = s3.id_software)
               AND s.id_software IN (SELECT s2.id_software
                                       FROM software_institution si, software s2
                                      WHERE s2.flg_mni = g_flg_available
                                        AND si.id_software = s2.id_software
                                        AND si.id_institution = i_id_institution
                                        AND s2.id_software != 26)
               AND s.id_software NOT IN (SELECT DISTINCT edcs2.id_software
                                           FROM exam_dep_clin_serv edcs2
                                          WHERE edcs2.id_institution = i_id_institution
                                            AND edcs2.id_exam = i_id_exam
                                            AND edcs2.flg_type IN ('P', 'E', 'C')
                                            AND edcs2.id_dep_clin_serv IS NULL);
    
        g_error := 'GET INST_EXAM CURSOR';
        OPEN o_inst_exam_room FOR
            SELECT er.id_room id_room, nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_desc
              FROM exam_room er, room r, department d
             WHERE er.id_exam = i_id_exam
               AND er.flg_available = pk_exam_constant.g_available
               AND r.id_room = er.id_room
               AND d.id_department = r.id_department
               AND d.id_institution = i_id_institution
               AND rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_inst_exam);
                pk_types.open_my_cursor(o_inst_exam_wf_mv_pat);
                pk_types.open_my_cursor(o_inst_exam_wf_result);
                pk_types.open_my_cursor(o_inst_exam_room);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INST_EXAM_ALL');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_exam_all;

    /********************************************************************************************
    * Institution exam parametrization
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_exam               Exam ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID's
    * @param i_flg_mv_pat            Array - Move Patient flags
    * @param i_room                  Array - Move Patient rooms
    * @param i_first_result          Array - First to regist result
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/24
    ********************************************************************************************/
    FUNCTION set_inst_exam
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_exam        IN exam_dep_clin_serv.id_exam%TYPE,
        i_id_institution IN exam_dep_clin_serv.id_institution%TYPE,
        i_id_software    IN table_number,
        i_flg_mv_pat     IN table_varchar,
        i_room           IN table_number,
        i_first_result   IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam_room_count NUMBER := 0;
        l_exam_room       exam_room.id_exam_room%TYPE;
        l_room            exam_room.id_room%TYPE;
    
        l_edcs_flg_type exam_dep_clin_serv.flg_type%TYPE;
    
    BEGIN
    
        FOR i IN 1 .. i_id_software.count
        LOOP
            SELECT decode(edcs.flg_type, 'E', 'P', 'P', 'P', 'C', 'C')
              INTO l_edcs_flg_type
              FROM exam_dep_clin_serv edcs
             WHERE edcs.id_exam = i_id_exam
               AND edcs.id_institution = i_id_institution
               AND edcs.id_software = i_id_software(i)
               AND edcs.id_dep_clin_serv IS NULL
               AND edcs.flg_type IN ('P', 'E', 'C');
        
            g_error := 'UPDATE EXAM_DEP_CLIN_SERV';
            UPDATE exam_dep_clin_serv edcs
               SET edcs.flg_mov_pat      = i_flg_mv_pat(i),
                   edcs.flg_first_result = i_first_result(i),
                   edcs.flg_type         = l_edcs_flg_type
             WHERE edcs.id_exam = i_id_exam
               AND edcs.id_institution = i_id_institution
               AND edcs.id_software = i_id_software(i)
               AND edcs.id_dep_clin_serv IS NULL
               AND edcs.flg_type IN ('P', 'E', 'C');
        
            SELECT COUNT(er.id_exam_room)
              INTO l_exam_room_count
              FROM exam_room er, room r, department s, dept d, software_dept sd
             WHERE er.id_exam = i_id_exam
               AND er.id_room = r.id_room
               AND r.id_department = s.id_department
               AND s.id_institution = i_id_institution
               AND s.id_dept = d.id_dept
               AND d.id_dept = sd.id_dept
               AND sd.id_software = i_id_software(i);
        
            IF i_room(i) IS NOT NULL
            THEN
                IF l_exam_room_count = 0
                THEN
                
                    g_error := 'GET SEQ_EXAM_ROOM.NEXTVAL';
                    SELECT seq_exam_room.nextval
                      INTO l_exam_room
                      FROM dual;
                
                    g_error := 'INSERT INTO EXAM_ROOM';
                    INSERT INTO exam_room
                        (id_exam_room, id_exam, id_room, rank, adw_last_update, flg_available)
                    VALUES
                        (l_exam_room, i_id_exam, i_room(i), 0, SYSDATE, 'Y');
                
                ELSE
                
                    IF l_exam_room_count = 1
                    THEN
                    
                        SELECT DISTINCT er.id_room
                          INTO l_room
                          FROM exam_room er, room r, department s, dept d, software_dept sd
                         WHERE er.id_exam = i_id_exam
                           AND er.id_room = r.id_room
                           AND r.id_department = s.id_department
                           AND s.id_dept = d.id_dept
                           AND d.id_institution = i_id_institution
                           AND d.id_dept = sd.id_dept
                           AND sd.id_software = i_id_software(i);
                    
                        g_error := 'UPDATE EXAM_ROOM';
                        UPDATE exam_room er
                           SET er.id_room = i_room(i), er.flg_available = g_flg_available
                         WHERE er.id_exam = i_id_exam
                           AND er.id_room = l_room
                           AND er.id_exam_room IN (SELECT er.id_exam_room
                                                     FROM exam_room er, room r, department s, dept d, software_dept sd
                                                    WHERE er.id_exam = i_id_exam
                                                      AND er.id_room = r.id_room
                                                      AND r.id_department = s.id_department
                                                      AND s.id_dept = d.id_dept
                                                      AND d.id_institution = i_id_institution
                                                      AND d.id_dept = sd.id_dept
                                                      AND sd.id_software = i_id_software(i));
                    
                    END IF;
                
                END IF;
            
            ELSE
            
                IF l_exam_room_count = 1
                THEN
                    g_error := 'UPDATE EXAM_ROOM';
                    UPDATE exam_room er
                       SET er.flg_available = 'N'
                     WHERE er.id_exam = i_id_exam
                       AND er.id_room = (SELECT er.id_room
                                           FROM exam_room er, room r, department s, dept d, software_dept sd
                                          WHERE er.id_exam = i_id_exam
                                            AND er.id_room = r.id_room
                                            AND r.id_department = s.id_department
                                            AND s.id_institution = i_id_institution
                                            AND s.id_dept = d.id_dept
                                            AND d.id_dept = sd.id_dept
                                            AND sd.id_software = i_id_software(i));
                END IF;
            
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_MCDT', 'SET_INST_EXAM');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_inst_exam;

    /********************************************************************************************
    * Get Exams by Institution and Software
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_flg_image           Exam type
    * @param i_search              Search
    * @param o_list                Exams list
    * @param o_error               Error
    *
    * @value i_flg_image           {*} 'I' Image exams {*} 'O' Other exams
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/29
    ********************************************************************************************/
    FUNCTION get_inst_soft_exam_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_software    IN analysis_instit_soft.id_software%TYPE,
        i_flg_image      IN VARCHAR2,
        i_search         IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_backoffice_exam.get_inst_soft_exam_list(i_lang,
                                                          i_id_institution,
                                                          i_id_software,
                                                          i_flg_image,
                                                          i_search,
                                                          o_list,
                                                          o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INST_SOFT_EXAM_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_soft_exam_list;

    /********************************************************************************************
    * Set Analysis Types in different softwares
    *
    * @param i_lang            Prefered language ID
    * @param i_id_institution  Institution ID
    * @param i_software        Software ID
    * @param i_mcdt            Analysis ID / Exam ID / Intervention ID
    * @param i_flg_type        Types
    * @param i_context         Context
    * @param o_error           Error
    *
    *
    * @value i_context         {*} 'A' Analyis {*} 'E' Exams {*} 'I' Interventions
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2008/05/08
    ********************************************************************************************/
    FUNCTION set_inst_soft_mcdt_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN software.id_software%TYPE,
        i_mcdt           IN VARCHAR2,
        i_flg_type       IN VARCHAR2,
        i_context        IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis             analysis_instit_soft.id_analysis_instit_soft%TYPE;
        l_exam                 exam_dep_clin_serv.id_exam_dep_clin_serv%TYPE;
        l_interv               interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE;
        l_type                 analysis_instit_soft.flg_type%TYPE;
        l_analysis_instit_soft analysis_instit_soft.id_analysis_instit_soft%TYPE;
        l_mcdt_analysis        table_varchar2;
        l_missing_data         VARCHAR2(200);
    
        CURSOR c_analysis_inst_soft
        (
            c_id_software    IN analysis_instit_soft.id_software%TYPE,
            c_id_analysis    IN analysis_instit_soft.id_analysis%TYPE,
            c_id_sample_type IN analysis_instit_soft.id_sample_type%TYPE
        ) IS
            SELECT ais.flg_type
              FROM analysis_instit_soft ais
             WHERE ais.id_institution = i_id_institution
               AND ais.id_software = c_id_software
               AND ais.id_analysis = c_id_analysis
               AND ais.id_sample_type = c_id_sample_type;
    
        CURSOR c_exams_inst_soft
        (
            c_id_software IN exam_dep_clin_serv.id_software%TYPE,
            c_id_exam     IN exam_dep_clin_serv.id_exam%TYPE
        ) IS
            SELECT edcs.flg_type
              FROM exam_dep_clin_serv edcs
             WHERE edcs.id_institution = i_id_institution
               AND edcs.id_software = c_id_software
               AND edcs.id_exam = c_id_exam
               AND edcs.flg_type IN ('P', 'E', 'C');
    
        CURSOR c_interv_inst_soft
        (
            c_id_software IN interv_dep_clin_serv.id_software%TYPE,
            c_id_interv   IN interv_dep_clin_serv.id_intervention%TYPE
        ) IS
            SELECT idcs.flg_type
              FROM interv_dep_clin_serv idcs
             WHERE idcs.id_institution = i_id_institution
               AND idcs.id_software = c_id_software
               AND idcs.id_intervention = c_id_interv
               AND idcs.flg_type IN ('P', 'E', 'C');
    
        l_rows         table_varchar;
        l_rows_aux     table_varchar;
        l_rows_delidcs table_varchar;
        l_error        t_error_out;
    BEGIN
        IF i_context = 'A'
        THEN
        
            l_mcdt_analysis := pk_utils.str_split(i_mcdt, '|');
        
            IF i_flg_type = 'E'
            THEN
                OPEN c_analysis_inst_soft(i_software, l_mcdt_analysis(1), l_mcdt_analysis(2));
                FETCH c_analysis_inst_soft
                    INTO l_type;
                CLOSE c_analysis_inst_soft;
            
                IF l_type IS NULL
                THEN
                    g_error := 'GET SEQ_ANALYSIS_INSTIT_SOFT.NEXTVAL';
                    SELECT seq_analysis_instit_soft.nextval
                      INTO l_analysis
                      FROM dual;
                
                    g_error := 'INSERT INTO ANALYSIS_INST_SOFT';
                    INSERT INTO analysis_instit_soft
                        (id_analysis_instit_soft,
                         id_analysis,
                         id_sample_type,
                         flg_type,
                         id_institution,
                         id_software,
                         flg_available,
                         rank)
                    VALUES
                        (l_analysis,
                         l_mcdt_analysis(1),
                         l_mcdt_analysis(2),
                         i_flg_type,
                         i_id_institution,
                         i_software,
                         'Y',
                         0);
                ELSIF l_type = 'X'
                THEN
                    g_error := 'UPDATE ANALYSIS_INST_SOFT';
                    UPDATE analysis_instit_soft ais
                       SET ais.flg_type = 'E'
                     WHERE ais.id_analysis = l_mcdt_analysis(1)
                       AND ais.id_sample_type = l_mcdt_analysis(2)
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_software;
                ELSIF l_type = 'W'
                THEN
                    g_error := 'UPDATE ANALYSIS_INST_SOFT';
                    UPDATE analysis_instit_soft ais
                       SET ais.flg_type = 'P'
                     WHERE ais.id_analysis = l_mcdt_analysis(1)
                       AND ais.id_sample_type = l_mcdt_analysis(2)
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_software;
                ELSIF l_type = 'C'
                THEN
                    l_missing_data := get_missing_data(i_lang, i_mcdt, i_id_institution, i_software, i_context);
                    IF l_missing_data IS NULL
                    THEN
                        g_error := 'UPDATE ANALYSIS_INST_SOFT';
                        UPDATE analysis_instit_soft ais
                           SET ais.flg_type = 'P'
                         WHERE ais.id_analysis = l_mcdt_analysis(1)
                           AND ais.id_sample_type = l_mcdt_analysis(2)
                           AND ais.id_institution = i_id_institution
                           AND ais.id_software = i_software;
                    ELSE
                        g_error := 'UPDATE ANALYSIS_INST_SOFT';
                        UPDATE analysis_instit_soft ais
                           SET ais.flg_type = 'E'
                         WHERE ais.id_analysis = l_mcdt_analysis(1)
                           AND ais.id_sample_type = l_mcdt_analysis(2)
                           AND ais.id_institution = i_id_institution
                           AND ais.id_software = i_software;
                    END IF;
                END IF;
            ELSIF i_flg_type = 'X'
            THEN
                OPEN c_analysis_inst_soft(i_software, l_mcdt_analysis(1), l_mcdt_analysis(2));
                FETCH c_analysis_inst_soft
                    INTO l_type;
                CLOSE c_analysis_inst_soft;
            
                IF l_type IS NULL
                THEN
                    g_error := 'GET SEQ_ANALYSIS_INSTIT_SOFT.NEXTVAL';
                    SELECT seq_analysis_instit_soft.nextval
                      INTO l_analysis
                      FROM dual;
                
                    g_error := 'INSERT INTO ANALYSIS_INST_SOFT';
                    INSERT INTO analysis_instit_soft
                        (id_analysis_instit_soft,
                         id_analysis,
                         id_sample_type,
                         flg_type,
                         id_institution,
                         id_software,
                         flg_available,
                         rank)
                    VALUES
                        (l_analysis,
                         l_mcdt_analysis(1),
                         l_mcdt_analysis(2),
                         i_flg_type,
                         i_id_institution,
                         i_software,
                         'Y',
                         0);
                ELSIF l_type = 'E'
                THEN
                    g_error := 'UPDATE ANALYSIS_INST_SOFT';
                    UPDATE analysis_instit_soft ais
                       SET ais.flg_type = 'X'
                     WHERE ais.id_analysis = l_mcdt_analysis(1)
                       AND ais.id_sample_type = l_mcdt_analysis(2)
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_software;
                ELSIF l_type = 'P'
                THEN
                    g_error := 'UPDATE ANALYSIS_INST_SOFT';
                    UPDATE analysis_instit_soft ais
                       SET ais.flg_type = 'W'
                     WHERE ais.id_analysis = l_mcdt_analysis(1)
                       AND ais.id_sample_type = l_mcdt_analysis(2)
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_software;
                ELSIF l_type = 'C'
                THEN
                    l_missing_data := get_missing_data(i_lang, i_mcdt, i_id_institution, i_software, i_context);
                    IF l_missing_data IS NULL
                    THEN
                        g_error := 'UPDATE ANALYSIS_INST_SOFT';
                        UPDATE analysis_instit_soft ais
                           SET ais.flg_type = 'W'
                         WHERE ais.id_analysis = l_mcdt_analysis(1)
                           AND ais.id_sample_type = l_mcdt_analysis(2)
                           AND ais.id_institution = i_id_institution
                           AND ais.id_software = i_software;
                    ELSE
                        g_error := 'UPDATE ANALYSIS_INST_SOFT';
                        UPDATE analysis_instit_soft ais
                           SET ais.flg_type = 'X'
                         WHERE ais.id_analysis = l_mcdt_analysis(1)
                           AND ais.id_sample_type = l_mcdt_analysis(2)
                           AND ais.id_institution = i_id_institution
                           AND ais.id_software = i_software;
                    END IF;
                END IF;
            ELSIF i_flg_type = 'C'
            THEN
                OPEN c_analysis_inst_soft(i_software, l_mcdt_analysis(1), l_mcdt_analysis(2));
                FETCH c_analysis_inst_soft
                    INTO l_type;
                CLOSE c_analysis_inst_soft;
            
                IF l_type IS NULL
                THEN
                    g_error := 'GET SEQ_ANALYSIS_INSTIT_SOFT.NEXTVAL';
                    SELECT seq_analysis_instit_soft.nextval
                      INTO l_analysis
                      FROM dual;
                
                    g_error := 'INSERT INTO ANALYSIS_INST_SOFT';
                    INSERT INTO analysis_instit_soft
                        (id_analysis_instit_soft,
                         id_analysis,
                         id_sample_type,
                         flg_type,
                         id_institution,
                         id_software,
                         flg_available,
                         rank)
                    VALUES
                        (l_analysis,
                         l_mcdt_analysis(1),
                         l_mcdt_analysis(2),
                         i_flg_type,
                         i_id_institution,
                         i_software,
                         'Y',
                         0);
                ELSE
                    g_error := 'UPDATE ANALYSIS_INST_SOFT';
                    UPDATE analysis_instit_soft ais
                       SET ais.flg_type = i_flg_type
                     WHERE ais.id_analysis = l_mcdt_analysis(1)
                       AND ais.id_sample_type = l_mcdt_analysis(2)
                       AND ais.id_institution = i_id_institution
                       AND ais.id_software = i_software;
                END IF;
            ELSIF i_flg_type = 'I'
            THEN
                SELECT id_analysis_instit_soft
                  INTO l_analysis_instit_soft
                  FROM analysis_instit_soft ais
                 WHERE ais.id_analysis = l_mcdt_analysis(1)
                   AND ais.id_sample_type = l_mcdt_analysis(2)
                   AND ais.id_institution = i_id_institution
                   AND ais.id_software = i_software;
            
                g_error := 'DELETE FROM ANALYSIS_INSTIT_RECIPIENT';
                DELETE FROM analysis_instit_recipient air
                 WHERE air.id_analysis_instit_soft = l_analysis_instit_soft;
            
                g_error := 'DELETE FROM ANALYSIS_PARAM_FUNCIONALITY';
            
                DELETE FROM analysis_param_funcionality apf
                 WHERE apf.id_analysis_param_funcionality IN
                       (SELECT DISTINCT apf.id_analysis_param_funcionality
                          FROM analysis_param_funcionality apf, analysis_param ap
                         WHERE apf.id_analysis_param = ap.id_analysis_param
                           AND ap.id_institution = i_id_institution
                           AND ap.id_software = i_software
                           AND ap.id_analysis = l_mcdt_analysis(1)
                           AND ap.id_sample_type = l_mcdt_analysis(2));
            
                g_error := 'DELETE FROM ANALYSIS_PARAM';
                DELETE FROM analysis_param ap
                 WHERE ap.id_analysis = l_mcdt_analysis(1)
                   AND ap.id_sample_type = l_mcdt_analysis(2)
                   AND ap.id_institution = i_id_institution
                   AND ap.id_software = i_software;
            
                g_error := 'DELETE FROM ANALYSIS_COLLECTION_INT';
                DELETE FROM analysis_collection_int aci
                 WHERE aci.id_analysis_collection IN
                       (SELECT ac.id_analysis_collection
                          FROM analysis_collection ac
                         WHERE ac.id_analysis_instit_soft = l_analysis_instit_soft);
            
                g_error := 'DELETE FROM ANALYSIS_COLLECTION';
                DELETE FROM analysis_collection ac
                 WHERE ac.id_analysis_instit_soft = l_analysis_instit_soft;
            
                g_error := 'DELETE FROM ANALYSIS_INST_SOFT';
                DELETE FROM analysis_instit_soft ais
                 WHERE ais.id_analysis = l_mcdt_analysis(1)
                   AND ais.id_sample_type = l_mcdt_analysis(2)
                   AND ais.id_institution = i_id_institution
                   AND ais.id_software = i_software;
            
                g_error := 'DELETE FROM ANALYSIS_DEP_CLIN_SERV';
                DELETE FROM analysis_dep_clin_serv adcs
                 WHERE adcs.id_analysis = l_mcdt_analysis(1)
                   AND adcs.id_sample_type = l_mcdt_analysis(2)
                   AND adcs.id_software = i_software
                   AND adcs.id_dep_clin_serv IN (SELECT dcs.id_dep_clin_serv
                                                   FROM dep_clin_serv dcs, department s
                                                  WHERE dcs.id_department = s.id_department
                                                    AND s.id_institution = i_id_institution);
            
            END IF;
        ELSIF i_context = 'E'
        THEN
            IF i_flg_type = 'E'
            THEN
                OPEN c_exams_inst_soft(i_software, i_mcdt);
                FETCH c_exams_inst_soft
                    INTO l_type;
                CLOSE c_exams_inst_soft;
            
                IF l_type IS NULL
                THEN
                    g_error := 'GET SEQ_EXAM_DEP_CLIN_SERV.NEXTVAL';
                    SELECT seq_exam_dep_clin_serv.nextval
                      INTO l_exam
                      FROM dual;
                
                    g_error := 'INSERT INTO EXAM_DEP_CLIN_SERV';
                    INSERT INTO exam_dep_clin_serv
                        (id_exam_dep_clin_serv, id_exam, flg_type, id_institution, id_software, rank)
                    VALUES
                        (l_exam, i_mcdt, i_flg_type, i_id_institution, i_software, 0);
                ELSIF l_type = 'C'
                THEN
                    g_error := 'UPDATE EXAM_DEP_CLIN_SERV';
                    UPDATE exam_dep_clin_serv edcs
                       SET edcs.flg_type = i_flg_type
                     WHERE edcs.id_exam = i_mcdt
                       AND edcs.id_institution = i_id_institution
                       AND edcs.id_software = i_software
                       AND edcs.id_dep_clin_serv IS NULL;
                END IF;
            ELSIF i_flg_type = 'C'
            THEN
                OPEN c_exams_inst_soft(i_software, i_mcdt);
                FETCH c_exams_inst_soft
                    INTO l_type;
                CLOSE c_exams_inst_soft;
            
                IF l_type IS NULL
                THEN
                    g_error := 'GET SEQ_EXAM_DEP_CLIN_SERV.NEXTVAL';
                    SELECT seq_exam_dep_clin_serv.nextval
                      INTO l_exam
                      FROM dual;
                
                    g_error := 'INSERT INTO EXAM_DEP_CLIN_SERV';
                    INSERT INTO exam_dep_clin_serv
                        (id_exam_dep_clin_serv, id_exam, flg_type, id_institution, id_software, rank)
                    VALUES
                        (l_exam, i_mcdt, i_flg_type, i_id_institution, i_software, 0);
                ELSIF l_type = 'P'
                      OR l_type = 'E'
                THEN
                    g_error := 'UPDATE EXAM_DEP_CLIN_SERV';
                    UPDATE exam_dep_clin_serv edcs
                       SET edcs.flg_type = i_flg_type
                     WHERE edcs.id_exam = i_mcdt
                       AND edcs.id_institution = i_id_institution
                       AND edcs.id_software = i_software
                       AND edcs.id_dep_clin_serv IS NULL;
                END IF;
            ELSIF i_flg_type = 'I'
            THEN
                g_error := 'DELETE FROM EXAM_DEP_CLIN_SERV';
                DELETE FROM exam_dep_clin_serv edcs
                 WHERE edcs.id_exam = i_mcdt
                   AND edcs.id_institution = i_id_institution
                   AND edcs.id_software = i_software
                   AND edcs.flg_type IN ('P', 'E', 'C');
            
                g_error := 'DELETE FROM EXAM_DEP_CLIN_SERV';
                DELETE FROM exam_dep_clin_serv edcs
                 WHERE edcs.id_exam = i_mcdt
                   AND edcs.id_software = i_software
                   AND edcs.id_dep_clin_serv IN (SELECT dcs.id_dep_clin_serv
                                                   FROM dep_clin_serv dcs, department s
                                                  WHERE dcs.id_department = s.id_department
                                                    AND s.id_institution = i_id_institution);
            END IF;
        ELSIF i_context = 'I'
        THEN
            IF i_flg_type = 'E'
            THEN
                OPEN c_interv_inst_soft(i_software, i_mcdt);
                FETCH c_interv_inst_soft
                    INTO l_type;
                CLOSE c_interv_inst_soft;
            
                IF l_type IS NULL
                THEN
                    g_error := 'INSERT INTO INTERV_DEP_CLIN_SERV';
                    ts_interv_dep_clin_serv.ins(id_interv_dep_clin_serv_out => l_interv,
                                                id_intervention_in          => i_mcdt,
                                                flg_type_in                 => i_flg_type,
                                                id_institution_in           => i_id_institution,
                                                id_software_in              => i_software,
                                                rank_in                     => 0,
                                                rows_out                    => l_rows);
                
                    t_data_gov_mnt.process_insert(i_lang, i_prof, 'INTERV_DEP_CLIN_SERV', l_rows, l_error);
                
                ELSIF l_type = 'C'
                THEN
                    g_error := 'UPDATE EXAM_DEP_CLIN_SERV';
                    l_rows  := table_varchar();
                    ts_interv_dep_clin_serv.upd(flg_type_in  => i_flg_type,
                                                flg_type_nin => FALSE,
                                                where_in     => 'id_intervention = ' || i_mcdt || '
                       AND id_institution = ' ||
                                                                i_id_institution || '
                       AND id_software = ' || i_software || '
                       AND id_dep_clin_serv IS NULL',
                                                rows_out     => l_rows);
                
                    t_data_gov_mnt.process_update(i_lang,
                                                  i_prof,
                                                  'INTERV_DEP_CLIN_SERV',
                                                  l_rows,
                                                  l_error,
                                                  table_varchar('FLG_TYPE'));
                END IF;
            ELSIF i_flg_type = 'C'
            THEN
                OPEN c_interv_inst_soft(i_software, i_mcdt);
                FETCH c_interv_inst_soft
                    INTO l_type;
                CLOSE c_interv_inst_soft;
            
                IF l_type IS NULL
                THEN
                    g_error := 'INSERT INTO INTERV_DEP_CLIN_SERV';
                    ts_interv_dep_clin_serv.ins(id_interv_dep_clin_serv_out => l_interv,
                                                id_intervention_in          => i_mcdt,
                                                flg_type_in                 => i_flg_type,
                                                id_institution_in           => i_id_institution,
                                                id_software_in              => i_software,
                                                rank_in                     => 0,
                                                rows_out                    => l_rows);
                
                    t_data_gov_mnt.process_insert(i_lang, i_prof, 'INTERV_DEP_CLIN_SERV', l_rows, l_error);
                
                ELSIF l_type = 'P'
                      OR l_type = 'E'
                THEN
                    g_error := 'UPDATE EXAM_DEP_CLIN_SERV';
                    l_rows  := table_varchar();
                    ts_interv_dep_clin_serv.upd(flg_type_in  => i_flg_type,
                                                flg_type_nin => FALSE,
                                                where_in     => 'id_intervention = ' || i_mcdt || '
                       AND id_institution = ' ||
                                                                i_id_institution || '
                       AND id_software = ' || i_software || '
                       AND id_dep_clin_serv IS NULL',
                                                rows_out     => l_rows);
                
                    t_data_gov_mnt.process_update(i_lang,
                                                  i_prof,
                                                  'INTERV_DEP_CLIN_SERV',
                                                  l_rows,
                                                  l_error,
                                                  table_varchar('FLG_TYPE'));
                
                END IF;
            ELSIF i_flg_type = 'I'
            THEN
                g_error := 'DELETE FROM INTERV_DEP_CLIN_SERV';
                ts_interv_dep_clin_serv.del_by(where_clause_in => 'id_intervention = ' || i_mcdt || '
                   AND id_institution = ' ||
                                                                  i_id_institution || '
                   AND id_software = ' || i_software || '
                   AND flg_type IN (''P'', ''E'', ''C'')',
                                               rows_out        => l_rows_delidcs);
            
                g_error := 'DELETE FROM INTERV_DEP_CLIN_SERV';
                ts_interv_dep_clin_serv.del_by(where_clause_in => 'id_intervention = ' || i_mcdt || '
                   AND id_software = ' || i_software || '
                   AND id_dep_clin_serv IN (SELECT dcs.id_dep_clin_serv
                                                   FROM dep_clin_serv dcs, department s
                                                  WHERE dcs.id_department = s.id_department
                                                    AND s.id_institution = ' ||
                                                                  i_id_institution || ')',
                                               rows_out        => l_rows_aux);
            
                l_rows_delidcs := l_rows_delidcs MULTISET UNION l_rows_aux;
            
                t_data_gov_mnt.process_delete(i_lang, i_prof, 'INTERV_DEP_CLIN_SERV', l_rows_delidcs, l_error);
            END IF;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'SET_INST_SOFT_MCDT_STATE');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_inst_soft_mcdt_state;

    /********************************************************************************************
    * Get Interventions categories
    *
    * @param i_lang            Prefered language ID
    * @param o_list            Categories list
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2008/05/29
    ********************************************************************************************/
    FUNCTION get_interv_cat_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
        
            SELECT *
              FROM (SELECT ic.id_interv_category,
                           pk_translation.get_translation(i_lang, ic.code_interv_category) interv_category_desc
                      FROM interv_category ic
                     WHERE ic.flg_available = pk_alert_constant.g_yes) t
             WHERE t.interv_category_desc IS NOT NULL
            -- JB 01-04-2011 ALERT-163151
             ORDER BY t.interv_category_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_INTERV_CAT_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_interv_cat_list;

    /********************************************************************************************
    * Verify MCDT's missing data
    *
    * @param i_lang                  Prefered language ID
    * @param i_mcdt                  Analysis ID / Exams ID / Interventions ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param i_context               Context
    *
    * @value i_context               {*} 'A' Analyis {*} 'E' Exams {*} 'I' Interventions
    *
    * @return                      NULL or MISSING DATA
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/06/01
    ********************************************************************************************/
    FUNCTION get_missing_data
    (
        i_lang           IN language.id_language%TYPE,
        i_mcdt           IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_context        IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_analysis_count
        (
            c_analysis       IN analysis_instit_soft.id_analysis%TYPE,
            c_sample_type    IN analysis_instit_soft.id_sample_type%TYPE,
            c_id_institution IN analysis_instit_soft.id_institution%TYPE
        ) IS
            SELECT DISTINCT (COUNT(decode(ais.flg_mov_pat, '', 'NULL', 'N')) +
                            COUNT(decode(ais.flg_first_result, '', 'NULL', 'N')) +
                            COUNT(decode(ais.flg_mov_recipient, '', 'NULL', 'N')) +
                            COUNT(decode(ais.flg_harvest, '', 'NULL', 'N')))
              FROM analysis_instit_soft ais
             WHERE ais.id_institution = c_id_institution
               AND ais.id_analysis = c_analysis
               AND ais.id_sample_type = c_sample_type;
    
        CURSOR c_exam_count
        (
            c_id_exam        IN exam_dep_clin_serv.id_exam%TYPE,
            c_id_institution IN exam_dep_clin_serv.id_institution%TYPE
        ) IS
            SELECT DISTINCT (COUNT(decode(edcs.flg_first_result, '', 'NULL', 'N')) +
                            COUNT(decode(edcs.flg_mov_pat, '', 'NULL', 'N')))
              FROM exam_dep_clin_serv edcs
             WHERE edcs.id_exam = c_id_exam
               AND edcs.id_institution = c_id_institution
               AND edcs.flg_type IN ('P', 'E', 'C')
               AND edcs.id_dep_clin_serv IS NULL;
    
        CURSOR c_interv_count
        (
            c_interv         IN interv_dep_clin_serv.id_intervention%TYPE,
            c_id_institution IN interv_dep_clin_serv.id_institution%TYPE
        ) IS
            SELECT DISTINCT (COUNT(decode(idcs.flg_bandaid, '', 'NULL', 'N')) +
                            COUNT(decode(idcs.flg_chargeable, '', 'NULL', 'N')))
              FROM interv_dep_clin_serv idcs
             WHERE idcs.id_dep_clin_serv IS NULL
               AND idcs.flg_type IN ('P', 'E', 'C')
               AND idcs.id_institution = c_id_institution
               AND idcs.id_intervention = c_interv;
    
        CURSOR c_analysis
        (
            c_analysis       IN analysis_instit_soft.id_analysis%TYPE,
            c_sample_type    IN analysis_instit_soft.id_sample_type%TYPE,
            c_id_institution IN analysis_instit_soft.id_institution%TYPE
        ) IS
            SELECT DISTINCT ais.flg_mov_pat, ais.flg_first_result, ais.flg_mov_recipient, ais.flg_harvest
              FROM analysis_instit_soft ais
             WHERE ais.id_institution = c_id_institution
               AND ais.id_analysis = c_analysis
               AND ais.id_sample_type = c_sample_type;
    
        CURSOR c_exam
        (
            c_id_exam        IN exam_dep_clin_serv.id_exam%TYPE,
            c_id_institution IN exam_dep_clin_serv.id_institution%TYPE
        ) IS
            SELECT DISTINCT edcs.flg_first_result, edcs.flg_mov_pat
              FROM exam_dep_clin_serv edcs
             WHERE edcs.id_exam = c_id_exam
               AND edcs.id_institution = c_id_institution
               AND edcs.flg_type IN ('P', 'E', 'C')
               AND edcs.id_dep_clin_serv IS NULL;
    
        CURSOR c_interv
        (
            c_interv         IN interv_dep_clin_serv.id_intervention%TYPE,
            c_id_institution IN interv_dep_clin_serv.id_institution%TYPE
        ) IS
            SELECT DISTINCT idcs.flg_bandaid, idcs.flg_chargeable
              FROM interv_dep_clin_serv idcs
             WHERE idcs.id_dep_clin_serv IS NULL
               AND idcs.flg_type IN ('P', 'E', 'C')
               AND idcs.id_institution = c_id_institution
               AND idcs.id_intervention = c_interv;
    
        l_analysis_count   NUMBER := 0;
        l_exam_count       NUMBER := 0;
        l_interv_count     NUMBER := 0;
        l_flg_first_result exam_dep_clin_serv.flg_first_result%TYPE;
        l_flg_mv_pat       exam_dep_clin_serv.flg_mov_pat%TYPE;
        l_flg_mv_recipient analysis_instit_soft.flg_mov_recipient%TYPE;
        l_flg_harvest      analysis_instit_soft.flg_harvest%TYPE;
        l_flg_bandaid      interv_dep_clin_serv.flg_bandaid%TYPE;
        l_flg_chargeable   interv_dep_clin_serv.flg_chargeable%TYPE;
        l_res              VARCHAR2(200) := NULL;
    
        l_mcdt_analysis table_varchar2;
    
    BEGIN
    
        IF i_context = 'A'
        THEN
            l_mcdt_analysis := pk_utils.str_split(i_mcdt, '|');
        
            g_error := 'OPEN C_ANALYSIS_COUNT';
            OPEN c_analysis_count(l_mcdt_analysis(1), l_mcdt_analysis(2), i_id_institution);
            FETCH c_analysis_count
                INTO l_analysis_count;
            IF l_analysis_count > 0
            THEN
                g_error := 'OPEN C_ANALYSIS';
                OPEN c_analysis(l_mcdt_analysis(1), l_mcdt_analysis(2), i_id_institution);
                LOOP
                    FETCH c_analysis
                        INTO l_flg_mv_pat, l_flg_first_result, l_flg_mv_recipient, l_flg_harvest;
                    IF l_flg_first_result IS NULL
                       OR l_flg_mv_pat IS NULL
                       OR l_flg_mv_recipient IS NULL
                       OR l_flg_harvest IS NULL
                    THEN
                        l_res := pk_message.get_message(i_lang, 'ADMINISTRATOR_T063');
                    END IF;
                    EXIT WHEN c_analysis%NOTFOUND;
                END LOOP;
                CLOSE c_analysis;
            END IF;
        ELSIF i_context IN ('I', 'O')
        THEN
            g_error := 'OPEN C_EXAM_COUNT';
            OPEN c_exam_count(i_mcdt, i_id_institution);
            FETCH c_exam_count
                INTO l_exam_count;
            IF l_exam_count > 0
            THEN
                g_error := 'OPEN C_EXAM';
                OPEN c_exam(i_mcdt, i_id_institution);
                LOOP
                    FETCH c_exam
                        INTO l_flg_first_result, l_flg_mv_pat;
                    IF l_flg_first_result IS NULL
                       OR l_flg_mv_pat IS NULL
                    THEN
                        l_res := pk_message.get_message(i_lang, 'ADMINISTRATOR_T063');
                    END IF;
                    EXIT WHEN c_exam%NOTFOUND;
                END LOOP;
                CLOSE c_exam;
            END IF;
        
        ELSIF i_context IN ('P', 'M')
        THEN
            g_error := 'OPEN C_INTERV_COUNT';
            OPEN c_interv_count(i_mcdt, i_id_institution);
            FETCH c_interv_count
                INTO l_interv_count;
            IF l_interv_count > 0
            THEN
            
                g_error := 'OPEN C_INTERV';
                OPEN c_interv(i_mcdt, i_id_institution);
                LOOP
                    FETCH c_interv
                        INTO l_flg_bandaid, l_flg_chargeable;
                    IF l_flg_bandaid IS NULL
                       OR l_flg_chargeable IS NULL
                    THEN
                        l_res := pk_message.get_message(i_lang, 'ADMINISTRATOR_T063');
                    END IF;
                    EXIT WHEN c_interv%NOTFOUND;
                END LOOP;
                CLOSE c_interv;
            END IF;
        END IF;
    
        RETURN l_res;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_missing_data;

    /********************************************************************************************
    * Get all sample recipient
    *
    * @param i_lang           Prefered language ID
    * @param i_search         Search
    * @param o_recipient_list Sample recipients
    * @param o_error          Error
    *
    *
    * @return                 true or false on success or error
    *
    * @author                 JTS
    * @version                0.1
    * @since                  2008/08/20
    ********************************************************************************************/
    FUNCTION get_sample_recipient_all
    (
        i_lang           IN language.id_language%TYPE,
        i_search         IN VARCHAR2,
        o_recipient_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET RECIPIENT LIST CURSOR';
    
        IF i_search IS NULL
        THEN
            OPEN o_recipient_list FOR
                SELECT sr.id_sample_recipient id,
                       pk_translation.get_translation(i_lang, sr.code_sample_recipient) name,
                       sr.capacity,
                       decode(sr.flg_available, 'Y', 'A', 'I') flg_status
                  FROM sample_recipient sr
                 WHERE pk_translation.get_translation(i_lang, sr.code_sample_recipient) IS NOT NULL
                 ORDER BY flg_status, name;
        ELSE
            OPEN o_recipient_list FOR
                SELECT sr.id_sample_recipient id,
                       pk_translation.get_translation(i_lang, sr.code_sample_recipient) name,
                       sr.capacity,
                       decode(sr.flg_available, 'Y', 'A', 'I') flg_status
                  FROM sample_recipient sr
                 WHERE translate(upper(pk_translation.get_translation(i_lang, sr.code_sample_recipient)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND pk_translation.get_translation(i_lang, sr.code_sample_recipient) IS NOT NULL
                 ORDER BY flg_status, name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_recipient_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_SAMPLE_RECIPIENT_ALL');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_sample_recipient_all;

    /********************************************************************************************
    * Get possible list for analysis workflow
    *
    * @param i_lang                Prefered language ID
    * @param o_list                cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      TÈrcio Soares
    * @version                     0.1
    * @since                       2008/12/22
    ********************************************************************************************/
    FUNCTION get_analysis_yes_no_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT desc_val, val, img_name, rank
              FROM sys_domain s
             WHERE s.code_domain = 'YES_NO'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
               AND s.flg_available = g_flg_available
            UNION
            SELECT pk_message.get_message(i_lang, 'ADMINISTRATOR_T205') desc_val, NULL val, NULL img_name, NULL rank
              FROM dual
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_MCDT',
                                   'GET_ANALYSIS_YES_NO_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_analysis_yes_no_list;

    /********************************************************************************************
    * Get MCDT state in institution and software's
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id                    MCDT identification
    * @param i_software              Software ID's
    * @param i_context               Context
    *
    *
    * @value     i_context          {*} 'A' Analyis {*} 'I' Image exams {*} 'O' Others Exams {*} 'P' Interventions   
    *                               {*} 'M' MFR Interventions
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.5.0.7.2
    * @since                       2009/11/11
    ********************************************************************************************/
    FUNCTION get_inst_pesq_state
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id             IN VARCHAR2,
        i_software       IN table_number,
        i_context        IN VARCHAR2
    ) RETURN table_varchar IS
    
        l_type_pesq     VARCHAR2(200);
        l_type_exec     VARCHAR2(200);
        l_type_inactive VARCHAR2(200);
        l_type_conv     VARCHAR2(200);
        l_id_market     NUMBER(24);
    
        l_error t_error_out;
    
        l_state_cur pk_types.cursor_type;
    
        l_data table_varchar;
    
        l_id table_varchar2;
    
    BEGIN
    
        l_type_pesq     := pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE', 'E', i_lang);
        l_type_exec     := pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE', 'X', i_lang);
        l_type_conv     := pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE', 'C', i_lang);
        l_type_inactive := pk_sysdomain.get_domain('BO_ANALYSIS_INSTIT_SOFT.FLG_TYPE', 'I', i_lang);
    
        IF i_context = 'A'
        THEN
            l_id := pk_utils.str_split(i_id, '|');
        
            g_error := 'GET INST_ANALYSIS_LIST CURSOR';
            OPEN l_state_cur FOR
                SELECT to_char(id_software) || ',' || ais.flg_type || ',' ||
                       decode(ais.flg_type,
                              'P',
                              l_type_pesq,
                              'E',
                              l_type_pesq,
                              'W',
                              l_type_exec,
                              'X',
                              l_type_exec,
                              'C',
                              l_type_conv)
                  FROM analysis_instit_soft ais
                 WHERE ais.id_institution = i_id_institution
                   AND ais.id_analysis = l_id(1)
                   AND ais.id_sample_type = l_id(2)
                   AND ais.flg_available = g_flg_available
                   AND ais.id_software IN (SELECT column_value
                                             FROM TABLE(CAST(i_software AS table_number)));
        
            FETCH l_state_cur BULK COLLECT
                INTO l_data;
        
            CLOSE l_state_cur;
        
        ELSIF i_context IN ('I', 'O')
        THEN
        
            g_error := 'GET INST_IMAGE_EXAM_LIST CURSOR';
            OPEN l_state_cur FOR
                SELECT to_char(id_software) || ',' || decode(edcs.flg_type, 'P', 'E', edcs.flg_type) || ',' ||
                       pk_sysdomain.get_domain('BO_EXAMS_INSTIT_SOFT.FLG_TYPE',
                                               decode(edcs.flg_type, 'P', 'E', edcs.flg_type),
                                               i_lang)
                  FROM exam_dep_clin_serv edcs
                 WHERE edcs.id_institution = i_id_institution
                   AND edcs.id_dep_clin_serv IS NULL
                   AND edcs.flg_type IN ('P', 'E', 'C')
                   AND edcs.id_exam = i_id
                   AND edcs.id_software IN (SELECT column_value
                                              FROM TABLE(CAST(i_software AS table_number)));
        
            FETCH l_state_cur BULK COLLECT
                INTO l_data;
        
            CLOSE l_state_cur;
        
        ELSIF i_context = 'P'
        THEN
            g_error := 'GET INST_INTERVENTION_LIST CURSOR';
            OPEN l_state_cur FOR
                SELECT to_char(id_software) || ',' || decode(idcs.flg_type, 'P', 'E', idcs.flg_type) || ',' ||
                       pk_sysdomain.get_domain('BO_INTERV_INSTIT_SOFT.FLG_TYPE',
                                               decode(idcs.flg_type, 'P', 'E', idcs.flg_type),
                                               i_lang)
                  FROM interv_dep_clin_serv idcs
                 WHERE idcs.id_institution = i_id_institution
                   AND idcs.id_dep_clin_serv IS NULL
                   AND idcs.flg_type IN ('P', 'E', 'C')
                   AND idcs.id_intervention = i_id
                   AND idcs.id_software IN (SELECT column_value
                                              FROM TABLE(CAST(i_software AS table_number)));
        
            FETCH l_state_cur BULK COLLECT
                INTO l_data;
        
            CLOSE l_state_cur;
        
        ELSIF i_context = 'M'
        THEN
            g_error := 'GET INST_INTERVENTION_LIST CURSOR';
            OPEN l_state_cur FOR
                SELECT to_char(id_software) || ',' || decode(ris.flg_add_remove, 'A', 'E', ris.flg_add_remove) || ',' ||
                       pk_sysdomain.get_domain('BO_INTERV_INSTIT_SOFT.FLG_TYPE',
                                               decode(ris.flg_add_remove, 'A', 'E', ris.flg_add_remove),
                                               i_lang)
                  FROM rehab_area_interv rai, rehab_inst_soft ris
                 WHERE rai.id_intervention = i_id
                   AND rai.id_rehab_area_interv = ris.id_rehab_area_interv
                   AND ris.id_institution = i_id_institution
                   AND ris.id_software IN (SELECT column_value
                                             FROM TABLE(CAST(i_software AS table_number)));
        
            FETCH l_state_cur BULK COLLECT
                INTO l_data;
        
            CLOSE l_state_cur;
        
        END IF;
    
        RETURN l_data;
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_MCDT',
                                              i_function => 'GET_INST_PESQ_STATE',
                                              o_error    => l_error);
            RETURN l_data;
        
    END get_inst_pesq_state;

    /********************************************************************************************
    * Set flags on Analysis Questionaire
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_analysis           Analysis ID
    * @param i_room                  Room ID
    * @param i_tbl_id_analysis_quest List of id questionnaires to be updated
    * @param i_tbl_val               List of flag values
    *
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MARCO FREIRE
    * @version                     2.6.0.3
    * @since                       2010/05/21
    ********************************************************************************************/
    FUNCTION set_lab_questionnaire
    (
        i_lang           IN language.id_language%TYPE,
        i_id_analysis    IN analysis.id_analysis%TYPE,
        i_id_sample_type IN sample_type.id_sample_type%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_room_quest  IN room_questionnaire.id_room_questionnaire%TYPE,
        i_timing         IN analysis_questionnaire.flg_time%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_room_questionnaire room_questionnaire.id_room_questionnaire%TYPE;
        l_id_questionnaire      room_questionnaire.id_questionnaire%TYPE;
        l_room                  room_questionnaire.id_room%TYPE;
    
        TYPE l_t_tbl_id_analysis_room IS TABLE OF analysis_room.id_analysis_room%TYPE;
        l_tbl_analysis_room l_t_tbl_id_analysis_room;
    
    BEGIN
    
        g_error := 'Select id_analysis_room';
        pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_LAB_QUESTIONNAIRE ' || g_error);
    
        g_error := 'Select room and id_questionnaire';
        pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_LAB_QUESTIONNAIRE ' || g_error);
        BEGIN
            SELECT rq.id_room, rq.id_questionnaire
              INTO l_room, l_id_questionnaire
              FROM room_questionnaire rq
             WHERE rq.id_room_questionnaire = i_id_room_quest
               AND rq.flg_available = g_flg_available;
        EXCEPTION
            WHEN no_data_found THEN
                l_room             := NULL;
                l_id_questionnaire := NULL;
        END;
    
        IF l_id_questionnaire IS NOT NULL
           AND l_room IS NOT NULL
        THEN
        
            g_error := 'INSERT INTO ANALYSIS_QUESTIONNAIRE ERROR';
            pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_LAB_QUESTIONNAIRE ' || g_error);
            INSERT INTO analysis_questionnaire
                (id_analysis_questionnaire,
                 id_analysis,
                 id_room,
                 id_questionnaire,
                 flg_time,
                 rank,
                 flg_available,
                 id_sample_type)
            VALUES
                (seq_analysis_questionnaire.nextval,
                 i_id_analysis,
                 l_room,
                 l_id_questionnaire,
                 i_timing,
                 0,
                 g_flg_available,
                 i_id_sample_type);
        
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
                                              'SET_LAB_QUESTIONNAIRE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_lab_questionnaire;

    /********************************************************************************************
    * Get questionnaire
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_analysis           Analysis ID
    * @param i_id_exam               Exame ID
    * @param i_id_room               Room ID
    *
    * @return                      true or false on success or error
    *
    * @author                      MARCO FREIRE
    * @version                     2.6.0.3
    * @since                       2010/05/28
    ********************************************************************************************/
    FUNCTION get_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_room          IN room.id_room%TYPE,
        o_questionnaire OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Select questionnaire';
        pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.GET_QUESTIONNAIRE ' || g_error);
        OPEN o_questionnaire FOR
            SELECT rq.id_room_questionnaire,
                   pk_translation.get_translation(i_lang, 'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || qr.id_questionnaire) desc_questionnaire,
                   pk_translation.get_translation(i_lang, 'RESPONSE.CODE_RESPONSE.' || qr.id_response) desc_response
              FROM room_questionnaire rq, questionnaire_response qr
             WHERE rq.id_room = i_room
               AND rq.flg_available = g_flg_available
               AND rq.id_questionnaire = qr.id_questionnaire;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_QUESTIONNAIRE',
                                              o_error);
            RETURN FALSE;
        
    END get_questionnaire;

    /********************************************************************************************
    * Institution exam parametrization
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_exam               Exam ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID's
    * @param i_flg_mv_pat            Array - Move Patient flags
    * @param i_room                  Exam room
    * @param i_first_result          Array - First to regist result
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2010/06/18
    ********************************************************************************************/
    FUNCTION set_inst_exam_new
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_exam        IN exam_dep_clin_serv.id_exam%TYPE,
        i_id_institution IN exam_dep_clin_serv.id_institution%TYPE,
        i_id_software    IN table_number,
        i_flg_mv_pat     IN table_varchar,
        i_room           IN exam_room.id_room%TYPE,
        i_first_result   IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam_room_count NUMBER := 0;
        l_exam_room       exam_room.id_exam_room%TYPE;
        l_room            exam_room.id_room%TYPE;
    
        l_edcs_flg_type exam_dep_clin_serv.flg_type%TYPE;
    
        CURSOR c_exam_room IS
            SELECT er.id_exam_room, er.id_room
              FROM exam_room er, room r, department d
             WHERE er.id_exam = i_id_exam
               AND er.flg_available = pk_exam_constant.g_available
               AND r.id_room = er.id_room
               AND d.id_department = r.id_department
               AND d.id_institution = i_id_institution;
    
    BEGIN
    
        FOR i IN 1 .. i_id_software.count
        LOOP
        
            SELECT decode(edcs.flg_type, 'E', 'P', 'P', 'P', 'C', 'C')
              INTO l_edcs_flg_type
              FROM exam_dep_clin_serv edcs
             WHERE edcs.id_exam = i_id_exam
               AND edcs.id_institution = i_id_institution
               AND edcs.id_software = i_id_software(i)
               AND edcs.id_dep_clin_serv IS NULL
               AND edcs.flg_type IN ('P', 'E', 'C');
        
            g_error := 'UPDATE EXAM_DEP_CLIN_SERV';
            pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
            UPDATE exam_dep_clin_serv edcs
               SET edcs.flg_mov_pat      = i_flg_mv_pat(i),
                   edcs.flg_first_result = i_first_result(i),
                   edcs.flg_type         = l_edcs_flg_type
             WHERE edcs.id_exam = i_id_exam
               AND edcs.id_institution = i_id_institution
               AND edcs.id_software = i_id_software(i)
               AND edcs.id_dep_clin_serv IS NULL
               AND edcs.flg_type IN ('P', 'E', 'C');
        
        END LOOP;
    
        IF i_room IS NOT NULL
        THEN
        
            SELECT COUNT(er.id_exam_room)
              INTO l_exam_room_count
              FROM exam_room er, room r, department d
             WHERE er.id_exam = i_id_exam
               AND er.flg_available = g_flg_available
               AND r.id_room = er.id_room
               AND d.id_department = r.id_department
               AND d.id_institution = i_id_institution;
        
            IF l_exam_room_count = 0
            THEN
            
                g_error := 'GET SEQ_EXAM_ROOM.NEXTVAL';
                pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
                SELECT seq_exam_room.nextval
                  INTO l_exam_room
                  FROM dual;
            
                g_error := 'INSERT INTO EXAM_ROOM';
                pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
                INSERT INTO exam_room
                    (id_exam_room, id_exam, id_room, rank, adw_last_update, flg_available, flg_default)
                VALUES
                    (l_exam_room, i_id_exam, i_room, 0, SYSDATE, g_flg_available, g_yes);
            
                g_error := 'ALERT_INTER.exam_room_new FOR ID_EXAM = ' || i_id_exam || 'IN ID_ROOM = ' || i_room;
                pk_alertlog.log_debug('PK_BACKOFFICE.set_inst_exam_new ' || g_error);
                alert_inter.pk_ia_event_backoffice.exam_room_new(i_id_exam_room   => l_exam_room,
                                                                 i_id_institution => i_id_institution);
            
            ELSE
            
                g_error := 'GET EXAM_ROOM DATA';
                pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
                OPEN c_exam_room;
                LOOP
                
                    g_error := 'GET EXAM_ROOM INFO';
                    pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
                    FETCH c_exam_room
                        INTO l_exam_room, l_room;
                    EXIT WHEN c_exam_room%NOTFOUND;
                
                    g_error := 'UPDATE EXAM_ROOM, SET FLG_AVAILABLE = N';
                    pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
                    UPDATE exam_room er
                       SET er.flg_available = pk_alert_constant.get_no
                     WHERE er.id_exam_room = l_exam_room;
                
                    g_error := 'ALERT_INTER.exam_room_delete FOR ID_EXAM = ' || i_id_exam || 'IN ID_ROOM = ' || i_room;
                    pk_alertlog.log_debug('PK_BACKOFFICE.set_inst_exam_new ' || g_error);
                    alert_inter.pk_ia_event_backoffice.exam_room_delete(i_id_exam_room   => l_exam_room,
                                                                        i_id_institution => i_id_institution,
                                                                        id_exam          => i_id_exam,
                                                                        id_room          => l_room);
                
                END LOOP;
            
                CLOSE c_exam_room;
            
                g_error := 'GET SEQ_EXAM_ROOM.NEXTVAL';
                pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
                SELECT seq_exam_room.nextval
                  INTO l_exam_room
                  FROM dual;
            
                g_error := 'INSERT INTO EXAM_ROOM';
                pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
                INSERT INTO exam_room
                    (id_exam_room, id_exam, id_room, rank, adw_last_update, flg_available, flg_default)
                VALUES
                    (l_exam_room, i_id_exam, i_room, 0, SYSDATE, g_flg_available, g_yes);
            
                g_error := 'ALERT_INTER.exam_room_new FOR ID_EXAM = ' || i_id_exam || 'IN ID_ROOM = ' || i_room;
                pk_alertlog.log_debug('PK_BACKOFFICE.set_inst_exam_new ' || g_error);
                alert_inter.pk_ia_event_backoffice.exam_room_new(i_id_exam_room   => l_exam_room,
                                                                 i_id_institution => i_id_institution);
            
            END IF;
        
        ELSE
        
            g_error := 'GET EXAM_ROOM DATA';
            pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
            OPEN c_exam_room;
            LOOP
            
                g_error := 'GET EXAM_ROOM INFO';
                pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
                FETCH c_exam_room
                    INTO l_exam_room, l_room;
                EXIT WHEN c_exam_room%NOTFOUND;
            
                g_error := 'UPDATE EXAM_ROOM, SET FLG_AVAILABLE = N';
                pk_alertlog.log_debug('PK_BACKOFFICE_MCDT.SET_INST_EXAM_NEW ' || g_error);
                UPDATE exam_room er
                   SET er.flg_available = pk_alert_constant.get_no
                 WHERE er.id_exam_room = l_exam_room;
            
                g_error := 'ALERT_INTER.exam_room_delete FOR ID_EXAM = ' || i_id_exam || 'IN ID_ROOM = ' || i_room;
                pk_alertlog.log_debug('PK_BACKOFFICE.set_inst_exam_new ' || g_error);
                alert_inter.pk_ia_event_backoffice.exam_room_delete(i_id_exam_room   => l_exam_room,
                                                                    i_id_institution => i_id_institution,
                                                                    id_exam          => i_id_exam,
                                                                    id_room          => l_room);
            
            END LOOP;
        
            CLOSE c_exam_room;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_MCDT',
                                              i_function => 'SET_INST_EXAM_NEW',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_inst_exam_new;

    /********************************************************************************************
    * Set of a new Analysis Collection.
    *
    * @ param i_lang                     Preferred language ID for this professional 
    * @ param i_id_institution           Institution ID
    * @ param i_id_software              Software ID
    * @ param i_prof                     Object (professional ID, institution ID, software ID)    
    * @ param i_id_analysis              analysis ID    
    * @ param i_id_analysis_collection   analysis_collection ID            
    * @ param i_num_collection           Number of Collections 
    * @ param i_order_collection         Order of the Collection
    * @ param i_interval                 Interval of the Collection   
    * @ param i_flg_interval_type        Type Interval of the Collection        
    * @ param i_state                    Indication state (Y - active/N - Inactive)
    *
    * @param o_error                     Error
    *
    * @return                            true or false on success or error
    *
    * @author                            Teresa coutinho
    * @version                           2.6.1
    * @since                             2011/03/15
    **********************************************************************************************/
    FUNCTION set_analysis_collection
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_institution         IN analysis_instit_soft.id_institution%TYPE,
        i_id_software            IN table_number,
        i_id_analysis            IN analysis_instit_soft.id_analysis%TYPE,
        i_id_sample_type         IN analysis_instit_soft.id_sample_type%TYPE,
        i_id_analysis_collection IN table_number,
        i_num_collection         IN analysis_collection.num_collection%TYPE,
        i_order_collection       IN table_number,
        i_interval               IN table_number,
        i_flg_interval_type      IN analysis_collection.flg_interval_type%TYPE,
        i_state                  IN analysis_collection.flg_available%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_analysis_collection analysis_collection.id_analysis_collection%TYPE;
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
    
        g_backoffice_parameterization CONSTANT VARCHAR2(1 CHAR) := 'B';
        l_order_collection        table_number := table_number();
        l_id_analysis_inst_soft   analysis_instit_soft.id_analysis_instit_soft%TYPE;
        l_seq_analysis_collection analysis_collection.id_analysis_collection%TYPE;
    
        CURSOR c_analysis_inst_soft(l_software software.id_software%TYPE) IS
            SELECT ais.id_analysis_instit_soft
              FROM analysis_instit_soft ais
             WHERE ais.id_institution = i_id_institution
               AND ais.id_software = l_software
               AND ais.id_analysis = i_id_analysis
               AND ais.id_sample_type = i_id_sample_type;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_order_collection := i_order_collection;
    
        FOR i IN 1 .. i_id_software.count
        LOOP
            OPEN c_analysis_inst_soft(i_id_software(i));
            FETCH c_analysis_inst_soft
                INTO l_id_analysis_inst_soft;
            CLOSE c_analysis_inst_soft;
        
            IF l_id_analysis_inst_soft IS NOT NULL
            THEN
                IF i_id_analysis_collection IS NOT NULL
                   AND i_id_analysis_collection.count > 0
                THEN
                    g_error := 'UPDATE ANALYSIS_COLLECTION';
                    pk_alertlog.log_debug(g_error);
                
                    UPDATE analysis_collection
                       SET flg_status = pk_alert_constant.g_flg_status_e, flg_available = pk_alert_constant.g_no
                     WHERE id_analysis_collection = i_id_analysis_collection(i);
                
                    UPDATE analysis_collection_int
                       SET flg_available = pk_alert_constant.g_no
                     WHERE id_analysis_collection = i_id_analysis_collection(i);
                
                    IF i_num_collection > 1
                    THEN
                        SELECT seq_analysis_collection.nextval
                          INTO l_seq_analysis_collection
                          FROM dual;
                    
                        INSERT INTO analysis_collection
                            (id_analysis_collection,
                             num_collection,
                             flg_interval_type,
                             flg_available,
                             flg_parametrization_type,
                             flg_status,
                             id_analysis_instit_soft)
                        VALUES
                            (l_seq_analysis_collection,
                             i_num_collection,
                             i_flg_interval_type,
                             pk_alert_constant.g_yes,
                             g_backoffice_parameterization,
                             i_state,
                             l_id_analysis_inst_soft);
                    
                        -- inserir o intervalo a zero para a 1∫ colheita                            
                        INSERT INTO analysis_collection_int
                            (id_analysis_collection_int,
                             id_analysis_collection,
                             order_collection,
                             INTERVAL,
                             flg_available)
                        VALUES
                            (seq_analysis_collection_int.nextval,
                             l_seq_analysis_collection,
                             0,
                             0,
                             pk_alert_constant.g_yes);
                    
                        FOR i IN 1 .. i_interval.count
                        LOOP
                            g_error := 'INSERT INTO ANALYSIS_COLLECTION_INT';
                            INSERT INTO analysis_collection_int
                                (id_analysis_collection_int,
                                 id_analysis_collection,
                                 order_collection,
                                 INTERVAL,
                                 flg_available)
                            VALUES
                                (seq_analysis_collection_int.nextval,
                                 l_seq_analysis_collection,
                                 i,
                                 i_interval(i),
                                 pk_alert_constant.g_yes);
                        END LOOP;
                    END IF;
                ELSE
                    g_error                  := 'GET SEQ_ANALYSIS_COLLECTION.NEXTVAL';
                    l_id_analysis_collection := seq_analysis_collection.nextval;
                
                    SELECT seq_analysis_collection.nextval
                      INTO l_seq_analysis_collection
                      FROM dual;
                
                    g_error := 'CREATE NEW ANALYSIS_COLLECTION';
                    INSERT INTO analysis_collection
                        (id_analysis_collection,
                         num_collection,
                         flg_interval_type,
                         flg_available,
                         flg_parametrization_type,
                         flg_status,
                         id_analysis_instit_soft)
                    VALUES
                        (l_seq_analysis_collection,
                         i_num_collection,
                         i_flg_interval_type,
                         pk_alert_constant.g_yes,
                         g_backoffice_parameterization,
                         i_state,
                         l_id_analysis_inst_soft);
                    --                    
                    g_error := 'CALL t_data_gov_mnt.process_insert';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ANALYSIS_COLLECTION',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    -- inserir o intervalo a zero para a 1∫ colheita                            
                    INSERT INTO analysis_collection_int
                        (id_analysis_collection_int, id_analysis_collection, order_collection, INTERVAL, flg_available)
                    VALUES
                        (seq_analysis_collection_int.nextval, l_seq_analysis_collection, 0, 0, pk_alert_constant.g_yes);
                
                    FOR i IN 1 .. i_interval.count
                    LOOP
                    
                        INSERT INTO analysis_collection_int
                            (id_analysis_collection_int,
                             id_analysis_collection,
                             order_collection,
                             INTERVAL,
                             flg_available)
                        VALUES
                            (seq_analysis_collection_int.nextval,
                             l_seq_analysis_collection,
                             i,
                             i_interval(i),
                             pk_alert_constant.g_yes);
                    END LOOP;
                END IF;
            END IF;
        END LOOP;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_MCDT',
                                              i_function => 'SET_ANALYSIS_COLLECTION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_analysis_collection;
    /********************************************************************************************
    * Get Institution Searchable List Number of records
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_software              Software ID's
    * @param i_context               Context
    * @param i_search                Search filter
    * @param o_inst_pesq_count       Number of records
    * @param o_error                 Error
    *
    *
    * @value     i_context          {*} 'A' Analyis {*} 'I' Image exams {*} 'O' Others Exams {*} 'P' Interventions   
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/06/28
    ********************************************************************************************/
    FUNCTION get_inst_pesq_list_count
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN analysis_instit_soft.id_institution%TYPE,
        i_software        IN table_number,
        i_context         IN VARCHAR2,
        i_search          IN VARCHAR2,
        o_inst_pesq_count OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'get_inst_pesq_list_count';
        l_id_market NUMBER(24);
        l_search    VARCHAR2(4000) := '%' || translate(upper(REPLACE(REPLACE(REPLACE(i_search, '\', '\\'), '%', '\%'),
                                                                     '_',
                                                                     '\_')),
                                                       '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                                       'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%';
    
    BEGIN
    
        IF i_context = 'A'
        THEN
            g_error := 'GET INST_ANALYSIS_LIST NUMBER OF RECORDS';
            IF i_search IS NULL
            THEN
                SELECT COUNT(aux.id_analysis)
                  INTO o_inst_pesq_count
                  FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                  i_order => g_flg_available,
                                                                  i_table => 'ANALYSIS')) t
                  JOIN (SELECT /*+no_merge*/
                         a.id_analysis, st.id_sample_type, a.code_analysis, st.code_sample_type
                          FROM analysis a
                          JOIN analysis_sample_type ast
                            ON (a.id_analysis = ast.id_analysis AND ast.flg_available = g_flg_available)
                          JOIN sample_type st
                            ON (ast.id_sample_type = st.id_sample_type AND st.flg_available = g_flg_available)
                         WHERE a.flg_available = g_flg_available) aux
                    ON (aux.code_analysis = t.code_translation);
            
            ELSE
                SELECT COUNT(aux.id_analysis)
                  INTO o_inst_pesq_count
                  FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                  i_order => g_flg_available,
                                                                  i_table => 'ANALYSIS')) t
                  JOIN (SELECT /*+no_merge*/
                         a.id_analysis, st.id_sample_type, a.code_analysis, st.code_sample_type
                          FROM analysis a
                          JOIN analysis_sample_type ast
                            ON (a.id_analysis = ast.id_analysis AND ast.flg_available = g_flg_available)
                          JOIN sample_type st
                            ON (ast.id_sample_type = st.id_sample_type AND st.flg_available = g_flg_available)
                         WHERE a.flg_available = g_flg_available) aux
                    ON (aux.code_analysis = t.code_translation)
                 WHERE (translate(upper(t.desc_translation), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                       l_search OR translate(upper(pk_translation.get_translation(i_lang, aux.code_sample_type)),
                                              '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                              'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE l_search);
            END IF;
        
        ELSIF i_context = 'I'
        THEN
        
            g_error := 'GET INST_IMAGE_EXAM_LIST NUMBER OF RECORDS';
            IF i_search IS NULL
            THEN
                SELECT COUNT(aux.id_exam)
                  INTO o_inst_pesq_count
                  FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                  i_order => g_flg_available,
                                                                  i_table => 'EXAM')) t
                  JOIN (SELECT e.id_exam, e.code_exam
                          FROM exam e
                         WHERE e.flg_available = g_flg_available
                           AND e.flg_type = i_context) aux
                    ON (aux.code_exam = t.code_translation);
            
            ELSE
                SELECT COUNT(aux.id_exam)
                  INTO o_inst_pesq_count
                  FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                  i_order => g_flg_available,
                                                                  i_table => 'EXAM')) t
                  JOIN (SELECT e.id_exam, e.code_exam
                          FROM exam e
                         WHERE e.flg_available = g_flg_available
                           AND e.flg_type = i_context) aux
                    ON (aux.code_exam = t.code_translation)
                 WHERE translate(upper(t.desc_translation), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                       l_search ESCAPE '\';
            END IF;
        
        ELSIF i_context = 'O'
        THEN
            g_error := 'GET INST_OTHER_EXAM_LIST NUMBER OF RECORDS';
            IF i_search IS NULL
            THEN
                SELECT COUNT(aux.id_exam)
                  INTO o_inst_pesq_count
                  FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                  i_order => g_flg_available,
                                                                  i_table => 'EXAM')) t
                  JOIN (SELECT e.id_exam, e.code_exam
                          FROM exam e
                         WHERE e.flg_available = g_flg_available
                           AND e.flg_type != 'I') aux
                    ON (aux.code_exam = t.code_translation);
            ELSE
                SELECT COUNT(aux.id_exam)
                  INTO o_inst_pesq_count
                  FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                  i_order => g_flg_available,
                                                                  i_table => 'EXAM')) t
                  JOIN (SELECT e.id_exam, e.code_exam
                          FROM exam e
                         WHERE e.flg_available = g_flg_available
                           AND e.flg_type != 'I') aux
                    ON (aux.code_exam = t.code_translation)
                 WHERE translate(upper(t.desc_translation), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                       l_search ESCAPE '\';
            END IF;
        
        ELSIF i_context = 'P'
        THEN
            g_error := 'GET INST_INTERVENTION_LIST NUMBER OF RECORDS';
            IF i_search IS NULL
            THEN
                SELECT COUNT(aux.id_intervention)
                  INTO o_inst_pesq_count
                  FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                  i_order => g_flg_available,
                                                                  i_table => 'INTERVENTION')) t
                  JOIN (SELECT /*+no_merge*/
                         i.id_intervention, i.code_intervention
                          FROM intervention i
                         WHERE i.flg_status = 'A'
                           AND NOT EXISTS (SELECT 0
                                  FROM rehab_area_interv rai
                                 WHERE rai.id_intervention = i.id_intervention)) aux
                    ON (aux.code_intervention = t.code_translation);
            
            ELSE
                SELECT COUNT(aux.id_intervention)
                  INTO o_inst_pesq_count
                  FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                  i_order => g_flg_available,
                                                                  i_table => 'INTERVENTION')) t
                  JOIN (SELECT /*+no_merge*/
                         i.id_intervention, i.code_intervention
                          FROM intervention i
                         WHERE i.flg_status = 'A'
                           AND NOT EXISTS (SELECT 0
                                  FROM rehab_area_interv rai
                                 WHERE rai.id_intervention = i.id_intervention)) aux
                    ON (aux.code_intervention = t.code_translation)
                 WHERE translate(upper(t.desc_translation), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                       l_search ESCAPE '\';
            END IF;
        
            --MFR Interventions
        ELSIF i_context = 'M'
        THEN
            g_error := 'GET INST_INTERVENTION_LIST NUMBER OF RECORDS';
            IF i_search IS NULL
            THEN
                SELECT COUNT(aux.id_intervention)
                  INTO o_inst_pesq_count
                  FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                  i_order => g_flg_available,
                                                                  i_table => 'INTERVENTION')) t
                  JOIN (SELECT /*+no_merge*/
                         i.id_intervention, i.code_intervention
                          FROM intervention i
                         WHERE i.flg_status = 'A'
                           AND EXISTS (SELECT 0
                                  FROM rehab_area_interv rai
                                 WHERE rai.id_intervention = i.id_intervention)) aux
                    ON (aux.code_intervention = t.code_translation);
            ELSE
                SELECT COUNT(aux.id_intervention)
                  INTO o_inst_pesq_count
                  FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                  i_order => g_flg_available,
                                                                  i_table => 'INTERVENTION')) t
                  JOIN (SELECT /*+no_merge*/
                         i.id_intervention, i.code_intervention
                          FROM intervention i
                         WHERE i.flg_status = 'A'
                           AND EXISTS (SELECT 0
                                  FROM rehab_area_interv rai
                                 WHERE rai.id_intervention = i.id_intervention)) aux
                    ON (aux.code_intervention = t.code_translation)
                 WHERE translate(upper(t.desc_translation), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                       l_search ESCAPE '\';
            END IF;
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
        
    END get_inst_pesq_list_count;
    /********************************************************************************************
    * Get Institution Searchable List Data
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_software              Software ID's
    * @param i_context               Context
    * @param i_search                Search filter
    * @param i_start_record          start record
    * @param i_num_records           number of records to show     
    * @param o_inst_pesq_list        List
    * @param o_error                 Error
    *
    *
    * @value     i_context          {*} 'A' Analyis {*} 'I' Image exams {*} 'O' Others Exams {*} 'P' Interventions   
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/06/28
    ********************************************************************************************/
    FUNCTION get_inst_pesq_list_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_context        IN VARCHAR2,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'get_inst_pesq_list';
        l_id_market NUMBER(24);
        l_mcdt_data t_table_mcdt;
        l_search    VARCHAR2(4000) := '%' || translate(upper(REPLACE(REPLACE(REPLACE(i_search, '\', '\\'), '%', '\%'),
                                                                     '_',
                                                                     '\_')),
                                                       '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                                       'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%';
    BEGIN
    
        IF i_context = 'A'
        THEN
            g_error := 'GET INST_ANALYSIS_LIST DATA';
            IF i_search IS NULL
            THEN
                SELECT t_rec_mcdt(data_rec.id,
                                  data_rec.id_2,
                                  data_rec.name_aux,
                                  data_rec.name,
                                  data_rec.values_desc,
                                  data_rec.flg_missing_data)
                  BULK COLLECT
                  INTO l_mcdt_data
                  FROM (SELECT aux.id_analysis id,
                               aux.id_sample_type id_2,
                               t.desc_translation name_aux,
                               t.desc_translation || ' / ' ||
                               pk_translation.get_translation(i_lang, aux.code_sample_type) name,
                               NULL values_desc,
                               NULL flg_missing_data
                          FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                          i_order => g_flg_available,
                                                                          i_table => 'ANALYSIS')) t
                          JOIN (SELECT /*+no_merge*/
                                a.id_analysis, st.id_sample_type, a.code_analysis, st.code_sample_type
                                 FROM analysis a
                                 JOIN analysis_sample_type ast
                                   ON (a.id_analysis = ast.id_analysis AND ast.flg_available = g_flg_available)
                                 JOIN sample_type st
                                   ON (ast.id_sample_type = st.id_sample_type AND st.flg_available = g_flg_available)
                                WHERE a.flg_available = g_flg_available) aux
                            ON (aux.code_analysis = t.code_translation)) data_rec
                 ORDER BY data_rec.name;
            ELSE
                SELECT t_rec_mcdt(data_rec.id,
                                  data_rec.id_2,
                                  data_rec.name_aux,
                                  data_rec.name,
                                  data_rec.values_desc,
                                  data_rec.flg_missing_data)
                  BULK COLLECT
                  INTO l_mcdt_data
                  FROM (SELECT aux.id_analysis id,
                               aux.id_sample_type id_2,
                               t.desc_translation name_aux,
                               t.desc_translation || ' / ' ||
                               pk_translation.get_translation(i_lang, aux.code_sample_type) name,
                               NULL values_desc,
                               NULL flg_missing_data
                          FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                          i_order => g_flg_available,
                                                                          i_table => 'ANALYSIS')) t
                          JOIN (SELECT /*+no_merge*/
                                a.id_analysis, st.id_sample_type, a.code_analysis, st.code_sample_type
                                 FROM analysis a
                                 JOIN analysis_sample_type ast
                                   ON (a.id_analysis = ast.id_analysis AND ast.flg_available = g_flg_available)
                                 JOIN sample_type st
                                   ON (ast.id_sample_type = st.id_sample_type AND st.flg_available = g_flg_available)
                                WHERE a.flg_available = g_flg_available) aux
                            ON (aux.code_analysis = t.code_translation)
                         WHERE (translate(upper(t.desc_translation),
                                          '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                          'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE l_search OR
                               translate(upper(pk_translation.get_translation(i_lang, aux.code_sample_type)),
                                          '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                          'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE l_search)) data_rec
                 ORDER BY data_rec.name;
            
            END IF;
        
        ELSIF i_context = 'I'
        THEN
        
            g_error := 'GET INST_IMAGE_EXAM_LIST DATA';
            IF i_search IS NULL
            THEN
                SELECT t_rec_mcdt(data_rec.id,
                                  NULL,
                                  data_rec.name_aux,
                                  data_rec.name,
                                  data_rec.values_desc,
                                  data_rec.flg_missing_data)
                  BULK COLLECT
                  INTO l_mcdt_data
                  FROM (SELECT aux.id_exam        id,
                               NULL               name_aux,
                               t.desc_translation name,
                               NULL               values_desc,
                               NULL               flg_missing_data
                          FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                          i_order => g_flg_available,
                                                                          i_table => 'EXAM')) t
                          JOIN (SELECT /*+no_merge*/
                                e.id_exam, e.code_exam
                                 FROM exam e
                                WHERE e.flg_available = g_flg_available
                                  AND e.flg_type = 'I') aux
                            ON (aux.code_exam = t.code_translation)) data_rec
                 ORDER BY data_rec.name;
            ELSE
                SELECT t_rec_mcdt(data_rec.id,
                                  NULL,
                                  data_rec.name_aux,
                                  data_rec.name,
                                  data_rec.values_desc,
                                  data_rec.flg_missing_data)
                  BULK COLLECT
                  INTO l_mcdt_data
                  FROM (SELECT aux.id_exam        id,
                               NULL               name_aux,
                               t.desc_translation name,
                               NULL               values_desc,
                               NULL               flg_missing_data
                          FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                          i_order => g_flg_available,
                                                                          i_table => 'EXAM')) t
                          JOIN (SELECT /*+no_merge*/
                                e.id_exam, e.code_exam
                                 FROM exam e
                                WHERE e.flg_available = g_flg_available
                                  AND e.flg_type = 'I') aux
                            ON (aux.code_exam = t.code_translation)
                         WHERE translate(upper(t.desc_translation),
                                         '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE l_search ESCAPE '\') data_rec
                 ORDER BY data_rec.name;
            END IF;
        ELSIF i_context = 'O'
        THEN
            g_error := 'GET INST_OTHER_EXAM_LIST DATA';
            IF i_search IS NULL
            THEN
                SELECT t_rec_mcdt(data_rec.id,
                                  NULL,
                                  data_rec.name_aux,
                                  data_rec.name,
                                  data_rec.values_desc,
                                  data_rec.flg_missing_data)
                  BULK COLLECT
                  INTO l_mcdt_data
                  FROM (SELECT aux.id_exam        id,
                               NULL               name_aux,
                               t.desc_translation name,
                               NULL               values_desc,
                               NULL               flg_missing_data
                          FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                          i_order => g_flg_available,
                                                                          i_table => 'EXAM')) t
                          JOIN (SELECT /*+no_merge*/
                                e.id_exam, e.code_exam
                                 FROM exam e
                                WHERE e.flg_available = g_flg_available
                                  AND e.flg_type != 'I') aux
                            ON (aux.code_exam = t.code_translation)) data_rec
                 ORDER BY data_rec.name;
            ELSE
                SELECT t_rec_mcdt(data_rec.id,
                                  NULL,
                                  data_rec.name_aux,
                                  data_rec.name,
                                  data_rec.values_desc,
                                  data_rec.flg_missing_data)
                  BULK COLLECT
                  INTO l_mcdt_data
                  FROM (SELECT aux.id_exam        id,
                               NULL               name_aux,
                               t.desc_translation name,
                               NULL               values_desc,
                               NULL               flg_missing_data
                          FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                          i_order => g_flg_available,
                                                                          i_table => 'EXAM')) t
                          JOIN (SELECT /*+no_merge*/
                                e.id_exam, e.code_exam
                                 FROM exam e
                                WHERE e.flg_available = g_flg_available
                                  AND e.flg_type != 'I') aux
                            ON (aux.code_exam = t.code_translation)
                         WHERE translate(upper(t.desc_translation),
                                         '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE l_search ESCAPE '\') data_rec
                 ORDER BY data_rec.name;
            END IF;
        ELSIF i_context = 'P'
        THEN
            g_error := 'GET INST_INTERVENTION_LIST DATA';
            IF i_search IS NULL
            THEN
                SELECT t_rec_mcdt(data_rec.id,
                                  NULL,
                                  data_rec.name_aux,
                                  data_rec.name,
                                  data_rec.values_desc,
                                  data_rec.flg_missing_data)
                  BULK COLLECT
                  INTO l_mcdt_data
                  FROM (SELECT aux.id_intervention id,
                               NULL                name_aux,
                               t.desc_translation  name,
                               NULL                values_desc,
                               NULL                flg_missing_data
                          FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                          i_order => 'Y',
                                                                          i_table => 'INTERVENTION')) t
                          JOIN (SELECT /*+no_merge*/
                                i.id_intervention, i.code_intervention
                                 FROM intervention i
                                WHERE i.flg_status = 'A'
                                  AND NOT EXISTS (SELECT 0
                                         FROM rehab_area_interv rai
                                        WHERE rai.id_intervention = i.id_intervention)) aux
                            ON (aux.code_intervention = t.code_translation)) data_rec
                 ORDER BY data_rec.name;
            ELSE
                SELECT t_rec_mcdt(data_rec.id,
                                  NULL,
                                  data_rec.name_aux,
                                  data_rec.name,
                                  data_rec.values_desc,
                                  data_rec.flg_missing_data)
                  BULK COLLECT
                  INTO l_mcdt_data
                  FROM (SELECT aux.id_intervention id,
                               NULL                name_aux,
                               t.desc_translation  name,
                               NULL                values_desc,
                               NULL                flg_missing_data
                          FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                          i_order => 'Y',
                                                                          i_table => 'INTERVENTION')) t
                          JOIN (SELECT /*+no_merge*/
                                i.id_intervention, i.code_intervention
                                 FROM intervention i
                                WHERE i.flg_status = 'A'
                                  AND NOT EXISTS (SELECT 0
                                         FROM rehab_area_interv rai
                                        WHERE rai.id_intervention = i.id_intervention)) aux
                            ON (aux.code_intervention = t.code_translation)
                         WHERE translate(upper(t.desc_translation),
                                         '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE l_search ESCAPE '\') data_rec
                 ORDER BY data_rec.name;
            END IF;
            --MFR Interventions
        ELSIF i_context = 'M'
        THEN
            g_error := 'GET INST_INTERVENTION_LIST DATA';
            IF i_search IS NULL
            THEN
                SELECT t_rec_mcdt(data_rec.id,
                                  NULL,
                                  data_rec.name_aux,
                                  data_rec.name,
                                  data_rec.values_desc,
                                  data_rec.flg_missing_data)
                  BULK COLLECT
                  INTO l_mcdt_data
                  FROM (SELECT aux.id_intervention id,
                               NULL                name_aux,
                               t.desc_translation  name,
                               NULL                values_desc,
                               NULL                flg_missing_data
                          FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                          i_order => 'Y',
                                                                          i_table => 'INTERVENTION')) t
                          JOIN (SELECT /*+no_merge*/
                                i.id_intervention, i.code_intervention
                                 FROM intervention i
                                WHERE i.flg_status = 'A'
                                  AND EXISTS (SELECT 0
                                         FROM rehab_area_interv rai
                                        WHERE rai.id_intervention = i.id_intervention)) aux
                            ON (aux.code_intervention = t.code_translation)) data_rec
                 ORDER BY data_rec.name;
            ELSE
                SELECT t_rec_mcdt(data_rec.id,
                                  NULL,
                                  data_rec.name_aux,
                                  data_rec.name,
                                  data_rec.values_desc,
                                  data_rec.flg_missing_data)
                  BULK COLLECT
                  INTO l_mcdt_data
                  FROM (SELECT aux.id_intervention id,
                               NULL                name_aux,
                               t.desc_translation  name,
                               NULL                values_desc,
                               NULL                flg_missing_data
                          FROM TABLE(pk_translation.get_table_translation(i_lang  => i_lang,
                                                                          i_order => 'Y',
                                                                          i_table => 'INTERVENTION')) t
                          JOIN (SELECT /*+no_merge*/
                                i.id_intervention, i.code_intervention
                                 FROM intervention i
                                WHERE i.flg_status = 'A'
                                  AND EXISTS (SELECT 0
                                         FROM rehab_area_interv rai
                                        WHERE rai.id_intervention = i.id_intervention)) aux
                            ON (aux.code_intervention = t.code_translation)
                         WHERE translate(upper(t.desc_translation),
                                         '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE l_search ESCAPE '\') data_rec
                 ORDER BY data_rec.name;
            END IF;
        END IF;
    
        OPEN o_inst_pesq_list FOR
            SELECT mcdt.id,
                   mcdt.id_2,
                   mcdt.name_aux,
                   mcdt.name,
                   pk_backoffice_mcdt.get_inst_pesq_state(i_lang,
                                                          i_id_institution,
                                                          decode(i_context, 'A', mcdt.id || '|' || mcdt.id_2, mcdt.id),
                                                          i_software,
                                                          i_context) values_desc,
                   decode((pk_backoffice_mcdt.get_missing_data(i_lang,
                                                               decode(i_context,
                                                                      'A',
                                                                      mcdt.id || '|' || mcdt.id_2,
                                                                      mcdt.id),
                                                               i_id_institution,
                                                               0,
                                                               i_context)),
                          NULL,
                          'N',
                          'Y') flg_missing_data
              FROM (SELECT rownum rn, t.*
                      FROM TABLE(CAST(l_mcdt_data AS t_table_mcdt)) t) mcdt
             WHERE rn BETWEEN i_start_record AND i_start_record + i_num_records - 1;
    
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
        
    END get_inst_pesq_list_data;
    /********************************************************************************************
    * check exam configuration
    *
    * @param i_id_exam            Exam ID
    * @param i_id_institution     Institution ID
    * @param i_flg_type           Type of configuration
    *
    *
    * @return                     number of results found
    *
    * @author                     RMGM
    * @version                    2.6.1
    * @since                      2013/04/05
    ********************************************************************************************/
    FUNCTION check_exam_config
    (
        i_id_exam        IN exam_dep_clin_serv.id_exam%TYPE,
        i_id_institution IN exam_dep_clin_serv.id_institution%TYPE,
        i_flg_type       IN exam_dep_clin_serv.flg_type%TYPE
    ) RETURN NUMBER IS
        l_result NUMBER := 0;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        g_error := 'COUNT IF CONTENT ' || i_id_exam || 'IS CONFIGURED IN INSTITUTION ' || i_id_institution;
        SELECT nvl((SELECT COUNT(*)
                     FROM exam_dep_clin_serv edcs
                    WHERE edcs.id_exam = i_id_exam
                      AND edcs.id_institution = i_id_institution
                      AND edcs.flg_type = i_flg_type),
                   0)
          INTO l_result
          FROM dual;
        RETURN l_result;
    
    END check_exam_config;

BEGIN

    pk_alertlog.log_init(pk_alertlog.who_am_i);

    g_flg_available := 'Y';
    g_no            := 'N';
    g_yes           := 'Y';

    g_status_i := 'I';
    g_status_a := 'A';

    g_analysis_flg_available  := 'ANALYSIS.FLG_AVAILABLE';
    g_analysis_add_task       := 'ANALYSIS_ADD_TASK';
    g_patient_gender          := 'PATIENT.GENDER';
    g_recipient_flg_available := 'SAMPLE_RECIPIENT.FLG_AVAILABLE';
    g_parameter_flg_available := 'PARAMETER_ANALYSIS.FLG_AVAILABLE';

    g_domain_gender := 'PATIENT.GENDER';

    g_hand_icon := 'HandSelectedIcon';

END pk_backoffice_mcdt;
/
