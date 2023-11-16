/*-- Last Change Revision: $Rev: 1905124 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-06 14:57:52 +0100 (qui, 06 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_healthprogram_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_healthprogram_prm';

    -- Private Methods
    pos_soft NUMBER(1) := 1;

    -- content loader method

    -- searcheable loader method

    FUNCTION set_health_program_si_search
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
        g_func_name := upper('set_health_program_si_search');
        MERGE INTO health_program_soft_inst hpsi
        USING (SELECT norm_data.id_health_program, norm_data.id_software, norm_data.flg_active
                 FROM (SELECT temp_data.id_health_program,
                              i_software(pos_soft) id_software,
                              temp_data.flg_active,
                              row_number() over(PARTITION BY temp_data.id_health_program ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                         FROM (SELECT def_hpsi.rowid l_row,
                                      def_hpsi.id_health_program,
                                      def_hpsi.flg_active,
                                      hpmv.id_market,
                                      hpmv.version,
                                      def_hpsi.id_software
                                 FROM alert_default.health_program_soft_inst def_hpsi
                                INNER JOIN alert_default.health_program_mrk_vrs hpmv
                                   ON (hpmv.id_health_program = def_hpsi.id_health_program)
                                WHERE def_hpsi.flg_active = g_flg_available
                                  AND hpmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                          column_value
                                                           FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  AND hpmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  AND def_hpsi.id_software IN
                                      (SELECT /*+ dynamic_sampling(p 2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p)) temp_data) norm_data
                WHERE norm_data.records_count = 1) def_data
        ON (def_data.id_health_program = hpsi.id_health_program AND def_data.id_software = hpsi.id_software AND i_institution = hpsi.id_institution)
        WHEN MATCHED THEN
            UPDATE
               SET flg_active = def_data.flg_active
        WHEN NOT MATCHED THEN
            INSERT
                (id_health_program, id_institution, id_software, flg_active)
            VALUES
                (def_data.id_health_program, i_institution, i_software(pos_soft), def_data.flg_active);
    
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
    END set_health_program_si_search;

    FUNCTION del_health_program_si_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete health_program_soft_inst';
        g_func_name := upper('del_health_program_si_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM po_param_hpg pphpg
             WHERE pphpg.id_institution = i_institution
               AND pphpg.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            DELETE FROM health_program_soft_inst hpsi
             WHERE hpsi.id_institution = i_institution
               AND hpsi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM po_param_hpg pphpg
             WHERE pphpg.id_institution = i_institution;
        
            DELETE FROM health_program_soft_inst hpsi
             WHERE hpsi.id_institution = i_institution;
        
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
    END del_health_program_si_search;

    FUNCTION set_health_program_ev_search
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
        g_func_name := upper('set_health_program_ev_search');
        MERGE INTO health_program_event hpe
        USING (SELECT norm_data.id_health_program, norm_data.id_event, norm_data.id_software, norm_data.flg_active
                 FROM (SELECT temp_data.id_health_program,
                              temp_data.id_event,
                              i_software(pos_soft) id_software,
                              temp_data.flg_active,
                              row_number() over(PARTITION BY temp_data.id_health_program, temp_data.id_event ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                         FROM (SELECT def_hpe.id_health_program,
                                      nvl(pk_backoffice_default.get_event_alert(i_lang, def_hpe.id_event), 0) id_event,
                                      def_hpe.flg_active,
                                      hpmv.id_market,
                                      hpmv.version,
                                      def_hpe.id_software
                                 FROM alert_default.health_program_event def_hpe
                                INNER JOIN alert_default.health_program_mrk_vrs hpmv
                                   ON (hpmv.id_health_program = def_hpe.id_health_program)
                                WHERE def_hpe.flg_active = 'Y'
                                  AND hpmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                          column_value
                                                           FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  AND hpmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  AND def_hpe.id_software IN
                                      (SELECT /*+ dynamic_sampling(p 2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p)) temp_data
                        WHERE temp_data.id_event > 0) norm_data
                WHERE norm_data.records_count = 1) def_data
        ON (def_data.id_health_program = hpe.id_health_program AND def_data.id_event = hpe.id_event AND i_institution = hpe.id_institution AND def_data.id_software = hpe.id_software)
        WHEN MATCHED THEN
            UPDATE
               SET hpe.flg_active = def_data.flg_active
        WHEN NOT MATCHED THEN
            INSERT
                (id_health_program, id_event, id_institution, id_software, dt_hpg_event_tstz, flg_active)
            VALUES
                (def_data.id_health_program,
                 def_data.id_event,
                 i_institution,
                 i_software(pos_soft),
                 current_timestamp,
                 def_data.flg_active);
    
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
    END set_health_program_ev_search;

    -- frequent loader method

    FUNCTION del_health_program_ev_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete health_program_event';
        g_func_name := upper('del_health_program_ev_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM health_program_event hpe
             WHERE hpe.id_institution = i_institution
               AND hpe.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM health_program_event hpe
             WHERE hpe.id_institution = i_institution;
        
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
    END del_health_program_ev_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_healthprogram_prm;
/