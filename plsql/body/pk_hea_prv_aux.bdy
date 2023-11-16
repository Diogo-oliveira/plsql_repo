/*-- Last Change Revision: $Rev: 2049530 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-11-09 15:32:22 +0000 (qua, 09 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_hea_prv_aux IS

    /**
    * Returns the professional photo.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    *
    * @return                       The professional photo
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_photo
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        IF pk_profphoto.check_blob(i_id_professional) = 'N'
        THEN
            RETURN '';
        ELSE
            RETURN pk_profphoto.get_prof_photo(profissional(i_id_professional, 0, i_prof.software));
        END IF;
    END;

    /**
    * Returns the number of habits.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The number of habits
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_habits
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_habits NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_habits
          FROM pat_habit
         WHERE id_patient = i_id_patient
           AND flg_status NOT IN (g_pat_allergy_flg_cancelled, g_pat_allergy_flg_resolved);
        RETURN l_habits;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 0;
    END get_habits;

    /**
    * Returns the number of relevant notes.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The number of relevant notes
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_relev_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_relev_notes NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_relev_notes
          FROM v_pat_notes
         WHERE id_patient = i_id_patient
           AND flg_status != pk_alert_constant.g_cancelled;
        RETURN l_relev_notes;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 0;
    END;

    /**
    * Returns the number of previous episodes.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The number of previous episodes
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prev_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_prev_epis NUMBER;
    BEGIN
        BEGIN
            SELECT COUNT(0)
              INTO l_prev_epis
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND e.flg_status IN (pk_edis_proc.g_epis_inactive)
               AND e.flg_ehr = pk_visit.g_flg_ehr_n;
        EXCEPTION
            WHEN no_data_found THEN
                l_prev_epis := 0;
        END;
    
        l_prev_epis := l_prev_epis +
                       pk_edis_proc.get_prev_episode(i_lang, i_id_patient, i_prof.institution, i_prof.software);
        RETURN l_prev_epis;
    END;

    /**
    * Returns the blood type.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The blood type
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_blood_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
    
        l_blood_group VARCHAR2(1000 CHAR);
    
    BEGIN
    
        BEGIN
            SELECT to_char(desc_analysis_result) desc_analysis_result
              INTO l_blood_group
              FROM (SELECT listagg(arp.desc_analysis_result, ' ') within GROUP(ORDER BY arp.dt_analysis_result_par_tstz) desc_analysis_result
                      FROM pat_blood_group pbg, analysis_result_par arp
                     WHERE pbg.id_patient = i_id_patient
                       AND pbg.flg_status = pk_alert_constant.g_active
                       AND pbg.id_analysis_result = arp.id_analysis_result
                     ORDER BY pbg.dt_pat_blood_group_tstz DESC)
             WHERE rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_blood_group := NULL;
        END;
    
        IF l_blood_group IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN l_blood_group;
        END IF;
    
    END get_blood_type;

    /**
    * Returns complaints and additional information.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_call_type            Function call type: A-application, R-reports
    *
    * @param o_title_diag           Diagnosis title (used in the report header)            
    * @param o_compl_diag           Complaint diagnoses
    * @param o_title_pain           Complaint title (used in the report header)
    * @param o_compl_pain           Complaint
    * @param o_info_adic            Additional information
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE set_comp_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_call_type  IN VARCHAR2,
        o_title_diag OUT VARCHAR2,
        o_compl_diag OUT VARCHAR2,
        o_title_pain OUT VARCHAR2,
        o_compl_pain OUT VARCHAR2,
        o_info_adic  OUT VARCHAR2
    ) IS
        l_diags          table_varchar;
        l_title_diags    table_varchar;
        l_triage_prof    VARCHAR2(32676);
        l_desc_anamnesis VARCHAR2(32676);
        l_anamnesis_prof VARCHAR2(32676);
        l_desc_triage    VARCHAR2(32676);
    
        l_id_epis_type episode.id_epis_type%TYPE;
    
        l_cur_epis_complaint pk_complaint.epis_complaint_cur;
        l_row_epis_complaint pk_complaint.epis_complaint_rec;
        l_error              t_error_out;
    
        -- report labels
        l_discharge_diagn_mess    CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_FINAL_T001';
        l_primary_diagn_mess      CONSTANT sys_message.code_message%TYPE := 'REP_PRIMARY_DIAGNOSIS_001';
        l_differential_diagn_mess CONSTANT sys_message.code_message%TYPE := 'EDIS_GRID_T025';
        l_prev_diagnosis_mess     CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_M039';
        l_flowchart_mess          CONSTANT sys_message.code_message%TYPE := 'PREV_EPISODE_T334';
        l_complaint_mess          CONSTANT sys_message.code_message%TYPE := 'COMPLAINT_T004';
        l_reason_for_visit_mess   CONSTANT sys_message.code_message%TYPE := 'PREV_EPISODE_T557';
    
        l_title_pain              sys_message.desc_message%TYPE;
        l_title_triage            sys_message.desc_message%TYPE;
        l_config_show_triage_info sys_config.value%TYPE;
        l_column_flg_triage_res_grids CONSTANT VARCHAR2(200 CHAR) := 'FLG_TRIAGE_RES_GRIDS';
        l_conf_flg_triage_res_grids triage_configuration.flg_triage_res_grids%TYPE;
        l_config_record_date_order  sys_config.value%TYPE;
        l_triage_date               epis_triage.dt_end_tstz%TYPE;
        l_complaint_date            epis_complaint.adw_last_update_tstz%TYPE;
    
        l_diff_diagnoses_same_icd  sys_config.value%TYPE := pk_sysconfig.get_config('ALLOW_DIFF_DIAGNOSIS_SAME_ICD',
                                                                                    i_prof);
        l_disch_diagnoses_same_icd sys_config.value%TYPE := pk_sysconfig.get_config('ALLOW_DISCH_DIAGNOSIS_SAME_ICD',
                                                                                    i_prof);
        l_complaints               sys_message.desc_message%TYPE;
        l_id_professional          epis_complaint.id_professional%TYPE;
    BEGIN
        -- DIAGNÓSTICOS
        g_error := 'OPEN C_DIAGNOSIS';
        -- FORMATS DIAGNOSES FOR PRESENTATION AND CORRECTLY SORTS THEM 
        SELECT *
          BULK COLLECT
          INTO l_diags, l_title_diags
          FROM (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                  i_id_diagnosis        => d.id_diagnosis,
                                                  i_desc_epis_diagnosis => ed2.desc_epis_diagnosis,
                                                  i_code                => d.code_icd,
                                                  i_flg_other           => d.flg_other,
                                                  i_flg_std_diag        => ad.flg_icd9,
                                                  i_epis_diag           => ed2.id_epis_diagnosis) desc_diagnosis,
                       decode(ed2.flg_final_type,
                              pk_edis_proc.g_epis_diag_final_type_primary,
                              l_primary_diagn_mess,
                              decode(ed2.flg_type,
                                     pk_edis_proc.g_epis_diag_type_definitive,
                                     l_discharge_diagn_mess,
                                     l_differential_diagn_mess)) diag_title
                  FROM ( -- SELECTS THE DIAGNOSES TO SHOW
                        SELECT ed.*,
                                row_number() over(PARTITION BY ed.id_diagnosis, ed.id_diagnosis_condition, ed.id_sub_analysis, ed.id_anatomical_area, ed.id_anatomical_side ORDER BY decode(ed.flg_type, pk_edis_proc.g_epis_diag_type_definitive, 0, 1) ASC, decode(ed.flg_status, pk_edis_proc.g_epis_diag_confirmed, 0, 1) ASC, decode(ed.flg_status, pk_edis_proc.g_epis_diag_despiste, ed.dt_epis_diagnosis_tstz, ed.dt_confirmed_tstz) DESC) rn
                          FROM epis_diagnosis ed
                         WHERE ed.id_episode = i_id_episode
                           AND ed.flg_status IN (pk_edis_proc.g_epis_diag_confirmed, pk_edis_proc.g_epis_diag_despiste)) ed2
                  JOIN diagnosis d
                    ON (d.id_diagnosis = ed2.id_diagnosis)
                  LEFT JOIN alert_diagnosis ad
                    ON ad.id_alert_diagnosis = ed2.id_alert_diagnosis
                 WHERE ((l_diff_diagnoses_same_icd = pk_alert_constant.g_yes AND
                       ed2.flg_type = pk_diagnosis.g_diag_type_p) OR
                       (l_disch_diagnoses_same_icd = pk_alert_constant.g_yes AND
                       ed2.flg_type = pk_diagnosis.g_diag_type_d) OR ed2.rn = 1)
                 ORDER BY decode(ed2.flg_type, pk_edis_proc.g_epis_diag_type_definitive, 0, 1) ASC,
                          decode(ed2.flg_final_type,
                                 pk_edis_proc.g_epis_diag_final_type_primary,
                                 0,
                                 pk_edis_proc.g_epis_diag_final_type_sec,
                                 1,
                                 2),
                          decode(ed2.flg_status, pk_edis_proc.g_epis_diag_confirmed, 0, 1) ASC)
         WHERE rownum < 5;
    
        IF l_diags.count > 0
        THEN
            --tem diagnosticos
            o_compl_diag := CASE i_call_type
                                WHEN g_call_header_app THEN
                                 pk_utils.concat_table(l_diags, '; ')
                                WHEN g_call_header_rep THEN
                                 l_diags(1)
                                ELSE
                                 NULL
                            END;
        
            o_title_diag := pk_message.get_message(i_lang, i_prof, l_title_diags(1));
        
        ELSE
            -- fetch previous cancer diagnosis
            IF NOT pk_diagnosis_core.get_pat_prev_cancer_diag(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_id_episode,
                                                              i_patient => pk_episode.get_epis_patient(i_lang,
                                                                                                       i_prof,
                                                                                                       i_id_episode),
                                                              o_diags   => l_diags,
                                                              o_error   => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_diags.count > 0
            THEN
                o_compl_diag := l_diags(1);
                o_title_diag := pk_message.get_message(i_lang, i_prof, l_prev_diagnosis_mess);
            ELSE
            
                -- não tem diagnostico, então procura-se queixa e triagem
                BEGIN
                    g_error        := 'GET EPIS TYPE';
                    l_id_epis_type := pk_episode.get_epis_type(i_lang, i_id_episode);
                
                    /*                   IF l_id_epis_type IN
                       (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_urgent_care)
                    THEN
                        g_error := 'GET EMERGENCY COMPLAINT';*/
                    /*                        IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_episode        => i_id_episode,
                                                               i_epis_docum     => NULL,
                                                               i_flg_only_scope => pk_alert_constant.g_no,
                                                               o_epis_complaint => l_cur_epis_complaint,
                                                               o_error          => l_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        g_error := 'FETCH L_CUR_EPIS_COMPLAINT';
                        FETCH l_cur_epis_complaint
                            INTO l_row_epis_complaint;
                        CLOSE l_cur_epis_complaint;
                    
                        l_desc_anamnesis := pk_complaint.get_epis_complaint_desc(i_lang,
                                                                                 i_prof,
                                                                                 l_row_epis_complaint.desc_complaint,
                                                                                 l_row_epis_complaint.patient_complaint);
                        l_complaint_date := l_row_epis_complaint.dt_register;
                    */
                    IF NOT pk_complaint.get_complaint_header(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_episode        => i_id_episode,
                                                             o_last_complaint => l_desc_anamnesis,
                                                             o_complaints     => l_complaints,
                                                             o_professional   => l_id_professional,
                                                             o_dt_register    => l_complaint_date,
                                                             o_error          => l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    IF l_id_professional IS NOT NULL
                    THEN
                        SELECT nvl(p.nick_name, p.name) || '; ' ||
                               pk_date_utils.date_time_chr_tsz(i_lang, l_complaint_date, i_prof)
                          INTO l_anamnesis_prof
                          FROM professional p
                         WHERE p.id_professional = l_id_professional;
                    END IF;
                    l_title_pain := pk_message.get_message(i_lang, i_prof, l_complaint_mess);
                    /*                    ELSE
                        g_error := 'GET COMPLAINT';
                        SELECT desc_compl,
                               (SELECT nvl(p.nick_name, p.name)
                                  FROM professional p
                                 WHERE t.id_professional = p.id_professional) || '; ' ||
                               pk_date_utils.date_time_chr_tsz(i_lang, t.dt_last, i_prof) prof_desc,
                               dt_last dt_complaint
                          INTO l_desc_anamnesis, l_anamnesis_prof, l_complaint_date
                          FROM (SELECT pk_translation.get_translation(i_lang,
                                                                      'COMPLAINT.CODE_COMPLAINT.' || ec.id_complaint) ||
                                       nvl2(ec.patient_complaint, ' (' || ec.patient_complaint || ')', '') desc_compl,
                                       ec.adw_last_update_tstz dt_last,
                                       id_professional
                                  FROM epis_complaint ec
                                 WHERE ec.id_episode = i_id_episode
                                   AND ec.flg_status = pk_edis_proc.g_epis_complaint_active
                                UNION ALL
                                SELECT pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_compl,
                                       ea.dt_epis_anamnesis_tstz dt_last,
                                       id_professional
                                  FROM epis_anamnesis ea
                                 WHERE ea.id_episode = i_id_episode
                                   AND ea.flg_type = pk_edis_proc.g_epis_anam_type_complaint
                                   AND ea.flg_status = pk_edis_proc.g_epis_anam_status_active
                                      --Sofia Mendes: ALERT-73924: only the definitive registries should appear on header
                                   AND ea.flg_temp = pk_clinical_info.g_flg_def
                                --
                                 ORDER BY dt_last DESC) t
                         WHERE rownum < 2;
                    
                        l_title_pain := pk_message.get_message(i_lang, i_prof, l_reason_for_visit_mess);
                    END IF;*/
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
                -- Triagem
                g_error                     := 'GET TRIAGE CONFIGURATION: FLG_TRIAGE_RES_GRIDS';
                l_conf_flg_triage_res_grids := pk_edis_triage.get_triage_config_by_name(i_lang        => i_lang,
                                                                                        i_prof        => i_prof,
                                                                                        i_episode     => i_id_episode,
                                                                                        i_triage_type => NULL,
                                                                                        i_config      => l_column_flg_triage_res_grids);
                IF l_conf_flg_triage_res_grids = pk_alert_constant.g_yes
                THEN
                    BEGIN
                        g_error := 'GET TRIAGE';
                        SELECT nvl2(e.id_triage_white_reason, -- if white reason exists show it
                                    pk_translation.get_translation(i_lang,
                                                                   'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                                   e.id_triage_white_reason) || ': ' || e.notes,
                                    nvl2(e.id_triage, -- if a single id_triage exists use it
                                         pk_edis_triage.get_board_label(i_lang,
                                                                        i_prof,
                                                                        t.id_triage_board,
                                                                        td.id_triage_decision_point,
                                                                        t.id_triage_type),
                                         -- if no single id_triage exists use id_triage_board in edis_triage
                                         pk_edis_triage.get_board_label(i_lang, i_prof, e.id_triage_board, NULL, NULL))) desc_triage,
                               (SELECT nvl(p.nick_name, p.name)
                                  FROM professional p
                                 WHERE e.id_professional = p.id_professional) || '; ' ||
                               pk_date_utils.date_time_chr_tsz(i_lang, e.dt_end_tstz, i_prof) triage_prof,
                               e.dt_end_tstz triage_date
                          INTO l_desc_triage, l_triage_prof, l_triage_date
                          FROM (SELECT etr.id_triage,
                                       etr.id_triage_white_reason,
                                       etr.id_professional,
                                       etr.dt_end_tstz,
                                       etr.notes,
                                       etr.flg_selected_option,
                                       etr.id_epis_triage,
                                       etr.id_triage_board
                                  FROM epis_triage etr
                                 WHERE etr.id_episode = i_id_episode
                                 ORDER BY etr.dt_begin_tstz DESC) e
                          LEFT JOIN triage t
                            ON e.id_triage = t.id_triage
                          LEFT JOIN triage_discriminator td
                            ON td.id_triage_discriminator = t.id_triage_discriminator
                         WHERE rownum < 2;
                    
                        l_title_triage := pk_message.get_message(i_lang, i_prof, l_flowchart_mess);
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                END IF;
            END IF;
        END IF;
    
        -- inpatient report header doesnt show the complaint
        IF o_compl_diag IS NULL
           AND (i_call_type = g_call_header_app OR l_id_epis_type <> pk_alert_constant.g_epis_type_inpatient)
        THEN
            l_config_record_date_order := pk_sysconfig.get_config('TRIAGE_COMPLAINT_RECORD_DATE_ORDER',
                                                                  i_prof.institution,
                                                                  i_prof.software);
        
            IF l_config_record_date_order = pk_alert_constant.g_yes
            THEN
                -- if configured to show most recent record, give priority to it whether it is a triage or complaint info
                IF (l_desc_triage IS NULL OR l_triage_date < l_complaint_date)
                   AND l_desc_anamnesis IS NOT NULL
                THEN
                    o_compl_pain := l_desc_anamnesis;
                    o_info_adic  := '(' || l_anamnesis_prof || ' ' || pk_message.get_message(i_lang, 'EDIS_IDENT_T001') || ')';
                    o_title_pain := l_title_pain;
                ELSIF l_desc_triage IS NOT NULL
                THEN
                    o_compl_pain := l_desc_triage;
                    o_info_adic  := '(' || l_triage_prof || ' ' || pk_message.get_message(i_lang, 'EDIS_IDENT_T001') || ')';
                    o_title_pain := l_title_triage;
                END IF;
            ELSE
            
                IF (i_call_type = g_call_header_app OR l_id_epis_type <> pk_alert_constant.g_epis_type_inpatient)
                THEN
                
                    l_config_show_triage_info := pk_sysconfig.get_config('SHOW_TRIAGE_INFO_IN_HEADER',
                                                                         i_prof.institution,
                                                                         i_prof.software);
                    IF l_desc_triage IS NOT NULL
                       AND l_config_show_triage_info = pk_alert_constant.g_yes
                    THEN
                        o_compl_pain := l_desc_triage;
                        o_info_adic  := '(' || l_triage_prof || ' ' ||
                                        pk_message.get_message(i_lang, 'EDIS_IDENT_T001') || ')';
                        o_title_pain := l_title_triage;
                    ELSIF l_desc_anamnesis IS NOT NULL
                    THEN
                        o_compl_pain := l_desc_anamnesis;
                        o_info_adic  := '(' || l_anamnesis_prof || ' ' ||
                                        pk_message.get_message(i_lang, 'EDIS_IDENT_T001') || ')';
                        o_title_pain := l_title_pain;
                    END IF;
                END IF;
            END IF;
        END IF;
    END;

    /**
    * Returns the patient process.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_pat_identifier    Patient Identifier
    *
    * @return                       The patient process
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_process
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_pat_identifier IN pat_identifier.id_pat_identifier%TYPE,
        i_id_episode        IN episode.id_episode%TYPE DEFAULT NULL
    ) RETURN VARCHAR IS
        l_process_number pat_identifier.alert_process_number%TYPE;
        l_institution    episode.id_institution%TYPE;
    BEGIN
        BEGIN
            SELECT pi.alert_process_number
              INTO l_process_number
              FROM pat_identifier pi
             WHERE i_id_pat_identifier IS NOT NULL
               AND pi.id_pat_identifier = i_id_pat_identifier;
        EXCEPTION
            WHEN no_data_found THEN
                BEGIN
                    IF i_id_episode IS NOT NULL
                    THEN
                        l_institution := pk_episode.get_epis_institution_id(i_lang       => i_lang,
                                                                            i_prof       => i_prof,
                                                                            i_id_episode => i_id_episode);
                    ELSE
                        l_institution := i_prof.institution;
                    END IF;
                    SELECT num_clin_record
                      INTO l_process_number
                      FROM (SELECT crn.*
                              FROM clin_record crn
                             WHERE crn.id_patient = i_id_patient
                               AND crn.flg_status = pk_alert_constant.g_active
                             ORDER BY decode(crn.id_institution, l_institution, 1, 0) DESC)
                     WHERE rownum < 2;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
        END;
        RETURN nvl(l_process_number, '---');
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '---';
    END;

    /**
    * Returns the room time.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_epis_row             Episode table row
    *
    * @return                       The room time
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_room_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_row IN episode%ROWTYPE
    ) RETURN VARCHAR IS
        l_room_time VARCHAR2(1000);
    BEGIN
        SELECT pk_edis_proc.get_los_duration(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_epis_row.id_episode,
                                             i_dt_begin   => (SELECT MAX(m.dt_end_tstz)
                                                                FROM movement m
                                                               WHERE m.id_episode = i_epis_row.id_episode
                                                                 AND m.flg_status != pk_edis_proc.g_cancelled),
                                             i_dt_end     => i_epis_row.dt_end_tstz)
          INTO l_room_time
          FROM dual;
        RETURN l_room_time;
    END;

    /**
    * Returns disposition, transfer or reopen if applied.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       Disposition, transfer or reopen if applied
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_disp_transf_reopen
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_origin           sys_message.desc_message%TYPE;
        l_epis_type        epis_type.id_epis_type%TYPE;
        l_type_disch       VARCHAR2(1 CHAR);
        l_exists_discharge VARCHAR2(1 CHAR);
        l_error            t_error_out;
    
        CURSOR c_disch IS
            SELECT d.flg_status,
                   d.flg_type_disch,
                   pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz) dt_admin
            
              FROM discharge d
             WHERE d.id_episode = i_id_episode
               AND d.flg_status IN (pk_edis_proc.g_discharge_flg_status_pend,
                                    pk_edis_proc.g_discharge_flg_status_reopen,
                                    pk_edis_proc.g_discharge_flg_status_active)
             ORDER BY d.id_discharge DESC;
    
        l_disch                   c_disch%ROWTYPE;
        l_epis_out_on_pass_active VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'OPEN c_disch';
        OPEN c_disch;
        FETCH c_disch
            INTO l_disch;
        CLOSE c_disch;
    
        IF NOT pk_discharge.check_exists_disch_type(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_episode     => i_id_episode,
                                                    i_flg_type    => NULL,
                                                    o_exist_disch => l_exists_discharge,
                                                    o_type        => l_type_disch,
                                                    o_error       => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_disch.flg_status = pk_edis_proc.g_discharge_flg_status_pend
        THEN
            -- discharge is pending
            IF i_prof.software = pk_edis_proc.g_soft_triage
               AND l_disch.flg_type_disch = pk_edis_proc.g_discharge_disch_type_triage
            THEN
                l_origin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'HEADER_M016');
            ELSE
                IF l_type_disch = pk_disposition.g_disp_adms
                THEN
                    l_origin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'HEADER_M029');
                ELSE
                    l_origin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'HEADER_M015');
                END IF;
            END IF;
        ELSIF l_disch.flg_status = pk_edis_proc.g_discharge_flg_status_reopen
        THEN
            -- discharge is reopened
            l_origin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'HEADER_M011');
        ELSIF l_disch.flg_status = pk_edis_proc.g_discharge_flg_status_active
        THEN
            -- discharge is active
            IF l_disch.dt_admin IS NOT NULL
            THEN
                IF l_type_disch = pk_disposition.g_disp_adms
                THEN
                    l_origin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'HEADER_M030');
                ELSE
                    l_origin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'HEADER_M022');
                END IF;
            ELSE
                l_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_id_episode);
            
                IF l_epis_type = pk_alert_constant.g_epis_type_social
                THEN
                    l_origin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'HEADER_M023');
                ELSIF l_epis_type = pk_alert_constant.g_epis_type_dietitian
                THEN
                    l_origin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'HEADER_M024');
                ELSE
                    IF l_type_disch = pk_disposition.g_disp_adms
                    THEN
                        l_origin := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'HEADER_M029');
                    ELSE
                        l_origin := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'HEADER_M010');
                    END IF;
                END IF;
            END IF;
        ELSIF l_disch.flg_status IS NULL
        THEN
            -- no discharge exists!
            IF pk_ubu.get_episode_transportation(i_id_episode, i_prof) IS NOT NULL
            THEN
                l_origin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'HEADER_M009');
            ELSE
                -- Se tiver origem noutra instituição mostra senão mostra estado da alta se a tiver
                l_origin := pk_transfer_institution.get_inst_transfer_message(i_lang, i_prof, i_id_episode);
                IF l_origin IS NULL
                THEN
                    -- When an Out of pass is Ongoing
                    IF pk_epis_out_on_pass.check_epis_out_on_pass_active(i_lang, i_prof, i_id_episode) =
                       pk_alert_constant.g_yes
                    THEN
                        l_origin := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'HEADER_M031');
                    END IF;
                END IF;
            
            END IF;
        END IF;
    
        RETURN l_origin;
    END;

    /**
    * Returns the patient health plan.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          schedule Id
    *
    * @return                       The patient health plan
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_health_plan
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        g_error := 'PK_ADT.GET_HEALTH_PLAN';
        RETURN pk_adt.get_health_plan(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_id_patient => i_id_patient,
                                      i_id_episode => i_id_episode);
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**
    * Returns the 'Servico Nacional de Saude' number.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           episode Id
    * @param i_id_schedule          schedule Id
    *
    * @return                       The 'Servico Nacional de Saude' number
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_sns
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
        l_num_health_plan pat_health_plan.num_health_plan%TYPE;
    
        l_hp_entity VARCHAR2(4000);
        l_hp_desc   VARCHAR2(4000);
        l_error     t_error_out;
        l_retval    BOOLEAN;
        l_mk        market.id_market%TYPE;
        l_val       v_person.social_security_number%TYPE;
        l_desc      sys_message.desc_message%TYPE;
        l_hp_id_hp  pat_health_plan.id_health_plan%TYPE;
    
    BEGIN
        g_error := 'Call pk_utils.get_institution_market / i_id_institution=' || i_prof.institution;
        l_mk    := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        IF l_mk IN (pk_alert_constant.g_id_market_mx, pk_alert_constant.g_id_market_cl)
           AND i_prof.software = pk_alert_constant.g_soft_referral
        THEN
            IF l_mk = pk_alert_constant.g_id_market_mx
            THEN
                l_desc := pk_message.get_message(i_lang, 'ID_PATIENT_SOCIALSECURITYNUMBER');
            ELSE
                l_desc := pk_message.get_message(i_lang, 'ID_PATIENT_RUN');
            END IF;
        
            SELECT decode(l_mk, pk_alert_constant.g_id_market_mx, per.social_security_number, per.run_number)
              INTO l_val
              FROM v_patient pat
              JOIN v_person per
                ON (pat.id_person = per.id_person)
             WHERE pat.id_patient = i_id_patient;
        
            IF l_val IS NOT NULL
            THEN
                RETURN l_desc || ' - ' || l_val;
            END IF;
        
        ELSE
        
            g_error  := 'Call pk_adt.get_national_health_number / i_id_patient=' || i_id_patient;
            l_retval := pk_adt.get_national_health_number(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_patient      => i_id_patient,
                                                          o_hp_id_hp        => l_hp_id_hp,
                                                          o_num_health_plan => l_num_health_plan,
                                                          o_hp_entity       => l_hp_entity,
                                                          o_hp_desc         => l_hp_desc,
                                                          o_error           => l_error);
        
            IF l_retval
               AND l_num_health_plan IS NOT NULL
            THEN
                RETURN l_num_health_plan || ' - ' || l_hp_entity || ' - ' || l_hp_desc;
            ELSE
                RETURN NULL;
            END IF;
        END IF;
    
        RETURN NULL;
    END;

    /**
    * Returns the RECM and 'No allergies to drugs'.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The RECM and 'No allergies to drugs'
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_recm_no_allergies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
        l_ret   pk_translation.t_desc_translation;
        l_recm  pk_translation.t_desc_translation;
        l_error t_error_out;
    BEGIN
        g_error := 'GET NKDA TEXT';
        IF NOT pk_episode.get_nkda_label(i_lang, i_prof, i_id_patient, l_ret, l_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        g_error := 'OPEN C_PAT_RECM';
        BEGIN
            SELECT flg_recm
              INTO l_recm
              FROM (SELECT r.flg_recm, vpr.expiration_date
                      FROM v_pat_recm vpr
                      LEFT JOIN recm r
                        ON r.id_recm = vpr.id_recm
                     WHERE vpr.id_patient = i_id_patient
                     ORDER BY 2 DESC)
             WHERE rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_ret IS NULL
           AND l_recm IS NOT NULL
        THEN
            l_ret := pk_message.get_message(i_lang, 'IDENT_PATIENT_T023') || ' - ' || l_recm;
        ELSIF l_ret IS NOT NULL
              AND l_recm IS NOT NULL
        THEN
            l_ret := l_ret || ' / ' || pk_message.get_message(i_lang, 'IDENT_PATIENT_T023') || ' - ' || l_recm;
        END IF;
    
        RETURN l_ret;
    END get_recm_no_allergies;

    /**
    * Returns the category of a professional.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       The category of a professional
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_category
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_instituttion IN institution.id_institution%TYPE
    ) RETURN VARCHAR IS
        l_ret pk_translation.t_desc_translation;
    BEGIN
        SELECT pk_translation.get_translation(i_lang, c.code_category)
          INTO l_ret
          FROM prof_cat pc, category c
         WHERE pc.id_professional = i_id_professional
           AND pc.id_institution = i_id_instituttion
           AND pc.id_category = c.id_category;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**
    * Returns the name of the room.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       The name of the room
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_room_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR IS
        l_ret pk_translation.t_desc_translation;
    BEGIN
        SELECT coalesce(r.desc_room,
                        pk_translation.get_translation_dtchk(i_lang, r.code_room),
                        r.desc_room_abbreviation)
          INTO l_ret
          FROM room r
         WHERE r.id_room = i_id_room;
    
        IF l_ret IS NULL
        THEN
            l_ret := pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION.' || i_id_room);
        END IF;
    
        RETURN nvl(l_ret, '---');
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**
    * Returns the service name.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_dep_clin_serv     Dep_clin_serv Id
    *
    * @return                       The service name
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_service
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR IS
        l_ret pk_translation.t_desc_translation;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, d.code_department)
          INTO l_ret
          FROM dep_clin_serv dcs
          JOIN department d
            ON d.id_department = dcs.id_department
         WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**
    * Returns the clinical service name.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_dep_clin_serv     Dep_clin_serv Id
    *
    * @return                       The clinical service name
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_clin_service
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR IS
        l_ret pk_translation.t_desc_translation;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
          INTO l_ret
          FROM dep_clin_serv dcs
          JOIN clinical_service cs
            ON cs.id_clinical_service = dcs.id_clinical_service
         WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**
    * Returns the service in which the room is.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_room              Room Id
    *
    * @return                       The service in which the room is
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR IS
        l_ret pk_translation.t_desc_translation;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, d.code_department)
          INTO l_ret
          FROM room r
          JOIN department d
            ON d.id_department = r.id_department
         WHERE r.id_room = i_id_room;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**
    * Returns the service in which the bed is.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_bed               Bed Id
    *
    * @return                       The service in which the bed is
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_bed_service
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN VARCHAR IS
        l_ret pk_translation.t_desc_translation;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, d.code_department)
          INTO l_ret
          FROM bed b
          JOIN room r
            ON r.id_room = b.id_room
          JOIN department d
            ON d.id_department = r.id_department
         WHERE b.id_bed = i_id_bed;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**
    * Returns the room in which the bed is.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_bed               Bed Id
    *
    * @return                       The room in which the bed is
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_room_name
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN VARCHAR IS
        l_ret pk_translation.t_desc_translation;
    BEGIN
    
        SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
          INTO l_ret
          FROM bed b
          JOIN room r
            ON r.id_room = b.id_room
         WHERE b.id_bed = i_id_bed;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            IF i_prof.software = pk_edis_proc.g_soft_inp
            THEN
                RETURN NULL;
            ELSE
                RETURN '---';
            END IF;
    END;

    /**
    * Returns the bed name.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_bed               Bed Id
    *
    * @return                       The bed name
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_bed_name
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN VARCHAR IS
        l_ret pk_translation.t_desc_translation;
    BEGIN
    
        SELECT nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed))
          INTO l_ret
          FROM bed b
         WHERE b.id_bed = i_id_bed;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**
    * Returns the disposition date and label.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_row_ei               EPIS_INFO row_type
    * 
    * @param o_disp_date            Disposition date
    * @param o_disp_label           Disposition label
    *
    * @return                       The disposition date and label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE get_disposition_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_row_ei     IN epis_info%ROWTYPE,
        o_disp_date  OUT VARCHAR2,
        o_disp_label OUT VARCHAR2
    ) IS
        l_error          t_error_out;
        l_disp_date_tstz epis_info.dt_med_tstz%TYPE;
    BEGIN
        g_error := 'CALL PK_DISCHARGE.GET_INP_DISPOSITION_DATE';
        IF NOT pk_api_inpatient.get_inp_disposition_date(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_row_ei         => i_row_ei,
                                                         o_disp_date      => o_disp_date,
                                                         o_disp_date_tstz => l_disp_date_tstz,
                                                         o_disp_label     => o_disp_label,
                                                         o_error          => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
    END get_disposition_date;

    /**
    * Returns the appointment type.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_row_ei               EPIS_INFO row_type
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The appointment type
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_appointment_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_row_ei      IN epis_info%ROWTYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
        l_ret              pk_translation.t_desc_translation;
        l_desc_event       pk_translation.t_desc_translation;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
        BEGIN
            SELECT pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event),
                   s.id_dcs_requested
              INTO l_desc_event, l_id_dep_clin_serv
              FROM schedule s
              LEFT JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
             WHERE s.id_schedule = nvl(i_id_schedule, i_row_ei.id_schedule);
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_desc_event IS NOT NULL
        THEN
            l_desc_event := l_desc_event || ': ';
        END IF;
    
        l_ret := l_desc_event || get_clin_service(i_lang, i_prof, nvl(i_row_ei.id_dep_clin_serv, l_id_dep_clin_serv));
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**
    * Returns the date in the correct format.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_dt                   Date
    *
    * @return                       The date in the correct format
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_format_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_dt   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR IS
    BEGIN
        --
        RETURN nvl(pk_date_utils.to_char_insttimezone(i_lang,
                                                      i_prof,
                                                      i_dt,
                                                      REPLACE(pk_message.get_message(i_lang, i_prof, 'DATE_FORMAT_M008'),
                                                              ' ',
                                                              '"')),
                   '---');
    END;

    /**
    * Returns the waiting time.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_dt_target            Target date
    * @param i_dt_register          Register date
    * @param i_dt_first             First observation date
    *
    * @return                       The waiting time
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_waiting
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_target   IN schedule_outp.dt_target_tstz%TYPE,
        i_dt_register IN episode.dt_begin_tstz%TYPE,
        i_dt_first    IN epis_info.dt_first_obs_tstz%TYPE
    ) RETURN VARCHAR IS
        l_t1 VARCHAR2(100);
        l_t2 VARCHAR2(100);
    BEGIN
        IF i_dt_first IS NULL
           OR i_dt_target IS NULL
        THEN
            l_t1 := '---';
        ELSE
            l_t1 := pk_date_utils.get_elapsed_tsz(i_lang, i_dt_first, i_dt_target);
        END IF;
        IF i_dt_first IS NULL
           OR i_dt_register IS NULL
        THEN
            l_t2 := '---';
        ELSE
            l_t2 := pk_date_utils.get_elapsed_tsz(i_lang, i_dt_first, i_dt_register);
        END IF;
        RETURN l_t1 || ' / ' || l_t2;
    END;

    /**
    * Returns the surgery responsible professional and specialty.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @param o_prof                 The surgery responsible professional
    * @param o_prof                 The surgery responsible professional specialty
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE get_surg_resp_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_prof           OUT VARCHAR2,
        o_prof_spec_inst OUT VARCHAR2
    ) IS
    
        l_exist_principal VARCHAR2(1);
    
    BEGIN
        BEGIN
            SELECT pk_sr_tools.get_team_profissional(i_lang, i_prof, td.id_episode) prof_name,
                   ' (' || pk_translation.get_translation(i_lang, s.code_speciality) || '; ' || i.abbreviation || ')' prof_spec
              INTO o_prof, o_prof_spec_inst
              FROM professional p, sr_prof_team_det td, speciality s, schedule_sr sc, institution i, sr_epis_interv sei
             WHERE sc.id_episode = i_id_episode
               AND td.id_episode = sc.id_episode
               AND td.id_category_sub = pk_sr_grid.g_catg_surg_resp
               AND td.flg_status != pk_sr_grid.g_cancel
               AND p.id_professional = td.id_professional
               AND s.id_speciality(+) = p.id_speciality
               AND i.id_institution = sc.id_institution
               AND td.id_sr_epis_interv = sei.id_sr_epis_interv
               AND sei.flg_type = 'P'
               AND sei.id_episode = sc.id_episode
               AND rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                l_exist_principal := 'N';
            
        END;
    
        IF l_exist_principal = 'N'
        THEN
            o_prof           := pk_sr_tools.get_team_profissional(i_lang, i_prof, i_id_episode);
            o_prof_spec_inst := NULL;
        
            IF o_prof IS NULL
            THEN
                BEGIN
                    SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional)
                      INTO o_prof
                      FROM sch_resource sr
                      JOIN schedule_sr ss
                        ON ss.id_schedule = sr.id_schedule
                     WHERE ss.id_episode = i_id_episode
                       AND (sr.flg_leader = pk_alert_constant.g_yes OR sr.flg_leader IS NULL);
                EXCEPTION
                    WHEN no_data_found THEN
                        o_prof := NULL;
                END;
            END IF;
        END IF;
    
    END;

    -- Function taken from PK_TRIAGE_AUDIT
    /**
    * Returns the episode complaint.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_episode              Episode Id
    *
    * @param o_title_epis_compl     Title of episode complaint
    * @param o_epis_compl           Episode complaint
    * @param o_error                Error message
    *
    * @return                       True if succeeded. False otherwise. 
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_epis_compl
    (
        i_lang             language.id_language%TYPE,
        i_prof             profissional,
        i_episode          episode.id_episode%TYPE,
        o_title_epis_compl OUT VARCHAR2,
        o_epis_compl       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cur_epis_complaint pk_complaint.epis_complaint_cur;
        l_row_epis_complaint pk_complaint.epis_complaint_rec;
    
    BEGIN
        BEGIN
            g_error := 'GET DIAG';
            SELECT t.desc_diagnosis
              INTO o_epis_compl
              FROM (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis
                      FROM diagnosis d, epis_diagnosis ed, alert_diagnosis ad
                     WHERE ed.id_episode = i_episode
                       AND ed.id_diagnosis = d.id_diagnosis
                       AND ed.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND ed.flg_type = 'P'
                       AND ed.flg_status IN ('F', 'D')
                     ORDER BY ed.dt_epis_diagnosis_tstz, ed.dt_confirmed_tstz DESC) t
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF o_epis_compl IS NOT NULL
        THEN
            o_title_epis_compl := pk_message.get_message(i_lang, 'DIAGNOSIS_FINAL_T023');
        ELSE
            o_title_epis_compl := pk_message.get_message(i_lang, 'TRIAGE_T002');
        
            g_error := 'GET EMERGENCY COMPLAINT';
            IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => i_episode,
                                                   i_epis_docum     => NULL,
                                                   i_flg_only_scope => pk_alert_constant.g_no,
                                                   o_epis_complaint => l_cur_epis_complaint,
                                                   o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'FETCH L_CUR_EPIS_COMPLAINT';
            FETCH l_cur_epis_complaint
                INTO l_row_epis_complaint;
            CLOSE l_cur_epis_complaint;
        
            o_epis_compl := pk_complaint.get_epis_complaint_desc(i_lang,
                                                                 i_prof,
                                                                 l_row_epis_complaint.desc_complaint,
                                                                 l_row_epis_complaint.patient_complaint);
        
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
                                              'GET_EPIS_COMPL',
                                              o_error);
            RETURN FALSE;
    END get_epis_compl;

    /**
    * Returns the professional photo timestamp.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    *
    * @return                       The professional photo timestamp
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/05/06
    */
    FUNCTION get_photo_timestamp
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR IS
        l_timestamp VARCHAR(50);
    BEGIN
        IF pk_profphoto.check_blob(i_id_professional) = 'N'
        THEN
            RETURN '';
        ELSE
            SELECT pk_date_utils.date_send_tsz(i_lang, pp.dt_photo_tstz, i_prof)
              INTO l_timestamp
              FROM prof_photo pp
             WHERE pp.id_professional = i_id_professional;
            RETURN l_timestamp;
        END IF;
    END;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
