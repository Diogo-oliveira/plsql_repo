/*-- Last Change Revision: $Rev: 2026838 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_bodydiagram_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_BODYDIAGRAM_prm';
    pos_soft        NUMBER := 1;
    -- g_table_name    t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_bd_age_grp_si_search
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
        g_func_name := upper('set_bd_age_grp_si_search');
        INSERT INTO bd_age_grp_soft_inst
            (id_body_diag_age_grp, min_age, max_age, id_software, id_institution)
        
            SELECT def_data.id_body_diag_age_grp,
                   def_data.min_age,
                   def_data.max_age,
                   i_software(pos_soft),
                   i_institution
              FROM (SELECT temp_data.id_body_diag_age_grp,
                           temp_data.min_age,
                           temp_data.max_age,
                           row_number() over(PARTITION BY temp_data.id_body_diag_age_grp
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT bdsi.id_body_diag_age_grp,
                                    bdsi.min_age,
                                    bdsi.max_age,
                                    bdsi.id_software,
                                    bdmv.id_market,
                                    bdmv.version
                             -- decode FKS to dest_vals
                               FROM alert_default.bd_age_grp_soft_inst bdsi
                              INNER JOIN alert_default.body_diag_age_grp_mrk_vrs bdmv
                                 ON bdmv.id_body_diag_age_grp = bdsi.id_body_diag_age_grp
                              INNER JOIN body_diag_age_grp bdag
                                 ON bdag.id_body_diag_age_grp = bdsi.id_body_diag_age_grp
                             
                              WHERE
                             
                              bdsi.id_software IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_software AS table_number)) p)
                           AND bdmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                  column_value
                                                   FROM TABLE(CAST(i_mkt AS table_number)) p)
                             
                           AND bdmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                column_value
                                                 FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM bd_age_grp_soft_inst bdsi1
                     WHERE bdsi1.id_body_diag_age_grp = def_data.id_body_diag_age_grp
                       AND bdsi1.id_institution = i_institution
                       AND bdsi1.id_software = i_software(pos_soft));
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
    END set_bd_age_grp_si_search;
    -- frequent loader method
	
	FUNCTION del_bd_age_grp_si_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete bd_age_grp_si_search';
        g_func_name := upper('del_bd_age_grp_si_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM bd_age_grp_soft_inst bagsi
             WHERE bagsi.id_institution = i_institution
               AND bagsi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM bd_age_grp_soft_inst bagsi
             WHERE bagsi.id_institution = i_institution;
        
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
    END del_bd_age_grp_si_search;

    FUNCTION set_diag_lay_dcs_freq
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
        g_func_name := upper('set_diag_lay_dep_clin_serv_freq');
        INSERT INTO diag_lay_dep_clin_serv
            (id_diag_lay_dep_clin_serv,
             id_diagram_layout,
             id_institution,
             id_software,
             flg_type,
             rank,
             adw_last_update,
             id_dep_clin_serv)
            SELECT seq_diag_lay_dep_clin_serv.nextval,
                   def_data.id_diagram_layout,
                   i_institution,
                   i_software(pos_soft) id_software,
                   def_data.flg_type,
                   0,
                   SYSDATE,
                   i_dep_clin_serv_out
              FROM (SELECT def_dlcs.id_diagram_layout,
                           def_dlcs.flg_type,
                           row_number() over(PARTITION BY def_dlcs.id_diagram_layout, def_dlcs.flg_type ORDER BY def_dlcs.id_software DESC, def_dlcs.id_market DESC, decode(def_dlcs.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM alert_default.diag_lay_clin_serv def_dlcs
                     WHERE def_dlcs.id_software IN
                           (SELECT /*+ dynamic_sampling(p 2) */
                             column_value
                              FROM TABLE(CAST(i_software AS table_number)) p)
                       AND def_dlcs.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                   column_value
                                                    FROM TABLE(CAST(i_mkt AS table_number)) p)
                       AND def_dlcs.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                 column_value
                                                  FROM TABLE(CAST(i_vers AS table_varchar)) p)
                       AND def_dlcs.id_clinical_service IN
                           (SELECT /*+ dynamic_sampling(p 2) */
                             column_value
                              FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM diag_lay_dep_clin_serv dldcs
                     WHERE dldcs.id_diagram_layout = def_data.id_diagram_layout
                       AND dldcs.id_software = i_software(pos_soft)
                       AND dldcs.flg_type = def_data.flg_type
                       AND dldcs.id_dep_clin_serv = i_dep_clin_serv_out);
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
    END set_diag_lay_dcs_freq;
	
	FUNCTION del_diag_lay_dcs_freq
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete diag_lay_dcs_freq';
        g_func_name := upper('del_diag_lay_dcs_freq');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM diag_lay_dep_clin_serv dldcs
             WHERE dldcs.id_institution = i_institution
               AND dldcs.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM diag_lay_dep_clin_serv dldcs
             WHERE dldcs.id_institution = i_institution;
        
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
    END del_diag_lay_dcs_freq;
    -- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_bodydiagram_prm;
/