/*-- Last Change Revision: $Rev: 2027849 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_viewer AS

    FUNCTION get_synch
    (
        i_lang   IN language.id_language%TYPE,
        i_viewer IN viewer.id_viewer%TYPE,
        i_prof   IN profissional,
        o_synch  OUT pk_types.cursor_type,
        o_param  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_profile_template profile_template.id_profile_template%TYPE;
    
        l_has_viewer VARCHAR2(1);
    
    BEGIN
    
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        IF i_viewer = 1
        THEN
            BEGIN
                SELECT pk_alert_constant.g_yes
                  INTO l_has_viewer
                  FROM profile_template pt
                 WHERE pt.id_profile_template = l_profile_template
                   AND pt.id_templ_assoc != 0;
            EXCEPTION
                WHEN no_data_found THEN
                    pk_types.open_my_cursor(o_synch);
                    pk_types.open_my_cursor(o_param);
                
                    RETURN TRUE;
            END;
        ELSE
            l_has_viewer := pk_alert_constant.g_yes;
        END IF;
    
        g_error := 'GET O_SYNCH';
        OPEN o_synch FOR
            SELECT t.id_viewer_synchronize,
                   t.host_screen,
                   t.operation,
                   t.viewer_screen,
                   t.flg_state,
                   t.leaf_sys_button,
                   t.id_viewer,
                   t.mc_name
              FROM (SELECT vs.id_viewer_synchronize,
                           vs.host_screen,
                           vs.operation,
                           vs.viewer_screen,
                           vs.flg_state,
                           vs.leaf_sys_button,
                           vs.id_viewer,
                           v.mc_name,
                           row_number() over(PARTITION BY vs.id_viewer, vs.host_screen, vs.flg_state ORDER BY vs.id_institution DESC, vs.id_software DESC, vs.id_profile_template DESC, vs.operation ASC) rn
                      FROM viewer_synchronize vs
                      JOIN viewer v
                        ON v.id_viewer = vs.id_viewer
                     WHERE vs.id_viewer = i_viewer
                       AND vs.operation IN ('SHOW', 'HIDE', 'HTML_SHOW', 'HTML_HIDE')
                       AND vs.id_institution IN (0, i_prof.institution)
                       AND vs.id_software IN (0, i_prof.software)
                       AND vs.id_profile_template IN (0, l_profile_template)
                       AND l_has_viewer = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT vs.id_viewer_synchronize,
                           vs.host_screen,
                           vs.operation,
                           vs.viewer_screen,
                           vs.flg_state,
                           vs.leaf_sys_button,
                           vs.id_viewer,
                           v.mc_name,
                           row_number() over(PARTITION BY vs.id_viewer, vs.host_screen, vs.flg_state ORDER BY vs.id_institution DESC, vs.id_software DESC, vs.id_profile_template DESC) rn
                      FROM viewer_synchronize vs
                      JOIN viewer v
                        ON v.id_viewer = vs.id_viewer
                     WHERE vs.id_viewer = i_viewer
                       AND vs.operation = 'CLEAR'
                       AND vs.id_institution IN (0, i_prof.institution)
                       AND vs.id_software IN (0, i_prof.software)
                       AND vs.id_profile_template IN (0, l_profile_template)
                       AND l_has_viewer = pk_alert_constant.g_yes) t
             WHERE t.rn = 1
             ORDER BY t.id_viewer_synchronize;
    
        g_error := 'GET O_PARAM';
        OPEN o_param FOR
            SELECT t.id_viewer_synchronize, t.name, t.value
              FROM (SELECT vs.id_viewer_synchronize,
                           vsp.name,
                           vsp.value,
                           row_number() over(PARTITION BY vs.id_viewer, vs.host_screen, vs.flg_state ORDER BY vs.id_institution DESC, vs.id_software DESC, vs.id_profile_template DESC, vs.operation ASC) rn
                      FROM viewer_synchronize vs, viewer_synch_param vsp
                     WHERE vs.id_viewer = i_viewer
                       AND vs.operation IN ('SHOW', 'HIDE', 'HTML_SHOW', 'HTML_HIDE')
                       AND vsp.id_viewer_synchronize = vs.id_viewer_synchronize
                       AND vs.id_institution IN (0, i_prof.institution)
                       AND vs.id_software IN (0, i_prof.software)
                       AND vs.id_profile_template IN (0, l_profile_template)
                       AND l_has_viewer = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT vs.id_viewer_synchronize,
                           vsp.name,
                           vsp.value,
                           row_number() over(PARTITION BY vs.id_viewer, vs.host_screen, vs.operation, vs.flg_state ORDER BY vs.id_institution DESC, vs.id_software DESC, vs.id_profile_template DESC) rn
                      FROM viewer_synchronize vs, viewer_synch_param vsp
                     WHERE vs.id_viewer = i_viewer
                       AND vs.operation = 'CLEAR'
                       AND vsp.id_viewer_synchronize = vs.id_viewer_synchronize
                       AND vs.id_institution IN (0, i_prof.institution)
                       AND vs.id_software IN (0, i_prof.software)
                       AND vs.id_profile_template IN (0, l_profile_template)
                       AND l_has_viewer = pk_alert_constant.g_yes) t
             WHERE t.rn = 1
             ORDER BY t.id_viewer_synchronize;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SYNCH',
                                              o_error);
            pk_types.open_my_cursor(o_synch);
            pk_types.open_my_cursor(o_param);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_synch;

    FUNCTION get_refresh
    (
        i_lang    IN language.id_language%TYPE,
        i_viewer  IN viewer.id_viewer%TYPE,
        i_prof    IN profissional,
        o_refresh OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET O_REFRESH';
        OPEN o_refresh FOR
            SELECT vr.id_viewer, vr.viewer_screen, vr.service, v.mc_name
              FROM viewer_refresh vr
              JOIN viewer v
                ON v.id_viewer = vr.id_viewer
             WHERE vr.id_viewer = i_viewer
             ORDER BY viewer_screen;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REFRESH',
                                              o_error);
            pk_types.open_my_cursor(o_refresh);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_refresh;

    FUNCTION get_viewer_shortcut
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_shortcut     IN sys_shortcut.id_sys_shortcut%TYPE,
        o_sys_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_access        pk_types.cursor_type;
        l_has_sign_off  VARCHAR(1 CHAR);
        l_dummy         pk_types.cursor_type;
        l_access_rowcnt NUMBER;
    
    BEGIN
    
        g_error := 'GET_SHORTCUT';
        IF NOT pk_access.get_shortcut(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_patient => NULL,
                                      i_episode => i_episode,
                                      i_short   => i_shortcut,
                                      o_access  => l_access,
                                      o_prt     => l_dummy,
                                      o_error   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error         := 'CALL pk_utils.get_rowcount';
        l_access_rowcnt := pk_utils.get_rowcount(io_cursor => l_access);
    
        g_error := 'GET_SIGN_OFF';
        IF NOT pk_sign_off.get_epis_sign_off_state(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_episode  => i_episode,
                                                   o_sign_off => l_has_sign_off,
                                                   o_error    => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_access_rowcnt < 1
           OR l_has_sign_off = pk_alert_constant.g_yes
        THEN
            o_sys_shortcut := NULL;
        ELSE
            o_sys_shortcut := i_shortcut;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VIEWER_SHORTCUT',
                                              o_error);
            RETURN FALSE;
    END get_viewer_shortcut;

    FUNCTION get_date_interval
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_interval IN VARCHAR2,
        o_dt_begin OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_dt_end   OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALCULATE THE INTERVAL FOR DATES';
        CASE i_interval
            WHEN g_interval_last24h_d THEN
                --D-Last 24H
                o_dt_begin := pk_date_utils.add_days_to_tstz(g_sysdate_tstz, -1);
                o_dt_end   := g_sysdate_tstz;
            WHEN g_interval_week_w THEN
                --W-Week
                o_dt_begin := pk_date_utils.add_days_to_tstz(g_sysdate_tstz, -7);
                o_dt_end   := g_sysdate_tstz;
            WHEN g_interval_month_m THEN
                --M-Month
                o_dt_begin := pk_date_utils.non_ansi_add_months(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_date         => g_sysdate_tstz,
                                                                i_nr_of_months => -1,
                                                                o_error        => o_error);
                o_dt_end   := g_sysdate_tstz;
            ELSE
                --A-All or NULL
                o_dt_begin := NULL;
                o_dt_end   := NULL;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATE_INTERVAL',
                                              o_error);
            RETURN FALSE;
    END get_date_interval;

    FUNCTION get_pat_ehr_ea
    (
        i_lang        IN language.id_language%TYPE,
        i_prof_id     IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_patient     IN patient.id_patient%TYPE
    ) RETURN pk_types.cursor_type IS
    
        l_prof profissional := profissional(i_prof_id, i_institution, i_software);
    
        l_list pk_types.cursor_type;
    
    BEGIN
    
        --The aliases must be as they are (ex: descAllergy, dtAllergy, etc.) because of the Java layer.
        --They also have to be between quotation marks in order for the Java not to uppercase them.
        g_error := 'OPEN l_list';
        OPEN l_list FOR
            SELECT vea.id_patient AS "idPatient",
                   --allergies
                   vea.num_allergy AS "numAllergy",
                   nvl(vea.desc_allergy, pk_translation.get_translation(i_lang, vea.code_allergy)) AS "descAllergy",
                   vea.dt_allergy AS "dtAllergy",
                   decode(vea.dt_allergy_fmt,
                          'Y',
                          pk_date_utils.get_year(i_lang, l_prof, vea.dt_allergy),
                          'M',
                          pk_date_utils.get_month_year(i_lang, l_prof, vea.dt_allergy),
                          'D',
                          pk_date_utils.dt_chr_tsz(i_lang, vea.dt_allergy, l_prof),
                          pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_allergy, l_prof)) AS "dtAllergyFormatted",
                   --notes
                   vea.num_note AS "numNote",
                   nvl(vea.desc_note, nvl(pk_translation.get_translation(i_lang, vea.code_note), vea.code_note)) AS "descNote",
                   vea.dt_note AS "dtNote",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_note, l_prof) AS "dtNoteFormatted",
                   --vital signs
                   vea.num_vs AS "numVs",
                   nvl(vea.desc_vs, nvl(pk_translation.get_translation(i_lang, vea.code_vs), vea.code_vs)) AS "descVs",
                   vea.dt_vs AS "dtVs",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_vs, l_prof) AS "dtVsFormatted",
                   --labs
                   vea.num_lab AS "numLab",
                   nvl(vea.desc_lab,
                       nvl(pk_hibernate_intf.get_lab_test_desc(i_lang,
                                                               l_prof,
                                                               pk_lab_tests_constant.g_analysis_alias,
                                                               vea.code_lab),
                           vea.code_lab)) AS "descLab",
                   vea.dt_lab AS "dtLab",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_lab, l_prof) AS "dtLabFormatted",
                   --icnp
                   vea.num_diag_icnp AS "numDiagIcnp",
                   nvl(vea.desc_diag_icnp,
                       nvl(pk_translation.get_translation(i_lang, vea.code_diag_icnp), vea.code_diag_icnp)) AS "descDiagIcnp",
                   vea.dt_diag_icnp AS "dtDiagIcnp",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_diag_icnp, l_prof) AS "dtDiagIcnpFormatted",
                   --episode
                   vea.num_episode AS "numEpisode",
                   nvl(vea.desc_episode,
                       nvl(pk_translation.get_translation(i_lang, vea.code_episode), vea.code_episode)) AS "descEpisode",
                   vea.dt_episode AS "dtEpisode",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_episode, l_prof) AS "dtEpisodeFormatted",
                   --episode and archive
                   vea.num_epis_archive AS "numEpisArchive",
                   nvl(vea.desc_epis_archive,
                       nvl(pk_translation.get_translation(i_lang, vea.code_epis_archive), vea.code_epis_archive)) AS "descEpisArchive",
                   vea.dt_epis_archive AS "dtEpisArchive",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_epis_archive, l_prof) AS "dtEpisArchiveFormatted",
                   --archive
                   vea.num_archive AS "numArchive",
                   nvl(vea.desc_archive,
                       nvl(pk_translation.get_translation(i_lang, vea.code_archive), vea.code_archive)) AS "descArchive",
                   vea.dt_archive AS "dtArchive",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_archive, l_prof) AS "dtArchiveFormatted",
                   --exams
                   vea.num_exam AS "numExam",
                   nvl(vea.desc_exam,
                       nvl(pk_exams_api_db.get_alias_translation(i_lang, l_prof, vea.code_exam), vea.code_exam)) AS "descExam",
                   vea.dt_exam AS "dtExam",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_exam, l_prof) AS "dtExamFormatted",
                   --medication
                   vea.num_med AS "numMed",
                   nvl(vea.desc_med, nvl(pk_translation.get_translation(i_lang, vea.code_med), vea.code_med)) AS "descMed",
                   vea.dt_med AS "dtMed",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_med, l_prof) AS "dtMedFormatted",
                   --problems
                   vea.num_problem AS "numProblem",
                   coalesce(vea.desc_problem,
                             CASE
                                 WHEN vea.id_problem IS NOT NULL THEN
                                  pk_ts_core_ro.get_term_desc_translation(i_lang,
                                                                          vea.id_problem,
                                                                          nvl(vea.id_task_type, pk_alert_constant.g_task_diagnosis))
                                 ELSE
                                  NULL
                             END,
                             CASE
                                 WHEN vea.code_problem IS NOT NULL
                                      AND vea.code_problem LIKE 'CONCEPT_TERM.CODE_CONCEPT_TERM.%' THEN
                                  pk_ts_core_ro.get_term_desc_translation(i_lang,
                                                                          regexp_replace(vea.code_problem,
                                                                                         'CONCEPT_TERM.CODE_CONCEPT_TERM.'),
                                                                          pk_alert_constant.g_task_problems)
                                 ELSE
                                  NULL
                             END,
                             nvl(pk_translation.get_translation(i_lang, vea.code_problem), vea.code_problem)) AS "descProblem",
                   vea.dt_problem AS "dtProblem",
                   decode(vea.dt_problem_fmt,
                          'Y',
                          pk_date_utils.get_year(i_lang, l_prof, vea.dt_problem),
                          'M',
                          pk_date_utils.get_month_year(i_lang, l_prof, vea.dt_problem),
                          'D',
                          pk_date_utils.dt_chr_tsz(i_lang, vea.dt_problem, l_prof),
                          pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_problem, l_prof)) AS "dtProblemFormatted",
                   --interventions
                   vea.num_interv AS "numInterv",
                   nvl(vea.desc_interv,
                       nvl(pk_procedures_api_db.get_alias_translation(i_lang, l_prof, vea.code_interv), vea.code_interv)) AS "descInterv",
                   vea.dt_interv AS "dtInterv",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_interv, l_prof) AS "dtIntervFormatted",
                   --blood products
                   vea.num_bp AS "numBP",
                   nvl(vea.desc_bp, nvl(pk_translation.get_translation(i_lang, vea.code_bp), vea.code_bp)) AS "descBP",
                   vea.dt_bp AS "dtBP",
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, vea.dt_bp, l_prof) AS "dtBPFormatted"
              FROM viewer_ehr_ea vea
             WHERE vea.id_patient = i_patient;
    
        RETURN l_list;
    
    END get_pat_ehr_ea;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_viewer;
/
