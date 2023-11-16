/*-- Last Change Revision: $Rev: 2027077 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:55 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_edis_global_search IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations
    FUNCTION get_rec_result_epis_diagnosis
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_diagnosis%ROWTYPE
    ) RETURN t_trl_trs_result IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_REC_RESULT_EPIS_DIAGNOSIS';
        --
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
    BEGIN
        l_trl_trs_result.id_episode      := i_rowtype.id_episode;
        l_trl_trs_result.id_patient      := i_rowtype.id_patient;
        l_trl_trs_result.id_professional := pk_diagnosis_core.get_prof_diagnosis(i_lang                => NULL,
                                                                                 i_prof                => NULL,
                                                                                 i_flg_status          => i_rowtype.flg_status,
                                                                                 i_professional_diag   => i_rowtype.id_professional_diag,
                                                                                 i_prof_confirmed      => i_rowtype.id_prof_confirmed,
                                                                                 i_professional_cancel => i_rowtype.id_professional_cancel,
                                                                                 i_prof_base           => i_rowtype.id_prof_base,
                                                                                 i_prof_rulled_out     => i_rowtype.id_prof_rulled_out);
        l_trl_trs_result.dt_record       := pk_diagnosis_core.get_dt_diagnosis(i_lang              => NULL,
                                                                               i_prof              => NULL,
                                                                               i_flg_status        => i_rowtype.flg_status,
                                                                               i_dt_epis_diagnosis => i_rowtype.dt_epis_diagnosis_tstz,
                                                                               i_dt_confirmed      => i_rowtype.dt_confirmed_tstz,
                                                                               i_dt_cancel         => i_rowtype.dt_cancel_tstz,
                                                                               i_dt_base           => i_rowtype.dt_base_tstz,
                                                                               i_dt_rulled_out     => i_rowtype.dt_rulled_out_tstz);
    
        pk_alertlog.log_debug(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 to_char(l_trl_trs_result.dt_record),
                              object_name     => g_package,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_rec_result_epis_diagnosis;

    PROCEDURE get_codes_desc_epis_diagnosis
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_diagnosis%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_CODES_DESC_EPIS_DIAGNOSIS';
        --
        l_lang_all CONSTANT language.id_language%TYPE := 0;
        --
        l_code_epis_diag VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_EPIS_DIAGNOSIS.' ||
                                               i_rowtype.id_epis_diagnosis;
        l_desc_epis_diag pk_translation.t_desc_translation;
        --
        l_code_cancel_reason VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' ||
                                                   i_rowtype.id_epis_diagnosis;
        --
        CURSOR c_diag_info IS
            SELECT decode(tv.id_language, l_lang_all, i_lang, tv.id_language) id_language,
                   ad.id_alert_diagnosis,
                   d.id_diagnosis,
                   nvl(ad.code_alert_diagnosis, d.code_diagnosis) code_diagnosis,
                   d.code_icd code,
                   d.flg_other,
                   ad.flg_icd9 flg_std_diag
              FROM diagnosis d
              JOIN terminology_version tv
                ON tv.id_terminology_version = d.id_terminology_version
              LEFT JOIN alert_diagnosis ad
                ON ad.id_diagnosis = i_rowtype.id_diagnosis
               AND ad.id_alert_diagnosis =
                   nvl(i_rowtype.id_alert_diagnosis,
                       pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => i_rowtype.id_diagnosis,
                                                                          i_task_type       => pk_alert_constant.g_task_diagnosis))
             WHERE d.id_diagnosis = i_rowtype.id_diagnosis
               AND rownum = 1;
    
        r_diag_info c_diag_info%ROWTYPE;
    BEGIN
        OPEN c_diag_info;
        FETCH c_diag_info
            INTO r_diag_info;
        CLOSE c_diag_info;
    
        l_desc_epis_diag := pk_diagnosis.std_diag_desc(i_lang                => r_diag_info.id_language,
                                                       i_prof                => i_prof,
                                                       i_id_alert_diagnosis  => r_diag_info.id_alert_diagnosis,
                                                       i_id_diagnosis        => r_diag_info.id_diagnosis,
                                                       i_code_diagnosis      => r_diag_info.code_diagnosis,
                                                       i_diagnosis_language  => r_diag_info.id_language,
                                                       i_desc_epis_diagnosis => i_rowtype.desc_epis_diagnosis,
                                                       i_code                => r_diag_info.code,
                                                       i_flg_other           => r_diag_info.flg_other,
                                                       i_flg_std_diag        => r_diag_info.flg_std_diag,
                                                       i_show_aditional_info => pk_alert_constant.g_no,
                                                       i_ed_rowtype          => i_rowtype) ||
                            pk_diagnosis.get_origin_diagnosis(i_lang,
                                                              i_prof,
                                                              i_rowtype.id_episode,
                                                              i_rowtype.id_episode_origin);
    
        pk_alertlog.log_debug(text            => 'LANG: ' || i_lang || '; PROF: (' || i_prof.id || ', ' ||
                                                 i_prof.institution || ', ' || i_prof.software || '); ID_EPIS_DIAG: ' ||
                                                 i_rowtype.id_epis_diagnosis || '; DESC_DIAG: ' || l_desc_epis_diag,
                              object_name     => g_package,
                              sub_object_name => k_function_name);
    
        o_code_list := table_varchar(l_code_epis_diag);
        o_desc_list := table_varchar(l_desc_epis_diag);
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            o_code_list.extend;
            o_code_list(o_code_list.count) := l_code_cancel_reason;
        
            o_desc_list.extend;
            o_desc_list(o_desc_list.count) := pk_cancel_reason.get_cancel_reason_desc(i_lang,
                                                                                      i_prof,
                                                                                      i_rowtype.id_cancel_reason);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
    END get_codes_desc_epis_diagnosis;

    -- PAT_HABIT
    FUNCTION get_rec_result_pat_habit
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN pat_habit%ROWTYPE
    ) RETURN t_trl_trs_result IS
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_REC_RESULT_PAT_HABIT';
    
    BEGIN
        l_trl_trs_result.id_episode := i_rowtype.id_episode;
        l_trl_trs_result.id_patient := i_rowtype.id_patient;
    
        -- flg_status  varchar2(1)      estado: a - activo, c - cancelado pelo prof., u - cancelado pelo utente
    
        CASE i_rowtype.flg_status
            WHEN pk_patient.g_pat_habit_active THEN
                -- Active
                BEGIN
                    l_trl_trs_result.id_professional := i_rowtype.id_prof_writes;
                    l_trl_trs_result.dt_record       := i_rowtype.dt_pat_habit_tstz;
                END;
            WHEN pk_patient.g_pat_habit_canc THEN
                -- Cancel
                BEGIN
                    l_trl_trs_result.id_professional := i_rowtype.id_prof_cancel;
                    l_trl_trs_result.dt_record       := i_rowtype.dt_cancel_tstz;
                END;
        END CASE;
    
        l_trl_trs_result.id_task_type := NULL;
    
        pk_alertlog.log_debug(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 to_char(l_trl_trs_result.dt_record),
                              object_name     => g_package,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_rec_result_pat_habit;

    -- PAT_HABIT Code
    PROCEDURE get_codes_desc_pat_habit
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN pat_habit%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_CODES_DESC_PAT_HABIT';
    
        l_code_habit VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_HABIT.' || i_rowtype.id_pat_habit;
    
        l_code_cancel_reason VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' ||
                                                   i_rowtype.id_pat_habit;
    
        l_code_habit_characterization VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table ||
                                                            '.ID_HABIT_CHARACTERIZATION.' || i_rowtype.id_pat_habit;
    
    BEGIN
        o_code_list := table_varchar(l_code_habit);
        o_desc_list := table_varchar(pk_translation.get_translation(i_lang, 'HABIT.CODE_HABIT.' || i_rowtype.id_habit));
    
        IF i_rowtype.id_habit_characterization IS NOT NULL
        THEN
        
            o_code_list.extend;
            o_code_list(o_code_list.last) := l_code_habit_characterization;
        
            o_desc_list.extend;
            o_desc_list(o_desc_list.last) := pk_translation.get_translation(i_lang,
                                                                            'HABIT_CHARACTERIZATION.CODE_HABIT_CHARACTERIZATION.' ||
                                                                            i_rowtype.id_habit_characterization);
        END IF;
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            o_code_list.extend;
            o_code_list(o_code_list.last) := l_code_cancel_reason;
        
            o_desc_list.extend;
            o_desc_list(o_desc_list.last) := pk_cancel_reason.get_cancel_reason_desc(i_lang,
                                                                                     i_prof,
                                                                                     i_rowtype.id_cancel_reason);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
        
    END get_codes_desc_pat_habit;

    -- EPIS_DIAGNOSIS_NOTES
    FUNCTION get_rec_result_epis_diag_notes
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_diagnosis_notes%ROWTYPE
    ) RETURN t_trl_trs_result IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_REC_RESULT_EPIS_DIAG_NOTES';
    
        CURSOR c_cur IS
            SELECT ep.id_patient
              FROM episode ep
             WHERE ep.id_episode = i_rowtype.id_episode;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_patient;
        CLOSE c_cur;
    
        l_trl_trs_result.id_episode := i_rowtype.id_episode;
    
        IF i_rowtype.dt_cancel IS NULL
        THEN
            -- Is Create
            l_trl_trs_result.id_professional := i_rowtype.id_prof_create;
            l_trl_trs_result.dt_record       := i_rowtype.dt_create;
        ELSE
            -- Is Cancel
            l_trl_trs_result.id_professional := i_rowtype.id_prof_cancel;
            l_trl_trs_result.dt_record       := i_rowtype.dt_cancel;
        END IF;
    
        l_trl_trs_result.id_task_type := NULL;
    
        pk_alertlog.log_debug(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 to_char(l_trl_trs_result.dt_record),
                              object_name     => g_package,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_rec_result_epis_diag_notes;

    -- EPIS_DIAGNOSIS_NOTES Code
    PROCEDURE get_codes_desc_epis_diag_notes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_diagnosis_notes%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_CODES_DESC_EPIS_DIAG_NOTES';
    
        l_code_cancel_reason VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' ||
                                                   i_rowtype.id_epis_diagnosis_notes;
    
    BEGIN
        o_code_list := table_varchar();
        o_desc_list := table_varchar();
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            o_code_list := table_varchar(l_code_cancel_reason);
            o_desc_list := table_varchar(pk_cancel_reason.get_cancel_reason_desc(i_lang,
                                                                                 i_prof,
                                                                                 i_rowtype.id_cancel_reason));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
        
    END get_codes_desc_epis_diag_notes;

    -- PAT_ALLERGY
    FUNCTION get_rec_result_pat_allergy
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN pat_allergy%ROWTYPE
    ) RETURN t_trl_trs_result IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_REC_RESULT_PAT_ALLERGY';
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
    
    BEGIN
        -- id_episode
        l_trl_trs_result.id_episode := i_rowtype.id_episode;
    
        -- id_patient      
        l_trl_trs_result.id_patient := i_rowtype.id_patient;
    
        -- id_professional
        l_trl_trs_result.id_professional := i_rowtype.id_prof_write;
    
        -- dt_record
        l_trl_trs_result.dt_record := i_rowtype.dt_pat_allergy_tstz;
    
        -- id_task_type    
        l_trl_trs_result.id_task_type := NULL;
    
        pk_alertlog.log_debug(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 to_char(l_trl_trs_result.dt_record),
                              object_name     => g_package,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_rec_result_pat_allergy;

    -- PAT_ALLERGY Code
    PROCEDURE get_codes_desc_pat_allergy
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN pat_allergy%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_CODES_DESC_PAT_ALLERGY';
    
        l_code_allergy VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_ALLERGY.' ||
                                             i_rowtype.id_pat_allergy;
    
        l_code_cancel_reason VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' ||
                                                   i_rowtype.id_pat_allergy;
    
        l_code_allergy_severity VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_ALLERGY_SEVERITY.' ||
                                                      i_rowtype.id_pat_allergy;
    
    BEGIN
        o_code_list := table_varchar();
        o_desc_list := table_varchar();
    
        IF i_rowtype.id_allergy IS NOT NULL
        THEN
            o_code_list.extend;
            o_code_list(o_code_list.last) := l_code_allergy;
        
            o_desc_list.extend;
            o_desc_list(o_desc_list.last) := pk_translation.get_translation(i_lang,
                                                                            'ALLERGY.CODE_ALLERGY.' ||
                                                                            i_rowtype.id_allergy);
        END IF;
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            o_code_list.extend;
            o_code_list(o_code_list.last) := l_code_cancel_reason;
        
            o_desc_list.extend;
            o_desc_list(o_desc_list.last) := pk_cancel_reason.get_cancel_reason_desc(i_lang,
                                                                                     i_prof,
                                                                                     i_rowtype.id_cancel_reason);
        END IF;
    
        IF i_rowtype.id_allergy_severity IS NOT NULL
        THEN
            o_code_list.extend;
            o_code_list(o_code_list.last) := l_code_allergy_severity;
        
            o_desc_list.extend;
            o_desc_list(o_desc_list.last) := pk_translation.get_translation(i_lang,
                                                                            'ALLERGY_SEVERITY.CODE_ALLERGY_SEVERITY.' ||
                                                                            i_rowtype.id_allergy_severity);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
        
    END get_codes_desc_pat_allergy;

    -- PAT_ALLERGY_SYMPTOMS
    FUNCTION get_rec_result_pat_allergy_sym
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN pat_allergy_symptoms%ROWTYPE
    ) RETURN t_trl_trs_result IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_REC_RESULT_PAT_ALLERGY_SYMPTOMS';
    
        CURSOR c_cur IS
            SELECT pa.id_episode, pa.id_patient, pa.id_prof_write, pa.dt_pat_allergy_tstz
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_rowtype.id_pat_allergy;
    
        l_id_episode          pat_allergy.id_episode%TYPE;
        l_id_patient          pat_allergy.id_patient%TYPE;
        l_id_prof_write       pat_allergy.id_prof_write%TYPE;
        l_dt_pat_allergy_tstz pat_allergy.dt_pat_allergy_tstz%TYPE;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
    
    BEGIN
    
        OPEN c_cur;
        FETCH c_cur
            INTO l_id_episode, l_id_patient, l_id_prof_write, l_dt_pat_allergy_tstz;
        CLOSE c_cur;
    
        -- id_episode
        l_trl_trs_result.id_episode := l_id_episode;
    
        -- id_patient      
        l_trl_trs_result.id_patient := l_id_patient;
    
        -- id_professional
        l_trl_trs_result.id_professional := l_id_prof_write;
    
        -- dt_record
        l_trl_trs_result.dt_record := l_dt_pat_allergy_tstz;
    
        -- id_task_type    
        l_trl_trs_result.id_task_type := NULL;
    
        pk_alertlog.log_debug(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 to_char(l_trl_trs_result.dt_record),
                              object_name     => g_package,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_rec_result_pat_allergy_sym;

    -- PAT_ALLERGY_SYMPTOMS Code
    PROCEDURE get_codes_desc_pat_allergy_sym
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN pat_allergy_symptoms%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_CODES_DESC_PAT_ALLERGY_SYMPTOMS';
    
        l_code_allergy_symptoms VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_ALLERGY_SYMPTOMS.' ||
                                                      i_rowtype.id_pat_allergy || '.' || i_rowtype.id_allergy_symptoms;
    
    BEGIN
        o_code_list := table_varchar();
        o_desc_list := table_varchar();
    
        o_code_list.extend;
        o_code_list(o_code_list.last) := l_code_allergy_symptoms;
    
        o_desc_list.extend;
        o_desc_list(o_desc_list.last) := pk_translation.get_translation(i_lang,
                                                                        'ALLERGY_SYMPTOMS.CODE_ALLERGY_SYMPTOMS.' ||
                                                                        i_rowtype.id_allergy_symptoms);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
        
    END get_codes_desc_pat_allergy_sym;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_edis_global_search;
/
