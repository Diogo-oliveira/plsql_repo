/*-- Last Change Revision: $Rev: 1994181 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2021-07-13 15:16:36 +0100 (ter, 13 jul 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_prev_encounter IS

    g_error         VARCHAR2(1000 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);
    g_found         BOOLEAN;
    g_exception EXCEPTION;

    g_caller user_objects.object_name%TYPE;

    g_prv_enc t_rec_prev_encounter;

    -- field types
    g_field_header    CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_field_title     CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_field_record    CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_field_signature CONSTANT VARCHAR2(1 CHAR) := 'I';

    g_schortcut_prev_episode CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 800593;

    -- nursing appointments episode type
    g_epis_nurse epis_type.id_epis_type%TYPE;

    g_flg_type_m CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_flg_type_s CONSTANT VARCHAR2(1 CHAR) := 'S';

    g_et_code      CONSTANT translation.code_translation%TYPE := 'EPIS_TYPE.CODE_EPIS_TYPE.';
    g_et_code_icon CONSTANT translation.code_translation%TYPE := 'EPIS_TYPE.CODE_ICON.';
    -- field has no data
    g_no_data CONSTANT VARCHAR2(2 CHAR) := '--';

    g_sys_config_report CONSTANT VARCHAR2(20 CHAR) := 'TIMELINE_REPORT';

    -- shared cursors
    CURSOR c_epis_recomend
    (
        i_episode  IN epis_recomend.id_episode%TYPE,
        i_type_flg IN epis_recomend.flg_type%TYPE
    ) IS
        SELECT er.desc_epis_recomend_clob description, er.id_professional, er.dt_epis_recomend_tstz dt_change
          FROM epis_recomend er
         WHERE er.id_episode = i_episode
           AND er.flg_temp != pk_clinical_info.g_flg_hist
           AND er.flg_type = i_type_flg
           AND er.flg_status = pk_alert_constant.g_active
         ORDER BY dt_change DESC;

    CURSOR c_epis IS
        SELECT coalesce(ei.id_first_nurse_resp,
                        ei.id_prof_first_nurse_obs,
                        decode(e.id_epis_type, g_epis_nurse, ei.sch_prof_outp_id_prof)) id_prof_nur,
               nvl(ei.id_professional, decode(e.id_epis_type, g_epis_nurse, NULL, ei.sch_prof_outp_id_prof)) id_prof_med,
               e.dt_begin_tstz dt_change
          FROM episode e
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         WHERE e.id_episode = g_prv_enc.id_episode;

    /**
    * Reset global g_prv_enc variable.
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2009/12/23
    */
    PROCEDURE reset_var IS
    BEGIN
        g_prv_enc := t_rec_prev_encounter(id_episode    => NULL,
                                          id_schedule   => NULL,
                                          id_epis_type  => NULL,
                                          enc_data      => table_clob(),
                                          id_prof_med   => NULL,
                                          dt_change_med => NULL,
                                          id_prof_nur   => NULL,
                                          dt_change_nur => NULL);
    END reset_var;

    /**
    * Checks if the reports layer is consuming the current service call.
    *
    * @return               true if service is for reports consumption, false otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/12
    */
    FUNCTION check_rep_consumer RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
        -- reports consumer is identified by having REP in its name
        IF instr(str1 => upper(g_caller), str2 => 'REP') > 0
        THEN
            l_ret := TRUE;
        ELSE
            l_ret := FALSE;
        END IF;
    
        RETURN l_ret;
    END check_rep_consumer;

    /**
    * Checks if the record change date is the most recent.
    * If so, it sets it in the global g_prv_enc variable.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_id      professional who made the change
    * @param i_dt_change    change date to check
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2010/01/04
    */
    PROCEDURE check_dt_change
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        i_dt_change IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        l_cat category.flg_type%TYPE;
    BEGIN
        l_cat := pk_prof_utils.get_category(i_lang, profissional(i_prof_id, i_prof.institution, i_prof.software));
    
        IF l_cat = pk_alert_constant.g_cat_type_doc
        THEN
            IF g_prv_enc.dt_change_med IS NULL
               OR i_dt_change > g_prv_enc.dt_change_med
            THEN
                g_prv_enc.dt_change_med := i_dt_change;
                g_prv_enc.id_prof_med   := i_prof_id;
            END IF;
        ELSIF l_cat = pk_alert_constant.g_cat_type_nurse
        THEN
            IF g_prv_enc.dt_change_nur IS NULL
               OR i_dt_change > g_prv_enc.dt_change_nur
            THEN
                g_prv_enc.dt_change_nur := i_dt_change;
                g_prv_enc.id_prof_nur   := i_prof_id;
            END IF;
        END IF;
    END check_dt_change;

    /**
    * Appends data to enc_data collection.
    *
    * @param i_table        data to append
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/03
    */
    PROCEDURE append_data(i_table IN table_clob) IS
        l_last_idx PLS_INTEGER;
    BEGIN
        IF i_table IS NULL
           OR i_table.count < 1
        THEN
            -- no data to append
            NULL;
        ELSE
            -- get encounter data last index
            l_last_idx := nvl(g_prv_enc.enc_data.last, 0);
            -- extend the collection
            g_prv_enc.enc_data.extend(i_table.count);
            -- append data
            FOR i IN i_table.first .. i_table.last
            LOOP
                g_prv_enc.enc_data(l_last_idx + i) := i_table(i);
            END LOOP;
        END IF;
    END append_data;

    /**
    * Get current episode signature.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_force_nur    force nurse signature
    *
    * @returns              current episode signature
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/03
    */
    FUNCTION get_signature
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_force_nur IN BOOLEAN := FALSE
    ) RETURN pk_translation.t_desc_translation IS
        l_signature pk_translation.t_desc_translation := NULL;
        l_message   sys_message.desc_message%TYPE;
    BEGIN
        l_message := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'DASHBOARD_T012');
    
        IF (i_force_nur OR g_prv_enc.id_epis_type = g_epis_nurse)
           AND g_prv_enc.id_prof_nur IS NOT NULL
        THEN
            l_signature := l_message || pk_tools.get_prof_description(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_prof_id => g_prv_enc.id_prof_nur,
                                                                      i_date    => g_prv_enc.dt_change_nur,
                                                                      i_episode => g_prv_enc.id_episode) || ' / ' ||
                           pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                       i_date => g_prv_enc.dt_change_nur,
                                                       i_inst => i_prof.institution,
                                                       i_soft => i_prof.software);
        ELSIF g_prv_enc.id_prof_med IS NOT NULL
        THEN
            l_signature := l_message || pk_tools.get_prof_description(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_prof_id => g_prv_enc.id_prof_med,
                                                                      i_date    => g_prv_enc.dt_change_med,
                                                                      i_episode => g_prv_enc.id_episode) || ' / ' ||
                           pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                       i_date => g_prv_enc.dt_change_med,
                                                       i_inst => i_prof.institution,
                                                       i_soft => i_prof.software);
        END IF;
    
        RETURN l_signature;
    END get_signature;

    /**
    * Sorts and concatenates all descriptions.
    *
    * @param i_descs        descriptions
    *
    * @return               sorted and appended descriptions
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2009/12/23
    */
    FUNCTION get_sort_concat(i_descs IN table_varchar) RETURN VARCHAR2 IS
    BEGIN
        -- sort descriptions, and append all in a string
        RETURN pk_utils.to_string(pk_utils.sort_table_varchar(i_descs));
    END get_sort_concat;

    /**
    * Get reason for visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_error        error
    *
    * @returns              false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2010/01/04
    */
    FUNCTION get_reason_for_visit
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_title     sys_message.desc_message%TYPE;
        l_rea_visit pk_types.cursor_type;
        l_text      table_clob := table_clob();
        l_prof      table_number := table_number();
        l_date      table_timestamp_tz := table_timestamp_tz();
        l_reason    VARCHAR2(32767);
        l_cur_ec    pk_complaint.epis_complaint_cur;
        l_row_ec    pk_complaint.epis_complaint_rec;
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T001') || ': ';
    
        IF g_prv_enc.id_epis_type IN
           (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_urgent_care)
        THEN
        
            g_error := 'GET EMERGENCY COMPLAINT';
            IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => g_prv_enc.id_episode,
                                                   i_epis_docum     => NULL,
                                                   i_flg_only_scope => pk_alert_constant.g_no,
                                                   o_epis_complaint => l_cur_ec,
                                                   o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'FETCH L_CUR_EC';
            FETCH l_cur_ec
                INTO l_row_ec;
            CLOSE l_cur_ec;
        
            l_reason := pk_complaint.get_epis_complaint_desc(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_scope_complaint => l_row_ec.desc_complaint,
                                                             i_chief_complaint => l_row_ec.patient_complaint);
        ELSE
            g_error := 'CALL pk_progress_notes.get_reason_for_visit';
            IF NOT pk_progress_notes.get_reason_for_visit(i_lang      => i_lang,
                                                          i_episode   => g_prv_enc.id_episode,
                                                          o_rea_visit => l_rea_visit,
                                                          o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'FETCH l_rea_visit';
            FETCH l_rea_visit BULK COLLECT
                INTO l_text, l_prof, l_date;
            CLOSE l_rea_visit;
        END IF;
    
        IF l_text.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_text.first .. l_text.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_text(i)));
            END LOOP;
        ELSIF l_reason IS NOT NULL
        THEN
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, l_reason));
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    
        RETURN TRUE;
    END get_reason_for_visit;

    /**
    * Get subjective.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    *
    * @author               Sofia Mendes
    * @version               2.6.3
    * @since                24/06/2013
    */
    FUNCTION get_templates
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_doc_area    IN doc_area.id_doc_area%TYPE,
        i_title_code_msg IN sys_message.code_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR(13 CHAR) := 'GET_TEMPLATES';
        l_id_epis_documentation table_number;
    
        l_cur_templ pk_touch_option_out.t_cur_plain_text_entry;
        l_tbl_templ pk_touch_option_out.t_coll_plain_text_entry;
        l_limit     PLS_INTEGER := 1000;
        l_title     sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'GET epis_documentation ids';
        pk_alertlog.log_debug(g_error);
    
        BEGIN
            SELECT ed.id_epis_documentation
              BULK COLLECT
              INTO l_id_epis_documentation
              FROM epis_documentation ed
             WHERE ed.id_episode = g_prv_enc.id_episode
               AND ed.flg_status = 'A'
               AND ed.id_doc_area = i_id_doc_area;
        END;
    
        IF (l_id_epis_documentation.exists(1))
        THEN
            l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => i_title_code_msg) || ': ';
        
            g_error := 'CALL pk_touch_option_out.get_plain_text_entries.';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                       i_prof                    => i_prof,
                                                       i_epis_documentation_list => l_id_epis_documentation,
                                                       o_entries                 => l_cur_templ);
        
            LOOP
                g_error := 'FETCH TEMPLATES CURSOR';
                pk_alertlog.log_debug(g_error);
                FETCH l_cur_templ BULK COLLECT
                    INTO l_tbl_templ LIMIT l_limit;
            
                FOR i IN 1 .. l_tbl_templ.count
                LOOP
                    IF (i = 1)
                    THEN
                        append_data(i_table => table_clob(g_field_title, l_title || chr(10)));
                    END IF;
                
                    append_data(i_table => table_clob(g_field_record,
                                                      pk_string_utils.clob_to_plsqlvarchar2(l_tbl_templ(i)
                                                                                            .plain_text_entry || chr(10))));
                END LOOP;
                EXIT WHEN l_cur_templ%NOTFOUND;
            END LOOP;
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
                                              'GET_TEMPLATES',
                                              o_error);
        
    END get_templates;

    /**
    * Get subjective.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_flg_show_template  Y-show the HPI and RoS templates in the Subjective and the Physical exam in the Objective. N-Otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2010/01/04
    */
    PROCEDURE get_subjective
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_show_template IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) IS
        l_title       sys_message.desc_message%TYPE;
        l_desc        table_clob := table_clob();
        l_prof        table_number := table_number();
        l_date        table_timestamp_tz := table_timestamp_tz();
        l_group_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'GROUP_NOTE_T003');
        l_count       NUMBER(12) := 0;
        l_title_chk   NUMBER := 0;
        l_error_out   t_error_out;
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM group_note gn
          JOIN pat_group_note pgn
            ON pgn.id_group_note = gn.id_group_note
         WHERE pgn.id_patient = (SELECT ei.id_patient
                                   FROM episode e
                                   JOIN epis_info ei
                                     ON ei.id_episode = e.id_episode
                                  WHERE e.id_episode = g_prv_enc.id_episode)
           AND pgn.id_episode = g_prv_enc.id_episode
           AND pgn.flg_active = pk_alert_constant.g_yes;
    
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T002') || ': ';
    
        g_error := 'OPEN c_epis_recomend';
        OPEN c_epis_recomend(i_episode => g_prv_enc.id_episode, i_type_flg => pk_progress_notes.g_type_subjective);
        FETCH c_epis_recomend BULK COLLECT
            INTO l_desc, l_prof, l_date;
        g_found := c_epis_recomend%FOUND;
        CLOSE c_epis_recomend;
    
        IF l_desc.count > 0
        THEN
            l_title_chk := 1;
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSIF l_count = 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    
        IF (i_flg_show_template = pk_alert_constant.g_yes)
        THEN
            g_error := 'CALL get_templates. id_doc_area: 21. id_episode: ' || g_prv_enc.id_episode;
            pk_alertlog.log_info(text => g_error);
            IF NOT get_templates(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_id_episode     => g_prv_enc.id_episode,
                                 i_id_doc_area    => 21,
                                 i_title_code_msg => 'PREV_EPISODE_T466',
                                 o_error          => l_error_out)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'CALL get_templates. id_doc_area: 22. id_episode: ' || g_prv_enc.id_episode;
            pk_alertlog.log_info(text => g_error);
        
            IF NOT get_templates(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_id_episode     => g_prv_enc.id_episode,
                                 i_id_doc_area    => 22,
                                 i_title_code_msg => 'REVIEW_SYSTEMS_T001',
                                 o_error          => l_error_out)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_count > 0
        THEN
            IF l_title_chk = 0
            THEN
                append_data(i_table => table_clob(g_field_title, l_title));
            END IF;
            append_data(i_table => table_clob(g_field_record, l_group_notes));
        END IF;
    
    END get_subjective;

    /**
    * Get objective.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_flg_show_template  Y-show the HPI and RoS templates in the Subjective and the Physical exam in the Objective. N-Otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2010/01/04
    */
    PROCEDURE get_objective
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_show_template IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) IS
        l_title     sys_message.desc_message%TYPE;
        l_desc      table_clob := table_clob();
        l_prof      table_number := table_number();
        l_date      table_timestamp_tz := table_timestamp_tz();
        l_error_out t_error_out;
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T003') || ': ';
    
        g_error := 'OPEN c_epis_recomend';
        OPEN c_epis_recomend(i_episode => g_prv_enc.id_episode, i_type_flg => pk_progress_notes.g_type_objective);
        FETCH c_epis_recomend BULK COLLECT
            INTO l_desc, l_prof, l_date;
        g_found := c_epis_recomend%FOUND;
        CLOSE c_epis_recomend;
    
        IF l_desc.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    
        IF (i_flg_show_template = pk_alert_constant.g_yes)
        THEN
            g_error := 'CALL get_templates. id_doc_area: 21. id_episode: ' || g_prv_enc.id_episode;
            pk_alertlog.log_info(text => g_error);
            IF NOT get_templates(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_id_episode     => g_prv_enc.id_episode,
                                 i_id_doc_area    => 28,
                                 i_title_code_msg => 'EHR_VIEWER_T004',
                                 o_error          => l_error_out)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    END get_objective;

    /**
    * Get assessment.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2010/01/04
    */
    PROCEDURE get_assessment
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        l_title sys_message.desc_message%TYPE;
        l_desc  table_varchar := table_varchar();
        l_prof  table_number := table_number();
        l_date  table_timestamp_tz := table_timestamp_tz();
        l_error t_error_out;
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T004') || ': ';
    
 /*       g_error := 'OPEN c_epis_recomend';
        OPEN c_epis_recomend(i_episode => g_prv_enc.id_episode, i_type_flg => pk_progress_notes.g_type_assessment);
        FETCH c_epis_recomend BULK COLLECT
            INTO l_desc, l_prof, l_date;
        g_found := c_epis_recomend%FOUND;
        CLOSE c_epis_recomend;
    
        IF l_desc.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;*/
                g_error := 'CALL get_templates. id_doc_area: 36150. id_episode: ' || g_prv_enc.id_episode;
        pk_alertlog.log_info(text => g_error);
        IF NOT get_templates(i_lang           => i_lang,
                             i_prof           => i_prof,
                             i_id_episode     => g_prv_enc.id_episode,
                             i_id_doc_area    => pk_summary_page.g_doc_area_assessment,
                             i_title_code_msg => 'PREV_ENCOUNTER_T004',
                             o_error          => l_error)
        THEN
            RAISE g_exception;
        END IF;
         IF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    END get_assessment;

    /**
    * Get plan.
    *
    * @param i_lang          language identifier
    * @param i_prof          logged professional structure
    * @param i_flg_show_cits Y - Should be shown the CITS info. N- Otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2010/01/04
    */
    PROCEDURE get_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_show_cits IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) IS
        l_flg_sep CONSTANT VARCHAR2(3 CHAR) := ' - ';
        l_sd_dr   CONSTANT sys_domain.code_domain%TYPE := 'DICTATION_REPORT.REPORT_STATUS';
    
        CURSOR c_dict_report IS
            SELECT pk_translation.get_translation(i_lang, wt.code_work_type) || l_flg_sep ||
                   (SELECT pk_sysdomain.get_domain(l_sd_dr, dr.report_status, i_lang)
                      FROM dual) description,
                   dr.id_prof_dictated id_professional,
                   dr.last_update_date dt_change
              FROM dictation_report dr, work_type wt
             WHERE dr.id_episode = g_prv_enc.id_episode
               AND wt.id_work_type(+) = dr.id_work_type
               AND dr.id_work_type = pk_progress_notes.g_dictation_area_plan
            UNION ALL
            SELECT pk_translation.get_translation(i_lang, wt.code_work_type) || l_flg_sep ||
                   (SELECT pk_sysdomain.get_domain(l_sd_dr, drh.report_status, i_lang)
                      FROM dual) description,
                   drh.id_prof_dictated id_professional,
                   drh.last_update_date dt_change
              FROM dictation_report_hist drh, work_type wt
             WHERE drh.id_episode = g_prv_enc.id_episode
               AND wt.id_work_type(+) = drh.id_work_type
               AND drh.id_work_type = pk_progress_notes.g_dictation_area_plan;
    
        r_dict_report c_dict_report%ROWTYPE;
        l_title       sys_message.desc_message%TYPE;
        l_desc        table_varchar := table_varchar();
        l_prof        table_number := table_number();
        l_date        table_timestamp_tz := table_timestamp_tz();
    
        l_cits_descs       table_varchar := table_varchar();
        l_cits_title       table_varchar := table_varchar();
        l_cits_signature   table_varchar := table_varchar();
        l_cits_descs_count PLS_INTEGER;
        l_error            t_error_out;
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T005') || ': ';
    
        -- get standard plan records
    
        g_error := 'CALL get_templates. id_doc_area: 21. id_episode: ' || g_prv_enc.id_episode;
        pk_alertlog.log_info(text => g_error);
        IF NOT get_templates(i_lang           => i_lang,
                             i_prof           => i_prof,
                             i_id_episode     => g_prv_enc.id_episode,
                             i_id_doc_area    => pk_summary_page.g_doc_area_plan,
                             i_title_code_msg => 'PLAN_NOTES_T001',
                             o_error          => l_error)
        THEN
            RAISE g_exception;
        END IF;
        -- get dictation reports in the plan area
        g_error := 'OPEN c_dict_report';
        OPEN c_dict_report;
        FETCH c_dict_report
            INTO r_dict_report;
        g_found := c_dict_report%FOUND;
        CLOSE c_dict_report;
    
        IF g_found
        THEN
            check_dt_change(i_lang      => i_lang,
                            i_prof      => i_prof,
                            i_prof_id   => r_dict_report.id_professional,
                            i_dt_change => r_dict_report.dt_change);
        
            -- append dictation reports to standard plan records
            l_desc := l_desc MULTISET UNION table_varchar(r_dict_report.description);
        END IF;
    
        -- append data
        IF l_desc.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    
        --CITS
        IF (i_flg_show_cits = pk_alert_constant.g_yes)
        THEN
            append_data(i_table => table_clob(g_field_record, ''));
        
            g_error := 'CALL pk_cit.get_cits_by_patient. ';
            pk_alertlog.log_info(g_error);
            IF NOT pk_cit.get_cits_by_patient(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_patient      => pk_episode.get_id_patient(i_episode => g_prv_enc.id_episode),
                                              i_id_episode      => g_prv_enc.id_episode,
                                              i_excluded_status => table_varchar(pk_cit.g_flg_status_canceled,
                                                                                 pk_cit.g_flg_status_concluded,
                                                                                 pk_cit.g_flg_status_expired),
                                              o_cit_desc        => l_cits_descs,
                                              o_cit_title       => l_cits_title,
                                              o_signature       => l_cits_signature,
                                              o_error           => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF (l_cits_descs IS NOT NULL AND l_cits_descs.exists(1))
            THEN
                append_data(i_table => table_clob(g_field_title, l_cits_title(1) || ':' || chr(10)));
            
                l_cits_descs_count := l_cits_descs.count;
            
                FOR i IN 1 .. l_cits_descs_count
                LOOP
                    append_data(i_table => table_clob(g_field_record, l_cits_descs(i)));
                END LOOP;
            END IF;
        END IF;
    END get_plan;

    /**
    * Retrieve encounter medical data.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_flg_show_template  Y-show the HPI and RoS templates in the Subjective and the Physical exam in the Objective. N-Otherwise
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2009/12/23
    */
    FUNCTION get_data_med
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_show_template IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        r_epis         c_epis%ROWTYPE;
        l_blk_info     t_coll_soap_block := t_coll_soap_block();
        l_signature    pk_translation.t_desc_translation;
        l_is_group_app VARCHAR2(1 CHAR);
    BEGIN
        -- get available blocks on previous encounter
        g_error := 'CALL pk_progress_notes_upd.get_freetext_block_info';
        IF NOT pk_progress_notes_upd.get_freetext_block_info(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_episode    => g_prv_enc.id_episode,
                                                             o_soap_block => l_blk_info,
                                                             o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_blk_info IS NULL
           OR l_blk_info.count < 1
        THEN
            -- add no data when no blocks are available
            NULL;
        ELSE
        
            l_is_group_app := pk_grid_amb.is_group_app(i_lang, i_prof, g_prv_enc.id_schedule, g_prv_enc.id_episode);
            IF l_is_group_app = pk_alert_constant.g_yes
            THEN
                -- append medical data header
                append_data(i_table => table_clob(g_field_header,
                                                  pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'EPIS_HISTORY_T006') || ' - ' ||
                                                  pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'SCH_T640')));
            ELSE
                -- append medical data header
                append_data(i_table => table_clob(g_field_header,
                                                  pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'EPIS_HISTORY_T006')));
            END IF;
        
            -- for each available block, retrieve its data
            FOR i IN l_blk_info.first .. l_blk_info.last
            LOOP
                IF l_blk_info(i).flg_type = pk_progress_notes.g_type_reason_visit
                THEN
                    g_error := 'CALL get_reason_for_visit';
                    IF NOT get_reason_for_visit(i_lang => i_lang, i_prof => i_prof, o_error => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                ELSIF l_blk_info(i).flg_type = pk_progress_notes.g_type_subjective
                THEN
                    g_error := 'CALL get_subjective';
                    get_subjective(i_lang => i_lang, i_prof => i_prof, i_flg_show_template => i_flg_show_template);
                ELSIF l_blk_info(i).flg_type = pk_progress_notes.g_type_objective
                THEN
                    g_error := 'CALL get_objective';
                    get_objective(i_lang => i_lang, i_prof => i_prof, i_flg_show_template => i_flg_show_template);
                ELSIF l_blk_info(i).flg_type = pk_progress_notes.g_type_assessment
                THEN
                    g_error := 'CALL get_assessment';
                    get_assessment(i_lang => i_lang, i_prof => i_prof);
                ELSIF l_blk_info(i).flg_type = pk_progress_notes.g_type_plan
                THEN
                    g_error := 'CALL get_plan';
                    get_plan(i_lang => i_lang, i_prof => i_prof, i_flg_show_cits => i_flg_show_template);
                END IF;
            END LOOP;
        
            -- ensure a medical professional and change date are set
            IF g_prv_enc.id_prof_med IS NULL
            THEN
                g_error := 'OPEN c_epis';
                OPEN c_epis;
                FETCH c_epis
                    INTO r_epis;
                CLOSE c_epis;
            
                IF r_epis.id_prof_med IS NOT NULL
                THEN
                    g_prv_enc.id_prof_med   := r_epis.id_prof_med;
                    g_prv_enc.dt_change_med := r_epis.dt_change;
                END IF;
            END IF;
        
            -- append medical data signature
            l_signature := get_signature(i_lang => i_lang, i_prof => i_prof);
            IF l_signature IS NOT NULL
            THEN
                append_data(i_table => table_clob(g_field_signature, l_signature));
            END IF;
        END IF;
    
        RETURN TRUE;
    END get_data_med;

    /**
    * Get ICNP interventions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2009/12/23
    */
    PROCEDURE get_icnp_interv
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        CURSOR c_interv IS
            SELECT pk_icnp.desc_composition(i_lang, iei.id_composition) description,
                   coalesce(iei.id_prof_last_update, iei.id_prof_close, iei.id_prof) id_professional,
                   coalesce(iei.dt_last_update, iei.dt_close_tstz, iei.dt_icnp_epis_interv_tstz) dt_change
              FROM icnp_epis_intervention iei
             WHERE iei.id_episode = g_prv_enc.id_episode
               AND iei.id_episode_destination IS NULL
             ORDER BY dt_change DESC;
    
        l_title sys_message.desc_message%TYPE;
        l_desc  table_varchar := table_varchar();
        l_prof  table_number := table_number();
        l_date  table_timestamp_tz := table_timestamp_tz();
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T012') || ': ';
    
        g_error := 'OPEN c_interv';
        OPEN c_interv;
        FETCH c_interv BULK COLLECT
            INTO l_desc, l_prof, l_date;
        CLOSE c_interv;
    
        IF l_desc.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    END get_icnp_interv;

    /**
    * Get ICNP diagnosis.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2009/12/23
    */
    PROCEDURE get_icnp_diag
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        CURSOR c_diag IS
            SELECT pk_icnp.desc_composition(i_lang, ied.id_composition) description,
                   coalesce(ied.id_prof_last_update, ied.id_prof_close, ied.id_professional) id_professional,
                   coalesce(ied.dt_last_update, ied.dt_close_tstz, ied.dt_icnp_epis_diag_tstz) dt_change
              FROM icnp_epis_diagnosis ied
             WHERE ied.id_episode = g_prv_enc.id_episode
               AND ied.flg_status = pk_alert_constant.g_active
             ORDER BY dt_change DESC;
    
        l_title sys_message.desc_message%TYPE;
        l_desc  table_varchar := table_varchar();
        l_prof  table_number := table_number();
        l_date  table_timestamp_tz := table_timestamp_tz();
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T008') || ': ';
    
        g_error := 'OPEN c_diag';
        OPEN c_diag;
        FETCH c_diag BULK COLLECT
            INTO l_desc, l_prof, l_date;
        CLOSE c_diag;
    
        IF l_desc.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    END get_icnp_diag;

    /**
    * Get nursing notes.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2009/12/23
    */
    PROCEDURE get_nur_notes
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        l_title sys_message.desc_message%TYPE;
        l_desc  table_varchar := table_varchar();
        l_prof  table_number := table_number();
        l_date  table_timestamp_tz := table_timestamp_tz();
    
        CURSOR c_nur_notes(i_episode IN episode.id_episode%TYPE) IS
            SELECT n.notes, n.id_professional, n.change_date
              FROM (SELECT ed.notes notes, ed.id_professional, ed.dt_last_update_tstz change_date
                      FROM epis_documentation ed
                     WHERE ed.id_episode = i_episode
                       AND ed.id_doc_area = pk_summary_page.g_doc_area_nursing_notes
                       AND ed.flg_status = pk_alert_constant.g_active
                    UNION ALL
                    SELECT er.desc_epis_recomend_clob notes, er.id_professional, er.dt_epis_recomend_tstz change_date
                      FROM epis_recomend er
                     WHERE er.id_episode = i_episode
                       AND er.flg_type = pk_discharge.g_type_n
                       AND er.flg_temp != pk_clinical_info.g_flg_hist) n
             ORDER BY n.change_date DESC;
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T006') || ': ';
    
        g_error := 'OPEN c_nur_notes';
        OPEN c_nur_notes(i_episode => g_prv_enc.id_episode);
        FETCH c_nur_notes BULK COLLECT
            INTO l_desc, l_prof, l_date;
        CLOSE c_nur_notes;
    
        IF l_desc.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    END get_nur_notes;

    /**
    * Get vital signs.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_error        error
    *
    * @returns              false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2010/01/05
    */
    FUNCTION get_vital_sign
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_title     sys_message.desc_message%TYPE;
        l_vs_cursor pk_types.cursor_type;
        l_desc      table_varchar := table_varchar();
        l_prof      table_number := table_number();
        l_date      table_timestamp_tz := table_timestamp_tz();
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T007') || ': ';
    
        g_error := 'CALL pk_progress_notes.get_epis_vs_all';
        IF NOT pk_progress_notes.get_epis_vs_all(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => g_prv_enc.id_episode,
                                                 i_order   => 'D',
                                                 o_vs_data => l_vs_cursor,
                                                 o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH l_vs_cursor';
        FETCH l_vs_cursor BULK COLLECT
            INTO l_desc, l_prof, l_date;
        CLOSE l_vs_cursor;
    
        IF l_desc.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    
        RETURN TRUE;
    END get_vital_sign;

    /**
    * Get addendum.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_error        error
    *
    * @returns              false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.6.0
    * @since                2011/10/03
    */
    FUNCTION get_addendum
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_signature             pk_translation.t_desc_translation;
        l_title                 sys_message.desc_message%TYPE;
        l_ad_cursor             pk_types.cursor_type;
        l_id                    table_number := table_number();
        l_id_episode            table_number := table_number();
        l_dt                    table_varchar := table_varchar();
        l_prof_sign             table_varchar := table_varchar();
        l_id_prof               table_number := table_number();
        l_notes                 table_clob := table_clob();
        l_sign_off_dt           table_varchar := table_varchar();
        l_sign_off_prof_sign    table_varchar := table_varchar();
        l_addendum_sign_off_str table_varchar := table_varchar();
        l_flg_status            table_varchar := table_varchar();
        l_cancel_reason_desc    table_varchar := table_varchar();
        l_cancel_notes          table_varchar := table_varchar();
        l_cancel_dt             table_varchar := table_varchar();
        l_cancel_prof_sign      table_varchar := table_varchar();
        l_addendum_cancel_str   table_varchar := table_varchar();
        l_dt_event              table_timestamp_tz := table_timestamp_tz();
        l_rank                  table_number := table_number();
    BEGIN
        --l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'SIGN_OFF_T022') || ': ';
    
        g_error := 'CALL pk_progress_notes.get_epis_vs_all';
        IF NOT pk_sign_off.get_epis_addendums(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_episode   => g_prv_enc.id_episode,
                                              o_addendums => l_ad_cursor,
                                              o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH l_ad_cursor';
        FETCH l_ad_cursor BULK COLLECT
            INTO l_id,
                 l_id_episode,
                 l_dt,
                 l_prof_sign,
                 l_id_prof,
                 l_notes,
                 l_sign_off_dt,
                 l_sign_off_prof_sign,
                 l_addendum_sign_off_str,
                 l_flg_status,
                 l_cancel_reason_desc,
                 l_cancel_notes,
                 l_cancel_dt,
                 l_cancel_prof_sign,
                 l_addendum_cancel_str,
                 l_dt_event,
                 l_rank;
        CLOSE l_ad_cursor;
    
        IF l_id.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            FOR i IN l_id.first .. l_id.last
            LOOP
                IF l_flg_status(i) <> 'C'
                THEN
                    append_data(i_table => table_clob(g_field_record, l_notes(i)));
                    -- append data signature
                    l_signature := l_prof_sign(i) || ' / ' || l_dt(i);
                    IF l_signature IS NOT NULL
                    THEN
                        append_data(i_table => table_clob(g_field_signature, l_signature));
                    END IF;
                END IF;
            END LOOP;
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    
        RETURN TRUE;
    END get_addendum;
    /**
    * Get procedures.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_error        error
    *
    * @returns              false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2010/01/05
    */
    FUNCTION get_procedures
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_title       sys_message.desc_message%TYPE;
        l_proc_cursor pk_types.cursor_type;
        l_desc        table_varchar := table_varchar();
        l_prof        table_number := table_number();
        l_date        table_timestamp_tz := table_timestamp_tz();
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T010') || ': ';
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.GET_PROCEDURE_IN_EPISODE';
        IF NOT pk_procedures_external_api_db.get_procedure_in_episode(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_episode => g_prv_enc.id_episode,
                                                                      i_order   => 'D',
                                                                      o_list    => l_proc_cursor,
                                                                      o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH l_proc_cursor';
        FETCH l_proc_cursor BULK COLLECT
            INTO l_desc, l_prof, l_date;
        CLOSE l_proc_cursor;
    
        IF l_desc.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    
        RETURN TRUE;
    END get_procedures;

    /**
    * Get patient education (aka, teachings).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2010/01/05
    */
    PROCEDURE get_pat_educ
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        CURSOR c_pat_educ IS
            SELECT pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic) description,
                   ntr.id_prof_req id_professional,
                   ntr.dt_nurse_tea_req_tstz date_change
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntr.id_nurse_tea_topic = ntt.id_nurse_tea_topic
             WHERE ntr.id_episode = g_prv_enc.id_episode
               AND ntr.flg_status != pk_alert_constant.g_cancelled
             ORDER BY ntr.dt_nurse_tea_req_tstz DESC;
    
        l_title sys_message.desc_message%TYPE;
        l_desc  table_varchar := table_varchar();
        l_prof  table_number := table_number();
        l_date  table_timestamp_tz := table_timestamp_tz();
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T009') || ': ';
    
        g_error := 'OPEN c_pat_educ';
        OPEN c_pat_educ;
        FETCH c_pat_educ BULK COLLECT
            INTO l_desc, l_prof, l_date;
        CLOSE c_pat_educ;
    
        IF l_desc.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    END get_pat_educ;

    /**
    * Get periodic observations.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_error        error
    *
    * @returns              false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2010/01/05
    */
    FUNCTION get_per_obs
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_title     sys_message.desc_message%TYPE;
        l_po_cursor pk_types.cursor_type;
        l_desc      table_varchar := table_varchar();
        l_prof      table_number := table_number();
        l_date      table_timestamp_tz := table_timestamp_tz();
    BEGIN
        l_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PREV_ENCOUNTER_T013') || ': ';
    
        g_error := 'CALL pk_periodic_observation.get_epis_per_obs';
        -- ALERT-154864
        pk_periodic_observation.get_epis_per_obs(i_lang => i_lang,
                                                 
                                                 i_prof    => i_prof,
                                                 i_episode => g_prv_enc.id_episode,
                                                 o_per_obs => l_po_cursor);
    
        g_error := 'FETCH l_po_cursor';
        FETCH l_po_cursor BULK COLLECT
            INTO l_desc, l_prof, l_date;
        CLOSE l_po_cursor;
    
        IF l_desc.count > 0
        THEN
            append_data(i_table => table_clob(g_field_title, l_title));
        
            check_dt_change(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_prof(1), i_dt_change => l_date(1));
            FOR i IN l_desc.first .. l_desc.last
            LOOP
                append_data(i_table => table_clob(g_field_record, l_desc(i)));
            END LOOP;
        ELSIF check_rep_consumer
        THEN
            NULL;
        ELSE
            append_data(i_table => table_clob(g_field_title, l_title, g_field_record, g_no_data));
        END IF;
    
        RETURN TRUE;
    END get_per_obs;

    /**
    * Retrieve encounter nursing data.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2009/12/23
    */
    FUNCTION get_data_nur
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        r_epis      c_epis%ROWTYPE;
        l_signature pk_translation.t_desc_translation;
    BEGIN
        -- append nursing data header
        append_data(i_table => table_clob(g_field_header,
                                          pk_message.get_message(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_code_mess => 'EPIS_HISTORY_T007')));
    
        g_error := 'CALL get_nur_notes';
        get_nur_notes(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'CALL get_vital_sign';
        IF NOT get_vital_sign(i_lang => i_lang, i_prof => i_prof, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_icnp_diag';
        get_icnp_diag(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'CALL get_pat_educ';
        get_pat_educ(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'CALL get_procedures';
        IF NOT get_procedures(i_lang => i_lang, i_prof => i_prof, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_icnp_interv';
        get_icnp_interv(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'CALL get_per_obs';
        IF NOT get_per_obs(i_lang => i_lang, i_prof => i_prof, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- ensure a nursing professional and change date are set
        IF g_prv_enc.id_prof_nur IS NULL
        THEN
            g_error := 'OPEN c_epis';
            OPEN c_epis;
            FETCH c_epis
                INTO r_epis;
            CLOSE c_epis;
        
            IF r_epis.id_prof_nur IS NOT NULL
            THEN
                g_prv_enc.id_prof_nur   := r_epis.id_prof_nur;
                g_prv_enc.dt_change_nur := r_epis.dt_change;
            END IF;
        END IF;
    
        -- append nursing data signature
        l_signature := get_signature(i_lang => i_lang, i_prof => i_prof, i_force_nur => TRUE);
        IF l_signature IS NOT NULL
        THEN
            append_data(i_table => table_clob(g_field_signature, l_signature));
        END IF;
    
        RETURN TRUE;
    END get_data_nur;

    /**
    * Retrieve addendum data.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Paulo Texeira
    * @version               2.6.1
    * @since                2011/10/03
    */
    FUNCTION get_data_addendum
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- append nursing data header
        append_data(i_table => table_clob(g_field_header,
                                          pk_message.get_message(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_code_mess => 'SIGN_OFF_T022')));
    
        g_error := 'CALL get_vital_sign';
        IF NOT get_addendum(i_lang => i_lang, i_prof => i_prof, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_data_addendum;
    /**
    * Retrieves data for encounter.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_flg_show_template  Y-show the HPI and RoS templates in the Subjective and the Physical exam in the Objective. N-Otherwise
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2009/12/23
    */
    FUNCTION get_data_epis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_show_template IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- episode data is divided in two parts: medical and nursing
        -- all episodes should be checked for nursing data;
        -- yet, only medical appointments should be checked for medical data
        -- 2.6.4.2. added outpatient validation, on outp dashboard ignore medical appointments because thet are visible in a different block
        IF g_prv_enc.id_epis_type != g_epis_nurse
           AND i_prof.software <> pk_alert_constant.g_soft_outpatient
        THEN
            g_error := 'CALL get_data_med';
            IF NOT get_data_med(i_lang              => i_lang,
                                i_prof              => i_prof,
                                i_flg_show_template => i_flg_show_template,
                                o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL get_data_nur';
        IF NOT get_data_nur(i_lang => i_lang, i_prof => i_prof, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF i_prof.software = pk_alert_constant.g_soft_private_practice
        THEN
            g_error := 'CALL get_data_addendum';
            IF NOT get_data_addendum(i_lang => i_lang, i_prof => i_prof, o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    END get_data_epis;

    /**
    * Retrieves data of the cancelled schedule.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    *
    * @author               Pedro Carneiro
    * @version               2.6.0
    * @since                2009/12/23
    */
    PROCEDURE get_data_sched
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        CURSOR c_sched IS
            SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                   s.id_prof_cancel id_professional,
                   s.dt_cancel_tstz
              FROM schedule s
              LEFT JOIN cancel_reason cr
                ON s.id_cancel_reason = cr.id_cancel_reason
             WHERE s.id_schedule = g_prv_enc.id_schedule;
        r_sched        c_sched%ROWTYPE;
        l_header_code  sys_message.code_message%TYPE;
        l_signature    pk_translation.t_desc_translation;
        l_is_group_app VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'OPEN c_sched';
        OPEN c_sched;
        FETCH c_sched
            INTO r_sched;
        g_found := c_sched%FOUND;
        CLOSE c_sched;
    
        IF g_found
        THEN
            check_dt_change(i_lang      => i_lang,
                            i_prof      => i_prof,
                            i_prof_id   => r_sched.id_professional,
                            i_dt_change => r_sched.dt_cancel_tstz);
        
            IF g_prv_enc.id_epis_type = g_epis_nurse
            THEN
                l_header_code := 'EPIS_HISTORY_T007';
            ELSE
                l_header_code := 'EPIS_HISTORY_T006';
            END IF;
        
            l_is_group_app := pk_grid_amb.is_group_app(i_lang, i_prof, g_prv_enc.id_schedule, g_prv_enc.id_episode);
            IF l_is_group_app = pk_alert_constant.g_yes
            THEN
                append_data(i_table => table_clob(g_field_header,
                                                  pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => l_header_code) || ' - ' ||
                                                  pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'SCH_T640'),
                                                  g_field_title,
                                                  pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'PREV_ENCOUNTER_T014') || ': ',
                                                  g_field_record,
                                                  r_sched.cancel_reason));
            ELSE
                append_data(i_table => table_clob(g_field_header,
                                                  pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => l_header_code),
                                                  g_field_title,
                                                  pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'PREV_ENCOUNTER_T014') || ': ',
                                                  g_field_record,
                                                  r_sched.cancel_reason));
            END IF;
            l_signature := get_signature(i_lang => i_lang, i_prof => i_prof);
            IF l_signature IS NOT NULL
            THEN
                append_data(i_table => table_clob(g_field_signature, l_signature));
            END IF;
        
        END IF;
    END get_data_sched;

    /**
    * Retrieves data for encounter. Sets it to the global variable g_prv_enc.
    *
    * @param i_lang          language identifier
    * @param i_prof          logged professional structure
    * @param i_episode       episode identifier
    * @param i_schedule      schedule identifier
    * @param i_epis_type     episode type identifier
    * @param i_flg_show_template  Y-show the HPI and RoS templates in the Subjective and the Physical exam in the Objective. N-Otherwise
    * @param o_error         error
    *
    * @return                false if errors occur, true otherwise
    *
    * @author                Pedro Carneiro
    * @version                2.6.0
    * @since                 2009/12/23
    */
    FUNCTION get_data
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_schedule          IN schedule.id_schedule%TYPE,
        i_epis_type         IN epis_type.id_epis_type%TYPE,
        i_flg_show_template IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        reset_var;
    
        g_prv_enc.id_episode   := i_episode;
        g_prv_enc.id_schedule  := i_schedule;
        g_prv_enc.id_epis_type := i_epis_type;
    
        IF i_episode IS NULL
        THEN
            -- retrieve data for a cancelled schedule
            g_error := 'CALL get_data_sched';
            get_data_sched(i_lang => i_lang, i_prof => i_prof);
        ELSE
            -- retrieve data for a normal episode
            g_error := 'CALL get_data_epis';
            IF NOT get_data_epis(i_lang              => i_lang,
                                 i_prof              => i_prof,
                                 i_flg_show_template => i_flg_show_template,
                                 o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    END get_data;

    /**
    * Retrieves detail data for encounter. Sets it to the global variable g_prv_enc.
    *
    * @param i_lang          language identifier
    * @param i_prof          logged professional structure
    * @param i_episode       episode identifier
    * @param i_schedule      schedule identifier
    * @param i_epis_type     episode type identifier
    * @param o_error         error
    *
    * @return                false if errors occur, true otherwise
    *
    * @author                Pedro Carneiro
    * @version                2.6.0
    * @since                 2009/12/23
    */
    FUNCTION get_data_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_schedule  IN schedule.id_schedule%TYPE,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        reset_var;
    
        g_prv_enc.id_episode   := i_episode;
        g_prv_enc.id_schedule  := i_schedule;
        g_prv_enc.id_epis_type := i_epis_type;
    
        IF i_episode IS NULL
        THEN
            -- retrieve data for a cancelled schedule
            g_error := 'CALL get_data_sched';
            get_data_sched(i_lang => i_lang, i_prof => i_prof);
        ELSE
            -- retrieve data for a normal episode
            -- which consists in nursing information only
            g_error := 'CALL get_data_nur';
            IF NOT get_data_nur(i_lang => i_lang, i_prof => i_prof, o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    END get_data_det;

    /**
    * Retrieve summarized descriptions on all previous encounters.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param i_flg_type     {*} 'A' All Specialities {*} 'M' With me {*} 'S' My speciality    
    * @param o_enc_info     previous contacts descriptions
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2009/04/27
    *
    * @dependents           PK_PATIENT_SUMMARY.get_amb_dashboard 
    */
    FUNCTION get_prev_enc_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2 DEFAULT 'A',
        o_enc_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_doctor_icon   sys_domain.img_name%TYPE;
        l_nurse_icon    sys_domain.img_name%TYPE;
        l_epis_type     epis_type.id_epis_type%TYPE;
        l_hand_off_type sys_config.value%TYPE;
        l_prof_cat      category.flg_type%TYPE;
        l_show_cancel   sys_config.value%TYPE;
    BEGIN
        l_epis_type   := pk_sysconfig.get_config(i_code_cf => 'EPIS_TYPE', i_prof => i_prof);
        g_epis_nurse  := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => i_prof);
        l_doctor_icon := pk_sysdomain.get_img(i_lang => i_lang, i_code_dom => 'SCHEDULE_OUTP.FLG_STATE', i_val => 'T');
        l_nurse_icon  := pk_sysdomain.get_img(i_lang => i_lang, i_code_dom => 'SCHEDULE_OUTP.FLG_STATE', i_val => 'N');
        l_show_cancel := pk_sysconfig.get_config(i_code_cf => 'DASHBOARD_SHOW_CANCEL_INFO', i_prof => i_prof);
    
        IF i_flg_type = g_flg_type_m
        THEN
            -- consults with me
            g_error := 'GET CONFIGURATIONS';
            pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
            l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
        
            g_error := 'OPEN o_enc_info with me';
            OPEN o_enc_info FOR
                SELECT t.id_episode,
                       t.id_schedule,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_enc, i_prof) dt_begin,
                       t.clinical_service,
                       (SELECT pk_translation.get_translation(i_lang, g_et_code || t.id_epis_type)
                          FROM dual) episode_type,
                       pk_tools.get_prof_description(i_lang, i_prof, t.id_professional, t.dt_enc, t.id_episode) prof,
                       decode(t.id_epis_type, l_epis_type, l_doctor_icon, g_epis_nurse, l_nurse_icon, l_doctor_icon) icon_name,
                       g_schortcut_prev_episode shortcut,
                       t.flg_status,
                       decode(t.id_epis_type, l_epis_type, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_nurse,
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_enc, i_prof) dt_begin_day,
                       t.id_report
                  FROM (SELECT NULL id_schedule,
                               e.id_episode,
                               e.dt_begin_tstz dt_enc,
                               pk_episode.get_cs_desc(i_lang, i_prof, e.id_episode) clinical_service,
                               e.id_epis_type,
                               e.flg_status,
                               nvl(decode(e.id_epis_type, g_epis_nurse, ei.id_first_nurse_resp, ei.id_professional),
                                   ei.sch_prof_outp_id_prof) id_professional,
                               pk_sysconfig.get_config(g_sys_config_report, i_prof.institution, ei.id_software) id_report
                          FROM episode e
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         WHERE e.id_patient = i_patient
                           AND e.id_epis_type IN (l_epis_type, g_epis_nurse)
                           AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                           AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
                           AND e.id_institution = i_prof.institution
                           AND i_prof.id IN
                               (SELECT column_value
                                  FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                                  i_prof,
                                                                                  e.id_episode,
                                                                                  l_prof_cat,
                                                                                  l_hand_off_type)))
                        UNION ALL
                        SELECT s.id_schedule,
                               NULL id_episode,
                               sp.dt_target_tstz dt_enc,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, s.id_dcs_requested) clinical_service,
                               sp.id_epis_type,
                               s.flg_status,
                               spo.id_professional,
                               pk_sysconfig.get_config(g_sys_config_report, i_prof.institution, sp.id_software) id_report
                          FROM schedule s
                          JOIN schedule_outp sp
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON s.id_schedule = sg.id_schedule
                          LEFT JOIN sch_prof_outp spo
                            ON sp.id_schedule_outp = spo.id_schedule_outp
                         WHERE sg.id_patient = i_patient
                           AND s.flg_status = pk_alert_constant.g_cancelled
                           AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                           AND sp.id_epis_type IN (l_epis_type, g_epis_nurse)
                           AND s.id_instit_requested = i_prof.institution
                           AND spo.id_professional = i_prof.id
                           AND l_show_cancel = pk_alert_constant.g_yes) t
                 ORDER BY t.dt_enc DESC;
        ELSIF i_flg_type = g_flg_type_s
        THEN
            -- consults of my speciality
            g_error := 'OPEN o_enc_info my speciality';
            OPEN o_enc_info FOR
                SELECT t.id_episode,
                       t.id_schedule,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_enc, i_prof) dt_begin,
                       t.clinical_service,
                       (SELECT pk_translation.get_translation(i_lang, g_et_code || t.id_epis_type)
                          FROM dual) episode_type,
                       pk_tools.get_prof_description(i_lang, i_prof, t.id_professional, t.dt_enc, t.id_episode) prof,
                       decode(t.id_epis_type, l_epis_type, l_doctor_icon, g_epis_nurse, l_nurse_icon, l_doctor_icon) icon_name,
                       g_schortcut_prev_episode shortcut,
                       t.flg_status,
                       decode(t.id_epis_type, l_epis_type, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_nurse,
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_enc, i_prof) dt_begin_day,
                       t.id_report
                  FROM (SELECT NULL id_schedule,
                               e.id_episode,
                               e.dt_begin_tstz dt_enc,
                               pk_episode.get_cs_desc(i_lang, i_prof, e.id_episode) clinical_service,
                               e.id_epis_type,
                               e.flg_status,
                               nvl(decode(e.id_epis_type, g_epis_nurse, ei.id_first_nurse_resp, ei.id_professional),
                                   ei.sch_prof_outp_id_prof) id_professional,
                               pk_sysconfig.get_config(g_sys_config_report, i_prof.institution, ei.id_software) id_report
                          FROM episode e
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         WHERE e.id_patient = i_patient
                           AND e.id_epis_type IN (l_epis_type, g_epis_nurse)
                           AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                           AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
                           AND e.id_institution = i_prof.institution
                           AND e.id_clinical_service = (SELECT epis.id_clinical_service
                                                          FROM episode epis
                                                         WHERE epis.id_episode = i_episode)
                        UNION ALL
                        SELECT s.id_schedule,
                               NULL id_episode,
                               sp.dt_target_tstz dt_enc,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, s.id_dcs_requested) clinical_service,
                               sp.id_epis_type,
                               s.flg_status,
                               spo.id_professional,
                               pk_sysconfig.get_config(g_sys_config_report, i_prof.institution, sp.id_software) id_report
                          FROM schedule s
                          JOIN schedule_outp sp
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON s.id_schedule = sg.id_schedule
                          LEFT JOIN sch_prof_outp spo
                            ON sp.id_schedule_outp = spo.id_schedule_outp
                         WHERE sg.id_patient = i_patient
                           AND s.flg_status = pk_alert_constant.g_cancelled
                           AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                           AND sp.id_epis_type IN (l_epis_type, g_epis_nurse)
                           AND s.id_instit_requested = i_prof.institution
                           AND s.id_dcs_requested = (SELECT ei.id_dep_clin_serv
                                                       FROM epis_info ei
                                                      WHERE ei.id_episode = i_episode)
                           AND l_show_cancel = pk_alert_constant.g_yes) t
                 ORDER BY t.dt_enc DESC;
        ELSE
            -- all appointments
            g_error := 'OPEN o_enc_info all';
            OPEN o_enc_info FOR
                SELECT t.id_episode,
                       t.id_schedule,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_enc, i_prof) dt_begin,
                       t.clinical_service,
                       (SELECT pk_translation.get_translation(i_lang, g_et_code || t.id_epis_type)
                          FROM dual) episode_type,
                       pk_tools.get_prof_description(i_lang, i_prof, t.id_professional, t.dt_enc, t.id_episode) prof,
                       decode(t.id_epis_type, l_epis_type, l_doctor_icon, g_epis_nurse, l_nurse_icon, l_doctor_icon) icon_name,
                       g_schortcut_prev_episode shortcut,
                       t.flg_status,
                       decode(t.id_epis_type, l_epis_type, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_nurse,
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_enc, i_prof) dt_begin_day,
                       t.id_report
                  FROM (SELECT NULL id_schedule,
                               e.id_episode,
                               e.dt_begin_tstz dt_enc,
                               pk_episode.get_cs_desc(i_lang, i_prof, e.id_episode) clinical_service,
                               e.id_epis_type,
                               e.flg_status,
                               nvl(decode(e.id_epis_type, g_epis_nurse, ei.id_first_nurse_resp, ei.id_professional),
                                   ei.sch_prof_outp_id_prof) id_professional,
                               pk_sysconfig.get_config(g_sys_config_report, i_prof.institution, ei.id_software) id_report
                          FROM episode e
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         WHERE e.id_patient = i_patient
                           AND e.id_epis_type IN (l_epis_type, g_epis_nurse)
                           AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                           AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
                           AND e.id_institution = i_prof.institution
                        UNION ALL
                        SELECT s.id_schedule,
                               NULL id_episode,
                               sp.dt_target_tstz dt_enc,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, s.id_dcs_requested) clinical_service,
                               sp.id_epis_type,
                               s.flg_status,
                               spo.id_professional,
                               pk_sysconfig.get_config(g_sys_config_report, i_prof.institution, sp.id_software) id_report
                          FROM schedule s
                          JOIN schedule_outp sp
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON s.id_schedule = sg.id_schedule
                          LEFT JOIN sch_prof_outp spo
                            ON sp.id_schedule_outp = spo.id_schedule_outp
                         WHERE sg.id_patient = i_patient
                           AND s.flg_status = pk_alert_constant.g_cancelled
                           AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                           AND sp.id_epis_type IN (l_epis_type, g_epis_nurse)
                           AND s.id_instit_requested = i_prof.institution
                           AND l_show_cancel = pk_alert_constant.g_yes) t
                 ORDER BY t.dt_enc DESC;
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
                                              i_function => 'GET_PREV_ENC_INFO',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prev_enc_info;

    /********************************************************************************************
    * Function to return the previous visits of a patient
    *
    * @param   i_lang        Language ID
    * @param   i_prof        Professional's details
    * @param   i_patient     ID patient
    * @param   i_episode     ID episode
    * @param   i_flg_type    type of visits M - My ; S - My speciality; A - All
    *
    * @return                True or False
    *
    * @author                Elisabete Bugalho
    * @version               2.6.2
    * @since                 2012/04/03   
    ********************************************************************************************/
    FUNCTION get_prev_visits
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2 DEFAULT 'A',
        o_enc_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hand_off_type sys_config.value%TYPE;
        l_prof_cat      category.flg_type%TYPE;
    
    BEGIN
        g_epis_nurse := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => i_prof);
    
        IF i_flg_type = g_flg_type_m
        THEN
            -- consults with me
            g_error := 'GET CONFIGURATIONS';
            pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
            l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
        
            g_error := 'OPEN o_enc_info with me';
            OPEN o_enc_info FOR
                SELECT t.id_episode,
                       t.id_schedule,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_enc, i_prof) dt_begin,
                       t.clinical_service,
                       (SELECT pk_translation.get_translation(i_lang, g_et_code || t.id_epis_type)
                          FROM dual) episode_type,
                       pk_tools.get_prof_description(i_lang, i_prof, t.id_professional, t.dt_enc, t.id_episode) prof,
                       (SELECT pk_translation.get_translation(i_lang, g_et_code_icon || t.id_epis_type)
                          FROM dual) icon_name,
                       g_schortcut_prev_episode shortcut,
                       t.flg_status,
                       decode(t.id_epis_type, g_epis_nurse, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_nurse,
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_enc, i_prof) dt_begin_day
                  FROM (SELECT NULL id_schedule,
                               e.id_episode,
                               e.dt_begin_tstz dt_enc,
                               get_visit_type_epis(i_lang, i_prof, ei.id_episode, e.id_epis_type) clinical_service,
                               e.id_epis_type,
                               e.flg_status,
                               nvl(decode(e.id_epis_type, g_epis_nurse, ei.id_first_nurse_resp, ei.id_professional),
                                   ei.sch_prof_outp_id_prof) id_professional
                          FROM episode e
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         WHERE e.id_patient = i_patient
                              --   AND e.id_epis_type IN (l_epis_type, g_epis_nurse)
                           AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                           AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
                           AND e.id_institution = i_prof.institution
                           AND i_prof.id IN
                               (SELECT column_value
                                  FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                                  i_prof,
                                                                                  e.id_episode,
                                                                                  l_prof_cat,
                                                                                  l_hand_off_type)))) t
                 ORDER BY t.dt_enc DESC;
        ELSIF i_flg_type = g_flg_type_s
        THEN
            -- consults of my speciality
            g_error := 'OPEN o_enc_info my speciality';
            OPEN o_enc_info FOR
                SELECT t.id_episode,
                       t.id_schedule,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_enc, i_prof) dt_begin,
                       t.clinical_service,
                       (SELECT pk_translation.get_translation(i_lang, g_et_code || t.id_epis_type)
                          FROM dual) episode_type,
                       pk_tools.get_prof_description(i_lang, i_prof, t.id_professional, t.dt_enc, t.id_episode) prof,
                       (SELECT pk_translation.get_translation(i_lang, g_et_code_icon || t.id_epis_type)
                          FROM dual) icon_name,
                       g_schortcut_prev_episode shortcut,
                       t.flg_status,
                       decode(t.id_epis_type, g_epis_nurse, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_nurse,
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_enc, i_prof) dt_begin_day
                  FROM (SELECT NULL id_schedule,
                               e.id_episode,
                               e.dt_begin_tstz dt_enc,
                               get_visit_type_epis(i_lang, i_prof, ei.id_episode, e.id_epis_type) clinical_service,
                               e.id_epis_type,
                               e.flg_status,
                               nvl(decode(e.id_epis_type, g_epis_nurse, ei.id_first_nurse_resp, ei.id_professional),
                                   ei.sch_prof_outp_id_prof) id_professional
                          FROM episode e
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         WHERE e.id_patient = i_patient
                           AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                           AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
                           AND e.id_institution = i_prof.institution
                           AND e.id_clinical_service = (SELECT epis.id_clinical_service
                                                          FROM episode epis
                                                         WHERE epis.id_episode = i_episode)) t
                 ORDER BY t.dt_enc DESC;
        ELSE
            -- all appointments
            g_error := 'OPEN o_enc_info all';
            OPEN o_enc_info FOR
                SELECT t.id_episode,
                       t.id_schedule,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_enc, i_prof) dt_begin,
                       t.clinical_service,
                       (SELECT pk_translation.get_translation(i_lang, g_et_code || t.id_epis_type)
                          FROM dual) episode_type,
                       pk_tools.get_prof_description(i_lang, i_prof, t.id_professional, t.dt_enc, t.id_episode) prof,
                       (SELECT pk_translation.get_translation(i_lang, g_et_code_icon || t.id_epis_type)
                          FROM dual) icon_name,
                       g_schortcut_prev_episode shortcut,
                       t.flg_status,
                       decode(t.id_epis_type, g_epis_nurse, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                       
                       flg_nurse,
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_enc, i_prof) dt_begin_day
                  FROM (SELECT NULL id_schedule,
                               e.id_episode,
                               e.dt_begin_tstz dt_enc,
                               get_visit_type_epis(i_lang, i_prof, ei.id_episode, e.id_epis_type) clinical_service,
                               e.id_epis_type,
                               e.flg_status,
                               nvl(decode(e.id_epis_type, g_epis_nurse, ei.id_first_nurse_resp, ei.id_professional),
                                   ei.sch_prof_outp_id_prof) id_professional
                          FROM episode e
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         WHERE e.id_patient = i_patient
                           AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                           AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
                           AND e.id_institution = i_prof.institution
                           AND e.id_epis_type != pk_alert_constant.g_hhc_epis_type) t
                 ORDER BY t.dt_enc DESC;
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
                                              i_function => 'GET_PREV_VISITS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prev_visits;

    /**
    * Retrieve summarized info on all previous encounters.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param o_enc_info     previous encounters info
    * @param o_enc_data     previous encounters data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2009/03/31
    */
    FUNCTION get_prev_encounter
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_enc_info OUT pk_types.cursor_type,
        o_enc_data OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_schedule  table_number := table_number();
        l_id_episode   table_number := table_number();
        l_id_epis_type table_number := table_number();
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_encounters   t_coll_prev_encounter := t_coll_prev_encounter();
        l_show_cancel  sys_config.value%TYPE;
        l_owner        all_objects.owner%TYPE;
        l_line         NUMBER;
        l_type         user_objects.object_type%TYPE;
    
        CURSOR c_encounters IS
            SELECT NULL id_schedule, e.id_episode, e.id_epis_type
              FROM episode e
              JOIN epis_info ei
                ON e.id_episode = ei.id_episode
             WHERE e.id_patient = i_patient
               AND e.id_epis_type IN (l_epis_type, g_epis_nurse)
               AND e.flg_status = pk_alert_constant.g_epis_status_inactive
               AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
               AND e.id_institution = i_prof.institution
            UNION ALL
            SELECT s.id_schedule, NULL id_episode, sp.id_epis_type
              FROM schedule s
              JOIN schedule_outp sp
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
             WHERE sg.id_patient = i_patient
               AND s.flg_status = pk_alert_constant.g_cancelled
               AND sp.id_epis_type IN (l_epis_type, g_epis_nurse)
               AND s.id_instit_requested = i_prof.institution
               AND l_show_cancel = pk_alert_constant.g_yes;
    
    BEGIN
    
        l_epis_type   := pk_sysconfig.get_config(i_code_cf => 'EPIS_TYPE', i_prof => i_prof);
        g_epis_nurse  := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => i_prof);
        l_show_cancel := pk_sysconfig.get_config(i_code_cf => 'DASHBOARD_SHOW_CANCEL_INFO', i_prof => i_prof);
    
        -- get previous encounters info
        g_error := 'CALL get_prev_enc_info';
        IF NOT get_prev_enc_info(i_lang     => i_lang,
                                 i_prof     => i_prof,
                                 i_patient  => i_patient,
                                 i_episode  => i_episode,
                                 i_flg_type => NULL,
                                 o_enc_info => o_enc_info,
                                 o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- get previous encounters id's
        g_error := 'OPEN c_encounters';
        OPEN c_encounters;
        FETCH c_encounters BULK COLLECT
            INTO l_id_schedule, l_id_episode, l_id_epis_type;
        CLOSE c_encounters;
    
        IF l_id_epis_type.count > 0
        THEN
            g_error := 'CALL get_data';
            FOR i IN l_id_epis_type.first .. l_id_epis_type.last
            LOOP
                IF NOT get_data(i_lang      => i_lang,
                                i_prof      => i_prof,
                                i_episode   => l_id_episode(i),
                                i_schedule  => l_id_schedule(i),
                                i_epis_type => l_id_epis_type(i),
                                o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                l_encounters.extend;
                l_encounters(i) := g_prv_enc;
            END LOOP;
        END IF;
    
        g_error := 'OPEN o_enc_data';
        OPEN o_enc_data FOR
            SELECT /*+opt_estimate(table t rows=1)*/
             t.id_episode,
             t.id_schedule,
             t.id_epis_type,
             t.enc_data,
             decode(t.id_prof_med,
                    NULL,
                    NULL,
                    pk_tools.get_prof_description(i_lang, i_prof, t.id_prof_med, t.dt_change_med, t.id_episode) || ' / ' ||
                    pk_date_utils.date_char_tsz(i_lang, t.dt_change_med, i_prof.institution, i_prof.software)) prof_med,
             decode(t.id_prof_nur,
                    NULL,
                    NULL,
                    pk_tools.get_prof_description(i_lang, i_prof, t.id_prof_nur, t.dt_change_nur, t.id_episode) || ' / ' ||
                    pk_date_utils.date_char_tsz(i_lang, t.dt_change_nur, i_prof.institution, i_prof.software)) prof_nur,
             pk_date_utils.dt_chr_tsz(i_lang, decode(t.id_episode, NULL, sp.dt_target_tstz, e.dt_begin_tstz), i_prof) dt_begin,
             t.id_epis_type viewer_category,
             (SELECT pk_translation.get_translation(i_lang, g_et_code || t.id_epis_type)
                FROM dual) viewer_category_desc,
             nvl(t.id_prof_med, t.id_prof_nur) viewer_id_prof,
             pk_date_utils.date_send_tsz(i_lang, decode(t.id_episode, NULL, sp.dt_target_tstz, e.dt_begin_tstz), i_prof) viewer_date,
             CASE
                  WHEN se.flg_is_group = pk_alert_constant.g_yes THEN
                   pk_alert_constant.g_yes
                  ELSE
                   pk_alert_constant.g_no
              END flg_group_app
              FROM TABLE(l_encounters) t
              LEFT JOIN episode e
                ON t.id_episode = e.id_episode
              LEFT JOIN schedule_outp sp
                ON t.id_schedule = sp.id_schedule
              LEFT JOIN epis_info ei
                ON ei.id_episode = e.id_episode
              LEFT JOIN schedule s
                ON ei.id_schedule = s.id_schedule
              LEFT JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
             ORDER BY decode(t.id_episode, NULL, sp.dt_target_tstz, e.dt_begin_tstz) DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PREV_ENCOUNTER',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prev_encounter;

    /**
    * Retrieve detailed info on previous encounter.
    * Information is SOAP oriented.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param o_soap_blocks  soap blocks
    * @param o_data_blocks  data blocks
    * @param o_simple_text  simple text blocks structure
    * @param o_doc_reg      documentation registers
    * @param o_doc_val      documentation values
    * @param o_free_text    free text records
    * @param o_rea_visit    reason for visit records
    * @param o_app_type     appointment type
    * @param o_prof_rec     author and date of last change
    * @param o_nur_data     previous encounter nursing data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5
    * @since                2010/12/20
    */
    FUNCTION get_prev_encounter_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_soap_blocks OUT pk_types.cursor_type,
        o_data_blocks OUT pk_types.cursor_type,
        o_simple_text OUT pk_types.cursor_type,
        o_doc_reg     OUT pk_types.cursor_type,
        o_doc_val     OUT pk_types.cursor_type,
        o_free_text   OUT pk_types.cursor_type,
        o_rea_visit   OUT pk_types.cursor_type,
        o_app_type    OUT pk_types.cursor_type,
        o_prof_rec    OUT pk_translation.t_desc_translation,
        o_nur_data    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type epis_type.id_epis_type%TYPE;
    BEGIN
        g_epis_nurse := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => i_prof);
        l_epis_type  := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_episode);
    
        IF l_epis_type = g_epis_nurse
        THEN
            -- when detailing a nursing appointment, show no SOAP data
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_types.open_my_cursor(o_nur_data);
        ELSE
            g_error := 'CALL pk_progress_notes_upd.get_prog_notes_blocks_no_btn';
            IF NOT pk_progress_notes_upd.get_prog_notes_blocks_no_btn(i_lang        => i_lang,
                                                                      i_prof        => i_prof,
                                                                      i_patient     => i_patient,
                                                                      i_episode     => i_episode,
                                                                      o_soap_blocks => o_soap_blocks,
                                                                      o_data_blocks => o_data_blocks,
                                                                      o_simple_text => o_simple_text,
                                                                      o_doc_reg     => o_doc_reg,
                                                                      o_doc_val     => o_doc_val,
                                                                      o_free_text   => o_free_text,
                                                                      o_rea_visit   => o_rea_visit,
                                                                      o_app_type    => o_app_type,
                                                                      o_prof_rec    => o_prof_rec,
                                                                      o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'CALL get_data_det';
        IF NOT get_data_det(i_lang      => i_lang,
                            i_prof      => i_prof,
                            i_episode   => i_episode,
                            i_schedule  => NULL,
                            i_epis_type => l_epis_type,
                            o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_nur_data';
        OPEN o_nur_data FOR
            SELECT /*+opt_estimate(table t rows=1)*/
             t.id_episode,
             t.id_schedule,
             t.id_epis_type,
             t.enc_data,
             NULL prof_med,
             pk_tools.get_prof_description(i_lang, i_prof, t.id_prof_nur, t.dt_change_nur, t.id_episode) || ' / ' ||
             pk_date_utils.date_char_tsz(i_lang, t.dt_change_nur, i_prof.institution, i_prof.software) prof_nur,
             pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_begin
              FROM TABLE(t_coll_prev_encounter(g_prv_enc)) t
              JOIN episode e
                ON t.id_episode = e.id_episode;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PREV_ENCOUNTER_DET',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_types.open_my_cursor(o_nur_data);
            RETURN FALSE;
    END get_prev_encounter_det;

    /**
    * Retrieve summarized info on the last encounter.
    * If the last encounter was cancelled, then it should also be presented.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param o_enc_data     previous encounters data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2009/03/31
    *
    * @dependents           PK_PATIENT_SUMMARY.get_amb_dashboard 
    */
    FUNCTION get_last_encounter
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_enc_data OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type     epis_type.id_epis_type%TYPE;
        l_encounters    t_coll_prev_encounter := t_coll_prev_encounter();
        l_epis_found    BOOLEAN := FALSE;
        l_sched_found   BOOLEAN := FALSE;
        l_hand_off_type sys_config.value%TYPE;
        l_prof_cat      category.flg_type%TYPE;
        l_filter        sys_config.value%TYPE;
        l_show_cancel   sys_config.value%TYPE;
    
        CURSOR c_last_epis IS
            SELECT e.id_episode, e.id_epis_type, e.dt_begin_tstz
              FROM episode e
             WHERE e.id_patient = i_patient
               AND id_epis_type IN (l_epis_type, g_epis_nurse)
               AND e.flg_status = pk_alert_constant.g_epis_status_inactive
               AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
               AND e.id_institution = i_prof.institution
             ORDER BY e.dt_begin_tstz DESC;
    
        CURSOR c_last_epis_me IS
            SELECT e.id_episode, e.id_epis_type, e.dt_begin_tstz
              FROM episode e
             WHERE e.id_patient = i_patient
               AND id_epis_type IN (l_epis_type, g_epis_nurse)
               AND e.flg_status = pk_alert_constant.g_epis_status_inactive
               AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
               AND e.id_institution = i_prof.institution
               AND i_prof.id IN (SELECT column_value
                                   FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                                   i_prof,
                                                                                   id_episode,
                                                                                   l_prof_cat,
                                                                                   l_hand_off_type)))
             ORDER BY e.dt_begin_tstz DESC;
    
        CURSOR c_last_epis_type IS
            SELECT e.id_episode, e.id_epis_type, e.dt_begin_tstz
              FROM episode e
             WHERE e.id_patient = i_patient
               AND id_epis_type IN (l_epis_type, g_epis_nurse)
               AND e.flg_status = pk_alert_constant.g_epis_status_inactive
               AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
               AND e.id_institution = i_prof.institution
               AND e.id_clinical_service = (SELECT epis.id_clinical_service
                                              FROM episode epis
                                             WHERE epis.id_episode = i_episode)
             ORDER BY e.dt_begin_tstz DESC;
    
        CURSOR c_last_sched IS
            SELECT s.id_schedule, sp.id_epis_type, sp.dt_target_tstz
              FROM schedule s
              JOIN schedule_outp sp
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
             WHERE sg.id_patient = i_patient
               AND s.flg_status = pk_alert_constant.g_cancelled
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND sp.id_epis_type IN (l_epis_type, g_epis_nurse)
               AND s.id_instit_requested = i_prof.institution
             ORDER BY sp.dt_target_tstz DESC;
    
        r_last_epis  c_last_epis%ROWTYPE;
        r_last_sched c_last_sched%ROWTYPE;
    BEGIN
        l_epis_type  := pk_sysconfig.get_config(i_code_cf => 'EPIS_TYPE', i_prof => i_prof);
        g_epis_nurse := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => i_prof);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_prof_cat    := pk_prof_utils.get_category(i_lang, i_prof);
        l_filter      := pk_sysconfig.get_config(i_code_cf => 'DASHBOARD_LAST_CONSULT_FILTER', i_prof => i_prof);
        l_show_cancel := pk_sysconfig.get_config(i_code_cf => 'DASHBOARD_SHOW_CANCEL_INFO', i_prof => i_prof);
    
        -- retrieve last episode
        IF l_filter = pk_alert_constant.g_yes -- Filter the last contact
        THEN
            -- with me
            g_error := 'OPEN c_last_epis_me';
            OPEN c_last_epis_me;
            FETCH c_last_epis_me
                INTO r_last_epis;
            l_epis_found := c_last_epis_me%FOUND;
            CLOSE c_last_epis_me;
        
            IF NOT l_epis_found
            THEN
                -- this type of consult
                g_error := 'OPEN c_last_epis_type';
                OPEN c_last_epis_type;
                FETCH c_last_epis_type
                    INTO r_last_epis;
                l_epis_found := c_last_epis_type%FOUND;
                CLOSE c_last_epis_type;
            
                IF NOT l_epis_found
                THEN
                    -- last consult in institution
                    g_error := 'OPEN c_last_epis I';
                    OPEN c_last_epis;
                    FETCH c_last_epis
                        INTO r_last_epis;
                    l_epis_found := c_last_epis%FOUND;
                    CLOSE c_last_epis;
                END IF;
            END IF;
        ELSE
            -- use no filter
            g_error := 'OPEN c_last_epis II';
            OPEN c_last_epis;
            FETCH c_last_epis
                INTO r_last_epis;
            l_epis_found := c_last_epis%FOUND;
            CLOSE c_last_epis;
        END IF;
    
        IF l_show_cancel = pk_alert_constant.g_yes
        THEN
            -- retrieve last cancelled schedule
            g_error := 'OPEN c_last_sched';
            OPEN c_last_sched;
            FETCH c_last_sched
                INTO r_last_sched;
            l_sched_found := c_last_sched%FOUND;
            CLOSE c_last_sched;
        END IF;
    
        IF l_epis_found
        THEN
            -- have episode? get data for it
            g_error := 'CALL get_data - episode';
            IF NOT get_data(i_lang              => i_lang,
                            i_prof              => i_prof,
                            i_episode           => r_last_epis.id_episode,
                            i_schedule          => NULL,
                            i_epis_type         => r_last_epis.id_epis_type,
                            i_flg_show_template => pk_alert_constant.g_yes,
                            o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_encounters.extend;
            l_encounters(1) := g_prv_enc;
        
            -- if a more recent schedule exists, show it as well
            IF l_sched_found
               AND r_last_sched.dt_target_tstz > r_last_epis.dt_begin_tstz
            THEN
                g_error := 'CALL get_data - schedule';
                IF NOT get_data(i_lang              => i_lang,
                                i_prof              => i_prof,
                                i_episode           => NULL,
                                i_schedule          => r_last_sched.id_schedule,
                                i_epis_type         => r_last_sched.id_epis_type,
                                i_flg_show_template => pk_alert_constant.g_yes,
                                o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                l_encounters.extend;
                l_encounters(2) := g_prv_enc;
            END IF;
        ELSIF l_sched_found
        THEN
            -- only a schedule exists? show it
            g_error := 'CALL get_data - schedule';
            IF NOT get_data(i_lang              => i_lang,
                            i_prof              => i_prof,
                            i_episode           => NULL,
                            i_schedule          => r_last_sched.id_schedule,
                            i_epis_type         => r_last_sched.id_epis_type,
                            i_flg_show_template => pk_alert_constant.g_yes,
                            o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_encounters.extend;
            l_encounters(1) := g_prv_enc;
        END IF;
    
        g_error := 'OPEN o_enc_data';
        OPEN o_enc_data FOR
            SELECT /*+opt_estimate(table t rows=1)*/
             t.id_episode,
             t.id_schedule,
             t.id_epis_type,
             t.enc_data,
             decode(t.id_prof_med,
                    NULL,
                    NULL,
                    pk_tools.get_prof_description(i_lang, i_prof, t.id_prof_med, t.dt_change_med, t.id_episode) || ' / ' ||
                    pk_date_utils.date_char_tsz(i_lang, t.dt_change_med, i_prof.institution, i_prof.software)) prof_med,
             decode(t.id_prof_nur,
                    NULL,
                    NULL,
                    pk_tools.get_prof_description(i_lang, i_prof, t.id_prof_nur, t.dt_change_nur, t.id_episode) || ' / ' ||
                    pk_date_utils.date_char_tsz(i_lang, t.dt_change_nur, i_prof.institution, i_prof.software)) prof_nur,
             pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                decode(t.id_episode, NULL, sp.dt_target_tstz, e.dt_begin_tstz),
                                                i_prof) dt_begin,
             decode(t.id_episode,
                    NULL,
                    pk_hea_prv_aux.get_clin_service(i_lang, i_prof, s.id_dcs_requested),
                    pk_episode.get_cs_desc(i_lang, i_prof, t.id_episode)) clinical_service,
             (SELECT pk_translation.get_translation(i_lang, g_et_code || t.id_epis_type)
                FROM dual) episode_type,
             decode(t.id_episode, NULL, s.flg_status, e.flg_status) flg_status,
             decode(t.id_epis_type, l_epis_type, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_nurse
              FROM TABLE(l_encounters) t
              LEFT JOIN episode e
                ON t.id_episode = e.id_episode
              LEFT JOIN schedule_outp sp
                ON t.id_schedule = sp.id_schedule
              LEFT JOIN schedule s
                ON t.id_schedule = s.id_schedule
             ORDER BY decode(t.id_episode, NULL, sp.dt_target_tstz, e.dt_begin_tstz) DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_LAST_ENCOUNTER',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_last_encounter;

    FUNCTION get_visit_type_edis
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_diagnosis pk_translation.t_desc_translation;
    BEGIN
        SELECT desc_diagnosis
          INTO l_diagnosis
          FROM (SELECT -- ALERT-736: diagnosis synonyms support
                 pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                            i_id_diagnosis        => d.id_diagnosis,
                                            i_desc_epis_diagnosis => ed2.desc_epis_diagnosis,
                                            i_code                => d.code_icd,
                                            i_flg_other           => d.flg_other,
                                            i_flg_std_diag        => ad.flg_icd9,
                                            i_epis_diag           => ed2.id_epis_diagnosis,
                                            i_show_aditional_info => pk_alert_constant.g_no) desc_diagnosis
                  FROM ( -- SELECTS THE DIAGNOSES TO SHOW
                        SELECT ed.*,
                                row_number() over(PARTITION BY ed.id_diagnosis ORDER BY decode(ed.flg_type, pk_edis_proc.g_epis_diag_type_definitive, 0, 1) ASC, decode(ed.flg_status, pk_edis_proc.g_epis_diag_confirmed, 0, 1) ASC, decode(ed.flg_status, pk_edis_proc.g_epis_diag_despiste, ed.dt_epis_diagnosis_tstz, ed.dt_confirmed_tstz) DESC) rn
                          FROM epis_diagnosis ed
                         WHERE ed.id_episode = i_episode
                           AND ed.flg_status IN (pk_edis_proc.g_epis_diag_confirmed, pk_edis_proc.g_epis_diag_despiste)) ed2
                  JOIN diagnosis d
                    ON (d.id_diagnosis = ed2.id_diagnosis)
                  LEFT JOIN alert_diagnosis ad
                    ON ad.id_alert_diagnosis = ed2.id_alert_diagnosis
                 WHERE ed2.rn = 1
                 ORDER BY decode(ed2.flg_type, pk_edis_proc.g_epis_diag_type_definitive, 0, 1) ASC,
                          decode(ed2.flg_final_type,
                                 pk_edis_proc.g_epis_diag_final_type_primary,
                                 0,
                                 pk_edis_proc.g_epis_diag_final_type_sec,
                                 1,
                                 2),
                          decode(ed2.flg_status, pk_edis_proc.g_epis_diag_confirmed, 0, 1) ASC)
         WHERE rownum = 1;
        IF l_diagnosis IS NULL
        THEN
            l_diagnosis := pk_edis_grid.get_complaint_grid(i_lang, i_prof, i_episode);
        END IF;
        RETURN l_diagnosis;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /********************************************************************************************
    * Function to return the visit type 
    *
    * @param   i_lang        Language ID
    * @param   i_prof        Professional's details
    * @param   i_episode     ID episode
    * @param   i_epis_type   id epis_type
    *
    * @return                True or False
    *
    * @author                Elisabete Bugalho
    * @version               2.6.2
    * @since                 2012/04/05 
    ********************************************************************************************/
    FUNCTION get_visit_type_epis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_epis_type IN epis_type.id_epis_type%TYPE
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    BEGIN
        IF i_epis_type IN (pk_alert_constant.g_epis_type_outpatient,
                           pk_alert_constant.g_epis_type_primary_care,
                           pk_alert_constant.g_epis_type_private_practice,
                           pk_alert_constant.g_epis_type_social,
                           pk_alert_constant.g_epis_type_nurse_care,
                           pk_alert_constant.g_epis_type_nurse_outp,
                           pk_alert_constant.g_epis_type_nurse_pp,
                           pk_alert_constant.g_epis_type_dietitian) -- amb product
        THEN
            RETURN pk_episode.get_cs_desc(i_lang, i_prof, i_episode);
        ELSIF i_epis_type IN (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_soft_ubu) -- EDIS
        THEN
            RETURN get_visit_type_edis(i_lang, i_prof, i_episode);
        ELSIF i_epis_type = pk_alert_constant.g_epis_type_inpatient -- INP
        THEN
            RETURN pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, i_episode);
        ELSIF i_epis_type = pk_alert_constant.g_epis_type_operating -- ORIS
        THEN
            RETURN pk_sr_clinical_info.get_primary_surg_proc(i_lang, i_prof, i_episode);
        ELSE
            RETURN pk_episode.get_cs_desc(i_lang, i_prof, i_episode);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_VISIT_TYPE_EPIS',
                                              o_error    => l_error);
            RETURN NULL;
        
    END get_visit_type_epis;

BEGIN
    -- Log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
END pk_prev_encounter;
/
