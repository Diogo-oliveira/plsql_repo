CREATE OR REPLACE PACKAGE BODY pk_labtest_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_LABTEST_PRM';
    pos_soft        NUMBER := 1;
    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_sample_type_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('SAMPLE_TYPE.CODE_SAMPLE_TYPE.');
    
    BEGIN
    
        g_func_name := upper('LOAD_SAMPLE_RECIPIENT_DEF');
    
        INSERT INTO sample_type
            (id_sample_type, code_sample_type, id_content, flg_available, gender, age_min, age_max, rank)
            SELECT seq_sample_type.nextval,
                   l_code_translation || seq_sample_type.currval,
                   def_data.id_content,
                   def_data.flg_available,
                   def_data.gender,
                   def_data.age_min,
                   def_data.age_max,
                   0
              FROM (SELECT ad_st.id_content, ad_st.flg_available, ad_st.gender, ad_st.age_min, ad_st.age_max
                      FROM ad_sample_type ad_st
                     WHERE ad_st.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM sample_type a_st
                             WHERE a_st.id_content = ad_st.id_content
                               AND a_st.flg_available = g_flg_available)) def_data;
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_sample_type_def;

    FUNCTION load_sample_recipient_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.');
    
    BEGIN
    
        g_func_name := upper('LOAD_SAMPLE_RECIPIENT_DEF');
    
        INSERT INTO sample_recipient
            (id_sample_recipient,
             code_sample_recipient,
             id_content,
             flg_available,
             capacity,
             code_capacity_measure,
             rank,
             /*ALERT-288259 Added these columns*/
             id_unit_measure,
             standard_code)
            SELECT seq_sample_recipient.nextval,
                   l_code_translation || seq_sample_recipient.currval,
                   def_data.id_content,
                   def_data.flg_available,
                   def_data.capacity,
                   def_data.code_capacity_measure,
                   0,
                   def_data.id_unit_measure,
                   def_data.standard_code
              FROM (SELECT ad_sr.id_content,
                           ad_sr.flg_available,
                           ad_sr.capacity,
                           ad_sr.code_capacity_measure,
                           ad_sr.id_unit_measure,
                           ad_sr.standard_code
                      FROM ad_sample_recipient ad_sr
                     WHERE ad_sr.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM sample_recipient a_sr
                             WHERE a_sr.id_content = ad_sr.id_content
                               AND a_sr.flg_available = g_flg_available)) def_data;
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_sample_recipient_def;

    FUNCTION load_analysis_group_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.');
    
    BEGIN
    
        g_func_name := upper('LOAD_ANALYSIS_GROUP_DEF');
    
        INSERT INTO analysis_group
            (id_analysis_group, code_analysis_group, id_content, gender, age_min, age_max, rank)
            SELECT seq_analysis_group.nextval,
                   l_code_translation || seq_analysis_group.currval,
                   def_data.id_content,
                   def_data.gender,
                   def_data.age_min,
                   def_data.age_max,
                   0
              FROM (SELECT ad_ag.id_content, ad_ag.gender, ad_ag.age_min, ad_ag.age_max
                      FROM ad_analysis_group ad_ag
                     WHERE NOT EXISTS (SELECT 0
                              FROM analysis_group a_ag
                             WHERE a_ag.id_content = ad_ag.id_content
                               AND a_ag.flg_available = g_flg_available)) def_data;
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_group_def;

    FUNCTION load_analysis_parameter_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.');
    
    BEGIN
    
        g_func_name := upper('LOAD_ANALYSIS_PARAMETER_DEF');
    
        INSERT INTO analysis_parameter
            (id_analysis_parameter, code_analysis_parameter, id_content, flg_available, flg_type)
            SELECT seq_analysis_parameter.nextval,
                   l_code_translation || seq_analysis_parameter.currval,
                   def_data.id_content,
                   def_data.flg_available,
                   def_data.flg_type
              FROM (SELECT ad_ap.id_content, ad_ap.flg_available, ad_ap.flg_type
                      FROM ad_analysis_parameter ad_ap
                     WHERE ad_ap.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM analysis_parameter a_ap
                             WHERE a_ap.id_content = ad_ap.id_content
                               AND a_ap.flg_available = g_flg_available)) def_data;
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_parameter_def;

    FUNCTION load_analysis_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('ANALYSIS.CODE_ANALYSIS.');
    
    BEGIN
    
        g_func_name := upper('LOAD_ANALYSIS_DEF');
    
        INSERT INTO analysis
            (id_analysis, code_analysis, id_content, flg_available, gender, age_min, age_max, id_sample_type, rank)
            SELECT seq_analysis.nextval,
                   l_code_translation || seq_analysis.currval,
                   def_data.id_content,
                   def_data.flg_available,
                   def_data.gender,
                   def_data.age_min,
                   def_data.age_max,
                   def_data.id_sample_type,
                   0
              FROM (SELECT ad_a.id_content,
                           ad_a.flg_available,
                           ad_a.gender,
                           ad_a.age_min,
                           ad_a.age_max,
                           decode(ad_a.id_sample_type,
                                  NULL,
                                  NULL,
                                  nvl((SELECT a_st.id_sample_type
                                        FROM sample_type a_st
                                       WHERE a_st.flg_available = g_flg_available
                                         AND EXISTS (SELECT 1
                                                FROM ad_sample_type ad_st
                                               WHERE ad_st.id_sample_type = ad_a.id_sample_type
                                                 AND ad_st.id_content = a_st.id_content
                                                 AND ad_st.flg_available = g_flg_available)),
                                      0)) id_sample_type
                      FROM ad_analysis ad_a
                     WHERE ad_a.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM analysis a_a
                             WHERE a_a.id_content = ad_a.id_content
                               AND a_a.flg_available = g_flg_available)) def_data
             WHERE def_data.id_sample_type > 0
                OR def_data.id_sample_type IS NULL;
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_def;

    FUNCTION load_analysis_agp_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('LOAD_ANALYSIS_AGP_DEF');
    
        INSERT INTO analysis_agp
            (id_analysis_agp, id_analysis, id_analysis_group, rank, id_sample_type)
            SELECT seq_analysis_agp.nextval,
                   def_data.id_analysis,
                   def_data.id_analysis_group,
                   def_data.rank,
                   def_data.id_sample_type
              FROM (SELECT nvl((SELECT a_a.id_analysis
                                 FROM analysis a_a
                                 JOIN ad_analysis ad_a
                                   ON a_a.id_content = ad_a.id_content
                                WHERE ad_a.id_analysis = ad_aagp.id_analysis
                                  AND a_a.flg_available = g_flg_available
                                  AND ad_a.flg_available = g_flg_available),
                               0) id_analysis,
                           nvl((SELECT a_ag.id_analysis_group
                                 FROM analysis_group a_ag
                                 JOIN ad_analysis_group ad_ag
                                   ON ad_ag.id_content = a_ag.id_content
                                WHERE ad_ag.id_analysis_group = ad_aagp.id_analysis_group
                                  AND a_ag.flg_available = g_flg_available),
                               0) id_analysis_group,
                           ad_aagp.rank,
                           nvl((SELECT a_st.id_sample_type
                                 FROM sample_type a_st
                                 JOIN ad_sample_type ad_st
                                   ON ad_st.id_content = a_st.id_content
                                WHERE ad_st.id_sample_type = ad_aagp.id_sample_type
                                  AND a_st.flg_available = g_flg_available
                                  AND ad_st.flg_available = g_flg_available),
                               0) id_sample_type
                      FROM ad_analysis_agp ad_aagp) def_data
             WHERE def_data.id_analysis > 0
               AND def_data.id_analysis_group > 0
               AND def_data.id_sample_type > 0
               AND NOT EXISTS (SELECT 0
                      FROM analysis_agp a_aagp
                     WHERE a_aagp.id_sample_type = def_data.id_sample_type
                       AND a_aagp.id_analysis_group = def_data.id_analysis_group
                       AND a_aagp.id_analysis = def_data.id_analysis)
               AND EXISTS (SELECT 0
                      FROM analysis_sample_type a_ast
                     WHERE a_ast.id_analysis = def_data.id_analysis
                       AND a_ast.id_sample_type = def_data.id_sample_type
                       AND a_ast.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_agp_def;

    FUNCTION load_analysis_desc_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('ANALYSIS_DESC.CODE_ANALYSIS_DESC.');
    
    BEGIN
    
        g_func_name := upper('LOAD_ANALYSIS_DESC_DEF');
    
        INSERT INTO analysis_desc
            (id_analysis_desc,
             code_analysis_desc,
             id_content,
             id_analysis,
             flg_available,
             VALUE,
             icon,
             id_analysis_parameter,
             rank,
             flg_blood_type,
             id_sample_type)
            SELECT seq_analysis_desc.nextval,
                   l_code_translation || seq_analysis_desc.currval,
                   def_data.id_content,
                   def_data.id_analysis,
                   def_data.flg_available,
                   def_data.value,
                   def_data.icon,
                   def_data.id_analysis_parameter,
                   def_data.rank,
                   def_data.flg_blood_type,
                   def_data.id_sample_type
              FROM (SELECT ad_ad.id_content,
                           nvl((SELECT a_a.id_analysis
                                 FROM analysis a_a
                                 JOIN ad_analysis ad_a
                                   ON a_a.id_content = ad_a.id_content
                                WHERE ad_a.id_analysis = ad_ad.id_analysis
                                  AND ad_a.flg_available = g_flg_available
                                  AND a_a.flg_available = g_flg_available),
                               0) id_analysis,
                           ad_ad.flg_available,
                           ad_ad.value,
                           ad_ad.icon,
                           nvl((SELECT a_ap.id_analysis_parameter
                                 FROM analysis_parameter a_ap
                                 JOIN ad_analysis_parameter ad_ap
                                   ON ad_ap.id_content = a_ap.id_content
                                WHERE ad_ap.id_analysis_parameter = ad_ad.id_analysis_parameter
                                  AND ad_ap.flg_available = g_flg_available
                                  AND a_ap.flg_available = g_flg_available),
                               0) id_analysis_parameter,
                           ad_ad.rank,
                           ad_ad.flg_blood_type,
                           nvl((SELECT a_st.id_sample_type
                                 FROM sample_type a_st
                                 JOIN ad_sample_type ad_st
                                   ON ad_st.id_content = a_st.id_content
                                WHERE ad_st.id_sample_type = ad_ad.id_sample_type
                                  AND a_st.flg_available = g_flg_available
                                  AND ad_st.flg_available = g_flg_available),
                               0) id_sample_type
                      FROM ad_analysis_desc ad_ad
                    --dup_code - see nvl
                     WHERE ad_ad.flg_available = g_flg_available) def_data
             WHERE def_data.id_sample_type > 0
               AND def_data.id_analysis > 0
               AND def_data.id_analysis_parameter > 0
               AND NOT EXISTS
             (SELECT 0
                      FROM analysis_desc a_ad
                     WHERE a_ad.id_content = def_data.id_content
                       AND a_ad.id_analysis = def_data.id_analysis
                       AND a_ad.id_analysis_parameter = def_data.id_analysis_parameter
                       AND a_ad.id_sample_type = def_data.id_sample_type
                       AND (a_ad.value = def_data.value OR (a_ad.value IS NULL AND def_data.value IS NULL))
                       AND a_ad.flg_available = g_flg_available)
               AND EXISTS (SELECT 0
                      FROM analysis_sample_type a_ast
                     WHERE a_ast.id_analysis = def_data.id_analysis
                       AND a_ast.id_sample_type = def_data.id_sample_type
                       AND a_ast.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_desc_def;

    FUNCTION load_analysis_loinc_templ_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('LOAD_ANALYSIS_LOINC_TEMPLATE_DEF');
    
        INSERT INTO analysis_loinc_template
            (id_analysis_loinc_template, id_analysis, loinc_code)
            SELECT seq_analysis_loinc_template.nextval, def_data.id_analysis, def_data.loinc_code
              FROM (SELECT a_a.id_analysis, ad_alt.loinc_code
                      FROM ad_analysis_loinc_template ad_alt
                      JOIN ad_analysis ad_a
                        ON ad_a.id_analysis = ad_alt.id_analysis
                       AND ad_a.flg_available = g_flg_available
                      JOIN analysis a_a
                        ON a_a.id_content = ad_a.id_content
                       AND a_a.flg_available = g_flg_available
                     WHERE NOT EXISTS (SELECT 0
                              FROM analysis_loinc_template a_alt
                             WHERE a_alt.id_analysis = a_a.id_analysis
                               AND a_alt.loinc_code = ad_alt.loinc_code)) def_data;
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_loinc_templ_def;

    FUNCTION load_lab_tests_uni_mea_cnv_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('LOAD_LAB_TESTS_UNI_MEA_CNV_DEF');
    
        INSERT INTO lab_tests_uni_mea_cnv
            (id_lab_tests_uni_mea_cnv, id_lt_param_src_unit, id_lt_param_dst_unit, factor, decimals)
            SELECT seq_lab_tests_uni_mea_cnv.nextval,
                   def_data.id_lab_tests_par_uni_mea_src,
                   def_data.id_lab_tests_par_uni_mea_dest,
                   def_data.factor,
                   def_data.decimals
              FROM (SELECT a_ltpum.id_lab_tests_par_uni_mea  id_lab_tests_par_uni_mea_src,
                           a_ltpum1.id_lab_tests_par_uni_mea id_lab_tests_par_uni_mea_dest,
                           ad_ltumc.factor,
                           ad_ltumc.decimals
                      FROM ad_lab_tests_uni_mea_cnv ad_ltumc
                      JOIN ad_lab_tests_par_uni_mea ad_ltpum
                        ON ad_ltpum.id_lab_tests_par_uni_mea = ad_ltumc.id_lt_param_src_unit
                      JOIN ad_analysis_parameter ad_ap
                        ON ad_ap.id_analysis_parameter = ad_ltpum.id_analysis_parameter
                       AND ad_ap.flg_available = g_flg_available
                      JOIN analysis_parameter a_ap
                        ON a_ap.id_content = ad_ap.id_content
                       AND a_ap.flg_available = g_flg_available
                      JOIN lab_tests_par_uni_mea a_ltpum
                        ON a_ltpum.id_unit_measure = ad_ltpum.id_unit_measure
                       AND a_ltpum.id_analysis_parameter = a_ap.id_analysis_parameter
                      LEFT JOIN lab_tests_uni_mea_cnv a_ltumc
                        ON a_ltumc.id_lt_param_src_unit = a_ltpum.id_lab_tests_par_uni_mea
                      JOIN ad_lab_tests_par_uni_mea ad_ltpum1
                        ON ad_ltpum1.id_lab_tests_par_uni_mea = ad_ltumc.id_lt_param_dst_unit
                      JOIN ad_analysis_parameter ad_ap1
                        ON ad_ap1.id_analysis_parameter = ad_ltpum1.id_analysis_parameter
                       AND ad_ap1.flg_available = g_flg_available
                      JOIN analysis_parameter a_ap2
                        ON a_ap2.id_content = ad_ap1.id_content
                       AND a_ap2.flg_available = g_flg_available
                      JOIN lab_tests_par_uni_mea a_ltpum1
                        ON a_ltpum1.id_unit_measure = ad_ltpum1.id_unit_measure
                       AND a_ltpum1.id_analysis_parameter = a_ap2.id_analysis_parameter
                      LEFT JOIN lab_tests_uni_mea_cnv a_ltumc1
                        ON a_ltumc1.id_lt_param_dst_unit = a_ltpum1.id_lab_tests_par_uni_mea
                     WHERE NOT EXISTS (SELECT 0
                              FROM lab_tests_uni_mea_cnv a_ltumc
                             WHERE a_ltumc.id_lt_param_src_unit = a_ltpum.id_lab_tests_par_uni_mea
                               AND a_ltumc.id_lt_param_dst_unit = a_ltpum1.id_lab_tests_par_uni_mea)) def_data;
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_lab_tests_uni_mea_cnv_def;

    FUNCTION load_lab_tests_par_uni_mea_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('LOAD_LAB_TESTS_PAR_UNI_MEA_DEF');
    
        INSERT INTO lab_tests_par_uni_mea
            (id_lab_tests_par_uni_mea,
             id_analysis_parameter,
             id_unit_measure,
             min_measure_interval,
             max_measure_interval)
            SELECT seq_lab_tests_par_uni_mea.nextval,
                   def_data.id_analysis_parameter,
                   def_data.id_unit_measure,
                   def_data.min_measure_interval,
                   def_data.max_measure_interval
              FROM (SELECT a_ap.id_analysis_parameter,
                           ad_ltpum.id_unit_measure,
                           ad_ltpum.min_measure_interval,
                           ad_ltpum.max_measure_interval
                      FROM ad_lab_tests_par_uni_mea ad_ltpum
                      JOIN ad_analysis_parameter ad_ap
                        ON ad_ap.id_analysis_parameter = ad_ltpum.id_analysis_parameter
                       AND ad_ap.flg_available = g_flg_available
                      JOIN analysis_parameter a_ap
                        ON a_ap.id_content = ad_ap.id_content
                       AND a_ap.flg_available = g_flg_available
                      JOIN unit_measure a_um
                        ON a_um.id_unit_measure = ad_ltpum.id_unit_measure
                       AND a_um.flg_available = g_flg_available
                     WHERE NOT EXISTS (SELECT 0
                              FROM lab_tests_par_uni_mea a_ltpum
                             WHERE a_ltpum.id_analysis_parameter = a_ap.id_analysis_parameter
                               AND a_ltpum.id_unit_measure = a_um.id_unit_measure)) def_data;
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_lab_tests_par_uni_mea_def;

    /********************************************************************************************
    * Get Default Configuration on Analysis and Sample Type Relation
    *
    * @param i_lang                Prefered language ID
    * @param o_labst               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION load_analysis_st_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('LOAD_ANALYSIS_ST_DEF');
        g_error     := 'OPEN CONFIGURATION CURSOR';
    
        INSERT INTO analysis_sample_type
            (id_analysis,
             id_sample_type,
             id_content_analysis,
             id_content_sample_type,
             id_content,
             flg_available,
             gender,
             age_min,
             age_max)
            SELECT def_data.id_analysis,
                   def_data.id_sample_type,
                   def_data.lt_id_content,
                   def_data.st_id_content,
                   def_data.id_content,
                   g_flg_available,
                   def_data.gender,
                   def_data.age_min,
                   def_data.age_max
              FROM (SELECT temp_data.l_row,
                           temp_data.id_analysis,
                           temp_data.id_sample_type,
                           temp_data.lt_id_content,
                           temp_data.st_id_content,
                           temp_data.id_content,
                           temp_data.age_max,
                           temp_data.age_min,
                           temp_data.gender,
                           row_number() over(PARTITION BY temp_data.id_analysis, temp_data.id_sample_type ORDER BY temp_data.l_row) records_count
                      FROM (SELECT ad_ast.rowid l_row,
                                   nvl((SELECT a_a.id_analysis
                                         FROM analysis a_a
                                        WHERE a_a.id_content = ad_a.id_content
                                          AND a_a.flg_available = g_flg_available),
                                       0) id_analysis,
                                   ad_a.id_content lt_id_content,
                                   nvl((SELECT a_st.id_sample_type
                                         FROM sample_type a_st
                                        WHERE a_st.id_content = ad_st.id_content
                                          AND a_st.flg_available = g_flg_available),
                                       0) id_sample_type,
                                   ad_st.id_content st_id_content,
                                   ad_ast.id_content,
                                   ad_ast.age_max,
                                   ad_ast.age_min,
                                   ad_ast.gender
                              FROM ad_analysis_sample_type ad_ast
                              JOIN ad_analysis ad_a
                                ON ad_a.id_analysis = ad_ast.id_analysis
                               AND ad_a.flg_available = g_flg_available
                              JOIN ad_sample_type ad_st
                                ON ad_st.id_sample_type = ad_ast.id_sample_type
                               AND ad_st.flg_available = g_flg_available
                             WHERE ad_ast.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_analysis > 0
                       AND temp_data.id_sample_type > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM analysis_sample_type a_ast
                     WHERE a_ast.id_analysis = def_data.id_analysis
                       AND a_ast.id_sample_type = def_data.id_sample_type);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_st_def;

    /********************************************************************************************
    * Get Default Configuration on Analysis and Body Structure Relation
    *
    * @param i_lang                Prefered language ID
    * @param o_labbs               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/

    FUNCTION load_analysis_bs_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('LOAD_ANALYSIS_BS_DEF');
        g_error     := 'OPEN CONFIGURATION CURSOR';
    
        INSERT INTO analysis_body_structure
            (id_analysis, id_sample_type, id_body_structure, flg_available)
            SELECT def_data.id_analysis, def_data.id_sample_type, def_data.id_body_structure, g_flg_available
              FROM (SELECT temp_data.l_row,
                           temp_data.id_analysis,
                           temp_data.id_sample_type,
                           temp_data.id_body_structure,
                           row_number() over(PARTITION BY temp_data.id_analysis, temp_data.id_sample_type, temp_data.id_body_structure ORDER BY temp_data.l_row) records_count
                      FROM (SELECT ad_abs.rowid l_row,
                                   nvl((SELECT a_a.id_analysis
                                         FROM analysis a_a
                                         JOIN ad_analysis ad_a
                                           ON a_a.id_content = ad_a.id_content
                                        WHERE ad_a.id_analysis = ad_abs.id_analysis
                                          AND a_a.flg_available = g_flg_available
                                          AND ad_a.flg_available = g_flg_available),
                                       0) id_analysis,
                                   nvl((SELECT a_st.id_sample_type
                                         FROM sample_type a_st
                                         JOIN ad_sample_type ad_st
                                           ON a_st.id_content = ad_st.id_content
                                        WHERE ad_st.id_sample_type = ad_abs.id_sample_type
                                          AND a_st.flg_available = g_flg_available
                                          AND ad_st.flg_available = g_flg_available),
                                       0) id_sample_type,
                                   nvl((SELECT a_bs.id_body_structure
                                         FROM body_structure a_bs
                                         JOIN ad_body_structure ad_bs
                                           ON a_bs.id_content = ad_bs.id_content
                                        WHERE ad_bs.id_body_structure = ad_abs.id_body_structure
                                          AND a_bs.flg_available = g_flg_available
                                          AND ad_bs.flg_available = g_flg_available),
                                       0) id_body_structure
                              FROM ad_analysis_body_structure ad_abs
                            --dup code -- see nvl
                             WHERE ad_abs.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_analysis > 0
                       AND temp_data.id_sample_type > 0
                       AND temp_data.id_body_structure > 0) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM analysis_sample_type a_ast
                     WHERE a_ast.id_analysis = def_data.id_analysis
                       AND a_ast.id_sample_type = def_data.id_sample_type
                       AND a_ast.flg_available = g_flg_available)
               AND NOT EXISTS (SELECT 0
                      FROM analysis_body_structure a_abs
                     WHERE a_abs.flg_available = g_flg_available
                       AND a_abs.id_analysis = def_data.id_analysis
                       AND a_abs.id_sample_type = def_data.id_sample_type
                       AND a_abs.id_body_structure = def_data.id_body_structure);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_bs_def;

    /********************************************************************************************
    * Get Default Configuration on Analysis and Complaint Relation
    *
    * @param i_lang                Prefered language ID
    * @param o_labcmpl             Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/

    FUNCTION load_analysis_complaint_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('LOAD_ANALYSIS_COMPLAINT_DEF');
        g_error     := 'OPEN CONFIGURATION CURSOR';
    
        INSERT INTO lab_tests_complaint
            (id_analysis, id_complaint, flg_available, id_sample_type)
            SELECT def_data.id_analysis, def_data.id_complaint, g_flg_available, def_data.id_sample_type
              FROM (SELECT temp_data.l_row,
                           temp_data.id_analysis,
                           temp_data.id_sample_type,
                           temp_data.id_complaint,
                           row_number() over(PARTITION BY temp_data.id_analysis, temp_data.id_sample_type, temp_data.id_complaint ORDER BY temp_data.l_row) records_count
                      FROM (SELECT ad_ltc.rowid l_row,
                                   nvl((SELECT a_a.id_analysis
                                         FROM analysis a_a
                                         JOIN ad_analysis ad_a
                                           ON a_a.id_content = ad_a.id_content
                                        WHERE ad_a.id_analysis = ad_ltc.id_analysis
                                          AND a_a.flg_available = g_flg_available
                                          AND ad_a.flg_available = g_flg_available),
                                       0) id_analysis,
                                   nvl((SELECT a_st.id_sample_type
                                         FROM sample_type a_st
                                         JOIN ad_sample_type ad_st
                                           ON a_st.id_content = ad_st.id_content
                                        WHERE ad_st.id_sample_type = ad_ltc.id_sample_type
                                          AND a_st.flg_available = g_flg_available
                                          AND ad_st.flg_available = g_flg_available),
                                       0) id_sample_type,
                                   nvl((SELECT a_c.id_complaint
                                         FROM complaint a_c
                                         JOIN ad_complaint ad_c
                                           ON ad_c.id_content = a_c.id_content
                                        WHERE ad_c.id_complaint = ad_ltc.id_complaint
                                          AND a_c.flg_available = g_flg_available
                                          AND ad_c.flg_available = 'Y'),
                                       0) id_complaint
                              FROM ad_lab_tests_complaint ad_ltc
                             WHERE ad_ltc.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_analysis > 0
                       AND temp_data.id_sample_type > 0
                       AND temp_data.id_complaint > 0) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM analysis_sample_type ad_ast
                     WHERE ad_ast.id_analysis = def_data.id_analysis
                       AND ad_ast.id_sample_type = def_data.id_sample_type
                       AND ad_ast.flg_available = g_flg_available)
               AND NOT EXISTS (SELECT 0
                      FROM lab_tests_complaint a_ltc
                     WHERE a_ltc.id_analysis = def_data.id_analysis
                       AND a_ltc.id_sample_type = def_data.id_sample_type
                       AND a_ltc.id_complaint = def_data.id_complaint
                       AND a_ltc.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_complaint_def;

    /********************************************************************************************
      * Set Default calculators for Analysis parameters
    *
    * @param i_lang                   Prefered language ID
    * @param o_analysis_res_calc      Analysis calculations
    * @param o_error                  Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      LCRS
    * @version                     2.6.1.14
    * @since                       2012/02/28
    ********************************************************************************************/

    FUNCTION load_analysis_res_calcs_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        INSERT INTO analysis_res_calculator
            (id_analysis_res_calc, id_analysis_parameter, internal_name)
            SELECT def_data.id_analysis_res_calc, def_data.id_analysis_parameter, def_data.internal_name
              FROM (SELECT ad_arc.id_analysis_res_calc,
                           nvl((SELECT a_ap.id_analysis_parameter
                                 FROM analysis_parameter a_ap
                                 JOIN ad_analysis_parameter ad_ap
                                   ON a_ap.id_content = ad_ap.id_content
                                WHERE ad_ap.id_analysis_parameter = ad_arc.id_analysis_parameter
                                  AND ad_ap.flg_available = g_flg_available
                                  AND a_ap.flg_available = g_flg_available
                                  AND rownum = 1),
                               0) id_analysis_parameter,
                           ad_arc.internal_name
                      FROM ad_analysis_res_calculator ad_arc) def_data
             WHERE def_data.id_analysis_parameter > 0
               AND NOT EXISTS (SELECT 0
                      FROM analysis_res_calculator a_arc
                     WHERE a_arc.id_analysis_res_calc = def_data.id_analysis_res_calc);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'LOAD_ANALYSIS_RES_CALCS_DEF',
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_res_calcs_def;
    /********************************************************************************************
    * Set Default calculators for Analysis results
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis_res_par_calc Analysis Parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      LCRS
    * @version                     2.6.1.14
    * @since                       2012/02/29
    ********************************************************************************************/

    FUNCTION load_ana_res_par_calcs_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        INSERT INTO analysis_res_par_calc
            (id_analysis_res_calc, id_analysis_parameter, order_num)
            SELECT def_data.id_analysis_res_calc, def_data.id_analysis_parameter, def_data.order_num
              FROM (SELECT nvl((SELECT a_ap.id_analysis_parameter
                                 FROM analysis_parameter a_ap
                                 JOIN ad_analysis_parameter ad_ap
                                   ON a_ap.id_content = ad_ap.id_content
                                WHERE ad_ap.id_analysis_parameter = ad_arpc.id_analysis_parameter
                                  AND ad_ap.flg_available = g_flg_available
                                  AND a_ap.flg_available = g_flg_available
                                  AND rownum = 1),
                               0) id_analysis_parameter,
                           nvl((SELECT a_arc.id_analysis_res_calc
                                 FROM analysis_res_calculator a_arc
                                WHERE a_arc.id_analysis_res_calc = ad_arpc.id_analysis_res_calc
                                  AND rownum = 1),
                               0) id_analysis_res_calc,
                           ad_arpc.order_num
                      FROM ad_analysis_res_par_calc ad_arpc) def_data
             WHERE def_data.id_analysis_res_calc > 0
               AND def_data.id_analysis_parameter > 0
               AND NOT EXISTS (SELECT 0
                      FROM analysis_res_par_calc a_arpc
                     WHERE a_arpc.id_analysis_parameter = def_data.id_analysis_parameter
                       AND a_arpc.id_analysis_res_calc = def_data.id_analysis_res_calc);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'LOAD_ANA_RES_PAR_CALCS_DEF',
                                              o_error);
            RETURN FALSE;
        
    END load_ana_res_par_calcs_def;

    /* RMGM added in v2.6.4.0.3 new content table ALERT-285529*/
    FUNCTION load_analysis_spec_cond_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('ANALYSIS_SPECIMEN_CONDITION.CODE_SPECIMEN_CONDITION.');
    
    BEGIN
    
        g_func_name := upper('LOAD_ANALYSIS_SPEC_COND_DEF');
    
        INSERT INTO analysis_specimen_condition
            (id_specimen_condition, VALUE, code_specimen_condition, id_content, inst_owner, flg_available)
            SELECT seq_analysis_spec_condition.nextval,
                   def_data.value,
                   l_code_translation || seq_analysis_spec_condition.currval,
                   def_data.id_content,
                   0,
                   'Y'
              FROM (SELECT ad_asc.value, ad_asc.id_content
                      FROM ad_analysis_specimen_condition ad_asc
                     WHERE ad_asc.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM analysis_specimen_condition a_asc
                             WHERE a_asc.id_content = ad_asc.id_content
                               AND a_asc.flg_available = g_flg_available)) def_data;
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'LOAD_ANALYSIS_SPEC_COND_DEF',
                                              o_error);
            RETURN FALSE;
        
    END load_analysis_spec_cond_def;

    -- searcheable loader method
    FUNCTION set_analysis_ci_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_ANALYSIS_CI_SEARCH');
    
        INSERT INTO analysis_collection_int
            (id_analysis_collection_int,
             id_analysis_collection,
             order_collection,
             INTERVAL,
             flg_available,
             id_sample_recipient)
            SELECT seq_analysis_collection_int.nextval,
                   def_data.id_analysis_collection,
                   def_data.order_collection,
                   def_data.interval,
                   g_flg_available,
                   def_data.id_sample_recipient
              FROM (SELECT temp_data.id_analysis_collection,
                           temp_data.order_collection,
                           temp_data.interval,
                           temp_data.id_sample_recipient,
                           row_number() over(PARTITION BY temp_data.id_analysis_collection, temp_data.id_sample_recipient, temp_data.order_collection ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT -- decode FKS to dest_vals
                             nvl((SELECT a_ac.id_analysis_collection
                                   FROM analysis_sample_type a_ast
                                   JOIN analysis_instit_soft a_ais
                                     ON a_ais.id_analysis = a_ast.id_analysis
                                    AND a_ais.id_sample_type = a_ast.id_sample_type
                                    AND a_ais.id_software = i_software(pos_soft)
                                    AND a_ais.id_institution = i_institution
                                    AND a_ais.flg_available = g_flg_available
                                   JOIN analysis_collection a_ac
                                     ON a_ac.id_analysis_instit_soft = a_ais.id_analysis_instit_soft
                                    AND a_ac.flg_available = g_flg_available
                                  WHERE a_ast.id_content = ad_ast.id_content
                                    AND a_ais.flg_type = ad_ais.flg_type),
                                 0) id_analysis_collection,
                             ad_aci.order_collection,
                             ad_aci.interval,
                             decode(ad_aci.id_sample_recipient,
                                    NULL,
                                    NULL,
                                    nvl((SELECT a_sr.id_sample_recipient
                                          FROM sample_recipient a_sr
                                          JOIN ad_sample_recipient ad_sr
                                            ON ad_sr.id_content = a_sr.id_content
                                         WHERE a_sr.flg_available = g_flg_available
                                           AND ad_sr.id_sample_recipient = ad_aci.id_sample_recipient),
                                        0)) id_sample_recipient,
                             ad_ais.id_software,
                             ad_amv.id_market,
                             ad_amv.version
                              FROM ad_analysis_collection_int ad_aci
                              JOIN ad_analysis_collection ad_ac
                                ON ad_ac.id_analysis_collection = ad_aci.id_analysis_collection
                               AND ad_ac.flg_available = g_flg_available
                              JOIN ad_analysis_instit_soft ad_ais
                                ON ad_ais.id_analysis_instit_soft = ad_ac.id_analysis_instit_soft
                               AND ad_ais.flg_available = g_flg_available
                              JOIN ad_analysis_sample_type ad_ast
                                ON ad_ast.id_analysis = ad_ais.id_analysis
                               AND ad_ast.id_sample_type = ad_ais.id_sample_type
                                  --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                               AND ((ad_ast.id_content IN (SELECT *
                                                             FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                   l_cnt_count = 0)
                               AND ad_ast.flg_available = g_flg_available
                              JOIN ad_ast_mkt_vrs ad_amv
                                ON ad_amv.id_content = ad_ast.id_content
                             WHERE ad_ais.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_amv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_amv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_analysis_collection > 0
                       AND temp_data.id_sample_recipient > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS
             (SELECT 0
                      FROM analysis_collection_int a_aci
                     WHERE a_aci.id_analysis_collection = def_data.id_analysis_collection
                       AND (a_aci.id_sample_recipient = def_data.id_sample_recipient OR
                           (a_aci.id_sample_recipient IS NULL AND def_data.id_sample_recipient IS NULL)));
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_ci_search;

    FUNCTION del_analysis_ci_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete analysis_collection_int';
        g_func_name := upper('DEL_ANALYSIS_CI_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM analysis_collection_int a_aci
             WHERE EXISTS (SELECT 1
                      FROM analysis_collection a_ac
                     WHERE a_aci.id_analysis_collection = a_ac.id_analysis_collection
                       AND EXISTS (SELECT 1
                              FROM analysis_instit_soft a_ais
                             WHERE a_ais.id_analysis_instit_soft = a_ac.id_analysis_instit_soft
                               AND a_ais.id_institution = i_institution
                               AND a_ais.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)));
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM analysis_collection_int a_aci
             WHERE EXISTS (SELECT 1
                      FROM analysis_collection a_ac
                     WHERE a_aci.id_analysis_collection = a_ac.id_analysis_collection
                       AND EXISTS (SELECT 1
                              FROM analysis_instit_soft a_ais
                             WHERE a_ais.id_analysis_instit_soft = a_ac.id_analysis_instit_soft
                               AND a_ais.id_institution = i_institution));
        
            o_result_tbl := SQL%ROWCOUNT;
        
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
                                              g_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END del_analysis_ci_search;

    FUNCTION set_analysis_collection_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_ANALYSIS_COLLECTION_SEARCH');
    
        INSERT INTO analysis_collection
            (id_analysis_collection,
             id_analysis_instit_soft,
             num_collection,
             flg_interval_type,
             flg_status,
             flg_available)
            SELECT seq_analysis_collection.nextval,
                   def_data.id_analysis_instit_soft,
                   def_data.num_collection,
                   def_data.flg_interval_type,
                   def_data.flg_status,
                   g_flg_available
              FROM (SELECT temp_data.id_analysis_instit_soft,
                           temp_data.num_collection,
                           temp_data.flg_interval_type,
                           temp_data.flg_status,
                           row_number() over(PARTITION BY temp_data.id_analysis_instit_soft ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT -- decode FKS to dest_vals
                             nvl((SELECT a_ais.id_analysis_instit_soft
                                   FROM analysis_sample_type a_ast
                                   JOIN analysis_instit_soft a_ais
                                     ON a_ais.id_analysis = a_ast.id_analysis
                                    AND a_ais.id_sample_type = a_ast.id_sample_type
                                    AND a_ais.id_software = i_software(pos_soft)
                                    AND a_ais.id_institution = i_institution
                                  WHERE a_ast.id_content = ad_ast.id_content
                                    AND a_ais.flg_type = ad_ais.flg_type
                                    AND a_ais.flg_available = g_flg_available),
                                 0) id_analysis_instit_soft,
                             ad_ac.num_collection,
                             ad_ac.flg_interval_type,
                             ad_ac.flg_status,
                             ad_ais.id_software,
                             ad_amv.id_market,
                             ad_amv.version
                              FROM ad_analysis_collection ad_ac
                              JOIN ad_analysis_instit_soft ad_ais
                                ON ad_ais.id_analysis_instit_soft = ad_ac.id_analysis_instit_soft
                              JOIN ad_analysis_sample_type ad_ast
                                ON ad_ast.id_analysis = ad_ais.id_analysis
                               AND ad_ast.id_sample_type = ad_ais.id_sample_type
                               AND ad_ast.flg_available = g_flg_available
                                  --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                               AND ((ad_ast.id_content IN (SELECT *
                                                             FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                   l_cnt_count = 0)
                              JOIN ad_ast_mkt_vrs ad_amv
                                ON ad_amv.id_content = ad_ast.id_content
                             WHERE ad_ac.flg_available = g_flg_available
                               AND ad_ais.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_amv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_amv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_analysis_instit_soft > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM analysis_collection a_ac
                     WHERE a_ac.id_analysis_instit_soft = def_data.id_analysis_instit_soft);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_collection_search;

    FUNCTION del_analysis_collection_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete analysis_collection';
        g_func_name := upper('DEL_ANALYSIS_COLLECTION_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM analysis_collection a_ac
             WHERE EXISTS
             (SELECT 1
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis_instit_soft = a_ac.id_analysis_instit_soft
                       AND a_ais.id_institution = i_institution
                       AND a_ais.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                  column_value
                                                   FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM analysis_collection a_ac
             WHERE EXISTS (SELECT 1
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis_instit_soft = a_ac.id_analysis_instit_soft
                       AND a_ais.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        
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
                                              g_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END del_analysis_collection_search;

    FUNCTION set_analysis_um_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_ANALYSIS_UM_SEARCH');
    
        INSERT INTO analysis_unit_measure
            (id_analysis_unit_measure,
             id_analysis,
             id_unit_measure,
             id_analysis_parameter,
             val_min,
             val_max,
             format_num,
             decimals,
             flg_default,
             val_min_str,
             val_max_str,
             gender,
             age_min,
             age_max,
             id_sample_text,
             id_institution,
             id_software,
             id_sample_type)
            SELECT seq_analysis_unit_measure.nextval,
                   def_data.id_analysis,
                   def_data.id_unit_measure,
                   def_data.id_analysis_parameter,
                   def_data.val_min,
                   def_data.val_max,
                   def_data.format_num,
                   def_data.decimals,
                   def_data.flg_default,
                   def_data.val_min_str,
                   def_data.val_max_str,
                   def_data.gender,
                   def_data.age_min,
                   def_data.age_max,
                   def_data.id_sample_text,
                   i_institution,
                   i_software(pos_soft),
                   def_data.id_sample_type
              FROM (SELECT temp_data.id_analysis,
                           temp_data.id_unit_measure,
                           temp_data.id_analysis_parameter,
                           temp_data.val_min,
                           temp_data.val_max,
                           temp_data.format_num,
                           temp_data.decimals,
                           temp_data.flg_default,
                           temp_data.val_min_str,
                           temp_data.val_max_str,
                           temp_data.gender,
                           temp_data.age_min,
                           temp_data.age_max,
                           temp_data.id_sample_text,
                           temp_data.id_sample_type,
                           row_number() over(PARTITION BY temp_data.id_analysis, temp_data.id_sample_type, temp_data.id_analysis_parameter, temp_data.id_unit_measure, temp_data.gender, temp_data.age_min, temp_data.age_max, temp_data.id_sample_text ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_a.id_analysis
                                         FROM analysis a_a
                                         JOIN ad_analysis ad_a
                                           ON a_a.id_content = ad_a.id_content
                                          AND ad_a.flg_available = g_flg_available
                                        WHERE a_a.flg_available = g_flg_available
                                          AND ad_a.id_analysis = ad_aum.id_analysis),
                                       0) id_analysis,
                                   decode(ad_aum.id_unit_measure,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_um.id_unit_measure
                                                FROM unit_measure a_um
                                               WHERE a_um.flg_available = g_flg_available
                                                 AND a_um.id_unit_measure = ad_aum.id_unit_measure),
                                              -1)) id_unit_measure,
                                   decode(ad_aum.id_analysis_parameter,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_ap.id_analysis_parameter
                                                FROM analysis_parameter a_ap
                                                JOIN ad_analysis_parameter ad_ap
                                                  ON ad_ap.id_content = a_ap.id_content
                                                 AND ad_ap.flg_available = g_flg_available
                                               WHERE a_ap.flg_available = g_flg_available
                                                 AND ad_ap.id_analysis_parameter = ad_aum.id_analysis_parameter),
                                              0)) id_analysis_parameter,
                                   ad_aum.val_min,
                                   ad_aum.val_max,
                                   ad_aum.format_num,
                                   ad_aum.decimals,
                                   ad_aum.flg_default,
                                   ad_aum.val_min_str,
                                   ad_aum.val_max_str,
                                   ad_aum.gender,
                                   ad_aum.age_min,
                                   ad_aum.age_max,
                                   ad_aum.id_sample_text,
                                   nvl((SELECT a_st.id_sample_type
                                         FROM sample_type a_st
                                         JOIN ad_sample_type ad_st
                                           ON ad_st.id_content = a_st.id_content
                                          AND ad_st.flg_available = g_flg_available
                                        WHERE a_st.flg_available = g_flg_available
                                          AND ad_st.id_sample_type = ad_aum.id_sample_type),
                                       0) id_sample_type,
                                   ad_aum.id_software,
                                   ad_amv.id_market,
                                   ad_amv.version
                            -- decode FKS to dest_vals
                              FROM ad_analysis_unit_measure ad_aum
                              JOIN ad_analysis_sample_type ad_ast
                                ON ad_ast.id_analysis = ad_aum.id_analysis
                               AND ad_ast.id_sample_type = ad_aum.id_sample_type
                               AND ad_ast.flg_available = g_flg_available
                                  --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                               AND ((ad_ast.id_content IN (SELECT *
                                                             FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                   l_cnt_count = 0)
                              JOIN ad_ast_mkt_vrs ad_amv
                                ON ad_amv.id_content = ad_ast.id_content
                             WHERE ad_aum.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_amv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_amv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_sample_type > 0
                       AND temp_data.id_analysis > 0
                       AND (temp_data.id_unit_measure > 0 OR temp_data.id_unit_measure IS NULL)
                       AND (temp_data.id_analysis_parameter > 0 OR temp_data.id_analysis_parameter IS NULL)) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM analysis_sample_type a_ast
                     WHERE a_ast.id_analysis = def_data.id_analysis
                       AND a_ast.id_sample_type = def_data.id_sample_type
                       AND a_ast.flg_available = g_flg_available)
               AND NOT EXISTS
             (SELECT 0
                      FROM analysis_unit_measure a_aum
                     WHERE a_aum.id_software = i_software(pos_soft)
                       AND a_aum.id_institution = i_institution
                       AND a_aum.id_analysis = def_data.id_analysis
                       AND (a_aum.id_analysis_parameter = def_data.id_analysis_parameter OR
                           (a_aum.id_analysis_parameter IS NULL AND def_data.id_analysis_parameter IS NULL))
                       AND a_aum.id_unit_measure = def_data.id_unit_measure
                       AND a_aum.id_sample_type = def_data.id_sample_type);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_um_search;

    FUNCTION del_analysis_um_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete analysis_unit_measure';
        g_func_name := upper('DEL_ANALYSIS_UM_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM analysis_unit_measure a_aum
             WHERE a_aum.id_institution = i_institution
               AND a_aum.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM analysis_unit_measure a_aum
             WHERE a_aum.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
        
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
                                              g_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END del_analysis_um_search;

    FUNCTION set_analysis_loinc_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_ANALYSIS_LOINC_SEARCH');
    
        INSERT INTO analysis_loinc
            (id_analysis_loinc, id_analysis, loinc_code, flg_default, id_institution, id_software, id_sample_type)
            SELECT seq_analysis_loinc.nextval,
                   def_data.id_analysis,
                   def_data.loinc_code,
                   def_data.flg_default,
                   i_institution,
                   i_software(pos_soft),
                   def_data.id_sample_type
              FROM (SELECT temp_data.id_analysis,
                           temp_data.loinc_code,
                           temp_data.flg_default,
                           temp_data.id_sample_type,
                           row_number() over(PARTITION BY temp_data.id_analysis, temp_data.id_sample_type, temp_data.loinc_code, temp_data.flg_default ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT /*+ index(al ALC_S_FK_I) index(ast AST_ST_IDX) index(ast AST_ANL_IDX) index(ast AST_AVL_IDX)*/
                             nvl((SELECT a_a.id_analysis
                                   FROM analysis a_a
                                   JOIN ad_analysis ad_a
                                     ON a_a.id_content = ad_a.id_content
                                    AND ad_a.flg_available = g_flg_available
                                  WHERE a_a.flg_available = g_flg_available
                                    AND ad_a.id_analysis = ad_al.id_analysis),
                                 0) id_analysis,
                             ad_al.loinc_code,
                             ad_al.flg_default,
                             nvl((SELECT a_st.id_sample_type
                                   FROM sample_type a_st
                                   JOIN ad_sample_type ad_st
                                     ON ad_st.id_content = a_st.id_content
                                    AND ad_st.flg_available = g_flg_available
                                  WHERE a_st.flg_available = g_flg_available
                                    AND ad_st.id_sample_type = ad_al.id_sample_type),
                                 0) id_sample_type,
                             ad_amv.id_market,
                             ad_amv.version,
                             ad_al.id_software
                              FROM ad_analysis_loinc ad_al
                              JOIN ad_analysis_sample_type ad_ast
                                ON ad_ast.id_analysis = ad_al.id_analysis
                               AND ad_ast.id_sample_type = ad_al.id_sample_type
                               AND ad_ast.flg_available = g_flg_available
                                  --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                               AND ((ad_ast.id_content IN (SELECT *
                                                             FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                   l_cnt_count = 0)
                              JOIN ad_ast_mkt_vrs ad_amv
                                ON ad_amv.id_content = ad_ast.id_content
                               AND ad_amv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_amv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_al.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)) temp_data
                     WHERE temp_data.id_analysis > 0
                       AND temp_data.id_sample_type > 0) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM analysis_sample_type a_ast
                     WHERE a_ast.id_analysis = def_data.id_analysis
                       AND a_ast.id_sample_type = def_data.id_sample_type
                       AND a_ast.flg_available = g_flg_available)
               AND NOT EXISTS (SELECT 0
                      FROM analysis_loinc a_al
                     WHERE a_al.id_analysis = def_data.id_analysis
                       AND a_al.id_sample_type = def_data.id_sample_type
                       AND a_al.id_institution = i_institution
                       AND a_al.id_software = i_software(pos_soft)
                       AND a_al.flg_default = def_data.flg_default);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_loinc_search;

    FUNCTION del_analysis_loinc_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete analysis_loinc';
        g_func_name := upper('DEL_ANALYSIS_LOINC_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM analysis_loinc a_al
             WHERE a_al.id_institution = i_institution
               AND a_al.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM analysis_loinc a_al
             WHERE a_al.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
        
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
                                              g_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END del_analysis_loinc_search;

    FUNCTION set_analysis_pf_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_ANALYSIS_PF_SEARCH');
    
        INSERT INTO analysis_param_funcionality
            (id_analysis_param_funcionality, id_analysis_param, flg_type, flg_fill_type, rank)
            SELECT seq_analysis_param_func.nextval,
                   def_data.id_analysis_param,
                   def_data.flg_type,
                   def_data.flg_fill_type,
                   0 AS rank
              FROM (SELECT temp_data.id_analysis_param,
                           temp_data.flg_type,
                           temp_data.flg_fill_type,
                           row_number() over(PARTITION BY temp_data.id_analysis_param, temp_data.flg_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_ap.id_analysis_param
                                         FROM analysis_param a_ap
                                         JOIN analysis_sample_type a_ast
                                           ON a_ap.id_analysis = a_ast.id_analysis
                                          AND a_ap.id_sample_type = a_ast.id_sample_type
                                          AND a_ast.flg_available = g_flg_available
                                        WHERE a_ast.id_content = ad_ast.id_content
                                          AND a_ap.id_analysis_parameter = a_apm.id_analysis_parameter
                                          AND a_ap.id_software = i_software(pos_soft)
                                          AND a_ap.id_institution = i_institution
                                          AND a_ap.flg_available = g_flg_available),
                                       0) id_analysis_param,
                                   ad_apf.flg_type,
                                   ad_apf.flg_fill_type,
                                   a_apm.id_analysis_parameter,
                                   ad_ast.id_content,
                                   ad_ap.id_software,
                                   ad_amv.id_market,
                                   ad_amv.version
                              FROM ad_analysis_param ad_ap
                              JOIN ad_analysis_param_funcionality ad_apf
                                ON ad_apf.id_analysis_param = ad_ap.id_analysis_param
                              JOIN ad_analysis_sample_type ad_ast
                                ON ad_ast.id_analysis = ad_ap.id_analysis
                               AND ad_ast.id_sample_type = ad_ap.id_sample_type
                               AND ad_ast.flg_available = g_flg_available
                                  --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                               AND ((ad_ast.id_content IN (SELECT *
                                                             FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                   l_cnt_count = 0)
                              JOIN ad_ast_mkt_vrs ad_amv
                                ON ad_amv.id_content = ad_ast.id_content
                              JOIN ad_analysis_parameter ad_apm
                                ON ad_apm.id_analysis_parameter = ad_ap.id_analysis_parameter
                               AND ad_apm.flg_available = g_flg_available
                              JOIN analysis_parameter a_apm
                                ON a_apm.id_content = ad_apm.id_content
                               AND a_apm.flg_available = g_flg_available
                             WHERE ad_ap.flg_available = g_flg_available
                               AND ad_ap.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_amv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_amv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_analysis_param > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM analysis_param_funcionality a_apf
                     WHERE a_apf.id_analysis_param = def_data.id_analysis_param
                       AND a_apf.flg_type = def_data.flg_type);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_pf_search;

    FUNCTION del_analysis_pf_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete analysis_param_funcionality';
        g_func_name := upper('DEL_ANALYSIS_PF_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM analysis_param_funcionality a_apf
             WHERE EXISTS
             (SELECT 1
                      FROM analysis_param a_ap
                     WHERE a_ap.id_analysis_param = a_apf.id_analysis_param
                       AND a_ap.id_institution = i_institution
                       AND a_ap.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                 column_value
                                                  FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM analysis_param_funcionality a_apf
             WHERE EXISTS (SELECT 1
                      FROM analysis_param a_ap
                     WHERE a_ap.id_analysis_param = a_apf.id_analysis_param
                       AND a_ap.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        
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
                                              g_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END del_analysis_pf_search;

    FUNCTION set_analysis_ir_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        INSERT INTO analysis_instit_recipient
            (id_analysis_instit_recipient,
             id_analysis_instit_soft,
             id_sample_recipient,
             flg_default,
             /*ALERT-288259 Added these columns*/
             qty_harvest,
             num_recipient)
            SELECT seq_analysis_instit_recipient.nextval,
                   def_data.id_analysis_instit_soft,
                   def_data.id_sample_recipient,
                   def_data.flg_default,
                   def_data.qty_harvest,
                   def_data.num_recipient
              FROM (SELECT temp_data.id_analysis_instit_soft,
                           temp_data.id_sample_recipient,
                           nvl((SELECT decode(a_air1.flg_default, g_flg_available, 'N', temp_data.flg_default)
                                 FROM analysis_instit_recipient a_air1
                                WHERE a_air1.id_analysis_instit_soft = temp_data.id_analysis_instit_soft
                                  AND a_air1.flg_default = g_flg_available),
                               temp_data.flg_default) flg_default,
                           temp_data.qty_harvest,
                           temp_data.num_recipient,
                           row_number() over(PARTITION BY temp_data.id_analysis_instit_soft, temp_data.id_sample_recipient ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT a_ais.id_analysis_instit_soft,
                                   a_sr.id_sample_recipient,
                                   ad_air.flg_default,
                                   ad_air.qty_harvest,
                                   ad_air.num_recipient,
                                   ad_ais.id_software,
                                   ad_amv.id_market,
                                   ad_amv.version
                              FROM ad_analysis_instit_recipient ad_air
                              JOIN ad_analysis_instit_soft ad_ais
                                ON ad_air.id_analysis_instit_soft = ad_ais.id_analysis_instit_soft
                               AND ad_ais.flg_available = g_flg_available
                              JOIN ad_analysis_sample_type ad_ast
                                ON ad_ast.id_analysis = ad_ais.id_analysis
                               AND ad_ast.id_sample_type = ad_ais.id_sample_type
                               AND ad_ast.flg_available = g_flg_available
                                  --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                               AND ((ad_ast.id_content IN (SELECT *
                                                             FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                   l_cnt_count = 0)
                              JOIN ad_ast_mkt_vrs ad_amv
                                ON ad_amv.id_content = ad_ast.id_content
                              JOIN ad_sample_recipient ad_sr
                                ON ad_sr.id_sample_recipient = ad_air.id_sample_recipient
                               AND ad_sr.flg_available = g_flg_available
                              JOIN sample_recipient a_sr
                                ON ad_sr.id_content = a_sr.id_content
                               AND a_sr.flg_available = g_flg_available
                              JOIN analysis_sample_type a_ast
                                ON a_ast.id_content = ad_ast.id_content
                               AND a_ast.flg_available = g_flg_available
                              JOIN analysis_instit_soft a_ais
                                ON a_ais.id_analysis = a_ast.id_analysis
                               AND a_ais.id_sample_type = a_ast.id_sample_type
                               AND a_ais.flg_type = ad_ais.flg_type
                               AND a_ais.id_software = i_software(pos_soft)
                               AND a_ais.id_institution = i_institution
                               AND a_ais.flg_available = g_flg_available
                             WHERE ad_ais.flg_available = g_flg_available
                               AND ad_amv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_amv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_ais.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)) temp_data
                     WHERE temp_data.id_sample_recipient > 0
                       AND temp_data.id_analysis_instit_soft > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM analysis_instit_recipient a_air
                     WHERE a_air.id_analysis_instit_soft = def_data.id_analysis_instit_soft
                       AND a_air.id_sample_recipient = def_data.id_sample_recipient);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_ir_search;

    FUNCTION del_analysis_ir_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete analysis_instit_recipient';
        g_func_name := upper('DEL_ANALYSIS_IR_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM analysis_instit_recipient a_air
             WHERE EXISTS
             (SELECT 1
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis_instit_soft = a_air.id_analysis_instit_soft
                       AND a_ais.id_institution = i_institution
                       AND a_ais.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                  column_value
                                                   FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM analysis_instit_recipient a_air
             WHERE EXISTS (SELECT 1
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis_instit_soft = a_air.id_analysis_instit_soft
                       AND a_ais.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        
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
                                              g_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END del_analysis_ir_search;

    FUNCTION set_analysis_is_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_ANALYSIS_IS_SEARCH');
    
        INSERT INTO analysis_instit_soft
            (id_analysis_instit_soft,
             id_analysis,
             id_exam_cat,
             flg_type,
             flg_mov_pat,
             flg_first_result,
             flg_mov_recipient,
             flg_harvest,
             rank,
             cost,
             price,
             flg_execute,
             flg_justify,
             flg_interface,
             flg_chargeable,
             id_institution,
             id_software,
             flg_available,
             id_sample_type,
             flg_category_type)
            SELECT seq_analysis_instit_soft.nextval,
                   def_data.id_analysis,
                   def_data.id_exam_cat,
                   def_data.flg_type,
                   def_data.flg_mov_pat,
                   def_data.flg_first_result,
                   def_data.flg_mov_recipient,
                   def_data.flg_harvest,
                   def_data.rank,
                   def_data.cost,
                   def_data.price,
                   def_data.flg_execute,
                   def_data.flg_justify,
                   def_data.flg_interface,
                   def_data.flg_chargeable,
                   i_institution,
                   i_software(pos_soft),
                   g_flg_available,
                   def_data.id_sample_type,
                   def_data.flg_category_type
              FROM (SELECT temp_data.id_analysis,
                           temp_data.id_exam_cat,
                           temp_data.flg_type,
                           temp_data.flg_mov_pat,
                           temp_data.flg_first_result,
                           temp_data.flg_mov_recipient,
                           temp_data.flg_harvest,
                           temp_data.rank,
                           temp_data.cost,
                           temp_data.price,
                           temp_data.flg_execute,
                           temp_data.flg_justify,
                           temp_data.flg_interface,
                           temp_data.flg_chargeable,
                           temp_data.flg_available,
                           temp_data.id_sample_type,
                           temp_data.flg_category_type,
                           row_number() over(PARTITION BY temp_data.id_analysis, temp_data.id_sample_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_a.id_analysis
                                         FROM analysis a_a
                                         JOIN ad_analysis ad_a
                                           ON ad_a.id_content = a_a.id_content
                                          AND ad_a.flg_available = g_flg_available
                                        WHERE ad_a.id_analysis = ad_ais.id_analysis
                                          AND a_a.flg_available = g_flg_available),
                                       0) id_analysis,
                                   nvl((SELECT a_ec.id_exam_cat
                                         FROM exam_cat a_ec
                                         JOIN ad_exam_cat ad_ec
                                           ON ad_ec.id_content = a_ec.id_content
                                          AND ad_ec.flg_available = g_flg_available
                                        WHERE ad_ec.id_exam_cat = ad_ais.id_exam_cat
                                          AND a_ec.flg_available = g_flg_available),
                                       0) id_exam_cat,
                                   ad_ais.flg_type,
                                   ad_ais.flg_mov_pat,
                                   ad_ais.flg_first_result,
                                   ad_ais.flg_mov_recipient,
                                   ad_ais.flg_harvest,
                                   ad_ais.rank,
                                   ad_ais.cost,
                                   ad_ais.price,
                                   ad_ais.flg_execute,
                                   ad_ais.flg_justify,
                                   ad_ais.flg_interface,
                                   ad_ais.flg_chargeable,
                                   ad_ais.flg_available,
                                   nvl((SELECT a_st.id_sample_type
                                         FROM sample_type a_st
                                         JOIN ad_sample_type ad_st
                                           ON ad_st.id_content = a_st.id_content
                                          AND ad_st.flg_available = g_flg_available
                                        WHERE ad_st.id_sample_type = ad_ais.id_sample_type
                                          AND a_st.flg_available = g_flg_available),
                                       0) id_sample_type,
                                   ad_ais.flg_category_type,
                                   ad_ais.id_software,
                                   ad_amv.id_market,
                                   ad_amv.version
                            -- decode FKS to dest_vals
                              FROM ad_analysis_instit_soft ad_ais
                              JOIN ad_analysis_sample_type ad_ast
                                ON ad_ast.id_analysis = ad_ais.id_analysis
                               AND ad_ast.id_sample_type = ad_ais.id_sample_type
                               AND ad_ast.flg_available = g_flg_available
                                  --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                               AND ((ad_ast.id_content IN (SELECT *
                                                             FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                   l_cnt_count = 0)
                              JOIN ad_ast_mkt_vrs ad_amv
                                ON ad_amv.id_content = ad_ast.id_content
                             WHERE ad_ais.flg_available = g_flg_available
                               AND ad_ais.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_amv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_amv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_sample_type > 0
                       AND temp_data.id_analysis > 0
                       AND temp_data.id_exam_cat > 0) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM analysis_sample_type a_ast
                     WHERE a_ast.id_analysis = def_data.id_analysis
                       AND a_ast.id_sample_type = def_data.id_sample_type
                       AND a_ast.flg_available = g_flg_available)
               AND NOT EXISTS (SELECT 0
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis = def_data.id_analysis
                       AND a_ais.id_sample_type = def_data.id_sample_type
                       AND a_ais.id_institution = i_institution
                       AND a_ais.id_software = i_software(pos_soft));
    
        o_result_tbl := SQL%ROWCOUNT;
    
        INSERT INTO analysis_instit_soft
            (id_analysis_instit_soft,
             id_analysis_group,
             flg_type,
             flg_mov_pat,
             flg_first_result,
             flg_mov_recipient,
             flg_harvest,
             rank,
             cost,
             price,
             flg_execute,
             flg_justify,
             flg_interface,
             flg_chargeable,
             id_institution,
             id_software,
             flg_available,
             flg_category_type)
            SELECT seq_analysis_instit_soft.nextval,
                   def_data.id_analysis_group,
                   def_data.flg_type,
                   def_data.flg_mov_pat,
                   def_data.flg_first_result,
                   def_data.flg_mov_recipient,
                   def_data.flg_harvest,
                   def_data.rank,
                   def_data.cost,
                   def_data.price,
                   def_data.flg_execute,
                   def_data.flg_justify,
                   def_data.flg_interface,
                   def_data.flg_chargeable,
                   i_institution,
                   i_software(pos_soft),
                   g_flg_available,
                   def_data.flg_category_type
              FROM (SELECT temp_data.id_analysis_group,
                           temp_data.flg_type,
                           temp_data.flg_mov_pat,
                           temp_data.flg_first_result,
                           temp_data.flg_mov_recipient,
                           temp_data.flg_harvest,
                           temp_data.rank,
                           temp_data.cost,
                           temp_data.price,
                           temp_data.flg_execute,
                           temp_data.flg_justify,
                           temp_data.flg_interface,
                           temp_data.flg_chargeable,
                           temp_data.flg_available,
                           temp_data.flg_category_type,
                           row_number() over(PARTITION BY temp_data.id_analysis_group ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_ag.id_analysis_group
                                         FROM analysis_group a_ag
                                        WHERE a_ag.id_content = ad_ag.id_content
                                          AND a_ag.flg_available = g_flg_available),
                                       0) id_analysis_group,
                                   ad_ais.flg_type,
                                   ad_ais.flg_mov_pat,
                                   ad_ais.flg_first_result,
                                   ad_ais.flg_mov_recipient,
                                   ad_ais.flg_harvest,
                                   ad_ais.rank,
                                   ad_ais.cost,
                                   ad_ais.price,
                                   ad_ais.flg_execute,
                                   ad_ais.flg_justify,
                                   ad_ais.flg_interface,
                                   ad_ais.flg_chargeable,
                                   ad_ais.flg_available,
                                   ad_ais.flg_category_type,
                                   ad_ais.id_software,
                                   ad_amv.id_market,
                                   ad_amv.version
                              FROM ad_analysis_instit_soft ad_ais
                              JOIN ad_analysis_group_mrk_vrs ad_amv
                                ON ad_amv.id_analysis_group = ad_ais.id_analysis_group
                              JOIN ad_analysis_group ad_ag
                                ON ad_ag.id_analysis_group = ad_ais.id_analysis_group
                                  --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                               AND ((ad_ag.id_content IN (SELECT *
                                                            FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                   l_cnt_count = 0)
                             WHERE ad_ais.flg_available = g_flg_available
                               AND ad_ais.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_amv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_amv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_analysis_group > 0
               AND NOT EXISTS (SELECT 0
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis_group = def_data.id_analysis_group
                       AND a_ais.id_institution = i_institution
                       AND a_ais.id_software = i_software(pos_soft));
    
        o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_is_search;

    FUNCTION del_analysis_is_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete analysis_instit_soft';
        g_func_name := upper('DEL_ANALYSIS_IS_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM ref_analysis_orig_dest a_raod
             WHERE EXISTS
             (SELECT 1
                      FROM analysis_instit_soft a_ais
                     WHERE (a_ais.id_analysis_instit_soft = a_raod.id_analysis_is_orig OR
                           a_ais.id_analysis_instit_soft = a_raod.id_analysis_is_dest)
                       AND a_ais.id_institution = i_institution
                       AND a_ais.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                  column_value
                                                   FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        
            DELETE FROM analysis_room a_ar
             WHERE EXISTS
             (SELECT 1
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis_instit_soft = a_ar.id_analysis_instit_soft
                       AND a_ais.id_institution = i_institution
                       AND a_ais.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                  column_value
                                                   FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
        
            DELETE FROM analysis_param_instit a_api
             WHERE EXISTS
             (SELECT 1
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis_instit_soft = a_api.id_analysis_instit_soft
                       AND a_ais.id_institution = i_institution
                       AND a_ais.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                  column_value
                                                   FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
        
            DELETE FROM analysis_instit_soft a_ais
             WHERE a_ais.id_institution = i_institution
               AND a_ais.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM ref_analysis_orig_dest a_raod
             WHERE EXISTS (SELECT 1
                      FROM analysis_instit_soft a_ais
                     WHERE (a_ais.id_analysis_instit_soft = a_raod.id_analysis_is_orig OR
                           a_ais.id_analysis_instit_soft = a_raod.id_analysis_is_dest)
                       AND a_ais.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        
            DELETE FROM analysis_room a_ar
             WHERE EXISTS (SELECT 1
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis_instit_soft = a_ar.id_analysis_instit_soft
                       AND a_ais.id_institution = i_institution);
        
            o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
        
            DELETE FROM analysis_param_instit a_api
             WHERE EXISTS (SELECT 1
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis_instit_soft = a_api.id_analysis_instit_soft
                       AND a_ais.id_institution = i_institution);
        
            o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
        
            DELETE FROM analysis_instit_soft a_ais
             WHERE a_ais.id_institution = i_institution;
        
            o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
        
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
                                              g_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END del_analysis_is_search;

    FUNCTION set_analysis_param_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_ANALYSIS_PARAM_SEARCH');
    
        INSERT INTO analysis_param
            (id_analysis_param,
             id_analysis,
             id_analysis_parameter,
             color_graph,
             flg_fill_type,
             rank,
             id_institution,
             id_software,
             flg_available,
             id_sample_type)
            SELECT seq_analysis_param.nextval,
                   def_data.id_analysis,
                   def_data.id_analysis_parameter,
                   def_data.color_graph,
                   def_data.flg_fill_type,
                   def_data.rank,
                   i_institution,
                   i_software(pos_soft),
                   g_flg_available,
                   def_data.id_sample_type
              FROM (SELECT temp_data.id_analysis,
                           temp_data.id_analysis_parameter,
                           temp_data.color_graph,
                           temp_data.flg_fill_type,
                           temp_data.rank,
                           temp_data.id_sample_type,
                           row_number() over(PARTITION BY temp_data.id_analysis, temp_data.id_analysis_parameter, temp_data.id_sample_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_a.id_analysis
                                         FROM analysis a_a
                                         JOIN ad_analysis ad_a
                                           ON a_a.id_content = ad_a.id_content
                                          AND ad_a.flg_available = g_flg_available
                                        WHERE ad_a.id_analysis = ad_ap.id_analysis
                                          AND a_a.flg_available = g_flg_available),
                                       0) id_analysis,
                                   nvl((SELECT a_apr.id_analysis_parameter
                                         FROM analysis_parameter a_apr
                                         JOIN ad_analysis_parameter ad_apr
                                           ON ad_apr.id_content = a_apr.id_content
                                          AND ad_apr.flg_available = g_flg_available
                                        WHERE ad_apr.id_analysis_parameter = ad_ap.id_analysis_parameter
                                          AND a_apr.flg_available = g_flg_available),
                                       0) id_analysis_parameter,
                                   ad_ap.color_graph,
                                   ad_ap.flg_fill_type,
                                   ad_ap.rank,
                                   nvl((SELECT a_st.id_sample_type
                                         FROM sample_type a_st
                                         JOIN ad_sample_type ad_st
                                           ON ad_st.id_content = a_st.id_content
                                          AND ad_st.flg_available = g_flg_available
                                        WHERE ad_st.id_sample_type = ad_ap.id_sample_type
                                          AND a_st.flg_available = g_flg_available),
                                       0) id_sample_type,
                                   ad_ap.id_software,
                                   ad_amv.id_market,
                                   ad_amv.version
                              FROM ad_analysis_param ad_ap
                              JOIN ad_analysis_sample_type ad_ast
                                ON ad_ast.id_analysis = ad_ap.id_analysis
                               AND ad_ast.id_sample_type = ad_ap.id_sample_type
                               AND ad_ast.flg_available = g_flg_available
                                  --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                               AND ((ad_ast.id_content IN (SELECT *
                                                             FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                   l_cnt_count = 0)
                              JOIN ad_ast_mkt_vrs ad_amv
                                ON ad_amv.id_content = ad_ast.id_content
                             WHERE ad_ap.flg_available = g_flg_available
                               AND ad_ap.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_amv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_amv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_sample_type > 0
                       AND temp_data.id_analysis > 0
                       AND temp_data.id_analysis_parameter > 0) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM analysis_sample_type a_ast
                     WHERE a_ast.id_analysis = def_data.id_analysis
                       AND a_ast.id_sample_type = def_data.id_sample_type
                       AND a_ast.flg_available = g_flg_available)
               AND NOT EXISTS (SELECT 0
                      FROM analysis_param a_ap
                     WHERE a_ap.id_analysis = def_data.id_analysis
                       AND a_ap.id_analysis_parameter = def_data.id_analysis_parameter
                       AND a_ap.id_sample_type = def_data.id_sample_type
                       AND a_ap.id_institution = i_institution
                       AND a_ap.id_software = i_software(pos_soft));
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_param_search;

    FUNCTION del_analysis_param_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete analysis_param';
        g_func_name := upper('DEL_ANALYSIS_PARAM_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM interv_analysis_param a_iap
             WHERE EXISTS
             (SELECT 1
                      FROM analysis_param a_ap
                     WHERE a_iap.id_analysis_param = a_ap.id_analysis_param
                       AND a_ap.id_institution = i_institution
                       AND a_ap.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                 column_value
                                                  FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        
            DELETE FROM analysis_param a_ap
             WHERE a_ap.id_institution = i_institution
               AND a_ap.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM interv_analysis_param a_iap
             WHERE EXISTS (SELECT 1
                      FROM analysis_param a_ap
                     WHERE a_iap.id_analysis_param = a_ap.id_analysis_param
                       AND a_ap.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        
            DELETE FROM analysis_param a_ap
             WHERE a_ap.id_institution = i_institution;
        
            o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
        
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
                                              g_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END del_analysis_param_search;

    FUNCTION set_lab_questionnaire_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        INSERT INTO analysis_questionnaire
            (id_analysis_questionnaire,
             id_analysis,
             id_questionnaire,
             flg_time,
             rank,
             flg_available,
             id_sample_type,
             id_analysis_group,
             id_response,
             flg_type,
             flg_mandatory,
             flg_copy,
             flg_validation,
             flg_exterior,
             id_unit_measure,
             id_institution)
            SELECT seq_analysis_questionnaire.nextval,
                   def_data.id_analysis,
                   def_data.id_questionnaire,
                   def_data.flg_time,
                   def_data.rank,
                   g_flg_available,
                   def_data.id_sample_type,
                   def_data.id_analysis_group,
                   def_data.id_response,
                   def_data.flg_type,
                   def_data.flg_mandatory,
                   def_data.flg_copy,
                   def_data.flg_validation,
                   def_data.flg_exterior,
                   def_data.id_unit_measure,
                   i_institution
              FROM (SELECT temp_data.id_analysis,
                           temp_data.id_questionnaire,
                           temp_data.flg_time,
                           temp_data.rank,
                           temp_data.id_sample_type,
                           temp_data.id_analysis_group,
                           temp_data.id_response,
                           temp_data.flg_type,
                           temp_data.flg_mandatory,
                           temp_data.flg_copy,
                           temp_data.flg_validation,
                           temp_data.flg_exterior,
                           temp_data.id_unit_measure,
                           row_number() over(PARTITION BY temp_data.id_analysis, temp_data.id_questionnaire, temp_data.id_sample_type, temp_data.id_analysis_group, temp_data.id_response, temp_data.flg_time ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(ad_aq.id_analysis,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_a.id_analysis
                                                FROM analysis a_a
                                                JOIN ad_analysis ad_a
                                                  ON ad_a.id_content = a_a.id_content
                                                 AND ad_a.flg_available = g_flg_available
                                               WHERE a_a.flg_available = g_flg_available
                                                 AND ad_a.id_analysis = ad_aq.id_analysis),
                                              0)) id_analysis,
                                   nvl((SELECT a_q.id_questionnaire
                                         FROM questionnaire a_q
                                         JOIN ad_questionnaire ad_q
                                           ON ad_q.id_content = a_q.id_content
                                          AND ad_q.flg_available = g_flg_available
                                        WHERE a_q.flg_available = g_flg_available
                                          AND ad_q.id_questionnaire = ad_aq.id_questionnaire),
                                       0) id_questionnaire,
                                   ad_aq.flg_time,
                                   ad_aq.rank,
                                   decode(ad_aq.id_sample_type,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_st.id_sample_type
                                                FROM sample_type a_st
                                                JOIN ad_sample_type ad_st
                                                  ON ad_st.id_content = a_st.id_content
                                                 AND ad_st.flg_available = g_flg_available
                                               WHERE a_st.flg_available = g_flg_available
                                                 AND ad_st.id_sample_type = ad_aq.id_sample_type),
                                              0)) id_sample_type,
                                   decode(ad_aq.id_analysis_group,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_ag.id_analysis_group
                                                FROM analysis_group a_ag
                                                JOIN ad_analysis_group ad_ag
                                                  ON ad_ag.id_content = a_ag.id_content
                                               WHERE a_ag.flg_available = g_flg_available
                                                    --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                                                 AND ((ad_ag.id_content IN
                                                     (SELECT *
                                                          FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                                     l_cnt_count = 0)
                                                 AND ad_ag.id_analysis_group = ad_aq.id_analysis_group),
                                              0)) id_analysis_group,
                                   decode(ad_aq.id_response,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_r.id_response
                                                FROM response a_r
                                                JOIN ad_response ad_r
                                                  ON ad_r.id_content = a_r.id_content
                                               WHERE a_r.flg_available = g_flg_available
                                                 AND ad_r.flg_available = g_flg_available
                                                 AND ad_r.id_response = ad_aq.id_response),
                                              0)) id_response,
                                   ad_aq.flg_type,
                                   ad_aq.flg_mandatory,
                                   ad_aq.flg_copy,
                                   ad_aq.flg_validation,
                                   ad_aq.flg_exterior,
                                   decode(ad_aq.id_unit_measure,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_ums.id_unit_measure_subtype
                                                FROM unit_measure_subtype a_ums
                                               WHERE a_ums.id_unit_measure_subtype = ad_aq.id_unit_measure),
                                              0)) id_unit_measure,
                                   ad_aq.id_market,
                                   ad_aq.version
                              FROM ad_analysis_questionnaire ad_aq
                             WHERE ad_aq.flg_available = g_flg_available
                               AND ad_aq.id_market IN (SELECT /*+dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_aq.version IN (SELECT /*+dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_questionnaire > 0
                       AND (temp_data.id_response > 0 OR temp_data.id_response IS NULL)
                       AND (temp_data.id_analysis_group > 0 OR temp_data.id_analysis_group IS NULL)
                       AND (temp_data.id_unit_measure > 0 OR temp_data.id_unit_measure IS NULL)
                       AND (temp_data.id_analysis > 0 OR temp_data.id_analysis IS NULL)
                       AND (temp_data.id_sample_type > 0 OR temp_data.id_sample_type IS NULL)
                       AND (EXISTS
                            (SELECT 0
                               FROM analysis_sample_type a_ast
                              WHERE a_ast.id_analysis = temp_data.id_analysis
                                AND a_ast.id_sample_type = temp_data.id_sample_type
                                   --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                                AND ((a_ast.id_content IN (SELECT *
                                                             FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                    l_cnt_count = 0)
                                AND a_ast.flg_available = g_flg_available) OR temp_data.id_analysis_group IS NOT NULL)) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM questionnaire_response qr
                     WHERE qr.id_questionnaire = def_data.id_questionnaire
                       AND (qr.id_response = def_data.id_response OR
                           (qr.id_response IS NULL AND def_data.id_response IS NULL)))
               AND NOT EXISTS (SELECT 0
                      FROM analysis_questionnaire a_aq
                     WHERE (a_aq.id_analysis = def_data.id_analysis OR
                           (a_aq.id_analysis IS NULL AND def_data.id_analysis IS NULL))
                       AND (a_aq.id_sample_type = def_data.id_sample_type OR
                           (a_aq.id_sample_type IS NULL AND def_data.id_sample_type IS NULL))
                       AND (a_aq.id_analysis_group = def_data.id_analysis_group OR
                           (a_aq.id_analysis_group IS NULL AND def_data.id_analysis_group IS NULL))
                       AND (a_aq.id_response = def_data.id_response OR
                           (a_aq.id_response IS NULL AND def_data.id_response IS NULL))
                       AND a_aq.id_questionnaire = def_data.id_questionnaire
                       AND a_aq.flg_time = def_data.flg_time
                       AND a_aq.flg_available = g_flg_available
                       AND a_aq.id_institution = i_institution);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_lab_questionnaire_search;

    FUNCTION del_lab_questionnaire_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete analysis_questionnaire';
        g_func_name := upper('DEL_LAB_QUESTIONNAIRE_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
        
            RETURN TRUE;
        
        ELSE
        
            DELETE FROM analysis_questionnaire aq
             WHERE aq.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
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
                                              g_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END del_lab_questionnaire_search;

    -- frequent loader method
    FUNCTION set_analysis_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_id_content        IN table_varchar DEFAULT table_varchar(),
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
        g_func_name := upper('SET_ANALYSIS_DEP_CLIN_SERV_FREQ');
    
        INSERT INTO analysis_dep_clin_serv
            (id_analysis_dep_clin_serv,
             id_analysis,
             id_dep_clin_serv,
             rank,
             adw_last_update,
             id_software,
             flg_available,
             id_sample_type)
            SELECT seq_analysis_dep_clin_serv.nextval,
                   def_data.id_analysis,
                   i_dep_clin_serv_out,
                   def_data.rank,
                   SYSDATE,
                   id_software,
                   g_flg_available,
                   def_data.id_sample_type
              FROM (SELECT temp_data.id_analysis,
                           temp_data.rank,
                           i_software(pos_soft) id_software,
                           temp_data.id_sample_type,
                           row_number() over(PARTITION BY temp_data.id_analysis, temp_data.id_sample_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_a.id_analysis
                                         FROM analysis a_a
                                         JOIN ad_analysis ad_a
                                           ON ad_a.id_content = a_a.id_content
                                          AND ad_a.flg_available = g_flg_available
                                        WHERE ad_a.id_analysis = ad_acs.id_analysis
                                          AND a_a.flg_available = g_flg_available),
                                       0) id_analysis,
                                   nvl(ad_acs.rank, 0) rank,
                                   nvl((SELECT a_st.id_sample_type
                                         FROM sample_type a_st
                                         JOIN ad_sample_type ad_st
                                           ON ad_st.id_content = a_st.id_content
                                        WHERE ad_st.id_sample_type = ad_acs.id_sample_type
                                          AND a_st.flg_available = g_flg_available),
                                       0) id_sample_type,
                                   ad_acs.id_software,
                                   ad_amv.id_market,
                                   ad_amv.version
                              FROM ad_analysis_clin_serv ad_acs
                              JOIN ad_analysis_sample_type ad_ast
                                ON ad_ast.id_analysis = ad_acs.id_analysis
                               AND ad_ast.id_sample_type = ad_acs.id_sample_type
                               AND ad_ast.flg_available = g_flg_available
                                  --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                               AND ((ad_ast.id_content IN (SELECT *
                                                             FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                   l_cnt_count = 0)
                              JOIN ad_ast_mkt_vrs ad_amv
                                ON ad_amv.id_content = ad_ast.id_content
                             WHERE ad_amv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_amv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_acs.id_analysis_group IS NULL
                               AND ad_acs.flg_available = g_flg_available
                               AND ad_acs.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_acs.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                     WHERE temp_data.id_analysis > 0
                       AND temp_data.id_sample_type > 0) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis = def_data.id_analysis
                       AND a_ais.id_sample_type = def_data.id_sample_type
                       AND a_ais.flg_type = 'P'
                       AND a_ais.id_institution = i_institution
                       AND a_ais.id_software = i_software(pos_soft)
                       AND a_ais.flg_available = g_flg_available)
               AND EXISTS (SELECT 0
                      FROM analysis_sample_type a_ast
                     WHERE a_ast.id_analysis = def_data.id_analysis
                       AND a_ast.id_sample_type = def_data.id_sample_type
                       AND a_ast.flg_available = g_flg_available)
               AND NOT EXISTS (SELECT 0
                      FROM analysis_dep_clin_serv adcs
                     WHERE adcs.id_analysis = def_data.id_analysis
                       AND adcs.id_sample_type = def_data.id_sample_type
                       AND adcs.id_dep_clin_serv = i_dep_clin_serv_out
                       AND adcs.id_software = i_software(pos_soft));
    
        o_result_tbl := SQL%ROWCOUNT;
    
        INSERT INTO analysis_dep_clin_serv
            (id_analysis_dep_clin_serv,
             id_dep_clin_serv,
             rank,
             adw_last_update,
             id_software,
             id_analysis_group,
             flg_available)
            SELECT seq_analysis_dep_clin_serv.nextval,
                   i_dep_clin_serv_out,
                   def_data.rank,
                   SYSDATE,
                   i_software(pos_soft) id_software,
                   def_data.id_analysis_group,
                   g_flg_available
              FROM (SELECT temp_data.id_analysis_group,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_analysis_group ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_ag.id_analysis_group
                                         FROM analysis_group a_ag
                                         JOIN ad_analysis_group ad_ag
                                           ON a_ag.id_content = ad_ag.id_content
                                        WHERE ad_ag.id_analysis_group = ad_acs.id_analysis_group
                                          AND a_ag.flg_available = g_flg_available
                                             --if l_cnt_count = 0 all content is inserted, else it is fltered by id_content
                                          AND ((ad_ag.id_content IN (SELECT *
                                                                       FROM TABLE(i_id_content)) AND l_cnt_count > 0) OR
                                              l_cnt_count = 0)),
                                       0) id_analysis_group,
                                   nvl(ad_acs.rank, 0) rank,
                                   ad_acs.id_software,
                                   agmv.id_market,
                                   agmv.version
                              FROM ad_analysis_clin_serv ad_acs
                              JOIN ad_analysis_group_mrk_vrs agmv
                                ON agmv.id_analysis_group = ad_acs.id_analysis_group
                               AND agmv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND agmv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)
                             WHERE ad_acs.id_analysis IS NULL
                               AND ad_acs.flg_available = g_flg_available
                               AND ad_acs.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_acs.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                     WHERE temp_data.id_analysis_group > 0) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM analysis_instit_soft a_ais
                     WHERE a_ais.id_analysis_group = def_data.id_analysis_group
                       AND a_ais.flg_type = 'P'
                       AND a_ais.id_institution = i_institution
                       AND a_ais.id_software = i_software(pos_soft)
                       AND a_ais.flg_available = g_flg_available)
               AND NOT EXISTS (SELECT 0
                      FROM analysis_dep_clin_serv adcs
                     WHERE adcs.id_analysis_group = def_data.id_analysis_group
                       AND adcs.id_dep_clin_serv = i_dep_clin_serv_out
                       AND adcs.id_software = i_software(pos_soft));
    
        o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_freq;

    FUNCTION del_analysis_freq
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
        o_dcs_list table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete analysis_dep_clin_serv';
        g_func_name := upper('DEL_ANALYSIS_FREQ');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            SELECT a_dcs.id_dep_clin_serv
              BULK COLLECT
              INTO o_dcs_list
              FROM dep_clin_serv a_dcs
              JOIN department a_d
                ON a_d.id_department = a_dcs.id_department
              JOIN dept a_dp
                ON a_dp.id_dept = a_d.id_dept
              JOIN software_dept a_sd
                ON a_sd.id_dept = a_dp.id_dept
             WHERE a_d.id_institution = i_institution
               AND a_d.id_institution = a_dp.id_institution
               AND a_dcs.id_clinical_service != 0
               AND a_sd.id_software IN (SELECT /*+ opt_estimate(area_list rows = 2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) sw_list);
        
        ELSE
            SELECT a_dcs.id_dep_clin_serv
              BULK COLLECT
              INTO o_dcs_list
              FROM dep_clin_serv a_dcs
              JOIN department a_d
                ON a_d.id_department = a_dcs.id_department
              JOIN dept a_dp
                ON a_dp.id_dept = a_d.id_dept
              JOIN software_dept a_sd
                ON a_sd.id_dept = a_dp.id_dept
             WHERE a_d.id_institution = i_institution
               AND a_d.id_institution = a_dp.id_institution
               AND a_dcs.id_clinical_service != 0;
        END IF;
    
        DELETE FROM analysis_dep_clin_serv a_adcs
         WHERE a_adcs.id_dep_clin_serv IN (SELECT /*+ dynamic_sampling(2)*/
                                            column_value
                                             FROM TABLE(CAST(o_dcs_list AS table_number)) p);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END del_analysis_freq;

    FUNCTION set_analysis_ir_clone
    (
        i_lang          IN language.id_language%TYPE,
        i_o_institution IN institution.id_institution%TYPE,
        i_d_institution IN institution.id_institution%TYPE,
        i_software      IN table_number,
        o_result_tbl    OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('SET_ANALYSIS_PARAM_FUNCIONALITY_CLONE');
    
        INSERT INTO analysis_instit_recipient
            (id_analysis_instit_recipient,
             id_analysis_instit_soft,
             id_sample_recipient,
             flg_default,
             id_room,
             qty_harvest,
             num_recipient)
            SELECT seq_analysis_instit_recipient.nextval,
                   def_data.id_analysis_instit_soft,
                   def_data.id_sample_recipient,
                   def_data.flg_default,
                   NULL,
                   def_data.qty_harvest,
                   def_data.num_recipient
              FROM (SELECT temp_data.id_sample_recipient,
                           temp_data.flg_default,
                           temp_data.qty_harvest,
                           temp_data.id_analysis_instit_soft,
                           temp_data.num_recipient,
                           row_number() over(PARTITION BY temp_data.id_analysis_instit_soft ORDER BY temp_data.l_row) records_count
                      FROM (SELECT a_air.rowid l_row,
                                   a_air.id_sample_recipient,
                                   a_air.flg_default,
                                   a_air.qty_harvest,
                                   a_air.num_recipient,
                                   nvl((SELECT a_ais1.id_analysis_instit_soft
                                         FROM analysis_instit_soft a_ais1
                                        WHERE a_ais1.id_analysis = a_ais.id_analysis
                                          AND a_ais1.id_software = a_ais.id_software
                                          AND a_ais1.flg_available = a_ais.flg_available
                                          AND a_ais1.id_sample_type = a_ais.id_sample_type
                                          AND a_ais1.flg_type = a_ais.flg_type
                                          AND a_ais1.id_institution = i_d_institution
                                          AND a_ais1.flg_available = g_flg_available),
                                       0) id_analysis_instit_soft
                              FROM analysis_instit_recipient a_air
                              JOIN analysis_instit_soft a_ais
                                ON a_ais.id_analysis_instit_soft = a_air.id_analysis_instit_soft
                             WHERE a_ais.id_institution = i_o_institution
                               AND a_ais.flg_available = g_flg_available
                               AND a_ais.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_analysis_instit_soft != 0
               AND NOT EXISTS (SELECT 0
                      FROM analysis_instit_recipient a_air
                     WHERE a_air.id_analysis_instit_soft = id_analysis_instit_soft
                       AND a_air.id_sample_recipient = def_data.id_sample_recipient
                       AND a_air.flg_default = def_data.flg_default
                       AND a_air.id_room IS NULL);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_ir_clone;

    FUNCTION set_analysis_param_func_clone
    (
        i_lang          IN language.id_language%TYPE,
        i_o_institution IN institution.id_institution%TYPE,
        i_d_institution IN institution.id_institution%TYPE,
        i_software      IN table_number,
        o_result_tbl    OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('SET_ANALYSIS_PARAM_FUNCIONALITY_CLONE');
    
        INSERT INTO analysis_param_funcionality
            (id_analysis_param_funcionality, flg_type, rank, flg_fill_type, id_analysis_param)
            SELECT seq_analysis_param_func.nextval,
                   def_data.flg_type,
                   def_data.rank,
                   def_data.flg_fill_type,
                   def_data.i_param
              FROM (SELECT temp_data.flg_type,
                           temp_data.rank,
                           temp_data.flg_fill_type,
                           temp_data.i_param,
                           row_number() over(PARTITION BY temp_data.flg_type, temp_data.i_param ORDER BY temp_data.l_row) records_count
                      FROM (SELECT a_apf.rowid l_row,
                                   a_apf.flg_type,
                                   a_apf.rank,
                                   a_apf.flg_fill_type,
                                   nvl((SELECT a_ap1.id_analysis_param
                                         FROM analysis_param a_ap1
                                        WHERE a_ap1.id_analysis = a_ap.id_analysis
                                          AND a_ap1.id_software = a_ap.id_software
                                          AND a_ap1.flg_available = a_ap.flg_available
                                          AND a_ap1.id_analysis_parameter = a_ap.id_analysis_parameter
                                          AND a_ap1.id_institution = i_d_institution
                                          AND a_ap1.flg_available = g_flg_available
                                          AND a_ap1.id_sample_type = a_ap.id_sample_type),
                                       0) i_param
                              FROM analysis_param_funcionality a_apf
                              JOIN analysis_param a_ap
                                ON a_ap.id_analysis_param = a_apf.id_analysis_param
                             WHERE a_ap.id_institution = i_o_institution
                               AND a_ap.flg_available = g_flg_available
                               AND a_ap.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.i_param != 0
               AND NOT EXISTS (SELECT 0
                      FROM analysis_param_funcionality a_apf
                     WHERE a_apf.id_analysis_param = i_param
                       AND a_apf.flg_type = def_data.flg_type);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_analysis_param_func_clone;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_labtest_prm;
/
