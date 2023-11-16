/*-- Last Change Revision: $Rev: 2027318 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_lens IS

    FUNCTION is_lens_available
    (
        i_lens lens.id_lens%TYPE,
        i_prof profissional
    ) RETURN lens_soft_inst.rank%TYPE IS
    
        l_return lens_soft_inst.rank%TYPE;
    
    BEGIN
    
        SELECT rank
          INTO l_return
          FROM (SELECT lsi.id_lens,
                       lsi.flg_available,
                       lsi.rank,
                       row_number() over(ORDER BY decode(lsi.id_institution, i_prof.institution, 1, 2), decode(lsi.id_software, i_prof.software, 1, 2)) line_number
                  FROM lens_soft_inst lsi
                 WHERE lsi.id_lens = i_lens
                   AND lsi.id_institution IN (0, i_prof.institution)
                   AND lsi.id_software IN (0, i_prof.software))
         WHERE line_number = 1;
    
        RETURN l_return;
    
    END is_lens_available;

    FUNCTION get_lens_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_lens IN lens.id_lens%TYPE,
        o_lens    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_LENS';
        OPEN o_lens FOR
            SELECT l.id_lens,
                   pk_translation.get_translation(i_lang, l.code_lens) lens_desc,
                   l.flg_type,
                   l.id_parent,
                   nvl(l.flg_undefined, pk_alert_constant.g_no) flg_undefined
              FROM lens l
             WHERE is_lens_available(l.id_lens, i_prof) IS NOT NULL
               AND nvl(i_id_lens, -1) = nvl(l.id_parent, -1)
             ORDER BY is_lens_available(l.id_lens, i_prof), lens_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LENS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_lens);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lens_list;

    FUNCTION get_adv_inp_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_lens      IN lens.id_lens%TYPE,
        o_adv_inp      OUT pk_types.cursor_type,
        o_adv_inp_form OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_far   VARCHAR2(50 CHAR) := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T021') || '@{SPACE}';
        l_msg_med   VARCHAR2(50 CHAR) := '@{SEP}' || pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T022') ||
                                         '@{SPACE}';
        l_msg_close VARCHAR2(50 CHAR) := '@{SEP}' || pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T023') ||
                                         '@{SPACE}';
    
        l_msg_mul VARCHAR2(50 CHAR) := g_msg_sign_mult || '@{SPACE}';
    
        l_msg_radius   VARCHAR2(50 CHAR) := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T024') || '@{SPACE}';
        l_msg_diameter VARCHAR2(50 CHAR) := '@{SEP}' || pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T025') ||
                                            '@{SPACE}';
        l_msg_power    VARCHAR2(50 CHAR) := '@{SEP}' || pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T026') ||
                                            '@{SPACE}';
    
        l_msg_far_empty   VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg_med_empty   VARCHAR2(50 CHAR) := '@{SEP}' || g_msg_invalid;
        l_msg_close_empty VARCHAR2(50 CHAR) := '@{SEP}' || g_msg_invalid;
    
        l_msg_radius_empty   VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg_diameter_empty VARCHAR2(50 CHAR) := '@{SEP}' || g_msg_invalid;
        l_msg_power_empty    VARCHAR2(50 CHAR) := '@{SEP}' || g_msg_invalid;
    
    BEGIN
    
        g_error := 'OPEN CURSOR FOR o_adv_inp';
        OPEN o_adv_inp FOR
            SELECT ai.id_advanced_input,
                   ai.intern_name,
                   aif.id_advanced_input_field,
                   aif.type pad_type,
                   pk_translation.get_translation(i_lang, aif.code_advanced_input_field) desc_input_field,
                   aifd.id_advanced_input_field_det,
                   aifd.field_name,
                   aifd.min_value,
                   aifd.max_value,
                   pk_message.get_message(i_lang, aifd.format_message) format,
                   aifd.alignment,
                   aifd.separator,
                   aifd.style,
                   aifd.input_mask,
                   um.id_unit_measure,
                   pk_translation.get_translation(i_lang, um.code_unit_measure) desc_unit,
                   nvl(pk_translation.get_translation(i_lang, um.code_unit_measure_abrv),
                       pk_translation.get_translation(i_lang, um.code_unit_measure)) desc_unit_abbr,
                   umt.id_unit_measure_type,
                   pk_translation.get_translation(i_lang, umt.code_unit_measure_type) desc_unit_type
              FROM advanced_input ai
              JOIN lens_advanced_input lai
                ON lai.id_advanced_input = ai.id_advanced_input
              JOIN advanced_input_soft_inst aisi
                ON aisi.id_advanced_input = lai.id_advanced_input
               AND aisi.id_institution IN (0, i_prof.institution)
               AND aisi.id_software IN (0, i_prof.software)
               AND aisi.flg_active = pk_alert_constant.g_yes
              JOIN advanced_input_field aif
                ON aif.id_advanced_input_field = aisi.id_advanced_input_field
              JOIN advanced_input_field_det aifd
                ON aifd.id_advanced_input_field = aif.id_advanced_input_field
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = aifd.id_unit
              LEFT JOIN unit_measure_type umt
                ON umt.id_unit_measure_type = um.id_unit_measure_type
             WHERE lai.id_lens = i_id_lens
             ORDER BY ai.id_advanced_input, aisi.rank;
    
        g_error := 'OPEN CURSOR FOR o_adv_inp_form';
        OPEN o_adv_inp_form FOR
            SELECT ai.id_advanced_input,
                   ai.intern_name,
                   pk_utils.query_to_string('SELECT decode(aifd.field_name, ''FAR_SPHERE'', ''' || l_msg_far ||
                                            ''', ''PERM_SPHERE'', ''' || l_msg_med || ''', ''CLOSE_SPHERE'', ''' ||
                                            l_msg_close || ''', ''FAR_AXIS'', ''' || l_msg_mul ||
                                            ''', ''CLOSE_AXIS'', ''' || l_msg_mul || ''', ''PERM_AXIS'', ''' ||
                                            l_msg_mul || ''', ''FAR_PRISM'', ''' || ''', ''CLOSE_PRISM'', ''' ||
                                            ''', ''PERM_PRISM'', ''' || ''', ''FAR'', ''' || l_msg_far ||
                                            ''', ''CLOSE'', ''' || l_msg_close || ''', ''BVD'', ''' ||
                                            ''', ''CURVATURE_RADIUS'', ''' || l_msg_radius || ''', ''DIAMETER'', ''' ||
                                            l_msg_diameter || ''', ''POWER'', ''' || l_msg_power ||
                                            ''') || ''@{'' || aifd.field_name || ''}'' || ''@{''|| aifd.field_name ||''_UNIT}''' || --
                                            '  FROM advanced_input_field_det aifd ' || --
                                            '  JOIN advanced_input_field aif ' || --
                                            '    ON aif.id_advanced_input_field = aifd.id_advanced_input_field ' || --
                                            '  JOIN advanced_input_soft_inst aisi ' || --
                                            '    ON aisi.id_advanced_input = ' || ai.id_advanced_input || --
                                            '   AND aisi.id_institution IN (0, ' || i_prof.institution || ') ' || --
                                            '   AND aisi.id_software IN (0, ' || i_prof.software || ') ' || --
                                            '   AND aisi.flg_active = ''Y'' ' || --
                                            '   AND aisi.id_advanced_input_field = aif.id_advanced_input_field ' || --
                                            ' ORDER BY aisi.rank',
                                            '@{SPACE}') format,
                   pk_utils.query_to_string('SELECT decode(aifd.field_name, ''FAR_SPHERE'', ''' || l_msg_far_empty ||
                                            ''', ''PERM_SPHERE'', ''' || l_msg_med_empty || ''', ''CLOSE_SPHERE'', ''' ||
                                            l_msg_close_empty || ''', ''FAR_AXIS'', ''' || ''', ''CLOSE_AXIS'', ''' ||
                                            ''', ''PERM_AXIS'', ''' || ''', ''FAR_PRISM'', ''' ||
                                            ''', ''PERM_PRISM'', ''' || ''', ''CLOSE_PRISM'', ''' || ''', ''FAR'', ''' ||
                                            l_msg_far_empty || ''', ''CLOSE'', ''' || l_msg_close_empty ||
                                            ''', ''BVD'', ''' || ''', ''CURVATURE_RADIUS'', ''' || l_msg_radius_empty ||
                                            ''', ''DIAMETER'', ''' || l_msg_diameter_empty || ''', ''POWER'', ''' ||
                                            l_msg_power_empty || ''') ' || --
                                            '  FROM advanced_input_field_det aifd ' || --
                                            '  JOIN advanced_input_field aif ' || --
                                            '    ON aif.id_advanced_input_field = aifd.id_advanced_input_field ' || --
                                            '  JOIN advanced_input_soft_inst aisi ' || --
                                            '    ON aisi.id_advanced_input = ' || ai.id_advanced_input || --
                                            '   AND aisi.id_institution IN (0, ' || i_prof.institution || ') ' || --
                                            '   AND aisi.id_software IN (0, ' || i_prof.software || ') ' || --
                                            '   AND aisi.flg_active = ''Y'' ' || --
                                            '   AND aisi.id_advanced_input_field = aif.id_advanced_input_field ' || --
                                            ' ORDER BY aisi.rank',
                                            '') empty_format
              FROM advanced_input ai
              JOIN lens_advanced_input lai
                ON lai.id_advanced_input = ai.id_advanced_input
             WHERE lai.id_lens = i_id_lens;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ADV_INP_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_adv_inp);
            pk_types.open_my_cursor(o_adv_inp_form);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_adv_inp_list;

    FUNCTION create_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_lens              IN lens.id_lens%TYPE,
        i_id_adv_inp           IN table_number,
        i_id_adv_inp_field_det IN table_number,
        i_values               IN table_varchar,
        i_notes                IN VARCHAR2,
        i_cur_tstz             TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_lens_presc        OUT lens_presc.id_lens_presc%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_presc     lens_presc%ROWTYPE;
        l_presc_det lens_presc_det%ROWTYPE;
    
        l_rows table_varchar;
    
    BEGIN
    
        g_error := 'GET LENS_PRESC NEXTVAL';
        SELECT seq_lens_presc.nextval
          INTO o_id_lens_presc
          FROM dual;
    
        l_presc.id_lens_presc      := o_id_lens_presc;
        l_presc.id_lens            := i_id_lens;
        l_presc.id_episode         := i_id_episode;
        l_presc.id_patient         := i_id_patient;
        l_presc.id_prof_presc      := i_prof.id;
        l_presc.dt_lens_presc_tstz := i_cur_tstz;
        l_presc.flg_status         := pk_alert_constant.g_lens_presc_flg_status_i;
        l_presc.notes              := i_notes;
    
        g_error := 'INSERT INTO LENS_PRESC';
        ts_lens_presc.ins(rec_in => l_presc, rows_out => l_rows);
    
        l_presc_det.id_lens_presc := l_presc.id_lens_presc;
    
        FOR i IN 1 .. i_values.count
        LOOP
            l_presc_det.id_lens_presc_hist   := -1;
            l_presc_det.id_advanced_input    := i_id_adv_inp(i);
            l_presc_det.id_adv_inp_field_det := i_id_adv_inp_field_det(i);
            l_presc_det.value                := i_values(i);
            IF l_presc_det.value IS NOT NULL
            THEN
                g_error := 'INSERT INTO LENS_PRESC_DET(' || i || ')';
                pk_alertlog.log_debug(g_error);
                ts_lens_presc_det.ins(rec_in => l_presc_det, rows_out => l_rows);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PRESC',
                                              o_error);
            RETURN FALSE;
    END create_presc;

    FUNCTION create_presc_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_lens              IN table_number,
        i_id_adv_inp           IN table_table_number,
        i_id_adv_inp_field_det IN table_table_number,
        i_values               IN table_table_varchar,
        i_notes                IN table_varchar,
        o_id_lens_presc        OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        o_id_lens_presc := table_number();
    
        FOR i IN 1 .. i_id_lens.count
        LOOP
            o_id_lens_presc.extend;
        
            g_error := 'CREATE_PRESC(' || i || ')';
            IF NOT create_presc(i_lang                 => i_lang,
                                i_prof                 => i_prof,
                                i_id_episode           => i_id_episode,
                                i_id_patient           => i_id_patient,
                                i_id_lens              => i_id_lens(i),
                                i_id_adv_inp           => i_id_adv_inp(i),
                                i_id_adv_inp_field_det => i_id_adv_inp_field_det(i),
                                i_values               => i_values(i),
                                i_notes                => i_notes(i),
                                i_cur_tstz             => g_sysdate_tstz,
                                o_id_lens_presc        => o_id_lens_presc(i),
                                o_error                => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PRESC_LIST',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_presc_list;

    FUNCTION update_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_lens_presc        IN lens_presc.id_lens_presc%TYPE,
        i_id_episode           IN lens_presc.id_episode%TYPE,
        i_id_lens              IN lens.id_lens%TYPE DEFAULT NULL,
        i_flg_status           IN lens_presc.flg_status%TYPE DEFAULT NULL,
        i_id_adv_inp           IN table_number DEFAULT NULL,
        i_id_adv_inp_field_det IN table_number DEFAULT NULL,
        i_values               IN table_varchar DEFAULT NULL,
        i_notes                IN VARCHAR2 DEFAULT NULL,
        i_id_cancel_reason     IN NUMBER DEFAULT NULL,
        i_cur_tstz             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_presc      lens_presc%ROWTYPE;
        l_presc_hist lens_presc_hist%ROWTYPE;
        l_presc_det  lens_presc_det%ROWTYPE;
    
        l_rows table_varchar;
    
    BEGIN
    
        g_error := 'SELECT INTO .. FROM LENS_PRESC';
        SELECT *
          INTO l_presc
          FROM lens_presc l
         WHERE l.id_lens_presc = i_id_lens_presc;
    
        -- Store history data
        g_error := 'GET LENS_PRESC_HIST NEXTVAL';
        SELECT seq_lens_presc_hist.nextval
          INTO l_presc_hist.id_lens_presc_hist
          FROM dual;
    
        l_presc_hist.id_lens_presc      := l_presc.id_lens_presc;
        l_presc_hist.id_lens            := l_presc.id_lens;
        l_presc_hist.id_episode         := l_presc.id_episode;
        l_presc_hist.id_patient         := l_presc.id_patient;
        l_presc_hist.id_prof_presc      := l_presc.id_prof_presc;
        l_presc_hist.dt_lens_presc_tstz := l_presc.dt_lens_presc_tstz;
        l_presc_hist.id_prof_cancel     := l_presc.id_prof_cancel;
        l_presc_hist.dt_cancel_tstz     := l_presc.dt_cancel_tstz;
        l_presc_hist.id_prof_print      := l_presc.id_prof_print;
        l_presc_hist.dt_print_tstz      := l_presc.dt_print_tstz;
        l_presc_hist.flg_status         := l_presc.flg_status;
        l_presc_hist.notes              := l_presc.notes;
        l_presc_hist.notes_cancel       := l_presc.notes_cancel;
        l_presc_hist.id_cancel_reason   := l_presc.id_cancel_reason;
        l_presc_hist.create_user        := i_prof.id;
        l_presc_hist.create_time        := i_cur_tstz;
    
        g_error := 'INSERT INTO LENS_PRESC_HIST';
        ts_lens_presc_hist.ins(rec_in => l_presc_hist, rows_out => l_rows);
    
        g_error := 'UPDATE LENS_PRESC_DET';
        UPDATE lens_presc_det l
           SET l.id_lens_presc_hist = l_presc_hist.id_lens_presc_hist
         WHERE l.id_lens_presc = l_presc.id_lens_presc
           AND l.id_lens_presc_hist = -1;
    
        IF i_values IS NULL
           OR i_values.count = 0
        THEN
            g_error := 'INSERT INTO LENS_PRESC_DET';
            pk_alertlog.log_debug(g_error);
            INSERT INTO lens_presc_det
                (id_lens_presc, id_lens_presc_hist, id_advanced_input, id_adv_inp_field_det, VALUE)
                SELECT l.id_lens_presc, -1, l.id_advanced_input, l.id_adv_inp_field_det, l.value
                  FROM lens_presc_det l
                 WHERE l.id_lens_presc = l_presc.id_lens_presc
                   AND l.id_lens_presc_hist = l_presc_hist.id_lens_presc_hist;
        END IF;
    
        l_presc.id_lens    := nvl(i_id_lens, l_presc.id_lens);
        l_presc.id_episode := nvl(i_id_episode, l_presc.id_episode);
    
        IF i_flg_status = pk_alert_constant.g_lens_presc_flg_status_i -- In construction
        THEN
            l_presc.id_prof_presc      := i_prof.id;
            l_presc.dt_lens_presc_tstz := i_cur_tstz;
            l_presc.notes              := i_notes;
        ELSIF i_flg_status = pk_alert_constant.g_lens_presc_flg_status_p -- Printed
        THEN
            l_presc.id_prof_print := i_prof.id;
            l_presc.dt_print_tstz := i_cur_tstz;
            l_presc.notes         := i_notes;
        ELSIF i_flg_status = pk_alert_constant.g_lens_presc_flg_status_c -- Cancelled
        THEN
            l_presc.id_prof_cancel   := i_prof.id;
            l_presc.dt_cancel_tstz   := i_cur_tstz;
            l_presc.notes_cancel     := i_notes;
            l_presc.id_cancel_reason := i_id_cancel_reason;
        END IF;
    
        l_presc.flg_status := i_flg_status;
    
        g_error := 'UPDATE LENS_PRESC';
        ts_lens_presc.upd(rec_in => l_presc, rows_out => l_rows);
    
        IF i_values IS NOT NULL
           AND i_values.count > 0
        THEN
            l_presc_det.id_lens_presc := l_presc.id_lens_presc;
        
            FOR i IN 1 .. i_values.count
            LOOP
                l_presc_det.id_lens_presc_hist   := -1;
                l_presc_det.id_advanced_input    := i_id_adv_inp(i);
                l_presc_det.id_adv_inp_field_det := i_id_adv_inp_field_det(i);
                l_presc_det.value                := i_values(i);
            
                IF l_presc_det.value IS NOT NULL
                THEN
                    g_error := 'INSERT INTO LENS_PRESC_DET(' || i || ')';
                    ts_lens_presc_det.ins(rec_in => l_presc_det, rows_out => l_rows);
                END IF;
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
                                              'UPDATE_PRESC',
                                              o_error);
            RETURN FALSE;
    END update_presc;

    FUNCTION set_presc_print
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_lens_presc IN lens_presc.id_lens_presc%TYPE,
        i_id_episode    IN lens_presc.id_episode%TYPE,
        i_cur_tstz      IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'UPDATE_PRESC';
        IF NOT update_presc(i_lang          => i_lang,
                            i_prof          => i_prof,
                            i_id_lens_presc => i_id_lens_presc,
                            i_id_episode    => i_id_episode,
                            i_flg_status    => pk_alert_constant.g_lens_presc_flg_status_p,
                            i_cur_tstz      => i_cur_tstz,
                            o_error         => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'SET_PRESC_PRINT',
                                              o_error);
            RETURN FALSE;
    END set_presc_print;

    FUNCTION set_presc_list_print
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_episode    IN lens_presc.id_episode%TYPE,
        i_id_lens_presc IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_id_lens_presc.count
        LOOP
            g_error := 'SET_PRESC_PRINT(' || i || ')';
            IF NOT set_presc_print(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_id_lens_presc => i_id_lens_presc(i),
                                   i_id_episode    => i_id_episode,
                                   i_cur_tstz      => g_sysdate_tstz,
                                   o_error         => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PRESC_LIST_PRINT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_presc_list_print;

    FUNCTION set_presc_cancel
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_lens_presc    IN lens_presc.id_lens_presc%TYPE,
        i_id_episode       IN NUMBER,
        i_notes            IN VARCHAR2,
        i_id_cancel_reason IN NUMBER,
        i_cur_tstz         TIMESTAMP WITH LOCAL TIME ZONE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'UPDATE_PRESC';
        IF NOT update_presc(i_lang             => i_lang,
                            i_prof             => i_prof,
                            i_id_lens_presc    => i_id_lens_presc,
                            i_id_episode       => i_id_episode,
                            i_flg_status       => pk_alert_constant.g_lens_presc_flg_status_c,
                            i_notes            => i_notes,
                            i_id_cancel_reason => i_id_cancel_reason,
                            i_cur_tstz         => i_cur_tstz,
                            o_error            => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'SET_PRESC_CANCEL',
                                              o_error);
            RETURN FALSE;
    END set_presc_cancel;

    FUNCTION set_presc_list_cancel
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN lens_presc.id_episode%TYPE,
        i_id_lens_presc    IN table_number,
        i_id_cancel_reason IN NUMBER,
        i_notes            IN VARCHAR2,
        i_confirmation     IN VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_cursor           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_confirmation = pk_alert_constant.g_yes
        THEN
            o_flg_show := pk_alert_constant.g_no;
        
            FOR i IN 1 .. i_id_lens_presc.count
            LOOP
                g_error := 'SET_PRESC_CANCEL(' || i || ')';
                IF NOT set_presc_cancel(i_lang             => i_lang,
                                        i_prof             => i_prof,
                                        i_id_lens_presc    => i_id_lens_presc(i),
                                        i_id_episode       => i_id_episode,
                                        i_notes            => i_notes,
                                        i_id_cancel_reason => i_id_cancel_reason,
                                        i_cur_tstz         => g_sysdate_tstz,
                                        o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END LOOP;
        
            OPEN o_cursor FOR
                SELECT 1
                  FROM dual
                 WHERE 1 = 2;
        
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_episode,
                                          i_pat                 => i_id_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            COMMIT;
        ELSE
            o_flg_show := pk_alert_constant.g_yes;
        
            g_error     := 'GET_MESSAGES';
            o_msg_title := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T037');
        
            IF i_id_lens_presc.count < 2
            THEN
                o_msg := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_M001');
            ELSE
                o_msg := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_M002');
            END IF;
        
            o_button := 'NC86464' || pk_sysdomain.get_domain('YES_NO', pk_alert_constant.g_no, i_lang) || --
                        '|C829664' || pk_sysdomain.get_domain('YES_NO', pk_alert_constant.g_yes, i_lang) || '|';
        
            g_error := 'OPEN O_CURSOR';
            OPEN o_cursor FOR
                SELECT lp.id_lens_presc, pk_translation.get_translation(i_lang, l.code_lens) lens_presc_desc
                  FROM lens_presc lp
                  JOIN lens l
                    ON l.id_lens = lp.id_lens
                 WHERE lp.id_lens_presc IN (SELECT *
                                              FROM TABLE(i_id_lens_presc));
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
                                              'SET_PRESC_LIST_CANCEL',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_presc_list_cancel;

    FUNCTION set_presc_values
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_lens_presc        IN lens_presc.id_lens_presc%TYPE,
        i_id_lens              IN lens.id_lens%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_adv_inp           IN table_number,
        i_id_adv_inp_field_det IN table_number,
        i_values               IN table_varchar,
        i_notes                IN VARCHAR2,
        i_cur_tstz             TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'UPDATE_PRESC';
        RETURN update_presc(i_lang                 => i_lang,
                            i_prof                 => i_prof,
                            i_id_lens_presc        => i_id_lens_presc,
                            i_id_lens              => i_id_lens,
                            i_id_episode           => i_id_episode,
                            i_flg_status           => pk_alert_constant.g_lens_presc_flg_status_i,
                            i_id_adv_inp           => i_id_adv_inp,
                            i_id_adv_inp_field_det => i_id_adv_inp_field_det,
                            i_values               => i_values,
                            i_notes                => i_notes,
                            i_cur_tstz             => i_cur_tstz,
                            o_error                => o_error);
    
    END set_presc_values;

    FUNCTION set_presc_list_values
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN lens_presc.id_episode%TYPE,
        i_id_lens_presc        IN table_number,
        i_id_lens              IN table_number,
        i_id_adv_inp           IN table_table_number,
        i_id_adv_inp_field_det IN table_table_number,
        i_values               IN table_table_varchar,
        i_notes                IN table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_id_lens_presc.count
        LOOP
            g_error := 'SET_PRESC_VALUES(' || i || ')';
            IF NOT set_presc_values(i_lang                 => i_lang,
                                    i_prof                 => i_prof,
                                    i_id_lens_presc        => i_id_lens_presc(i),
                                    i_id_lens              => i_id_lens(i),
                                    i_id_episode           => i_id_episode,
                                    i_id_adv_inp           => i_id_adv_inp(i),
                                    i_id_adv_inp_field_det => i_id_adv_inp_field_det(i),
                                    i_values               => i_values(i),
                                    i_notes                => i_notes(i),
                                    i_cur_tstz             => g_sysdate_tstz,
                                    o_error                => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PRESC_LIST_VALUES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_presc_list_values;

    FUNCTION get_degrees
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_lens_presc      IN lens_presc.id_lens_presc%TYPE,
        i_id_lens_presc_hist IN lens_presc_hist.id_lens_presc_hist%TYPE,
        i_flg_type           IN lens.flg_type%TYPE,
        i_flg_adv_inp        IN VARCHAR2
    ) RETURN VARCHAR IS
    
        l_adv_inp VARCHAR2(64) := 'LENS_PRESC_GLASSES_';
    
        CURSOR c_presc_info IS
            SELECT to_number(lpd.value, '9999999D9999999', 'NLS_NUMERIC_CHARACTERS = ''. ''')
              FROM lens_presc_det lpd
              JOIN lens_presc lp
                ON lp.id_lens_presc = lpd.id_lens_presc
              JOIN advanced_input ai
                ON ai.id_advanced_input = lpd.id_advanced_input
              JOIN advanced_input_field_det aifd
                ON aifd.id_advanced_input_field_det = lpd.id_adv_inp_field_det
              JOIN advanced_input_field aif
                ON aif.id_advanced_input_field = aifd.id_advanced_input_field
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = aifd.id_unit
             WHERE ai.intern_name = l_adv_inp
               AND lpd.id_lens_presc = i_id_lens_presc
               AND lpd.id_lens_presc_hist = -1
               AND aifd.field_name IN ('FAR_AXIS', 'CLOSE_AXIS', 'FAR_PRISM', 'CLOSE_PRISM')
               AND lpd.value IS NOT NULL
               AND lp.flg_status = pk_alert_constant.g_lens_presc_flg_status_p;
    
        l_val lens_presc_det.value%TYPE;
    
    BEGIN
    
        IF i_id_lens_presc_hist != -1
           OR i_flg_type = pk_alert_constant.g_lens_flg_type_l
        THEN
            RETURN NULL;
        ELSE
            IF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_r
            THEN
                l_adv_inp := l_adv_inp || 'RIGHT_EYE';
            ELSIF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_l
            THEN
                l_adv_inp := l_adv_inp || 'LEFT_EYE';
            ELSE
                RETURN NULL;
            END IF;
        
            g_error := 'OPEN CURSOR C_PRESC_INFO';
            OPEN c_presc_info;
            FETCH c_presc_info
                INTO l_val;
            CLOSE c_presc_info;
        END IF;
    
        RETURN l_val;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => 'GET_DEGREES',
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END get_degrees;

    FUNCTION get_presc_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_lens_presc      IN lens_presc.id_lens_presc%TYPE,
        i_id_lens_presc_hist IN lens_presc_hist.id_lens_presc_hist%TYPE,
        i_flg_type           IN lens.flg_type%TYPE,
        i_flg_adv_inp        IN VARCHAR2,
        i_ign_perm           IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR IS
    
        l_adv_inp VARCHAR2(64) := 'LENS_PRESC_';
    
        CURSOR c_presc_info IS
            SELECT aif.intern_name,
                   lpd.value,
                   aifd.format_message,
                   decode(um.id_unit_measure,
                          NULL,
                          '',
                          nvl(pk_translation.get_translation(i_lang, um.code_unit_measure_abrv),
                              pk_translation.get_translation(i_lang, um.code_unit_measure))) desc_unit
              FROM lens_presc_det lpd
              JOIN advanced_input ai
                ON ai.id_advanced_input = lpd.id_advanced_input
              JOIN advanced_input_field_det aifd
                ON aifd.id_advanced_input_field_det = lpd.id_adv_inp_field_det
              JOIN advanced_input_field aif
                ON aif.id_advanced_input_field = aifd.id_advanced_input_field
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = aifd.id_unit
             WHERE ai.intern_name = l_adv_inp
               AND lpd.id_lens_presc = i_id_lens_presc
               AND lpd.id_lens_presc_hist = i_id_lens_presc_hist
            UNION
            SELECT aif.intern_name,
                   lpd.value,
                   aifd.format_message,
                   decode(um.id_unit_measure,
                          NULL,
                          '',
                          nvl(pk_translation.get_translation(i_lang, um.code_unit_measure_abrv),
                              pk_translation.get_translation(i_lang, um.code_unit_measure))) desc_unit
              FROM lens_presc_det lpd
              JOIN advanced_input ai
                ON ai.id_advanced_input = lpd.id_advanced_input
              JOIN advanced_input_field_det aifd
                ON aifd.id_advanced_input_field_det = lpd.id_adv_inp_field_det
              JOIN advanced_input_field aif
                ON aif.id_advanced_input_field = aifd.id_advanced_input_field
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = aifd.id_unit
             WHERE ai.intern_name = decode(l_adv_inp, 'LENS_PRESC_GLASSES_INTERPUPIL', 'LENS_PRESC_GLASSES_BVD', NULL)
               AND lpd.id_lens_presc = i_id_lens_presc
               AND lpd.id_lens_presc_hist = i_id_lens_presc_hist;
    
        l_msg11 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg12 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg13 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg14 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg21 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg22 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg23 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg24 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg31 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg32 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg33 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg34 VARCHAR2(50 CHAR) := g_msg_invalid;
    
        l_msg_far   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T021');
        l_msg_med   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T022');
        l_msg_close sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T023');
    
        l_msg_prism    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T044');
        l_msg_radius   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T024');
        l_msg_diameter sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T025');
        l_msg_power    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T026');
    
        l_num_val       NUMBER;
        l_val_formatted VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_ign_perm = pk_alert_constant.g_no
        THEN
            l_msg21 := g_msg_invalid;
        END IF;
    
        IF i_flg_type = pk_alert_constant.g_lens_flg_type_g
        THEN
            l_adv_inp := l_adv_inp || 'GLASSES_';
        ELSIF i_flg_type = pk_alert_constant.g_lens_flg_type_l
        THEN
            l_adv_inp := l_adv_inp || 'CONTACT_';
        END IF;
    
        IF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_r
        THEN
            l_adv_inp := l_adv_inp || 'RIGHT_EYE';
        ELSIF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_l
        THEN
            l_adv_inp := l_adv_inp || 'LEFT_EYE';
        ELSIF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_o
        THEN
            IF i_flg_type = pk_alert_constant.g_lens_flg_type_g
            THEN
                l_adv_inp := l_adv_inp || 'INTERPUPIL';
            ELSIF i_flg_type = pk_alert_constant.g_lens_flg_type_l
            THEN
                l_adv_inp := l_adv_inp || 'BRAND';
            END IF;
        END IF;
    
        g_error := 'OPEN CURSOR c_presc_info for ' || l_adv_inp;
        FOR rec IN c_presc_info
        LOOP
            IF rec.intern_name != 'BRAND'
            THEN
                g_error         := 'CONVERT VALUES';
                l_num_val       := to_number(rec.value, '9999999D9999999', 'NLS_NUMERIC_CHARACTERS = ''. ''');
                l_val_formatted := TRIM(REPLACE(to_char(l_num_val,
                                                        pk_message.get_message(i_lang, i_prof, rec.format_message)),
                                                '.',
                                                pk_sysconfig.get_config('DECIMAL_SYMBOL', i_prof)));
            END IF;
        
            IF rec.intern_name = 'FAR_SPHERE'
            THEN
                l_msg11 := l_val_formatted;
            ELSIF rec.intern_name = 'FAR_CYLINDER'
            THEN
                l_msg12 := l_val_formatted;
            ELSIF rec.intern_name = 'FAR_AXIS'
            THEN
                l_msg13 := ' ' || g_msg_sign_mult || ' ' || l_val_formatted || rec.desc_unit;
            ELSIF rec.intern_name = 'FAR_PRISM'
            THEN
                l_msg14 := ' ' || l_msg_prism || l_val_formatted;
            ELSIF rec.intern_name = 'PERM_SPHERE'
            THEN
                l_msg21 := l_val_formatted;
            ELSIF rec.intern_name = 'PERM_CYLINDER'
            THEN
                l_msg22 := l_val_formatted;
            ELSIF rec.intern_name = 'PERM_AXIS'
            THEN
                l_msg23 := ' ' || g_msg_sign_mult || ' ' || l_val_formatted || rec.desc_unit;
            ELSIF rec.intern_name = 'PERM_PRISM'
            THEN
                l_msg24 := ' ' || l_msg_prism || l_val_formatted;
            ELSIF rec.intern_name = 'CLOSE_SPHERE'
            THEN
                l_msg31 := l_val_formatted;
            ELSIF rec.intern_name = 'CLOSE_CYLINDER'
            THEN
                l_msg32 := l_val_formatted;
            ELSIF rec.intern_name = 'CLOSE_AXIS'
            THEN
                l_msg33 := ' ' || g_msg_sign_mult || ' ' || l_val_formatted || rec.desc_unit;
            ELSIF rec.intern_name = 'CLOSE_PRISM'
            THEN
                l_msg34 := ' ' || l_msg_prism || l_val_formatted;
            ELSIF rec.intern_name = 'FAR'
            THEN
                l_msg11 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'CLOSE'
            THEN
                l_msg12 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'BVD'
            THEN
                l_msg13 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'CURVATURE_RADIUS'
            THEN
                l_msg11 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'DIAMETER'
            THEN
                l_msg21 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'POWER'
            THEN
                l_msg31 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'BRAND'
            THEN
                l_msg11 := rec.value;
            END IF;
        END LOOP;
    
        IF i_flg_type = pk_alert_constant.g_lens_flg_type_g
        THEN
            IF i_flg_adv_inp IN (pk_alert_constant.g_lens_presc_info_r, pk_alert_constant.g_lens_presc_info_l)
            THEN
                IF i_ign_perm = pk_alert_constant.g_yes
                   AND l_msg21 = g_msg_invalid
                   AND l_msg22 = g_msg_invalid
                   AND l_msg23 = g_msg_invalid
                   AND l_msg24 = g_msg_invalid
                THEN
                    IF l_msg11 = g_msg_invalid
                       AND l_msg12 = g_msg_invalid
                       AND l_msg13 = g_msg_invalid
                       AND l_msg14 = g_msg_invalid
                       AND l_msg31 = g_msg_invalid
                       AND l_msg32 = g_msg_invalid
                       AND l_msg33 = g_msg_invalid
                       AND l_msg34 = g_msg_invalid
                    THEN
                        RETURN l_msg11 || chr(13) || l_msg31;
                    ELSE
                        IF l_msg13 = g_msg_invalid
                        THEN
                            l_msg13 := g_msg_sign_mult || ' ' || g_msg_invalid;
                        END IF;
                    
                        IF l_msg33 = g_msg_invalid
                        THEN
                            l_msg33 := g_msg_sign_mult || ' ' || g_msg_invalid;
                        END IF;
                    
                        IF l_msg34 = g_msg_invalid
                        THEN
                            l_msg34 := '';
                        END IF;
                    
                        RETURN l_msg_far || ' ' || TRIM(l_msg11) || ' ' || TRIM(l_msg12) || ' ' || TRIM(l_msg13) || ' ' || TRIM(l_msg14) || chr(13) || --
                        l_msg_close || ' ' || TRIM(l_msg31) || ' ' || TRIM(l_msg32) || ' ' || TRIM(l_msg33) || ' ' || TRIM(l_msg34);
                    END IF;
                
                ELSE
                    IF l_msg11 = g_msg_invalid
                       AND l_msg12 = g_msg_invalid
                       AND l_msg13 = g_msg_invalid
                       AND l_msg14 = g_msg_invalid
                       AND l_msg21 = g_msg_invalid
                       AND l_msg22 = g_msg_invalid
                       AND l_msg23 = g_msg_invalid
                       AND l_msg24 = g_msg_invalid
                       AND l_msg31 = g_msg_invalid
                       AND l_msg32 = g_msg_invalid
                       AND l_msg33 = g_msg_invalid
                       AND l_msg34 = g_msg_invalid
                    THEN
                        RETURN l_msg11 || chr(13) || l_msg21 || chr(13) || l_msg31;
                    ELSE
                        IF l_msg13 = g_msg_invalid
                        THEN
                            l_msg13 := g_msg_sign_mult || ' ' || g_msg_invalid;
                        END IF;
                    
                        IF l_msg23 = g_msg_invalid
                        THEN
                            l_msg23 := g_msg_sign_mult || ' ' || g_msg_invalid;
                        END IF;
                    
                        IF l_msg33 = g_msg_invalid
                        THEN
                            l_msg33 := g_msg_sign_mult || ' ' || g_msg_invalid;
                        END IF;
                    
                        IF l_msg34 = g_msg_invalid
                        THEN
                            l_msg34 := '';
                        END IF;
                    
                        RETURN l_msg_far || ' ' || TRIM(l_msg11) || ' ' || TRIM(l_msg12) || ' ' || TRIM(l_msg13) || ' ' || TRIM(l_msg14) || chr(13) || --
                        l_msg_med || ' ' || TRIM(l_msg21) || ' ' || TRIM(l_msg22) || ' ' || TRIM(l_msg23) || ' ' || TRIM(l_msg24) || chr(13) || --
                        l_msg_close || ' ' || TRIM(l_msg31) || ' ' || TRIM(l_msg32) || ' ' || TRIM(l_msg33) || ' ' || TRIM(l_msg34);
                    
                    END IF;
                END IF;
            
            ELSIF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_o
            THEN
                RETURN l_msg_far || ' ' || TRIM(l_msg11) || '; ' || l_msg_close || ' ' || TRIM(l_msg12) --
                || '@{SEP}' || TRIM(l_msg13);
            END IF;
        
        ELSIF i_flg_type = pk_alert_constant.g_lens_flg_type_l
        THEN
            IF i_flg_adv_inp IN (pk_alert_constant.g_lens_presc_info_r, pk_alert_constant.g_lens_presc_info_l)
            THEN
            
                IF l_msg11 = g_msg_invalid
                   AND l_msg21 = g_msg_invalid
                   AND l_msg31 = g_msg_invalid
                THEN
                    RETURN l_msg11 || chr(13) || l_msg21 || chr(13) || l_msg31;
                ELSE
                    RETURN l_msg_radius || ' ' || TRIM(l_msg11) || chr(13) || --
                    l_msg_diameter || ' ' || TRIM(l_msg21) || chr(13) || --
                    l_msg_power || ' ' || TRIM(l_msg31);
                END IF;
            
            ELSIF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_o
            THEN
                RETURN TRIM(l_msg11);
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => 'GET_PRESC_INFO',
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END get_presc_info;

    FUNCTION get_ignore_perm
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    
        CURSOR c_ign_perm IS
            SELECT aisi.flg_active
              FROM advanced_input_soft_inst aisi
              JOIN advanced_input_field aif
                ON aif.id_advanced_input_field = aisi.id_advanced_input_field
              JOIN advanced_input ai
                ON ai.id_advanced_input = aisi.id_advanced_input
             WHERE aisi.id_institution IN (0, i_prof.institution)
               AND aisi.id_software IN (0, i_prof.software)
               AND aif.intern_name IN ('PERM_SPHERE', 'PERM_CYLINDER', 'PERM_AXIS', 'PERM_PRISM')
               AND aisi.flg_active = pk_alert_constant.g_yes
               AND rownum < 2;
    
        l_aux      VARCHAR2(1 CHAR);
        l_ign_perm VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_IGN_PERM';
        OPEN c_ign_perm;
        FETCH c_ign_perm
            INTO l_aux;
        g_found := c_ign_perm%FOUND;
        CLOSE c_ign_perm;
    
        IF NOT g_found
        THEN
            l_ign_perm := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_ign_perm;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => 'GET_IGNORE_PERM',
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END get_ignore_perm;

    FUNCTION get_presc_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN lens.id_lens%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_grid       OUT pk_types.cursor_type,
        o_details    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ign_perm VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_msg_presc_glasses      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'LENS_PRESC_T040');
        l_msg_presc_contact_lens sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'LENS_PRESC_T027');
        l_msg_current_epis       sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'LENS_PRESC_T010');
        l_msg_other_epis         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'LENS_PRESC_T011');
        l_msg_cancelled          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M028');
        l_msg_with_notes         sys_message.desc_message%TYPE := '(' ||
                                                                  pk_message.get_message(i_lang, i_prof, 'COMMON_M008') || ')';
    
    BEGIN
    
        g_error    := 'CHECK IGNORE PERM';
        l_ign_perm := get_ignore_perm(i_lang, i_prof);
    
        g_error := 'OPEN CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT id_lens_presc,
                   id_lens id_col1,
                   desc_lens desc_col1,
                   flg_type sep_crit_col1,
                   decode(flg_type,
                          pk_alert_constant.g_lens_flg_type_g,
                          l_msg_presc_glasses,
                          pk_alert_constant.g_lens_flg_type_l,
                          l_msg_presc_contact_lens,
                          NULL) desc_crit_col1,
                   right_desc id_col2,
                   right_desc desc_col2,
                   flg_type sep_crit_col2,
                   decode(flg_type,
                          pk_alert_constant.g_lens_flg_type_g,
                          l_msg_presc_glasses,
                          pk_alert_constant.g_lens_flg_type_l,
                          l_msg_presc_contact_lens,
                          NULL) desc_crit_col2,
                   left_desc id_col3,
                   left_desc desc_col3,
                   flg_type sep_crit_col3,
                   decode(flg_type,
                          pk_alert_constant.g_lens_flg_type_g,
                          l_msg_presc_glasses,
                          pk_alert_constant.g_lens_flg_type_l,
                          l_msg_presc_contact_lens,
                          NULL) desc_crit_col3,
                   dt_val id_col4,
                   dt_desc desc_col4,
                   hour_desc,
                   decode(flg_status, pk_alert_constant.g_lens_presc_flg_status_c, l_msg_cancelled, '') ||
                   decode(notes,
                          NULL,
                          decode(notes_cancel, NULL, '', chr(13) || l_msg_with_notes),
                          chr(13) || l_msg_with_notes) notes,
                   cur_episode sep_crit_col4,
                   decode(cur_episode, 1, l_msg_current_epis, l_msg_other_epis) desc_crit_col4,
                   flg_status id_col5,
                   icon desc_col5,
                   flg_status sep_crit_col5,
                   desc_status desc_crit_col5,
                   decode(flg_status,
                          pk_alert_constant.g_lens_presc_flg_status_i,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) allow_edit,
                   decode(flg_status,
                          pk_alert_constant.g_lens_presc_flg_status_c,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) allow_print,
                   decode(flg_status,
                          pk_alert_constant.g_lens_presc_flg_status_i,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_lens_presc_flg_status_p,
                          decode(cur_episode, 1, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                          pk_alert_constant.g_no) allow_cancel,
                   pk_alert_constant.g_yes allow_duplicate,
                   desc_lens lens_desc,
                   right_desc,
                   left_desc,
                   id_lens,
                   id_parent,
                   notes notes_desc
              FROM (SELECT lp.id_lens_presc,
                           l.id_lens,
                           l.id_parent,
                           pk_translation.get_translation(i_lang, l.code_lens) desc_lens,
                           l.flg_type,
                           get_presc_info(i_lang,
                                          i_prof,
                                          lp.id_lens_presc,
                                          -1,
                                          l.flg_type,
                                          pk_alert_constant.g_lens_presc_info_r,
                                          l_ign_perm) right_desc,
                           get_presc_info(i_lang,
                                          i_prof,
                                          lp.id_lens_presc,
                                          -1,
                                          l.flg_type,
                                          pk_alert_constant.g_lens_presc_info_l,
                                          l_ign_perm) left_desc,
                           pk_date_utils.date_send_tsz(i_lang, lp.dt_lens_presc_tstz, i_prof) dt_val,
                           pk_date_utils.date_chr_short_read_tsz(i_lang, lp.dt_lens_presc_tstz, i_prof) dt_desc,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            lp.dt_lens_presc_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) hour_desc,
                           lp.flg_status,
                           pk_sysdomain.get_domain('LENS_PRESC.FLG_STATUS', lp.flg_status, i_lang) desc_status,
                           pk_sysdomain.get_img(i_lang, 'LENS_PRESC.FLG_STATUS', lp.flg_status) icon,
                           lp.id_episode,
                           decode(lp.id_episode, i_id_episode, 1, 0) cur_episode,
                           lp.notes,
                           lp.notes_cancel
                      FROM lens_presc lp
                      JOIN lens l
                        ON l.id_lens = lp.id_lens
                     WHERE lp.id_patient = i_id_patient
                       AND (lp.id_episode = i_id_episode OR lp.flg_status != pk_alert_constant.g_lens_presc_flg_status_c));
    
        g_error := 'OPEN CURSOR O_DETAILS';
        OPEN o_details FOR
            SELECT lp.id_lens_presc,
                   ai.id_advanced_input,
                   ai.intern_name,
                   aifd.id_advanced_input_field_det,
                   aifd.field_name,
                   CASE
                        WHEN pk_utils.is_number(lpd.value) = pk_alert_constant.g_yes THEN
                         to_char(to_number(lpd.value, '9999999D9999999', 'NLS_NUMERIC_CHARACTERS = ''. '''))
                        ELSE
                         lpd.value
                    END VALUE,
                   nvl(pk_translation.get_translation(i_lang, um.code_unit_measure_abrv),
                       pk_translation.get_translation(i_lang, um.code_unit_measure)) desc_unit_abbr
              FROM lens_presc lp
              JOIN lens_presc_det lpd
                ON lpd.id_lens_presc = lp.id_lens_presc
              JOIN advanced_input ai
                ON ai.id_advanced_input = lpd.id_advanced_input
              JOIN advanced_input_field_det aifd
                ON aifd.id_advanced_input_field_det = lpd.id_adv_inp_field_det
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = aifd.id_unit
             WHERE lp.id_patient = i_id_patient
               AND lpd.id_lens_presc_hist = -1
               AND (lp.id_episode = i_id_episode OR lp.flg_status != pk_alert_constant.g_lens_presc_flg_status_c);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PRESC_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            pk_types.open_my_cursor(o_details);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_presc_list;

    FUNCTION get_presc_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_lens_presc IN lens_presc.id_lens_presc%TYPE,
        i_flg_show_hist IN VARCHAR2,
        o_presc_det     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ign_perm VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_msg_print  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T029');
        l_msg_first  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T013');
        l_msg_edit   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T038');
        l_msg_cancel sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T039');
    
        l_msg_other_glasses_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'LENS_PRESC_T020') ||
                                                                   '@{SEP}' ||
                                                                   pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'LENS_PRESC_T045');
        l_msg_other_lens_label    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'LENS_PRESC_T019');
    
    BEGIN
    
        g_error    := 'CHECK IGNORE PERM';
        l_ign_perm := get_ignore_perm(i_lang, i_prof);
    
        g_error := 'OPEN CURSOR O_PRESC_DET';
        OPEN o_presc_det FOR
            SELECT msg,
                   dt_desc,
                   dt_desc_report,
                   desc_prof,
                   decode(desc_speciality, '', '', '(' || desc_speciality || ')') desc_speciality,
                   desc_speciality desc_speciality_report,
                   degree_right,
                   degree_left,
                   right_desc,
                   left_desc,
                   other_label,
                   other_desc,
                   lens_desc,
                   status_desc,
                   flg_status,
                   notes,
                   cancel_reason_desc,
                   notes_cancel,
                   dt_print,
                   dt_print_report,
                   flg_type,
                   right_desc_report,
                   left_desc_report,
                   other_desc_report
              FROM (SELECT msg,
                           pk_date_utils.date_char_tsz(i_lang, dt_tstz, i_prof.institution, i_prof.software) dt_desc,
                           pk_date_utils.date_char_tsz(i_lang, dt_tstz, i_prof.institution, i_prof.software) dt_desc_report,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof) desc_prof,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, id_prof, dt_tstz, id_episode) desc_speciality,
                           degree_right,
                           degree_left,
                           right_desc,
                           left_desc,
                           other_label,
                           other_desc,
                           lens_desc,
                           status_desc,
                           flg_status,
                           notes,
                           cancel_reason_desc,
                           notes_cancel,
                           decode(dt_print_tstz,
                                  NULL,
                                  '',
                                  pk_date_utils.date_char_tsz(i_lang, dt_print_tstz, i_prof.institution, i_prof.software)) dt_print,
                           decode(dt_print_tstz,
                                  NULL,
                                  '',
                                  pk_date_utils.date_char_tsz(i_lang, dt_print_tstz, i_prof.institution, i_prof.software)) dt_print_report,
                           flg_type,
                           dt_tstz,
                           right_desc_report,
                           left_desc_report,
                           other_desc_report
                      FROM (SELECT decode(lp.flg_status,
                                          pk_alert_constant.g_lens_presc_flg_status_p,
                                          l_msg_print,
                                          pk_alert_constant.g_lens_presc_flg_status_i,
                                          decode((SELECT COUNT(*)
                                                   FROM lens_presc_hist lph
                                                  WHERE lph.id_lens_presc = i_id_lens_presc),
                                                 0,
                                                 l_msg_first,
                                                 l_msg_edit),
                                          pk_alert_constant.g_lens_presc_flg_status_c,
                                          l_msg_cancel) msg,
                                   decode(lp.flg_status,
                                          pk_alert_constant.g_lens_presc_flg_status_p,
                                          lp.dt_print_tstz,
                                          pk_alert_constant.g_lens_presc_flg_status_i,
                                          lp.dt_lens_presc_tstz,
                                          pk_alert_constant.g_lens_presc_flg_status_c,
                                          lp.dt_cancel_tstz) dt_tstz,
                                   lp.dt_print_tstz,
                                   decode(lp.flg_status,
                                          pk_alert_constant.g_lens_presc_flg_status_p,
                                          lp.id_prof_print,
                                          pk_alert_constant.g_lens_presc_flg_status_i,
                                          lp.id_prof_presc,
                                          pk_alert_constant.g_lens_presc_flg_status_c,
                                          lp.id_prof_cancel) id_prof,
                                   pk_lens.get_degrees(i_lang,
                                                       i_prof,
                                                       lp.id_lens_presc,
                                                       -1,
                                                       l.flg_type,
                                                       pk_alert_constant.g_lens_presc_info_r) degree_right,
                                   pk_lens.get_degrees(i_lang,
                                                       i_prof,
                                                       lp.id_lens_presc,
                                                       -1,
                                                       l.flg_type,
                                                       pk_alert_constant.g_lens_presc_info_l) degree_left,
                                   pk_lens.get_presc_info(i_lang,
                                                          i_prof,
                                                          lp.id_lens_presc,
                                                          -1,
                                                          l.flg_type,
                                                          pk_alert_constant.g_lens_presc_info_r,
                                                          l_ign_perm) right_desc,
                                   pk_lens.get_presc_info(i_lang,
                                                          i_prof,
                                                          lp.id_lens_presc,
                                                          -1,
                                                          l.flg_type,
                                                          pk_alert_constant.g_lens_presc_info_l,
                                                          l_ign_perm) left_desc,
                                   (CAST(pk_utils.str_split(decode(l.flg_type,
                                                                   pk_alert_constant.g_lens_flg_type_g,
                                                                   l_msg_other_glasses_label,
                                                                   pk_alert_constant.g_lens_flg_type_l,
                                                                   l_msg_other_lens_label,
                                                                   NULL),
                                                            '@{SEP}') AS table_varchar2)) other_label,
                                   (CAST(pk_utils.str_split(pk_lens.get_presc_info(i_lang,
                                                                                   i_prof,
                                                                                   lp.id_lens_presc,
                                                                                   -1,
                                                                                   l.flg_type,
                                                                                   pk_alert_constant.g_lens_presc_info_o,
                                                                                   l_ign_perm),
                                                            '@{SEP}') AS table_varchar2)) other_desc,
                                   pk_translation.get_translation(i_lang, l.code_lens) lens_desc,
                                   pk_sysdomain.get_domain('LENS_PRESC.FLG_STATUS', lp.flg_status, i_lang) status_desc,
                                   lp.notes,
                                   decode(cr.id_cancel_reason,
                                          NULL,
                                          NULL,
                                          pk_translation.get_translation(i_lang, cr.code_cancel_reason)) cancel_reason_desc,
                                   lp.notes_cancel,
                                   l.id_lens,
                                   lp.id_lens_presc,
                                   lp.flg_status,
                                   pk_date_utils.date_send_tsz(i_lang, lp.dt_lens_presc_tstz, i_prof) dt_val,
                                   lp.id_episode,
                                   l.flg_type,
                                   pk_lens.get_presc_info_report(i_lang,
                                                                 i_prof,
                                                                 lp.id_lens_presc,
                                                                 -1,
                                                                 l.flg_type,
                                                                 pk_alert_constant.g_lens_presc_info_r,
                                                                 l_ign_perm) right_desc_report,
                                   pk_lens.get_presc_info_report(i_lang,
                                                                 i_prof,
                                                                 lp.id_lens_presc,
                                                                 -1,
                                                                 l.flg_type,
                                                                 pk_alert_constant.g_lens_presc_info_l,
                                                                 l_ign_perm) left_desc_report,
                                   pk_lens.get_presc_info_report(i_lang,
                                                                 i_prof,
                                                                 lp.id_lens_presc,
                                                                 -1,
                                                                 l.flg_type,
                                                                 pk_alert_constant.g_lens_presc_info_o,
                                                                 l_ign_perm) other_desc_report
                              FROM lens_presc lp
                              JOIN lens l
                                ON l.id_lens = lp.id_lens
                              LEFT JOIN cancel_reason cr
                                ON cr.id_cancel_reason = lp.id_cancel_reason
                             WHERE lp.id_lens_presc = i_id_lens_presc
                            UNION ALL
                            SELECT decode(lph.flg_status,
                                          pk_alert_constant.g_lens_presc_flg_status_p,
                                          l_msg_print,
                                          pk_alert_constant.g_lens_presc_flg_status_i,
                                          decode((SELECT COUNT(*)
                                                   FROM lens_presc_hist lph2
                                                  WHERE lph2.id_lens_presc = i_id_lens_presc
                                                    AND lph2.dt_lens_presc_tstz < lph.dt_lens_presc_tstz),
                                                 0,
                                                 l_msg_first,
                                                 l_msg_edit),
                                          pk_alert_constant.g_lens_presc_flg_status_c,
                                          l_msg_cancel) msg,
                                   decode(lph.flg_status,
                                          pk_alert_constant.g_lens_presc_flg_status_p,
                                          lph.dt_print_tstz,
                                          pk_alert_constant.g_lens_presc_flg_status_i,
                                          lph.dt_lens_presc_tstz,
                                          pk_alert_constant.g_lens_presc_flg_status_c,
                                          lph.dt_cancel_tstz) dt_tstz,
                                   lph.dt_print_tstz,
                                   decode(lph.flg_status,
                                          pk_alert_constant.g_lens_presc_flg_status_p,
                                          lph.id_prof_print,
                                          pk_alert_constant.g_lens_presc_flg_status_i,
                                          lph.id_prof_presc,
                                          pk_alert_constant.g_lens_presc_flg_status_c,
                                          lph.id_prof_cancel) id_prof,
                                   pk_lens.get_degrees(i_lang,
                                                       i_prof,
                                                       lph.id_lens_presc,
                                                       lph.id_lens_presc_hist,
                                                       l.flg_type,
                                                       pk_alert_constant.g_lens_presc_info_r) degree_right,
                                   pk_lens.get_degrees(i_lang,
                                                       i_prof,
                                                       lph.id_lens_presc,
                                                       lph.id_lens_presc_hist,
                                                       l.flg_type,
                                                       pk_alert_constant.g_lens_presc_info_l) degree_left,
                                   pk_lens.get_presc_info(i_lang,
                                                          i_prof,
                                                          lph.id_lens_presc,
                                                          lph.id_lens_presc_hist,
                                                          l.flg_type,
                                                          pk_alert_constant.g_lens_presc_info_r,
                                                          l_ign_perm) right_desc,
                                   pk_lens.get_presc_info(i_lang,
                                                          i_prof,
                                                          lph.id_lens_presc,
                                                          lph.id_lens_presc_hist,
                                                          l.flg_type,
                                                          pk_alert_constant.g_lens_presc_info_l,
                                                          l_ign_perm) left_desc,
                                   (CAST(pk_utils.str_split(decode(l.flg_type,
                                                                   pk_alert_constant.g_lens_flg_type_g,
                                                                   l_msg_other_glasses_label,
                                                                   pk_alert_constant.g_lens_flg_type_l,
                                                                   l_msg_other_lens_label,
                                                                   NULL),
                                                            '@{SEP}') AS table_varchar2)) other_label,
                                   (CAST(pk_utils.str_split(pk_lens.get_presc_info(i_lang,
                                                                                   i_prof,
                                                                                   lph.id_lens_presc,
                                                                                   lph.id_lens_presc_hist,
                                                                                   l.flg_type,
                                                                                   pk_alert_constant.g_lens_presc_info_o,
                                                                                   l_ign_perm),
                                                            '@{SEP}') AS table_varchar2)) other_desc,
                                   pk_translation.get_translation(i_lang, l.code_lens) lens_desc,
                                   pk_sysdomain.get_domain('LENS_PRESC.FLG_STATUS', lph.flg_status, i_lang) status_desc,
                                   lph.notes,
                                   decode(cr.id_cancel_reason,
                                          NULL,
                                          NULL,
                                          pk_translation.get_translation(i_lang, cr.code_cancel_reason)) cancel_reason_desc,
                                   lph.notes_cancel,
                                   l.id_lens,
                                   lph.id_lens_presc,
                                   lph.flg_status,
                                   pk_date_utils.date_send_tsz(i_lang, lph.dt_lens_presc_tstz, i_prof) dt_val,
                                   lph.id_episode,
                                   l.flg_type,
                                   pk_lens.get_presc_info_report(i_lang,
                                                                 i_prof,
                                                                 lph.id_lens_presc,
                                                                 lph.id_lens_presc_hist,
                                                                 l.flg_type,
                                                                 pk_alert_constant.g_lens_presc_info_r,
                                                                 l_ign_perm) right_desc_report,
                                   pk_lens.get_presc_info_report(i_lang,
                                                                 i_prof,
                                                                 lph.id_lens_presc,
                                                                 lph.id_lens_presc_hist,
                                                                 l.flg_type,
                                                                 pk_alert_constant.g_lens_presc_info_l,
                                                                 l_ign_perm) left_desc_report,
                                   pk_lens.get_presc_info_report(i_lang,
                                                                 i_prof,
                                                                 lph.id_lens_presc,
                                                                 lph.id_lens_presc_hist,
                                                                 l.flg_type,
                                                                 pk_alert_constant.g_lens_presc_info_o,
                                                                 l_ign_perm) other_desc_report
                              FROM lens_presc_hist lph
                              JOIN lens l
                                ON l.id_lens = lph.id_lens
                              LEFT JOIN cancel_reason cr
                                ON cr.id_cancel_reason = lph.id_cancel_reason
                             WHERE lph.id_lens_presc = i_id_lens_presc
                               AND i_flg_show_hist = pk_alert_constant.g_yes))
             ORDER BY dt_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PRESC_DET',
                                              o_error);
            pk_types.open_my_cursor(o_presc_det);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_presc_det;

    FUNCTION get_physical_exam_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_elements table_varchar := table_varchar('RIGHT_EYE_FAR_SPHERE',
                                                  'RIGHT_EYE_FAR_CYLINDER',
                                                  'RIGHT_EYE_FAR_AXIS',
                                                  'RIGHT_EYE_FAR_PRIM',
                                                  'RIGHT_EYE_PERM_SPHERE',
                                                  'RIGHT_EYE_PERM_CYLINDER',
                                                  'RIGHT_EYE_PERM_AXIS',
                                                  'RIGHT_EYE_PERM_PRIM',
                                                  'RIGHT_EYE_CLOSE_SPHERE',
                                                  'RIGHT_EYE_CLOSE_CYLINDER',
                                                  'RIGHT_EYE_CLOSE_AXIS',
                                                  'RIGHT_EYE_CLOSE_PRIM',
                                                  'LEFT_EYE_FAR_SPHERE',
                                                  'LEFT_EYE_FAR_CYLINDER',
                                                  'LEFT_EYE_FAR_AXIS',
                                                  'LEFT_EYE_FAR_PRIM',
                                                  'LEFT_EYE_PERM_SPHERE',
                                                  'LEFT_EYE_PERM_CYLINDER',
                                                  'LEFT_EYE_PERM_AXIS',
                                                  'LEFT_EYE_PERM_PRIM',
                                                  'LEFT_EYE_CLOSE_SPHERE',
                                                  'LEFT_EYE_CLOSE_CYLINDER',
                                                  'LEFT_EYE_CLOSE_AXIS',
                                                  'LEFT_EYE_CLOSE_PRIM',
                                                  'INTERPUPIL_FAR',
                                                  'INTERPUPIL_CLOSE');
    
        l_values             table_varchar;
        l_desc_values        table_varchar;
        l_last_epis_doc      epis_documentation.id_epis_documentation%TYPE;
        l_last_date_epis_doc epis_documentation.dt_creation_tstz%TYPE;
        c_cursor             pk_types.cursor_type;
        r_doc                pk_touch_option.t_coll_last_elem_val;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_DATA';
        IF NOT pk_touch_option.get_last_doc_area_elem_values(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_episode            => i_id_episode,
                                                             i_doc_area           => 6094, --(28=Physical exam, 6094=Oftalmologic exam),
                                                             i_doc_template       => NULL,
                                                             i_table_element_keys => l_elements,
                                                             i_key_type           => 'N',
                                                             o_last_epis_doc      => l_last_epis_doc,
                                                             o_last_date_epis_doc => l_last_date_epis_doc,
                                                             o_element_values     => c_cursor,
                                                             o_error              => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        BEGIN
            g_error := 'FETCH c_cursor BULK COLLECT INTO r_doc';
            FETCH c_cursor BULK COLLECT
                INTO r_doc;
            CLOSE c_cursor;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        l_values := table_varchar();
        l_values.extend(l_elements.count);
        l_desc_values := table_varchar();
        l_desc_values.extend(l_elements.count);
    
        IF r_doc IS NOT NULL
        THEN
            FOR i IN 1 .. r_doc.count
            LOOP
                FOR j IN 1 .. l_elements.count
                LOOP
                    IF r_doc(i).internal_name = l_elements(j)
                    THEN
                        l_values(j) := r_doc(i).value;
                        l_desc_values(j) := r_doc(i).formatted_value;
                    END IF;
                END LOOP;
            END LOOP;
        END IF;
    
        g_error := 'OPEN O_DATA';
        OPEN o_data FOR
            SELECT a.adv_inp_internal,
                   a.adv_inp_field_internal,
                   a.val,
                   a.desc_val,
                   nvl(pk_translation.get_translation(i_lang, um.code_unit_measure_abrv),
                       pk_translation.get_translation(i_lang, um.code_unit_measure)) desc_unit
              FROM (SELECT 'LENS_PRESC_GLASSES_RIGHT_EYE' adv_inp_internal,
                           'FAR_SPHERE' adv_inp_field_internal,
                           l_values(1) val,
                           l_desc_values(1) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_RIGHT_EYE' adv_inp_internal,
                           'FAR_CYLINDER' adv_inp_field_internal,
                           l_values(2) val,
                           l_desc_values(2) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_RIGHT_EYE' adv_inp_internal,
                           'FAR_AXIS' adv_inp_field_internal,
                           l_values(3) val,
                           l_values(3) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_RIGHT_EYE' adv_inp_internal,
                           'PERM_SPHERE' adv_inp_field_internal,
                           l_values(4) val,
                           l_desc_values(4) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_RIGHT_EYE' adv_inp_internal,
                           'PERM_CYLINDER' adv_inp_field_internal,
                           l_values(5) val,
                           l_desc_values(5) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_RIGHT_EYE' adv_inp_internal,
                           'PERM_AXIS' adv_inp_field_internal,
                           l_values(6) val,
                           l_values(6) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_RIGHT_EYE' adv_inp_internal,
                           'CLOSE_SPHERE' adv_inp_field_internal,
                           l_values(7) val,
                           l_desc_values(7) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_RIGHT_EYE' adv_inp_internal,
                           'CLOSE_CYLINDER' adv_inp_field_internal,
                           l_values(8) val,
                           l_desc_values(8) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_RIGHT_EYE' adv_inp_internal,
                           'CLOSE_AXIS' adv_inp_field_internal,
                           l_values(9) val,
                           l_values(9) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_LEFT_EYE' adv_inp_internal,
                           'FAR_SPHERE' adv_inp_field_internal,
                           l_values(10) val,
                           l_desc_values(10) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_LEFT_EYE' adv_inp_internal,
                           'FAR_CYLINDER' adv_inp_field_internal,
                           l_values(11) val,
                           l_desc_values(11) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_LEFT_EYE' adv_inp_internal,
                           'FAR_AXIS' adv_inp_field_internal,
                           l_values(12) val,
                           l_values(12) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_LEFT_EYE' adv_inp_internal,
                           'PERM_SPHERE' adv_inp_field_internal,
                           l_values(13) val,
                           l_desc_values(13) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_LEFT_EYE' adv_inp_internal,
                           'PERM_CYLINDER' adv_inp_field_internal,
                           l_values(14) val,
                           l_desc_values(14) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_LEFT_EYE' adv_inp_internal,
                           'PERM_AXIS' adv_inp_field_internal,
                           l_values(15) val,
                           l_values(15) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_LEFT_EYE' adv_inp_internal,
                           'CLOSE_SPHERE' adv_inp_field_internal,
                           l_values(16) val,
                           l_desc_values(16) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_LEFT_EYE' adv_inp_internal,
                           'CLOSE_CYLINDER' adv_inp_field_internal,
                           l_values(17) val,
                           l_desc_values(17) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_LEFT_EYE' adv_inp_internal,
                           'CLOSE_AXIS' adv_inp_field_internal,
                           l_values(18) val,
                           l_values(18) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_INTERPUPIL' adv_inp_internal,
                           'FAR' adv_inp_field_internal,
                           l_values(19) val,
                           l_desc_values(19) desc_val
                      FROM dual
                    UNION ALL
                    SELECT 'LENS_PRESC_GLASSES_INTERPUPIL' adv_inp_internal,
                           'CLOSE' adv_inp_field_internal,
                           l_values(20) val,
                           l_desc_values(20) desc_val
                      FROM dual) a
              JOIN advanced_input ai
                ON ai.intern_name = a.adv_inp_internal
              JOIN advanced_input_field aif
                ON aif.intern_name = a.adv_inp_field_internal
              JOIN advanced_input_field_det aifd
                ON aifd.field_name = a.adv_inp_field_internal
              JOIN advanced_input_soft_inst aisi
                ON aisi.id_advanced_input = ai.id_advanced_input
               AND aisi.id_advanced_input_field = aif.id_advanced_input_field
               AND aisi.id_institution IN (0, i_prof.institution)
               AND aisi.id_software IN (0, i_prof.software)
               AND aisi.flg_active = pk_alert_constant.g_yes
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = aifd.id_unit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PHYSICAL_EXAM_DATA',
                                              o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_physical_exam_data;

    FUNCTION get_ehr_presc_lens
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_CURSOR';
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   get_ehr_presc_lens_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND (SELECT COUNT(1)
                      FROM lens_presc lp
                     WHERE lp.id_episode = e.id_episode
                       AND lp.flg_status = pk_alert_constant.g_lens_presc_flg_status_p) > 0
             ORDER BY e.dt_begin_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EHR_PRESC_LENS',
                                              o_error);
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ehr_presc_lens;

    FUNCTION get_ehr_presc_lens_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_varchar IS
    
        l_presc table_varchar;
    
        l_title    VARCHAR2(100);
        l_value    VARCHAR2(2000);
        l_ign_perm VARCHAR2(1) := pk_alert_constant.g_no;
    
        l_msg_other_glasses_label sys_message.desc_message%TYPE;
        l_msg_other_lens_label    sys_message.desc_message%TYPE;
        l_msg_title_glasses       sys_message.desc_message%TYPE;
        l_msg_title_lens          sys_message.desc_message%TYPE;
        l_msg_right_label         sys_message.desc_message%TYPE;
        l_msg_left_label          sys_message.desc_message%TYPE;
        l_msg_type_label          sys_message.desc_message%TYPE;
        l_msg_print_label         sys_message.desc_message%TYPE;
        l_msg_notes_label         sys_message.desc_message%TYPE;
    
        CURSOR c_cursor IS
            SELECT decode(flg_type,
                          pk_alert_constant.g_lens_flg_type_g,
                          l_msg_title_glasses,
                          pk_alert_constant.g_lens_flg_type_l,
                          l_msg_title_lens,
                          NULL) desc_title,
                   pk_date_utils.date_char_tsz(i_lang, dt_lens_presc_tstz, i_prof.institution, i_prof.software) desc_date,
                   
                   pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof) desc_prof,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, id_prof, dt_lens_presc_tstz, i_id_episode) desc_speciality,
                   right_desc,
                   left_desc,
                   other_label,
                   other_desc,
                   lens_desc,
                   pk_date_utils.date_char_tsz(i_lang, dt_print_tstz, i_prof.institution, i_prof.software) desc_print,
                   notes
              FROM (SELECT lp.dt_print_tstz,
                           lp.dt_lens_presc_tstz,
                           decode(lp.flg_status,
                                  pk_alert_constant.g_lens_presc_flg_status_p,
                                  lp.id_prof_print,
                                  pk_alert_constant.g_lens_presc_flg_status_i,
                                  lp.id_prof_presc,
                                  pk_alert_constant.g_lens_presc_flg_status_c,
                                  lp.id_prof_cancel) id_prof,
                           get_presc_info(i_lang,
                                          i_prof,
                                          lp.id_lens_presc,
                                          -1,
                                          l.flg_type,
                                          pk_alert_constant.g_lens_presc_info_r,
                                          l_ign_perm) right_desc,
                           get_presc_info(i_lang,
                                          i_prof,
                                          lp.id_lens_presc,
                                          -1,
                                          l.flg_type,
                                          pk_alert_constant.g_lens_presc_info_l,
                                          l_ign_perm) left_desc,
                           decode(l.flg_type,
                                  pk_alert_constant.g_lens_flg_type_g,
                                  l_msg_other_glasses_label,
                                  pk_alert_constant.g_lens_flg_type_l,
                                  l_msg_other_lens_label,
                                  NULL) other_label,
                           get_presc_info(i_lang,
                                          i_prof,
                                          lp.id_lens_presc,
                                          -1,
                                          l.flg_type,
                                          pk_alert_constant.g_lens_presc_info_o,
                                          l_ign_perm) other_desc,
                           pk_translation.get_translation(i_lang, l.code_lens) lens_desc,
                           l.flg_type,
                           lp.notes
                      FROM lens_presc lp
                      JOIN lens l
                        ON l.id_lens = lp.id_lens
                      LEFT JOIN cancel_reason cr
                        ON cr.id_cancel_reason = lp.id_cancel_reason
                     WHERE lp.id_episode = i_id_episode
                       AND lp.flg_status = pk_alert_constant.g_lens_presc_flg_status_p)
             ORDER BY dt_lens_presc_tstz DESC;
    
        TYPE t_cursor_type IS TABLE OF c_cursor%ROWTYPE;
    
        l_record  t_cursor_type;
        l_counter NUMBER;
    
        internal_exception EXCEPTION;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error    := 'CHECK IGNORE PERM';
        l_ign_perm := get_ignore_perm(i_lang, i_prof);
    
        g_error                   := 'GET MESSAGES';
        l_msg_title_glasses       := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T040');
        l_msg_title_lens          := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T027');
        l_msg_other_glasses_label := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T020');
        l_msg_other_lens_label    := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T019');
    
        l_msg_right_label := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T005');
        l_msg_left_label  := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T006');
        l_msg_type_label  := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T003');
        l_msg_print_label := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T014');
        l_msg_notes_label := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T007');
    
        g_error := 'PK_EHR_COMMON.GET_VISIT_TYPE_BY_EPIS';
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
    
        l_presc := table_varchar();
        l_presc.extend(3);
        l_presc(1) := '';
        l_presc(2) := l_title;
        l_presc(3) := l_value;
    
        g_error := 'OPEN CURSOR C_CURSOR';
        OPEN c_cursor;
        LOOP
            FETCH c_cursor BULK COLLECT
                INTO l_record LIMIT 100;
            FOR i IN 1 .. l_record.count
            LOOP
                l_counter := l_presc.count;
                l_presc.extend(18);
                l_presc(l_counter + 1) := 'T';
                l_presc(l_counter + 2) := l_record(i).desc_title;
                l_presc(l_counter + 3) := NULL;
            
                l_presc(l_counter + 4) := 'TB';
                l_presc(l_counter + 5) := l_msg_right_label;
                l_presc(l_counter + 6) := l_msg_left_label;
            
                l_presc(l_counter + 7) := 'TC';
                l_presc(l_counter + 8) := l_record(i).right_desc;
                l_presc(l_counter + 9) := l_record(i).left_desc;
            
                l_presc(l_counter + 10) := '';
                l_presc(l_counter + 11) := l_record(i).other_label;
                l_presc(l_counter + 12) := l_record(i).other_desc;
            
                l_presc(l_counter + 13) := '';
                l_presc(l_counter + 14) := l_msg_type_label;
                l_presc(l_counter + 15) := l_record(i).lens_desc;
            
                l_presc(l_counter + 16) := '';
                l_presc(l_counter + 17) := l_msg_print_label;
                l_presc(l_counter + 18) := l_record(i).desc_print;
                IF l_record(i).notes IS NOT NULL
                THEN
                    l_counter := l_presc.count;
                    l_presc.extend(3);
                    l_presc(l_counter + 1) := '';
                    l_presc(l_counter + 2) := l_msg_notes_label;
                    l_presc(l_counter + 3) := l_record(i).notes;
                END IF;
                l_counter := l_presc.count;
                l_presc.extend(3);
            
                l_presc(l_counter + 1) := 'I';
                l_presc(l_counter + 2) := l_record(i).desc_date;
                l_presc(l_counter + 3) := l_record(i).desc_prof || ', ' || l_record(i).desc_speciality;
            END LOOP;
        
            EXIT WHEN c_cursor%NOTFOUND;
        END LOOP;
    
        RETURN l_presc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => 'GET_EHR_PRESC_LENS_BY_EPIS',
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END get_ehr_presc_lens_by_epis;

    FUNCTION get_presc_det_rep
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_lens_presc IN lens_presc.id_lens_presc%TYPE,
        o_presc_det_rep OUT pk_types.cursor_type,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'OPEN CURSOR O_PRESC_DET_REP';
        OPEN o_presc_det_rep FOR
            SELECT adv_inp_name,
                   adv_inp_fld_name,
                   decode(format,
                          NULL,
                          VALUE,
                          TRIM(REPLACE(to_char(to_number(VALUE, '9999999D9999999', 'NLS_NUMERIC_CHARACTERS = ''. '''),
                                               format),
                                       '.',
                                       pk_sysconfig.get_config('DECIMAL_SYMBOL', i_prof)))) val,
                   desc_unit
              FROM (SELECT ai.intern_name adv_inp_name,
                           aif.intern_name adv_inp_fld_name,
                           lpd.value,
                           decode(aifd.format_message,
                                  NULL,
                                  NULL,
                                  pk_message.get_message(i_lang, i_prof, aifd.format_message)) format,
                           decode(um.id_unit_measure,
                                  NULL,
                                  '',
                                  nvl(pk_translation.get_translation(i_lang, um.code_unit_measure_abrv),
                                      pk_translation.get_translation(i_lang, um.code_unit_measure))) desc_unit
                    
                      FROM lens_presc_det lpd
                      JOIN advanced_input ai
                        ON ai.id_advanced_input = lpd.id_advanced_input
                      JOIN advanced_input_field_det aifd
                        ON aifd.id_advanced_input_field_det = lpd.id_adv_inp_field_det
                      JOIN advanced_input_field aif
                        ON aif.id_advanced_input_field = aifd.id_advanced_input_field
                      LEFT JOIN unit_measure um
                        ON um.id_unit_measure = aifd.id_unit
                     WHERE lpd.id_lens_presc = i_id_lens_presc
                       AND lpd.id_lens_presc_hist = -1
                     ORDER BY ai.id_advanced_input, aif.id_advanced_input_field);
    
        g_error := 'OPEN O_DATA';
        OPEN o_data FOR
            SELECT pk_translation.get_translation(i_lang, l.code_lens) desc_lens,
                   lp.notes,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lp.id_prof_presc) desc_prof,
                   get_presc_info(i_lang,
                                  i_prof,
                                  lp.id_lens_presc,
                                  -1,
                                  pk_alert_constant.g_lens_flg_type_l,
                                  pk_alert_constant.g_lens_presc_info_o,
                                  pk_alert_constant.g_yes) brand
              FROM lens_presc lp
              JOIN lens l
                ON l.id_lens = lp.id_lens
             WHERE lp.id_lens_presc = i_id_lens_presc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PRESC_DET_REP',
                                              o_error);
            pk_types.open_my_cursor(o_presc_det_rep);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_presc_det_rep;

    FUNCTION get_presc_info_report
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_lens_presc      IN lens_presc.id_lens_presc%TYPE,
        i_id_lens_presc_hist IN lens_presc_hist.id_lens_presc_hist%TYPE,
        i_flg_type           IN lens.flg_type%TYPE,
        i_flg_adv_inp        IN VARCHAR2,
        i_ign_perm           IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR IS
    
        l_adv_inp VARCHAR2(64) := 'LENS_PRESC_';
    
        CURSOR c_presc_info IS
            SELECT aif.intern_name,
                   lpd.value,
                   aifd.format_message,
                   decode(um.id_unit_measure,
                          NULL,
                          '',
                          nvl(pk_translation.get_translation(i_lang, um.code_unit_measure_abrv),
                              pk_translation.get_translation(i_lang, um.code_unit_measure))) desc_unit
              FROM lens_presc_det lpd
              JOIN advanced_input ai
                ON ai.id_advanced_input = lpd.id_advanced_input
              JOIN advanced_input_field_det aifd
                ON aifd.id_advanced_input_field_det = lpd.id_adv_inp_field_det
              JOIN advanced_input_field aif
                ON aif.id_advanced_input_field = aifd.id_advanced_input_field
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = aifd.id_unit
             WHERE ai.intern_name = l_adv_inp
               AND lpd.id_lens_presc = i_id_lens_presc
               AND lpd.id_lens_presc_hist = i_id_lens_presc_hist;
    
        l_msg11 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg12 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg13 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg14 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg21 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg22 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg23 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg24 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg31 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg32 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg33 VARCHAR2(50 CHAR) := g_msg_invalid;
        l_msg34 VARCHAR2(50 CHAR) := g_msg_invalid;
    
        l_msg_far   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T021');
        l_msg_med   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T022');
        l_msg_close sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T023');
    
        l_msg_prism    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T044');
        l_msg_radius   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T024');
        l_msg_diameter sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T025');
        l_msg_power    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LENS_PRESC_T026');
    
        l_num_val NUMBER;
    
        l_val_formatted VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_ign_perm = pk_alert_constant.g_no
        THEN
            l_msg21 := g_msg_invalid;
        END IF;
    
        IF i_flg_type = pk_alert_constant.g_lens_flg_type_g
        THEN
            l_adv_inp := l_adv_inp || 'GLASSES_';
        ELSIF i_flg_type = pk_alert_constant.g_lens_flg_type_l
        THEN
            l_adv_inp := l_adv_inp || 'CONTACT_';
        END IF;
    
        IF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_r
        THEN
            l_adv_inp := l_adv_inp || 'RIGHT_EYE';
        ELSIF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_l
        THEN
            l_adv_inp := l_adv_inp || 'LEFT_EYE';
        ELSIF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_o
        THEN
            IF i_flg_type = pk_alert_constant.g_lens_flg_type_g
            THEN
                l_adv_inp := l_adv_inp || 'INTERPUPIL';
            ELSIF i_flg_type = pk_alert_constant.g_lens_flg_type_l
            THEN
                l_adv_inp := l_adv_inp || 'BRAND';
            END IF;
        END IF;
    
        g_error := 'OPEN CURSOR c_presc_info for ' || l_adv_inp;
        FOR rec IN c_presc_info
        LOOP
            IF rec.intern_name != 'BRAND'
            THEN
                g_error         := 'CONVERT VALUES';
                l_num_val       := to_number(rec.value, '9999999D9999999', 'NLS_NUMERIC_CHARACTERS = ''. ''');
                l_val_formatted := TRIM(REPLACE(to_char(l_num_val,
                                                        pk_message.get_message(i_lang, i_prof, rec.format_message)),
                                                '.',
                                                pk_sysconfig.get_config('DECIMAL_SYMBOL', i_prof)));
            END IF;
        
            IF rec.intern_name = 'FAR_SPHERE'
            THEN
                l_msg11 := l_val_formatted;
            ELSIF rec.intern_name = 'FAR_CYLINDER'
            THEN
                l_msg12 := l_val_formatted;
            ELSIF rec.intern_name = 'FAR_AXIS'
            THEN
                l_msg13 := ' ' || g_msg_sign_mult || ' ' || l_val_formatted || rec.desc_unit;
            ELSIF rec.intern_name = 'FAR_PRISM'
            THEN
                l_msg14 := ' ' || l_msg_prism || l_val_formatted;
            ELSIF rec.intern_name = 'PERM_SPHERE'
            THEN
                l_msg21 := l_val_formatted;
            ELSIF rec.intern_name = 'PERM_CYLINDER'
            THEN
                l_msg22 := l_val_formatted;
            ELSIF rec.intern_name = 'PERM_AXIS'
            THEN
                l_msg23 := ' ' || g_msg_sign_mult || ' ' || l_val_formatted || rec.desc_unit;
            ELSIF rec.intern_name = 'PERM_PRISM'
            THEN
                l_msg24 := ' ' || l_msg_prism || l_val_formatted;
            ELSIF rec.intern_name = 'CLOSE_SPHERE'
            THEN
                l_msg31 := l_val_formatted;
            ELSIF rec.intern_name = 'CLOSE_CYLINDER'
            THEN
                l_msg32 := l_val_formatted;
            ELSIF rec.intern_name = 'CLOSE_AXIS'
            THEN
                l_msg33 := ' ' || g_msg_sign_mult || ' ' || l_val_formatted || rec.desc_unit;
            ELSIF rec.intern_name = 'CLOSE_PRISM'
            THEN
                l_msg34 := ' ' || l_msg_prism || l_val_formatted;
            ELSIF rec.intern_name = 'FAR'
            THEN
                l_msg11 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'CLOSE'
            THEN
                l_msg12 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'BVD'
            THEN
                l_msg13 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'CURVATURE_RADIUS'
            THEN
                l_msg11 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'DIAMETER'
            THEN
                l_msg21 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'POWER'
            THEN
                l_msg31 := l_val_formatted || ' ' || rec.desc_unit;
            ELSIF rec.intern_name = 'BRAND'
            THEN
                l_msg11 := rec.value;
            END IF;
        END LOOP;
    
        IF i_flg_type = pk_alert_constant.g_lens_flg_type_g
        THEN
            IF i_flg_adv_inp IN (pk_alert_constant.g_lens_presc_info_r, pk_alert_constant.g_lens_presc_info_l)
            THEN
                IF i_ign_perm = pk_alert_constant.g_yes
                   AND l_msg21 = g_msg_invalid
                   AND l_msg22 = g_msg_invalid
                   AND l_msg23 = g_msg_invalid
                THEN
                    IF l_msg11 = g_msg_invalid
                       AND l_msg12 = g_msg_invalid
                       AND l_msg13 = g_msg_invalid
                       AND l_msg31 = g_msg_invalid
                       AND l_msg32 = g_msg_invalid
                       AND l_msg33 = g_msg_invalid
                    THEN
                        RETURN NULL; --l_msg11 || chr(13) || l_msg31;
                    ELSE
                        IF l_msg13 = g_msg_invalid
                        THEN
                            l_msg13 := g_msg_sign_mult || ' ' || g_msg_invalid;
                        END IF;
                    
                        IF l_msg33 = g_msg_invalid
                        THEN
                            l_msg33 := g_msg_sign_mult || ' ' || g_msg_invalid;
                        END IF;
                    
                        IF l_msg11 = g_msg_invalid
                           AND l_msg12 = g_msg_invalid
                           AND l_msg13 = g_msg_sign_mult || ' ' || g_msg_invalid
                           AND (l_msg31 <> g_msg_invalid OR l_msg32 <> g_msg_invalid OR
                           l_msg33 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                        THEN
                            RETURN l_msg_close || ' ' || TRIM(l_msg31) || ' ' || TRIM(l_msg32) || ' ' || TRIM(l_msg33);
                        ELSIF l_msg31 = g_msg_invalid
                              AND l_msg32 = g_msg_invalid
                              AND l_msg33 = g_msg_sign_mult || ' ' || g_msg_invalid
                              AND (l_msg11 <> g_msg_invalid OR l_msg12 <> g_msg_invalid OR
                              l_msg13 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                        THEN
                            RETURN l_msg_far || ' ' || TRIM(l_msg11) || ' ' || TRIM(l_msg12) || ' ' || TRIM(l_msg13);
                        ELSE
                            RETURN l_msg_far || ' ' || TRIM(l_msg11) || ' ' || TRIM(l_msg12) || ' ' || TRIM(l_msg13) || chr(13) || --
                            l_msg_close || ' ' || TRIM(l_msg31) || ' ' || TRIM(l_msg32) || ' ' || TRIM(l_msg33);
                        END IF;
                    END IF;
                ELSE
                    IF l_msg11 = g_msg_invalid
                       AND l_msg12 = g_msg_invalid
                       AND l_msg13 = g_msg_invalid
                       AND l_msg21 = g_msg_invalid
                       AND l_msg22 = g_msg_invalid
                       AND l_msg23 = g_msg_invalid
                       AND l_msg31 = g_msg_invalid
                       AND l_msg32 = g_msg_invalid
                       AND l_msg33 = g_msg_invalid
                    THEN
                        RETURN NULL; --l_msg11 || chr(13) || l_msg21 || chr(13) || l_msg31;
                    ELSE
                        IF l_msg13 = g_msg_invalid
                        THEN
                            l_msg13 := g_msg_sign_mult || ' ' || g_msg_invalid;
                        END IF;
                    
                        IF l_msg23 = g_msg_invalid
                        THEN
                            l_msg23 := g_msg_sign_mult || ' ' || g_msg_invalid;
                        END IF;
                    
                        IF l_msg33 = g_msg_invalid
                        THEN
                            l_msg33 := g_msg_sign_mult || ' ' || g_msg_invalid;
                        END IF;
                    
                        IF l_msg11 = g_msg_invalid
                           AND l_msg12 = g_msg_invalid
                           AND l_msg13 = g_msg_sign_mult || ' ' || g_msg_invalid
                           AND l_msg21 = g_msg_invalid
                           AND l_msg22 = g_msg_invalid
                           AND l_msg23 = g_msg_sign_mult || ' ' || g_msg_invalid
                           AND (l_msg31 <> g_msg_invalid OR l_msg32 <> g_msg_invalid OR
                           l_msg33 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                        THEN
                            RETURN l_msg_close || ' ' || TRIM(l_msg31) || ' ' || TRIM(l_msg32) || ' ' || TRIM(l_msg33);
                        
                        ELSIF l_msg11 = g_msg_invalid
                              AND l_msg12 = g_msg_invalid
                              AND l_msg13 = g_msg_sign_mult || ' ' || g_msg_invalid
                              AND l_msg31 = g_msg_invalid
                              AND l_msg32 = g_msg_invalid
                              AND l_msg33 = g_msg_sign_mult || ' ' || g_msg_invalid
                              AND (l_msg21 <> g_msg_invalid OR l_msg22 <> g_msg_invalid OR
                              l_msg23 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                        THEN
                            RETURN l_msg_med || ' ' || TRIM(l_msg21) || ' ' || TRIM(l_msg22) || ' ' || TRIM(l_msg23);
                        
                        ELSIF l_msg21 = g_msg_invalid
                              AND l_msg22 = g_msg_invalid
                              AND l_msg23 = g_msg_sign_mult || ' ' || g_msg_invalid
                              AND l_msg31 = g_msg_invalid
                              AND l_msg32 = g_msg_invalid
                              AND l_msg33 = g_msg_sign_mult || ' ' || g_msg_invalid
                              AND (l_msg11 <> g_msg_invalid OR l_msg12 <> g_msg_invalid OR
                              l_msg13 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                        THEN
                            RETURN l_msg_far || ' ' || TRIM(l_msg11) || ' ' || TRIM(l_msg12) || ' ' || TRIM(l_msg13);
                        
                        ELSIF l_msg11 = g_msg_invalid
                              AND l_msg12 = g_msg_invalid
                              AND l_msg13 = g_msg_sign_mult || ' ' || g_msg_invalid
                              AND (l_msg21 <> g_msg_invalid OR l_msg22 <> g_msg_invalid OR
                              l_msg23 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                              AND (l_msg31 <> g_msg_invalid OR l_msg32 <> g_msg_invalid OR
                              l_msg33 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                        THEN
                            RETURN l_msg_med || ' ' || TRIM(l_msg21) || ' ' || TRIM(l_msg22) || ' ' || TRIM(l_msg23) || chr(13) || --
                            l_msg_close || ' ' || TRIM(l_msg31) || ' ' || TRIM(l_msg32) || ' ' || TRIM(l_msg33);
                        
                        ELSIF l_msg21 = g_msg_invalid
                              AND l_msg22 = g_msg_invalid
                              AND l_msg23 = g_msg_sign_mult || ' ' || g_msg_invalid
                              AND (l_msg11 <> g_msg_invalid OR l_msg12 <> g_msg_invalid OR
                              l_msg13 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                              AND (l_msg31 <> g_msg_invalid OR l_msg32 <> g_msg_invalid OR
                              l_msg33 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                        THEN
                            RETURN l_msg_far || ' ' || TRIM(l_msg11) || ' ' || TRIM(l_msg12) || ' ' || TRIM(l_msg13) || chr(13) || --                           
                            l_msg_close || ' ' || TRIM(l_msg31) || ' ' || TRIM(l_msg32) || ' ' || TRIM(l_msg33);
                        ELSIF l_msg31 = g_msg_invalid
                              AND l_msg32 = g_msg_invalid
                              AND l_msg33 = g_msg_sign_mult || ' ' || g_msg_invalid
                              AND (l_msg11 <> g_msg_invalid OR l_msg12 <> g_msg_invalid OR
                              l_msg13 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                              AND (l_msg21 <> g_msg_invalid OR l_msg22 <> g_msg_invalid OR
                              l_msg23 <> g_msg_sign_mult || ' ' || g_msg_invalid)
                        THEN
                            RETURN l_msg_far || ' ' || TRIM(l_msg11) || ' ' || TRIM(l_msg12) || ' ' || TRIM(l_msg13) || chr(13) || --
                            l_msg_med || ' ' || TRIM(l_msg21) || ' ' || TRIM(l_msg22) || ' ' || TRIM(l_msg23);
                        ELSE
                            RETURN l_msg_far || ' ' || TRIM(l_msg11) || ' ' || TRIM(l_msg12) || ' ' || TRIM(l_msg13) || chr(13) || --
                            l_msg_med || ' ' || TRIM(l_msg21) || ' ' || TRIM(l_msg22) || ' ' || TRIM(l_msg23) || chr(13) || --
                            l_msg_close || ' ' || TRIM(l_msg31) || ' ' || TRIM(l_msg32) || ' ' || TRIM(l_msg33);
                        END IF;
                    END IF;
                END IF;
            ELSIF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_o
            THEN
                IF l_msg11 = g_msg_invalid
                   AND l_msg12 = g_msg_invalid
                THEN
                    RETURN NULL;
                ELSE
                    RETURN l_msg_far || ' ' || TRIM(l_msg11) || '; ' || l_msg_close || ' ' || TRIM(l_msg12);
                END IF;
            END IF;
        ELSIF i_flg_type = pk_alert_constant.g_lens_flg_type_l
        THEN
            IF i_flg_adv_inp IN (pk_alert_constant.g_lens_presc_info_r, pk_alert_constant.g_lens_presc_info_l)
            THEN
                IF l_msg11 = g_msg_invalid
                   AND l_msg21 = g_msg_invalid
                   AND l_msg31 = g_msg_invalid
                THEN
                    RETURN NULL; --l_msg11 || chr(13) || l_msg21 || chr(13) || l_msg31;
                
                ELSIF l_msg11 = g_msg_invalid
                      AND l_msg21 = g_msg_invalid
                      AND l_msg31 <> g_msg_invalid
                THEN
                    RETURN l_msg_power || ' ' || TRIM(l_msg31);
                
                ELSIF l_msg11 = g_msg_invalid
                      AND l_msg21 <> g_msg_invalid
                      AND l_msg31 = g_msg_invalid
                THEN
                    RETURN l_msg_diameter || ' ' || TRIM(l_msg21);
                
                ELSIF l_msg11 <> g_msg_invalid
                      AND l_msg21 = g_msg_invalid
                      AND l_msg31 = g_msg_invalid
                THEN
                    RETURN l_msg_radius || ' ' || TRIM(l_msg11);
                
                ELSIF l_msg11 = g_msg_invalid
                      AND l_msg21 <> g_msg_invalid
                      AND l_msg31 <> g_msg_invalid
                THEN
                    RETURN l_msg_diameter || ' ' || TRIM(l_msg21) || chr(13) || --
                    l_msg_power || ' ' || TRIM(l_msg31);
                
                ELSIF l_msg11 <> g_msg_invalid
                      AND l_msg21 = g_msg_invalid
                      AND l_msg31 <> g_msg_invalid
                THEN
                    RETURN l_msg_radius || ' ' || TRIM(l_msg11) || chr(13) || --                   
                    l_msg_power || ' ' || TRIM(l_msg31);
                
                ELSIF l_msg11 <> g_msg_invalid
                      AND l_msg21 <> g_msg_invalid
                      AND l_msg31 = g_msg_invalid
                THEN
                    RETURN l_msg_radius || ' ' || TRIM(l_msg11) || chr(13) || --
                    l_msg_diameter || ' ' || TRIM(l_msg21);
                ELSE
                    RETURN l_msg_radius || ' ' || TRIM(l_msg11) || chr(13) || --
                    l_msg_diameter || ' ' || TRIM(l_msg21) || chr(13) || --
                    l_msg_power || ' ' || TRIM(l_msg31);
                END IF;
            
            ELSIF i_flg_adv_inp = pk_alert_constant.g_lens_presc_info_o
            THEN
                IF l_msg11 = g_msg_invalid
                THEN
                    RETURN NULL;
                ELSE
                    RETURN TRIM(l_msg11);
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => 'GET_PRESC_INFO_REPORT',
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END get_presc_info_report;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_lens;
/
