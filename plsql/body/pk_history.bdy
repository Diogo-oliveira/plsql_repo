/*-- Last Change Revision: $Rev: 2027206 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_history AS

    /**********************************************************************************************
    * GET_EPIS_COMPLETE_HISTORY       Returns all information active for complete history functionality
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param o_text                   The history text       
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          13-Nov-2006
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4 
    * @since                          05-Feb-2011
    **********************************************************************************************/
    FUNCTION get_all_epis_complete_history
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_text       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN CURSOR TEXT';
        OPEN o_text FOR
            SELECT ch.id_complete_history,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ch.id_professional) name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ch.id_professional, NULL, NULL) desc_speciality,
                   pk_date_utils.date_char_tsz(i_lang, ch.dt_creation_tstz, i_prof.institution, i_prof.software) dt_creation,
                   ch.id_professional,
                   ch.long_text,
                   ch.flg_status
              FROM complete_history ch
             WHERE ch.id_episode = i_id_episode
               AND (ch.flg_status IN (g_hist_active, g_hist_outdated) OR
                   (ch.flg_status = g_hist_inactive AND NOT EXISTS
                    (SELECT ch2.id_parent
                        FROM complete_history ch2
                       WHERE ch2.id_parent = ch.id_complete_history)))
             ORDER BY ch.dt_creation_tstz DESC, ch.id_complete_history DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ALL_EPIS_COMPLETE_HISTORY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_text);
            RETURN FALSE;
        
    END get_all_epis_complete_history;

    /**********************************************************************************************
    * GET_EPIS_COMPLETE_HISTORY       Returns the History id and text of a given id or episode
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_id_complete_history    History Record ID
    * @param o_text                   The history text       
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          13-Nov-2006
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4 
    * @since                          05-Feb-2011
    **********************************************************************************************/
    FUNCTION get_epis_complete_history
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_complete_history IN complete_history.id_complete_history%TYPE,
        o_text                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN CURSOR TEXT';
        OPEN o_text FOR
            SELECT ch.id_complete_history, ch.long_text
              FROM complete_history ch
             WHERE ch.id_episode = i_id_episode
               AND ch.id_complete_history = nvl(i_id_complete_history, ch.id_complete_history)
             ORDER BY ch.dt_creation_tstz DESC, ch.id_complete_history DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_EPIS_COMPLETE_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_text);
            RETURN FALSE;
        
    END get_epis_complete_history;

    /**********************************************************************************************
    * SET_EPIS_COMPLETE_HISTORY       Saves a register into the patient integrated history
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_text                   text to save in the patient history       
    * @param i_flg_action             Indicates the origin of the current registry ('N'-New registry; 'E'-Edited registry)
    * @param i_id_parent_ch           Id complete history used for update information
    * @param i_dt_creation_tstz       date of creation of current registry
    * @param o_id_complete_history    Id of complete_history created
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Carlos Ferreira
    * @version                        1.0 
    * @since                          14-Jan-2007
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4
    * @since                          05-Feb-2011
    **********************************************************************************************/
    FUNCTION set_epis_complete_history
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_text                IN complete_history.long_text%TYPE,
        i_flg_action          IN complete_history.flg_action%TYPE,
        i_id_parent_ch        IN complete_history.id_parent%TYPE,
        i_dt_creation_tstz    IN complete_history.dt_creation_tstz%TYPE,
        o_id_complete_history OUT complete_history.id_complete_history%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient          complete_history.id_patient%TYPE;
        l_new_flg_status      complete_history.flg_status%TYPE;
        l_id_complete_history complete_history.id_complete_history%TYPE;
    BEGIN
        g_error := 'GET ID_PATIENT FOR EPIS:' || i_id_episode;
        SELECT id_patient
          INTO l_id_patient
          FROM episode epi
         WHERE epi.id_episode = i_id_episode;
    
        g_error := 'UPD FORMER COMPLETE HISTORY EPIS:' || i_id_episode;
        IF i_flg_action = 'E' --edition of existing registry
        THEN
            l_new_flg_status := g_hist_inactive;
            --
            UPDATE complete_history
               SET flg_status = l_new_flg_status
             WHERE id_episode = i_id_episode
               AND flg_status = g_hist_active;
        END IF;
    
        SELECT seq_complete_history.nextval
          INTO l_id_complete_history
          FROM dual;
        o_id_complete_history := l_id_complete_history;
    
        g_error := 'INS FORMER COMPLETE HISTORY EPIS:' || i_id_episode;
        INSERT INTO complete_history
            (id_complete_history,
             id_episode,
             id_patient,
             id_professional,
             dt_creation_tstz,
             flg_status,
             long_text,
             flg_action,
             id_parent)
        VALUES
            (l_id_complete_history,
             i_id_episode,
             l_id_patient,
             i_prof.id,
             i_dt_creation_tstz,
             g_hist_active,
             i_text,
             i_flg_action,
             i_id_parent_ch);
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_dt_creation_tstz,
                                      i_dt_first_obs        => i_dt_creation_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_EPIS_COMPLETE_HISTORY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_complete_history;

    /**********************************************************************************************
    * SET_EPIS_COMPLETE_HISTORY       Saves a register into the patient integrated history
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_text                   text to save in the patient history       
    * @param i_flg_action             Indicates the origin of the current registry ('N'-New registry; 'E'-Edited registry)
    * @param i_id_parent_ch           Id complete history used for update information
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Carlos Ferreira
    * @version                        1.0 
    * @since                          14-Jan-2007
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4
    * @since                          05-Feb-2011
    **********************************************************************************************/
    FUNCTION set_epis_complete_history
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_text         IN complete_history.long_text%TYPE,
        i_flg_action   IN complete_history.flg_action%TYPE,
        i_id_parent_ch IN complete_history.id_parent%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_complete_history complete_history.id_complete_history%TYPE;
    BEGIN
        g_error := 'CALL TO SET_EPIS_COMPLETE_HISTORY';
        IF NOT set_epis_complete_history(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_episode          => i_id_episode,
                                         i_text                => i_text,
                                         i_flg_action          => i_flg_action,
                                         i_id_parent_ch        => i_id_parent_ch,
                                         i_dt_creation_tstz    => current_timestamp,
                                         o_id_complete_history => l_id_complete_history,
                                         o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_EPIS_COMPLETE_HISTORY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_complete_history;

    /**********************************************************************************************
    * SET_MATCH_COMPLETE_HISTORY      Function used in match functionality to update Complete History date between episodes and patients.
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode_new         Destiny episode ID
    * @param i_id_episode_old         Origin episode ID
    * @param i_id_patient_new         Destiny patient ID
    * @param i_id_patient_old         Origin patient ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4
    * @since                          2011/02/05
    **********************************************************************************************/
    FUNCTION set_match_complete_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode_new IN episode.id_episode%TYPE,
        i_id_episode_old IN episode.id_episode%TYPE,
        i_id_patient_new IN patient.id_patient%TYPE,
        i_id_patient_old IN patient.id_patient%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --PK_MATCH: EPISODE
        IF i_id_episode_new IS NOT NULL
           AND i_id_episode_old IS NOT NULL
        THEN
            g_error := 'UPD FORMER COMPLETE HISTORY (by match functionality) NEW_EPIS:' || i_id_episode_new ||
                       ' OLD_EPIS: ' || i_id_episode_old;
            UPDATE complete_history ch
               SET ch.id_episode = i_id_episode_new
             WHERE ch.id_episode = i_id_episode_old;
        END IF;
    
        --PK_MATCH: PATIENT
        IF i_id_patient_new IS NOT NULL
           AND i_id_patient_old IS NOT NULL
        THEN
            g_error := 'UPD FORMER COMPLETE HISTORY (by match functionality) NEW_PAT:' || i_id_patient_new ||
                       ' OLD_PAT: ' || i_id_patient_old;
            UPDATE complete_history ch
               SET ch.id_patient = i_id_patient_new
             WHERE ch.id_patient = i_id_patient_old;
        END IF;
    
        --PK_API_EDIS: set_episode_new_patient
        IF i_id_patient_new IS NOT NULL
           AND i_id_episode_old IS NOT NULL
        THEN
            g_error := 'UPD FORMER COMPLETE HISTORY (by PK_API_EDIS) NEW_PAT:' || i_id_patient_new || ' OLD_EPIS: ' ||
                       i_id_episode_old;
            UPDATE complete_history ch
               SET ch.id_patient = i_id_patient_new
             WHERE ch.id_episode = i_id_episode_old;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_MATCH_COMPLETE_HISTORY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_match_complete_history;

    /**********************************************************************************************
    * GET_EPIS_CH_HIST                Gets epis complete history history or detail data
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param o_hist                   History cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4
    * @since                          05-Feb-2011
    **********************************************************************************************/
    FUNCTION get_epis_ch_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_complete_history IN complete_history.id_complete_history%TYPE,
        i_flg_screen          IN VARCHAR2,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EPIS_CH_HIST';
        --
        TYPE tab_epis_complete_hist IS TABLE OF complete_history%ROWTYPE;
        l_tab_epis_complete_hist tab_epis_complete_hist;
    
        l_tab_det t_table_inp_detail := t_table_inp_detail();
    
        l_desc_notes     sys_message.desc_message%TYPE;
        l_desc_new_notes sys_message.desc_message%TYPE;
        --   
    
        FUNCTION get_values
        (
            i_actual_row   IN complete_history%ROWTYPE,
            i_previous_row IN complete_history%ROWTYPE,
            io_tab_det     IN OUT t_table_inp_detail
        ) RETURN BOOLEAN IS
            l_flg_status VARCHAR(1 CHAR) := CASE
                                                WHEN i_actual_row.flg_action = pk_history.g_hist_cancel THEN
                                                 pk_history.g_hist_cancel
                                                ELSE
                                                 pk_history.g_hist_active
                                            END;
        BEGIN
        
            --title
            pk_inp_detail.add_new_item(i_id_detail   => i_actual_row.id_complete_history,
                                       i_label_descr => pk_sysdomain.get_domain(i_code_dom => 'COMPLETE_HISTORY.FLG_ACTION',
                                                                                i_val      => i_actual_row.flg_action,
                                                                                i_lang     => i_lang),
                                       i_value_descr => NULL,
                                       i_flg_type    => pk_inp_detail.g_title_t,
                                       i_flg_status  => l_flg_status,
                                       io_tab_det    => io_tab_det);
        
            --notes
            IF nvl(i_actual_row.long_text, '-1') <> nvl(i_previous_row.long_text, '-1')
            THEN
                --previous value
                pk_inp_detail.add_new_item(i_id_detail   => i_actual_row.id_complete_history,
                                           i_label_descr => l_desc_notes,
                                           i_value_descr => nvl(i_previous_row.long_text, pk_inp_detail.g_detail_empty),
                                           i_flg_type    => pk_inp_detail.g_content_c,
                                           i_flg_status  => l_flg_status,
                                           io_tab_det    => io_tab_det);
                --new value
                pk_inp_detail.add_new_item(i_id_detail   => i_actual_row.id_complete_history,
                                           i_label_descr => l_desc_new_notes,
                                           i_value_descr => nvl(i_actual_row.long_text, pk_inp_detail.g_detail_empty),
                                           i_flg_type    => pk_inp_detail.g_new_content_n,
                                           i_flg_status  => l_flg_status,
                                           io_tab_det    => io_tab_det);
            END IF;
        
            --signature
            pk_inp_detail.add_new_item(i_id_detail   => i_actual_row.id_complete_history,
                                       i_label_descr => NULL,
                                       i_value_descr => pk_inp_detail.get_signature(i_lang                => i_lang,
                                                                                    i_prof                => i_prof,
                                                                                    i_id_episode          => i_actual_row.id_episode,
                                                                                    i_date                => i_actual_row.dt_creation_tstz,
                                                                                    i_id_prof_last_change => i_actual_row.id_professional),
                                       i_flg_type    => pk_inp_detail.g_signature_s,
                                       i_flg_status  => l_flg_status,
                                       io_tab_det    => io_tab_det);
        
            RETURN TRUE;
        END get_values;
    
        FUNCTION get_first_values
        (
            i_actual_row IN complete_history%ROWTYPE,
            io_tab_det   IN OUT t_table_inp_detail
        ) RETURN BOOLEAN IS
            l_flg_status VARCHAR(1 CHAR) := CASE
                                                WHEN i_actual_row.flg_action = pk_history.g_hist_cancel THEN
                                                 pk_history.g_hist_cancel
                                                ELSE
                                                 pk_history.g_hist_active
                                            END;
        BEGIN
        
            --title
            pk_inp_detail.add_new_item(i_id_detail   => i_actual_row.id_complete_history,
                                       i_label_descr => pk_sysdomain.get_domain(i_code_dom => 'COMPLETE_HISTORY.FLG_ACTION',
                                                                                i_val      => i_actual_row.flg_action,
                                                                                i_lang     => i_lang),
                                       i_value_descr => NULL,
                                       i_flg_type    => pk_inp_detail.g_title_t,
                                       i_flg_status  => l_flg_status,
                                       io_tab_det    => io_tab_det);
        
            --i_row.notes               
            IF i_actual_row.long_text IS NOT NULL
            THEN
                pk_inp_detail.add_new_item(i_id_detail   => i_actual_row.id_complete_history,
                                           i_label_descr => l_desc_notes,
                                           i_value_descr => i_actual_row.long_text,
                                           i_flg_type    => pk_inp_detail.g_content_c,
                                           i_flg_status  => l_flg_status,
                                           io_tab_det    => io_tab_det);
            END IF;
        
            --signature
            pk_inp_detail.add_new_item(i_id_detail   => i_actual_row.id_complete_history,
                                       i_label_descr => NULL,
                                       i_value_descr => pk_inp_detail.get_signature(i_lang                => i_lang,
                                                                                    i_prof                => i_prof,
                                                                                    i_id_episode          => i_actual_row.id_episode,
                                                                                    i_date                => i_actual_row.dt_creation_tstz,
                                                                                    i_id_prof_last_change => i_actual_row.id_professional),
                                       i_flg_type    => pk_inp_detail.g_signature_s,
                                       i_flg_status  => l_flg_status,
                                       io_tab_det    => io_tab_det);
        
            RETURN TRUE;
        END get_first_values;
    
    BEGIN
        --get all labels
        l_desc_notes := pk_message.get_message(i_lang, i_prof, 'COMPLETEHIST_T018');
    
        g_error := 'GET HIST ID_COMPLETE_HISTORY: ' || i_id_complete_history;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_flg_screen = pk_inp_detail.g_history_h
        THEN
            l_desc_new_notes := pk_message.get_message(i_lang, i_prof, 'COMPLETEHIST_T112');
        
            --History screen
            SELECT ch.* BULK COLLECT
              INTO l_tab_epis_complete_hist
              FROM complete_history ch
            CONNECT BY PRIOR ch.id_parent = ch.id_complete_history
             START WITH ch.id_complete_history = i_id_complete_history
             ORDER BY ch.dt_creation_tstz DESC;
        ELSE
            --Detail screen
            SELECT ch.* BULK COLLECT
              INTO l_tab_epis_complete_hist
              FROM complete_history ch
             WHERE ch.id_complete_history = i_id_complete_history;
        END IF;
    
        g_error := 'l_tab_epis_complete_hist ' || l_tab_epis_complete_hist.count;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_tab_epis_complete_hist.count != 0
        THEN
            FOR i IN l_tab_epis_complete_hist.first .. l_tab_epis_complete_hist.last
            LOOP
                IF (i = l_tab_epis_complete_hist.count)
                THEN
                    IF NOT get_first_values(i_actual_row => l_tab_epis_complete_hist(l_tab_epis_complete_hist.count),
                                            io_tab_det   => l_tab_det)
                    THEN
                        RETURN FALSE;
                    END IF;
                ELSE
                    IF NOT get_values(i_actual_row   => l_tab_epis_complete_hist(i),
                                      i_previous_row => l_tab_epis_complete_hist(i + 1),
                                      io_tab_det     => l_tab_det)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
                IF i_flg_screen = pk_inp_detail.g_history_h
                THEN
                
                    pk_inp_detail.add_new_item(i_id_detail   => l_tab_epis_complete_hist(i).id_complete_history,
                                               i_label_descr => NULL,
                                               i_value_descr => NULL,
                                               i_flg_type    => pk_inp_detail.g_line_l,
                                               i_flg_status  => NULL,
                                               io_tab_det    => l_tab_det);
                
                END IF;
            
            END LOOP;
        END IF;
    
        g_error := 'OPEN O_HIST';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_hist FOR
            SELECT t.id_detail, t.label_descr, t.value_descr, t.flg_type, t.flg_status
              FROM TABLE(l_tab_det) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_epis_ch_hist;

-- ***************************************************************************
-- *********************************  CONSTRUCTOR  ***************************
-- ***************************************************************************
BEGIN
    -- Log initialization.
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_history;
/
