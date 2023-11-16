/*-- Last Change Revision: $Rev: 2055616 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:27:24 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_lab_tests_utils IS

    FUNCTION create_lab_test_req_par
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_analysis_req_par OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis_parameter IS
            SELECT DISTINCT apar.id_analysis_parameter, ard.id_analysis, ard.id_sample_type
              FROM analysis_req_det ard, analysis_param apar, analysis_parameter ap
             WHERE ard.id_analysis_req_det = i_analysis_req_det
               AND ard.id_analysis = apar.id_analysis
               AND ard.id_sample_type = apar.id_sample_type
               AND apar.id_institution = i_prof.institution
               AND apar.id_software = i_prof.software
               AND apar.flg_available = pk_lab_tests_constant.g_available
               AND apar.id_analysis_parameter = ap.id_analysis_parameter
               AND ap.flg_available = pk_lab_tests_constant.g_available;
    
        l_analysis_parameter c_analysis_parameter%ROWTYPE;
    
        l_next_par analysis_req_par.id_analysis_req_par%TYPE;
    
        i NUMBER := 1;
    
    BEGIN
    
        o_analysis_req_par := table_number();
    
        FOR rec IN c_analysis_parameter
        LOOP
            g_error := 'GET SEQ_ANALYSIS_REQ_PAR.NEXTVAL';
            SELECT seq_analysis_req_par.nextval
              INTO l_next_par
              FROM dual;
        
            INSERT INTO analysis_req_par
                (id_analysis_req_par, id_analysis_req_det, id_analysis_parameter)
            VALUES
                (l_next_par, i_analysis_req_det, rec.id_analysis_parameter);
        
            -- Log message
            pk_alertlog.log_debug(object_name => 'PK_LAB_TESTS_UTILS',
                                  text        => 'INSERT INTO analysis_req_par(id_analysis_req_par, id_analysis_req_det, id_analysis_parameter) VALUES (' ||
                                                 l_next_par || ', ' || i_analysis_req_det || ', ' ||
                                                 rec.id_analysis_parameter || ')');
        
            l_analysis_parameter.id_analysis    := rec.id_analysis;
            l_analysis_parameter.id_sample_type := rec.id_sample_type;
        
            o_analysis_req_par.extend;
            o_analysis_req_par(i) := l_next_par;
            i := i + 1;
        END LOOP;
    
        IF i = 1
        THEN
            g_error := REPLACE(pk_message.get_message(i_lang, 'ANALYSIS_M097'),
                               '@1',
                               pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                        i_prof,
                                                                        pk_lab_tests_constant.g_analysis_alias,
                                                                        'ANALYSIS.CODE_ANALYSIS.' ||
                                                                        l_analysis_parameter.id_analysis,
                                                                        'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                        l_analysis_parameter.id_sample_type,
                                                                        NULL));
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
                                              'CREATE_LAB_TEST_REQ_PAR',
                                              o_error);
            RETURN FALSE;
    END create_lab_test_req_par;

    FUNCTION get_lab_test_request
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_analysis IN table_number,
        o_msg_req  OUT VARCHAR2,
        o_button   OUT VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_days_limit sys_config.value%TYPE;
        l_string_req VARCHAR2(1000 CHAR);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        o_button := 'NC';
    
        l_days_limit := pk_sysconfig.get_config('LAB_TESTS_LAST_ORDER', i_prof);
    
        SELECT REPLACE(substr(concatenate(lte.desc_analysis || ' - ' ||
                                          pk_date_utils.dt_chr_tsz(i_lang, lte.dt_req, i_prof) || ' (' ||
                                          pk_date_utils.get_elapsed_sysdate_tsz(i_lang, lte.dt_req) || '); '),
                              1,
                              length(concatenate(lte.desc_analysis || ' - ' ||
                                                 pk_date_utils.dt_chr_tsz(i_lang, lte.dt_req, i_prof) || ' (' ||
                                                 pk_date_utils.get_elapsed_sysdate_tsz(i_lang, lte.dt_req) || '); ')) - 2),
                       '); ',
                       '); ' || chr(10))
          INTO l_string_req
          FROM (SELECT lte.dt_req,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 pk_lab_tests_constant.g_analysis_alias,
                                                                 'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type,
                                                                 NULL) desc_analysis,
                       row_number() over(PARTITION BY lte.id_analysis ORDER BY lte.dt_req DESC) rn
                  FROM lab_tests_ea lte,
                       (SELECT *
                          FROM analysis_instit_soft
                         WHERE id_analysis IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                *
                                                 FROM TABLE(i_analysis) t)
                           AND flg_available = pk_lab_tests_constant.g_available
                           AND id_software = i_prof.software
                           AND id_institution = i_prof.institution
                           AND flg_type = pk_lab_tests_constant.g_analysis_can_req) ais
                 WHERE lte.id_patient = i_patient
                   AND lte.id_analysis IN (SELECT /*+opt_estimate(table t rows=1)*/
                                            *
                                             FROM TABLE(i_analysis) t)
                   AND lte.flg_status_det != pk_lab_tests_constant.g_analysis_cancel
                   AND (lte.flg_status_harvest IS NULL OR
                       lte.flg_status_harvest != pk_lab_tests_constant.g_harvest_cancel)
                   AND ((lte.dt_req BETWEEN current_timestamp - numtodsinterval(l_days_limit, 'DAY') AND
                       current_timestamp) OR
                       (lte.dt_harvest BETWEEN current_timestamp - numtodsinterval(l_days_limit, 'DAY') AND
                       current_timestamp) OR
                       (lte.dt_analysis_result BETWEEN current_timestamp - numtodsinterval(l_days_limit, 'DAY') AND
                       current_timestamp))
                   AND lte.id_analysis = ais.id_analysis
                   AND ais.flg_duplicate_warn = pk_lab_tests_constant.g_yes) lte
         WHERE lte.rn = 1;
    
        IF l_string_req IS NOT NULL
        THEN
            o_msg_req := REPLACE(pk_message.get_message(i_lang, 'ANALYSIS_M002'), '@1', l_string_req);
        
            RETURN pk_lab_tests_constant.g_yes;
        ELSE
        
            RETURN pk_lab_tests_constant.g_no;
        END IF;
    
    END get_lab_test_request;

    FUNCTION get_lab_test_id_content
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_content analysis_sample_type.id_content%TYPE;
    
    BEGIN
    
        SELECT ast.id_content
          INTO l_id_content
          FROM analysis_sample_type ast
         WHERE ast.id_analysis = i_analysis
           AND ast.id_sample_type = i_sample_type
           AND ast.flg_available = pk_lab_tests_constant.g_available;
    
        RETURN l_id_content;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_id_content;

    FUNCTION get_lab_test_param_id_content
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_content analysis_parameter.id_content%TYPE;
    
    BEGIN
    
        SELECT apar.id_content
          INTO l_id_content
          FROM analysis_param ap, analysis_parameter apar
         WHERE ap.id_analysis = i_analysis
           AND ap.id_sample_type = i_sample_type
           AND ap.id_analysis_parameter = i_analysis_parameter
           AND ap.id_software = i_prof.software
           AND ap.id_institution = i_prof.institution
           AND ap.flg_available = pk_lab_tests_constant.g_available
           AND ap.id_analysis_parameter = apar.id_analysis_parameter
           AND apar.flg_available = pk_lab_tests_constant.g_available;
    
        RETURN l_id_content;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_param_id_content;

    FUNCTION get_alias_translation
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_flg_type                  IN VARCHAR2,
        i_analysis_code_translation IN translation.code_translation%TYPE,
        i_sample_code_translation   IN translation.code_translation%TYPE,
        i_dep_clin_serv             IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
    
        l_analysis    analysis.id_analysis%TYPE;
        l_sample_type sample_type.id_sample_type%TYPE;
    
        l_desc_mess pk_translation.t_desc_translation;
    
    BEGIN
    
        IF i_flg_type = pk_lab_tests_constant.g_analysis_alias
        THEN
            l_analysis    := REPLACE(i_analysis_code_translation, 'ANALYSIS.CODE_ANALYSIS.');
            l_sample_type := REPLACE(i_sample_code_translation, 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.');
        
            l_desc_mess := pk_lab_tests_utils.get_alias_translation(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_flg_type         => pk_lab_tests_constant.g_analysis_sample_type_alias,
                                                                    i_code_translation => 'ANALYSIS_SAMPLE_TYPE.CODE_ANALYSIS_SAMPLE_TYPE.' ||
                                                                                          lpad(l_analysis, 12, '0') ||
                                                                                          lpad(l_sample_type, 12, '0'),
                                                                    i_dep_clin_serv    => i_dep_clin_serv);
        
            IF l_desc_mess IS NULL
            THEN
                l_desc_mess := pk_lab_tests_utils.get_alias_translation(i_lang             => i_lang,
                                                                        i_prof             => i_prof,
                                                                        i_flg_type         => pk_lab_tests_constant.g_analysis_alias,
                                                                        i_code_translation => i_analysis_code_translation,
                                                                        i_dep_clin_serv    => i_dep_clin_serv) || ', ' ||
                               lower(pk_lab_tests_utils.get_alias_translation(i_lang             => i_lang,
                                                                              i_prof             => i_prof,
                                                                              i_flg_type         => pk_lab_tests_constant.g_analysis_sample_alias,
                                                                              i_code_translation => i_sample_code_translation,
                                                                              i_dep_clin_serv    => i_dep_clin_serv));
            END IF;
        ELSIF i_flg_type = pk_lab_tests_constant.g_analysis_parameter_alias
        THEN
            l_desc_mess := pk_lab_tests_utils.get_alias_translation(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_flg_type         => pk_lab_tests_constant.g_analysis_parameter_alias,
                                                                    i_code_translation => i_analysis_code_translation,
                                                                    i_dep_clin_serv    => i_dep_clin_serv) || ', ' ||
                           lower(pk_lab_tests_utils.get_alias_translation(i_lang             => i_lang,
                                                                          i_prof             => i_prof,
                                                                          i_flg_type         => pk_lab_tests_constant.g_analysis_sample_alias,
                                                                          i_code_translation => i_sample_code_translation,
                                                                          i_dep_clin_serv    => i_dep_clin_serv));
        END IF;
    
        RETURN l_desc_mess;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION get_alias_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_type         IN VARCHAR2,
        i_code_translation IN translation.code_translation%TYPE,
        i_dep_clin_serv    IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
    
        l_code_alias translation.code_translation%TYPE;
        l_desc_mess  pk_translation.t_desc_translation;
    
    BEGIN
    
        g_error      := 'CALL GET_ALIAS_CODE_TRANSLATION';
        l_code_alias := get_alias_code_translation(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_flg_type         => i_flg_type,
                                                   i_code_translation => i_code_translation,
                                                   i_dep_clin_serv    => i_dep_clin_serv);
    
        g_error := 'GET TRANSLATION';
        IF l_code_alias IS NOT NULL
        THEN
            l_desc_mess := pk_translation.get_translation(i_lang, l_code_alias);
        END IF;
    
        g_error := 'TEST OUTPUT MESSAGE';
        IF l_desc_mess IS NULL
        THEN
            l_desc_mess := pk_translation.get_translation(i_lang, i_code_translation);
        END IF;
    
        RETURN l_desc_mess;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION get_alias_code_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_type         IN VARCHAR2,
        i_code_translation IN translation.code_translation%TYPE,
        i_dep_clin_serv    IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN translation.code_translation%TYPE IS
    
        c_code_alias pk_types.cursor_type;
        l_code_alias translation.code_translation%TYPE;
    
    BEGIN
    
        IF i_flg_type = pk_lab_tests_constant.g_analysis_sample_type_alias
        THEN
            g_error := 'OPEN C_ALIAS ANALYSIS_ALIAS';
            OPEN c_code_alias FOR
                SELECT (SELECT code_ast_alias
                          FROM (SELECT t.code_ast_alias,
                                       row_number() over(PARTITION BY t.id_analysis, t.id_sample_type ORDER BY t.id_institution DESC, t.id_software DESC) rn
                                  FROM (SELECT /*+ index(ast ASE_CODE_AST_IDX) use_nl(asta ast) */
                                         asta.code_ast_alias,
                                         asta.id_analysis,
                                         asta.id_sample_type,
                                         asta.id_institution,
                                         asta.id_software,
                                         asta.id_professional,
                                         asta.id_dep_clin_serv
                                          FROM analysis_sample_type_alias asta
                                          JOIN analysis_sample_type ast
                                            ON asta.id_analysis = ast.id_analysis
                                           AND asta.id_sample_type = ast.id_sample_type
                                         WHERE ast.code_analysis_sample_type = i_code_translation
                                           AND rownum > 0) t
                                 WHERE decode(t.id_institution, 0, nvl(i_prof.institution, 0), t.id_institution) =
                                       nvl(i_prof.institution, 0)
                                   AND decode(t.id_software, 0, nvl(i_prof.software, 0), t.id_software) =
                                       nvl(i_prof.software, 0)
                                   AND decode(nvl(t.id_professional, 0), 0, nvl(i_prof.id, 0), t.id_professional) =
                                       nvl(i_prof.id, 0)
                                   AND decode(nvl(t.id_dep_clin_serv, 0), 0, nvl(i_dep_clin_serv, 0), t.id_dep_clin_serv) =
                                       nvl(i_dep_clin_serv, 0))
                         WHERE rn = 1)
                  FROM dual;
        ELSIF i_flg_type = pk_lab_tests_constant.g_analysis_alias
        THEN
        
            g_error := 'OPEN C_ALIAS ANALYSIS_ALIAS';
            OPEN c_code_alias FOR
                SELECT (SELECT code_analysis_alias
                          FROM (SELECT t.code_analysis_alias,
                                       row_number() over(PARTITION BY t.id_analysis ORDER BY t.id_institution DESC, t.id_software DESC) rn
                                  FROM (SELECT /*+ index(a ANALY_CODE_I) use_nl(aa a) */
                                         aa.code_analysis_alias,
                                         aa.id_analysis,
                                         aa.id_institution,
                                         aa.id_software,
                                         aa.id_professional,
                                         aa.id_dep_clin_serv
                                          FROM analysis_alias aa
                                          JOIN analysis a
                                            ON aa.id_analysis = a.id_analysis
                                         WHERE a.code_analysis = i_code_translation
                                           AND rownum > 0) t
                                 WHERE decode(t.id_institution, 0, nvl(i_prof.institution, 0), t.id_institution) =
                                       nvl(i_prof.institution, 0)
                                   AND decode(t.id_software, 0, nvl(i_prof.software, 0), t.id_software) =
                                       nvl(i_prof.software, 0)
                                   AND decode(nvl(t.id_professional, 0), 0, nvl(i_prof.id, 0), t.id_professional) =
                                       nvl(i_prof.id, 0)
                                   AND decode(nvl(t.id_dep_clin_serv, 0), 0, nvl(i_dep_clin_serv, 0), t.id_dep_clin_serv) =
                                       nvl(i_dep_clin_serv, 0))
                         WHERE rn = 1)
                  FROM dual;
        
        ELSIF i_flg_type = pk_lab_tests_constant.g_analysis_group_alias
        THEN
            g_error := 'OPEN C_ALIAS ANALYSIS_GROUP_ALIAS';
            OPEN c_code_alias FOR
                SELECT (SELECT code_analysis_group_alias
                          FROM (SELECT aga.code_analysis_group_alias,
                                       row_number() over(PARTITION BY aga.id_analysis_group ORDER BY aga.id_institution DESC, aga.id_software DESC) rn
                                  FROM analysis_group_alias aga
                                  JOIN analysis_group ag
                                    ON aga.id_analysis_group = ag.id_analysis_group
                                 WHERE decode(aga.id_institution, 0, nvl(i_prof.institution, 0), aga.id_institution) =
                                       nvl(i_prof.institution, 0)
                                   AND decode(aga.id_software, 0, nvl(i_prof.software, 0), aga.id_software) =
                                       nvl(i_prof.software, 0)
                                   AND decode(nvl(aga.id_professional, 0), 0, nvl(i_prof.id, 0), aga.id_professional) =
                                       nvl(i_prof.id, 0)
                                   AND decode(nvl(aga.id_dep_clin_serv, 0),
                                              0,
                                              nvl(i_dep_clin_serv, 0),
                                              aga.id_dep_clin_serv) = nvl(i_dep_clin_serv, 0)
                                   AND ag.code_analysis_group = i_code_translation)
                         WHERE rn = 1)
                  FROM dual;
        ELSIF i_flg_type = pk_lab_tests_constant.g_analysis_parameter_alias
        THEN
            g_error := 'OPEN C_ALIAS ANALYSIS_PARAMETER_ALIAS';
            OPEN c_code_alias FOR
                SELECT (SELECT code_analysis_parameter_alias
                          FROM (SELECT code_analysis_parameter_alias,
                                       row_number() over(PARTITION BY apa.id_analysis_parameter ORDER BY apa.id_institution DESC, apa.id_software DESC) rn
                                  FROM analysis_parameter_alias apa
                                  JOIN analysis_parameter ap
                                    ON apa.id_analysis_parameter = ap.id_analysis_parameter
                                 WHERE decode(apa.id_institution, 0, nvl(i_prof.institution, 0), apa.id_institution) =
                                       nvl(i_prof.institution, 0)
                                   AND decode(apa.id_software, 0, nvl(i_prof.software, 0), apa.id_software) =
                                       nvl(i_prof.software, 0)
                                   AND decode(nvl(apa.id_professional, 0), 0, nvl(i_prof.id, 0), apa.id_professional) =
                                       nvl(i_prof.id, 0)
                                   AND decode(nvl(apa.id_dep_clin_serv, 0),
                                              0,
                                              nvl(i_dep_clin_serv, 0),
                                              apa.id_dep_clin_serv) = nvl(i_dep_clin_serv, 0)
                                   AND ap.code_analysis_parameter = i_code_translation)
                         WHERE rn = 1)
                  FROM dual;
        ELSIF i_flg_type = pk_lab_tests_constant.g_analysis_sample_alias
        THEN
            g_error := 'OPEN C_ALIAS SAMPLE_TYPE_ALIAS';
            OPEN c_code_alias FOR
                SELECT (SELECT code_sample_type_alias
                          FROM (SELECT code_sample_type_alias,
                                       row_number() over(PARTITION BY sta.id_sample_type ORDER BY sta.id_institution DESC, sta.id_software DESC) rn
                                  FROM sample_type_alias sta
                                  JOIN sample_type st
                                    ON sta.id_sample_type = st.id_sample_type
                                 WHERE decode(sta.id_institution, 0, nvl(i_prof.institution, 0), sta.id_institution) =
                                       nvl(i_prof.institution, 0)
                                   AND decode(sta.id_software, 0, nvl(i_prof.software, 0), sta.id_software) =
                                       nvl(i_prof.software, 0)
                                   AND decode(nvl(sta.id_professional, 0), 0, nvl(i_prof.id, 0), sta.id_professional) =
                                       nvl(i_prof.id, 0)
                                   AND decode(nvl(sta.id_dep_clin_serv, 0),
                                              0,
                                              nvl(i_dep_clin_serv, 0),
                                              sta.id_dep_clin_serv) = nvl(i_dep_clin_serv, 0)
                                   AND st.code_sample_type = i_code_translation)
                         WHERE rn = 1)
                  FROM dual;
        END IF;
    
        FETCH c_code_alias
            INTO l_code_alias;
        CLOSE c_code_alias;
    
        RETURN l_code_alias;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_code_translation;

    FUNCTION get_lab_test_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_analysis      IN analysis.id_analysis%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER IS
    
        l_lab_test_rank NUMBER;
    
        l_prof_dep_clin_serv table_number := table_number();
    
    BEGIN
    
        IF i_dep_clin_serv IS NOT NULL
        THEN
            SELECT /*+ result_cache*/
             1
              BULK COLLECT
              INTO l_prof_dep_clin_serv
              FROM prof_dep_clin_serv pdcs
             WHERE pdcs.id_professional = i_prof.id
               AND pdcs.id_dep_clin_serv = i_dep_clin_serv
               AND pdcs.flg_status = pk_lab_tests_constant.g_selected
               AND pdcs.flg_default = pk_lab_tests_constant.g_yes;
        
            IF l_prof_dep_clin_serv.count > 0
            THEN
                g_error := 'GET LAB TEST RANK 1';
                SELECT MAX(adcs.rank)
                  INTO l_lab_test_rank
                  FROM analysis_dep_clin_serv adcs
                 WHERE adcs.id_analysis = i_analysis
                   AND adcs.id_dep_clin_serv = i_dep_clin_serv
                   AND adcs.id_software = i_prof.software
                   AND adcs.flg_available = pk_lab_tests_constant.g_available;
            ELSE
                g_error := 'GET LAB TEST RANK 2';
                SELECT coalesce((SELECT MAX(ais.rank)
                                  FROM analysis_instit_soft ais
                                 WHERE ais.id_analysis = i_analysis
                                   AND ais.id_institution = i_prof.institution
                                   AND ais.id_software = i_prof.software
                                   AND ais.flg_available = pk_lab_tests_constant.g_available),
                                (SELECT MAX(ais.rank)
                                   FROM analysis_instit_soft ais
                                  WHERE ais.id_analysis = i_analysis
                                    AND ais.id_institution = i_prof.institution
                                    AND ais.flg_available = pk_lab_tests_constant.g_available),
                                (SELECT rank
                                   FROM analysis a
                                  WHERE a.id_analysis = i_analysis
                                    AND a.flg_available = pk_lab_tests_constant.g_available))
                  INTO l_lab_test_rank
                  FROM dual;
            END IF;
        ELSE
            g_error := 'GET LAB TEST RANK 3';
            SELECT coalesce((SELECT MAX(ais.rank)
                              FROM analysis_instit_soft ais
                             WHERE ais.id_analysis = i_analysis
                               AND ais.id_institution = i_prof.institution
                               AND ais.id_software = i_prof.software
                               AND ais.flg_available = pk_lab_tests_constant.g_available),
                            (SELECT MAX(ais.rank)
                               FROM analysis_instit_soft ais
                              WHERE ais.id_analysis = i_analysis
                                AND ais.id_institution = i_prof.institution
                                AND ais.flg_available = pk_lab_tests_constant.g_available),
                            (SELECT a.rank
                               FROM analysis a
                              WHERE a.id_analysis = i_analysis
                                AND a.flg_available = pk_lab_tests_constant.g_available))
              INTO l_lab_test_rank
              FROM dual;
        END IF;
    
        IF l_lab_test_rank IS NULL
           OR l_lab_test_rank = 0
        THEN
            l_lab_test_rank := -1;
        END IF;
    
        RETURN l_lab_test_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN - 1;
    END get_lab_test_rank;

    FUNCTION get_lab_test_parameter_rank
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN NUMBER IS
    
        l_parameter_rank NUMBER;
    
    BEGIN
    
        g_error := 'Get lab test parameter rank by institution and software';
        SELECT coalesce((SELECT ap.rank
                          FROM analysis_param ap
                         WHERE ap.id_analysis = i_analysis
                           AND ap.id_sample_type = i_sample_type
                           AND ap.id_analysis_parameter = i_analysis_parameter
                           AND ap.id_institution = i_prof.institution
                           AND ap.id_software = i_prof.software
                           AND ap.flg_available = pk_lab_tests_constant.g_available),
                        (SELECT ap.rank
                           FROM analysis_parameter ap
                          WHERE ap.id_analysis_parameter = i_analysis_parameter
                            AND ap.flg_available = pk_lab_tests_constant.g_available))
          INTO l_parameter_rank
          FROM dual;
    
        IF l_parameter_rank IS NULL
        THEN
            l_parameter_rank := 0;
        END IF;
    
        RETURN l_parameter_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_parameter_rank;

    FUNCTION get_lab_test_sample_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN NUMBER IS
    
        l_sample_type_rank NUMBER;
    
    BEGIN
    
        g_error := 'Get sample type rank';
        SELECT st.rank
          INTO l_sample_type_rank
          FROM sample_type st
         WHERE st.id_sample_type = i_sample_type
           AND st.flg_available = pk_lab_tests_constant.g_available;
    
        IF l_sample_type_rank IS NULL
        THEN
            l_sample_type_rank := 0;
        END IF;
    
        RETURN l_sample_type_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_sample_rank;

    FUNCTION get_lab_test_group_rank
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_analysis_group IN analysis_group.id_analysis_group%TYPE,
        i_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER IS
    
        l_lab_test_group_rank NUMBER;
    
        l_prof_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    
    BEGIN
    
        IF i_dep_clin_serv IS NOT NULL
        THEN
            BEGIN
                SELECT 1
                  INTO l_prof_dep_clin_serv
                  FROM prof_dep_clin_serv pdcs
                 WHERE pdcs.id_professional = i_prof.id
                   AND pdcs.id_dep_clin_serv = i_dep_clin_serv
                   AND pdcs.flg_status = pk_lab_tests_constant.g_selected
                   AND pdcs.flg_default = pk_lab_tests_constant.g_yes;
            EXCEPTION
                WHEN no_data_found THEN
                    l_prof_dep_clin_serv := 0;
            END;
        
            IF l_prof_dep_clin_serv = 1
            THEN
                g_error := 'GET LAB TEST GROUP RANK 1';
                SELECT MAX(adcs.rank)
                  INTO l_lab_test_group_rank
                  FROM analysis_dep_clin_serv adcs
                 WHERE adcs.id_analysis_group = i_analysis_group
                   AND adcs.id_dep_clin_serv = i_dep_clin_serv
                   AND adcs.id_software = i_prof.software
                   AND adcs.flg_available = pk_lab_tests_constant.g_available;
            ELSE
                g_error := 'GET LAB TEST GROUP RANK 2';
                SELECT coalesce((SELECT MAX(ais.rank)
                                  FROM analysis_instit_soft ais
                                 WHERE ais.id_analysis_group = i_analysis_group
                                   AND ais.id_institution = i_prof.institution
                                   AND ais.id_software = i_prof.software
                                   AND ais.flg_available = pk_lab_tests_constant.g_available),
                                (SELECT MAX(ais.rank)
                                   FROM analysis_instit_soft ais
                                  WHERE ais.id_analysis_group = i_analysis_group
                                    AND ais.id_institution = i_prof.institution
                                    AND ais.flg_available = pk_lab_tests_constant.g_available),
                                (SELECT ag.rank
                                   FROM analysis_group ag
                                  WHERE ag.id_analysis_group = i_analysis_group
                                    AND ag.flg_available = pk_lab_tests_constant.g_available))
                  INTO l_lab_test_group_rank
                  FROM dual;
            END IF;
        ELSE
            g_error := 'GET LAB TEST GROUP RANK 3';
            SELECT coalesce((SELECT MAX(ais.rank)
                              FROM analysis_instit_soft ais
                             WHERE ais.id_analysis_group = i_analysis_group
                               AND ais.id_institution = i_prof.institution
                               AND ais.id_software = i_prof.software
                               AND ais.flg_available = pk_lab_tests_constant.g_available),
                            (SELECT MAX(ais.rank)
                               FROM analysis_instit_soft ais
                              WHERE ais.id_analysis_group = i_analysis_group
                                AND ais.id_institution = i_prof.institution
                                AND ais.flg_available = pk_lab_tests_constant.g_available),
                            (SELECT ag.rank
                               FROM analysis_group ag
                              WHERE ag.id_analysis_group = i_analysis_group))
              INTO l_lab_test_group_rank
              FROM dual;
        END IF;
    
        IF l_lab_test_group_rank IS NULL
           OR l_lab_test_group_rank = 0
        THEN
            l_lab_test_group_rank := -1;
        END IF;
    
        RETURN l_lab_test_group_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN - 1;
    END get_lab_test_group_rank;

    FUNCTION get_lab_test_category
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_cat IN exam_cat.id_exam_cat%TYPE
    ) RETURN NUMBER IS
    
        l_exam_cat NUMBER;
    
    BEGIN
    
        g_error := 'SELECT EXAM_CAT';
        SELECT ec.id_exam_cat
          INTO l_exam_cat
          FROM (SELECT ec.id_exam_cat, ec.parent_id
                  FROM exam_cat ec
                 WHERE ec.flg_available = pk_lab_tests_constant.g_available
                CONNECT BY PRIOR ec.parent_id = ec.id_exam_cat
                 START WITH ec.id_exam_cat = i_exam_cat) ec
         WHERE ec.parent_id IS NULL;
    
        RETURN l_exam_cat;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_category;

    FUNCTION get_lab_test_category_rank
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_cat IN exam_cat.id_exam_cat%TYPE
    ) RETURN NUMBER IS
    
        l_rank NUMBER;
    
    BEGIN
    
        g_error := 'SELECT EXAM_CAT';
        SELECT ec.rank
          INTO l_rank
          FROM exam_cat ec
         WHERE ec.id_exam_cat = i_exam_cat
           AND ec.flg_available = pk_lab_tests_constant.g_available;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_category_rank;

    FUNCTION get_lab_test_question_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_analysis      IN analysis.id_analysis%TYPE,
        i_sample_type   IN sample_type.id_sample_type%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_flg_time      IN analysis_questionnaire.flg_time%TYPE
    ) RETURN NUMBER IS
    
        l_rank NUMBER;
    
    BEGIN
    
        g_error := 'SELECT ANALYSIS_QUESTIONNAIRE';
        SELECT MAX(aq.rank)
          INTO l_rank
          FROM analysis_questionnaire aq
         WHERE aq.id_analysis = i_analysis
           AND aq.id_sample_type = i_sample_type
           AND aq.id_questionnaire = i_questionnaire
           AND aq.flg_time = i_flg_time
           AND aq.id_institution = i_prof.institution
           AND aq.flg_available = pk_lab_tests_constant.g_available;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_question_rank;

    FUNCTION get_lab_test_unit_measure
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN NUMBER IS
    
        l_unit_measure analysis_unit_measure.id_unit_measure%TYPE;
    
    BEGIN
    
        g_error := 'SELECT';
        SELECT t.id_unit_measure
          INTO l_unit_measure
          FROM (SELECT aum.id_unit_measure id_unit_measure, rownum rn
                  FROM analysis_unit_measure aum
                 WHERE aum.id_analysis = i_analysis
                   AND aum.id_sample_type = i_sample_type
                   AND aum.id_analysis_parameter = i_analysis_parameter
                   AND aum.id_institution IN (0, i_prof.institution)
                   AND aum.id_software IN (0, i_prof.software)
                   AND aum.flg_default = pk_lab_tests_constant.g_yes
                 ORDER BY aum.id_institution DESC, aum.id_software DESC) t
         WHERE t.rn = 1;
    
        RETURN l_unit_measure;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_lab_test_unit_measure;

    FUNCTION get_lab_test_reference_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_flg_type           IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_patient IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_patient c_patient%ROWTYPE;
    
        l_ref_val VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        IF i_flg_type = 'MIN'
        THEN
            g_error := 'SELECT';
            SELECT TRIM(t.val_min_str)
              INTO l_ref_val
              FROM (SELECT aum.val_min_str, rownum rn
                      FROM analysis_unit_measure aum
                     WHERE aum.id_analysis = i_analysis
                       AND aum.id_sample_type = i_sample_type
                       AND aum.id_analysis_parameter = i_analysis_parameter
                       AND aum.id_institution IN (0, i_prof.institution)
                       AND aum.id_software IN (0, i_prof.software)
                       AND aum.flg_default = pk_lab_tests_constant.g_yes
                       AND (((l_patient.gender IS NOT NULL AND
                           coalesce(aum.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                           l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                           (nvl(l_patient.age, 0) BETWEEN nvl(aum.age_min, 0) AND
                           nvl(aum.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0))
                     ORDER BY id_institution DESC, id_software DESC) t
             WHERE t.rn = 1;
        ELSIF i_flg_type = 'MAX'
        THEN
            g_error := 'SELECT';
            SELECT TRIM(t.val_max_str)
              INTO l_ref_val
              FROM (SELECT aum.val_max_str, rownum rn
                      FROM analysis_unit_measure aum
                     WHERE aum.id_analysis = i_analysis
                       AND aum.id_sample_type = i_sample_type
                       AND aum.id_analysis_parameter = i_analysis_parameter
                       AND aum.id_institution IN (0, i_prof.institution)
                       AND aum.id_software IN (0, i_prof.software)
                       AND aum.flg_default = pk_lab_tests_constant.g_yes
                       AND (((l_patient.gender IS NOT NULL AND
                           coalesce(aum.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                           l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                           (nvl(l_patient.age, 0) BETWEEN nvl(aum.age_min, 0) AND
                           nvl(aum.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0))
                     ORDER BY id_institution DESC, id_software DESC) t
             WHERE t.rn = 1;
        ELSE
            g_error := 'SELECT';
            SELECT TRIM(t.val_min_str) || ' - ' || TRIM(t.val_max_str)
              INTO l_ref_val
              FROM (SELECT aum.val_min_str, aum.val_max_str, rownum rn
                      FROM analysis_unit_measure aum
                     WHERE aum.id_analysis = i_analysis
                       AND aum.id_sample_type = i_sample_type
                       AND aum.id_analysis_parameter = i_analysis_parameter
                       AND aum.id_institution IN (0, i_prof.institution)
                       AND aum.id_software IN (0, i_prof.software)
                       AND aum.flg_default = pk_lab_tests_constant.g_yes
                       AND (((l_patient.gender IS NOT NULL AND
                           coalesce(aum.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                           l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                           (nvl(l_patient.age, 0) BETWEEN nvl(aum.age_min, 0) AND
                           nvl(aum.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0))
                     ORDER BY id_institution DESC, id_software DESC) t
             WHERE t.rn = 1;
        
            IF l_ref_val = ' - '
            THEN
                l_ref_val := '';
            END IF;
        END IF;
    
        RETURN l_ref_val;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_lab_test_reference_value;

    FUNCTION get_lab_test_parameter_type
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN VARCHAR2 IS
    
        l_parameter_type analysis_parameter.flg_type%TYPE;
    
    BEGIN
    
        g_error := 'SELECT';
        SELECT ap.flg_type
          INTO l_parameter_type
          FROM analysis_parameter ap
         WHERE ap.id_analysis_parameter = i_analysis_parameter;
    
        RETURN l_parameter_type;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_lab_test_parameter_type;

    FUNCTION get_lab_test_parameter_color
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN VARCHAR2 IS
    
        l_parameter_color analysis_param.color_graph%TYPE;
    
    BEGIN
    
        g_error := 'SELECT';
        SELECT ap.color_graph
          INTO l_parameter_color
          FROM analysis_param ap
         WHERE ap.id_analysis = i_analysis
           AND ap.id_sample_type = i_sample_type
           AND ap.id_analysis_parameter = i_analysis_parameter
           AND ap.id_institution = i_prof.institution
           AND ap.id_software = i_prof.software
           AND ap.flg_available = pk_lab_tests_constant.g_available;
    
        RETURN l_parameter_color;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_lab_test_parameter_color;

    FUNCTION get_lab_test_parameter_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN NUMBER IS
    
        l_sample_text sample_text.id_sample_text%TYPE;
    
    BEGIN
    
        g_error := 'SELECT';
        SELECT t.id_sample_text
          INTO l_sample_text
          FROM (SELECT aum.id_sample_text id_sample_text, rownum rn
                  FROM analysis_unit_measure aum
                 WHERE aum.id_analysis = i_analysis
                   AND aum.id_sample_type = i_sample_type
                   AND aum.id_analysis_parameter = i_analysis_parameter
                   AND aum.id_institution IN (0, i_prof.institution)
                   AND aum.id_software IN (0, i_prof.software)
                   AND aum.flg_default = pk_lab_tests_constant.g_yes
                 ORDER BY aum.id_institution DESC, aum.id_software DESC) t
         WHERE t.rn = 1;
    
        RETURN l_sample_text;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_lab_test_parameter_notes;

    FUNCTION get_lab_test_cat_id_content
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_cat IN exam_cat.id_exam_cat%TYPE
    ) RETURN VARCHAR2 IS
    
        l_content VARCHAR2(200 CHAR);
    
    BEGIN
    
        g_error := 'SELECT EXAM_CAT';
        SELECT id_content
          INTO l_content
          FROM exam_cat ec
         WHERE ec.id_exam_cat = i_exam_cat
           AND ec.flg_available = pk_lab_tests_constant.g_yes;
    
        RETURN l_content;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_lab_test_cat_id_content;

    FUNCTION get_questionnaire_id_content
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN VARCHAR2 IS
    
        l_content VARCHAR2(200 CHAR);
    
    BEGIN
    
        IF i_response IS NOT NULL
        THEN
            g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
            SELECT id_content
              INTO l_content
              FROM questionnaire_response qr
             WHERE qr.id_questionnaire = i_questionnaire
               AND qr.id_response = i_response
               AND qr.flg_available = pk_lab_tests_constant.g_yes;
        ELSE
            g_error := 'SELECT QUESTIONNAIRE';
            SELECT id_content
              INTO l_content
              FROM questionnaire q
             WHERE q.id_questionnaire = i_questionnaire
               AND q.flg_available = pk_lab_tests_constant.g_yes;
        END IF;
    
        RETURN l_content;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_questionnaire_id_content;

    PROCEDURE get_lab_test_init_parameters
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
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        i_context_ids(g_prof_software));
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_flg_type     VARCHAR2(2 CHAR);
        l_codification codification.id_codification%TYPE;
        l_analysis_req analysis_req.id_analysis_req%TYPE;
        l_harvest      harvest.id_harvest%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
    
        pk_context_api.set_parameter('i_patient', l_patient);
        pk_context_api.set_parameter('i_episode', l_episode);
    
        CASE i_custom_filter
            WHEN 0 THEN
                l_flg_type := pk_lab_tests_constant.g_analysis_can_req;
            WHEN 1 THEN
                l_flg_type := pk_lab_tests_constant.g_analysis_freq;
            WHEN 2 THEN
                l_flg_type := pk_lab_tests_constant.g_analysis_complaint;
            ELSE
                l_flg_type := pk_lab_tests_constant.g_analysis_codification;
            
                IF i_context_vals IS NOT NULL
                   AND i_context_vals.count > 0
                THEN
                    BEGIN
                        l_codification := i_context_vals(3);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_codification := i_context_vals(2);
                    END;
                END IF;
        END CASE;
    
        pk_context_api.set_parameter('i_flg_type', l_flg_type);
        pk_context_api.set_parameter('i_analysis_req', l_analysis_req);
        pk_context_api.set_parameter('i_harvest', l_harvest);
        pk_context_api.set_parameter('i_codification',
                                     CASE WHEN i_filter_name = 'LabTestsSearch' THEN i_context_vals(2) ELSE
                                     l_codification END);
        pk_context_api.set_parameter('i_value',
                                     CASE WHEN i_filter_name = 'LabTestsSearch' THEN i_context_vals(1) ELSE NULL END);
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'g_analysis_alias' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_alias;
            WHEN 'g_analysis_area_lab_tests' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_area_lab_tests;
            WHEN 'g_analysis_area_orders' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_area_orders;
            WHEN 'g_analysis_button_ok' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_button_ok;
            WHEN 'g_analysis_button_cancel' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_button_cancel;
            WHEN 'g_analysis_button_action' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_button_action;
            WHEN 'g_analysis_button_edit' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_button_edit;
            WHEN 'g_analysis_button_confirmation' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_button_confirmation;
            WHEN 'g_analysis_button_read' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_button_read;
            WHEN 'g_analysis_pending' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_pending;
            WHEN 'g_analysis_req' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_req;
            WHEN 'g_analysis_tosched' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_tosched;
            WHEN 'g_analysis_result' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_result;
            WHEN 'g_analysis_type_req' THEN
                o_vc2 := pk_lab_tests_constant.g_analysis_type_req;
            WHEN 'g_flg_time_r' THEN
                o_vc2 := pk_lab_tests_constant.g_flg_time_r;
            WHEN 'g_media_archive_analysis_doc' THEN
                o_vc2 := pk_lab_tests_constant.g_media_archive_analysis_doc;
            WHEN 'g_yes' THEN
                o_vc2 := pk_lab_tests_constant.g_yes;
            WHEN 'g_no' THEN
                o_vc2 := pk_lab_tests_constant.g_no;
            WHEN 'g_syn_str_analysis' THEN
                o_vc2 := 'ANALYSIS.CODE_ANALYSIS OR ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS';
            WHEN 'g_color_red' THEN
                o_vc2 := pk_alert_constant.g_color_red;
            WHEN 'g_display_type_date_icon' THEN
                o_vc2 := pk_alert_constant.g_display_type_date_icon;
            WHEN 'g_dt_yyyymmddhh24miss_tzr' THEN
                o_vc2 := pk_alert_constant.g_dt_yyyymmddhh24miss_tzr;
            WHEN 'l_msg_order' THEN
                o_vc2 := pk_message.get_message(l_lang, 'LAB_TESTS_T181');
            WHEN 'l_msg_lab_tests_num' THEN
                o_vc2 := pk_message.get_message(l_lang, 'LAB_TESTS_T182');
            WHEN 'l_msg_not_aplicable' THEN
                o_vc2 := pk_message.get_message(l_lang, 'COMMON_M036');
            WHEN 'l_msg_notes' THEN
                o_vc2 := pk_message.get_message(l_lang, 'COMMON_M097');
            WHEN 'l_top_result' THEN
                o_vc2 := pk_sysconfig.get_config('LAB_TESTS_RESULTS_ON_TOP', l_prof);
            WHEN 'l_visit' THEN
                o_id := pk_visit.get_visit(l_episode, l_error);
            WHEN 'l_epis_type' THEN
                SELECT id_epis_type
                  INTO o_id
                  FROM episode
                 WHERE id_episode = l_episode;
        END CASE;
    
    END get_lab_test_init_parameters;

    FUNCTION get_lab_test_in_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_flg_type     IN VARCHAR2
    ) RETURN CLOB IS
    
        l_analysis_req_det CLOB;
        l_desc_analysis    CLOB;
    
    BEGIN
    
        g_error := 'GET L_ANALYSIS_REQ_DET AND L_DESC_ANALYSIS';
        SELECT substr(concatenate_clob(lte.id_analysis_req_det || ';'),
                      1,
                      length(concatenate_clob(lte.id_analysis_req_det || ';')) - 1) id_analysis_req_det,
               substr(concatenate_clob(lte.desc_analysis || '@' || lte.status_string || ';'),
                      1,
                      length(concatenate_clob(lte.desc_analysis || '@' || lte.status_string || ';')) - 1) desc_analysis
          INTO l_analysis_req_det, l_desc_analysis
          FROM (SELECT lte.id_analysis_req_det,
                       pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                i_prof,
                                                                pk_lab_tests_constant.g_analysis_alias,
                                                                'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type,
                                                                NULL) desc_analysis,
                       pk_utils.get_status_string(i_lang,
                                                  i_prof,
                                                  lte.status_str,
                                                  lte.status_msg,
                                                  lte.status_icon,
                                                  lte.status_flg) status_string,
                       decode(lte.flg_referral,
                              NULL,
                              pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_STATUS', lte.flg_status_det),
                              pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_REFERRAL', lte.flg_referral)) rank
                  FROM lab_tests_ea lte
                 WHERE lte.id_analysis_req = i_analysis_req
                   AND (SELECT get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                          FROM dual) = pk_alert_constant.g_yes
                 ORDER BY 4, 2) lte;
    
        IF i_flg_type = 'ID'
        THEN
            RETURN l_analysis_req_det;
        ELSE
            RETURN l_desc_analysis;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_in_order;

    FUNCTION get_harvest_in_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE
    ) RETURN CLOB IS
    
        l_harvest CLOB;
    
    BEGIN
    
        g_error := 'GET L_HARVEST';
        SELECT substr(concatenate_clob(lte.id_harvest || ';'), 1, length(concatenate_clob(lte.id_harvest || ';')) - 1) id_harvest
          INTO l_harvest
          FROM (SELECT lte.id_analysis_req_det,
                       ah.id_harvest,
                       pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                i_prof,
                                                                pk_lab_tests_constant.g_analysis_alias,
                                                                'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type,
                                                                NULL) desc_analysis,
                       decode(lte.flg_referral,
                              NULL,
                              pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_STATUS', lte.flg_status_det),
                              pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_REFERRAL', lte.flg_referral)) rank
                  FROM lab_tests_ea lte, analysis_harvest ah
                 WHERE lte.id_analysis_req = i_analysis_req
                   AND lte.id_analysis_req_det = ah.id_analysis_req_det
                   AND (SELECT get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                          FROM dual) = pk_alert_constant.g_yes
                 ORDER BY 4, 3) lte;
    
        RETURN l_harvest;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_harvest_in_order;

    FUNCTION get_lab_test_permission
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_area                IN VARCHAR2,
        i_button              IN VARCHAR2,
        i_episode             IN episode.id_episode%TYPE,
        i_analysis_req        IN analysis_req.id_analysis_req%TYPE,
        i_analysis_req_det    IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_current_episode IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_analysis_req IS
            SELECT lte.id_episode analysis_episode,
                   lte.id_prof_writes id_prof_req,
                   lte.id_prof_order,
                   lte.flg_time_harvest flg_time,
                   decode(i_analysis_req, NULL, lte.flg_status_det, lte.flg_status_req) flg_status,
                   lte.flg_referral,
                   lte.dt_target dt_begin,
                   lte.flg_col_inst,
                   ais.flg_first_result
              FROM (SELECT id_analysis_req_det,
                           id_analysis,
                           dt_target,
                           id_sample_type,
                           flg_time_harvest,
                           flg_status_req,
                           flg_status_det,
                           flg_col_inst,
                           flg_referral,
                           id_prof_writes,
                           id_prof_order,
                           id_episode
                      FROM lab_tests_ea
                     WHERE id_analysis_req_det = i_analysis_req_det
                    UNION
                    SELECT id_analysis_req_det,
                           id_analysis,
                           dt_target,
                           id_sample_type,
                           flg_time_harvest,
                           flg_status_req,
                           flg_status_det,
                           flg_col_inst,
                           flg_referral,
                           id_prof_writes,
                           id_prof_order,
                           id_episode
                      FROM lab_tests_ea
                     WHERE id_analysis_req = i_analysis_req) lte,
                   analysis_req_det ard,
                   (SELECT *
                      FROM analysis_instit_soft
                     WHERE flg_available = pk_lab_tests_constant.g_available
                       AND id_institution = i_prof.institution
                       AND id_software = i_prof.software) ais
             WHERE lte.id_analysis_req_det = ard.id_analysis_req_det
               AND lte.id_analysis = ais.id_analysis(+)
               AND lte.id_sample_type = ais.id_sample_type(+)
               AND (SELECT get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                      FROM dual) = pk_alert_constant.g_yes;
    
        CURSOR c_analysis_result IS
            SELECT ar.*
              FROM analysis_result ar
             WHERE ar.id_analysis_req_det = i_analysis_req_det
               AND (SELECT get_lab_test_access_permission(i_lang, i_prof, ar.id_analysis)
                      FROM dual) = pk_alert_constant.g_yes;
    
        l_permission VARCHAR2(1 CHAR);
    
        l_analysis_req    c_analysis_req%ROWTYPE;
        l_analysis_result c_analysis_result%ROWTYPE;
        l_episode_type    episode.id_epis_type%TYPE;
    
        l_workflow                   sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_WORKFLOW', i_prof);
        l_ref                        sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_AVAILABILITY', i_prof);
        l_ref_shortcut               sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_MCDT_SHORTCUT', i_prof);
        l_cancel_order               sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_ORDER_CANCEL', i_prof);
        l_canceling_permission       sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_CANCEL_PERMISSION',
                                                                                      i_prof);
        l_edit_result                sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_RESULT_EDIT', i_prof);
        l_cancel_result              sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_RESULT_CANCEL', i_prof);
        l_reading_permission         sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_READING_PERMISSION_BY_PROFILE_TEMPLATE',
                                                                                      i_prof);
        l_reading_without_permission sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_READING_WITHOUT_PERMISSIONS_BY_PROF_TEMPLATE',
                                                                                      i_prof);
    
        l_prof_cat_type category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
    
        l_view_only_profile VARCHAR2(1 CHAR) := pk_prof_utils.check_has_functionality(i_lang,
                                                                                      i_prof,
                                                                                      'READ ONLY PROFILE');
    
    BEGIN
    
        g_error := 'OPEN C_ANALYSIS_REQ';
        OPEN c_analysis_req;
        FETCH c_analysis_req
            INTO l_analysis_req;
        CLOSE c_analysis_req;
    
        g_error := 'OPEN C_ANALYSIS_RESULT';
        OPEN c_analysis_result;
        FETCH c_analysis_result
            INTO l_analysis_result;
        CLOSE c_analysis_result;
    
        IF i_area = pk_lab_tests_constant.g_analysis_area_lab_tests
        THEN
            IF i_button = pk_lab_tests_constant.g_analysis_button_ok
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_analysis_req.flg_referral IN
                       (pk_lab_tests_constant.g_flg_referral_s, pk_lab_tests_constant.g_flg_referral_i)
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSE
                        IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_cancel
                        THEN
                            l_permission := pk_lab_tests_constant.g_no;
                        ELSIF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_read
                        THEN
                            l_permission := pk_lab_tests_constant.g_yes;
                        ELSIF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_result
                        THEN
                            IF l_episode_type = pk_lab_tests_constant.g_episode_type_lab
                            THEN
                                IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                THEN
                                    l_permission := pk_lab_tests_constant.g_yes;
                                ELSE
                                    l_permission := pk_lab_tests_constant.g_no;
                                END IF;
                            ELSE
                                IF i_prof.id IN (l_analysis_req.id_prof_req, l_analysis_req.id_prof_order)
                                THEN
                                    l_permission := pk_lab_tests_constant.g_yes;
                                ELSE
                                    SELECT decode(i_prof.id,
                                                  pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                               i_prof,
                                                                                               e.id_episode,
                                                                                               l_prof_cat_type,
                                                                                               NULL),
                                                  pk_lab_tests_constant.g_yes,
                                                  pk_lab_tests_constant.g_no)
                                      INTO l_permission
                                      FROM episode e
                                     WHERE e.id_episode = i_episode;
                                END IF;
                            END IF;
                        ELSE
                            IF i_flg_current_episode = pk_lab_tests_constant.g_yes
                            THEN
                                IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_exterior
                                THEN
                                    IF l_ref = pk_lab_tests_constant.g_yes
                                       AND l_ref_shortcut = pk_lab_tests_constant.g_yes
                                       AND l_prof_cat_type IN
                                       (pk_alert_constant.g_cat_type_doc, pk_alert_constant.g_cat_type_technician)
                                    THEN
                                        l_permission := pk_lab_tests_constant.g_yes;
                                    ELSE
                                        l_permission := pk_lab_tests_constant.g_no;
                                    END IF;
                                ELSE
                                    IF l_workflow = pk_lab_tests_constant.g_yes
                                    THEN
                                        IF l_analysis_req.flg_time = pk_lab_tests_constant.g_flg_time_b
                                        THEN
                                            IF l_analysis_req.flg_status IN
                                               (pk_lab_tests_constant.g_analysis_tosched,
                                                pk_lab_tests_constant.g_analysis_sched)
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_no;
                                            ELSE
                                                IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                END IF;
                                            END IF;
                                        ELSIF l_analysis_req.flg_time = pk_lab_tests_constant.g_flg_time_n
                                        THEN
                                            IF i_episode = l_analysis_req.analysis_episode
                                            THEN
                                                IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                                THEN
                                                    IF l_analysis_req.flg_status IN
                                                       (pk_lab_tests_constant.g_analysis_wtg_tde,
                                                        pk_lab_tests_constant.g_analysis_pending,
                                                        pk_lab_tests_constant.g_analysis_toexec)
                                                    THEN
                                                        l_permission := pk_lab_tests_constant.g_yes;
                                                    ELSIF l_analysis_req.flg_status IN
                                                          (pk_lab_tests_constant.g_analysis_req,
                                                           pk_lab_tests_constant.g_analysis_sos)
                                                    THEN
                                                        IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                                        THEN
                                                            l_permission := pk_lab_tests_constant.g_yes;
                                                        ELSE
                                                            l_permission := pk_lab_tests_constant.g_no;
                                                        END IF;
                                                    ELSE
                                                        l_permission := pk_lab_tests_constant.g_no;
                                                    END IF;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                END IF;
                                            ELSE
                                                l_permission := pk_lab_tests_constant.g_no;
                                            END IF;
                                        ELSE
                                            IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                            THEN
                                                IF l_analysis_req.flg_status IN
                                                   (pk_lab_tests_constant.g_analysis_wtg_tde,
                                                    pk_lab_tests_constant.g_analysis_pending,
                                                    pk_lab_tests_constant.g_analysis_toexec)
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                ELSIF l_analysis_req.flg_status IN
                                                      (pk_lab_tests_constant.g_analysis_req,
                                                       pk_lab_tests_constant.g_analysis_sos)
                                                THEN
                                                    IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                                    THEN
                                                        l_permission := pk_lab_tests_constant.g_yes;
                                                    ELSE
                                                        l_permission := pk_lab_tests_constant.g_no;
                                                    END IF;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                END IF;
                                            ELSE
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            END IF;
                                        END IF;
                                    ELSE
                                        IF l_analysis_req.flg_time = pk_lab_tests_constant.g_flg_time_n
                                        THEN
                                            IF i_episode = l_analysis_req.analysis_episode
                                            THEN
                                                IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                ELSE
                                                    IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                                    THEN
                                                        l_permission := pk_lab_tests_constant.g_yes;
                                                    ELSE
                                                        l_permission := pk_lab_tests_constant.g_no;
                                                    END IF;
                                                END IF;
                                            ELSE
                                                l_permission := pk_lab_tests_constant.g_no;
                                            END IF;
                                        ELSIF l_analysis_req.flg_time = pk_lab_tests_constant.g_flg_time_b
                                        THEN
                                            IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                            THEN
                                                IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                END IF;
                                            ELSE
                                                IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                ELSE
                                                    IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                                    THEN
                                                        l_permission := pk_lab_tests_constant.g_yes;
                                                    ELSE
                                                        l_permission := pk_lab_tests_constant.g_no;
                                                    END IF;
                                                END IF;
                                            END IF;
                                        ELSE
                                            IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                            THEN
                                                IF l_analysis_req.flg_status IN
                                                   (pk_lab_tests_constant.g_analysis_wtg_tde,
                                                    pk_lab_tests_constant.g_analysis_pending,
                                                    pk_lab_tests_constant.g_analysis_req,
                                                    pk_lab_tests_constant.g_analysis_sos)
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                END IF;
                                            ELSE
                                                IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                END IF;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            ELSE
                                IF l_analysis_req.flg_status IN
                                   (pk_lab_tests_constant.g_analysis_tosched, pk_lab_tests_constant.g_analysis_sched)
                                THEN
                                    l_permission := pk_lab_tests_constant.g_no;
                                ELSE
                                    IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                    THEN
                                        l_permission := pk_lab_tests_constant.g_no;
                                    ELSE
                                        l_permission := pk_lab_tests_constant.g_yes;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_cancel
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_analysis_req.flg_referral IN
                       (pk_lab_tests_constant.g_flg_referral_r,
                        pk_lab_tests_constant.g_flg_referral_s,
                        pk_lab_tests_constant.g_flg_referral_i)
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSE
                        IF l_analysis_req.flg_status IN
                           (pk_lab_tests_constant.g_analysis_result,
                            pk_lab_tests_constant.g_analysis_read,
                            pk_lab_tests_constant.g_analysis_cancel)
                        THEN
                            l_permission := pk_lab_tests_constant.g_no;
                        ELSE
                            IF l_cancel_order = pk_lab_tests_constant.g_yes
                            THEN
                                BEGIN
                                    SELECT /*+opt_estimate (table t rows=1)*/
                                     pk_lab_tests_constant.g_no
                                      INTO l_permission
                                      FROM TABLE(pk_string_utils.str_split(l_canceling_permission, '|'))
                                     WHERE column_value = l_analysis_req.flg_status;
                                
                                EXCEPTION
                                    WHEN no_data_found THEN
                                        IF l_prof_cat_type NOT IN
                                           (pk_alert_constant.g_cat_type_doc, pk_alert_constant.g_cat_type_technician)
                                        THEN
                                            IF pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                                                      i_prof                   => i_prof,
                                                                                      i_episode                => i_episode,
                                                                                      i_task_type              => pk_alert_constant.g_task_lab_tests,
                                                                                      i_cosign_def_action_type => pk_co_sign.g_cosign_action_def_cancel) =
                                               pk_lab_tests_constant.g_yes
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            ELSE
                                                IF pk_prof_utils.get_category(i_lang,
                                                                              profissional(l_analysis_req.id_prof_req,
                                                                                           i_prof.institution,
                                                                                           i_prof.software)) =
                                                   l_prof_cat_type
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                END IF;
                                            END IF;
                                        ELSE
                                            l_permission := pk_lab_tests_constant.g_yes;
                                        END IF;
                                END;
                            ELSE
                                l_permission := pk_lab_tests_constant.g_no;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_action
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_cancel
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSE
                        l_permission := pk_lab_tests_constant.g_yes;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_edit
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_analysis_req.flg_referral IN
                       (pk_lab_tests_constant.g_flg_referral_r,
                        pk_lab_tests_constant.g_flg_referral_s,
                        pk_lab_tests_constant.g_flg_referral_i)
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSIF l_analysis_req.flg_status IN
                          (pk_lab_tests_constant.g_analysis_sos,
                           pk_lab_tests_constant.g_analysis_exterior,
                           pk_lab_tests_constant.g_analysis_tosched,
                           pk_lab_tests_constant.g_analysis_pending,
                           pk_lab_tests_constant.g_analysis_req,
                           pk_lab_tests_constant.g_analysis_review)
                    THEN
                        l_permission := pk_lab_tests_constant.g_yes;
                    ELSE
                        l_permission := pk_lab_tests_constant.g_no;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_confirmation
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_analysis_req.analysis_episode IS NOT NULL
                    THEN
                        IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_pending
                        THEN
                            l_permission := pk_lab_tests_constant.g_yes;
                        ELSIF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_exterior
                              AND l_ref = pk_lab_tests_constant.g_yes
                        THEN
                            l_permission := pk_lab_tests_constant.g_yes;
                        ELSE
                            l_permission := pk_lab_tests_constant.g_no;
                        END IF;
                    ELSE
                        IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_exterior
                           AND l_ref = pk_lab_tests_constant.g_yes
                        THEN
                            l_permission := pk_lab_tests_constant.g_yes;
                        ELSE
                            l_permission := pk_lab_tests_constant.g_no;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_read
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    BEGIN
                        -- Checks if exists any profile that exceptionaly should NOT have reading permissions. --
                        -- If returns, the reading permission should be disabled, otherwise proceeds with validation --
                        -- USA - Tuba City request --
                        SELECT /*+opt_estimate (table t rows=1)*/
                        DISTINCT pk_lab_tests_constant.g_no
                          INTO l_permission
                          FROM TABLE(pk_string_utils.str_split(l_reading_without_permission, '|'))
                         WHERE column_value = pk_prof_utils.get_prof_profile_template(i_prof);
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_result
                            THEN
                                IF l_episode_type = pk_lab_tests_constant.g_episode_type_lab
                                THEN
                                    IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                    THEN
                                        l_permission := pk_lab_tests_constant.g_yes;
                                    ELSE
                                        l_permission := pk_lab_tests_constant.g_no;
                                    END IF;
                                ELSE
                                    BEGIN
                                        -- Checks if exists any profile that shoud have reading permissions. --
                                        -- If returns, it should proceed without any validation, and the reading option will be visible. --
                                        -- UK - Brighton NHS Trust request --           
                                        SELECT /*+opt_estimate (table t rows=1)*/
                                        DISTINCT pk_lab_tests_constant.g_yes
                                          INTO l_permission
                                          FROM TABLE(pk_string_utils.str_split(l_reading_permission, '|'))
                                         WHERE column_value = pk_prof_utils.get_prof_profile_template(i_prof);
                                    
                                    EXCEPTION
                                        WHEN no_data_found THEN
                                            IF i_prof.id IN (l_analysis_req.id_prof_req, l_analysis_req.id_prof_order)
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            ELSE
                                                SELECT decode(i_prof.id,
                                                              pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                                           i_prof,
                                                                                                           e.id_episode,
                                                                                                           l_prof_cat_type,
                                                                                                           NULL),
                                                              pk_lab_tests_constant.g_yes,
                                                              pk_lab_tests_constant.g_no)
                                                  INTO l_permission
                                                  FROM episode e
                                                 WHERE e.id_episode = i_episode;
                                            END IF;
                                    END;
                                END IF;
                            ELSE
                                l_permission := pk_lab_tests_constant.g_no;
                            END IF;
                    END;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_detail
            THEN
                l_permission := pk_lab_tests_constant.g_yes;
            END IF;
        ELSIF i_area = pk_lab_tests_constant.g_analysis_area_orders
        THEN
            IF i_button = pk_lab_tests_constant.g_analysis_button_ok
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_cancel
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSIF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_read
                    THEN
                        l_permission := pk_lab_tests_constant.g_yes;
                    ELSIF l_analysis_req.flg_status IN
                          (pk_lab_tests_constant.g_analysis_result_partial, pk_lab_tests_constant.g_analysis_result)
                    THEN
                        IF l_episode_type = pk_lab_tests_constant.g_episode_type_lab
                        THEN
                            IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                            THEN
                                l_permission := pk_lab_tests_constant.g_yes;
                            ELSE
                                l_permission := pk_lab_tests_constant.g_no;
                            END IF;
                        ELSE
                            IF i_prof.id IN (l_analysis_req.id_prof_req, l_analysis_req.id_prof_order)
                            THEN
                                l_permission := pk_lab_tests_constant.g_yes;
                            ELSE
                                SELECT decode(i_prof.id,
                                              pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                           i_prof,
                                                                                           e.id_episode,
                                                                                           l_prof_cat_type,
                                                                                           NULL),
                                              pk_lab_tests_constant.g_yes,
                                              pk_lab_tests_constant.g_no)
                                  INTO l_permission
                                  FROM episode e
                                 WHERE e.id_episode = i_episode;
                            END IF;
                        END IF;
                    ELSIF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_exterior
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSE
                        IF i_flg_current_episode = pk_lab_tests_constant.g_yes
                        THEN
                            IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_exterior
                            THEN
                                IF l_ref = pk_lab_tests_constant.g_yes
                                   AND l_ref_shortcut = pk_lab_tests_constant.g_yes
                                   AND l_prof_cat_type IN
                                   (pk_alert_constant.g_cat_type_doc, pk_alert_constant.g_cat_type_technician)
                                THEN
                                    l_permission := pk_lab_tests_constant.g_yes;
                                ELSE
                                    l_permission := pk_lab_tests_constant.g_no;
                                END IF;
                            ELSE
                                IF l_workflow = pk_lab_tests_constant.g_yes
                                THEN
                                    IF l_analysis_req.flg_time = pk_lab_tests_constant.g_flg_time_b
                                    THEN
                                        IF l_analysis_req.flg_status IN
                                           (pk_lab_tests_constant.g_analysis_tosched,
                                            pk_lab_tests_constant.g_analysis_sched)
                                        THEN
                                            l_permission := pk_lab_tests_constant.g_no;
                                        ELSE
                                            IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_no;
                                            ELSE
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            END IF;
                                        END IF;
                                    ELSIF l_analysis_req.flg_time = pk_lab_tests_constant.g_flg_time_n
                                    THEN
                                        IF i_episode = l_analysis_req.analysis_episode
                                        THEN
                                            IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                            THEN
                                                IF l_analysis_req.flg_status IN
                                                   (pk_lab_tests_constant.g_analysis_wtg_tde,
                                                    pk_lab_tests_constant.g_analysis_pending,
                                                    pk_lab_tests_constant.g_analysis_toexec)
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                ELSIF l_analysis_req.flg_status IN
                                                      (pk_lab_tests_constant.g_analysis_req,
                                                       pk_lab_tests_constant.g_analysis_sos)
                                                THEN
                                                    IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                                    THEN
                                                        l_permission := pk_lab_tests_constant.g_yes;
                                                    ELSE
                                                        l_permission := pk_lab_tests_constant.g_no;
                                                    END IF;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                END IF;
                                            ELSE
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            END IF;
                                        ELSE
                                            l_permission := pk_lab_tests_constant.g_no;
                                        END IF;
                                    ELSE
                                        IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                        THEN
                                            IF l_analysis_req.flg_status IN
                                               (pk_lab_tests_constant.g_analysis_wtg_tde,
                                                pk_lab_tests_constant.g_analysis_pending,
                                                pk_lab_tests_constant.g_analysis_toexec)
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            ELSIF l_analysis_req.flg_status IN
                                                  (pk_lab_tests_constant.g_analysis_req,
                                                   pk_lab_tests_constant.g_analysis_sos)
                                            THEN
                                                IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                END IF;
                                            ELSE
                                                l_permission := pk_lab_tests_constant.g_no;
                                            END IF;
                                        ELSE
                                            l_permission := pk_lab_tests_constant.g_yes;
                                        END IF;
                                    END IF;
                                ELSE
                                    IF l_analysis_req.flg_time = pk_lab_tests_constant.g_flg_time_n
                                    THEN
                                        IF i_episode = l_analysis_req.analysis_episode
                                        THEN
                                            IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_no;
                                            ELSE
                                                IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                END IF;
                                            END IF;
                                        ELSE
                                            l_permission := pk_lab_tests_constant.g_no;
                                        END IF;
                                    ELSIF l_analysis_req.flg_time = pk_lab_tests_constant.g_flg_time_b
                                    THEN
                                        IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                        THEN
                                            IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            ELSE
                                                l_permission := pk_lab_tests_constant.g_no;
                                            END IF;
                                        ELSE
                                            IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_no;
                                            ELSE
                                                IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                                THEN
                                                    l_permission := pk_lab_tests_constant.g_yes;
                                                ELSE
                                                    l_permission := pk_lab_tests_constant.g_no;
                                                END IF;
                                            END IF;
                                        END IF;
                                    ELSE
                                        IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                        THEN
                                            IF l_analysis_req.flg_status IN
                                               (pk_lab_tests_constant.g_analysis_wtg_tde,
                                                pk_lab_tests_constant.g_analysis_pending,
                                                pk_lab_tests_constant.g_analysis_req,
                                                pk_lab_tests_constant.g_analysis_sos)
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            ELSE
                                                l_permission := pk_lab_tests_constant.g_no;
                                            END IF;
                                        ELSE
                                            IF l_analysis_req.flg_col_inst = pk_lab_tests_constant.g_yes
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            ELSE
                                                l_permission := pk_lab_tests_constant.g_no;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            END IF;
                        ELSE
                            IF l_analysis_req.flg_status IN
                               (pk_lab_tests_constant.g_analysis_tosched, pk_lab_tests_constant.g_analysis_sched)
                            THEN
                                l_permission := pk_lab_tests_constant.g_no;
                            ELSE
                                IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                THEN
                                    l_permission := pk_lab_tests_constant.g_no;
                                ELSE
                                    l_permission := pk_lab_tests_constant.g_yes;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_cancel
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_analysis_req.flg_status IN
                       (pk_lab_tests_constant.g_analysis_partial,
                        pk_lab_tests_constant.g_analysis_result,
                        pk_lab_tests_constant.g_analysis_read,
                        pk_lab_tests_constant.g_analysis_cancel)
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSE
                        IF l_cancel_order = pk_lab_tests_constant.g_yes
                        THEN
                            BEGIN
                                SELECT /*+opt_estimate (table t rows=1)*/
                                 pk_lab_tests_constant.g_no
                                  INTO l_permission
                                  FROM TABLE(pk_string_utils.str_split(l_canceling_permission, '|'))
                                 WHERE column_value = l_analysis_req.flg_status;
                            
                            EXCEPTION
                                WHEN no_data_found THEN
                                    IF l_prof_cat_type NOT IN
                                       (pk_alert_constant.g_cat_type_doc, pk_alert_constant.g_cat_type_technician)
                                    THEN
                                        IF pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                                                  i_prof                   => i_prof,
                                                                                  i_episode                => i_episode,
                                                                                  i_task_type              => pk_alert_constant.g_task_lab_tests,
                                                                                  i_cosign_def_action_type => pk_co_sign.g_cosign_action_def_cancel) =
                                           pk_lab_tests_constant.g_yes
                                        THEN
                                            l_permission := pk_lab_tests_constant.g_yes;
                                        ELSE
                                            IF pk_prof_utils.get_category(i_lang,
                                                                          profissional(l_analysis_req.id_prof_req,
                                                                                       i_prof.institution,
                                                                                       i_prof.software)) =
                                               l_prof_cat_type
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            ELSE
                                                l_permission := pk_lab_tests_constant.g_no;
                                            END IF;
                                        END IF;
                                    ELSE
                                        l_permission := pk_lab_tests_constant.g_yes;
                                    END IF;
                            END;
                        ELSE
                            l_permission := pk_lab_tests_constant.g_no;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_edit
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_analysis_req.flg_status IN (pk_lab_tests_constant.g_analysis_sos,
                                                     pk_lab_tests_constant.g_analysis_exterior,
                                                     pk_lab_tests_constant.g_analysis_tosched,
                                                     pk_lab_tests_constant.g_analysis_pending,
                                                     pk_lab_tests_constant.g_analysis_req)
                    THEN
                        l_permission := pk_lab_tests_constant.g_yes;
                    ELSE
                        l_permission := pk_lab_tests_constant.g_no;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_action
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_cancel
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSE
                        l_permission := pk_lab_tests_constant.g_yes;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_read
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    BEGIN
                        -- Checks if exists any profile that exceptionaly should NOT have reading permissions. --
                        -- If returns, the reading permission should be disabled, otherwise proceeds with validation --
                        -- USA - Tuba City request --
                        SELECT /*+opt_estimate (table t rows=1)*/
                        DISTINCT pk_lab_tests_constant.g_no
                          INTO l_permission
                          FROM TABLE(pk_string_utils.str_split(l_reading_without_permission, '|'))
                         WHERE column_value = pk_prof_utils.get_prof_profile_template(i_prof);
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_result
                            THEN
                                IF l_episode_type = pk_lab_tests_constant.g_episode_type_lab
                                THEN
                                    IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                    THEN
                                        l_permission := pk_lab_tests_constant.g_yes;
                                    ELSE
                                        l_permission := pk_lab_tests_constant.g_no;
                                    END IF;
                                ELSE
                                    BEGIN
                                        -- Checks if exists any profile that shoud have reading permissions. --
                                        -- If returns, it should proceed without any validation, and the reading option will be visible. --
                                        -- UK - Brighton NHS Trust request --           
                                        SELECT /*+opt_estimate (table t rows=1)*/
                                        DISTINCT pk_lab_tests_constant.g_yes
                                          INTO l_permission
                                          FROM TABLE(pk_string_utils.str_split(l_reading_permission, '|'))
                                         WHERE column_value = pk_prof_utils.get_prof_profile_template(i_prof);
                                    
                                    EXCEPTION
                                        WHEN no_data_found THEN
                                            IF i_prof.id IN (l_analysis_req.id_prof_req, l_analysis_req.id_prof_order)
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            ELSE
                                                SELECT decode(i_prof.id,
                                                              pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                                           i_prof,
                                                                                                           e.id_episode,
                                                                                                           l_prof_cat_type,
                                                                                                           NULL),
                                                              pk_lab_tests_constant.g_yes,
                                                              pk_lab_tests_constant.g_no)
                                                  INTO l_permission
                                                  FROM episode e
                                                 WHERE e.id_episode = i_episode;
                                            END IF;
                                    END;
                                END IF;
                            ELSE
                                l_permission := pk_lab_tests_constant.g_no;
                            END IF;
                    END;
                END IF;
            END IF;
        ELSIF i_area = pk_lab_tests_constant.g_analysis_area_results
        THEN
            IF i_button = pk_lab_tests_constant.g_analysis_button_create
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSE
                        l_permission := pk_lab_tests_constant.g_yes;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_edit
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_edit_result = pk_lab_tests_constant.g_no
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSE
                        IF l_analysis_result.flg_status = pk_lab_tests_constant.g_analysis_cancel
                        THEN
                            l_permission := pk_lab_tests_constant.g_no;
                        ELSE
                            IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                            THEN
                                l_permission := pk_lab_tests_constant.g_yes;
                            ELSIF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                            THEN
                                l_permission := pk_lab_tests_constant.g_no;
                            ELSE
                                IF pk_prof_utils.get_category(i_lang,
                                                              profissional(l_analysis_result.id_professional,
                                                                           i_prof.institution,
                                                                           i_prof.software)) = l_prof_cat_type
                                THEN
                                    l_permission := pk_lab_tests_constant.g_yes;
                                ELSE
                                    l_permission := pk_lab_tests_constant.g_no;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_cancel
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_cancel_result = pk_lab_tests_constant.g_no
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSE
                        IF l_analysis_result.flg_status = pk_lab_tests_constant.g_analysis_cancel
                        THEN
                            l_permission := pk_lab_tests_constant.g_no;
                        ELSE
                            IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                            THEN
                                l_permission := pk_lab_tests_constant.g_yes;
                            ELSIF instr(nvl(l_analysis_req.flg_first_result, '#'), l_prof_cat_type) = 0
                            THEN
                                l_permission := pk_lab_tests_constant.g_no;
                            ELSE
                                IF pk_prof_utils.get_category(i_lang,
                                                              profissional(l_analysis_result.id_professional,
                                                                           i_prof.institution,
                                                                           i_prof.software)) = l_prof_cat_type
                                THEN
                                    l_permission := pk_lab_tests_constant.g_yes;
                                ELSE
                                    l_permission := pk_lab_tests_constant.g_no;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_lab_tests_constant.g_analysis_button_read
            THEN
                IF l_view_only_profile = pk_lab_tests_constant.g_yes
                THEN
                    l_permission := pk_lab_tests_constant.g_no;
                ELSE
                    IF l_analysis_result.flg_status = pk_lab_tests_constant.g_analysis_cancel
                    THEN
                        l_permission := pk_lab_tests_constant.g_no;
                    ELSE
                        BEGIN
                            -- Checks if exists any profile that exceptionaly should NOT have reading permissions. --
                            -- If returns, the reading permission should be disabled, otherwise proceeds with validation --
                            -- USA - Tuba City request --
                            SELECT /*+opt_estimate (table t rows=1)*/
                            DISTINCT pk_lab_tests_constant.g_no
                              INTO l_permission
                              FROM TABLE(pk_string_utils.str_split(l_reading_without_permission, '|'))
                             WHERE column_value = pk_prof_utils.get_prof_profile_template(i_prof);
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                IF l_episode_type = pk_lab_tests_constant.g_episode_type_lab
                                THEN
                                    IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                    THEN
                                        l_permission := pk_lab_tests_constant.g_yes;
                                    ELSE
                                        l_permission := pk_lab_tests_constant.g_no;
                                    END IF;
                                ELSE
                                    BEGIN
                                        -- Checks if exists any profile that shoud have reading permissions. --
                                        -- If returns, it should proceed without any validation, and the reading option will be visible. --
                                        -- UK - Brighton NHS Trust request --           
                                        SELECT /*+opt_estimate (table t rows=1)*/
                                        DISTINCT pk_lab_tests_constant.g_yes
                                          INTO l_permission
                                          FROM TABLE(pk_string_utils.str_split(l_reading_permission, '|'))
                                         WHERE column_value = pk_prof_utils.get_prof_profile_template(i_prof);
                                    
                                    EXCEPTION
                                        WHEN no_data_found THEN
                                            IF i_prof.id IN (l_analysis_req.id_prof_req, l_analysis_req.id_prof_order)
                                            THEN
                                                l_permission := pk_lab_tests_constant.g_yes;
                                            ELSE
                                                SELECT decode(i_prof.id,
                                                              pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                                           i_prof,
                                                                                                           e.id_episode,
                                                                                                           l_prof_cat_type,
                                                                                                           NULL),
                                                              pk_lab_tests_constant.g_yes,
                                                              pk_lab_tests_constant.g_no)
                                                  INTO l_permission
                                                  FROM episode e
                                                 WHERE e.id_episode = i_episode;
                                            END IF;
                                    END;
                                END IF;
                        END;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN l_permission;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_permission;

    FUNCTION get_lab_test_access_permission
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN analysis.id_analysis%TYPE,
        i_flg_type IN group_access.flg_type%TYPE DEFAULT pk_lab_tests_constant.g_infectious_diseases_orders
    ) RETURN VARCHAR2 IS
    
        l_count_inst_soft_records NUMBER := 0;
        l_count_prof_records      NUMBER := 0;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count_inst_soft_records
          FROM (SELECT DISTINCT gar.id_record id_analysis
                  FROM group_access ga
                 INNER JOIN group_access_prof gaf
                    ON gaf.id_group_access = ga.id_group_access
                 INNER JOIN group_access_record gar
                    ON gar.id_group_access = ga.id_group_access
                 WHERE ga.id_institution = i_prof.institution
                   AND ga.id_software = i_prof.software
                   AND ga.flg_type = i_flg_type
                   AND gar.flg_type = 'A'
                   AND ga.flg_available = pk_lab_tests_constant.g_available
                   AND gaf.flg_available = pk_lab_tests_constant.g_available
                   AND gar.flg_available = pk_lab_tests_constant.g_available) a_infect
         WHERE a_infect.id_analysis = i_analysis;
    
        IF l_count_inst_soft_records > 0
        THEN
            SELECT COUNT(*)
              INTO l_count_prof_records
              FROM group_access ga
             INNER JOIN group_access_prof gaf
                ON gaf.id_group_access = ga.id_group_access
             INNER JOIN group_access_record gar
                ON gar.id_group_access = ga.id_group_access
             WHERE gaf.id_professional = i_prof.id
               AND ga.id_institution = i_prof.institution
               AND ga.id_software = i_prof.software
               AND ga.flg_type = i_flg_type
               AND gar.flg_type = 'A'
               AND ga.flg_available = pk_lab_tests_constant.g_available
               AND gaf.flg_available = pk_lab_tests_constant.g_available
               AND gar.flg_available = pk_lab_tests_constant.g_available
               AND gar.id_record = i_analysis;
        
            IF l_count_prof_records > 0
            THEN
                RETURN pk_alert_constant.g_yes;
            ELSE
                RETURN pk_alert_constant.g_no;
            END IF;
        ELSE
            RETURN pk_alert_constant.g_yes;
        END IF;
    
    END get_lab_test_access_permission;

    FUNCTION get_lab_test_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diagnosis_list IN analysis_req_det_hist.id_diagnosis_list%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_diagnosis_list IS
            SELECT pk_diagnosis.get_mcdt_description(i_lang, i_prof, t.id_diagnosis_list) diagnosis_desc
              FROM (SELECT column_value id_diagnosis_list
                      FROM TABLE(CAST(pk_utils.str_split(i_diagnosis_list, ';') AS table_varchar2))) t;
    
        l_diagnosis_list c_diagnosis_list%ROWTYPE;
    
        l_diagnosis_desc VARCHAR2(4000);
    
    BEGIN
    
        FOR l_diagnosis_list IN c_diagnosis_list
        LOOP
            IF l_diagnosis_desc IS NULL
            THEN
                l_diagnosis_desc := l_diagnosis_list.diagnosis_desc;
            ELSE
                l_diagnosis_desc := l_diagnosis_desc || ', ' || l_diagnosis_list.diagnosis_desc;
            END IF;
        END LOOP;
    
        RETURN l_diagnosis_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_diagnosis;

    FUNCTION get_lab_test_codification
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_analysis_codification IN analysis_codification.id_analysis_codification%TYPE
    ) RETURN NUMBER IS
    
        l_codification NUMBER;
    
    BEGIN
    
        IF i_analysis_codification IS NOT NULL
        THEN
            g_error := 'SELECT ANALYSIS_CODIFICATION';
            SELECT ac.id_codification
              INTO l_codification
              FROM analysis_codification ac
             WHERE ac.id_analysis_codification = i_analysis_codification;
        ELSE
            l_codification := NULL;
        END IF;
    
        RETURN l_codification;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_codification;

    FUNCTION get_lab_test_with_codification
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_codification VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_analysis IS NOT NULL
           AND i_sample_type IS NOT NULL
        THEN
            g_error := 'GET CODIFICATION';
            SELECT ' (' || listagg(desc_codification, ', ') within GROUP(ORDER BY c.desc_codification) || ')'
              INTO l_codification
              FROM (SELECT pk_translation.get_translation(i_lang, c.code_codification) desc_codification
                      FROM analysis_codification ac, codification_instit_soft cis, codification c
                     WHERE ac.id_analysis = i_analysis
                       AND ac.id_sample_type = i_sample_type
                       AND ac.flg_show_codification = pk_lab_tests_constant.g_yes
                       AND ac.flg_available = pk_lab_tests_constant.g_available
                       AND ac.id_codification = cis.id_codification
                       AND cis.id_institution = i_prof.institution
                       AND cis.id_software = i_prof.software
                       AND cis.flg_available = pk_lab_tests_constant.g_available
                       AND cis.id_codification = c.id_codification
                       AND c.flg_available = pk_lab_tests_constant.g_available) c;
        ELSE
            l_codification := NULL;
        END IF;
    
        IF l_codification = ' ()'
        THEN
            l_codification := NULL;
        END IF;
    
        RETURN l_codification;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_with_codification;

    FUNCTION get_lab_test_icon
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_icon_name VARCHAR2(200 CHAR);
    
    BEGIN
    
        g_error := 'GET ORDER_RECURRENCE';
        SELECT substr(decode(lte.flg_doc,
                             pk_lab_tests_constant.g_yes,
                             pk_sysdomain.get_img(i_lang,
                                                  'ANALYSIS_MEDIA_ARCHIVE.FLG_TYPE',
                                                  pk_lab_tests_constant.g_media_archive_analysis_doc) || '|',
                             NULL) || decode(lte.id_ard_parent, NULL, NULL, 'ReflexTestIcon' || '|') ||
                      decode(lte.flg_relevant,
                             pk_lab_tests_constant.g_yes,
                             pk_sysdomain.get_img(i_lang, 'ANALYSIS_RESULT_PAR.FLG_RELEVANT', lte.flg_relevant) || '|',
                             NULL),
                      1,
                      length(decode(lte.flg_doc,
                                    pk_lab_tests_constant.g_yes,
                                    pk_sysdomain.get_img(i_lang,
                                                         'ANALYSIS_MEDIA_ARCHIVE.FLG_TYPE',
                                                         pk_lab_tests_constant.g_media_archive_analysis_doc) || '|',
                                    NULL) || decode(lte.id_ard_parent, NULL, NULL, 'ReflexTestIcon' || '|') ||
                             decode(lte.flg_relevant,
                                    pk_lab_tests_constant.g_yes,
                                    pk_sysdomain.get_img(i_lang, 'ANALYSIS_RESULT_PAR.FLG_RELEVANT', lte.flg_relevant) || '|',
                                    NULL)) - 1)
          INTO l_icon_name
          FROM lab_tests_ea lte
         WHERE lte.id_analysis_req_det = i_analysis_req_det;
    
        RETURN l_icon_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_icon;

    FUNCTION get_lab_test_barcode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE,
        i_code         IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        TYPE lab_test_barcode IS RECORD(
            clinical_record      clin_record.num_clin_record%TYPE,
            num_label            NUMBER(24),
            dt_label             TIMESTAMP(6) WITH LOCAL TIME ZONE,
            barcode              harvest.barcode%TYPE,
            id_room_receive_tube harvest.id_room_receive_tube%TYPE,
            id_sample_recipient  sample_recipient.id_sample_recipient%TYPE,
            id_sample_type       sample_type.id_sample_type%TYPE);
    
        l_barcode lab_test_barcode;
    
        l_patient patient.id_patient%TYPE;
    
        l_code  VARCHAR2(4000) := i_code;
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET ORDER BARCODE';
        SELECT t.id_patient
          INTO l_patient
          FROM (SELECT ar.id_patient
                  FROM analysis_req ar
                 WHERE ar.id_analysis_req = i_analysis_req
                   AND i_analysis_req IS NOT NULL
                UNION ALL
                SELECT h.id_patient
                  FROM harvest h
                 WHERE h.id_harvest = i_harvest
                   AND i_harvest IS NOT NULL) t;
    
        g_error := 'CALL TO PK_PATIENT.GET_CLIN_REC';
        IF NOT pk_patient.get_clin_rec(i_lang       => i_lang,
                                       i_pat        => l_patient,
                                       i_instit     => i_prof.institution,
                                       i_pat_family => NULL,
                                       o_num        => l_barcode.clinical_record,
                                       o_error      => l_error)
        THEN
            NULL;
        END IF;
    
        IF i_analysis_req IS NOT NULL
        THEN
            g_error := 'GET ORDER BARCODE';
            SELECT ar.id_analysis_req, ar.dt_req_tstz, ar.barcode
              INTO l_barcode.num_label, l_barcode.dt_label, l_barcode.barcode
              FROM analysis_req ar
             WHERE ar.id_analysis_req = i_analysis_req;
        
        ELSE
            g_error := 'GET HARVEST BARCODE';
            SELECT t.dt_harvest_tstz, t.barcode, t.id_room_receive_tube, t.id_sample_recipient, t.id_sample_type
              INTO l_barcode.dt_label,
                   l_barcode.barcode,
                   l_barcode.id_room_receive_tube,
                   l_barcode.id_sample_recipient,
                   l_barcode.id_sample_type
              FROM (SELECT h.dt_harvest_tstz,
                           nvl(h.barcode, ard.barcode) barcode,
                           h.id_room_receive_tube,
                           ah.id_sample_recipient,
                           ard.id_sample_type
                      FROM harvest h, analysis_harvest ah, analysis_req_det ard
                     WHERE h.id_harvest = i_harvest
                       AND h.id_harvest = ah.id_harvest
                       AND ah.id_analysis_req_det = ard.id_analysis_req_det
                     GROUP BY h.id_harvest,
                              h.dt_harvest_tstz,
                              h.barcode,
                              ard.barcode,
                              h.id_room_receive_tube,
                              ah.id_sample_recipient,
                              ard.id_sample_type,
                              h.dt_harvest_reg_tstz) t
             WHERE rownum = 1;
        
        END IF;
    
        g_error := 'REPLACE BARCODE';
        l_code  := REPLACE(l_code, '@01', l_barcode.barcode);
    
        g_error := 'REPLACE BARCODE CODE';
        l_code  := REPLACE(l_code, '@04', l_barcode.barcode);
    
        g_error := 'REPLACE PATIENT';
        l_code  := REPLACE(l_code, '@02', pk_patient.get_patient_name(i_lang, l_patient));
    
        g_error := 'REPLACE CLIN_RECORD';
        l_code  := REPLACE(l_code,
                           '@03',
                           pk_message.get_message(i_lang, i_prof, 'BARCODE_CLIN_REC_LABEL') || ' ' ||
                           l_barcode.clinical_record);
    
        g_error := 'REPLACE';
        l_code  := REPLACE(l_code, '@05', '');
    
        g_error := 'REPLACE LABORATORY';
        l_code  := REPLACE(l_code,
                           '@06',
                           pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || l_barcode.id_room_receive_tube));
    
        g_error := 'REPLACE DT_HARVEST';
        l_code  := REPLACE(l_code,
                           '@07',
                           pk_date_utils.date_char_tsz(i_lang, l_barcode.dt_label, i_prof.institution, i_prof.software));
    
        g_error := 'REPLACE';
        l_code  := REPLACE(l_code, '@08', '');
    
        g_error := 'REPLACE SAMPLE_TYPE';
        l_code  := REPLACE(l_code,
                           '@09',
                           pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                    i_prof,
                                                                    pk_lab_tests_constant.g_analysis_sample_alias,
                                                                    'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                    l_barcode.id_sample_type,
                                                                    NULL));
    
        g_error := 'REPLACE RECIPIENT';
        l_code  := REPLACE(l_code,
                           '@10',
                           pk_translation.get_translation(i_lang,
                                                          'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                          l_barcode.id_sample_recipient));
    
        g_error := 'REPLACE';
        l_code  := REPLACE(l_code, '@11', '');
    
        g_error := 'REPLACE';
        l_code  := REPLACE(l_code, '@12', '');
    
        RETURN l_code;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_barcode;

    FUNCTION get_lab_test_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_field      IN table_varchar,
        i_analysis_field_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_detail VARCHAR2(1000 CHAR);
    
    BEGIN
    
        -- 'T' - Title
        -- 'F'
        IF i_analysis_field_type = 'T'
        THEN
            FOR i IN 2 .. i_analysis_field.count
            LOOP
                IF i_analysis_field(i) IS NOT NULL
                THEN
                    l_detail := i_analysis_field(1);
                END IF;
            END LOOP;
        ELSE
            IF i_analysis_field(1) IS NOT NULL
            THEN
                l_detail := chr(9) || chr(32) || chr(32) || i_analysis_field(1);
            END IF;
        END IF;
    
        RETURN l_detail;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_detail;

    FUNCTION get_lab_test_detail_clob
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_field      IN table_clob,
        i_analysis_field_type IN VARCHAR2
    ) RETURN CLOB IS
    
        l_detail CLOB;
    
    BEGIN
    
        -- 'T' - Title
        -- 'F'
        IF i_analysis_field_type = 'T'
        THEN
            FOR i IN 2 .. i_analysis_field.count
            LOOP
                IF i_analysis_field(i) IS NOT NULL
                THEN
                    l_detail := i_analysis_field(1);
                END IF;
            END LOOP;
        ELSE
            IF i_analysis_field(1) IS NOT NULL
            THEN
                l_detail := chr(9) || chr(32) || chr(32) || i_analysis_field(1);
            END IF;
        END IF;
    
        RETURN l_detail;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_detail_clob;

    FUNCTION get_lab_test_question_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_analysis      IN analysis.id_analysis%TYPE,
        i_sample_type   IN sample_type.id_sample_type%TYPE,
        i_flg_time      IN analysis_questionnaire.flg_time%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN analysis_questionnaire.flg_type%TYPE IS
    
        l_type analysis_questionnaire.flg_type%TYPE;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_analysis = ' || coalesce(to_char(i_analysis), '<null>');
        g_error := g_error || ' i_sample_type = ' || coalesce(to_char(i_sample_type), '<null>');
        g_error := g_error || ' i_questionnaire = ' || coalesce(to_char(i_questionnaire), '<null>');
        g_error := g_error || ' i_response = ' || coalesce(to_char(i_response), '<null>');
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => g_package_name,
                              sub_object_name => 'GET_LAB_TEST_QUESTION_TYPE');
    
        SELECT aq.flg_type
          INTO l_type
          FROM analysis_questionnaire aq
         INNER JOIN questionnaire_response qr
            ON aq.id_questionnaire = qr.id_questionnaire
           AND aq.id_response = qr.id_response
         WHERE aq.id_analysis = i_analysis
           AND aq.id_sample_type = i_sample_type
           AND aq.flg_time = i_flg_time
           AND aq.id_questionnaire = i_questionnaire
           AND (aq.id_response = i_response OR i_response IS NULL)
           AND aq.id_institution = i_prof.institution
           AND aq.flg_available = pk_lab_tests_constant.g_available
           AND qr.flg_available = pk_lab_tests_constant.g_available
           AND rownum < 2;
    
        RETURN l_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'GET_LAB_TEST_QUESTION_TYPE',
                                                  l_error);
                RETURN NULL;
            END;
    END get_lab_test_question_type;

    FUNCTION get_lab_test_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_analysis      IN analysis.id_analysis%TYPE,
        i_sample_type   IN sample_type.id_sample_type%TYPE,
        i_flg_time      IN VARCHAR2
    ) RETURN table_varchar IS
    
        CURSOR c_patient IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_patient c_patient%ROWTYPE;
    
        l_response table_varchar;
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
        SELECT qr.id_response || '|' || qr.desc_response || '|' || qr.flg_free_text
          BULK COLLECT
          INTO l_response
          FROM (SELECT qr.id_response,
                       pk_mcdt.get_response_alias(i_lang, i_prof, 'RESPONSE.CODE_RESPONSE.' || qr.id_response) desc_response,
                       r.flg_free_text,
                       qr.rank
                  FROM questionnaire_response qr, response r
                 WHERE qr.id_questionnaire = i_questionnaire
                   AND qr.flg_available = pk_lab_tests_constant.g_available
                   AND qr.id_response = r.id_response
                   AND r.flg_available = pk_lab_tests_constant.g_available
                   AND EXISTS (SELECT 1
                          FROM analysis_questionnaire aq
                         WHERE aq.id_analysis = i_analysis
                           AND aq.flg_time = i_flg_time
                           AND aq.id_sample_type = i_sample_type
                           AND aq.id_institution = i_prof.institution
                           AND aq.flg_available = pk_lab_tests_constant.g_available
                           AND aq.id_questionnaire = qr.id_questionnaire
                           AND aq.id_response = qr.id_response)
                   AND (((l_patient.gender IS NOT NULL AND
                       coalesce(r.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                       l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                       (nvl(l_patient.age, 0) BETWEEN nvl(r.age_min, 0) AND
                       nvl(r.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0))) qr
         ORDER BY qr.rank, qr.desc_response;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_response;

    FUNCTION get_lab_test_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN analysis_question_response.notes%TYPE
    ) RETURN analysis_question_response.notes%TYPE IS
    
        l_ret analysis_question_response.notes%TYPE;
    
    BEGIN
    
        -- Heuristic to minimize attempts to parse an invalid date
        IF dbms_lob.getlength(i_notes) = length('YYYYMMDDHHMMSS') -- This is the size of a stored serialized date, not a mask (HH vs HH24).
        THEN
            -- We try to parse the note as a serialized date 
            l_ret := pk_date_utils.dt_chr_str(i_lang     => i_lang,
                                              i_date     => i_notes,
                                              i_inst     => i_prof.institution,
                                              i_soft     => i_prof.software,
                                              i_timezone => NULL);
        ELSE
            l_ret := i_notes;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore parse errors and return original content
            RETURN i_notes;
    END get_lab_test_response;

    FUNCTION get_lab_test_episode_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_questionnaire IN analysis_question_response.id_questionnaire%TYPE
    ) RETURN VARCHAR2 IS
    
        l_response VARCHAR2(1000 CHAR);
    
    BEGIN
    
        SELECT substr(concatenate(t.id_response || '|'), 1, length(concatenate(t.id_response || '|')) - 1)
          INTO l_response
          FROM (SELECT aqr.id_response,
                       dense_rank() over(PARTITION BY aqr.id_questionnaire ORDER BY aqr.dt_last_update_tstz DESC) rn
                  FROM analysis_question_response aqr
                 WHERE aqr.id_episode = i_episode
                   AND aqr.id_questionnaire = i_questionnaire) t
         WHERE t.rn = 1;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_episode_response;

    FUNCTION get_harvest_instructions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_harvest_instructions analysis_instit_soft.harvest_instructions%TYPE;
    
    BEGIN
    
        g_error := 'GET HARVEST_INSTRUCTIONS';
        SELECT ais.harvest_instructions
          INTO l_harvest_instructions
          FROM analysis_instit_soft ais
         WHERE ais.id_analysis = i_analysis
           AND ais.id_sample_type = i_sample_type
           AND ais.flg_type = pk_lab_tests_constant.g_analysis_can_req
           AND ais.id_institution = i_prof.institution
           AND ais.id_software = i_prof.software
           AND ais.flg_available = pk_lab_tests_constant.g_available;
    
        RETURN l_harvest_instructions;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_harvest_instructions;

    FUNCTION get_harvest_professional
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE
    ) RETURN NUMBER IS
    
        l_prof_harvest harvest.id_prof_harvest%TYPE;
    
    BEGIN
    
        g_error := 'GET PROF_HARVEST';
        SELECT h.id_prof_harvest
          INTO l_prof_harvest
          FROM harvest h
         WHERE h.id_harvest = i_harvest;
    
        RETURN l_prof_harvest;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_harvest_professional;

    FUNCTION get_harvest_institution
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE
    ) RETURN NUMBER IS
    
        l_institution harvest.id_institution%TYPE;
    
    BEGIN
    
        g_error := 'GET ID_INSTITUTION';
        SELECT h.id_institution
          INTO l_institution
          FROM harvest h
         WHERE h.id_harvest = i_harvest;
    
        RETURN l_institution;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_harvest_institution;

    FUNCTION get_harvest_unit_measure
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_sample_recipient IN sample_recipient.id_sample_recipient%TYPE
    ) RETURN NUMBER IS
    
        l_unit_measure unit_measure.id_unit_measure%TYPE;
    
    BEGIN
    
        g_error := 'GET UNIT_MEASURE';
        SELECT sr.id_unit_measure
          INTO l_unit_measure
          FROM sample_recipient sr
         WHERE sr.id_sample_recipient = i_sample_recipient;
    
        RETURN l_unit_measure;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_harvest_unit_measure;

    FUNCTION get_harvest_alias_translation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc_mess pk_translation.t_desc_translation;
    
    BEGIN
    
        SELECT desc_analysis
          INTO l_desc_mess
          FROM (SELECT listagg(t.desc_analysis, '; ') within GROUP(ORDER BY t.dt_target, t.id_analysis_req_det) desc_analysis
                  FROM (SELECT h.id_harvest,
                               pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                        i_prof,
                                                                        pk_lab_tests_constant.g_analysis_alias,
                                                                        'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                        'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                        lte.id_sample_type,
                                                                        NULL) AS desc_analysis,
                               lte.dt_target,
                               lte.id_analysis_req_det
                          FROM harvest h
                          JOIN analysis_harvest ah
                            ON ah.id_harvest = h.id_harvest
                          JOIN lab_tests_ea lte
                            ON lte.id_analysis_req_det = ah.id_analysis_req_det
                         WHERE h.id_harvest = i_harvest
                           AND (lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e OR
                               (lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_b AND
                               pk_date_utils.trunc_insttimezone(i_prof, lte.dt_target, NULL) =
                               pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)) OR
                               (lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_n AND lte.id_episode IS NOT NULL))
                           AND (lte.flg_orig_analysis IS NULL OR lte.flg_orig_analysis NOT IN ('M', 'O', 'S'))
                           AND lte.flg_col_inst = pk_lab_tests_constant.g_yes
                           AND lte.flg_status_det NOT IN
                               (pk_lab_tests_constant.g_analysis_draft, pk_lab_tests_constant.g_analysis_wtg_tde)
                           AND (lte.flg_referral IS NULL OR lte.flg_referral = pk_lab_tests_constant.g_flg_referral_a OR
                               lte.flg_referral = pk_lab_tests_constant.g_flg_referral_r)
                           AND ((ah.flg_status = pk_lab_tests_constant.g_active) OR
                               (ah.flg_status = pk_lab_tests_constant.g_inactive AND
                               h.flg_status IN
                               (pk_lab_tests_constant.g_harvest_cancel, pk_lab_tests_constant.g_harvest_rejected)))
                           AND h.flg_status NOT IN
                               (pk_lab_tests_constant.g_harvest_suspended, pk_lab_tests_constant.g_harvest_inactive)
                           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                                  FROM dual) = pk_alert_constant.g_yes) t);
    
        RETURN l_desc_mess;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_harvest_alias_translation;

    FUNCTION get_lab_test_doc_external
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE
    ) RETURN NUMBER IS
    
        l_doc_external doc_external.id_doc_external%TYPE;
    
    BEGIN
    
        g_error := 'URL IN ANALYSIS_MEDIA_ARCHIVE';
        BEGIN
            SELECT ama.id_doc_external
              INTO l_doc_external
              FROM analysis_media_archive ama, doc_external de
             WHERE ama.id_analysis_result_par = i_analysis_result_par
               AND ama.flg_type = pk_lab_tests_constant.g_media_archive_analysis_res
               AND ama.flg_status = pk_lab_tests_constant.g_active
               AND ama.id_doc_external = de.id_doc_external
               AND de.flg_status = pk_alert_constant.g_active;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_doc_external := NULL;
        END;
    
        RETURN l_doc_external;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_doc_external;

    FUNCTION get_lab_test_result_url
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_url_type         IN VARCHAR2,
        o_url              OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_UTILS.GET_LAB_TEST_RESULT_URL';
        o_url   := pk_lab_tests_utils.get_lab_test_result_url(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_analysis_req_det => i_analysis_req_det,
                                                              i_url_type         => i_url_type);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_RESULT_URL',
                                              o_error);
            RETURN NULL;
    END get_lab_test_result_url;

    FUNCTION get_lab_test_result_url
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_url_type         IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_url     VARCHAR2(4000 CHAR);
        l_hashmap pk_ia_external_info.tt_table_varchar;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'CHECK RESULT';
        SELECT 1
          INTO l_url
          FROM lab_tests_ea lte
         WHERE lte.id_analysis_req_det = i_analysis_req_det
           AND lte.id_analysis_result IS NOT NULL;
    
        IF pk_sysconfig.get_config(i_code_cf => 'ANALYSIS_INTERFACE', i_prof => i_prof) = pk_lab_tests_constant.g_no
        THEN
            l_url := pk_lab_tests_constant.g_no;
        ELSE
            g_error := 'HASHMAP PARAMETERS';
            l_hashmap('id_analysis_req_det') := table_varchar(to_char(i_analysis_req_det));
        
            IF i_url_type = pk_lab_tests_constant.g_analysis_result_url
            THEN
                g_error := 'CALL TO PK_IA_EXTERNAL_INFO.GET_LAB_RESULT';
                IF NOT pk_ia_external_info.get_lab_result(i_prof    => i_prof,
                                                          i_hashmap => l_hashmap,
                                                          o_result  => l_url,
                                                          o_error   => l_error)
                THEN
                    l_url := pk_lab_tests_constant.g_no;
                END IF;
            ELSE
                g_error := 'CALL TO PK_IA_EXTERNAL_INFO.GET_LAB_REPORT';
                IF NOT pk_ia_external_info.get_lab_report(i_prof    => i_prof,
                                                          i_hashmap => l_hashmap,
                                                          o_report  => l_url,
                                                          o_error   => l_error)
                THEN
                    l_url := pk_lab_tests_constant.g_no;
                END IF;
            END IF;
        END IF;
    
        g_error := 'No URL';
        IF nvl(l_url, '#') = '#'
        THEN
            l_url := pk_lab_tests_constant.g_no;
        ELSE
            l_url := l_url;
        END IF;
    
        RETURN l_url;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_lab_tests_constant.g_no;
        WHEN OTHERS THEN
            RETURN l_url;
    END get_lab_test_result_url;

    FUNCTION get_lab_test_result_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
    
        l_result_status NUMBER;
    
    BEGIN
    
        g_error := 'SELECT RESULT_STATUS';
        SELECT rs.id_result_status
          INTO l_result_status
          FROM result_status rs
         WHERE rs.flg_default = pk_lab_tests_constant.g_yes
           AND rs.value = pk_lab_tests_constant.g_analysis_result
           AND rs.flg_multichoice = pk_lab_tests_constant.g_yes
           AND rownum = 1;
    
        RETURN l_result_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_result_status;

    FUNCTION get_lab_test_result_parameters
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_partial_result VARCHAR2(50 CHAR);
    
        l_show_result sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('LAB_TESTS_PARTIAL_RESULT_SHOW', i_prof);
    
    BEGIN
    
        SELECT CASE
                    WHEN b.count_result = a.count_req THEN
                     ''
                    ELSE
                     b.count_result || '/' || a.count_req
                END num_res
          INTO l_partial_result
          FROM (SELECT COUNT(*) count_req
                  FROM analysis_req_par arp
                 WHERE arp.id_analysis_req_det = i_analysis_req_det) a,
               (SELECT COUNT(*) count_result
                  FROM (SELECT aresp.*,
                               row_number() over(PARTITION BY aresp.id_analysis_req_par ORDER BY aresp.dt_analysis_result_par_tstz) rn
                          FROM analysis_result_par aresp, analysis_req_par arp
                         WHERE arp.id_analysis_req_det = i_analysis_req_det
                           AND aresp.id_analysis_req_par = arp.id_analysis_req_par)
                 WHERE rn = 1) b
         WHERE b.count_result > 0
           AND a.count_req > b.count_result
           AND l_show_result = pk_lab_tests_constant.g_yes;
    
        RETURN l_partial_result;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_lab_test_result_parameters;

    FUNCTION get_lab_test_calculated_result
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_analysis_calculator IN analysis_res_calculator.id_analysis_res_calc%TYPE,
        i_analysis_result_par IN table_number,
        i_result              IN table_number
    ) RETURN VARCHAR2 IS
    
        CURSOR c_pat IS
            SELECT p.gender,
                   months_between(SYSDATE, p.dt_birth) / 12 age,
                   p.flg_race,
                   vpea1.id_vital_sign weight,
                   vpea2.id_vital_sign height
              FROM patient p,
                   (SELECT vpea.id_vital_sign, vpea.id_patient
                      FROM vs_patient_ea vpea
                     WHERE vpea.id_patient = i_patient
                       AND vpea.id_vital_sign = 29) vpea1,
                   (SELECT vpea.id_vital_sign, vpea.id_patient
                      FROM vs_patient_ea vpea
                     WHERE vpea.id_patient = i_patient
                       AND vpea.id_vital_sign = 30) vpea2
             WHERE p.id_patient = i_patient
               AND p.id_patient = vpea1.id_patient(+)
               AND p.id_patient = vpea2.id_patient(+);
    
        CURSOR c_analysis_calculator IS
            SELECT arc.id_analysis_res_calc
              FROM analysis_res_calculator arc, analysis_res_par_calc arpc
             WHERE arc.id_analysis_res_calc = arpc.id_analysis_res_calc
               AND arpc.id_analysis_parameter =
                   (SELECT arp.id_analysis_parameter
                      FROM analysis_result_par arp
                     WHERE arp.id_analysis_result_par IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(i_analysis_result_par) t));
    
        l_pat c_pat%ROWTYPE;
    
        l_analysis_calculator analysis_res_calculator.id_analysis_res_calc%TYPE;
    
        l_result_value NUMBER;
    
        l_result VARCHAR2(1000 CHAR);
    
    BEGIN
    
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_pat;
        CLOSE c_pat;
    
        g_error := 'OPEN C_ANALYSIS_CALCULATOR';
        OPEN c_analysis_calculator;
        FETCH c_analysis_calculator
            INTO l_analysis_calculator;
        CLOSE c_analysis_calculator;
    
        g_error := 'ANALYSIS_CALCULATOR: ' || i_analysis_calculator;
        IF i_analysis_calculator = pk_lab_tests_constant.g_analysis_formula_gfr
        THEN
            l_result_value := 186.3 * power(i_result(1), -1.154) * power(l_pat.age, -0.203);
        
            IF l_pat.gender = 'F'
            THEN
                l_result_value := l_result_value * 0.762;
            END IF;
        
            IF l_pat.flg_race = 'B'
            THEN
                l_result_value := l_result_value * 1.210;
            END IF;
        
        ELSIF i_analysis_calculator = pk_lab_tests_constant.g_analysis_formula_ccc
        THEN
            l_result_value := (((i_result(1) / i_result(2)) * (i_result(3) / 1440)) * 1.73) /
                              (power(l_pat.weight, 0.425) * power(l_pat.height, 0.725) * 0.007184);
        
        ELSIF i_analysis_calculator = pk_lab_tests_constant.g_analysis_formula_osm
        THEN
            l_result_value := 2 * (i_result(1) + i_result(2)) + (i_result(3) / 18) * (i_result(4) / 3.2);
        
        ELSIF i_analysis_calculator = pk_lab_tests_constant.g_analysis_formula_ccr
        THEN
            l_result_value := (140 - l_pat.age) * l_pat.weight / 72 * i_result(1);
        
            IF l_pat.gender = 'F'
            THEN
                l_result_value := l_result_value * 0.85;
            END IF;
        END IF;
    
        g_error := 'L_RESULT_VALUE';
        IF l_result_value IS NOT NULL
        THEN
            SELECT arc.id_analysis_parameter || '|' || round(l_result_value)
              INTO l_result
              FROM analysis_res_calculator arc
             WHERE arc.id_analysis_res_calc = i_analysis_calculator;
        
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_calculated_result;

    FUNCTION get_lab_test_initial_convert
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        o_last_unit_mea      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        -- Gets unit measure and last date corresponding with the lab tests and with the parameter
        OPEN o_last_unit_mea FOR
            SELECT id_unit_measure
              FROM (SELECT ar.id_analysis,
                           ar.id_sample_type,
                           ltpu.id_analysis_parameter,
                           arp.id_unit_measure,
                           MAX(ar.dt_analysis_result_tstz) last_date
                      FROM lab_tests_par_uni_mea ltpu
                     INNER JOIN analysis_result_par arp
                        ON ltpu.id_analysis_parameter = arp.id_analysis_parameter
                     INNER JOIN analysis_result ar
                        ON arp.id_analysis_result = ar.id_analysis_result
                     INNER JOIN analysis_param ap
                        ON ar.id_analysis = ap.id_analysis
                       AND ar.id_sample_type = ap.id_sample_type
                     WHERE ar.id_patient = i_patient
                       AND ar.id_institution = i_prof.institution
                       AND ap.id_analysis_parameter = i_analysis_parameter
                       AND ap.id_analysis = i_analysis
                       AND ap.id_sample_type = i_sample_type
                       AND ap.id_software = i_prof.software
                       AND arp.id_unit_measure IS NOT NULL
                     GROUP BY ar.id_analysis, ar.id_sample_type, ltpu.id_analysis_parameter, arp.id_unit_measure) mu
             WHERE mu.last_date IN (SELECT MAX(ar.dt_analysis_result_tstz) last_date
                                      FROM lab_tests_par_uni_mea ltpu
                                     INNER JOIN analysis_result_par arp
                                        ON ltpu.id_analysis_parameter = arp.id_analysis_parameter
                                     INNER JOIN analysis_result ar
                                        ON arp.id_analysis_result = ar.id_analysis_result
                                     INNER JOIN analysis_param ap
                                        ON ar.id_analysis = ap.id_analysis
                                       AND ar.id_sample_type = ap.id_sample_type
                                     WHERE ar.id_patient = i_patient
                                       AND ar.id_institution = i_prof.institution
                                       AND ap.id_analysis_parameter = i_analysis_parameter
                                       AND ap.id_analysis = i_analysis
                                       AND ap.id_sample_type = i_sample_type
                                       AND ap.id_software = i_prof.software
                                       AND arp.id_unit_measure IS NOT NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_INITIAL_CONVERT',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_initial_convert;

    FUNCTION get_lab_test_concat_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN VARCHAR2,
        i_delim            IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_tbl_analysis_req_det table_number;
    
        l_ret VARCHAR2(4000 CHAR);
    
    BEGIN
        l_tbl_analysis_req_det := pk_utils.str_split_n(i_list => i_analysis_req_det, i_delim => i_delim);
    
        FOR i IN l_tbl_analysis_req_det.first .. l_tbl_analysis_req_det.last
        LOOP
            l_ret := l_ret || pk_lab_tests_external.get_lab_test_description(i_lang             => i_lang,
                                                                             i_prof             => i_prof,
                                                                             i_analysis_req_det => l_tbl_analysis_req_det(i),
                                                                             i_co_sign_hist     => NULL) || CASE
                         WHEN i = l_tbl_analysis_req_det.last THEN
                          NULL
                         ELSE
                          ' / '
                     END;
        END LOOP;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_concat_desc;

    FUNCTION get_result_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_RESULT_FORM_VALUES';
    
        --Return variable
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        l_id_harvest         harvest.id_harvest%TYPE;
        l_id_analysis_result analysis_result.id_analysis_result%TYPE;
    
        l_dt_harvest              VARCHAR2(200 CHAR) := NULL;
        l_dt_analysis_result      VARCHAR2(200 CHAR) := NULL;
        l_dt_analysis_result_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_result_origin_val      VARCHAR2(30);
        l_result_origin_desc_val VARCHAR2(200);
    
        l_flg_result_origin analysis_result.flg_result_origin%TYPE;
    
        l_result_origin_notes analysis_result.result_origin_notes%TYPE;
    
        l_result_notes analysis_result.notes%TYPE;
    
        l_id_prof_request   professional.id_professional%TYPE;
        l_desc_prof_request VARCHAR2(300 CHAR);
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
    
        --Array i_tbl_id_pk possible values:
        --i_tbl_id_pk(1) => id_harvest
        --i_tbl_id_pk(2) => id_analysis_result
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF (i_action IS NULL OR i_action <> pk_dyn_form_constant.get_submit_action)
        THEN
            l_id_harvest := CASE i_tbl_id_pk(1)
                                WHEN -1 THEN
                                 NULL
                                ELSE
                                 i_tbl_id_pk(1)
                            END;
        
            l_id_analysis_result := CASE i_tbl_id_pk(2)
                                        WHEN -1 THEN
                                         NULL
                                        ELSE
                                         i_tbl_id_pk(2)
                                    END;
        
            IF l_id_harvest IS NOT NULL
            THEN
                SELECT pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => h.dt_harvest_tstz, i_prof => i_prof)
                  INTO l_dt_harvest
                  FROM harvest h
                 WHERE h.id_harvest = l_id_harvest;
            ELSIF l_id_analysis_result IS NOT NULL
            THEN
                SELECT pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => ar.dt_sample, i_prof => i_prof)
                  INTO l_dt_harvest
                  FROM analysis_result ar
                 WHERE ar.id_analysis_result = l_id_analysis_result;
            ELSE
                l_dt_harvest := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                            i_date => current_timestamp,
                                                            i_prof => i_prof);
            END IF;
        
            IF l_id_analysis_result IS NOT NULL
            THEN
                SELECT pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                   i_date => coalesce(ar.dt_analysis_result_tstz, g_sysdate_tstz),
                                                   i_prof => i_prof),
                       ar.notes,
                       ar.flg_result_origin,
                       ar.result_origin_notes,
                       ar.id_prof_req
                  INTO l_dt_analysis_result,
                       l_result_notes,
                       l_flg_result_origin,
                       l_result_origin_notes,
                       l_id_prof_request
                  FROM analysis_result ar
                 WHERE ar.id_analysis_result = l_id_analysis_result;
            ELSE
                l_dt_analysis_result := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                    i_date => current_timestamp,
                                                                    i_prof => i_prof);
            END IF;
        
            g_error := 'GET ANALYSIS_RESULT.FLG_RESULT_ORIGIN SYS_DOMAIN';
            SELECT val, label
              INTO l_result_origin_val, l_result_origin_desc_val
              FROM (SELECT s.val, s.desc_val label
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                          i_prof,
                                                                          'ANALYSIS_RESULT.FLG_RESULT_ORIGIN',
                                                                          NULL)) s
                     ORDER BY rank)
             WHERE (val = l_flg_result_origin)
                OR l_flg_result_origin IS NULL
               AND rownum = 1;
        
            IF i_root_name = pk_orders_constant.g_ds_lab_results_with_prof_list
            THEN
                BEGIN
                    SELECT to_number(t.domain_value), t.desc_domain
                      INTO l_id_prof_request, l_desc_prof_request
                      FROM TABLE(pk_lab_tests_core.get_lab_test_result_prof_list(i_lang => i_lang, i_prof => i_prof)) t
                     WHERE t.domain_value = coalesce(l_id_prof_request, i_prof.id);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_prof_request   := NULL;
                        l_desc_prof_request := NULL;
                END;
            END IF;
        
            --Insert the default values in the return variable (tbl_result)
            g_error := 'SELECT INTO TBL_RESULT';
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_date_service THEN
                                                                  l_dt_harvest
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_date_result THEN
                                                                  l_dt_analysis_result
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_result_origin THEN
                                                                  l_result_origin_val
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_ordered_by THEN
                                                                  to_char(l_id_prof_request)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_place_service_ft THEN
                                                                  l_result_origin_notes
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_result_notes THEN
                                                                  to_char(l_result_notes)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_result_origin THEN
                                                                  l_result_origin_desc_val
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_ordered_by THEN
                                                                  l_desc_prof_request
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_result_notes THEN
                                                                  to_char(l_result_notes)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_place_service_ft THEN
                                                                  l_result_origin_notes
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => CASE
                                                                 WHEN t.id_unit_measure IS NOT NULL THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => t.id_unit_measure)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => coalesce(def.flg_event_type,
                                                                      pk_orders_constant.g_component_active),
                                       flg_multi_status   => pk_alert_constant.g_no,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.internal_name_parent,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
              LEFT JOIN ds_def_event def
                ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
             WHERE d.internal_name IN (pk_orders_constant.g_ds_date_service,
                                       pk_orders_constant.g_ds_date_result,
                                       pk_orders_constant.g_ds_result_origin,
                                       pk_orders_constant.g_ds_ordered_by,
                                       pk_orders_constant.g_ds_place_service_ft,
                                       pk_orders_constant.g_ds_result_notes)
             ORDER BY t.rn;
        ELSE
            --SUBMIT ACTION      
            IF i_curr_component IS NOT NULL
            THEN
                --Check which element has been changed
                SELECT d.internal_name_child
                  INTO l_curr_comp_int_name
                  FROM ds_cmpt_mkt_rel d
                 WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
            
                IF l_curr_comp_int_name = pk_orders_constant.g_ds_date_result
                THEN
                    FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                    LOOP
                        IF i_tbl_int_name(i) = l_curr_comp_int_name
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            l_dt_analysis_result_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                       i_prof      => i_prof,
                                                                                       i_timestamp => i_value(i) (1),
                                                                                       i_timezone  => NULL);
                        
                            IF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                               i_date1 => l_dt_analysis_result_tstz,
                                                               i_date2 => g_sysdate_tstz) = 'G'
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_curr_comp_int_name,
                                                                                   VALUE              => i_value(i) (1),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_error,
                                                                                   err_msg            => pk_message.get_message(i_lang,
                                                                                                                                'COMMON_M163'),
                                                                                   flg_event_type     => pk_orders_constant.g_component_active,
                                                                                   flg_multi_status   => pk_alert_constant.g_no,
                                                                                   idx                => i_idx);
                            END IF;
                        
                            EXIT;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_result_form_values;

    PROCEDURE set_lab_test_migration IS
    
        l_sql VARCHAR2(4000);
    
        l_tab_translation t_tab_translation;
    
        l_code_translation table_varchar;
    
    BEGIN
    
        l_sql := 'alter table ' || g_package_owner || '.analysis_dep_clin_serv drop constraint acst_uk DROP INDEX';
        EXECUTE IMMEDIATE l_sql;
        l_sql := 'alter table ' || g_package_owner || '.bo_analysis_param drop CONSTRAINT bap_uk DROP INDEX';
        EXECUTE IMMEDIATE l_sql;
        l_sql := 'alter table ' || g_package_owner || '.analysis_room drop CONSTRAINT arm_uk DROP INDEX';
        EXECUTE IMMEDIATE l_sql;
        l_sql := 'alter table ' || g_package_owner || '.analysis_instit_soft drop CONSTRAINT ais_uk DROP INDEX';
        EXECUTE IMMEDIATE l_sql;
        l_sql := 'alter table ' || g_package_owner || '.analysis_param drop CONSTRAINT apm_uk DROP INDEX';
        EXECUTE IMMEDIATE l_sql;
        l_sql := 'alter table ' || g_package_owner || '.lab_tests_complaint drop CONSTRAINT lttc_pk DROP INDEX';
        EXECUTE IMMEDIATE l_sql;
    
        dbms_output.put_line('Constraints dropped.');
    
        -- Content / Config
        INSERT INTO analysis_sample_type_alias
            (id_analysis_sample_type_alias,
             id_analysis,
             id_sample_type,
             code_ast_alias,
             id_institution,
             id_software,
             id_dep_clin_serv,
             id_professional)
            (SELECT seq_analysis_sample_type_alias.nextval,
                    astm.id_analysis,
                    astm.id_sample_type,
                    'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' || seq_analysis_sample_type_alias.currval,
                    id_institution,
                    id_software,
                    id_dep_clin_serv,
                    id_professional
               FROM analysis_alias t, analysis_sample_type_mig astm
              WHERE astm.id_analysis_legacy = t.id_analysis
                AND EXISTS (SELECT 1
                       FROM analysis_sample_type_mig astm
                      WHERE astm.id_analysis_legacy = t.id_analysis));
    
        dbms_output.put_line('INSERT analysis_sample_type_alias concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        SELECT t_rec_translation(t.code_translation,
                                 t.table_owner,
                                 NULL,
                                 NULL,
                                 t.module,
                                 t.desc_lang_1,
                                 t.desc_lang_2,
                                 t.desc_lang_3,
                                 t.desc_lang_4,
                                 t.desc_lang_5,
                                 t.desc_lang_6,
                                 t.desc_lang_7,
                                 t.desc_lang_8,
                                 t.desc_lang_9,
                                 t.desc_lang_10,
                                 t.desc_lang_11,
                                 t.desc_lang_12,
                                 t.desc_lang_13,
                                 t.desc_lang_14,
                                 t.desc_lang_15,
                                 t.desc_lang_16,
                                 t.desc_lang_17,
                                 t.desc_lang_18,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL)
          BULK COLLECT
          INTO l_tab_translation
          FROM (SELECT asta.code_ast_alias code_translation,
                       'ALERT' table_owner,
                       'ALERT' schema_name,
                       'PFH' module,
                       (SELECT desc_lang_1
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_1,
                       (SELECT desc_lang_2
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_2,
                       (SELECT desc_lang_3
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_3,
                       (SELECT desc_lang_4
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_4,
                       (SELECT desc_lang_5
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_5,
                       (SELECT desc_lang_6
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_6,
                       (SELECT desc_lang_7
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_7,
                       (SELECT desc_lang_8
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_8,
                       (SELECT desc_lang_9
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_9,
                       (SELECT desc_lang_10
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_10,
                       (SELECT desc_lang_11
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_11,
                       (SELECT desc_lang_12
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_12,
                       (SELECT desc_lang_13
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_13,
                       (SELECT desc_lang_14
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_14,
                       (SELECT desc_lang_15
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_15,
                       (SELECT desc_lang_16
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_16,
                       (SELECT desc_lang_17
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_17,
                       (SELECT desc_lang_18
                          FROM translation
                         WHERE code_translation = 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || aa.id_analysis_alias) desc_lang_18
                  FROM analysis_alias aa, analysis_sample_type_mig astm, analysis_sample_type_alias asta
                 WHERE aa.id_analysis = astm.id_analysis_legacy
                   AND astm.id_analysis = asta.id_analysis
                   AND astm.id_sample_type = asta.id_sample_type
                   AND aa.id_institution = asta.id_institution
                   AND aa.id_software = asta.id_software) t;
    
        pk_translation.ins_bulk_translation(i_tab => l_tab_translation);
    
        dbms_output.put_line('UPDATE translation concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE analysis_alias t
           SET (id_analysis) =
               (SELECT astm.id_analysis
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_alias concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        l_code_translation := table_varchar();
    
        SELECT t.code_translation
          BULK COLLECT
          INTO l_code_translation
          FROM translation t
         WHERE EXISTS (SELECT 1
                  FROM analysis_alias aa
                 WHERE ROWID IN (SELECT ROWID
                                   FROM (SELECT id_analysis,
                                                id_institution,
                                                id_software,
                                                id_professional,
                                                id_dep_clin_serv,
                                                row_number() over(PARTITION BY id_analysis, id_institution, id_software, id_professional, id_dep_clin_serv ORDER BY id_analysis_alias DESC) rn
                                           FROM analysis_alias) t
                                  WHERE rn > 1)
                   AND aa.code_analysis_alias = t.code_translation);
    
        pk_translation.delete_code_translation(l_code_translation);
    
        dbms_output.put_line('DELETE code_analysis_alias from translation concluded. ' || SQL%ROWCOUNT ||
                             ' rows deleted.');
    
        DELETE analysis_alias
         WHERE ROWID IN (SELECT ROWID
                           FROM (SELECT id_analysis,
                                        id_institution,
                                        id_software,
                                        id_professional,
                                        id_dep_clin_serv,
                                        row_number() over(PARTITION BY id_analysis, id_institution, id_software, id_professional, id_dep_clin_serv ORDER BY id_analysis_alias DESC) rn
                                   FROM analysis_alias) t
                          WHERE rn > 1);
    
        dbms_output.put_line('DELETE analysis_alias concluded. ' || SQL%ROWCOUNT || ' rows deleted.');
    
        UPDATE analysis_agp t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_agp concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE analysis_param t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_param concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        DELETE analysis_param_funcionality
         WHERE id_analysis_param IN (SELECT id_analysis_param
                                       FROM analysis_param
                                      WHERE ROWID IN (SELECT ROWID
                                                        FROM (SELECT id_analysis,
                                                                     id_sample_type,
                                                                     id_analysis_parameter,
                                                                     id_institution,
                                                                     id_software,
                                                                     row_number() over(PARTITION BY id_analysis, id_sample_type, id_analysis_parameter, id_institution, id_software ORDER BY id_analysis_param DESC) rn
                                                                FROM analysis_param) t
                                                       WHERE rn > 1));
    
        dbms_output.put_line('DELETE analysis_param_funcionality concluded. ' || SQL%ROWCOUNT || ' rows deleted.');
    
        DELETE analysis_param
         WHERE ROWID IN (SELECT ROWID
                           FROM (SELECT id_analysis,
                                        id_sample_type,
                                        id_analysis_parameter,
                                        id_institution,
                                        id_software,
                                        row_number() over(PARTITION BY id_analysis, id_sample_type, id_analysis_parameter, id_institution, id_software ORDER BY id_analysis_param DESC) rn
                                   FROM analysis_param) t
                          WHERE rn > 1);
    
        dbms_output.put_line('DELETE analysis_param concluded. ' || SQL%ROWCOUNT || ' rows deleted.');
    
        UPDATE lab_tests_complaint t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE lab_tests_complaint concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        DELETE lab_tests_complaint
         WHERE ROWID IN (SELECT ROWID
                           FROM (SELECT id_complaint,
                                        id_analysis,
                                        id_sample_type,
                                        row_number() over(PARTITION BY id_complaint, id_analysis, id_sample_type ORDER BY id_complaint DESC) rn
                                   FROM lab_tests_complaint) t
                          WHERE rn > 1);
    
        dbms_output.put_line('DELETE lab_tests_complaint concluded. ' || SQL%ROWCOUNT || ' rows deleted.');
    
        UPDATE analysis_instit_soft t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_instit_soft concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        DELETE analysis_instit_recipient
         WHERE id_analysis_instit_soft IN (SELECT id_analysis_instit_soft
                                             FROM analysis_instit_soft
                                            WHERE ROWID IN (SELECT ROWID
                                                              FROM (SELECT id_analysis,
                                                                           id_institution,
                                                                           id_software,
                                                                           id_analysis_group,
                                                                           id_sample_type,
                                                                           row_number() over(PARTITION BY id_analysis, id_institution, id_software, id_analysis_group, id_sample_type ORDER BY id_analysis_instit_soft DESC) rn
                                                                      FROM analysis_instit_soft) t
                                                             WHERE rn > 1));
    
        dbms_output.put_line('DELETE analysis_instit_recipient concluded. ' || SQL%ROWCOUNT || ' rows deleted.');
    
        DELETE analysis_instit_soft
         WHERE ROWID IN (SELECT ROWID
                           FROM (SELECT id_analysis,
                                        id_institution,
                                        id_software,
                                        id_analysis_group,
                                        id_sample_type,
                                        row_number() over(PARTITION BY id_analysis, id_institution, id_software, id_analysis_group, id_sample_type ORDER BY id_analysis_instit_soft DESC) rn
                                   FROM analysis_instit_soft) t
                          WHERE rn > 1);
    
        dbms_output.put_line('DELETE analysis_instit_soft concluded. ' || SQL%ROWCOUNT || ' rows deleted.');
    
        UPDATE analysis_dep_clin_serv t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_dep_clin_serv concluded. ' || SQL%ROWCOUNT || ' rows updated.');
        DELETE analysis_dep_clin_serv
         WHERE ROWID IN (SELECT ROWID
                           FROM (SELECT id_analysis,
                                        id_dep_clin_serv,
                                        id_software,
                                        id_professional,
                                        id_analysis_group,
                                        row_number() over(PARTITION BY id_analysis, id_dep_clin_serv, id_software, id_professional, id_analysis_group ORDER BY id_analysis_dep_clin_serv DESC) rn
                                   FROM analysis_dep_clin_serv) t
                          WHERE rn > 1);
    
        dbms_output.put_line('DELETE analysis_dep_clin_serv concluded. ' || SQL%ROWCOUNT || ' rows deleted.');
    
        UPDATE analysis_room t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_room concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        DELETE analysis_room
         WHERE ROWID IN (SELECT ROWID
                           FROM (SELECT id_analysis,
                                        id_sample_type,
                                        id_room,
                                        flg_type,
                                        id_institution,
                                        flg_default,
                                        row_number() over(PARTITION BY id_analysis, id_sample_type, id_room, flg_type, id_institution, flg_default ORDER BY id_analysis_room DESC) rn
                                   FROM analysis_room) t
                          WHERE rn > 1);
    
        dbms_output.put_line('DELETE analysis_room concluded. ' || SQL%ROWCOUNT || ' rows deleted.');
    
        UPDATE analysis_unit_measure t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_unit_measure concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE analysis_questionnaire t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_questionnaire concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE bo_analysis_param t
           SET (id_analysis) =
               (SELECT astm.id_analysis
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE bo_analysis_param concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE p1_analysis_default_dest t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE p1_analysis_default_dest concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE p1_exr_analysis t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE p1_exr_analysis concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE p1_exr_temp t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE p1_exr_temp concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE p1_origin_approval_config t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE p1_origin_approval_config concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE event t
           SET (id_group, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_group)
         WHERE t.flg_group = 'A'
           AND EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_group);
    
        dbms_output.put_line('UPDATE event concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        -- Transactional
        UPDATE analysis_req_det t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_req_det concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE analysis_req_det_hist t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_req_det_hist concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE analysis_result t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_result concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE analysis_result_hist t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE analysis_result_hist concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE lab_tests_ea t
           SET (id_analysis, id_sample_type) =
               (SELECT astm.id_analysis, astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis)
         WHERE EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_analysis);
    
        dbms_output.put_line('UPDATE lab_tests_ea concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        UPDATE task_timeline_ea t
           SET (id_sub_group_import, code_desc_sub_group, id_sample_type, code_desc_sample_type) =
               (SELECT astm.id_analysis,
                       'ANALYSIS.CODE_ANALYSIS.' || astm.id_analysis,
                       astm.id_sample_type,
                       'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || astm.id_sample_type
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_sub_group_import)
         WHERE t.id_tl_task IN (5, 17)
           AND EXISTS (SELECT 1
                  FROM analysis_sample_type_mig astm
                 WHERE astm.id_analysis_legacy = t.id_sub_group_import);
    
        dbms_output.put_line('UPDATE task_timeline_ea concluded. ' || SQL%ROWCOUNT || ' rows updated.');
    
        l_sql := 'alter table ' || g_package_owner ||
                 '.analysis_dep_clin_serv add (constraint acst_uk unique (id_analysis, id_sample_type, id_analysis_group, id_dep_clin_serv, id_software, id_professional))';
        EXECUTE IMMEDIATE l_sql;
        l_sql := 'alter table ' || g_package_owner ||
                 '.bo_analysis_param add (constraint bap_uk unique (id_analysis, id_analysis_parameter))';
        EXECUTE IMMEDIATE l_sql;
        l_sql := 'alter table ' || g_package_owner ||
                 '.analysis_room add (constraint arm_uk unique (id_analysis, id_sample_type, id_room, flg_type, id_institution, flg_default))';
        EXECUTE IMMEDIATE l_sql;
        l_sql := 'alter table ' || g_package_owner ||
                 '.analysis_instit_soft add (constraint ais_uk unique (id_analysis, id_sample_type, id_analysis_group, id_institution, id_software))';
        EXECUTE IMMEDIATE l_sql;
        l_sql := 'alter table ' || g_package_owner ||
                 '.analysis_param add (constraint apm_uk unique (id_analysis, id_sample_type, id_analysis_parameter, id_institution, id_software))';
        EXECUTE IMMEDIATE l_sql;
        l_sql := 'alter table ' || g_package_owner ||
                 '.lab_tests_complaint add (constraint lttc_pk primary key (id_complaint, id_analysis, id_sample_type))';
        EXECUTE IMMEDIATE l_sql;
    
        dbms_output.put_line('Constraints added.');
    
    END set_lab_test_migration;

    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT t_clin_quest_table,
        o_ds_target   OUT t_clin_quest_target_table,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN;
    
        l_tbl_analysis          table_varchar;
        l_tbl_aux               table_number;
        l_tbl_id_analysis       table_number := table_number();
        l_tbl_id_sample         table_number := table_number();
        l_tbl_id_analysis_final table_number;
        l_tbl_id_sample_final   table_number;
        l_patient               patient%ROWTYPE;
        l_count                 NUMBER;
    BEGIN
    
        l_tbl_analysis := pk_string_utils.str_split(i_list => i_screen_name, i_delim => '|');
        --l_tbl_id_analysis := pk_utils.str_split_n(i_list => i_screen_name, i_delim => '|');
        l_tbl_id_analysis := table_number();
    
        FOR i IN 1 .. l_tbl_analysis.count
        LOOP
            l_tbl_aux := table_number();
            l_tbl_aux := pk_utils.str_split_n(i_list => l_tbl_analysis(i), i_delim => '_');
        
            l_tbl_id_analysis.extend;
            l_tbl_id_analysis(l_tbl_id_analysis.count) := l_tbl_aux(1);
            l_tbl_id_sample.extend;
            l_tbl_id_sample(l_tbl_id_sample.count) := l_tbl_aux(2);
        END LOOP;
    
        IF i_action = 70
        THEN
            FOR i IN l_tbl_id_analysis.first .. l_tbl_id_analysis.last
            LOOP
                SELECT ipd.id_analysis, ipd.id_sample_type
                  INTO l_tbl_id_analysis(i), l_tbl_id_sample(i)
                  FROM analysis_req_det ipd
                 WHERE ipd.id_analysis_req_det = l_tbl_id_analysis(i);
            END LOOP;
        ELSE
            SELECT DISTINCT eq.id_analysis, eq.id_sample_type
              BULK COLLECT
              INTO l_tbl_id_analysis_final, l_tbl_id_sample_final
              FROM analysis_questionnaire eq
             WHERE eq.id_analysis IN (SELECT column_value
                                        FROM TABLE(l_tbl_id_analysis))
               AND eq.flg_time = pk_exam_constant.g_exam_cq_on_order
               AND eq.id_institution = i_prof.institution
               AND eq.flg_available = pk_exam_constant.g_available;
            IF l_tbl_id_analysis_final.count = 0
            THEN
                o_components := t_clin_quest_table();
                o_ds_target  := t_clin_quest_target_table();
                RETURN TRUE;
            END IF;
        END IF;
    
        SELECT t_clin_quest_row(id_ds_cmpt_mkt_rel        => z.id_ds_cmpt_mkt_rel,
                                id_ds_component_parent    => z.id_ds_component_parent,
                                code_alt_desc             => z.code_alt_desc,
                                desc_component            => z.desc_component,
                                internal_name             => z.internal_name,
                                flg_data_type             => z.flg_data_type,
                                internal_sample_text_type => z.internal_sample_text_type,
                                id_ds_component_child     => z.id_ds_component_child,
                                rank                      => z.rank,
                                max_len                   => z.max_len,
                                min_len                   => z.min_len,
                                min_value                 => z.min_value,
                                max_value                 => z.max_value,
                                position                  => z.position,
                                flg_multichoice           => z.flg_multichoice,
                                comp_size                 => z.comp_size,
                                flg_wrap_text             => z.flg_wrap_text,
                                multichoice_code          => z.multichoice_code,
                                service_params            => z.service_params,
                                flg_event_type            => z.flg_event_type,
                                flg_exp_type              => z.flg_exp_type,
                                input_expression          => z.input_expression,
                                input_mask                => z.input_mask,
                                comp_offset               => z.comp_offset,
                                flg_hidden                => z.flg_hidden,
                                placeholder               => z.placeholder,
                                validation_message        => z.validation_message,
                                flg_clearable             => z.flg_clearable,
                                crate_identifier          => z.crate_identifier,
                                rn                        => z.rn,
                                flg_repeatable            => z.flg_repeatable,
                                flg_data_type2            => z.flg_data_type2,
                                text_line_nr              => NULL)
          BULK COLLECT
          INTO o_components
          FROM (SELECT 0 id_ds_cmpt_mkt_rel,
                       NULL id_ds_component_parent,
                       NULL code_alt_desc,
                       pk_message.get_message(i_lang, 'PROCEDURES_T163') desc_component,
                       i_screen_name internal_name,
                       NULL flg_data_type,
                       NULL internal_sample_text_type,
                       --to_number(i_screen_name) id_ds_component_child,
                       0    id_ds_component_child,
                       1    rank,
                       NULL max_len,
                       NULL min_len,
                       NULL min_value,
                       NULL max_value,
                       1    position,
                       NULL flg_multichoice,
                       NULL comp_size,
                       NULL flg_wrap_text,
                       NULL multichoice_code,
                       NULL service_params,
                       NULL flg_event_type,
                       NULL flg_exp_type,
                       NULL input_expression,
                       NULL input_mask,
                       NULL comp_offset,
                       NULL flg_hidden,
                       NULL placeholder,
                       NULL validation_message,
                       NULL flg_clearable,
                       NULL crate_identifier,
                       1    rn,
                       NULL flg_repeatable,
                       NULL flg_data_type2
                  FROM dual
                UNION ALL
                SELECT to_number(t.column_value) id_ds_cmpt_mkt_rel,
                       0 id_ds_component_parent,
                       NULL code_alt_desc,
                       pk_translation.get_translation(i_lang, 'ANALYSIS.CODE_ANALYSIS.' || to_number(t.column_value)) desc_component,
                       pk_translation.get_translation(i_lang, 'ANALYSIS.CODE_ANALYSIS.' || to_number(t.column_value)) internal_name,
                       NULL flg_data_type,
                       NULL internal_sample_text_type,
                       to_number(t.column_value) id_ds_component_child,
                       rownum rank,
                       NULL max_len,
                       NULL min_len,
                       NULL min_value,
                       NULL max_value,
                       rownum position,
                       NULL flg_multichoice,
                       NULL comp_size,
                       NULL flg_wrap_text,
                       NULL multichoice_code,
                       NULL service_params,
                       NULL flg_event_type,
                       NULL flg_exp_type,
                       NULL input_expression,
                       NULL input_mask,
                       NULL comp_offset,
                       NULL flg_hidden,
                       NULL placeholder,
                       NULL validation_message,
                       NULL flg_clearable,
                       NULL crate_identifier,
                       rownum rn,
                       NULL flg_repeatable,
                       NULL flg_data_type2
                  FROM TABLE(l_tbl_id_analysis_final) t
                UNION ALL
                SELECT (q.id_questionnaire * 10 + q.id_analysis) id_ds_cmpt_mkt_rel,
                       q.id_analysis id_ds_component_parent,
                       NULL code_alt_desc,
                       pk_mcdt.get_questionnaire_alias(i_lang,
                                                       i_prof,
                                                       'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || q.id_questionnaire) desc_component,
                       to_char('A' || '|' || q.id_analysis || '_' || q.id_questionnaire || '_' || q.id_sample_type) internal_name,
                       decode(q.flg_type, 'D', 'DT', 'ME', 'MS', 'MI', 'MM', 'N', 'K', NULL) flg_data_type,
                       NULL internal_sample_text_type,
                       q.id_questionnaire id_ds_component_child,
                       q.id_questionnaire rank,
                       NULL max_len,
                       NULL min_len,
                       NULL min_value,
                       NULL max_value,
                       rownum + 1000 position,
                       decode(q.flg_type, 'ME', 'SRV', 'MI', 'SRV', NULL) flg_multichoice,
                       NULL comp_size,
                       NULL flg_wrap_text,
                       decode(q.flg_type, 'ME', 'GET_MULTICHOICE_CQ', 'MI', 'GET_MULTICHOICE_CQ', NULL) multichoice_code,
                       (q.id_questionnaire * 10 + q.id_analysis) service_params,
                       decode(q.id_questionnaire_parent, NULL, decode(q.flg_mandatory, 'Y', 'M', NULL), 'I') flg_event_type,
                       NULL flg_exp_type,
                       NULL input_expression,
                       NULL input_mask,
                       NULL comp_offset,
                       pk_alert_constant.g_no flg_hidden,
                       NULL placeholder,
                       NULL validation_message,
                       pk_alert_constant.g_yes flg_clearable,
                       NULL crate_identifier,
                       rownum + 100 rn,
                       NULL flg_repeatable,
                       NULL flg_data_type2
                  FROM (SELECT DISTINCT iq.id_analysis,
                                        iq.id_sample_type,
                                        iq.id_questionnaire,
                                        qr.id_questionnaire_parent,
                                        qr.id_response_parent,
                                        iq.flg_type,
                                        iq.flg_mandatory,
                                        iq.flg_copy,
                                        iq.flg_validation,
                                        iq.id_unit_measure
                          FROM analysis_questionnaire iq,
                               questionnaire_response qr,
                               (SELECT column_value AS id_analysis
                                  FROM TABLE(l_tbl_id_analysis_final)) p,
                               (SELECT column_value AS id_sample_type
                                  FROM TABLE(l_tbl_id_sample_final)) s
                         WHERE iq.id_analysis = p.id_analysis
                           AND iq.id_sample_type = s.id_sample_type
                           AND iq.flg_time = 'O'
                           AND iq.id_institution = i_prof.institution
                           AND iq.flg_available = pk_procedures_constant.g_available
                           AND iq.id_questionnaire = qr.id_questionnaire
                           AND iq.id_response = qr.id_response
                           AND qr.flg_available = pk_procedures_constant.g_available
                           AND EXISTS
                         (SELECT 1
                                  FROM questionnaire q
                                 WHERE q.id_questionnaire = iq.id_questionnaire
                                   AND q.flg_available = pk_procedures_constant.g_available
                                   AND (((l_patient.gender IS NOT NULL AND
                                       coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                       ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                       l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                       (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                       nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q
                 ORDER BY rank) z;
    
        SELECT t_clin_quest_target_row(id_cmpt_mkt_origin    => z.id_cmpt_mkt_origin,
                                       id_cmpt_origin        => z.id_cmpt_origin,
                                       id_ds_event           => z.id_ds_event,
                                       flg_type              => z.flg_type,
                                       VALUE                 => z.value,
                                       id_cmpt_mkt_dest      => z.id_cmpt_mkt_dest,
                                       id_cmpt_dest          => z.id_cmpt_dest,
                                       field_mask            => z.field_mask,
                                       flg_event_target_type => z.flg_event_target_type,
                                       validation_message    => z.validation_message,
                                       rn                    => z.rn)
          BULK COLLECT
          INTO o_ds_target
          FROM (
                
                SELECT (q.id_questionnaire * 10 + q.id_analysis) id_cmpt_mkt_origin,
                        q.id_questionnaire id_cmpt_origin,
                        q.id_questionnaire id_ds_event,
                        'E' flg_type,
                        --'@1 == ' || get_response_parent(i_lang, i_prof, q.id_exam, q.id_questionnaire) VALUE,
                        '@1 == ' || get_response_parent(i_lang, i_prof, q.id_analysis, q.id_questionnaire) VALUE,
                        qd.id_questionnaire * 10 + q.id_analysis id_cmpt_mkt_dest,
                        NULL id_cmpt_dest,
                        NULL field_mask,
                        'A' flg_event_target_type,
                        NULL validation_message,
                        1 rn
                  FROM (SELECT DISTINCT iq.id_analysis,
                                         iq.id_questionnaire,
                                         qr.id_questionnaire_parent,
                                         qr.id_response_parent,
                                         iq.flg_type,
                                         iq.flg_mandatory,
                                         iq.flg_copy,
                                         iq.flg_validation,
                                         iq.id_unit_measure,
                                         iq.rank
                           FROM analysis_questionnaire iq, questionnaire_response qr
                          WHERE iq.id_analysis IN (SELECT *
                                                     FROM TABLE(l_tbl_id_analysis_final))
                            AND iq.id_sample_type IN (SELECT *
                                                        FROM TABLE(l_tbl_id_sample_final))
                            AND iq.flg_time = 'O'
                            AND iq.id_institution = i_prof.institution
                            AND iq.flg_available = pk_procedures_constant.g_available
                            AND iq.id_questionnaire = qr.id_questionnaire
                            AND iq.id_response = qr.id_response
                            AND qr.flg_available = pk_procedures_constant.g_available
                            AND EXISTS
                          (SELECT 1
                                   FROM questionnaire q
                                  WHERE q.id_questionnaire = iq.id_questionnaire
                                    AND q.flg_available = pk_procedures_constant.g_available
                                    AND (((l_patient.gender IS NOT NULL AND coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                        l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                        nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q,
                        (SELECT DISTINCT qr.id_questionnaire, qr.id_questionnaire_parent, eq.id_analysis
                           FROM analysis_questionnaire eq
                          INNER JOIN questionnaire_response qr
                             ON eq.id_questionnaire = qr.id_questionnaire
                          WHERE eq.id_analysis IN (SELECT *
                                                     FROM TABLE(l_tbl_id_analysis_final))
                            AND eq.id_sample_type IN (SELECT *
                                                        FROM TABLE(l_tbl_id_sample_final))
                            AND eq.id_institution = i_prof.institution) qd
                 WHERE q.id_response_parent IS NULL
                   AND qd.id_questionnaire_parent = q.id_questionnaire
                   AND qd.id_analysis = q.id_analysis
                   AND q.flg_type IN ('ME', 'MI')
                UNION ALL
                SELECT (q.id_questionnaire * 10 + q.id_analysis) id_cmpt_mkt_origin,
                        q.id_questionnaire id_cmpt_origin,
                        q.id_questionnaire id_ds_event,
                        'E' flg_type,
                        --'@1 == ' || get_response_parent(i_lang, i_prof, q.id_exam, q.id_questionnaire) VALUE,
                        '@1 != ' || get_response_parent(i_lang, i_prof, q.id_analysis, q.id_questionnaire) VALUE,
                        qd.id_questionnaire * 10 + q.id_analysis id_cmpt_mkt_dest,
                        NULL id_cmpt_dest,
                        NULL field_mask,
                        'I' flg_event_target_type,
                        NULL validation_message,
                        1 rn
                  FROM (SELECT DISTINCT iq.id_analysis,
                                         iq.id_questionnaire,
                                         qr.id_questionnaire_parent,
                                         qr.id_response_parent,
                                         iq.flg_type,
                                         iq.flg_mandatory,
                                         iq.flg_copy,
                                         iq.flg_validation,
                                         iq.id_unit_measure,
                                         iq.rank
                           FROM analysis_questionnaire iq, questionnaire_response qr
                          WHERE iq.id_analysis IN (SELECT *
                                                     FROM TABLE(l_tbl_id_analysis_final))
                            AND iq.id_sample_type IN (SELECT *
                                                        FROM TABLE(l_tbl_id_sample_final))
                            AND iq.flg_time = 'O'
                            AND iq.id_institution = i_prof.institution
                            AND iq.flg_available = pk_procedures_constant.g_available
                            AND iq.id_questionnaire = qr.id_questionnaire
                            AND iq.id_response = qr.id_response
                            AND qr.flg_available = pk_procedures_constant.g_available
                            AND EXISTS
                          (SELECT 1
                                   FROM questionnaire q
                                  WHERE q.id_questionnaire = iq.id_questionnaire
                                    AND q.flg_available = pk_procedures_constant.g_available
                                    AND (((l_patient.gender IS NOT NULL AND coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                        l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                        nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q,
                        (SELECT DISTINCT qr.id_questionnaire, qr.id_questionnaire_parent, eq.id_analysis
                           FROM analysis_questionnaire eq
                          INNER JOIN questionnaire_response qr
                             ON eq.id_questionnaire = qr.id_questionnaire
                          WHERE eq.id_analysis IN (SELECT *
                                                     FROM TABLE(l_tbl_id_analysis_final))
                            AND eq.id_sample_type IN (SELECT *
                                                        FROM TABLE(l_tbl_id_sample_final))
                            AND eq.id_institution = i_prof.institution) qd
                 WHERE q.id_response_parent IS NULL
                   AND qd.id_questionnaire_parent = q.id_questionnaire
                   AND qd.id_analysis = q.id_analysis
                   AND q.flg_type IN ('ME', 'MI')) z;
        --pk_types.open_cursor_if_closed(o_ds_target);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FULL_ITEMS_BY_SCREEN',
                                              o_error);
            RETURN FALSE;
    END get_full_items_by_screen;

    FUNCTION get_response_parent
    (
        i_lang          language.id_language%TYPE,
        i_prof          profissional,
        i_analysis      analysis.id_analysis%TYPE,
        i_questionnaire questionnaire.id_questionnaire%TYPE
    ) RETURN NUMBER AS
        l_ret NUMBER(24);
    BEGIN
    
        SELECT DISTINCT qr.id_response_parent
          INTO l_ret
          FROM analysis_questionnaire iq
         INNER JOIN questionnaire_response qr
            ON iq.id_questionnaire = qr.id_questionnaire
         WHERE iq.id_analysis = i_analysis
           AND qr.id_questionnaire_parent = i_questionnaire
           AND iq.id_institution = i_prof.institution;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_response_parent;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_lab_tests_utils;
/
