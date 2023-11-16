/*-- Last Change Revision: $Rev: 2026622 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:22 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_advanced_directives IS

    g_code_msg_reviewed      CONSTANT sys_message.code_message%TYPE := 'ADVANCE_DIRECTIVES_M007';
    g_code_msg_not_reviewed  CONSTANT sys_message.code_message%TYPE := 'ADVANCE_DIRECTIVES_M008';
    g_code_msg_part_reviewed CONSTANT sys_message.code_message%TYPE := 'ADVANCE_DIRECTIVES_M009';

    g_cfg_dnar_diff_cat CONSTANT sys_config.id_sys_config%TYPE := 'ADV_DIRECTIVE_HEADER_DNAR_DIFF_CAT';

    g_flg_state_review_all  CONSTANT VARCHAR2(1) := 'A'; --A - All Reviewed
    g_flg_state_review_part CONSTANT VARCHAR2(1) := 'P'; --P - Partially reviewed
    g_flg_state_review_not  CONSTANT VARCHAR2(1) := 'N'; --N - Not reviewed

    g_alert_type_add CONSTANT VARCHAR2(1) := 'A';
    g_alert_type_rem CONSTANT VARCHAR2(1) := 'R';

    g_greater CONSTANT VARCHAR2(1) := 'G';
    g_equal   CONSTANT VARCHAR2(1) := 'E';

    g_rem_prof_temp_by_episode CONSTANT reminder_prof_temp.value%TYPE := 'BY_EPISODE';

    g_recurr_plan_excp EXCEPTION;

    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
    
        o_error.err_desc := g_package_name || '.' || i_func_proc_name || ' / ' || i_error;
    
        pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                        text_in       => i_error,
                                        name1_in      => 'OWNER',
                                        value1_in     => 'ALERT',
                                        name2_in      => 'PACKAGE',
                                        value2_in     => g_package_name,
                                        name3_in      => 'FUNCTION',
                                        value3_in     => i_func_proc_name);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling;

    FUNCTION error_handling_ext
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
    
        l_error_in.set_all(i_lang, SQLCODE, i_sqlerror, i_error, 'ALERT', g_package_name, i_func_proc_name);
        l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling_ext;

    /**********************************************************************************************
    * Set alert
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis_documentation     epis documentation id
    * @param i_type                   operation type: A - add, R- remove
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.1.1
    * @since                          2011/06/09
    **********************************************************************************************/
    FUNCTION set_alert
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_episode            IN episode.id_episode%TYPE DEFAULT -1,
        i_type               IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ALERT';
        --
        l_sys_alert_event sys_alert_event%ROWTYPE;
        l_sys_alert CONSTANT PLS_INTEGER := 200;
        --
        l_ret BOOLEAN;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF i_type = g_alert_type_add
        THEN
            g_error := 'ADD ALERT - ID_EPIS_DOC: ' || i_epis_documentation;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_ret := pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_sys_alert           => l_sys_alert,
                                                      i_id_episode          => i_episode,
                                                      i_id_record           => i_epis_documentation,
                                                      i_dt_record           => g_sysdate_tstz,
                                                      i_id_professional     => NULL,
                                                      i_id_room             => NULL,
                                                      i_id_clinical_service => NULL,
                                                      i_flg_type_dest       => 'C',
                                                      i_replace1            => NULL,
                                                      i_replace2            => NULL,
                                                      o_error               => o_error);
        ELSIF i_type = g_alert_type_rem
        THEN
            g_error := 'DEL ALERT - ID_EPIS_DOC: ' || i_epis_documentation;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_sys_alert_event.id_sys_alert := l_sys_alert;
            l_sys_alert_event.id_record    := i_epis_documentation;
        
            l_ret := pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_sys_alert_event => l_sys_alert_event,
                                                      o_error           => o_error);
        END IF;
    
        RETURN l_ret;
    END set_alert;

    /********************************************************************************************
    * Gets the type of advance directive for a patient or a record
    *
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, software and institution ids
    * @param   I_PATIENT             patient id
    * @param   I_EPIS_DOCUMENTATION  documentation ID assoiciated with the advance directive
    *
    * @param   o_desc_pat_adv_dir    advance directive description (for a record)
    * @param   o_pat_adv_dir         advance directive descriptions (for a patient)
    *
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   15-04-2010
    **********************************************************************************************/
    FUNCTION get_adv_dir_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_desc_pat_adv_dir   OUT VARCHAR2,
        o_pat_adv_dir        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_has_adv_dir         VARCHAR2(1);
        l_id_shortcut_adv_dir NUMBER;
    
    BEGIN
    
        IF i_patient IS NOT NULL
        THEN
            IF NOT pk_advanced_directives.get_adv_directives_for_header(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_patient            => i_patient,
                                                                        i_episode            => NULL,
                                                                        o_has_adv_directives => l_has_adv_dir,
                                                                        o_adv_directive_sh   => l_id_shortcut_adv_dir,
                                                                        o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'GET ADVANCE DIRECTIVES';
            OPEN o_pat_adv_dir FOR
                SELECT pk_translation.get_translation(i_lang, a.code_summary_page_section) || ', ' ||
                       pk_date_utils.dt_chr_tsz(i_lang, a.dt_last_update_tstz, i_prof.institution, i_prof.software) desc_advanced,
                       l_id_shortcut_adv_dir id_sys_shortcut
                  FROM (SELECT DISTINCT sps.code_summary_page_section, ed.dt_last_update_tstz
                          FROM epis_documentation ed
                          JOIN summary_page_section sps
                            ON sps.id_doc_area = ed.id_doc_area
                          JOIN summary_page sp
                            ON sp.id_summary_page = sps.id_summary_page
                          JOIN episode epis
                            ON epis.id_episode = ed.id_episode
                         WHERE epis.id_patient = i_patient
                           AND sp.id_summary_page = g_summ_page_adv_dir
                           AND ed.flg_status = g_adv_status_active) a
                
                 ORDER BY a.dt_last_update_tstz DESC;
        
        ELSIF i_epis_documentation IS NOT NULL
        THEN
            pk_types.open_my_cursor(o_pat_adv_dir);
        
            SELECT pk_translation.get_translation(i_lang, sps.code_summary_page_section) desc_advanced
              INTO o_desc_pat_adv_dir
              FROM epis_documentation ed
              JOIN summary_page_section sps
                ON sps.id_doc_area = ed.id_doc_area
             WHERE ed.id_epis_documentation = i_epis_documentation;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_adv_dir);
            RETURN error_handling(i_lang, 'GET_ADV_DIR_DESC', g_error, SQLERRM, FALSE, o_error);
    END get_adv_dir_desc;

    /********************************************************************************************
    * Gets the current document ID associated with an advance directive
    *
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PATIENT             patient id
    * @param   I_DOC_TYPE            document type
    * @param   O_ID_PAT_ADV_DIR      patient advance directive ID
    * @param   O_ID_PAT_DOC          current document ID
    *
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   16-02-2009
    **********************************************************************************************/
    FUNCTION get_adv_dir_doc_id
    (
        i_lang           IN NUMBER,
        i_patient        IN doc_external.id_patient%TYPE,
        i_doc_type       IN doc_external.id_doc_type%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_id_pat_adv_dir OUT pat_advance_directive.id_pat_advance_directive%TYPE,
        o_id_pat_doc     OUT pat_adv_directive_doc.id_pat_adv_directive_doc%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_doc_area doc_area.id_doc_area%TYPE;
    
        CURSOR c_doc_area IS
            SELECT id_doc_area
              FROM advance_directive ad
             WHERE ad.id_doc_type = i_doc_type;
    
    BEGIN
    
        BEGIN
            IF i_doc_type IS NOT NULL
            THEN
                g_error := 'FETCH DOC_AREA';
                OPEN c_doc_area;
                FETCH c_doc_area
                    INTO l_id_doc_area;
                CLOSE c_doc_area;
            
                g_error := 'CHECK EXISTING DOCS';
                SELECT t.id_pat_advance_directive, t.id_pat_adv_directive_doc
                  INTO o_id_pat_adv_dir, o_id_pat_doc
                  FROM (SELECT p.id_pat_advance_directive, pdoc.id_pat_adv_directive_doc
                          FROM pat_advance_directive p
                          JOIN epis_documentation edoc
                            ON p.id_epis_documentation = edoc.id_epis_documentation
                           AND edoc.id_doc_area = l_id_doc_area
                          LEFT JOIN pat_adv_directive_doc pdoc
                            ON p.id_pat_advance_directive = pdoc.id_pat_advance_directive
                           AND pdoc.flg_status IN (g_doc_status_active, g_doc_status_cancel)
                          LEFT JOIN doc_external de
                            ON pdoc.id_doc_external = de.id_doc_external
                           AND de.id_doc_type = i_doc_type
                         WHERE p.id_patient = i_patient
                           AND p.flg_status = g_adv_status_active
                         ORDER BY edoc.dt_creation_tstz DESC) t
                 WHERE rownum = 1;
            
            ELSIF i_doc_area IS NOT NULL
            THEN
                g_error := 'CHECK EXISTING DOCS';
                SELECT p.id_pat_advance_directive
                  INTO o_id_pat_adv_dir
                  FROM pat_advance_directive p
                  JOIN epis_documentation edoc
                    ON p.id_epis_documentation = edoc.id_epis_documentation
                   AND edoc.id_doc_area = i_doc_area
                 WHERE p.id_patient = i_patient
                   AND p.flg_status = g_adv_status_active;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                o_id_pat_adv_dir := NULL;
                o_id_pat_doc     := NULL;
        END;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_ADV_DIR_DOC_ID', g_error, SQLERRM, FALSE, o_error);
    END get_adv_dir_doc_id;

    /**
    * This function tels if a patient has any advanced directives
    *
    * @param i_lang language id
    * @param i_prof user object
    * @param i_patient patient id
    * @param o_has_adv_directives Y if patient has advanced directives, N otherwise
    * @param o_adv_directive_sh advanced directives shortcut to jump to when accessing it from the header
    * @param o_error error message, in case of error
    * @return true (all ok), false (error)
    *
    * @author  José Silva
    * @version 2.0
    * @since   23-02-2009
    */

    FUNCTION get_adv_directives_for_header
    
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_has_adv_directives OUT VARCHAR2,
        o_adv_directive_sh   OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat_adv_directive IS
            SELECT p.flg_has_adv_directive
              FROM pat_advance_directive p
             WHERE p.id_patient = i_patient
               AND p.flg_has_adv_directive = g_yes
               AND p.flg_status = g_adv_status_active;
    
        l_has_adv_directives pat_advance_directive.flg_has_adv_directive%TYPE := pk_alert_constant.g_no;
    
    BEGIN
        g_error := 'GET FLG_HAS_ADV_DIRECTIVE';
    
        OPEN c_pat_adv_directive;
        FETCH c_pat_adv_directive
            INTO l_has_adv_directives;
        CLOSE c_pat_adv_directive;
    
        g_error := 'GET SHORTCUT';
        IF nvl(l_has_adv_directives, pk_alert_constant.g_no) = pk_alert_constant.g_yes
        THEN
            BEGIN
                SELECT id_sys_shortcut
                  INTO o_adv_directive_sh
                  FROM (SELECT nvl(ss.id_parent, ss.id_sys_shortcut) id_sys_shortcut
                          FROM sys_shortcut ss, prof_profile_template ppt, profile_templ_access pta
                         WHERE ss.id_software = i_prof.software
                           AND (ss.intern_name = 'ADVANCED_DIRECTIVES' OR ss.intern_name = 'ADVANCED_DIRECTIVES_ADMIN')
                           AND ppt.id_professional = i_prof.id
                           AND ppt.id_software = ss.id_software
                           AND pta.id_profile_template =
                               (SELECT pt.id_parent
                                  FROM profile_template pt
                                 WHERE pt.id_profile_template = ppt.id_profile_template)
                           AND NOT EXISTS (SELECT 0
                                  FROM profile_templ_access p
                                 WHERE p.id_profile_template = ppt.id_profile_template
                                   AND p.id_sys_button_prop = ss.id_sys_button_prop
                                   AND p.flg_add_remove = pk_access.g_flg_type_remove)
                           AND pta.flg_add_remove = pk_access.g_flg_type_add
                           AND pta.id_sys_button_prop = ss.id_sys_button_prop
                        UNION ALL
                        SELECT nvl(ss.id_parent, ss.id_sys_shortcut) id_sys_shortcut
                          FROM sys_shortcut ss, prof_profile_template ppt, profile_templ_access pta
                         WHERE ss.id_software = i_prof.software
                           AND (ss.intern_name = 'ADVANCED_DIRECTIVES' OR ss.intern_name = 'ADVANCED_DIRECTIVES_ADMIN')
                           AND ppt.id_professional = i_prof.id
                           AND ppt.id_software = ss.id_software
                           AND ppt.id_institution = i_prof.institution
                           AND pta.id_profile_template = ppt.id_profile_template
                           AND pta.flg_add_remove = pk_access.g_flg_type_add
                           AND pta.id_sys_button_prop = ss.id_sys_button_prop)
                 WHERE rownum = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    o_has_adv_directives := pk_alert_constant.g_no;
            END;
        END IF;
    
        o_has_adv_directives := nvl(l_has_adv_directives, pk_alert_constant.g_no);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_ADV_DIRECTIVES_FOR_HEADER', g_error, SQLERRM, FALSE, o_error);
    END get_adv_directives_for_header;

    /********************************************************************************************
    * Sets all different advance directives registered to the patient
    *
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PAT_ADV_DIRECTIVE   patient advance directive ID
    * @param   I_DOC_AREA            document area ID
    * @param   i_id_doc_element      array with doc elements
    *
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   23-02-2009
    **********************************************************************************************/
    FUNCTION set_pat_adv_directives
    (
        i_lang              IN NUMBER,
        i_pat_adv_directive IN pat_advance_directive.id_pat_advance_directive%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_id_doc_element    IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids table_varchar;
        l_flag   PLS_INTEGER := 0;
    
        CURSOR c_doc_area IS
            SELECT ad.*, decode(a.column_value, ad.id_doc_element_yes, g_yes, ad.id_doc_element_no, g_no) flg_rsp
              FROM advance_directive ad
              JOIN TABLE(i_id_doc_element) a
                ON (a.column_value = ad.id_doc_element_yes OR a.column_value = ad.id_doc_element_no)
             WHERE ad.id_doc_area = i_doc_area;
    
    BEGIN
    
        g_error := 'DELETE PREVIOUS RECORDS';
        ts_pat_advance_directive_det.del_by(where_clause_in => 'id_pat_advance_directive = ' || i_pat_adv_directive);
    
        g_error := 'LOOP ADVANCE DIRECTIVES';
        FOR r_doc_area IN c_doc_area
        LOOP
            IF r_doc_area.flg_type IN (g_flg_adv_type_w, g_flg_adv_type_c)
            THEN
                g_error := 'INSERT INTO PAT_ADVANCE_DIRECTIVE_DET';
                l_flag  := 1;
            
                ts_pat_advance_directive_det.ins(id_pat_advance_directive_in => i_pat_adv_directive,
                                                 id_advance_directive_in     => r_doc_area.id_advance_directive,
                                                 flg_advance_directive_in    => r_doc_area.flg_rsp,
                                                 rows_out                    => l_rowids);
            ELSIF r_doc_area.flg_type IN (g_flg_adv_type_h, g_flg_adv_type_l)
            THEN
                g_error := 'UPDATE PAT_ADVANCE_DIRECTIVE';
                ts_pat_advance_directive.upd(flg_has_adv_directive_in    => r_doc_area.flg_rsp,
                                             id_pat_advance_directive_in => i_pat_adv_directive,
                                             rows_out                    => l_rowids);
            END IF;
        END LOOP;
    
        g_error := 'LOOP ADVANCE DIRECTIVES - NEW AREAS (DNAR; END OF LIFE CARE)';
        FOR r_doc_area IN (SELECT ad.id_advance_directive, g_yes flg_rsp
                             FROM advance_directive ad
                            WHERE ad.id_doc_area = i_doc_area
                              AND ad.flg_available = pk_alert_constant.g_available
                              AND ad.flg_type IN
                                  (pk_advanced_directives.g_flg_adv_type_d, pk_advanced_directives.g_flg_adv_type_e))
        
        LOOP
            g_error  := 'INSERT INTO PAT_ADVANCE_DIRECTIVE_DET';
            l_flag   := 1;
            l_rowids := table_varchar();
            ts_pat_advance_directive_det.ins(id_pat_advance_directive_in => i_pat_adv_directive,
                                             id_advance_directive_in     => r_doc_area.id_advance_directive,
                                             flg_advance_directive_in    => r_doc_area.flg_rsp,
                                             rows_out                    => l_rowids);
        END LOOP;
    
        g_error := 'LOOP ADVANCE DIRECTIVES - NEW AREAS Patient Alert';
        FOR r_doc_area IN (SELECT ad.id_advance_directive, g_yes flg_rsp
                             FROM advance_directive ad
                            WHERE ad.id_doc_area = i_doc_area
                              AND ad.flg_available = pk_alert_constant.g_available
                              AND ad.flg_type IN (pk_advanced_directives.g_flg_adv_type_a))
        
        LOOP
            g_error  := 'INSERT INTO PAT_ADVANCE_DIRECTIVE_DET';
            l_flag   := 1;
            l_rowids := table_varchar();
            ts_pat_advance_directive_det.ins(id_pat_advance_directive_in => i_pat_adv_directive,
                                             id_advance_directive_in     => r_doc_area.id_advance_directive,
                                             flg_advance_directive_in    => r_doc_area.flg_rsp,
                                             rows_out                    => l_rowids);
        END LOOP;
    
        l_rowids := table_varchar();
    
        IF l_flag = 1
        THEN
            g_error := 'UPDATE PAT_ADVANCE_DIRECTIVE 2';
            ts_pat_advance_directive.upd(flg_has_adv_directive_in    => g_yes,
                                         id_pat_advance_directive_in => i_pat_adv_directive,
                                         rows_out                    => l_rowids);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_PAT_ADV_DIRECTIVES', g_error, SQLERRM, TRUE, o_error);
    END set_pat_adv_directives;

    /********************************************************************************************
    * Gets the last DNAR documentation for the current patient (if exists)
    *
    * @param   i_lang                      language associated to the professional executing the request
    * @param   i_prof                      professional, institution and software ids
    * @param   i_patient                   Patient id
    * @param   o_pat_advance_directive     Pat advance directive id
    * @param   o_epis_documentation        Epis documentation id
    * @param   o_episode                   Episode id
    * @param   o_error                     Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Alexandre Santos
    * @version                        2.6.1.1
    * @since                          01-06-2011
    **********************************************************************************************/
    FUNCTION get_last_dnar_doc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        o_pat_advance_directive OUT pat_advance_directive.id_pat_advance_directive%TYPE,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_episode               OUT epis_documentation.id_episode%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_LAST_DNAR_DOC';
        --
        l_one CONSTANT PLS_INTEGER := 1;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'GET ID_PAT_ADVANCE_DIRECTIVE - I_PATIENT: ' || i_patient;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT t.id_pat_advance_directive, t.id_epis_documentation, t.id_episode
          INTO o_pat_advance_directive, o_epis_documentation, o_episode
          FROM (SELECT pad.id_pat_advance_directive,
                       ed.id_epis_documentation,
                       ed.id_episode,
                       row_number() over(ORDER BY ed.dt_last_update_tstz DESC) line_number
                  FROM epis_documentation ed
                  JOIN epis_documentation_det edd
                    ON edd.id_epis_documentation = ed.id_epis_documentation
                  JOIN pat_advance_directive pad
                    ON pad.id_epis_documentation = ed.id_epis_documentation
                  JOIN advance_directive ad
                    ON ad.id_doc_area = ed.id_doc_area
                   AND ad.flg_type = pk_advanced_directives.g_flg_adv_type_d
                 WHERE pad.id_patient = i_patient
                   AND ed.flg_status = pk_advanced_directives.g_adv_status_active) t
         WHERE t.line_number = l_one;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_pat_advance_directive := NULL;
            o_epis_documentation    := NULL;
            o_episode               := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, l_func_name, g_error, SQLERRM, TRUE, o_error);
    END get_last_dnar_doc;

    /********************************************************************************************
    * Check if DNAR was reviewed
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_patient           Patient ID
    * @param   i_episode           episode id
    * @param   i_profile_template  Profile template ID
    * @param   o_flg_it_to_review  If a message should or should not be shown to the user
    * @param   o_error             Error message
    *
    * @value   o_flg_it_to_review  Y - Is to review
    *                              N - Was already reviewed
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1.1
    * @since   23-05-2011
    **********************************************************************************************/
    FUNCTION check_ad_dnar_review_int
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_profile_template      IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_pat_advance_directive IN pat_advance_directive.id_pat_advance_directive%TYPE DEFAULT NULL,
        o_flg_is_to_review      OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_AD_DNAR_REVIEW_INT';
        --
        l_recurr_opt_within_x_days CONSTANT reminder_prof_temp.id_recurr_option%TYPE := 12;
        l_one                      CONSTANT PLS_INTEGER := 1;
        --
        l_exception EXCEPTION;
        --
        l_pat_advance_directive pat_adv_dir_recurr_plan.id_pat_advance_directive%TYPE;
        l_epis_documentation    epis_documentation.id_epis_documentation%TYPE;
        l_episode               episode.id_episode%TYPE;
        l_profile_template      profile_template.id_profile_template%TYPE;
        --
        l_id_recurr_plan pat_adv_dir_recurr_plan.id_recurr_plan%TYPE;
        l_dt_start       pat_adv_dir_recurr_plan.dt_start%TYPE;
        l_exec_number    pat_adv_dir_recurr_plan.exec_number%TYPE;
        l_exec_timestamp pat_adv_dir_recurr_plan.exec_timestamp%TYPE;
        --
        l_recurr_plan       t_tbl_order_recurr_plan;
        l_last_exec_reached VARCHAR2(1);
        l_rec_rem_pt        t_rec_reminder_prof_temp;
        --
        c_reviews       pk_review.t_cur_reviews;
        l_table_reviews pk_review.t_tab_reviews;
        l_exists_review BOOLEAN := FALSE;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF i_pat_advance_directive IS NULL
        THEN
            g_error := 'CALL GET_LAST_DNAR_DOC';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT get_last_dnar_doc(i_lang                  => i_lang,
                                     i_prof                  => i_prof,
                                     i_patient               => i_patient,
                                     o_pat_advance_directive => l_pat_advance_directive,
                                     o_epis_documentation    => l_epis_documentation,
                                     o_episode               => l_episode,
                                     o_error                 => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            l_pat_advance_directive := i_pat_advance_directive;
        
            g_error := 'GET ID_EPIS_DOC AND ID_EPISODE FOR ID_PAT_ADV_DIR: ' || l_pat_advance_directive;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            SELECT pad.id_epis_documentation, ed.id_episode
              INTO l_epis_documentation, l_episode
              FROM pat_advance_directive pad
              JOIN epis_documentation ed
                ON ed.id_epis_documentation = pad.id_epis_documentation
             WHERE pad.id_pat_advance_directive = l_pat_advance_directive;
        END IF;
    
        IF l_pat_advance_directive IS NOT NULL
        THEN
            IF i_profile_template IS NOT NULL
            THEN
                g_error := 'SET PROF_TEMP TO ' || i_profile_template;
            ELSE
                g_error := 'GET PROF PROFILE TEMPLATE - I_PROF: (' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                           i_prof.software || ')';
            END IF;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_profile_template := nvl(i_profile_template, pk_prof_utils.get_prof_profile_template(i_prof => i_prof));
        
            BEGIN
                g_error := 'GET RECURR PLAN FOR ID_PAT_ADVANCE_DIRECTIVE: ' || l_pat_advance_directive ||
                           '; ID_PROFILE_TEMPLATE: ' || l_profile_template;
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                SELECT rp.id_recurr_plan, rp.dt_start
                  INTO l_id_recurr_plan, l_dt_start
                  FROM pat_adv_dir_recurr_plan rp
                 WHERE rp.id_pat_advance_directive = l_pat_advance_directive
                   AND rp.id_profile_template = l_profile_template;
            EXCEPTION
                WHEN no_data_found THEN
                    o_flg_is_to_review := pk_alert_constant.g_no;
                    l_id_recurr_plan   := NULL;
            END;
        
            g_error := 'CALL GET_REM_PROF_TEMP_VARS FOR: ' || pk_reminder_constant.g_rem_param_int_nm_recurr;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_rec_rem_pt := pk_reminder_api_db.get_prof_temp_selected_value(i_lang             => i_lang,
                                                                            i_prof             => i_prof,
                                                                            i_internal_name    => pk_reminder_constant.g_rem_param_int_nm_recurr,
                                                                            i_id_prof_template => l_profile_template);
        
            IF l_id_recurr_plan IS NOT NULL
            THEN
                g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.GET_ORDER_RECURR_PLAN';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF NOT pk_order_recurrence_api_db.get_order_recurr_plan(i_lang              => i_lang,
                                                                        i_prof              => i_prof,
                                                                        i_order_plan        => l_id_recurr_plan,
                                                                        i_plan_start_date   => l_dt_start,
                                                                        i_plan_end_date     => NULL,
                                                                        o_order_plan        => l_recurr_plan,
                                                                        o_last_exec_reached => l_last_exec_reached,
                                                                        o_error             => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                BEGIN
                    g_error := 'GET RETURNED INFO';
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
                    SELECT t.id_order_recurrence_plan, t.exec_number, t.exec_timestamp
                      INTO l_id_recurr_plan, l_exec_number, l_exec_timestamp
                      FROM (SELECT rp.id_order_recurrence_plan,
                                   rp.exec_number,
                                   rp.exec_timestamp,
                                   row_number() over(ORDER BY rp.exec_timestamp ASC) line_number
                              FROM TABLE(l_recurr_plan) rp) t
                     WHERE t.line_number = l_one;
                
                    IF l_rec_rem_pt.id_recurr_option = l_recurr_opt_within_x_days
                    THEN
                        --WITHIN_X_DAYS
                        o_flg_is_to_review  := pk_alert_constant.g_no;
                        l_last_exec_reached := NULL;
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        IF l_rec_rem_pt.id_recurr_option = l_recurr_opt_within_x_days
                        THEN
                            --WITHIN_X_DAYS
                            o_flg_is_to_review  := pk_alert_constant.g_yes;
                            l_last_exec_reached := NULL;
                        ELSE
                            o_flg_is_to_review  := pk_alert_constant.g_no;
                            l_last_exec_reached := NULL;
                        END IF;
                END;
            
                IF l_last_exec_reached IS NOT NULL
                THEN
                    g_error := 'CALL PK_DATE_UTILS.COMPARE_DATES_TSZ';
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
                    IF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                       i_date1 => g_sysdate_tstz,
                                                       i_date2 => l_exec_timestamp) IN (g_greater, g_equal)
                    THEN
                        o_flg_is_to_review := pk_alert_constant.g_yes;
                    ELSE
                        o_flg_is_to_review := pk_alert_constant.g_no;
                    END IF;
                END IF;
            ELSIF l_rec_rem_pt IS NOT NULL
                  AND l_rec_rem_pt.value = g_rem_prof_temp_by_episode
            THEN
                g_error := 'GET REVIEWS FOR PROF_TEMP: ' || l_profile_template;
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF NOT pk_review.get_reviews_by_pt(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_id_episode     => nvl(i_episode, l_episode),
                                                   i_id_record_area => l_epis_documentation,
                                                   i_flg_context    => pk_review.get_adv_directives_context,
                                                   i_id_prof_templ  => l_profile_template,
                                                   o_reviews        => c_reviews,
                                                   o_error          => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                g_error := 'FETCH ALL REVIEWS INTO TABLE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                FETCH c_reviews BULK COLLECT
                    INTO l_table_reviews;
            
                g_error := 'CLOSE C_REVIEWS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                CLOSE c_reviews;
            
                IF l_table_reviews.exists(1)
                THEN
                    l_exists_review := FALSE;
                
                    FOR i IN l_table_reviews.first .. l_table_reviews.last
                    LOOP
                        IF i_episode = l_table_reviews(i).id_episode
                        THEN
                            l_exists_review := TRUE;
                            EXIT;
                        END IF;
                    END LOOP;
                ELSE
                    l_exists_review := FALSE;
                END IF;
            
                IF l_exists_review
                THEN
                    o_flg_is_to_review := pk_alert_constant.g_no;
                ELSE
                    o_flg_is_to_review := pk_alert_constant.g_yes;
                END IF;
            END IF;
        ELSE
            o_flg_is_to_review := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END check_ad_dnar_review_int;

    /********************************************************************************************
    * Check if DNAR is reviewed, partially reviewed or not reviewed
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_patient           Patient ID
    * @param   i_episode           episode id
    * @param   o_flg_review        DNAR review state
    * @param   o_error             Error message
    *
    * @value   o_flg_review  A - All Reviewed
    *                        P - Partially reviewed
    *                        N - Not reviewed
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1.1
    * @since   23-05-2011
    **********************************************************************************************/
    FUNCTION check_ad_dnar_rev_all_int
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_flg_review         OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_AD_DNAR_REV_ALL_INT';
        --
        l_pat_advance_directive pat_adv_dir_recurr_plan.id_pat_advance_directive%TYPE;
        l_episode               episode.id_episode%TYPE;
        l_epis_documentation    epis_documentation.id_epis_documentation%TYPE;
        --
        l_flg_global_state VARCHAR2(1) := NULL;
        l_flg_curr_state   VARCHAR2(1);
        --
        l_dnar_diff_cat sys_config.value%TYPE;
        l_doctor_review VARCHAR2(1) := NULL;
        l_nurse_review  VARCHAR2(1) := NULL;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'CALL GET_LAST_DNAR_DOC';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT get_last_dnar_doc(i_lang                  => i_lang,
                                 i_prof                  => i_prof,
                                 i_patient               => i_patient,
                                 o_pat_advance_directive => l_pat_advance_directive,
                                 o_epis_documentation    => l_epis_documentation,
                                 o_episode               => l_episode,
                                 o_error                 => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        --When l_pat_advance_directive is null means that there isn't any record in DNAR area
        IF l_pat_advance_directive IS NOT NULL
          --Validate if input epis_doc is the last dnar epis_doc
           AND nvl(i_epis_documentation, l_epis_documentation) IS NOT NULL
           AND nvl(i_epis_documentation, l_epis_documentation) = l_epis_documentation
        THEN
            g_error := 'GET CFG - ' || g_cfg_dnar_diff_cat;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_dnar_diff_cat := pk_sysconfig.get_config(i_code_cf => g_cfg_dnar_diff_cat, i_prof => i_prof);
        
            g_error := 'LOOP THRU ALL CONFIGURED REMINDER PROFILES';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            FOR r_rpt IN (SELECT t.id_reminder_param,
                                 t.id_profile_template,
                                 t.flg_selected_value,
                                 t.id_recurr_option,
                                 t.value,
                                 (SELECT nvl(c.flg_type, pt.flg_type)
                                    FROM profile_template pt
                                    LEFT JOIN category c
                                      ON c.id_category = pt.id_category
                                   WHERE pt.id_profile_template = t.id_profile_template) prof_category
                            FROM TABLE(pk_reminder_api_db.tf_reminder_prof_temp(i_lang,
                                                                                i_prof,
                                                                                pk_reminder_constant.g_rem_param_int_nm_recurr,
                                                                                l_episode)) t)
            LOOP
                g_error := 'CALL CHECK_AD_DNAR_REVIEW_INT';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF NOT check_ad_dnar_review_int(i_lang                  => i_lang,
                                                i_prof                  => i_prof,
                                                i_patient               => i_patient,
                                                i_episode               => i_episode,
                                                i_profile_template      => r_rpt.id_profile_template,
                                                i_pat_advance_directive => l_pat_advance_directive,
                                                o_flg_is_to_review      => l_flg_curr_state,
                                                o_error                 => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF nvl(l_dnar_diff_cat, pk_alert_constant.g_no) = pk_alert_constant.g_no
                THEN
                    IF l_flg_global_state IS NULL
                    THEN
                        l_flg_global_state := nvl(l_flg_curr_state, pk_alert_constant.g_no);
                    ELSIF l_flg_global_state != nvl(l_flg_curr_state, pk_alert_constant.g_no)
                    THEN
                        o_flg_review := g_flg_state_review_part;
                        EXIT;
                    END IF;
                ELSE
                    CASE r_rpt.prof_category
                        WHEN pk_alert_constant.g_cat_type_doc THEN
                            IF l_doctor_review IS NULL
                            THEN
                                l_doctor_review := l_flg_curr_state;
                            ELSIF l_doctor_review = pk_alert_constant.g_yes
                                  AND l_flg_curr_state = pk_alert_constant.g_no
                            THEN
                                l_doctor_review := pk_alert_constant.g_no;
                            END IF;
                        WHEN pk_alert_constant.g_cat_type_nurse THEN
                            IF l_nurse_review IS NULL
                            THEN
                                l_nurse_review := l_flg_curr_state;
                            ELSIF l_nurse_review = pk_alert_constant.g_yes
                                  AND l_flg_curr_state = pk_alert_constant.g_no
                            THEN
                                l_nurse_review := pk_alert_constant.g_no;
                            END IF;
                    END CASE;
                
                    IF l_doctor_review = pk_alert_constant.g_no
                       AND l_nurse_review = pk_alert_constant.g_no
                    THEN
                        o_flg_review := g_flg_state_review_all;
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            IF o_flg_review IS NULL
            THEN
                IF nvl(l_dnar_diff_cat, pk_alert_constant.g_no) = pk_alert_constant.g_yes
                THEN
                    IF l_doctor_review = l_nurse_review
                    THEN
                        l_flg_global_state := l_doctor_review;
                    ELSIF nvl(l_doctor_review, ' ') != nvl(l_nurse_review, ' ')
                    THEN
                        l_flg_global_state := g_flg_state_review_part;
                    ELSE
                        l_flg_global_state := pk_alert_constant.g_no;
                    END IF;
                END IF;
            
                CASE l_flg_global_state
                    WHEN pk_alert_constant.g_yes THEN
                        o_flg_review := g_flg_state_review_not;
                    WHEN pk_alert_constant.g_no THEN
                        o_flg_review := g_flg_state_review_all;
                    WHEN g_flg_state_review_part THEN
                        o_flg_review := g_flg_state_review_part;
                    ELSE
                        o_flg_review := g_flg_state_review_not;
                END CASE;
            END IF;
        ELSE
            o_flg_review := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END check_ad_dnar_rev_all_int;

    /********************************************************************************************
    * Sets the advance directive review information
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_epis_doc       documentation record (touch-option ID)
    * @param   i_review_notes   revision notes
    * @param   o_error          Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          27-10-2009
    **********************************************************************************************/
    FUNCTION set_adv_dir_review_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_epis_doc     IN epis_documentation.id_epis_documentation%TYPE,
        i_review_notes IN review_detail.review_notes%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ADV_DIR_REVIEW_INT';
        --
        l_exception EXCEPTION;
        l_error      t_error_out;
        l_id_episode episode.id_episode%TYPE;
        --
        l_patient               patient.id_patient%TYPE;
        l_pat_advance_directive pat_adv_dir_recurr_plan.id_pat_advance_directive%TYPE;
        l_epis_documentation    epis_documentation.id_epis_documentation%TYPE;
        l_episode               episode.id_episode%TYPE;
        --
        l_prof_temp profile_template.id_profile_template%TYPE;
        l_dt_start  pat_adv_dir_recurr_plan.dt_start%TYPE;
    BEGIN
    
        g_error := 'CALL TO SET_REVIEW';
        IF NOT pk_review.set_review(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_id_record_area => i_epis_doc,
                                    i_flg_context    => pk_review.get_adv_directives_context,
                                    i_dt_review      => g_sysdate_tstz,
                                    i_review_notes   => i_review_notes,
                                    i_episode        => i_episode,
                                    i_flg_auto       => pk_alert_constant.g_no,
                                    o_error          => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET ID_EPISODE';
        SELECT ed.id_episode, epis.id_patient
          INTO l_id_episode, l_patient
          FROM epis_documentation ed
          JOIN episode epis
            ON epis.id_episode = ed.id_episode
         WHERE ed.id_epis_documentation = i_epis_doc;
    
        g_error := 'CALL GET_LAST_DNAR_DOC';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT get_last_dnar_doc(i_lang                  => i_lang,
                                 i_prof                  => i_prof,
                                 i_patient               => l_patient,
                                 o_pat_advance_directive => l_pat_advance_directive,
                                 o_epis_documentation    => l_epis_documentation,
                                 o_episode               => l_episode,
                                 o_error                 => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_pat_advance_directive IS NOT NULL
        THEN
            l_prof_temp := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
            BEGIN
                SELECT p.dt_start
                  INTO l_dt_start
                  FROM pat_adv_dir_recurr_plan p
                 WHERE p.id_pat_advance_directive = l_pat_advance_directive
                   AND p.id_profile_template = l_prof_temp;
            
                IF pk_date_utils.compare_dates_tsz(i_prof => i_prof, i_date1 => g_sysdate_tstz, i_date2 => l_dt_start) IN
                   (g_greater, g_equal)
                THEN
                    l_dt_start := g_sysdate_tstz;
                END IF;
            
                g_error := 'UPDATE RECURRENCE PLAN';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                ts_pat_adv_dir_recurr_plan.upd(id_pat_advance_directive_in => l_pat_advance_directive,
                                               id_profile_template_in      => l_prof_temp,
                                               dt_start_in                 => l_dt_start,
                                               exec_timestamp_in           => NULL,
                                               exec_timestamp_nin          => FALSE,
                                               exec_number_in              => NULL,
                                               exec_number_nin             => FALSE);
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      l_func_name,
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLERRM,
                                      TRUE,
                                      o_error);
        
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, l_func_name, g_error, SQLERRM, TRUE, o_error);
    END set_adv_dir_review_int;

    /********************************************************************************************
    * Creates all adv. directives DNAR recurrence plans
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_patient                    Patient id
    * @param i_new_episode                Episode id
    * @param o_error                      Error message
    *
    * @return                             true or false on success or error
    *
    * @author                             Alexandre Santos
    * @version                            2.6.1.1
    * @since                              31-05-2011
    **********************************************************************************************/
    FUNCTION set_recurr_plan
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_new_episode IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_RECURR_AREA';
        --
        l_pat_advance_directive pat_adv_dir_recurr_plan.id_pat_advance_directive%TYPE;
        l_epis_documentation    epis_documentation.id_epis_documentation%TYPE;
        l_episode               episode.id_episode%TYPE;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'CALL GET_LAST_DNAR_DOC';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT get_last_dnar_doc(i_lang                  => i_lang,
                                 i_prof                  => i_prof,
                                 i_patient               => i_patient,
                                 o_pat_advance_directive => l_pat_advance_directive,
                                 o_epis_documentation    => l_epis_documentation,
                                 o_episode               => l_episode,
                                 o_error                 => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL PK_ADVANCED_DIRECTIVES.SET_RECURR_PLAN';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_advanced_directives.set_recurr_plan(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_pat_adv_dir => l_pat_advance_directive,
                                                      i_new_episode => i_new_episode,
                                                      o_error       => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, l_func_name, g_error, SQLERRM, TRUE, o_error);
    END set_recurr_plan;

    /********************************************************************************************
    * Creates all adv. directives DNAR recurrence plans
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_pat_adv_dir                Pat advance directive id
    * @param i_new_episode                Episode id
    * @param o_error                      Error message
    *
    * @return                             true or false on success or error
    *
    * @author                             Alexandre Santos
    * @version                            2.6.1.1
    * @since                              31-05-2011
    **********************************************************************************************/
    FUNCTION set_recurr_plan
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat_adv_dir IN pat_advance_directive.id_pat_advance_directive%TYPE,
        i_new_episode IN episode.id_episode%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_RECURR_AREA';
        --
        l_zero CONSTANT PLS_INTEGER := 0;
        l_one  CONSTANT PLS_INTEGER := 1;
        l_two  CONSTANT PLS_INTEGER := 2;
        --
        l_id_patient       patient.id_patient%TYPE;
        l_id_episode       episode.id_episode%TYPE;
        l_flg_dnar_review  VARCHAR2(1);
        l_rem_param_active reminder_prof_temp.id_reminder_param%TYPE;
        l_rem_param_recurr reminder_prof_temp.id_reminder_param%TYPE;
        l_start_date       order_recurr_plan.start_date%TYPE;
        l_recurr_plan      pat_adv_dir_recurr_plan.id_recurr_plan%TYPE;
        --
        l_tbl_rem_param t_table_reminder_param;
        l_rec_rem_pt    t_rec_reminder_prof_temp;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'GET PAT AND EPISODE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
            SELECT pad.id_patient, ed.id_episode
              INTO l_id_patient, l_id_episode
              FROM pat_advance_directive pad
              JOIN epis_documentation ed
                ON ed.id_epis_documentation = pad.id_epis_documentation
             WHERE pad.id_pat_advance_directive = i_pat_adv_dir;
        
            g_error := 'CHECK DNAR REVIEW STATE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT check_ad_dnar_review_int(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_patient               => l_id_patient,
                                            i_episode               => l_id_episode,
                                            i_pat_advance_directive => i_pat_adv_dir,
                                            o_flg_is_to_review      => l_flg_dnar_review,
                                            o_error                 => o_error)
            THEN
                RAISE l_exception;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_dnar_review := NULL;
        END;
    
        --l_flg_dnar_review = NULL = doesn't have any data filled in DNAR doc_area
        IF l_flg_dnar_review IS NOT NULL
        THEN
            g_error := 'CANCEL ALL RECURR PLANS - ID_PAT_ADVANCE_DIRECTIVE: ' || i_pat_adv_dir;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_advanced_directives.cancel_adv_dir_recurr_plans(i_lang        => i_lang,
                                                                      i_prof        => i_prof,
                                                                      i_pat_adv_dir => i_pat_adv_dir,
                                                                      i_episode     => nvl(i_new_episode, l_id_episode),
                                                                      o_error       => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'GET REMINDER PARAMETERS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_tbl_rem_param := pk_reminder_api_db.tf_reminder_params(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_internal_name => pk_reminder_constant.g_recurr_adv_dir_dnar_area);
        
            IF l_tbl_rem_param.count != l_two
            THEN
                g_error            := 'REMINDER PARAMS - INCORRECT NUMBER OF PARAMETERS';
                l_rem_param_active := NULL;
                l_rem_param_recurr := NULL;
            ELSE
                l_rem_param_active := l_tbl_rem_param(l_one).id_reminder_param;
                l_rem_param_recurr := l_tbl_rem_param(l_two).id_reminder_param;
            END IF;
        
            IF l_rem_param_active IS NOT NULL
               AND l_rem_param_recurr IS NOT NULL
            THEN
                --It's necessary to create a recurrence task to each of the parameterize profiles.
                FOR r_rpt IN (SELECT t.id_reminder_param,
                                     t.id_profile_template,
                                     t.flg_selected_value,
                                     t.id_recurr_option,
                                     t.value
                                FROM TABLE(pk_reminder_api_db.tf_reminder_prof_temp(i_lang,
                                                                                    i_prof,
                                                                                    l_rem_param_recurr,
                                                                                    --i_episode != null means that is a new episode so
                                                                                    --plans are created for that profiles
                                                                                    nvl(i_new_episode, l_id_episode))) t
                               WHERE t.id_recurr_option IS NOT NULL)
                LOOP
                    g_error := 'CALL GET_REM_PROF_TEMP_VARS FOR: ' || l_rem_param_active;
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
                    l_rec_rem_pt := pk_reminder_api_db.get_prof_temp_selected_value(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_id_reminder_param => l_rem_param_active,
                                                                                    i_id_prof_template  => r_rpt.id_profile_template);
                
                    IF l_rec_rem_pt.flg_selected_value = pk_alert_constant.g_yes
                       AND r_rpt.id_profile_template != l_zero --Double check, most probably id_prof_temp will be != 0
                       AND r_rpt.value IS NULL
                    THEN
                        g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.CREATE_N_SET_ORDER_RECURR_PLAN';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                        IF NOT
                            pk_order_recurrence_api_db.create_n_set_order_recurr_plan(i_lang                         => i_lang,
                                                                                      i_prof                         => i_prof,
                                                                                      i_order_recurr_area            => pk_reminder_constant.g_recurr_adv_dir_dnar_area,
                                                                                      i_order_recurr_option          => r_rpt.id_recurr_option,
                                                                                      i_start_date                   => g_sysdate_tstz,
                                                                                      i_flg_include_start_dt_in_plan => pk_alert_constant.g_yes,
                                                                                      o_start_date                   => l_start_date,
                                                                                      o_order_recurr_plan            => l_recurr_plan,
                                                                                      o_error                        => o_error)
                        THEN
                            RAISE g_recurr_plan_excp;
                        END IF;
                    
                        g_error := 'ASSOCIATE RECUR_PLAN WITH PAT_ADV_DIR';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                        ts_pat_adv_dir_recurr_plan.ins(id_pat_advance_directive_in => i_pat_adv_dir,
                                                       id_profile_template_in      => r_rpt.id_profile_template,
                                                       id_recurr_plan_in           => l_recurr_plan,
                                                       dt_start_in                 => l_start_date);
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN g_recurr_plan_excp THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, l_func_name, g_error, SQLERRM, TRUE, o_error);
    END set_recurr_plan;

    /********************************************************************************************
    * Cancels all adv. directives recurrence plans
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_patient                    Patient id
    * @param i_episode                    Episode id
    * @param o_error                      Error message
    *
    * @return                             true or false on success or error
    *
    * @author                             Alexandre Santos
    * @version                            2.6.1.1
    * @since                              31-05-2011
    **********************************************************************************************/
    FUNCTION cancel_adv_dir_recurr_plans
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_ADV_DIR_RECURR_PLANS';
        --
        l_pat_advance_directive pat_adv_dir_recurr_plan.id_pat_advance_directive%TYPE;
        l_epis_documentation    epis_documentation.id_epis_documentation%TYPE;
        l_episode               episode.id_episode%TYPE;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'CALL GET_LAST_DNAR_DOC';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT get_last_dnar_doc(i_lang                  => i_lang,
                                 i_prof                  => i_prof,
                                 i_patient               => i_patient,
                                 o_pat_advance_directive => l_pat_advance_directive,
                                 o_epis_documentation    => l_epis_documentation,
                                 o_episode               => l_episode,
                                 o_error                 => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL PK_ADVANCED_DIRECTIVES.CANCEL_ADV_DIR_RECURR_PLANS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_advanced_directives.cancel_adv_dir_recurr_plans(i_lang        => i_lang,
                                                                  i_prof        => i_prof,
                                                                  i_pat_adv_dir => l_pat_advance_directive,
                                                                  i_episode     => nvl(i_episode, l_episode),
                                                                  o_error       => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, l_func_name, g_error, SQLERRM, TRUE, o_error);
    END cancel_adv_dir_recurr_plans;

    /********************************************************************************************
    * Cancels all adv. directives recurrence plans
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_pat_adv_dir                Pat advance directive id
    * @param i_episode                    Episode id
    * @param o_error                      Error message
    *
    * @return                             true or false on success or error
    *
    * @author                             Alexandre Santos
    * @version                            2.6.1.1
    * @since                              31-05-2011
    **********************************************************************************************/
    FUNCTION cancel_adv_dir_recurr_plans
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat_adv_dir IN pat_advance_directive.id_pat_advance_directive%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_ADV_DIR_RECURR_PLANS';
        --
        l_col_name_id_pat_adv_dir CONSTANT VARCHAR2(30) := 'ID_PAT_ADVANCE_DIRECTIVE';
        --
        l_already_called BOOLEAN := FALSE;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'CANCEL ALL RECURR PLANS - ID_PAT_ADVANCE_DIRECTIVE: ' || i_pat_adv_dir;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        FOR r_padrp IN (SELECT p.id_recurr_plan, pad.id_epis_documentation
                          FROM pat_adv_dir_recurr_plan p
                          JOIN pat_advance_directive pad
                            ON pad.id_pat_advance_directive = p.id_pat_advance_directive
                         WHERE p.id_pat_advance_directive = i_pat_adv_dir
                           AND (p.id_profile_template IN
                               (SELECT pt.id_profile_template
                                   FROM profile_template pt
                                  WHERE pt.id_software = (SELECT ei.id_software
                                                            FROM epis_info ei
                                                           WHERE ei.id_episode = i_episode)) OR i_episode IS NULL))
        LOOP
        
            g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.SET_ORDER_RECURR_PLAN_FINISH - ID_RECURR_PLAN: ' ||
                       r_padrp.id_recurr_plan;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_order_recurrence_api_db.set_order_recurr_plan_finish(i_lang              => i_lang,
                                                                           i_prof              => i_prof,
                                                                           i_order_recurr_plan => r_padrp.id_recurr_plan,
                                                                           o_error             => o_error)
            THEN
                RAISE g_recurr_plan_excp;
            END IF;
        
            IF NOT l_already_called
            THEN
                g_error := 'DELETE ALERT';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF NOT set_alert(i_lang               => i_lang,
                                 i_prof               => i_prof,
                                 i_epis_documentation => r_padrp.id_epis_documentation,
                                 i_episode            => i_episode,
                                 i_type               => g_alert_type_rem,
                                 o_error              => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                l_already_called := TRUE;
            END IF;
        END LOOP;
    
        g_error := 'DELETE ALL RECURR PLANS - ID_PAT_ADVANCE_DIRECTIVE: ' || i_pat_adv_dir;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        ts_pat_adv_dir_recurr_plan.del_by_col(colname_in => l_col_name_id_pat_adv_dir, colvalue_in => i_pat_adv_dir);
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_recurr_plan_excp THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, l_func_name, g_error, SQLERRM, TRUE, o_error);
    END cancel_adv_dir_recurr_plans;

    /********************************************************************************************
    * Sets an advance directive record
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_prof_cat_type              professional category
    * @param i_doc_area                   doc_area id
    * @param i_doc_template               doc_template id
    * @param i_epis_documentation         epis documentation id
    * @param i_flg_type                   A Agree, E edit, N - new
    * @param i_id_documentation           array with id documentation,
    * @param i_id_doc_element             array with doc elements
    * @param i_id_doc_element_crit        array with doc elements crit
    * @param i_value                      array with values,
    * @param i_notes                      note
    * @param i_id_doc_element_qualif      array with doc elements qualif
    * @param i_epis_context               episode context id (Ex: id_interv_presc_det,...)
    * @param o_error                      Error message
    *
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0
    * @since                              11-02-2009
    **********************************************************************************************/
    FUNCTION set_advance_directive
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ADVANCE_DIRECTIVE';
    
        l_one_second CONSTANT PLS_INTEGER := (1 / 24 / 60 / 60);
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_id_patient         patient.id_patient%TYPE;
        l_id_pat_adv_dir     pat_advance_directive.id_pat_advance_directive%TYPE;
        l_id_pat_doc         pat_adv_directive_doc.id_pat_adv_directive_doc%TYPE;
        l_exception                 EXCEPTION;
        l_except_cancel_recurr_plan EXCEPTION;
        l_error     t_error_out;
        l_rowids    table_varchar;
        l_count_doc NUMBER := 0;
    
        l_t_id_pat_adv_dir ts_pat_advance_directive.pat_advance_directive_tc;
    BEGIN
    
        g_error := 'GET PATIENT ID';
        SELECT id_patient
          INTO l_id_patient
          FROM episode
         WHERE id_episode = i_epis;
    
        g_error := 'CALL TO GET_ADV_DIR_DOC_ID';
        IF NOT get_adv_dir_doc_id(i_lang           => i_lang,
                                  i_patient        => l_id_patient,
                                  i_doc_type       => NULL,
                                  i_doc_area       => i_doc_area,
                                  o_id_pat_adv_dir => l_id_pat_adv_dir,
                                  o_id_pat_doc     => l_id_pat_doc,
                                  o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL TO PK_TOUCH_OPTION.SET_EPIS_DOCUMENT_INTERNAL';
        IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_prof_cat_type         => i_prof_cat_type,
                                                          i_epis                  => i_epis,
                                                          i_doc_area              => i_doc_area,
                                                          i_doc_template          => i_doc_template,
                                                          i_epis_documentation    => i_epis_documentation,
                                                          i_flg_type              => i_flg_type,
                                                          i_id_documentation      => i_id_documentation,
                                                          i_id_doc_element        => i_id_doc_element,
                                                          i_id_doc_element_crit   => i_id_doc_element_crit,
                                                          i_value                 => i_value,
                                                          i_notes                 => i_notes,
                                                          i_id_epis_complaint     => NULL,
                                                          i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                          i_epis_context          => i_epis_context,
                                                          o_epis_documentation    => l_epis_documentation,
                                                          o_error                 => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'UPDATE EPIS_DOCUMENTATION';
        IF is_to_register_more(i_lang => i_lang, i_prof => i_prof, i_id_doc_area => i_doc_area, o_error => o_error) =
           pk_alert_constant.g_no
        THEN
            ts_epis_documentation.upd(flg_status_in => g_epis_bartchart_out,
                                      where_in      => 'id_doc_area = ' || i_doc_area ||
                                                       ' AND id_episode IN ( SELECT id_episode
                                                                                FROM episode
                                                                               WHERE id_patient = ' ||
                                                       l_id_patient || ')' || ' AND flg_status = ''' ||
                                                       g_epis_bartchart_act || '''' || ' AND id_epis_documentation <> ' ||
                                                       l_epis_documentation,
                                      rows_out      => l_rowids);
        END IF;
        l_rowids := table_varchar();
    
        IF i_epis_documentation IS NULL
        THEN
            g_error := 'OUTDATE PREVIOUS PAT_ADVANCE_DIRECTIVE';
            IF is_to_register_more(i_lang => i_lang, i_prof => i_prof, i_id_doc_area => i_doc_area, o_error => o_error) =
               pk_alert_constant.g_no
            THEN
                ts_pat_advance_directive.upd(flg_status_in               => g_adv_status_out,
                                             id_pat_advance_directive_in => l_id_pat_adv_dir,
                                             rows_out                    => l_rowids);
            END IF;
            l_rowids := table_varchar();
        
            g_error := 'INSERT INTO PAT_ADVANCE_DIRECTIVE';
            ts_pat_advance_directive.ins(id_patient_in            => l_id_patient,
                                         id_epis_documentation_in => l_epis_documentation,
                                         flg_has_adv_directive_in => g_has_adv_unk,
                                         flg_status_in            => g_adv_status_active,
                                         rows_out                 => l_rowids);
        
            l_t_id_pat_adv_dir := ts_pat_advance_directive.get_data_rowid(rows_in => l_rowids);
            SELECT COUNT(1)
              INTO l_count_doc
              FROM pat_adv_directive_doc pdoc
             WHERE pdoc.id_pat_advance_directive = l_id_pat_adv_dir
               AND pdoc.flg_status = pk_alert_constant.g_active;
        
            IF l_count_doc > 0
            THEN
                ts_pat_adv_directive_doc.upd(id_pat_advance_directive_in => l_t_id_pat_adv_dir(1).id_pat_advance_directive,
                                             where_in                    => 'id_pat_advance_directive = ' ||
                                                                            l_id_pat_adv_dir,
                                             rows_out                    => l_rowids);
            END IF;
            l_id_pat_adv_dir := l_t_id_pat_adv_dir(1).id_pat_advance_directive;
        
            g_error := 'CALL SET_RECURR_PLAN';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_advanced_directives.set_recurr_plan(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_pat_adv_dir => l_id_pat_adv_dir,
                                                          o_error       => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            g_error := 'UPDATE PAT_ADVANCE_DIRECTIVE';
            ts_pat_advance_directive.upd(flg_has_adv_directive_in    => g_has_adv_unk,
                                         id_epis_documentation_in    => l_epis_documentation,
                                         id_pat_advance_directive_in => l_id_pat_adv_dir,
                                         rows_out                    => l_rowids);
        END IF;
    
        g_error := 'CALL TO SET_PAT_ADV_DIRECTIVES';
        IF NOT set_pat_adv_directives(i_lang              => i_lang,
                                      i_pat_adv_directive => l_id_pat_adv_dir,
                                      i_doc_area          => i_doc_area,
                                      i_id_doc_element    => i_id_doc_element,
                                      o_error             => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        --AS ALERT-122481
        -- Requisite:
        --   When a adv. directive of a previous episode is edited it should automatically be considered as reviewed
        --   When a adv. directive is created it should automatically be considered as reviewed
        IF i_flg_type IN (pk_touch_option.g_flg_edition_type_new, pk_touch_option.g_flg_edition_type_edit)
        THEN
            g_error := 'CALL SET_ADV_DIR_REVIEW_INT';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            --I'm adding one second to the review time to make sure that the review is after the recurr task start date
            g_sysdate_tstz := pk_date_utils.add_days_to_tstz(i_timestamp => current_timestamp, i_days => l_one_second);
            IF NOT set_adv_dir_review_int(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_episode      => i_epis,
                                          i_epis_doc     => l_epis_documentation,
                                          i_review_notes => NULL,
                                          o_error        => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'CREATE ALERT';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT set_alert(i_lang               => i_lang,
                             i_prof               => i_prof,
                             i_epis_documentation => l_epis_documentation,
                             i_episode            => i_epis,
                             i_type               => g_alert_type_add,
                             o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        o_epis_documentation := l_epis_documentation;
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_except_cancel_recurr_plan THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN g_recurr_plan_excp THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      l_func_name,
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLERRM,
                                      TRUE,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, l_func_name, g_error, SQLERRM, TRUE, o_error);
    END set_advance_directive;

    /********************************************************************************************
    * Sets a new advance directive document
    *
    * @param   i_id_doc              id do documento a fechar
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, institution and software ids
    * @param   I_PATIENT             patient id
    * @param   I_EPISODE             episode id
    * @param   I_EXT_REQ             external request id
    * @param   I_DOC_TYPE            tipo documento
    * @param   I_DESC_DOC_TYPE       descrição manual do tipo documento
    * @param   i_num_doc             numero do documento original
    * @param   i_dt_doc              data emissao do doc. original
    * @param   i_dt_expire           validade do doc. original
    * @param   i_dest                destination id
    * @param   i_desc_dest           descrição manual da destination
    * @param   i_ori_type            doc_ori_type id
    * @param   i_desc_ori_doc_type   descrição manual do ori_type
    * @param   i_original            doc_original id
    * @param   i_desc_original       descrição manual do original
    * @param   i_btn                 contexto
    * @param   i_title               descritivo manual do doc.
    * @param   i_flg_sent_by         info sobre o carrier do doc
    * @param   i_flg_received        indica se recebeu o documento
    * @param   i_prof_perf_by        id do profissional escolhido no performed by
    * @param   i_desc_perf_by        descrição manual do performed by
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   15-02-2009
    **********************************************************************************************/
    FUNCTION set_advance_directive_doc
    (
        i_id_doc            IN doc_external.id_doc_external%TYPE,
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_patient           IN doc_external.id_patient%TYPE,
        i_episode           IN doc_external.id_episode%TYPE,
        i_ext_req           IN doc_external.id_external_request%TYPE,
        i_doc_type          IN doc_external.id_doc_type%TYPE,
        i_desc_doc_type     IN doc_external.desc_doc_type%TYPE,
        i_num_doc           IN doc_external.num_doc%TYPE,
        i_dt_doc            IN doc_external.dt_emited%TYPE,
        i_dt_expire         IN doc_external.dt_expire%TYPE,
        i_dest              IN doc_external.id_doc_destination%TYPE,
        i_desc_dest         IN doc_external.desc_doc_destination%TYPE,
        i_ori_doc_type      IN doc_external.id_doc_ori_type%TYPE,
        i_desc_ori_doc_type IN doc_external.desc_doc_ori_type%TYPE,
        i_original          IN doc_external.id_doc_original%TYPE,
        i_desc_original     IN doc_external.desc_doc_original%TYPE,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title             IN doc_external.title%TYPE,
        i_flg_sent_by       IN doc_external.flg_sent_by%TYPE,
        i_flg_received      IN doc_external.flg_received%TYPE,
        i_prof_perf_by      IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by      IN doc_external.desc_perf_by%TYPE,
        i_notes             IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_id_doc_comments table_number;
        l_error           t_error_out;
    
    BEGIN
    
        BEGIN
            SELECT a.id_doc_comment
              BULK COLLECT
              INTO l_id_doc_comments
              FROM doc_comments a
             WHERE a.id_doc_external = i_id_doc
               AND a.flg_cancel = pk_alert_constant.g_no;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        g_error := 'CREATE DOC';
        IF NOT pk_doc.create_savedoc_internal(i_id_doc            => i_id_doc,
                                              i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_patient           => i_patient,
                                              i_episode           => i_episode,
                                              i_ext_req           => i_ext_req,
                                              i_doc_type          => i_doc_type,
                                              i_desc_doc_type     => i_desc_doc_type,
                                              i_num_doc           => i_num_doc,
                                              i_dt_doc            => i_dt_doc,
                                              i_dt_expire         => i_dt_expire,
                                              i_dest              => i_dest,
                                              i_desc_dest         => i_desc_dest,
                                              i_ori_doc_type      => i_ori_doc_type,
                                              i_desc_ori_doc_type => i_desc_ori_doc_type,
                                              i_original          => i_original,
                                              i_desc_original     => i_desc_original,
                                              i_btn               => i_btn,
                                              i_title             => i_title,
                                              i_flg_sent_by       => i_flg_sent_by,
                                              i_flg_received      => i_flg_received,
                                              i_prof_perf_by      => i_prof_perf_by,
                                              i_desc_perf_by      => i_desc_perf_by,
                                              --
                                              i_author             => NULL,
                                              i_specialty          => NULL,
                                              i_doc_language       => NULL,
                                              i_flg_publish        => NULL,
                                              i_conf_code          => table_varchar(),
                                              i_desc_conf_code     => table_varchar(),
                                              i_code_coding_schema => table_varchar(),
                                              i_conf_code_set      => table_varchar(),
                                              i_desc_conf_code_set => table_varchar(),
                                              --
                                              o_error => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_notes IS NOT NULL
        THEN
        
            FOR i IN 1 .. l_id_doc_comments.count
            LOOP
                IF NOT pk_doc.cancel_comments(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_doc_comments => l_id_doc_comments(i),
                                              i_type_reg        => NULL,
                                              o_error           => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END LOOP;
        
            IF NOT pk_doc.set_comments(i_lang            => i_lang,
                                       i_prof            => i_prof,
                                       i_id_doc_external => i_id_doc,
                                       i_id_image        => NULL,
                                       i_desc_comment    => i_notes,
                                       i_date_comment    => NULL,
                                       o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
        
            IF l_id_doc_comments IS NOT NULL
               AND l_id_doc_comments.count > 0
            THEN
                FOR i IN 1 .. l_id_doc_comments.count
                LOOP
                    IF NOT pk_doc.cancel_comments(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_doc_comments => l_id_doc_comments(i),
                                                  i_type_reg        => NULL,
                                                  o_error           => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        g_error := 'ASSOCIATE NEW DOCUMENT';
        IF NOT set_adv_dir_associated_doc_int(i_id_doc   => i_id_doc,
                                              i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_patient  => i_patient,
                                              i_doc_type => i_doc_type,
                                              o_error    => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_ADVANCE_DIRECTIVE_DOC',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLERRM,
                                      TRUE,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'SET_ADVANCE_DIRECTIVE_DOC', g_error, SQLERRM, TRUE, o_error);
    END set_advance_directive_doc;

    /********************************************************************************************
    * Associates a new document with an advance directive record
    *
    * @param   i_id_doc              list of documents to associate
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, institution and software ids
    * @param   I_PATIENT             patient id
    * @param   I_EPISODE             episode id
    * @param   I_DOC_TYPE            list of document types
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   15-02-2009
    **********************************************************************************************/
    FUNCTION set_adv_dir_associated_doc
    (
        i_id_doc   IN table_number,
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_patient  IN doc_external.id_patient%TYPE,
        i_doc_type IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
    BEGIN
    
        FOR i IN 1 .. i_id_doc.count
        LOOP
            g_error := 'ASSOCIATE NEW DOCUMENT';
            IF NOT set_adv_dir_associated_doc_int(i_id_doc   => i_id_doc(i),
                                                  i_lang     => i_lang,
                                                  i_prof     => i_prof,
                                                  i_patient  => i_patient,
                                                  i_doc_type => i_doc_type(i),
                                                  o_error    => l_error)
            THEN
                RAISE l_exception;
            END IF;
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_ADV_DIR_ASSOCIATED_DOC',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLERRM,
                                      TRUE,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'SET_ADV_DIR_ASSOCIATED_DOC', g_error, SQLERRM, TRUE, o_error);
    END set_adv_dir_associated_doc;

    /********************************************************************************************
    * Associates a new document with an advance directive record
    *
    * @param   i_id_doc              id do documento a fechar
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, institution and software ids
    * @param   I_PATIENT             patient id
    * @param   I_EPISODE             episode id
    * @param   I_DOC_TYPE            tipo documento
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   15-02-2009
    **********************************************************************************************/
    FUNCTION set_adv_dir_associated_doc_int
    (
        i_id_doc   IN doc_external.id_doc_external%TYPE,
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_patient  IN doc_external.id_patient%TYPE,
        i_doc_type IN doc_external.id_doc_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error          t_error_out;
        l_id_pat_adv_dir pat_advance_directive.id_pat_advance_directive%TYPE;
        l_id_pat_doc     pat_adv_directive_doc.id_pat_adv_directive_doc%TYPE;
        l_rowids         table_varchar;
    
        l_flg_type advance_directive.flg_type%TYPE;
        CURSOR c_adv_dir IS
            SELECT ad.flg_type
              FROM advance_directive ad
             WHERE ad.id_doc_type = i_doc_type;
    BEGIN
    
        g_error := 'CALL TO GET_ADV_DIR_DOC_ID';
        IF NOT get_adv_dir_doc_id(i_lang           => i_lang,
                                  i_patient        => i_patient,
                                  i_doc_type       => i_doc_type,
                                  i_doc_area       => NULL,
                                  o_id_pat_adv_dir => l_id_pat_adv_dir,
                                  o_id_pat_doc     => l_id_pat_doc,
                                  o_error          => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'FETCH DOC_AREA';
        OPEN c_adv_dir;
        FETCH c_adv_dir
            INTO l_flg_type;
        CLOSE c_adv_dir;
    
        g_error := 'INACTIVE PREVIOUS DOCS';
        IF l_id_pat_doc IS NOT NULL
           AND l_flg_type != pk_advanced_directives.g_flg_adv_type_e
        THEN
            ts_pat_adv_directive_doc.upd(flg_status_in => g_doc_status_inactive,
                                         where_in      => 'id_pat_adv_directive_doc = ' || l_id_pat_doc,
                                         rows_out      => l_rowids);
        END IF;
    
        l_rowids := table_varchar();
    
        g_error := 'ASSOCIATE NEW DOC';
        IF l_id_pat_adv_dir IS NOT NULL
        THEN
            ts_pat_adv_directive_doc.ins(id_doc_external_in          => i_id_doc,
                                         id_pat_advance_directive_in => l_id_pat_adv_dir,
                                         flg_status_in               => g_doc_status_active,
                                         id_professional_in          => i_prof.id,
                                         dt_register_in              => current_timestamp,
                                         rows_out                    => l_rowids);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling(i_lang,
                                  'SET_ADV_DIR_ASSOCIATED_DOC_INT',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  TRUE,
                                  o_error);
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_ADV_DIR_ASSOCIATED_DOC_INT', g_error, SQLERRM, TRUE, o_error);
    END set_adv_dir_associated_doc_int;

    /********************************************************************************************
    * Updates a new advance directive document
    *
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, institution and software ids
    * @param   I_ID_DOC              document ID
    * @param   I_DOC_TYPE            document type
    * @param   I_DESC_DOC_TYPE       manual description
    * @param   i_num_doc             document number
    * @param   i_dt_doc              emission date
    * @param   i_dt_expire           expiration date
    * @param   i_dest                destination id
    * @param   i_desc_dest           destination description
    * @param   i_ori_type            document origin type
    * @param   i_desc_ori_doc_type   document origin manual description
    * @param   i_original            doc_original id
    * @param   i_desc_original       original manual description
    * @param   i_btn                 context area
    * @param   i_title               document title
    * @param   i_flg_sent_by         document carrier
    * @param   i_flg_received        document was received?
    * @param   i_prof_perf_by        "performed by" field
    * @param   i_desc_perf_by        "performed by" manual description
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   08-04-2009
    **********************************************************************************************/
    FUNCTION update_adv_dir_doc
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_doc            IN NUMBER,
        i_doc_type          IN NUMBER,
        i_desc_doc_type     IN VARCHAR2,
        i_num_doc           IN VARCHAR2,
        i_dt_doc            IN DATE,
        i_dt_expire         IN DATE,
        i_orig_dest         IN NUMBER,
        i_desc_ori_dest     IN VARCHAR2,
        i_orig_type         IN NUMBER,
        i_desc_ori_doc_type IN VARCHAR2,
        i_notes             IN VARCHAR2,
        i_sent_by           IN doc_external.flg_sent_by%TYPE,
        i_received          IN doc_external.flg_received%TYPE,
        i_original          IN NUMBER,
        i_desc_original     IN VARCHAR2,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title             IN doc_external.title%TYPE,
        i_prof_perf_by      IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by      IN doc_external.desc_perf_by%TYPE,
        i_notes_upd         IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
        l_exception EXCEPTION;
        l_id_doc_external doc_external.id_doc_external%TYPE;
        l_id_docs         doc_comments.id_doc_comment%TYPE;
        l_rowids          table_varchar;
    BEGIN
    
        BEGIN
            SELECT t.id_doc_comment
              INTO l_id_docs
              FROM (SELECT a.id_doc_comment
                      FROM doc_comments a
                     WHERE a.id_doc_external = i_id_doc
                       AND a.flg_cancel = pk_alert_constant.g_no
                     ORDER BY a.dt_comment DESC) t
             WHERE rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        g_error := 'UPDATE DOC';
        IF NOT pk_doc.update_doc_internal(i_lang,
                                          i_prof,
                                          i_id_doc,
                                          i_doc_type,
                                          i_desc_doc_type,
                                          i_num_doc,
                                          i_dt_doc,
                                          i_dt_expire,
                                          i_orig_dest,
                                          i_desc_ori_dest,
                                          i_orig_type,
                                          i_desc_ori_doc_type,
                                          i_notes,
                                          i_sent_by,
                                          i_received,
                                          i_original,
                                          i_desc_original,
                                          i_btn,
                                          i_title,
                                          i_prof_perf_by,
                                          i_desc_perf_by,
                                          --
                                          NULL,
                                          NULL,
                                          NULL,
                                          NULL,
                                          NULL,
                                          table_varchar(),
                                          table_varchar(),
                                          table_varchar(),
                                          table_varchar(),
                                          table_varchar(),
                                          i_notes_upd,
                                          --
                                          l_id_doc_external,
                                          l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_id_docs IS NOT NULL
        THEN
        
            IF NOT pk_doc.cancel_comments(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_id_doc_comments => l_id_docs,
                                          i_type_reg        => NULL,
                                          o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        g_error := 'UPDATE ADV_DIR_DOC';
        ts_pat_adv_directive_doc.upd(id_doc_external_in => l_id_doc_external,
                                     where_in           => 'id_doc_external = ' || i_id_doc,
                                     rows_out           => l_rowids);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_ADV_DIR_ASSOCIATED_DOC',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLERRM,
                                      TRUE,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'SET_ADV_DIR_ASSOCIATED_DOC', g_error, SQLERRM, TRUE, o_error);
    END update_adv_dir_doc;

    /********************************************************************************************
    * Advance directive document list
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   o_error   Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          15-02-2009
    **********************************************************************************************/
    FUNCTION get_adv_dir_doc_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error          t_error_out;
        l_my_pt          profile_template.id_profile_template%TYPE;
        l_id_pat_adv_dir table_number;
    
    BEGIN
    
        g_error := 'GET PROFILE_TEMPLATE';
        IF NOT pk_doc.get_profile_template(i_lang, i_prof, l_my_pt, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET ACTIVE PAT ADV DIR';
        BEGIN
            SELECT p.id_pat_advance_directive
              BULK COLLECT
              INTO l_id_pat_adv_dir
              FROM pat_advance_directive p
             WHERE p.id_patient = i_patient
               AND p.flg_status = g_adv_status_active;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_pat_adv_dir := NULL;
        END;
    
        IF l_id_pat_adv_dir IS NOT NULL
        THEN
            g_error := 'GET ADV DIR DOCS';
            OPEN o_list FOR
                SELECT dot.id_doc_ori_type,
                       pk_translation.get_translation(i_lang, dot.code_doc_ori_type) oritypedesc,
                       (SELECT DISTINCT a.id_doc_area
                          FROM advance_directive a
                         WHERE a.id_doc_type = dt.id_doc_type) id_doc_area,
                       pk_translation.get_translation(i_lang, dt.code_doc_type) typedesc,
                       de.title,
                       de.id_doc_external iddoc,
                       (SELECT COUNT(1)
                          FROM doc_image
                         WHERE id_doc_external = de.id_doc_external
                           AND flg_status = pk_doc.g_img_active) numimages,
                       pk_date_utils.date_chr_short_read(i_lang, de.dt_emited, i_prof) dt_emited,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   nvl(de.dt_updated, de.dt_inserted),
                                                   i_prof.institution,
                                                   i_prof.software) lastupdateddate,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(de.id_professional_upd, de.id_professional)) lastupdatedby,
                       pk_doc.get_main_thumb_url(i_lang, i_prof, de.id_doc_external) url_thumb,
                       de.flg_status,
                       dot.flg_comment_type
                  FROM doc_type dt
                  JOIN doc_external de
                    ON (dt.id_doc_type = de.id_doc_type)
                  JOIN doc_ori_type dot
                    ON (de.id_doc_ori_type = dot.id_doc_ori_type)
                  JOIN pat_adv_directive_doc p
                    ON (p.id_doc_external = de.id_doc_external)
                  JOIN TABLE(l_id_pat_adv_dir) a
                    ON (a.column_value = p.id_pat_advance_directive)
                 WHERE de.id_patient = i_patient
                   AND de.flg_status IN (pk_doc.g_doc_active, pk_doc.g_doc_inactive)
                   AND pk_doc.get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                       pk_doc.g_doc_config_y
                   AND pk_doc.get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                       pk_doc.g_doc_config_y
                   AND p.flg_status IN (g_doc_status_active, g_doc_status_cancel)
                 ORDER BY dt.id_doc_type DESC;
        ELSE
            pk_types.open_my_cursor(o_list);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_list);
            RETURN error_handling_ext(i_lang,
                                      'GET_ADV_DIR_DOC_LIST',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLERRM,
                                      FALSE,
                                      o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN error_handling_ext(i_lang, 'GET_ADV_DIR_DOC_LIST', g_error, SQLERRM, FALSE, o_error);
    END get_adv_dir_doc_list;

    /********************************************************************************************
    * Gets the list of documents to import (from the "Documents" deepnav)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_pat                    Patient ID
    * @param i_btn                    context
    * @param o_list                   list of documents
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          15-02-2009
    **********************************************************************************************/
    FUNCTION get_adv_dir_doc_import
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_pat     IN patient.id_patient%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error           t_error_out;
        l_my_pt           profile_template.id_profile_template%TYPE;
        l_list            pk_doc.p_doc_list_rec_cur;
        l_rec_list        pk_doc.p_doc_list_rec;
        l_id_pat_adv_dir  pat_advance_directive.id_pat_advance_directive%TYPE;
        l_id_pat_doc      pat_adv_directive_doc.id_pat_adv_directive_doc%TYPE;
        l_id_doc_external doc_external.id_doc_external%TYPE;
    
        CURSOR c_doc_types IS
            SELECT *
              FROM (SELECT DISTINCT (dt.id_doc_type)
                      FROM doc_type dt
                     INNER JOIN doc_types_config dtc
                        ON dtc.id_doc_type = dt.id_doc_type
                     WHERE dtc.id_doc_ori_type_parent = g_doc_ori_type_adv_dir
                       AND pk_doc.get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                           pk_doc.g_doc_config_y
                       AND dt.flg_available = g_yes
                       AND dtc.id_institution IN (i_prof.institution, 0)
                       AND dtc.id_software IN (i_prof.software, 0)
                       AND dtc.id_profile_template IN (l_my_pt, 0)
                       AND dt.id_doc_type IN (SELECT DISTINCT nvl(ad.id_doc_type, t.id_doc_type) id_doc_type
                                                FROM pat_advance_directive pad
                                                JOIN epis_documentation ed
                                                  ON ed.id_epis_documentation = pad.id_epis_documentation
                                                LEFT JOIN pat_advance_directive_det padd
                                                  ON padd.id_pat_advance_directive = pad.id_pat_advance_directive
                                                LEFT JOIN advance_directive ad
                                                  ON ad.id_advance_directive = padd.id_advance_directive
                                                 AND ad.flg_available = pk_alert_constant.g_yes
                                                LEFT JOIN doc_type dt_i
                                                  ON dt_i.id_doc_type = ad.id_doc_type
                                                LEFT JOIN (SELECT DISTINCT ad_e.id_doc_area, ad_e.id_doc_type
                                                            FROM advance_directive ad_e
                                                           WHERE ad_e.flg_available = pk_alert_constant.g_yes) t
                                                  ON t.id_doc_area = ed.id_doc_area
                                               WHERE pad.id_patient = i_pat
                                                 AND pad.flg_status = pk_alert_constant.g_active
                                                 AND ed.flg_status = pk_alert_constant.g_active))
             ORDER BY id_doc_type;
    
        l_id_doc_types   table_number;
        l_desc_doc_types table_varchar;
        l_id_doc_ext     table_number;
    
        counter PLS_INTEGER := 1;
        l_default_i CONSTANT VARCHAR2(1) := 'I';
    
    BEGIN
    
        g_error          := 'INIT COLLECTIONS';
        l_id_doc_types   := table_number();
        l_desc_doc_types := table_varchar();
        l_id_doc_ext     := table_number();
    
        g_error := 'GET PROFILE_TEMPLATE';
        IF NOT pk_doc.get_profile_template(i_lang, i_prof, l_my_pt, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'LOOP DOC_TYPES';
        FOR r_doc_type IN c_doc_types
        LOOP
            l_id_pat_doc := NULL;
            g_error      := 'CALL TO GET_ADV_DIR_DOC_ID';
            IF NOT get_adv_dir_doc_id(i_lang           => i_lang,
                                      i_patient        => i_pat,
                                      i_doc_type       => r_doc_type.id_doc_type,
                                      i_doc_area       => NULL,
                                      o_id_pat_adv_dir => l_id_pat_adv_dir,
                                      o_id_pat_doc     => l_id_pat_doc,
                                      o_error          => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF l_id_pat_doc IS NOT NULL
            THEN
                g_error := 'GET ID_DOC_EXTERNAL';
                SELECT p.id_doc_external
                  INTO l_id_doc_external
                  FROM pat_adv_directive_doc p
                 WHERE p.id_pat_adv_directive_doc = l_id_pat_doc;
            END IF;
        
            g_error := 'CALL TO GET_DOC_LIST_TYPE';
            IF NOT pk_doc.get_doc_list_type(i_lang     => i_lang,
                                            i_prof     => i_prof,
                                            i_patient  => i_pat,
                                            i_episode  => i_episode,
                                            i_doc_type => r_doc_type.id_doc_type,
                                            i_btn      => i_btn,
                                            o_list     => l_list,
                                            o_error    => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'LOOP l_list';
            LOOP
                g_error := 'FETCH RECORD';
                FETCH l_list
                    INTO l_rec_list;
            
                EXIT WHEN l_list%NOTFOUND OR l_rec_list.id_doc_external <> nvl(l_id_doc_external, -1);
            
            END LOOP;
        
            CLOSE l_list;
        
            g_error := 'ASSING VALUES';
            IF l_rec_list.title IS NOT NULL
               AND l_rec_list.id_doc_external <> nvl(l_id_doc_external, -1)
            THEN
                l_id_doc_types.extend;
                l_desc_doc_types.extend;
                l_id_doc_ext.extend;
            
                l_id_doc_types(counter) := r_doc_type.id_doc_type;
                l_desc_doc_types(counter) := l_rec_list.title || ' (' || l_rec_list.typedesc || ') - ' ||
                                             l_rec_list.lastupdateddate;
                l_id_doc_ext(counter) := l_rec_list.id_doc_external;
            
                counter := counter + 1;
            END IF;
        
            l_rec_list := NULL;
        
        END LOOP;
    
        g_error := 'OPEN CURSOR o_list';
        OPEN o_list FOR
            SELECT a.column_value id_doc_type, b.column_value desc_doc, c.column_value id_doc, l_default_i flg_default
              FROM (SELECT column_value, rownum num
                      FROM TABLE(l_id_doc_types)) a,
                   (SELECT column_value, rownum num
                      FROM TABLE(l_desc_doc_types)) b,
                   (SELECT column_value, rownum num
                      FROM TABLE(l_id_doc_ext)) c
             WHERE a.num = b.num
               AND b.num = c.num;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_list);
            RETURN error_handling_ext(i_lang,
                                      'GET_ADV_DIR_DOC_IMPORT',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLERRM,
                                      FALSE,
                                      o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN error_handling_ext(i_lang, 'GET_ADV_DIR_DOC_IMPORT', g_error, SQLERRM, FALSE, o_error);
    END get_adv_dir_doc_import;

    /********************************************************************************************
    * Cancels an advance directive record (documentation or attached document)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_type                   Cancellation type: E - epis_documentation, D - document
    * @param i_id_doc                 document ID to be cancelled
    * @param i_id_epis_doc            the documentation episode ID to be cancelled
    * @param i_id_cancel_reason       Cancellation reason ID
    * @param i_notes                  Cancel Notes
    * @param o_error                  Error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   16-02-2009
    **********************************************************************************************/
    FUNCTION cancel_advance_directive
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_type             IN VARCHAR2,
        i_id_doc           IN doc_external.id_doc_external%TYPE,
        i_id_epis_doc      IN epis_documentation.id_epis_documentation%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error t_error_out;
        l_type_epis_doc CONSTANT VARCHAR2(1) := 'E';
        l_type_doc      CONSTANT VARCHAR2(1) := 'D';
        l_flg_show         VARCHAR2(50);
        l_msg_title        VARCHAR2(200);
        l_msg_text         VARCHAR2(200);
        l_button           VARCHAR2(50);
        l_rowids           table_varchar;
        l_tbl_pat_doc      table_number := table_number();
        l_tbl_doc_external table_number := table_number();
    
    BEGIN
    
        IF i_type = l_type_epis_doc
        THEN
            g_error := 'CANCEL EPIS_DOCUMENTATION';
            IF NOT pk_touch_option.cancel_epis_doc_no_commit(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_id_epis_doc => i_id_epis_doc,
                                                             i_notes       => i_notes,
                                                             i_test        => g_no,
                                                             o_flg_show    => l_flg_show,
                                                             o_msg_title   => l_msg_title,
                                                             o_msg_text    => l_msg_text,
                                                             o_button      => l_button,
                                                             o_error       => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'CANCEL PAT_ADVANCE_DIRECTIVE';
            ts_pat_advance_directive.upd(flg_status_in       => g_adv_status_cancel,
                                         id_cancel_reason_in => i_id_cancel_reason,
                                         id_prof_cancel_in   => i_prof.id,
                                         notes_cancel_in     => i_notes,
                                         dt_cancel_in        => current_timestamp,
                                         where_in            => 'id_epis_documentation = ' || i_id_epis_doc,
                                         rows_out            => l_rowids);
        
        ELSIF i_type = l_type_doc
        THEN
            g_error := 'CANCEL DOC';
            IF NOT
                pk_doc.cancel_doc_internal(i_lang => i_lang, i_prof => i_prof, i_id_doc => i_id_doc, o_error => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'GET ID_PAT_DOC';
            SELECT id_pat_adv_directive_doc
              BULK COLLECT
              INTO l_tbl_pat_doc
              FROM pat_adv_directive_doc p
             WHERE p.id_doc_external = i_id_doc
               AND p.flg_status = g_doc_status_active;
        
            g_error := 'CANCEL pat_adv_directive_doc';
            FOR i IN l_tbl_pat_doc.first .. l_tbl_pat_doc.last
            LOOP
                ts_pat_adv_directive_doc.upd(flg_status_in       => g_doc_status_cancel,
                                             id_cancel_reason_in => i_id_cancel_reason,
                                             id_prof_cancel_in   => i_prof.id,
                                             notes_cancel_in     => i_notes,
                                             dt_cancel_in        => current_timestamp,
                                             where_in            => 'id_pat_adv_directive_doc = ' || l_tbl_pat_doc(i),
                                             rows_out            => l_rowids);
            END LOOP;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CANCEL_ADVANCE_DIRECTIVE',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLERRM,
                                      TRUE,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'CANCEL_ADVANCE_DIRECTIVE', g_error, SQLERRM, TRUE, o_error);
    END cancel_advance_directive;

    /********************************************************************************************
    * Gets the cancelation information to place in the detail screen
    *
    * @param   I_LANG     language associated to the professional executing the request
    * @param   I_PROF     professional, institution and software ids
    * @param   I_EPIS_DOC documentation record (touch-option ID)
    * @param   i_id_doc   document ID
    * @param   o_det      detail information
    * @param   o_reviews  record review information
    * @param   o_error    Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          26-02-2009
    **********************************************************************************************/
    FUNCTION get_advance_directive_det
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_id_doc   IN doc_external.id_doc_external%TYPE,
        o_det      OUT pk_types.cursor_type,
        o_reviews  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_label_cancel_reason sys_message.desc_message%TYPE;
        l_label_cancel_prof   sys_message.desc_message%TYPE;
        l_label_cancel_date   sys_message.desc_message%TYPE;
        l_label_cancel_notes  sys_message.desc_message%TYPE;
    
        l_id_episode episode.id_episode%TYPE;
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
        l_epis_doc table_number;
        --
        CURSOR c_epis_doc IS
            SELECT ed.id_epis_documentation
              FROM epis_documentation ed
            CONNECT BY PRIOR ed.id_epis_documentation = ed.id_epis_documentation_parent
             START WITH ed.id_epis_documentation = i_epis_doc
            UNION ALL
            SELECT ed.id_epis_documentation
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation <> i_epis_doc
            CONNECT BY PRIOR ed.id_epis_documentation_parent = ed.id_epis_documentation
             START WITH ed.id_epis_documentation = i_epis_doc;
    
    BEGIN
    
        l_label_cancel_reason := pk_message.get_message(i_lang, 'ADVANCE_DIRECTIVES_T014');
        l_label_cancel_prof   := pk_message.get_message(i_lang, 'ADVANCE_DIRECTIVES_T016');
        l_label_cancel_date   := pk_message.get_message(i_lang, 'ADVANCE_DIRECTIVES_T013');
        l_label_cancel_notes  := pk_message.get_message(i_lang, 'ADVANCE_DIRECTIVES_T015');
    
        IF i_epis_doc IS NOT NULL
        THEN
        
            g_error := 'GET EPISODE ID';
            SELECT id_episode
              INTO l_id_episode
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation = i_epis_doc;
        
            g_error := 'OPEN C_EPIS_DOC';
            OPEN c_epis_doc;
            FETCH c_epis_doc BULK COLLECT
                INTO l_epis_doc;
            CLOSE c_epis_doc;
        
            g_error := 'GET PAT ADVANCE DIRECTIVE DET';
            OPEN o_det FOR
                SELECT l_label_cancel_reason cancel_reason_title,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, p.id_cancel_reason) cancel_reason,
                       l_label_cancel_prof prof_cancel_title,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_prof_cancel) prof_cancel,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        p.id_prof_cancel,
                                                        p.dt_cancel,
                                                        (SELECT id_episode
                                                           FROM epis_documentation ed
                                                          WHERE ed.id_epis_documentation = p.id_epis_documentation)) spec_cancel,
                       l_label_cancel_notes notes_cancel_title,
                       p.notes_cancel,
                       l_label_cancel_date dt_cancel_title,
                       pk_date_utils.date_char_tsz(i_lang, p.dt_cancel, i_prof.institution, i_prof.software) dt_cancel,
                       pk_sysdomain.get_domain('PAT_ADVANCE_DIRECTIVE.FLG_STATUS', p.flg_status, i_lang) desc_status
                  FROM pat_advance_directive p
                 WHERE p.id_epis_documentation = i_epis_doc;
        
            g_error := 'GET REVIEW';
            IF NOT pk_review.get_group_reviews_by_id(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_episode     => l_id_episode,
                                                     i_id_record_area => l_epis_doc,
                                                     i_flg_context    => pk_review.get_adv_directives_context,
                                                     o_reviews        => o_reviews,
                                                     o_error          => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSIF i_id_doc IS NOT NULL
        THEN
            g_error := 'GET PAT ADVANCE DIRECTIVE DOC DET';
            OPEN o_det FOR
                SELECT l_label_cancel_reason cancel_reason_title,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, p.id_cancel_reason) cancel_reason,
                       l_label_cancel_prof prof_cancel_title,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_prof_cancel) prof_cancel,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_prof_cancel, NULL, NULL) spec_cancel,
                       l_label_cancel_notes notes_cancel_title,
                       p.notes_cancel,
                       l_label_cancel_date dt_cancel_title,
                       pk_date_utils.date_char_tsz(i_lang, p.dt_cancel, i_prof.institution, i_prof.software) dt_cancel
                  FROM pat_adv_directive_doc p
                 WHERE p.id_doc_external = i_id_doc
                   AND p.flg_status IN (g_doc_status_active, g_doc_status_cancel);
        
            pk_types.open_my_cursor(o_reviews);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_det);
            pk_types.open_my_cursor(o_reviews);
            RETURN error_handling_ext(i_lang,
                                      'GET_ADVANCE_DIRECTIVE_DET',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLERRM,
                                      FALSE,
                                      o_error);
        
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_det);
            pk_types.open_my_cursor(o_reviews);
            RETURN error_handling_ext(i_lang, 'GET_ADVANCE_DIRECTIVE_DET', g_error, SQLERRM, FALSE, o_error);
    END get_advance_directive_det;

    /********************************************************************************************
    * Sets the advance directive review information
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_epis_doc       documentation record (touch-option ID)
    * @param   i_review_notes   revision notes
    * @param   i_episode        Episode id
    * @param   o_error          Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          27-10-2009
    **********************************************************************************************/
    FUNCTION set_adv_dir_review
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_doc     IN epis_documentation.id_epis_documentation%TYPE,
        i_review_notes IN review_detail.review_notes%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ADV_DIR_REVIEW';
    BEGIN
        g_error := 'CALL SET_ADV_DIR_REVIEW_INT';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT set_adv_dir_review_int(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_epis_doc     => i_epis_doc,
                                      i_review_notes => i_review_notes,
                                      i_episode      => i_episode,
                                      o_error        => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        ELSE
            COMMIT;
            RETURN TRUE;
        END IF;
    END set_adv_dir_review;

    /********************************************************************************************
    * Sets all episose advance directives as reviewed
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_id_summary_page   Summary page id
    * @param   i_pat               Patient ID
    * @param   i_episode           Episode ID
    * @param   o_error             Error message
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION set_adv_dir_review_all
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SUMMARY_PAGE_SECTIONS';
        --
        l_exception EXCEPTION;
        --
        c_sections    pk_summary_page.t_cur_section;
        l_tbl_section pk_summary_page.t_coll_section;
        l_rec_section pk_summary_page.t_rec_section;
        --
        c_dar     pk_touch_option.t_cur_doc_area_register;
        l_tbl_dar pk_touch_option.t_coll_doc_area_register;
        l_rec_dar pk_touch_option.t_rec_doc_area_register;
        --
        l_doc_area_val       pk_types.cursor_type;
        l_template_layouts   pk_types.cursor_type;
        l_doc_area_component pk_types.cursor_type;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'GET ALL DOC_AREAS AVAILABLE TO THIS PROF: Professional(' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                   i_prof.software || '); ID_SUMM_PAGE: ' || i_id_summary_page || '; I_PAT: ' || i_pat ||
                   '; I_EPISODE: ' || i_episode;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_summary_page => i_id_summary_page,
                                                         i_pat             => i_pat,
                                                         o_sections        => c_sections,
                                                         o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'FETCH ALL SECTION INTO TABLE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        FETCH c_sections BULK COLLECT
            INTO l_tbl_section;
    
        g_error := 'CLOSE C_SECTIONS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        CLOSE c_sections;
    
        IF l_tbl_section IS NOT NULL
           AND l_tbl_section.count > 0
        THEN
            g_error := 'RUN THROUGH ALL SECTIONS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            FOR i IN l_tbl_section.first .. l_tbl_section.last
            LOOP
                l_rec_section := l_tbl_section(i);
            
                g_error := 'GET DOC_AREA DOCS FOR DOC_AREA: ' || l_rec_section.id_doc_area;
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF NOT pk_summary_page.get_summ_page_doc_area_pat(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_episode            => i_episode,
                                                                  i_pat                => i_pat,
                                                                  i_doc_area           => l_rec_section.id_doc_area,
                                                                  o_doc_area_register  => c_dar,
                                                                  o_doc_area_val       => l_doc_area_val,
                                                                  o_template_layouts   => l_template_layouts,
                                                                  o_doc_area_component => l_doc_area_component,
                                                                  o_error              => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                g_error := 'FETCH ALL DOCS INTO TABLE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                FETCH c_dar BULK COLLECT
                    INTO l_tbl_dar;
            
                g_error := 'CLOSE C_DAR';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                CLOSE c_dar;
            
                IF l_tbl_dar IS NOT NULL
                   AND l_tbl_dar.count > 0
                THEN
                    g_error := 'RUN THROUGH ALL DOCS';
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
                    FOR i IN l_tbl_dar.first .. l_tbl_dar.last
                    LOOP
                        l_rec_dar := l_tbl_dar(i);
                    
                        IF l_rec_dar.flg_status = pk_touch_option.g_epis_doc_active
                        THEN
                            g_error := 'CALL SET_ADV_DIR_REVIEW_INT';
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package_name,
                                                 sub_object_name => l_func_name);
                            IF NOT set_adv_dir_review_int(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_epis_doc     => l_rec_dar.id_epis_documentation,
                                                          i_review_notes => NULL,
                                                          i_episode      => i_episode,
                                                          o_error        => o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        END IF;
                    END LOOP;
                END IF;
            END LOOP;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END set_adv_dir_review_all;

    /********************************************************************************************
    * Returns the sections within a summary page
    *
    * @param   i_lang             language associated to the professional executing the request
    * @param   i_prof             professional, institution and software ids
    * @param   i_id_summary_page  Summary page ID
    * @param   i_pat              Patient ID
    * @param   i_episode           Episode ID
    * @param   o_sections         Cursor containing the sections info
    * @param   o_epis_review      Cursor containing the episode review info
    * @param   o_error            Error message
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_summary_page_sections
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_epis_review     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SUMMARY_PAGE_SECTIONS';
        --
        l_exception EXCEPTION;
        --
        c_reviews         pk_review.t_cur_reviews;
        l_table_reviews   pk_review.t_tab_reviews;
        l_cur_rec_review  pk_review.t_rec_review;
        l_last_rec_review pk_review.t_rec_review;
        l_title           sys_message.desc_message%TYPE;
        --
        l_tbl_epis_doc            table_number;
        l_tbl_disct_reviewed_docs table_number;
        --
        l_flg_dnar_review    VARCHAR2(1);
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'Call pk_summary_page.get_summary_page_sections';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_summary_page => i_id_summary_page,
                                                         i_pat             => i_pat,
                                                         o_sections        => o_sections,
                                                         o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET ALL EPIS_DOCUMENTATION OF CURRENT EPISODE: ' || i_episode;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT ed.id_epis_documentation
          BULK COLLECT
          INTO l_tbl_epis_doc
          FROM pat_advance_directive pad
          JOIN epis_documentation ed
            ON ed.id_epis_documentation = pad.id_epis_documentation
          JOIN summary_page_section sps
            ON sps.id_doc_area = ed.id_doc_area
         WHERE pad.id_patient = i_pat
           AND sps.id_summary_page = i_id_summary_page
           AND ed.flg_status = pk_alert_constant.g_active;
    
        g_error := 'GET ALL REVIEWS MADE ON EPIS_DOC: ' || pk_utils.concat_table(l_tbl_epis_doc);
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        --Get reviews of epis_docs in current episode
        IF NOT pk_review.get_group_reviews_by_id(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_episode     => i_episode,
                                                 i_id_record_area => l_tbl_epis_doc,
                                                 i_flg_context    => pk_review.get_adv_directives_context,
                                                 o_reviews        => c_reviews,
                                                 o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'FETCH ALL REVIEWS INTO TABLE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        FETCH c_reviews BULK COLLECT
            INTO l_table_reviews;
    
        g_error := 'CLOSE C_REVIEWS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        CLOSE c_reviews;
    
        IF l_table_reviews IS NOT NULL
           AND l_table_reviews.count > 0
        THEN
            l_tbl_disct_reviewed_docs := table_number();
        
            g_error := 'SEARCH FOR LAST REVIEW INFO';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            FOR i IN l_table_reviews.first .. l_table_reviews.last
            LOOP
                l_cur_rec_review := l_table_reviews(i);
            
                IF l_cur_rec_review.id_episode = i_episode
                   AND nvl(l_last_rec_review.dt_review, l_cur_rec_review.dt_review) <= l_cur_rec_review.dt_review
                THEN
                    l_last_rec_review := l_cur_rec_review;
                END IF;
            
                l_tbl_disct_reviewed_docs.extend();
                l_tbl_disct_reviewed_docs(l_tbl_disct_reviewed_docs.count) := l_cur_rec_review.id_record_area;
            END LOOP;
        END IF;
    
        g_error := 'GET DISTINCT EPIS_DOC REVIEWS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF l_tbl_disct_reviewed_docs IS NOT NULL
           AND l_tbl_disct_reviewed_docs.count > 0
        THEN
            l_tbl_disct_reviewed_docs := l_tbl_disct_reviewed_docs MULTISET UNION DISTINCT l_tbl_disct_reviewed_docs;
        END IF;
    
        g_error := 'CHECK DNAR REVIEW STATE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT check_ad_dnar_rev_all_int(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_patient    => i_pat,
                                         i_episode    => i_episode,
                                         o_flg_review => l_flg_dnar_review,
                                         o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET REVIEW MESSAGE STATE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF l_last_rec_review.id_record_area IS NULL
        THEN
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_not_reviewed);
        ELSIF l_tbl_disct_reviewed_docs IS NOT NULL
              AND l_tbl_epis_doc.count = l_tbl_disct_reviewed_docs.count
              AND (l_flg_dnar_review = g_flg_state_review_all OR l_flg_dnar_review IS NULL)
        THEN
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_reviewed);
        ELSIF l_flg_dnar_review = g_flg_state_review_not
        THEN
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_not_reviewed);
        ELSE
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_part_reviewed);
        END IF;
    
        g_error := 'OPEN CURSOR O_EPIS_REVIEW';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_epis_review FOR
            SELECT l_title title,
                   l_last_rec_review.dt_reg_str dt_last_review,
                   l_last_rec_review.prof_reg nick_name,
                   l_last_rec_review.prof_spec_reg desc_speciality,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, l_last_rec_review.dt_review, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    l_last_rec_review.dt_review,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   pk_date_utils.date_char_tsz(i_lang, l_last_rec_review.dt_review, i_prof.institution, i_prof.software) date_hour_target
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_sections);
            pk_types.open_my_cursor(o_epis_review);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sections);
            pk_types.open_my_cursor(o_epis_review);
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END get_summary_page_sections;

    /********************************************************************************************
    * Returns documentation data for a given patient (the one referenced on the current episode)
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_episode           Episode ID
    * @param   i_pat               Patient ID
    * @param   i_doc_area          Doc area ID
    * @param   i_flg_scope         Scope
    * @param   o_doc_area_register Doc area data
    * @param   o_doc_area_val      Documentation data for the patient's episodes
    * @param   o_template_layouts  Cursor containing the layout for each template used
    * @param   o_error             Error message
    *
    * @value   i_flg_scope         E - Adv. Directives inserted/edited or validated in the current episode
    *                              V - Adv. Directives inserted/edited or validated in the current visit
    *                              P - All Patient Adv. Directives
    *                              F - Flash funtion
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_spdap_int
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_pat                IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_flg_scope          IN VARCHAR2,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SPDAP_INT';
        --
        l_zero CONSTANT PLS_INTEGER := 0;
        --
        l_exception EXCEPTION;
        --
        c_doc_area_register pk_touch_option.t_cur_doc_area_register;
        r_doc_area_register pk_touch_option.t_rec_doc_area_register;
        --
        l_table_dar          t_table_adv_dir_dar := t_table_adv_dir_dar();
        l_flg_reviewed       VARCHAR2(1);
        l_flg_scope          VARCHAR2(1);
        l_insert_into_result BOOLEAN;
    
        FUNCTION get_flg_was_reviewed(i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE)
            RETURN VARCHAR2 IS
            l_sub_func_name CONSTANT VARCHAR2(30) := 'GET_FLG_WAS_REVIEWED';
            --
            l_flg_was_reviewed VARCHAR2(1);
            l_flg_dnar_review  VARCHAR2(1);
        
            c_reviews       pk_review.t_cur_reviews;
            l_table_reviews pk_review.t_tab_reviews;
        BEGIN
            --Verify if this advanced directive was reviewed in the current episode
            g_error := 'GET REVIEW';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_sub_func_name);
            IF NOT pk_review.get_reviews_by_id(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_id_episode     => i_episode,
                                               i_id_record_area => i_epis_documentation,
                                               i_flg_context    => pk_review.get_adv_directives_context,
                                               o_reviews        => c_reviews,
                                               o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'FETCH ALL REVIEWS INTO TABLE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_sub_func_name);
            FETCH c_reviews BULK COLLECT
                INTO l_table_reviews;
        
            g_error := 'CLOSE C_REVIEWS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_sub_func_name);
            CLOSE c_reviews;
        
            IF l_table_reviews IS NOT NULL
               AND l_table_reviews.count > l_zero
            THEN
                g_error := 'CHECK DNAR REVIEW STATE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF NOT check_ad_dnar_rev_all_int(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_patient            => i_pat,
                                                 i_episode            => i_episode,
                                                 i_epis_documentation => i_epis_documentation,
                                                 o_flg_review         => l_flg_dnar_review,
                                                 o_error              => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                g_error := 'SET FLG_WAS_REVIWED';
                pk_alertlog.log_debug(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => l_sub_func_name);
                IF l_flg_dnar_review = g_flg_state_review_all
                   OR l_flg_dnar_review IS NULL
                THEN
                    l_flg_was_reviewed := g_flg_state_review_all;
                ELSIF l_flg_dnar_review = g_flg_state_review_part
                THEN
                    l_flg_was_reviewed := g_flg_state_review_part;
                ELSE
                    l_flg_was_reviewed := g_flg_state_review_not;
                END IF;
            ELSE
                l_flg_was_reviewed := g_flg_state_review_not;
            END IF;
        
            RETURN l_flg_was_reviewed;
        END get_flg_was_reviewed;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'Call pk_summary_page.get_summ_page_doc_area_pat';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_summary_page.get_summ_page_doc_area_pat(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_episode            => i_episode,
                                                          i_pat                => i_pat,
                                                          i_doc_area           => i_doc_area,
                                                          o_doc_area_register  => c_doc_area_register,
                                                          o_doc_area_val       => o_doc_area_val,
                                                          o_template_layouts   => o_template_layouts,
                                                          o_doc_area_component => o_doc_area_component,
                                                          o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'RUNS THROUGH THE CURSOR C_DOC_AREA_REGISTER';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        LOOP
            FETCH c_doc_area_register
                INTO r_doc_area_register;
            EXIT WHEN c_doc_area_register%NOTFOUND;
        
            IF nvl(i_flg_scope, pk_advanced_directives.g_sum_page_doc_area_f) =
               pk_advanced_directives.g_sum_page_doc_area_f
            THEN
                --Flash scope
                --This value isn't used by flash so we don't need to calculate it
                l_flg_scope := NULL;
            ELSE
                --Reports scope
                IF NOT pk_advanced_directives.get_flg_scope(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_epis_documentation => r_doc_area_register.id_epis_documentation,
                                                            i_episode            => i_episode,
                                                            o_scope              => l_flg_scope,
                                                            o_error              => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            l_flg_reviewed := get_flg_was_reviewed(i_epis_documentation => r_doc_area_register.id_epis_documentation);
        
            CASE
                WHEN i_flg_scope IN
                     (pk_advanced_directives.g_sum_page_doc_area_p, pk_advanced_directives.g_sum_page_doc_area_f) THEN
                    l_insert_into_result := TRUE;
                WHEN i_flg_scope = pk_advanced_directives.g_sum_page_doc_area_v
                     AND l_flg_scope IN
                     (pk_advanced_directives.g_sum_page_doc_area_v, pk_advanced_directives.g_sum_page_doc_area_e) THEN
                    l_insert_into_result := TRUE;
                WHEN i_flg_scope = pk_advanced_directives.g_sum_page_doc_area_e
                     AND l_flg_scope IN (pk_advanced_directives.g_sum_page_doc_area_e) THEN
                    l_insert_into_result := TRUE;
                ELSE
                    l_insert_into_result := FALSE;
            END CASE;
        
            IF l_insert_into_result
            THEN
                --Fill record information
                g_error := 'FILL TABLE DAR';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_table_dar.extend;
                l_table_dar(l_table_dar.count) := t_rec_adv_dir_dar(order_by_default      => r_doc_area_register.order_by_default,
                                                                    order_default         => r_doc_area_register.order_default,
                                                                    id_epis_documentation => r_doc_area_register.id_epis_documentation,
                                                                    PARENT                => r_doc_area_register.parent,
                                                                    id_doc_template       => r_doc_area_register.id_doc_template,
                                                                    template_desc         => r_doc_area_register.template_desc,
                                                                    dt_creation           => r_doc_area_register.dt_creation,
                                                                    dt_creation_tstz      => r_doc_area_register.dt_creation_tstz,
                                                                    dt_register           => r_doc_area_register.dt_register,
                                                                    id_professional       => r_doc_area_register.id_professional,
                                                                    nick_name             => r_doc_area_register.nick_name,
                                                                    desc_speciality       => r_doc_area_register.desc_speciality,
                                                                    id_doc_area           => r_doc_area_register.id_doc_area,
                                                                    flg_status            => r_doc_area_register.flg_status,
                                                                    desc_status           => r_doc_area_register.desc_status,
                                                                    flg_current_episode   => r_doc_area_register.flg_current_episode,
                                                                    notes                 => r_doc_area_register.notes,
                                                                    dt_last_update        => r_doc_area_register.dt_last_update,
                                                                    dt_last_update_tstz   => r_doc_area_register.dt_last_update_tstz,
                                                                    flg_detail            => r_doc_area_register.flg_detail,
                                                                    flg_external          => r_doc_area_register.flg_external,
                                                                    flg_type_register     => r_doc_area_register.flg_type_register,
                                                                    flg_table_origin      => r_doc_area_register.flg_table_origin,
                                                                    flg_was_reviewed      => l_flg_reviewed,
                                                                    flg_scope             => l_flg_scope,
                                                                    signature             => r_doc_area_register.signature);
            END IF;
        END LOOP;
    
        g_error := 'OPEN CURSOR O_DOC_AREA_REGISTER';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_doc_area_register FOR
            SELECT t.order_by_default,
                   t.order_default,
                   t.id_epis_documentation,
                   t.parent,
                   t.id_doc_template,
                   t.template_desc,
                   t.dt_creation,
                   t.dt_creation_tstz,
                   t.dt_register,
                   t.id_professional,
                   t.nick_name,
                   t.desc_speciality,
                   t.id_doc_area,
                   t.flg_status,
                   t.desc_status,
                   t.flg_current_episode,
                   t.notes,
                   t.dt_last_update,
                   t.dt_last_update_tstz,
                   t.flg_detail,
                   t.flg_external,
                   t.flg_type_register,
                   t.flg_table_origin,
                   t.flg_was_reviewed,
                   t.flg_scope,
                   t.signature
              FROM TABLE(l_table_dar) t;
    
        g_error := 'CLOSE CURSOR C_DOC_AREA_REGISTER';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        CLOSE c_doc_area_register;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END get_spdap_int;

    /********************************************************************************************
    * Returns documentation data for a given patient (the one referenced on the current episode)
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_episode           Episode ID
    * @param   i_pat               Patient ID
    * @param   i_doc_area          Doc area ID
    * @param   o_doc_area_register Doc area data
    * @param   o_doc_area_val      Documentation data for the patient's episodes
    * @param   o_template_layouts  Cursor containing the layout for each template used
    * @param   o_error             Error message
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_pat                IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SUMM_PAGE_DOC_AREA_PAT';
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init - Flash function';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'Call pk_advanced_directives.get_spdap_int';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT get_spdap_int(i_lang               => i_lang,
                             i_prof               => i_prof,
                             i_episode            => i_episode,
                             i_pat                => i_pat,
                             i_doc_area           => i_doc_area,
                             i_flg_scope          => pk_advanced_directives.g_sum_page_doc_area_f,
                             o_doc_area_register  => o_doc_area_register,
                             o_doc_area_val       => o_doc_area_val,
                             o_template_layouts   => o_template_layouts,
                             o_doc_area_component => o_doc_area_component,
                             o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END get_summ_page_doc_area_pat;

    /********************************************************************************************
    * Returns documentation data for a given patient (This function is used in reports)
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_episode           Episode ID
    * @param   i_pat               Patient ID
    * @param   i_doc_area          Doc area ID
    * @param   i_flg_scope         Scope
    * @param   o_doc_area_register Doc area data
    * @param   o_doc_area_val      Documentation data for the patient's episodes
    * @param   o_template_layouts  Cursor containing the layout for each template used
    * @param   o_error             Error message
    *
    * @value   i_flg_scope         E - Adv. Directives inserted/edited or validated in the current episode
    *                              V - Adv. Directives inserted/edited or validated in the current visit
    *                              P - All Patient Adv. Directives
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_pat                IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_flg_scope          IN VARCHAR2,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SUMM_PAGE_DOC_AREA_PAT';
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init - Reports function; FLG_SCOPE: ' || i_flg_scope;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'Call pk_advanced_directives.get_spdap_int';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT get_spdap_int(i_lang               => i_lang,
                             i_prof               => i_prof,
                             i_episode            => i_episode,
                             i_pat                => i_pat,
                             i_doc_area           => i_doc_area,
                             i_flg_scope          => i_flg_scope,
                             o_doc_area_register  => o_doc_area_register,
                             o_doc_area_val       => o_doc_area_val,
                             o_template_layouts   => o_template_layouts,
                             o_doc_area_component => o_doc_area_component,
                             o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END get_summ_page_doc_area_pat;

    /********************************************************************************************
    * Get adv. dir. type of icon to show in header
    *
    * @param   i_episode        Episode ID
    *
    * @return  DNAR Physician or DNAR Patient or Normal Adv. Dir. or NULL (no adv. dir. data for current patient)
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_adv_dir_icon_type_int
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_varchar2 IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ADV_DIR_ICON_TYPE_INT';
    
        l_one CONSTANT PLS_INTEGER := 1;
    
        l_dnar_diff_cat sys_config.value%TYPE;
    
        l_dnar_phy  PLS_INTEGER;
        l_dnar_nur  PLS_INTEGER;
        l_dnar_pat  VARCHAR2(1);
        l_pat_alert PLS_INTEGER;
        l_adv_dir   PLS_INTEGER;
    
        l_ret     table_varchar2 := table_varchar2();
        l_patient patient.id_patient%TYPE;
    BEGIN
    
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'VALIDATE DNAR PHYSICIAN';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'GET CFG - ' || g_cfg_dnar_diff_cat;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        l_dnar_diff_cat := pk_sysconfig.get_config(i_code_cf => g_cfg_dnar_diff_cat, i_prof => i_prof);
    
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        IF (pk_advanced_directives.is_to_review_dnar(i_lang    => NULL,
                                                     i_prof    => i_prof,
                                                     i_patient => pk_episode.get_id_patient(i_episode),
                                                     i_episode => i_episode) = pk_alert_constant.g_no OR
           nvl(l_dnar_diff_cat, pk_alert_constant.g_no) = pk_alert_constant.g_no)
        THEN
            IF nvl(l_dnar_diff_cat, pk_alert_constant.g_no) = pk_alert_constant.g_no
            THEN
            
                --Verify DNAR Physician
                SELECT COUNT(*) show_dnar_physician
                  INTO l_dnar_phy
                  FROM (SELECT row_number() over(ORDER BY ed.dt_last_update_tstz DESC) line_number
                          FROM epis_documentation ed
                          JOIN epis_documentation_det edd
                            ON edd.id_epis_documentation = ed.id_epis_documentation
                          JOIN pat_advance_directive pad
                            ON pad.id_epis_documentation = ed.id_epis_documentation
                          JOIN advance_directive ad
                            ON ad.id_doc_area = ed.id_doc_area
                           AND ad.flg_type = pk_advanced_directives.g_flg_adv_type_d
                         WHERE pad.id_patient = l_patient
                           AND ed.flg_status = pk_advanced_directives.g_adv_status_active) t
                 WHERE t.line_number = l_one;
            
                IF l_dnar_phy = l_one
                THEN
                    l_ret.extend;
                    l_ret(l_ret.last) := g_adv_dir_icon_type_dph;
                END IF;
            ELSIF l_dnar_diff_cat = pk_alert_constant.g_yes
            THEN
                --Verify DNAR Physician
                SELECT COUNT(*) show_dnar_physician
                  INTO l_dnar_phy
                  FROM (SELECT row_number() over(ORDER BY rd.dt_review DESC) line_number
                          FROM epis_documentation ed
                          JOIN review_detail rd
                            ON rd.id_record_area = ed.id_epis_documentation
                           AND rd.flg_context = pk_review.get_adv_directives_context
                          JOIN epis_documentation_det edd
                            ON edd.id_epis_documentation = ed.id_epis_documentation
                          JOIN pat_advance_directive pad
                            ON pad.id_epis_documentation = ed.id_epis_documentation
                          JOIN advance_directive ad
                            ON ad.id_doc_area = ed.id_doc_area
                           AND ad.flg_type = pk_advanced_directives.g_flg_adv_type_d
                          JOIN episode epis
                            ON epis.id_episode = ed.id_episode
                          JOIN epis_info ei
                            ON ei.id_episode = epis.id_episode
                         WHERE pad.id_patient = l_patient
                           AND ed.flg_status = pk_advanced_directives.g_adv_status_active
                           AND nvl(pk_advanced_directives.is_to_review_dnar(i_lang                  => NULL,
                                                                            i_prof                  => profissional(rd.id_professional,
                                                                                                                    epis.id_institution,
                                                                                                                    ei.id_software),
                                                                            i_patient               => pad.id_patient,
                                                                            i_episode               => i_episode,
                                                                            i_profile_template      => pk_prof_utils.get_prof_profile_template(i_prof => profissional(rd.id_professional,
                                                                                                                                                                      epis.id_institution,
                                                                                                                                                                      ei.id_software)),
                                                                            i_pat_advance_directive => pad.id_pat_advance_directive),
                                   pk_alert_constant.g_no) = pk_alert_constant.g_no
                           AND pk_prof_utils.get_category(i_lang => NULL,
                                                          i_prof => profissional(rd.id_professional,
                                                                                 epis.id_institution,
                                                                                 ei.id_software)) =
                               pk_alert_constant.g_cat_type_doc) t
                 WHERE t.line_number = l_one;
            
                --Verify DNAR Nurse
                SELECT COUNT(*) show_dnar_nurse
                  INTO l_dnar_nur
                  FROM (SELECT row_number() over(ORDER BY rd.dt_review DESC) line_number
                          FROM epis_documentation ed
                          JOIN review_detail rd
                            ON rd.id_record_area = ed.id_epis_documentation
                           AND rd.flg_context = pk_review.get_adv_directives_context
                          JOIN epis_documentation_det edd
                            ON edd.id_epis_documentation = ed.id_epis_documentation
                          JOIN pat_advance_directive pad
                            ON pad.id_epis_documentation = ed.id_epis_documentation
                          JOIN advance_directive ad
                            ON ad.id_doc_area = ed.id_doc_area
                           AND ad.flg_type = pk_advanced_directives.g_flg_adv_type_d
                          JOIN episode epis
                            ON epis.id_episode = ed.id_episode
                          JOIN epis_info ei
                            ON ei.id_episode = epis.id_episode
                         WHERE pad.id_patient = l_patient --CEMR-1710
                           AND ed.flg_status = pk_advanced_directives.g_adv_status_active
                           AND nvl(pk_advanced_directives.is_to_review_dnar(i_lang                  => NULL,
                                                                            i_prof                  => profissional(rd.id_professional,
                                                                                                                    epis.id_institution,
                                                                                                                    ei.id_software),
                                                                            i_patient               => pad.id_patient,
                                                                            i_episode               => i_episode,
                                                                            i_profile_template      => pk_prof_utils.get_prof_profile_template(i_prof => profissional(rd.id_professional,
                                                                                                                                                                      epis.id_institution,
                                                                                                                                                                      ei.id_software)),
                                                                            i_pat_advance_directive => pad.id_pat_advance_directive),
                                   pk_alert_constant.g_no) = pk_alert_constant.g_no
                           AND pk_prof_utils.get_category(i_lang => NULL,
                                                          i_prof => profissional(rd.id_professional,
                                                                                 epis.id_institution,
                                                                                 ei.id_software)) =
                               pk_alert_constant.g_cat_type_nurse) t
                 WHERE t.line_number = l_one;
            
                IF l_dnar_phy = l_one
                   AND l_dnar_nur = l_one
                THEN
                    l_ret.extend;
                    l_ret(l_ret.last) := g_adv_dir_icon_type_dph;
                END IF;
            END IF;
        
            g_error := 'VALIDATE DNAR PAT';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            --Verify DNAR Patient
            BEGIN
                SELECT decode(t.id_doc_element, t.id_doc_element_no, pk_alert_constant.g_yes, pk_alert_constant.g_no) show_dnar_pat
                  INTO l_dnar_pat
                  FROM (SELECT edd.id_doc_element,
                               ad.id_doc_element_no,
                               row_number() over(ORDER BY ed.dt_last_update_tstz DESC) line_number
                          FROM epis_documentation ed
                          JOIN epis_documentation_det edd
                            ON edd.id_epis_documentation = ed.id_epis_documentation
                          JOIN pat_advance_directive pad
                            ON pad.id_epis_documentation = ed.id_epis_documentation
                          JOIN advance_directive ad
                            ON ad.id_doc_area = ed.id_doc_area
                           AND ad.flg_type = pk_advanced_directives.g_flg_adv_type_c
                         WHERE pad.id_patient = l_patient --CEMR-1710
                           AND ed.flg_status = pk_advanced_directives.g_adv_status_active) t
                 WHERE t.line_number = l_one;
            EXCEPTION
                WHEN no_data_found THEN
                    l_dnar_pat := pk_alert_constant.g_no;
            END;
        
            IF l_dnar_pat = pk_alert_constant.g_yes
            THEN
                l_ret.extend;
                l_ret(l_ret.last) := g_adv_dir_icon_type_dp;
            END IF;
        
            g_error := 'VALIDATE ADV DIR';
            --Verify Patient Alert
            BEGIN
                SELECT COUNT(*)
                  INTO l_pat_alert
                  FROM epis_documentation_det edd
                  JOIN doc_element de
                    ON edd.id_doc_element = de.id_doc_element
                  JOIN epis_documentation ed
                    ON ed.id_epis_documentation = edd.id_epis_documentation
                  JOIN advance_directive ad
                    ON ad.id_doc_area = ed.id_doc_area
                  JOIN pat_advance_directive pad
                    ON pad.id_epis_documentation = ed.id_epis_documentation
                 WHERE instr(upper(de.internal_name), 'INACTIVE') = 0
                   AND pad.id_patient = l_patient
                   AND ed.id_doc_area = g_patient_alerts_doc_area
                   AND ad.flg_type = pk_advanced_directives.g_flg_adv_type_a
                   AND ed.flg_status = pk_advanced_directives.g_adv_status_active;
            
                IF l_pat_alert > 0
                THEN
                    l_ret.extend;
                    l_ret(l_ret.last) := g_adv_dir_icon_type_a;
                END IF;
            END;
        
            --Verify adv. dir.
            BEGIN
                SELECT COUNT(*)
                  INTO l_adv_dir
                  FROM epis_documentation ed
                  JOIN epis_documentation_det edd
                    ON edd.id_epis_documentation = ed.id_epis_documentation
                  JOIN pat_advance_directive pad
                    ON pad.id_epis_documentation = ed.id_epis_documentation
                  JOIN advance_directive ad
                    ON ad.id_doc_area = ed.id_doc_area
                  LEFT JOIN pat_advance_directive_det padd
                    ON pad.id_pat_advance_directive = padd.id_pat_advance_directive
                 WHERE pad.id_patient = l_patient
                   AND ed.flg_status = pk_advanced_directives.g_adv_status_active
                   AND ((ad.flg_type NOT IN (pk_advanced_directives.g_flg_adv_type_c,
                                             pk_advanced_directives.g_flg_adv_type_d,
                                             pk_advanced_directives.g_flg_adv_type_a) AND
                       padd.flg_advance_directive IS NULL) OR ad.flg_type = pk_advanced_directives.g_flg_adv_type_c AND
                       padd.flg_advance_directive = pk_alert_constant.g_yes AND
                       padd.id_advance_directive = ad.id_advance_directive);
            END;
        
            IF l_adv_dir >= l_one
            THEN
                l_ret.extend;
                l_ret(l_ret.last) := g_adv_dir_icon_type_n;
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_varchar2();
    END get_adv_dir_icon_type_int;

    /********************************************************************************************
    * Get adv. dir. icon
    *
    * @param   i_episode        Episode ID
    *
    * @return  Advanced directive icon
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_header_icon_int
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_HEADER_ICON_INT';
    
        l_icon_adv_dir_black CONSTANT VARCHAR2(50) := 'HeaderAdvDirectivesIcon';
        l_icon_adv_dir_red   CONSTANT VARCHAR2(50) := 'HeaderAdvDirectivesRedIcon';
    
        l_icon table_varchar2;
        l_ret  VARCHAR2(50);
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'SET ICON TO SHOW';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        l_icon := get_adv_dir_icon_type_int(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        CASE l_icon(l_icon.first)
            WHEN g_adv_dir_icon_type_dph THEN
                l_ret := l_icon_adv_dir_black; --l_icon_adv_dir_red EMR-463
            WHEN g_adv_dir_icon_type_dp THEN
                l_ret := l_icon_adv_dir_black; --l_icon_adv_dir_red EMR-463;
            WHEN g_adv_dir_icon_type_a THEN
                l_ret := l_icon_adv_dir_black; --l_icon_adv_dir_red EMR-463;
            WHEN g_adv_dir_icon_type_n THEN
                l_ret := l_icon_adv_dir_black;
            ELSE
                l_ret := NULL;
        END CASE;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_header_icon_int;

    /********************************************************************************************
    * Get adv. dir. icon
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_episode        Episode ID
    *
    * @return  Advanced directive icon
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_header_icon
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_HEADER_ICON';
    BEGIN
        g_error := 'CALL GET_HEADER_ICON_INT';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        RETURN get_header_icon_int(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    END get_header_icon;

    /********************************************************************************************
    * Sets the advance directive review information
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_episode        Episode ID
    * @param   o_text           Message "Advance directives"/"Patient"/"Physician"
    * @param   o_error          Error message
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_header_text
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_text    OUT table_varchar2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SUMM_PAGE_DOC_AREA_PAT';
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'Call get_header_text2_int';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        o_text := get_adv_dir_icon_type_int(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END get_header_text;

    /********************************************************************************************
    * Gets the scope of doc.
    *   --if current epis_document episode
    *   --   - is equal to current episode then set scope as episode
    *   --   - was inserted in the same visit then set scope as visit
    *   --   - otherwise set scope as patient
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_epis_documentation   Episode documentation ID
    * @param   i_episode              Episode ID
    * @param   o_scope                Epis Documentation Scope
    * @param   o_error                Error message
    *
    * @values  o_scope   E - Episode
    *                    V - Visit
    *                    P - Patient
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_flg_scope
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_episode            IN epis_documentation.id_episode%TYPE,
        o_scope              OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_FLG_SCOPE';
        --
        l_pipe CONSTANT VARCHAR2(1) := '|';
        l_one  CONSTANT PLS_INTEGER := 1;
        l_two  CONSTANT PLS_INTEGER := 2;
    BEGIN
        BEGIN
            g_error := 'VERIFY IF SCOPE IS "E" Or "V"';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            SELECT decode(i_episode,
                          t.id_episode,
                          pk_advanced_directives.g_sum_page_doc_area_e,
                          pk_advanced_directives.g_sum_page_doc_area_v)
              INTO o_scope
              FROM (SELECT ed2.id_episode,
                           row_number() over(ORDER BY decode(ed2.id_epis_documentation, i_epis_documentation, 1, 2)) line_number
                      FROM epis_documentation ed2
                     WHERE ed2.id_epis_documentation IN
                           (SELECT column_value
                              FROM TABLE (SELECT pk_utils.str_split_n(substr(sys_connect_by_path(ed.id_epis_documentation,
                                                                                                 '|'),
                                                                             l_two),
                                                                      l_pipe) lst_ids
                                            FROM epis_documentation ed
                                           WHERE ed.id_epis_documentation = i_epis_documentation
                                           START WITH ed.id_epis_documentation_parent IS NULL
                                          CONNECT BY PRIOR ed.id_epis_documentation = ed.id_epis_documentation_parent))
                       AND ed2.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_outdated)
                       AND ed2.id_episode IN (SELECT e.id_visit
                                                FROM episode e
                                               WHERE e.id_episode = i_episode)) t
             WHERE t.line_number = l_one;
        
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'SET AS PATIENT SCOPE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                o_scope := pk_advanced_directives.g_sum_page_doc_area_p;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END get_flg_scope;

    /********************************************************************************************
    * Get adv. dir. type of icon to show in the header of reports
    *
    * @param   i_episode        Episode ID
    *
    * @value   i_flg_scope         E - Adv. Directives inserted/edited or validated in the current episode
    *                              V - Adv. Directives inserted/edited or validated in the current visit
    *                              P - All Patient Adv. Directives
    *
    * @return  DNAR Physician or DNAR Patient or Normal Adv. Dir. or NULL (related with the given episode)
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_rep_adv_dir_type_int
    (
        i_flg_scope IN VARCHAR2,
        i_episode   IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_one CONSTANT PLS_INTEGER := 1;
    
        l_dnar_phy PLS_INTEGER;
        l_dnar_pat VARCHAR2(1);
        l_adv_dir  PLS_INTEGER;
        l_episodes table_number;
    
        l_ret VARCHAR2(3) := NULL;
    
    BEGIN
    
        g_error := 'Init';
        IF i_flg_scope = pk_advanced_directives.g_sum_page_doc_area_p
        THEN
            l_ret := NULL;
        ELSE
            g_error := 'GET EPISODES';
            CASE i_flg_scope
                WHEN pk_advanced_directives.g_sum_page_doc_area_e THEN
                    l_episodes := table_number(i_episode);
                WHEN pk_advanced_directives.g_sum_page_doc_area_v THEN
                    SELECT epis.id_episode
                      BULK COLLECT
                      INTO l_episodes
                      FROM episode epis
                     WHERE epis.id_visit = (SELECT id_visit
                                              FROM episode e
                                             WHERE e.id_episode = i_episode);
            END CASE;
        
            g_error := 'VALIDATE DNAR PHYSICIAN';
            IF l_episodes IS NOT NULL
               AND l_episodes.count > 0
            THEN
                --Verify DNAR Physician
                BEGIN
                    SELECT COUNT(*) show_dnar_physician
                      INTO l_dnar_phy
                      FROM (SELECT row_number() over(ORDER BY ed.dt_last_update_tstz DESC) line_number
                              FROM epis_documentation ed
                              JOIN epis_documentation_det edd
                                ON edd.id_epis_documentation = ed.id_epis_documentation
                              JOIN advance_directive ad
                                ON ad.id_doc_area = ed.id_doc_area
                               AND ad.flg_type = pk_advanced_directives.g_flg_adv_type_d
                             WHERE ed.id_episode IN (SELECT column_value
                                                       FROM TABLE(l_episodes))
                               AND ed.flg_status = pk_advanced_directives.g_adv_status_active) t
                     WHERE t.line_number = l_one;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_ret := NULL;
                END;
            
                IF l_dnar_phy = l_one
                THEN
                    l_ret := g_adv_dir_icon_type_dph;
                END IF;
            END IF;
        
            g_error := 'VALIDATE DNAR PAT';
            IF l_episodes IS NOT NULL
               AND l_episodes.count > 0
               AND l_ret IS NULL
            THEN
                --Verify DNAR Patient
                BEGIN
                    SELECT decode(t.id_doc_element,
                                  t.id_doc_element_no,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) show_dnar_pat
                      INTO l_dnar_pat
                      FROM (SELECT edd.id_doc_element,
                                   ad.id_doc_element_no,
                                   row_number() over(ORDER BY ed.dt_last_update_tstz DESC) line_number
                              FROM epis_documentation ed
                              JOIN epis_documentation_det edd
                                ON edd.id_epis_documentation = ed.id_epis_documentation
                              JOIN advance_directive ad
                                ON ad.id_doc_area = ed.id_doc_area
                               AND ad.flg_type = pk_advanced_directives.g_flg_adv_type_c
                             WHERE ed.id_episode IN (SELECT column_value
                                                       FROM TABLE(l_episodes))
                               AND ed.flg_status = pk_advanced_directives.g_adv_status_active) t
                     WHERE t.line_number = l_one;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_ret := NULL;
                END;
            
                IF l_dnar_pat = pk_alert_constant.g_yes
                THEN
                    l_ret := g_adv_dir_icon_type_dp;
                END IF;
            END IF;
        
            g_error := 'VALIDATE ADV DIR';
            IF l_episodes IS NOT NULL
               AND l_episodes.count > 0
               AND l_ret IS NULL
            THEN
                --Verify adv. dir.
                BEGIN
                    SELECT COUNT(*) show_adv_dir
                      INTO l_adv_dir
                      FROM epis_documentation ed
                      JOIN epis_documentation_det edd
                        ON edd.id_epis_documentation = ed.id_epis_documentation
                      JOIN advance_directive ad
                        ON ad.id_doc_area = ed.id_doc_area
                     WHERE ed.id_episode IN (SELECT column_value
                                               FROM TABLE(l_episodes))
                       AND ed.flg_status = pk_advanced_directives.g_adv_status_active;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_ret := NULL;
                END;
            
                IF l_adv_dir >= l_one
                THEN
                    l_ret := g_adv_dir_icon_type_n;
                END IF;
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_rep_adv_dir_type_int;

    /********************************************************************************************
    * Get report header scope
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_episode        Episode ID
    * @param   o_scope          DNAR Physician or DNAR Patient or Normal Adv. Dir. or NULL (related with the given episode)
    * @param   o_error          Error message
    *
    * @value   i_flg_scope         E - Adv. Directives inserted/edited or validated in the current episode
    *                              V - Adv. Directives inserted/edited or validated in the current visit
    *                              P - All Patient Adv. Directives
    *
    * @values  o_scope   DPH  - DNAR Physician
    *                    DP   - DNAR Patient
    *                    N    - Has advance directives
    *                    NULL - Doesn't have advance directives
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_report_hea_scope
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_scope IN VARCHAR2,
        o_scope     OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REPORT_HEA_SCOPE';
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'Call get_rep_adv_dir_type_int';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        o_scope := get_rep_adv_dir_type_int(i_flg_scope => i_flg_scope, i_episode => i_episode);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END get_report_hea_scope;

    /********************************************************************************************
    * Check if DNAR popup is to be shown
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_patient           Patient ID
    * @param   i_episode           episode id
    * @param   o_adv_dir_short_yes Shortcut ID when the user aswers Yes to the question
    * @param   o_adv_dir_short_no  Shortcut ID when the user aswers No to the question
    * @param   o_flg_show          If a message should or should not be shown to the user
    * @param   o_msg_title         Message title
    * @param   o_msg               Message body
    * @param   o_flg_show          If a message should or should not be shown to the user
    * @param   o_msg_title         Message title
    * @param   o_msg               Message body
    * @param   o_btn_cfg           Buttons configurations
    * @param   o_btn_desc_yes      Description of YES button
    * @param   o_btn_desc_no       Description of NO button
    * @param   o_error             Error message
    *
    * @value   o_flg_show          Y - Show message
    *                              N - Don't show
    *
    * @value   o_btn_cfg           YN - Yes/No buttons
    *                              GD - Go to DNAR button
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1.1
    * @since   23-05-2011
    **********************************************************************************************/
    FUNCTION check_adv_dir_dnar_review
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        o_adv_dir_short_yes OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_adv_dir_short_no  OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_btn_cfg           OUT VARCHAR2,
        o_btn_desc_yes      OUT VARCHAR2,
        o_btn_desc_no       OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_ADV_DIR_DNAR_REVIEW';
        --
        l_cfg_adv_dir_buttons  CONSTANT sys_config.id_sys_config%TYPE := 'ADV_DIRECTIVE_BUTTONS';
        l_msg_button_yes       CONSTANT sys_message.code_message%TYPE := 'COMMON_M022'; --Yes
        l_msg_button_no        CONSTANT sys_message.code_message%TYPE := 'COMMON_M023'; --No
        l_msg_button_goto_dnar CONSTANT sys_message.code_message%TYPE := 'ADVANCED_DIRECTIVES_M011'; --Go to DNAR
        l_msg_goto_dnar_title  CONSTANT sys_message.code_message%TYPE := 'ADVANCED_DIRECTIVES_M012'; --You must review the DNAR order now
        l_btn_yn               CONSTANT sys_config.value%TYPE := 'YN'; --Yes/No buttons
        l_btn_gd               CONSTANT sys_config.value%TYPE := 'GD'; --Go to DNAR button
        --
        l_exception EXCEPTION;
        --
        r_reminder reminder%ROWTYPE;
        --
        l_dummy_value         VARCHAR2(1);
        l_id_shortcut_adv_dir PLS_INTEGER;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'CALL PK_SYSCONFIG.GET_CONFIG';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        o_btn_cfg := pk_sysconfig.get_config(i_code_cf => l_cfg_adv_dir_buttons, i_prof => i_prof);
    
        g_error := 'CALL CHECK_AD_DNAR_REVIEW_INT';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT check_ad_dnar_review_int(i_lang             => i_lang,
                                        i_prof             => i_prof,
                                        i_patient          => i_patient,
                                        i_episode          => i_episode,
                                        o_flg_is_to_review => o_flg_show,
                                        o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF o_flg_show = pk_alert_constant.g_yes
        THEN
            g_error := 'GET ADV DIR SHORTCUT';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_advanced_directives.get_adv_directives_for_header(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_patient            => i_patient,
                                                                        i_episode            => i_episode,
                                                                        o_has_adv_directives => l_dummy_value,
                                                                        o_adv_directive_sh   => l_id_shortcut_adv_dir,
                                                                        o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'GET REMINDER ROW';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            r_reminder := pk_reminder_api_db.get_reminder_row(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_internal_name => pk_reminder_constant.g_recurr_adv_dir_dnar_area);
        
            o_adv_dir_short_yes := nvl(l_id_shortcut_adv_dir, r_reminder.id_sys_shortcut_yes);
            o_adv_dir_short_no  := r_reminder.id_sys_shortcut_no;
        
            o_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => r_reminder.code_msg_body);
        
            IF o_btn_cfg = l_btn_yn
            THEN
                o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => r_reminder.code_msg_title);
            
                o_btn_desc_yes := pk_message.get_message(i_lang => i_lang, i_code_mess => l_msg_button_yes);
                o_btn_desc_no  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_msg_button_no);
            ELSIF o_btn_cfg = l_btn_gd
            THEN
                o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => l_msg_goto_dnar_title);
            
                o_btn_desc_yes := pk_message.get_message(i_lang => i_lang, i_code_mess => l_msg_button_goto_dnar);
                o_btn_desc_no  := NULL;
            ELSE
                --These are the default values
                o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => r_reminder.code_msg_title);
            
                o_btn_desc_yes := pk_message.get_message(i_lang => i_lang, i_code_mess => l_msg_button_yes);
                o_btn_desc_no  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_msg_button_no);
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END check_adv_dir_dnar_review;

    /********************************************************************************************
    * Get list of actions for a specified subject and state.
    * Based on get_actions function.
    *
    * @param   i_lang              Preferred language ID for this professional
    * @param   i_prof              Object (professional ID, institution ID, software ID)
    * @param   i_subject           Subject
    * @param   i_from_state        State
    * @param   o_actions           Cursor with actions
    * @param   o_error             Error message
    *
    * @return  true or false on success or error
    *
    * @author  Alexandre Santos
    * @version 2.6.1.1
    * @since   23-05-2011
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ACTIONS';
        --
        l_id_action_review     CONSTANT action.id_action%TYPE := 44289;
        l_id_action_review_all CONSTANT action.id_action%TYPE := 50100;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'OPEN CURSOR O_ACTIONS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_actions FOR
            SELECT /*+opt_estimate(table,act,scale_rows=0.0001)*/
             a.id_action,
             a.id_parent,
             a.level_nr,
             a.from_state,
             a.to_state,
             a.desc_action,
             a.icon,
             a.flg_default,
             a.action,
             a.flg_active,
             (CASE
                  WHEN a.id_action IN (l_id_action_review, l_id_action_review_all) THEN
                   pk_alert_constant.g_yes
                  ELSE
                   pk_alert_constant.g_no
              END) flg_review
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, i_subject, i_from_state)) a;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_actions);
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END get_actions;

    FUNCTION get_adv_dir_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ADV_DIR_ACTIONS';
    
        l_count NUMBER := 0;
    BEGIN
    
        SELECT COUNT(*) COLLECT
          INTO l_count
          FROM pat_advance_directive p
         WHERE p.id_patient = i_patient
           AND p.flg_status = g_adv_status_active;
    
        g_error := 'OPEN CURSOR O_ACTIONS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_actions FOR
            SELECT /*+opt_estimate(table act rows=1)*/
             act.id_action,
             act.id_parent,
             act.level_nr AS "LEVEL", --used to manage the shown' items by Flash
             act.from_state,
             act.to_state, --destination state flag
             act.desc_action, --action's description
             act.icon, --action's icon
             act.flg_default, --default action             
             CASE
                  WHEN (act.from_state = 'D' OR act.from_state = 'I')
                       AND l_count = 0 THEN
                   g_doc_status_inactive
                  ELSE
                   act.flg_active --action's state
              END flg_active,
             act.action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, 'ADV_DIR_ADD', NULL)) act;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_actions);
            RETURN error_handling_ext(i_lang           => i_lang,
                                      i_func_proc_name => l_func_name,
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
    END get_adv_dir_actions;

    /**
    * Retrieves the last profile_template review for a given Problem, Allergy, Habit, Medication, Blood type,
    * Advanced directive or Past history, ordered by date
    * (Based on get_group_reviews_by_id)
    * (Used by reports team)
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  group of record ids
    * @param o_reviews         cursor for reviews
    * @param o_error           error message
    *
    * @author                  Alexandre Santos
    * @since                   2011-05-31
    * @version                 2.6.1.1
    * @reason                  ALERT-41412
    */
    FUNCTION get_greviews_by_pt_last_dt
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN table_number,
        o_reviews        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_GREVIEWS_BY_PT_LAST_DT';
    BEGIN
        g_error := 'CALL pk_review.get_greviews_by_pt_last_dt';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        RETURN pk_review.get_greviews_by_pt_last_dt(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_episode     => i_id_episode,
                                                    i_id_record_area => i_id_record_area,
                                                    i_flg_context    => pk_review.get_adv_directives_context,
                                                    o_reviews        => o_reviews,
                                                    o_error          => o_error);
    END get_greviews_by_pt_last_dt;

    /********************************************************************************************
    * Is to review DNAR area for the given patient
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_patient           Patient ID
    * @param   i_episode           Episode ID
    *
    * @return  'Y' - if is to review
    *          'N' - otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6.1.1
    * @since   23-05-2011
    **********************************************************************************************/
    FUNCTION is_to_review_dnar
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'IS_TO_REVIEW_DNAR';
        --
        l_ret   VARCHAR2(1);
        l_error t_error_out;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'CALL CHECK_AD_DNAR_REVIEW_INT';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT check_ad_dnar_review_int(i_lang             => i_lang,
                                        i_prof             => i_prof,
                                        i_patient          => i_patient,
                                        i_episode          => i_episode,
                                        o_flg_is_to_review => l_ret,
                                        o_error            => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE || ' - ' || SQLERRM;
    END is_to_review_dnar;

    /********************************************************************************************
    * Check if DNAR was reviewed
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_patient           Patient ID
    * @param   i_episode           Episode ID
    * @param   i_profile_template  Profile template ID
    *
    *
    * @return  Y - Is to review; N - Was already reviewed
    *
    * @author  Alexandre Santos
    * @version 2.6.3
    * @since   04-09-2013
    **********************************************************************************************/
    FUNCTION is_to_review_dnar
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_profile_template      IN profile_template.id_profile_template%TYPE,
        i_pat_advance_directive IN pat_advance_directive.id_pat_advance_directive%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'IS_TO_REVIEW_DNAR';
    
        l_ret       VARCHAR2(1 CHAR);
        l_error_out t_error_out;
    BEGIN
        g_error := 'CALL CHECK_AD_DNAR_REVIEW_INT';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT check_ad_dnar_review_int(i_lang                  => i_lang,
                                        i_prof                  => i_prof,
                                        i_patient               => i_patient,
                                        i_episode               => i_episode,
                                        i_profile_template      => i_profile_template,
                                        i_pat_advance_directive => i_pat_advance_directive,
                                        o_flg_is_to_review      => l_ret,
                                        o_error                 => l_error_out)
        THEN
            g_error := 'ERROR CALLING CHECK_AD_DNAR_REVIEW_INT';
            l_ret   := NULL;
        END IF;
    
        RETURN l_ret;
    END is_to_review_dnar;

    /**
    * Returns the icon status , EMR-463
    *
    * @param i_lang           
    * @param i_prof
    * @param i_episode                      
    *
    * @return   Icon Status
    *
    * @author   Alexander Camilo
    * @version  1
    * @since    2018/03/15
    */
    FUNCTION get_header_icon_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_HEADER_ICON_STATUS';
        l_icon          table_varchar2;
        l_ret           VARCHAR2(240);
        l_urgent_status VARCHAR2(30) := 'URGENT';
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'SET ICON TO SHOW';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        l_icon := pk_advanced_directives.get_adv_dir_icon_type_int(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_episode => i_episode);
    
        IF l_icon IS NOT NULL
        THEN
            CASE l_icon(l_icon.first)
                WHEN g_adv_dir_icon_type_dph THEN
                    l_ret := l_urgent_status; --l_icon_adv_dir_red;
                WHEN g_adv_dir_icon_type_dp THEN
                    l_ret := l_urgent_status; --l_icon_adv_dir_red;
                WHEN g_adv_dir_icon_type_a THEN
                    l_ret := l_urgent_status; --l_icon_adv_dir_red;
                ELSE
                    l_ret := NULL;
            END CASE;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_header_icon_status;

    /********************************************************************************************
    * Check if a patient is on patient Alerts
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   PATIENT ID
    * @param o_flg_show     Y - if on patient alerts N - Not on  patient alerts
    * @param o_title        modalWindows title
    * @param o_warning      alerts cursor
    * @param o_shortcut     id shortcut to  patient alerts
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author              Jorge Silva
    * @version              2.6.1
    * @since                2012/07/23
    **********************************************************************************************/
    FUNCTION get_active_patient_alerts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_warning    OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_shortcut   OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_table table_varchar2;
        --
        l_exception EXCEPTION;
        l_ret   VARCHAR2(1);
        vresult VARCHAR2(1000) := '';
    BEGIN
    
        IF is_to_show_warning(i_lang        => i_lang,
                              i_prof        => i_prof,
                              i_id_doc_area => g_patient_alerts_doc_area,
                              o_error       => o_error) = pk_alert_constant.g_yes
        THEN
            BEGIN
                SELECT pk_translation.get_translation(i_lang, dc.code_doc_component)
                  BULK COLLECT
                  INTO l_table
                  FROM epis_documentation_det edd
                  JOIN doc_element de
                    ON edd.id_doc_element = de.id_doc_element
                  JOIN epis_documentation ed
                    ON ed.id_epis_documentation = edd.id_epis_documentation
                  JOIN pat_advance_directive pad
                    ON pad.id_epis_documentation = ed.id_epis_documentation
                  JOIN documentation d
                    ON d.id_documentation = edd.id_documentation
                  JOIN doc_component dc
                    ON d.id_doc_component = dc.id_doc_component
                 WHERE instr(upper(de.internal_name), 'INACTIVE') = 0
                   AND pad.id_patient = i_id_patient
                   AND ed.id_doc_area = g_patient_alerts_doc_area
                   AND ed.flg_status = pk_documentation.g_epis_documentation_act;
            END;
        
            IF (l_table IS NOT NULL AND l_table.count > 0)
            
            THEN
                o_flg_show := pk_alert_constant.g_yes;
            
                FOR indx IN 1 .. l_table.count
                LOOP
                    vresult := vresult || l_table(indx) || '<BR><BR>';
                END LOOP;
            
                o_warning := pk_message.get_message(i_lang, i_prof, 'ADVANCE_DIRECTIVES_T020') || ': <BR><BR>' ||
                             vresult;
                o_title   := pk_message.get_message(i_lang, i_prof, 'ADVANCE_DIRECTIVES_T019');
            
                IF NOT pk_advanced_directives.get_adv_directives_for_header(i_lang,
                                                                            i_prof,
                                                                            i_id_patient,
                                                                            NULL,
                                                                            l_ret,
                                                                            o_shortcut,
                                                                            o_error)
                THEN
                    RAISE l_exception;
                END IF;
            ELSE
                o_flg_show := pk_alert_constant.g_no;
            END IF;
        ELSE
            o_flg_show := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ACTIVE_PATIENT_ALERTS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_active_patient_alerts;

    /**
    * Get configured doc_area
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   o_error          Error message
    *
    * @return  doc_area list
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.6
    * @since                2018-07-27
    */
    FUNCTION get_patient_alert_doc_area
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN table_varchar IS
        l_tbl_record          table_number := table_number();
        l_id_prof_cat         NUMBER;
        l_id_market           market.id_market%TYPE;
        l_id_profile_template NUMBER;
        l_config              t_config;
        l_tbl_doc_area        table_varchar;
        l_id_config           NUMBER;
        l_id_inst_owner       NUMBER;
    
        k_area CONSTANT VARCHAR2(30) := 'ADVANCE_DIRECTIVE';
    BEGIN
        l_id_market           := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                 i_id_institution => i_prof.institution);
        l_id_prof_cat         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
    
        g_error := 'call pk_core_config.get_config()';
        pk_alertlog.log_debug(g_error);
    
        l_config := pk_core_config.get_config(i_area             => k_area,
                                              i_prof             => i_prof,
                                              i_market           => l_id_market,
                                              i_category         => l_id_prof_cat,
                                              i_profile_template => l_id_profile_template,
                                              i_prof_dcs         => NULL,
                                              i_episode_dcs      => NULL);
    
        IF l_config IS NOT NULL
        THEN
            l_id_config     := l_config.id_config;
            l_id_inst_owner := l_config.id_inst_owner;
            SELECT cfg_tbl.id_record
              BULK COLLECT
              INTO l_tbl_record
              FROM v_config_table cfg_tbl
             WHERE cfg_tbl.id_config = l_id_config
               AND cfg_tbl.id_inst_owner IN (l_id_inst_owner, 0)
             ORDER BY cfg_tbl.id_config DESC, cfg_tbl.id_inst_owner DESC;
        END IF;
    
        SELECT /*+ OPT_ESTIMATE(TABLE t ROWS=1) */
         t.field_01
          BULK COLLECT
          INTO l_tbl_doc_area
          FROM TABLE(pk_core_config.get_values(i_tbl_record       => l_tbl_record,
                                               i_area             => k_area,
                                               i_prof             => i_prof,
                                               i_market           => l_id_market,
                                               i_category         => l_id_prof_cat,
                                               i_profile_template => l_id_profile_template,
                                               i_prof_dcs         => NULL,
                                               i_episode_dcs      => NULL)) t
         WHERE t.field_04 = 'Y';
        RETURN l_tbl_doc_area;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PATIENT_ALERT_DOC_AREA',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_patient_alert_doc_area;

    /**
    * Get configured patient alert for header
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param  i_patient     Patient ID
    * @param   i_episode        Episode ID
    * @param   o_has_pat_alerts           If paitent has patient alert or not
    * @param   o_error          Error message
    *
    * @value o_has_pat_alerts     {*} 'Y' Has patient alert  {*] 'N' no patient alert
    *
    * @return  true or false on success or error
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.6
    * @since                2018-06-27
    */
    FUNCTION get_pat_alerts_for_header
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        o_has_pat_alerts OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tab_doc_area     table_varchar := table_varchar();
        l_pat_alerts_count NUMBER;
        l_elem_organ_donation_yes CONSTANT doc_element.internal_name%TYPE := 'INT_ORGAN_DONATION_Y';
        l_elem_end_life_care_yes  CONSTANT doc_element.internal_name%TYPE := 'INT_END_LIFE_CARE_Y';
        l_elem_catheter_on        CONSTANT doc_element.internal_name%TYPE := 'INT_CATH_ON_TIME';
        l_elem_catheter_remove    CONSTANT doc_element.internal_name%TYPE := 'INT_CATH_REMOVE_TIME';
    BEGIN
    
        g_error        := 'CALL get_patient_alert_doc_area';
        l_tab_doc_area := get_patient_alert_doc_area(i_lang => i_lang, i_prof => i_prof, o_error => o_error);
    
        SELECT COUNT(*)
          INTO l_pat_alerts_count
          FROM (
                 -- Records for organ donation, end life care in 'End of life' doc area
                 SELECT pk_alert_constant.g_yes flg_patient_alert
                   FROM epis_documentation_det edd
                   JOIN doc_element de
                     ON edd.id_doc_element = de.id_doc_element
                   JOIN epis_documentation ed
                     ON ed.id_epis_documentation = edd.id_epis_documentation
                   JOIN pat_advance_directive pad
                     ON pad.id_epis_documentation = ed.id_epis_documentation
                   JOIN documentation d
                     ON d.id_documentation = edd.id_documentation
                   JOIN doc_component dc
                     ON d.id_doc_component = dc.id_doc_component
                  WHERE instr(upper(de.internal_name), 'INACTIVE') = 0
                    AND pad.id_patient = i_patient
                    AND ed.id_doc_area IN (SELECT /*+ OPT_ESTIMATE(TABLE t1 ROWS=1) */
                                            column_value
                                             FROM TABLE(l_tab_doc_area) t1)
                    AND ed.id_doc_area = g_end_of_life_doc_area
                    AND de.internal_name IN (l_elem_organ_donation_yes, l_elem_end_life_care_yes)
                    AND ed.flg_status = pk_documentation.g_epis_documentation_act
                 UNION ALL
                 -- Records for Catheter info in 'Patient's Alert' doc area
                SELECT pk_alert_constant.g_yes flg_patient_alert
                  FROM (SELECT ed.id_epis_documentation,
                                pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => pk_touch_option.get_template_value(i_lang               => i_lang,
                                                                                                                i_prof               => i_prof,
                                                                                                                i_patient            => NULL,
                                                                                                                i_episode            => i_episode,
                                                                                                                i_doc_area           => ed.id_doc_area,
                                                                                                                i_epis_documentation => ed.id_epis_documentation,
                                                                                                                i_doc_int_name       => NULL,
                                                                                                                i_element_int_name   => l_elem_catheter_on,
                                                                                                                i_show_internal      => NULL,
                                                                                                                i_scope_type         => 'E',
                                                                                                                i_mask               => NULL,
                                                                                                                i_field_type         => NULL),
                                                              
                                                              i_timezone => NULL) start_time,
                                pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => pk_touch_option.get_template_value(i_lang               => i_lang,
                                                                                                                i_prof               => i_prof,
                                                                                                                i_patient            => NULL,
                                                                                                                i_episode            => i_episode,
                                                                                                                i_doc_area           => ed.id_doc_area,
                                                                                                                i_epis_documentation => ed.id_epis_documentation,
                                                                                                                i_doc_int_name       => NULL,
                                                                                                                i_element_int_name   => l_elem_catheter_remove,
                                                                                                                i_show_internal      => NULL,
                                                                                                                i_scope_type         => 'E',
                                                                                                                i_mask               => NULL,
                                                                                                                i_field_type         => NULL),
                                                              
                                                              i_timezone => NULL) end_time
                           FROM epis_documentation ed
                           JOIN pat_advance_directive pad
                             ON pad.id_epis_documentation = ed.id_epis_documentation
                          WHERE ed.id_episode = i_episode
                            AND ed.id_doc_area IN (SELECT /*+ OPT_ESTIMATE(TABLE t1 ROWS=1) */
                                                    column_value
                                                     FROM TABLE(l_tab_doc_area) t1)
                            AND ed.id_doc_area = g_patient_alerts_doc_area
                            AND ed.flg_status = pk_documentation.g_epis_documentation_act) t2
                 WHERE t2.end_time IS NULL
                    OR pk_date_utils.compare_dates(t2.end_time, current_timestamp) = 'G') t;
    
        IF l_pat_alerts_count > 0
        THEN
            o_has_pat_alerts := pk_alert_constant.g_yes;
        ELSE
            o_has_pat_alerts := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PAT_ALERTS_FOR_HEADER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_pat_alerts_for_header;

    /**
    * Get configured patient alert tooltip
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param  i_patient     Patient ID
    * @param   i_episode        Episode ID
    * @param   o_pat_alerts_tooltip           Patient alert tooltip
    * @param   o_error          Error message
    *
    * @return  true or false on success or error
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.6
    * @since                2018-06-27
    */
    FUNCTION get_pat_alerts_tooltip
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_pat_alerts_tooltip OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tab_doc_area     table_varchar := table_varchar();
        l_pat_alerts_count NUMBER;
        l_elem_organ_donation_yes CONSTANT doc_element.internal_name%TYPE := 'INT_ORGAN_DONATION_Y';
        l_elem_end_life_care_yes  CONSTANT doc_element.internal_name%TYPE := 'INT_END_LIFE_CARE_Y';
        l_elem_catheter_on        CONSTANT doc_element.internal_name%TYPE := 'INT_CATH_ON_TIME';
        l_elem_catheter_remove    CONSTANT doc_element.internal_name%TYPE := 'INT_CATH_REMOVE_TIME';
    
        l_hospice_desc  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'HEADER_M026');
        l_organ_desc    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'HEADER_M027');
        l_catheter_desc sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'HEADER_M028');
    
        k_lf           CONSTANT VARCHAR2(2 CHAR) := chr(10);
        k_lparenthesis CONSTANT VARCHAR2(1 CHAR) := '(';
        k_rparenthesis CONSTANT VARCHAR2(1 CHAR) := ')';
        k_spc          CONSTANT VARCHAR2(1 CHAR) := chr(32);
    BEGIN
    
        g_error        := 'CALL get_patient_alert_doc_area';
        l_tab_doc_area := get_patient_alert_doc_area(i_lang => i_lang, i_prof => i_prof, o_error => o_error);
    
        SELECT listagg(pat_alert_desc ||
                       decode(pat_alert_count, NULL, '', k_spc || k_lparenthesis || pat_alert_count || k_rparenthesis),
                       k_lf) within GROUP(ORDER BY t.rank ASC)
          INTO o_pat_alerts_tooltip
          FROM (
                 -- Records for organ donation, end life care in 'End of life' doc area
                 SELECT (CASE de.internal_name
                             WHEN l_elem_end_life_care_yes THEN
                              l_hospice_desc
                             WHEN l_elem_organ_donation_yes THEN
                              l_organ_desc
                         END) pat_alert_desc,
                         NULL pat_alert_count,
                         (CASE de.internal_name
                             WHEN l_elem_end_life_care_yes THEN
                              1
                             WHEN l_elem_organ_donation_yes THEN
                              2
                         END) rank
                   FROM epis_documentation_det edd
                   JOIN doc_element de
                     ON edd.id_doc_element = de.id_doc_element
                   JOIN epis_documentation ed
                     ON ed.id_epis_documentation = edd.id_epis_documentation
                   JOIN pat_advance_directive pad
                     ON pad.id_epis_documentation = ed.id_epis_documentation
                   JOIN documentation d
                     ON d.id_documentation = edd.id_documentation
                   JOIN doc_component dc
                     ON d.id_doc_component = dc.id_doc_component
                  WHERE instr(upper(de.internal_name), 'INACTIVE') = 0
                    AND pad.id_patient = i_patient
                    AND ed.id_doc_area IN (SELECT /*+ OPT_ESTIMATE(TABLE t1 ROWS=1) */
                                            column_value
                                             FROM TABLE(l_tab_doc_area) t1)
                    AND ed.id_doc_area = g_end_of_life_doc_area
                    AND de.internal_name IN (l_elem_organ_donation_yes, l_elem_end_life_care_yes)
                    AND ed.flg_status = pk_documentation.g_epis_documentation_act
                 UNION ALL
                 -- Records for Catheter info in 'Patient's Alert' doc area
                SELECT decode(catheter_count, 0, NULL, l_catheter_desc) pat_alert_desc,
                        decode(catheter_count, 0, NULL, catheter_count) pat_alert_count,
                        3 rank
                  FROM (SELECT COUNT(*) catheter_count
                           FROM (SELECT ed.id_epis_documentation,
                                        pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                      i_prof      => i_prof,
                                                                      i_timestamp => pk_touch_option.get_template_value(i_lang               => i_lang,
                                                                                                                        i_prof               => i_prof,
                                                                                                                        i_patient            => NULL,
                                                                                                                        i_episode            => i_episode,
                                                                                                                        i_doc_area           => ed.id_doc_area,
                                                                                                                        i_epis_documentation => ed.id_epis_documentation,
                                                                                                                        i_doc_int_name       => NULL,
                                                                                                                        i_element_int_name   => l_elem_catheter_on,
                                                                                                                        i_show_internal      => NULL,
                                                                                                                        i_scope_type         => 'E',
                                                                                                                        i_mask               => NULL,
                                                                                                                        i_field_type         => NULL),
                                                                      
                                                                      i_timezone => NULL) start_time,
                                        pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                      i_prof      => i_prof,
                                                                      i_timestamp => pk_touch_option.get_template_value(i_lang               => i_lang,
                                                                                                                        i_prof               => i_prof,
                                                                                                                        i_patient            => NULL,
                                                                                                                        i_episode            => i_episode,
                                                                                                                        i_doc_area           => ed.id_doc_area,
                                                                                                                        i_epis_documentation => ed.id_epis_documentation,
                                                                                                                        i_doc_int_name       => NULL,
                                                                                                                        i_element_int_name   => l_elem_catheter_remove,
                                                                                                                        i_show_internal      => NULL,
                                                                                                                        i_scope_type         => 'E',
                                                                                                                        i_mask               => NULL,
                                                                                                                        i_field_type         => NULL),
                                                                      
                                                                      i_timezone => NULL) end_time
                                   FROM epis_documentation ed
                                   JOIN pat_advance_directive pad
                                     ON pad.id_epis_documentation = ed.id_epis_documentation
                                  WHERE ed.id_episode = i_episode
                                    AND ed.id_doc_area IN (SELECT /*+ OPT_ESTIMATE(TABLE t1 ROWS=1) */
                                                            column_value
                                                             FROM TABLE(l_tab_doc_area) t1)
                                    AND ed.id_doc_area = g_patient_alerts_doc_area
                                    AND ed.flg_status = pk_documentation.g_epis_documentation_act) t2
                          WHERE t2.end_time IS NULL
                             OR pk_date_utils.compare_dates(t2.end_time, current_timestamp) = 'G')) t
         ORDER BY t.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PAT_ALERTS_TOOLTIP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_pat_alerts_tooltip;

    FUNCTION get_doc_types
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        my_exception EXCEPTION;
        l_my_pt profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        g_error := 'GET PROFILE';
        l_my_pt := pk_prof_utils.get_prof_profile_template(i_prof);
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT DISTINCT dtc.id_doc_type,
                            pk_translation.get_translation(i_lang, dt.code_doc_type) desc_doc_type,
                            dtc.flg_publishable,
                            dt.rank,
                            dot.flg_comment_type
              FROM doc_types_config dtc
             INNER JOIN doc_type dt
                ON dt.id_doc_type = dtc.id_doc_type
             INNER JOIN doc_ori_type dot
                ON dt.id_doc_ori_type = dot.id_doc_ori_type
             WHERE dtc.id_doc_ori_type_parent = i_doc_ori_type
               AND dt.flg_available = pk_alert_constant.g_yes
               AND dtc.id_institution IN (i_prof.institution, 0)
               AND dtc.id_software IN (i_prof.software, 0)
               AND dtc.id_profile_template IN (l_my_pt, 0)
               AND pk_translation.get_translation(i_lang, dt.code_doc_type) IS NOT NULL
               AND dt.id_doc_type IN (SELECT DISTINCT nvl(ad.id_doc_type, t.id_doc_type) id_doc_type
                                        FROM pat_advance_directive pad
                                        JOIN epis_documentation ed
                                          ON ed.id_epis_documentation = pad.id_epis_documentation
                                        LEFT JOIN pat_advance_directive_det padd
                                          ON padd.id_pat_advance_directive = pad.id_pat_advance_directive
                                        LEFT JOIN advance_directive ad
                                          ON ad.id_advance_directive = padd.id_advance_directive
                                         AND ad.flg_available = pk_alert_constant.g_yes
                                        LEFT JOIN doc_type dt
                                          ON dt.id_doc_type = ad.id_doc_type
                                        LEFT JOIN (SELECT DISTINCT ad_e.id_doc_area, ad_e.id_doc_type
                                                    FROM advance_directive ad_e
                                                   WHERE ad_e.flg_available = pk_alert_constant.g_yes) t
                                          ON t.id_doc_area = ed.id_doc_area
                                       WHERE pad.id_patient = i_patient
                                         AND pad.flg_status = pk_alert_constant.g_active
                                         AND ed.flg_status = pk_alert_constant.g_active)
             ORDER BY rank, desc_doc_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_TYPES',
                                                     o_error);
    END get_doc_types;

    /**
    * Check if it can register more than one template by doc_area
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param  i_id_doc_area     doc_area ID
    * @param   o_error          Error message
    *
    * @return  {'Y'} Yes or {'N'} No
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.6
    * @since                2018-07-24
    */
    FUNCTION is_to_register_more
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_tbl_record          table_number := table_number();
        l_id_prof_cat         NUMBER;
        l_id_market           market.id_market%TYPE;
        l_id_profile_template NUMBER;
        l_config              t_config;
        l_tbl_config          t_tbl_config_table;
        l_id_config           NUMBER;
        l_id_inst_owner       NUMBER;
    
        k_area CONSTANT VARCHAR2(30) := 'ADVANCE_DIRECTIVE';
    BEGIN
        l_id_market           := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                 i_id_institution => i_prof.institution);
        l_id_prof_cat         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
    
        g_error := 'call pk_core_config.get_config()';
        pk_alertlog.log_debug(g_error);
    
        l_config := pk_core_config.get_config(i_area             => k_area,
                                              i_prof             => i_prof,
                                              i_market           => l_id_market,
                                              i_category         => l_id_prof_cat,
                                              i_profile_template => l_id_profile_template,
                                              i_prof_dcs         => NULL,
                                              i_episode_dcs      => NULL);
    
        IF l_config IS NOT NULL
        THEN
            l_id_config     := l_config.id_config;
            l_id_inst_owner := l_config.id_inst_owner;
            SELECT cfg_tbl.id_record
              BULK COLLECT
              INTO l_tbl_record
              FROM v_config_table cfg_tbl
             WHERE cfg_tbl.id_config = l_id_config
               AND cfg_tbl.id_inst_owner IN (l_id_inst_owner, 0)
             ORDER BY cfg_tbl.id_config DESC, cfg_tbl.id_inst_owner DESC;
        END IF;
    
        l_tbl_config := pk_core_config.get_values(i_tbl_record       => l_tbl_record,
                                                  i_area             => k_area,
                                                  i_prof             => i_prof,
                                                  i_market           => l_id_market,
                                                  i_category         => l_id_prof_cat,
                                                  i_profile_template => l_id_profile_template,
                                                  i_prof_dcs         => NULL,
                                                  i_episode_dcs      => NULL);
    
        IF l_tbl_config.count = 0
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        FOR i IN 1 .. l_tbl_config.count
        LOOP
            IF (l_tbl_config(i).field_01 = i_id_doc_area)
            THEN
                RETURN l_tbl_config(i).field_02;
            END IF;
        END LOOP;
    
        RETURN pk_alert_constant.g_no;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'IS_TO_REGISTER_MORE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_constant.g_no;
    END is_to_register_more;

    /**
    * Check if it needs to show alert warning by doc_area
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param  i_id_doc_area     doc_area ID
    * @param   o_error          Error message
    *
    * @return  {'Y'} Yes or {'N'} No
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.6
    * @since                2018-07-24
    */
    FUNCTION is_to_show_warning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_tbl_record          table_number := table_number();
        l_id_prof_cat         NUMBER;
        l_id_market           market.id_market%TYPE;
        l_id_profile_template NUMBER;
        l_config              t_config;
        l_tbl_config          t_tbl_config_table;
        l_id_config           NUMBER;
        l_id_inst_owner       NUMBER;
    
        k_area CONSTANT VARCHAR2(30) := 'ADVANCE_DIRECTIVE';
    BEGIN
        l_id_market           := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                 i_id_institution => i_prof.institution);
        l_id_prof_cat         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
    
        g_error := 'call pk_core_config.get_config()';
        pk_alertlog.log_debug(g_error);
    
        l_config := pk_core_config.get_config(i_area             => k_area,
                                              i_prof             => i_prof,
                                              i_market           => l_id_market,
                                              i_category         => l_id_prof_cat,
                                              i_profile_template => l_id_profile_template,
                                              i_prof_dcs         => NULL,
                                              i_episode_dcs      => NULL);
    
        IF l_config IS NOT NULL
        THEN
            l_id_config     := l_config.id_config;
            l_id_inst_owner := l_config.id_inst_owner;
            SELECT cfg_tbl.id_record
              BULK COLLECT
              INTO l_tbl_record
              FROM v_config_table cfg_tbl
             WHERE cfg_tbl.id_config = l_id_config
               AND cfg_tbl.id_inst_owner IN (l_id_inst_owner, 0)
             ORDER BY cfg_tbl.id_config DESC, cfg_tbl.id_inst_owner DESC;
        END IF;
    
        l_tbl_config := pk_core_config.get_values(i_tbl_record       => l_tbl_record,
                                                  i_area             => k_area,
                                                  i_prof             => i_prof,
                                                  i_market           => l_id_market,
                                                  i_category         => l_id_prof_cat,
                                                  i_profile_template => l_id_profile_template,
                                                  i_prof_dcs         => NULL,
                                                  i_episode_dcs      => NULL);
    
        IF l_tbl_config.count = 0
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        FOR i IN 1 .. l_tbl_config.count
        LOOP
            IF (l_tbl_config(i).field_01 = i_id_doc_area)
            THEN
                RETURN l_tbl_config(i).field_03;
            END IF;
        END LOOP;
    
        RETURN pk_alert_constant.g_yes;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'IS_TO_REGISTER_MORE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_constant.g_no;
    END is_to_show_warning;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_sysdate_tstz := current_timestamp;
END pk_advanced_directives;
/
