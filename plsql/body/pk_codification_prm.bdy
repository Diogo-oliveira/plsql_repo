CREATE OR REPLACE PACKAGE BODY pk_codification_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'pk_codification_prm';
    pos_soft        NUMBER := 1;
    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_codification_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('codification.code_codification.');
    
    BEGIN
    
        g_func_name := upper('load_codification_def');
    
        INSERT INTO codification
            (id_codification, code_codification, flg_available, id_content, id_map_set)
            SELECT seq_codification.nextval,
                   l_code_translation || seq_codification.currval,
                   g_flg_available,
                   id_content,
                   id_map_set
              FROM (SELECT ad_c.id_codification, ad_c.id_content, ad_c.id_map_set
                      FROM ad_codification ad_c
                     WHERE ad_c.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT a_c.id_codification
                              FROM codification a_c
                             WHERE a_c.id_content = ad_c.id_content
                               AND a_c.flg_available = g_flg_available)) def_data;
    
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
        
    END load_codification_def;

    FUNCTION load_analysis_codification_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('load_analysis_codification_def');
    
        INSERT INTO analysis_codification
            (id_analysis_codification,
             id_codification,
             id_analysis,
             flg_available,
             id_sample_type,
             standard_code,
             standard_desc,
             dt_standard_begin,
             dt_standard_end,
             flg_show_codification,
             flg_mandatory_info,
             flg_concatenate_info)
            SELECT seq_analysis_codification.nextval,
                   id_codification,
                   id_analysis,
                   g_flg_available,
                   id_sample_type,
                   standard_code,
                   standard_desc,
                   dt_standard_begin,
                   dt_standard_end,
                   flg_show_codification,
                   flg_mandatory_info,
                   flg_concatenate_info
              FROM (SELECT row_number() over(PARTITION BY temp_data.id_codification, temp_data.id_analysis, temp_data.id_sample_type ORDER BY temp_data.l_row) records_count,
                           temp_data.id_codification,
                           temp_data.id_analysis,
                           temp_data.id_sample_type,
                           temp_data.standard_code,
                           temp_data.standard_desc,
                           temp_data.dt_standard_begin,
                           temp_data.dt_standard_end,
                           temp_data.flg_show_codification,
                           temp_data.flg_mandatory_info,
                           temp_data.flg_concatenate_info
                      FROM (SELECT nvl((SELECT a_c.id_codification
                                         FROM codification a_c
                                         JOIN ad_codification ad_c
                                           ON a_c.id_content = ad_c.id_content
                                        WHERE ad_c.id_codification = ad_ac.id_codification
                                          AND a_c.flg_available = g_flg_available
                                          AND ad_c.flg_available = g_flg_available),
                                       0) id_codification,
                                   nvl((SELECT a_a.id_analysis
                                         FROM analysis a_a
                                         JOIN ad_analysis ad_a
                                           ON a_a.id_content = ad_a.id_content
                                        WHERE ad_a.id_analysis = ad_ac.id_analysis
                                          AND a_a.flg_available = g_flg_available
                                          AND ad_a.flg_available = g_flg_available),
                                       0) id_analysis,
                                   nvl((SELECT a_st.id_sample_type
                                         FROM ad_sample_type ad_st
                                         JOIN sample_type a_st
                                           ON a_st.id_content = ad_st.id_content
                                        WHERE ad_ac.id_sample_type = ad_st.id_sample_type
                                          AND a_st.flg_available = g_flg_available
                                          AND ad_st.flg_available = g_flg_available),
                                       0) id_sample_type,
                                   ad_ac.rowid l_row,
                                   ad_ac.standard_code,
                                   ad_ac.standard_desc,
                                   ad_ac.dt_standard_begin,
                                   ad_ac.dt_standard_end,
                                   ad_ac.flg_show_codification,
                                   ad_ac.flg_mandatory_info,
                                   ad_ac.flg_concatenate_info
                              FROM ad_analysis_codification ad_ac
                             WHERE ad_ac.flg_available = g_flg_available) temp_data) def_data
             WHERE def_data.id_codification > 0
               AND def_data.id_analysis > 0
               AND def_data.id_sample_type > 0
               AND def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM analysis_sample_type a_ast
                     WHERE a_ast.id_analysis = def_data.id_analysis
                       AND a_ast.id_sample_type = def_data.id_sample_type)
               AND NOT EXISTS (SELECT 0
                      FROM analysis_codification a_ac
                     WHERE a_ac.id_codification = def_data.id_codification
                       AND a_ac.id_analysis = def_data.id_analysis
                       AND a_ac.id_sample_type = def_data.id_sample_type
                       AND a_ac.flg_available = g_flg_available);
    
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
        
    END load_analysis_codification_def;

    FUNCTION load_exam_codification_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('load_exam_codification_def');
    
        INSERT INTO exam_codification
            (id_exam_codification,
             id_codification,
             id_exam,
             flg_available,
             standard_code,
             standard_desc,
             dt_standard_begin,
             dt_standard_end,
             flg_show_codification,
             flg_show_quantity)
            SELECT seq_exam_codification.nextval,
                   id_codification,
                   id_exam,
                   g_flg_available,
                   standard_code,
                   standard_desc,
                   dt_standard_begin,
                   dt_standard_end,
                   flg_show_codification,
                   flg_show_quantity
              FROM (SELECT nvl((SELECT a_c.id_codification
                                 FROM codification a_c
                                 JOIN ad_codification ad_c
                                   ON a_c.id_content = ad_c.id_content
                                WHERE ad_c.id_codification = ad_ec.id_codification
                                  AND a_c.flg_available = g_flg_available),
                               0) id_codification,
                           nvl((SELECT a_e.id_exam
                                 FROM exam a_e
                                 JOIN ad_exam ad_e
                                   ON a_e.id_content = ad_e.id_content
                                WHERE ad_e.id_exam = ad_ec.id_exam
                                  AND a_e.flg_available = g_flg_available),
                               0) id_exam,
                           ad_ec.standard_code,
                           ad_ec.standard_desc,
                           ad_ec.dt_standard_begin,
                           ad_ec.dt_standard_end,
                           ad_ec.flg_show_codification,
                           ad_ec.flg_show_quantity
                      FROM alert_default.exam_codification ad_ec
                     WHERE ad_ec.flg_available = g_flg_available) def_data
             WHERE def_data.id_codification > 0
               AND def_data.id_exam > 0
               AND NOT EXISTS (SELECT 0
                      FROM exam_codification a_ec
                     WHERE a_ec.id_codification = def_data.id_codification
                       AND a_ec.id_exam = def_data.id_exam
                       AND a_ec.flg_available = g_flg_available);
    
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
        
    END load_exam_codification_def;

    FUNCTION load_interv_codification_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('load_interv_codification_def');
    
        INSERT INTO interv_codification
            (id_interv_codification,
             id_codification,
             id_intervention,
             flg_available,
             standard_code,
             standard_desc,
             dt_standard_begin,
             dt_standard_end,
             flg_show_code,
             flg_show_codification)
            SELECT seq_interv_codification.nextval,
                   id_codification,
                   id_intervention,
                   g_flg_available,
                   standard_code,
                   standard_desc,
                   dt_standard_begin,
                   dt_standard_end,
                   flg_show_code,
                   flg_show_codification
              FROM (SELECT nvl((SELECT a_c.id_codification
                                 FROM codification a_c
                                 JOIN ad_codification ad_c
                                   ON a_c.id_content = ad_c.id_content
                                WHERE ad_c.id_codification = ad_ic.id_codification
                                  AND a_c.flg_available = g_flg_available),
                               0) id_codification,
                           nvl((SELECT a_i.id_intervention
                                 FROM intervention a_i
                                 JOIN alert_default.intervention ad_i
                                   ON a_i.id_content = ad_i.id_content
                                WHERE ad_i.id_intervention = ad_ic.id_intervention
                                  AND a_i.flg_status = pk_alert_constant.g_active),
                               0) id_intervention,
                           ad_ic.standard_code,
                           ad_ic.standard_desc,
                           ad_ic.dt_standard_begin,
                           ad_ic.dt_standard_end,
                           ad_ic.flg_show_code,
                           ad_ic.flg_show_codification
                      FROM ad_interv_codification ad_ic
                     WHERE ad_ic.flg_available = g_flg_available) def_data
             WHERE def_data.id_codification > 0
               AND def_data.id_intervention > 0
               AND NOT EXISTS (SELECT 0
                      FROM interv_codification ad_ic
                     WHERE ad_ic.id_codification = def_data.id_codification
                       AND ad_ic.id_intervention = def_data.id_intervention
                       AND ad_ic.flg_available = g_flg_available);
    
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
        
    END load_interv_codification_def;
    /********************************************************************************************
    * Configuration of Diagnosis and codification relation
    *
    * @param i_lang                  Language id
    * @param o_result                Number of results configured
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/12/13
    * @version                       2.6.1.14
    ********************************************************************************************/
    FUNCTION load_diag_codif_def
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('load_diag_codif_def');
        g_error     := 'SET SR_INTERV_CODIFICATION CONTENT';
    
        INSERT INTO diag_codification
            (flg_diag_type, id_codification)
            SELECT def_data.flg_diag_type, def_data.id_codification
              FROM (SELECT temp_data.flg_diag_type,
                           temp_data.id_codification,
                           row_number() over(PARTITION BY temp_data.id_codification, temp_data.flg_diag_type ORDER BY temp_data.l_row) records_count
                      FROM (SELECT ad_dc.flg_diag_type,
                                   nvl((SELECT a_c.id_codification
                                         FROM codification a_c
                                         JOIN ad_codification ad_c
                                           ON ad_c.id_content = a_c.id_content
                                          AND ad_c.flg_available = g_flg_available
                                        WHERE a_c.flg_available = g_flg_available
                                          AND ad_c.id_codification = ad_dc.id_codification),
                                       0) id_codification,
                                   ad_dc.rowid l_row
                              FROM ad_diag_codification ad_dc) temp_data
                     WHERE temp_data.id_codification > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM diag_codification a_dc
                     WHERE a_dc.id_codification = def_data.id_codification
                       AND a_dc.flg_diag_type = def_data.flg_diag_type);
    
        o_result := SQL%ROWCOUNT;
    
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
        
    END load_diag_codif_def;
    /********************************************************************************************
    * Configuration of Diagnosis and codification relation
    *
    * @param i_lang                  Language id
    * @param o_result                Number of results configured
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/12/13
    * @version                       2.6.1.14
    ********************************************************************************************/
    FUNCTION load_extcause_codif_def
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('load_extcause_codif_def');
        g_error     := 'SET EXTERNAL CAUSE CODIFICATION CONTENT';
    
        INSERT INTO ext_cause_codification
            (id_ext_cause_codification,
             id_codification,
             id_external_cause,
             flg_available,
             standard_code,
             standard_desc,
             dt_standard_begin,
             dt_standard_end)
            SELECT nvl((SELECT MAX(id_ext_cause_codification)
                         FROM ext_cause_codification),
                       0) + rownum,
                   def_data.id_codification,
                   def_data.id_external_cause,
                   g_flg_available,
                   def_data.standard_code,
                   def_data.standard_desc,
                   def_data.dt_standard_begin,
                   def_data.dt_standard_end
              FROM (SELECT temp_data.id_codification,
                           temp_data.id_external_cause,
                           temp_data.standard_code,
                           temp_data.standard_desc,
                           temp_data.dt_standard_begin,
                           temp_data.dt_standard_end,
                           row_number() over(PARTITION BY temp_data.id_codification, temp_data.id_external_cause, temp_data.standard_code ORDER BY temp_data.l_row) records_count
                      FROM (SELECT nvl((SELECT a_c.id_codification
                                         FROM codification a_c
                                         JOIN ad_codification ad_c
                                           ON ad_c.id_content = a_c.id_content
                                          AND ad_c.flg_available = g_flg_available
                                        WHERE a_c.flg_available = g_flg_available
                                          AND ad_c.id_codification = ad_ecc.id_codification),
                                       0) id_codification,
                                   nvl((SELECT a_ec.id_external_cause
                                         FROM external_cause a_ec
                                         JOIN ad_external_cause ad_ec
                                           ON ad_ec.id_content = a_ec.id_content
                                          AND ad_ec.flg_available = g_flg_available
                                        WHERE a_ec.flg_available = g_flg_available
                                          AND ad_ec.id_external_cause = ad_ecc.id_external_cause),
                                       0) id_external_cause,
                                   ad_ecc.standard_code,
                                   ad_ecc.standard_desc,
                                   ad_ecc.dt_standard_begin,
                                   ad_ecc.dt_standard_end,
                                   ad_ecc.rowid l_row
                              FROM ad_ext_cause_codification ad_ecc
                             WHERE ad_ecc.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_codification > 0
                       AND temp_data.id_external_cause > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM ext_cause_codification a_ecc
                     WHERE a_ecc.id_codification = def_data.id_codification
                       AND a_ecc.id_external_cause = def_data.id_external_cause
                       AND a_ecc.standard_code = def_data.standard_code
                       AND a_ecc.flg_available = g_flg_available);
    
        o_result := SQL%ROWCOUNT;
    
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
        
    END load_extcause_codif_def;

    -- searcheable loader method
    FUNCTION set_codification_is_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('set_codification_is_search');
    
        INSERT INTO codification_instit_soft
            (id_codif_instit_soft,
             id_codification,
             flg_default,
             flg_available,
             flg_use_on_referral,
             id_software,
             id_institution)
            SELECT seq_codification_instit_soft.nextval,
                   def_data.id_codification,
                   def_data.flg_default,
                   def_data.flg_available,
                   flg_use_on_referral,
                   i_software(pos_soft),
                   i_institution
              FROM (SELECT temp_data.id_codification,
                           temp_data.flg_default,
                           temp_data.flg_available,
                           temp_data.flg_use_on_referral,
                           row_number() over(PARTITION BY temp_data.id_codification ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_c.id_codification
                                                FROM codification a_c
                                               WHERE a_c.flg_available = g_flg_available
                                                 AND a_c.id_content = ad_c.id_content),
                                              0),
                                          nvl((SELECT a_c.id_codification
                                                FROM codification a_c
                                               WHERE a_c.flg_available = g_flg_available
                                                 AND a_c.id_content = ad_c.id_content
                                                 AND to_char(ad_c.id_content) IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_codification,
                                   ad_cis.flg_default,
                                   ad_cis.flg_available,
                                   ad_cis.flg_use_on_referral,
                                   ad_cis.id_software,
                                   ad_cmv.id_market,
                                   ad_cmv.version
                            -- decode FKS to dest_vals
                              FROM ad_codification_mrk_vrs ad_cmv
                              JOIN ad_codification_instit_soft ad_cis
                                ON ad_cis.id_codification = ad_cmv.id_codification
                              JOIN ad_codification ad_c
                                ON ad_c.id_codification = ad_cis.id_codification
                             WHERE ad_cis.flg_available = g_flg_available
                               AND ad_c.flg_available = g_flg_available
                               AND ad_cis.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_cmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_cmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND id_codification > 0
               AND NOT EXISTS (SELECT 0
                      FROM codification_instit_soft a_cis
                     WHERE a_cis.id_codification = def_data.id_codification
                       AND a_cis.id_institution = i_institution
                       AND a_cis.id_software = i_software(pos_soft)
                       AND a_cis.flg_available = g_flg_available);
    
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
        
    END set_codification_is_search;
    -- frequent loader method

    FUNCTION del_codification_is_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete codification_instit_soft';
        g_func_name := upper('del_codification_is_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM codification_instit_soft ad_cis
             WHERE ad_cis.id_institution = i_institution
               AND ad_cis.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(i_software AS table_number)) p);
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM codification_instit_soft ad_cis
             WHERE ad_cis.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END del_codification_is_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

END pk_codification_prm;
/
