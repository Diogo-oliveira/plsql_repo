/*-- Last Change Revision: $Rev: 1915085 $*/
/*-- Last Change by: $Author: ana.moita $*/
/*-- Date of last change: $Date: 2019-09-05 08:05:48 +0100 (qui, 05 set 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_prog_notes_out IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Delete the notes associated to the given episodes.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_episode      Episode list
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.6.2
    * @since   16-Apr-2013
    */
    FUNCTION delete_episode_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(20 CHAR) := 'DELETE_EPISODE_NOTES';
    BEGIN
        g_error := 'DELETE EPISODE NOTES';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        FOR rec IN (SELECT epn.id_epis_pn
                      FROM epis_pn epn
                     WHERE epn.id_episode IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                               column_value
                                                FROM TABLE(i_episode) t))
        LOOP
            g_error := 'CALL delete_note. id_epis_pn: ' || rec.id_epis_pn;
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_prog_notes_core.delete_note(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_id_epis_pn => rec.id_epis_pn,
                                                  o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END delete_episode_notes;

    /**
    * Returns the last note info for edis summary grids
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_id_epis_pn             Note identifier
    *
    * @param      o_flg_edited             Indicate if the SOAP block was edited
    * @param      o_pn_soap_block          Soap Block array with ids
    * @param      o_pn_signoff_note        Notes array
    * @param      o_error                  error information
    *
    * @return                              false if errors occur, true otherwise
    *
    * @author                              Sofia Mendes
    * @version                             2.6.3
    * @since                               23-Jul-2013
    */
    FUNCTION get_last_note_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_software IN software.id_software%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_pn_area  IN pn_area.id_pn_area%TYPE,
        o_note        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.get_epis_prog_notes';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_last_note_text(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_id_software => i_id_software,
                                                      i_id_episode  => i_id_episode,
                                                      i_id_pn_area  => i_id_pn_area,
                                                      o_note        => o_note,
                                                      o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_note);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_LAST_NOTE_TEXT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_note);
            RETURN FALSE;
        
    END get_last_note_text;

    FUNCTION set_pn_group_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN table_number,
        i_notes   IN epis_pn_det.pn_note%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(20 CHAR) := 'SET_PN_GROUP_NOTES';
    BEGIN
        FOR i IN i_episode.first .. i_episode.last
        LOOP
        
            g_error := 'CALL PK_PROG_NOTES_CORE.SET_PN_GROUP_NOTES';
            IF NOT pk_prog_notes_core.set_pn_group_notes(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => i_episode(i),
                                                         i_notes      => i_notes,
                                                         o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
        
    END set_pn_group_notes;

    FUNCTION tf_progress_note_cda
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_id_pn_note_type IN pn_note_type .id_pn_note_type%TYPE
    ) RETURN t_coll_progress_note_cda
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_PROGRESS_NOTE_CDA';
    
        l_id_patient      patient.id_patient%TYPE;
        l_id_episode      episode.id_episode%TYPE;
        l_id_visit        visit.id_visit%TYPE;
        l_soap_block_edis pn_soap_block.id_pn_soap_block%TYPE := 34;
        l_soap_block_ftxt pn_soap_block.id_pn_soap_block%TYPE := 17;
        l_data_block_ftxt pn_soap_block.id_pn_soap_block%TYPE := 147;
    
        l_rec_progress_note_cda t_rec_progress_note_cda;
        l_error                 t_error_out;
    BEGIN
    
        IF i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            g_has_error := TRUE;
            g_error     := 'SCOPE ID OR TYPE IS NULL';
            RAISE g_exception;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => l_error)
        THEN
            g_has_error := TRUE;
            RAISE g_exception;
        END IF;
    
        FOR l_rec_progress_note_cda IN (SELECT ep.id_epis_pn,
                                               epd.id_epis_pn_det,
                                               ep.flg_status,
                                               pk_sysdomain.get_domain('EPIS_PN.FLG_STATUS', ep.flg_status, i_lang),
                                               epd.pn_note,
                                               pk_date_utils.date_send_tsz(i_lang, ep.dt_create, i_prof),
                                               ep.dt_create,
                                               pk_date_utils.date_char_tsz(i_lang,
                                                                           ep.dt_create,
                                                                           i_prof.institution,
                                                                           i_prof.software)
                                          FROM epis_pn ep
                                          JOIN epis_pn_det epd
                                            ON epd.id_epis_pn = ep.id_epis_pn
                                         INNER JOIN (SELECT e.id_episode
                                                      FROM episode e
                                                     WHERE e.id_episode = l_id_episode
                                                       AND e.id_patient = l_id_patient
                                                       AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                    UNION ALL
                                                    SELECT e.id_episode
                                                      FROM episode e
                                                     WHERE e.id_patient = l_id_patient
                                                       AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                    UNION ALL
                                                    SELECT e.id_episode
                                                      FROM episode e
                                                     WHERE e.id_visit = l_id_visit
                                                       AND e.id_patient = l_id_patient
                                                       AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                            ON ep.id_episode = epi.id_episode
                                         WHERE ep.id_pn_note_type IN (i_id_pn_note_type)
                                           AND epd.id_pn_soap_block IN (pk_prog_notes_constants.g_sblock_hcourse_30,
                                                                        pk_prog_notes_constants.g_sblock_edcourse_35,
                                                                        pk_prog_notes_constants.g_sblock_creport_36,
                                                                        l_soap_block_edis, -- EMR-316
                                                                        l_soap_block_ftxt)
                                           AND epd.id_pn_data_block IN (pk_prog_notes_constants.g_dblock_hcourse_136,
                                                                        pk_prog_notes_constants.g_dblock_edcourse_138,
                                                                        pk_prog_notes_constants.g_dblock_creport_120,
                                                                        l_data_block_ftxt))
        LOOP
            PIPE ROW(l_rec_progress_note_cda);
        END LOOP;
    
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN;
        
    END tf_progress_note_cda;

    --- VWR
    /**
    * Returns the pn_note_type flag to viewer checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    * @param      i_pn_area                pn area internal name
    * @param      i_ids_pn_note_type       list of id pn note type,
    * @param      o_flg_checklist          Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    * @param      o_error                  error information
    *
    * @return     false if errors occur, true otherwise
    *
    * @author     Anna Kurowska
    * @version    2.7.1
    * @since      02-Mar-2017
    */
    FUNCTION get_vwr_note_by_area
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_scope_type       IN VARCHAR2,
        i_pn_area          IN pn_area.internal_name%TYPE,
        i_ids_pn_note_type IN table_number,
        o_flg_checklist    OUT VARCHAR2,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30 CHAR) := 'GET_VWR_NOTE_BY_AREA';
        l_flg_checklist       VARCHAR2(1 CHAR);
        l_id_pn_note_type_all table_number := table_number();
        l_id                  pn_note_type.id_pn_note_type%TYPE;
        l_id_department       department.id_department%TYPE;
        l_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
    
    BEGIN
        g_error := 'GET EPISODE DEPARTMENT';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_id_department := pk_progress_notes_upd.get_department(i_episode => i_episode, i_epis_pn => NULL);
    
        g_error := 'GET EPISODE DCS';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_id_dep_clin_serv := pk_progress_notes_upd.get_dep_clin_serv(i_episode => i_episode, i_epis_pn => NULL);
    
        g_error := 'Get i_pn_area from parametrizations function i_pn_area: ' || i_pn_area || ' and i_episode: ' ||
                   i_episode;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --find all notes that are possible for given pn_area
        BEGIN
            SELECT /*+ OPT_ESTIMATE (TABLE tt ROWS=1)*/
             tt.id_pn_note_type
              BULK COLLECT
              INTO l_id_pn_note_type_all
              FROM TABLE(pk_prog_notes_utils.tf_pn_note_type(i_lang,
                                                             i_prof,
                                                             i_episode,
                                                             NULL,
                                                             NULL,
                                                             l_id_department,
                                                             l_id_dep_clin_serv,
                                                             NULL,
                                                             table_varchar(i_pn_area),
                                                             NULL,
                                                             pk_prog_notes_constants.g_pn_flg_scope_area_a,
                                                             NULL)) tt
              JOIN pn_note_type nt
                ON nt.id_pn_note_type = tt.id_pn_note_type
             WHERE tt.flg_write = pk_alert_constant.g_yes
               AND tt.flg_create_on_app = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_pn_note_type_all := NULL;
        END;
    
        o_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        --go through all given note types and check if they are configured for inst/soft. if yes return state.
        IF ((l_id_pn_note_type_all.count > 0 AND l_id_pn_note_type_all.exists(1)) AND
           (i_ids_pn_note_type.count > 0 AND i_ids_pn_note_type.exists(1)))
        THEN
            g_error := 'GET_NOTE_VIEWER_CHECKLIST';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            FOR i IN i_ids_pn_note_type.first .. i_ids_pn_note_type.last
            LOOP
                l_id := i_ids_pn_note_type(i);
                IF pk_utils.search_table_number(i_table => l_id_pn_note_type_all, i_search => l_id) > 0
                THEN
                    IF NOT get_note_viewer_checklist(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_patient         => i_patient,
                                                     i_episode         => i_episode,
                                                     i_scope_type      => i_scope_type,
                                                     i_id_pn_note_type => l_id,
                                                     o_flg_checklist   => l_flg_checklist,
                                                     o_error           => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    CASE l_flg_checklist
                        WHEN pk_viewer_checklist.g_checklist_ongoing THEN
                            o_flg_checklist := l_flg_checklist;
                            EXIT;
                        WHEN pk_viewer_checklist.g_checklist_completed THEN
                            o_flg_checklist := l_flg_checklist;
                        ELSE
                            o_flg_checklist := o_flg_checklist;
                    END CASE;
                
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_vwr_note_by_area;

    /**
    * Returns flag to viewer checklist for note summary of given id_pn_note_type
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    * @param      i_id_pn_note_type        id pn note type,
    * @param      o_flg_checklist          Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    * @param      o_error                  error information
    *
    * @return     false if errors occur, true otherwise
    *
    * @author     Anna Kurowska
    * @version    2.7.1
    * @since      03-Mar-2017
    */
    FUNCTION get_vwr_note_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_scope_type      IN VARCHAR2,
        i_id_pn_note_type pn_note_type.id_pn_note_type%TYPE,
        o_flg_checklist   OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_VWR_NOTE_SUMMARY';
        l_episodes  table_number := table_number();
    BEGIN
    
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        g_error := 'GET FLG_CHECKLIST';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT decode(COUNT(ep.flg_status),
                      0,
                      pk_viewer_checklist.g_checklist_not_started,
                      pk_viewer_checklist.g_checklist_completed)
          INTO o_flg_checklist
          FROM epis_pn ep
         WHERE ep.id_episode IN (SELECT /*+ opt_estimate(table t rows=1) */
                                  column_value
                                   FROM TABLE(l_episodes) t)
           AND ep.id_pn_note_type = i_id_pn_note_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_vwr_note_summary;

    /**
    * Returns the pn_note_type flag to viewer checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    * @param      i_id_pn_note_type        PN_NOTE_TYPE ID
    *
    * @param      o_flg_checklist          Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    * @param      o_error                  error information
    *
    * @return     false if errors occur, true otherwise
    *
    * @author     Vanessa barsottelli
    * @version    2.6.5
    * @since      21-Set-2016
    */
    FUNCTION get_note_viewer_checklist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_scope_type      IN VARCHAR2,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_flg_checklist   OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(30 CHAR) := 'GET_NOTE_VIEWER_CHECKLIST';
        l_episodes     table_number := table_number();
        l_flg_sign_off pn_note_type_mkt.flg_sign_off%TYPE;
        l_flg_submit   pn_note_type_mkt.flg_submit%TYPE;
        l_cnt_draft    NUMBER(24);
        l_cnt_sign_off NUMBER(24);
        l_cnt_submit   NUMBER(24);
    BEGIN
    
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        g_error := 'GET PN_NOTE_TYPE FLG_SIGN_OFF';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        BEGIN
            SELECT t.flg_sign_off, t.flg_submit
              INTO l_flg_sign_off, l_flg_submit
              FROM TABLE(pk_prog_notes_utils.tf_pn_note_type(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_episode          => decode(i_scope_type,
                                                                                             pk_episode.g_scope_episode,
                                                                                             i_episode,
                                                                                             NULL),
                                                             i_id_profile_template => NULL,
                                                             i_id_market           => NULL,
                                                             i_id_department       => NULL,
                                                             i_id_dep_clin_serv    => NULL,
                                                             i_id_category         => NULL,
                                                             i_area                => NULL,
                                                             i_id_note_type        => i_id_pn_note_type,
                                                             i_flg_scope           => pk_prog_notes_constants.g_pn_flg_scope_notetype_n,
                                                             i_software            => i_prof.software)) t;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_sign_off := pk_alert_constant.g_no;
        END;
    
        IF l_flg_sign_off = pk_alert_constant.g_yes
        THEN
            g_error := 'GET FLG_CHECKLIST WITH SIGN_OFF';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT COUNT(ep.flg_status) cnt
              INTO l_cnt_draft
              FROM epis_pn ep
             WHERE ep.id_episode IN (SELECT *
                                       FROM TABLE(l_episodes))
               AND ep.flg_status IN
                   (pk_prog_notes_constants.g_epis_pn_flg_status_d, pk_prog_notes_constants.g_epis_pn_flg_status_f)
               AND (ep.flg_auto_saved = pk_alert_constant.g_no --it is not temporary state the note is already saved
                   OR ep.flg_auto_saved = pk_alert_constant.g_yes AND ep.id_prof_last_update IS NOT NULL) -- EMR-211
               AND ep.id_pn_note_type = i_id_pn_note_type;
        
            SELECT COUNT(ep.flg_status) cnt
              INTO l_cnt_sign_off
              FROM epis_pn ep
             WHERE ep.id_episode IN (SELECT *
                                       FROM TABLE(l_episodes))
               AND ep.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_s
               AND ep.id_pn_note_type = i_id_pn_note_type;
        
            IF l_cnt_draft > 0
            THEN
                o_flg_checklist := pk_viewer_checklist.g_checklist_ongoing;
            ELSIF l_cnt_sign_off > 0
            THEN
                o_flg_checklist := pk_viewer_checklist.g_checklist_completed;
            ELSE
                o_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
            END IF;
        ELSIF l_flg_submit = pk_alert_constant.g_yes
        THEN
        
            SELECT COUNT(ep.flg_status) cnt
              INTO l_cnt_draft
              FROM epis_pn ep
             WHERE ep.id_episode IN (SELECT *
                                       FROM TABLE(l_episodes))
               AND ep.flg_status IN
                   (pk_prog_notes_constants.g_epis_pn_flg_status_d, pk_prog_notes_constants.g_epis_pn_flg_for_review)
               AND ep.flg_auto_saved = pk_alert_constant.g_no
               AND ep.id_pn_note_type = i_id_pn_note_type;
        
            SELECT COUNT(ep.flg_status) cnt
              INTO l_cnt_submit
              FROM epis_pn ep
             WHERE ep.id_episode IN (SELECT * /*+ opt_estimate(table t rows=1) */
                                       FROM TABLE(l_episodes))
               AND ep.flg_status IN
                   (pk_prog_notes_constants.g_epis_pn_flg_submited, pk_prog_notes_constants.g_epis_pn_flg_draftsubmit)
               AND ep.id_pn_note_type = i_id_pn_note_type;
        
            IF l_cnt_draft > 0
            THEN
                o_flg_checklist := pk_viewer_checklist.g_checklist_ongoing;
            ELSIF l_cnt_submit > 0
            THEN
                o_flg_checklist := pk_viewer_checklist.g_checklist_completed;
            ELSE
                o_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
            END IF;
        ELSE
            g_error := 'GET FLG_CHECKLIST WITHOUT SIGN_OFF';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT decode(COUNT(ep.flg_status),
                          0,
                          pk_viewer_checklist.g_checklist_not_started,
                          pk_viewer_checklist.g_checklist_completed)
              INTO o_flg_checklist
              FROM epis_pn ep
             WHERE ep.id_episode IN (SELECT /*+ opt_estimate(table t rows=1) */
                                      column_value
                                       FROM TABLE(l_episodes) t)
               AND ep.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_f
               AND ep.flg_auto_saved = pk_alert_constant.g_no -- CMF CHANGE FOR ALERT-331452
               AND ep.id_pn_note_type = i_id_pn_note_type;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_note_viewer_checklist;

    /**
    * History and Physical viewer checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Vanessa barsottelli
    * @version     2.6.5
    * @since       21-Set-2016
    */
    FUNCTION get_hp_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_HP_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_id_handp_2, -- H&P
                                                            pk_prog_notes_constants.g_note_type_id_handp_ft_8); -- H&P free text
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_hp;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: HP';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_hp_vchecklist;

    /**
    * Current visit viewer checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Vanessa barsottelli
    * @version     2.6.5
    * @since       24-Set-2016
    */
    FUNCTION get_cv_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name       VARCHAR2(30 CHAR) := 'GET_CV_VCHECKLIST';
        l_flg_checklist   VARCHAR2(1 CHAR);
        l_error           t_error_out;
        l_id_pn_note_type pn_note_type.id_pn_note_type%TYPE := pk_prog_notes_constants.g_note_type_current_visit_9; --Current visit
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_SUMMARY FOR ID_PN_NOTE_TYPE: 9';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_summary(i_lang            => i_lang,
                                    i_prof            => i_prof,
                                    i_patient         => i_patient,
                                    i_episode         => i_episode,
                                    i_scope_type      => i_scope_type,
                                    i_id_pn_note_type => l_id_pn_note_type,
                                    o_flg_checklist   => l_flg_checklist,
                                    o_error           => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_cv_vchecklist;

    /**
    * Current Discharge Summary checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Vanessa barsottelli
    * @version     2.6.5
    * @since       24-Set-2016
    */
    FUNCTION get_ds_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_DS_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_id_disch_sum_12, --Discharge summary
                                                            pk_prog_notes_constants.g_note_type_id_disch_sum_ft_13,
                                                            pk_prog_notes_constants.g_note_type_psy_ds); --Discharge summary free text
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_ds;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: DS';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_ds_vchecklist;

    /**
    * Current Nursing assemssment notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_nsp_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name       VARCHAR2(30 CHAR) := 'GET_NSP_VCHECKLIST';
        l_flg_checklist   VARCHAR2(1 CHAR);
        l_error           t_error_out;
        l_id_pn_note_type pn_note_type.id_pn_note_type%TYPE := pk_prog_notes_constants.g_note_type_nur_assm_16; --Nursing assessment
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: NSP';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_summary(i_lang            => i_lang,
                                    i_prof            => i_prof,
                                    i_patient         => i_patient,
                                    i_episode         => i_episode,
                                    i_scope_type      => i_scope_type,
                                    i_id_pn_note_type => l_id_pn_note_type,
                                    o_flg_checklist   => l_flg_checklist,
                                    o_error           => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_nsp_vchecklist;
    /**
    * Current Nursing Initial Assessment checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Vanessa barsottelli
    * @version     2.6.5
    * @since       24-Set-2016
    */
    FUNCTION get_nia_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_NIA_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_nur_init_assm_17, --Initial nursing assessment
                                                            pk_prog_notes_constants.g_note_type_nia_ft_19, -- Initial nursing assessment free text
                                                            pk_prog_notes_constants.g_note_type_nur_init_assm_42); --Initial nursing assessment AHP
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_nia;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: NIA';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_nia_vchecklist;

    /**
    * Current nursing progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_npn_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_NPN_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_nur_prog_note_18, -- Nursing progress notes
                                                            pk_prog_notes_constants.g_note_type_npn_ft_20); --Nursing progress notes free text
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_npn;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: NPN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_npn_vchecklist;

    /**
    * Current physician progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_pn_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_PN_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_prog_note_10, /*Recheck*/
                                                            pk_prog_notes_constants.g_note_type_prog_note_ft_11, /*Recheck free text*/
                                                            pk_prog_notes_constants.g_note_type_prog_note_32, -- Physician progress note - outp
                                                            pk_prog_notes_constants.g_note_type_id_ftn_7, -- Physician progress note free text
                                                            pk_prog_notes_constants.g_note_type_prog_note_3);
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_pn;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: PN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_pn_vchecklist;

    /**
    * Current consultation report notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_crds_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_CRDS_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_visit_note_14); --consultation report
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_ds;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: DS';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_crds_vchecklist;

    /**
    * Current initial nutrition evaluation notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_dia_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_DIA_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_die_init_assm_29, --dietary initial assessment
                                                            pk_prog_notes_constants.g_note_type_dia_ft_24); --dietary initial assessment free text
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_dia;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: DIA';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_dia_vchecklist;

    /**
    * Current nutrition progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_dpn_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_DPN_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_nutr_prog_note_33, --Nutrition progress note
                                                            pk_prog_notes_constants.g_note_type_dpn_ft_25, -- Nutrition progress note free text
                                                            pk_prog_notes_constants.g_note_type_nutr_prog_note_26); -- Nutrition notes - TEC
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_dpn;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: DPN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_dpn_vchecklist;

    /**
    * Current nutrition visit note checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_nvn_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_NVN_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_nutr_visit_note_30); --Nutrition visit note
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_nvn;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: NVN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_nvn_vchecklist;

    /**
    * Current Pharmacist notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_phan_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_PHAN_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_pharm_note_ft_34); --Pharmacist notes free text
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_phan;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: PHAN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_phan_vchecklist;

    /**
    * Current Initial respiratory assessment note checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_ria_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_RIA_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_resp_init_assm_27); --Initial respiratory assessment
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_ria;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: RIA';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_ria_vchecklist;

    /**
    * Current Respiratory therapy progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_rpn_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(30 CHAR) := 'GET_RPN_VCHECKLIST';
        l_flg_checklist    VARCHAR2(1 CHAR);
        l_error            t_error_out;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_resp_prog_note_28); --Respiratory therapy progress notes
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_rpn;
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: RPN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_rpn_vchecklist;

    /**
    * Get the id_tasks associated to a note and a given task type
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_id_epis_pn             Note ID
    * @param      i_id_tl_task             Task type ID
    *
    * @author      Sofia Mendes
    * @version     2.7.1
    * @since       07/09/2017
    */
    FUNCTION get_note_tasks_by_task_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_id_tl_task IN tl_task.id_tl_task%TYPE,
        o_tasks      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_NOTE_TASKS_BY_TASK_TYPE';
    
    BEGIN
    
        g_error := 'GET_NOTE_TASKS_BY_TASK_TYPE. i_id_epis_pn: ' || i_id_epis_pn || ' i_id_tl_task: ' || i_id_tl_task;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT epdt.id_task
          BULK COLLECT
          INTO o_tasks
          FROM epis_pn_det epd
          JOIN epis_pn_det_task epdt
            ON epdt.id_epis_pn_det = epd.id_epis_pn_det
         WHERE epd.id_epis_pn = i_id_epis_pn
           AND epd.flg_status = pk_alert_constant.g_active
           AND ((epdt.flg_status = pk_alert_constant.g_active AND
               epdt.id_task_type = pk_prog_notes_constants.g_task_problems_group_ass) OR
               epdt.id_task_type <> pk_prog_notes_constants.g_task_problems_group_ass)
           AND epdt.id_task_type = i_id_tl_task;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_note_tasks_by_task_type;

    /******************************************************************************
    UC2 & UC3 & UC4: An ISS required diagnosis has been documented, please consider an ISS assessment.
    Please select one of the following actions or indicate a reason:
    
    UC5: ISS assessment score equal or greater than 16 requires a Discharge diagnosis of T07 (ICD-10).
    
    UC61: An ISS required diagnosis has been documented, please consider an ISS assessment. Please editthe note.
    UC62: An ISS assessment score equal or greater than 16 requires a Discharge diagnosis of T07 (ICD-10). Please edit the note.
    ******************************************************************************/
    FUNCTION check_iss_diag_validation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
        i_check_origin IN VARCHAR2 DEFAULT 'N', -- N: Submit in note; A: Submit in action
        o_return_flag  OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        g_use_case_2       CONSTANT VARCHAR2(10 CHAR) := 'UC2';
        g_use_case_5       CONSTANT VARCHAR2(10 CHAR) := 'UC5';
        g_use_case_61      CONSTANT VARCHAR2(10 CHAR) := 'UC61';
        g_use_case_62      CONSTANT VARCHAR2(10 CHAR) := 'UC62';
        g_submit_in_note   CONSTANT VARCHAR2(1 CHAR) := 'N';
        g_submit_in_action CONSTANT VARCHAR2(1 CHAR) := 'A';
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_ISS_DIAG_VALIDATION';
    
        l_check_iss_diag_validation   VARCHAR2(100 CHAR) := nvl(pk_sysconfig.get_config('CHECK_ISS_DIAG_VALIDATION',
                                                                                        i_prof),
                                                                pk_alert_constant.g_no);
        l_multiple_injuries_diag_code VARCHAR2(1000 CHAR) := pk_sysconfig.get_config('MULTIPLE_INJURIES_DIAGNOSIS_CODE',
                                                                                     i_prof);
    
        l_iss_tt_list table_number := table_number();
        l_dd_tt_list  table_number := table_number();
    
        l_iss_tt_num NUMBER := 0; -- Modified Injury Severity Score (ISS)
        l_dd_tt_num  NUMBER := 0; -- Discharge Diagnosis
    
        l_max_modified_iss_score     epis_mtos_param.registered_value%TYPE := 0;
        l_flg_multiple_injuries_diag VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        -----------------------------------------------------
        FUNCTION get_pn_task_type_list
        (
            i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
            i_id_task_type IN epis_pn_det_task.id_task_type%TYPE
        ) RETURN table_number IS
            l_task_list table_number := table_number();
        BEGIN
            SELECT epdt.id_task
              BULK COLLECT
              INTO l_task_list
              FROM epis_pn ep
              JOIN epis_pn_det epd
                ON epd.id_epis_pn = ep.id_epis_pn
              JOIN epis_pn_det_task epdt
                ON epdt.id_epis_pn_det = epd.id_epis_pn_det
             WHERE ep.id_epis_pn = i_id_epis_pn
               AND ep.flg_status != pk_prog_notes_constants.g_epis_pn_flg_status_c
               AND epd.flg_status IN
                   (pk_prog_notes_constants.g_epis_pn_det_flg_status_a, pk_prog_notes_constants.g_epis_pn_det_sug_add_s)
               AND epdt.flg_status IN
                   (pk_prog_notes_constants.g_epis_pn_det_flg_status_a, pk_prog_notes_constants.g_epis_pn_det_sug_add_s)
               AND epdt.id_task_type = i_id_task_type
               AND ((i_id_task_type = pk_prog_notes_constants.g_task_mtos_score AND -- if we have mtos_score task, it has to be a isstw (Modified Injury Severity Score)
                   epdt.id_group_import = pk_sev_scores_constant.g_id_score_isstw) OR
                   (i_id_task_type != pk_prog_notes_constants.g_task_mtos_score));
        
            RETURN l_task_list;
        END;
        -----------------------------------------------------
        FUNCTION get_modified_iss_score(i_iss_list table_number) RETURN NUMBER IS
            l_modified_iss_score epis_mtos_param.registered_value%TYPE := 0;
            l_miss_cur_score     epis_mtos_param.registered_value%TYPE;
        BEGIN
            IF nvl(cardinality(i_iss_list), 0) > 0
            THEN
                FOR i IN i_iss_list.first .. i_iss_list.last
                LOOP
                    IF i_iss_list(i) IS NOT NULL
                    THEN
                        l_miss_cur_score := nvl(pk_sev_scores_core.get_modified_score(i_lang            => i_lang,
                                                                                      i_prof            => i_prof,
                                                                                      i_epis_mtos_score => i_iss_list(i)),
                                                0);
                    END IF;
                
                    IF l_miss_cur_score > l_modified_iss_score
                    THEN
                        l_modified_iss_score := l_miss_cur_score;
                    END IF;
                END LOOP;
            END IF;
        
            RETURN l_modified_iss_score;
        END;
        -----------------------------------------------------
        FUNCTION get_diagnosis_injury(l_dd_tt_list table_number) RETURN NUMBER IS
            l_counter NUMBER := 0;
        BEGIN
            SELECT COUNT(1)
              INTO l_counter
              FROM alert_core_data.v_ts1_terms_ea t
              JOIN (SELECT ed.id_alert_diagnosis
                      FROM epis_diagnosis ed
                      JOIN (SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                            column_value id_epis_diagnosis, rownum rn
                             FROM TABLE(l_dd_tt_list) t) d
                        ON d.id_epis_diagnosis = ed.id_epis_diagnosis
                     WHERE ed.flg_type = pk_diagnosis.g_diag_type_d
                       AND ed.flg_status NOT IN (pk_diagnosis.g_ed_flg_status_ca, pk_diagnosis.g_ed_flg_status_r)
                       AND (ed.flg_is_complication = pk_alert_constant.g_no OR ed.flg_is_complication IS NULL)) ed
                ON ed.id_alert_diagnosis = t.id_concept_term
             WHERE alert_core_func.pk_ts1_api.set_ts_context(i_lang           => i_lang,
                                                             i_concept_type   => 'INJURY',
                                                             i_id_task_type   => 63, -- complications are also diagnosis
                                                             i_id_institution => i_prof.institution,
                                                             i_id_software    => i_prof.software,
                                                             i_id_patient     => NULL) = 1;
        
            RETURN l_counter;
        END;
        -----------------------------------------------------
        FUNCTION get_multiple_injuries_diag(l_dd_tt_list table_number) RETURN VARCHAR2 IS
            l_counter NUMBER := 0;
        BEGIN
            SELECT COUNT(1)
              INTO l_counter
              FROM epis_diagnosis ed
              JOIN (SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                     column_value id_epis_diagnosis, rownum rn
                      FROM TABLE(l_dd_tt_list) t) d
                ON d.id_epis_diagnosis = ed.id_epis_diagnosis
             WHERE ed.flg_type = pk_diagnosis.g_diag_type_d
               AND ed.flg_status NOT IN (pk_diagnosis.g_ed_flg_status_ca, pk_diagnosis.g_ed_flg_status_r)
               AND (ed.flg_is_complication = pk_alert_constant.g_no OR ed.flg_is_complication IS NULL)
               AND alert_core_func.pk_ts1_api.get_term_code(i_id_concept_term => ed.id_alert_diagnosis) =
                   l_multiple_injuries_diag_code
               AND l_multiple_injuries_diag_code IS NOT NULL;
        
            IF l_counter > 0
            THEN
                RETURN pk_alert_constant.g_yes;
            ELSE
                RETURN pk_alert_constant.g_no;
            END IF;
        END;
        -----------------------------------------------------
    BEGIN
        IF l_check_iss_diag_validation = pk_alert_constant.g_no
        THEN
            o_return_flag := pk_alert_constant.g_no;
            RETURN TRUE;
        END IF;
    
        l_iss_tt_list := get_pn_task_type_list(i_id_epis_pn, pk_prog_notes_constants.g_task_mtos_score);
        l_dd_tt_list  := get_pn_task_type_list(i_id_epis_pn, pk_prog_notes_constants.g_task_final_diag);
    
        l_iss_tt_num := nvl(cardinality(l_iss_tt_list), 0);
        l_dd_tt_num  := get_diagnosis_injury(l_dd_tt_list);
    
        l_max_modified_iss_score := get_modified_iss_score(l_iss_tt_list);
        -- NECESSÁRIO passar o diagnóstico 'T07' para sys_cfg ou outra coisa
        l_flg_multiple_injuries_diag := get_multiple_injuries_diag(l_dd_tt_list);
    
        ---------------------------------
        IF l_dd_tt_num > 0
           AND l_iss_tt_num = 0 -- UC2, UC3 & UC4: required Diagnosis and without ISS assessment
        THEN
            IF i_check_origin = g_submit_in_note
            THEN
                o_return_flag := g_use_case_2;
            ELSE
                o_return_flag := g_use_case_61;
            END IF;
            -----------------------------
        ELSIF l_iss_tt_num > 0 -- UC5: with ISS total score equal or greater than 16 (and without specific diagnosis)
              AND l_max_modified_iss_score >= 16
              AND l_flg_multiple_injuries_diag = pk_alert_constant.g_no
        THEN
            IF i_check_origin = g_submit_in_note
            THEN
                o_return_flag := g_use_case_5;
            ELSE
                o_return_flag := g_use_case_62;
            END IF;
        ELSE
            o_return_flag := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        --WHEN no_data_found THEN
        --    RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END check_iss_diag_validation;

    /******************************************************************************
    ******************************************************************************/
    FUNCTION get_iss_diag_val_params
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_return_flag     IN VARCHAR2,
        o_msg_box_desc    OUT VARCHAR2,
        o_msg_box_options OUT pk_types.cursor_type,
        o_include_reasons OUT VARCHAR2, -- Y/N
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_ISS_DIAG_VAL_PARAMS';
    
        l_option_desc     table_varchar := table_varchar();
        l_app_file        table_number := table_number();
        l_search_criteria table_varchar := table_varchar();
        l_block_criteria  table_varchar := table_varchar();
    
        g_use_case_2  CONSTANT VARCHAR2(10 CHAR) := 'UC2';
        g_use_case_5  CONSTANT VARCHAR2(10 CHAR) := 'UC5';
        g_use_case_61 CONSTANT VARCHAR2(10 CHAR) := 'UC61';
        g_use_case_62 CONSTANT VARCHAR2(10 CHAR) := 'UC62';
    
        g_use_case_2_msg  CONSTANT VARCHAR2(10 CHAR) := 'PN_T201';
        g_use_case_5_msg  CONSTANT VARCHAR2(10 CHAR) := 'PN_T202';
        g_use_case_61_msg CONSTANT VARCHAR2(10 CHAR) := 'PN_T203';
        g_use_case_62_msg CONSTANT VARCHAR2(10 CHAR) := 'PN_T204';
    
        g_opt_add_iss_assessment  CONSTANT VARCHAR2(100 CHAR) := 'PROGRESS_NOTES_T140'; -- Add ISS assessment
        g_opt_edit_iss_assessment CONSTANT VARCHAR2(100 CHAR) := 'PROGRESS_NOTES_T141'; -- Edit ISS assessment
        g_opt_add_discharge_diag  CONSTANT VARCHAR2(100 CHAR) := 'PROGRESS_NOTES_T142'; -- Add discharge diagnosis
        g_opt_edit_discharge_diag CONSTANT VARCHAR2(100 CHAR) := 'PROGRESS_NOTES_T143'; -- Edit discharge diagnosis
    
        ---------------------------------------------------
        PROCEDURE extend_tables(l_num NUMBER) IS
        BEGIN
            l_option_desc.extend(l_num);
            l_app_file.extend(l_num);
            l_search_criteria.extend(l_num);
            l_block_criteria.extend(l_num);
        END extend_tables;
    BEGIN
        ---------------------------------------------
        IF i_return_flag = g_use_case_2 -- UC2, UC3 & UC4: required Diagnosis and without ISS assessment
        THEN
            extend_tables(2);
            o_msg_box_desc    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_use_case_2_msg);
            o_include_reasons := pk_alert_constant.g_yes;
        
            l_option_desc     := table_varchar(g_opt_add_iss_assessment, g_opt_edit_discharge_diag);
            l_app_file        := table_number(5264, NULL); -- 5264: SeverityScoresGridAddEdit; 1456: DiagnosisFinalCreate  (application_file)
            l_search_criteria := table_varchar(NULL, NULL);
            l_block_criteria  := table_varchar(NULL, 1518); -- 1518: Discharge diagnoses soap block
            ---------------------------------------------
        ELSIF i_return_flag = g_use_case_5
        THEN
            extend_tables(1);
            o_msg_box_desc    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_use_case_5_msg);
            o_include_reasons := pk_alert_constant.g_no;
        
            l_option_desc     := table_varchar(g_opt_add_discharge_diag);
            l_app_file        := table_number(1456); -- 1456: DiagnosisFinalCreate (application_file)
            l_search_criteria := table_varchar('T07');
            l_block_criteria  := table_varchar(NULL);
            ---------------------------------------------
        ELSIF i_return_flag = g_use_case_61
        THEN
            extend_tables(2);
            o_msg_box_desc    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_use_case_61_msg);
            o_include_reasons := pk_alert_constant.g_yes;
        
            l_option_desc     := table_varchar(g_opt_edit_iss_assessment, g_opt_edit_discharge_diag);
            l_app_file        := table_number(NULL, NULL);
            l_search_criteria := table_varchar(NULL, NULL);
            l_block_criteria  := table_varchar(1519, 1518); -- 1519: ISS soap block; 1518: Discharge diagnoses soap block
            ---------------------------------------------
        ELSIF i_return_flag = g_use_case_62
        THEN
            extend_tables(1);
            o_msg_box_desc    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_use_case_62_msg);
            o_include_reasons := pk_alert_constant.g_no;
        
            l_option_desc     := table_varchar(g_opt_edit_discharge_diag);
            l_app_file        := table_number(NULL);
            l_search_criteria := table_varchar(NULL);
            l_block_criteria  := table_varchar(1518); -- 1518: Discharge diagnoses soap block
        END IF;
    
        OPEN o_msg_box_options FOR
            SELECT t1.rn,
                   pk_message.get_message(i_lang => i_lang, i_code_mess => t1.option_desc) option_desc,
                   t2.file_name,
                   t3.search_criteria,
                   t4.block_criteria
              FROM (SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                     rownum rn, column_value option_desc
                      FROM TABLE(l_option_desc) t) t1
              JOIN (SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                     rownum rn, column_value app_file, af.file_name
                      FROM TABLE(l_app_file) t
                      LEFT JOIN application_file af
                        ON af.id_application_file = t.column_value) t2
                ON t2.rn = t1.rn
              JOIN (SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                     rownum rn, column_value search_criteria
                      FROM TABLE(l_search_criteria) t) t3
                ON t3.rn = t1.rn
              JOIN (SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                     rownum rn, column_value block_criteria
                      FROM TABLE(l_block_criteria) t) t4
                ON t4.rn = t1.rn;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_iss_diag_val_params;

	    /**
    * Current psychology progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       03/12/2018
    */
    FUNCTION get_vwr_psycho_prog_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_VWR_PSYCHO_PROG_NOTE';
        l_flg_checklist VARCHAR2(1 CHAR);
        l_error         t_error_out;
    
        l_pn_area pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_psypn;
		l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_psycho_pn,
                                                            pk_prog_notes_constants.g_note_type_arabic_ft,
                                                            pk_prog_notes_constants.g_note_type_arabic_ft_sw,
                                                            pk_prog_notes_constants.g_note_type_arabic_ft_psy);
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: PSYPN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_vwr_psycho_prog_note;

    /**
    * Current psychology visit note checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.4
    * @since       03/12/2018
    */
    FUNCTION get_vwr_psycho_visit_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_VWR_PSYCHO_VISIT_NOTE';
        l_flg_checklist VARCHAR2(1 CHAR);
        l_error         t_error_out;
    
        l_pn_area pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_psyvn;
		l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_psycho_vn);
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: PSYVN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_vwr_psycho_visit_note;
	
	    /**
    * Current initial nutrition evaluation notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.4
    * @since       03/12/2018
    */
    FUNCTION get_vwr_psycho_ia
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_VWR_PSYCHO_IA';
        l_flg_checklist VARCHAR2(1 CHAR);
        l_error         t_error_out;
    
        l_pn_area pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_psyia;
		l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_psycho_ia);
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: PSYIA';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_vwr_psycho_ia;
	
    /**
    * Current initial CDC evaluation notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.4
    * @since       03/12/2018
    */
    FUNCTION get_vwr_cdc_ia
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_VWR_CDC_IA';
        l_flg_checklist VARCHAR2(1 CHAR);
        l_error         t_error_out;
    
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_cdcia;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_arabic_ft_cdc_ia,
                                                            pk_prog_notes_constants.g_note_type_ft_cdc_ia);
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: CDCIA';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_vwr_cdc_ia;

    /**
    * Current CDC visit note checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.4
    * @since       09/07/2019
    */
    FUNCTION get_vwr_cdc_visit_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_VWR_PSYCHO_VISIT_NOTE';
        l_flg_checklist VARCHAR2(1 CHAR);
        l_error         t_error_out;
    
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_cdcvn;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_arabic_ft_cdc_vn,
                                                            pk_prog_notes_constants.g_note_type_ft_cdc_vn);
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: PSYVN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_vwr_cdc_visit_note;

    /**
    * Current psychology progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.1
    * @since       09/07/2019
    */
    FUNCTION get_vwr_cdc_prog_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_VWR_CDC_PROG_NOTE';
        l_flg_checklist VARCHAR2(1 CHAR);
        l_error         t_error_out;
    
        l_pn_area          pn_area.internal_name%TYPE := pk_prog_notes_constants.g_area_cdcpn;
        l_ids_pn_note_type table_number := NEW table_number(pk_prog_notes_constants.g_note_type_arabic_ft_cdc_pn,
                                                            pk_prog_notes_constants.g_note_type_ft_cdc_pn);
    BEGIN
    
        g_error := 'CALL GET_VWR_NOTE_BY_AREA FOR PN_AREA: CDCPN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_vwr_note_by_area(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_patient          => i_patient,
                                    i_episode          => i_episode,
                                    i_scope_type       => i_scope_type,
                                    i_pn_area          => l_pn_area,
                                    i_ids_pn_note_type => l_ids_pn_note_type,
                                    o_flg_checklist    => l_flg_checklist,
                                    o_error            => l_error)
        THEN
            l_flg_checklist := NULL;
        END IF;
    
        RETURN l_flg_checklist;
    END get_vwr_cdc_prog_note;

BEGIN
    -- Initialization
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_prog_notes_out;
/
