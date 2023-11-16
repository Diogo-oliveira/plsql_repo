/*-- Last Change Revision: $Rev: 1905124 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-06 14:57:52 +0100 (qui, 06 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_follow_up_entity_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_follow_up_entity_prm';
    pos_soft        NUMBER := 1;
    g_table_name    t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_follow_up_entity_si_search
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
        g_func_name := upper('set_follow_up_entity_si_search');
        MERGE INTO follow_up_entity_soft_inst fuesi
        USING (SELECT def_data.id_follow_up_entity, def_data.id_software, def_data.flg_available, def_data.rank
                 FROM (SELECT temp_data.id_follow_up_entity,
                              i_software(pos_soft) id_software,
                              temp_data.flg_available,
                              temp_data.rank,
                              row_number() over(PARTITION BY temp_data.id_follow_up_entity ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                         FROM (SELECT def_fuesi.id_follow_up_entity,
                                      def_fuesi.flg_available,
                                      def_fuesi.rank,
                                      def_fuesi.id_software,
                                      fuemv.id_market,
                                      fuemv.version
                                 FROM alert_default.follow_up_entity_soft_inst def_fuesi
                                INNER JOIN alert_default.follow_up_entity_mrk_vrs fuemv
                                   ON (fuemv.id_follow_up_entity = def_fuesi.id_follow_up_entity)
                                WHERE def_fuesi.flg_available = 'Y'
                                  AND fuemv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                            FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  AND fuemv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  AND def_fuesi.id_software IN
                                      (SELECT /*+           opt_estimate(p rows = 10)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p)) temp_data) def_data
                WHERE def_data.records_count = 1) result_data
        ON (fuesi.id_follow_up_entity = result_data.id_follow_up_entity AND fuesi.id_software = result_data.id_software AND fuesi.id_institution = i_institution)
        WHEN MATCHED THEN
            UPDATE
               SET fuesi.flg_available = result_data.flg_available
             WHERE fuesi.flg_available = 'N'
        WHEN NOT MATCHED THEN
            INSERT
                (id_follow_up_entity, id_institution, id_software, flg_available, rank)
            VALUES
                (result_data.id_follow_up_entity,
                 i_institution,
                 i_software(pos_soft),
                 result_data.flg_available,
                 result_data.rank);
    
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
    END set_follow_up_entity_si_search;

    -- frequent loader method

    FUNCTION del_follow_up_entity_si_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete follow_up_entity_soft_inst';
        g_func_name := upper('del_follow_up_entity_si_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM follow_up_entity_soft_inst foesi
             WHERE foesi.id_institution = i_institution
               AND foesi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM follow_up_entity_soft_inst foesi
             WHERE foesi.id_institution = i_institution;
        
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
    END del_follow_up_entity_si_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_follow_up_entity_prm;
/