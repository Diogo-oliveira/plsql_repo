CREATE OR REPLACE PACKAGE BODY pk_intervention_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_INTERVENTION_prm';

    g_table_name t_med_char;
    pos_soft     NUMBER := 1;

    -- Private Methods
    /********************************************************************************************
    * Get destination table Id Interv_Dep_clin_serv
    *
    * @param i_interv_cs             Alert_default Interv_clin_serv_id
    * @param i_institution           Institution ID
    * @param i_dcs                   Dep_clin_serv_id
    *
    * @return                        Id Interv_Dep_clin_serv
    *
    * @author                        RMGM
    * @version                       0.1
    * @since                         2013/05/14
    ********************************************************************************************/

    FUNCTION get_idcs_dest_id
    (
        i_interv_cs   IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_dcs         IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE IS
    
        l_res interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE := 0;
    
    BEGIN
    
        SELECT nvl((SELECT a_idcs.id_interv_dep_clin_serv
                     FROM (SELECT nvl((SELECT a_i.id_intervention
                                        FROM intervention a_i
                                       WHERE a_i.id_content = ad_i.id_content
                                         AND a_i.flg_status = g_active),
                                      0) id_intervention,
                                  ad_ics.flg_type,
                                  ad_ics.id_software
                             FROM ad_interv_clin_serv ad_ics
                             JOIN ad_intervention ad_i
                               ON (ad_i.id_intervention = ad_ics.id_intervention AND ad_i.flg_status = g_active)
                            WHERE ad_ics.id_interv_clin_serv = i_interv_cs) def_interv
                     JOIN interv_dep_clin_serv a_idcs
                       ON (a_idcs.id_intervention = def_interv.id_intervention)
                    WHERE a_idcs.flg_type = def_interv.flg_type
                      AND a_idcs.id_software = def_interv.id_software
                      AND (a_idcs.id_institution = i_institution OR
                          (a_idcs.id_institution IS NULL AND i_institution IS NULL))
                      AND (a_idcs.id_dep_clin_serv = i_dcs OR (a_idcs.id_dep_clin_serv IS NULL AND i_dcs IS NULL))),
                   0)
          INTO l_res
          FROM dual;
    
        RETURN l_res;
    
    END get_idcs_dest_id;

    -- content loader method
    FUNCTION load_intervention_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('INTERVENTION.CODE_INTERVENTION.');
        l_level_array      table_number := table_number();
    
    BEGIN
    
        g_func_name := upper('LOAD_INTERVENTION_DEF');
    
        SELECT DISTINCT LEVEL
          BULK COLLECT
          INTO l_level_array
          FROM ad_intervention ad_i
         WHERE ad_i.flg_status = g_active
         START WITH ad_i.id_intervention_parent IS NULL
        CONNECT BY PRIOR ad_i.id_intervention = ad_i.id_intervention_parent
         ORDER BY LEVEL ASC;
    
        FORALL c_level IN 1 .. l_level_array.count
            INSERT INTO intervention
                (id_intervention,
                 id_intervention_parent,
                 code_intervention,
                 flg_status,
                 rank,
                 id_body_part,
                 flg_mov_pat,
                 gender,
                 age_min,
                 age_max,
                 mdm_coding,
                 cpt_code,
                 id_spec_sys_appar,
                 ref_form_code,
                 flg_type,
                 id_content,
                 flg_category_type,
                 flg_technical,
                 prev_recovery_time,
                 id_system_organ)
                SELECT seq_intervention.nextval,
                       id_intervention_parent,
                       l_code_translation || seq_intervention.currval,
                       g_active,
                       0,
                       id_body_part,
                       flg_mov_pat,
                       gender,
                       age_min,
                       age_max,
                       mdm_coding,
                       cpt_code,
                       id_spec_sys_appar,
                       ref_form_code,
                       flg_type,
                       id_content,
                       flg_category_type,
                       flg_technical,
                       prev_recovery_time,
                       id_system_organ
                  FROM (SELECT ad_i.id_intervention,
                               ad_i.id_content,
                               decode(ad_i.id_intervention_parent,
                                      NULL,
                                      NULL,
                                      nvl((SELECT a_i.id_intervention
                                            FROM intervention a_i
                                            JOIN ad_intervention ad_i1
                                              ON a_i.id_content = ad_i1.id_content
                                           WHERE ad_i1.id_intervention = ad_i.id_intervention_parent
                                             AND a_i.flg_status = g_active
                                             AND ad_i1.flg_status = g_active),
                                          0)) id_intervention_parent,
                               ad_i.id_body_part,
                               ad_i.flg_mov_pat,
                               ad_i.gender,
                               ad_i.age_min,
                               ad_i.age_max,
                               ad_i.mdm_coding,
                               ad_i.cpt_code,
                               ad_i.id_spec_sys_appar,
                               ad_i.ref_form_code,
                               ad_i.flg_type,
                               ad_i.flg_category_type,
                               ad_i.flg_technical,
                               ad_i.prev_recovery_time,
                               ad_i.id_system_organ,
                               LEVEL lvl
                          FROM ad_intervention ad_i
                         WHERE ad_i.flg_status = g_active
                         START WITH ad_i.id_intervention_parent IS NULL
                        CONNECT BY PRIOR ad_i.id_intervention = ad_i.id_intervention_parent) def_data
                 WHERE def_data.lvl = l_level_array(c_level)
                   AND NOT EXISTS
                 (SELECT 0
                          FROM intervention a_i1
                         WHERE a_i1.id_content = def_data.id_content
                           AND flg_status = g_active)
                   AND (def_data.id_intervention_parent != 0 OR def_data.id_intervention_parent IS NULL);
    
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
        
    END load_intervention_def;

    FUNCTION load_interv_category_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('interv_category.code_interv_category.');
    
    BEGIN
        INSERT INTO interv_category
            (id_interv_category, code_interv_category, flg_available, id_content, rank, adw_last_update)
            SELECT seq_interv_category.nextval,
                   l_code_translation || seq_interv_category.currval,
                   g_flg_available,
                   id_content,
                   rank,
                   SYSDATE
              FROM (SELECT ad_ic.id_interv_category, ad_ic.id_content, ad_ic.rank
                      FROM ad_interv_category ad_ic
                     WHERE ad_ic.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM interv_category a_ic
                             WHERE ad_ic.id_content = a_ic.id_content
                               AND ad_ic.flg_available = g_flg_available)) def_data;
    
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
        
    END load_interv_category_def;

    FUNCTION load_interv_physiatry_area_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('INTERV_PHYSIATRY_AREA.CODE_INTERV_PHYSIATRY_AREA.');
    
    BEGIN
    
        g_func_name := upper('LOAD_INTERV_PHYSIATRY_AREA_DEF');
    
        INSERT INTO interv_physiatry_area
            (id_interv_physiatry_area,
             code_interv_physiatry_area,
             rank,
             adw_last_update,
             flg_type,
             id_physiatry_area,
             id_content)
            SELECT seq_interv_physiatry_area.nextval,
                   l_code_translation || seq_interv_physiatry_area.currval,
                   rank,
                   SYSDATE,
                   flg_type,
                   id_physiatry_area,
                   id_content
              FROM (SELECT ad_ipa.id_interv_physiatry_area,
                           ad_ipa.id_content,
                           ad_ipa.rank,
                           ad_ipa.flg_type,
                           decode(ad_ipa.id_physiatry_area,
                                  NULL,
                                  NULL,
                                  nvl((SELECT a_pa.id_physiatry_area
                                        FROM physiatry_area a_pa
                                        JOIN ad_physiatry_area ad_pa
                                          ON a_pa.id_content = ad_pa.id_content
                                       WHERE ad_pa.id_physiatry_area = ad_ipa.id_physiatry_area),
                                      0)) id_physiatry_area
                      FROM ad_interv_physiatry_area ad_ipa
                     WHERE NOT EXISTS (SELECT 0
                              FROM interv_physiatry_area a_ipa
                             WHERE a_ipa.id_content = ad_ipa.id_content)) def_data
             WHERE def_data.id_physiatry_area > 0;
    
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
        
    END load_interv_physiatry_area_def;

    FUNCTION load_physiatry_area_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('PHYSIATRY_AREA.CODE_PHYSIATRY_AREA.');
    
    BEGIN
    
        g_func_name := upper('LOAD_PHYSIATRY_AREA_DEF');
    
        INSERT INTO physiatry_area
            (id_physiatry_area, code_physiatry_area, rank, adw_last_update, id_content)
            SELECT seq_physiatry_area.nextval,
                   l_code_translation || seq_physiatry_area.currval,
                   rank,
                   SYSDATE,
                   id_content
              FROM (SELECT pa.id_physiatry_area, pa.id_content, pa.rank
                      FROM alert_default.physiatry_area pa
                     WHERE NOT EXISTS (SELECT 0
                              FROM physiatry_area dest_tbl
                             WHERE pa.id_content = pa.id_content)) def_data;
    
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
        
    END load_physiatry_area_def;

    -- searcheable loader method
    /********************************************************************************************
    * Set Default Interventions Categories
    *
    * @param i_lang                Prefered language ID
    * @param o_interv_cat          Interventions categories
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/31
    ********************************************************************************************/

    FUNCTION set_inst_interv_cat
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_software       IN table_number,
        i_id_content     IN table_varchar DEFAULT table_varchar(),
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(2);
        l_cnt_count NUMBER := 0;
    
    BEGIN
        dbms_output.put_line(l_flg_type);
    
        g_error := 'INSERT INTO INTERV_INT_CAT';
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO interv_int_cat
            (id_interv_category, id_intervention, rank, adw_last_update, id_software, id_institution, flg_add_remove)
            SELECT def_data.id_interv_category,
                   def_data.id_intervention,
                   0,
                   SYSDATE,
                   i_software(pos_soft),
                   i_id_institution,
                   g_active
              FROM (SELECT temp_data.id_interv_category,
                           temp_data.id_intervention,
                           row_number() over(PARTITION BY temp_data.id_interv_category, temp_data.id_intervention ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_ic.id_interv_category
                                         FROM interv_category a_ic
                                        WHERE a_ic.flg_available = g_flg_available
                                          AND a_ic.id_content = ad_ic.id_content),
                                       0) id_interv_category,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_i.id_intervention
                                                FROM intervention a_i
                                                JOIN ad_intervention ad_i
                                                  ON ad_i.id_content = a_i.id_content
                                                 AND ad_i.flg_status = g_active
                                               WHERE ad_i.id_intervention = ad_iic.id_intervention
                                                 AND a_i.flg_status = g_active
                                                 AND (ad_i.flg_type = l_flg_type OR ad_i.flg_type = ad_i.flg_type)),
                                              0),
                                          nvl((SELECT a_i.id_intervention
                                                FROM intervention a_i
                                                JOIN ad_intervention ad_i
                                                  ON ad_i.id_content = a_i.id_content
                                                 AND ad_i.flg_status = g_active
                                               WHERE ad_i.id_intervention = ad_iic.id_intervention
                                                 AND a_i.flg_status = g_active
                                                 AND (ad_i.flg_type = l_flg_type OR ad_i.flg_type = ad_i.flg_type)
                                                 AND ad_i.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                              0)) id_intervention,
                                   ad_iic.id_software,
                                   ad_imv.id_market,
                                   ad_imv.version
                              FROM ad_interv_int_cat ad_iic
                              JOIN ad_interv_category ad_ic
                                ON ad_iic.id_interv_category = ad_ic.id_interv_category
                              JOIN ad_interv_mrk_vrs ad_imv
                                ON ad_imv.id_intervention = ad_iic.id_intervention
                             WHERE ad_ic.flg_available = g_flg_available
                               AND ad_iic.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_imv.id_market IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_market AS table_number)) p)
                               AND ad_imv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_version AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_intervention > 0
                       AND temp_data.id_interv_category > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM interv_int_cat a_iic1
                     WHERE a_iic1.id_interv_category = def_data.id_interv_category
                       AND a_iic1.id_intervention = def_data.id_intervention
                       AND a_iic1.id_software = i_software(pos_soft)
                       AND a_iic1.id_institution = i_id_institution);
    
        o_result := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'SET_INST_INTERV_CAT',
                                              o_error);
            RETURN FALSE;
        
    END set_inst_interv_cat;

    FUNCTION del_inst_interv_cat
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete interv_int_cat';
        g_func_name := upper('DEL_INST_INTERV_CAT');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM interv_int_cat iic
             WHERE iic.id_institution = i_institution
               AND iic.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM interv_int_cat iic
             WHERE iic.id_institution = i_institution;
        
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
        
    END del_inst_interv_cat;

    FUNCTION set_intervention_search
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
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(3);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_INTERVENTION_SEARCH');
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO interv_dep_clin_serv
            (id_interv_dep_clin_serv,
             id_intervention,
             flg_type,
             id_institution,
             id_software,
             rank,
             adw_last_update,
             flg_bandaid,
             flg_chargeable)
            SELECT seq_interv_dep_clin_serv.nextval,
                   def_data.id_intervention,
                   def_data.flg_type,
                   i_institution,
                   i_software(pos_soft),
                   0,
                   SYSDATE,
                   def_data.flg_bandaid,
                   def_data.flg_chargeable
              FROM (SELECT temp_data.id_intervention,
                           temp_data.flg_type,
                           temp_data.flg_bandaid,
                           temp_data.flg_chargeable,
                           row_number() over(PARTITION BY temp_data.id_intervention, temp_data.flg_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT /*+ index(src_tbl ICS_SW_BIDX) index(imv IMV_MKT_BIDX) index(imv IMV_VRS_BIDX) index(imv IMV_INT_BIDX)*/
                             decode(l_cnt_count,
                                    0,
                                    nvl((SELECT a_i.id_intervention
                                          FROM intervention a_i
                                          JOIN ad_intervention ad_i
                                            ON ad_i.id_content = a_i.id_content
                                           AND ad_i.flg_status = g_active
                                         WHERE ad_i.id_intervention = ad_ics.id_intervention
                                           AND a_i.flg_status = g_active
                                           AND (ad_i.flg_type = l_flg_type OR ad_i.flg_type = ad_i.flg_type)),
                                        0),
                                    nvl((SELECT a_i.id_intervention
                                          FROM intervention a_i
                                          JOIN ad_intervention ad_i
                                            ON ad_i.id_content = a_i.id_content
                                           AND ad_i.flg_status = g_active
                                         WHERE ad_i.id_intervention = ad_ics.id_intervention
                                           AND a_i.flg_status = g_active
                                           AND (ad_i.flg_type = l_flg_type OR ad_i.flg_type = ad_i.flg_type)
                                           AND ad_i.id_content IN
                                               (SELECT /*+ opt_estimate(p rows = 10)*/
                                                 column_value
                                                  FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                        0)) id_intervention,
                             ad_ics.flg_type,
                             ad_ics.flg_bandaid,
                             ad_ics.flg_chargeable,
                             ad_ics.id_software,
                             ad_imv.id_market,
                             ad_imv.version
                            -- decode FKS to dest_vals
                              FROM ad_interv_clin_serv ad_ics
                              JOIN ad_interv_mrk_vrs ad_imv
                                ON ad_imv.id_intervention = ad_ics.id_intervention
                             WHERE ad_ics.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_imv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_imv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_ics.flg_type != 'M') temp_data
                     WHERE temp_data.id_intervention > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM interv_dep_clin_serv a_idcs
                     WHERE a_idcs.id_intervention = def_data.id_intervention
                       AND a_idcs.flg_type = def_data.flg_type
                       AND a_idcs.id_institution = i_institution
                       AND a_idcs.id_software = i_software(pos_soft));
    
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
        
    END set_intervention_search;

    FUNCTION del_intervention_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete interv_dep_clin_serv';
        g_func_name := upper('DEL_INTERVENTION_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM ref_interv_orig_dest riod
             WHERE EXISTS
             (SELECT 1
                      FROM interv_dep_clin_serv idcs
                     WHERE (idcs.id_interv_dep_clin_serv = riod.id_interv_dcs_orig OR
                           idcs.id_interv_dep_clin_serv = riod.id_interv_dcs_dest)
                       AND idcs.id_institution = i_institution
                       AND idcs.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                 column_value
                                                  FROM TABLE(CAST(i_software AS table_number)) p));
            o_result_tbl := SQL%ROWCOUNT;
        
            DELETE FROM interv_dep_clin_serv idcs
             WHERE idcs.id_institution = i_institution
               AND idcs.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT + o_result_tbl;
        
        ELSE
            DELETE FROM ref_interv_orig_dest riod
             WHERE EXISTS (SELECT 1
                      FROM interv_dep_clin_serv idcs
                     WHERE (idcs.id_interv_dep_clin_serv = riod.id_interv_dcs_orig OR
                           idcs.id_interv_dep_clin_serv = riod.id_interv_dcs_dest)
                       AND idcs.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        
            DELETE FROM interv_dep_clin_serv idcs
             WHERE idcs.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT + o_result_tbl;
        
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
        
    END del_intervention_search;

    -- frequent loader method
    FUNCTION set_intervention_freq
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
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(3);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_INTERVENTION_FREQ');
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO interv_dep_clin_serv
            (id_interv_dep_clin_serv,
             id_intervention,
             id_dep_clin_serv,
             flg_type,
             rank,
             adw_last_update,
             id_software,
             flg_bandaid,
             flg_chargeable,
             id_institution)
            SELECT seq_interv_dep_clin_serv.nextval,
                   def_data.id_intervention,
                   i_dep_clin_serv_out,
                   def_data.flg_type,
                   0,
                   SYSDATE,
                   i_software(pos_soft),
                   def_data.flg_bandaid,
                   def_data.flg_chargeable,
                   i_institution
              FROM (SELECT temp_data.id_intervention,
                           temp_data.flg_type,
                           temp_data.flg_bandaid,
                           temp_data.flg_chargeable,
                           row_number() over(PARTITION BY temp_data.id_intervention, temp_data.flg_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_i.id_intervention
                                                FROM intervention a_i
                                                JOIN ad_intervention ad_i
                                                  ON ad_i.id_content = a_i.id_content
                                                 AND ad_i.flg_status = g_active
                                               WHERE ad_i.id_intervention = ad_ics.id_intervention
                                                 AND a_i.flg_status = g_active
                                                 AND (ad_i.flg_type = l_flg_type OR ad_i.flg_type = ad_i.flg_type)),
                                              0),
                                          nvl((SELECT a_i.id_intervention
                                                FROM intervention a_i
                                                JOIN ad_intervention ad_i
                                                  ON ad_i.id_content = a_i.id_content
                                                 AND ad_i.flg_status = g_active
                                               WHERE ad_i.id_intervention = ad_ics.id_intervention
                                                 AND a_i.flg_status = g_active
                                                 AND (ad_i.flg_type = l_flg_type OR ad_i.flg_type = ad_i.flg_type)
                                                 AND ad_i.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                              0)) id_intervention,
                                   ad_ics.flg_type,
                                   ad_ics.flg_bandaid,
                                   ad_ics.flg_chargeable,
                                   ad_ics.id_software,
                                   ad_imv.id_market,
                                   ad_imv.version
                              FROM ad_interv_clin_serv ad_ics
                              JOIN ad_interv_mrk_vrs ad_imv
                                ON ad_imv.id_intervention = ad_ics.id_intervention
                             WHERE ad_ics.id_software IN
                                   (SELECT /*+ dynamic_sampling(4)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_ics.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(4)*/
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)
                               AND ad_imv.id_market IN (SELECT /*+ dynamic_sampling(4)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_imv.version IN (SELECT /*+ dynamic_sampling(4)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_intervention > 0) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM interv_dep_clin_serv a_idcs
                     WHERE a_idcs.id_intervention = def_data.id_intervention
                       AND a_idcs.id_dep_clin_serv IS NULL
                       AND a_idcs.flg_type = 'P'
                       AND a_idcs.id_institution = i_institution
                       AND a_idcs.id_software = i_software(pos_soft))
               AND NOT EXISTS (SELECT 0
                      FROM interv_dep_clin_serv a_idcs1
                     WHERE a_idcs1.id_intervention = def_data.id_intervention
                       AND a_idcs1.id_dep_clin_serv = i_dep_clin_serv_out
                       AND a_idcs1.flg_type = def_data.flg_type
                       AND a_idcs1.id_software = i_software(pos_soft));
    
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
        
    END set_intervention_freq;

    /********************************************************************************************
    * Set interv_dcs_most_freq_except configuration
    *
    * @param i_lang                  Language ID
    * @param i_institution           Institution ID
    * @param i_mkt                   Market Search List
    * @param i_vers                  Content Version Search List
    * @param i_software              Software Search List
    * @param i_clin_serv_in          Default Clinical Service Seach list
    * @param i_clin_serv_out         Configuration target (id_clinical_service)
    * @param i_dep_clin_serv_out     Configuration target (Dep_clin_serv_id)
    * @param o_result                Number of records inserted
    * @param o_error                 Error message
    *
    * @return                        True or False
    *
    * @author                        RMGM
    * @version                       0.1
    * @since                         2013/05/14
    ********************************************************************************************/

    FUNCTION set_int_dcs_mf_except_all
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_mkt          IN table_number,
        i_vers         IN table_varchar,
        i_software     IN table_number,
        i_id_content   IN table_varchar DEFAULT table_varchar(),
        i_clin_serv_in IN table_number,
        
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'SET INTERVENTION BY PROFESSIONAL CATEGORY, MARKET AND VERSION';
    
        INSERT INTO interv_dcs_most_freq_except
            (id_interv_dcs_most_freq_except,
             id_interv_dep_clin_serv,
             flg_cat_prof,
             flg_available,
             adw_last_update,
             flg_status)
            SELECT seq_interv_dcs_most_f_e.nextval,
                   def_data.id_interv_dep_clin_serv,
                   def_data.flg_cat_prof,
                   g_flg_available,
                   SYSDATE,
                   def_data.flg_status
              FROM (SELECT temp_data.id_interv_dep_clin_serv,
                           temp_data.flg_cat_prof,
                           temp_data.flg_status,
                           row_number() over(PARTITION BY temp_data.id_interv_dep_clin_serv, temp_data.flg_cat_prof ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT ad_idmfe.rowid l_row,
                                   decode(ad_ics.id_clinical_service,
                                          NULL,
                                          pk_default_inst_preferences.get_idcs_dest_id(ad_idmfe.id_interv_clin_serv,
                                                                                       i_institution,
                                                                                       NULL),
                                          pk_default_inst_preferences.get_idcs_dest_id(ad_idmfe.id_interv_clin_serv,
                                                                                       NULL,
                                                                                       i_dep_clin_serv_out)) id_interv_dep_clin_serv,
                                   ad_idmfe.flg_cat_prof,
                                   ad_idmfe.flg_status,
                                   ad_idmfe.id_market,
                                   ad_idmfe.version
                              FROM ad_interv_dcs_most_freq_except ad_idmfe
                              JOIN ad_interv_clin_serv ad_ics
                                ON ad_ics.id_interv_clin_serv = ad_idmfe.id_interv_clin_serv
                             WHERE ad_idmfe.flg_available = g_flg_available
                               AND ad_idmfe.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_idmfe.version IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_interv_dep_clin_serv > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM interv_dcs_most_freq_except a_idmfe
                     WHERE a_idmfe.id_interv_dep_clin_serv = def_data.id_interv_dep_clin_serv
                       AND a_idmfe.flg_cat_prof = def_data.flg_cat_prof);
    
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
                                              'set_int_dcs_mf_except_all',
                                              o_error);
            RETURN FALSE;
        
    END set_int_dcs_mf_except_all;

    FUNCTION del_int_dcs_mf_except_all
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete interv_dcs_most_freq_except';
        g_func_name := upper('DEL_INT_DCS_MF_EXCEPT_ALL');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM interv_dcs_most_freq_except a_imfe
             WHERE EXISTS (SELECT 1
                      FROM interv_dep_clin_serv a_idcs
                     WHERE a_imfe.id_interv_dep_clin_serv = a_idcs.id_interv_dep_clin_serv
                       AND a_idcs.id_institution = i_institution
                       AND a_idcs.id_software IN
                           (SELECT /*+ dynamic_sampling(2)*/
                             column_value
                              FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM interv_dcs_most_freq_except a_imfe
             WHERE EXISTS (SELECT 1
                      FROM interv_dep_clin_serv a_idcs
                     WHERE a_imfe.id_interv_dep_clin_serv = a_idcs.id_interv_dep_clin_serv
                       AND a_idcs.id_institution = i_institution);
        
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
        
    END del_int_dcs_mf_except_all;

    FUNCTION set_interv_question_search
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
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(3);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_INTERV_QUESTION_SEARCH');
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO interv_questionnaire
            (id_interv_questionnaire,
             id_intervention,
             id_questionnaire,
             flg_type,
             flg_mandatory,
             rank,
             flg_available,
             flg_time,
             id_response,
             flg_copy,
             flg_validation,
             flg_exterior,
             id_unit_measure,
             id_institution)
            SELECT seq_interv_questionnaire.nextval,
                   def_data.id_intervention,
                   def_data.id_questionnaire,
                   def_data.flg_type,
                   def_data.flg_mandatory,
                   def_data.rank,
                   def_data.flg_available,
                   def_data.flg_time,
                   def_data.id_response,
                   def_data.flg_copy,
                   def_data.flg_validation,
                   def_data.flg_exterior,
                   def_data.id_unit_measure,
                   i_institution
              FROM (SELECT temp_data.id_intervention,
                           temp_data.id_questionnaire,
                           temp_data.flg_type,
                           temp_data.flg_mandatory,
                           temp_data.rank,
                           temp_data.flg_available,
                           temp_data.flg_time,
                           temp_data.id_response,
                           temp_data.flg_copy,
                           temp_data.flg_validation,
                           temp_data.flg_exterior,
                           temp_data.id_unit_measure,
                           row_number() over(PARTITION BY temp_data.id_intervention, temp_data.id_questionnaire, temp_data.flg_time, temp_data.id_response ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(ad_iq.id_intervention,
                                          NULL,
                                          NULL,
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT a_i.id_intervention
                                                       FROM intervention a_i
                                                       JOIN ad_intervention ad_i
                                                         ON ad_i.id_content = a_i.id_content
                                                        AND ad_i.flg_status = g_active
                                                      WHERE ad_i.id_intervention = ad_iq.id_intervention
                                                        AND a_i.flg_status = g_active
                                                        AND (ad_i.flg_type = l_flg_type OR ad_i.flg_type = ad_i.flg_type)),
                                                     0),
                                                 nvl((SELECT a_i.id_intervention
                                                       FROM intervention a_i
                                                       JOIN ad_intervention ad_i
                                                         ON ad_i.id_content = a_i.id_content
                                                        AND ad_i.flg_status = g_active
                                                      WHERE ad_i.id_intervention = ad_iq.id_intervention
                                                        AND a_i.flg_status = g_active
                                                        AND (ad_i.flg_type = l_flg_type OR ad_i.flg_type = ad_i.flg_type)
                                                        AND ad_i.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0))) id_intervention,
                                   nvl((SELECT a_q.id_questionnaire
                                         FROM questionnaire a_q
                                         JOIN ad_questionnaire ad_q
                                           ON a_q.id_content = ad_q.id_content
                                          AND ad_q.flg_available = a_q.flg_available
                                        WHERE ad_q.id_questionnaire = ad_iq.id_questionnaire
                                          AND a_q.flg_available = g_flg_available),
                                       0) id_questionnaire,
                                   ad_iq.flg_type,
                                   ad_iq.flg_mandatory,
                                   ad_iq.rank,
                                   ad_iq.flg_available,
                                   ad_iq.flg_time,
                                   decode(ad_iq.id_response,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_r.id_response
                                                FROM response a_r
                                                JOIN alert_default.response ad_r
                                                  ON ad_r.id_content = a_r.id_content
                                                 AND ad_r.flg_available = a_r.flg_available
                                               WHERE a_r.flg_available = g_flg_available
                                                 AND ad_r.id_response = ad_iq.id_response),
                                              0)) id_response,
                                   ad_iq.flg_copy,
                                   ad_iq.flg_validation,
                                   ad_iq.flg_exterior,
                                   decode(ad_iq.id_unit_measure,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_ums.id_unit_measure_subtype
                                                FROM unit_measure_subtype a_ums
                                               WHERE a_ums.id_unit_measure_subtype = ad_iq.id_unit_measure),
                                              0)) id_unit_measure,
                                   ad_iq.id_market,
                                   ad_iq.version
                            -- decode FKS to dest_vals
                              FROM ad_interv_questionnaire ad_iq
                             WHERE ad_iq.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_iq.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND (def_data.id_intervention > 0 OR def_data.id_intervention IS NULL)
               AND (def_data.id_response > 0 OR def_data.id_response IS NULL)
               AND (def_data.id_unit_measure > 0 OR def_data.id_unit_measure IS NULL)
               AND def_data.id_questionnaire > 0
               AND EXISTS (SELECT 0
                      FROM questionnaire_response a_qr
                     WHERE a_qr.id_questionnaire = def_data.id_questionnaire
                       AND (a_qr.id_response = def_data.id_response OR
                           (a_qr.id_response IS NULL AND def_data.id_response IS NULL)))
               AND NOT EXISTS (SELECT 0
                      FROM interv_questionnaire a_iq
                     WHERE (a_iq.id_intervention = def_data.id_intervention OR
                           (a_iq.id_intervention IS NULL AND def_data.id_intervention IS NULL))
                       AND (a_iq.id_response = def_data.id_response OR
                           (a_iq.id_response IS NULL AND def_data.id_response IS NULL))
                       AND a_iq.id_questionnaire = def_data.id_questionnaire
                       AND a_iq.id_institution = i_institution
                       AND a_iq.flg_time = def_data.flg_time
                       AND a_iq.flg_available = g_flg_available);
    
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
        
    END set_interv_question_search;

    FUNCTION del_interv_question_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete interv_questionnaire';
        g_func_name := upper('DEL_INTERV_QUESTION_SEARCH');
    
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
            DELETE FROM interv_questionnaire iq
             WHERE iq.id_institution = i_institution;
        
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
        
    END del_interv_question_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

END pk_intervention_prm;
/
