/*-- Last Change Revision: $Rev: 2027427 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_data_export AS

    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    g_retval BOOLEAN;
    g_found  BOOLEAN;
    g_exception EXCEPTION;
    g_error VARCHAR2(1000 CHAR);
    g_passive         CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_solv            CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_create          CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_diagnosis       CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_final_diagnosis CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_alergies        CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_analysis        CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_finish          CONSTANT VARCHAR2(1 CHAR) := 'F';

    TYPE mcdt_req_rec IS RECORD(
        id             NUMBER(24),
        id_req_det     NUMBER(24),
        text           VARCHAR2(4000),
        dt_insert      VARCHAR2(200),
        prof_name      VARCHAR2(200),
        flg_type       VARCHAR2(2),
        flg_status     VARCHAR2(2),
        id_institution NUMBER(24),
        flg_priority   VARCHAR2(1),
        flg_home       VARCHAR2(1));

    -- rehab        
    TYPE rehab_rec IS RECORD(
        id_intervention NUMBER(24),
        desc_procedure  VARCHAR2(4000),
        desc_area       VARCHAR2(4000),
        date_req        VARCHAR2(4000),
        proc_status     VARCHAR2(1 CHAR),
        total_sessions  NUMBER(6),
        num_sessions    NUMBER(6));

    TYPE t_coll_rehab IS TABLE OF rehab_rec;
    /**
    * The screen used to export data for the referral shows the items configured 
    * in p1_export_data_config in an hierarchic fashion.
    * One item should only be displayed if there's data available for some of its
    * descendants. 
    *
    * This function evaluates if the provided item has data for any of its descendents
    *
    * @param   i_lang professional language id
    * @param   i_prof professional id, institution and software.
    * @param   i_patient patient id
    * @param   i_episode id    
    * @param   i_dec_row record of p1_data_export_config
    * @param   o_has_descendant. 1 if there data for at least one decendant. 0 otherwise.
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-05-2008
    */
    FUNCTION has_descendant
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_dec_row        IN p1_data_export_config%ROWTYPE,
        o_has_descendant OUT NUMBER
    ) RETURN BOOLEAN IS
        l_sql_aux        VARCHAR2(4000);
        l_has_descendant PLS_INTEGER DEFAULT 0;
        c_count          pk_types.cursor_type;
        l_count          NUMBER DEFAULT 0;
        l_conf_row       p1_data_export_config%ROWTYPE;
    
        CURSOR c_ IS
            SELECT *
              FROM p1_data_export_config d
             WHERE d.id_software = i_prof.software
               AND d.id_parent = i_dec_row.id_data_export_config
               AND d.flg_available = pk_ref_constant.g_yes;
    BEGIN
        g_error := 'open c_';
        OPEN c_;
        LOOP
            FETCH c_
                INTO l_conf_row;
            EXIT WHEN c_%NOTFOUND;
        
            -- Basta um ter filhos para ser verdadeiro...
            IF l_has_descendant > 0
            THEN
                l_has_descendant := 1;
            ELSE
                g_error := 'call has_descendant';
                IF NOT has_descendant(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_patient        => i_patient,
                                      i_episode        => i_episode,
                                      i_dec_row        => l_conf_row,
                                      o_has_descendant => l_has_descendant)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END LOOP;
        CLOSE c_;
    
        -- Se o filho tem eu também    
        IF l_has_descendant > 0
        THEN
            o_has_descendant := 1;
        ELSIF i_dec_row.function IS NOT NULL
        -- Conta Filhos   
        THEN
        
            l_sql_aux := 'SELECT count(1) FROM TABLE(CAST(' || i_dec_row.function || ' AS t_coll_p1_export_data))';
        
            l_sql_aux := REPLACE(l_sql_aux, '@LANG', to_char(i_lang));
            l_sql_aux := REPLACE(l_sql_aux, '@PROFESSIONAL', to_char(i_prof.id));
            l_sql_aux := REPLACE(l_sql_aux, '@INSTITUTION', to_char(i_prof.institution));
            l_sql_aux := REPLACE(l_sql_aux, '@SOFTWARE', to_char(i_prof.software));
            l_sql_aux := REPLACE(l_sql_aux, '@PATIENT', to_char(i_patient));
            l_sql_aux := REPLACE(l_sql_aux, '@EPISODE', to_char(i_episode));
        
            g_error := 'OPEN c_count FOR ' || i_dec_row.id_data_export_config;
            --pk_alertlog.log_debug(g_error);
        
            OPEN c_count FOR l_sql_aux;
            FETCH c_count
                INTO l_count;
            CLOSE c_count;
        
            IF l_count > 0
            THEN
                o_has_descendant := 1;
            ELSE
                o_has_descendant := 0;
            END IF;
        
        ELSE
            o_has_descendant := 0;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN FALSE;
    END has_descendant;

    /**
    * The screen used to export data for the referral shows the items configured 
    * in p1_export_data_config in an hierarchic fashion.
    * One item should only be displayed if there's data available for some of its
    * descendants. 
    *
    * This function evaluates if the provided item has data for any of its descendents
    *
    * @param   i_lang professional language id
    * @param   i_prof professional id, institution and software.
    * @param   i_patient patient id
    * @param   i_episode id    
    * @param   i_ref_type referral type
    * @param   o_has_descendant. 1 if there data for at least one decendant. 0 otherwise.
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-05-2008
    */
    FUNCTION has_descendant
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_ref_type IN p1_external_request.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_ IS
            SELECT *
              FROM p1_data_export_config d
             WHERE d.id_software = i_prof.software
               AND d.flg_available = pk_ref_constant.g_yes
               AND d.flg_p1_data_type = pk_ref_constant.g_data_export_p1_type_req_pref || i_ref_type;
    
        l_has_descendant PLS_INTEGER DEFAULT 0;
        l_dec_row        p1_data_export_config%ROWTYPE;
    BEGIN
    
        OPEN c_;
        LOOP
            FETCH c_
                INTO l_dec_row;
            EXIT WHEN c_%NOTFOUND;
        
            g_error := 'call has_descendant';
            IF NOT has_descendant(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_patient        => i_patient,
                                  i_episode        => i_episode,
                                  i_dec_row        => l_dec_row,
                                  o_has_descendant => l_has_descendant)
            THEN
                RETURN pk_ref_constant.g_no;
            END IF;
        
            IF l_has_descendant > 0
            THEN
                RETURN pk_ref_constant.g_yes;
            END IF;
        END LOOP;
        CLOSE c_;
    
        RETURN pk_ref_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END has_descendant;

    /**
    * Returns the data items available for exporting
    *
    * @param   i_lang professional language id
    * @param   i_prof professional id, institution and software.
    * @param   i_patient patient id
    * @param   i_episode id    
    * @param   i_ref_type referral type {*} 'A' analysis {*}'I' image, {*}'E' exam {*}'P' Intervention {*} 'F' PMR Intervention       
    * @param   o_data data items list
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   14-05-2008
    * @modify  Joana Barroso 14-07-2008 Adicionei flg_p1_data_type ao query 
    */
    FUNCTION get_data_export_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_ref_type IN p1_external_request.flg_type%TYPE,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dec_row        p1_data_export_config%ROWTYPE;
        l_sql            VARCHAR2(32000);
        l_func           VARCHAR2(4000);
        l_has_descendant NUMBER;
    
        CURSOR c_(x_type p1_data_export_config.flg_p1_data_type%TYPE) IS
            SELECT d.*
              FROM p1_data_export_config d
             WHERE d.id_software = i_prof.software
               AND d.flg_available = pk_ref_constant.g_yes
               AND (d.flg_p1_data_type NOT IN (pk_ref_constant.g_data_export_p1_type_ra,
                                               pk_ref_constant.g_data_export_p1_type_ri,
                                               pk_ref_constant.g_data_export_p1_type_re,
                                               pk_ref_constant.g_data_export_p1_type_rp,
                                               pk_ref_constant.g_data_export_p1_type_rf) OR
                   d.flg_p1_data_type = x_type)
             ORDER BY id_parent, rank, pk_translation.get_translation(i_lang, code_data_export_config);
    
    BEGIN
    
        g_error := 'OPEN c_';
        OPEN c_(pk_ref_constant.g_data_export_p1_type_req_pref || i_ref_type);
        LOOP
            FETCH c_
                INTO l_dec_row;
            EXIT WHEN c_%NOTFOUND;
            g_error  := 'CALL has_descendant';
            g_retval := has_descendant(i_lang, i_prof, i_patient, i_episode, l_dec_row, l_has_descendant);
        
            IF l_has_descendant > 0
            THEN
            
                IF l_sql IS NOT NULL
                THEN
                    g_error := 'Append 1';
                    l_sql   := l_sql || chr(10) || 'UNION ALL' || chr(10);
                END IF;
                IF l_dec_row.flg_type = pk_ref_constant.g_data_export_type_s
                THEN
                    g_error := 'Append 2';
                    l_sql   := l_sql || 'SELECT id_data_export_config,
                                 nvl(id_parent, 0) id_parent,      
                                 NULL id, 
                                 pk_translation.get_translation(' || to_char(i_lang) ||
                               ', code_data_export_config) label ,
                               flg_p1_data_type type_req,
                               null id_req
                      FROM p1_data_export_config
                     WHERE id_data_export_config = ' || l_dec_row.id_data_export_config;
                
                    pk_alertlog.log_debug(l_sql);
                
                ELSE
                    IF l_dec_row.function IS NOT NULL
                    THEN
                        l_func := l_dec_row.function;
                        l_func := REPLACE(l_func, '@LANG', to_char(i_lang));
                        l_func := REPLACE(l_func, '@PROFESSIONAL', to_char(i_prof.id));
                        l_func := REPLACE(l_func, '@INSTITUTION', to_char(i_prof.institution));
                        l_func := REPLACE(l_func, '@SOFTWARE', to_char(i_prof.software));
                        l_func := REPLACE(l_func, '@PATIENT', to_char(i_patient));
                        l_func := REPLACE(l_func, '@EPISODE', to_char(i_episode));
                    
                        g_error := 'Append 3';
                        l_sql   := l_sql || 'SELECT id_data_export_config,
                                 nvl(id_parent, 0) id_parent,      
                                 NULL id, 
                                 pk_translation.get_translation(' || to_char(i_lang) ||
                                   ', code_data_export_config) label , flg_p1_data_type type_req, null id_req FROM p1_data_export_config WHERE id_data_export_config = ' ||
                                   l_dec_row.id_data_export_config || chr(10) || 'UNION ALL ' || chr(10) || 'SELECT ' ||
                                   l_dec_row.id_data_export_config || ' id_data_export_config, ' ||
                                   l_dec_row.id_data_export_config ||
                                   ' id_parent, id, title label, NULL type_req, id_req id_req FROM TABLE(CAST(' ||
                                   l_func || ' AS t_coll_p1_export_data))';
                    
                        pk_alertlog.log_debug(l_sql);
                    
                    ELSE
                        pk_alertlog.log_warn('Type F and i_conf_row.FUNCTION IS NOT NULL');
                        l_sql := NULL;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        CLOSE c_;
    
        g_error := 'OPEN o_data';
        IF l_sql IS NOT NULL
        THEN
            OPEN o_data FOR l_sql;
        ELSE
            pk_types.open_my_cursor(o_data);
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DATA_EXPORT_LIST',
                                                     o_error    => o_error);
    END get_data_export_list;

    FUNCTION get_data_export_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_ref_type             IN p1_external_request.flg_type%TYPE,
        i_root_name            IN VARCHAR2,
        o_categories_data      OUT pk_types.cursor_type,
        o_elements_data        OUT pk_types.cursor_type,
        o_internal_names_field OUT VARCHAR2,
        o_internal_name_values OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dec_row        p1_data_export_config%ROWTYPE;
        l_sql            VARCHAR2(32000);
        l_func           VARCHAR2(4000);
        l_has_descendant NUMBER;
    
        c_data_aux pk_types.cursor_type;
        l_tbl_data t_tbl_list_export;
    
        CURSOR c_(x_type p1_data_export_config.flg_p1_data_type%TYPE) IS
            SELECT d.*
              FROM p1_data_export_config d
             WHERE d.id_software = i_prof.software
               AND d.flg_available = pk_ref_constant.g_yes
               AND (d.flg_p1_data_type NOT IN (pk_ref_constant.g_data_export_p1_type_ra,
                                               pk_ref_constant.g_data_export_p1_type_ri,
                                               pk_ref_constant.g_data_export_p1_type_re,
                                               pk_ref_constant.g_data_export_p1_type_rp,
                                               pk_ref_constant.g_data_export_p1_type_rf) OR
                   d.flg_p1_data_type = x_type)
             ORDER BY id_parent, rank, pk_translation.get_translation(i_lang, code_data_export_config);
    
    BEGIN
    
        g_error := 'OPEN c_';
        OPEN c_(pk_ref_constant.g_data_export_p1_type_req_pref || i_ref_type);
        LOOP
            FETCH c_
                INTO l_dec_row;
            EXIT WHEN c_%NOTFOUND;
            g_error  := 'CALL has_descendant';
            g_retval := has_descendant(i_lang, i_prof, i_patient, i_episode, l_dec_row, l_has_descendant);
        
            IF l_has_descendant > 0
            THEN
            
                IF l_sql IS NOT NULL
                THEN
                    g_error := 'Append 1';
                    l_sql   := l_sql || chr(10) || 'UNION ALL' || chr(10);
                END IF;
                IF l_dec_row.flg_type = pk_ref_constant.g_data_export_type_s
                THEN
                    g_error := 'Append 2';
                    l_sql   := l_sql || 'SELECT id_parent, 
                                 pk_translation.get_translation(' || to_char(i_lang) ||
                               ', code_data_export_config) label, 
                               null id_req,
                               p.id_data_export_config
                      FROM p1_data_export_config p
                     WHERE p.id_data_export_config is not null and id_data_export_config = ' ||
                               l_dec_row.id_data_export_config; -- || ' and id_parent is not null';
                
                    pk_alertlog.log_debug(l_sql);
                
                ELSE
                    IF l_dec_row.function IS NOT NULL
                    THEN
                        l_func := l_dec_row.function;
                        l_func := REPLACE(l_func, '@LANG', to_char(i_lang));
                        l_func := REPLACE(l_func, '@PROFESSIONAL', to_char(i_prof.id));
                        l_func := REPLACE(l_func, '@INSTITUTION', to_char(i_prof.institution));
                        l_func := REPLACE(l_func, '@SOFTWARE', to_char(i_prof.software));
                        l_func := REPLACE(l_func, '@PATIENT', to_char(i_patient));
                        l_func := REPLACE(l_func, '@EPISODE', to_char(i_episode));
                    
                        g_error := 'Append 3';
                        l_sql   := l_sql || 'SELECT id_parent,
                                 pk_translation.get_translation(' || to_char(i_lang) ||
                                   ', code_data_export_config) label, null id_req, p.id_data_export_config FROM p1_data_export_config p WHERE id_data_export_config = ' ||
                                   l_dec_row.id_data_export_config /*|| ' and id_parent is not null '*/
                                   || chr(10) || 'UNION ALL ' || chr(10) || 'SELECT ' ||
                                   l_dec_row.id_data_export_config || ' id_parent, title label, id_req, ' ||
                                   l_dec_row.id_data_export_config || ' id_data_export_config FROM TABLE(CAST(' ||
                                   l_func || ' AS t_coll_p1_export_data)) ';
                    
                        pk_alertlog.log_debug(l_sql);
                    
                    ELSE
                        pk_alertlog.log_warn('Type F and i_conf_row.FUNCTION IS NOT NULL');
                        l_sql := NULL;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        CLOSE c_;
    
        g_error := 'OPEN o_data';
        IF l_sql IS NOT NULL
        THEN
            OPEN c_data_aux FOR l_sql;
        
            FETCH c_data_aux BULK COLLECT
                INTO l_tbl_data;
        
            OPEN o_categories_data FOR
                SELECT t.id_data_export_config AS id, t.label
                  FROM TABLE(l_tbl_data) t
                 WHERE t.id_parent IS NULL;
        
            OPEN o_elements_data FOR
                SELECT t.id_parent, t.id_data_export_config AS id_element, t.label, t.id_req, rownum AS rn
                  FROM TABLE(l_tbl_data) t
                 WHERE t.id_parent IS NOT NULL;
        ELSE
            pk_types.open_my_cursor(o_categories_data);
            pk_types.open_my_cursor(o_elements_data);
        END IF;
    
        o_internal_names_field := pk_orders_constant.g_ds_p1_import_ids;
        o_internal_name_values := pk_orders_constant.g_ds_p1_import_values;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_categories_data);
            pk_types.open_my_cursor(o_elements_data);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DATA_EXPORT_LIST',
                                                     o_error    => o_error);
    END get_data_export_list;

    /**
    * Get request types: appointment, analysis, exams, intervention and MFR
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_patient patient id
    * @param   i_episode espisode id        
    * @param   o_type avaible request types on REFERAL
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-05-2008
    */
    FUNCTION get_request_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_type    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ppt       profile_template.id_profile_template%TYPE;
        l_id_market market.id_market%TYPE;
    BEGIN
        g_error := 'Init get_request_type / ID_PATIENT=' || i_patient || ' ID_EPISODE=' || i_episode;
        pk_alertlog.log_debug(g_error);
        l_ppt       := pk_tools.get_prof_profile_template(i_prof);
        l_id_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        g_error := 'OPEN o_type';
    
        OPEN o_type FOR
            SELECT DISTINCT t.flg_type_ref data,
                            pk_sysdomain.get_domain(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_code_dom      => 'P1_EXTERNAL_REQUEST.FLG_TYPE',
                                                    i_val           => t.flg_type_ref,
                                                    i_dep_clin_serv => NULL) desc_action,
                            pk_sysdomain.get_rank(i_lang     => i_lang,
                                                  i_code_dom => 'P1_EXTERNAL_REQUEST.FLG_TYPE',
                                                  i_val      => t.flg_type_ref) rank,
                            pk_sysdomain.get_img(i_lang     => i_lang,
                                                 i_code_dom => 'P1_EXTERNAL_REQUEST.FLG_TYPE',
                                                 i_val      => t.flg_type_ref) icon,
                            t.flg_available flg_active
              FROM (SELECT rcc.id_ref_completion,
                           rcc.flg_type_ref,
                           rcc.flg_available,
                           row_number() over(PARTITION BY rcc.id_market, rcc.flg_type_ref ORDER BY rcc.id_market DESC, rcc.flg_available DESC) rn
                      FROM ref_completion_cfg rcc
                     WHERE rcc.id_software IN (i_prof.software, pk_ref_constant.g_zero)
                       AND rcc.id_institution IN (i_prof.institution, pk_ref_constant.g_zero)
                       AND rcc.id_profile_template IN (l_ppt, pk_ref_constant.g_zero)
                       AND rcc.flg_available != pk_alert_constant.g_no
                       AND rcc.id_market IN (l_id_market, pk_ref_constant.g_zero)) t
             WHERE t.rn = 1
             ORDER BY rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_type);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REQUEST_TYPE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
    END get_request_type;

    /**
    * Gets request detail based on the data items provided
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Professional, institution and software ids
    * @param   i_patient              Patient identifier
    * @param   i_episode              Episode identifier
    * @param   i_data_export          List of items (as in p1_data_export_config) to include in the request
    * @param   i_ref_type             Referral type 
    * @param   o_detail               Request general data
    * @param   o_text                 Referral information detail: Reason, Symptomology, Progress, History, Family history,
    *                                  Objective exam, Diagnostic exams and Notes (mcdts)   
    * @param   o_problem              Referral problems information
    * @param   o_diagnosis            Referral diagnosis information
    * @param   o_mcdt                 MCDT data   
    * @param   o_error
    *
    * @value   i_flg_type             {*} 'C' - Appointments {*} 'A'  - Lab tests {*} 'I' - Imaging exams {*} 'E' - Other exams
    *                                 {*} 'P' - Procedures {*} 'F' -  Rehabilitation {*} 'S'  - Surgery requests
    *                                 {*} 'N' - Admission requests
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   23-05-2008
    */
    FUNCTION get_p1_detail_new
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_data_export  IN table_table_number,
        i_ref_type     IN p1_external_request.flg_type%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_text         OUT pk_types.cursor_type,
        o_problem      OUT pk_types.cursor_type,
        o_diagnosis    OUT pk_types.cursor_type,
        o_mcdt         OUT pk_types.cursor_type,
        o_notes_adm    OUT pk_types.cursor_type,
        o_needs        OUT pk_types.cursor_type,
        o_info         OUT pk_types.cursor_type,
        o_notes_status OUT pk_types.cursor_type,
        o_answer       OUT pk_types.cursor_type,
        o_title_status OUT VARCHAR2,
        o_editable     OUT VARCHAR2,
        o_can_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_dc(x p1_data_export_config.id_data_export_config%TYPE) IS
            SELECT dc.*
              FROM p1_data_export_config dc
             WHERE dc.id_data_export_config = x;
    
        CURSOR c_dc_type_f IS
            SELECT DISTINCT dc.*
              FROM p1_data_export_config dc
             WHERE dc.id_software = i_prof.software
               AND dc.flg_type = pk_ref_constant.g_data_export_type_f
               AND dc.flg_available = pk_ref_constant.g_yes;
    
        l_dec_row p1_data_export_config%ROWTYPE;
    
        TYPE t_func_tab IS TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(26);
        l_func_tab t_func_tab;
    
        TYPE t_ids_tab IS TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(26);
        l_ids_tab t_ids_tab;
    
        TYPE t_sql_tab IS TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(26);
        l_sql_tab t_sql_tab;
    
        l_aux_idx    VARCHAR2(26);
        l_date_str   VARCHAR2(100);
        l_date_flash VARCHAR2(50);
        l_text       VARCHAR2(32767);
        l_number     NUMBER(2);
    
        l_probl_date DATE;
        l_year       NUMBER(24);
        l_month      NUMBER(24);
        l_day        NUMBER(24);
    BEGIN
    
        g_error := 'Init get_p1_detail_new / ID_PATIENT=' || i_patient || ' ID_EPISODE=' || i_episode || ' REQ_TYPE=' ||
                   i_ref_type;
        pk_alertlog.log_debug(g_error);
    
        FOR i IN 1 .. i_data_export.count
        LOOP
        
            g_error := 'OPEN c_dc : ' || i_data_export(i) (1);
        
            OPEN c_dc(i_data_export(i) (1));
            FETCH c_dc
                INTO l_dec_row;
            g_found := c_dc%FOUND;
            CLOSE c_dc;
        
            g_error := 'Initializing 1';
            IF NOT l_sql_tab.exists(l_dec_row.flg_p1_data_type)
            THEN
                l_sql_tab(l_dec_row.flg_p1_data_type) := NULL;
            END IF;
        
            IF NOT l_func_tab.exists(l_dec_row.flg_p1_data_type)
            THEN
                l_func_tab(l_dec_row.flg_p1_data_type) := NULL;
            END IF;
        
            g_error := 'g_found ';
            IF g_found
            THEN
            
                g_error := 'Found  : ' || l_dec_row.flg_type;
                IF l_dec_row.flg_type = pk_ref_constant.g_data_export_type_f
                THEN
                    -- Para os tipo F filtra resultados pelos id escolhidos
                    l_aux_idx := l_dec_row.id_data_export_config || l_dec_row.flg_p1_data_type;
                    g_error   := 'l_aux_idx  : ' || l_aux_idx;
                
                    -- Inicializar
                    g_error := 'Initializing 2';
                    IF NOT l_ids_tab.exists(l_aux_idx)
                    THEN
                        g_error := 'entrou no l_ids_tab.EXISTS(l_aux_idx)';
                        l_ids_tab(l_aux_idx) := NULL;
                    END IF;
                
                    g_error := 'Append l_ids ' || l_aux_idx;
                
                    IF l_ids_tab(l_aux_idx) IS NOT NULL
                    THEN
                        l_ids_tab(l_aux_idx) := l_ids_tab(l_aux_idx) || ',';
                    ELSE
                        l_func_tab(l_dec_row.flg_p1_data_type) := l_dec_row.function;
                    END IF;
                
                    l_ids_tab(l_aux_idx) := l_ids_tab(l_aux_idx) || i_data_export(i) (2);
                    -- Caso contrario mostra todos os resultados   
                ELSE
                    l_aux_idx := l_dec_row.flg_p1_data_type;
                
                    l_func_tab(l_aux_idx) := l_dec_row.function;
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@LANG', to_char(i_lang));
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@PROFESSIONAL', to_char(i_prof.id));
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@INSTITUTION', to_char(i_prof.institution));
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@SOFTWARE', to_char(i_prof.software));
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@PATIENT', to_char(i_patient));
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@EPISODE', to_char(i_episode));
                
                    g_error := 'Append ' || l_aux_idx;
                    IF l_sql_tab(l_aux_idx) IS NOT NULL
                    THEN
                        g_error := 'Append in' || l_aux_idx;
                        l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) || chr(10) || 'UNION ALL' || chr(10);
                    END IF;
                
                    g_error := 'Testing l_aux_idx';
                    BEGIN
                        l_number := to_number(l_aux_idx);
                    EXCEPTION
                        WHEN value_error THEN
                            l_number := NULL;
                    END;
                
                    g_error := 'Append out' || l_aux_idx;
                    IF l_number IN (pk_ref_constant.g_detail_type_jstf,
                                    pk_ref_constant.g_detail_type_sntm,
                                    pk_ref_constant.g_detail_type_evlt,
                                    pk_ref_constant.g_detail_type_hstr,
                                    pk_ref_constant.g_detail_type_hstf,
                                    pk_ref_constant.g_detail_type_obje,
                                    pk_ref_constant.g_detail_type_cmpe,
                                    pk_ref_constant.g_detail_type_vs)
                    THEN
                        -- diferent columns
                        l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) ||
                                                'SELECT id, null id_parent, id_req, title, decode(text, null,'''', text) text, ' ||
                                                'pk_date_utils.dt_chr_date_hour_tsz(' || i_lang ||
                                                ', pk_date_utils.get_string_tstz(' || i_lang || ', profissional(' ||
                                                i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                                                '), dt_insert,null), profissional(' || i_prof.id || ',' ||
                                                i_prof.institution || ',' || i_prof.software || ')) dt_insert, ' ||
                                                'prof_name, ''' || l_aux_idx
                                               --begin|| ''' flg_type, ''' ||
                                                || ''' flg_type, pk_translation.get_translation(' || i_lang ||
                                                ' ,''P1_DATA_EXPORT_CONFIG.CODE_DATA_EXPORT_CONFIG.''||' ||
                                                to_char(l_dec_row.id_data_export_config) || ') desc_type, ''' ||
                                               --end
                                                pk_ref_constant.g_detail_status_a ||
                                                ''' flg_status, null id_institution, null flg_priority, null flg_home FROM TABLE(CAST(' ||
                                                l_func_tab(l_aux_idx) ||
                                                ' AS t_coll_p1_export_data)) WHERE text IS NOT NULL ';
                    
                    ELSE
                    
                        l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) ||
                                                'SELECT id, null id_parent, id_req, title, decode(text, null,'''', text) text, dt_insert, prof_name, flg_type, pk_translation.get_translation(' ||
                                                i_lang || ' ,''P1_DATA_EXPORT_CONFIG.CODE_DATA_EXPORT_CONFIG.''||' ||
                                                to_char(l_dec_row.id_data_export_config) ||
                                                ') desc_type, flg_status, id_institution, flg_priority, flg_home FROM TABLE(CAST(' ||
                                                l_func_tab(l_aux_idx) || ' AS t_coll_p1_export_data)) ';
                    END IF;
                
                END IF;
            END IF;
        END LOOP;
    
        -- Constroi sql para os tipo F
        FOR ctf IN c_dc_type_f
        LOOP
            l_aux_idx := ctf.flg_p1_data_type;
            g_error   := 'Append l_sql ' || l_aux_idx;
            IF l_ids_tab.exists(ctf.id_data_export_config || l_aux_idx)
            THEN
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@LANG', to_char(i_lang));
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@PROFESSIONAL', to_char(i_prof.id));
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@INSTITUTION', to_char(i_prof.institution));
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@SOFTWARE', to_char(i_prof.software));
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@PATIENT', to_char(i_patient));
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@EPISODE', to_char(i_episode));
            
                g_error := 'Append 1 ' || l_aux_idx;
                IF l_sql_tab(l_aux_idx) IS NOT NULL
                THEN
                    g_error := 'Append in' || l_aux_idx;
                    l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) || chr(10) || 'UNION ALL' || chr(10);
                END IF;
            
                g_error := 'Testing l_aux_idx';
                BEGIN
                    l_number := to_number(l_aux_idx);
                EXCEPTION
                    WHEN value_error THEN
                        l_number := NULL;
                END;
            
                g_error := 'Append out' || l_aux_idx;
            
                IF l_number IN (pk_ref_constant.g_detail_type_jstf,
                                pk_ref_constant.g_detail_type_sntm,
                                pk_ref_constant.g_detail_type_evlt,
                                pk_ref_constant.g_detail_type_hstr,
                                pk_ref_constant.g_detail_type_hstf,
                                pk_ref_constant.g_detail_type_obje,
                                pk_ref_constant.g_detail_type_cmpe,
                                pk_ref_constant.g_detail_type_vs)
                THEN
                    -- diferent columns
                    l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) ||
                                            'SELECT id, null id_parent, id_req, title, decode(text, null,'''', text) text, ' ||
                                            'pk_date_utils.dt_chr_date_hour_tsz(' || i_lang ||
                                            ', pk_date_utils.get_string_tstz(' || i_lang || ', profissional(' ||
                                            i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                                            '), dt_insert,null), profissional(' || i_prof.id || ',' ||
                                            i_prof.institution || ',' || i_prof.software || ')) dt_insert, ' ||
                                            'prof_name, ''' || l_aux_idx
                                           --|| ''' flg_type, ''' ||
                                            || ''' flg_type, pk_translation.get_translation(' || i_lang ||
                                            ' ,''P1_DATA_EXPORT_CONFIG.CODE_DATA_EXPORT_CONFIG.''||' ||
                                            to_char(ctf.id_data_export_config) || ') desc_type, ''' ||
                                           -- end
                                            pk_ref_constant.g_detail_status_a ||
                                            ''' flg_status, null id_institution, null flg_priority, null flg_home FROM TABLE(CAST(' ||
                                            l_func_tab(l_aux_idx) ||
                                            ' AS t_coll_p1_export_data)) WHERE text is not null and id_req in (' ||
                                            l_ids_tab(ctf.id_data_export_config || l_aux_idx) || ')';
                
                ELSE
                
                    l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) ||
                                            'SELECT id, null id_parent, id_req, title, decode(text, null,'''', text) text, dt_insert, prof_name, flg_type, pk_translation.get_translation(' ||
                                            i_lang || ' ,''P1_DATA_EXPORT_CONFIG.CODE_DATA_EXPORT_CONFIG.''||' ||
                                            to_char(ctf.id_data_export_config) ||
                                            ') desc_type, flg_status, id_institution, flg_priority, flg_home FROM TABLE(CAST(' ||
                                            l_func_tab(l_aux_idx) ||
                                            ' AS t_coll_p1_export_data)) t where t.id_req in (' ||
                                            l_ids_tab(ctf.id_data_export_config || l_aux_idx) || ')'; -- order by dt_insert ';
                END IF;
            END IF;
        END LOOP;
    
        -- Notes
        g_error := 'O_NOTE';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_note)
        THEN
            l_text := l_sql_tab(pk_ref_constant.g_detail_type_note);
        END IF;
    
        --Reason
        g_error := 'O_JUSTIFICATION';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_jstf)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_jstf);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_jstf);
            END IF;
        END IF;
    
        -- Symptomatology   
        g_error := 'O_SYMPTOMS';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_sntm)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_sntm);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_sntm);
            END IF;
        END IF;
    
        -- Progress
        g_error := 'O_EVOLUTION';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_evlt)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_evlt);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_evlt);
            END IF;
        END IF;
    
        -- History
        g_error := 'O_HISTORY';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_hstr)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_hstr);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_hstr);
            END IF;
        END IF;
    
        -- Family history
        g_error := 'O_FAMILY_H';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_hstf)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_hstf);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_hstf);
            END IF;
        END IF;
    
        -- Objective exam
        g_error := 'O_EXAM';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_obje)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_obje);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_obje);
            END IF;
        END IF;
    
        -- Diagnostic exams
        g_error := 'O_COMPL_EXAM';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_cmpe)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_cmpe);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_cmpe);
            END IF;
        END IF;
    
        -- Vital Signs
        g_error := 'O_EXAM';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_vs)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_vs);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_vs);
            END IF;
        END IF;
    
        g_error := 'O_TEXT';
        IF l_text IS NOT NULL
        THEN
            OPEN o_text FOR l_text;
        ELSE
            pk_types.open_my_cursor(o_text);
        END IF;
    
        -- Problema de saude a resolver
        g_error := 'OPEN O_PROBLEM';
        IF l_sql_tab.exists(pk_ref_constant.g_data_export_p1_type_p)
        THEN
            OPEN o_problem FOR l_sql_tab(pk_ref_constant.g_data_export_p1_type_p);
        END IF;
    
        g_error := 'OPEN O_DIAGNOSIS';
        IF l_sql_tab.exists(pk_ref_constant.g_data_export_p1_type_d)
        THEN
            OPEN o_diagnosis FOR l_sql_tab(pk_ref_constant.g_data_export_p1_type_d);
        END IF;
    
        g_error := 'OPEN O_MCDT';
        IF i_ref_type IS NOT NULL
           AND i_ref_type != pk_ref_constant.g_p1_type_c
        THEN
            IF l_sql_tab.exists(pk_ref_constant.g_data_export_p1_type_req_pref || i_ref_type)
            THEN
                OPEN o_mcdt FOR l_sql_tab(pk_ref_constant.g_data_export_p1_type_req_pref || i_ref_type);
            END IF;
        END IF;
    
        IF o_problem IS NOT NULL -- JB 2008-07-11 para n preencher a data qd n é escolhida a história actual
        THEN
            BEGIN
                g_error := 'SELECT get_pat_problem / ID_PAT=' || i_patient || ' TYPE=' || g_diagnosis;
                SELECT dt_insert
                  INTO l_date_str
                  FROM (SELECT t.dt_insert
                          FROM TABLE(get_pat_problem(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     i_status  => pk_ref_constant.g_active,
                                                     i_type    => g_diagnosis)) t
                         ORDER BY t.dt_insert)
                 WHERE rownum = 1;
            
                l_probl_date := to_date(l_date_str, pk_ref_constant.g_format_date_2);
            
                l_year  := extract(YEAR FROM l_probl_date);
                l_month := extract(MONTH FROM l_probl_date);
                l_day   := extract(DAY FROM l_probl_date);
            
                -- convert format YYYYMMDDHH24MISS to "flash format interpretation"
                g_error      := 'Call pk_ref_utils.parse_dt_str_flash / l_date=' || l_date_str || ' l_year=' || l_year ||
                                ' l_month=' || l_month || ' l_day=' || l_day;
                l_date_flash := pk_ref_utils.parse_dt_str_flash(i_lang  => i_lang,
                                                                i_prof  => i_prof,
                                                                i_year  => l_year,
                                                                i_month => l_month,
                                                                i_day   => l_day);
            
                l_date_str := pk_ref_utils.parse_dt_str_app(i_lang  => i_lang,
                                                            i_prof  => i_prof,
                                                            i_year  => l_year,
                                                            i_month => l_month,
                                                            i_day   => l_day);
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_date_flash := NULL;
                    l_date_str   := NULL;
            END;
        END IF;
    
        g_error := 'OPEN O_P1_DETAIL';
        OPEN o_detail FOR
            SELECT NULL id_p1,
                   i_ref_type flg_type,
                   NULL num_req,
                   NULL dt_p1,
                   pk_sysdomain.get_img(i_lang, 'P1_EXTERNAL_REQUEST.FLG_STATUS', pk_ref_constant.g_p1_status_o) status_icon,
                   pk_ref_constant.g_p1_status_o flg_status,
                   pk_sysdomain.get_domain('P1_STATUS_COLOR.MED_CS', pk_ref_constant.g_p1_status_o, i_lang) status_colors,
                   pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', pk_ref_constant.g_p1_status_o, i_lang) desc_status,
                   NULL priority_icon,
                   pk_date_utils.get_elapsed_tsz(i_lang, current_timestamp, current_timestamp) dt_elapsed,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name_request,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, i_prof.institution) prof_spec_request,
                   NULL priority_desc, -- ALERT-273753
                   NULL id_dep_clin_serv,
                   NULL id_speciality,
                   NULL id_institution,
                   NULL inst_abbrev,
                   NULL inst_name,
                   NULL dep_name,
                   NULL spec_name,
                   NULL dt_schedule,
                   l_date_str dt_probl_begin,
                   l_date_flash dt_probl_begin_ts,
                   NULL flg_priority,
                   NULL flg_home,
                   NULL prof_redirected,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_last_interaction
              FROM professional p
             WHERE p.id_professional = i_prof.id;
    
        --
        pk_types.open_cursor_if_closed(o_detail);
        pk_types.open_cursor_if_closed(o_text);
        pk_types.open_cursor_if_closed(o_problem);
        pk_types.open_cursor_if_closed(o_diagnosis);
        pk_types.open_cursor_if_closed(o_mcdt);
        pk_types.open_cursor_if_closed(o_notes_adm);
        pk_types.open_cursor_if_closed(o_needs);
        pk_types.open_cursor_if_closed(o_info);
        pk_types.open_cursor_if_closed(o_notes_status);
        pk_types.open_cursor_if_closed(o_answer);
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_detail);
            pk_types.open_cursor_if_closed(o_text);
            pk_types.open_cursor_if_closed(o_problem);
            pk_types.open_cursor_if_closed(o_diagnosis);
            pk_types.open_cursor_if_closed(o_mcdt);
            pk_types.open_cursor_if_closed(o_notes_adm);
            pk_types.open_cursor_if_closed(o_needs);
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_notes_status);
            pk_types.open_cursor_if_closed(o_answer);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_P1_DETAIL_NEW',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_p1_detail_new;

    FUNCTION get_p1_data_export
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
        i_data_export    IN table_table_number,
        i_ref_type       IN p1_external_request.flg_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        CURSOR c_dc(x p1_data_export_config.id_data_export_config%TYPE) IS
            SELECT dc.*
              FROM p1_data_export_config dc
             WHERE dc.id_data_export_config = x;
    
        CURSOR c_dc_type_f IS
            SELECT DISTINCT dc.*
              FROM p1_data_export_config dc
             WHERE dc.id_software = i_prof.software
               AND dc.flg_type = pk_ref_constant.g_data_export_type_f
               AND dc.flg_available = pk_ref_constant.g_yes;
    
        l_dec_row p1_data_export_config%ROWTYPE;
    
        TYPE t_func_tab IS TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(26);
        l_func_tab t_func_tab;
    
        TYPE t_ids_tab IS TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(26);
        l_ids_tab t_ids_tab;
    
        TYPE t_sql_tab IS TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(26);
        l_sql_tab t_sql_tab;
    
        l_aux_idx    VARCHAR2(26);
        l_date_str   VARCHAR2(100);
        l_date_flash VARCHAR2(50);
        l_text       VARCHAR2(32767);
        l_number     NUMBER(2);
    
        l_probl_date DATE;
        l_year       NUMBER(24);
        l_month      NUMBER(24);
        l_day        NUMBER(24);
    
        --
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
    
        c_problems     pk_types.cursor_type;
        l_tbl_problems t_tbl_data_export;
    
        c_diagnosis     pk_types.cursor_type;
        l_tbl_diagnosis t_tbl_data_export;
    
        c_text     pk_types.cursor_type;
        l_tbl_text t_tbl_data_export;
    
        l_tbl_desc_aux table_varchar;
        l_desc_aux     VARCHAR2(4000);
    
        l_form_value      VARCHAR2(4000);
        l_form_value_desc VARCHAR2(4000);
    
        l_diagnosis_mandatory sys_config.value%TYPE;
    BEGIN
        g_error := 'Init get_p1_detail_new / ID_PATIENT=' || i_patient || ' ID_EPISODE=' || i_episode || ' REQ_TYPE=' ||
                   i_ref_type;
        pk_alertlog.log_debug(g_error);
    
        FOR i IN 1 .. i_data_export.count
        LOOP
        
            g_error := 'OPEN c_dc : ' || i_data_export(i) (1);
        
            OPEN c_dc(i_data_export(i) (1));
            FETCH c_dc
                INTO l_dec_row;
            g_found := c_dc%FOUND;
            CLOSE c_dc;
        
            g_error := 'Initializing 1';
            IF NOT l_sql_tab.exists(l_dec_row.flg_p1_data_type)
            THEN
                l_sql_tab(l_dec_row.flg_p1_data_type) := NULL;
            END IF;
        
            IF NOT l_func_tab.exists(l_dec_row.flg_p1_data_type)
            THEN
                l_func_tab(l_dec_row.flg_p1_data_type) := NULL;
            END IF;
        
            g_error := 'g_found ';
            IF g_found
            THEN
                g_error := 'Found  : ' || l_dec_row.flg_type;
                IF l_dec_row.flg_type = pk_ref_constant.g_data_export_type_f
                THEN
                    -- Para os tipo F filtra resultados pelos id escolhidos
                    l_aux_idx := l_dec_row.id_data_export_config || l_dec_row.flg_p1_data_type;
                    g_error   := 'l_aux_idx  : ' || l_aux_idx;
                
                    -- Inicializar
                    g_error := 'Initializing 2';
                    IF NOT l_ids_tab.exists(l_aux_idx)
                    THEN
                        g_error := 'entrou no l_ids_tab.EXISTS(l_aux_idx)';
                        l_ids_tab(l_aux_idx) := NULL;
                    END IF;
                
                    g_error := 'Append l_ids ' || l_aux_idx;
                
                    IF l_ids_tab(l_aux_idx) IS NOT NULL
                    THEN
                        l_ids_tab(l_aux_idx) := l_ids_tab(l_aux_idx) || ',';
                    ELSE
                        l_func_tab(l_dec_row.flg_p1_data_type) := l_dec_row.function;
                    END IF;
                
                    l_ids_tab(l_aux_idx) := l_ids_tab(l_aux_idx) || i_data_export(i) (2);
                    -- Caso contrario mostra todos os resultados   
                ELSE
                    l_aux_idx := l_dec_row.flg_p1_data_type;
                
                    l_func_tab(l_aux_idx) := l_dec_row.function;
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@LANG', to_char(i_lang));
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@PROFESSIONAL', to_char(i_prof.id));
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@INSTITUTION', to_char(i_prof.institution));
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@SOFTWARE', to_char(i_prof.software));
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@PATIENT', to_char(i_patient));
                    l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@EPISODE', to_char(i_episode));
                
                    g_error := 'Append ' || l_aux_idx;
                    IF l_sql_tab(l_aux_idx) IS NOT NULL
                    THEN
                        g_error := 'Append in' || l_aux_idx;
                        l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) || chr(10) || 'UNION ALL' || chr(10);
                    END IF;
                
                    g_error := 'Testing l_aux_idx';
                    BEGIN
                        l_number := to_number(l_aux_idx);
                    EXCEPTION
                        WHEN value_error THEN
                            l_number := NULL;
                    END;
                
                    g_error := 'Append out' || l_aux_idx;
                    IF l_number IN (pk_ref_constant.g_detail_type_jstf,
                                    pk_ref_constant.g_detail_type_sntm,
                                    pk_ref_constant.g_detail_type_evlt,
                                    pk_ref_constant.g_detail_type_hstr,
                                    pk_ref_constant.g_detail_type_hstf,
                                    pk_ref_constant.g_detail_type_obje,
                                    pk_ref_constant.g_detail_type_cmpe,
                                    pk_ref_constant.g_detail_type_vs)
                    THEN
                        -- diferent columns
                        l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) ||
                                                'SELECT id, null id_parent, id_req, title, decode(text, null,'''', text) text, ' ||
                                                'pk_date_utils.dt_chr_date_hour_tsz(' || i_lang ||
                                                ', pk_date_utils.get_string_tstz(' || i_lang || ', profissional(' ||
                                                i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                                                '), dt_insert,null), profissional(' || i_prof.id || ',' ||
                                                i_prof.institution || ',' || i_prof.software || ')) dt_insert, ' ||
                                                'prof_name, ''' || l_aux_idx
                                               --begin|| ''' flg_type, ''' ||
                                                || ''' flg_type, pk_translation.get_translation(' || i_lang ||
                                                ' ,''P1_DATA_EXPORT_CONFIG.CODE_DATA_EXPORT_CONFIG.''||' ||
                                                to_char(l_dec_row.id_data_export_config) || ') desc_type, ''' ||
                                               --end
                                                pk_ref_constant.g_detail_status_a ||
                                                ''' flg_status, null id_institution, null flg_priority, null flg_home FROM TABLE(CAST(' ||
                                                l_func_tab(l_aux_idx) ||
                                                ' AS t_coll_p1_export_data)) WHERE text IS NOT NULL ';
                    
                    ELSE
                    
                        l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) ||
                                                'SELECT id, null id_parent, id_req, title, decode(text, null,'''', text) text, dt_insert, prof_name, flg_type, pk_translation.get_translation(' ||
                                                i_lang || ' ,''P1_DATA_EXPORT_CONFIG.CODE_DATA_EXPORT_CONFIG.''||' ||
                                                to_char(l_dec_row.id_data_export_config) ||
                                                ') desc_type, flg_status, id_institution, flg_priority, flg_home FROM TABLE(CAST(' ||
                                                l_func_tab(l_aux_idx) || ' AS t_coll_p1_export_data)) ';
                    END IF;
                
                END IF;
            END IF;
        END LOOP;
    
        -- Constroi sql para os tipo F
        FOR ctf IN c_dc_type_f
        LOOP
            l_aux_idx := ctf.flg_p1_data_type;
            g_error   := 'Append l_sql ' || l_aux_idx;
            IF l_ids_tab.exists(ctf.id_data_export_config || l_aux_idx)
            THEN
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@LANG', to_char(i_lang));
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@PROFESSIONAL', to_char(i_prof.id));
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@INSTITUTION', to_char(i_prof.institution));
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@SOFTWARE', to_char(i_prof.software));
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@PATIENT', to_char(i_patient));
                l_func_tab(l_aux_idx) := REPLACE(l_func_tab(l_aux_idx), '@EPISODE', to_char(i_episode));
            
                g_error := 'Append 1 ' || l_aux_idx;
                IF l_sql_tab(l_aux_idx) IS NOT NULL
                THEN
                    g_error := 'Append in' || l_aux_idx;
                    l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) || chr(10) || 'UNION ALL' || chr(10);
                END IF;
            
                g_error := 'Testing l_aux_idx';
                BEGIN
                    l_number := to_number(l_aux_idx);
                EXCEPTION
                    WHEN value_error THEN
                        l_number := NULL;
                END;
            
                g_error := 'Append out' || l_aux_idx;
            
                IF l_number IN (pk_ref_constant.g_detail_type_jstf,
                                pk_ref_constant.g_detail_type_sntm,
                                pk_ref_constant.g_detail_type_evlt,
                                pk_ref_constant.g_detail_type_hstr,
                                pk_ref_constant.g_detail_type_hstf,
                                pk_ref_constant.g_detail_type_obje,
                                pk_ref_constant.g_detail_type_cmpe,
                                pk_ref_constant.g_detail_type_vs)
                THEN
                    -- diferent columns
                    l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) ||
                                            'SELECT id, null id_parent, id_req, title, decode(text, null,'''', text) text, ' ||
                                            'pk_date_utils.dt_chr_date_hour_tsz(' || i_lang ||
                                            ', pk_date_utils.get_string_tstz(' || i_lang || ', profissional(' ||
                                            i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                                            '), dt_insert,null), profissional(' || i_prof.id || ',' ||
                                            i_prof.institution || ',' || i_prof.software || ')) dt_insert, ' ||
                                            'prof_name, ''' || l_aux_idx
                                           --|| ''' flg_type, ''' ||
                                            || ''' flg_type, pk_translation.get_translation(' || i_lang ||
                                            ' ,''P1_DATA_EXPORT_CONFIG.CODE_DATA_EXPORT_CONFIG.''||' ||
                                            to_char(ctf.id_data_export_config) || ') desc_type, ''' ||
                                           -- end
                                            pk_ref_constant.g_detail_status_a ||
                                            ''' flg_status, null id_institution, null flg_priority, null flg_home FROM TABLE(CAST(' ||
                                            l_func_tab(l_aux_idx) ||
                                            ' AS t_coll_p1_export_data)) WHERE text is not null and id_req in (' ||
                                            l_ids_tab(ctf.id_data_export_config || l_aux_idx) || ')';
                
                ELSE
                
                    l_sql_tab(l_aux_idx) := l_sql_tab(l_aux_idx) ||
                                            'SELECT id, null id_parent, id_req, title, decode(text, null,'''', text) text, dt_insert, prof_name, flg_type, pk_translation.get_translation(' ||
                                            i_lang || ' ,''P1_DATA_EXPORT_CONFIG.CODE_DATA_EXPORT_CONFIG.''||' ||
                                            to_char(ctf.id_data_export_config) ||
                                            ') desc_type, flg_status, id_institution, flg_priority, flg_home FROM TABLE(CAST(' ||
                                            l_func_tab(l_aux_idx) ||
                                            ' AS t_coll_p1_export_data)) t where t.id_req in (' ||
                                            l_ids_tab(ctf.id_data_export_config || l_aux_idx) || ')'; -- order by dt_insert ';
                END IF;
            END IF;
        END LOOP;
    
        -- Notes
        g_error := 'NOTES';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_note)
        THEN
            l_text := l_sql_tab(pk_ref_constant.g_detail_type_note);
        END IF;
    
        --Reason
        g_error := 'REASON';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_jstf)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_jstf);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_jstf);
            END IF;
        END IF;
    
        --Symptomatology   
        g_error := 'SYMPTOMATOLOGY';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_sntm)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_sntm);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_sntm);
            END IF;
        END IF;
    
        -- Progress
        g_error := 'PROGRESS';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_evlt)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_evlt);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_evlt);
            END IF;
        END IF;
    
        -- History
        g_error := 'HISTORY';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_hstr)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_hstr);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_hstr);
            END IF;
        END IF;
    
        -- Family history
        g_error := 'FAMILY HISTORY';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_hstf)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_hstf);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_hstf);
            END IF;
        END IF;
    
        -- Objective exam
        g_error := 'OBJECTIVE EXAM';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_obje)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_obje);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_obje);
            END IF;
        END IF;
    
        -- Diagnostic exams
        g_error := 'DIAGNOSTIC EXAMS';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_cmpe)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_cmpe);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_cmpe);
            END IF;
        END IF;
    
        -- Vital Signs
        g_error := 'VITAL SIGNS';
        IF l_sql_tab.exists(pk_ref_constant.g_detail_type_vs)
        THEN
            IF l_text IS NULL
            THEN
                l_text := l_sql_tab(pk_ref_constant.g_detail_type_vs);
            ELSE
                l_text := l_text || chr(10) || 'UNION ALL' || chr(10) || l_sql_tab(pk_ref_constant.g_detail_type_vs);
            END IF;
        END IF;
    
        g_error := 'OPEN L_TEXT';
        IF l_text IS NOT NULL
        THEN
            OPEN c_text FOR l_text;
        
            FETCH c_text BULK COLLECT
                INTO l_tbl_text;
        END IF;
    
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
        
            IF l_ds_internal_name = pk_orders_constant.g_ds_problems_addressed
            THEN
                -- Problema de saude a resolver
                g_error := 'OPEN C_PROBLEM';
                IF l_sql_tab.exists(pk_ref_constant.g_data_export_p1_type_p)
                THEN
                    OPEN c_problems FOR l_sql_tab(pk_ref_constant.g_data_export_p1_type_p);
                
                    FETCH c_problems BULK COLLECT
                        INTO l_tbl_problems;
                
                    FOR j IN i_value(i).first .. i_value(i).last
                    LOOP
                        IF i_value(i) (j) IS NOT NULL
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => to_char(i_value(i) (j)),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => pk_ts_core_ro.get_term_desc_translation(i_id_language     => i_lang,
                                                                                                                                             i_id_concept_term => i_value(i) (j),
                                                                                                                                             i_id_task_type    => pk_alert_constant.g_task_problems),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => 'A',
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        END IF;
                    END LOOP;
                
                    FOR j IN l_tbl_problems.first .. l_tbl_problems.last
                    LOOP
                    
                        BEGIN
                            SELECT *
                              INTO l_form_value, l_form_value_desc
                              FROM (SELECT phd.id_alert_diagnosis,l_tbl_problems(j).title
                                      FROM pat_history_diagnosis phd
                                     WHERE phd.id_patient = i_patient
                                       AND phd.id_pat_history_diagnosis = l_tbl_problems(j).id_req
                                       AND (phd.id_diagnosis = l_tbl_problems(j).id OR phd.id_diagnosis IS NULL)
                                    UNION
                                    SELECT pp.id_alert_diagnosis,l_tbl_problems(j).title
                                      FROM pat_problem pp
                                     WHERE pp.id_patient = i_patient
                                       AND pp.id_pat_problem = l_tbl_problems(j).id_req
                                       AND (pp.id_diagnosis = l_tbl_problems(j).id OR pp.id_diagnosis IS NULL));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_form_value,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_form_value_desc,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => 'A',
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_form_value      := NULL;
                                l_form_value_desc := NULL;
                        END;
                    
                    END LOOP;
                END IF;
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_diagnosis
            THEN
                l_diagnosis_mandatory := pk_sysconfig.get_config(pk_ref_constant.g_ref_diag_mandatory, i_prof);
            
                g_error := 'OPEN C_DIAGNOSIS';
                IF l_sql_tab.exists(pk_ref_constant.g_data_export_p1_type_d)
                THEN
                    OPEN c_diagnosis FOR l_sql_tab(pk_ref_constant.g_data_export_p1_type_d);
                
                    FETCH c_diagnosis BULK COLLECT
                        INTO l_tbl_diagnosis;
                
                    FOR j IN i_value(i).first .. i_value(i).last
                    LOOP
                        IF i_value(i) (j) IS NOT NULL
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => to_char(i_value(i) (j)),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => pk_ts_core_ro.get_term_desc_translation(i_id_language     => i_lang,
                                                                                                                                             i_id_concept_term => i_value(i) (j),
                                                                                                                                             i_id_task_type    => pk_alert_constant.g_task_diagnosis),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      l_diagnosis_mandatory
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          'M'
                                                                                                         ELSE
                                                                                                          'A'
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        END IF;
                    END LOOP;
                
                    FOR j IN l_tbl_diagnosis.first .. l_tbl_diagnosis.last
                    LOOP
                        BEGIN
                            SELECT *
                              INTO l_form_value, l_form_value_desc
                              FROM (SELECT ed.id_alert_diagnosis,l_tbl_diagnosis(j).title
                                      FROM epis_diagnosis ed
                                     WHERE ed.id_epis_diagnosis = l_tbl_diagnosis(j).id_req);
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_form_value,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_form_value_desc,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      l_diagnosis_mandatory
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          'M'
                                                                                                         ELSE
                                                                                                          'A'
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_form_value      := NULL;
                                l_form_value_desc := NULL;
                        END;
                    
                    END LOOP;
                ELSE
                    FOR j IN i_value(i).first .. i_value(i).last
                    LOOP
                        IF i_value(i) (j) IS NOT NULL
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => to_char(i_value(i) (j)),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => pk_ts_core_ro.get_term_desc_translation(i_id_language     => i_lang,
                                                                                                                                             i_id_concept_term => i_value(i) (j),
                                                                                                                                             i_id_task_type    => pk_alert_constant.g_task_diagnosis),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      l_diagnosis_mandatory
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          'M'
                                                                                                         ELSE
                                                                                                          'A'
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        ELSE
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => NULL,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      l_diagnosis_mandatory
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          'M'
                                                                                                         ELSE
                                                                                                          'A'
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        END IF;
                    END LOOP;
                END IF;
            ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_personal_history,
                                         pk_orders_constant.g_ds_executed_tests_ft,
                                         pk_orders_constant.g_ds_family_history,
                                         pk_orders_constant.g_ds_vital_signs,
                                         pk_orders_constant.g_ds_objective_examination_ft)
                  AND l_tbl_text.exists(1)
            THEN
                g_error    := 'OPEN TEXT';
                l_desc_aux := NULL;
                FOR j IN i_value(i).first .. i_value(i).last
                LOOP
                    IF i_value(i) (j) IS NOT NULL
                    THEN
                        l_desc_aux := l_desc_aux || i_value(i) (j) || chr(10);
                    END IF;
                END LOOP;
            
                SELECT decode(l_ds_internal_name,
                              pk_orders_constant.g_ds_personal_history,
                              tt.title || ':' || chr(10),
                              NULL) || tt.text AS text
                  BULK COLLECT
                  INTO l_tbl_desc_aux
                  FROM (SELECT t.title, listagg(t.text, chr(10)) within GROUP(ORDER BY dt_insert) AS text
                          FROM TABLE(l_tbl_text) t
                         WHERE t.flg_type = decode(l_ds_internal_name,
                                                   pk_orders_constant.g_ds_personal_history,
                                                   3,
                                                   pk_orders_constant.g_ds_executed_tests_ft,
                                                   6,
                                                   pk_orders_constant.g_ds_family_history,
                                                   4,
                                                   pk_orders_constant.g_ds_vital_signs,
                                                   43,
                                                   pk_orders_constant.g_ds_objective_examination_ft,
                                                   5)
                         GROUP BY t.title) tt;
            
                IF l_tbl_desc_aux.count > 0
                THEN
                    FOR j IN l_tbl_desc_aux.first .. l_tbl_desc_aux.last
                    LOOP
                        l_desc_aux := l_desc_aux || l_tbl_desc_aux(j) || chr(10);
                    
                        IF j < l_tbl_desc_aux.last
                        THEN
                            l_desc_aux := l_desc_aux || chr(10);
                        END IF;
                    END LOOP;
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_desc_aux,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_desc_aux,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => 'A',
                                                                       flg_multi_status   => NULL,
                                                                       idx                => 1);
                END IF;
            ELSIF l_ds_internal_name IN
                  (pk_orders_constant.g_ds_p1_import_ids, pk_orders_constant.g_ds_p1_import_values)
            THEN
                --CLEAR MEM DATA
                --It is necessary to reset these fields, otherwise, the action 'Import data' would allways
                --append information on this field
                tbl_result.extend();
                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                   id_ds_component    => NULL,
                                                                   internal_name      => l_ds_internal_name,
                                                                   VALUE              => NULL,
                                                                   value_clob         => NULL,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => NULL,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => 'A',
                                                                   flg_multi_status   => NULL,
                                                                   idx                => 1);
            END IF;
        END LOOP;
    
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            IF l_ds_internal_name = pk_orders_constant.g_ds_onset
            THEN
                g_error := 'OPEN ONSET';
                IF l_tbl_problems.exists(1) -- JB 2008-07-11 para n preencher a data qd n é escolhida a história actual
                THEN
                    BEGIN
                        g_error := 'SELECT get_pat_problem / ID_PAT=' || i_patient || ' TYPE=' || g_diagnosis;
                        SELECT dt_insert
                          INTO l_date_str
                          FROM (SELECT t.dt_insert
                                  FROM TABLE(get_pat_problem(i_lang    => i_lang,
                                                             i_prof    => i_prof,
                                                             i_patient => i_patient,
                                                             i_status  => pk_ref_constant.g_active,
                                                             i_type    => g_diagnosis)) t
                                 ORDER BY t.dt_insert)
                         WHERE rownum = 1;
                    
                        l_probl_date := to_date(l_date_str, pk_ref_constant.g_format_date_2);
                    
                        l_year  := extract(YEAR FROM l_probl_date);
                        l_month := extract(MONTH FROM l_probl_date);
                        l_day   := extract(DAY FROM l_probl_date);
                    
                        -- convert format YYYYMMDDHH24MISS to "flash format interpretation"
                        g_error      := 'Call pk_ref_utils.parse_dt_str_flash / l_date=' || l_date_str || ' l_year=' ||
                                        l_year || ' l_month=' || l_month || ' l_day=' || l_day;
                        l_date_flash := pk_ref_utils.parse_dt_str_flash(i_lang  => i_lang,
                                                                        i_prof  => i_prof,
                                                                        i_year  => l_year,
                                                                        i_month => l_month,
                                                                        i_day   => l_day);
                    
                        l_date_str := pk_ref_utils.parse_dt_str_app(i_lang  => i_lang,
                                                                    i_prof  => i_prof,
                                                                    i_year  => l_year,
                                                                    i_month => l_month,
                                                                    i_day   => l_day);
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_date_flash || '000000',
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_date_str,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => 'A',
                                                                           flg_multi_status   => NULL,
                                                                           idx                => 1);
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_date_flash := NULL;
                            l_date_str   := NULL;
                    END;
                END IF;
            END IF;
        END LOOP;
    
        RETURN tbl_result;
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_P1_DATA_EXPORT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN t_tbl_ds_get_value();
    END get_p1_data_export;

    /**
    * Get all available specialities for requests
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof  professional, institution and software ids
    * @param   i_patient patient id, to filter by sex and age
    * @param   o_sql canceling reason id
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   22-05-2008
    */
    FUNCTION get_clinical_service
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_sql     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_gender   patient.gender%TYPE;
        l_age      NUMBER;
        l_pat_info pk_types.cursor_type;
        l_mk       market.id_market%TYPE;
    BEGIN
        g_error := 'CALL pk_ref_core.get_pat_info';
        IF NOT pk_ref_core.get_pat_info(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_patient => i_patient,
                                        o_info    => l_pat_info,
                                        o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_pat_info';
        FETCH l_pat_info
            INTO l_gender, l_age;
        CLOSE l_pat_info;
    
        g_error := 'CALL pk_utils.get_institution_market';
        l_mk    := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        g_error := 'OPEN O_SQL';
        OPEN o_sql FOR
            SELECT DISTINCT ps.id_speciality,
                            pk_translation.get_translation(i_lang, ps.code_speciality) desc_cls_srv,
                            pk_ref_constant.g_p1_type_c flg_type
              FROM p1_speciality ps
              JOIN ref_spec_market rsm
                ON (rsm.id_speciality = ps.id_speciality)
             WHERE ps.flg_available = pk_ref_constant.g_yes
               AND ((l_gender IS NOT NULL AND
                   nvl(ps.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, l_gender)) OR
                   l_gender IS NULL OR l_gender = pk_ref_constant.g_gender_i)
               AND (nvl(l_age, 0) BETWEEN nvl(ps.age_min, 0) AND nvl(ps.age_max, nvl(l_age, 0)) OR nvl(l_age, 0) = 0)
               AND pk_translation.get_translation(i_lang, ps.code_speciality) IS NOT NULL
               AND rsm.flg_available = pk_ref_constant.g_yes
               AND rsm.id_market = l_mk
               AND ps.id_speciality NOT IN (SELECT rsi.id_speciality
                                              FROM ref_spec_institution rsi
                                             WHERE rsi.id_speciality = ps.id_speciality
                                               AND rsi.id_institution = i_prof.institution
                                               AND rsi.flg_available = pk_ref_constant.g_no)
             ORDER BY desc_cls_srv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_sql);
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sql);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_CLINICAL_SERVICE',
                                                     o_error    => o_error);
    END get_clinical_service;

    FUNCTION get_clinical_service
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_core_domain IS
        l_gender   patient.gender%TYPE;
        l_age      NUMBER;
        l_pat_info pk_types.cursor_type;
        l_mk       market.id_market%TYPE;
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
        g_error := 'CALL pk_ref_core.get_pat_info';
        IF NOT pk_ref_core.get_pat_info(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_patient => i_patient,
                                        o_info    => l_pat_info,
                                        o_error   => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_pat_info';
        FETCH l_pat_info
            INTO l_gender, l_age;
        CLOSE l_pat_info;
    
        g_error := 'CALL pk_utils.get_institution_market';
        l_mk    := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => desc_cls_srv,
                                         domain_value  => id_speciality,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT DISTINCT ps.id_speciality,
                                        pk_translation.get_translation(i_lang, ps.code_speciality) desc_cls_srv,
                                        pk_ref_constant.g_p1_type_c flg_type
                          FROM p1_speciality ps
                          JOIN ref_spec_market rsm
                            ON (rsm.id_speciality = ps.id_speciality)
                         WHERE ps.flg_available = pk_ref_constant.g_yes
                           AND ((l_gender IS NOT NULL AND
                               nvl(ps.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, l_gender)) OR
                               l_gender IS NULL OR l_gender = pk_ref_constant.g_gender_i)
                           AND (nvl(l_age, 0) BETWEEN nvl(ps.age_min, 0) AND nvl(ps.age_max, nvl(l_age, 0)) OR
                               nvl(l_age, 0) = 0)
                           AND pk_translation.get_translation(i_lang, ps.code_speciality) IS NOT NULL
                           AND rsm.flg_available = pk_ref_constant.g_yes
                           AND rsm.id_market = l_mk
                           AND ps.id_speciality NOT IN
                               (SELECT rsi.id_speciality
                                  FROM ref_spec_institution rsi
                                 WHERE rsi.id_speciality = ps.id_speciality
                                   AND rsi.id_institution = i_prof.institution
                                   AND rsi.flg_available = pk_ref_constant.g_no)
                         ORDER BY desc_cls_srv));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLINICAL_SERVICE',
                                              o_error    => l_error);
            RETURN t_tbl_core_domain();
    END get_clinical_service;

    /**
    * Get all available clinical institutions  ALERT-158599
    *
    * @param   i_lang            language associated to the professional executing the request
    * @param   i_prof            professional, institution and software ids
    * @param   i_p1_spec         P1_speciality
    * @param   o_sql             clinical institutions
    * @param   o_error an error  message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   31-01-2011
    */
    FUNCTION get_clinical_institution
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_p1_spec IN p1_speciality.id_speciality%TYPE,
        o_sql     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_network_available VARCHAR2(1 CHAR);
        l_ref_net_all_inst      VARCHAR2(1 CHAR);
    BEGIN
        l_ref_network_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_network_available, i_prof),
                                       pk_ref_constant.g_no);
    
        g_error := 'NETWORK AVAILABLE=' || l_ref_network_available;
        IF l_ref_network_available = pk_ref_constant.g_yes
        THEN
        
            l_ref_net_all_inst := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_net_all_inst, i_prof),
                                      pk_ref_constant.g_no);
        
            IF l_ref_net_all_inst = pk_ref_constant.g_yes
            THEN
                g_error  := 'Call pk_ref_list.get_net_all_inst / i_p1_spec=' || i_p1_spec || ' NETWORK AVAILABLE=' ||
                            l_ref_network_available;
                g_retval := pk_ref_list.get_net_all_inst(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_ref_type            => 'A',
                                                         i_external_sys        => NULL,
                                                         i_id_speciality       => i_p1_spec,
                                                         i_flg_ref_line        => NULL,
                                                         i_flg_type_ins        => NULL,
                                                         i_flg_inside_ref_area => NULL,
                                                         i_flg_type            => pk_ref_constant.g_p1_type_c,
                                                         o_sql                 => o_sql,
                                                         o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSE
            
                g_error  := 'Call pk_ref_list.get_net_inst / i_p1_spec=' || i_p1_spec || ' NETWORK AVAILABLE=' ||
                            l_ref_network_available;
                g_retval := pk_ref_list.get_net_inst(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_ref_type            => pk_ref_constant.g_flg_availability_e,
                                                     i_external_sys        => NULL,
                                                     i_id_speciality       => i_p1_spec,
                                                     i_flg_ref_line        => NULL,
                                                     i_flg_type_ins        => NULL,
                                                     i_flg_inside_ref_area => NULL,
                                                     i_flg_type            => pk_ref_constant.g_p1_type_c,
                                                     o_sql                 => o_sql,
                                                     o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        ELSE
            OPEN o_sql FOR
                SELECT data.id_institution,
                       data.abbreviation abbreviation,
                       pk_translation.get_translation(i_lang, data.code_institution) desc_institution,
                       pk_ref_constant.g_yes flg_default,
                       (SELECT COUNT(sh.id_spec_help)
                          FROM p1_spec_help sh
                         WHERE sh.id_speciality = i_p1_spec
                           AND sh.id_institution = data.id_institution
                           AND sh.flg_available = pk_ref_constant.g_yes) help_count
                  FROM institution data
                 WHERE id_institution = to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, i_prof))
                   AND l_ref_network_available = pk_ref_constant.g_no
                 ORDER BY flg_default DESC, desc_institution;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_sql);
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sql);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_CLINICAL_INSTITUTION',
                                                     o_error    => o_error);
    END get_clinical_institution;

    FUNCTION get_clinical_institution
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_spec IN p1_speciality.id_speciality%TYPE
    ) RETURN t_tbl_core_domain IS
        l_ref_network_available VARCHAR2(1 CHAR);
        l_ref_net_all_inst      VARCHAR2(1 CHAR);
    
        l_sql    pk_types.cursor_type;
        l_record pk_ref_list.t_rec_ref_institution;
    
        l_ret   t_tbl_core_domain := t_tbl_core_domain();
        l_error t_error_out;
    BEGIN
        IF i_spec IS NOT NULL
        THEN
            l_ref_network_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_network_available, i_prof),
                                           pk_ref_constant.g_no);
        
            g_error := 'NETWORK AVAILABLE=' || l_ref_network_available;
            IF l_ref_network_available = pk_ref_constant.g_yes
            THEN
            
                l_ref_net_all_inst := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_net_all_inst, i_prof),
                                          pk_ref_constant.g_no);
            
                IF l_ref_net_all_inst = pk_ref_constant.g_yes
                THEN
                    g_error  := 'Call pk_ref_list.get_net_all_inst / i_spec=' || i_spec || ' NETWORK AVAILABLE=' ||
                                l_ref_network_available;
                    g_retval := pk_ref_list.get_net_all_inst(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_ref_type            => 'A',
                                                             i_external_sys        => NULL,
                                                             i_id_speciality       => i_spec,
                                                             i_flg_ref_line        => NULL,
                                                             i_flg_type_ins        => NULL,
                                                             i_flg_inside_ref_area => NULL,
                                                             i_flg_type            => pk_ref_constant.g_p1_type_c,
                                                             o_sql                 => l_sql,
                                                             o_error               => l_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception;
                    ELSE
                        LOOP
                            FETCH l_sql
                                INTO l_record;
                            EXIT WHEN l_sql%NOTFOUND;
                        
                            l_ret.extend();
                            l_ret(l_ret.count) := t_row_core_domain(internal_name => NULL,
                                                                    desc_domain   => l_record.desc_institution,
                                                                    domain_value  => l_record.id_institution,
                                                                    order_rank    => NULL,
                                                                    img_name      => NULL);
                        
                        END LOOP;
                    END IF;
                
                ELSE
                
                    g_error  := 'Call pk_ref_list.get_net_inst / i_spec=' || i_spec || ' NETWORK AVAILABLE=' ||
                                l_ref_network_available;
                    g_retval := pk_ref_list.get_net_inst(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_ref_type            => pk_ref_constant.g_flg_availability_e,
                                                         i_external_sys        => NULL,
                                                         i_id_speciality       => i_spec,
                                                         i_flg_ref_line        => NULL,
                                                         i_flg_type_ins        => NULL,
                                                         i_flg_inside_ref_area => NULL,
                                                         i_flg_type            => pk_ref_constant.g_p1_type_c,
                                                         o_sql                 => l_sql,
                                                         o_error               => l_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception;
                    ELSE
                        LOOP
                            FETCH l_sql
                                INTO l_record;
                            EXIT WHEN l_sql%NOTFOUND;
                        
                            l_ret.extend();
                            l_ret(l_ret.count) := t_row_core_domain(internal_name => NULL,
                                                                    desc_domain   => l_record.desc_institution,
                                                                    domain_value  => l_record.id_institution,
                                                                    order_rank    => NULL,
                                                                    img_name      => NULL);
                        
                        END LOOP;
                    END IF;
                END IF;
            ELSE
                SELECT *
                  BULK COLLECT
                  INTO l_ret
                  FROM (SELECT t_row_core_domain(internal_name => NULL,
                                                 desc_domain   => desc_institution,
                                                 domain_value  => id_institution,
                                                 order_rank    => NULL,
                                                 img_name      => NULL)
                          FROM (SELECT data.id_institution,
                                       pk_translation.get_translation(i_lang, data.code_institution) desc_institution,
                                       pk_ref_constant.g_yes flg_default
                                  FROM institution data
                                 WHERE id_institution =
                                       to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, i_prof))
                                   AND l_ref_network_available = pk_ref_constant.g_no
                                 ORDER BY flg_default DESC, desc_institution));
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN t_tbl_core_domain();
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLINICAL_INSTITUTION',
                                              o_error    => l_error);
            RETURN t_tbl_core_domain();
    END get_clinical_institution;

    /**
    * Get patient mcdt
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_episode episode id    
    * @param   i_patient patient id  
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   25-06-2008
    */
    FUNCTION get_pat_mcdt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN analysis_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED IS
    
        l_out_rec t_rec_p1_export_data;
    
        -- lab tests    
        l_lab_test_list            pk_lab_tests_external.t_cur_lab_test_result;
        l_reflex_test_list         pk_lab_tests_external.t_cur_lab_test_result;
        l_id_analysis_req_det_prev table_number;
        TYPE t_coll_lab_test_result IS TABLE OF pk_lab_tests_external.t_rec_lab_test_result;
        l_lab_test_result_tab    t_coll_lab_test_result;
        l_reflex_test_result_tab t_coll_lab_test_result;
    
        -- exams
        l_exam_list pk_exam_external.t_cur_exam_result;
        TYPE t_coll_exam_result IS TABLE OF pk_exam_external.t_rec_exam_result;
        l_lexam_result_tab t_coll_exam_result;
    
        -- interv
        l_procedure_list pk_procedures_external.t_cur_procedure;
        TYPE t_coll_procedure IS TABLE OF pk_procedures_external.t_rec_procedure;
        l_procedure_tab t_coll_procedure;
    
        -- rehab
        l_rec_rehab rehab_rec;
        l_rehab_tab t_coll_rehab;
        l_treat     pk_types.cursor_type;
    
        l_error              t_error_out;
        l_p1_doctor_req_t062 sys_message.desc_message%TYPE;
        l_analysis_t059      sys_message.desc_message%TYPE;
        l_ref_ext_sys_t004   sys_message.desc_message%TYPE;
        l_limit              PLS_INTEGER := 1000;
        l_params             VARCHAR2(1000 CHAR);
        l_params_int         VARCHAR2(1000 CHAR);
        l_parameter_result   VARCHAR2(1000 CHAR);
    
        FUNCTION clob_to_varchar2(x_clob IN CLOB) RETURN VARCHAR2 IS
            l_result VARCHAR2(1000 CHAR);
        BEGIN
            IF length(x_clob) > 200
            THEN
                l_result := pk_string_utils.clob_to_varchar2(x_clob, 200) || '...';
            ELSE
                l_result := x_clob;
            END IF;
        
            RETURN l_result;
        END clob_to_varchar2;
    
        -- sets the string do each labtest parameter result
        -- text format: <parameter_name> (<P1_DOCTOR_REQ_T062>: <mcdt_result>[ <abnorm>][ <desc_unit_measure>][ <ref_val>])
        FUNCTION get_labtest_param_result
        (
            x_desc_param        IN VARCHAR2,
            x_abnorm            IN VARCHAR2,
            x_ref_val           IN VARCHAR2,
            x_desc_unit_measure IN VARCHAR2,
            x_flg_result_type   IN VARCHAR2,
            x_result            IN CLOB
        ) RETURN VARCHAR2 IS
            l_analysis_result_value  VARCHAR2(1000 CHAR);
            l_labtest_result_varchar VARCHAR2(1000 CHAR);
            l_result                 VARCHAR2(1000 CHAR);
        BEGIN
            g_error                  := 'Init get_parameter_result';
            l_analysis_result_value  := NULL;
            l_labtest_result_varchar := pk_string_utils.clob_to_varchar2(x_result, 1000);
        
            g_error := 'CASE ' || x_flg_result_type;
            CASE x_flg_result_type
                WHEN pk_lab_tests_constant.g_analysis_result_icon THEN
                    -- icon type, get text after '|'
                    l_analysis_result_value := substr(l_labtest_result_varchar,
                                                      instr(l_labtest_result_varchar, '|') + 1);
                ELSE
                
                    -- number or text
                    l_analysis_result_value := clob_to_varchar2(x_clob => l_labtest_result_varchar);
            END CASE;
        
            -- setting output with lab test parameter results 
            g_error  := 'l_result';
            l_result := x_desc_param || ' (' || l_p1_doctor_req_t062 || ': ' || l_analysis_result_value;
        
            g_error := 'x_abnorm= ' || x_abnorm;
            IF x_abnorm IS NOT NULL
            THEN
                l_result := l_result || ' ' || x_abnorm;
            END IF;
        
            g_error := 'x_desc_unit_measure= ' || x_desc_unit_measure;
            IF x_desc_unit_measure IS NOT NULL
            THEN
                l_result := l_result || ' ' || x_desc_unit_measure;
            END IF;
        
            g_error := 'x_ref_val= ' || x_ref_val;
            IF nvl(x_ref_val, ' ') != ' '
            THEN
                l_result := l_result || '; ' || l_analysis_t059 || ': ' || x_ref_val;
            END IF;
        
            l_result := l_result || ') ';
        
            RETURN l_result;
        END get_labtest_param_result;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_epis=' || i_epis || ' i_patient=' || i_patient;
        g_error  := 'Init get_pat_mcdt / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        l_p1_doctor_req_t062 := pk_message.get_message(i_lang, 'P1_DOCTOR_REQ_T062');
        l_analysis_t059      := pk_message.get_message(i_lang, 'ANALYSIS_T059');
        l_ref_ext_sys_t004   := pk_message.get_message(i_lang, 'REF_EXT_SYS_T004'); -- reflext test
    
        -------------------------------------------------------
        -- getting lab test results information
    
        BEGIN
            g_error  := 'Call pk_lab_tests_external_api_db.get_epis_analysis_det_internal / ' || l_params;
            g_retval := pk_lab_tests_external_api_db.get_lab_test_resultsview(i_lang             => i_lang,
                                                                              i_prof             => i_prof,
                                                                              i_patient          => i_patient,
                                                                              i_episode          => i_epis,
                                                                              i_analysis_req_det => NULL,
                                                                              o_list             => l_lab_test_list,
                                                                              o_error            => l_error);
        
            FETCH l_lab_test_list BULK COLLECT
                INTO l_lab_test_result_tab;
            CLOSE l_lab_test_list;
        
            g_error := '<<lab_tests>> / FOR i IN 1 .. ' || l_lab_test_result_tab.count || ' / ' || l_params;
            <<lab_tests>>
            FOR i IN 1 .. l_lab_test_result_tab.count
            LOOP
            
                l_params_int := 'ID_ANALYSIS_REQ_DET=' || l_lab_test_result_tab(i).id_analysis_req_det(1) || ' DT_REQ=' || l_lab_test_result_tab(i).dt_req;
            
                g_error := 'l_id_analysis_req_det_prev / ' || l_params_int || ' / ' || l_params;
                IF l_lab_test_result_tab(i).flg_result_type IS NOT NULL
                    AND (l_id_analysis_req_det_prev IS NULL OR
                         l_id_analysis_req_det_prev.count != l_lab_test_result_tab(i).id_analysis_req_det.count OR
                         l_id_analysis_req_det_prev(1) != l_lab_test_result_tab(i).id_analysis_req_det(1) -- first ID_REQ_DET
                         )
                THEN
                
                    -----------------------------
                    -- for each analysis_req_det, that is not a reflex test, create a new row with analysis description and creation date
                
                    IF l_id_analysis_req_det_prev IS NOT NULL
                    THEN
                        PIPE ROW(l_out_rec); -- previous analysis_req_det
                    END IF;
                
                    -- new analysis_req_det
                    g_error   := 't_rec_p1_export_data() / ' || l_params_int || ' / ' || l_params;
                    l_out_rec := t_rec_p1_export_data();
                
                    g_error            := 'l_out_rec analysis / ' || l_params_int || ' / ' || l_params;
                    l_out_rec.id_req   := l_lab_test_result_tab(i).id_analysis;
                    l_out_rec.title    := l_lab_test_result_tab(i).desc_analysis || ' (' || l_lab_test_result_tab(i).dt_req || ')';
                    l_out_rec.flg_type := g_analysis;
                
                    -- add lab test name. Text format: <mcdt_name> (<mcdt_dt>)
                    l_out_rec.text := l_lab_test_result_tab(i).desc_analysis || ' (' || l_lab_test_result_tab(i).dt_req || ')';
                END IF;
            
                -----------------------------
                -- getting result values of each analysis_req_det
            
                IF l_lab_test_result_tab(i).flg_result_type IS NULL
                THEN
                    -- getting reflext test results (several results linked to the previous labtest parameter)
                    g_error  := 'Call pk_lab_tests_external_api_db.get_epis_analysis_det_internal / i_analysis_req_det=' ||
                                pk_utils.to_string(l_lab_test_result_tab(i).id_analysis_req_det) || ' / ' ||
                                l_params_int || ' / ' || l_params;
                    g_retval := pk_lab_tests_external_api_db.get_lab_test_resultsview(i_lang             => i_lang,
                                                                                      i_prof             => i_prof,
                                                                                      i_patient          => i_patient,
                                                                                      i_episode          => i_epis,
                                                                                      i_analysis_req_det => l_lab_test_result_tab(i).id_analysis_req_det,
                                                                                      o_list             => l_reflex_test_list,
                                                                                      o_error            => l_error);
                
                    g_error := 'FETCH l_reflex_test_list BULK COLLECT INTO / ' || l_params_int || ' / ' || l_params;
                    FETCH l_reflex_test_list BULK COLLECT
                        INTO l_reflex_test_result_tab;
                    CLOSE l_reflex_test_list;
                
                    g_error := 'FOR i IN 1 .. ' || l_reflex_test_result_tab.count || ' / <<reflex_tests>> / ' ||
                               l_params_int || ' / ' || l_params;
                    <<reflex_tests>>
                    FOR i IN 1 .. l_reflex_test_result_tab.count
                    LOOP
                        -- getting each result of reflext test
                        g_error            := 'Call get_labtest_param_result reflext test / ' || l_params_int || ' / ' ||
                                              l_params;
                        l_parameter_result := get_labtest_param_result(x_desc_param        => l_reflex_test_result_tab(i).desc_parameter,
                                                                       x_abnorm            => l_reflex_test_result_tab(i).abnormality,
                                                                       x_ref_val           => l_reflex_test_result_tab(i).ref_val,
                                                                       x_desc_unit_measure => l_reflex_test_result_tab(i).desc_unit_measure,
                                                                       x_flg_result_type   => l_reflex_test_result_tab(i).flg_result_type,
                                                                       x_result            => l_reflex_test_result_tab(i).result);
                    
                        -- append the result
                        l_out_rec.text := l_out_rec.text || chr(10) || '   - ' || l_ref_ext_sys_t004 || ': ' ||
                                          l_parameter_result;
                    END LOOP reflex_tests;
                
                ELSE
                    -- getting labtest result parameter
                    l_params_int := l_params_int || ' flg_type=' || l_lab_test_result_tab(i).flg_type || ' abnorm=' || l_lab_test_result_tab(i).abnormality ||
                                    ' l_ref_val=' || l_lab_test_result_tab(i).ref_val;
                
                    g_error            := 'Call get_labtest_param_result / ' || l_params_int || ' / ' || l_params;
                    l_parameter_result := get_labtest_param_result(x_desc_param        => l_lab_test_result_tab(i).desc_parameter,
                                                                   x_abnorm            => l_lab_test_result_tab(i).abnormality,
                                                                   x_ref_val           => l_lab_test_result_tab(i).ref_val,
                                                                   x_desc_unit_measure => l_lab_test_result_tab(i).desc_unit_measure,
                                                                   x_flg_result_type   => l_lab_test_result_tab(i).flg_result_type,
                                                                   x_result            => l_lab_test_result_tab(i).result);
                
                    -- append the result
                    l_out_rec.text := l_out_rec.text || chr(10) || '- ' || l_parameter_result;
                
                END IF;
            
                g_error                    := 'l_id_analysis_req_det_prev / ' || l_params_int || ' / ' || l_params;
                l_id_analysis_req_det_prev := l_lab_test_result_tab(i).id_analysis_req_det;
            END LOOP;
        
            IF l_out_rec.id_req IS NOT NULL
            THEN
                PIPE ROW(l_out_rec); -- the last analysis_req_det with results
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
                -- continue to import exams data            
        END;
    
        -------------------------------------------------------
        -- image and other exams
        BEGIN
            g_error  := 'image and other exams / ' || l_params;
            g_retval := pk_exams_external_api_db.get_exam_listview(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_episode => i_epis,
                                                                   o_list    => l_exam_list,
                                                                   o_error   => l_error);
        
            FETCH l_exam_list BULK COLLECT
                INTO l_lexam_result_tab;
            CLOSE l_exam_list;
        
            g_error := '<<exams>> / FOR i IN 1 .. ' || l_lexam_result_tab.count || ' / ' || l_params;
            <<exams>>
            FOR i IN 1 .. l_lexam_result_tab.count
            LOOP
            
                l_params_int := 'ID_EXAM_REQ_DET=' || l_lexam_result_tab(i).id_exam_req_det || ' ID_EXAM=' || l_lexam_result_tab(i).id_exam ||
                                ' DT_REQ=' || l_lexam_result_tab(i).dt_req;
            
                g_error          := 'l_out_rec exams / ' || l_params_int || ' / ' || l_params;
                l_out_rec        := t_rec_p1_export_data();
                l_out_rec.id_req := l_lexam_result_tab(i).id_exam;
            
                -- text format: <mcdt_name> (<mcdt_dt>; <P1_DOCTOR_REQ_T062>: <mcdt_result>)
                g_error        := 'l_out_rec.text / ' || l_params_int || ' / ' || l_params;
                l_out_rec.text := l_lexam_result_tab(i).desc_exam || ' (' || l_lexam_result_tab(i).dt_req;
            
                IF l_lexam_result_tab(i).result IS NOT NULL
                    AND length(l_lexam_result_tab(i).result) > 0
                THEN
                
                    l_out_rec.text := l_out_rec.text || '; ' || l_p1_doctor_req_t062 || ': ' ||
                                      clob_to_varchar2(x_clob => l_lexam_result_tab(i).result);
                END IF;
                l_out_rec.text := l_out_rec.text || ')';
            
                l_out_rec.title := l_lexam_result_tab(i).desc_exam || ' (' || l_lexam_result_tab(i).dt_req || ')';
            
                PIPE ROW(l_out_rec);
            END LOOP exams;
        EXCEPTION
            WHEN OTHERS THEN
                pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
                -- continue to import procedures data            
        END;
    
        -- interv
        BEGIN
            g_error  := 'Call pk_procedures_external_api_db.get_procedure_listview / ' || l_params;
            g_retval := pk_procedures_external_api_db.get_procedure_listview(i_lang    => i_lang,
                                                                             i_prof    => i_prof,
                                                                             i_episode => i_epis,
                                                                             o_list    => l_procedure_list,
                                                                             o_error   => l_error);
        
            FETCH l_procedure_list BULK COLLECT
                INTO l_procedure_tab;
            CLOSE l_procedure_list;
        
            g_error := '<<procedures>> / FOR i IN 1 .. ' || l_procedure_tab.count || ' / ' || l_params;
            <<procedures>>
            FOR i IN 1 .. l_procedure_tab.count
            LOOP
            
                l_params_int := 'ID_INTERV_PRESC_DET=' || l_procedure_tab(i).id_interv_presc_det || ' ID_INTERVENTION=' || l_procedure_tab(i).id_intervention ||
                                ' DT_REQ=' || l_procedure_tab(i).dt_req;
            
                g_error          := 'l_out_rec procedures / ' || l_params_int || ' / ' || l_params;
                l_out_rec        := t_rec_p1_export_data();
                l_out_rec.id_req := l_procedure_tab(i).id_intervention;
            
                -- text format: <mcdt_name> (<mcdt_dt>; <P1_DOCTOR_REQ_T062>: <mcdt_result>)
                g_error        := 'l_out_rec.text / ' || l_params_int || ' / ' || l_params;
                l_out_rec.text := l_procedure_tab(i).desc_procedure || ' (' || l_procedure_tab(i).dt_req;
                l_out_rec.text := l_out_rec.text || ')';
            
                l_out_rec.title := l_procedure_tab(i).desc_procedure || ' (' || l_procedure_tab(i).dt_req || ')';
            
                l_out_rec.flg_type := pk_ref_constant.g_p1_type_p;
            
                pk_alertlog.log_error(l_out_rec.text);
            
                PIPE ROW(l_out_rec);
            END LOOP procedures;
        EXCEPTION
            WHEN OTHERS THEN
                pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
                -- continue to import rehab data            
        END;
    
        g_error  := 'Call pk_rehab.get_rehab_treatment_referral / ' || l_params;
        g_retval := pk_rehab.get_rehab_treatment_referral(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_patient => i_patient,
                                                          i_id_episode => i_epis,
                                                          o_treat      => l_treat,
                                                          o_error      => l_error);
    
        g_error := 'FETCH l_treat / ' || l_params;
        LOOP
            FETCH l_treat BULK COLLECT
                INTO l_rehab_tab LIMIT l_limit;
        
            g_error := 'l_rehab_tab.COUNT=' || l_rehab_tab.count || ' / ' || l_params;
            FOR idx IN 1 .. l_rehab_tab.count
            LOOP
                l_rec_rehab := l_rehab_tab(idx);
            
                -- PMR intervention completed
                g_error := 'l_rec_rehab.proc_status=' || l_rec_rehab.proc_status || ' / ' || l_params;
                IF l_rec_rehab.proc_status = pk_rehab.g_rehab_presc_finished
                THEN
                    l_out_rec        := t_rec_p1_export_data();
                    l_out_rec.id_req := l_rec_rehab.id_intervention;
                
                    g_error        := 'rehab: l_out_rec.text / ' || l_params;
                    l_out_rec.text := l_rec_rehab.desc_procedure || ' (' ||
                                      pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                            pk_date_utils.get_string_tstz(i_lang,
                                                                                                          i_prof,
                                                                                                          l_rec_rehab.date_req,
                                                                                                          NULL),
                                                                            i_prof);
                
                    l_out_rec.text := l_out_rec.text || ')';
                
                    g_error         := 'l_out_rec.title / ' || l_params;
                    l_out_rec.title := l_rec_rehab.desc_procedure || ' ' || l_rec_rehab.desc_area || ' (' ||
                                       pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           l_rec_rehab.date_req,
                                                                                                           NULL),
                                                                             i_prof) || ')';
                
                    l_out_rec.flg_type := pk_ref_constant.g_p1_type_f;
                    --l_out_rec.flg_status := l_rec_rehab.proc_status;
                    --l_out_rec.dt_insert  := l_rec_rehab.date_req;
                
                    PIPE ROW(l_out_rec);
                
                END IF;
            
            END LOOP;
        
            EXIT WHEN l_treat%NOTFOUND;
        END LOOP;
    
        CLOSE l_treat;
    
        RETURN;
    
    EXCEPTION
        WHEN rowtype_mismatch THEN
            pk_alertlog.log_error('GET_PAT_MCDT - Alterar type. ' || g_error || ' / ' || SQLERRM);
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
    END get_pat_mcdt;

    /**
    * Get patient active problems list
    *
    * @param   i_lang    Language associated to the professional executing the request
    * @param   i_prof    Professional, institution and software ids
    * @param   i_patient Patient identifier
    * @param   i_status  Status problem
    * @param   i_type    Problem type     
    *
    * @value   i_type    {*} 'D' Relevant Disease; {*} 'P' Problems; {*} 'A' Allergies
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joao Sa
    * @version 1.0
    * @since   14-05-2008
    */
    FUNCTION get_pat_problem
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_status  IN VARCHAR2,
        i_type    IN VARCHAR2
    ) RETURN t_coll_p1_export_data
        PIPELINED IS
        out_rec           t_rec_p1_export_data := t_rec_p1_export_data(NULL,
                                                                       NULL,
                                                                       NULL,
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
        l_pat_problem     pk_problems.pat_problem_cur;
        l_pat_problem_rec pk_problems.pat_problem_rec;
        l_error           t_error_out;
    
        o_pat_prob_unaware_active   pk_types.cursor_type;
        o_pat_prob_unaware_outdated pk_types.cursor_type;
    BEGIN
        g_error  := 'Call pk_problems.get_pat_problem / STATUS=' || i_status || ' TYPE=' || i_type;
        g_retval := pk_problems.get_pat_problem(i_lang                      => i_lang,
                                                i_pat                       => i_patient,
                                                i_status                    => i_status,
                                                i_type                      => i_type,
                                                i_prof                      => i_prof,
                                                o_pat_problem               => l_pat_problem,
                                                o_pat_prob_unaware_active   => o_pat_prob_unaware_active,
                                                o_pat_prob_unaware_outdated => o_pat_prob_unaware_outdated,
                                                o_error                     => l_error);
    
        LOOP
            g_error := 'FETCH INTO l_pat_problem_rec';
            FETCH l_pat_problem
                INTO l_pat_problem_rec;
            EXIT WHEN l_pat_problem%NOTFOUND;
        
            IF l_pat_problem_rec.type = nvl(i_type, l_pat_problem_rec.type) -- filter here (the function does not do it)
               AND l_pat_problem_rec.flg_status = nvl(i_status, l_pat_problem_rec.flg_status)
            THEN
            
                g_error := 'Fill out_rec 1';
                --out_rec.id        := l_pat_problem_rec.id_problem;
                out_rec.id        := nvl(l_pat_problem_rec.id, pk_ref_constant.g_exr_diag_id_other); -- id_diagnosis
                out_rec.id_parent := NULL;
                out_rec.id_req    := l_pat_problem_rec.id_problem;
                out_rec.text      := l_pat_problem_rec.title;
            
                g_error := 'i_type=' || i_type;
                IF i_type = g_diagnosis
                THEN
                    -- Relevant Disease
                    out_rec.title := l_pat_problem_rec.desc_probl;
                    out_rec.text  := l_pat_problem_rec.title;
                ELSE
                    -- Problems or Allergies
                    g_error       := 'Problem data';
                    out_rec.title := l_pat_problem_rec.title;
                    out_rec.text  := l_pat_problem_rec.desc_probl;
                END IF;
            
                g_error                := 'Fill out_rec 2';
                out_rec.dt_insert      := l_pat_problem_rec.dt_order;
                out_rec.prof_name      := NULL;
                out_rec.flg_type       := l_pat_problem_rec.flg_source;
                out_rec.flg_status     := l_pat_problem_rec.flg_status;
                out_rec.id_institution := NULL;
                out_rec.flg_priority   := NULL;
                out_rec.flg_home       := NULL;
            
                IF i_type = g_alergies
                THEN
                    out_rec.text := out_rec.text || '.';
                    out_rec.id   := NULL; -- Allergies must have this field null
                END IF;
            
                g_error := 'i_pat_prob=' || out_rec.id || ' i_type=' || out_rec.flg_type;
                pk_alertlog.log_debug(g_error);
            
                -- Get notes        
                g_error := 'CALL to pk_problems.get_pat_problem_det / PAT_PROB=' || out_rec.id || ' TYPE=' ||
                           out_rec.flg_type;
                IF l_pat_problem_rec.title_notes IS NOT NULL
                THEN
                    out_rec.text := out_rec.text || chr(10) || l_pat_problem_rec.prob_notes;
                
                    --g_error  := 'Call pk_problems.get_pat_problem_det_new / i_pat_prob=' || out_rec.id || ' i_type=' || out_rec.flg_type;
                    --g_retval := pk_problems.get_pat_problem_det_new(i_lang     => i_lang,
                    --                                                i_prof     => i_prof,
                    --                                                i_pat_prob => out_rec.id,
                    --                                                i_type     => out_rec.flg_type,
                    --                                                o_problem  => l_problem,
                    --                                                o_error    => l_error);
                
                    --IF NOT g_retval
                    --THEN
                    --    RAISE g_exception;
                    --END IF;
                
                    --g_error := 'FETCH l_problem INTO l_problem_rec;';
                    --FETCH l_problem
                    --    INTO l_problem_rec;
                
                    --out_rec.text := l_problem_rec.notes;
                END IF;
            
                PIPE ROW(out_rec);
                out_rec.text := NULL;
            END IF;
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN no_data_needed THEN
            RETURN;
        WHEN no_data_found THEN
            RETURN;
        WHEN rowtype_mismatch THEN
            pk_alertlog.log_error('GET_PAT_PROBLEM. - Alterar type pat_problem_rec. ' || g_error || ' / ' || SQLERRM);
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
    END get_pat_problem;

    /**
    * Get patient diagnosis
    *
    * @param   i_lang    Language associated to the professional executing the request
    * @param   i_prof    Professional, institution and software ids
    * @param   i_epis    Episode identifier
    * @param   i_patient Patient identifier
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   20-05-2008
    */

    FUNCTION get_pat_diagnosis
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED IS
        out_rec t_rec_p1_export_data := t_rec_p1_export_data(NULL,
                                                             NULL,
                                                             NULL,
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
    
        l_diagnosis     pk_edis_types.diagnosis_cur;
        l_diagnosis_rec pk_edis_types.diagnosis_list_rec;
        l_error         t_error_out;
    
    BEGIN
    
        g_error  := 'Call pk_diagnosis.get_epis_diagnosis_list / ID_EPISODE=' || i_epis;
        g_retval := pk_diagnosis.get_epis_diagnosis_list(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_episode  => i_epis,
                                                         i_flg_type => pk_diagnosis.g_diag_type_p,
                                                         o_list     => l_diagnosis,
                                                         o_error    => l_error);
    
        LOOP
            g_error := 'FETCH INTO l_diagnosis';
        
            FETCH l_diagnosis
                INTO l_diagnosis_rec;
            EXIT WHEN l_diagnosis%NOTFOUND;
        
            IF l_diagnosis_rec.status_diagnosis = g_final_diagnosis
            -- JB 2008-06-16 Só interessam os que estão confirmados
            THEN
            
                out_rec.id        := l_diagnosis_rec.id_diagnosis;
                out_rec.id_parent := l_diagnosis_rec.id_alert_diagnosis;
                out_rec.id_req    := l_diagnosis_rec.id_epis_diagnosis;
                out_rec.title     := l_diagnosis_rec.desc_diagnosis;
                out_rec.text      := l_diagnosis_rec.notes;
            
                g_error           := 'DT_INSERT';
                out_rec.dt_insert := pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                           pk_date_utils.get_string_tstz(i_lang,
                                                                                                         i_prof,
                                                                                                         l_diagnosis_rec.date_diag,
                                                                                                         NULL),
                                                                           i_prof) || ')';
            
                out_rec.prof_name      := NULL;
                out_rec.flg_type       := g_diagnosis;
                out_rec.flg_status     := l_diagnosis_rec.status_diagnosis;
                out_rec.id_institution := NULL;
                out_rec.flg_priority   := NULL;
                out_rec.flg_home       := NULL;
            
                PIPE ROW(out_rec);
                out_rec.text := NULL;
            END IF;
        END LOOP;
    
        RETURN;
    EXCEPTION
        WHEN rowtype_mismatch THEN
            pk_alertlog.log_error('GET_PAT_DIAGNOSIS. - Alterar type diagnosis_rec. ' || g_error || ' / ' || SQLERRM);
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
    END get_pat_diagnosis;

    /**
    * Gets all analysis with results of a patient
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software    
    * @param   i_patient patient id    
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-05-2008
    */

    FUNCTION get_pat_analysis_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN analysis_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED IS
    
        out_rec t_rec_p1_export_data := t_rec_p1_export_data(NULL,
                                                             NULL,
                                                             NULL,
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
    
        l_analysis_val pk_types.cursor_type;
        l_mcdt_req_rec mcdt_req_rec;
        l_soft_inp_ubu software.id_software%TYPE;
    BEGIN
    
        IF pk_sysconfig.get_config('REFERRAL_REQ_MODE_A', i_prof) = g_create
        THEN
            RETURN;
        ELSE
            IF i_prof.software = to_number(pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof))
               OR i_prof.software = to_number(pk_sysconfig.get_config('SOFTWARE_ID_UBU', i_prof))
            THEN
                l_soft_inp_ubu := i_prof.software;
            END IF;
        
            g_error := 'OPEN L_ANALYSIS_VAL';
            OPEN l_analysis_val FOR
                SELECT ard.id_analysis id,
                       ard.id_analysis_req_det id_req_det,
                       pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL) text,
                       pk_date_utils.date_send_tsz(i_lang, ar.dt_req_tstz, i_prof) dt_insert,
                       NULL prof_name,
                       g_analysis flg_type,
                       ar.flg_status,
                       i_prof.institution id_institution,
                       NULL flg_priority,
                       NULL flg_home
                  FROM analysis_req_det ard
                  JOIN analysis_req ar
                    ON (ard.id_analysis_req = ar.id_analysis_req)
                  JOIN exam_cat ec
                    ON (ard.id_exam_cat = ec.id_exam_cat)
                  JOIN analysis a
                    ON (a.id_analysis = ard.id_analysis)
                 WHERE ar.id_episode = i_epis
                   AND ard.flg_status IN
                       (pk_lab_tests_constant.g_analysis_req, pk_lab_tests_constant.g_analysis_pending) -- Requisitado e pendente
                   AND ((ard.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e AND i_prof.software = l_soft_inp_ubu) OR
                       ard.flg_time_harvest IN (pk_lab_tests_constant.g_flg_time_b,
                                                 pk_lab_tests_constant.g_flg_time_d,
                                                 pk_lab_tests_constant.g_flg_time_n)) -- Neste episodio para ubu e inp e proximo e entre espisodioa para os restantes 
                   AND (ard.flg_referral IS NULL OR ard.flg_referral = pk_ref_constant.g_flg_referral_a)
                 ORDER BY dt_insert, text;
        
            LOOP
                g_error := 'FETCH INTO l_mcdt_req_rec';
                FETCH l_analysis_val
                    INTO l_mcdt_req_rec;
                EXIT WHEN l_analysis_val%NOTFOUND;
            
                out_rec.id             := l_mcdt_req_rec.id;
                out_rec.id_parent      := NULL;
                out_rec.id_req         := l_mcdt_req_rec.id_req_det;
                out_rec.title          := l_mcdt_req_rec.text;
                out_rec.text           := NULL;
                out_rec.dt_insert      := l_mcdt_req_rec.dt_insert;
                out_rec.prof_name      := l_mcdt_req_rec.prof_name;
                out_rec.flg_type       := l_mcdt_req_rec.flg_type;
                out_rec.flg_status     := l_mcdt_req_rec.flg_status;
                out_rec.id_institution := NULL;
                out_rec.flg_priority   := NULL;
                out_rec.flg_home       := NULL;
            
                PIPE ROW(out_rec);
                out_rec.text := NULL;
            END LOOP;
            RETURN;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || '/' || SQLERRM);
    END get_pat_analysis_req;

    /**
    * Gets all exams with results of a patient
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software    
    * @param   i_patient patient id 
    * @param   i_exam_type   {*} 'I' {*} 'E'
    *   
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   26-05-2008
    */
    /*
    FUNCTION get_pat_exam_req
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN exam_req.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        i_exam_type IN exam.flg_type%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED IS
    
        out_rec t_rec_p1_export_data := t_rec_p1_export_data(NULL,
                                                             NULL,
                                                             NULL,
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
    
        l_exam_val     pk_types.cursor_type;
        l_mcdt_req_rec mcdt_req_rec;
        l_soft_inp_ubu software.id_software%TYPE;
    BEGIN
    
        IF pk_sysconfig.get_config('REFERRAL_REQ_MODE_' || i_exam_type, i_prof) = g_create
        THEN
            RETURN;
        ELSE
        
            IF i_prof.software = to_number(pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof))
               OR i_prof.software = to_number(pk_sysconfig.get_config('SOFTWARE_ID_UBU', i_prof))
            THEN
                l_soft_inp_ubu := i_prof.software;
            END IF;
        
            g_error := 'OPEN L_EXAM_VAL';
            OPEN l_exam_val FOR
                SELECT eea.id_exam id,
                       eea.id_exam_req_det id_req_det,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam) text,
                       pk_date_utils.date_send_tsz(i_lang, eea.dt_req, i_prof) dt_insert,
                       NULL prof_name,
                       eea.flg_type,
                       eea.flg_status_det,
                       NULL id_institution,
                       NULL flg_priority,
                       NULL flg_home
                  FROM exams_ea eea
                  JOIN exam_cat ec
                    ON (eea.id_exam_cat = ec.id_exam_cat)
                 WHERE eea.flg_status_det IN (pk_exam_constant.g_exam_req, pk_exam_constant.g_exam_pending) -- Requisitado e pendente
                   AND eea.flg_type = i_exam_type
                   AND ((eea.flg_time = pk_exam_constant.g_flg_time_e AND i_prof.software = l_soft_inp_ubu) OR
                       eea.flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_n)) -- Neste episodio para ubu e inp e proximo e entre espisodioa para os restantes 
                   AND eea.id_episode = i_epis
                   AND (eea.flg_referral IS NULL OR eea.flg_referral = pk_ref_constant.g_flg_referral_a)
                 ORDER BY dt_insert, text;
        
            LOOP
                g_error := 'FETCH INTO l_mcdt_req_rec';
                FETCH l_exam_val
                    INTO l_mcdt_req_rec;
                EXIT WHEN l_exam_val%NOTFOUND;
            
                out_rec.id             := l_mcdt_req_rec.id;
                out_rec.id_parent      := NULL;
                out_rec.id_req         := l_mcdt_req_rec.id_req_det;
                out_rec.title          := l_mcdt_req_rec.text;
                out_rec.text           := NULL;
                out_rec.dt_insert      := l_mcdt_req_rec.dt_insert;
                out_rec.prof_name      := l_mcdt_req_rec.prof_name;
                out_rec.flg_type       := l_mcdt_req_rec.flg_type;
                out_rec.flg_status     := l_mcdt_req_rec.flg_status;
                out_rec.id_institution := NULL;
                out_rec.flg_priority   := NULL;
                out_rec.flg_home       := NULL;
                PIPE ROW(out_rec);
                out_rec.text := NULL;
            END LOOP;
            RETURN;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || '/' || SQLERRM);
    END get_pat_exam_req;
    */

    /**
    * Interventions requests for a given episode
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software    
    * @param   i_patient patient id 
    * @param   i_epis episode id
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-05-2008
    */

    /*    FUNCTION get_pat_interv_req
        (
            i_lang    IN language.id_language%TYPE,
            i_prof    IN profissional,
            i_epis    IN exam_req.id_episode%TYPE,
            i_patient IN patient.id_patient%TYPE
            
        ) RETURN t_coll_p1_export_data
            PIPELINED IS
        
            out_rec t_rec_p1_export_data := t_rec_p1_export_data(NULL,
                                                                 NULL,
                                                                 NULL,
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
        
            l_interv_val   pk_types.cursor_type;
            l_mcdt_req_rec mcdt_req_rec;
            l_soft_inp_ubu software.id_software%TYPE;
        BEGIN
        
            IF pk_sysconfig.get_config('REFERRAL_REQ_MODE_P', i_prof) = g_create
            THEN
                RETURN;
            ELSE
            
                IF i_prof.software = to_number(pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof))
                   OR i_prof.software = to_number(pk_sysconfig.get_config('SOFTWARE_ID_UBU', i_prof))
                THEN
                    l_soft_inp_ubu := i_prof.software;
                END IF;
            
                g_error := 'OPEN L_INTERV_VAL';
                OPEN l_interv_val FOR
                    SELECT pea.id_intervention id,
                           pea.id_interv_presc_det id_req_det,
                           pk_procedures_api_db.get_alias_translation(i_lang,
                                                           i_prof,
                                                           'INTERVENTION.CODE_INTERVENTION.' || pea.id_intervention,
                                                           null) text,
                           pk_date_utils.date_send_tsz(i_lang, pea.dt_interv_prescription, i_prof) dt_insert,
                           NULL prof_name,
                           pk_ref_constant.g_p1_type_p flg_type,
                           pea.flg_status_det,
                           NULL id_institution,
                           NULL flg_priority,
                           NULL flg_home
                      FROM procedures_ea pea
                     WHERE pea.id_episode = i_epis
                       AND ((pea.flg_time = pk_interv.g_flg_time_epis AND i_prof.software = l_soft_inp_ubu) OR
                           pea.flg_time IN (pk_interv.g_flg_time_betw, pk_interv.g_flg_time_next)) -- Neste episodio para ubu e inp e proximo e entre espisodioa para os restantes 
                       AND pea.flg_status_req IN (pk_interv.g_interv_req, pk_interv.g_interv_pend) -- Requisitado e pendente
                       AND (pea.flg_referral IS NULL OR pea.flg_referral = pk_ref_constant.g_flg_referral_a)
                       AND (pea.flg_mfr IS NULL OR pea.flg_mfr = pk_ref_constant.g_no) -- JB 2008-06-17
                     ORDER BY dt_insert, text;
            
                LOOP
                    g_error := 'FETCH INTO l_mcdt_req_rec';
                    FETCH l_interv_val
                        INTO l_mcdt_req_rec;
                    EXIT WHEN l_interv_val%NOTFOUND;
                    out_rec.id             := l_mcdt_req_rec.id;
                    out_rec.id_parent      := NULL;
                    out_rec.id_req         := l_mcdt_req_rec.id_req_det;
                    out_rec.title          := l_mcdt_req_rec.text;
                    out_rec.text           := NULL;
                    out_rec.dt_insert      := l_mcdt_req_rec.dt_insert;
                    out_rec.prof_name      := l_mcdt_req_rec.prof_name;
                    out_rec.flg_type       := l_mcdt_req_rec.flg_type;
                    out_rec.flg_status     := l_mcdt_req_rec.flg_status;
                    out_rec.id_institution := NULL;
                    out_rec.flg_priority   := NULL;
                    out_rec.flg_home       := NULL;
                    PIPE ROW(out_rec);
                    out_rec.text := NULL;
                END LOOP;
                RETURN;
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                pk_alertlog.log_error(g_error || '/' || SQLERRM);
        END get_pat_interv_req;
    */

    /**
    * PMR Interventions requests for a given episode
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software    
    * @param   i_patient patient id 
    * @param   i_epis episode id
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-05-2008
    */
    /*
    FUNCTION get_pat_interv_mfr_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
        
    ) RETURN t_coll_p1_export_data
        PIPELINED IS
    
        out_rec t_rec_p1_export_data := t_rec_p1_export_data(NULL,
                                                             NULL,
                                                             NULL,
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
    
        l_interv_val   pk_types.cursor_type;
        l_mcdt_req_rec mcdt_req_rec;
        l_soft_inp_ubu software.id_software%TYPE;
    BEGIN
    
        IF pk_sysconfig.get_config('REFERRAL_REQ_MODE_P', i_prof) = g_create
        THEN
            RETURN;
        ELSE
            IF i_prof.software = to_number(pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof))
               OR i_prof.software = to_number(pk_sysconfig.get_config('SOFTWARE_ID_UBU', i_prof))
            THEN
                l_soft_inp_ubu := i_prof.software;
            END IF;
        
            -- todo: adaptar ao PK_REHAB...
            g_error := 'OPEN L_INTERV_VAL';
            OPEN l_interv_val FOR
            
                SELECT i.id_intervention id,
                       ipd.id_interv_presc_det id_req_det,
                       pk_procedures_api_db.get_alias_translation(i_lang,
                                                       i_prof,
                                                       i.code_intervention,
                                                       null) text,
                       pk_date_utils.date_send_tsz(i_lang, ip.dt_interv_prescription_tstz, i_prof) dt_insert,
                       NULL prof_name,
                       pk_ref_constant.g_p1_type_f flg_type,
                       ipd.flg_status,
                       NULL id_institution,
                       NULL flg_priority,
                       NULL flg_home
                  FROM intervention i
                  JOIN interv_presc_det ipd
                    ON (i.id_intervention = ipd.id_intervention)
                  JOIN interv_prescription ip
                    ON (ipd.id_interv_prescription = ip.id_interv_prescription)
                 WHERE ip.id_episode = i_epis
                   AND ipd.flg_mfr = pk_ref_constant.g_yes -- tipo mfr
                   AND ((ip.flg_time = pk_interv.g_flg_time_epis AND i_prof.software = l_soft_inp_ubu) OR
                       ip.flg_time IN (pk_interv.g_flg_time_betw, pk_interv.g_flg_time_next)) -- Neste episodio para ubu e inp e proximo e entre espisodioa para os restantes 
                   AND ip.flg_status IN (pk_interv.g_interv_req, pk_interv.g_interv_pend) -- Requisitado e pendente
                   AND (ipd.flg_referral IS NULL OR ipd.flg_referral = pk_ref_constant.g_flg_referral_a)
                 ORDER BY dt_insert, text;
        
            LOOP
                g_error := 'FETCH INTO l_mcdt_req_rec';
                FETCH l_interv_val
                    INTO l_mcdt_req_rec;
                EXIT WHEN l_interv_val%NOTFOUND;
                out_rec.id             := l_mcdt_req_rec.id;
                out_rec.id_parent      := NULL;
                out_rec.id_req         := l_mcdt_req_rec.id_req_det;
                out_rec.title          := l_mcdt_req_rec.text;
                out_rec.text           := NULL;
                out_rec.dt_insert      := l_mcdt_req_rec.dt_insert;
                out_rec.prof_name      := l_mcdt_req_rec.prof_name;
                out_rec.flg_type       := l_mcdt_req_rec.flg_type;
                out_rec.flg_status     := l_mcdt_req_rec.flg_status;
                out_rec.id_institution := NULL;
                out_rec.flg_priority   := NULL;
                out_rec.flg_home       := NULL;
                PIPE ROW(out_rec);
                out_rec.text := NULL;
            END LOOP;
            RETURN;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || '/' || SQLERRM);
    END get_pat_interv_mfr_req;
    */

    /**
    * Gets vitals signs of a patient
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software    
    * @param   i_epis episode id
    * @param   i_patient patient id 
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   26-05-2008
    */
    FUNCTION get_pat_vital_sign
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED IS
        l_out_rec                t_rec_p1_export_data;
        l_vital_sign             pk_types.cursor_type;
        l_vital_sign_rec         pk_vital_sign_core.t_rec_vs_info;
        l_error                  t_error_out;
        l_ref_vitalsigns_enabled sys_config.value%TYPE;
    BEGIN
        -- import information only if field "Vital signs" is available
        l_ref_vitalsigns_enabled := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_vitalsigns_enabled, i_prof),
                                        pk_ref_constant.g_no);
    
        g_error := 'l_ref_vitalsigns_enabled=' || l_ref_vitalsigns_enabled;
        IF l_ref_vitalsigns_enabled = pk_ref_constant.g_yes
        THEN
            g_error := 'CALL pk_vital_sign.get_epis_vital_sign';
            IF pk_vital_sign.get_epis_vital_sign(i_lang, i_epis, i_prof, 'V2', l_vital_sign, l_error)
            THEN
                LOOP
                    g_error := 'FETCH INTO l_vital_sign_rec';
                    FETCH l_vital_sign
                        INTO l_vital_sign_rec;
                    EXIT WHEN l_vital_sign%NOTFOUND;
                
                    IF l_vital_sign_rec.value IS NOT NULL
                    THEN
                        l_out_rec                := t_rec_p1_export_data();
                        l_out_rec.id             := l_vital_sign_rec.id_vital_sign;
                        l_out_rec.id_parent      := NULL;
                        l_out_rec.id_req         := l_vital_sign_rec.id_vital_sign;
                        l_out_rec.title          := l_vital_sign_rec.name_vs || ': ' || l_vital_sign_rec.value || ' ' ||
                                                    l_vital_sign_rec.desc_unit_measure || ' ' ||
                                                    l_vital_sign_rec.pain_descr;
                        l_out_rec.text           := l_vital_sign_rec.name_vs || ': ' || l_vital_sign_rec.value || ' ' ||
                                                    l_vital_sign_rec.desc_unit_measure || ' ' ||
                                                    l_vital_sign_rec.pain_descr;
                        l_out_rec.dt_insert      := l_vital_sign_rec.short_dt_read;
                        l_out_rec.prof_name      := l_vital_sign_rec.prof_read;
                        l_out_rec.flg_type       := NULL;
                        l_out_rec.flg_status     := NULL;
                        l_out_rec.id_institution := NULL;
                        l_out_rec.flg_priority   := NULL;
                        l_out_rec.flg_home       := NULL;
                        PIPE ROW(l_out_rec);
                    END IF;
                END LOOP;
            END IF;
        END IF;
        RETURN;
    
    EXCEPTION
        WHEN rowtype_mismatch THEN
            pk_alertlog.log_error('GET_PAT_VITAL_SIGN. - Alterar type vital_sign_rec. ' || g_error || '/' || SQLERRM);
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || '/' || SQLERRM);
    END get_pat_vital_sign;

    /**
    * Get data for the past history for the doc_area provided
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_episode episode id    
    * @param   i_patient patient id    
    * @param   i_doc_area doc area id
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joao Sa
    * @version 1.0
    * @since   14-05-2008
    */
    FUNCTION get_past_hist_all
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(50 CHAR) := 'get_past_hist_all';
        l_error   t_error_out;
        l_out_rec t_rec_p1_export_data;
        l_ending  VARCHAR2(1 CHAR);
    
        -- cursors returned by pk_past_history_api.get_past_hist_all
        l_doc_area_register      pk_types.cursor_type;
        l_doc_area_val           pk_types.cursor_type;
        l_doc_area_register_tmpl pk_types.cursor_type;
        l_doc_area_val_tmpl      pk_types.cursor_type;
        l_doc_area               doc_area.id_doc_area%TYPE;
        l_doc_area_name          pk_translation.t_desc_translation;
        l_dummy                  pk_types.cursor_type;
        l_dummy2                 pk_types.cursor_type;
    
        -- 45 Past Medical History (relevant diseases included)
        TYPE doc_area_register_table IS TABLE OF pk_summary_page.doc_area_register_rec INDEX BY BINARY_INTEGER;
        l_dar_past_med_tab doc_area_register_table;
        l_dav_past_med_tab pk_summary_page.t_coll_val_past_med;
    
        -- 46 Past Surgical History, 52 Congenital Anomalies --> Bith History (Pre-Natal, Natal and Congenital Anomalies)
        TYPE s_doc_area_register_table IS TABLE OF pk_summary_page.s_doc_area_register_rec INDEX BY BINARY_INTEGER;
        l_dar_past_surg_tab s_doc_area_register_table;
        l_dav_past_surg_tab pk_summary_page.t_coll_past_surg;
    
        -- 49 Relevant Notes
        TYPE doc_area_reg_rel_notes_table IS TABLE OF pk_summary_page.doc_area_register_rec INDEX BY BINARY_INTEGER;
        l_dar_rel_notes_tab doc_area_reg_rel_notes_table;
        l_dav_rel_notes_tab pk_summary_page.t_coll_past_surg;
    
        --47 Past family history
        l_dav_past_fam_tab pk_summary_page.t_coll_past_fam;
    
        -- 1049 - Obstetric history
        l_dar_obs_hist_tab pk_pregnancy.t_coll_doc_area_pregnancy_ph;
        TYPE s_doc_area_obs_hist_table IS TABLE OF pk_pregnancy.p_doc_area_val_doc_rec_ph INDEX BY BINARY_INTEGER;
        l_dav_obs_hist_tab s_doc_area_obs_hist_table;
    
        -- Documentation
        -- free text
        TYPE doc_area_reg_doc_table IS TABLE OF pk_summary_page.doc_area_register_rec INDEX BY BINARY_INTEGER;
        l_dar_doc_tab doc_area_reg_doc_table;
        l_dav_doc_tab pk_summary_page.t_coll_past_surg;
        -- templates
        l_dar_templ_tab pk_touch_option.t_coll_doc_area_register;
        --l_dav_templ_tab pk_touch_option.t_coll_doc_area_val;
    
        l_cur_templ pk_touch_option_out.t_cur_plain_text_entry;
        l_tbl_templ pk_touch_option_out.t_coll_plain_text_entry;
        l_id_epis   table_number := table_number();
    
        TYPE t_tab_templ_scores IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY BINARY_INTEGER; --id_epis_documentation
        l_templ_scores t_tab_templ_scores;
    
        -- getting score descriptions
        FUNCTION get_template_scores(i_id_documentation IN table_number) RETURN t_tab_templ_scores IS
            l_tab_templ_scores t_tab_templ_scores;
        BEGIN
            g_error := 'GET template scores';
            FOR rec IN (SELECT t.id_epis_documentation, t.desc_class
                          FROM TABLE(pk_scales_core.tf_scales_list(i_lang, i_prof, i_patient, i_id_documentation)) t
                        UNION
                        SELECT t.id_epis_documentation, t.desc_class
                          FROM TABLE(pk_risk_factor.tf_risk_total_score(i_lang, i_prof, i_id_documentation)) t
                        UNION
                        SELECT t.id_epis_documentation, t.desc_class
                          FROM TABLE(pk_hcn.tf_hcn_score(i_lang, i_prof, i_id_documentation)) t)
            LOOP
                l_tab_templ_scores(rec.id_epis_documentation) := rec.desc_class;
            END LOOP;
        
            RETURN l_tab_templ_scores;
        END get_template_scores;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_patient=' || i_patient ||
                    ' i_doc_area=' || i_doc_area;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        IF i_doc_area = pk_ref_constant.g_doc_area_phy_exam
        THEN
            g_error  := 'Call pk_past_history.get_past_hist_all / ' || l_params;
            g_retval := pk_past_history.get_past_hist_all(i_lang                   => i_lang,
                                                          i_prof                   => i_prof,
                                                          i_current_episode        => i_episode,
                                                          i_scope                  => i_episode,
                                                          i_scope_type             => pk_alert_constant.g_scope_type_episode,
                                                          i_doc_area               => i_doc_area,
                                                          o_doc_area_register      => l_doc_area_register,
                                                          o_doc_area_val           => l_doc_area_val,
                                                          o_doc_area               => l_doc_area,
                                                          o_doc_area_register_tmpl => l_doc_area_register_tmpl,
                                                          o_doc_area_val_tmpl      => l_doc_area_val_tmpl,
                                                          o_template_layouts       => l_dummy,
                                                          o_doc_area_component     => l_dummy2,
                                                          o_error                  => l_error);
        
        ELSE
            g_error  := 'Call pk_past_history_api.get_past_hist_all / ' || l_params;
            g_retval := pk_past_history_api.get_past_hist_all(i_lang                   => i_lang,
                                                              i_prof                   => i_prof,
                                                              i_id_episode             => i_episode,
                                                              i_id_patient             => i_patient,
                                                              i_doc_area               => i_doc_area,
                                                              o_doc_area_register      => l_doc_area_register,
                                                              o_doc_area_val           => l_doc_area_val,
                                                              o_doc_area               => l_doc_area,
                                                              o_doc_area_register_tmpl => l_doc_area_register_tmpl,
                                                              o_doc_area_val_tmpl      => l_doc_area_val_tmpl,
                                                              o_template_layouts       => l_dummy,
                                                              o_doc_area_component     => l_dummy2,
                                                              o_error                  => l_error);
        END IF;
    
        CLOSE l_dummy;
        CLOSE l_dummy2;
    
        g_error         := 'Call pk_summary_page.get_doc_area_name / ' || l_params;
        l_doc_area_name := pk_summary_page.get_doc_area_name(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_doc_area => i_doc_area);
    
        CASE
            WHEN i_doc_area = pk_ref_constant.g_doc_area_past_med THEN
            
                -- 45 Past Medical History (relevant diseases included)
                ------------ free text ----------------------
                g_error := 'FETCH l_doc_area_register BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_register BULK COLLECT
                    INTO l_dar_past_med_tab;
            
                g_error := 'FETCH l_doc_area_val BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_val BULK COLLECT
                    INTO l_dav_past_med_tab;
            
                g_error  := 'l_ending / ' || l_params;
                l_ending := NULL;
            
                g_error := '<<doc_ar_past_med>> / ' || l_params;
                <<doc_ar_past_med>>
                FOR i IN 1 .. l_dar_past_med_tab.count
                LOOP
                
                    IF l_dar_past_med_tab(i).flg_status = pk_ref_constant.g_active
                    THEN
                    
                        g_error             := 't_rec_p1_export_data() / ' || l_params;
                        l_out_rec           := t_rec_p1_export_data();
                        l_out_rec.id_req    := l_dar_past_med_tab(i).id_episode;
                        l_out_rec.dt_insert := l_dar_past_med_tab(i).dt_register;
                        l_out_rec.prof_name := l_dar_past_med_tab(i).nick_name;
                        l_out_rec.prof_spec := l_dar_past_med_tab(i).desc_speciality;
                        l_out_rec.title     := l_doc_area_name;
                    
                        g_error := '<<doc_av_past_med>> / ' || l_params;
                        <<doc_av_past_med>>
                        FOR j IN 1 .. l_dav_past_med_tab.count
                        LOOP
                        
                            IF l_dav_past_med_tab(j)
                             .dt_register = l_dar_past_med_tab(i).dt_register
                                AND l_dav_past_med_tab(j).nick_name = l_dar_past_med_tab(i).nick_name
                                AND (l_dav_past_med_tab(j).flg_status IN (pk_ref_constant.g_active, g_passive, g_solv) -- JB 2008-06-13
                                     OR l_dav_past_med_tab(j).flg_status IS NULL) --FREE TEXT STATUS IS NULL
                            THEN
                                l_ending := '.';
                            
                                g_error        := 'l_out_rec.text / ' || l_params;
                                l_out_rec.text := l_out_rec.text || chr(10) || l_dav_past_med_tab(j).desc_past_hist_all;
                            END IF;
                        END LOOP doc_av_past_med;
                    
                        g_error        := 'l_out_rec.text 2 / ' || l_params;
                        l_out_rec.text := ltrim(l_out_rec.text, chr(10));
                    
                        IF l_out_rec.text IS NOT NULL
                           AND NOT (substr(l_out_rec.text, length(l_out_rec.text), length(l_ending)) = l_ending)
                        THEN
                            l_out_rec.text := l_out_rec.text || l_ending;
                        END IF;
                    
                        -- JB 2008-06-18 remove html tag
                        g_error := 'owa_pattern.change / ' || l_params;
                        owa_pattern.change(l_out_rec.text, '<b>', '', 'g');
                        owa_pattern.change(l_out_rec.text, '</b>', '', 'g');
                    
                        g_error := 'PIPE ROW / ' || l_params;
                        PIPE ROW(l_out_rec);
                    END IF;
                
                    l_ending := NULL;
                
                END LOOP doc_ar_past_med;
            
            WHEN i_doc_area IN (pk_ref_constant.g_doc_area_past_surg, pk_ref_constant.g_doc_area_cong_anom) THEN
                -- 46 Past Surgical History
                -- 52 Congenital Anomalies --> Bith History (Pre-Natal, Natal and Congenital Anomalies)
            
                ------------ free text ----------------------                
                g_error := 'FETCH l_doc_area_register BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_register BULK COLLECT
                    INTO l_dar_past_surg_tab;
            
                g_error := 'FETCH l_doc_area_val BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_val BULK COLLECT
                    INTO l_dav_past_surg_tab;
            
                g_error  := 'l_ending';
                l_ending := NULL;
            
                g_error := '<<doc_ar_surg>> / ' || l_params;
                <<doc_ar_surg>>
                FOR i IN 1 .. l_dar_past_surg_tab.count
                LOOP
                
                    IF l_dar_past_surg_tab(i).flg_status = pk_ref_constant.g_active
                    THEN
                    
                        g_error             := 't_rec_p1_export_data() / ' || l_params;
                        l_out_rec           := t_rec_p1_export_data();
                        l_out_rec.id_req    := l_dar_past_surg_tab(i).id_episode;
                        l_out_rec.dt_insert := l_dar_past_surg_tab(i).dt_register;
                        l_out_rec.prof_name := l_dar_past_surg_tab(i).nick_name;
                        l_out_rec.prof_spec := l_dar_past_surg_tab(i).desc_speciality;
                        l_out_rec.title     := l_doc_area_name;
                    
                        g_error := '<<doc_av_surg>> / ' || l_params;
                        <<doc_av_surg>>
                        FOR j IN 1 .. l_dav_past_surg_tab.count
                        LOOP
                        
                            IF l_dav_past_surg_tab(j).dt_register = l_dar_past_surg_tab(i).dt_register
                                AND l_dav_past_surg_tab(j).nick_name = l_dar_past_surg_tab(i).nick_name
                            THEN
                                l_ending := '.';
                            
                                g_error        := 'l_out_rec.text / ' || l_params;
                                l_out_rec.text := l_out_rec.text || chr(10) || l_dav_past_surg_tab(j).desc_past_hist_all;
                            END IF;
                        END LOOP doc_av_surg;
                    
                        g_error        := 'l_out_rec.text 2 / ' || l_params;
                        l_out_rec.text := ltrim(l_out_rec.text, chr(10));
                    
                        IF l_out_rec.text IS NOT NULL
                           AND NOT (substr(l_out_rec.text, length(l_out_rec.text), length(l_ending)) = l_ending)
                        THEN
                            l_out_rec.text := l_out_rec.text || l_ending;
                        END IF;
                    
                        -- JB 2008-06-18 remove html tag
                        g_error := 'owa_pattern.change / ' || l_params;
                        owa_pattern.change(l_out_rec.text, '<b>', '', 'g');
                        owa_pattern.change(l_out_rec.text, '</b>', '', 'g');
                    
                        g_error := 'PIPE ROW / ' || l_params;
                        PIPE ROW(l_out_rec);
                    END IF;
                
                    l_ending := NULL;
                
                END LOOP doc_ar_surg;
            
            WHEN i_doc_area = pk_ref_constant.g_doc_area_relev_notes THEN
            
                -- 49 Relevant Notes
                ------------ free text ----------------------
                g_error := 'FETCH l_doc_area_register BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_register BULK COLLECT
                    INTO l_dar_rel_notes_tab;
            
                g_error := 'FETCH l_doc_area_val BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_val BULK COLLECT
                    INTO l_dav_rel_notes_tab;
            
                g_error  := 'l_ending / ' || l_params;
                l_ending := NULL;
            
                g_error := '<<doc_ar_rel_notes>> / ' || l_params;
                <<doc_ar_rel_notes>>
                FOR i IN 1 .. l_dar_rel_notes_tab.count
                LOOP
                
                    IF l_dar_rel_notes_tab(i).id_episode IS NOT NULL
                        AND l_dar_rel_notes_tab(i).flg_status = pk_ref_constant.g_active
                    THEN
                        g_error             := 't_rec_p1_export_data() / ' || l_params;
                        l_out_rec           := t_rec_p1_export_data();
                        l_out_rec.id_req    := l_dar_rel_notes_tab(i).id_episode;
                        l_out_rec.dt_insert := l_dar_rel_notes_tab(i).dt_register;
                        l_out_rec.prof_name := l_dar_rel_notes_tab(i).nick_name;
                        l_out_rec.prof_spec := l_dar_rel_notes_tab(i).desc_speciality;
                        l_out_rec.title     := l_doc_area_name;
                    
                        g_error := '<<doc_av_rel_notes>> / ' || l_params;
                        <<doc_av_rel_notes>>
                        FOR j IN 1 .. l_dav_rel_notes_tab.count
                        LOOP
                            IF l_dav_rel_notes_tab(j).dt_register = l_dar_rel_notes_tab(i).dt_register
                                AND l_dav_rel_notes_tab(j).nick_name = l_dar_rel_notes_tab(i).nick_name
                            THEN
                                l_ending := '.';
                            
                                g_error        := 'l_out_rec.text / ' || l_params;
                                l_out_rec.text := l_out_rec.text || chr(10) || l_dav_rel_notes_tab(j).desc_past_hist_all;
                            END IF;
                        END LOOP doc_av_rel_notes;
                    
                        g_error        := 'l_out_rec.text 2 / ' || l_params;
                        l_out_rec.text := ltrim(l_out_rec.text, chr(10));
                    
                        IF l_out_rec.text IS NOT NULL
                           AND NOT (substr(l_out_rec.text, length(l_out_rec.text), length(l_ending)) = l_ending)
                        THEN
                            l_out_rec.text := l_out_rec.text || l_ending;
                        END IF;
                    
                        g_error := 'owa_pattern.change / ' || l_params;
                        owa_pattern.change(l_out_rec.text, '<b>', '', 'g');
                        owa_pattern.change(l_out_rec.text, '</b>', '', 'g');
                    
                        g_error := 'PIPE ROW / ' || l_params;
                        PIPE ROW(l_out_rec);
                    END IF;
                
                END LOOP doc_ar_rel_notes;
            
            WHEN i_doc_area = pk_ref_constant.g_doc_area_obs_hist THEN
            
                -- 1049 - Obstetric history
                ------------ free text ----------------------
                g_error := 'FETCH l_doc_area_register BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_register BULK COLLECT
                    INTO l_dar_obs_hist_tab;
            
                g_error := 'FETCH l_doc_area_val BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_val BULK COLLECT
                    INTO l_dav_obs_hist_tab;
            
                g_error := '<<doc_ar_obs_hist>> / ' || l_params;
                <<doc_ar_obs_hist>>
                FOR i IN 1 .. l_dar_obs_hist_tab.count
                LOOP
                
                    IF l_dar_obs_hist_tab(i).flg_status = pk_ref_constant.g_active
                    THEN
                    
                        g_error             := 't_rec_p1_export_data() / ' || l_params;
                        l_out_rec           := t_rec_p1_export_data();
                        l_out_rec.id_req    := l_dar_obs_hist_tab(i).id_doc_template;
                        l_out_rec.dt_insert := l_dar_obs_hist_tab(i).dt_register;
                        l_out_rec.prof_name := l_dar_obs_hist_tab(i).nick_name;
                        l_out_rec.prof_spec := l_dar_obs_hist_tab(i).desc_speciality;
                        l_out_rec.title     := l_doc_area_name;
                    
                        g_error := 'Set notes(' || i_doc_area || ')';
                        IF l_dar_obs_hist_tab(i).notes IS NOT NULL
                        THEN
                            l_out_rec.text := l_out_rec.text || chr(10) || l_dar_obs_hist_tab(i).notes;
                        END IF;
                    
                        l_out_rec.text := ltrim(l_out_rec.text, chr(10));
                    
                        IF l_out_rec.text IS NOT NULL
                           AND NOT (substr(l_out_rec.text, length(l_out_rec.text), 1) = '.')
                        THEN
                            NULL;
                        END IF;
                    
                        g_error := 'owa_pattern.change / ' || l_params;
                        owa_pattern.change(l_out_rec.text, '<b>', '', 'g');
                        owa_pattern.change(l_out_rec.text, '</b>', '', 'g');
                    
                        g_error := 'PIPE ROW / ' || l_params;
                        PIPE ROW(l_out_rec);
                    END IF;
                
                END LOOP doc_ar_obs_hist;
            
            WHEN i_doc_area = pk_ref_constant.g_doc_area_past_fam THEN
                ------------ free text ----------------------
                g_error := 'FETCH l_doc_area_register BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_register BULK COLLECT
                    INTO l_dar_doc_tab;
            
                g_error := 'FETCH l_doc_area_val BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_val BULK COLLECT
                    INTO l_dav_past_fam_tab;
            
                g_error := '<<doc_ar_doc>> / ' || l_params;
                <<doc_ar_doc>>
                FOR i IN 1 .. l_dar_doc_tab.count
                LOOP
                    IF l_dar_doc_tab(i).flg_status = pk_ref_constant.g_active
                    THEN
                        g_error             := 't_rec_p1_export_data() / ' || l_params;
                        l_out_rec           := t_rec_p1_export_data();
                        l_out_rec.id_req    := l_dar_doc_tab(i).id_pat_history_diagnosis;
                        l_out_rec.dt_insert := l_dar_doc_tab(i).dt_register;
                        l_out_rec.prof_name := l_dar_doc_tab(i).nick_name;
                        l_out_rec.prof_spec := l_dar_doc_tab(i).desc_speciality;
                        l_out_rec.title     := l_doc_area_name;
                    
                        g_error := '<<l_dav_past_fam_tab>> / ' || l_params;
                        <<doc_av_doc>>
                        IF nvl(l_dar_doc_tab(i).flg_status, pk_ref_constant.g_active) = pk_ref_constant.g_active
                        THEN
                            FOR j IN 1 .. l_dav_past_fam_tab.count
                            LOOP
                                --CDOC API executes a DISTINCT, therefore it is necessary to match the records
                                --by the dt_register
                                IF l_dar_doc_tab(i).dt_register = l_dav_past_fam_tab(j).dt_register
                                THEN
                                    l_ending       := '.';
                                    g_error        := 'l_out_rec.text / ' || l_params;
                                    l_out_rec.text := l_out_rec.text || chr(10) || l_dav_past_fam_tab(j).desc_past_hist_all;
                                END IF;
                            END LOOP doc_av_doc;
                        END IF;
                    
                        g_error        := 'l_out_rec.text 2 / ' || l_params;
                        l_out_rec.text := ltrim(l_out_rec.text, chr(10));
                    
                        IF l_out_rec.text IS NOT NULL
                           AND NOT (substr(l_out_rec.text, length(l_out_rec.text), length(l_ending)) = l_ending)
                        THEN
                            l_out_rec.text := l_out_rec.text || l_ending;
                        END IF;
                    
                        g_error := 'owa_pattern.change / ' || l_params;
                        owa_pattern.change(l_out_rec.text, '<b>', '', 'g');
                        owa_pattern.change(l_out_rec.text, '</b>', '', 'g');
                    
                        g_error := 'PIPE ROW / ' || l_params;
                        PIPE ROW(l_out_rec);
                    
                    END IF;
                END LOOP doc_ar_doc;
            
            ELSE
                -- Documentation (47; 48; 1050; 1051;1052; 1054)
                ------------ free text ----------------------
                g_error := 'FETCH l_doc_area_register BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_register BULK COLLECT
                    INTO l_dar_doc_tab;
            
                g_error := 'FETCH l_doc_area_val BULK COLLECT INTO / ' || l_params;
                FETCH l_doc_area_val BULK COLLECT
                    INTO l_dav_doc_tab;
            
                g_error := '<<doc_ar_doc>> / ' || l_params;
                <<doc_ar_doc>>
                FOR i IN 1 .. l_dar_doc_tab.count
                LOOP
                    IF l_dar_doc_tab(i).flg_status = pk_ref_constant.g_active
                    --AND l_dar_doc_tab(i).id_doc_area = i_doc_area
                    THEN
                        g_error             := 't_rec_p1_export_data() / ' || l_params;
                        l_out_rec           := t_rec_p1_export_data();
                        l_out_rec.id_req    := l_dar_doc_tab(i).id_pat_history_diagnosis;
                        l_out_rec.dt_insert := l_dar_doc_tab(i).dt_register;
                        l_out_rec.prof_name := l_dar_doc_tab(i).nick_name;
                        l_out_rec.prof_spec := l_dar_doc_tab(i).desc_speciality;
                        l_out_rec.title     := l_doc_area_name;
                    
                        g_error := '<<doc_av_doc>> / ' || l_params;
                        <<doc_av_doc>>
                        FOR j IN 1 .. l_dav_doc_tab.count
                        LOOP
                        
                            IF l_dar_doc_tab(i).id_pat_history_diagnosis = l_dav_doc_tab(j).id_pat_history_diagnosis
                                AND nvl(l_dar_doc_tab(i).flg_status, pk_ref_constant.g_active) =
                                pk_ref_constant.g_active
                            THEN
                                l_ending       := '.';
                                g_error        := 'l_out_rec.text / ' || l_params;
                                l_out_rec.text := l_out_rec.text || chr(10) || l_dav_doc_tab(j).desc_past_hist_all;
                            END IF;
                        END LOOP doc_av_doc;
                    
                        g_error        := 'l_out_rec.text 2 / ' || l_params;
                        l_out_rec.text := ltrim(l_out_rec.text, chr(10));
                    
                        IF l_out_rec.text IS NOT NULL
                           AND NOT (substr(l_out_rec.text, length(l_out_rec.text), length(l_ending)) = l_ending)
                        THEN
                            l_out_rec.text := l_out_rec.text || l_ending;
                        END IF;
                    
                        g_error := 'owa_pattern.change / ' || l_params;
                        owa_pattern.change(l_out_rec.text, '<b>', '', 'g');
                        owa_pattern.change(l_out_rec.text, '</b>', '', 'g');
                    
                        g_error := 'PIPE ROW / ' || l_params;
                        PIPE ROW(l_out_rec);
                    
                    END IF;
                END LOOP doc_ar_doc;
            
        END CASE;
    
        ------------ templates ----------------------
        g_error := 'FETCH l_doc_area_register_tmpl BULK COLLECT INTO / ' || l_params;
        FETCH l_doc_area_register_tmpl BULK COLLECT
            INTO l_dar_templ_tab;
    
        CLOSE l_doc_area_register_tmpl;
        CLOSE l_doc_area_val_tmpl;
    
        g_error := 'l_id_epis.extend / ' || l_params;
        l_id_epis.extend(l_dar_templ_tab.count);
        FOR i IN 1 .. l_dar_templ_tab.count
        LOOP
            l_id_epis(i) := l_dar_templ_tab(i).id_epis_documentation;
        END LOOP;
    
        -- get text from templates
        g_error := 'Call pk_touch_option_out.get_plain_text_entries / ' || l_params;
        pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                   i_prof                    => i_prof,
                                                   i_epis_documentation_list => l_id_epis,
                                                   o_entries                 => l_cur_templ);
    
        -- getting scores descriptions
        l_templ_scores := get_template_scores(i_id_documentation => l_id_epis);
    
        g_error := 'FETCH l_cur_templ / ' || l_params;
        FETCH l_cur_templ BULK COLLECT
            INTO l_tbl_templ;
    
        g_error := '<<doc_ar_templ>> / ' || l_params;
        <<doc_ar_templ>>
        FOR i IN 1 .. l_dar_templ_tab.count
        LOOP
            -- only active records
            IF l_dar_templ_tab(i).flg_status = pk_alert_constant.g_active
            THEN
                g_error          := 't_rec_p1_export_data() / ' || l_params;
                l_out_rec        := t_rec_p1_export_data();
                l_out_rec.id_req := l_dar_templ_tab(i).id_epis_documentation;
            
                l_out_rec.dt_insert := pk_date_utils.date_send_tsz(i_lang, l_dar_templ_tab(i).dt_creation_tstz, i_prof);
                l_out_rec.prof_name := l_dar_templ_tab(i).nick_name;
                l_out_rec.prof_spec := l_dar_templ_tab(i).desc_speciality;
                l_out_rec.title     := l_doc_area_name;
            
                g_error := '<<doc_ar_cur_templ>> / ' || l_params;
                FOR j IN 1 .. l_tbl_templ.count
                LOOP
                    IF l_dar_templ_tab(i).id_epis_documentation = l_tbl_templ(j).id_epis_documentation
                    THEN
                    
                        l_out_rec.text := l_out_rec.text || chr(10) || CASE
                                              WHEN l_templ_scores.exists(l_tbl_templ(j).id_epis_documentation) THEN
                                               l_templ_scores(l_tbl_templ(j).id_epis_documentation) || chr(10)
                                              ELSE
                                               NULL
                                          END || l_tbl_templ(j).plain_text_entry;
                    END IF;
                END LOOP doc_ar_cur_templ;
            
                g_error        := 'l_out_rec.text 2 / ' || l_params;
                l_out_rec.text := ltrim(l_out_rec.text, chr(10));
            
                IF l_out_rec.text IS NOT NULL
                   AND NOT (substr(l_out_rec.text, length(l_out_rec.text), length(l_ending)) = l_ending)
                THEN
                    l_out_rec.text := l_out_rec.text || l_ending;
                END IF;
            
                g_error := 'owa_pattern.change / ' || l_params;
                owa_pattern.change(l_out_rec.text, '<b>', '', 'g');
                owa_pattern.change(l_out_rec.text, '</b>', '', 'g');
            
                g_error := 'PIPE ROW / ' || l_params;
                PIPE ROW(l_out_rec);
            END IF;
        
        END LOOP doc_ar_templ;
    
        RETURN;
    EXCEPTION
        WHEN rowtype_mismatch THEN
            pk_alertlog.log_error(l_func_name || '. - Alterar type. ' || g_error || ' / ' || SQLERRM);
        WHEN no_data_found THEN
            RETURN;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
    END get_past_hist_all;

    /**
    * Get data for patient medication
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_episode episode id    
    * @param   i_patient patient id  
    * @param   i_type    Prescription type
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 2.5.2.3
    * @since   31-05-2012
    */
    FUNCTION get_pat_medication
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_type    IN VARCHAR2
    ) RETURN t_coll_p1_export_data
        PIPELINED IS
        --l_month_before TIMESTAMP WITH LOCAL TIME ZONE;    
        --l_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        --l_ret  pk_rt_types.g_tbl_list_prescription;    
        --l_ref_med_enabled sys_config.value%TYPE;
    BEGIN
    
        /*-- import information only if field "Medication" is available
        l_ref_med_enabled := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_medication_enabled, i_prof),
                                 pk_ref_constant.g_no);
        
        g_error := 'l_ref_med_enabled=' || l_ref_med_enabled;
        IF l_ref_med_enabled = pk_ref_constant.g_yes
        THEN
            l_tstz := current_timestamp;
        
            SELECT (l_tstz - INTERVAL '6' MONTH(6)) - INTERVAL '1' DAY(1)
              INTO l_month_before
              FROM dual;
        
            g_error := 'Call pk_api_pfh_in.get_list_prescription / I_ID_WORKFLOW =(13, 15, 16, 20), I_ID_PATIENT=' ||
                       i_patient;
            l_ret   := pk_api_pfh_in.get_list_prescription(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_id_workflow  => table_number_id(13, 15, 16, 20),
                                                           i_id_patient   => i_patient,
                                                           i_id_visit     => NULL,
                                                           i_id_presc     => NULL,
                                                           i_dt_begin     => l_month_before,
                                                           i_dt_end       => l_tstz,
                                                           i_history_data => 'N');
        END IF;*/
    
        RETURN;
    EXCEPTION
        WHEN rowtype_mismatch THEN
            pk_alertlog.log_error('GET_PAT_MEDICATION. - Change type. ' || g_error || '/' || SQLERRM);
        WHEN no_data_found THEN
            pk_alertlog.log_error(g_error || '/' || SQLERRM);
            RETURN;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || '/' || SQLERRM);
    END get_pat_medication;
BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_p1_data_export;
/
