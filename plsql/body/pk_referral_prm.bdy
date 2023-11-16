/*-- Last Change Revision: $Rev: 2027565 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_referral_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_REFERRAL_prm';

    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_p1_spec_help_search
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
        g_func_name := upper('set_p1_spec_help_search');
        INSERT INTO p1_spec_help
            (id_spec_help, code_title, code_text, rank, id_speciality, flg_available, id_institution)
            SELECT def_data.id_spec_help,
                   def_data.code_title,
                   def_data.code_text,
                   def_data.rank,
                   def_data.id_speciality,
                   def_data.flg_available,
                   i_institution
              FROM (SELECT temp_data.id_spec_help,
                           temp_data.code_title,
                           temp_data.code_text,
                           temp_data.rank,
                           temp_data.id_speciality,
                           temp_data.flg_available,
                           row_number() over(PARTITION BY temp_data.id_spec_help, temp_data.id_speciality
                           
                           ORDER BY temp_data.l_row) records_count
                      FROM (SELECT psh.rowid l_row,
                                   psh.id_spec_help,
                                   psh.code_title,
                                   psh.code_text,
                                   psh.rank,
                                   psh.id_speciality,
                                   psh.flg_available
                            -- decode FKS to dest_vals
                              FROM alert_default.p1_spec_help psh
                            
                             INNER JOIN p1_speciality ps
                                ON ps.id_speciality = psh.id_speciality
                            
                             WHERE psh.flg_available = g_flg_available
                               AND ps.flg_available = psh.flg_available) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM p1_spec_help psh1
                     WHERE psh1.id_spec_help = def_data.id_spec_help
                       AND psh1.id_institution = i_institution
                       AND psh1.id_speciality = def_data.id_speciality
                       AND psh1.flg_available = g_flg_available);
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
    END set_p1_spec_help_search;

    -- frequent loader method

    FUNCTION del_p1_spec_help_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete p1_spec_help';
        g_func_name := upper('del_p1_spec_help_search');
    
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
            DELETE FROM p1_spec_help psh
             WHERE psh.id_institution = i_institution;
        
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
    END del_p1_spec_help_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_referral_prm;
/
