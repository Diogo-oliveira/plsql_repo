/*-- Last Change Revision: $Rev: 1938464 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-03-05 10:01:10 +0000 (qui, 05 mar 2020) $*/

CREATE OR REPLACE PACKAGE BODY alert.pk_cancelreason_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_CANCELREASON_prm';
    pos_soft        NUMBER := 1;
    -- g_table_name    t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_cancelreason_search
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
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_CANCELREASON_SEARCH');
    
        MERGE INTO cancel_rea_soft_inst a_crsi
        USING (SELECT def_data.id_cancel_reason,
                      def_data.id_profile_template,
                      i_software(pos_soft) id_software,
                      def_data.flg_available,
                      def_data.rank,
                      def_data.id_cancel_rea_area,
                      def_data.flg_error
               FROM   (SELECT temp_data.id_cancel_reason,
                              temp_data.id_profile_template,
                              temp_data.flg_available,
                              temp_data.rank,
                              temp_data.id_cancel_rea_area,
                              temp_data.flg_error,
                              row_number() over(PARTITION BY temp_data.id_cancel_reason, temp_data.id_profile_template, temp_data.id_cancel_rea_area, temp_data.flg_error ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                       FROM   (SELECT ad_crsi.id_cancel_reason,
                                      ad_crsi.id_profile_template,
                                      ad_crsi.flg_available,
                                      ad_crsi.rank,
                                      decode(l_cnt_count,
                                             0,
                                             ad_crsi.id_cancel_rea_area,
                                             nvl((SELECT a_cra.id_cancel_rea_area
                                                 FROM   cancel_rea_area a_cra
                                                 WHERE  a_cra.id_cancel_rea_area = ad_crsi.id_cancel_rea_area
                                                        AND a_cra.intern_name IN
                                                        (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                             FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                                 0)) id_cancel_rea_area,
                                      ad_crsi.flg_error,
                                      ad_crsi.id_software,
                                      ad_crmv.id_market,
                                      ad_crmv.version
                               FROM   ad_cancel_rea_soft_inst ad_crsi
                               INNER  JOIN ad_cancel_reason_mrk_vrs ad_crmv
                               ON     ad_crmv.id_cancel_reason = ad_crsi.id_cancel_reason
                               WHERE  ad_crsi.flg_available = g_flg_available
                                      AND ad_crmv.id_market IN
                                      (SELECT /*+ opt_estimate(p rows = 10)*/
                                            column_value
                                           FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                      AND ad_crmv.version IN
                                      (SELECT /*+ opt_estimate(p rows = 10)*/
                                            column_value
                                           FROM   TABLE(CAST(i_vers AS table_varchar)) p)
                                      AND ad_crsi.id_software IN
                                      (SELECT /*+ opt_estimate(p rows = 10)*/
                                            column_value
                                           FROM   TABLE(CAST(i_software AS table_number)) p)) temp_data) def_data
               WHERE  def_data.records_count = 1
                      AND def_data.id_cancel_rea_area > 0) result_data
        
        ON (a_crsi.id_cancel_reason = result_data.id_cancel_reason AND a_crsi.id_profile_template = result_data.id_profile_template AND a_crsi.id_software = result_data.id_software AND a_crsi.id_cancel_rea_area = result_data.id_cancel_rea_area AND a_crsi.id_institution = i_institution)
        
        WHEN MATCHED THEN
            UPDATE SET a_crsi.flg_available = result_data.flg_available WHERE a_crsi.flg_available = 'N'
            
        
        WHEN NOT MATCHED THEN
            INSERT
                (id_cancel_reason,
                 id_profile_template,
                 id_software,
                 id_institution,
                 flg_available,
                 rank,
                 id_cancel_rea_area,
                 flg_error)
            VALUES
                (result_data.id_cancel_reason,
                 result_data.id_profile_template,
                 i_software(pos_soft),
                 i_institution,
                 result_data.flg_available,
                 result_data.rank,
                 result_data.id_cancel_rea_area,
                 result_data.flg_error);
    
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
    END set_cancelreason_search;

    -- frequent loader method

    FUNCTION del_cancelreason_search
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete cancel_rea_soft_inst';
        g_func_name := upper('del_cancelreason_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_soft_all
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM cancel_rea_soft_inst crsi
            WHERE  crsi.id_institution = i_institution
                   AND crsi.id_software IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                             column_value
                                            FROM   TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM cancel_rea_soft_inst crsi
            WHERE  crsi.id_institution = i_institution;
        
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
    END del_cancelreason_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner,
                         NAME  => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_cancelreason_prm;
/
