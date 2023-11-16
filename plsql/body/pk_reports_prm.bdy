/*-- Last Change Revision: $Rev:$*/
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/

CREATE OR REPLACE PACKAGE BODY pk_reports_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'pk_reports_prm';
    pos_soft        NUMBER := 1;

    /**
    * Configure reports per institution
    *
    * @param i_lang                              Prefered language ID
    * @param i_institution                     Institution ID
    * @param i_mkt                              Market ID (check content_market_version table)
    * @param i_vers                              Content Version (check content_market_version table)
    * @param i_software                        Software ID
    * @param o_result_tbl                     Number of records inserted
    * @param o_error                            Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/09/10
    */


    FUNCTION set_rep_section_cfg_inst_soft
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt IN table_number,
        i_vers IN table_varchar,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_func_name := upper('set_rep_section_cfg_inst_soft');
    
        INSERT INTO rep_section_cfg_inst_soft
            (id_rep_section_cfg_inst_soft,
             id_rep_section,
             id_reports,
             id_institution,
             id_software,
             id_rep_profile_template,
             rep_section_area,
             id_context,
             id_task_type_context,
             rank)
            SELECT seq_rep_section_cfg_inst_soft.nextval,
                   def_data.id_rep_section,
                   def_data.id_reports,
                   i_institution,
                   i_software(pos_soft),
                   def_data.id_rep_profile_template,
                   def_data.rep_section_area,
                   def_data.id_context,
                   def_data.id_task_type_context,
                   def_data.rank
            FROM   (SELECT rssmv.id_rep_section,
                           rssmv.id_reports,
                           rssmv.id_rep_profile_template,
                           rssmv.rep_section_area,
                           rssmv.id_context,
                           rssmv.id_task_type_context,
                           rssmv.rank,
                           row_number() over(PARTITION BY rssmv.id_rep_section, rssmv.id_reports, rssmv.id_rep_profile_template, rssmv.rep_section_area, rssmv.id_context, rssmv.id_task_type_context ORDER BY rssmv.id_software DESC, rssmv.id_market DESC, decode(rssmv.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   ad_rep_section_soft_mkt_vrs rssmv
                    WHERE  rssmv.flg_available = g_flg_available
                           AND rssmv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                  column_value
                                                 FROM   TABLE(CAST(i_vers AS table_varchar)) p)
                           AND rssmv.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                    column_value
                                                   FROM   TABLE(CAST(i_mkt AS table_number)) p)
                           AND
                           rssmv.id_software IN (SELECT /*+ dynamic_sampling(p 2) */
                                                  column_value
                                                 FROM   TABLE(CAST(i_software AS table_number)) p)) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 1
                    FROM   rep_section_cfg_inst_soft rscis
                    WHERE  rscis.id_rep_section = def_data.id_rep_section
                           AND rscis.id_reports = def_data.id_reports
                           AND rscis.id_institution = i_institution
                           AND rscis.id_software = i_software(pos_soft)
                           AND rscis.id_rep_profile_template = def_data.id_rep_profile_template
                           AND rscis.rep_section_area = def_data.rep_section_area
                           AND rscis.id_context = def_data.id_context
                           AND rscis.id_task_type_context = def_data.id_task_type_context);
    
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
    END set_rep_section_cfg_inst_soft;

    /**
    * Delete reports per institution
    *
    * @param i_lang                              Prefered language ID
    * @param i_institution                     Institution ID
    * @param i_software                        Software ID
    * @param o_result_tbl                     Number of records inserted
    * @param o_error                            Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/09/10
    */

    FUNCTION del_rep_section_cfg_inst_soft
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete rep_section_cfg_inst_soft';
        g_func_name := upper('del_rep_section_cfg_inst_soft');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_soft_all
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM rep_section_cfg_inst_soft rscis
            WHERE  rscis.id_institution = i_institution
                   AND rscis.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                              column_value
                                             FROM   TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM rep_section_cfg_inst_soft rscis
            WHERE  rscis.id_institution = i_institution;
        
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
        
    END del_rep_section_cfg_inst_soft;



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

END pk_reports_prm;
/
