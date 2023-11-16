/*-- Last Change Revision: $Rev: 2020408 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-07-29 15:50:06 +0100 (sex, 29 jul 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_rep_progress_notes IS

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

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
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PREV_ENCOUNTER';
    BEGIN
        g_error := 'CALL pk_prev_encounter.get_prev_encounter';
        IF NOT pk_prev_encounter.get_prev_encounter(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_patient  => i_patient,
                                                    i_episode  => i_episode,
                                                    o_enc_info => o_enc_info,
                                                    o_enc_data => o_enc_data,
                                                    o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_enc_info);
            pk_types.open_my_cursor(o_enc_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_enc_info);
            pk_types.open_my_cursor(o_enc_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prev_encounter;

    /********************************************************************************************
    * returns the soap block associated with the institution / software / clinical_service
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    *
    * @param OUT  o_free_text   Free text records cursor
    * @param OUT  o_rea_visit   Reason for visit records cursor
    * @param OUT  o_app_type    Appointment type records cursor
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    03/11/2010
    ********************************************************************************************/
    FUNCTION get_rep_prog_notes_blocks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_soap_blocks OUT pk_types.cursor_type,
        o_free_text   OUT pk_types.cursor_type,
        o_rea_visit   OUT pk_types.cursor_type,
        o_app_type    OUT pk_types.cursor_type,
        o_prof_rec    OUT pk_translation.t_desc_translation,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PROG_NOTES_BLOCKS';
    
    BEGIN
    
        -- get c_soap_blocks
        g_error := 'CALL pk_progress_notes_upd.get_soap_blocks';
        IF NOT pk_progress_notes_upd.get_rep_prog_notes_blocks(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_patient     => i_patient,
                                                               i_episode     => i_episode,
                                                               o_soap_blocks => o_soap_blocks,
                                                               o_free_text   => o_free_text,
                                                               o_rea_visit   => o_rea_visit,
                                                               o_app_type    => o_app_type,
                                                               o_prof_rec    => o_prof_rec,
                                                               o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    * Get reason for visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_rea_visit    cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/30
    */
    FUNCTION get_reason_for_visit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_rea_visit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_REASON_FOR_VISIT';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_reason_for_visit';
        IF NOT pk_progress_notes.get_reason_for_visit(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_episode   => i_episode,
                                                      o_rea_visit => o_rea_visit,
                                                      o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_rea_visit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_rea_visit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_reason_for_visit;

    /**
    * Get free text record detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param o_detail       detail cursor
    * @param o_history      history cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_free_text_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN NUMBER,
        o_detail     OUT pk_types.cursor_type,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FREE_TEXT_DET';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_free_text_det';
        IF NOT pk_progress_notes.get_free_text_det(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_soap_block => i_soap_block,
                                                   i_record     => i_record,
                                                   o_detail     => o_detail,
                                                   o_history    => o_history,
                                                   o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_history);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_history);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_free_text_det;

    /**
    * Get free text records complete detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_history      history cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/08
    */
    FUNCTION get_free_text_complete
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_history OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FREE_TEXT_COMPLETE';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_free_text_complete';
        IF NOT pk_progress_notes.get_free_text_complete(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_episode => i_episode,
                                                        o_history => o_history,
                                                        o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_history);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_history);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_free_text_complete;

    /**
    * Get the notes history or detail.
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_epis_pn                Note id
    * @param   i_scope                     id_patient if i_flg_scope = 'P'
    *                                      id_visit if i_flg_scope = 'V'
    *                                      id_episode if i_flg_scope = 'E'
    * @param   i_flg_report_type           Report type: C-complete report; D-forensic report
    * @param   i_start_date                Start date to be considered
    * @param   i_end_date                  End date to be considered
    * @param   i_flg_type                  Type: HN: History and Physical notes; PN: Progress 
    * @param   o_data                      Data cursor. Labels, format types and status
    * @param   o_values                    Texts/contents
    * @param   o_note_ids                  Note identifiers
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version 2.6.0.5
    * @since   02-02-2011
    */
    FUNCTION get_rep_progress_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_pn        IN epis_pn.id_epis_pn%TYPE,
        i_flg_scope         IN VARCHAR2,
        i_scope             IN NUMBER,
        i_flg_report_type   IN VARCHAR2,
        i_start_date        IN VARCHAR2,
        i_end_date          IN VARCHAR2,
        i_flg_type          IN VARCHAR2,
        i_pn_soap_block_in  IN table_number DEFAULT NULL,
        i_pn_note_type_in   IN table_number DEFAULT NULL,
        i_pn_soap_block_nin IN table_number DEFAULT NULL,
        i_pn_note_type_nin  IN table_number DEFAULT NULL,
        i_flg_search        IN table_varchar DEFAULT null,
        i_num_records       IN NUMBER DEFAULT NULL,
        o_data              OUT pk_types.cursor_type,
        o_values            OUT table_clob,
        o_note_ids          OUT table_number,
        o_note              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_REP_PROGRESS_NOTES';
        l_values         table_clob;
        l_note_type_desc VARCHAR2(1000 CHAR);
    BEGIN
        g_error := 'CALL pk_prog_notes_grids.get_rep_progress_notes';
        IF NOT pk_prog_notes_grids.get_rep_progress_notes(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_epis_pn        => i_id_epis_pn,
                                                          i_flg_scope         => i_flg_scope,
                                                          i_scope             => i_scope,
                                                          i_flg_report_type   => i_flg_report_type,
                                                          i_start_date        => i_start_date,
                                                          i_end_date          => i_end_date,
                                                          i_area              => i_flg_type,
                                                          i_pn_soap_block_in  => i_pn_soap_block_in,
                                                          i_pn_note_type_in   => i_pn_note_type_in,
                                                          i_pn_soap_block_nin => i_pn_soap_block_nin,
                                                          i_pn_note_type_nin  => i_pn_note_type_nin,
                                                          i_flg_search        => i_flg_search,
                                                          i_num_records       => i_num_records,
                                                          o_data              => o_data,
                                                          o_values            => o_values,
                                                          o_note_ids          => o_note_ids,
                                                          o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        OPEN o_note FOR
            SELECT e.id_epis_pn,
                   e.id_pn_note_type,
                   e.id_prof_create,
                   pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => e.id_prof_create) prof_signature,
                   pk_prof_utils.get_prof_num_order(i_lang => i_lang,
                                                    i_prof => profissional(e.id_prof_create,
                                                                           i_prof.institution,
                                                                           e.id_software)) prof_num_order,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => n.code_pn_note_type) note_desc,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => a.code_pn_area_report) report_desc
              FROM epis_pn e
              JOIN pn_area a
                ON e.id_pn_area = a.id_pn_area
              JOIN pn_note_type n
                ON e.id_pn_note_type = n.id_pn_note_type
             WHERE e.id_epis_pn IN (SELECT column_value
                                      FROM TABLE(o_note_ids));
                                      
        pk_prog_notes_utils.get_arabic_fields_one_cursor(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_note_ids => o_note_ids,
                                                         i_flg_report_type => i_flg_report_type,
                                                         io_values  => o_values);
    
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
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_rep_progress_notes;

    FUNCTION get_epis_prog_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area        IN VARCHAR2,
        i_filter      IN VARCHAR2 DEFAULT NULL,
        o_data        OUT pk_types.cursor_type,
        o_notes_texts OUT pk_types.cursor_type,
        o_addendums   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode     episode.id_episode%TYPE := i_id_episode;
        l_id_schedule    rehab_schedule.id_schedule%TYPE;
        l_id_epis_type   episode.id_epis_type%TYPE;
        l_filter         VARCHAR2(200 CHAR) := nvl(i_filter, pk_prog_notes_constants.g_filter_ds);
        l_comments_dummy pk_types.cursor_type;
    BEGIN
    
        IF i_prof.software = pk_alert_constant.g_soft_rehab
           AND i_area = pk_prog_notes_constants.g_screen_hp
        THEN
            g_error := 'CALL pk_rehab.get_origin_episode';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_rehab.get_origin_episode(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_id_episode        => i_id_episode,
                                               i_id_schedule       => NULL,
                                               o_id_episode_origin => l_id_episode,
                                               o_id_schedule       => l_id_schedule,
                                               o_id_epis_type      => l_id_epis_type,
                                               o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'CALL pk_prog_notes_core.get_epis_prog_notes';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_epis_prog_notes(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_episode   => l_id_episode,
                                                       i_id_patient   => NULL,
                                                       i_id_epis_pn   => i_id_epis_pn,
                                                       i_flg_scope    => pk_prog_notes_constants.g_flg_scope_e,
                                                       i_area         => i_area,
                                                       i_start_record => 0,
                                                       i_num_records  => 1,
                                                       i_search       => NULL,
                                                       i_filter       => l_filter,
                                                       o_data         => o_data,
                                                       o_notes_texts  => o_notes_texts,
                                                       o_addendums    => o_addendums,
                                                       o_comments     => l_comments_dummy,
                                                       o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PROG_NOTES',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            RETURN FALSE;
        
    END get_epis_prog_notes;

    /**
    * Returns the template id associated to a single page note type.
    *
    * @param i_lang         language identifier
    * @param i_id_epis_pn   episode id
    * @param o_id_task      id_task 
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Vítor Sá
    * @version               2.7.1.5
    * @since                2017/09/21
    */
    FUNCTION get_id_epis_documentation
    (
        i_lang       IN language.id_language%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_id_task    OUT epis_pn_det_task.id_task%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ID_EPIS_DOCUMENTATION';
    BEGIN
        g_error := 'get_id_task';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_progress_notes.get_id_epis_documentation(i_lang       => i_lang,
                                                           i_id_epis_pn => i_id_epis_pn,
                                                           o_id_task    => o_id_task,
                                                           o_error      => o_error)
        THEN
            RAISE g_exception;
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
        
    END get_id_epis_documentation;

    /**
    * Returns the template id associated to a single page note type.
    *
    * @param i_lang         language identifier
    * @param i_id_epis_pn   episode id
    * @param o_id_task      id_task 
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Coelho
    * @version              2.8.0.1
    * @since                2019/10/16
    */
    FUNCTION get_id_epis_documentation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_pn.id_episode%TYPE,
        i_id_pn_area IN pn_area.id_pn_area%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ID_EPIS_DOCUMENTATION';
    BEGIN
        g_error := 'get_id_task';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_progress_notes.get_id_epis_documentation(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_id_episode => i_id_episode,
                                                           i_id_pn_area => i_id_pn_area,
                                                           o_data       => o_data,
                                                           o_error      => o_error)
        THEN
            RAISE g_exception;
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
        
    END get_id_epis_documentation;

    FUNCTION get_note_by_area
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_area  IN pn_area.internal_name%TYPE,
        o_note  OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret       table_number;
        l_func_name VARCHAR2(30) := 'GET_NOTE_BY_AREA';
    BEGIN
    
        g_error := 'get_note_by_area';
        pk_alertlog.log_debug(g_error);
    
        l_ret := pk_prog_notes_utils.get_note_by_area(i_lang => i_lang, i_prof => i_prof, i_area => i_area);
    
        o_note := l_ret;
    
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
        
    END get_note_by_area;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_rep_progress_notes;
/