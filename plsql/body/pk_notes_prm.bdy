/*-- Last Change Revision: $Rev: 2027388 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_notes_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_NOTES_prm';

    g_table_name t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_notes_profile_inst_search
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
        g_func_name := upper('set_notes_profile_inst_search');
        INSERT INTO notes_profile_inst
            (id_notes_profile_inst,
             id_profile_template,
             id_notes_config,
             flg_write,
             flg_read,
             flg_available,
             id_institution)
        
            SELECT seq_notes_profile_inst.nextval,
                   def_data.id_profile_template,
                   def_data.id_notes_config,
                   def_data.flg_write,
                   def_data.flg_read,
                   def_data.flg_available,
                   i_institution
            
              FROM (SELECT temp_data.id_profile_template,
                           temp_data.id_notes_config,
                           temp_data.flg_write,
                           temp_data.flg_read,
                           temp_data.flg_available,
                           row_number() over(PARTITION BY temp_data.id_profile_template, temp_data.id_notes_config
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT npi.id_notes_config,
                                   npi.flg_write,
                                   npi.flg_read,
                                   npi.flg_available,
                                   npi.id_profile_template,
                                   ncmv.id_market,
                                   ncmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.notes_profile_inst npi
                             INNER JOIN alert_default.notes_config_mrk_vrs ncmv
                                ON npi.id_notes_config = ncmv.id_notes_config
                            
                             WHERE npi.flg_available = g_flg_available
                                  
                               AND ncmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND ncmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM notes_profile_inst npi1
                     WHERE npi1.id_institution = i_institution
                       AND npi1.id_notes_config = def_data.id_notes_config
                       AND npi1.id_profile_template = def_data.id_profile_template);
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
    END set_notes_profile_inst_search;
    -- frequent loader method

    FUNCTION del_notes_profile_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete notes_profile_inst';
        g_func_name := upper('del_notes_profile_inst_search');
    
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
            DELETE FROM notes_profile_inst npi
             WHERE npi.id_institution = i_institution;
        
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
    END del_notes_profile_inst_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_notes_prm;
/