/*-- Last Change Revision: $Rev: 2027655 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:55 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_scales_core IS

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations
    /**
    * Sends the registry in epis_scales_score  to the history tables
    *
    * @param   i_lang                    Professional preferred language
    * @param   i_prof                    Professional identification and its context (institution and software)
    * @param   i_id_epis_documentation   Epis documentation identifier
    * @param   i_dt_hist                 Date of history insertion
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   08-Jul-2011
    */
    FUNCTION set_epis_scales_score_hist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_dt_hist               IN epis_pn_signoff_hist.dt_epis_pn_signoff_hist%TYPE DEFAULT current_timestamp,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out table_varchar;
    
        CURSOR c_epis_scales_score IS
            SELECT ess.id_epis_scales_score,
                   ess.id_episode,
                   ess.id_patient,
                   ess.id_epis_documentation,
                   ess.flg_status,
                   ess.id_prof_create,
                   ess.dt_create,
                   ess.id_cancel_reason,
                   ess.notes_cancel,
                   ess.dt_cancel,
                   ess.id_prof_cancel,
                   ess.id_scales,
                   ess.id_scales_group,
                   ess.id_documentation,
                   ess.score_value
              FROM epis_scales_score ess
             WHERE ess.id_epis_documentation = i_id_epis_documentation;
    
        l_rec_epis_scores c_epis_scales_score%ROWTYPE;
    BEGIN
        g_error := 'Get sign off id for update';
        OPEN c_epis_scales_score;
        LOOP
            FETCH c_epis_scales_score
                INTO l_rec_epis_scores;
            EXIT WHEN c_epis_scales_score%NOTFOUND;
        
            g_error := 'Update history table';
            pk_alertlog.log_debug(g_error);
            ts_epis_scales_score_hist.ins(id_epis_scales_score_in  => l_rec_epis_scores.id_epis_scales_score,
                                          dt_epis_scales_score_in  => i_dt_hist,
                                          id_patient_in            => l_rec_epis_scores.id_patient,
                                          id_episode_in            => l_rec_epis_scores.id_episode,
                                          id_epis_documentation_in => l_rec_epis_scores.id_epis_documentation,
                                          flg_status_in            => l_rec_epis_scores.flg_status,
                                          id_prof_create_in        => l_rec_epis_scores.id_prof_create,
                                          dt_create_in             => l_rec_epis_scores.dt_create,
                                          id_cancel_reason_in      => l_rec_epis_scores.id_cancel_reason,
                                          notes_cancel_in          => l_rec_epis_scores.notes_cancel,
                                          dt_cancel_in             => l_rec_epis_scores.dt_cancel,
                                          id_prof_cancel_in        => l_rec_epis_scores.id_prof_cancel,
                                          id_scales_in             => l_rec_epis_scores.id_scales,
                                          id_scales_group_in       => l_rec_epis_scores.id_scales_group,
                                          id_documentation_in      => l_rec_epis_scores.id_documentation,
                                          score_value_in           => l_rec_epis_scores.score_value,
                                          rows_out                 => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'EPIS_SCALES_SCORE_HIST', l_rows_out, o_error);
        END LOOP;
        CLOSE c_epis_scales_score;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_EPIS_SCALES_SCORE_HIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_epis_scales_score_hist;

    /**
    * Saves the calculated partial and/or total scores.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 Episode ID
    * @param   i_id_epis_doc_old            Id_epis_documentation being updated    
    * @param   i_id_epis_doc_new            Id_epis_documentation created
    * @param   i_flags                      List of flags that identify the scope of the score: Scale, Documentation, Group
    * @param   i_ids                        List of ids: Scale, Documentation, Group
    * @param   i_scores                     List of calculated scores
    * @param   i_id_scales_formulas         Score calculation formulas Ids
    * @param   o_id_epis_scales_score       Epis scales score created IDs
    * @param   o_error                      Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit/Correct {*} 'A' Agree(deprecated) {*} 'U' Update/Copy&Edit {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
    * @value i_save_mode_list              {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   08-Jul-2011
    */
    FUNCTION set_epis_scales_score
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_doc_old      IN epis_documentation.id_epis_documentation%TYPE,
        i_id_epis_doc_new      IN epis_documentation.id_epis_documentation%TYPE,
        i_flags                IN table_varchar,
        i_ids                  IN table_number,
        i_scores               IN table_varchar,
        i_id_scales_formulas   IN table_number,
        i_dt_clinical          IN VARCHAR2 DEFAULT NULL,
        o_id_epis_scales_score OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count                PLS_INTEGER;
        l_rows_out             table_varchar;
        l_id_scales            scales.id_scales%TYPE;
        l_id_scales_group      scales_group.id_scales_group%TYPE;
        l_id_documentation     scales_formula.id_documentation%TYPE;
        l_id_patient           patient.id_patient%TYPE;
        l_id_epis_scales_score epis_scales_score.id_epis_scales_score%TYPE;
        l_score                epis_scales_score.score_value%TYPE;
        l_new_record           PLS_INTEGER;
        l_dt_clinical          epis_scales_score.dt_create%TYPE;
        l_id_vital_sign        scales.id_vital_sign%TYPE;
        l_vs_mode              VARCHAR2(1 CHAR);
        l_ret                  pk_touch_option_ti.t_coll_doc_element_vs;
        l_new_vs_read_list     table_number;
        l_dt_registry          VARCHAR2(20 CHAR);
        l_prof_cat_type        category.flg_type%TYPE;
        l_id_vital_sign_read   vital_sign_read.id_vital_sign_read%TYPE;
        l_register_vs          sys_config.value%TYPE;
    BEGIN
        g_sysdate := current_timestamp;
    
        o_id_epis_scales_score := table_number();
    
        l_register_vs := pk_sysconfig.get_config(i_code_cf => 'ASSESSMENT_SCALES_REGISTER_TOTAL_VS', i_prof => i_prof);
    
        g_error := 'CALL pk_episode.get_id_patient';
        pk_alertlog.log_debug(g_error);
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
    
        l_dt_clinical := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => i_dt_clinical,
                                                       i_timezone  => NULL);
    
        l_dt_clinical := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                          i_timestamp => l_dt_clinical,
                                                          i_format    => 'MI');
    
        g_error := 'CHECK IF EXISTS HISTORY. i_id_epis_doc_old: ' || i_id_epis_doc_old;
        pk_alertlog.log_debug(g_error);
        --check if there is some registries regarding the given id_epis_documentation
        SELECT COUNT(1)
          INTO l_count
          FROM epis_scales_score ess
         WHERE ess.id_epis_documentation = i_id_epis_doc_old;
    
        IF (l_count > 0)
        THEN
            --send the actual to the history
            g_error := 'CAL set_epis_scales_score_hist';
            pk_alertlog.log_debug(g_error);
            IF NOT set_epis_scales_score_hist(i_lang                  => i_lang,
                                              i_prof                  => i_prof,
                                              i_id_epis_documentation => i_id_epis_doc_old,
                                              o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            SELECT ess.id_vital_sign_read
              INTO l_id_vital_sign_read
              FROM epis_scales_score ess
             WHERE ess.id_epis_documentation = i_id_epis_doc_old
               AND ess.flg_status = pk_scales_constant.g_scales_score_status_a
               AND rownum = 1;
        
            --outdate the actual registries
            --update the scores that does not exists any more because the user de-seleted some elements of the template
            g_error := 'Update history table';
            pk_alertlog.log_debug(g_error);
            ts_epis_scales_score.upd(flg_status_in => pk_scales_constant.g_scales_score_status_o,
                                     where_in      => ' id_epis_documentation=' || i_id_epis_doc_old,
                                     rows_out      => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_SCALES_SCORE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        END IF;
    
        IF i_flags IS NOT NULL
        THEN
            FOR i IN 1 .. i_flags.count
            LOOP
                l_id_epis_scales_score := NULL;
                l_id_scales            := NULL;
                l_id_scales_group      := NULL;
                l_id_documentation     := NULL;
                l_new_record           := 0;
            
                IF (i_flags(i) = pk_scales_constant.g_score_scope_scale_s)
                THEN
                    l_id_scales := i_ids(i);
                
                    BEGIN
                        g_error := 'GET ID_EPIS_SCALES_SCORE SCOPE SCALES. id_scales: ' || i_ids(i) ||
                                   ' id_epis_documentation: ' || i_id_epis_doc_old;
                        pk_alertlog.log_debug(g_error);
                        SELECT ess.id_epis_scales_score
                          INTO l_id_epis_scales_score
                          FROM epis_scales_score ess
                         WHERE ess.id_scales = i_ids(i)
                           AND ess.id_epis_documentation = i_id_epis_doc_old
                           AND ess.flg_status = pk_scales_constant.g_scales_score_status_a
                           AND rownum = 1;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                
                ELSIF (i_flags(i) = pk_scales_constant.g_score_scope_comp_c)
                THEN
                    l_id_documentation := i_ids(i);
                
                    BEGIN
                        g_error := 'GET ID_EPIS_SCALES_SCORE SCOPE COMPONENT. id_scales: ' || i_ids(i) ||
                                   ' id_epis_documentation: ' || i_id_epis_doc_old;
                        pk_alertlog.log_debug(g_error);
                        SELECT ess.id_epis_scales_score
                          INTO l_id_epis_scales_score
                          FROM epis_scales_score ess
                         WHERE ess.id_documentation = i_ids(i)
                           AND ess.id_epis_documentation = i_id_epis_doc_old
                           AND ess.flg_status = pk_scales_constant.g_scales_score_status_a
                           AND rownum = 1;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                
                ELSIF (i_flags(i) = pk_scales_constant.g_score_scope_group_g)
                THEN
                    l_id_scales_group := i_ids(i);
                
                    BEGIN
                        g_error := 'GET ID_EPIS_SCALES_SCORE GROUP COMPONENT. id_scales: ' || i_ids(i) ||
                                   ' id_epis_documentation: ' || i_id_epis_doc_old;
                        pk_alertlog.log_debug(g_error);
                        SELECT ess.id_epis_scales_score
                          INTO l_id_epis_scales_score
                          FROM epis_scales_score ess
                         WHERE ess.id_scales_group = i_ids(i)
                           AND ess.id_epis_documentation = i_id_epis_doc_old
                           AND ess.flg_status = pk_scales_constant.g_scales_score_status_a
                           AND rownum = 1;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                END IF;
            
                IF (l_id_epis_scales_score IS NULL)
                THEN
                    l_new_record           := 1;
                    l_id_epis_scales_score := ts_epis_scales_score.next_key;
                END IF;
            
                --get_formula
            
                o_id_epis_scales_score.extend();
                o_id_epis_scales_score(o_id_epis_scales_score.last) := l_id_epis_scales_score;
            
                g_error := ' Convert score value to number i_score: ' || i_scores(i);
                pk_alertlog.log_debug(g_error);
                l_score := to_number(i_scores(i), '99999999999999999999.9999');
            
                --set the actual values
                g_error := 'Set actual values. i_id_episode: ' || i_id_episode || ' i_id_patient: ' || l_id_patient ||
                           ' id_epis_documentation: ' || i_id_epis_doc_new || ' id_scales: ' || l_id_scales ||
                           ' id_scales_group: ' || l_id_scales_group || ' id_documentation: ' || l_id_documentation ||
                           ' id_scales_formula: ' || i_id_scales_formulas(i) || ' score_value: ' || to_char(l_score);
                pk_alertlog.log_debug(g_error);
                ts_epis_scales_score.upd_ins(id_epis_scales_score_in  => l_id_epis_scales_score,
                                             id_episode_in            => i_id_episode,
                                             id_patient_in            => l_id_patient,
                                             id_epis_documentation_in => i_id_epis_doc_new,
                                             flg_status_in            => pk_scales_constant.g_scales_score_status_a,
                                             id_prof_create_in        => i_prof.id,
                                             dt_create_in             => nvl(l_dt_clinical, g_sysdate),
                                             id_cancel_reason_in      => NULL,
                                             notes_cancel_in          => NULL,
                                             dt_cancel_in             => NULL,
                                             id_prof_cancel_in        => NULL,
                                             id_scales_in             => l_id_scales,
                                             id_scales_group_in       => l_id_scales_group,
                                             id_documentation_in      => l_id_documentation,
                                             score_value_in           => l_score,
                                             id_scales_formula_in     => i_id_scales_formulas(i),
                                             rows_out                 => l_rows_out);
            
                IF l_register_vs = pk_alert_constant.g_yes and l_id_scales is not null 
                THEN
                    SELECT id_vital_sign
                      INTO l_id_vital_sign
                      FROM scales s
                     WHERE s.id_scales = l_id_scales;
                
                    IF l_id_vital_sign IS NOT NULL
                       AND l_id_vital_sign_read IS NULL
                    THEN
                    
                        l_prof_cat_type := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
                        IF NOT pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                                 i_episode            => i_id_episode,
                                                                 i_prof               => i_prof,
                                                                 i_pat                => l_id_patient,
                                                                 i_vs_id              => table_number(l_id_vital_sign),
                                                                 i_vs_val             => table_number(l_score),
                                                                 i_id_monit           => NULL,
                                                                 i_unit_meas          => table_number(NULL),
                                                                 i_vs_scales_elements => table_number(NULL),
                                                                 i_notes              => NULL,
                                                                 i_prof_cat_type      => l_prof_cat_type,
                                                                 i_dt_vs_read         => table_varchar(i_dt_clinical),
                                                                 i_epis_triage        => NULL,
                                                                 i_unit_meas_convert  => table_number(NULL),
                                                                 i_tbtb_attribute     => table_table_number(),
                                                                 i_tbtb_free_text     => table_table_clob(),
                                                                 --     i_id_edit_reason     => table_number(),
                                                                 --   i_notes_edit         => table_varchar(),
                                                                 o_vital_sign_read => l_new_vs_read_list,
                                                                 o_dt_registry     => l_dt_registry,
                                                                 o_error           => o_error)
                        THEN
                            g_error := 'The function pk_vital_sign.set_epis_vital_sign returns error';
                            RAISE g_exception;
                        END IF;
                    
                        UPDATE epis_scales_score
                           SET id_vital_sign_read = l_new_vs_read_list(1)
                         WHERE id_epis_scales_score = l_id_epis_scales_score;
                    
                    ELSIF l_id_vital_sign_read IS NOT NULL
                          AND l_id_vital_sign IS NOT NULL
                    THEN
                        IF NOT pk_vital_sign.edit_vital_sign(i_lang                    => i_lang,
                                                             i_prof                    => i_prof,
                                                             i_id_vital_sign_read      => l_id_vital_sign_read,
                                                             i_value                   => l_score,
                                                             i_id_unit_measure         => NULL,
                                                             i_dt_vital_sign_read_tstz => i_dt_clinical,
                                                             i_dt_registry             => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                      g_sysdate,
                                                                                                                      i_prof),
                                                             i_id_unit_measure_sel     => NULL,
                                                             i_tb_attribute            => NULL,
                                                             i_tb_free_text            => NULL,
                                                             i_id_edit_reason          => NULL,
                                                             i_notes_edit              => NULL,
                                                             o_error                   => o_error)
                        
                        THEN
                            g_error := 'The function pk_vital_sign.edit_vital_sign returns error';
                            RAISE g_exception;
                        END IF;
                    
                        UPDATE epis_scales_score
                           SET id_vital_sign_read = l_id_vital_sign_read -- l_new_vs_read_list(1)
                         WHERE id_epis_scales_score = l_id_epis_scales_score;
                    END IF;
                END IF;
                IF l_new_record = 1
                THEN
                    g_error := 'PROCESS INSERT EPIS_SCALES_SCORE';
                    pk_alertlog.log_debug('PK_SCALES_CORE.SET_EPIS_SCALES_CORE:  ' || g_error);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_SCALES_SCORE',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                ELSE
                    g_error := 'PROCESS UPDATE EPIS_SCALES_SCORE';
                    pk_alertlog.log_debug('PK_SCALES_CORE.SET_EPIS_SCALES_CORE:  ' || g_error);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_SCALES_SCORE',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                END IF;
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_EPIS_SCALES_SCORE',
                                              o_error);
            RETURN FALSE;
    END set_epis_scales_score;

    /**
    * Sets documentation values associated with an area (doc_area) of a template (doc_template). 
    * Includes support for vital signs.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_prof_cat_type              Professional category
    * @param   i_epis                       Episode ID
    * @param   i_doc_area                   Documentation area ID
    * @param   i_doc_template               Touch-option template ID
    * @param   i_epis_documentation         Epis documentation ID
    * @param   i_flg_type                   Operation that was applied to save this entry
    * @param   i_id_documentation           Array with id documentation
    * @param   i_id_doc_element             Array with doc elements
    * @param   i_id_doc_element_crit        Array with doc elements crit
    * @param   i_value                      Array with values
    * @param   i_notes                      Free text documentation / Additional notes
    * @param   i_id_doc_element_qualif      Array with element quantifications/qualifications 
    * @param   i_epis_context               Context ID (Ex: id_interv_presc_det, id_exam...)
    * @param   i_summary_and_notes          Template's summary to be included in clinical notes
    * @param   i_episode_context            Context episode id  used in preoperative ORIS area by OUTP, INP, EDIS
    * @param   i_flg_table_origin           Table source when is a record edition. Default: D - EPIS_DOCUMENTATION
    * @param   i_vs_element_list            List of template's elements ID (id_doc_element) filled with vital signs
    * @param   i_vs_save_mode_list          List of flags to indicate the applicable mode to save each vital signs measurement
    * @param   i_vs_list                    List of vital signs ID (id_vital_sign)
    * @param   i_vs_value_list              List of vital signs values
    * @param   i_vs_uom_list                List of units of measurement (id_unit_measure)
    * @param   i_vs_scales_list             List of scales (id_vs_scales_element)
    * @param   i_vs_date_list               List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
    * @param   i_vs_read_list               List of saved vital sign measurement (id_vital_sign_read)
    * @param   i_flags                      List of flags that identify the scope of the score: Scale, Documentation, Group
    * @param   i_ids                        List of ids: Scale, Documentation, Group
    * @param   i_scores                     List of calculated scores
    * @param   i_id_scales_formulas         Score calculation formulas Ids
    * @param   dt_clinical                  Clinical date
    * @param   o_epis_documentation         The epis_documentation ID created
    * @param   o_id_epis_scales_score       The epis_scales_score ID created
    * @param   o_error                      Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit/Correct {*} 'A' Agree(deprecated) {*} 'U' Update/Copy&Edit {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
    * @value i_save_mode_list              {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   08-Jul-2011
    */
    FUNCTION set_epis_doc_scales
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
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        i_flags                 IN table_varchar,
        i_ids                   IN table_number,
        i_scores                IN table_varchar,
        i_id_scales_formulas    IN table_number,
        i_id_edit_reason        IN table_number DEFAULT NULL,
        i_notes_edit            IN table_clob DEFAULT NULL,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_grid_doc_area sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL pk_touch_option.set_epis_documentation';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.set_epis_documentation(i_lang                  => i_lang,
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
                                                      i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                      i_epis_context          => i_epis_context,
                                                      i_summary_and_notes     => i_summary_and_notes,
                                                      i_episode_context       => i_episode_context,
                                                      i_flg_table_origin      => i_flg_table_origin,
                                                      i_vs_element_list       => i_vs_element_list,
                                                      i_vs_save_mode_list     => i_vs_save_mode_list,
                                                      i_vs_list               => i_vs_list,
                                                      i_vs_value_list         => i_vs_value_list,
                                                      i_vs_uom_list           => i_vs_uom_list,
                                                      i_vs_scales_list        => i_vs_scales_list,
                                                      i_vs_date_list          => i_vs_date_list,
                                                      i_vs_read_list          => i_vs_read_list,
                                                      i_id_edit_reason        => i_id_edit_reason,
                                                      i_notes_edit            => i_notes_edit,
                                                      i_dt_clinical           => i_dt_clinical,
                                                      o_epis_documentation    => o_epis_documentation,
                                                      o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_scales_core.set_epis_scales_score. i_id_episode: ' || i_epis || ' i_id_epis_doc_old: ' ||
                   i_epis_documentation || ' i_id_epis_doc_new: ' || o_epis_documentation;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.set_epis_scales_score(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_id_episode           => i_epis,
                                                    i_id_epis_doc_old      => i_epis_documentation,
                                                    i_id_epis_doc_new      => o_epis_documentation,
                                                    i_flags                => i_flags,
                                                    i_ids                  => i_ids,
                                                    i_scores               => i_scores,
                                                    i_id_scales_formulas   => i_id_scales_formulas,
                                                    i_dt_clinical          => i_dt_clinical,
                                                    o_id_epis_scales_score => o_id_epis_scales_score,
                                                    o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL update_scales_task: i_doc_area: ' || i_doc_area || ' i_episode: ' || i_epis;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_nurse.update_scales_task(i_lang     => i_lang,
                                               i_episode  => i_epis,
                                               i_doc_area => i_doc_area,
                                               i_prof     => i_prof,
                                               o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_EPIS_DOC_SCALES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_doc_scales;

    /********************************************************************************************
    * Get all the calculated scores.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_epis_documentation   Epis documentation ID        
    * @param i_id_patient              Patient id. Mandatory argument
    * @param i_id_visit                Visit id
    * @param i_id_episode              Episode id
    * @param i_id_doc_area             Doc_area id
    * @param i_start_date              Begin date (optional)        
    * @param i_end_date                End date (optional)
    * @param o_scores                  Scores info
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           12-Jul-2011
    **********************************************************************************************/
    FUNCTION get_saved_scores
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_visit              IN visit.id_visit%TYPE,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_doc_area           IN doc_area.id_doc_area%TYPE,
        i_start_date            IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date              IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_scores                OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_total_msg sys_message.code_message%TYPE;
    BEGIN
        g_error := 'CALL pk_message.get_message.';
        pk_alertlog.log_debug(g_error);
        l_total_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_scales_constant.g_total_msg);
    
        g_error := 'OPEN o_scores';
        pk_alertlog.log_debug(g_error);
        OPEN o_scores FOR
            SELECT CASE
                        WHEN sf.flg_formula_type = pk_scales_constant.g_formula_type_c THEN
                         NULL
                        ELSE
                         ess.score_value
                    END score_value,
                   ess.id_epis_documentation,
                   ess.id_scales,
                   ess.id_scales_group,
                   ess.id_documentation,
                   CASE
                        WHEN sf.flg_formula_type = pk_scales_constant.g_formula_type_c THEN
                         REPLACE(pk_translation.get_translation(i_lang, sf.code_scales_formula),
                                 pk_scales_constant.g_replace_1,
                                 score_value)
                        ELSE
                         nvl(pk_translation.get_translation(i_lang, sf.code_scales_formula), l_total_msg)
                    END description,
                   pk_translation.get_translation(i_lang,
                                                  pk_inp_nurse.get_scales_class(i_lang              => i_lang,
                                                                                i_prof              => i_prof,
                                                                                i_value             => ess.score_value,
                                                                                i_scales            => ess.id_scales,
                                                                                i_scope             => ess.id_episode,
                                                                                i_scope_type        => pk_alert_constant.g_scope_type_episode,
                                                                                i_id_scales_formula => ess.id_scales_formula)) class_description
              FROM epis_scales_score ess
              JOIN epis_documentation ed
                ON ed.id_epis_documentation = ess.id_epis_documentation
              JOIN episode epi
                ON epi.id_episode = ess.id_episode
              LEFT JOIN scales_formula sf
                ON ess.id_scales_formula = sf.id_scales_formula
             WHERE ess.id_epis_documentation = nvl(i_id_epis_documentation, ess.id_epis_documentation)
               AND ess.id_episode = nvl(i_id_episode, ess.id_episode)
               AND ess.id_patient = i_id_patient
               AND epi.id_visit = nvl(i_id_visit, epi.id_visit)
               AND sf.flg_visible = pk_alert_constant.g_yes
               AND ed.id_doc_area = nvl(i_id_doc_area, ed.id_doc_area)
               AND ess.dt_create >= nvl(i_start_date, ess.dt_create)
               AND ess.dt_create <= nvl(i_end_date, ess.dt_create);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_scores);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_SAVED_SCORES',
                                              o_error);
            RETURN FALSE;
    END get_saved_scores;

    /********************************************************************************************
    *  Get the main score associated to an epis_documentation.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_epis_documentation   Epis documentation ID                
    * @param i_flg_summary             Y - The score should appear in the summary grid. N - otherwise
    *
    * @return                          Score value
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           05-Jul-2011
    **********************************************************************************************/
    FUNCTION get_main_score
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_summary           IN scales_formula.flg_summary%TYPE DEFAULT pk_alert_constant.g_yes
    ) RETURN epis_scales_score.score_value%TYPE IS
        l_score epis_scales_score.score_value%TYPE;
        l_error t_error_out;
    BEGIN
        SELECT ess.score_value
          INTO l_score
          FROM epis_scales_score ess
          LEFT JOIN scales_formula sf
            ON ess.id_scales_formula = sf.id_scales_formula
         WHERE ess.id_epis_documentation = i_id_epis_documentation
           AND (sf.flg_formula_type = pk_scales_constant.g_formula_type_tm OR ess.id_scales_formula IS NULL)
           AND (sf.flg_visible = pk_alert_constant.g_yes OR sf.flg_visible IS NULL)
           AND (sf.flg_summary = i_flg_summary OR sf.flg_summary IS NULL)
           AND rownum = 1;
    
        RETURN l_score;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_MAIN_SCORE',
                                              l_error);
            RETURN NULL;
    END get_main_score;

    /**************************************************************************
    * return list of scales for patient, episode or visit                     *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    *                                 software ID)                            *
    * @param i_doc_area               the doc_area id                         *
    * @param i_scope                  id_patient, id_visit or id_episode      *
    *                                 according to i_flg_scope                *
    * @param i_scope_type             P-id_patient, V -id_visit, E-id_episode *
    * @param i_coll_epis_doc          Table number with id_epis_documentation *   
    * @param i_start_date             Begin date (optional)                   *  
    * @param i_end_date               End date (optional)                     *
    *                                                                         *
    * @return                         return list of scales for patient       *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/02/24                              *
    **************************************************************************/
    FUNCTION tf_scales_list
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_doc_area      IN NUMBER,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2 DEFAULT 'E',
        i_coll_epis_doc IN table_number DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN t_coll_doc_scales
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_SCALES_LIST';
        l_coll_scales t_coll_doc_scales;
    
        l_patient patient.id_patient%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_episode episode.id_episode%TYPE;
        l_error   t_error_out;
    
        CURSOR c_scales IS
            SELECT t.id_epis_documentation,
                   t.id_scales,
                   t.id_doc_template,
                   --mantained the 2 columns: desc_class and doc_desc_class because of the APIs using them
                   t.doc_desc_class      desc_class,
                   t.doc_desc_class,
                   t.soma,
                   t.id_professional,
                   t.nick_name,
                   t.date_target,
                   t.hour_target,
                   t.dt_last_update,
                   t.dt_last_update_tstz,
                   t.flg_status,
                   NULL                  signature
              FROM (SELECT ti.id_epis_documentation,
                           ti.id_scales,
                           ti.id_doc_template,
                           NULL desc_class,
                           decode(ti.soma,
                                  NULL,
                                  NULL,
                                  ti.score_value_str || ' ' ||
                                  pk_translation.get_translation(i_lang, ti.code_scale_score) ||
                                  decode(ti.class_description, NULL, NULL, ' - ' || ti.class_description)) doc_desc_class,
                           ti.soma,
                           ti.id_professional,
                           ti.nick_name,
                           ti.date_target,
                           ti.hour_target,
                           ti.dt_last_update,
                           ti.dt_last_update_tstz,
                           ti.flg_status
                      FROM (SELECT t_epis.id_epis_documentation,
                                   t_epis.id_scales,
                                   t_epis.id_doc_template,
                                   CASE
                                        WHEN t_epis.score_value < 1
                                             AND t_epis.score_value > 0
                                             AND t_epis.score_value NOT IN (0, 1) THEN
                                         to_char(t_epis.score_value, 'FM99990.99999')
                                        ELSE
                                         to_char(t_epis.score_value)
                                    END score_value_str,
                                   t_epis.score_value soma,
                                   t_epis.id_professional,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                                   pk_date_utils.dt_chr_tsz(i_lang, t_epis.dt_last_update_tstz, i_prof) date_target,
                                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                                    t_epis.dt_last_update_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software) hour_target,
                                   pk_date_utils.date_send_tsz(i_lang, t_epis.dt_last_update_tstz, i_prof) dt_last_update,
                                   t_epis.dt_last_update_tstz,
                                   t_epis.flg_status,
                                   scl.code_scale_score,
                                   decode(t_epis.score_value,
                                          NULL,
                                          NULL,
                                          pk_translation.get_translation(i_lang,
                                                                         pk_inp_nurse.get_scales_class(i_lang,
                                                                                                       i_prof,
                                                                                                       t_epis.score_value,
                                                                                                       scl.id_scales,
                                                                                                       l_patient,
                                                                                                       pk_alert_constant.g_scope_type_patient))) class_description
                            
                              FROM (SELECT eb.id_epis_documentation,
                                           eb.id_doc_template,
                                           eb.id_prof_last_update,
                                           eb.flg_status,
                                           eb.dt_last_update_tstz,
                                           eb.id_professional,
                                           ess.id_scales,
                                           ess.score_value,
                                           ess.id_scales_formula
                                      FROM epis_documentation eb
                                      JOIN episode epi
                                        ON epi.id_episode = eb.id_episode
                                      JOIN epis_scales_score ess
                                        ON ess.id_epis_documentation = eb.id_epis_documentation
                                       AND ess.id_episode = epi.id_episode
                                       AND eb.id_episode = ess.id_episode
                                       AND ess.id_patient = epi.id_patient
                                     WHERE ess.id_patient = l_patient
                                       AND ess.id_episode = nvl(l_episode, ess.id_episode)
                                       AND epi.id_visit = nvl(l_visit, epi.id_visit)
                                       AND eb.id_doc_area = i_doc_area
                                       AND ess.dt_create >= nvl(i_start_date, ess.dt_create)
                                       AND ess.dt_create <= nvl(i_end_date, ess.dt_create)
                                       AND (i_coll_epis_doc IS NULL OR
                                           eb.id_epis_documentation IN
                                           (SELECT /*+ dynamic_sampling( t_ids 2 ) */
                                              t_ids.column_value
                                               FROM TABLE(CAST(i_coll_epis_doc AS table_number)) t_ids))
                                    UNION ALL
                                    SELECT eb.id_epis_documentation,
                                           eb.id_doc_template,
                                           eb.id_prof_last_update,
                                           eb.flg_status,
                                           eb.dt_last_update_tstz,
                                           eb.id_professional,
                                           essh.id_scales,
                                           essh.score_value,
                                           essh.id_scales_formula
                                      FROM epis_scales_score_hist essh
                                      JOIN episode epi
                                        ON epi.id_episode = essh.id_episode
                                       AND epi.id_patient = essh.id_patient
                                      JOIN epis_documentation eb
                                        ON essh.id_epis_documentation = eb.id_epis_documentation
                                     WHERE essh.id_patient = l_patient
                                       AND essh.id_episode = nvl(l_episode, essh.id_episode)
                                       AND epi.id_visit = nvl(l_visit, epi.id_visit)
                                       AND eb.id_doc_area = i_doc_area
                                       AND essh.dt_create >= nvl(i_start_date, essh.dt_create)
                                       AND essh.dt_create <= nvl(i_end_date, essh.dt_create)
                                       AND (i_coll_epis_doc IS NULL OR
                                           eb.id_epis_documentation IN
                                           (SELECT /*+ dynamic_sampling( t_ids 2 ) */
                                              t_ids.column_value
                                               FROM TABLE(CAST(i_coll_epis_doc AS table_number)) t_ids))) t_epis
                              JOIN professional p
                                ON p.id_professional = t_epis.id_prof_last_update
                              JOIN scales scl
                                ON scl.id_scales = t_epis.id_scales
                              JOIN scales_formula sf
                                ON sf.id_scales_formula = t_epis.id_scales_formula
                               AND sf.flg_formula_type = pk_scales_constant.g_formula_type_tm) ti) t;
    
    BEGIN
        --Get list of values
        g_error := 'FILL T_TBL_SCALES_LIST_PAT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => l_error)
        THEN
            RETURN;
        END IF;
    
        OPEN c_scales;
        LOOP
            FETCH c_scales BULK COLLECT
                INTO l_coll_scales LIMIT 500;
            FOR i IN 1 .. l_coll_scales.count
            LOOP
                PIPE ROW(l_coll_scales(i));
            END LOOP;
            EXIT WHEN c_scales%NOTFOUND;
        END LOOP;
        CLOSE c_scales;
    
        RETURN;
    END tf_scales_list;

    /********************************************************************************************
    * Returns the info registered in the documentation regarding a patient, an episode or an visit.
    * For a patient scope: i_flg_scope = P and i_scope regards to id_patient
    * For a visit scope: i_flg_scope = V and i_scope regards to id_visit
    * For an episode scope: i_flg_scope = E and i_scope regards to id_episode    
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               the doc area ID
    * @param i_episode                the episode ID
    * @param i_scope                  Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type             Scope type (by episode; by visit; by patient)
    * @param i_coll_epis_doc          Table number with id_epis_documentation
    * @param i_start_date             Begin date (optional)        
    * @param i_end_date               End date (optional)
    * @param i_only_last              Only most updated record
    * @param o_scales_list            Cursor with the scales info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          06-Jan-2010
    **********************************************************************************************/
    FUNCTION get_scales_list
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_doc_area      IN NUMBER,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2 DEFAULT 'E',
        i_coll_epis_doc IN table_number DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_only_last     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_scales_list   OUT t_cur_doc_scales,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR o_scales_list';
        pk_alertlog.log_debug(g_error);
        OPEN o_scales_list FOR
            SELECT t_out.id_epis_documentation,
                   t_out.id_scales,
                   t_out.id_doc_template,
                   t_out.desc_class,
                   t_out.doc_desc_class,
                   t_out.soma,
                   t_out.id_professional,
                   t_out.nick_name,
                   t_out.date_target,
                   t_out.hour_target,
                   t_out.dt_last_update,
                   t_out.dt_last_update_tstz,
                   t_out.flg_status,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      NULL,
                                                      t_out.dt_last_update_tstz,
                                                      t_out.id_professional) signature
              FROM (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                     t.*,
                     CASE i_only_last
                         WHEN pk_alert_constant.g_yes THEN
                          row_number() over(PARTITION BY t.id_epis_documentation ORDER BY t.dt_last_update_tstz)
                         ELSE
                          1
                     END rn
                      FROM TABLE(tf_scales_list(i_lang,
                                                i_prof,
                                                i_doc_area,
                                                i_scope,
                                                i_scope_type,
                                                i_coll_epis_doc,
                                                i_start_date,
                                                i_end_date)) t) t_out
             WHERE t_out.rn = 1
             ORDER BY t_out.dt_last_update_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_scales_list_pat',
                                              o_error);
            pk_types.open_my_cursor(o_scales_list);
            RETURN FALSE;
    END get_scales_list;

    /********************************************************************************************
    * Devolve toda a informação registada na Documentation para um paciente, relativamente às escalas
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               the doc area ID    
    * @param o_scales_list            Cursor with the scales info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2008/10/27
    **********************************************************************************************/
    FUNCTION get_scales_list_pat
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_doc_area    IN NUMBER,
        i_id_episode  IN NUMBER,
        o_scales_list OUT t_cur_doc_scales,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient patient.id_patient%TYPE;
    BEGIN
        g_error := 'CALL pk_episode.get_id_patient. i_id_episode = ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        l_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
    
        g_error := 'CALL get_scales_list_pat. i_scope = ' || l_patient || '; i_scope_type: P';
        pk_alertlog.log_debug(g_error);
        IF NOT get_scales_list(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_doc_area    => i_doc_area,
                               i_scope       => l_patient,
                               i_scope_type  => pk_inp_util.g_scope_patient_p,
                               o_scales_list => o_scales_list,
                               o_error       => o_error)
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
                                              'get_scales_list_pat',
                                              o_error);
            pk_types.open_my_cursor(o_scales_list);
            RETURN FALSE;
    END get_scales_list_pat;

    /**********************************************************************************************
    * SET_MATCH_SCALES                   This function make "match" of scales scores of an episode
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.0.5
    * @since                                 07-Apr-2011
    **********************************************************************************************/
    FUNCTION set_match_scales_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    BEGIN
        --g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET SCORES FROM THE EPISODE.  i_episode_temp: ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        FOR rec IN (SELECT *
                      FROM epis_scales_score ess
                     WHERE ess.id_episode = i_episode_temp)
        LOOP
            --send the actual to the history
            g_error := 'CAL set_epis_scales_score_hist';
            pk_alertlog.log_debug(g_error);
            IF NOT set_epis_scales_score_hist(i_lang                  => i_lang,
                                              i_prof                  => i_prof,
                                              i_id_epis_documentation => rec.id_epis_documentation,
                                              o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END LOOP;
    
        --    
        g_error := 'CALL ts_epis_pn_hist.UPD WITH ID_EPISODE = ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_epis_scales_score_hist.upd(id_episode_in  => i_episode,
                                      id_episode_nin => FALSE,
                                      where_in       => 'id_episode = ' || i_episode_temp,
                                      rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE WITH ID_EPISODE ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_SCALES_SCORE_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        --
        g_error := 'CALL TS_EPIS_HIDRICS.UPD WITH ID_EPISODE = ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_epis_scales_score.upd(id_episode_in     => i_episode,
                                 id_episode_nin    => FALSE,
                                 id_prof_create_in => i_prof.id,
                                 dt_create_in      => current_timestamp,
                                 where_in          => 'id_episode = ' || i_episode_temp,
                                 rows_out          => l_rowids);
    
        g_error := 'PROCESS UPDATE WITH ID_EPISODE ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_SCALES_SCORE',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
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
                                              'SET_MATCH_SCALES_EPIS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_match_scales_epis;

    /**********************************************************************************************
    * SET_MATCH_SCALES                   This function make "match" of scales scores of a patient
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_patient_temp               Temporary patient
    * @param i_id_patient                    Patient identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.0.5
    * @since                                 07-Apr-2011
    **********************************************************************************************/
    FUNCTION set_match_scales_pat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient_temp IN patient.id_patient%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    BEGIN
        --g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET SCORES FROM THE PATIENT.  i_id_patient_temp: ' || i_id_patient_temp;
        pk_alertlog.log_debug(g_error);
        FOR rec IN (SELECT *
                      FROM epis_scales_score ess
                     WHERE ess.id_patient = i_id_patient_temp)
        LOOP
            --send the actual to the history
            g_error := 'CAL set_epis_scales_score_hist';
            pk_alertlog.log_debug(g_error);
            IF NOT set_epis_scales_score_hist(i_lang                  => i_lang,
                                              i_prof                  => i_prof,
                                              i_id_epis_documentation => rec.id_epis_documentation,
                                              o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END LOOP;
    
        --    
        g_error := 'CALL ts_epis_pn_hist.UPD WITH ID_PATIENT_TEMP = ' || i_id_patient_temp;
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_epis_scales_score_hist.upd(id_patient_in  => i_id_patient,
                                      id_patient_nin => FALSE,
                                      where_in       => 'id_patient = ' || i_id_patient_temp,
                                      rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE WITH ID_PATIENT ' || i_id_patient_temp;
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_SCALES_SCORE_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        --
        g_error := 'CALL TS_EPIS_HIDRICS.UPD WITH ID_PATIENT ' || i_id_patient_temp;
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_epis_scales_score.upd(id_patient_in     => i_id_patient,
                                 id_patient_nin    => FALSE,
                                 id_prof_create_in => i_prof.id,
                                 dt_create_in      => current_timestamp,
                                 where_in          => 'id_patient = ' || i_id_patient_temp,
                                 rows_out          => l_rowids);
    
        g_error := 'PROCESS UPDATE WITH ID_PATIENT ' || i_id_patient_temp;
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_SCALES_SCORE',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
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
                                              'SET_MATCH_SCALES_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_match_scales_pat;

    /********************************************************************************************
    *  Get the scales associated to the doc_area.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_doc_area             Documentation Area ID        
    * @param o_id_scales               Scales identifier
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           24-Mai-2011
    **********************************************************************************************/
    FUNCTION get_id_scales
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_id_doc_template IN doc_template.id_doc_template%TYPE,
        o_id_scales       OUT scales.id_scales%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET ID_SCALES. i_doc_area: ' || i_doc_area;
        pk_alertlog.log_debug(g_error);
        SELECT sdv.id_scales
          INTO o_id_scales
          FROM scales_doc_value sdv
          JOIN doc_element de
            ON de.id_doc_element = sdv.id_doc_element
          JOIN documentation doc
            ON doc.id_documentation = de.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON dtad.id_documentation = doc.id_documentation
         WHERE dtad.id_doc_area = i_doc_area
           AND dtad.id_doc_template = i_id_doc_template
           AND sdv.flg_available = pk_alert_constant.g_yes
           AND rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_id_scales := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ELEMENTS_SCORE',
                                              o_error);
            RETURN FALSE;
    END get_id_scales;

    /********************************************************************************************
    *  Get the documentation actual info and the respective scores.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_epis_documentation    Epis documentation Id        
    * @param i_id_scales                Scales Id    
    * @param o_groups                   Groups info: indicated the id_documentations that belongs to each group
    * @param o_scores                   Scores info
    * @param o_epis_doc_register        array with the detail info register
    * @param o_epis_document_val        array with detail of documentation
    * @param o_template_layouts         Cursor containing the layout for each template used
    * @param o_doc_area_component       Cursor containing the components for each template used 
    * @param o_record_count             Indicates the number of records that match filters criteria
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_scores_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        o_groups                OUT pk_types.cursor_type,
        o_scores                OUT pk_types.cursor_type,
        o_doc_area_register     OUT pk_types.cursor_type,
        o_epis_document_val     OUT pk_types.cursor_type,
        o_template_layouts      OUT pk_types.cursor_type,
        o_doc_area_component    OUT pk_types.cursor_type,
        o_record_count          OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_doc_area doc_area.id_doc_area%TYPE;
        l_id_patient  patient.id_patient%TYPE;
        l_id_episode  episode.id_episode%TYPE;
    
    BEGIN
        g_error := 'GET ID_EPISODE and ID_DOC_AREA.';
        SELECT ed.id_episode, ed.id_doc_area
          INTO l_id_episode, l_id_doc_area
          FROM epis_documentation ed
         WHERE ed.id_epis_documentation = i_id_epis_documentation;
    
        g_error := 'CALL pk_episode.get_id_patient: i_id_episode: ' || l_id_episode;
        pk_alertlog.log_debug(g_error);
        l_id_patient := pk_episode.get_id_patient(i_episode => l_id_episode);
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE_INTERNAL FUNCTION i_id_epis_documentation: ' ||
                   i_id_epis_documentation;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_episode         => l_id_episode,
                                                           i_id_patient         => l_id_patient,
                                                           i_doc_area           => l_id_doc_area,
                                                           i_epis_doc           => table_number(i_id_epis_documentation),
                                                           i_epis_anamn         => table_number(),
                                                           i_epis_rev_sys       => table_number(),
                                                           i_epis_obs           => table_number(),
                                                           i_epis_past_fsh      => table_number(),
                                                           i_epis_recomend      => table_number(),
                                                           i_flg_show_fm        => pk_alert_constant.g_no,
                                                           o_doc_area_register  => o_doc_area_register,
                                                           o_doc_area_val       => o_epis_document_val,
                                                           o_template_layouts   => o_template_layouts,
                                                           o_doc_area_component => o_doc_area_component,
                                                           o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_scales_formulas.get_groups. i_id_doc_area: ' || l_id_doc_area || ' i_id_scales: ' ||
                   i_id_scales;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_formulas.get_groups(i_lang     => i_lang,
                                             i_prof     => i_prof,
                                             i_doc_area => l_id_doc_area,
                                             i_scales   => i_id_scales,
                                             o_groups   => o_groups,
                                             o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_scales_core.get_saved_scores. i_id_epis_documentation: ' || i_id_epis_documentation;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.get_saved_scores(i_lang                  => i_lang,
                                               i_prof                  => i_prof,
                                               i_id_epis_documentation => i_id_epis_documentation,
                                               i_id_patient            => l_id_patient,
                                               i_id_visit              => NULL,
                                               i_id_episode            => NULL,
                                               i_id_doc_area           => NULL,
                                               o_scores                => o_scores,
                                               o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_epis_document_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_types.open_my_cursor(o_groups);
            pk_types.open_my_cursor(o_scores);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_epis_document_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_types.open_my_cursor(o_groups);
            pk_types.open_my_cursor(o_scores);
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_SCORES_DETAIL',
                                              o_error);
            RETURN FALSE;
    END get_scores_detail;

    /********************************************************************************************
    *  Get the documented assessment scales description "Title: score"
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_episode                  Episode Id
    * @param i_id_scales                Scales Id
    * @param o_ass_scales               Cursor with description in the format: "Title: score"
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Nuno Alves
    * @version                         2.6.3.8.2
    * @since                           27-04-2015
    **********************************************************************************************/
    FUNCTION get_epis_ass_scales_scores
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_show_all_scores IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_tbl_ass_scales  OUT t_coll_desc_scales,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient         patient.id_patient%TYPE;
        c_id_summary_page summary_page.id_summary_page%TYPE := 34;
        c_chr_separator   VARCHAR2(5) := ': ';
        l_sections        pk_types.cursor_type;
        l_sections_rec    pk_summary_page.t_rec_section;
        l_sections_tab    pk_summary_page.t_coll_section;
        l_doc_scales      pk_scales_core.t_cur_doc_scales;
        l_doc_scales_rec  pk_scales_core.t_rec_doc_scales;
        l_doc_scales_tab  pk_scales_core.t_coll_doc_scales;
        l_epis_doc_ids    table_number;
        l_doc_area_ids    table_number;
        l_record_count    NUMBER;
        l_tp_desc_scales  t_coll_desc_scales := t_coll_desc_scales();
        
        function get_detail_sig_by_epis_doc( i_epis_documentation in table_number ) return varchar2 is
          tbl_sig table_varchar;
          l_return varchar2(4000);
          l_epis_documentation number;
        begin
          
            if i_epis_documentation.count > 0 then
                l_epis_documentation := i_epis_documentation(1);
        
                select 
                pk_prof_utils.get_detail_signature(i_lang,i_prof,NULL,ed.dt_creation_tstz,ed.id_professional) signature
                bulk collect into tbl_sig
                from epis_documentation ed 
                where ed.id_epis_documentation = l_epis_documentation;
                
                if tbl_sig.count > 0 then
                   l_return := tbl_sig(1);
                end if;
          
            end if;
        
            return l_return;
          
          end get_detail_sig_by_epis_doc;
        
    BEGIN
        IF i_episode IS NULL
        THEN
            RAISE g_exception;
            RETURN FALSE;
        END IF;
        g_error := 'CALL pk_episode.get_epis_patient: i_id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        -- Get patient from episode
        l_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        g_error   := 'CALL pk_summary_page.get_summary_page_sections: i_id_summary_page: ' || c_id_summary_page ||
                     ', i_pat: ' || l_patient;
        pk_alertlog.log_debug(g_error);
        -- Get summary page sections for the assessment scales summary page, but we only need the doc_area ids and the section title
        IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_summary_page => c_id_summary_page,
                                                         i_pat             => l_patient,
                                                         o_sections        => l_sections,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FETCH l_sections BULK COLLECT
            INTO l_sections_tab;
        FOR i IN 1 .. l_sections_tab.count
        LOOP
            l_sections_rec := l_sections_tab(i);
            g_error        := 'CALL pk_touch_option.get_doc_area_value_ids: epis:' || i_episode || 'doc_area:' ||
                              l_sections_rec.id_doc_area;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_doc_area           => table_number(l_sections_rec.id_doc_area),
                                                          i_scope              => table_number(i_episode),
                                                          i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                          i_fltr_status        => pk_alert_constant.g_active,
                                                          o_record_count       => l_record_count,
                                                          o_coll_epis_doc      => l_epis_doc_ids,
                                                          o_coll_epis_anamn    => l_doc_area_ids,
                                                          o_coll_epis_rev_sys  => l_doc_area_ids,
                                                          o_coll_epis_obs      => l_doc_area_ids,
                                                          o_coll_epis_past_fsh => l_doc_area_ids,
                                                          o_coll_epis_recomend => l_doc_area_ids,
                                                          o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
            IF l_epis_doc_ids.count > 0
            THEN
               l_doc_scales_rec.desc_class := null;
               l_doc_scales_rec.signature  := null;
                IF l_sections_rec.flg_score = pk_alert_constant.g_yes
                THEN
                    -- Get the scales description with the score (desc_class)
                    g_error := 'CALL get_scales_list: epis:' || i_episode || 'doc_area:' || l_sections_rec.id_doc_area;
                    pk_alertlog.log_debug(g_error);
                    IF NOT get_scales_list(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_doc_area      => l_sections_rec.id_doc_area,
                                           i_scope         => i_episode,
                                           i_scope_type    => pk_alert_constant.g_scope_type_episode,
                                           i_coll_epis_doc => l_epis_doc_ids,
                                           i_only_last     => pk_alert_constant.g_yes,
                                           o_scales_list   => l_doc_scales,
                                           o_error         => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    FETCH l_doc_scales BULK COLLECT
                        INTO l_doc_scales_tab;
                    IF l_doc_scales_tab.exists(1)
                    THEN
                        IF i_show_all_scores = pk_alert_constant.g_yes
                        THEN
                            -- add all the registered scores for the scale
                            FOR j IN 1 .. l_doc_scales_tab.count
                            LOOP
                                l_doc_scales_rec := l_doc_scales_tab(j);
                            
                                l_tp_desc_scales.extend;
                                l_tp_desc_scales(l_tp_desc_scales.last()) := t_rec_desc_scales(l_sections_rec.translated_code ||
                                                                                               c_chr_separator ||
                                                                                               l_doc_scales_rec.desc_class,
                                                                                               l_doc_scales_rec.signature);
                            
                            END LOOP;
                        ELSE
                            -- only the most recent value for each score must be returned
                            -- the get_scales_list returns the info ordered by dt_last_update_tsz, so we only want the first record
                            l_doc_scales_rec := l_doc_scales_tab(1);
                        
                            l_tp_desc_scales.extend;
                            l_tp_desc_scales(l_tp_desc_scales.last()) := t_rec_desc_scales(l_sections_rec.translated_code ||
                                                                                           c_chr_separator ||
                                                                                           l_doc_scales_rec.desc_class,
                                                                                           l_doc_scales_rec.signature);
                        
                        END IF;
                    END IF;
                ELSE
                    -- No score, only the description of the scale must be shown
                    l_tp_desc_scales.extend;
                    l_doc_scales_rec.signature := get_detail_sig_by_epis_doc( l_epis_doc_ids );
                    l_tp_desc_scales(l_tp_desc_scales.last()) := t_rec_desc_scales(l_sections_rec.translated_code,
                                                                                   l_doc_scales_rec.signature);
                END IF;
            END IF;
        END LOOP;
    
        o_tbl_ass_scales := l_tp_desc_scales;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_epis_ass_scales_scores',
                                              o_error);
            RETURN FALSE;
    END get_epis_ass_scales_scores;
    /********************************************************************************************
    *  Get the documented assessment scales description "Title: score"
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_episode                  Episode Id
    * @param i_id_scales                Scales Id
    * @param o_ass_scales               Cursor with description in the format: "Title: score"
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Nuno Alves
    * @version                         2.6.3.8.2
    * @since                           27-04-2015
    **********************************************************************************************/
    FUNCTION get_epis_ass_scales_scores
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_episode     IN table_number,
        i_show_all_scores IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_ass_scales      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_count       NUMBER;
        l_scale_scores_tab t_coll_desc_scales := t_coll_desc_scales();
    BEGIN
        SELECT COUNT(1)
          INTO l_epis_count
          FROM TABLE(i_tbl_episode) t
         WHERE t.column_value IS NOT NULL;
        IF l_epis_count = 0
        THEN
            RAISE g_exception;
            RETURN FALSE;
        END IF;
        -- Make sure there is nothing on the tbl_temp
        DELETE FROM tbl_temp;
        FOR i IN 1 .. i_tbl_episode.count
        LOOP
            g_error := 'CALL pk_scales_core.get_epis_ass_scales_scores for episode: ' || i_tbl_episode(i);
            pk_alertlog.log_debug(g_error);
            -- Get summary page sections for the assessment scales summary page, but we only need the doc_area ids and the section title
            IF NOT pk_scales_core.get_epis_ass_scales_scores(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_episode         => i_tbl_episode(i),
                                                             i_show_all_scores => i_show_all_scores,
                                                             o_tbl_ass_scales  => l_scale_scores_tab,
                                                             o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
            -- Populate tbl_temp
            g_error := 'FORALL INSERT into tbl_temp';
            FORALL j IN 1 .. l_scale_scores_tab.count
                INSERT INTO tbl_temp
                    (num_1, vc_1, vc_2)
                VALUES
                    (i_tbl_episode(i), l_scale_scores_tab(j).desc_class, l_scale_scores_tab(j).signature);
        END LOOP;
        -- From table_varchar to a cursor with a desc_info field, like expected by the UX layer
        g_error := 'OPEN CURSOR o_ass_scales';
        pk_alertlog.log_debug(g_error);
        OPEN o_ass_scales FOR
            SELECT t.vc_1 desc_info, t.vc_2 signature, t.num_1 id_episode
              FROM tbl_temp t;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_ass_scales);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ass_scales);
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_epis_ass_scales_scores',
                                              o_error);
            RETURN FALSE;
    END get_epis_ass_scales_scores;
    /**
    * Copy the scores of an epis_documentation to an epis_documentation equal to the previous one (Copy without changes option)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 Episode ID
    * @param   i_id_epis_doc_old            Id_epis_documentation being updated    
    * @param   i_id_epis_doc_new            Id_epis_documentation created    
    * @param   o_id_epis_scales_score       Epis scales score created IDs
    * @param   o_error                      Error message
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   17-Oct-2011
    */
    FUNCTION set_copy_scores
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_doc_old      IN epis_documentation.id_epis_documentation%TYPE,
        i_id_epis_doc_new      IN epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_scales_score epis_scales_score.id_epis_scales_score%TYPE;
        l_rows_out             table_varchar;
    BEGIN
        g_sysdate := current_timestamp;
    
        o_id_epis_scales_score := table_number();
    
        FOR rec IN (SELECT ess.id_patient,
                           ess.flg_status,
                           ess.id_scales,
                           ess.id_scales_group,
                           ess.id_documentation,
                           ess.score_value,
                           ess.id_scales_formula
                      FROM epis_scales_score ess
                     WHERE ess.id_epis_documentation = i_id_epis_doc_old
                       AND ess.flg_status = pk_scales_constant.g_scales_score_status_a)
        LOOP
            l_id_epis_scales_score := ts_epis_scales_score.next_key;
        
            --set the actual values
            g_error := 'Set actual values. i_id_episode: ' || i_id_episode || ' i_id_patient: ' || rec.id_patient ||
                       ' id_epis_documentation: ' || i_id_epis_doc_new || ' id_scales: ' || rec.id_scales ||
                       ' id_scales_group: ' || rec.id_scales_group || ' id_documentation: ' || rec.id_documentation ||
                       ' id_scales_formula: ' || rec.id_scales_formula || ' score_value: ' || rec.score_value;
            pk_alertlog.log_debug(g_error);
            ts_epis_scales_score.ins(id_epis_scales_score_in  => l_id_epis_scales_score,
                                     id_episode_in            => i_id_episode,
                                     id_patient_in            => rec.id_patient,
                                     id_epis_documentation_in => i_id_epis_doc_new,
                                     flg_status_in            => rec.flg_status,
                                     id_prof_create_in        => i_prof.id,
                                     dt_create_in             => g_sysdate,
                                     id_cancel_reason_in      => NULL,
                                     notes_cancel_in          => NULL,
                                     dt_cancel_in             => NULL,
                                     id_prof_cancel_in        => NULL,
                                     id_scales_in             => rec.id_scales,
                                     id_scales_group_in       => rec.id_scales_group,
                                     id_documentation_in      => rec.id_documentation,
                                     score_value_in           => rec.score_value,
                                     id_scales_formula_in     => rec.id_scales_formula,
                                     rows_out                 => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'EPIS_SCALES_SCORE', l_rows_out, o_error);
        
            o_id_epis_scales_score.extend();
            o_id_epis_scales_score(o_id_epis_scales_score.last) := l_id_epis_scales_score;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_COPY_SCORES',
                                              o_error);
            RETURN FALSE;
    END set_copy_scores;

    /********************************************************************************************
    * return list of scales for a given epis_documentation           
    *                                                                         
    * @param i_lang                   The language ID                         
    * @param i_prof                   Object (professional ID, institution ID,software ID)   
    * @param i_patient                patient ID                         
    * @param i_epis_documentation     array with ID_EPIS_DOCUMENTION                        
    *                                                                         
    * @return                         return list of scales epis_documentation       
    *                                                                         
    * @author                         Elisabete Bugalho                              
    * @version                        2.6.2.1                                     
    * @since                          2012/03/26                              
    **************************************************************************/
    FUNCTION tf_scales_list
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_epis_documentation IN table_number
    ) RETURN t_coll_doc_scales
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'tf_scales_list';
        l_coll_scales t_coll_doc_scales;
    
        l_error t_error_out;
    
        CURSOR c_scales IS
            SELECT t.id_epis_documentation,
                   t.id_scales,
                   t.id_doc_template,
                   --mantained the 2 columns: desc_class and doc_desc_class because of the APIs using them
                   t.doc_desc_class      desc_class,
                   t.doc_desc_class,
                   t.soma,
                   t.id_professional,
                   t.nick_name,
                   t.date_target,
                   t.hour_target,
                   t.dt_last_update,
                   t.dt_last_update_tstz,
                   t.flg_status,
                   NULL                  signature
              FROM (SELECT ti.id_epis_documentation,
                           ti.id_scales,
                           ti.id_doc_template,
                           NULL desc_class,
                           decode(ti.soma,
                                  NULL,
                                  NULL,
                                  ti.score_value_str || ' ' ||
                                  pk_translation.get_translation(i_lang, ti.code_scale_score) ||
                                  decode(ti.class_description, NULL, NULL, ' - ' || ti.class_description)) doc_desc_class,
                           ti.soma,
                           ti.id_professional,
                           ti.nick_name,
                           ti.date_target,
                           ti.hour_target,
                           ti.dt_last_update,
                           ti.dt_last_update_tstz,
                           ti.flg_status
                      FROM (SELECT t_epis.id_epis_documentation,
                                   t_epis.id_scales,
                                   t_epis.id_doc_template,
                                   CASE
                                        WHEN t_epis.score_value < 1
                                             AND t_epis.score_value NOT IN (0, 1) THEN
                                         to_char(t_epis.score_value, 'FM99990.99999')
                                        ELSE
                                         to_char(t_epis.score_value)
                                    END score_value_str,
                                   t_epis.score_value soma,
                                   t_epis.id_professional,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                                   pk_date_utils.dt_chr_tsz(i_lang, t_epis.dt_last_update_tstz, i_prof) date_target,
                                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                                    t_epis.dt_last_update_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software) hour_target,
                                   pk_date_utils.date_send_tsz(i_lang, t_epis.dt_last_update_tstz, i_prof) dt_last_update,
                                   t_epis.dt_last_update_tstz,
                                   t_epis.flg_status,
                                   scl.code_scale_score,
                                   decode(t_epis.score_value,
                                          NULL,
                                          NULL,
                                          pk_translation.get_translation(i_lang,
                                                                         pk_inp_nurse.get_scales_class(i_lang,
                                                                                                       i_prof,
                                                                                                       t_epis.score_value,
                                                                                                       scl.id_scales,
                                                                                                       i_patient,
                                                                                                       pk_alert_constant.g_scope_type_patient))) class_description
                            
                              FROM (SELECT eb.id_epis_documentation,
                                           eb.id_doc_template,
                                           eb.id_prof_last_update,
                                           eb.flg_status,
                                           eb.dt_last_update_tstz,
                                           eb.id_professional,
                                           ess.id_scales,
                                           ess.score_value,
                                           ess.id_scales_formula
                                      FROM epis_documentation eb
                                      JOIN epis_scales_score ess
                                        ON ess.id_epis_documentation = eb.id_epis_documentation
                                       AND eb.id_episode = ess.id_episode
                                     WHERE eb.id_epis_documentation IN
                                           (SELECT /*+ dynamic_sampling(t 2) */
                                             t.column_value
                                              FROM TABLE(i_epis_documentation) t)) t_epis
                              JOIN professional p
                                ON p.id_professional = t_epis.id_prof_last_update
                              JOIN scales scl
                                ON scl.id_scales = t_epis.id_scales
                              JOIN scales_formula sf
                                ON sf.id_scales_formula = t_epis.id_scales_formula
                               AND sf.flg_formula_type = pk_scales_constant.g_formula_type_tm) ti) t;
    
    BEGIN
        --Get list of values
        g_error := 'FILL T_TBL_SCALES_LIST_PAT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        OPEN c_scales;
        LOOP
            FETCH c_scales BULK COLLECT
                INTO l_coll_scales LIMIT 500;
            FOR i IN 1 .. l_coll_scales.count
            LOOP
                PIPE ROW(l_coll_scales(i));
            END LOOP;
            EXIT WHEN c_scales%NOTFOUND;
        END LOOP;
        CLOSE c_scales;
    
        RETURN;
    END tf_scales_list;

    FUNCTION cancel_scales_score_vs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_epis_doc      IN epis_documentation.id_epis_documentation%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_vital_sign_read epis_scales_score.id_vital_sign_read%TYPE;
    BEGIN
        BEGIN
            SELECT ess.id_vital_sign_read
              INTO l_id_vital_sign_read
              FROM epis_scales_score ess
             WHERE ess.id_epis_documentation = i_id_epis_doc
               AND ess.flg_status = pk_scales_constant.g_scales_score_status_a
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
        IF l_id_vital_sign_read IS NOT NULL
        THEN
            IF NOT pk_vital_sign_core.cancel_epis_vs_read(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_episode            => i_id_episode,
                                                          i_id_vital_sign_read => l_id_vital_sign_read,
                                                          i_id_cancel_reason   => i_id_cancel_reason,
                                                          i_notes              => i_notes,
                                                          o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    END cancel_scales_score_vs;
BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_scales_core;
/