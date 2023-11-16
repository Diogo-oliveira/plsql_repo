/*-- Last Change Revision: $Rev: 1904835 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-05 09:32:58 +0100 (qua, 05 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_complication_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_complication_prm';

    -- Private Methods

    -- content loader method
    FUNCTION load_complication_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('complication.code_complication.');
    BEGIN
        g_func_name := upper('load_complication_def');
    
        INSERT INTO complication
            (id_complication, code_complication, code, flg_available, id_content, id_comp_axe)
            SELECT seq_complication.nextval,
                   l_code_translation || seq_complication.currval,
                   code,
                   g_flg_available,
                   id_content,
                   id_comp_axe
              FROM (SELECT adc.id_complication,
                           adc.code,
                           adc.id_content,
                           decode(adc.id_comp_axe,
                                  NULL,
                                  NULL,
                                  nvl((SELECT ca.id_comp_axe
                                        FROM comp_axe ca
                                        JOIN alert_default.comp_axe aca
                                          ON ca.id_content = aca.id_content
                                       WHERE aca.id_comp_axe = adc.id_comp_axe
                                         AND ca.flg_available = g_flg_available
                                         AND aca.flg_available = g_flg_available
                                         AND rownum = 1),
                                      0)) id_comp_axe
                      FROM alert_default.complication adc
                     WHERE adc.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM complication dest_tbl
                             WHERE dest_tbl.id_content = adc.id_content)) def_data
             WHERE def_data.id_comp_axe > 0
                OR def_data.id_comp_axe IS NULL;
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
    END load_complication_def;

    FUNCTION load_comp_axe_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('comp_axe.code_comp_axe.');
    BEGIN
        g_func_name := upper('load_comp_axe_def');
        INSERT INTO comp_axe
            (id_comp_axe, code_comp_axe, code, flg_available, id_content, id_sys_list)
            SELECT seq_comp_axe.nextval,
                   l_code_translation || seq_comp_axe.currval,
                   code,
                   g_flg_available,
                   id_content,
                   id_sys_list
              FROM (SELECT ca.id_comp_axe,
                           ca.id_content,
                           ca.code,
                           nvl((SELECT id_sys_list
                                 FROM sys_list isl
                                WHERE isl.id_sys_list = ca.id_sys_list),
                               0) id_sys_list
                      FROM alert_default.comp_axe ca
                     WHERE ca.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM comp_axe dest_tbl
                             WHERE dest_tbl.id_content = ca.id_content
                               AND dest_tbl.flg_available = g_flg_available)) def_data
             WHERE def_data.id_sys_list > 0;
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
    END load_comp_axe_def;

    FUNCTION load_comp_axe_group_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('comp_axe_group.code_comp_axe_group.');
        l_level_array      table_number := table_number();
    BEGIN
        g_func_name := upper('load_ comp_axe_group_def');
    
        SELECT DISTINCT LEVEL BULK COLLECT
          INTO l_level_array
          FROM alert_default.comp_axe_group cag
         WHERE cag.flg_available = g_flg_available
         START WITH cag.id_parent_group IS NULL
        CONNECT BY PRIOR cag.id_comp_axe_group = cag.id_parent_group
         ORDER BY LEVEL ASC;
    
        FORALL c_level IN 1 .. l_level_array.count
            INSERT INTO comp_axe_group
                (id_comp_axe_group,
                 code_comp_axe_group,
                 code,
                 flg_available,
                 flg_exclusive,
                 flg_required,
                 id_parent_group,
                 flg_parent_grp_context,
                 id_content)
                SELECT seq_comp_axe_group.nextval,
                       l_code_translation || seq_comp_axe_group.currval,
                       code,
                       g_flg_available,
                       flg_exclusive,
                       flg_required,
                       id_parent_group,
                       flg_parent_grp_context,
                       id_content
                  FROM (SELECT cag.id_comp_axe_group,
                               cag.id_content,
                               cag.code,
                               cag.flg_exclusive,
                               cag.flg_required,
                               decode(cag.id_parent_group,
                                      NULL,
                                      NULL,
                                      nvl((SELECT c.id_comp_axe_group
                                            FROM comp_axe_group c
                                            JOIN alert_default.comp_axe_group cag2
                                              ON c.id_content = cag2.id_content
                                           WHERE cag2.id_comp_axe_group = cag.id_parent_group
                                             AND cag2.flg_available = g_flg_available
                                             AND c.flg_available = g_flg_available),
                                          0)) id_parent_group,
                               cag.flg_parent_grp_context,
                               LEVEL lvl
                          FROM alert_default.comp_axe_group cag
                         WHERE cag.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT dest_tbl.id_comp_axe_group
                                  FROM comp_axe_group dest_tbl
                                 WHERE dest_tbl.id_content = cag.id_content
                                   AND dest_tbl.flg_available = g_flg_available)
                         START WITH cag.id_parent_group IS NULL
                        CONNECT BY PRIOR cag.id_comp_axe_group = cag.id_parent_group) def_data
                 WHERE def_data.lvl = l_level_array(c_level)
                   AND (def_data.id_parent_group > 0 OR def_data.id_parent_group IS NULL);
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
    END load_comp_axe_group_def;
    -- searcheable loader method
    FUNCTION set_comp_axe_detail_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_comp_axe_detail_search');
        INSERT INTO comp_axe_detail
            (id_comp_axe_detail, id_comp_axe, id_parent_axe, id_comp_axe_group)
        
            SELECT seq_comp_axe_detail.nextval, def_data.i_comp_axe, def_data.i_parent_axe, def_data.i_comp_axe_group
              FROM (SELECT temp_data.i_comp_axe,
                           temp_data.i_parent_axe,
                           temp_data.i_comp_axe_group,
                           row_number() over(PARTITION BY temp_data.i_comp_axe, temp_data.i_parent_axe, temp_data.i_comp_axe_group
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ca.id_comp_axe
                                         FROM comp_axe ca
                                        WHERE ca.id_content = (SELECT ca2.id_content
                                                                 FROM alert_default.comp_axe ca2
                                                                WHERE ca2.id_comp_axe = cad.id_comp_axe)
                                             
                                          AND ca.flg_available = g_flg_available),
                                       0) i_comp_axe,
                                   
                                   decode(cad.id_parent_axe,
                                          NULL,
                                          NULL,
                                          (nvl((SELECT ca.id_comp_axe
                                                 FROM comp_axe ca
                                                WHERE ca.id_content =
                                                      (SELECT ca2.id_content
                                                         FROM alert_default.comp_axe ca2
                                                        WHERE ca2.id_comp_axe = cad.id_parent_axe)
                                                     
                                                  AND ca.flg_available = g_flg_available),
                                               0))) i_parent_axe,
                                   
                                   decode(cad.id_comp_axe_group,
                                          NULL,
                                          NULL,
                                          (nvl((SELECT cag.id_comp_axe_group
                                                 FROM comp_axe_group cag
                                                WHERE cag.id_content =
                                                      (SELECT cag2.id_content
                                                         FROM alert_default.comp_axe_group cag2
                                                        WHERE cag2.id_comp_axe_group = cad.id_comp_axe_group)
                                                     
                                                  AND cag.flg_available = g_flg_available),
                                               0))) i_comp_axe_group,
                                   cad.id_market,
                                   cad.version
                            
                            -- decode FKS to dest_vals
                              FROM alert_default.comp_axe_detail cad
                             INNER JOIN alert_default.comp_axe ca
                                ON ca.id_comp_axe = cad.id_comp_axe
                            
                             INNER JOIN alert_default.comp_axe_mrk_vrs camv
                                ON camv.id_comp_axe = cad.id_comp_axe
                               AND camv.id_market = cad.id_market
                               AND camv.version = cad.version
                            
                             WHERE ca.flg_available = g_flg_available
                                  
                               AND cad.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND cad.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND (def_data.i_parent_axe > 0 OR def_data.i_parent_axe IS NULL)
               AND def_data.i_comp_axe > 0
               AND (def_data.i_comp_axe_group > 0 OR def_data.i_comp_axe_group IS NULL)
               AND NOT EXISTS
             (SELECT 0
                      FROM comp_axe_detail cad1
                     WHERE cad1.id_comp_axe = def_data.i_comp_axe
                       AND (cad1.id_parent_axe = def_data.i_parent_axe OR
                           (def_data.i_parent_axe IS NULL AND cad1.id_parent_axe IS NULL))
                       AND (cad1.id_comp_axe_group = def_data.i_comp_axe_group OR
                           (def_data.i_comp_axe_group IS NULL AND cad1.id_comp_axe_group IS NULL)));
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
    END set_comp_axe_detail_search;

    -- frequent loader method
    FUNCTION set_comp_config_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        pos NUMBER := 1;
    BEGIN
        g_func_name := upper('set_comp_config_freq');
        INSERT INTO comp_config
            (id_comp_config,
             id_complication,
             id_comp_axe,
             id_clinical_service,
             id_institution,
             id_software,
             flg_configuration,
             id_sys_list,
             rank,
             flg_default)
            SELECT seq_comp_config.nextval,
                   def_data.id_complication,
                   def_data.id_comp_axe,
                   i_clin_serv_out,
                   i_institution,
                   id_software,
                   def_data.flg_configuration,
                   def_data.id_sys_list,
                   def_data.rank,
                   def_data.flg_default
              FROM (SELECT temp_data.id_complication,
                           temp_data.id_comp_axe,
                           i_software(pos) id_software,
                           temp_data.flg_configuration,
                           temp_data.id_sys_list,
                           temp_data.rank,
                           temp_data.flg_default,
                           row_number() over(PARTITION BY temp_data.id_complication, temp_data.id_comp_axe, temp_data.id_sys_list ORDER BY temp_data.id_software DESC) records_count
                      FROM (SELECT decode(cc.id_complication,
                                          NULL,
                                          NULL,
                                          nvl((SELECT c.id_complication
                                                FROM complication c
                                               INNER JOIN alert_default.complication c2
                                                  ON (c2.id_content = c.id_content)
                                               INNER JOIN alert_default.comp_mrk_vrs cmv
                                                  ON cmv.id_complication = c2.id_complication
                                                JOIN TABLE(i_mkt) mkt
                                                  ON cmv.id_market = mkt.column_value
                                                JOIN TABLE(i_vers) version
                                                  ON cmv.version = version.column_value
                                               WHERE c2.id_complication = cc.id_complication
                                                 AND c.flg_available = g_flg_available),
                                              0)) id_complication,
                                   decode(cc.id_comp_axe,
                                          NULL,
                                          NULL,
                                          nvl((SELECT ca.id_comp_axe
                                                FROM comp_axe ca
                                               INNER JOIN alert_default.comp_axe def_ca
                                                  ON (def_ca.id_content = ca.id_content)
                                               INNER JOIN alert_default.comp_axe_mrk_vrs camv
                                                  ON camv.id_comp_axe = def_ca.id_comp_axe
                                                JOIN TABLE(i_mkt) mkt
                                                  ON camv.id_market = mkt.column_value
                                                JOIN TABLE(i_vers) version
                                                  ON camv.version = version.column_value
                                               WHERE def_ca.id_comp_axe = cc.id_comp_axe
                                                 AND ca.flg_available = g_flg_available),
                                              0)) id_comp_axe,
                                   i_clin_serv_out id_clinical_service,
                                   cc.flg_configuration,
                                   cc.id_sys_list,
                                   cc.rank,
                                   cc.flg_default,
                                   cc.id_software
                              FROM alert_default.comp_config cc
                             WHERE cc.id_software IN (SELECT /*+ dynamic_sampling(p 2) */
                                                       column_value
                                                        FROM TABLE(CAST(i_software AS table_number)) p)
                               AND cc.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                     WHERE (temp_data.id_comp_axe IS NULL OR temp_data.id_comp_axe > 0)
                       AND (temp_data.id_complication IS NULL OR temp_data.id_complication > 0)) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS
             (SELECT 0
                      FROM comp_config cc
                     WHERE ((cc.id_complication = def_data.id_complication AND cc.id_comp_axe = def_data.id_comp_axe) OR
                           (cc.id_complication IS NULL AND cc.id_comp_axe = def_data.id_comp_axe) OR
                           (cc.id_comp_axe IS NULL AND cc.id_complication = def_data.id_complication) OR
                           cc.id_complication IS NULL AND cc.id_comp_axe IS NULL)
                       AND cc.id_clinical_service = i_clin_serv_out
                       AND cc.id_institution = i_institution
                       AND cc.id_sys_list = def_data.id_sys_list
                       AND cc.id_software = i_software(pos));
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
    END set_comp_config_freq;
	
    FUNCTION del_comp_config_freq
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete comp_config';
        g_func_name := upper('del_comp_config_freq');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM comp_config cc
             WHERE cc.id_institution = i_institution
               AND cc.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                       column_value
                                        FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM comp_config cc
             WHERE cc.id_institution = i_institution;
        
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
    END del_comp_config_freq;
    -- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_complication_prm;
/
