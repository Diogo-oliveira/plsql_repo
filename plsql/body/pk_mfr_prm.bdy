/*-- Last Change Revision: $Rev: 1904876 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-05 14:34:22 +0100 (qua, 05 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_mfr_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_MFR_prm';

    g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_rehab_area_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('rehab_area.code_rehab_area.');
    BEGIN
        g_func_name := upper('load_rehab_area_def');
        INSERT INTO rehab_area
            (id_rehab_area, code_rehab_area, id_content)
            SELECT seq_rehab_area.nextval, l_code_translation || seq_rehab_area.currval, id_content
              FROM (SELECT ra.id_content
                      FROM alert_default.rehab_area ra
                     WHERE ra.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM rehab_area dest_tbl
                             WHERE dest_tbl.id_content = ra.id_content)) def_data;
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
    END load_rehab_area_def;

    FUNCTION load_rehab_session_type_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('rehab_session_type.code_rehab_session_type.');
    BEGIN
        g_func_name := upper('load_rehab_session_type_def');
        INSERT INTO rehab_session_type
            (id_rehab_session_type, code_rehab_session_type, id_content)
            SELECT 'REHAB' || lpad(seq_rehab_session_type.nextval,
                                   length(seq_rehab_session_type.currval) + length(max_val) -
                                   length(seq_rehab_session_type.currval),
                                   '0'),
                   l_code_translation || 'REHAB' || lpad(seq_rehab_session_type.currval,
                                                         length(seq_rehab_session_type.currval) + length(max_val) -
                                                         length(seq_rehab_session_type.currval),
                                                         '0'),
                   id_content
              FROM (SELECT rst.id_rehab_session_type,
                           rst.id_content,
                           nvl((SELECT MAX(ltrim(id_rehab_session_type, 'REHAB'))
                                 FROM alert_default.rehab_session_type rst),
                               1000) max_val
                      FROM alert_default.rehab_session_type rst
                     WHERE rst.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM rehab_session_type dest_tbl
                             WHERE dest_tbl.id_content = rst.id_content)) def_data;
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
    END load_rehab_session_type_def;

    -- searcheable loader method
    FUNCTION set_rehab_area_interv_search
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
        g_func_name := upper('set_rehab_area_interv_search');
        INSERT INTO rehab_area_interv
            (id_rehab_area_interv, id_rehab_area, id_intervention)
            SELECT seq_rehab_area_interv.nextval, def_data.id_rehab_area, def_data.id_intervention
              FROM (SELECT temp_data.id_rehab_area,
                           temp_data.id_intervention,
                           row_number() over(PARTITION BY temp_data.id_rehab_area, temp_data.id_intervention
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_ra.id_rehab_area
                                         FROM rehab_area ext_ra
                                        INNER JOIN alert_default.rehab_area int_ra
                                           ON (int_ra.id_content = ext_ra.id_content AND
                                              int_ra.flg_available = g_flg_available)
                                        WHERE int_ra.id_rehab_area = src_tbl.id_rehab_area),
                                       0) id_rehab_area,
                                   nvl((SELECT ext_i.id_intervention
                                         FROM intervention ext_i
                                        INNER JOIN alert_default.intervention int_i
                                           ON (int_i.id_content = ext_i.id_content)
                                        WHERE int_i.id_intervention = src_tbl.id_intervention
                                          AND ext_i.flg_status = 'A'),
                                       0) id_intervention,
                                   imv.id_market,
                                   imv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.rehab_area_interv src_tbl
                             INNER JOIN alert_default.rehab_area_mrk_vrs ramv
                                ON (ramv.id_rehab_area = src_tbl.id_rehab_area)
                             INNER JOIN alert_default.interv_mrk_vrs imv
                                ON (imv.id_intervention = src_tbl.id_intervention AND imv.id_market = ramv.id_market AND
                                   imv.version = ramv.version)
                             WHERE ramv.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND ramv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_rehab_area > 0
                       AND temp_data.id_intervention > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM rehab_area_interv dest_tbl
                     WHERE dest_tbl.id_rehab_area = def_data.id_rehab_area
                       AND dest_tbl.id_intervention = def_data.id_intervention);
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
    END set_rehab_area_interv_search;
    -- rehab_area_inst
    FUNCTION set_rehab_area_search
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
        g_func_name := upper('set_rehab_area_search');
        INSERT INTO rehab_area_inst
            (id_rehab_area_inst, id_rehab_area, id_institution, flg_add_remove)
            SELECT seq_rehab_area_inst.nextval,
                   def_data.id_rehab_area,
                   def_data.id_institution,
                   def_data.flg_add_remove
              FROM (SELECT temp_data.id_rehab_area,
                           temp_data.id_institution,
                           temp_data.flg_add_remove,
                           row_number() over(PARTITION BY temp_data.id_rehab_area
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_ra.id_rehab_area
                                         FROM rehab_area ext_ra
                                        INNER JOIN alert_default.rehab_area int_ra
                                           ON (int_ra.id_content = ext_ra.id_content AND
                                              int_ra.flg_available = g_flg_available)
                                        WHERE int_ra.id_rehab_area = src_tbl.id_rehab_area),
                                       0) id_rehab_area,
                                   i_institution id_institution,
                                   'A' flg_add_remove,
                                   ramv.id_market,
                                   ramv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.rehab_area src_tbl
                             INNER JOIN alert_default.rehab_area_mrk_vrs ramv
                                ON (ramv.id_rehab_area = src_tbl.id_rehab_area)
                             WHERE ramv.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND ramv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_rehab_area > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM rehab_area_inst dest_tbl
                     WHERE dest_tbl.id_rehab_area = def_data.id_rehab_area
                       AND dest_tbl.id_institution = def_data.id_institution);
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
    END set_rehab_area_search;
    
	FUNCTION del_rehab_area_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete rehab_area_inst and rehab_area_inst_prof';
        g_func_name := upper('del_rehab_area_search');
    
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
            -- there is no update content, because there isn't any flg to inactivate, or nay field
            DELETE rehab_area_inst_prof a
             WHERE EXISTS (SELECT 1
                      FROM alert.rehab_area_inst b
                     WHERE b.id_rehab_area_inst = a.id_rehab_area_inst
                       AND b.id_institution = i_institution);
        
            DELETE FROM rehab_area_inst rai
             WHERE rai.id_institution = i_institution;
        
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
    END del_rehab_area_search;

    FUNCTION set_rehab_search
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
        g_func_name := upper('set_rehab_search');
        INSERT INTO rehab_inst_soft
            (id_rehab_inst_soft,
             id_rehab_area_interv,
             id_institution,
             id_software,
             id_rehab_session_type,
             flg_execute,
             flg_add_remove)
            SELECT seq_rehab_inst_soft.nextval,
                   id_rehab_area_interv,
                   id_institution,
                   id_software,
                   id_rehab_session_type,
                   flg_execute,
                   flg_add_remove
              FROM (SELECT temp_data.id_rehab_area_interv,
                           i_institution id_institution,
                           i_software(1) id_software,
                           temp_data.id_rehab_session_type,
                           temp_data.flg_execute,
                           temp_data.flg_add_remove,
                           row_number() over(PARTITION BY temp_data.id_rehab_area_interv
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT --id_rehab_inst_soft,
                             nvl((SELECT ext_rai.id_rehab_area_interv
                                   FROM rehab_area_interv ext_rai
                                  INNER JOIN rehab_area ext_ra
                                     ON (ext_ra.id_rehab_area = ext_rai.id_rehab_area)
                                  INNER JOIN intervention ext_i
                                     ON (ext_i.id_intervention = ext_rai.id_intervention AND ext_i.flg_status = 'A')
                                  INNER JOIN alert_default.rehab_area int_ra
                                     ON (int_ra.id_content = ext_ra.id_content AND int_ra.flg_available = 'Y')
                                  INNER JOIN alert_default.intervention int_i
                                     ON (int_i.id_content = ext_i.id_content AND int_i.flg_status = 'A')
                                  WHERE int_ra.id_rehab_area = ramv.id_rehab_area
                                    AND int_i.id_intervention = rai.id_intervention),
                                 0) id_rehab_area_interv,
                             
                             nvl((SELECT ext_rst.id_rehab_session_type
                                   FROM rehab_session_type ext_rst
                                  INNER JOIN alert_default.rehab_session_type int_rst
                                     ON (int_rst.id_content = ext_rst.id_content AND int_rst.flg_available = 'Y')
                                  WHERE int_rst.id_rehab_session_type = src_tbl.id_rehab_session_type),
                                 '0') id_rehab_session_type,
                             src_tbl.flg_execute,
                             src_tbl.flg_add_remove,
                             src_tbl.id_software,
                             ramv.id_market,
                             ramv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.rehab_inst_soft src_tbl
                             INNER JOIN alert_default.rehab_area_interv rai
                                ON (rai.id_rehab_area_interv = src_tbl.id_rehab_area_interv)
                             INNER JOIN alert_default.rehab_area_mrk_vrs ramv
                                ON (ramv.id_rehab_area = rai.id_rehab_area)
                             INNER JOIN alert_default.rehab_session_type_mrk_vrs rstmv
                                ON (rstmv.id_rehab_session_type = src_tbl.id_rehab_session_type AND
                                   rstmv.id_market = ramv.id_market AND rstmv.version = ramv.version)
                             WHERE src_tbl.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ramv.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND ramv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_rehab_session_type != '0'
                       AND temp_data.id_rehab_area_interv > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM rehab_inst_soft dest_tbl
                     WHERE dest_tbl.id_rehab_area_interv = def_data.id_rehab_area_interv
                       AND dest_tbl.id_institution = def_data.id_institution
                       AND dest_tbl.id_software = def_data.id_software
                       AND dest_tbl.id_rehab_session_type = def_data.id_rehab_session_type
                       AND dest_tbl.flg_add_remove = def_data.flg_add_remove
                       AND dest_tbl.flg_execute = def_data.flg_execute);
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
    END set_rehab_search;

    FUNCTION del_rehab_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete rehab_inst_soft';
        g_func_name := upper('del_rehab_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM alert.rehab_inst_soft_ext rise
             WHERE EXISTS
             (SELECT 1
                      FROM rehab_inst_soft ris
                     WHERE ris.id_rehab_inst_soft = rise.id_rehab_inst_soft
                       AND ris.id_institution = i_institution
                       AND ris.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                column_value
                                                 FROM TABLE(CAST(i_software AS table_number)) p));
        
            DELETE FROM rehab_inst_soft ris
             WHERE ris.id_institution = i_institution
               AND ris.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM alert.rehab_inst_soft_ext rise
             WHERE EXISTS (SELECT 1
                      FROM rehab_inst_soft ris
                     WHERE ris.id_rehab_inst_soft = rise.id_rehab_inst_soft
                       AND ris.id_institution = i_institution);
        
            DELETE FROM rehab_inst_soft ris
             WHERE ris.id_institution = i_institution;
        
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
    END del_rehab_search;

    -- frequent loader method
    FUNCTION set_rehab_freq
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
    BEGIN
        g_func_name := upper('set_rehab_freq');
        INSERT INTO rehab_dep_clin_serv
            (id_dep_clin_serv, id_rehab_session_type)
            SELECT def_data.id_dep_clin_serv, def_data.id_rehab_session_type
              FROM (SELECT i_dep_clin_serv_out id_dep_clin_serv,
                           temp_data.id_rehab_session_type,
                           row_number() over(PARTITION BY temp_data.id_rehab_session_type
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT alert_rst.id_rehab_session_type
                                         FROM rehab_session_type alert_rst
                                        WHERE alert_rst.id_content = rst.id_content
                                          AND rownum = 1),
                                       '-100') id_rehab_session_type,
                                   rstmv.id_market,
                                   rstmv.version
                              FROM alert_default.rehab_clin_serv rcs
                             INNER JOIN alert_default.rehab_session_type rst
                                ON (rst.id_rehab_session_type = rcs.id_rehab_session_type AND
                                   rst.flg_available = g_flg_available)
                             INNER JOIN alert_default.rehab_session_type_mrk_vrs rstmv
                                ON (rstmv.id_rehab_session_type = rst.id_rehab_session_type AND
                                   rstmv.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p) AND
                                   rstmv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p))
                             WHERE rcs.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                     WHERE temp_data.id_rehab_session_type != '-100') def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM rehab_dep_clin_serv ext_tbl
                     WHERE ext_tbl.id_dep_clin_serv = i_dep_clin_serv_out
                       AND ext_tbl.id_rehab_session_type = def_data.id_rehab_session_type);
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
    END set_rehab_freq;

    FUNCTION del_rehab_freq
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
        g_error     := 'delete rehab_dep_clin_serv';
        g_func_name := upper('del_rehab_freq');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            SELECT dcs.id_dep_clin_serv
              BULK COLLECT
              INTO o_dcs_list
              FROM dep_clin_serv dcs
             INNER JOIN department d
                ON (d.id_department = dcs.id_department)
             INNER JOIN dept dp
                ON (dp.id_dept = d.id_dept)
             INNER JOIN software_dept sd
                ON (sd.id_dept = dp.id_dept)
             WHERE d.id_institution = i_institution
               AND d.id_institution = dp.id_institution
               AND dcs.id_clinical_service != 0
               AND sd.id_software IN (SELECT /*+ opt_estimate(area_list rows = 2)*/
                                       column_value
                                        FROM TABLE(CAST(i_software AS table_number)) sw_list);
        ELSE
            SELECT dcs.id_dep_clin_serv
              BULK COLLECT
              INTO o_dcs_list
              FROM dep_clin_serv dcs
             INNER JOIN department d
                ON (d.id_department = dcs.id_department)
             INNER JOIN dept dp
                ON (dp.id_dept = d.id_dept)
             INNER JOIN software_dept sd
                ON (sd.id_dept = dp.id_dept)
             WHERE d.id_institution = i_institution
               AND d.id_institution = dp.id_institution
               AND dcs.id_clinical_service != 0;
        END IF;
    
        DELETE FROM rehab_dep_clin_serv rdcs
         WHERE rdcs.id_dep_clin_serv IN (SELECT /*+ dynamic_sampling(2)*/
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
    END del_rehab_freq;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_mfr_prm;
/
