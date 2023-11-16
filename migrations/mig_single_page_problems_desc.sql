-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 28/Aug/2013 
-- CHANGE REASON: ALERT-260486 Past history registration disappeared 
DECLARE
    l_prof           profissional;
    l_problem_desc   CLOB;
    l_problem_status sys_domain.desc_val%TYPE;
    l_problem_notes  pat_history_diagnosis.notes%TYPE;

    l_problem_text CLOB;
    l_update       PLS_INTEGER := 1;
BEGIN
    FOR rec IN (SELECT epdt.pn_note,
                       epn.id_prof_create id_professional,
                       e.id_institution,
                       ei.id_software,
                       il.id_language,
                       epdt.id_task,
                       epdt.id_epis_pn_det_task,
                       epn.id_episode,
                       e.id_epis_type
                  FROM epis_pn_det_task epdt
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn_det = epdt.id_epis_pn_det
                  JOIN epis_pn epn
                    ON epn.id_epis_pn = epd.id_epis_pn
                 INNER JOIN episode e
                    ON epn.id_episode = e.id_episode
                 INNER JOIN epis_info ei
                    ON e.id_episode = ei.id_episode
                 INNER JOIN institution i
                    ON e.id_institution = i.id_institution
                 INNER JOIN institution_language il
                    ON i.id_institution = il.id_institution
                 WHERE epdt.id_task_type = 18
                   AND epn.id_pn_note_type IN (9, 16)
                )
    LOOP
        IF (rec.id_language IS NOT NULL AND rec.id_professional IS NOT NULL AND rec.id_institution IS NOT NULL AND
           rec.id_software IS NOT NULL)
        THEN
            l_prof := profissional(rec.id_professional, rec.id_institution, rec.id_software);
        
            BEGIN
                SELECT decode(phd.desc_pat_history_diagnosis,
                              NULL,
                              pk_diagnosis.std_diag_desc(i_lang               => rec.id_language,
                                                         i_prof               => l_prof,
                                                         i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                         i_id_diagnosis       => d.id_diagnosis,
                                                         i_id_task_type       => pk_alert_constant.g_task_problems,
                                                         i_code               => d.code_icd,
                                                         i_flg_other          => d.flg_other,
                                                         i_flg_std_diag       => ad.flg_icd9) ||
                              REPLACE(' (' || pk_sysdomain.get_domain(pk_problems.g_pat_problem_protocol,
                                                                      d.flg_type,
                                                                      rec.id_language) || ')',
                                      ' ()',
                                      ''),
                              decode(phd.id_alert_diagnosis,
                                     NULL,
                                     phd.desc_pat_history_diagnosis,
                                     phd.desc_pat_history_diagnosis || ' - ' ||
                                     pk_diagnosis.std_diag_desc(i_lang               => rec.id_language,
                                                                i_prof               => l_prof,
                                                                i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                i_id_diagnosis       => d.id_diagnosis,
                                                                i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                i_code               => d.code_icd,
                                                                i_flg_other          => d.flg_other,
                                                                i_flg_std_diag       => ad.flg_icd9) ||
                                     REPLACE(' (' || pk_sysdomain.get_domain(pk_problems.g_pat_problem_protocol,
                                                                             d.flg_type,
                                                                             rec.id_language) || ')',
                                             ' ()',
                                             ''))) || ', ' ||
                   pk_problems.get_problem_type_desc(i_lang               => rec.id_language,
                                         i_prof               => l_prof,
                                         i_flg_area           => phd.flg_area,
                                         i_id_alert_diagnosis => phd.id_alert_diagnosis) desc_probl,
                       pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, rec.id_language) desc_status,
                       decode(phd.flg_status, 'C', phd.cancel_notes, phd.notes) prob_notes
                  INTO l_problem_desc, l_problem_status, l_problem_notes
                  FROM pat_history_diagnosis phd
                  LEFT JOIN diagnosis d
                    ON phd.id_diagnosis = d.id_diagnosis
                  LEFT JOIN alert_diagnosis ad
                    ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                 WHERE phd.id_pat_history_diagnosis = rec.id_task;
            EXCEPTION
                WHEN OTHERS THEN
                    dbms_output.put_line('id_task: ' || rec.id_task || ' id_epis_pn_det_task: ' ||
                                         rec.id_epis_pn_det_task);
                    l_update := 0;
            END;
        
            IF (l_update = 1)
            THEN
                l_problem_text := l_problem_desc || ', ' || l_problem_status;
            
                IF l_problem_notes IS NOT NULL
                THEN
                    l_problem_text := l_problem_text || ', ' || l_problem_notes;
                END IF;
            
                IF (dbms_lob.compare(rec.pn_note, l_problem_text) <> 0)
                THEN
                    IF (l_problem_text IS NOT NULL)
                    THEN
                      --dbms_output.put_line('id_episode: ' || rec.id_episode || ' ' || rec.id_epis_type || ' ' || rec.id_institution);
                        UPDATE epis_pn_det_task epdt
                           SET epdt.pn_note = l_problem_text
                         WHERE epdt.id_epis_pn_det_task = rec.id_epis_pn_det_task;
                    END IF;
                END IF;
            END IF;
        END IF;
        l_update := 1;
    END LOOP;

END;
/
-- CHANGE END: Sofia Mendes
