/*-- Last Change Revision: $Rev: 1909612 $*/
/*-- Last Change by: $Author: helder.moreira $*/
/*-- Date of last change: $Date: 2019-07-25 10:55:09 +0100 (qui, 25 jul 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_transport_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_TRANSPORT_prm';

    --g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_transp_entity_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('transp_entity.code_transp_entity.');
    BEGIN
        g_func_name := upper('load_transp_entity_def');
        INSERT INTO transp_entity
            (id_transp_entity,
             code_transp_entity,
             rank,
             flg_type,
             flg_transp,
             flg_available,
             id_content,
             id_institution)
            SELECT seq_transp_entity.nextval,
                   l_code_translation || seq_transp_entity.currval,
                   def_data.rank,
                   def_data.flg_type,
                   def_data.flg_transp,
                   def_data.flg_available,
                   def_data.id_content,
                   0
              FROM (SELECT source_tbl.rank,
                           source_tbl.flg_type,
                           source_tbl.flg_transp,
                           source_tbl.flg_available,
                           source_tbl.id_content
                      FROM alert_default.transp_entity source_tbl
                     WHERE source_tbl.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM transp_entity dest_tbl
                             WHERE dest_tbl.id_content = source_tbl.id_content
                               AND dest_tbl.flg_available = g_flg_available)) def_data;
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
    END load_transp_entity_def;
    -- searcheable loader method
    FUNCTION set_transp_ent_inst_search
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
        g_func_name := upper('set_transp_ent_inst_search');
        INSERT INTO transp_ent_inst
            (id_transp_ent_inst, id_transp_entity, flg_available, flg_type, id_institution)
        
            SELECT seq_transp_ent_inst.nextval,
                   def_data.i_transp_entity,
                   g_flg_available,
                   pk_alert_constant.g_active,
                   i_institution
              FROM (SELECT temp_data.i_transp_entity,
                           row_number() over(PARTITION BY temp_data.i_transp_entity
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT tea.id_transp_entity
                                         FROM transp_entity tea
                                        WHERE tea.id_content = te.id_content
                                          AND tea.flg_available = g_flg_available
                                          AND tea.id_institution = 0),
                                       0) i_transp_entity,
                                   temv.id_market,
                                   temv.version
                            
                            -- decode FKS to dest_vals
                              FROM alert_default.transp_entity_mrk_vrs temv
                             INNER JOIN alert_default.transp_entity te
                                ON te.id_transp_entity = temv.id_transp_entity
                            
                             WHERE te.flg_available = g_flg_available
                                  
                               AND temv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND temv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.i_transp_entity > 0
               AND NOT EXISTS (SELECT 0
                      FROM transp_ent_inst tei
                     WHERE tei.id_transp_entity = i_transp_entity
                       AND tei.flg_available = g_flg_available
                       AND tei.id_institution = i_institution);
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
    END set_transp_ent_inst_search;

	-- frequent loader method

	FUNCTION del_transp_ent_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete transp_ent_inst';
        g_func_name := upper('del_transp_ent_inst_search');
    
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
            UPDATE transp_ent_inst tei
               SET tei.flg_available = 'N'
             WHERE tei.id_institution = i_institution
			   AND tei.flg_available = 'Y';

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
    END del_transp_ent_inst_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_transport_prm;
/