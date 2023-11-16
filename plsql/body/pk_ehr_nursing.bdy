/*-- Last Change Revision: $Rev: 2027110 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ehr_nursing IS

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
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
    END error_handling;
    --

    /**
    * This function performs error handling and is used internally by other functions in this package.
    * Private function.
    *
    * @param i_lang                Language identifier.
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM.
    * @param o_error               Message to be shown to the user.
    *
    * @return  FALSE (in any case, in order to allow a RETURN error_handling statement in exception
    * handling blocks).
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        o_error := pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_common_m001) || chr(10) ||
                   g_package_name || '.' || i_func_proc_name;
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
        RETURN FALSE;
    END error_handling;
    --

    /**
    * This function verifies if the patient have any previous diagnosis
    *
    * @param i_patient             Patient identifier.
    * @param i_date                Date of the creation of the register.
    *
    * @return  BOOLEAN
    *
    * @author   Thiago Brito
    * @version  2.4.3
    * @since    2008/05/27
    */
    FUNCTION is_first_diagnosis
    (
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN icnp_epis_diagnosis.dt_icnp_epis_diag_tstz%TYPE
    ) RETURN BOOLEAN IS
    
        v_total PLS_INTEGER := 0;
    
    BEGIN
        SELECT COUNT(*) total
          INTO v_total
          FROM icnp_epis_diagnosis
         WHERE id_patient = i_patient
           AND id_episode = i_episode
           AND dt_icnp_epis_diag_tstz < i_date;
    
        IF (v_total = 0)
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END;
    --

    /**
    * Returns patient education by EPISODE identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @return  The patient education array for the EPISODE identifier.
    *
    * @author   Thiago Brito
    * @version  2.4.3
    * @since    2008/05/21
    */
    FUNCTION get_nursing_notes_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_clob IS
        l_plans table_clob;
        l_title VARCHAR2(100);
        l_value VARCHAR2(2000);
        l_error t_error_out;
    
        CURSOR c_cursor IS
            SELECT er.desc_epis_recomend_clob desc_val,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) desc_prof,
                   pk_date_utils.date_char_tsz(i_lang, er.dt_epis_recomend_tstz, i_prof.institution, i_prof.software) desc_date,
                   nvl(pk_prof_utils.get_category(i_lang,
                                                  profissional(er.id_professional, i_prof.institution, i_prof.software)),
                       pk_alert_constant.g_cat_type_nurse) AS cat,
                   er.dt_epis_recomend_tstz ord_column
              FROM epis_recomend er
             WHERE er.id_episode = i_id_episode
               AND er.desc_epis_recomend_clob IS NOT NULL
               AND er.flg_type = g_flg_type_nursing_notes
            UNION ALL
            SELECT ed.notes desc_val,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) desc_prof,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) desc_date,
                   nvl(pk_prof_utils.get_category(i_lang,
                                                  profissional(ed.id_professional, i_prof.institution, i_prof.software)),
                       pk_alert_constant.g_cat_type_nurse) AS cat,
                   ed.dt_creation_tstz ord_column
              FROM epis_documentation ed
             WHERE ed.id_episode = i_id_episode
               AND ed.id_doc_area = pk_summary_page.g_doc_area_nursing_notes
               AND ed.flg_status = pk_alert_constant.g_active
             ORDER BY ord_column DESC;
    
        TYPE t_cursor_type IS TABLE OF c_cursor%ROWTYPE;
        l_record  t_cursor_type;
        l_counter NUMBER;
        internal_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_ehr_common.get_visit_type_by_epis(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_id_episode   => i_id_episode,
                                                    i_id_epis_type => i_id_epis_type,
                                                    i_sep          => '; ',
                                                    o_title        => l_title,
                                                    o_value        => l_value,
                                                    o_error        => l_error)
        THEN
            RAISE internal_exception;
        END IF;
    
        l_plans := table_clob();
        l_plans.extend(3);
        l_plans(1) := '';
        l_plans(2) := l_title;
        l_plans(3) := l_value;
    
        l_title := pk_message.get_message(i_lang, i_prof, 'EHR_NURSING_NOTES_T001'); -- Notes | Notas
        OPEN c_cursor;
        LOOP
            FETCH c_cursor BULK COLLECT
                INTO l_record LIMIT 100;
            FOR i IN 1 .. l_record.count
            LOOP
                l_counter := l_plans.count;
                l_plans.extend(7);
                l_plans(l_counter + 1) := '';
                l_plans(l_counter + 2) := l_title || ': ';
                l_plans(l_counter + 3) := l_record(i).desc_val;
                l_plans(l_counter + 4) := 'I';
                l_plans(l_counter + 5) := l_record(i).desc_prof;
                l_plans(l_counter + 6) := l_record(i).desc_date;
                l_plans(l_counter + 7) := l_record(i).cat;
            
            END LOOP;
            EXIT WHEN c_cursor%NOTFOUND;
        END LOOP;
    
        RETURN l_plans;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                o_error t_error_out;
            BEGIN
                g_error := pk_message.get_message(i_lang, g_msg_common_m001) || chr(10) || l_error.err_desc;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  'GET_NURSING_NOTES_BY_EPIS',
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
            END;
    END get_nursing_notes_by_epis;

    FUNCTION get_nursing_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'GET_NURSING_NOTES';
    
    BEGIN
    
        g_error := 'OPEN O_CURSOR';
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   table_table_clob(get_nursing_notes_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type)) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND (((SELECT COUNT(1)
                        FROM epis_recomend er
                       WHERE er.id_episode = e.id_episode
                         AND er.flg_type = g_flg_type_nursing_notes
                         AND er.desc_epis_recomend_clob IS NOT NULL) > 0) OR
                   ((SELECT COUNT(1)
                        FROM epis_documentation ed
                       WHERE ed.id_episode = e.id_episode
                         AND ed.id_doc_area = pk_summary_page.g_doc_area_nursing_notes
                         AND ed.flg_status = pk_alert_constant.g_active) > 0))
             ORDER BY e.dt_begin_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END;

    FUNCTION get_assessment_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE
    ) RETURN table_varchar IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_assessment_by_epis';
    
        -- Using maps with keys of type "varchar" to ensure be possible to use up to 24 digits
        SUBTYPE t_map_key IS VARCHAR2(255 CHAR);
    
        TYPE t_doc_entry_rec IS RECORD(
            id_epis_documentation epis_documentation.id_epis_documentation%TYPE,
            dt_creation_tstz      epis_documentation.dt_creation_tstz%TYPE,
            id_professional       epis_documentation.id_professional%TYPE);
    
        TYPE t_map_doc_entry IS TABLE OF t_doc_entry_rec INDEX BY t_map_key;
    
        l_plans                   table_varchar;
        l_epis_documentation_list table_number;
        l_counter                 pk_types.t_big_num;
        l_title                   pk_types.t_med_char;
        l_value                   pk_types.t_huge_byte;
        l_error                   t_error_out;
        l_cur_templ               pk_touch_option_out.t_cur_plain_text_entry;
        l_tbl_templ               pk_touch_option_out.t_coll_plain_text_entry;
        l_entry                   t_doc_entry_rec;
        l_map_entries             t_map_doc_entry;
        internal_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'Retrieving episode type';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        IF NOT pk_ehr_common.get_visit_type_by_epis(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_id_episode   => i_id_episode,
                                                    i_id_epis_type => i_id_epis_type,
                                                    i_sep          => '; ',
                                                    o_title        => l_title,
                                                    o_value        => l_value,
                                                    o_error        => l_error)
        THEN
            RAISE internal_exception;
        END IF;
    
        l_plans := table_varchar();
        l_plans.extend(3);
        l_plans(1) := '';
        l_plans(2) := l_title;
        l_plans(3) := l_value;
    
        l_epis_documentation_list := table_number();
        g_error                   := 'Retrieving documentation entry IDs';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        FOR c_entries IN (SELECT ed.id_epis_documentation, ed.dt_creation_tstz, ed.id_professional
                            FROM epis_documentation ed
                           WHERE ed.id_episode = i_id_episode
                             AND ed.id_doc_area IN (SELECT id_doc_area
                                                      FROM doc_area a
                                                     WHERE a.id_doc_area = i_doc_area
                                                        OR a.id_parent_doc_area = i_doc_area)
                             AND ed.flg_status = pk_alert_constant.g_active)
        LOOP
            l_epis_documentation_list.extend();
            l_epis_documentation_list(l_epis_documentation_list.last) := c_entries.id_epis_documentation;
        
            l_entry.id_epis_documentation := c_entries.id_epis_documentation;
            l_entry.dt_creation_tstz      := c_entries.dt_creation_tstz;
            l_entry.id_professional       := c_entries.id_professional;
        
            l_map_entries(to_char(l_entry.id_epis_documentation)) := l_entry;
        
        END LOOP;
    
        g_error := 'Retrieving plain text entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                   i_prof                    => i_prof,
                                                   i_epis_documentation_list => l_epis_documentation_list,
                                                   i_use_html_format         => pk_alert_constant.g_yes,
                                                   o_entries                 => l_cur_templ);
    
        g_error := 'Fetching plain text entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        LOOP
            FETCH l_cur_templ BULK COLLECT
                INTO l_tbl_templ LIMIT 100;
            EXIT WHEN l_tbl_templ.count = 0;
        
            FOR i IN 1 .. l_tbl_templ.count
            LOOP
                l_counter := l_plans.count;
            
                l_plans.extend(6);
                l_plans(l_counter + 1) := '';
                l_plans(l_counter + 2) := '';
                l_plans(l_counter + 3) := dbms_lob.substr(l_tbl_templ(i).plain_text_entry,
                                                          pk_types.k_varchar2_pl_max_length);
                l_plans(l_counter + 4) := 'I';
                l_plans(l_counter + 5) := pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                           i_prof    => i_prof,
                                                                           i_prof_id => l_map_entries(to_char(l_tbl_templ(i).id_epis_documentation))
                                                                                        .id_professional);
                l_plans(l_counter + 6) := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                      i_date => l_map_entries(to_char(l_tbl_templ(i).id_epis_documentation))
                                                                                .dt_creation_tstz,
                                                                      i_inst => i_prof.institution,
                                                                      i_soft => i_prof.software);
            
            END LOOP;
        END LOOP;
    
        RETURN l_plans;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                o_error t_error_out;
            BEGIN
                g_error := pk_message.get_message(i_lang, g_msg_common_m001) || chr(10) || l_error.err_desc;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  k_function_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN NULL;
            END;
        
    END get_assessment_by_epis;

    FUNCTION get_assessment
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_doc_area   IN doc_area.id_doc_area%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'GET_ASSESSMENT';
    
    BEGIN
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   get_assessment_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, i_doc_area) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND (SELECT COUNT(1)
                      FROM epis_documentation ed
                     WHERE ed.id_episode = e.id_episode
                       AND ed.flg_status = pk_alert_constant.g_active
                       AND ed.id_doc_area IN (SELECT id_doc_area
                                                FROM doc_area a
                                               WHERE a.id_doc_area = i_doc_area
                                                  OR a.id_parent_doc_area = i_doc_area)) > 0
             ORDER BY e.dt_begin_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, g_msg_common_m001);
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_cursor);
                RETURN FALSE;
            END;
        
    END get_assessment;

    FUNCTION get_diagnosis_interv_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_varchar IS
    
        l_plans table_varchar;
        l_title VARCHAR2(100);
        l_value VARCHAR2(2000);
        l_error t_error_out;
    
        CURSOR c_cursor IS
            SELECT ied.id_icnp_epis_diag,
                   ied.id_parent,
                   ied.id_composition,
                   ied.dt_icnp_epis_diag_tstz,
                   ied.id_professional,
                   ied.flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS prof,
                   ied.dt_close_tstz AS dt_close,
                   ied.id_episode,
                   ied.id_episode AS id_episode2,
                   ied.id_patient,
                   pk_translation.get_translation(i_lang, ic.code_icnp_composition) composition,
                   pk_sysdomain.get_domain(g_icnp_epis_diagnosis, ied.flg_status, i_lang) status
              FROM icnp_epis_diagnosis ied, icnp_composition ic, professional p
             WHERE ied.id_episode = i_id_episode
               AND ied.id_professional = p.id_professional
               AND ied.id_composition = ic.id_composition
            UNION ALL
            SELECT ied.id_icnp_epis_diag,
                   ied.id_parent,
                   ied.id_composition,
                   ied.dt_icnp_epis_diag_tstz,
                   ied.id_professional,
                   ied.flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS prof,
                   ied.dt_close_tstz AS dt_close,
                   ied.id_episode,
                   iie.id_episode AS id_episode2,
                   ied.id_patient,
                   pk_translation.get_translation(i_lang, ic.code_icnp_composition) composition,
                   pk_sysdomain.get_domain(g_icnp_epis_diagnosis, ied.flg_status, i_lang) status
              FROM icnp_epis_diagnosis ied, icnp_composition ic, professional p, interv_icnp_ea iie
             WHERE ied.id_episode IN (iie.id_episode, iie.id_episode_origin)
               AND iie.id_episode = i_id_episode
               AND ied.id_professional = p.id_professional
               AND ied.id_composition = ic.id_composition
               AND ied.id_episode <> iie.id_episode
             ORDER BY dt_icnp_epis_diag_tstz DESC;
    
        TYPE t_cursor_type IS TABLE OF c_cursor%ROWTYPE;
        l_record t_cursor_type;
    
        CURSOR c_intervention
        (
            l_id_icnp_edis_diag NUMBER,
            l_id_episode        NUMBER
        ) IS
            SELECT iei.id_icnp_epis_interv,
                   pk_translation.get_translation(i_lang, ic.code_icnp_composition) composition,
                   (SELECT sd.desc_val
                      FROM sys_domain sd
                     WHERE sd.code_domain = g_icnp_epis_interv
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND val = iei.flg_status) status,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(iei.dt_close_tstz,
                                                      NULL,
                                                      (SELECT iip.dt_take_tstz
                                                         FROM icnp_interv_plan iip
                                                        WHERE iip.dt_take_tstz IS NOT NULL
                                                          AND iip.id_icnp_epis_interv = iei.id_icnp_epis_interv
                                                          AND rownum = 1),
                                                      iei.dt_close_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_last_execution,
                   decode(iei.id_prof_close,
                          NULL,
                          --(SELECT p.name --ALERT-10363
                          (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)
                             FROM icnp_interv_plan iip, professional p
                            WHERE iip.id_prof_take = p.id_professional
                              AND iip.dt_take_tstz IS NOT NULL
                              AND iip.id_icnp_epis_interv = iei.id_icnp_epis_interv
                              AND rownum = 1),
                          --(SELECT p.name --ALERT-10363
                          (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)
                             FROM professional p
                            WHERE p.id_professional = iei.id_prof_close)) AS prof_take,
                   pk_date_utils.date_char_tsz(i_lang,
                                               iei.dt_icnp_epis_interv_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_interv,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS prof_name
              FROM icnp_epis_diag_interv  iedi,
                   icnp_epis_intervention iei,
                   icnp_composition       ic,
                   professional           p,
                   interv_icnp_ea         iie
             WHERE iedi.id_icnp_epis_interv = iei.id_icnp_epis_interv
               AND p.id_professional(+) = iei.id_prof
               AND iei.id_composition(+) = ic.id_composition
               AND iei.id_icnp_epis_interv = iie.id_icnp_epis_interv --p
               AND iedi.id_icnp_epis_diag = l_id_icnp_edis_diag
               AND iei.id_episode IN (l_id_episode);
    
        TYPE t_intervention_type IS TABLE OF c_intervention%ROWTYPE;
        l_record_det t_intervention_type;
    
        -- INTERVN합ES RESULTANTE DA PRESCRI허O
        CURSOR c_intervention_presc(l_id_episode NUMBER) IS
        
            SELECT iei.id_icnp_epis_interv,
                   pk_translation.get_translation(i_lang, ic.code_icnp_composition) composition,
                   (SELECT sd.desc_val
                      FROM sys_domain sd
                     WHERE sd.code_domain = g_icnp_epis_interv
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND val = iei.flg_status) status,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(iei.dt_close_tstz,
                                                      NULL,
                                                      (SELECT iip.dt_take_tstz
                                                         FROM icnp_interv_plan iip
                                                        WHERE iip.dt_take_tstz IS NOT NULL
                                                          AND iip.id_icnp_epis_interv = iei.id_icnp_epis_interv
                                                          AND rownum = 1),
                                                      iei.dt_close_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_last_execution,
                   decode(iei.id_prof_close,
                          NULL,
                          --(SELECT p.name --ALERT-10363
                          (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)
                             FROM icnp_interv_plan iip, professional p
                            WHERE iip.id_prof_take = p.id_professional
                              AND iip.dt_take_tstz IS NOT NULL
                              AND iip.id_icnp_epis_interv = iei.id_icnp_epis_interv
                              AND rownum = 1),
                          --(SELECT p.name --ALERT-10363
                          (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)
                             FROM professional p
                            WHERE p.id_professional = iei.id_prof_close)) AS prof_take,
                   pk_date_utils.date_char_tsz(i_lang,
                                               iei.dt_icnp_epis_interv_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_interv,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS prof_name
              FROM icnp_epis_intervention iei,
                   icnp_composition       ic,
                   professional           p,
                   interv_icnp_ea         iie,
                   icnp_suggest_interv    isi
             WHERE isi.id_icnp_epis_interv = iie.id_icnp_epis_interv
               AND p.id_professional(+) = iei.id_prof
               AND iei.id_composition(+) = ic.id_composition
               AND iei.id_icnp_epis_interv = iie.id_icnp_epis_interv --p
               AND iei.id_episode IN (l_id_episode)
               AND NOT EXISTS
             (SELECT 1
                      FROM icnp_epis_diag_interv iedi
                     WHERE iedi.id_icnp_epis_interv = iie.id_icnp_epis_interv
                       AND iedi.flg_status_rel IN
                           (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated));
    
        TYPE t_intervention_type_p IS TABLE OF c_intervention_presc%ROWTYPE;
        l_record_det_presc t_intervention_type_p;
    
        l_counter NUMBER;
        internal_exception EXCEPTION;
    
        -- intervention (NURSING_DIAG_INTERV_T002)
        l_intervention VARCHAR2(200);
        -- intervention (NURSING_DIAG_INTERV_T002)
        l_intervention_presc VARCHAR2(200);
        -- last_performed (NURSING_DIAG_INTERV_T003)
        l_last_performed VARCHAR2(200);
        -- status (NURSING_DIAG_INTERV_T004)
        l_status VARCHAR2(200);
        -- reassessed (NURSING_DIAG_INTERV_T005)
        l_reassessed VARCHAR2(200);
        -- initial_diagnosis (NURSING_DIAG_INTERV_T006)
        l_initial_diagnosis VARCHAR2(200);
    
        flg_control  BOOLEAN := FALSE;
        flg_data     BOOLEAN := FALSE;
        l_id_episode NUMBER;
    
    BEGIN
    
        IF NOT pk_ehr_common.get_visit_type_by_epis(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_id_episode   => i_id_episode,
                                                    i_id_epis_type => i_id_epis_type,
                                                    i_sep          => '; ',
                                                    o_title        => l_title,
                                                    o_value        => l_value,
                                                    o_error        => l_error)
        THEN
            RAISE internal_exception;
        END IF;
    
        l_intervention       := pk_message.get_message(i_lang, 'NURSING_DIAG_INTERV_T002');
        l_intervention_presc := pk_message.get_message(i_lang, 'NURSING_DIAG_INTERV_T007');
        l_last_performed     := pk_message.get_message(i_lang, 'NURSING_DIAG_INTERV_T003');
        l_status             := pk_message.get_message(i_lang, 'NURSING_DIAG_INTERV_T004');
        l_reassessed         := pk_message.get_message(i_lang, 'NURSING_DIAG_INTERV_T005');
        l_initial_diagnosis  := pk_message.get_message(i_lang, 'NURSING_DIAG_INTERV_T006');
    
        l_plans := table_varchar();
        l_plans.extend(3);
        l_plans(1) := '';
        l_plans(2) := l_title;
        l_plans(3) := l_value;
    
        IF ((l_title IS NOT NULL) OR (l_value IS NOT NULL))
        THEN
            l_counter := l_plans.count;
            l_plans.extend(3);
            l_plans(l_counter + 1) := '';
            l_plans(l_counter + 2) := '';
            l_plans(l_counter + 3) := '';
        END IF;
    
        OPEN c_cursor;
        LOOP
        
            FETCH c_cursor BULK COLLECT
                INTO l_record LIMIT 100;
        
            FOR i IN 1 .. l_record.count
            LOOP
            
                l_counter := l_plans.count;
                l_plans.extend(6);
            
                l_plans(l_counter + 1) := '';
            
                IF (is_first_diagnosis(l_record(i).id_patient, i_id_episode, l_record(i).dt_icnp_epis_diag_tstz))
                THEN
                    l_plans(l_counter + 2) := l_initial_diagnosis || ': ';
                ELSE
                    l_plans(l_counter + 2) := l_reassessed || ': ';
                END IF;
            
                l_plans(l_counter + 3) := l_record(i).composition;
            
                l_plans(l_counter + 4) := '';
                l_plans(l_counter + 5) := '';
                l_plans(l_counter + 6) := '';
            
                IF l_record(i).id_episode2 IS NULL
                THEN
                    l_id_episode := l_record(i).id_episode;
                ELSE
                    l_id_episode := l_record(i).id_episode2;
                END IF;
            
                --OPEN c_intervention(l_record(i).id_icnp_epis_diag);
                OPEN c_intervention(l_record(i).id_icnp_epis_diag, l_id_episode);
                LOOP
                
                    FETCH c_intervention BULK COLLECT
                        INTO l_record_det LIMIT 100;
                
                    FOR j IN 1 .. l_record_det.count
                    LOOP
                        l_counter := l_plans.count;
                        l_plans.extend(3);
                        l_plans(l_counter + 1) := '';
                        l_plans(l_counter + 2) := l_intervention || ': ';
                        l_plans(l_counter + 3) := l_record_det(j).composition;
                    
                        IF (l_record_det(j).dt_last_execution IS NOT NULL)
                        THEN
                            l_counter := l_plans.count;
                            l_plans.extend(3);
                            l_plans(l_counter + 1) := '';
                            l_plans(l_counter + 2) := l_last_performed || ': ';
                            l_plans(l_counter + 3) := l_record_det(j)
                                                      .dt_last_execution || ', ' || l_record_det(j).prof_take;
                            flg_control := TRUE;
                        END IF;
                    
                        IF (l_record_det(j).status IS NOT NULL)
                        THEN
                            l_counter := l_plans.count;
                            l_plans.extend(3);
                            l_plans(l_counter + 1) := '';
                            l_plans(l_counter + 2) := l_status || ': ';
                            l_plans(l_counter + 3) := l_record_det(j).status;
                            flg_control := TRUE;
                        END IF;
                    
                        IF ((l_record_det(j).prof_name IS NOT NULL) OR (l_record_det(j).dt_interv IS NOT NULL))
                        THEN
                            l_counter := l_plans.count;
                            l_plans.extend(3);
                            l_plans(l_counter + 1) := 'I';
                            l_plans(l_counter + 2) := l_record_det(j).prof_name;
                            l_plans(l_counter + 3) := l_record_det(j).dt_interv;
                            flg_control := TRUE;
                        END IF;
                    
                        IF (flg_control)
                        THEN
                            l_counter := l_plans.count;
                            l_plans.extend(3);
                            l_plans(l_counter + 1) := '';
                            l_plans(l_counter + 2) := '';
                            l_plans(l_counter + 3) := '';
                        END IF;
                    
                    -- flg_data := TRUE;
                    
                    END LOOP;
                
                    EXIT WHEN c_intervention%NOTFOUND;
                END LOOP;
            
                CLOSE c_intervention;
            
            END LOOP;
        
            flg_data := TRUE;
        
            EXIT WHEN c_cursor%NOTFOUND;
        
        END LOOP;
    
        --INTERVEN합ES RESULTANTE DE PRESCRI플O
        OPEN c_intervention_presc(l_id_episode);
        LOOP
        
            FETCH c_intervention_presc BULK COLLECT
                INTO l_record_det_presc LIMIT 100;
        
            FOR j IN 1 .. l_record_det_presc.count
            LOOP
                l_counter := l_plans.count;
                l_plans.extend(3);
                l_plans(l_counter + 1) := '';
                l_plans(l_counter + 2) := l_intervention_presc || ': ';
                l_plans(l_counter + 3) := l_record_det_presc(j).composition;
            
                IF (l_record_det_presc(j).dt_last_execution IS NOT NULL)
                THEN
                    l_counter := l_plans.count;
                    l_plans.extend(3);
                    l_plans(l_counter + 1) := '';
                    l_plans(l_counter + 2) := l_last_performed || ': ';
                    l_plans(l_counter + 3) := l_record_det_presc(j)
                                              .dt_last_execution || ', ' || l_record_det_presc(j).prof_take;
                    flg_control := TRUE;
                END IF;
            
                IF (l_record_det_presc(j).status IS NOT NULL)
                THEN
                    l_counter := l_plans.count;
                    l_plans.extend(3);
                    l_plans(l_counter + 1) := '';
                    l_plans(l_counter + 2) := l_status || ': ';
                    l_plans(l_counter + 3) := l_record_det_presc(j).status;
                    flg_control := TRUE;
                END IF;
            
                IF ((l_record_det_presc(j).prof_name IS NOT NULL) OR (l_record_det_presc(j).dt_interv IS NOT NULL))
                THEN
                    l_counter := l_plans.count;
                    l_plans.extend(3);
                    l_plans(l_counter + 1) := 'I';
                    l_plans(l_counter + 2) := l_record_det_presc(j).prof_name;
                    l_plans(l_counter + 3) := l_record_det_presc(j).dt_interv;
                    flg_control := TRUE;
                END IF;
            
                IF (flg_control)
                THEN
                    l_counter := l_plans.count;
                    l_plans.extend(3);
                    l_plans(l_counter + 1) := '';
                    l_plans(l_counter + 2) := '';
                    l_plans(l_counter + 3) := '';
                END IF;
            
            END LOOP;
        
            EXIT WHEN c_intervention_presc%NOTFOUND;
        END LOOP;
    
        CLOSE c_intervention_presc;
    
        IF (NOT flg_data)
        THEN
            l_plans.delete;
            RETURN NULL;
        ELSE
            RETURN l_plans;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            --PLLopes 10/03/2009 ALERT-17261- setting error content into input object 
            DECLARE
                o_error t_error_out;
            BEGIN
                g_error := pk_message.get_message(i_lang, g_msg_common_m001) || chr(10) || l_error.err_desc;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  'GET_DIAGNOSIS_INTERV_BY_EPIS',
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                --pk_util.undo_changes;
                --RETURN FALSE;
            END;
    END;

    FUNCTION get_diagnosis_interventions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'GET_DIAGNOSES_INTERVENTIONS';
    
    BEGIN
    
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   get_diagnosis_interv_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND (((SELECT COUNT(1)
                        FROM icnp_epis_intervention iei
                       WHERE iei.id_episode = e.id_episode) > 0) OR
                   (SELECT COUNT(1)
                       FROM icnp_epis_diagnosis ied
                      WHERE ied.id_episode = e.id_episode) > 0)
               AND get_diagnosis_interv_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type) IS NOT NULL
             ORDER BY e.dt_begin_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            --PLLopes 10/03/2009 ALERT-17261- setting error content into input object 
            BEGIN
                g_error := pk_message.get_message(i_lang, g_msg_common_m001);
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                --pk_util.undo_changes;
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_cursor);
                RETURN FALSE;
            END;
        
    END;
    --

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

    g_icnp_epis_diagnosis := 'ICNP_EPIS_DIAGNOSIS.FLG_STATUS';
    g_icnp_epis_interv    := 'ICNP_EPIS_INTERVENTION.FLG_STATUS';
    g_flg_reassessed      := 'R';

    g_action    := 'A';
    g_diagnosis := 'D';
    g_yes       := 'Y';
    g_no        := 'N';
    g_date      := 'D';
    g_icon      := 'I';
    g_male      := 'M';
    g_female    := 'F';
    g_both      := 'B';
    g_no_color  := 'X';

    /*
    * diagnosis / intervention status
    */
    g_finished    := 'F';
    g_solved      := 'S';
    g_active      := 'A';
    g_canceled    := 'C';
    g_revaluated  := 'R';
    g_interrupted := 'I';
    g_terminated  := 'T';

    g_flg_time_epis := 'E';
    g_flg_time_next := 'N';
    g_flg_time_betw := 'B';

    g_interv_req  := 'R';
    g_interv_exec := 'E';
    g_interv_canc := 'C';
    g_interv_pend := 'D';
    g_interv_fin  := 'F';
    g_interv_part := 'P';

    g_interv_plan_admt  := 'A';
    g_interv_plan_nadmt := 'N';
    g_interv_plan_req   := 'R';
    g_interv_plan_pend  := 'D';
    g_interv_plan_canc  := 'C';
    g_interv_plan_mod   := 'M';

    g_take_sos  := 'S';
    g_take_nor  := 'N';
    g_take_uni  := 'U';
    g_take_cont := 'C';
    g_take_eter := 'A';

    g_flg_type_nursing_notes := 'N';

END pk_ehr_nursing;
/
