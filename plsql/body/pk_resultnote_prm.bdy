/*-- Last Change Revision: $Rev: 1905124 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-06 14:57:52 +0100 (qui, 06 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_resultnote_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_RESULTNOTE_prm';
    pos_soft        NUMBER := 1;

    -- Private Methods

    -- content loader method
    FUNCTION load_result_notes_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('result_notes.code_result_notes.');
    BEGIN
        g_func_name := upper('load_result_notes_def');
        INSERT INTO result_notes
            (id_result_notes, code_result_notes, flg_abnormality, flg_free_text, id_content, flg_available)
            SELECT seq_result_notes.nextval,
                   l_code_translation || seq_result_notes.currval,
                   flg_abnormality,
                   flg_free_text,
                   id_content,
                   g_flg_available
              FROM (SELECT source_tbl.flg_abnormality, source_tbl.flg_free_text, source_tbl.id_content
                      FROM alert_default.result_notes source_tbl
                     WHERE source_tbl.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM result_notes dest_tbl
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
    END load_result_notes_def;
    -- searcheable loader method
    FUNCTION set_result_notes_is_search
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
        g_func_name := upper('set_result_notes_is_search');
        INSERT INTO result_notes_instit_soft
            (id_res_notes_instit_soft, id_result_notes, flg_available, rank, id_institution, id_software)
        
            SELECT seq_result_notes_instit_soft.nextval,
                   def_data.id_result_notes,
                   g_flg_available,
                   def_data.rank,
                   i_institution,
                   i_software(pos_soft)
              FROM (SELECT temp_data.id_result_notes,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_result_notes
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) frecords_count
                      FROM (SELECT nvl((SELECT rn.id_result_notes
                                         FROM alert_default.result_notes def_rn
                                        INNER JOIN result_notes rn
                                           ON (rn.id_content = def_rn.id_content)
                                        WHERE def_rn.id_result_notes = def_rnis.id_result_notes
                                          AND def_rn.flg_available = g_flg_available),
                                       0) id_result_notes,
                                   def_rnis.rank,
                                   def_rnis.id_software,
                                   def_rnis.id_market,
                                   def_rnis.version
                              FROM alert_default.result_notes_instit_soft def_rnis
                             WHERE def_rnis.id_market IN (SELECT /*+ dynamic_sampling(m 2) */
                                                           m.column_value
                                                            FROM TABLE(i_mkt) m)
                               AND def_rnis.version IN (SELECT /*+ dynamic_sampling(v 2) */
                                                         v.column_value
                                                          FROM TABLE(i_vers) v)
                               AND def_rnis.id_software IN (SELECT /*+ dynamic_sampling(s 2) */
                                                             s.column_value
                                                              FROM TABLE(i_software) s)
                               AND def_rnis.flg_available = g_flg_available) temp_data
                    -- remove content not available in ALERT DB
                     WHERE temp_data.id_result_notes > 0) def_data
            -- remove duplicates
             WHERE def_data.frecords_count = 1
               AND NOT EXISTS (SELECT 0
                    -- unique key validation
                      FROM result_notes_instit_soft rnis
                     WHERE rnis.id_result_notes = def_data.id_result_notes
                       AND rnis.id_institution = i_institution
                       AND rnis.id_software = i_software(pos_soft)
                       AND rnis.flg_available = g_flg_available);
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
    END set_result_notes_is_search;

    -- frequent loader method

    FUNCTION del_result_notes_is_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete result_notes_instit_soft';
        g_func_name := upper('del_result_notes_is_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM result_notes_instit_soft rnis
             WHERE rnis.id_institution = i_institution
               AND rnis.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM result_notes_instit_soft rnis
             WHERE rnis.id_institution = i_institution;
        
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
    END del_result_notes_is_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_resultnote_prm;
/