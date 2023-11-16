/*-- Last Change Revision: $Rev: 2050053 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-11-11 11:35:03 +0000 (sex, 11 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sample_text IS

    k_action_add  CONSTANT NUMBER := pk_hhc_constant.k_action_add;
    k_action_edit CONSTANT NUMBER := pk_hhc_constant.k_action_edit;

    CURSOR g_pat(i_patient IN NUMBER) IS
        SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
          FROM patient
         WHERE id_patient = i_patient;

    --***************************************************
    FUNCTION get_pat_info(i_patient IN NUMBER) RETURN g_pat%ROWTYPE IS
        c_return g_pat%ROWTYPE;
    BEGIN
    
        OPEN g_pat(i_patient);
        FETCH g_pat
            INTO c_return;
        CLOSE g_pat;
    
        RETURN c_return;
    
    END get_pat_info;

    --******************************************************
    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_sample) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL rank, NULL title, NULL text, NULL code_icd, NULL id_diagnosis, NULL flg_class
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    --**************************************************
    FUNCTION get_prof_category(i_prof IN profissional) RETURN NUMBER IS
        k_default_lang CONSTANT NUMBER := 2;
    BEGIN
        RETURN pk_prof_utils.get_id_category(k_default_lang, i_prof);
    END get_prof_category;

        /******************************************************************************
           OBJECTIVO:   Obter textos de deteminado tipo.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_SAMPLE_TEXT_TYPE - Nome interno do tipo de texto 
                       I_PROF - Profissional q acede
                  Saida:   O_SAMPLE_TEXT - textos e títulos
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/29
          NOTAS: 
          Deprecated. Use get_large_sample_text to avoid the varchar limit of 4000 bytes 
        *********************************************************************************/
    FUNCTION get_sample_text
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_type IN sample_text_type.intern_name_sample_text_type%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_prof             IN alert.profissional,
        o_sample_text      OUT cursor_sample,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cat prof_cat.id_category%TYPE;
        r_pat   g_pat%ROWTYPE;
        g_error VARCHAR2(4000);
    BEGIN
        g_error := 'OPEN C_CAT';
        l_cat   := get_prof_category(i_prof);
    
        g_error := 'OPEN C_PAT';
        r_pat   := get_pat_info(i_patient);
    
        g_error := 'GET CURSOR';
        OPEN o_sample_text FOR
            SELECT rank,
                   decode(needs_translation, 1, title_trl, title) title,
                   decode(needs_translation, 1, text_trl, text) text,
                   code_icd,
                   id_diagnosis,
                   flg_class
              FROM (SELECT *
                      FROM (SELECT 1 needs_translation,
                                   st.rank,
                                   st.code_title_sample_text title,
                                   st.code_desc_sample_text text,
                                   pk_translation.get_translation(i_lang, st.code_title_sample_text) title_trl,
                                   pk_translation.get_translation(i_lang, st.code_desc_sample_text) text_trl,
                                   st.code_icd,
                                   st.id_diagnosis,
                                   st.flg_class
                              FROM sample_text_soft_inst sts
                              JOIN sample_text_type stt
                                ON sts.id_sample_text_type = stt.id_sample_text_type
                              JOIN sample_text st
                                ON sts.id_sample_text = st.id_sample_text
                             WHERE upper(stt.intern_name_sample_text_type) = upper(i_sample_text_type)
                               AND sts.id_software = i_prof.software
                               AND sts.id_institution = i_prof.institution
                               AND st.flg_available = g_stext_avail
                               AND stt.flg_available = g_stext_type_avail
                               AND EXISTS (SELECT 1
                                      FROM sample_text_type_cat sttc
                                     WHERE sttc.id_sample_text_type = stt.id_sample_text_type
                                       AND sttc.id_category = l_cat
                                       AND sttc.id_institution IN (0, i_prof.institution))
                               AND ((r_pat.gender IS NOT NULL AND nvl(st.gender, 'I') IN ('I', r_pat.gender)) OR
                                    r_pat.gender IS NULL OR r_pat.gender = 'I')
                               AND (nvl(r_pat.age, 0) BETWEEN nvl(st.age_min, 0) AND
                                    nvl(st.age_max, nvl(r_pat.age, 0)) OR nvl(r_pat.age, 0) = 0)
                               AND rownum > 0) t1
                     WHERE t1.title_trl IS NOT NULL
                       AND t1.text_trl IS NOT NULL
                    UNION ALL
                    SELECT *
                      FROM (SELECT 0 needs_translation,
                                   stf.rank,
                                   stf.title_sample_text_prof title,
                                   pk_string_utils.clob_to_sqlvarchar2(stf.desc_sample_text_prof) text,
                                   NULL title_trl,
                                   NULL text_trl,
                                   NULL code_icd,
                                   NULL id_diagnosis,
                                   NULL flg_class
                              FROM sample_text_type stt
                             INNER JOIN sample_text_prof stf
                                ON stt.id_sample_text_type = stf.id_sample_text_type
                             WHERE upper(stt.intern_name_sample_text_type) = upper(i_sample_text_type)
                               AND stf.id_software = i_prof.software
                               AND EXISTS (SELECT 1
                                      FROM sample_text_type_cat sttc
                                     WHERE sttc.id_sample_text_type = stt.id_sample_text_type
                                       AND sttc.id_category = l_cat
                                       AND sttc.id_institution IN (0, i_prof.institution))
                                  --AND stf.id_institution IN (0, i_prof.institution)
                               AND stf.id_professional = i_prof.id
                               AND stf.id_software = i_prof.software
                               AND rownum > 0) t2
                     WHERE t2.title IS NOT NULL
                       AND t2.text IS NOT NULL)
             ORDER BY rank, title; --, text;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SAMPLE_TEXT',
                                              'GET_SAMPLE_TEXT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            open_my_cursor(o_sample_text);
            RETURN FALSE;
    END get_sample_text;

    /********************************************************************************************
    * Get predefined texts
    * The function uses large objects for descritions to avoid the varchar limit of 4000 chars 
    *
    * @param i_lang                      Language ID
    * @param i_sample_text_type          Internal text type
    * @param i_patient                   Patient
    * @param i_prof                      Professional
    * @param i_episode                   Episode ID (Optional) If it is sent and there is a predefined text associated to current episode's complaint that is pre-selected as default
    * @param o_sample_text               Predefined texts
    * @param o_error                     Error info
    *                        
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.7
    * @since   10-Fev-10
    **********************************************************************************************/
    FUNCTION get_large_sample_text
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_type IN sample_text_type.intern_name_sample_text_type%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_prof             IN alert.profissional,
        i_episode          IN episode.id_episode%TYPE DEFAULT NULL,
        o_sample_text      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        function_call_excep EXCEPTION;
    
        l_cat    prof_cat.id_category%TYPE;
        l_gender patient.gender%TYPE;
        l_age    patient.age%TYPE;
        l_diag   diagnosis.id_diagnosis%TYPE;
        l_code   diagnosis.code_icd%TYPE;
    
        --*******************************************
        PROCEDURE l_process_error
        (
            i_sqlcode IN NUMBER,
            i_sqlerrm IN VARCHAR2,
            i_error   IN VARCHAR2
        ) IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang,
                                              i_sqlcode,
                                              i_sqlerrm,
                                              i_error,
                                              'ALERT',
                                              'PK_SAMPLE_TEXT',
                                              'GET_LARGE_SAMPLE_TEXT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sample_text);
        
        END l_process_error;
    
    BEGIN
    
        g_error := 'pk_prof_utils.get_id_category';
        l_cat   := get_prof_category(i_prof);
    
        g_error := 'pk_patient.get_pat_info_by_patient';
        IF NOT pk_patient.get_pat_info_by_patient(i_lang    => i_lang,
                                                  i_patient => i_patient,
                                                  o_gender  => l_gender,
                                                  o_age     => l_age)
        THEN
            RAISE function_call_excep;
        END IF;
    
        --Selects by default the predefined text that is associated to current complaint's diagnosis 
        IF i_episode IS NOT NULL
        THEN
            g_error := 'GET PK_CLINICAL_INFO.GET_ANAMNESIS_CODE';
            IF NOT pk_clinical_info.get_anamnesis_code(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_prof    => i_prof,
                                                       o_code    => l_code,
                                                       o_id_diag => l_diag,
                                                       o_error   => o_error)
            THEN
                RAISE function_call_excep;
            END IF;
        
        END IF;
    
        g_error := 'OPEN o_sample_text';
        OPEN o_sample_text FOR
            SELECT rank, title, text, code_icd, id_diagnosis, flg_class, flg_default
              FROM (SELECT rank,
                           decode(needs_translation, 1, pk_translation.get_translation(i_lang, title), title) title,
                           decode(needs_translation, 1, to_clob(pk_translation.get_translation(i_lang, text)), text) text,
                           code_icd,
                           id_diagnosis,
                           flg_class,
                           decode(nvl(id_diagnosis, 0), nvl(l_diag, -1), pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
                      FROM (
                            -- Predefined texts inserted by Alert
                            SELECT 1 needs_translation,
                                    st.rank,
                                    st.code_title_sample_text title,
                                    to_clob(st.code_desc_sample_text) text,
                                    st.code_icd,
                                    st.id_diagnosis,
                                    st.flg_class
                              FROM sample_text_soft_inst sts
                             INNER JOIN sample_text st
                                ON sts.id_sample_text = st.id_sample_text
                             INNER JOIN (SELECT DISTINCT stt.id_sample_text_type, stt.intern_name_sample_text_type
                                           FROM sample_text_type stt
                                          INNER JOIN sample_text_type_cat sttc
                                             ON stt.id_sample_text_type = sttc.id_sample_text_type
                                          WHERE upper(stt.intern_name_sample_text_type) = upper(i_sample_text_type)
                                            AND stt.flg_available = pk_alert_constant.g_yes
                                            AND sttc.id_institution IN (i_prof.institution, 0)
                                            AND sttc.id_category = l_cat) stt
                                ON stt.id_sample_text_type = sts.id_sample_text_type
                             WHERE upper(stt.intern_name_sample_text_type) = upper(i_sample_text_type)
                               AND sts.id_software = i_prof.software
                               AND sts.id_institution = i_prof.institution
                               AND st.flg_available = pk_alert_constant.g_yes
                               AND sts.flg_available = pk_alert_constant.g_yes
                               AND pk_patient.validate_pat_gender(l_gender, st.gender) = 1
                               AND (st.age_min <= l_age OR st.age_min IS NULL OR l_age IS NULL)
                               AND (st.age_max >= l_age OR st.age_max IS NULL OR l_age IS NULL)
                            
                            UNION ALL
                            
                            -- Predefined texts inserted by Profissional
                            SELECT 0                          needs_translation,
                                    stp.rank,
                                    stp.title_sample_text_prof title,
                                    stp.desc_sample_text_prof  text,
                                    NULL                       code_icd,
                                    NULL                       id_diagnosis,
                                    NULL                       flg_class
                              FROM sample_text_prof stp
                              JOIN (SELECT DISTINCT stt.id_sample_text_type
                                           FROM sample_text_type stt
                                          INNER JOIN sample_text_type_cat sttc
                                             ON stt.id_sample_text_type = sttc.id_sample_text_type
                                     WHERE upper(stt.intern_name_sample_text_type) = upper(i_sample_text_type) --By Keyword area
                                            AND stt.flg_available = pk_alert_constant.g_yes
                                            AND sttc.id_institution IN (i_prof.institution, 0) -- By current institution + default
                                            AND sttc.id_category = l_cat) stt
                                ON stt.id_sample_text_type = stp.id_sample_text_type
                             WHERE 0 = 0
                                  --AND stp.id_institution IN (i_prof.institution, 0)
                               AND stp.id_professional = i_prof.id
                               AND stp.id_software = i_prof.software))
             WHERE title IS NOT NULL
               AND text IS NOT NULL
               AND rownum > 0
             ORDER BY rank, title; --, pk_string_utils.clob_to_sqlvarchar2(text);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            l_process_error(SQLCODE,
                                   'Error calling internal function',
                            'The call to function ' || g_error || ' returned an error ');
            RETURN FALSE;
        WHEN OTHERS THEN
            l_process_error(SQLCODE, SQLERRM, g_error);
            RETURN FALSE;
    END get_large_sample_text;

    /******************************************************************************
       OBJECTIVO: Obter textos de história, salientando o registo cujo código associado, 
            se for o caso, corresponde ao código do texto de queixa 
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_SAMPLE_TEXT_TYPE - Nome interno do tipo de texto 
                             I_PATIENT - ID do utente 
                             I_EPISODE - ID do episódio 
               I_PROF - Profissional q acede
              Saida: O_SAMPLE_TEXT - textos e títulos
             O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/05/31 
      NOTAS:
      Deprecated. Use get_large_sample_text to avoid the varchar limit of 4000 bytes 
    *********************************************************************************/
    FUNCTION get_sample_text_epis
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_type IN sample_text_type.intern_name_sample_text_type%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_prof             IN alert.profissional,
        o_sample_text      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cat prof_cat.id_category%TYPE;
    
        CURSOR c_pat IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
              FROM patient
             WHERE id_patient = i_patient;
        r_pat c_pat%ROWTYPE;
    
        l_diag NUMBER;
        l_code VARCHAR2(200);
    
        err_clinical_info EXCEPTION;
    
        --***************************************
        PROCEDURE l_process_error
        (
            i_sqlcode IN NUMBER,
            i_sqlerrm IN VARCHAR2,
            i_error   IN VARCHAR2
        ) IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang,
                                              i_sqlcode,
                                              i_sqlerrm,
                                              i_error,
                                              'ALERT',
                                              'PK_SAMPLE_TEXT',
                                              'GET_SAMPLE_TEXT_EPIS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sample_text);
        
        END l_process_error;
    
    BEGIN
        l_cat := get_prof_category(i_prof);
    
        g_error := 'OPEN C_PAT';
        r_pat   := get_pat_info(i_patient);
    
        g_error := 'GET CONFIG';
        IF upper(i_sample_text_type) = pk_sysconfig.get_config('COMPLAINT_ANAMNESIS', i_prof)
        THEN
            g_error := 'GET PK_CLINICAL_INFO.GET_ANAMNESIS_CODE';
            IF NOT pk_clinical_info.get_anamnesis_code(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_prof    => i_prof,
                                                       o_code    => l_code,
                                                       o_id_diag => l_diag,
                                                       o_error   => o_error)
            THEN
            
                RAISE err_clinical_info;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_sample_text FOR
            SELECT *
              FROM (SELECT a.rank, a.title, to_clob(a.text) text, a.code_icd, a.id_diagnosis, a.flg_default
                      FROM (SELECT t.rank, t.title, t.text, t.code_icd, t.id_diagnosis, t.flg_default
                              FROM (SELECT st.rank,
                                           pk_translation.get_translation(i_lang, st.code_title_sample_text) title,
                                           pk_translation.get_translation(i_lang, st.code_desc_sample_text) text,
                                           st.code_icd,
                                           st.id_diagnosis,
                                           decode(nvl(st.id_diagnosis, 0), nvl(l_diag, -1), 'Y', 'N') flg_default
                                      FROM sample_text_soft_inst stsi
                                      JOIN sample_text_type stt
                                        ON stsi.id_sample_text_type = stt.id_sample_text_type
                                     INNER JOIN sample_text_type_cat sttc
                                        ON stt.id_sample_text_type = sttc.id_sample_text_type
                                     INNER JOIN sample_text st
                                        ON stsi.id_sample_text = st.id_sample_text
                                     WHERE upper(stt.intern_name_sample_text_type) = upper(i_sample_text_type)
                                       AND stsi.id_software = i_prof.software
                                       AND stt.flg_available = g_stext_type_avail
                                       AND st.flg_available = g_stext_avail
                                       AND sttc.id_category = l_cat
                                       AND sttc.id_institution IN (0, i_prof.institution)
                                       AND stsi.id_institution = i_prof.institution
                                       AND ((r_pat.gender IS NOT NULL AND nvl(st.gender, 'I') IN ('I', r_pat.gender)) OR
                                            r_pat.gender IS NULL OR r_pat.gender = 'I')
                                       AND (nvl(r_pat.age, 0) BETWEEN nvl(st.age_min, 0) AND
                                            nvl(st.age_max, nvl(r_pat.age, 0)) OR nvl(r_pat.age, 0) = 0)) t
                             GROUP BY t.rank, t.title, t.text, t.code_icd, t.id_diagnosis, t.flg_default) a
                    UNION ALL
                    SELECT stf.rank,
                           stf.title_sample_text_prof title,
                           stf.desc_sample_text_prof text,
                           NULL code_icd,
                           NULL id_diagnosis,
                           'N' flg_default
                      FROM (SELECT stt.id_sample_text_type
                              FROM sample_text_type stt
                             INNER JOIN sample_text_type_cat sttc
                                ON stt.id_sample_text_type = sttc.id_sample_text_type
                              JOIN sample_text_type_soft stts
                                ON stt.id_sample_text_type = stts.id_sample_text_type
                             WHERE upper(stt.intern_name_sample_text_type) = upper(i_sample_text_type)
                               AND stts.id_software = i_prof.software
                               AND sttc.id_category = l_cat
                               AND sttc.id_institution IN (0, i_prof.institution)
                             GROUP BY stt.id_sample_text_type) a
                     INNER JOIN sample_text_prof stf
                        ON stf.id_sample_text_type = a.id_sample_text_type
                       AND stf.id_professional = i_prof.id
                       AND stf.id_software = i_prof.software
                    --AND stf.id_institution IN (0, i_prof.institution)
                    ) t
             WHERE title IS NOT NULL
               AND text IS NOT NULL
               AND rownum > 0
             ORDER BY rank, title; --, pk_string_utils.clob_to_sqlvarchar2(text);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_clinical_info THEN
            l_process_error(SQLCODE, SQLERRM, g_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            l_process_error(SQLCODE, SQLERRM, g_error);
            RETURN FALSE;
    END get_sample_text_epis;

        /******************************************************************************
           OBJECTIVO:   Obter textos criados pelo profissional 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_PROF - Profissional q acede
                  Saida:   O_SAMPLE_TEXT - textos e títulos
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/05/11
          NOTAS:
          
          UPDATED
          passa a filtrar tambem pela coluna sample_text_type.flg_available
          *@author  Telmo Castro
          *@version 2.4.3
          *@date    15-07-2008
        *********************************************************************************/
    FUNCTION get_sample_text_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN alert.profissional,
        o_sample_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_sample_text FOR
            SELECT stp.id_sample_text_prof,
                   stp.rank,
                   stp.title_sample_text_prof title,
                   stp.desc_sample_text_prof text,
                   pk_translation.get_translation(i_lang, stt.code_sample_text_type) area
              FROM sample_text_prof stp
              JOIN sample_text_type stt
                ON stp.id_sample_text_type = stt.id_sample_text_type
             WHERE stp.id_professional = i_prof.id
               AND stt.id_software = i_prof.software
               AND stt.flg_available = g_stext_type_avail
             ORDER BY stp.rank, title, pk_string_utils.clob_to_sqlvarchar2(text);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SAMPLE_TEXT',
                                              'GET_SAMPLE_TEXT_PROF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sample_text);
            RETURN FALSE;
    END get_sample_text_prof;

        /******************************************************************************
           OBJECTIVO:   Cancelar textos do profissional
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_SAMPLE_TEXT - ID do registo a cancelar 
                  Saida:   O_ERROR - erro 
        
          CRIAÇÃO: CRS 2005/05/11
          NOTAS:
        *********************************************************************************/
    FUNCTION cancel_sample_text_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_sample_text IN sample_text_prof.id_sample_text_prof%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'UPDATE';
        DELETE sample_text_prof
         WHERE id_sample_text_prof = i_sample_text;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SAMPLE_TEXT',
                                              'CANCEL_SAMPLE_TEXT_PROF',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_sample_text_prof;

        /******************************************************************************
           OBJECTIVO:   Registar textos do profissional
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_ID_SAMPLE_TEXT - ID do registo, se se trata de uma actualização 
                     I_SAMPLE_TEXT_TYPE - Tipo de texto
                       I_PROF - Profissional q acede
                     I_TITLE - título
                     I_TEXT - texto
                  Saida:   O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/29
          NOTAS:
        *********************************************************************************/
    FUNCTION set_sample_text_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_id_sample_text   IN sample_text_prof.id_sample_text_prof%TYPE,
        i_sample_text_type IN sample_text_prof.id_sample_text_type%TYPE,
        i_prof             IN alert.profissional,
        i_title            IN sample_text_prof.title_sample_text_prof%TYPE,
        i_text             IN sample_text_prof.desc_sample_text_prof%TYPE,
        i_rank             IN sample_text_prof.rank%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next sample_text_prof.id_sample_text_prof%TYPE;
        --l_char VARCHAR2(1);
    
        --****************************
        FUNCTION verify_stp_exist RETURN BOOLEAN IS
            l_count NUMBER;
        BEGIN
        
            SELECT COUNT(*)
              INTO l_count
              FROM sample_text_prof
             WHERE id_sample_text_prof = i_id_sample_text;
    
            RETURN(l_count > 0);
        
        END verify_stp_exist;
    
    BEGIN
        g_error := 'OPEN C_TEXT';
    
        g_found := verify_stp_exist();
    
        IF g_found
        THEN
            g_error := 'UPDATE SAMPLE_TEXT_PROF';
            UPDATE sample_text_prof
               SET title_sample_text_prof = i_title,
                   desc_sample_text_prof  = i_text,
                   --js, 2007-07-18
                   id_sample_text_type = i_sample_text_type
             WHERE id_sample_text_prof = i_id_sample_text;
        
        ELSE
            g_error := 'GET SEQ_SAMPLE_TEXT_PROF.NEXTVAL';
            l_next  := seq_sample_text_prof.nextval;
        
            g_error := 'INSERT';
            INSERT INTO sample_text_prof
                (id_sample_text_prof,
                 id_sample_text_type,
                 id_professional,
                 title_sample_text_prof,
                 desc_sample_text_prof,
                 rank,
                 flg_status,
                 id_institution,
                 id_software)
            VALUES
                (l_next,
                 i_sample_text_type,
                 i_prof.id,
                 i_title,
                 i_text,
                 nvl(i_rank, 0),
                 g_stext_prof_active,
                 i_prof.institution,
                 i_prof.software);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SAMPLE_TEXT',
                                              'GET_SAMPLE_TEXT_PROF',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_sample_text_prof;

        /******************************************************************************
           OBJECTIVO:   Obter textos de deteminado profissional.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_SAMPLE_TEXT_PROF - Tipo de texto 
                       I_PROF - Profissional q acede
                  Saida:   O_SAMPLE_TEXT - textos e títulos
                     O_ERROR - erro
        
          CRIAÇÃO: SS 2005/08/26  
          NOTAS:
        *********************************************************************************/
    FUNCTION get_sample_text_det
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_prof IN sample_text_prof.id_sample_text_prof%TYPE,
        i_prof             IN alert.profissional,
        o_sample_text      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_sample_text FOR
            SELECT stp.rank,
                   stp.title_sample_text_prof title,
                   stp.desc_sample_text_prof text,
                   stt.id_sample_text_type,
                   pk_translation.get_translation(i_lang, stt.code_sample_text_type) text_type
              FROM sample_text_prof stp
              JOIN sample_text_type stt
                ON stp.id_sample_text_type = stt.id_sample_text_type
             WHERE stp.id_sample_text_prof = i_sample_text_prof
               AND stp.id_professional = i_prof.id
               AND stt.id_software = i_prof.software
             ORDER BY rank, title, pk_string_utils.clob_to_sqlvarchar2(text);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SAMPLE_TEXT',
                                              'GET_SAMPLE_TEXT_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sample_text);
            RETURN FALSE;
    END get_sample_text_det;

    PROCEDURE init_sample_text
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        --k_pos_episode      CONSTANT NUMBER(24) := 5;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
        --l_msg VARCHAR2(4000);
    
    BEGIN
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_software' THEN
                o_id := l_prof.software;
            WHEN 'i_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_category' THEN
                o_id := pk_prof_utils.get_id_category(i_lang => l_lang, i_prof => l_prof);
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_sample_text;

    --***********************************************************************
    FUNCTION get_sample_text_detail
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_area        IN VARCHAR2,
        i_sample_text IN NUMBER,
        o_detail      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
        k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';
        k_area_one CONSTANT VARCHAR2(0200 CHAR) := 'SAMPLE_TEXT';
        k_area_two CONSTANT VARCHAR2(0200 CHAR) := 'SAMPLE_TEXT2';
    
        CURSOR row_c(i_id_category IN NUMBER) IS
            SELECT
            ----
             stp.dt_creation,
             pk_translation.get_translation(i_lang, stt.code_sample_text_type) area,
             stp.desc_sample_text_prof description,
             stp.title_sample_text_prof title,
             stp.id_professional id_professional
              FROM sample_text_prof stp
              JOIN sample_text_type stt
                ON stp.id_sample_text_type = stt.id_sample_text_type
             WHERE stt.flg_available = 'Y'
               AND stp.id_sample_text_prof = i_sample_text
               AND i_area = k_area_one
            UNION ALL
            SELECT xtmp.*
              FROM (SELECT current_timestamp dt_creation,
                           '' area,
                           to_clob(pk_translation.get_translation(i_lang, st.code_desc_sample_text)) description,
                           pk_translation.get_translation(i_lang, st.code_title_sample_text) title,
                           -1 id_professional
                      FROM sample_text st
                      JOIN sample_text_soft_inst stsi
                        ON stsi.id_sample_text = st.id_sample_text
                      JOIN sample_text_type_soft sts
                        ON sts.id_sample_text_type = stsi.id_sample_text_type
                       AND sts.id_software = stsi.id_software
                      JOIN sample_text_type stt
                        ON stt.id_sample_text_type = stsi.id_sample_text_type
                      JOIN sample_text_type_cat sttc
                        ON sttc.id_sample_text_type = stsi.id_sample_text_type
                       AND sttc.id_institution = stsi.id_institution
                     WHERE st.flg_available = 'Y'
                       AND st.id_sample_text = i_sample_text
                       AND stsi.id_institution = i_prof.institution
                       AND stsi.id_software = i_prof.software
                       AND sttc.id_category = i_id_category
                       AND i_area = k_area_two
                       AND rownum < 2) xtmp;
    
        TYPE type_sample IS TABLE OF row_c%ROWTYPE;
        tbl_sample type_sample;
    
        tbl_data t_tab_dd_data := t_tab_dd_data();
    
        l_desc     VARCHAR2(4000);
        l_val      VARCHAR2(4000);
        l_type     VARCHAR2(0010 CHAR);
        l_clob     CLOB;
        l_bool     BOOLEAN;
        l_flg_clob CLOB;
    
        --**************************************
        PROCEDURE l_get_sample_data IS
            l_id_category NUMBER;
        BEGIN
        
            l_id_category := get_prof_category(i_prof);
        
            OPEN row_c(l_id_category);
            FETCH row_c BULK COLLECT
                INTO tbl_sample;
            CLOSE row_c;
        
        END l_get_sample_data;
    
        --****************************************
        PROCEDURE l_push(i_row IN t_rec_dd_data) IS
            l_count NUMBER;
        BEGIN
        
            tbl_data.extend();
            l_count := tbl_data.count;
            tbl_data(l_count) := i_row;
        
        END l_push;
    
        --*****************************************
        PROCEDURE l_fill_row
        (
            i_desc     IN VARCHAR2,
            i_val      IN VARCHAR2,
            i_flg_type IN VARCHAR2,
            i_clob     IN CLOB,
            i_flg_clob IN VARCHAR2 DEFAULT 'N',
            i_flg_sep  IN VARCHAR2 DEFAULT 'Y'
        ) IS
            l_bool BOOLEAN;
            l_row  t_rec_dd_data;
            l_desc VARCHAR2(4000);
            l_sep  VARCHAR2(0020 CHAR);
        BEGIN
        
            l_bool := i_flg_clob = k_no AND i_val IS NOT NULL;
            l_bool := l_bool OR (i_flg_clob = k_yes AND dbms_lob.getlength(i_clob) > 0);
        
            IF i_flg_type NOT IN ('LP', 'L1', 'WL')
            THEN
            
                l_sep := NULL;
                IF i_flg_sep = k_yes
                THEN
                    l_sep := ': ';
                END IF;
                l_desc := i_desc || l_sep;
            
            ELSE
                l_desc := i_desc;
            END IF;
        
            IF l_bool
               OR (i_flg_type IN ('L1', 'WL'))
            THEN
                l_row := t_rec_dd_data(descr    => l_desc, --VARCHAR2(1000 CHAR),
                                       val      => i_val, --VARCHAR2(4000 CHAR),
                                       flg_type => i_flg_type, --VARCHAR2(200 CHAR),
                                       flg_html => k_no, --VARCHAR2(1 CHAR),
                                       val_clob => i_clob, --CLOB,
                                       flg_clob => i_flg_clob --VARCHAR2(1 CHAR)
                                       );
                l_push(l_row);
            
            END IF;
        
        END l_fill_row;
    
        --***********************************
        FUNCTION iif
        (
            i_bool  IN BOOLEAN,
            i_true  IN VARCHAR2,
            i_false IN VARCHAR2
        ) RETURN VARCHAR2 IS
        BEGIN
            IF i_bool
            THEN
                RETURN i_true;
            ELSE
                RETURN i_false;
            END IF;
        END iif;
    
        --***********************************
        FUNCTION l_get_prof_name(i_prof IN NUMBER) RETURN VARCHAR2 IS
            tbl_name table_varchar;
            l_return VARCHAR2(4000);
        BEGIN
        
            SELECT name
              BULK COLLECT
              INTO tbl_name
              FROM professional
             WHERE id_professional = i_prof;
        
            IF tbl_name.count > 0
            THEN
                l_return := tbl_name(1);
            END IF;
        
            RETURN l_return;
        
        END l_get_prof_name;
    
        --****************************************************************
        PROCEDURE l_get_signature
        (
            i_id_prof IN NUMBER,
            i_dt      IN TIMESTAMP WITH LOCAL TIME ZONE
        ) IS
            l_signature           VARCHAR2(4000);
            l_spec                VARCHAR2(4000);
        BEGIN
        
            l_spec := pk_prof_utils.get_spec_signature(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_prof_id => i_id_prof,
                                                       i_dt_reg  => i_dt,
                                                       i_episode => NULL);
        
            IF l_spec IS NOT NULL
            THEN
                l_spec := ' (' || l_spec || ')';
            END IF;
        
            l_signature := l_spec || '; ' ||
                           pk_date_utils.date_char_tsz(i_lang, i_dt, i_prof.institution, i_prof.software);
        
            l_signature := pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_id_prof) ||
                           l_signature;
        
            --  ( signature )
            l_desc := NULL; --l_label;
            l_val  := l_signature;
            l_clob := NULL;
            l_type := 'LP';
            l_fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
        END l_get_signature;
    
        --**********************************
        PROCEDURE l_push_white_line IS
        BEGIN
        
            l_desc := '';
            l_val  := '';
            l_clob := NULL;
            l_type := 'WL';
            l_fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
        END l_push_white_line;
    
    BEGIN
    
        -- full data
        l_get_sample_data();
    
        <<lup_thru_detail>>
        FOR i IN 1 .. tbl_sample.count
        LOOP
        
            l_push_white_line();
        
            -- Title
            l_desc := pk_message.get_message(i_lang, 'FREQUENT_TEXT_T004');
            l_val  := NULL;
            l_clob := NULL;
            l_type := 'L1';
            l_fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob, i_flg_sep => k_no);
        
            l_push_white_line();
        
            IF i_area = k_area_one
            THEN
            -- Area
                l_desc := pk_message.get_message(i_lang, 'FREQUENT_TEXT_T001') || ':';
            l_val  := tbl_sample(i).area;
            l_clob := NULL;
            l_type := 'L2B';
                l_fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob, i_flg_sep => k_no);
            END IF;
        
            -- title
            l_desc := pk_message.get_message(i_lang, 'FREQUENT_TEXT_T002');
            l_val  := tbl_sample(i).title;
            l_clob := NULL;
            l_type := 'L2B';
            l_fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
            l_flg_clob := iif(dbms_lob.getlength(tbl_sample(i).description) > 0, k_yes, k_no);
            IF l_flg_clob = k_yes
            THEN
                l_clob := tbl_sample(i).description;
                l_val  := NULL;
            END IF;
        
            l_desc := pk_message.get_message(i_lang, 'FREQUENT_TEXT_T003');
            l_type := 'L2B';
            l_fill_row(i_desc     => l_desc,
                     i_val      => l_val,
                     i_flg_type => l_type,
                     i_clob     => l_clob,
                     i_flg_clob => l_flg_clob);
        
            -- white line
        
            l_push_white_line();
        
            IF i_area = k_area_one
            THEN
                l_get_signature(tbl_sample(i).id_professional, tbl_sample(i).dt_creation);
        
                l_push_white_line();
            END IF;
        
        END LOOP lup_thru_cosign;
    
        OPEN o_detail FOR
            SELECT t.*
              FROM TABLE(tbl_data) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail);
            l_bool := pk_alert_exceptions.process_error(i_lang,
                                                        SQLCODE,
                                                        SQLERRM,
                                                        '',
                                                        'ALERT',
                                                        'PK_SAMLE_TEXT',
                                                        'GET_SAMPLE_TEXT_DETAIL',
                                                        o_error);
            RETURN FALSE;
        
    END get_sample_text_detail;

    ------------------------------------------
    FUNCTION get_dyn_new_values
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_ds_get_value IS
        tbl_tree_configs t_dyn_tree_table := t_dyn_tree_table();
        tbl_result       t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_temp         t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_value          VARCHAR2(4000);
        l_lob            CLOB;
        l_bool           BOOLEAN;
        l_count          NUMBER;
    
        PROCEDURE init_rec IS
        BEGIN
            tbl_result(l_count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => NULL,
                                                      id_ds_component    => NULL,
                                                      internal_name      => NULL,
                                                      VALUE              => NULL,
                                                      min_value          => NULL,
                                                      max_value          => NULL,
                                                      desc_value         => NULL,
                                                      desc_clob          => NULL,
                                                      value_clob         => NULL,
                                                      id_unit_measure    => NULL,
                                                      desc_unit_measure  => NULL,
                                                      flg_validation     => NULL,
                                                      err_msg            => NULL,
                                                      flg_event_type     => NULL,
                                                      flg_multi_status   => NULL,
                                                      idx                => NULL);
        END init_rec;
    
    BEGIN
    
        -- ge components
        tbl_tree_configs := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_patient        => NULL,
                                                    i_component_name => i_root_name,
                                                    i_action         => NULL);
    
        <<lup_thru_elements>>
        FOR j IN 1 .. tbl_tree_configs.count
        LOOP
        
            l_bool := FALSE;
            tbl_result.extend();
            l_count := tbl_result.count;
        
            CASE tbl_tree_configs(j).internal_name_child
                WHEN 'DS_STEXT_AREA' THEN
                    l_bool  := TRUE;
                    l_value := NULL;
                    l_lob   := NULL;
                WHEN 'DS_STEXT_DESC' THEN
                    l_bool  := TRUE;
                    l_value := NULL;
                    l_lob   := NULL;
                WHEN 'DS_STEXT_TEXT' THEN
                    l_bool  := TRUE;
                    l_value := NULL;
                    l_lob   := NULL;
                ELSE
                    NULL;
            END CASE;
        
            --tbl_result(l_count) := t_rec_ds_get_value();
            init_rec();
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => tbl_tree_configs(j).id_ds_cmpt_mkt_rel,
                                      id_ds_component    => tbl_tree_configs(j).id_ds_component_child,
                                      internal_name      => tbl_tree_configs(j).internal_name_child,
                                      VALUE              => l_value,
                                      min_value          => NULL,
                                      max_value          => NULL,
                                      desc_value         => NULL,
                                      desc_clob          => NULL,
                                      value_clob         => NULL,
                                      id_unit_measure    => NULL,
                                      desc_unit_measure  => NULL,
                                      flg_validation     => 'Y',
                                      err_msg            => NULL,
                                      flg_event_type     => 'NA',
                                      flg_multi_status   => NULL,
                                      idx                => 1)
              BULK COLLECT
              INTO tbl_temp
              FROM dual;
        
            tbl_result := tbl_result MULTISET UNION ALL tbl_temp;
        
        END LOOP lup_thru_elements;
    
        RETURN tbl_result;
    
    END get_dyn_new_values;

    FUNCTION get_dyn_edit_values
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER,
        i_id_patient IN NUMBER,
        i_id_stp     IN NUMBER,
        i_root_name  IN VARCHAR2
    ) RETURN t_tbl_ds_get_value IS
        tbl_result       t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_temp         t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_tree_configs t_dyn_tree_table;
    
        l_value VARCHAR2(4000);
        l_desc_value VARCHAR2(4000);
        l_lob   CLOB;
        l_bool  BOOLEAN;
        --l_count NUMBER;
    
        CURSOR xstp_c IS
            SELECT pk_translation.get_translation(i_lang, stt.code_sample_text_type) area,
                   stp.title_sample_text_prof stp_description,
                   stp.desc_sample_text_prof stp_text,
                   stt.id_sample_text_type
              FROM sample_text_prof stp
              JOIN sample_text_type stt
                ON stt.id_sample_text_type = stp.id_sample_text_type
             WHERE stp.id_sample_text_prof = i_id_stp;
    
        TYPE type_stp IS TABLE OF xstp_c%ROWTYPE;
        tbl_data type_stp;
    
        --------------------------
        PROCEDURE get_stp_data IS
        BEGIN
        
            OPEN xstp_c;
            FETCH xstp_c BULK COLLECT
                INTO tbl_data;
            CLOSE xstp_c;
        
        END get_stp_data;
    
    BEGIN
    
        -- ge components
        tbl_tree_configs := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_patient        => NULL,
                                                    i_component_name => i_root_name,
                                                    i_action         => NULL);
        -- get info                     
        get_stp_data();
    
        <<lup_thru_data>>
        FOR i IN 1 .. tbl_data.count
        LOOP
        
            <<lup_thru_elements>>
            FOR j IN 1 .. tbl_tree_configs.count
            LOOP
            
                l_bool := FALSE;
                --tbl_result.extend();
                --l_count := tbl_result.count;
                l_desc_value := null;
                CASE tbl_tree_configs(j).internal_name_child
                    WHEN 'DS_STEXT_AREA' THEN
                        l_desc_value := tbl_data(i).area;
                        l_bool  := TRUE;
                        l_value := tbl_data(i).id_sample_text_type;
                        l_lob   := NULL;
                    WHEN 'DS_STEXT_DESC' THEN
                        l_bool  := TRUE;
                        l_desc_value := tbl_data(i).stp_description;
                        l_lob   := NULL;
                        l_value := null;
                    WHEN 'DS_STEXT_TEXT' THEN
                        l_bool  := TRUE;
                        l_value := NULL;
                        l_lob   := tbl_data(i).stp_text;
                    WHEN 'DS_STEXT_ID_PROF' THEN
                        l_bool  := TRUE;
                        l_value := i_id_stp;
                        l_lob   := NULL;
                    ELSE
                        NULL;
                END CASE;
            
                --tbl_result(l_count).id_ds_cmpt_mkt_rel := tbl_tree_configs(j).id_ds_cmpt_mkt_rel;
            
                SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => tbl_tree_configs(j).id_ds_cmpt_mkt_rel,
                                          id_ds_component    => tbl_tree_configs(j).id_ds_component_child,
                                          internal_name      => tbl_tree_configs(j).internal_name_child,
                                          VALUE              => l_value,
                                          min_value          => NULL,
                                          max_value          => NULL,
                                          desc_value         => l_desc_value,
                                          desc_clob          => NULL,
                                          value_clob         => l_lob,
                                          id_unit_measure    => NULL,
                                          desc_unit_measure  => NULL,
                                          flg_validation     => 'Y',
                                          err_msg            => NULL,
                                          flg_event_type     => 'NA',
                                          flg_multi_status   => NULL,
                                          idx                => 1)
                  BULK COLLECT
                  INTO tbl_temp
                  FROM dual;
            
                tbl_result := tbl_result MULTISET UNION ALL tbl_temp;
            
            END LOOP lup_thru_elements;
        
        END LOOP lup_thru_data;
    
        RETURN tbl_result;
    
    END get_dyn_edit_values;

    -------------------------------------------
    FUNCTION get_stext_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        l_error VARCHAR2(1000 CHAR);
    
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        k_action_edit CONSTANT NUMBER := 235534419;
        k_action_edit2 CONSTANT NUMBER := 235534421;
        l_id_sample_text      NUMBER;
        l_id_sample_text_type NUMBER;
    
        --*******************************************
        PROCEDURE l_set_id IS
        BEGIN
        
            l_id_sample_text      := i_tbl_id_pk(1);
            l_id_sample_text_type := i_tbl_id_pk(2);
        
        END l_set_id;
    
    BEGIN
    
        CASE i_action
            WHEN k_action_edit THEN
                l_error    := 'get_edit_values';
                tbl_result := get_dyn_edit_values(i_lang,
                                                  i_prof,
                                                  i_episode,
                                                  i_patient,
                                                  i_tbl_id_pk(1),
                                                  i_root_name
                                                  --,o_error
                                                  );
            WHEN k_action_add THEN
                l_error    := 'get_add_values';
                tbl_result := get_dyn_new_values(i_lang => i_lang, i_prof => i_prof, i_root_name => i_root_name);
            WHEN k_action_edit2 THEN
            
                l_set_id();
                tbl_result := get_dyn_edit2_values(i_lang,
                                                   i_prof,
                                                   i_episode,
                                                   i_patient,
                                                   l_id_sample_text,
                                                   l_id_sample_text_type,
                                                   i_root_name);
            ELSE
                NULL;
        END CASE;
    
        RETURN tbl_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              'ALERt',
                                              'P_SAMPLE_TEXT',
                                              'get_stext_values',
                                              o_error);
            RETURN NULL;
    END get_stext_values;

    FUNCTION get_sample_text_area
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain IS
        l_ret t_tbl_core_domain;
    BEGIN
    
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => 'GET_SAMPLE_TEXT_AREA',
                                         desc_domain   => area,
                                         domain_value  => id_sample_text_type,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT stt.id_sample_text_type,
                               pk_translation.get_translation(i_lang, stt.code_sample_text_type) area
                          FROM sample_text_type stt
                          JOIN sample_text_type_soft stf
                            ON stt.id_sample_text_type = stf.id_sample_text_type
                         WHERE stf.id_software = i_prof.software
                           AND stt.flg_available = pk_alert_constant.g_yes
                           AND EXISTS (SELECT 1
                                  FROM sample_text_type_cat sttc
                                 WHERE sttc.id_sample_text_type = stt.id_sample_text_type
                                   AND sttc.id_category =
                                       (SELECT id_category
                                          FROM prof_cat
                                         WHERE id_professional = i_prof.id
                                           AND id_institution IN (0, i_prof.institution))
                                   AND sttc.id_institution IN (0, i_prof.institution))
                         ORDER BY area));
    
        RETURN l_ret;
    
    END get_sample_text_area;

    FUNCTION save_dyn_sample_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tbl_mkt_rel IN table_number,
        i_value       IN table_varchar,
        i_value_clob  IN table_clob,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_ds_component    NUMBER;
        l_sample_text_type   NUMBER;
        l_title              VARCHAR2(4000);
        l_text               CLOB;
        l_id_stext_type_prof NUMBER;
        l_bool               BOOLEAN;
    
        -------------------------------
        FUNCTION get_comp_by_cmpt(i_id_mkt_rel IN NUMBER) RETURN VARCHAR2 IS
            tbl_name table_varchar;
            l_return VARCHAR2(4000);
        BEGIN
        
            SELECT internal_name_child
              BULK COLLECT
              INTO tbl_name
              FROM v_ds_cmpt_mkt_rel
             WHERE id_ds_cmpt_mkt_rel = i_id_mkt_rel;
        
            IF tbl_name.count > 0
            THEN
                l_return := tbl_name(1);
            END IF;
        
            RETURN l_return;
        
        END get_comp_by_cmpt;
    
        ------------------------------------
        PROCEDURE map_dyn_to_fields IS
        BEGIN
        
            <<lup_thru_comp>>
            FOR i IN 1 .. i_tbl_mkt_rel.count
            LOOP
            
                l_id_ds_component := get_comp_by_cmpt(i_id_mkt_rel => i_tbl_mkt_rel(i));
            
                CASE l_id_ds_component
                    WHEN 'DS_STEXT_AREA' THEN
                        l_sample_text_type := i_value(i);
                    WHEN 'DS_STEXT_DESC' THEN
                        l_title := i_value(i);
                    WHEN 'DS_STEXT_TEXT' THEN
                        l_text := i_value_clob(i);
                    WHEN 'DS_STEXT_ID_PROF' THEN
                        l_id_stext_type_prof := i_value(i);
                    ELSE
                        NULL;
                END CASE;
            
            END LOOP lup_thru_comp;
        
        END map_dyn_to_fields;
    
    BEGIN
    
        map_dyn_to_fields();
    
        l_bool := set_sample_text_prof(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_sample_text   => l_id_stext_type_prof,
                                       i_sample_text_type => l_sample_text_type,
                                       i_title            => l_title,
                                       i_text             => l_text,
                                       i_rank             => 0,
                                       o_error            => o_error);
    
        RETURN l_bool;
    
    END save_dyn_sample_text;

    FUNCTION get_dyn_edit2_values
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER,
        i_id_patient IN NUMBER,
        --
        --i_id_stp     IN NUMBER,
        i_id_stext      IN NUMBER,
        i_id_stext_type IN NUMBER,
        --
        i_root_name  IN VARCHAR2
    ) RETURN t_tbl_ds_get_value IS
        tbl_result       t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_temp         t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_tree_configs t_dyn_tree_table;
    
        l_value VARCHAR2(4000);
        l_desc_value varchar2(4000);
        l_lob   CLOB;
        l_bool  BOOLEAN;
        l_count NUMBER;
    
        CURSOR xstp_c(i_category IN NUMBER) IS
            SELECT NULL id_sample_text_prof,
                   st2.id_sample_text,
                   pk_translation.get_translation(i_lang, st2.code_area) xarea,
                   pk_translation.get_translation(i_lang, st2.code_title) xtitle,
                   pk_translation.get_translation(i_lang, st2.code_text) xtext,
                   st2.id_sample_text_type
              FROM v_sample_text_2 st2
             WHERE st2.id_sample_text = i_id_stext
               AND st2.id_sample_text_type = i_id_stext_type
               AND st2.id_institution = i_prof.institution
               AND st2.id_software = i_prof.software
               AND st2.id_category = i_category
               AND rownum < 2; -- there can be only one
    
        TYPE type_stp IS TABLE OF xstp_c%ROWTYPE;
        tbl_data type_stp;
    
        --------------------------
        PROCEDURE l_get_stp_data IS
            l_id_category NUMBER;
        BEGIN
        
            l_id_category := get_prof_category(i_prof);
        
            OPEN xstp_c(l_id_category);
            FETCH xstp_c BULK COLLECT
                INTO tbl_data;
            CLOSE xstp_c;
        
        END l_get_stp_data;
    
    BEGIN
    
        -- ge components
        tbl_tree_configs := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_patient        => NULL,
                                                    i_component_name => i_root_name,
                                                    i_action         => NULL);
        -- get info                     
        l_get_stp_data();
    
        <<lup_thru_data>>
        FOR i IN 1 .. tbl_data.count
        LOOP
        
            <<lup_thru_elements>>
            FOR j IN 1 .. tbl_tree_configs.count
            LOOP
            
                l_bool := FALSE;
                tbl_result.extend();
                l_count := tbl_result.count;
            
                l_desc_value := null;
                CASE tbl_tree_configs(j).internal_name_child
                    WHEN 'DS_STEXT_AREA' THEN
                        l_desc_value := tbl_data(i).xarea;
                        l_bool  := TRUE;
                        l_value := tbl_data(i).id_sample_Text_type;
                        l_lob   := NULL;
                    WHEN 'DS_STEXT_DESC' THEN
                        l_bool  := TRUE;
                        l_desc_value := tbl_data(i).xtitle;
                        l_lob   := NULL;
                        l_value := null;
                    WHEN 'DS_STEXT_TEXT' THEN
                        l_bool  := TRUE;
                        l_value := NULL;
                        l_lob   := tbl_data(i).xtext;
                    WHEN 'DS_STEXT_ID_PROF' THEN
                        l_bool  := TRUE;
                        l_value := NULL;
                        l_lob   := NULL;
                    ELSE
                        NULL;
                END CASE;
            
                SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => tbl_tree_configs(j).id_ds_cmpt_mkt_rel,
                                          id_ds_component    => tbl_tree_configs(j).id_ds_component_child,
                                          internal_name      => tbl_tree_configs(j).internal_name_child,
                                          VALUE              => l_value,
                                          min_value          => NULL,
                                          max_value          => NULL,
                                          desc_value         => l_desc_value,
                                          desc_clob          => NULL,
                                          value_clob         => l_lob,
                                          id_unit_measure    => NULL,
                                          desc_unit_measure  => NULL,
                                          flg_validation     => 'Y',
                                          err_msg            => NULL,
                                          flg_event_type     => 'NA',
                                          flg_multi_status   => NULL,
                                          idx                => 1)
                  BULK COLLECT
                  INTO tbl_temp
                  FROM dual;
            
                tbl_result := tbl_result MULTISET UNION ALL tbl_temp;
            
            END LOOP lup_thru_elements;
        
        END LOOP lup_thru_data;
    
        RETURN tbl_result;
    
    END get_dyn_edit2_values;

    PROCEDURE inicialize IS
    BEGIN

    g_stext_avail       := 'Y';
    g_stext_type_avail  := 'Y';
    g_stext_prof_cancel := 'C';
    g_stext_prof_active := 'A';
        g_selected          := 'S';

    END inicialize;

BEGIN

    inicialize();
	
END pk_sample_text;
/
