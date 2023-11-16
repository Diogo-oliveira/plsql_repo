/*-- Last Change Revision: $Rev: 2027416 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_analysis AS

    /**
    * Get analysis from analysis group.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ANALALYSIS_GROUP id analysis group
    * @param   I_PROF_CAT_TYPE  type of professional category
    * @param   O_ANALYSIS analysis list
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  CRS 
    * @version 2.4.3
    * @since   2005-12-14
    * @modify  Joao Sa 2008-04-14 pode usar funcao de pk_lab_tests_api_db. As analises do grupo nao dependem da instituicao.
    */

    FUNCTION get_lab_test_in_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_analysis_group IN analysis_group.id_analysis_group%TYPE,
        i_codification   IN codification.id_codification%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_lab_tests_api_db.get_lab_test_in_group(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => i_patient,
                                                         i_analysis_group => i_analysis_group,
                                                         i_codification   => i_codification,
                                                         o_list           => o_list,
                                                         o_error          => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_LAB_TEST_IN_GROUP',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_lab_test_in_group;

    /**
    * Get sample type list
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_PATIENT selected patient
    * @param   O_SAMPLE_TYPE flag sample type list
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  CRS  
    * @version 2.4.3
    * @since   2005-05-09
    * @modify  Joana Barroso 2008-04-17 para referenciacao de P1
    */

    FUNCTION get_sample_type_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_sample_type OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_gender   patient.gender%TYPE;
        l_age      NUMBER;
        l_pat_info pk_types.cursor_type;
    
    BEGIN
    
        g_error := 'CALL pk_ref_core.get_pat_info';
        IF NOT pk_ref_core.get_pat_info(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_patient => i_patient,
                                        o_info    => l_pat_info,
                                        o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_pat_info';
        FETCH l_pat_info
            INTO l_gender, l_age;
        CLOSE l_pat_info;
    
        g_error := 'GET CURSOR';
        OPEN o_sample_type FOR
            SELECT pk_translation.get_translation(i_lang, st.code_sample_type) code_sample_type, st.id_sample_type
              FROM sample_type st
             WHERE st.flg_available = pk_ref_constant.g_yes
               AND st.id_sample_type IN
                   (SELECT a.id_sample_type
                      FROM analysis a
                      JOIN analysis_instit_soft ad
                        ON (a.id_analysis = ad.id_analysis)
                      JOIN analysis_instit_soft aisd
                        ON (ad.id_analysis = aisd.id_analysis)
                      JOIN p1_dest_institution pdi
                        ON (pdi.id_inst_orig = i_prof.institution AND aisd.id_institution = pdi.id_inst_dest)
                     WHERE
                    -- requestable at origin institution
                     ad.id_software = i_prof.software
                  AND ad.id_institution = i_prof.institution
                  AND ad.flg_available = pk_ref_constant.g_yes
                  AND ad.flg_type = pk_alert_constant.g_analysis_request
                  AND ad.id_exam_cat IS NOT NULL -- ACM 2008-12-23 grelha mostra analises atraves das categorias (get_analysis_samp_list)
                  AND a.flg_available = pk_ref_constant.g_yes
                    -- executable at dest institution
                  AND aisd.flg_available = pk_ref_constant.g_yes
                  AND aisd.flg_execute = pk_ref_constant.g_yes
                  AND aisd.id_software = pk_alert_constant.g_soft_referral
                  AND aisd.flg_type = pk_alert_constant.g_analysis_request
                    -- analysis
                  AND pdi.flg_type = pk_ref_constant.g_p1_type_a
                  AND ((l_gender IS NOT NULL AND nvl(a.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                     l_gender = 'I')
                  AND (nvl(l_age, 0) BETWEEN nvl(a.age_min, 0) AND nvl(a.age_max, nvl(l_age, 0)) OR nvl(l_age, 0) = 0)
                    --RS 20071228 Só mostra análises com parametros activos
                  AND EXISTS (SELECT 1
                        FROM analysis_param ap
                       WHERE ap.id_analysis = a.id_analysis
                         AND ap.flg_available = pk_ref_constant.g_yes
                         AND ap.id_institution = pdi.id_inst_dest
                         AND ap.id_software = i_prof.software))
               AND ((l_gender IS NOT NULL AND nvl(st.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                   l_gender = 'I')
               AND (nvl(l_age, 0) BETWEEN nvl(st.age_min, 0) AND nvl(st.age_max, nvl(l_age, 0)) OR nvl(l_age, 0) = 0)
             ORDER BY st.rank, code_sample_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SAMPLE_TYPE_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sample_type);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END;

    /**
    * Get institutions for the selected analysis
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ANALYSIS selected analysis
    * @param   O_INST_DEST destination institution
    * @param   O_REF_AREA flag to reference area
    * @param   O_ERROR an error message, set when return=false
    *
    * @value   O_REF_AREA {*} 'Y' in reference area {*} 'N' out of reference area
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   22-02-2008
    * @modify  Joana Barroso 2008-04-17 para referenciacao de P1
    * @modify Joana Barroso 08/05/2008 JOIN
    */
    -- Versão 2.4.3: Nao tem coluna p1_dest_institution.flg_inside_ref_area    
    FUNCTION get_analysis_institutions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis     IN analysis.id_analysis%TYPE,
        o_institutions OUT pk_types.cursor_type,
        o_ref_area     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init get_analysis_institutions';
        pk_alertlog.log_debug(g_error);
    
        g_error := 'OPEN O_INST_DEST';
        OPEN o_institutions FOR
            SELECT DISTINCT pdi.id_inst_dest id_institution,
                            ist.abbreviation abbreviation,
                            pk_translation.get_translation(i_lang, ist.code_institution) desc_institution
              FROM p1_dest_institution pdi
              JOIN analysis_instit_soft ais
                ON (pdi.id_inst_dest = ais.id_institution)
              JOIN institution ist
                ON (ist.id_institution = pdi.id_inst_dest)
             WHERE pdi.id_inst_orig = i_prof.institution
               AND ais.flg_available = pk_ref_constant.g_yes
               AND ais.flg_execute = pk_ref_constant.g_yes
               AND ais.id_software = pk_alert_constant.g_soft_referral
               AND ais.flg_type = pk_alert_constant.g_analysis_request
               AND ais.id_analysis = i_analysis
               AND pdi.flg_type = pk_ref_constant.g_p1_type_a
             ORDER BY abbreviation, desc_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ANALYSIS_INSTITUTIONS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_institutions);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END;

    /**
    * Get default institutions for the selected analysis. 
    * If not configured in p1_analysis_default_dest returns 
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ANALYSIS selected analysis
    * @param   O_INST_DEST default destination institution
    * @param   O_REF_AREA flag to reference area
    * @param   O_ERROR an error message, set when return=false
    *
    * @value   O_REF_AREA {*} 'Y' in reference area {*} 'N' out of reference area
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   26-02-2008
    * @modify  Joana Barroso 8-03-2008 estava errado di.id_dest_institution
    * @modify Joana Barroso 08/05/2008 JOIN
    */
    -- Versão 2.4.3: Nao tem coluna p1_dest_institution.flg_inside_ref_area
    FUNCTION get_analysis_default_insts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis     IN table_number,
        o_institutions OUT pk_types.cursor_type,
        o_ref_area     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init get_analysis_default_insts';
        pk_alertlog.log_debug(g_error);
    
        g_error := 'OPEN C_INST_DEST';
        OPEN o_institutions FOR
        -- records in p1_analysis_default_dest
            SELECT adi.id_analysis id_analysis,
                   pdi.id_inst_dest id_institution,
                   ist.abbreviation abbreviation,
                   pk_translation.get_translation(i_lang, ist.code_institution) desc_institution
              FROM p1_analysis_default_dest adi
              JOIN p1_dest_institution pdi
                ON (adi.id_dest_institution = pdi.id_dest_institution)
              JOIN institution ist
                ON (ist.id_institution = pdi.id_inst_dest)
              JOIN TABLE(CAST(i_analysis AS table_number)) tt
                ON (adi.id_analysis = tt.column_value)
             WHERE pdi.flg_type = pk_ref_constant.g_p1_type_a
               AND pdi.id_inst_orig = i_prof.institution
            UNION ALL
            -- records in p1_dest_institution (as default) and not in p1_analysis_default_dest
            SELECT ais.id_analysis id_analysis,
                   pdi.id_inst_dest id_institution,
                   ist.abbreviation abbreviation,
                   pk_translation.get_translation(i_lang, ist.code_institution) desc_institution
              FROM p1_dest_institution pdi
              JOIN analysis_instit_soft ais
                ON (pdi.id_inst_dest = ais.id_institution)
              JOIN institution ist
                ON (ist.id_institution = pdi.id_inst_dest)
              JOIN TABLE(CAST(i_analysis AS table_number)) tt
                ON (ais.id_analysis = tt.column_value)
             WHERE pdi.id_inst_orig = i_prof.institution
               AND pdi.flg_type = pk_ref_constant.g_p1_type_a
                  -- executable at dest institution
               AND ais.flg_available = pk_ref_constant.g_yes
               AND ais.flg_execute = pk_ref_constant.g_yes
               AND ais.id_software = pk_alert_constant.g_soft_referral
               AND ais.flg_type = pk_alert_constant.g_analysis_request
                  -- analysis               
               AND pdi.flg_default = pk_ref_constant.g_yes
               AND tt.column_value NOT IN (SELECT ad.id_analysis
                                             FROM p1_analysis_default_dest ad
                                             JOIN p1_dest_institution pdi
                                               ON (ad.id_dest_institution = pdi.id_dest_institution)
                                            WHERE pdi.id_inst_orig = i_prof.institution
                                              AND pdi.flg_type = pk_ref_constant.g_p1_type_a)
            UNION ALL
            -- records in p1_dest_institution (**not** default) and not in p1_dest_institution (as default) and not in p1_analysis_default_dest
            SELECT ais.id_analysis id_analysis,
                   pdi.id_inst_dest id_institution,
                   ist.abbreviation abbreviation,
                   pk_translation.get_translation(i_lang, ist.code_institution) desc_institution
              FROM p1_dest_institution pdi
              JOIN analysis_instit_soft ais
                ON (pdi.id_inst_dest = ais.id_institution)
              JOIN institution ist
                ON (ist.id_institution = pdi.id_inst_dest)
              JOIN TABLE(CAST(i_analysis AS table_number)) tt
                ON (ais.id_analysis = tt.column_value)
             WHERE pdi.id_inst_orig = i_prof.institution
               AND pdi.flg_type = pk_ref_constant.g_p1_type_a
                  -- executable at dest institution
               AND ais.flg_available = pk_ref_constant.g_yes
               AND ais.flg_execute = pk_ref_constant.g_yes
               AND ais.id_software = pk_alert_constant.g_soft_referral
               AND ais.flg_type = pk_alert_constant.g_analysis_request
                  -- analysis
               AND pdi.flg_default = pk_ref_constant.g_no -- not default
                  -- not in p1_dest_institution (as default)
               AND ais.id_analysis NOT IN (SELECT aisi.id_analysis id_analysis
                                             FROM p1_dest_institution pdii
                                             JOIN analysis_instit_soft aisi
                                               ON (pdii.id_inst_dest = aisi.id_institution)
                                             JOIN TABLE(CAST(i_analysis AS table_number)) tt
                                               ON (aisi.id_analysis = tt.column_value)
                                            WHERE pdii.id_inst_orig = i_prof.institution
                                              AND pdii.flg_type = pk_ref_constant.g_p1_type_a
                                              AND aisi.flg_execute = pk_ref_constant.g_yes
                                              AND aisi.id_software = pk_alert_constant.g_soft_referral
                                              AND aisi.flg_type = pk_alert_constant.g_analysis_request
                                              AND pdii.flg_default = pk_ref_constant.g_yes)
                  -- not in p1_analysis_default_dest
               AND tt.column_value NOT IN (SELECT ad.id_analysis
                                             FROM p1_analysis_default_dest ad
                                             JOIN p1_dest_institution pdii
                                               ON (ad.id_dest_institution = pdii.id_dest_institution)
                                            WHERE pdii.id_inst_orig = i_prof.institution
                                              AND pdii.flg_type = pk_ref_constant.g_p1_type_a)
             ORDER BY abbreviation, desc_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ANALYSIS_DEFAULT_INSTS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_institutions);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * get common institution based on all required analysis
    *
    * @param    i_lang            preferred language id
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_analysis        array of requested analysis
    * @param    o_inst            cursor with institution information
    * @param    o_error           error message structure
    *
    * @return   boolean           false in case of error, otherwise true
    *
    * @author   Carlos Loureiro
    * @version  1.0
    * @since    2009/08/28
    ********************************************************************************************/
    FUNCTION get_analysis_inst
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN table_number,
        o_inst     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_institution institution.id_institution%TYPE;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'pk_sysconfig.get_config ' || g_ref_external_inst;
        l_id_institution := to_number(pk_sysconfig.get_config(g_ref_external_inst, i_prof));
    
        g_error := 'GET CURSOR WITH COMMON INSTITUTIONS';
    
        OPEN o_inst FOR
            SELECT ais_dest.id_institution,
                   pk_translation.get_translation(i_lang, inst.code_institution) AS institution_name,
                   inst.abbreviation AS institution_abbreviation
              FROM analysis_instit_soft ais_dest
              JOIN analysis a
                ON a.id_analysis = ais_dest.id_analysis
              JOIN institution inst
                ON inst.id_institution = ais_dest.id_institution
             WHERE a.flg_available = pk_alert_constant.g_available
               AND ais_dest.flg_available = pk_ref_constant.g_yes
               AND ais_dest.flg_type = pk_alert_constant.g_analysis_request
               AND ais_dest.flg_execute = pk_ref_constant.g_yes
               AND ais_dest.id_software = pk_alert_constant.g_soft_referral
               AND ais_dest.id_analysis_instit_soft IN
                   (SELECT raod.id_analysis_is_dest
                      FROM (SELECT column_value id_analysis
                              FROM TABLE(i_analysis)) table_id_analysis
                      JOIN analysis_instit_soft ais_orig
                        ON ais_orig.id_analysis = table_id_analysis.id_analysis
                      JOIN ref_analysis_orig_dest raod
                        ON raod.id_analysis_is_orig = ais_orig.id_analysis_instit_soft
                     WHERE raod.flg_available = pk_ref_constant.g_yes
                       AND ais_orig.flg_available = pk_ref_constant.g_yes
                       AND ais_orig.flg_type = pk_alert_constant.g_analysis_request
                       AND ais_orig.id_institution = i_prof.institution
                       AND ais_orig.id_software = i_prof.software)
             GROUP BY ais_dest.id_institution,
                      pk_translation.get_translation(i_lang, inst.code_institution),
                      inst.abbreviation
            HAVING COUNT(ais_dest.id_analysis) >= (SELECT COUNT(*)
                                                     FROM TABLE(i_analysis))
            UNION ALL
            SELECT i.id_institution,
                   pk_translation.get_translation(i_lang, i.code_institution) AS institution_name,
                   i.abbreviation AS institution_abbreviation
              FROM institution i
             WHERE i.id_institution = l_id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        -- unexpected error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ANALYSIS_INST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_inst);
            RETURN FALSE;
        
    END get_analysis_inst;

    FUNCTION get_analysis_inst
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        l_id_institution           institution.id_institution%TYPE;
        l_tbl_analysis_sample_type table_varchar;
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'pk_sysconfig.get_config ' || g_ref_external_inst;
        l_id_institution := to_number(pk_sysconfig.get_config(g_ref_external_inst, i_prof));
    
        l_tbl_analysis_sample_type := pk_utils.str_split_l(i_list => i_analysis, i_delim => '|');
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => institution_name,
                                         domain_value  => id_institution,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT ais_dest.id_institution,
                               pk_translation.get_translation(i_lang, inst.code_institution) AS institution_name
                          FROM analysis_instit_soft ais_dest
                          JOIN analysis a
                            ON a.id_analysis = ais_dest.id_analysis
                          JOIN institution inst
                            ON inst.id_institution = ais_dest.id_institution
                         WHERE a.flg_available = pk_alert_constant.g_available
                           AND ais_dest.flg_available = pk_ref_constant.g_yes
                           AND ais_dest.flg_type = pk_alert_constant.g_analysis_request
                           AND ais_dest.flg_execute = pk_ref_constant.g_yes
                           AND ais_dest.id_software = pk_alert_constant.g_soft_referral
                           AND ais_dest.id_analysis_instit_soft IN
                               (SELECT raod.id_analysis_is_dest
                                  FROM (SELECT ast.id_analysis /*+opt_estimate(table t rows=1)*/
                                          FROM TABLE(l_tbl_analysis_sample_type) t
                                          JOIN analysis_sample_type ast
                                            ON ast.id_content = t.column_value) table_id_analysis
                                  JOIN analysis_instit_soft ais_orig
                                    ON ais_orig.id_analysis = table_id_analysis.id_analysis
                                  JOIN ref_analysis_orig_dest raod
                                    ON raod.id_analysis_is_orig = ais_orig.id_analysis_instit_soft
                                 WHERE raod.flg_available = pk_ref_constant.g_yes
                                   AND ais_orig.flg_available = pk_ref_constant.g_yes
                                   AND ais_orig.flg_type = pk_alert_constant.g_analysis_request
                                   AND ais_orig.id_institution = i_prof.institution
                                   AND ais_orig.id_software = i_prof.software)
                         GROUP BY ais_dest.id_institution,
                                  pk_translation.get_translation(i_lang, inst.code_institution),
                                  inst.abbreviation
                        HAVING COUNT(ais_dest.id_analysis) >= (SELECT COUNT(*) /*+opt_estimate(table t rows=1)*/
                                                                FROM TABLE(l_tbl_analysis_sample_type) t)
                        UNION ALL
                        SELECT i.id_institution,
                               pk_translation.get_translation(i_lang, i.code_institution) AS institution_name
                          FROM institution i
                         WHERE i.id_institution = l_id_institution));
    
        RETURN l_ret;
    
    EXCEPTION
        -- unexpected error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ANALYSIS_INST',
                                              o_error    => l_error);
            RETURN t_tbl_core_domain();
        
    END get_analysis_inst;

    /**
    * Checks if referral can be sent to dest institution: all analysis req are ready to be sent
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Id professional, institution and software    
    * @param   i_analysis_req_det    Analysis req detail identification    
    * @param   o_flg_completed       Flag indicating if all analysis workflow are completed in professionl institution
    * @param   O_ERROR               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   31-08-2009
    */
    FUNCTION check_ref_completed
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_flg_completed    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_list                 pk_types.cursor_type; -- [id_analysis_req_det|end_of_ext_workflow]
        l_analysis_req_det_tab table_number := table_number();
        l_flg_completed_tab    table_varchar := table_varchar();
    BEGIN
    
        g_error  := 'Calling pk_lab_tests_external_api_db.check_lab_test_workflow_end / analysis_req_det.COUNT=' ||
                    i_analysis_req_det.count;
        g_retval := pk_lab_tests_external_api_db.check_lab_test_workflow_end(i_lang             => i_lang,
                                                                             i_prof             => i_prof,
                                                                             i_analysis_req_det => i_analysis_req_det,
                                                                             o_list             => l_list,
                                                                             o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_list';
        FETCH l_list BULK COLLECT
            INTO l_analysis_req_det_tab, l_flg_completed_tab;
        CLOSE l_list;
    
        g_error := 'LOOP';
        FOR i IN 1 .. l_flg_completed_tab.count
        LOOP
            IF l_flg_completed_tab(i) = pk_ref_constant.g_no
            THEN
                o_flg_completed := pk_ref_constant.g_no;
            END IF;
        
        END LOOP;
    
        o_flg_completed := nvl(o_flg_completed, pk_ref_constant.g_yes);
    
        g_error := 'o_flg_completed=' || o_flg_completed;
        pk_alertlog.log_debug(g_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            IF l_list%ISOPEN
            THEN
                CLOSE l_list;
            END IF;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REF_COMPLETED',
                                              o_error    => o_error);
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
    END check_ref_completed;

    FUNCTION get_ref_analysis_req_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_completed VARCHAR2(4000);
    
    BEGIN
    
        IF i_analysis_req_det IS NULL
        THEN
            g_error := 'i_analysis_req_det is null';
            RAISE g_exception;
        END IF;
    
        g_error  := 'Calling PK_P1_ANALYSIS.check_ref_completed / analysis_req_det.COUNT=' || i_analysis_req_det.count;
        g_retval := check_ref_completed(i_lang             => i_lang,
                                        i_prof             => i_prof,
                                        i_analysis_req_det => i_analysis_req_det,
                                        o_flg_completed    => l_flg_completed,
                                        o_error            => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Open o_sql';
        OPEN o_sql FOR
            SELECT id_external_request, l_flg_completed flg_completed
              FROM p1_exr_temp pet
              JOIN TABLE(i_analysis_req_det) tt
                ON (pet.id_analysis_req_det = tt.column_value);
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_ANALYSIS_REQ_DET',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_ref_analysis_req_det;

-- ##########################################################################

-- **********************************************************************
-- ****************************  CONSTRUCTOR  ***************************
-- **********************************************************************
--BEGIN

--xsp := chr(32);
--xpl := '''';    

END pk_p1_analysis;
/
