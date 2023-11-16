/*-- Last Change Revision: $Rev:$*/
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/

CREATE OR REPLACE PACKAGE BODY pk_meds_association_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'pk_meds_association_prm';
    pos_soft        NUMBER := 1;

    --function set_lnk_product_intervention and del_lnk_product_intervention previously in pk_lnk_product_intervention_prm (now deprecated)

    /**
    *  Get id_product_supplier
    *
    * @param i_lang                        Prefered language ID
    * @param i_institution               ID institutio
    * @param o_error                      Error
    *
    * @return                            Table_varchar 
    *
    * @author                           Adriana Salgueiro
    * @version                          v2.8.2.0
    * @since                             2020/05/20
    */

    FUNCTION get_supplier
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN VARCHAR AS
    
        o_id_supplier VARCHAR2(30);
    
    BEGIN
    
        g_func_name := upper('GET_SUPPLIER');
    
        SELECT DISTINCT apm_smi.id_supplier
          INTO o_id_supplier
          FROM apm_supplier_mkt_inst apm_smi
          JOIN institution a_i
            ON apm_smi.id_market = a_i.id_market
         WHERE a_i.id_institution = i_institution
           AND apm_smi.flg_available = g_flg_available;
    
        dbms_output.put_line(o_id_supplier);
    
        RETURN o_id_supplier;
    
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
            NULL;
            RETURN NULL;
        
    END get_supplier;

    /**
    * Configure association between interventions and mediation per software
    *
    * @param i_lang                     Prefered language ID
    * @param i_mkt                     Market ID
    * @param i_vers                     Content Version
    * @param i_id_software          Software ID
    * @param i_id_content           Product id content
    * @param o_result_tbl            Number of records inserted
    * @param o_error                   Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.1.0
    * @since                        2019/12/24
    * @update                      2020/02/26
    */

    FUNCTION set_lnk_product_intervention
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
    
        l_id_context          VARCHAR2(200) := 'LNK_PRODUCT_INTERVENTION';
        l_grant               NUMBER;
        l_flg_default         NUMBER;
        l_grant_order         NUMBER := 20;
        l_cnt_count           NUMBER := i_id_content.count;
        l_id_product_supplier VARCHAR2(30);
    
    BEGIN
    
        g_func_name := upper('SET_LNK_PRODUCT_INTERVENTION');
    
        l_id_product_supplier := get_supplier(i_lang => i_lang, i_institution => i_institution, o_error => o_error);
    
        l_grant := alert_product_mt.pk_grants.set_by_soft_inst(i_context     => l_id_context,
                                                               i_prof        => (profissional(0,
                                                                                              i_institution,
                                                                                              i_software(pos_soft))),
                                                               i_grant_order => l_grant_order);
    
        SELECT COUNT(ad_lpi.flg_default)
          INTO l_flg_default
          FROM apm_lnk_product_intervention apm_lpi
          JOIN ad_lnk_product_intervention ad_lpi
            ON apm_lpi.id_product = ad_lpi.id_product
           AND apm_lpi.id_product_supplier = ad_lpi.id_product_supplier
           AND apm_lpi.id_grant = l_grant
         WHERE apm_lpi.flg_available = g_flg_available
           AND apm_lpi.flg_default = g_flg_available;
    
        INSERT INTO apm_lnk_product_intervention ad_lpi
            (id_product, id_product_supplier, id_intervention, flg_default, flg_available, id_grant)
            SELECT def_data.id_product,
                   def_data.id_product_supplier,
                   def_data.id_intervention,
                   def_data.flg_default,
                   def_data.flg_available,
                   l_grant
              FROM (SELECT temp_data.id_product,
                           temp_data.id_product_supplier,
                           temp_data.id_intervention,
                           temp_data.flg_default,
                           temp_data.flg_available,
                           row_number() over(PARTITION BY temp_data.id_product, temp_data.id_product_supplier, temp_data.id_intervention ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          ad_lpi.id_product,
                                          nvl((SELECT id_product
                                                FROM apm_product apm_p
                                               WHERE apm_p.id_product = ad_lpi.id_product
                                                 AND apm_p.id_product_supplier = l_id_product_supplier
                                                 AND apm_p.flg_available = g_flg_available
                                                 AND apm_p.id_product IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              '0')) id_product,
                                   ad_lpi.id_product_supplier,
                                   nvl((SELECT a_i.id_intervention
                                         FROM intervention a_i
                                         JOIN ad_intervention ad_i
                                           ON ad_i.id_content = a_i.id_content
                                          AND ad_i.flg_status = g_active
                                        WHERE ad_i.id_intervention = ad_lpi.id_intervention
                                          AND a_i.flg_status = g_active),
                                       0) id_intervention,
                                   CASE
                                        WHEN l_flg_default > 0 THEN
                                         'N'
                                        WHEN l_flg_default = 0 THEN
                                         ad_lpi.flg_default
                                    END AS flg_default,
                                   ad_lpi.flg_available,
                                   ad_lpi.id_market,
                                   ad_lpi.version
                              FROM ad_lnk_product_intervention ad_lpi
                             WHERE ad_lpi.flg_available = g_flg_available
                               AND ad_lpi.id_product_supplier = l_id_product_supplier
                               AND EXISTS
                             (SELECT 0
                                      FROM apm_product apm_p2
                                     WHERE apm_p2.id_product = ad_lpi.id_product
                                       AND apm_p2.id_product_supplier = l_id_product_supplier
                                       AND apm_p2.flg_available = g_flg_available)
                               AND ad_lpi.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_lpi.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_lpi.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)) temp_data) def_data
             WHERE def_data.records_rank = 1
               AND def_data.id_intervention != 0
               AND def_data.id_product != '0'
               AND NOT EXISTS (SELECT 1
                      FROM apm_lnk_product_intervention apm_lpi
                     WHERE apm_lpi.id_product = def_data.id_product
                       AND apm_lpi.id_product_supplier = def_data.id_product_supplier
                       AND apm_lpi.id_grant = l_grant
                       AND apm_lpi.id_intervention = def_data.id_intervention);
    
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
    END set_lnk_product_intervention;

    /**
    * Delete all associations between interventions and id_products for a specific a specific instit per grant
    *
    * @param i_lang                        Prefered language ID
    * @param i_id_institution          Institution ID
    * @param i_id_software             Software ID
    * @param o_result_tbl               Number of records inserted
    * @param o_error                      Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/12/24
    */

    FUNCTION del_lnk_product_intervention
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all            table_number := table_number();
        l_result_tbl          NUMBER := 0;
        l_id_context          VARCHAR2(200) := 'LNK_PRODUCT_INTERVENTION';
        l_grant               NUMBER;
        l_grant_order         NUMBER := 20;
        l_id_product_supplier VARCHAR2(30);
    
    BEGIN
    
        g_error := 'delete lnk_product_intervention';
    
        g_func_name := upper('DEL_LNK_PRODUCT_INTERVENTION');
    
        l_grant := alert_product_mt.pk_grants.set_by_soft_inst(i_context     => l_id_context,
                                                               i_prof        => (profissional(0,
                                                                                              i_institution,
                                                                                              i_software(pos_soft))),
                                                               i_grant_order => l_grant_order);
    
        l_id_product_supplier := get_supplier(i_lang => i_lang, i_institution => i_institution, o_error => o_error);
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
        
            FOR i IN 1 .. i_software.count
            LOOP
            
                DELETE FROM apm_lnk_product_intervention ad_lpi
                 WHERE ad_lpi.id_grant = l_grant
                   AND ad_lpi.id_product_supplier = l_id_product_supplier;
            
                l_result_tbl := l_result_tbl + SQL%ROWCOUNT;
            
            END LOOP;
        
            o_result_tbl := l_result_tbl;
        
        ELSE
        
            DELETE FROM apm_lnk_product_intervention ad_lpi
             WHERE ad_lpi.id_product_supplier = l_id_product_supplier;
        
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
        
    END del_lnk_product_intervention;

    /**
    * Configure association between analysis param and mediation per software
    *
    * @param i_lang                     Prefered language ID
    * @param i_mkt                     Market ID
    * @param i_vers                     Content Version
    * @param i_id_software          Software ID
    * @param i_id_content           Product id content
    * @param o_result_tbl            Number of records inserted
    * @param o_error                   Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.1.0
    * @since                        2019/12/24
    * @update                      2020/02/26
    */

    FUNCTION set_lnk_prod_analysis_param
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
    
        l_id_context          VARCHAR2(200) := 'LNK_PROD_ANALYSIS_PARAM';
        l_grant               NUMBER;
        l_grant_order         NUMBER := 20;
        l_cnt_count           NUMBER := i_id_content.count;
        l_id_product_supplier VARCHAR2(30);
    
    BEGIN
    
        g_func_name := upper('SET_LNK_PROD_ANALYSIS_PARAM');
    
        l_id_product_supplier := get_supplier(i_lang => i_lang, i_institution => i_institution, o_error => o_error);
    
        l_grant := alert_product_mt.pk_grants.set_by_soft_inst(i_context     => l_id_context,
                                                               i_prof        => (profissional(0,
                                                                                              i_institution,
                                                                                              i_software(pos_soft))),
                                                               i_grant_order => l_grant_order);
    
        INSERT INTO apm_lnk_prod_analysis_param
            (id_product, id_product_supplier, id_analysis_param, flg_available, id_grant)
            SELECT def_data.id_product,
                   def_data.id_product_supplier,
                   def_data.id_analysis_param,
                   def_data.flg_available,
                   l_grant
              FROM (SELECT temp_data.id_product,
                           temp_data.id_product_supplier,
                           temp_data.id_analysis_param,
                           temp_data.flg_available,
                           row_number() over(PARTITION BY temp_data.id_product, temp_data.id_product_supplier, temp_data.id_analysis_param ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          ad_lpap.id_product,
                                          nvl((SELECT id_product
                                                FROM apm_product apm_p
                                               WHERE apm_p.id_product = ad_lpap.id_product
                                                 AND apm_p.id_product_supplier = ad_lpap.id_product_supplier
                                                 AND apm_p.id_product_supplier = l_id_product_supplier
                                                 AND apm_p.flg_available = g_flg_available
                                                 AND apm_p.id_product IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              '0')) id_product,
                                   ad_lpap.id_product_supplier,
                                   nvl((SELECT a_ap.id_analysis_param
                                         FROM analysis_param a_ap
                                         JOIN analysis_parameter a_apr
                                           ON a_ap.id_analysis_parameter = a_apr.id_analysis_parameter
                                          AND a_apr.flg_available = g_flg_available
                                         JOIN analysis_sample_type a_ast
                                           ON a_ast.flg_available = g_flg_available
                                          AND a_ap.id_analysis = a_ast.id_analysis
                                          AND a_ap.id_sample_type = a_ast.id_sample_type
                                        WHERE a_ap.flg_available = g_flg_available
                                          AND a_ap.id_software IN
                                              (SELECT /*+ dynamic_sampling(2)*/
                                                column_value
                                                 FROM TABLE(CAST(i_software AS table_number)) p)
                                          AND a_ap.id_institution = i_institution
                                          AND a_apr.id_content = ad_apr.id_content
                                          AND a_ast.id_content = ad_ast.id_content),
                                       0) id_analysis_param,
                                   ad_lpap.flg_available,
                                   ad_lpap.id_market,
                                   ad_lpap.version
                              FROM ad_lnk_prod_analysis_param ad_lpap
                              JOIN ad_analysis_param ad_ap
                                ON ad_lpap.id_analysis_param = ad_ap.id_analysis_param
                               AND ad_ap.flg_available = g_flg_available
                              JOIN ad_analysis_parameter ad_apr
                                ON ad_ap.id_analysis_parameter = ad_apr.id_analysis_parameter
                               AND ad_apr.flg_available = g_flg_available
                              JOIN ad_analysis_sample_type ad_ast
                                ON ad_ast.id_analysis = ad_ap.id_analysis
                               AND ad_ast.id_sample_type = ad_ap.id_sample_type
                               AND ad_ast.flg_available = g_flg_available
                             WHERE ad_lpap.flg_available = g_flg_available
                               AND ad_lpap.id_market IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_lpap.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_rank = 1
               AND def_data.id_analysis_param != 0
               AND def_data.id_product != '0'
               AND NOT EXISTS (SELECT 1
                      FROM apm_lnk_prod_analysis_param apm_lpap
                     WHERE apm_lpap.id_product = def_data.id_product
                       AND apm_lpap.id_product_supplier = def_data.id_product_supplier
                       AND apm_lpap.id_grant = l_grant
                       AND apm_lpap.id_analysis_param = def_data.id_analysis_param);
    
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
    END set_lnk_prod_analysis_param;

    /**
    * Delete all associations between analysis_param and id_products for a specific a specific instit per grant
    *
    * @param i_lang                        Prefered language ID
    * @param i_id_institution          Institution ID
    * @param i_id_software             Software ID
    * @param o_result_tbl               Number of records inserted
    * @param o_error                      Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/12/24
    */

    FUNCTION del_lnk_prod_analysis_param
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all            table_number := table_number();
        l_result_tbl          NUMBER := 0;
        l_id_context          VARCHAR2(200) := 'LNK_PROD_ANALYSIS_PARAM';
        l_grant               NUMBER;
        l_grant_order         NUMBER := 20;
        l_id_product_supplier VARCHAR2(30);
    
    BEGIN
    
        g_error := 'DELETE LNK_PROD_ANALYSIS_PARAM';
    
        g_func_name := upper('DEL_LNK_PROD_ANALYSIS_PARAM');
    
        l_grant := alert_product_mt.pk_grants.set_by_soft_inst(i_context     => l_id_context,
                                                               i_prof        => (profissional(0,
                                                                                              i_institution,
                                                                                              i_software(pos_soft))),
                                                               i_grant_order => l_grant_order);
    
        l_id_product_supplier := get_supplier(i_lang => i_lang, i_institution => i_institution, o_error => o_error);
    
        dbms_output.put_line(l_grant);
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            FOR i IN 1 .. i_software.count
            LOOP
            
                DELETE FROM apm_lnk_prod_analysis_param ad_lpap
                 WHERE ad_lpap.id_grant = l_grant
                   AND ad_lpap.id_product_supplier = l_id_product_supplier;
            
                l_result_tbl := l_result_tbl + SQL%ROWCOUNT;
            
            END LOOP;
        
            o_result_tbl := l_result_tbl;
        
        ELSE
        
            DELETE FROM apm_lnk_prod_analysis_param ad_lpap
             WHERE ad_lpap.id_product_supplier = l_id_product_supplier;
        
            o_result_tbl := l_result_tbl + SQL%ROWCOUNT;
        
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
        
    END del_lnk_prod_analysis_param;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

END pk_meds_association_prm;
/
