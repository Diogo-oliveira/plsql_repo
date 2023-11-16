/*-- Last Change Revision: $Rev: 1991042 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2021-06-03 16:28:45 +0100 (qui, 03 jun 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_doc_area_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_doc_area_prm';
    pos_soft        NUMBER := 1;
    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_doc_area_is_search
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
    
        g_func_name := upper('set_doc_area_is_search');
    
        INSERT INTO doc_area_inst_soft
            (id_doc_area_inst_soft,
             id_doc_area,
             flg_mode,
             flg_type,
             flg_switch_mode,
             flg_multiple,
             id_sys_shortcut_error,
             id_institution,
             id_software,
             id_market)
            SELECT seq_doc_area_inst_soft.nextval,
                   def_data.id_doc_area,
                   def_data.flg_mode,
                   def_data.flg_type,
                   def_data.flg_switch_mode,
                   def_data.flg_multiple,
                   def_data.id_sys_shortcut_error,
                   i_institution,
                   i_software(pos_soft),
                   NULL
              FROM (SELECT temp_data.id_doc_area,
                           temp_data.flg_mode,
                           temp_data.flg_type,
                           temp_data.flg_switch_mode,
                           temp_data.flg_multiple,
                           temp_data.id_sys_shortcut_error,
                           row_number() over(PARTITION BY temp_data.id_doc_area ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT dais.rowid l_row,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_da.id_doc_area
                                                FROM doc_area a_da
                                               WHERE a_da.id_doc_area = dais.id_doc_area
                                                 AND a_da.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_da.id_doc_area
                                                FROM doc_area a_da
                                               WHERE a_da.id_doc_area = dais.id_doc_area
                                                 AND a_da.flg_available = g_flg_available
                                                 AND to_char(a_da.id_doc_area) IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_doc_area,
                                   dais.flg_mode,
                                   dais.flg_type,
                                   dais.flg_switch_mode,
                                   dais.flg_multiple,
                                   dais.id_sys_shortcut_error,
                                   dais.id_software,
                                   damv.id_market,
                                   damv.version
                            -- decode FKS to dest_vals
                              FROM ad_doc_area_mrk_vrs damv
                              JOIN ad_doc_area_inst_soft dais
                                ON dais.id_doc_area = damv.id_doc_area
                              JOIN doc_area da
                                ON da.id_doc_area = damv.id_doc_area
                             WHERE da.flg_available = g_flg_available
                               AND dais.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND damv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND damv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_doc_area != 0
               AND NOT EXISTS (SELECT 0
                      FROM doc_area_inst_soft dais1
                     WHERE dais1.id_doc_area = def_data.id_doc_area
                       AND dais1.id_software = i_software(pos_soft)
                       AND dais1.id_institution = i_institution
                       AND dais1.id_market IS NULL);
    
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
    END set_doc_area_is_search;

    FUNCTION del_doc_area_is_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete doc_area_inst_soft';
        g_func_name := upper('DEL_DOC_AREA_IS_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM doc_area_inst_soft a_dais
             WHERE a_dais.id_institution = i_institution
               AND a_dais.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
        
            DELETE FROM doc_area_inst_soft dais
             WHERE dais.id_institution = i_institution;
        
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
    END del_doc_area_is_search;

    /********************************************************************************************
    * Set Default Dashboard areas configuration
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/15
    ********************************************************************************************/
    FUNCTION set_dash_da_mkt_search
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
        g_func_name := upper('set_dash_da_mkt_search');
        g_error     := 'LOAD DASHBOARD DOC AREAS BY MKT';
    
        INSERT INTO dash_doc_area_mkt
            (id_doc_area, id_market, flg_available)
            SELECT def_data.id_doc_area, def_data.id_market, g_flg_available
              FROM (SELECT temp_data.id_doc_area,
                           temp_data.id_market,
                           row_number() over(PARTITION BY temp_data.id_doc_area, temp_data.id_market ORDER BY decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_da.id_doc_area
                                                FROM doc_area a_da
                                               WHERE a_da.id_doc_area = def_tbl.id_doc_area
                                                 AND a_da.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_da.id_doc_area
                                                FROM doc_area a_da
                                               WHERE a_da.id_doc_area = def_tbl.id_doc_area
                                                 AND a_da.flg_available = g_flg_available
                                                 AND to_char(a_da.id_doc_area) IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_doc_area,
                                   def_tbl.id_market,
                                   def_tbl.version
                              FROM alert_default.dash_doc_area_mkt def_tbl
                             WHERE def_tbl.flg_available = g_flg_available
                               AND def_tbl.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND def_tbl.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)) temp_data
                     WHERE NOT EXISTS (SELECT 0
                              FROM dash_doc_area_mkt dest_tbl
                             WHERE dest_tbl.id_doc_area = temp_data.id_doc_area
                               AND dest_tbl.id_market = temp_data.id_market
                               AND dest_tbl.flg_available = g_flg_available)) def_data
             WHERE def_data.records_count = 1;
    
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
    END set_dash_da_mkt_search;
    /********************************************************************************************
    * Set Default Dashboard areas configuration
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/15
    ********************************************************************************************/
    FUNCTION set_dash_da_inst_search
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
    
        g_func_name := upper('set_dash_da_inst_search');
        g_error     := 'LOAD DASHBOARD DOC AREAS BY INSTITUTION';
    
        INSERT INTO dash_doc_area_inst
            (id_doc_area, id_institution, flg_available)
            SELECT def_data.id_doc_area, i_institution, g_flg_available
              FROM (SELECT temp_data.id_doc_area,
                           row_number() over(PARTITION BY temp_data.id_doc_area ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_da.id_doc_area
                                                FROM doc_area a_da
                                               WHERE a_da.id_doc_area = def_tbl.id_doc_area
                                                 AND a_da.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_da.id_doc_area
                                                FROM doc_area a_da
                                               WHERE a_da.id_doc_area = def_tbl.id_doc_area
                                                 AND a_da.flg_available = g_flg_available
                                                 AND to_char(a_da.id_doc_area) IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_doc_area,
                                   def_tbl.id_market,
                                   def_tbl.version
                              FROM alert_default.dash_doc_area_mkt def_tbl
                             WHERE def_tbl.flg_available = g_flg_available
                               AND def_tbl.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND def_tbl.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)) temp_data
                     WHERE NOT EXISTS (SELECT 0
                              FROM dash_doc_area_inst dest_tbl
                             WHERE dest_tbl.id_doc_area = temp_data.id_doc_area
                               AND dest_tbl.id_institution = i_institution
                               AND dest_tbl.flg_available = g_flg_available)) def_data
             WHERE def_data.records_count = 1;
    
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
    END set_dash_da_inst_search;
    -- frequent loader method

    FUNCTION del_dash_da_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete dash_doc_area_inst';
        g_func_name := upper('del_dash_da_inst_search');
    
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
            DELETE FROM dash_doc_area_inst dcai
             WHERE dcai.id_institution = i_institution;
        
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
    END del_dash_da_inst_search;

    /**
    * Load doc_category from default table
    *
    * @param i_lang                   Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error                 Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/07/08
    */

    FUNCTION load_doc_category_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('doc_category.code_doc_category.');
    
    BEGIN
        --inserts all available records into alert, from alert_default, that do not exist in alert 
        INSERT INTO doc_category
            (id_doc_category, internal_name, code_doc_category, flg_available, id_content)
            SELECT seq_doc_category.nextval,
                   internal_name,
                   l_code_translation || seq_doc_category.currval,
                   g_flg_available,
                   id_content
              FROM (SELECT ad_dc.internal_name, ad_dc.id_content
                      FROM ad_doc_category ad_dc
                     WHERE ad_dc.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM doc_category adc
                             WHERE adc.id_content = ad_dc.id_content
                               AND adc.flg_available = g_flg_available)) def_data;
    
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
    END load_doc_category_def;

    /**
    * Set Default Doc category for institution and software
    *
    * @param i_lang                    Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_mkt                    Market ID
    * @param i_vers                    Content Version
    * @param i_id_software         Software ID
    * @param i_id_content           Content ID
    * @param o_result_tbl           Number of records inserted
    * @param o_error                  Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.7.4.5
    * @since                        2019/07/05
    */

    FUNCTION set_doc_cat_inst_soft
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
    
        g_func_name := upper('set_doc_cat_inst_soft');
    
        INSERT INTO doc_category_inst_soft
            (id_doc_cat_inst_soft, id_doc_category, id_software, id_institution, rank)
            SELECT seq_doc_cat_inst_soft.nextval,
                   def_data.id_doc_category,
                   i_software(pos_soft),
                   i_institution,
                   def_data.rank
              FROM (SELECT temp_data.id_doc_category,
                           row_number() over(PARTITION BY temp_data.id_doc_category ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank,
                           temp_data.rank
                      FROM (SELECT nvl((SELECT a_dc.id_doc_category
                                         FROM doc_category a_dc
                                         JOIN ad_doc_category ad_dc
                                           ON a_dc.id_content = ad_dc.id_content
                                        WHERE ad_dc.id_doc_category = ad_dcmv.id_doc_category
                                          AND a_dc.flg_available = g_flg_available
                                          AND ad_dc.flg_available = g_flg_available),
                                       0) id_doc_category,
                                   ad_dcs.id_software,
                                   ad_dcmv.id_market,
                                   ad_dcmv.version,
                                   ad_dcs.rank
                              FROM ad_doc_category_mkt_vrs ad_dcmv
                              JOIN ad_doc_category_software ad_dcs
                                ON ad_dcs.id_doc_category = ad_dcmv.id_doc_category
                             WHERE ad_dcs.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_dcmv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_dcmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_rank = 1
               AND def_data.id_doc_category != 0
               AND NOT EXISTS (SELECT 0
                      FROM doc_category_inst_soft adcis
                     WHERE adcis.id_doc_category = def_data.id_doc_category
                       AND adcis.id_institution = i_institution
                       AND adcis.id_software = i_software(pos_soft));
    
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
    END set_doc_cat_inst_soft;

    /**
    * Configure doc_areas requested associated to categories for institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution       Institution ID
    * @param i_mkt                     Market ID
    * @param i_vers                     Content Version
    * @param i_id_software          Software ID
    * @param i_id_content           Content ID
    * @param o_result_tbl            Number of records inserted
    * @param o_error                   Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/07/05
    */

    FUNCTION set_doc_cat_area_inst_soft
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
    
        g_func_name := upper('set_doc_cat_area_inst_soft');
    
        INSERT INTO doc_category_area_inst_soft
            (id_doc_cat_area_inst_soft, id_doc_category, id_doc_area, id_institution, id_software, flg_available, rank)
            SELECT seq_doc_cat_area_inst_soft.nextval,
                   def_data.id_doc_category,
                   def_data.id_doc_area,
                   i_institution,
                   i_software(pos_soft),
                   def_data.flg_available,
                   def_data.rank
              FROM (SELECT temp_data.id_doc_category,
                           row_number() over(PARTITION BY temp_data.id_doc_category, temp_data.id_doc_area ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank,
                           temp_data.id_doc_area,
                           temp_data.flg_available,
                           temp_data.rank
                      FROM (SELECT nvl((SELECT a_dc.id_doc_category
                                         FROM doc_category a_dc
                                         JOIN ad_doc_category ad_dc
                                           ON a_dc.id_content = ad_dc.id_content
                                        WHERE ad_dc.id_doc_category = ad_dcamv.id_doc_category
                                          AND a_dc.flg_available = g_flg_available
                                          AND ad_dc.flg_available = g_flg_available),
                                       0) id_doc_category,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_da.id_doc_area
                                                FROM doc_area a_da
                                               WHERE a_da.id_doc_area = ad_dcamv.id_doc_area
                                                 AND a_da.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_da.id_doc_area
                                                FROM doc_area a_da
                                               WHERE a_da.id_doc_area = ad_dcamv.id_doc_area
                                                 AND a_da.flg_available = g_flg_available
                                                 AND to_char(a_da.id_doc_area) IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_doc_area,
                                   ad_dcas.flg_available,
                                   ad_dcamv.rank,
                                   ad_dcamv.version,
                                   ad_dcamv.id_market
                              FROM ad_doc_category_area_mkt_vrs ad_dcamv
                              JOIN ad_doc_category_area_software ad_dcas
                                ON ad_dcas.id_doc_area = ad_dcamv.id_doc_area
                               AND ad_dcas.flg_available = g_flg_available
                             WHERE ad_dcas.flg_available = g_flg_available
                               AND ad_dcamv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_dcamv.version IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_dcas.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)) temp_data) def_data
             WHERE def_data.records_rank = 1
               AND def_data.id_doc_category != 0
               AND def_data.id_doc_area != 0
               AND NOT EXISTS (SELECT 0
                      FROM doc_category_area_inst_soft adcais
                     WHERE adcais.id_doc_category = def_data.id_doc_category
                       AND adcais.id_doc_area = def_data.id_doc_area
                       AND adcais.id_institution = i_institution
                       AND adcais.id_software = i_software(pos_soft));
    
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
    END set_doc_cat_area_inst_soft;

    /**
    * Delete Doc category per institution and software
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution       Institution ID
    * @param i_id_software          Software ID
    * @param o_result_tbl            Number of records inserted
    * @param o_error                   Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/07/09
    */

    FUNCTION del_doc_cat_inst_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete DOC_CATEGORY_INST_SOFT';
        g_func_name := upper('del_doc_cat_inst_soft');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM doc_category_inst_soft a_dcis
             WHERE a_dcis.id_institution = i_institution
               AND a_dcis.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM doc_category_inst_soft adcis
             WHERE adcis.id_institution = i_institution;
        
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
        
    END del_doc_cat_inst_soft;

    /**
    * Delete Doc category associated to areas per institution and software
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution       Institution ID
    * @param i_id_software          Software ID
    * @param o_result_tbl            Number of records inserted
    * @param o_error                   Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/07/09
    */

    FUNCTION del_doc_cat_area_inst_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete DOC_CATEGORY_AREA_INST_SOFT';
        g_func_name := upper('del_doc_cat_area_inst_soft');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM doc_category_area_inst_soft a_dcais
             WHERE a_dcais.id_institution = i_institution
               AND a_dcais.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                            column_value
                                             FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
        
            DELETE FROM doc_category_area_inst_soft adcais
             WHERE adcais.id_institution = i_institution;
        
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
        
    END del_doc_cat_area_inst_soft;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_doc_area_prm;
/
