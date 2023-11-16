/*-- Last Change Revision: $Rev: 2027194 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_health_program IS

    /********************************************************************************************
    * Registers history of patient health programs.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_pat_hpg          patient health program identifier
    * @param i_flg_operation    flg_operation
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/05/07
    ********************************************************************************************/
    FUNCTION set_pat_hpg_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_hpg       IN pat_health_program.id_pat_health_program%TYPE,
        i_flg_operation IN pat_health_program_hist.flg_operation%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat_hpg_hist pat_health_program_hist%ROWTYPE;
        l_rowids       table_varchar := table_varchar();
    BEGIN
        g_error := 'SELECT pat_health_program ' || i_pat_hpg;
        SELECT phpg.id_pat_health_program,
               phpg.id_patient,
               phpg.id_health_program,
               phpg.dt_pat_hpg_tstz,
               phpg.id_professional,
               phpg.id_institution,
               phpg.id_software,
               phpg.flg_status,
               phpg.flg_monitor_loc,
               phpg.dt_begin_tstz,
               phpg.dt_end_tstz,
               phpg.notes,
               phpg.id_cancel_reason,
               phpg.cancel_notes,
               current_timestamp,
               i_flg_operation
          INTO l_pat_hpg_hist.id_pat_health_program,
               l_pat_hpg_hist.id_patient,
               l_pat_hpg_hist.id_health_program,
               l_pat_hpg_hist.dt_pat_hpg_tstz,
               l_pat_hpg_hist.id_professional,
               l_pat_hpg_hist.id_institution,
               l_pat_hpg_hist.id_software,
               l_pat_hpg_hist.flg_status,
               l_pat_hpg_hist.flg_monitor_loc,
               l_pat_hpg_hist.dt_begin_tstz,
               l_pat_hpg_hist.dt_end_tstz,
               l_pat_hpg_hist.notes,
               l_pat_hpg_hist.id_cancel_reason,
               l_pat_hpg_hist.cancel_notes,
               l_pat_hpg_hist.dt_pat_hpg_hist_tstz,
               l_pat_hpg_hist.flg_operation
          FROM pat_health_program phpg
         WHERE phpg.id_pat_health_program = i_pat_hpg;
    
        g_error := 'INSERT INTO pat_health_program_hist';
        ts_pat_health_program_hist.ins(rec_in => l_pat_hpg_hist, rows_out => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_HEALTH_PROGRAM_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_PAT_HPG_HIST',
                                                     o_error);
    END set_pat_hpg_hist;

    /*******************************************************************************************
    * Retrieves a patient's health program data. If the health program identifier is NULL,
    * then it returns default values for a new inscription.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param i_health_program   health program identifier
    * @param i_flg_action       action fired
    * @param o_hpg              cursor
    * @param o_min_dt           date domain left bound
    * @param o_max_dt           date domain right bound
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION get_pat_hpg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_health_program IN health_program.id_health_program%TYPE,
        i_flg_action     IN action.internal_name%TYPE,
        o_hpg            OUT pk_types.cursor_type,
        o_min_dt         OUT VARCHAR2,
        o_max_dt         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_min_dt_begin VARCHAR2(16);
        l_dt           TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_status   table_varchar := table_varchar();
        l_dt_ends      table_timestamp_tz := table_timestamp_tz();
        l_flg_mon_loc  pat_health_program.flg_monitor_loc%TYPE;
        l_dt_begin     pat_health_program.dt_begin_tstz%TYPE;
        l_dt_end       pat_health_program.dt_end_tstz%TYPE;
        l_notes        pat_health_program.notes%TYPE;
    
        CURSOR c_hpg IS
            SELECT phpg.flg_monitor_loc, phpg.dt_begin_tstz, phpg.dt_end_tstz, phpg.notes
              FROM pat_health_program phpg
             WHERE phpg.id_patient = i_patient
               AND phpg.id_health_program = i_health_program
               AND phpg.id_institution = i_prof.institution
               AND phpg.id_software = i_prof.software
               AND phpg.flg_status != g_flg_status_cancelled;
        CURSOR c_hist IS
            SELECT phph.flg_status, phph.dt_end_tstz
              FROM pat_health_program phpg
              JOIN pat_health_program_hist phph
             USING (id_pat_health_program)
             WHERE phpg.id_patient = i_patient
               AND phpg.id_health_program = i_health_program
               AND phpg.id_institution = i_prof.institution
               AND phpg.id_software = i_prof.software
               AND phpg.flg_status != g_flg_status_cancelled
             ORDER BY phph.dt_pat_hpg_hist_tstz DESC;
    BEGIN
        l_dt := pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp);
    
        IF i_flg_action = g_action_new
        -- action performed was new inscription
        -- (previous was cancelled or non-existent)
        THEN
            -- no minimum begin date must be set
            l_min_dt_begin := NULL;
        
            -- set default form values
            l_flg_mon_loc := g_flg_mon_inst;
            l_dt_begin    := l_dt;
        
        ELSIF i_flg_action = g_action_edit
        -- action performed was edition
        THEN
            -- retrieve history of patient's health program
            g_error := 'OPEN c_hist';
            OPEN c_hist;
            FETCH c_hist BULK COLLECT
                INTO l_flg_status, l_dt_ends;
            CLOSE c_hist;
        
            FOR i IN 1 .. l_flg_status.count
            LOOP
                -- if health program is currently active,
                -- set minimum begin date as date of last removal
                -- if health program is currently removed,
                -- set minimum begin date as date of previous removal
                IF (l_flg_status(1) = g_flg_status_active OR (l_flg_status(1) = g_flg_status_inactive AND i > 1))
                   AND l_flg_status(i) = g_flg_status_inactive
                THEN
                    l_min_dt_begin := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                  i_date => l_dt_ends(i),
                                                                  i_prof => i_prof);
                    EXIT;
                END IF;
            END LOOP;
        
            -- set default form values
            g_error := 'OPEN c_hpg';
            OPEN c_hpg;
            FETCH c_hpg
                INTO l_flg_mon_loc, l_dt_begin, l_dt_end, l_notes;
            CLOSE c_hpg;
        
        ELSIF i_flg_action = g_action_inc
        -- action performed was inscription
        THEN
            -- health program is currently removed,
            -- set minimum begin date as date of current removal
            g_error := 'OPEN c_hpg';
            OPEN c_hpg;
            FETCH c_hpg
                INTO l_flg_mon_loc, l_dt_begin, l_dt_end, l_notes;
            CLOSE c_hpg;
        
            l_min_dt_begin := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_dt_end, i_prof => i_prof);
        
            -- set default form values
            l_flg_mon_loc := g_flg_mon_inst;
            l_dt_begin    := l_dt;
            l_dt_end      := NULL;
            l_notes       := NULL;
        
        ELSIF i_flg_action = g_action_rem
        -- action performed was removal
        THEN
            -- health program is currently active,
            -- set minimum begin date as date of current removal
            g_error := 'OPEN c_hpg';
            OPEN c_hpg;
            FETCH c_hpg
                INTO l_flg_mon_loc, l_dt_begin, l_dt_end, l_notes;
            CLOSE c_hpg;
        
            -- set default form values
            l_dt_end := l_dt;
            l_notes  := NULL;
        
        END IF;
    
        -- set date domain
        o_min_dt := l_min_dt_begin;
        o_max_dt := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_dt, i_prof => i_prof);
    
        g_error := 'OPEN o_hpg';
        OPEN o_hpg FOR
            SELECT l_flg_mon_loc flg_monitor_loc,
                   pk_sysdomain.get_domain(g_flg_mon_domain_form, l_flg_mon_loc, i_lang) monitor_loc,
                   pk_date_utils.date_send_tsz(i_lang, l_dt_begin, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, l_dt_end, i_prof) dt_end,
                   l_notes notes
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_HPG',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_hpg);
            RETURN FALSE;
    END get_pat_hpg;

    /*******************************************************************************************
    * Retrieves a patient's health programs.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param o_hpgs             cursor (id, name, dt_begin, dt_end, state)
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION get_pat_hpgs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_hpgs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_cancel sys_message.desc_message%TYPE;
        l_msg_notes  sys_message.desc_message%TYPE;
    BEGIN
        l_msg_cancel := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M001');
        l_msg_notes  := ' ' || pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M002');
    
        g_error := 'OPEN o_hpgs';
        OPEN o_hpgs FOR
            SELECT id_health_program,
                   phpg.id_pat_health_program,
                   pk_translation.get_translation(i_lang, hpg.code_health_program) ||
                   decode(phpg.flg_status,
                          g_flg_status_active,
                          NULL,
                          ' (' || pk_sysdomain.get_domain(g_flg_status_domain, phpg.flg_status, i_lang) || ')') desc_health_program,
                   pk_translation.get_translation(i_lang, hpg.code_health_program) desc_health_program_canceled,
                   pk_date_utils.dt_chr_tsz(i_lang, phpg.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.dt_chr_tsz(i_lang, phpg.dt_end_tstz, i_prof) dt_end,
                   phpg.flg_status,
                   get_monitor_loc(i_lang, phpg.id_institution, g_flg_mon_domain_grid, phpg.flg_monitor_loc) status_desc,
                   decode(decode(phpg.flg_status, g_flg_status_cancelled, phpg.cancel_notes, phpg.notes),
                          NULL,
                          NULL,
                          l_msg_notes) notes_desc,
                   decode(phpg.flg_status, g_flg_status_cancelled, phpg.cancel_notes, phpg.notes) notes,
                   pk_date_utils.date_char_tsz(i_lang, phpg.dt_pat_hpg_tstz, i_prof.institution, i_prof.software) ||
                   chr(10) || pk_prof_utils.get_name_signature(i_lang, i_prof, phpg.id_professional) ||
                   decode(pk_prof_utils.get_spec_signature(i_lang, i_prof, phpg.id_professional, i_prof.institution),
                          NULL,
                          ' ',
                          ' (' ||
                          pk_prof_utils.get_spec_signature(i_lang, i_prof, phpg.id_professional, i_prof.institution) || ') ') prof_spec
              FROM health_program hpg
              JOIN pat_health_program phpg
             USING (id_health_program)
             WHERE phpg.id_patient = i_patient
               AND phpg.id_institution = i_prof.institution
             ORDER BY decode(phpg.flg_status,
                             g_flg_status_active,
                             1,
                             g_flg_status_inactive,
                             2,
                             g_flg_status_cancelled,
                             3),
                      phpg.dt_begin_tstz;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_HPGS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_hpgs);
            RETURN FALSE;
    END get_pat_hpgs;

    /*******************************************************************************************
    * Retrieves a history of operations made in a patient's health program.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_pat_hpg          patient health program identifier
    * @param o_desc             cursor
    * @param o_hist             cursor (info, details)
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION get_pat_hpg_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat_hpg IN pat_health_program.id_pat_health_program%TYPE,
        o_desc    OUT pk_types.cursor_type,
        o_hist    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_sign      sys_message.desc_message%TYPE;
        l_msg_edit      sys_message.desc_message%TYPE;
        l_msg_canc      sys_message.desc_message%TYPE;
        l_msg_rem       sys_message.desc_message%TYPE;
        l_msg_program   sys_message.desc_message%TYPE;
        l_msg_monitor   sys_message.desc_message%TYPE;
        l_msg_signed    sys_message.desc_message%TYPE;
        l_msg_removed   sys_message.desc_message%TYPE;
        l_msg_notes     sys_message.desc_message%TYPE;
        l_msg_status    sys_message.desc_message%TYPE;
        l_msg_canc_reas sys_message.desc_message%TYPE;
        l_msg_canc_nt   sys_message.desc_message%TYPE;
        l_br            VARCHAR2(4) := '<br>';
        l_na            VARCHAR2(2) := '--';
        -- reports
        l_msg_program_rep   sys_message.desc_message%TYPE;
        l_msg_monitor_rep   sys_message.desc_message%TYPE;
        l_msg_signed_rep    sys_message.desc_message%TYPE;
        l_msg_removed_rep   sys_message.desc_message%TYPE;
        l_msg_notes_rep     sys_message.desc_message%TYPE;
        l_msg_status_rep    sys_message.desc_message%TYPE;
        l_msg_canc_reas_rep sys_message.desc_message%TYPE;
        l_msg_canc_nt_rep   sys_message.desc_message%TYPE;
        -- end reports
    
    BEGIN
        l_msg_sign          := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M003');
        l_msg_edit          := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M004');
        l_msg_canc          := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M005');
        l_msg_rem           := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M006');
        l_msg_program_rep   := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M014') || ': ';
        l_msg_monitor_rep   := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M010') || ' ';
        l_msg_signed_rep    := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M027') || ' ';
        l_msg_removed_rep   := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M012') || ' ';
        l_msg_notes_rep     := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M013') || ' ';
        l_msg_status_rep    := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M007') || ' ';
        l_msg_canc_reas_rep := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M008') || ' ';
        l_msg_canc_nt_rep   := pk_message.get_message(i_lang, i_prof, 'HEALTH_PROGRAM_M023') || ' ';
        l_msg_program       := '<b>' || l_msg_program_rep || '</b>';
        l_msg_monitor       := '<b>' || l_msg_monitor_rep || '</b>';
        l_msg_signed        := '<b>' || l_msg_signed_rep || '</b>';
        l_msg_removed       := '<b>' || l_msg_removed_rep || '</b>';
        l_msg_notes         := '<b>' || l_msg_notes_rep || '</b>';
        l_msg_status        := '<b>' || l_msg_status_rep || '</b>';
        l_msg_canc_reas     := '<b>' || l_msg_canc_reas_rep || '</b>';
        l_msg_canc_nt       := '<b>' || l_msg_canc_nt_rep || '</b>';
    
        g_error := 'OPEN o_desc';
        OPEN o_desc FOR
            SELECT l_msg_program || pk_translation.get_translation(i_lang, hpg.code_health_program) || l_br ||
                   l_msg_monitor || pk_sysdomain.get_domain(g_flg_mon_domain_form, phpg.flg_monitor_loc, i_lang) || l_br ||
                   l_msg_notes || decode(phpg.notes, NULL, l_na, phpg.notes) hpg_desc,
                   -------
                   --rep--
                   -------
                   l_msg_program_rep lab_code_health_program_rep,
                   pk_translation.get_translation(i_lang, hpg.code_health_program) code_health_program_rep,
                   l_msg_monitor_rep lab_status_rep,
                   pk_sysdomain.get_domain(g_flg_mon_domain_form, phpg.flg_monitor_loc, i_lang) status_rep,
                   l_msg_notes_rep lab_notes_rep,
                   decode(phpg.notes, NULL, l_na, phpg.notes) notes_rep
              FROM pat_health_program phpg
              JOIN health_program hpg
             USING (id_health_program)
             WHERE phpg.id_pat_health_program = i_pat_hpg;
    
        g_error := 'OPEN o_hist';
        OPEN o_hist FOR
            SELECT decode(phph.flg_operation,
                          g_flg_edit,
                          decode(phph.dt_end_tstz, null, 
                          l_msg_edit,l_msg_rem),
                          g_flg_add,
                          l_msg_sign,
                          decode(phph.flg_status, g_flg_status_cancelled, l_msg_canc, l_msg_rem)) operation,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, phph.dt_pat_hpg_hist_tstz, i_prof) reg_date,
                   pk_tools.get_prof_description(i_lang, i_prof, phph.id_professional, phph.dt_pat_hpg_hist_tstz, NULL) prof_name,
                   phph.flg_status,
                   decode(phph.flg_operation,
                          g_flg_edit,
                          -- edited
                          l_msg_monitor || pk_sysdomain.get_domain(g_flg_mon_domain_form, phph.flg_monitor_loc, i_lang) || l_br ||
                          l_msg_signed || pk_date_utils.dt_chr_tsz(i_lang, phph.dt_begin_tstz, i_prof) || l_br ||
                          l_msg_removed ||
                          decode(phph.dt_end_tstz,
                                 NULL,
                                 l_na,
                                 pk_date_utils.dt_chr_tsz(i_lang, phph.dt_end_tstz, i_prof)) || l_br || l_msg_notes ||
                          nvl(phph.notes, l_na),
                          g_flg_add,
                          -- signed
                          l_msg_monitor || pk_sysdomain.get_domain(g_flg_mon_domain_form, phph.flg_monitor_loc, i_lang) || l_br ||
                          l_msg_signed || pk_date_utils.dt_chr_tsz(i_lang, phph.dt_begin_tstz, i_prof) || l_br ||
                          l_msg_removed ||
                          decode(phph.dt_end_tstz,
                                 NULL,
                                 l_na,
                                 pk_date_utils.dt_chr_tsz(i_lang, phph.dt_end_tstz, i_prof)) || l_br || l_msg_notes ||
                          nvl(phph.notes, l_na) || l_br || l_msg_status ||
                          pk_sysdomain.get_domain(g_flg_status_domain, phph.flg_status, i_lang),
                          decode(phph.flg_status,
                                 g_flg_status_cancelled,
                                 -- cancelled
                                 l_msg_canc_reas ||
                                 decode(id_cancel_reason,
                                        NULL,
                                        l_na,
                                        pk_translation.get_translation(i_lang, cr.code_cancel_reason)) || l_br ||
                                 l_msg_canc_nt || nvl(phph.cancel_notes, l_na),
                                 -- removed
                                 l_msg_removed ||
                                 decode(phph.dt_end_tstz,
                                        NULL,
                                        l_na,
                                        pk_date_utils.dt_chr_tsz(i_lang, phph.dt_end_tstz, i_prof)) || l_br ||
                                 l_msg_status || pk_sysdomain.get_domain(g_flg_status_domain, phph.flg_status, i_lang))) history,
                   ----------
                   --report--
                   ----------
                   -- edited
                   decode(phph.flg_operation, g_flg_edit, l_msg_monitor_rep) lab_edited_mon_rep,
                   decode(phph.flg_operation,
                          g_flg_edit,
                          pk_sysdomain.get_domain(g_flg_mon_domain_form, phph.flg_monitor_loc, i_lang)) edited_mon_rep,
                   decode(phph.flg_operation, g_flg_edit, l_msg_signed_rep) lab_edited_sin_rep,
                   decode(phph.flg_operation, g_flg_edit, pk_date_utils.dt_chr_tsz(i_lang, phph.dt_begin_tstz, i_prof)) edited_sin_rep,
                   decode(phph.flg_operation, g_flg_edit, l_msg_removed_rep) lab_edited_rem_rep,
                   decode(phph.flg_operation,
                          g_flg_edit,
                          decode(phph.dt_end_tstz,
                                 NULL,
                                 l_na,
                                 pk_date_utils.dt_chr_tsz(i_lang, phph.dt_end_tstz, i_prof))) edited_rem_rep,
                   decode(phph.flg_operation, g_flg_edit, l_msg_notes_rep) lab_edited_notes_rep,
                   decode(phph.flg_operation, g_flg_edit, nvl(phph.notes, l_na)) edited_notes_rep,
                   -- signed
                   decode(phph.flg_operation, g_flg_add, l_msg_monitor_rep) lab_signed_mon_rep,
                   decode(phph.flg_operation,
                          g_flg_add,
                          pk_sysdomain.get_domain(g_flg_mon_domain_form, phph.flg_monitor_loc, i_lang)) signed_mon_rep,
                   decode(phph.flg_operation, g_flg_add, l_msg_signed_rep) lab_signed_sin_rep,
                   decode(phph.flg_operation, g_flg_add, pk_date_utils.dt_chr_tsz(i_lang, phph.dt_begin_tstz, i_prof)) signed_sin_rep,
                   decode(phph.flg_operation, g_flg_add, l_msg_removed_rep) lab_signed_rem_rep,
                   decode(phph.flg_operation,
                          g_flg_add,
                          decode(phph.dt_end_tstz,
                                 NULL,
                                 l_na,
                                 pk_date_utils.dt_chr_tsz(i_lang, phph.dt_end_tstz, i_prof))) signed_rem_rep,
                   decode(phph.flg_operation, g_flg_add, l_msg_notes_rep) lab_signed_notes_rep,
                   decode(phph.flg_operation, g_flg_add, nvl(phph.notes, l_na)) signed_notes_rep,
                   decode(phph.flg_operation, g_flg_add, l_msg_status_rep) lab_signed_status_rep,
                   decode(phph.flg_operation,
                          g_flg_add,
                          pk_sysdomain.get_domain(g_flg_status_domain, phph.flg_status, i_lang)) signed_status_rep,
                   -- cancelled     
                   decode(phph.flg_status, g_flg_status_cancelled, l_msg_canc_reas_rep) lab_cancelled_status_rep,
                   decode(phph.flg_status,
                          g_flg_status_cancelled,
                          decode(id_cancel_reason,
                                 NULL,
                                 l_na,
                                 pk_translation.get_translation(i_lang, cr.code_cancel_reason))) cancelled_status_rep,
                   
                   decode(phph.flg_status, g_flg_status_cancelled, l_msg_canc_nt_rep) lab_cancelled_notes_rep,
                   decode(phph.flg_status, g_flg_status_cancelled, nvl(phph.cancel_notes, l_na)) cancelled_notes_rep,
                   -- removed
                   decode(phph.flg_operation,
                          g_flg_state_change,
                          decode(phph.flg_status, g_flg_status_inactive, l_msg_removed_rep)) lab_removed_rep,
                   decode(phph.flg_operation,
                          g_flg_state_change,
                          decode(phph.flg_status,
                                 g_flg_status_inactive,
                                 decode(phph.dt_end_tstz,
                                        NULL,
                                        l_na,
                                        pk_date_utils.dt_chr_tsz(i_lang, phph.dt_end_tstz, i_prof)))) removed_rep,
                   decode(phph.flg_operation,
                          g_flg_state_change,
                          decode(phph.flg_status, g_flg_status_inactive, l_msg_status_rep)) lab_cancelled_removed_rep,
                   decode(phph.flg_operation,
                          g_flg_state_change,
                          decode(phph.flg_status,
                                 g_flg_status_inactive,
                                 pk_sysdomain.get_domain(g_flg_status_domain, phph.flg_status, i_lang))) cancelled_removed_rep
              FROM pat_health_program_hist phph
              LEFT OUTER JOIN cancel_reason cr
             USING (id_cancel_reason)
             WHERE phph.id_pat_health_program = i_pat_hpg
               AND phph.id_institution = i_prof.institution
               AND phph.id_software = i_prof.software
             ORDER BY phph.dt_pat_hpg_hist_tstz DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_HPG_HIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_desc);
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_pat_hpg_hist;

    /*******************************************************************************************
    * Retrieve available health programs,
    * signaling those which the patient can be subscribed to.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param i_health_program   health program identifier
    * @param o_avail            cursor
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION get_available_hpgs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_avail   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_avail';
        OPEN o_avail FOR
            SELECT id_health_program id_action,
                   pk_translation.get_translation(i_lang, hpg.code_health_program) desc_action,
                   decode(phpg.id_pat_health_program, NULL, 'A', 'I') flg_active,
                   g_action_new action
              FROM health_program hpg
              JOIN health_program_soft_inst hpsi
             USING (id_health_program)
              LEFT OUTER JOIN (SELECT phpg.id_pat_health_program,
                                      phpg.id_health_program,
                                      phpg.id_institution,
                                      phpg.id_software
                                 FROM pat_health_program phpg
                                WHERE phpg.id_patient = i_patient
                                  AND phpg.flg_status != g_flg_status_cancelled
                                  AND phpg.id_institution = i_prof.institution
                                  AND phpg.id_software = i_prof.software) phpg
             USING (id_health_program)
             WHERE hpsi.id_institution IN (i_prof.institution, 0)
               AND hpsi.id_software IN (i_prof.software, 0)
               AND hpsi.flg_active = g_flg_yes
             ORDER BY desc_action;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AVAILABLE_HPGS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_avail);
            RETURN FALSE;
    END get_available_hpgs;

    /*******************************************************************************************
    * Creates or edits a patient's health program inscription.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param i_health_program   health program identifier
    * @param i_monitor_loc      monitor location flag
    * @param i_dt_begin         begin date
    * @param i_dt_end           end date
    * @param i_notes            record notes
    * @param i_action           action performed
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION set_pat_hpg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_health_program IN health_program.id_health_program%TYPE,
        i_monitor_loc    IN pat_health_program.flg_monitor_loc%TYPE,
        i_dt_begin       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_notes          IN pat_health_program.notes%TYPE,
        i_action         IN action.internal_name%TYPE,
        i_origin         IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_pat_hpg pat_health_program.id_pat_health_program%TYPE;
        l_flg_status pat_health_program.flg_status%TYPE;
        l_dt_begin   pat_health_program.dt_begin_tstz%TYPE;
        l_dt_end     pat_health_program.dt_end_tstz%TYPE;
        l_flg_oper   pat_health_program_hist.flg_operation%TYPE;
        l_rowids     table_varchar := table_varchar();
    BEGIN
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_timestamp => i_dt_begin,
                                                    i_timezone  => NULL);
        IF i_dt_end IS NULL
        THEN
            l_flg_status := g_flg_status_active;
        ELSE
            l_flg_status := g_flg_status_inactive;
            l_dt_end     := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_timestamp => i_dt_end,
                                                          i_timezone  => NULL);
        END IF;
        
        IF l_flg_status = g_flg_status_inactive
           AND l_dt_end < l_dt_begin
           AND i_origin = pk_alert_constant.g_pregnancy
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'SELECT id_pat_health_program';
        BEGIN
            SELECT phpg.id_pat_health_program
              INTO l_id_pat_hpg
              FROM pat_health_program phpg
             WHERE phpg.id_patient = i_patient
               AND phpg.id_health_program = i_health_program
               AND phpg.id_institution = i_prof.institution
               AND phpg.id_software = i_prof.software
               AND phpg.flg_status != g_flg_status_cancelled;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_pat_hpg := NULL;
        END;
    
        IF l_id_pat_hpg IS NULL
        THEN
            g_error := 'INSERT INTO pat_health_program';
            ts_pat_health_program.ins(id_pat_health_program_out => l_id_pat_hpg,
                                      id_patient_in             => i_patient,
                                      id_health_program_in      => i_health_program,
                                      dt_pat_hpg_tstz_in        => current_timestamp,
                                      id_professional_in        => i_prof.id,
                                      id_institution_in         => i_prof.institution,
                                      id_software_in            => i_prof.software,
                                      flg_status_in             => l_flg_status,
                                      flg_monitor_loc_in        => i_monitor_loc,
                                      dt_begin_tstz_in          => l_dt_begin,
                                      dt_end_tstz_in            => l_dt_end,
                                      notes_in                  => i_notes,
                                      rows_out                  => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_HEALTH_PROGRAM',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
            g_error := 'UPDATE pat_health_program ' || l_id_pat_hpg;
            ts_pat_health_program.upd(id_pat_health_program_in => l_id_pat_hpg,
                                      id_professional_in       => i_prof.id,
                                      id_institution_in        => i_prof.institution,
                                      id_software_in           => i_prof.software,
                                      flg_status_in            => l_flg_status,
                                      flg_monitor_loc_in       => i_monitor_loc,
                                      dt_begin_tstz_in         => l_dt_begin,
                                      dt_end_tstz_nin          => FALSE,
                                      dt_end_tstz_in           => l_dt_end,
                                      notes_nin                => FALSE,
                                      notes_in                 => i_notes,
                                      rows_out                 => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_HEALTH_PROGRAM',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        IF i_action = g_action_edit
        THEN
            l_flg_oper := g_flg_edit;
        ELSIF i_action IN (g_action_new, g_action_inc)
        THEN
            l_flg_oper := g_flg_add;
        ELSE
            l_flg_oper := g_flg_state_change;
        END IF;
    
        g_error := 'CALL set_pat_hpg_hist';
        IF NOT set_pat_hpg_hist(i_lang, i_prof, l_id_pat_hpg, l_flg_oper, o_error)
        THEN
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_HPG',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_hpg;

    /*******************************************************************************************
    * Cancels a patient's health program inscription.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_pat_hpg          pat health program identifier
    * @param i_motive           cancellation motive
    * @param i_notes            cancellation notes
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION cancel_pat_hpg
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat_hpg IN pat_health_program.id_pat_health_program%TYPE,
        i_motive  IN pat_health_program.id_cancel_reason%TYPE,
        i_notes   IN pat_health_program.cancel_notes%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar := table_varchar();
    BEGIN
        g_error := 'UPDATE pat_health_program ' || i_pat_hpg;
        ts_pat_health_program.upd(id_pat_health_program_in => i_pat_hpg,
                                  id_professional_in       => i_prof.id,
                                  id_institution_in        => i_prof.institution,
                                  id_software_in           => i_prof.software,
                                  flg_status_in            => g_flg_status_cancelled,
                                  id_cancel_reason_in      => i_motive,
                                  cancel_notes_in          => i_notes,
                                  rows_out                 => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_HEALTH_PROGRAM',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'CALL set_pat_hpg_hist';
        IF NOT set_pat_hpg_hist(i_lang, i_prof, i_pat_hpg, g_flg_state_change, o_error)
        THEN
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
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAT_HPG',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_pat_hpg;

    /*******************************************************************************************
    * Checks if an institution has health programs configured, if the professional is a
    * physician. If the professional is a nurse, then it also checks configuration
    * HEALTH_PROGRAMS_NURSE_PERMISSION, that allows nurses to change health programs.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_prof_cat         logged professional category
    * @param o_avail            'Y', if at least one health program is available, 'N' otherwise
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/05/06
    ********************************************************************************************/
    FUNCTION check_hpgs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        o_avail    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
        IF i_prof_cat = pk_alert_constant.g_cat_type_nurse
        THEN
            o_avail := pk_sysconfig.get_config('HEALTH_PROGRAMS_NURSE_PERMISSION', i_prof);
            IF o_avail = g_flg_no
            THEN
                RETURN TRUE;
            END IF;
        END IF;
    
        SELECT COUNT(*)
          INTO l_count
          FROM health_program_soft_inst hpsi
         WHERE hpsi.id_institution IN (i_prof.institution, 0)
           AND hpsi.id_software IN (i_prof.software, 0)
           AND hpsi.flg_active = g_flg_yes;
    
        IF l_count > 0
        THEN
            o_avail := g_flg_yes;
        ELSE
            o_avail := g_flg_no;
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
                                              'CHECK_HPGS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_hpgs;

    /*******************************************************************************************
    * Retrieves the health programs a patient is currently inscripted.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param o_hpgs             cursor
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/05/07
    ********************************************************************************************/
    FUNCTION get_pat_insc_hpgs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_hpgs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_sys_shortcut CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 1875;
    BEGIN
        OPEN o_hpgs FOR
            SELECT pk_translation.get_translation(i_lang, hpg.code_health_program) description,
                   l_id_sys_shortcut shortcut
              FROM pat_health_program phpg
              JOIN health_program hpg
             USING (id_health_program)
             WHERE phpg.id_patient = i_patient
               AND phpg.id_institution = i_prof.institution
               AND phpg.id_software = i_prof.software
               AND phpg.flg_status = g_flg_status_active
             ORDER BY description;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_INSC_HPGS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_hpgs);
            RETURN FALSE;
    END get_pat_insc_hpgs;

    /**
    * Get patient's health programs.
    *
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_exc_status   statuses list to exclude
    *
    * @return               health program identifiers list
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/10/30
    */
    FUNCTION get_pat_hpgs
    (
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_exc_status IN table_varchar := table_varchar()
    ) RETURN table_number IS
        l_ret   table_number;
        l_insts table_number;
        l_cnt   PLS_INTEGER;
    BEGIN
        IF i_exc_status IS NULL
           OR i_exc_status.count < 1
        THEN
            l_cnt := 0;
        ELSE
            l_cnt := i_exc_status.count;
        END IF;
    
        l_insts := pk_list.tf_get_all_inst_group(i_institution  => i_prof.institution,
                                                 i_flg_relation => pk_adt.g_inst_grp_flg_rel_adt);
    
        SELECT DISTINCT phpg.id_health_program
          BULK COLLECT
          INTO l_ret
          FROM pat_health_program phpg
         WHERE phpg.id_patient = i_patient
           AND phpg.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                        t.column_value id_institution
                                         FROM TABLE(CAST(l_insts AS table_number)) t)
           AND (l_cnt = 0 OR
               phpg.flg_status NOT IN (SELECT /*+opt_estimate(table t rows=1)*/
                                         t.column_value flg_status
                                          FROM TABLE(CAST(i_exc_status AS table_varchar)) t));
    
        RETURN l_ret;
    END get_pat_hpgs;

    /**
    * Get health programs collection.
    * Used in periodic observations.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_exc_status   statuses list to exclude
    *
    * @return               health programs collection
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/12
    */
    FUNCTION get_pat_hpgs_coll
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_exc_status IN table_varchar := table_varchar()
    ) RETURN t_coll_sets IS
        l_ret  t_coll_sets;
        l_hpgs table_number;
        l_cnt  PLS_INTEGER;
    
    BEGIN
        IF i_exc_status IS NULL
           OR i_exc_status.count < 1
        THEN
            l_cnt := 0;
        ELSE
            l_cnt := i_exc_status.count;
        END IF;
    
        l_hpgs := get_pat_hpgs(i_prof => i_prof, i_patient => i_patient, i_exc_status => i_exc_status);
    
        SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT pk_periodic_observation.g_task_type_hpg id_task_type,
                       hpg.id_content sets_id,
                       hpg.rank,
                       pk_translation.get_translation(i_lang, hpg.code_health_program) sets_desc,
                       get_monitor_loc(i_lang, phpg.id_institution, g_flg_mon_domain_grid, phpg.flg_monitor_loc) sets_institutions
                  FROM health_program hpg
                  JOIN pat_health_program phpg
                    ON hpg.id_health_program = phpg.id_health_program
                 WHERE phpg.id_patient = i_patient
                   AND hpg.id_health_program IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                  t.column_value id_health_program
                                                   FROM TABLE(CAST(l_hpgs AS table_number)) t)
                   AND (l_cnt = 0 OR phpg.flg_status NOT IN
                       (SELECT /*+opt_estimate(table t rows=1)*/
                                       t.column_value flg_status
                                        FROM TABLE(CAST(i_exc_status AS table_varchar)) t)))
         ORDER BY rank, sets_desc;
    
        RETURN l_ret;
    END get_pat_hpgs_coll;

    /**
    * Get monitoring location description.
    *
    * @param i_lang         language identifier
    * @param i_inst         institution identifier
    * @param i_domain       monitor location domain code
    * @param i_flg_mon_loc  monitor location flag
    *
    * @return               monitoring location description
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/10/30
    */
    FUNCTION get_monitor_loc
    (
        i_lang        IN language.id_language%TYPE,
        i_inst        IN institution.id_institution%TYPE,
        i_domain      IN sys_domain.code_domain%TYPE,
        i_flg_mon_loc IN pat_health_program.flg_monitor_loc%TYPE
    ) RETURN sys_domain.desc_val%TYPE IS
        l_ret sys_domain.desc_val%TYPE;
    BEGIN
        IF i_flg_mon_loc = g_flg_mon_inst
        THEN
            l_ret := pk_utils.get_institution_name(i_lang => i_lang, i_id_institution => i_inst);
        ELSIF i_flg_mon_loc = g_flg_mon_other
        THEN
            l_ret := pk_sysdomain.get_domain(i_code_dom => i_domain, i_val => i_flg_mon_loc, i_lang => i_lang);
        END IF;
    
        RETURN l_ret;
    END get_monitor_loc;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_health_program;
/
