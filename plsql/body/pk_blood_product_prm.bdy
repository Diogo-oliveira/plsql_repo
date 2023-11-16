/*-- Last Change Revision: $Rev: 1945382 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-04-14 09:13:16 +0100 (ter, 14 abr 2020) $*/
CREATE OR REPLACE PACKAGE BODY alert.pk_blood_product_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_BLOOD_PRODUCT_PRM';
    pos_soft        NUMBER := 1;

    -- Private Methods

    /**
    * Load hemo types from default table
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                Ana Moita
    * @version               v2.7.4.5
    * @since                 2018/10/24
    */

    FUNCTION load_hemo_type_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('HEMO_TYPE.CODE_HEMO_TYPE.');
    
    BEGIN
    
        INSERT INTO hemo_type
            (id_hemo_type, code_hemo_type, flg_available, rank, id_content)
            SELECT seq_hemo_type.nextval,
                   l_code_translation || seq_hemo_type.currval,
                   g_flg_available,
                   rank,
                   id_content
              FROM (SELECT ad_ht.rank, ad_ht.id_content
                      FROM ad_hemo_type ad_ht
                     WHERE ad_ht.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM hemo_type a_ht
                             WHERE a_ht.id_content = ad_ht.id_content)) def_data;
    
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
    END load_hemo_type_def;

    /**
    * Set Default Hemo types for institution and software
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_mkt                 Market ID
    * @param i_vers                Content Version
    * @param i_id_software         Software ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Ana Moita
    * @version                     v2.7.4.5
    * @since                       2018/10/24
    */
    -- searcheable loader method signature
    FUNCTION set_hemo_type_instit_soft
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
    
        g_func_name := upper('set_hemo_type_instit_soft');
    
        INSERT INTO hemo_type_instit_soft
            (id_hemo_type_instit_soft, id_hemo_type, flg_available, id_software, id_institution)
            SELECT seq_hemo_type_instit_soft.nextval,
                   def_data.id_hemo_type,
                   g_flg_available,
                   i_software(pos_soft),
                   i_institution
              FROM (SELECT temp_data.id_hemo_type,
                           row_number() over(PARTITION BY temp_data.id_hemo_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT ad_hts.rowid l_row,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_ht.id_hemo_type
                                                FROM hemo_type a_ht
                                                JOIN ad_hemo_type ad_ht
                                                  ON a_ht.id_content = ad_ht.id_content
                                               WHERE ad_ht.id_hemo_type = ad_htmv.id_hemo_type
                                                 AND ad_ht.flg_available = g_flg_available
                                                 AND a_ht.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_ht.id_hemo_type
                                                FROM hemo_type a_ht
                                                JOIN ad_hemo_type ad_ht
                                                  ON a_ht.id_content = ad_ht.id_content
                                               WHERE ad_ht.id_hemo_type = ad_htmv.id_hemo_type
                                                 AND ad_ht.flg_available = g_flg_available
                                                 AND a_ht.flg_available = g_flg_available
                                                 AND ad_ht.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_hemo_type,
                                   ad_hts.id_software,
                                   ad_htmv.id_market,
                                   ad_htmv.version
                            -- decode FKS to dest_vals
                              FROM ad_hemo_type_mrk_vrs ad_htmv
                             INNER JOIN ad_hemo_type_software ad_hts
                                ON ad_hts.id_hemo_type = ad_htmv.id_hemo_type
                             INNER JOIN ad_hemo_type ad_ht
                                ON ad_ht.id_hemo_type = ad_htmv.id_hemo_type
                             WHERE ad_hts.flg_available = g_flg_available
                               AND ad_ht.flg_available = g_flg_available
                               AND ad_hts.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_htmv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND ad_htmv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND id_hemo_type != 0
               AND NOT EXISTS (SELECT 0
                      FROM hemo_type_instit_soft a_htis
                     WHERE a_htis.id_hemo_type = def_data.id_hemo_type
                       AND a_htis.id_institution = i_institution
                       AND a_htis.id_software = i_software(pos_soft)
                       AND a_htis.flg_available = g_flg_available);
                       
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
    END set_hemo_type_instit_soft;

    FUNCTION del_hemo_type_instit_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
      
        g_error     := 'delete hemo_type_instit_soft';
        g_func_name := upper('DEL_HEMO_TYPE_INSTIT_SOFT');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM hemo_type_instit_soft a_htis
             WHERE a_htis.id_institution = i_institution
               AND a_htis.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
            
        ELSE
          
            DELETE FROM hemo_type_instit_soft htis
             WHERE htis.id_institution = i_institution;
        
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
    END del_hemo_type_instit_soft;
    -- frequent loader method
    /**
    * Configure analysis requested by hemo type for institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_mkt                 Market ID
    * @param i_vers                Content Version
    * @param i_id_software         Software ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Ana Moita
    * @version                     v2.7.4.5
    * @since                       2018/10/24
    */
    FUNCTION set_hemo_type_analysis
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
    
        g_func_name := upper('set_hemo_type_analysis');
    
        INSERT INTO hemo_type_analysis
            (id_hemo_type_analysis,
             id_hemo_type,
             id_analysis,
             id_sample_type,
             flg_available,
             time_req,
             unit_time_req,
             id_institution,
             flg_reaction_form,
             flg_newborn)
            SELECT seq_hemo_type_analysis.nextval,
                   def_data.id_hemo_type,
                   def_data.id_analysis,
                   def_data.id_sample_type,
                   def_data.flg_available,
                   def_data.time_req,
                   def_data.unit_time_req,
                   i_institution,
                   def_data.flg_reaction_form,
                   def_data.flg_newborn
              FROM (SELECT temp_data.id_hemo_type,
                           temp_data.id_analysis,
                           temp_data.id_sample_type,
                           temp_data.flg_available,
                           temp_data.time_req,
                           temp_data.unit_time_req,
                           temp_data.flg_reaction_form,
                           temp_data.flg_newborn,
                           row_number() over(PARTITION BY temp_data.id_hemo_type, temp_data.id_analysis, temp_data.id_sample_type, temp_data.flg_reaction_form ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(ad_hta.id_hemo_type,
                                          NULL,
                                          NULL,
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT a_ht.id_hemo_type
                                                       FROM hemo_type a_ht
                                                       JOIN ad_hemo_type ad_ht
                                                         ON a_ht.id_content = ad_ht.id_content
                                                      WHERE ad_ht.id_hemo_type = ad_hta.id_hemo_type
                                                        AND ad_ht.flg_available = g_flg_available
                                                        AND a_ht.flg_available = g_flg_available),
                                                     0),
                                                 nvl((SELECT a_ht.id_hemo_type
                                                       FROM hemo_type a_ht
                                                       JOIN ad_hemo_type ad_ht
                                                         ON a_ht.id_content = ad_ht.id_content
                                                      WHERE ad_ht.id_hemo_type = ad_hta.id_hemo_type
                                                        AND ad_ht.flg_available = g_flg_available
                                                        AND a_ht.flg_available = g_flg_available
                                                        AND ad_ht.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                                     0))) id_hemo_type,
                                   nvl((SELECT a_ast.id_analysis
                                         FROM analysis_sample_type a_ast
                                        INNER JOIN ad_analysis_sample_type ad_ast
                                           ON a_ast.id_content = ad_ast.id_content
                                        WHERE ad_ast.id_content = ad_hta.id_content_ast
                                          AND ad_ast.flg_available = g_flg_available
                                          AND a_ast.flg_available = g_flg_available),
                                       0) id_analysis,
                                   nvl((SELECT a_ast.id_sample_type
                                         FROM analysis_sample_type a_ast
                                        INNER JOIN ad_analysis_sample_type ad_ast
                                           ON a_ast.id_content = ad_ast.id_content
                                        WHERE ad_ast.id_content = ad_hta.id_content_ast
                                          AND ad_ast.flg_available = g_flg_available
                                          AND a_ast.flg_available = g_flg_available),
                                       0) id_sample_type,
                                   ad_hta.flg_available,
                                   ad_hta.time_req,
                                   ad_hta.unit_time_req,
                                   ad_hta.flg_reaction_form,
                                   ad_hta.id_market,
                                   ad_hta.version,
                                   ad_hta.flg_newborn
                            -- decode FKS to dest_vals
                              FROM ad_hemo_type_analysis ad_hta
                             WHERE ad_hta.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_hta.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND (def_data.id_hemo_type > 0 OR def_data.id_hemo_type IS NULL)
               AND def_data.id_analysis > 0
               AND def_data.id_sample_type > 0
               AND NOT EXISTS (SELECT 0
                      FROM hemo_type_analysis a_hta
                     WHERE a_hta.id_hemo_type = def_data.id_hemo_type
                       AND a_hta.id_analysis = def_data.id_analysis
                       AND a_hta.id_sample_type = def_data.id_sample_type
                       AND a_hta.id_institution = i_institution
                       AND (a_hta.unit_time_req = def_data.unit_time_req OR
                           def_data.unit_time_req IS NULL AND def_data.unit_time_req IS NULL)
                       AND (a_hta.time_req = def_data.time_req OR
                           def_data.time_req IS NULL AND def_data.time_req IS NULL)
                       AND a_hta.flg_available = g_flg_available
                       AND a_hta.flg_reaction_form = def_data.flg_reaction_form
                       AND a_hta.flg_newborn = def_data.flg_newborn);
    
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
    END set_hemo_type_analysis;

    FUNCTION del_hemo_type_analysis
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
      
        g_error     := 'delete hemo_type_analysis';
        g_func_name := upper('DEL_HEMO_TYPE_ANALYSIS');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_sw_list
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_sw_list.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM hemo_type_analysis a_hta
             WHERE a_hta.id_institution = i_institution;
        
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
    END del_hemo_type_analysis;

    /**
    * Set Default Questionnaire of Hemo types by institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_mkt                 Market ID
    * @param i_vers                Content Version
    * @param i_id_software         Software ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Ana Moita
    * @version                     v2.7.4.5
    * @since                       2018/10/24
    */

    FUNCTION set_bp_questionnaire_search
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
    
        g_func_name := upper('set_bp_questionnaire_search');
    
        INSERT INTO bp_questionnaire
            (id_bp_questionnaire,
             id_hemo_type,
             id_questionnaire,
             flg_time,
             flg_type,
             flg_mandatory,
             rank,
             flg_available,
             id_response,
             flg_copy,
             flg_validation,
             flg_exterior,
             id_unit_measure,
             id_institution)
            SELECT seq_bp_questionnaire.nextval,
                   def_data.id_hemo_type,
                   def_data.id_questionnaire,
                   def_data.flg_time,
                   def_data.flg_type,
                   def_data.flg_mandatory,
                   def_data.rank,
                   def_data.flg_available,
                   def_data.id_response,
                   def_data.flg_copy,
                   def_data.flg_validation,
                   def_data.flg_exterior,
                   def_data.id_unit_measure,
                   i_institution
              FROM (SELECT temp_data.id_hemo_type,
                           temp_data.id_questionnaire,
                           temp_data.flg_time,
                           temp_data.flg_type,
                           temp_data.flg_mandatory,
                           temp_data.rank,
                           temp_data.flg_available,
                           temp_data.id_response,
                           temp_data.flg_copy,
                           temp_data.flg_validation,
                           temp_data.flg_exterior,
                           temp_data.id_unit_measure,
                           row_number() over(PARTITION BY temp_data.id_hemo_type, temp_data.id_questionnaire, temp_data.flg_time, temp_data.id_response ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(ad_bq.id_hemo_type,
                                          NULL,
                                          NULL,
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT a_ht.id_hemo_type
                                                       FROM hemo_type a_ht
                                                       JOIN ad_hemo_type ad_ht
                                                         ON a_ht.id_content = ad_ht.id_content
                                                      WHERE ad_ht.id_hemo_type = ad_bq.id_hemo_type
                                                        AND ad_ht.flg_available = g_flg_available
                                                        AND a_ht.flg_available = g_flg_available),
                                                     0),
                                                 nvl((SELECT a_ht.id_hemo_type
                                                       FROM hemo_type a_ht
                                                       JOIN ad_hemo_type ad_ht
                                                         ON a_ht.id_content = ad_ht.id_content
                                                      WHERE ad_ht.id_hemo_type = ad_bq.id_hemo_type
                                                        AND ad_ht.flg_available = g_flg_available
                                                        AND a_ht.flg_available = g_flg_available
                                                        AND ad_ht.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                                     0))) id_hemo_type,
                                   nvl((SELECT a_q.id_questionnaire
                                         FROM questionnaire a_q
                                        INNER JOIN ad_questionnaire ad_q
                                           ON a_q.id_content = ad_q.id_content
                                        WHERE ad_q.id_questionnaire = ad_bq.id_questionnaire
                                          AND ad_q.flg_available = g_flg_available
                                          AND a_q.flg_available = g_flg_available),
                                       0) id_questionnaire,
                                   ad_bq.flg_time,
                                   ad_bq.flg_type,
                                   ad_bq.flg_mandatory,
                                   ad_bq.rank,
                                   ad_bq.flg_available,
                                   decode(ad_bq.id_response,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_r.id_response
                                                FROM response a_r
                                               INNER JOIN ad_response ad_r
                                                  ON ad_r.id_content = a_r.id_content
                                               WHERE a_r.flg_available = g_flg_available
                                                 AND ad_r.flg_available = g_flg_available
                                                 AND ad_r.id_response = ad_bq.id_response),
                                              0)) id_response,
                                   ad_bq.flg_copy,
                                   ad_bq.flg_validation,
                                   ad_bq.flg_exterior,
                                   decode(ad_bq.id_unit_measure_subtype,
                                          NULL,
                                          NULL,
                                          nvl((SELECT ums.id_unit_measure_subtype
                                                FROM a_unit_measure_subtype ums
                                               WHERE ums.id_unit_measure_subtype = ad_bq.id_unit_measure_subtype),
                                              0)) id_unit_measure,
                                   ad_bq.id_market,
                                   ad_bq.version
                            -- decode FKS to dest_vals
                              FROM ad_bp_questionnaire ad_bq
                             WHERE ad_bq.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_bq.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND (def_data.id_hemo_type > 0 OR def_data.id_hemo_type IS NULL)
               AND (def_data.id_response > 0 OR def_data.id_response IS NULL)
               AND (def_data.id_unit_measure > 0 OR def_data.id_unit_measure IS NULL)
               AND def_data.id_questionnaire > 0
               AND EXISTS (SELECT 0
                      FROM questionnaire_response a_qr
                     WHERE a_qr.id_questionnaire = def_data.id_questionnaire
                       AND (a_qr.id_response = def_data.id_response OR
                           (a_qr.id_response IS NULL AND def_data.id_response IS NULL)))
               AND NOT EXISTS (SELECT 0
                      FROM bp_questionnaire a_bpq
                     WHERE (a_bpq.id_hemo_type = def_data.id_hemo_type OR
                           (a_bpq.id_hemo_type IS NULL AND def_data.id_hemo_type IS NULL))
                       AND (a_bpq.id_response = def_data.id_response OR
                           (a_bpq.id_response IS NULL AND def_data.id_response IS NULL))
                       AND a_bpq.id_questionnaire = id_questionnaire
                       AND a_bpq.id_institution = i_institution
                       AND a_bpq.flg_time = def_data.flg_time
                       AND a_bpq.flg_available = g_flg_available);
                       
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
    END set_bp_questionnaire_search;

    FUNCTION del_bp_questionnaire_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
      
        g_error     := 'delete bp_questionnaire';
        g_func_name := upper('DEL_BP_QUESTIONNAIRE_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_sw_list
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_sw_list.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM bp_questionnaire a_bq
             WHERE a_bq.id_institution = i_institution;
        
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
    END del_bp_questionnaire_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_blood_product_prm;
/