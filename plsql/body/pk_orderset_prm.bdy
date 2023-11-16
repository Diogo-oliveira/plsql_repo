/*-- Last Change Revision: $Rev: 1909626 $*/
/*-- Last Change by: $Author: helder.moreira $*/
/*-- Date of last change: $Date: 2019-07-25 11:40:30 +0100 (qui, 25 jul 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_orderset_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_orderset_prm';

    g_cfg_done  t_low_char;
    pos_soft    NUMBER := 1;
    l_ost_table order_set_container_table := order_set_container_table();

    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_order_set_search
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
        g_func_name := upper('set_order_set_search');
        INSERT INTO order_set
            (id_order_set,
             id_order_set_internal,
             id_order_set_previous_version,
             title,
             author_desc,
             flg_target_professionals,
             flg_edit_permissions,
             flg_status,
             notes_global,
             flg_additional_info,
             id_content,
             id_institution,
             id_software,
             clinical_indications)
            SELECT seq_order_set.nextval,
                   def_data.id_order_set_internal,
                   def_data.id_order_set_previous_version,
                   def_data.title,
                   def_data.author_desc,
                   def_data.flg_target_professionals,
                   def_data.flg_edit_permissions,
                   def_data.flg_status,
                   def_data.notes_global,
                   def_data.flg_additional_info,
                   def_data.id_content,
                   i_institution,
                   i_software(pos_soft),
                   def_data.clinical_indications
              FROM (SELECT temp_data.id_order_set_internal,
                           temp_data.id_order_set_previous_version,
                           temp_data.title,
                           temp_data.author_desc,
                           temp_data.flg_target_professionals,
                           temp_data.flg_edit_permissions,
                           temp_data.flg_status,
                           temp_data.notes_global,
                           temp_data.flg_additional_info,
                           temp_data.id_content,
                           temp_data.clinical_indications,
                           row_number() over(PARTITION BY temp_data.id_content ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT os.id_order_set_internal,
                                   os.id_order_set_previous_version,
                                   os.title,
                                   os.author_desc,
                                   os.flg_target_professionals,
                                   os.flg_edit_permissions,
                                   os.flg_status,
                                   os.notes_global,
                                   os.flg_additional_info,
                                   os.id_content,
                                   os.clinical_indications,
                                   omv.id_market,
                                   omv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.order_set os
                             INNER JOIN alert_default.order_set_mrk_vrs omv
                                ON omv.id_order_set = os.id_order_set
                             WHERE EXISTS (SELECT 0
                                      FROM alert_default.order_set_task ost
                                     WHERE ost.id_order_set = os.id_order_set)
                                  
                               AND omv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND omv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM order_set os1
                     WHERE os1.id_content = def_data.id_content
                       AND os1.id_institution = i_institution
                       AND os1.flg_status != 'D');
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
    END set_order_set_search;

    FUNCTION del_order_set_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete order_set';
        g_func_name := upper('del_order_set_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            UPDATE order_set os
               SET os.flg_status = 'D'
             WHERE os.id_professional IS NULL
               AND os.id_institution = i_institution
			   AND os.flg_status != 'D'
               AND os.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                       column_value
                                        FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            UPDATE order_set os
               SET os.flg_status = 'D'
             WHERE os.id_professional IS NULL
               AND os.id_institution = i_institution
			   AND os.flg_status != 'D';
        
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
    END del_order_set_search;

    FUNCTION set_order_set_frequent_search
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
        g_func_name := upper('set_order_set_frequent_search');
        INSERT INTO order_set_frequent
            (id_order_set, rank, id_institution, id_software)
            SELECT def_data.i_order_set, def_data.rank, i_institution, i_software(pos_soft)
              FROM (SELECT temp_data.i_order_set,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.i_order_set
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT (nvl((SELECT os1.id_order_set
                                           FROM order_set os1
                                          WHERE os1.id_institution = i_institution
                                            AND os1.id_content = os.id_content
                                            AND os1.id_professional IS NULL
                                            AND rownum = 1),
                                         0)) i_order_set,
                                    osf.rank,
                                    osf.id_software,
                                    osmv.id_market,
                                    osmv.version
                             -- decode FKS to dest_vals
                               FROM alert_default.order_set os
                              INNER JOIN alert_default.order_set_mrk_vrs osmv
                                 ON osmv.id_order_set = os.id_order_set
                              INNER JOIN alert_default.order_set_frequent osf
                                 ON osf.id_order_set = os.id_order_set
                             
                              WHERE
                             
                              osf.id_software IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                   column_value
                                                    FROM TABLE(CAST(i_software AS table_number)) p)
                           AND osmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                  column_value
                                                   FROM TABLE(CAST(i_mkt AS table_number)) p)
                             
                           AND osmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                column_value
                                                 FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.i_order_set > 0
               AND NOT EXISTS (SELECT 0
                      FROM order_set_frequent osf1
                     WHERE osf1.id_order_set = def_data.i_order_set
                       AND osf1.id_institution = i_institution
                       AND osf1.id_software = i_software(pos_soft));
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
    END set_order_set_frequent_search;

    FUNCTION del_order_set_frequent_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete order_set_frequent';
        g_func_name := upper('del_order_set_frequent_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM order_set_frequent osf
             WHERE EXISTS (SELECT 1
                      FROM order_set os
                     WHERE os.id_order_set = osf.id_order_set
                       AND os.id_professional IS NULL)
               AND osf.id_institution = i_institution
               AND osf.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM order_set_frequent osf
             WHERE EXISTS (SELECT 1
                      FROM order_set os
                     WHERE os.id_order_set = osf.id_order_set
                       AND os.id_professional IS NULL)
               AND osf.id_institution = i_institution;
        
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
    END del_order_set_frequent_search;

    FUNCTION set_order_set_task_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        aux_ost_table order_set_container_table;
    BEGIN
        g_func_name := upper('set_order_set_task_search');
        SELECT seq_order_set_task.nextval, def_data.i_order_set, def_data.id_task_type, def_data.order_set_task_def
          BULK COLLECT
          INTO aux_ost_table
          FROM (SELECT temp_data.i_order_set, temp_data.id_task_type, temp_data.order_set_task_def
                
                  FROM (SELECT (nvl((SELECT os1.id_order_set
                                       FROM order_set os1
                                      WHERE os1.id_institution = i_institution
                                        AND os1.id_content = os.id_content
                                        AND os1.id_professional IS NULL
                                        AND rownum = 1),
                                     0)) i_order_set,
                                ost.id_task_type,
                                ost.id_order_set_task order_set_task_def
                         
                         -- decode FKS to dest_vals
                           FROM alert_default.order_set os
                          INNER JOIN alert_default.order_set_mrk_vrs osmv
                             ON os.id_order_set = osmv.id_order_set
                          INNER JOIN alert_default.order_set_task ost
                             ON ost.id_order_set = os.id_order_set
                          WHERE
                         
                          osmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                              column_value
                                               FROM TABLE(CAST(i_mkt AS table_number)) p)
                         
                       AND osmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                            column_value
                                             FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
        
         WHERE def_data.i_order_set > 0
           AND NOT EXISTS (SELECT 0
                  FROM order_set_task ost1
                 WHERE ost1.id_order_set = def_data.i_order_set
                   AND ost1.id_task_type = def_data.id_task_type);
    
        FORALL i IN aux_ost_table.first .. aux_ost_table.last
            INSERT INTO order_set_task
                (id_order_set_task, id_order_set, id_task_type)
            VALUES
                (aux_ost_table(i).l_ost, aux_ost_table(i).l_os, aux_ost_table(i).l_tt);
    
        l_ost_table := l_ost_table MULTISET UNION aux_ost_table;
    
        o_result_tbl := aux_ost_table.count;
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
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
            RETURN FALSE;
    END set_order_set_task_search;

    FUNCTION del_order_set_task_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete order_set_frequent';
        g_func_name := upper('del_order_set_task_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM order_set_task_dependency ostd
             WHERE EXISTS (SELECT 1
                      FROM order_set_task ost
                     WHERE ost.id_order_set_task = ostd.id_order_set_task_to
                       AND EXISTS (SELECT 1
                              FROM order_set os
                             WHERE os.id_order_set = ost.id_order_set
                               AND os.id_professional IS NULL
                               AND os.id_institution = i_institution
                               AND os.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)));
        
            DELETE FROM order_set_task ost
             WHERE EXISTS (SELECT 1
                      FROM order_set os
                     WHERE os.id_order_set = ost.id_order_set
                       AND os.id_professional IS NULL
                       AND os.id_institution = i_institution
                       AND os.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                               column_value
                                                FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM order_set_task_dependency ostd
             WHERE EXISTS (SELECT 1
                      FROM order_set_task ost
                     WHERE ost.id_order_set_task = ostd.id_order_set_task_to
                       AND EXISTS (SELECT 1
                              FROM order_set os
                             WHERE os.id_order_set = ost.id_order_set
                               AND os.id_professional IS NULL
                               AND os.id_institution = i_institution));
        
            DELETE FROM order_set_task ost
             WHERE EXISTS (SELECT 1
                      FROM order_set os
                     WHERE os.id_order_set = ost.id_order_set
                       AND os.id_professional IS NULL
                       AND os.id_institution = i_institution);
        
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
    END del_order_set_task_search;

    FUNCTION set_order_set_task_det_search
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
        g_func_name := upper('set_order_set_task_det_search');
        INSERT INTO order_set_task_detail
            (id_order_set_task_detail,
             id_order_set_task,
             flg_value_type,
             nvalue,
             dvalue,
             vvalue,
             flg_detail_type,
             id_advanced_input,
             id_advanced_input_field,
             id_advanced_input_field_det,
             id_unit_measure)
        
            SELECT seq_order_set_task_detail.nextval,
                   def_data.i_order_set_task,
                   def_data.flg_value_type,
                   def_data.nvalue,
                   def_data.dvalue,
                   def_data.vvalue,
                   def_data.flg_detail_type,
                   def_data.id_advanced_input,
                   def_data.id_advanced_input_field,
                   def_data.id_advanced_input_field_det,
                   def_data.id_unit_measure
              FROM (SELECT temp_data.i_order_set_task,
                           temp_data.flg_value_type,
                           temp_data.nvalue,
                           temp_data.dvalue,
                           temp_data.vvalue,
                           temp_data.flg_detail_type,
                           temp_data.id_advanced_input,
                           temp_data.id_advanced_input_field,
                           temp_data.id_advanced_input_field_det,
                           temp_data.id_unit_measure,
                           row_number() over(PARTITION BY temp_data.i_order_set_task, temp_data.flg_value_type, temp_data.nvalue, temp_data.dvalue, temp_data.vvalue, temp_data.flg_detail_type, temp_data.id_advanced_input, temp_data.id_advanced_input_field, temp_data.id_advanced_input_field_det, temp_data.id_unit_measure
                           
                           ORDER BY temp_data.l_row) records_count
                      FROM (SELECT ostd.rowid l_row,
                                   
                                   nvl((SELECT ost1.id_order_set_task
                                         FROM order_set_task ost1
                                        INNER JOIN order_set os1
                                           ON os1.id_order_set = ost1.id_order_set
                                        WHERE os1.id_institution = i_institution
                                          AND os1.id_content = os.id_content
                                          AND os1.id_professional IS NULL
                                          AND ost1.id_task_type = ost.id_task_type
                                          AND rownum = 1),
                                       0) i_order_set_task,
                                   
                                   ostd.flg_value_type,
                                   ostd.nvalue,
                                   ostd.dvalue,
                                   ostd.vvalue,
                                   ostd.flg_detail_type,
                                   ostd.id_advanced_input,
                                   ostd.id_advanced_input_field,
                                   ostd.id_advanced_input_field_det,
                                   ostd.id_unit_measure
                            
                            -- decode FKS to dest_vals
                              FROM alert_default.order_set os
                             INNER JOIN alert_default.order_set_task ost
                                ON os.id_order_set = ost.id_order_set
                             INNER JOIN alert_default.order_set_task_detail ostd
                                ON (ostd.id_order_set_task = ost.id_order_set_task)
                             WHERE EXISTS
                             (SELECT 0
                                      FROM alert_default.order_set_mrk_vrs osmv
                                     WHERE osmv.id_order_set = ost.id_order_set
                                       AND osmv.id_market IN
                                           (SELECT /*+ dynamic_sampling(p 2)*/
                                             column_value
                                              FROM TABLE(CAST(i_mkt AS table_number)) p)
                                          
                                       AND osmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                             column_value
                                                              FROM TABLE(CAST(i_vers AS table_varchar)) p))) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.i_order_set_task > 0
               AND NOT EXISTS
             (SELECT 0
                      FROM order_set_task_detail ostd1
                     WHERE ostd1.id_order_set_task = def_data.i_order_set_task
                       AND ostd1.flg_value_type = def_data.flg_value_type
                       AND nvl(ostd1.nvalue, 0) = nvl(def_data.nvalue, 0)
                       AND nvl(ostd1.dvalue, to_date('00:00:00', 'hh24:mi:ss')) =
                           nvl(def_data.dvalue, to_date('00:00:00', 'hh24:mi:ss'))
                       AND nvl(ostd1.vvalue, '0') = nvl(def_data.vvalue, '0')
                       AND ostd1.flg_detail_type = def_data.flg_detail_type
                       AND nvl(ostd1.id_advanced_input, 0) = nvl(def_data.id_advanced_input, 0)
                       AND nvl(ostd1.id_advanced_input_field, 0) = nvl(def_data.id_advanced_input_field, 0)
                       AND nvl(ostd1.id_advanced_input_field_det, 0) = nvl(def_data.id_advanced_input_field_det, 0)
                       AND nvl(ostd1.id_unit_measure, 0) = nvl(def_data.id_unit_measure, 0));
    
        o_result_tbl := SQL%ROWCOUNT;
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
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
            RETURN FALSE;
    END set_order_set_task_det_search;

    FUNCTION del_order_set_task_det_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete order_set_frequent';
        g_func_name := upper('del_order_set_task_det_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM order_set_task_detail ostd
             WHERE EXISTS (SELECT 1
                      FROM order_set_task ost
                     WHERE ost.id_order_set_task = ostd.id_order_set_task
                       AND EXISTS (SELECT 1
                              FROM order_set os
                             WHERE os.id_order_set = ost.id_order_set
                               AND os.id_professional IS NULL
                               AND os.id_institution = i_institution
                               AND os.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM order_set_task_detail ostd
             WHERE EXISTS (SELECT 1
                      FROM order_set_task ost
                     WHERE ost.id_order_set_task = ostd.id_order_set_task
                       AND EXISTS (SELECT 1
                              FROM order_set os
                             WHERE os.id_order_set = ost.id_order_set
                               AND os.id_professional IS NULL
                               AND os.id_institution = i_institution));
        
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
    END del_order_set_task_det_search;

    FUNCTION set_order_set_link_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_var_s VARCHAR2(1) := 'S';
        l_var_e VARCHAR2(1) := 'E';
        l_var_c VARCHAR2(1) := 'C';
        l_var_t VARCHAR2(1) := 'T';
    
    BEGIN
        g_func_name := 'set_order_set_link_search ';
    
        INSERT INTO order_set_link
            (id_order_set, id_link, flg_link_type)
            SELECT def_data.id_order_set, def_data.id_link, def_data.flg_link_type
              FROM (SELECT temp_data.id_order_set,
                           temp_data.id_link,
                           temp_data.flg_link_type,
                           temp_data.id_content,
                           row_number() over(PARTITION BY temp_data.id_order_set, temp_data.id_link, temp_data.flg_link_type
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT os.id_order_set
                                         FROM order_set os
                                        WHERE os.id_content = dos.id_content
                                          AND os.id_institution = i_institution
                                          AND os.id_professional IS NULL
                                          AND rownum = 1),
                                       0) id_order_set,
                                   dos.id_content id_content,
                                   decode(osl.flg_link_type,
                                          l_var_c,
                                          nvl((SELECT id_complaint
                                                FROM complaint
                                               WHERE id_complaint = osl.id_link),
                                              -1),
                                          l_var_s,
                                          osl.id_link,
                                          l_var_t,
                                          osl.id_link) id_link,
                                   osl.flg_link_type,
                                   osmv.id_market,
                                   osmv.version
                              FROM alert_default.order_set_link osl
                             INNER JOIN alert_default.order_set dos
                                ON osl.id_order_set = dos.id_order_set
                             INNER JOIN alert_default.order_set_mrk_vrs osmv
                                ON osl.id_order_set = osmv.id_order_set
                             WHERE osmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND osmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  
                               AND (osl.flg_link_type != l_var_e)
                            
                            UNION ALL (SELECT nvl((SELECT os.id_order_set
                                                   FROM order_set os
                                                  WHERE os.id_content = dos.id_content
                                                    AND os.id_institution = i_institution
                                                    AND os.id_professional IS NULL
                                                    AND rownum = 1),
                                                 0) id_order_set,
                                             
                                             dos.id_content    id_content,
                                             t.id_dept         id_link,
                                             osl.flg_link_type,
                                             osmv.id_market,
                                             osmv.version
                                        FROM software_dept sd
                                       INNER JOIN dept t
                                          ON sd.id_dept = t.id_dept
                                        JOIN alert_default.order_set_link osl
                                          ON sd.id_software = osl.id_link
                                       INNER JOIN alert_default.order_set dos
                                          ON osl.id_order_set = dos.id_order_set
                                       INNER JOIN alert_default.order_set_mrk_vrs osmv
                                          ON osl.id_order_set = osmv.id_order_set
                                       WHERE sd.id_software IN
                                             (SELECT /*+ dynamic_sampling(p 2)*/
                                               column_value
                                                FROM TABLE(CAST(i_software AS table_number)) p)
                                         AND osmv.id_market IN
                                             (SELECT /*+ dynamic_sampling(p 2)*/
                                               column_value
                                                FROM TABLE(CAST(i_mkt AS table_number)) p)
                                            
                                         AND osmv.version IN
                                             (SELECT /*+ dynamic_sampling(p 2)*/
                                               column_value
                                                FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                         AND t.id_institution = i_institution
                                         AND t.flg_available = 'Y'
                                         AND osl.flg_link_type = l_var_e)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_order_set > 0
               AND def_data.id_link > 0
               AND NOT EXISTS (SELECT 0
                      FROM order_set_link osl
                     WHERE osl.id_order_set = def_data.id_order_set
                       AND osl.id_link = def_data.id_link
                       AND osl.flg_link_type = def_data.flg_link_type);
    
        --o_result_tbl := l_id_order_set_array.count;
        o_result_tbl := SQL%ROWCOUNT;
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
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
            RETURN FALSE;
    END set_order_set_link_search;

    FUNCTION del_order_set_link_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete order_set_link';
        g_func_name := upper('del_order_set_link_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM order_set_link osl
             WHERE EXISTS (SELECT 1
                      FROM order_set os
                     WHERE os.id_order_set = osl.id_order_set
                       AND os.id_professional IS NULL
                       AND os.id_institution = i_institution
                       AND os.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                               column_value
                                                FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM order_set_link osl
             WHERE EXISTS (SELECT 1
                      FROM order_set os
                     WHERE os.id_order_set = osl.id_order_set
                       AND os.id_professional IS NULL
                       AND os.id_institution = i_institution);
        
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
    END del_order_set_link_search;

    FUNCTION set_order_set_task_l_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_number_2 NUMBER := 2;
        l_number_5 NUMBER := 5;
        l_number_3 NUMBER := 3;
        l_number_4 NUMBER := 4;
        l_number_9 NUMBER := 9;
        --  l_number_13 NUMBER := 13;
        --    l_number_15 NUMBER := 15;
        l_number_7  NUMBER := 7;
        l_number_8  NUMBER := 8;
        l_number_10 NUMBER := 43; /* ALERT-218903 replaced 10 by 43*/
        l_number_11 NUMBER := 11;
        l_number_12 NUMBER := 42; /*http://alertjira/browse/ALERT-195613*/
    
        l_var_n VARCHAR2(1) := 'N';
        l_var_e VARCHAR2(1) := 'E';
        l_var_g VARCHAR2(1) := 'G';
        l_var_c VARCHAR2(1) := 'C';
        l_var_a VARCHAR2(1) := 'A';
        l_var_l VARCHAR2(1) := 'L';
    
        l_cs_list table_number := table_number();
        l_ret     BOOLEAN;
        -- log
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors, -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_func_name := 'SET_INST_ORDER_SET_TASK_LINK';
        g_error     := 'OPEN c_order_set_task_link CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
        o_result_tbl := 0;
    
        IF l_ost_table IS NOT NULL
        THEN
            FORALL i IN l_ost_table.first .. l_ost_table.last SAVE EXCEPTIONS
                INSERT INTO order_set_task_link
                    (id_order_set_task, id_task_link, flg_task_link_type)
                    SELECT def_data.id_order_set_task, def_data.id_task_link, def_data.flg_task_link_type
                      FROM (SELECT l_ost_table(i).l_ost id_order_set_task,
                                   temp_data.id_task_link,
                                   temp_data.flg_task_link_type,
                                   temp_data.id_market,
                                   temp_data.version,
                                   row_number() over(PARTITION BY l_ost_table(i).l_ost, temp_data.id_task_link, temp_data.flg_task_link_type
                                   
                                   ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                              FROM (SELECT CASE
                                               WHEN ost.id_task_type = l_number_11
                                                    AND ostl.flg_task_link_type IN (l_var_n, l_var_a) THEN
                                                nvl((SELECT to_char(a.id_analysis)
                                                      FROM analysis a
                                                      JOIN alert_default.analysis a1
                                                        ON a.id_content = a1.id_content
                                                     WHERE a.flg_available = g_flg_available
                                                       AND a1.id_analysis = ostl.id_task_link
                                                       AND a1.flg_available = g_flg_available),
                                                    0)
                                               WHEN ost.id_task_type = l_number_11
                                                    AND ostl.flg_task_link_type = l_var_g THEN
                                               
                                                nvl((SELECT to_char(ag.id_analysis_group)
                                                      FROM analysis_group ag
                                                     WHERE ag.id_analysis_group = ostl.id_task_link
                                                       AND ag.flg_available = g_flg_available),
                                                    0)
                                               WHEN ost.id_task_type = l_number_11
                                                    AND ostl.flg_task_link_type = l_var_c THEN
                                                nvl((SELECT to_char(ac1.id_analysis_codification)
                                                      FROM alert_default.codification c
                                                     INNER JOIN codification c1
                                                        ON c1.id_content = c.id_content
                                                     INNER JOIN alert_default.analysis_codification ac
                                                        ON ac.id_codification = c.id_codification
                                                     INNER JOIN alert_default.analysis a
                                                        ON a.id_analysis = ac.id_analysis
                                                     INNER JOIN analysis a1
                                                        ON a1.id_content = a.id_content
                                                     INNER JOIN analysis_codification ac1
                                                        ON ac1.id_codification = c1.id_codification
                                                       AND ac1.id_analysis = a1.id_analysis
                                                     WHERE ac.id_analysis_codification = ostl.id_task_link
                                                          
                                                       AND ac.flg_available = g_flg_available
                                                       AND a.flg_available = g_flg_available
                                                       AND c.flg_available = g_flg_available
                                                          
                                                       AND a1.flg_available = g_flg_available
                                                       AND c1.flg_available = g_flg_available
                                                          
                                                       AND ac1.flg_available = g_flg_available
                                                       AND rownum = 1),
                                                    0)
                                               WHEN (ost.id_task_type = l_number_4 AND ostl.flg_task_link_type = l_var_n) THEN
                                                nvl((SELECT to_char(spc.id_speciality)
                                                      FROM speciality spc
                                                     INNER JOIN alert_default.speciality def_spc
                                                        ON (def_spc.id_content = spc.id_content)
                                                     WHERE def_spc.id_speciality = ostl.id_task_link
                                                       AND def_spc.flg_available = g_flg_available
                                                       AND spc.flg_available = g_flg_available),
                                                    '0')
                                               WHEN ost.id_task_type = l_number_9
                                                    AND ostl.flg_task_link_type = l_var_n THEN
                                                to_char(ostl.id_task_link)
                                               WHEN ost.id_task_type IN (l_number_7, l_number_8)
                                                    AND ostl.flg_task_link_type IN (l_var_n, l_var_e) THEN
                                                nvl((SELECT to_char(e.id_exam)
                                                      FROM exam e
                                                      JOIN alert_default.exam e1
                                                        ON e.id_content = e1.id_content
                                                     WHERE e.flg_available = g_flg_available
                                                       AND e1.id_exam = ostl.id_task_link
                                                       AND e1.flg_available = g_flg_available),
                                                    '0')
                                               WHEN ost.id_task_type IN (l_number_7, l_number_8)
                                                    AND ostl.flg_task_link_type = l_var_g THEN
                                                nvl((SELECT to_char(eg.id_exam_group)
                                                      FROM exam_group eg
                                                     WHERE eg.id_exam_group = ostl.id_task_link),
                                                    0)
                                               WHEN ost.id_task_type IN (l_number_7, l_number_8)
                                                    AND ostl.flg_task_link_type = l_var_c THEN
                                                nvl((SELECT to_char(ec1.id_exam_codification)
                                                      FROM alert_default.codification c
                                                     INNER JOIN codification c1
                                                        ON c1.id_content = c.id_content
                                                     INNER JOIN alert_default.exam_codification ec
                                                        ON c.id_codification = ec.id_codification
                                                     INNER JOIN alert_default.exam e
                                                        ON ec.id_exam = e.id_exam
                                                     INNER JOIN exam e1
                                                        ON e1.id_content = e.id_content
                                                     INNER JOIN exam_codification ec1
                                                        ON ec1.id_exam = e1.id_exam
                                                       AND ec1.id_codification = c1.id_codification
                                                    
                                                     WHERE ec.id_exam_codification = ostl.id_task_link
                                                          
                                                       AND ec.flg_available = g_flg_available
                                                       AND e.flg_available = g_flg_available
                                                       AND c.flg_available = g_flg_available
                                                          
                                                       AND e1.flg_available = g_flg_available
                                                       AND c1.flg_available = g_flg_available
                                                          
                                                       AND ec1.flg_available = g_flg_available
                                                       AND rownum = 1),
                                                    0)
                                           
                                               WHEN ost.id_task_type = l_number_12
                                                    AND ostl.flg_task_link_type = l_var_n THEN
                                                nvl((SELECT to_char(ntt.id_nurse_tea_topic)
                                                      FROM nurse_tea_topic ntt
                                                     WHERE ntt.flg_available = g_flg_available
                                                       AND ntt.id_nurse_tea_topic = ostl.id_task_link
                                                       AND rownum = 1),
                                                    0)
                                           
                                               WHEN ost.id_task_type = l_number_10
                                                    AND ostl.flg_task_link_type = l_var_n THEN
                                                nvl((SELECT to_char(i.id_intervention)
                                                      FROM intervention i
                                                      JOIN alert_default.intervention i1
                                                        ON i.id_content = i1.id_content
                                                     WHERE i.flg_status = g_active
                                                       AND i1.id_intervention = ostl.id_task_link
                                                       AND i1.flg_status = g_active),
                                                    0)
                                           
                                               WHEN ost.id_task_type = l_number_10
                                                    AND ostl.flg_task_link_type = l_var_c THEN
                                                nvl((SELECT to_char(ic1.id_interv_codification)
                                                      FROM alert_default.codification c
                                                     INNER JOIN
                                                    
                                                    codification c1
                                                        ON c1.id_content = c.id_content
                                                     INNER JOIN alert_default.interv_codification ic
                                                        ON ic.id_codification = c.id_codification
                                                     INNER JOIN alert_default.intervention i
                                                        ON i.id_intervention = ic.id_intervention
                                                     INNER JOIN
                                                    
                                                    intervention i1
                                                        ON i1.id_content = i.id_content
                                                     INNER JOIN interv_codification ic1
                                                        ON ic1.id_intervention = i1.id_intervention
                                                       AND ic1.id_codification = c1.id_codification
                                                     WHERE ic.id_interv_codification = ostl.id_task_link
                                                          
                                                       AND ic.flg_available = g_flg_available
                                                       AND i.flg_status = g_active
                                                       AND c.flg_available = g_flg_available
                                                          
                                                       AND i1.flg_status = g_active
                                                       AND c1.flg_available = g_flg_available
                                                          
                                                       AND ic1.flg_available = g_flg_available
                                                       AND rownum = 1),
                                                    0)
                                           
                                           END id_task_link,
                                           ostl.flg_task_link_type,
                                           ost.id_task_type,
                                           osmv.id_market,
                                           osmv.version
                                      FROM alert_default.order_set_task_link ostl
                                     INNER JOIN alert_default.order_set_task ost
                                        ON ostl.id_order_set_task = ost.id_order_set_task
                                     INNER JOIN alert_default.order_set os
                                        ON os.id_order_set = ost.id_order_set
                                     INNER JOIN alert_default.order_set_mrk_vrs osmv
                                        ON osmv.id_order_set = os.id_order_set
                                     INNER JOIN order_set os1
                                        ON os1.id_content = os.id_content
                                       AND os1.id_institution = i_institution
                                     WHERE ost.id_task_type NOT IN (l_number_2, l_number_5, l_number_3)
                                       AND osmv.id_market IN
                                           (SELECT /*+ dynamic_sampling(p 2)*/
                                             column_value
                                              FROM TABLE(CAST(i_mkt AS table_number)) p)
                                       AND osmv.version IN
                                           (SELECT /*+ dynamic_sampling(p 2)*/
                                             column_value
                                              FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                       AND os1.id_professional IS NULL
                                       AND ost.id_order_set_task = l_ost_table(i).l_ost_def
                                    
                                    UNION ALL
                                    SELECT /*+ dynamic_sampling(clinical_servs 2)*/
                                     nvl((SELECT to_char(cs.id_clinical_service)
                                           FROM clinical_service cs
                                          INNER JOIN alert_default.clinical_service cs1
                                             ON (cs1.id_content = cs.id_content)
                                          WHERE cs1.id_clinical_service = clinical_servs.column_value
                                            AND cs1.flg_available = g_flg_available
                                            AND cs.flg_available = g_flg_available),
                                         0) id_task_link,
                                     
                                     first_data.flg_task_link_type,
                                     first_data.id_task_type,
                                     first_data.id_market,
                                     first_data.version
                                    
                                      FROM (SELECT /* to_char(cs.id_clinical_service)*/
                                             ostl.id_task_link,
                                             ostl.flg_task_link_type,
                                             ost.id_task_type,
                                             os.id_content,
                                             osmv.id_market,
                                             osmv.version
                                              FROM alert_default.order_set_task_link ostl
                                             INNER JOIN alert_default.order_set_task ost
                                                ON (ostl.id_order_set_task = ost.id_order_set_task)
                                             INNER JOIN alert_default.order_set os
                                                ON (os.id_order_set = ost.id_order_set)
                                             INNER JOIN alert_default.order_set_mrk_vrs osmv
                                                ON (osmv.id_order_set = os.id_order_set)
                                             WHERE (ost.id_task_type = l_number_3 OR
                                                   (ost.id_task_type = l_number_4 AND ostl.flg_task_link_type = l_var_l))
                                                  
                                               AND osmv.id_market IN
                                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                                                  
                                               AND osmv.version IN
                                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                               AND ost.id_order_set_task = l_ost_table(i).l_ost_def) first_data
                                      JOIN TABLE(CAST(pk_backoffice_default.check_clinical_service_parent(i_lang, first_data.id_task_link) AS table_number)) clinical_servs
                                        ON (1 = 1)
                                     WHERE EXISTS (SELECT 0
                                              FROM order_set os1
                                             WHERE os1.id_institution = i_institution
                                               AND os1.id_professional IS NULL
                                               AND os1.id_content = first_data.id_content)) temp_data) def_data
                     WHERE def_data.records_count = 1
                       AND def_data.id_task_link > 0
                       AND NOT EXISTS (SELECT 0
                              FROM order_set_task_link ostl
                             WHERE ostl.flg_task_link_type = def_data.flg_task_link_type
                               AND ostl.id_task_link = def_data.id_task_link
                               AND ostl.id_order_set_task = l_ost_table(i).l_ost);
        END IF;
        o_result_tbl := SQL%ROWCOUNT;
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN bulk_errors THEN
            FOR indx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(indx).error_code,
                                                  SQLERRM(-sql%BULK_EXCEPTIONS(indx).error_code),
                                                  g_error || -sql%BULK_EXCEPTIONS(indx).error_index,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            END LOOP;
            RETURN FALSE;
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
    END set_order_set_task_l_search;

    -- frequent loader method

    FUNCTION del_order_set_task_l_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete order_set_task_link';
        g_func_name := upper('del_order_set_task_l_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM order_set_task_link osl
             WHERE EXISTS (SELECT 1
                      FROM order_set_task ost
                     WHERE ost.id_order_set_task = osl.id_order_set_task
                       AND EXISTS (SELECT 1
                              FROM order_set os
                             WHERE os.id_order_set = ost.id_order_set
                               AND os.id_professional IS NULL
                               AND os.id_institution = i_institution
                               AND os.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM order_set_task_link osl
             WHERE EXISTS (SELECT 1
                      FROM order_set_task ost
                     WHERE ost.id_order_set_task = osl.id_order_set_task
                       AND EXISTS (SELECT 1
                              FROM order_set os
                             WHERE os.id_order_set = ost.id_order_set
                               AND os.id_professional IS NULL
                               AND os.id_institution = i_institution));
        
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
    END del_order_set_task_l_search;

    -- global vars
    PROCEDURE reset_cfg_done IS
    BEGIN
        g_cfg_done := 'FALSE';
    END reset_cfg_done;

    FUNCTION get_cfg_done RETURN VARCHAR2 IS
    BEGIN
        RETURN g_cfg_done;
    END get_cfg_done;
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
    g_cfg_done    := 'FALSE';
END pk_orderset_prm;
/