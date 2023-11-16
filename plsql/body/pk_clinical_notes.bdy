/*-- Last Change Revision: $Rev: 2026877 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_clinical_notes IS

    /*
    *   WRITES MEDICAL NOTES for diagnosis ( DIARIES )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EPISODE               ID OF EPISODE
    * @param   I_ID_diagnosis             ID OF DIAGNOSIS
    * @param   I_FLG_STATUS               STATUS OF DIAGNOSIS
    * @param   I_SPECIFIC_NOTES           SPECIFIC NOTES REGISTERED WITH DIAGNOSIS
    * @param   I_GENERAL_NOTES            ENERAL NOTES FOR REGISTERED DIAGNOSIS
    * @param   I_ID_ALERT_DIAG            Id of alert_diagnosis (ALERT-736: diagnosis synonyms support)
    * @param   I_EPIS_DIAG_FLG_TYPE       Type of association between episode and diagnose (Final or Differential)
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   20-JUL-2007
    *
    */
    FUNCTION set_diagnosis_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_diagnosis       diagnosis.id_diagnosis%TYPE,
        i_flg_status         epis_diagnosis.flg_status%TYPE,
        i_specific_notes     epis_diagnosis.notes%TYPE,
        i_general_notes      epis_diagnosis_notes.notes%TYPE,
        i_id_alert_diag      epis_diagnosis.id_alert_diagnosis%TYPE,
        i_epis_diag_flg_type IN epis_diagnosis.flg_type%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diag_desc           pk_translation.t_desc_translation;
        l_diag_flg_status     sys_domain.desc_val%TYPE;
        l_diag_spc_notes      epis_diagnosis.notes%TYPE;
        l_diag_gen_notes      epis_diagnosis_notes.notes%TYPE;
        l_code_group_desc     VARCHAR2(4000);
        l_epis_diag_type_desc VARCHAR2(200);
        l_epis_type           epis_type.id_epis_type%TYPE;
    BEGIN
    
        g_error := 'GET EPIS TYPE';
        SELECT ep.id_epis_type
          INTO l_epis_type
          FROM episode ep
         WHERE ep.id_episode = i_id_episode;
    
        IF l_epis_type != pk_alert_constant.g_epis_type_inpatient
        THEN
            RETURN TRUE;
            --Only INP episodes are to be inserted.
        END IF;
    
        g_error := 'CALL TO GET_NOTES_FORMAT';
        IF NOT get_notes_format(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_notes_code => g_dgn_session,
                                o_format     => l_code_group_desc,
                                o_error      => o_error)
        THEN
        
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN c_habit_info';
        -- ALERT-736: diagnosis synonyms support
        SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                          i_id_diagnosis       => d.id_diagnosis,
                                          i_code               => d.code_icd,
                                          i_flg_other          => d.flg_other,
                                          i_flg_std_diag       => ad.flg_icd9)
          INTO l_diag_desc
          FROM diagnosis d
          LEFT JOIN alert_diagnosis ad
            ON ad.id_diagnosis = d.id_diagnosis
           AND ad.id_alert_diagnosis = i_id_alert_diag
         WHERE d.id_diagnosis = i_id_diagnosis;
    
        l_diag_flg_status := pk_sysdomain.get_domain('EPIS_DIAGNOSIS.FLG_STATUS', i_flg_status, i_lang);
        l_diag_spc_notes  := i_specific_notes;
        l_diag_gen_notes  := i_general_notes;
    
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@1', newsub => l_diag_desc);
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@2', newsub => l_diag_flg_status);
    
        -- [ALERT-34077] LMAIA 09-07-2009
        -- Diagnosis type is show in diary information
        l_epis_diag_type_desc := pk_sysdomain.get_domain('EPIS_DIAGNOSIS.FLG_TYPE', i_epis_diag_flg_type, i_lang);
        l_epis_diag_type_desc := l_epis_diag_type_desc || ' - ';
        l_code_group_desc     := REPLACE(srcstr => l_code_group_desc, oldsub => '@5', newsub => l_epis_diag_type_desc);
        -- END
    
        IF l_diag_spc_notes IS NOT NULL
           OR l_diag_spc_notes <> g_empty_space --Because FLASH screen puts an space by default in this field
        THEN
            l_diag_spc_notes := chr(32) || '-' || chr(32) || l_diag_spc_notes;
        END IF;
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@3', newsub => l_diag_spc_notes);
    
        IF l_diag_gen_notes IS NOT NULL
           OR l_diag_gen_notes <> g_empty_space
        THEN
            l_diag_gen_notes := chr(32) || '-' || chr(32) || l_diag_gen_notes;
        END IF;
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@4', newsub => l_diag_gen_notes);
    
        g_error := 'CALL SET_CLINICAL_NOTES_FOR_VISIT';
        IF NOT set_clinical_notes_for_visit(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_id_episode,
                                            i_notes_code => g_dgn_session,
                                            i_desc       => l_code_group_desc,
                                            o_error      => o_error)
        THEN
        
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DIAGNOSIS_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_diagnosis_notes;

    /*
    *   WRITES MEDICAL NOTES TO EPIS_RECOMEND ( DIARIES )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EPISODE               ID OF EPISODE
    * @param   I_ID_HABIT                 ID OF HABIT
    * @param   I_FLG_STATUS               STATUS OF HABIT
    * @param   I_FLG_NATURE               NATURE OF HABIT
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION set_habit_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_habit   habit.id_habit%TYPE,
        i_flg_status pat_problem.flg_status%TYPE,
        i_flg_nature pat_problem.flg_nature%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_habit_name       pk_translation.t_desc_translation;
        l_habit_flg_source sys_domain.desc_val%TYPE;
        l_habit_flg_status sys_domain.desc_val%TYPE;
        l_habit_flg_nature sys_domain.desc_val%TYPE;
        l_code_group_desc  VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'CALL TO GET_NOTES_FORMAT';
        IF NOT get_notes_format(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_notes_code => g_hbt_session,
                                o_format     => l_code_group_desc,
                                o_error      => o_error)
        THEN
        
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN c_habit_info';
        SELECT pk_translation.get_translation(i_lang, code_habit)
          INTO l_habit_name
          FROM habit
         WHERE id_habit = i_id_habit;
        l_habit_flg_source := pk_sysdomain.get_domain('PATIENT_PROBLEM.FLG_SOURCE', 'H', i_lang);
        l_habit_flg_status := pk_sysdomain.get_domain('PAT_HABIT.FLG_STATUS', i_flg_status, i_lang);
        IF i_flg_nature IS NULL
        THEN
            l_habit_flg_nature := NULL;
        ELSE
            l_habit_flg_nature := pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', i_flg_nature, i_lang) || ',';
        END IF;
    
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@1', newsub => l_habit_name);
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@2', newsub => l_habit_flg_source);
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@3', newsub => l_habit_flg_nature);
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@4', newsub => l_habit_flg_status);
    
        g_error := 'CALL SET_CLINICAL_NOTES_FOR_VISIT';
        IF NOT set_clinical_notes_for_visit(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_id_episode,
                                            i_notes_code => g_hbt_session,
                                            i_desc       => l_code_group_desc,
                                            o_error      => o_error)
        THEN
        
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_HABIT_NOTES',
                                              o_error);
        
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END set_habit_notes;

    /*
    *   WRITES MEDICAL NOTES TO EPIS_RECOMEND ( DIARIES )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EPISODE               ID OF EPISODE
    * @param   I_ID_ALLERGY               ID OF ALLERGY
    * @param   I_ID_PAT_ALLERGY           Patient Allergy identifier
    * @param   I_FLG_STATUS               STATUS OF ALLERGY
    * @param   I_FLG_NATURE               NATURE OF ALLERGY
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Maia
    * @version 1.0
    * @since   20-DEC-2007
    *
    */
    FUNCTION set_allergy_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_allergy     allergy.id_allergy%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_flg_status     pat_allergy.flg_status%TYPE,
        i_flg_nature     pat_allergy.flg_nature%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_allergy_name       pk_translation.t_desc_translation;
        l_allergy_flg_source sys_domain.desc_val%TYPE;
        l_allergy_flg_status sys_domain.desc_val%TYPE;
        l_allergy_flg_nature sys_domain.desc_val%TYPE;
        l_code_group_desc    VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'CALL TO GET_NOTES_FORMAT';
        IF NOT get_notes_format(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_notes_code => g_alg_session,
                                o_format     => l_code_group_desc,
                                o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN l_allergy_name';
        IF i_id_allergy IS NOT NULL
        THEN
            -- IF exists one defined ALLERGY
            SELECT pk_translation.get_translation(i_lang, code_allergy)
              INTO l_allergy_name
              FROM allergy
             WHERE id_allergy = i_id_allergy;
        ELSE
            -- Otherwise get description of the allergy
            SELECT pa.desc_allergy
              INTO l_allergy_name
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_id_pat_allergy;
        END IF;
    
        l_allergy_flg_source := pk_sysdomain.get_domain('PATIENT_PROBLEM.FLG_SOURCE', 'A', i_lang);
        l_allergy_flg_status := pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', i_flg_status, i_lang);
    
        IF i_flg_nature IS NULL
        THEN
            l_allergy_flg_nature := NULL;
        ELSE
            l_allergy_flg_nature := pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', i_flg_nature, i_lang) || ',';
        END IF;
    
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@1', newsub => l_allergy_name);
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@2', newsub => l_allergy_flg_source);
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@3', newsub => l_allergy_flg_nature);
        l_code_group_desc := REPLACE(srcstr => l_code_group_desc, oldsub => '@4', newsub => l_allergy_flg_status);
    
        g_error := 'CALL SET_CLINICAL_NOTES_FOR_VISIT';
        IF NOT set_clinical_notes_for_visit(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_id_episode,
                                            i_notes_code => g_alg_session,
                                            i_desc       => l_code_group_desc,
                                            o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_allergy_notes;

    /*
    * Get DESCRIPTION O FINTERVENTION
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_interv_presc_det        id of prescribed INTERVENTION
    *
    * @RETURN  string of INTERVENTION prescribed or null if no_data_found, or error msg
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-JUL-2008
    *
    */

    FUNCTION get_itv_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        SELECT pk_procedures_api_db.get_alias_translation(i_lang, i_prof, itv.code_intervention, NULL) xx
          INTO l_return
          FROM interv_presc_det ipd, intervention itv
         WHERE ipd.id_interv_presc_det = i_id_interv_presc_det
           AND ipd.id_intervention = itv.id_intervention;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            l_return := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                        'PK_CLINICAL_NOTES.GET_INTERVENTION_DESC.OTHERS 1/ ' || SQLERRM;
            RETURN l_return;
        
    END get_itv_desc;

    /*
    * Get profile of active professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   o_profile_template         id_profile of professional
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION get_profile_template
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_profile_template OUT profile_template.id_profile_template%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_prf IS
            SELECT ppt.id_profile_template
              FROM prof_profile_template ppt, profile_template prt
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution
               AND prt.id_profile_template = ppt.id_profile_template
               AND prt.id_templ_assoc IS NOT NULL;
    
    BEGIN
    
        o_profile_template := NULL;
    
        FOR prf IN c_prf
        LOOP
            o_profile_template := prf.id_profile_template;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_PROFILE_TEMPLATE',
                                                     o_error);
        
    END get_profile_template;

    /*
    * Get category of active professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   o_category                 category of active professional
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION get_category
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_category OUT category.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cat IS
            SELECT cat.flg_type
              FROM category cat, professional prf, prof_cat prc
             WHERE prf.id_professional = i_prof.id
               AND prc.id_professional = prf.id_professional
               AND prc.id_institution = i_prof.institution
               AND cat.id_category = prc.id_category;
    BEGIN
    
        FOR cat IN c_cat
        LOOP
            o_category := cat.flg_type;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_CATEGORY',
                                                     o_error);
    END get_category;

    /*
    * Checks for empty unfinished sessions. If it finds one, the session is erased.
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   27-DEC-2007
    *
    */
    FUNCTION check_session_integrity
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        err_general_exception EXCEPTION;
        l_ret BOOLEAN;
    
        -- sessions garbage collector
        CURSOR c_prof_session IS
            SELECT er.id_epis_recomend
              FROM epis_recomend er, notes_config nc
             WHERE er.id_professional = i_prof.id
               AND er.id_episode = i_id_episode
               AND er.id_notes_config = nc.id_notes_config
               AND nc.notes_code = g_begin_session
               AND NOT EXISTS (SELECT 0
                      FROM epis_recomend er2
                     WHERE er2.id_professional = i_prof.id
                       AND er2.id_episode = i_id_episode
                       AND er2.session_id = er.session_id
                       AND er2.id_epis_recomend <> er.id_epis_recomend);
    
        l_rows table_varchar := table_varchar();
    BEGIN
    
        g_error := 'DELETE UNUSED SESSIONS';
        pk_alertlog.log_debug(g_error);
        FOR r_prof_session IN c_prof_session
        LOOP
        
            g_error := 'DELETE EPIS_RECOMEND - DEL';
            ts_epis_recomend.del(id_epis_recomend_in => r_prof_session.id_epis_recomend, rows_out => l_rows);
        
            g_error := 't_data_gov_mnt.process_delete ts_epis_recomend';
            t_data_gov_mnt.process_delete(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_RECOMEND',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar());
        END LOOP;
    
        g_error := 'CLOSE PREVIOUS OPENED SESSIONS';
        pk_alertlog.log_debug(g_error);
        l_ret := set_clinical_notes_no_commit(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_episode => i_id_episode,
                                              i_notes_code => g_end_session,
                                              i_desc       => NULL,
                                              i_value      => NULL,
                                              o_error      => o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_general_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_SESSION_INTEGRITY.GENERAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_SESSION_INTEGRITY.OTHERS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_session_integrity;

    /*
    * SAves beginning of session ( can end previous unfinished session )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION set_init_session_no_commit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
    
        /*CURSOR c_bgn(i_flg_type IN epis_recomend.flg_type%TYPE) IS
        SELECT nfg.*
          FROM epis_recomend epr, notes_config nfg
         WHERE epr.id_episode = i_id_episode
           AND epr.id_notes_config = nfg.id_notes_config
           AND epr.id_notes_config = nfg.id_notes_config
           AND nfg.notes_code IN (g_begin_session, g_end_session)
           AND epr.flg_type = i_flg_type
         ORDER BY epr.dt_epis_recomend_tstz DESC, epr.id_epis_recomend DESC;*/
    
        err_general_exception EXCEPTION;
    BEGIN
    
        l_ret := check_session_integrity(i_lang, i_prof, i_id_episode, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        l_ret := set_clinical_notes_no_commit(i_lang, i_prof, i_id_episode, g_begin_session, NULL, NULL, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_general_exception THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_INIT_SESSION_NO_COMMIT.GENERAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_INIT_SESSION_NO_COMMIT.OTHERS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_init_session_no_commit;

    /*
    * SAves beginning of session ( can end previous unfinished session )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION init_session
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
        err_general_exception EXCEPTION;
    BEGIN
    
        l_ret := set_init_session_no_commit(i_lang, i_prof, i_id_episode, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_general_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INIT_SESSION.GENERAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INIT_SESSION.OTHERS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END init_session;

    /*
    * SAves end of session
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION set_end_session_no_commit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
        err_general_exception EXCEPTION;
    BEGIN
    
        l_ret := check_session_integrity(i_lang, i_prof, i_id_episode, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_general_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_END_SESSION_NO_COMMIT.GENERAL',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_END_SESSION_NO_COMMIT.OTHERS',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_end_session_no_commit;

    /*
    * SAves end of session
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION end_session
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
        err_general_exception EXCEPTION;
    
    BEGIN
    
        l_ret := set_end_session_no_commit(i_lang, i_prof, i_id_episode, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_general_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'END_SESSION.GENERAL',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'END_SESSION.OTHERS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END end_session;

    /*
    * set notes of professional based on access granted and profiles
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_notes_code               code to identify which kind of record is being saved.
    * @param   i_desc                     Main description
    * @param   i_valuer                   secondary value
    * @param   i_id_item                  Id item
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION set_clinical_notes_no_commit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes_code IN notes_config.notes_code%TYPE,
        i_desc       IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_value      IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_id_item    IN epis_recomend.id_item%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret                 BOOLEAN;
        l_rec                 epis_recomend%ROWTYPE;
        l_prof_cat            category.flg_type%TYPE;
        l_flg_type            epis_recomend.flg_type%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_software_inp        software.id_software%TYPE;
        l_cat_types           sys_config.value%TYPE;
        r_ncg                 notes_config%ROWTYPE;
    
        CURSOR c_acc
        (
            i_id_notes_config     IN notes_config.id_notes_config%TYPE,
            i_id_profile_template IN profile_template.id_profile_template%TYPE
        ) IS
            SELECT *
              FROM notes_profile_inst
             WHERE id_notes_config = i_id_notes_config
               AND id_profile_template = i_id_profile_template
               AND id_institution IN (i_prof.institution, 0)
               AND flg_available = pk_alert_constant.g_yes
             ORDER BY id_institution DESC;
    
        -- jsilva 27-12-2007 insert register in the open session of the current professional
        CURSOR c_prof_session IS
            SELECT er.session_id
              FROM epis_recomend er
             WHERE er.id_professional = i_prof.id
               AND er.id_episode = i_id_episode
               AND er.session_id IS NOT NULL
               AND NOT EXISTS (SELECT 0
                      FROM epis_recomend er2, notes_config nc
                     WHERE er2.id_professional = i_prof.id
                       AND er2.id_episode = i_id_episode
                       AND er2.session_id = er.session_id
                       AND er2.id_notes_config = nc.id_notes_config
                       AND nc.notes_code = g_end_session);
    
        err_general_exception     EXCEPTION;
        err_permissions_exception EXCEPTION;
        l_write                 notes_profile_inst.flg_write%TYPE;
        l_read                  notes_profile_inst.flg_read%TYPE;
        l_id_notes_profile_inst notes_profile_inst.id_notes_profile_inst%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_write        := g_no;
        l_software_inp := pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof);
        l_cat_types    := pk_sysconfig.get_config('DIARY_WRITE_PERMISSION', i_prof);
    
        SELECT *
          INTO r_ncg
          FROM notes_config
         WHERE notes_code = i_notes_code;
    
        g_error := 'GET CATEGORY';
        pk_alertlog.log_debug(g_error);
        l_ret := get_category(i_lang, i_prof, l_prof_cat, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        IF l_prof_cat = g_cat_nurse
        THEN
            l_flg_type := g_nursing_notes;
        ELSIF l_prof_cat = g_cat_doctor
              OR instr(l_cat_types, l_prof_cat) > 0
        THEN
            l_flg_type := g_medical_notes;
        ELSIF l_prof_cat = g_cat_adm
              OR l_prof_cat = g_cat_nutri
              OR l_prof_cat = g_cat_pharmacist
              OR l_prof_cat = g_cat_technician
              OR l_prof_cat = g_cat_director
              OR l_prof_cat = g_cat_coordinator
              OR l_prof_cat = g_cat_physical
        THEN
            l_flg_type := g_medical_notes;
        ELSE
            l_flg_type := g_medical_notes;
        END IF;
    
        g_error := 'GET profile template';
        pk_alertlog.log_debug(g_error);
        l_ret := get_profile_template(i_lang, i_prof, l_id_profile_template, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        -- LMAIA 06-08-2008
        -- Para garantir que a função é abortada se o profissional não estiver correctamente parametrizado
        IF l_id_profile_template IS NULL
        THEN
            RAISE err_permissions_exception;
        END IF;
    
        -- ************************************************
        g_error := 'INICIALIZE RECORD';
        pk_alertlog.log_debug(g_error);
        l_rec.dt_epis_recomend_tstz := g_sysdate_tstz;
    
        IF nvl(r_ncg.flg_id_item, g_no) = g_yes --i_notes_code IN (g_exam_session, g_analysis_session)
        THEN
        
            IF (i_id_item IS NOT NULL AND i_desc IS NOT NULL)
            THEN
                l_rec.desc_epis_recomend_clob := TRIM(i_desc);
                l_rec.id_item                 := i_id_item;
            ELSIF (i_id_item IS NULL AND i_desc IS NOT NULL)
            THEN
                l_rec.desc_epis_recomend_clob := TRIM(i_desc);
            ELSE
                l_rec.id_item := i_id_item;
            
            END IF;
        
        ELSE
            l_rec.desc_epis_recomend_clob := TRIM(i_desc); --i_desc; RNAlmeida 17-09-2008
        END IF;
    
        l_rec.flg_type        := l_flg_type;
        l_rec.id_episode      := i_id_episode;
        l_rec.id_patient      := pk_episode.get_id_patient(i_id_episode);
        l_rec.id_professional := i_prof.id;
        l_rec.flg_temp        := g_definitive;
    
        OPEN c_prof_session;
        FETCH c_prof_session
            INTO l_rec.session_id;
        CLOSE c_prof_session;
    
        IF l_rec.session_id IS NULL
        THEN
        
            IF i_notes_code = g_end_session
            THEN
                -- trying to close a session that doesnt exist
                RETURN TRUE;
            ELSIF i_notes_code = g_begin_session
            THEN
                SELECT seq_recomend_session_id.nextval
                  INTO l_rec.session_id
                  FROM dual;
            ELSE
                g_error := 'CALL  set_init_session_no_commit. i_id_episode: ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                l_ret := set_init_session_no_commit(i_lang, i_prof, i_id_episode, o_error);
                IF l_ret = FALSE
                THEN
                    RAISE err_general_exception;
                END IF;
            
                OPEN c_prof_session;
                FETCH c_prof_session
                    INTO l_rec.session_id;
                CLOSE c_prof_session;
            END IF;
        END IF;
    
        /*
               FOR cfg IN c_cfg(nvl(i_notes_code, g_cfg_text))
               LOOP
                   l_rec.id_notes_config := cfg.id_notes_config;
               END LOOP;
        */
        l_rec.id_notes_config   := r_ncg.id_notes_config;
        l_id_notes_profile_inst := NULL;
    
        g_error := 'CURSOR c_acc: id_notes_config ' || r_ncg.id_notes_config;
        pk_alertlog.log_debug(g_error);
        FOR acc IN c_acc(r_ncg.id_notes_config, l_id_profile_template)
        LOOP
        
            l_write := acc.flg_write;
            l_read  := acc.flg_read;
        
            l_id_notes_profile_inst := acc.id_notes_profile_inst;
        
            EXIT;
        
        END LOOP;
    
        -- LMAIA 07-08-2008
        -- Para garantir que a função é abortada se o profissional não estiver correctamente parametrizado
        IF l_id_notes_profile_inst IS NULL
        THEN
            RAISE err_permissions_exception;
        END IF;
    
        l_rec.dt_epis_recomend_tstz := current_timestamp;
        -- ASANTOS ALERT-176957 13-10-2011
        l_rec.flg_status := pk_alert_constant.g_active;
    
        IF l_write = g_yes
        THEN
            l_ret := ins_epis_recomend(i_lang, i_prof, l_rec, o_error);
            IF l_ret = FALSE
            THEN
                RAISE err_general_exception;
            END IF;
        
            IF (l_rec.id_notes_config NOT IN (1, 2))
            THEN
                g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => i_id_episode,
                                              i_pat                 => NULL,
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => NULL,
                                              i_dt_last_interaction => g_sysdate_tstz,
                                              i_dt_first_obs        => g_sysdate_tstz,
                                              o_error               => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        --Actualiza dados das observações
    
        -- external professionals have single entry sessions
        IF i_prof.software <> l_software_inp
           AND i_notes_code <> g_begin_session
        THEN
            g_error := 'CALL  set_end_session_no_commit. i_id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            l_ret := set_end_session_no_commit(i_lang, i_prof, i_id_episode, o_error);
            IF l_ret = FALSE
            THEN
                RAISE err_general_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_general_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES_NO_COMMIT.GENERAL',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN err_permissions_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES_NO_COMMIT.PERMISSIONS',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES_NO_COMMIT.OTHERS',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_clinical_notes_no_commit;

    /*
    * set notes of professional based on access granted and profiles
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_notes_code               code to identify which kind of record is being saved.
    * @param   i_desc                     Main description
    * @param   i_valuer                   secondary value
    * @param   i_id_item                  Id item
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION set_clinical_notes_no_commit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes_code IN notes_config.notes_code%TYPE,
        i_desc       IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_value      IN epis_recomend.desc_epis_recomend_clob%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL set_clinical_notes_no_commit';
        IF NOT set_clinical_notes_no_commit(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_id_episode,
                                            i_notes_code => i_notes_code,
                                            i_desc       => i_desc,
                                            i_value      => i_value,
                                            i_id_item    => NULL,
                                            o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES_NO_COMMIT.OTHERS',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_clinical_notes_no_commit;

    /*
    * set notes of professional based on access granted and profiles
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_notes_code               code to identify which kind of record is being saved.
    * @param   i_desc                     Main description
    * @param   i_valuer                   secondary value
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION set_clinical_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes_code IN notes_config.notes_code%TYPE,
        i_desc       IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_value      IN epis_recomend.desc_epis_recomend_clob%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
        err_general_exception EXCEPTION;
    
    BEGIN
    
        l_ret := set_clinical_notes_no_commit(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_episode => i_id_episode,
                                              i_notes_code => i_notes_code,
                                              i_desc       => i_desc,
                                              i_value      => i_value,
                                              o_error      => o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN err_general_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES.GENERAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES.OTHERS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_clinical_notes;

    /*
    * insert into table epis_recomend
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_rec                      record structure of epis_recomend
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION ins_epis_recomend
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_rec   IN epis_recomend%ROWTYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    BEGIN
    
        ts_epis_recomend.ins(rec_in => i_rec, gen_pky_in => TRUE, rows_out => l_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_RECOMEND',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        /*  < DENORM Ariel Machado >
        
        INSERT INTO epis_recomend
            (id_epis_recomend,
             desc_epis_recomend,
             flg_type,
             id_episode,
             id_professional,
             flg_temp,
             dt_epis_recomend_tstz,
             id_notes_config,
             id_item,
             session_id)
        VALUES
            (l_id_epis_recomend,
             i_rec.desc_epis_recomend,
             i_rec.flg_type,
             i_rec.id_episode,
             i_rec.id_professional,
             i_rec.flg_temp,
             i_rec.dt_epis_recomend_tstz,
             i_rec.id_notes_config,
             i_rec.id_item,
             i_rec.session_id);
             */
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES_DOC_AREA',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END ins_epis_recomend;

    /*
    * Set notes for inpatient episodes in visit of current episode
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_id_doc_area              id_doc_area given to find corresponding notes_code
    * @param   i_desc                     Main description
    * @param   i_id_item                  Id item
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   07-FEB-2008
    *
    */
    FUNCTION set_clinical_notes_doc_area
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        i_desc        IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_id_item     IN epis_recomend.id_item%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ncg IS
            SELECT *
              FROM notes_config
             WHERE id_doc_area = i_id_doc_area
             ORDER BY id_notes_config;
    
        l_notes_code notes_config.notes_code%TYPE;
    BEGIN
    
        FOR ncg IN c_ncg
        LOOP
            l_notes_code := ncg.notes_code;
        
            IF NOT set_clinical_notes_for_visit(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_id_episode,
                                                i_notes_code => l_notes_code,
                                                i_desc       => i_desc,
                                                i_id_item    => i_id_item,
                                                o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES_DOC_AREA',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_clinical_notes_doc_area;

    /*
    * Set notes for inpatient episodes in visit of current episode
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_id_doc_area              id_doc_area given to find corresponding notes_code
    * @param   i_desc                     Main description
    * @param   i_id_item                  Id item
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   07-FEB-2008
    *
    */
    FUNCTION set_clinical_notes_doc_area
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        i_desc        IN epis_recomend.desc_epis_recomend_clob%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT set_clinical_notes_doc_area(i_lang        => i_lang,
                                           i_prof        => i_prof,
                                           i_id_episode  => i_id_episode,
                                           i_id_doc_area => i_id_doc_area,
                                           i_desc        => i_desc,
                                           i_id_item     => NULL,
                                           o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES_DOC_AREA',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_clinical_notes_doc_area;

    /*
    * Set notes for inpatient episodes in visit of current episode
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_notes_code               code to identify which kind of record is being saved.
    * @param   i_desc                     Main description
    * @param   i_id_item                  Id item
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   07-FEB-2008
    *
    */
    FUNCTION set_clinical_notes_for_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes_code IN VARCHAR2, --notes_config.notes_code%TYPE,
        i_desc       IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_id_item    IN epis_recomend.id_item%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_type_inp sys_config.value%TYPE;
    
        CURSOR c_visit(i_id_epis_type IN epis_type.id_epis_type%TYPE) IS
            SELECT *
              FROM episode
             WHERE id_epis_type = i_id_epis_type
               AND id_visit IN (SELECT id_visit
                                  FROM episode
                                 WHERE id_episode = i_id_episode);
    
    BEGIN
    
        l_epis_type_inp := pk_sysconfig.get_config('ID_EPIS_TYPE_INPATIENT', i_prof);
    
        FOR r_vis IN c_visit(l_epis_type_inp)
        LOOP
        
            IF NOT set_clinical_notes_no_commit(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => r_vis.id_episode,
                                                i_notes_code => i_notes_code,
                                                i_desc       => i_desc,
                                                i_value      => NULL,
                                                i_id_item    => i_id_item,
                                                o_error      => o_error)
            THEN
            
                RETURN FALSE;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES_FOR_VISIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_clinical_notes_for_visit;

    /*
    * Set notes for inpatient episodes in visit of current episode
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_notes_code               code to identify which kind of record is being saved.
    * @param   i_desc                     Main description
    * @param   i_id_item                  Id item
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   07-FEB-2008
    *
    */
    FUNCTION set_clinical_notes_for_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes_code IN VARCHAR2, --notes_config.notes_code%TYPE,
        i_desc       IN epis_recomend.desc_epis_recomend_clob%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT set_clinical_notes_for_visit(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_id_episode,
                                            i_notes_code => i_notes_code,
                                            i_desc       => i_desc,
                                            i_id_item    => NULL,
                                            o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLINICAL_NOTES_FOR_VISIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_clinical_notes_for_visit;

    /*
    * Processes lines for grouping.
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_FLG_ID_ITEM              FLAG WHICH SAYS IF WE USE THE DESC OU THE ID_ITEM
    * @param   i_DESC_epis_recomend       DESCRIPTION OF ITEM TO PROCESS
    * @param   i_ID_ITEM                  ID OF ITEM TO PROCESS
    * @param   i_NOTES_CODE               TYPE OF ITEM FROM NOTES_CONFIG
    * @param   i_FORMAT                   STRING FOR FORMATING OUTPUT
    * @param   i_flg_show_outd_data       Y - show the outdated data; 
    *                                     N - to the outdated shows a message saying 'outdated'
    * @param   o_status                   Status of the record(active, outdated)
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   14-Jul-2008
    *
    */
    FUNCTION get_item
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_id_item        IN notes_config.flg_id_item%TYPE,
        i_desc_epis_recomend IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_id_item            IN epis_recomend.id_item%TYPE,
        i_notes_code         IN notes_config.notes_code%TYPE,
        i_format             IN notes_group.desc_format%TYPE,
        i_flg_show_outd_data IN VARCHAR2,
        o_item               OUT CLOB,
        o_status             OUT epis_documentation.flg_status%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_var1 VARCHAR2(4000);
        l_var2 VARCHAR2(4000);
        l_var3 VARCHAR2(4000);
        l_var4 VARCHAR2(4000);
        l_item CLOB;
    
        l_msg_disagree   sys_message.desc_message%TYPE;
        l_msg_agree_but  sys_message.desc_message%TYPE;
        l_msg_adicional  sys_message.desc_message%TYPE;
        l_doc_flg_status epis_documentation.flg_status%TYPE;
        l_func_name CONSTANT VARCHAR2(9 CHAR) := 'GET_ITEM2';
    BEGIN
    
        l_item := i_format;
    
        g_error := 'COMPARE FLG_ID_ITEM i_flg_id_item: ' || i_flg_id_item || ' i_id_item: ' || i_id_item;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF i_flg_id_item = g_no
        THEN
            l_item := i_desc_epis_recomend;
        END IF;
    
        o_status := pk_alert_constant.g_active;
    
        IF i_notes_code IN (g_pbm_session, g_rds_session)
        THEN
            -- PROBLEMS, RELEVANT DISEASES
            g_error := 'QUERY PROBLEMS, RELEVANT DISEASES';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            SELECT decode(phd.id_alert_diagnosis,
                          NULL,
                          phd.desc_pat_history_diagnosis,
                          
                          -- INPATIENT LMAIA 21-08-2008
                          -- Esta alteração deve-se ao facto de o campo desc_pat_history_diagnosis estar a ser escrito com as
                          -- tags <b> e </b> e com o facto de quando id_alert_diagnosis IN (-1, 0) não se deve apresentar a
                          -- tradução do campo code_alert_diagnosis.
                          --
                          --decode(phd.desc_pat_history_diagnosis, NULL, '', phd.desc_pat_history_diagnosis || ' - ') ||
                          --pk_translation.get_translation(i_lang, ad.code_alert_diagnosis)) desc_probl,
                          decode(phd.desc_pat_history_diagnosis,
                                 NULL,
                                 '',
                                 REPLACE(REPLACE(phd.desc_pat_history_diagnosis, '<b>', NULL), '</b>', NULL) || ' - ') ||
                          decode(phd.id_alert_diagnosis,
                                 g_none_alert_diagnosis, --'-1',
                                 NULL,
                                 g_unknown_alert_diagnosis, --'0',
                                 NULL,
                                 -- ALERT-736: diagnosis synonyms support
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9))) desc_probl,
                   -- END
                   
                   decode(phd.id_alert_diagnosis,
                          NULL,
                          pk_message.get_message(i_lang, 'PROBLEMS_M001'),
                          pk_message.get_message(i_lang, 'PROBLEMS_M004')) title,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status
              INTO l_var1, l_var2, l_var3, l_var4
              FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
             WHERE phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND phd.id_diagnosis = d.id_diagnosis(+)
               AND phd.id_pat_history_diagnosis = i_id_item;
        
            -- INPATIENT LMAIA 25-08-2008
            -- Se o 3º e 4º campo elementos existirem, convém colocar o traço e a vírgula, entretanto retiradas da máscara
            IF l_var3 IS NOT NULL
            THEN
                l_var3 := ' - ' || l_var3;
            END IF;
            IF l_var4 IS NOT NULL
            THEN
                l_var3 := l_var3 || ', ';
            END IF;
            -- END
        
            l_item := pk_utils.replaceclob(l_item, '@1', l_var1);
            l_item := pk_utils.replaceclob(l_item, '@2', l_var2);
            l_item := pk_utils.replaceclob(l_item, '@3', l_var3);
            l_item := pk_utils.replaceclob(l_item, '@4', l_var4);
        
        ELSIF i_notes_code = g_crv_session
        THEN
            -- REVIEW OF COLLEAGUE NOTES
            g_error := 'QUERY REVIEW OF COLLEAGUE NOTES';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_msg_disagree  := pk_message.get_message(i_lang, i_prof, 'ATTENDING_NOTES_M008');
            l_msg_agree_but := pk_message.get_message(i_lang, i_prof, 'ATTENDING_NOTES_M009');
            l_msg_adicional := pk_message.get_message(i_lang, i_prof, 'ATTENDING_NOTES_M004');
        
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) nick_name,
                   ean.flg_agree,
                   ean.notes_reviewed,
                   ean.notes_additional
              INTO l_var1, l_var2, l_var3, l_var4
              FROM epis_attending_notes ean, professional prf
             WHERE ean.id_professional = prf.id_professional
               AND ean.id_epis_attending_notes = i_id_item
             ORDER BY 1 DESC;
        
            l_item := pk_utils.replaceclob(l_item, '@1', l_var1);
        
            IF l_var2 = g_disagree
            THEN
            
                l_item := pk_utils.replaceclob(l_item, '@2', l_msg_disagree);
            
            ELSE
            
                IF l_var3 IS NOT NULL
                THEN
                
                    l_item := pk_utils.replaceclob(l_item, '@2', ' - ' || l_msg_agree_but || chr(32) || l_var3);
                
                ELSE
                    l_item := pk_utils.replaceclob(l_item, '@2', NULL);
                END IF;
            
            END IF;
        
            IF l_var4 IS NOT NULL
            THEN
                l_item := pk_utils.replaceclob(l_item, '@3', '. ' || l_msg_adicional || chr(32) || l_var4);
            ELSE
                l_item := pk_utils.replaceclob(l_item, '@3', NULL);
            END IF;
        
        ELSIF i_notes_code = g_alg_session
        THEN
            -- ALLERGIES
            g_error := 'QUERY ALLERGIES';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            NULL;
        ELSIF i_notes_code = g_hbt_session
        THEN
            -- HABITS
            g_error := 'QUERY HABITS';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            NULL;
        ELSIF i_notes_code IN (g_xrv_session)
        THEN
            -- EXAM REVIEW
            g_error := 'QUERY EXAM REVIEW';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            SELECT (SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     'A',
                                                                     'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                     NULL) x_desc
                    -- < DESNORM LMAIA 16-10-2008 >
                      FROM lab_tests_ea lte --, analysis_req_det ard, analysis ana
                     WHERE lte.id_analysis_req_det = ttr.id_request
                       AND g_review_analysis = ttr.flg_type
                    --AND ana.id_analysis = ard.id_analysis
                    -- < END DESNORM >
                    UNION ALL
                    /*<DENORM Sérgio Monteiro 2008-10-09>*/
                    SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) x_desc
                      FROM exams_ea eea
                     WHERE eea.id_exam_req_det = ttr.id_request
                       AND g_review_exam = ttr.flg_type
                    /*<DENORM Sérgio Monteiro 2008-10-09>*/
                    UNION ALL
                    -- < DESNORM LMAIA 16-10-2008 >
                    SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     'A',
                                                                     'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                     NULL) x_desc
                      FROM lab_tests_ea lte --, analysis_result anr, analysis ana
                     WHERE lte.id_analysis_result = ttr.id_request
                       AND g_review_result = ttr.flg_type
                    --AND ana.id_analysis = anr.id_analysis
                    ),
                   -- < END DESNORM >
                   desc_tests_review
              INTO l_var1, l_var2
              FROM tests_review ttr
             WHERE ttr.id_tests_review = i_id_item
             ORDER BY 1 DESC;
        
            l_item := to_clob(l_var1 || ' - ' || l_var2);
            --RETURN l_item;
        
            l_item := pk_utils.replaceclob(l_item, '@1', l_var1);
            l_item := pk_utils.replaceclob(l_item, '@2', l_var2);
        
        ELSIF i_notes_code = g_trs_session
        THEN
            -- TREATMENT RESPONSE
            g_error := 'QUERY TREATMENT RESPONSE';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            SELECT decode(tm.flg_type,
                          g_treat_drugs,
                          pk_api_pfh_clindoc_in.get_med_desc(i_lang, i_prof, tm.id_treatment),
                          get_itv_desc(i_lang, i_prof, tm.id_treatment)) var1,
                   tm.desc_treatment_management
              INTO l_var1, l_var2
              FROM treatment_management tm
             WHERE tm.id_treatment_management = i_id_item
             ORDER BY tm.dt_creation_tstz ASC;
        
            IF l_var2 IS NULL
            THEN
                l_item := l_var1;
            ELSE
                l_item := pk_utils.replaceclob(l_item, '@1', l_var1);
                l_item := pk_utils.replaceclob(l_item, '@2', l_var2);
            END IF;
        
        ELSIF i_notes_code IN (g_begin_session, g_end_session)
        THEN
            g_error := 'IGNORE BEGIN AND END SESSION';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_item := NULL;
            FOR i IN 1 .. 50
            LOOP
                l_item := l_item || '-';
            END LOOP;
        
        ELSIF i_notes_code IN (g_physexam_session, g_revsys_session, g_hpi_session)
        THEN
            BEGIN
                g_error := 'GET FGL_STATUS FOR ID_ITEM: ' || i_id_item;
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                SELECT ed.flg_status
                  INTO l_doc_flg_status
                  FROM epis_documentation ed
                 WHERE ed.id_epis_documentation = i_id_item;
            EXCEPTION
                WHEN no_data_found THEN
                    l_item   := i_desc_epis_recomend;
                    o_status := pk_alert_constant.g_active;
            END;
        
            IF (l_doc_flg_status IS NOT NULL)
            THEN
                IF (l_doc_flg_status = pk_alert_constant.g_active)
                THEN
                    l_item   := i_desc_epis_recomend;
                    o_status := l_doc_flg_status;
                ELSE
                    IF (i_flg_show_outd_data = pk_alert_constant.g_yes)
                    THEN
                        l_item := i_desc_epis_recomend;
                    ELSE
                        l_item := pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_DIARY_M001');
                    END IF;
                    o_status := l_doc_flg_status;
                END IF;
            END IF;
        END IF;
    
        o_item := l_item;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            -- IF THER IS NO CONTENT, THEN SHOW MUST GO ON. SUCCESSFULL.
            pk_alertlog.log_info(text            => 'GET_ITEM2 no_data_found exception',
                                 object_name     => g_package_name,
                                 sub_object_name => l_func_name);
            RETURN TRUE;
        WHEN OTHERS THEN
            /*DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'GET_ITEM');
                -- return failure of function_dummy
                RETURN g_msg_error || g_error;
            END;*/
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_item;

    /*
    * Processes group and lines for sumarry page.
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_session_id               id of session to process
    * @param   i_id_notes_ground          id of group to process
    * @param   i_id_episode               id of episode
    * @param   o_list_notes               List of notes of a group
    * @param   o_list_status              List of status of a group
    * @param   O_line                     line processed
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   14-Jul-2008
    *
    */
    FUNCTION get_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_session_id     IN epis_recomend.session_id%TYPE,
        i_id_notes_group IN notes_group.id_notes_group%TYPE,
        i_id_episode     IN epis_recomend.id_episode%TYPE,
        i_flg_report     IN notes_profile_inst.flg_print%TYPE,
        o_list_notes     OUT table_clob,
        o_list_status    OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_line VARCHAR2(32000);
        l_item CLOB;
    
        l_desc_header notes_group.desc_header%TYPE;
        l_code_header notes_group.code_header%TYPE;
    
        l_status epis_documentation.flg_status%TYPE;
    
        l_notes       table_clob := table_clob();
        l_status_list table_varchar := table_varchar();
    
        l_has_outdated BOOLEAN := FALSE;
    
        l_func_name CONSTANT VARCHAR2(9 CHAR) := 'GET_GROUP';
        --l_clob_amount      PLS_INTEGER := 32000;
    
        -- INPATIENT LMAIA 26-01-2009
        -- This select was updated in order to improve it's COST.
        -- It was added "id_episode" compare.
        CURSOR c_erd IS
            SELECT erd.id_epis_recomend,
                   erd.desc_epis_recomend_clob,
                   erd.id_notes_config,
                   ncg.code_group_desc,
                   erd.id_item,
                   ncg.notes_code,
                   ncg.flg_id_item,
                   ngp.desc_header,
                   ngp.code_header,
                   ngp.desc_format,
                   ngp.grp_delimiter,
                   erd.flg_type
              FROM epis_recomend erd
              JOIN notes_grp_cfg ngc
                ON erd.id_notes_config = ngc.id_notes_config
              JOIN notes_group ngp
                ON ngp.id_notes_group = ngc.id_notes_group
              JOIN notes_config ncg
                ON ncg.id_notes_config = ngc.id_notes_config
             WHERE erd.session_id = i_session_id
               AND erd.id_episode = i_id_episode
               AND ngc.id_notes_group = i_id_notes_group
               AND ngc.id_software = i_prof.software
               AND ngc.id_institution = i_prof.institution
             ORDER BY dt_epis_recomend_tstz;
        --
    
    BEGIN
    
        FOR erd IN c_erd
        LOOP
        
            l_desc_header := erd.desc_header;
            l_code_header := erd.code_header;
        
            g_error := 'CALL GET ITEM no get_group. id_epis_recomend: ' || erd.id_epis_recomend;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF get_item(i_lang,
                        i_prof,
                        erd.flg_id_item,
                        erd.desc_epis_recomend_clob,
                        erd.id_item,
                        erd.notes_code,
                        erd.code_group_desc,
                        pk_alert_constant.g_no,
                        l_item,
                        l_status,
                        o_error) = FALSE
            THEN
                g_error := 'GET ITEM return false. id_item: ' || erd.id_item || ' flg_id_item: ' || erd.flg_id_item;
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                RETURN FALSE;
            END IF;
        
            g_error := 'CONCAT ITEMS INFORMATION';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF l_line IS NULL
            THEN
                IF ((l_has_outdated = FALSE OR l_status = pk_alert_constant.g_active) AND
                   NOT (i_flg_report = pk_alert_constant.g_yes AND l_status <> pk_alert_constant.g_active))
                THEN
                    g_error := 'l_has_outdated';
                    pk_alertlog.log_info(text            => g_error,
                                         object_name     => g_package_name,
                                         sub_object_name => l_func_name);
                    l_notes.extend(1);
                    l_notes(l_notes.count) := l_item;
                    l_status_list.extend(1);
                    l_status_list(l_status_list.count) := l_status;
                END IF;
            
            ELSE
                g_error := 'append note text';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_notes.extend(1);
                l_notes(l_notes.count) := erd.grp_delimiter || chr(10) || l_item;
                l_status_list.extend(1);
                l_status_list(l_status_list.count) := l_status;
            END IF;
        
            IF (l_status <> pk_alert_constant.g_active AND l_has_outdated = FALSE)
            THEN
                l_has_outdated := TRUE;
            END IF;
        
        END LOOP;
    
        o_list_notes  := l_notes;
        o_list_status := l_status_list;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            --pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_GROUP',
                                              o_error);
            RETURN FALSE;
        
    END get_group;

    /**
    *  Returns a set of medical/nursing notes based on filters criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_episode            Episode ID 
    * @param   i_flg_type           Type of notes
    * @param   i_flg_summary        Type of summary 
    * @param   i_flg_report         Function invoked by reports 
    * @param   i_fltr_time_frame    Filter sessions of a specific time frame rank. Default NULL (no filter)
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_day          Number of the start day. Just considered when paging is used. Default 1
    * @param   i_num_days           Number of days to be retrieved. Just considered when paging is used.  Default 5
    * @param   o_more_records       Give how many days of records should be presented according to one institution;
    * @param   o_more_days          All registries were returned in this function: 1 -> If there are more results; 0 -> If there are not more results.
    * @param   o_sql                Notes made in given interval
    * @param   o_notes_desc         Notes description grouped by session
    * @param   o_status             Notes status grouped by session
    * @param   o_error              Error message 
    *
    * @value   i_flg_type         {*} g_medical_notes Medical notes {*} g_nursing_notes Nursing notes
    * @value   i_flg_summary      {*} g_flg_smry_full Full summary {*} g_flg_smry_last_days Summary with the most recent [i_days_on_summary] days {*} g_flg_smry_last_days_timeframe Summary with the most recent [i_days_on_summary] days for each time frame rank/interval
    * @value   i_flg_report       {*} pk_alert_constant.g_yes {*} pk_alert_constant.g_no
    * @value   i_paging           {*} pk_alert_constant.g_yes {*} pk_alert_constant.g_no
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.1.8.2
    * @since   18-10-2011
    */
    FUNCTION get_paginated_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_flg_type        IN epis_recomend.flg_type%TYPE,
        i_flg_summary     IN VARCHAR2,
        i_flg_report      IN notes_profile_inst.flg_print%TYPE,
        i_fltr_time_frame IN NUMBER DEFAULT NULL,
        i_paging          IN VARCHAR2 DEFAULT 'N',
        i_start_day       IN NUMBER DEFAULT 1,
        i_num_days        IN NUMBER DEFAULT 5,
        o_more_records    OUT NUMBER,
        o_more_days       OUT NUMBER,
        o_sql             OUT pk_types.cursor_type,
        o_notes_desc      OUT table_table_clob,
        o_status          OUT table_table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_paginated_summary';
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_institution      institution.id_institution%TYPE;
        l_id_software software.id_software%TYPE := CASE
                                                       WHEN i_flg_report = pk_alert_constant.g_yes
                                                            AND i_prof.software <> pk_alert_constant.g_soft_inpatient THEN
                                                        pk_alert_constant.g_soft_inpatient
                                                       ELSE
                                                        i_prof.software
                                                   END;
    
        l_ret              BOOLEAN;
        l_count            NUMBER;
        l_num_session_days NUMBER;
        l_start_day        NUMBER(24);
        l_end_day          NUMBER(24);
    
        l_num_session PLS_INTEGER := 0;
    
        l_year  VARCHAR2(0050);
        l_month VARCHAR2(0050);
        l_day   VARCHAR2(0050);
        l_date  VARCHAR2(0100);
    
        l_header    VARCHAR2(4000);
        l_type_desc sys_domain.desc_val%TYPE;
    
        l_diary_desc sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => 'INP_DIARY_T105');
    
        l_note_days_on_summary NUMBER := pk_sysconfig.get_config(i_code_cf => 'NOTE_DAYS_ON_SUMMARY', i_prof => i_prof);
        l_format_date          sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'DATE_FORMAT_M009');
    
        err_general_exception EXCEPTION;
    
        -- INPATIENT LMAIA 06-02-2009
        -- This change is to guarantee that in case of sequence for collumn "session_id" be restarted in clients,
        -- registries are ordered conveniently.
        CURSOR c_sid
        (
            i_days_on_summary  IN NUMBER,
            i_paging_start_day IN NUMBER,
            i_paging_end_day   IN NUMBER
        ) IS
            SELECT s.session_id,
                   s.id_professional,
                   s.session_day,
                   s.highest_time,
                   s.time_frame_total_days,
                   s.time_frame_rank,
                   l_diary_desc || ' (' || pk_inp_util.get_time_frame_desc(i_lang, i_prof, s.time_frame_rank) || ')' time_frame_desc
              FROM (SELECT dense_rank() over(ORDER BY a.session_day) paging_rank, a.*
                      FROM (SELECT x.session_day,
                                   x.session_id,
                                   x.id_professional,
                                   x.highest_time,
                                   x.time_frame_rank,
                                   x.session_day_rank,
                                   dense_rank() over(PARTITION BY x.time_frame_rank ORDER BY x.session_day DESC) time_frame_day_rank,
                                   COUNT(DISTINCT x.session_day) over(PARTITION BY x.time_frame_rank) time_frame_total_days
                              FROM (SELECT sid.session_day,
                                           sid.session_id,
                                           sid.id_professional,
                                           sid.highest_time,
                                           pk_inp_util.get_time_frame_rank(i_lang, i_prof, sid.session_day) time_frame_rank,
                                           dense_rank() over(ORDER BY sid.session_day DESC) session_day_rank
                                      FROM (SELECT /*+ no_merge(nc) use_nl(nc er) */
                                             pk_date_utils.trunc_insttimezone(i_prof, er.dt_epis_recomend_tstz, NULL) session_day,
                                             pk_date_utils.dt_chr_hour_tsz(i_lang, MAX(er.dt_epis_recomend_tstz), i_prof) highest_time,
                                             er.session_id,
                                             er.id_professional
                                              FROM epis_recomend er
                                             INNER JOIN (SELECT id_notes_config
                                                          FROM notes_config cfg
                                                         WHERE cfg.notes_code NOT IN (g_begin_session, g_end_session)) nc
                                                ON (er.id_notes_config = nc.id_notes_config)
                                             WHERE er.id_episode = i_id_episode
                                               AND er.flg_type = i_flg_type
                                             GROUP BY pk_date_utils.trunc_insttimezone(i_prof,
                                                                                       er.dt_epis_recomend_tstz,
                                                                                       NULL),
                                                      er.session_id,
                                                      er.id_professional) sid) x
                             WHERE x.time_frame_rank = i_fltr_time_frame -- Filter records according to the time interval they belong. Used to paginate records within a time interval.
                                OR i_fltr_time_frame IS NULL) a
                     WHERE (i_flg_summary = g_flg_smry_full OR i_flg_summary = g_flg_smry_last_days_timeframe OR
                           i_flg_summary = g_flg_smry_last_days AND a.session_day_rank <= i_days_on_summary) -- flg_summary='Y' - Show the last N days 
                       AND (i_flg_summary = g_flg_smry_full OR i_flg_summary = g_flg_smry_last_days OR
                           (i_flg_summary = g_flg_smry_last_days_timeframe AND
                           a.time_frame_day_rank <= i_days_on_summary)) -- flg_summary='T' - Show the last N days for each time frame rank.  
                    ) s -- Data paging  
             WHERE i_paging = pk_alert_constant.g_no
                OR (i_paging = pk_alert_constant.g_yes AND s.paging_rank >= i_paging_start_day AND
                   s.paging_rank <= i_paging_end_day)
             ORDER BY s.session_day, s.highest_time, s.session_id, s.id_professional;
    
        -- END
    
        CURSOR c_grp IS
            SELECT ngp.*
              FROM notes_group ngp
             WHERE ngp.flg_available = pk_alert_constant.g_yes
               AND ngp.id_notes_group IN (SELECT ngg.id_notes_group
                                            FROM notes_grp_cfg ngg
                                           WHERE ngg.id_software = l_id_software
                                             AND ngg.id_institution = l_id_institution)
             ORDER BY rank;
    
        l_tmp_inst_abbreviation institution.abbreviation%TYPE;
        l_prof_name             professional.name%TYPE;
        l_desc_speciality       pk_translation.t_desc_translation;
    
        err_get_group EXCEPTION;
    
        l_list_notes  table_clob := table_clob();
        l_list_status table_varchar := table_varchar();
    
        l_list_group_notes  table_clob := table_clob();
        l_list_group_status table_varchar := table_varchar();
    
        l_notes_desc table_table_clob := table_table_clob();
        l_status     table_table_varchar := table_table_varchar();
    
        l_cfg_show_free_text sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'GET PROFILE TEMPLATE';
        pk_alertlog.log_debug(g_error);
        l_ret := get_profile_template(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      o_profile_template => l_id_profile_template,
                                      o_error            => o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        g_error := 'VERIFY INSTITUTION SETTINGS';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(1)
          INTO l_count
          FROM notes_profile_inst
         WHERE id_profile_template = l_id_profile_template
           AND id_institution = i_prof.institution;
    
        l_id_institution := i_prof.institution;
        IF l_count = 0
        THEN
            l_id_institution := 0;
        END IF;
    
        -- *******************************************
        --        DELETE tmp_summary_med_notes;
        DELETE tmp_summary_med_notes;
        -- *******************************************
    
        -- get institituion of episode
        g_error := 'GET EPISODE INSTITUTION';
        pk_alertlog.log_debug(g_error);
        DECLARE
        BEGIN
            SELECT ist.abbreviation
              INTO l_tmp_inst_abbreviation
              FROM episode epi, visit vis, institution ist
             WHERE epi.id_episode = i_id_episode
               AND vis.id_visit = epi.id_visit
               AND ist.id_institution = vis.id_institution;
        
        EXCEPTION
            -- if theres no records, no big deal, continue execution
            WHEN no_data_found THEN
                NULL;
        END;
        --
    
        --Antonio.Neto (19-Nov-2010) Constants needed ro remove "Free Text" from Physicians Diaries (ALERT-126888)
        g_error := 'CALL PK_SYSCONFIG.GET_CONFIG';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sysconfig.get_config(g_cfg_show_free_text, i_prof, l_cfg_show_free_text)
        THEN
            RAISE err_general_exception;
        END IF;
    
        IF i_paging = pk_alert_constant.g_no
        THEN
            -- Returns all the resultset
            l_start_day := NULL;
            l_end_day   := NULL;
        ELSE
            l_start_day := i_start_day;
            l_end_day   := i_start_day + i_num_days - 1;
        
            IF l_start_day < 1
            THEN
                -- Minimum inbound 
                l_start_day := 1;
            END IF;
        
        END IF;
    
        -- Ensure that, even if there is a configuration error, are visualized at least two days of entries
        IF l_note_days_on_summary <= 0
        THEN
            l_note_days_on_summary := 2;
        END IF;
    
        pk_date_utils.set_dst_time_check_off;
    
        FOR xid IN c_sid(l_note_days_on_summary, l_start_day, l_end_day)
        LOOP
            l_num_session := l_num_session + 1;
        
            FOR grp IN c_grp
            LOOP
                g_error := 'DATES MANIPULATION';
                pk_alertlog.log_debug(g_error);
                l_year  := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => xid.session_day,
                                                              i_mask      => 'YYYY');
                l_month := pk_message.get_message(i_lang,
                                                  'TL_MONTH_' ||
                                                  to_number(pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                                                               i_prof      => i_prof,
                                                                                               i_timestamp => xid.session_day,
                                                                                               i_mask      => 'MM')));
                l_day   := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => xid.session_day,
                                                              i_mask      => 'DD');
            
                l_date := REPLACE(l_format_date, '@Y', l_year);
                l_date := REPLACE(l_date, '@M', TRIM(l_month));
                l_date := REPLACE(l_date, '@D', l_day);
                --                
                --
                l_list_group_notes  := table_clob();
                l_list_group_status := table_varchar();
                l_list_notes        := table_clob();
                l_list_status       := table_varchar();
            
                l_header := nvl(pk_translation.get_translation(i_lang => i_lang, i_code_mess => grp.code_header),
                                grp.desc_header);
            
                g_error := 'CALL GET_GROUP. i_id_notes_group: ' || grp.id_notes_group || ' session_id: ' ||
                           xid.session_id;
                pk_alertlog.log_debug(g_error);
                IF NOT get_group(i_lang           => i_lang,
                                 i_prof           => profissional(i_prof.id, l_id_institution, l_id_software),
                                 i_session_id     => xid.session_id,
                                 i_id_notes_group => grp.id_notes_group,
                                 i_id_episode     => i_id_episode,
                                 i_flg_report     => i_flg_report,
                                 o_list_notes     => l_list_group_notes,
                                 o_list_status    => l_list_group_status,
                                 o_error          => o_error)
                THEN
                    RAISE err_get_group;
                END IF;
            
                IF (l_list_group_notes IS NOT NULL AND l_list_group_notes.exists(1))
                THEN
                
                    IF l_header IS NOT NULL
                    THEN
                        --Antonio.Neto (19-Nov-2010) Constants needed ro remove "Free Text" from Physicians Diaries (ALERT-126888)
                        IF l_cfg_show_free_text = pk_alert_constant.g_no
                           AND g_free_text = grp.intern_name
                        THEN
                            l_header := NULL;
                        END IF;
                    
                        l_list_notes.extend(1);
                        l_list_notes(l_list_notes.count) := l_header;
                    
                        l_list_status.extend(1);
                        l_list_status(l_list_status.count) := pk_alert_constant.g_active;
                    END IF;
                
                    --Append the data in i_table_to_append to the table io_total_table      
                    g_error := 'CALL pk_utils.append_tables';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_utils.append_tables_clob(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_table_to_append => l_list_group_notes,
                                                       i_flg_replace     => pk_alert_constant.g_yes,
                                                       i_replacement     => grp.desc_format,
                                                       io_total_table    => l_list_notes,
                                                       o_error           => o_error)
                    THEN
                        RAISE err_general_exception;
                    END IF;
                
                    g_error := 'CALL pk_utils.append_tables';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_utils.append_tables(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_table_to_append => l_list_group_status,
                                                  i_flg_replace     => pk_alert_constant.g_no,
                                                  i_replacement     => '',
                                                  io_total_table    => l_list_status,
                                                  o_error           => o_error)
                    THEN
                        RAISE err_general_exception;
                    END IF;
                
                END IF;
            
                g_error := 'IS GROUP INFORMATION NULL';
                pk_alertlog.log_debug(g_error);
                IF l_list_notes IS NOT NULL
                   AND l_list_notes.exists(1)
                THEN
                    l_notes_desc.extend(1);
                    l_notes_desc(l_notes_desc.count) := l_list_notes;
                
                    l_status.extend(1);
                    l_status(l_status.count) := l_list_status;
                
                    -- get nickname and speciality of profession
                    -- END                   
                    g_error := 'GET PROFESSIONAL INFORMATION ' || xid.session_day;
                    pk_alertlog.log_debug(g_error);
                    SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) nick_name,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            prf.id_professional,
                                                            xid.session_day,
                                                            i_id_episode) desc_speciality
                      INTO l_prof_name, l_desc_speciality
                      FROM professional prf
                     WHERE prf.id_professional = xid.id_professional;
                
                    -- **********************************
                    --   INSERT INTO tmp_summary_med_notes
                    g_error := 'INSERT DATA INTO TMP_SUMMARY_MED_NOTES';
                    pk_alertlog.log_debug(g_error);
                    INSERT INTO tmp_summary_med_notes
                        (notes_date,
                         session_id,
                         notes_time,
                         id_professional,
                         rank,
                         nick_name,
                         desc_speciality,
                         inst_abbreviation,
                         dt_notes_tstz,
                         time_frame_rank,
                         time_frame_desc,
                         time_frame_total_days)
                    VALUES
                        (l_date,
                         xid.session_id,
                         xid.highest_time,
                         xid.id_professional,
                         grp.rank,
                         l_prof_name,
                         l_desc_speciality,
                         CASE WHEN l_tmp_inst_abbreviation IS NOT NULL AND l_desc_speciality IS NOT NULL THEN
                         ', ' || l_tmp_inst_abbreviation ELSE l_tmp_inst_abbreviation END,
                         trunc(xid.session_day),
                         xid.time_frame_rank,
                         xid.time_frame_desc,
                         xid.time_frame_total_days);
                    -- **********************************                   
                    --
                
                END IF;
            END LOOP; -- GRP
        END LOOP; -- end xid
        g_error := 'END LOOP';
        pk_alertlog.log_debug(g_error);
    
        pk_date_utils.set_dst_time_check_on;
    
        o_more_records := l_note_days_on_summary;
    
        -- Initialize variable o_more_days
        o_more_days := 0; -- All the information is returned in this function
    
        -- When flg_summary is 'Y' there are only returned the last <<l_note_days_on_summary>> days with registries
        IF i_flg_summary = g_flg_smry_last_days
        THEN
            -- Get how many days with registries exists in notes functionality
            g_error := 'GET NUMBER OF DIFERENT DAYS WITH REGISTRIES';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT COUNT(DISTINCT trunc(er.dt_epis_recomend_tstz)) session_days
                  INTO l_num_session_days
                  FROM epis_recomend er
                 INNER JOIN (SELECT id_notes_config
                               FROM notes_config cfg
                              WHERE cfg.notes_code NOT IN (g_begin_session, g_end_session)) nc
                    ON (er.id_notes_config = nc.id_notes_config)
                 WHERE er.id_episode = i_id_episode
                   AND er.flg_type = i_flg_type;
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_num_session_days := 0;
            END;
        
            -- IF there are more days os information than the one's that are returned
            g_error := 'COMPARE NUMBER OF DAYS OF REGISTRIES';
            pk_alertlog.log_debug(g_error);
            IF l_num_session_days > l_note_days_on_summary
            THEN
                o_more_days := 1; -- There are more information to return
            END IF;
        END IF;
    
        l_type_desc := pk_sysdomain.get_domain('EPIS_RECOMEND.FLG_TYPE', i_flg_type, i_lang);
    
        g_error := 'GET ALL THE NOTES REGISTRIES';
        pk_alertlog.log_debug(g_error);
        OPEN o_sql FOR
            SELECT notes_date,
                   session_id,
                   notes_time,
                   id_professional,
                   rank,
                   nick_name prof_recom,
                   desc_speciality || inst_abbreviation desc_speciality,
                   dt_notes_tstz,
                   pk_date_utils.date_send_tsz(i_lang, dt_notes_tstz, i_prof) dt_for_report,
                   time_frame_rank,
                   time_frame_desc,
                   time_frame_total_days,
                   pk_inp_util.get_time_frame_desc(i_lang, i_prof, time_frame_rank) time_frame_label,
                   l_type_desc || ' (' || pk_inp_util.get_time_frame_desc(i_lang, i_prof, time_frame_rank) || ')' rec_type_time_frame_desc
              FROM tmp_summary_med_notes
             ORDER BY dt_notes_tstz, notes_time, session_id, rank;
    
        o_notes_desc := l_notes_desc;
        o_status     := l_status;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_group THEN
            pk_alertlog.log_debug('err_get_group exception:' || g_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              co_function_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        
    END get_paginated_summary;

    /*
    * Get summary of medical notes ( grouping by topics )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   i_flg_summary              It is supposed return all registries ('N') or only the first's ones ('Y');
    * @param   o_more_records             Give how many days of records should be presented according to one institution;
    * @param   o_more_days                All registries were returned in this function: 1 -> If there are more results; 0 -> If there are not more results.
    * @param   o_sql                      notes made in given interval
    * @param   o_notes_desc               notes description grouped by session
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   14-JUL-2008
    *
    */
    FUNCTION get_summary
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_flg_type     IN epis_recomend.flg_type%TYPE,
        i_flg_summary  IN VARCHAR2, -- INP LMAIA 04-03-2009. IF 'Y' only returns last 3 days of registries, otherwise returns all.
        i_flg_report   IN notes_profile_inst.flg_print%TYPE,
        o_more_records OUT NUMBER,
        o_more_days    OUT NUMBER, -- INP LMAIA 04-03-2009. 1 -> If there are more results; 0 -> If there are not more results.
        o_sql          OUT pk_types.cursor_type,
        o_notes_desc   OUT table_table_clob,
        o_status       OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'call get_paginated_summary';
        RETURN get_paginated_summary(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_id_episode      => i_id_episode,
                                     i_flg_type        => i_flg_type,
                                     i_flg_summary     => i_flg_summary,
                                     i_flg_report      => i_flg_report,
                                     i_fltr_time_frame => NULL,
                                     i_paging          => pk_alert_constant.g_no,
                                     o_more_records    => o_more_records,
                                     o_more_days       => o_more_days,
                                     o_sql             => o_sql,
                                     o_notes_desc      => o_notes_desc,
                                     o_status          => o_status,
                                     o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        
    END get_summary;

    /*
    * Get summary of medical notes ( grouping by topics )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   i_flg_summary              It is supposed return all registries ('N') or only the first's ones ('Y');
    * @param   o_more_records             Give how many days of records should be presented according to one institution;
    * @param   o_more_days                All registries were returned in this function: 1 -> If there are more results; 0 -> If there are not more results.
    * @param   o_sql                      notes made in given interval
    * @param   o_notes_desc               notes description grouped by session
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   14-JUL-2008
    *
    */
    FUNCTION get_summary
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_flg_type     IN epis_recomend.flg_type%TYPE,
        i_flg_summary  IN VARCHAR2, -- INP LMAIA 04-03-2009. IF 'Y' only returns last 3 days of registries, otherwise returns all.
        o_more_records OUT NUMBER,
        o_more_days    OUT NUMBER, -- INP LMAIA 04-03-2009. 1 -> If there are more results; 0 -> If there are not more results.
        o_sql          OUT NOCOPY pk_types.cursor_type,
        o_notes_desc   OUT table_table_clob,
        o_status       OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT get_summary(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_id_episode   => i_id_episode,
                           i_flg_type     => i_flg_type,
                           i_flg_summary  => i_flg_summary,
                           i_flg_report   => pk_alert_constant.g_no,
                           o_more_records => o_more_records,
                           o_more_days    => o_more_days,
                           o_sql          => o_sql,
                           o_notes_desc   => o_notes_desc,
                           o_status       => o_status,
                           o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_summary;

    /*
    * Get summary of medical notes ( grouping by topics )  FOR REPORTS
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF_ID                  ID OF professional
    * @param   I_PROF_INSTITUTION         ID OF  institution
    * @param   I_PROF_SOFTWARE            ID OF software
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   o_more_records             Has more records to show: 1 - Yes; 0 - No;
    * @param   o_sql                      notes made in given interval
    * @param   o_notes_desc               notes description grouped by session
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   14-JUL-2008
    *
    */
    FUNCTION get_summary_externo
    (
        i_lang             IN language.id_language%TYPE,
        i_prof_id          IN professional.id_professional%TYPE,
        i_prof_institution IN institution.id_institution%TYPE,
        i_prof_software    IN software.id_software%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_flg_type         IN epis_recomend.flg_type%TYPE,
        o_more_records     OUT NUMBER,
        o_sql              OUT NOCOPY pk_types.cursor_type,
        o_notes_desc       OUT table_table_clob,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        i_prof                    profissional := profissional(i_prof_id, i_prof_institution, i_prof_software);
        l_status_dummy            table_table_varchar := table_table_varchar();
        l_flg_summary_information VARCHAR2(1) := g_no;
        l_more_days               NUMBER;
    BEGIN
        g_error := 'CALL get_summary';
        pk_alertlog.log_debug(g_error);
        -- CHAMAR FUNÇAO DO SUMARIO
        g_ret := get_summary(i_lang         => i_lang,
                             i_prof         => i_prof,
                             i_id_episode   => i_id_episode,
                             i_flg_type     => i_flg_type,
                             i_flg_summary  => l_flg_summary_information,
                             i_flg_report   => pk_alert_constant.g_yes,
                             o_more_records => o_more_records,
                             o_more_days    => l_more_days,
                             o_sql          => o_sql,
                             o_notes_desc   => o_notes_desc,
                             o_status       => l_status_dummy,
                             o_error        => o_error);
    
        IF g_ret = FALSE
        THEN
            RETURN FALSE;
        END IF;
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_SUMMARY_EXTERNO',
                                                     o_error);
            RETURN FALSE;
    END get_summary_externo;

    /*
    * Get writing format of notes_config item
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_notes_code               code identifying id_notes_code
    * @param   o_format                   format to use
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   18-JUL-2008
    *
    */
    FUNCTION get_notes_format
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_notes_code IN notes_config.notes_code%TYPE,
        o_format     OUT notes_config.code_group_desc%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_group_desc notes_config.code_group_desc%TYPE;
    BEGIN
    
        SELECT code_group_desc
          INTO l_code_group_desc
          FROM notes_config
         WHERE notes_code = i_notes_code;
    
        o_format := l_code_group_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_NOTES_FORMAT',
                                                       o_error);
            RETURN FALSE;
    END get_notes_format;

    /*
    * Get summary of medical notes registered in one specific session ( registries order by time )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   i_session_id               Session_id of section to be presented in detail screen
    * @param   o_session_summary          Has summary information about current session: "Hour INIT - Hour END (DAY)"    
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Maia
    * @version 1.0
    * @since   07-JAN-2009
    *
    * UPDATED: separated in 3 functions: get_summary_session_detail, get_summary_session and get_session_header
    * @author  Sofia Mendes
    * @version 2.5.1.3
    * @since   23-Nov-2010
    */
    FUNCTION get_session_header
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN epis_recomend.flg_type%TYPE,
        i_session_id      IN epis_recomend.session_id%TYPE,
        o_session_summary OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_format_min_date_day sys_message.desc_message%TYPE;
        l_format_max_date_day sys_message.desc_message%TYPE;
        l_format_date         sys_message.desc_message%TYPE;
        --
        l_session_summary VARCHAR2(4000) := '';
        --
        l_min_date_section epis_recomend.dt_epis_recomend_tstz%TYPE;
        l_max_date_section epis_recomend.dt_epis_recomend_tstz%TYPE;
        l_num_notes        NUMBER(24);
        --                        
        err_general_exception EXCEPTION;
    
        l_prof_name       professional.name%TYPE;
        l_desc_speciality pk_translation.t_desc_translation;
    
    BEGIN
    
        -- Get Min and Max Hours
        g_error := 'GET SESSION MIN AND MAX HOURS';
        SELECT MIN(er.dt_epis_recomend_tstz), MAX(er.dt_epis_recomend_tstz), COUNT(1) num_regs
          INTO l_min_date_section, l_max_date_section, l_num_notes
          FROM epis_recomend er
         WHERE er.session_id = i_session_id
           AND er.id_notes_config NOT IN (g_id_session_begin, g_id_session_end)
           AND er.flg_type = i_flg_type;
    
        -- Get summary information about current session.
        -- This information should be returned in parameter o_session_summary with the format:
        -- "12:33h - 14:50h (07-Jan-2009)" (example in portuguese)
    
        --
        -- FORMAT INIT DAY
        -- Variable "l_format_min_date_day" get date (day) from the first note of this section in correct language format
        --
        l_format_date         := pk_message.get_message(i_lang, 'DATE_FORMAT_M006');
        l_format_min_date_day := pk_date_utils.to_char_insttimezone(i_lang, i_prof, l_min_date_section, l_format_date);
        --
        -- FORMAT END DAY
        -- Variable "l_format_max_date_day" get date (day) from the last note of this section in correct language format
        --
        l_format_max_date_day := pk_date_utils.to_char_insttimezone(i_lang, i_prof, l_max_date_section, l_format_date);
        --
        -- Concatenate Final Session time and date information
        --
        IF l_num_notes = 1 -- IF there is only 1 note in currente section
        THEN
            l_session_summary := pk_date_utils.dt_chr_hour_tsz(i_lang => i_lang,
                                                               i_date => l_min_date_section,
                                                               i_prof => i_prof) || ' (' || l_format_min_date_day || ')';
        ELSE
            IF l_format_min_date_day = l_format_max_date_day -- IF first and last note were done in the same day
            THEN
                l_session_summary := pk_date_utils.dt_chr_hour_tsz(i_lang => i_lang,
                                                                   i_date => l_min_date_section,
                                                                   i_prof => i_prof) || ' - ' ||
                                     pk_date_utils.dt_chr_hour_tsz(i_lang => i_lang,
                                                                   i_date => l_max_date_section,
                                                                   i_prof => i_prof) || ' (' || l_format_min_date_day || ')';
            ELSE
                -- IF first and last note were done in diferent days
                l_session_summary := pk_date_utils.dt_chr_hour_tsz(i_lang => i_lang,
                                                                   i_date => l_min_date_section,
                                                                   i_prof => i_prof) || ' (' || l_format_min_date_day ||
                                     ') - ' || pk_date_utils.dt_chr_hour_tsz(i_lang => i_lang,
                                                                             i_date => l_max_date_section,
                                                                             i_prof => i_prof) || ' (' ||
                                     l_format_max_date_day || ')';
            END IF;
        END IF;
    
        g_error := 'GET prof name and specialty, i_session_id: ' || i_session_id;
        pk_alertlog.log_debug(g_error);
        SELECT td.nick_name, td.desc_speciality
          INTO l_prof_name, l_desc_speciality
          FROM tmp_summary_med_notes_detail td
         WHERE td.session_id = i_session_id
           AND rownum = 1;
    
        o_session_summary := l_session_summary || g_slash || l_prof_name || CASE
                                 WHEN l_desc_speciality IS NOT NULL THEN
                                  g_open_parenthesis || l_desc_speciality || g_close_parenthesis
                             END;
    
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SESSION_HEADER.OTHERS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END get_session_header;

    /*
    * Get summary of medical notes registered in one specific session ( registries order by time )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   i_flg_scope                Scope: P -patient; E- episode; V-visit; S-session
    * @param   i_id_episode               Episode identifier; mandatory if i_flg_scope='E'
    * @param   i_id_patient               Patient identifier; mandatory if i_flg_scope='P'
    * @param   i_id_visit                 Visit identifier; mandatory if i_flg_scope='V'
    * @param   i_flg_report_type          Report type: C-complete; D-detailed
    * @param   i_session_id               Session_id of section to be presented in detail screen. Mandatory if i_flg_scop='S'
    * @param   i_start_date               Start date to be considered
    * @param   i_end_date                 End date to be considered
    * @param   i_flg_report               Flag to consider when to show info for all profiles/software or not
    * @param   o_session_detail           Notes made in current session order by registry time
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Maia
    * @version 1.0
    * @since   07-JAN-2009
    *
    * UPDATED: separated in 3 functions: get_summary_session_detail, get_summary_session and get_session_header
    * @author  Sofia Mendes
    * @version 2.5.1.3
    * @since   23-Nov-2010
    *
    */
    FUNCTION get_summary_session
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN epis_recomend.flg_type%TYPE,
        i_session_id      IN epis_recomend.session_id%TYPE,
        i_flg_scope       IN VARCHAR2, -- P -patient; E- episode; V-visit
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_flg_report_type IN VARCHAR2, --C-complete; D-detailed
        i_start_date      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_report      IN notes_profile_inst.flg_print%TYPE DEFAULT pk_alert_constant.g_no,
        o_session_detail  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_institution      institution.id_institution%TYPE;
        l_id_software software.id_software%TYPE := CASE
                                                       WHEN i_flg_report = pk_alert_constant.g_yes
                                                            AND i_prof.software <> pk_alert_constant.g_soft_inpatient THEN
                                                        pk_alert_constant.g_soft_inpatient
                                                       ELSE
                                                        i_prof.software
                                                   END;
        --
        l_ret   BOOLEAN;
        l_count NUMBER;
        --
        err_general_exception EXCEPTION;
    
        l_status epis_documentation.flg_status%TYPE;
    
        l_prof_name       professional.name%TYPE;
        l_desc_speciality pk_translation.t_desc_translation;
        --
        l_item CLOB;
        l_date VARCHAR2(4000);
        --
        l_edited_msg    sys_message.code_message%TYPE;
        l_cancelled_msg sys_message.code_message%TYPE;
    
        l_cfg_show_free_text_det sys_config.value%TYPE;
        l_episodes               table_number := table_number();
        l_invalid_arguments EXCEPTION;
    
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'GET_SUMMARY_SESSION';
        --
        -- Cursor that returns all the information about each note from a session
        CURSOR session_reg_c(l_id_institution institution.id_institution%TYPE) IS
            SELECT er.session_id,
                   er.id_professional,
                   pk_date_utils.trunc_insttimezone(i_prof, er.dt_epis_recomend_tstz, NULL) session_day,
                   er.dt_epis_recomend_tstz,
                   t.desc_epis_recomend_clob,
                   er.id_item,
                   nc.flg_id_item,
                   nc.notes_code,
                   nc.code_group_desc,
                   ng.id_notes_group,
                   ng.desc_header,
                   ng.desc_format,
                   ng.code_header,
                   er.id_episode,
                   ng.intern_name
              FROM (SELECT er.session_id,
                           er.id_professional,
                           er.dt_epis_recomend_tstz,
                           er.id_item,
                           er.id_episode,
                           er.flg_type,
                           er.id_notes_config,
                           er.id_epis_recomend
                      FROM epis_recomend er
                     WHERE er.session_id = i_session_id
                    UNION
                    SELECT er.session_id,
                           er.id_professional,
                           er.dt_epis_recomend_tstz,
                           er.id_item,
                           er.id_episode,
                           er.flg_type,
                           er.id_notes_config,
                           er.id_epis_recomend
                      FROM epis_recomend er
                     WHERE er.id_episode = i_id_episode
                    UNION
                    SELECT er.session_id,
                           er.id_professional,
                           er.dt_epis_recomend_tstz,
                           er.id_item,
                           er.id_episode,
                           er.flg_type,
                           er.id_notes_config,
                           er.id_epis_recomend
                      FROM epis_recomend er
                     WHERE er.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                              column_value
                                               FROM TABLE(CAST(l_episodes AS table_number)) t)) er
            --this join is needed because it is not possible to use UNION with clob columns
              JOIN epis_recomend t
                ON er.id_epis_recomend = t.id_epis_recomend
              JOIN notes_config nc
                ON nc.id_notes_config = er.id_notes_config
              JOIN notes_grp_cfg ngc
                ON ngc.id_notes_config = nc.id_notes_config
              JOIN notes_group ng
                ON ng.id_notes_group = ngc.id_notes_group
             WHERE er.flg_type = i_flg_type
               AND nc.notes_code NOT IN (g_begin_session, g_end_session)
               AND ng.flg_available = g_yes
               AND ngc.id_software = l_id_software
               AND ngc.id_institution = l_id_institution
               AND (er.dt_epis_recomend_tstz >= i_start_date OR i_start_date IS NULL)
               AND (er.dt_epis_recomend_tstz <= i_end_date OR i_end_date IS NULL)
             ORDER BY er.dt_epis_recomend_tstz;
        --
        --
    BEGIN
    
        g_error := 'GET PROFILE TEMPLATE';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_ret := get_profile_template(i_lang, i_prof, l_id_profile_template, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_exception;
        END IF;
    
        g_error := 'VERIFY INSTITUTION SETTINGS';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT COUNT(1)
          INTO l_count
          FROM notes_profile_inst
         WHERE id_profile_template = l_id_profile_template
           AND id_institution = i_prof.institution;
    
        l_id_institution := i_prof.institution;
        IF l_count = 0
        THEN
            l_id_institution := 0;
        END IF;
    
        IF ((i_flg_scope = g_scope_visit_v AND i_id_patient IS NULL AND i_id_episode IS NOT NULL) OR
           (i_flg_scope = g_scope_episode_e AND i_id_episode IS NULL))
        THEN
            RAISE l_invalid_arguments;
        END IF;
    
        IF (i_flg_scope = g_scope_patient_p)
        THEN
            g_error := 'GET ID_EPISODES: i_id_patient: ' || i_id_patient;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            SELECT er.id_episode BULK COLLECT
              INTO l_episodes
              FROM epis_recomend er
              JOIN episode e
                ON er.id_episode = e.id_episode
             WHERE e.id_patient = i_id_patient;
        ELSE
            IF (i_flg_scope = g_scope_visit_v)
            THEN
                g_error := 'GET ID_EPISODES: i_id_visit: ' || i_id_visit;
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                SELECT er.id_episode BULK COLLECT
                  INTO l_episodes
                  FROM epis_recomend er
                  JOIN episode e
                    ON er.id_episode = e.id_episode
                 WHERE e.id_visit = i_id_visit;
            END IF;
        END IF;
    
        --Antonio.Neto (19-Nov-2010) Constants needed ro remove "Free Text" from Physicians Diaries (ALERT-126888)
        g_error := 'CALL PK_SYSCONFIG.GET_CONFIG';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_sysconfig.get_config(g_cfg_show_free_text_det, i_prof, l_cfg_show_free_text_det)
        THEN
            RAISE err_general_exception;
        END IF;
    
        --
        -- GET SESSION REGITRIES
        --
        -- *******************************************
        DELETE tmp_summary_med_notes_detail;
        -- *******************************************
    
        FOR session_reg IN session_reg_c(l_id_institution)
        LOOP
            l_item := '';
        
            -- GET item description (this is necessary because there are information that is not at epis_recomend.desc_epis_recomend
            g_error := 'CALL GET_ITEM flg_id_item: ' || session_reg.flg_id_item || ' id_item: ' || session_reg.id_item;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF get_item(i_lang,
                        i_prof,
                        session_reg.flg_id_item,
                        session_reg.desc_epis_recomend_clob,
                        session_reg.id_item,
                        session_reg.notes_code,
                        session_reg.code_group_desc,
                        pk_alert_constant.g_yes,
                        l_item,
                        l_status,
                        o_error) = FALSE
            THEN
                g_error := 'GET_ITEM returned false';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                RETURN FALSE;
            END IF;
        
            IF ((i_flg_report_type = g_report_complete_c AND l_status = pk_alert_constant.g_active) OR
               i_flg_report_type = g_report_complete_d OR i_flg_report_type IS NULL)
            THEN
                -- IF there is no description it should be visible group title (the agregater. Example: "Alterei medicação.")
                IF l_item IS NULL
                THEN
                    l_item := pk_translation.get_translation(i_lang => i_lang, i_code_mess => session_reg.code_header);
                END IF;
            
                -- INSERT into temporary table information about all items of this section
                IF l_item IS NOT NULL
                THEN
                    g_error := 'CALL pk_utils.replace_with_clob';
                    pk_alertlog.log_info(text            => g_error,
                                         object_name     => g_package_name,
                                         sub_object_name => l_func_name);
                    l_item := pk_utils.replace_with_clob(session_reg.desc_format,
                                                         '@1',
                                                         TRIM(trailing chr(10) FROM l_item));
                
                    --Antonio.Neto (19-Nov-2010) Constants needed ro remove "Free Text" from Physicians Diaries (ALERT-126888)
                    IF (l_cfg_show_free_text_det = pk_alert_constant.g_yes AND g_free_text = session_reg.intern_name)
                       OR g_free_text <> session_reg.intern_name
                    THEN
                        IF (l_item IS NOT NULL)
                        THEN
                            g_error := 'l_item is not null';
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package_name,
                                                 sub_object_name => l_func_name);
                            l_item := nvl(pk_translation.get_translation(i_lang, session_reg.code_header),
                                          session_reg.desc_header) || chr(10) || l_item;
                        ELSE
                            l_item := nvl(pk_translation.get_translation(i_lang, session_reg.code_header),
                                          session_reg.desc_header);
                        END IF;
                    END IF;
                
                    -- FORMAT item date, like it is suposed to be presented in aplication screen
                    g_error := 'CALL pk_date_utils.dt_chr_hour_tsz';
                    pk_alertlog.log_info(text            => g_error,
                                         object_name     => g_package_name,
                                         sub_object_name => l_func_name);
                    l_date := pk_date_utils.dt_chr_hour_tsz(i_lang => i_lang,
                                                            i_date => session_reg.dt_epis_recomend_tstz,
                                                            i_prof => i_prof);
                
                    -- get nickname and speciality of professional who made the session
                    g_error := 'GET PROFESSIONAL INFORMATION ' || session_reg.session_day;
                    pk_alertlog.log_info(text            => g_error,
                                         object_name     => g_package_name,
                                         sub_object_name => l_func_name);
                    SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) nick_name,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            session_reg.id_professional,
                                                            session_reg.session_day,
                                                            session_reg.id_episode) desc_speciality
                      INTO l_prof_name, l_desc_speciality
                      FROM professional prf
                     WHERE prf.id_professional = session_reg.id_professional;
                
                    g_error := 'Insert into tmp table';
                    pk_alertlog.log_info(text            => g_error,
                                         object_name     => g_package_name,
                                         sub_object_name => l_func_name);
                    -- *******************************************
                    --   INSERT INTO TMP_SUMMARY_MED_NOTES_DETAIL
                    -- *******************************************
                    INSERT INTO tmp_summary_med_notes_detail
                        (notes_date,
                         session_id,
                         notes_time,
                         id_professional,
                         notes_desc,
                         rank,
                         nick_name,
                         desc_speciality,
                         inst_abbreviation,
                         dt_notes_tstz,
                         flg_status)
                    VALUES
                        (l_date,
                         session_reg.session_id,
                         pk_date_utils.dt_chr_date_hour_tsz(i_lang, session_reg.dt_epis_recomend_tstz, i_prof),
                         NULL,
                         l_item,
                         NULL,
                         l_prof_name,
                         l_desc_speciality,
                         NULL,
                         session_reg.dt_epis_recomend_tstz,
                         l_status);
                    -- ********************************************
                END IF;
            END IF;
        END LOOP; -- end session_reg_c
    
        l_edited_msg    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_edited);
        l_cancelled_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_cancelled);
    
        --
        -- Cursor to return with information
        --
        g_error := 'OPEN o_session_detail';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_session_detail FOR
            SELECT session_id,
                   notes_date dt_epis_recomend_tstz,
                   notes_desc,
                   flg_status flg_status,
                   decode(flg_status,
                          pk_alert_constant.g_active,
                          NULL,
                          decode(flg_status, pk_touch_option.g_canceled, l_cancelled_msg, l_edited_msg) || g_colon ||
                          notes_time || g_comma || nick_name || g_open_parenthesis || desc_speciality ||
                          g_close_parenthesis) desc_signature,
                   pk_date_utils.date_send_tsz(i_lang, dt_notes_tstz, i_prof) dt_for_report,
                   pk_date_utils.date_chr_short_read(i_lang, dt_notes_tstz, i_prof) date_str,
                   id_professional,
                   nick_name,
                   desc_speciality
              FROM tmp_summary_med_notes_detail
             ORDER BY dt_notes_tstz;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_invalid_arguments THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'INVALID ARGUMENTS i_flg_scope: ' || i_flg_scope || ' i_id_episode: ' ||
                                              i_id_episode || ' i_id_patient: ' || i_id_patient || ' i_id_visit: ' ||
                                              i_id_visit || ' i_session_id: ' || i_session_id || ' i_flg_type: ' ||
                                              i_flg_type || ' i_flg_report_type: ' || i_flg_report_type ||
                                              ' i_start_date: ' || CAST(i_start_date AS VARCHAR2) || ' i_end_date: ' ||
                                              CAST(i_end_date AS VARCHAR2),
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_SESSION.INVALID_ARGUMENTS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_session_detail);
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_SESSION.OTHERS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_session_detail);
            RETURN FALSE;
        
    END get_summary_session;

    /*
    * Get summary of medical notes registered in one specific session ( registries order by time )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   i_session_id               Session_id of section to be presented in detail screen
    * @param   o_session_summary          Has summary information about current session: "Hour INIT - Hour END (DAY)"
    * @param   o_session_detail           Notes made in current session order by registry time
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Maia
    * @version 1.0
    * @since   07-JAN-2009
    * 
    * UPDATED: separated in 3 functions: get_summary_session_detail, get_summary_session and get_session_header
    * @author  Sofia Mendes
    * @version 2.5.1.3
    * @since   23-Nov-2010
    *
    */
    FUNCTION get_summary_session_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN epis_recomend.flg_type%TYPE,
        i_session_id      IN epis_recomend.session_id%TYPE,
        o_session_summary OUT VARCHAR2,
        o_session_detail  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL get_session_header; get_summary_session: ' || i_session_id;
        pk_alertlog.log_debug(g_error);
        IF NOT get_summary_session(i_lang            => i_lang,
                                   i_prof            => i_prof,
                                   i_flg_type        => i_flg_type,
                                   i_session_id      => i_session_id,
                                   i_flg_scope       => g_scope_session_s,
                                   i_id_episode      => NULL,
                                   i_id_patient      => NULL,
                                   i_id_visit        => NULL,
                                   i_flg_report_type => NULL,
                                   i_start_date      => NULL,
                                   i_end_date        => NULL,
                                   i_flg_report      => pk_alert_constant.g_no,
                                   
                                   o_session_detail => o_session_detail,
                                   o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL get_session_header; i_session_id: ' || i_session_id;
        pk_alertlog.log_debug(g_error);
        IF NOT get_session_header(i_lang            => i_lang,
                                  i_prof            => i_prof,
                                  i_flg_type        => i_flg_type,
                                  i_session_id      => i_session_id,
                                  o_session_summary => o_session_summary,
                                  o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_SESSION_DETAIL.OTHERS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_session_detail);
            RETURN FALSE;
        
    END get_summary_session_detail;

    /*
    * Get diaries info in one session, episode, patient or visit ( registries ordered by time )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   i_flg_scope                Scope: P -patient; E- episode; V-visit; S-session
    * @param   i_id_episode               Episode identifier; mandatory if i_flg_scope='E'
    * @param   i_id_patient               Patient identifier; mandatory if i_flg_scope='P'
    * @param   i_id_visit                 Visit identifier; mandatory if i_flg_scope='V'
    * @param   i_flg_report_type          Report type: C-complete; D-detailed
    * @param   i_session_id               Session_id of section to be presented in detail screen. Mandatory if i_flg_scop='S'
    * @param   i_start_date               Start date to be considered
    * @param   i_end_date                 End date to be considered    
    * @param   o_detail                   Notes made in current session/episode/patient/visit order by registry time
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sofia Mendes
    * @version 2.5.1.3
    * @since   23-Nov-2010
    *
    */
    FUNCTION get_diary_info_reports
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN epis_recomend.flg_type%TYPE,
        i_session_id      IN epis_recomend.session_id%TYPE,
        i_flg_scope       IN VARCHAR2, -- P -patient; E- episode; V-visit
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_flg_report_type IN VARCHAR2, --C-complete; D-detailed
        i_start_date      IN VARCHAR2,
        i_end_date        IN VARCHAR2,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        g_error := 'CALL GET_STRING_TSTZ FOR i_start_date';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_start_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_date,
                                             o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR i_end_date';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_end_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_date,
                                             o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL get_session_header; get_summary_session: ' || i_session_id;
        pk_alertlog.log_debug(g_error);
        IF NOT get_summary_session(i_lang            => i_lang,
                                   i_prof            => i_prof,
                                   i_flg_type        => i_flg_type,
                                   i_session_id      => i_session_id,
                                   i_flg_scope       => i_flg_scope,
                                   i_id_episode      => i_id_episode,
                                   i_id_patient      => i_id_patient,
                                   i_id_visit        => i_id_visit,
                                   i_flg_report_type => i_flg_report_type,
                                   i_start_date      => l_start_date,
                                   i_end_date        => l_end_date,
                                   i_flg_report      => pk_alert_constant.g_yes,
                                   o_session_detail  => o_detail,
                                   o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIARY_INFO_REPORTS.OTHERS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
        
    END get_diary_info_reports;

    /********************************************************************************************
    * Returns the Areas where the professional has access to write
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param i_flg_diary    Type of Diary
    *                            'P' - Physician Diary Notes
    *                            'N' - Nurse Diary Notes
    * @param o_areas        Areas with permissions to write
    * @param o_error        Error object
    *
    * @return               true if sucess, false otherwise
    *
    * @author               António Neto
    * @version              2.6.1
    * @since                13-Oct-2011
    ********************************************************************************************/
    FUNCTION get_area_write_permissions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_diary IN VARCHAR2,
        o_areas     OUT table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat VARCHAR2(1 CHAR);
        l_areas    table_varchar;
    
    BEGIN
        g_error    := 'CALL PK_PROF_UTILS.GET_CATEGORY';
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        --If Physician
        IF l_prof_cat = g_cat_doctor
        THEN
            --In Physcian Diaries Notes
            IF i_flg_diary = g_flg_diary_physician_p
            THEN
                l_areas := table_varchar(g_diary_physician, g_diary_entry_notes, g_diary_sch_disch);
            ELSE
                l_areas := table_varchar(g_diary_entry_notes, g_diary_sch_disch);
            END IF;
            --If Nurse
        ELSIF l_prof_cat = g_cat_nurse
        THEN
            --In Nurse Diaries Notes
            IF i_flg_diary = g_flg_diary_nurse_n
            THEN
                l_areas := table_varchar(g_diary_nurse, g_diary_sch_disch);
            ELSE
                l_areas := table_varchar(g_diary_sch_disch);
            END IF;
        ELSE
            l_areas := table_varchar();
        END IF;
    
        o_areas := l_areas;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AREA_WRITE_PERMISSIONS',
                                              o_error);
            RETURN FALSE;
    END get_area_write_permissions;

-- *************************************************************************************************
-- *************************************************************************************************
-- *************************************************************************************************
-- *************************************************************************************************

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END;
/
