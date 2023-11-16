/*-- Last Change Revision: $Rev: 1904835 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-05 09:32:58 +0100 (qua, 05 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_bodystructure_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_BODYSTRUCTURE_prm';

    -- Private Methods

    -- content loader method
    FUNCTION load_body_structure_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('body_structure.code_body_structure.');
    BEGIN
        INSERT INTO body_structure
            (id_body_structure, code_body_structure, flg_available, id_mcs_concept, id_content)
            SELECT seq_body_structure.nextval,
                   l_code_translation || seq_body_structure.currval,
                   g_flg_available,
                   id_mcs_concept,
                   id_content
              FROM (SELECT id_body_structure, id_mcs_concept, id_content
                      FROM alert_default.body_structure source_tbl
                     WHERE flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM body_structure dest_tbl
                             WHERE source_tbl.id_mcs_concept = dest_tbl.id_mcs_concept)) def_data;
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
    END load_body_structure_def;

    -- searcheable loader method

    -- frequent loader method
    FUNCTION set_body_structure_freq
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
        g_func_name := upper('set_body_structure_freq');
        INSERT INTO body_structure_dcs
            (id_body_structure_dcs, id_body_structure, id_dep_clin_serv, id_institution, flg_default, flg_available)
            SELECT seq_body_structure_dcs.nextval,
                   def_data.id_body_structure,
                   i_dep_clin_serv_out,
                   i_institution,
                   def_data.flg_default,
                   g_flg_available
              FROM (SELECT temp_data.id_body_structure,
                           temp_data.flg_default,
                           row_number() over(PARTITION BY temp_data.id_body_structure, temp_data.flg_default ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT alert_bs.id_body_structure
                                         FROM body_structure alert_bs
                                        INNER JOIN alert_default.body_structure def_bs
                                           ON (def_bs.id_content = alert_bs.id_content AND
                                              def_bs.flg_available = g_flg_available)
                                        WHERE alert_bs.flg_available = g_flg_available
                                          AND def_bs.id_body_structure = bsc.id_body_structure),
                                       0) id_body_structure,
                                   bsc.flg_default,
                                   bsmv.id_market,
                                   bsmv.version
                              FROM alert_default.body_structure_cs bsc
                             INNER JOIN alert_default.body_structure_mrk_vrs bsmv
                                ON (bsmv.id_body_structure = bsc.id_body_structure)
                             WHERE bsmv.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND bsmv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND bsc.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)
                               AND bsc.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_body_structure > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM body_structure_dcs bsdcs
                     WHERE bsdcs.id_body_structure = def_data.id_body_structure
                       AND bsdcs.id_dep_clin_serv = i_dep_clin_serv_out
                       AND bsdcs.id_institution = i_institution
                       AND bsdcs.flg_available = g_flg_available
                       AND bsdcs.flg_default = def_data.flg_default);
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
    END set_body_structure_freq;
	
	FUNCTION del_body_structure_freq
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
        g_error     := 'delete body_structure_dcs';
        g_func_name := upper('del_body_structure_freq');
    
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
    
        DELETE FROM body_structure_dcs bs
         WHERE bs.id_dep_clin_serv IN (SELECT /*+ dynamic_sampling(2)*/
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
    END del_body_structure_freq;
    -- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_yes           := pk_alert_constant.g_yes;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_bodystructure_prm;
/