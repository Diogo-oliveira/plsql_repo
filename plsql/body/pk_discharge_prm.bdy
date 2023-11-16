/*-- Last Change Revision: $Rev: 2046158 $*/
/*-- Last Change by: $Author: joana.barros $*/
/*-- Date of last change: $Date: 2022-09-23 12:16:47 +0100 (sex, 23 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_discharge_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'pk_discharge_prm';
    pos_soft        NUMBER := 1;
    g_flg_active    VARCHAR2(1) := 'A';
    g_flg_inactive  VARCHAR2(1) := 'I';
    g_no            VARCHAR2(1) := 'N';
    -- Private Methods

    -- content loader method
    FUNCTION ld_disch_instructions_grp_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('DISCH_INSTRUCTIONS_GROUP.CODE_DISCH_INSTRUCTIONS_GROUP.');
    
    BEGIN
    
        INSERT INTO disch_instructions_group
            (id_disch_instructions_group, code_disch_instructions_group, flg_available, adw_last_update, id_content)
            SELECT seq_disch_instructions.nextval,
                   l_code_translation || seq_disch_instructions.currval,
                   g_flg_available,
                   SYSDATE,
                   id_content
              FROM (SELECT ad_dig.id_disch_instructions_group, ad_dig.id_content
                      FROM ad_disch_instructions_group ad_dig
                     WHERE ad_dig.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM disch_instructions_group a_dig
                             WHERE a_dig.id_content = ad_dig.id_content
                               AND a_dig.flg_available = g_flg_available)) def_data;
    
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
        
    END ld_disch_instructions_grp_def;

    FUNCTION ld_disch_instructions_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation       translation.code_translation%TYPE := upper('DISCH_INSTRUCTIONS.CODE_DISCH_INSTRUCTIONS.');
        l_code_translation_title translation.code_translation%TYPE := upper('DISCH_INSTRUCTIONS.CODE_DISCH_INSTRUCTIONS_TITLE.');
    
    BEGIN
    
        INSERT INTO disch_instructions
            (id_disch_instructions,
             code_disch_instructions,
             code_disch_instructions_title,
             flg_available,
             adw_last_update,
             id_content)
            SELECT seq_disch_instructions.nextval,
                   l_code_translation || seq_disch_instructions.currval,
                   l_code_translation_title || seq_disch_instructions.currval,
                   g_flg_available,
                   SYSDATE,
                   id_content
              FROM (SELECT ad_di.id_disch_instructions, ad_di.id_content
                      FROM ad_disch_instructions ad_di
                     WHERE ad_di.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM disch_instructions a_di
                             WHERE a_di.id_content = ad_di.id_content
                               AND a_di.flg_available = g_flg_available)) def_data;
    
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
        
    END ld_disch_instructions_def;

    FUNCTION load_discharge_dest_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('DISCHARGE_DEST.CODE_DISCHARGE_DEST.');
    
    BEGIN
    
        INSERT INTO discharge_dest
            (id_discharge_dest, code_discharge_dest, flg_available, rank, adw_last_update, flg_type, id_content)
            SELECT seq_discharge_dest.nextval,
                   l_code_translation || seq_discharge_dest.currval,
                   g_flg_available,
                   1,
                   SYSDATE,
                   flg_type,
                   id_content
              FROM (SELECT ad_dd.id_content, ad_dd.flg_type
                      FROM ad_discharge_dest ad_dd
                     WHERE ad_dd.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM discharge_dest a_dd
                             WHERE a_dd.id_content = ad_dd.id_content
                               AND a_dd.flg_available = g_flg_available)) def_data;
    
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
        
    END load_discharge_dest_def;

    FUNCTION load_discharge_reason_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('DISCHARGE_REASON.CODE_DISCHARGE_REASON.');
    
    BEGIN
    
        INSERT INTO discharge_reason
            (id_discharge_reason,
             code_discharge_reason,
             flg_admin_medic,
             flg_available,
             rank,
             adw_last_update,
             file_to_execute,
             flg_type,
             id_content,
             flg_hhc_disch)
            SELECT seq_discharge_reason.nextval,
                   l_code_translation || seq_discharge_reason.currval,
                   flg_admin_medic,
                   g_flg_available,
                   1,
                   SYSDATE,
                   file_to_execute,
                   flg_type,
                   id_content,
                   flg_hhc_disch
              FROM (SELECT ad_dr.id_discharge_reason,
                           ad_dr.id_content,
                           ad_dr.flg_admin_medic,
                           ad_dr.file_to_execute,
                           ad_dr.flg_type,
                           ad_dr.flg_hhc_disch
                      FROM ad_discharge_reason ad_dr
                     WHERE ad_dr.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM discharge_reason a_dr
                             WHERE a_dr.id_content = ad_dr.id_content
                               AND a_dr.flg_available = g_flg_available)) def_data;
    
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
        
    END load_discharge_reason_def;

    -- searcheable loader method
    FUNCTION set_disch_instr_rel_search
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
    
        g_func_name := upper('SET_DISCH_INSTR_REL_SEARCH');
    
        INSERT INTO disch_instr_relation
            (id_disch_instr_relation, id_disch_instructions, id_disch_instructions_group, id_institution, id_software)
            SELECT seq_disch_instr_relation.nextval,
                   def_data.id_disch_instructions,
                   def_data.id_disch_instructions_group,
                   i_institution,
                   i_software(pos_soft)
              FROM (SELECT temp_data.id_disch_instructions,
                           temp_data.id_disch_instructions_group,
                           row_number() over(PARTITION BY temp_data.id_disch_instructions, temp_data.id_disch_instructions_group ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank
                      FROM (SELECT nvl((SELECT a_di.id_disch_instructions
                                         FROM disch_instructions a_di
                                         JOIN ad_disch_instructions ad_di
                                           ON a_di.id_content = ad_di.id_content
                                        WHERE ad_di.id_disch_instructions = ad_dir.id_disch_instructions
                                          AND a_di.flg_available = g_flg_available),
                                       0) id_disch_instructions,
                                   nvl((SELECT a_dig.id_disch_instructions_group
                                         FROM disch_instructions_group a_dig
                                         JOIN ad_disch_instructions_group ad_dig
                                           ON a_dig.id_content = ad_dig.id_content
                                        WHERE ad_dig.id_disch_instructions_group = ad_dir.id_disch_instructions_group
                                          AND a_dig.flg_available = g_flg_available),
                                       0) id_disch_instructions_group,
                                   ad_dir.id_software,
                                   ad_dir.id_market,
                                   ad_dir.version
                              FROM ad_disch_instr_relation ad_dir
                             WHERE ad_dir.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_dir.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_dir.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_rank = 1
               AND def_data.id_disch_instructions_group > 0
               AND def_data.id_disch_instructions > 0
               AND NOT EXISTS (SELECT 0
                      FROM disch_instr_relation a_dir
                     WHERE a_dir.id_disch_instructions = def_data.id_disch_instructions
                       AND a_dir.id_disch_instructions_group = def_data.id_disch_instructions_group
                       AND a_dir.id_institution = i_institution
                       AND a_dir.id_software = i_software(pos_soft));
    
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
        
    END set_disch_instr_rel_search;

    FUNCTION del_disch_instr_rel_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete disch_instr_relation';
        g_func_name := upper('DEL_DISCH_INSTR_REL_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM disch_instr_relation a_dir
             WHERE a_dir.id_institution = i_institution
               AND a_dir.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM disch_instr_relation a_dir
             WHERE a_dir.id_institution = i_institution;
        
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
        
    END del_disch_instr_rel_search;

    FUNCTION set_disch_rea_te_inst_search
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
    
        g_func_name := upper('SET_DISCH_REA_TE_INST_SEARCH');
    
        INSERT INTO disch_rea_transp_ent_inst
            (id_disch_rea_transp_ent_inst, id_discharge_reason, id_transp_ent_inst, flg_available)
            SELECT seq_disch_rea_transp_ent_inst.nextval,
                   def_data.id_discharge_reason,
                   def_data.id_transp_ent_inst,
                   g_flg_available
              FROM (SELECT temp_data.id_discharge_reason,
                           temp_data.id_transp_ent_inst,
                           row_number() over(PARTITION BY temp_data.id_discharge_reason, temp_data.id_transp_ent_inst ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_dr.id_discharge_reason
                                                FROM discharge_reason a_dr
                                               WHERE a_dr.id_content = ad_dr.id_content
                                                 AND a_dr.flg_available = ad_dr.flg_available
                                                 AND a_dr.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_dr.id_discharge_reason
                                                FROM discharge_reason a_dr
                                               WHERE a_dr.id_content = ad_dr.id_content
                                                 AND a_dr.flg_available = ad_dr.flg_available
                                                 AND a_dr.flg_available = g_flg_available
                                                 AND a_dr.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_discharge_reason,
                                   nvl((SELECT a_tei.id_transp_ent_inst
                                         FROM transp_entity a_te
                                         JOIN transp_ent_inst a_tei
                                           ON a_tei.id_transp_entity = a_te.id_transp_entity
                                          AND a_tei.flg_available = g_flg_available
                                          AND a_tei.id_institution = i_institution
                                        WHERE a_te.id_content = ad_te.id_content
                                          AND a_te.flg_available = ad_te.flg_available
                                          AND a_te.flg_available = g_flg_available
                                          AND rownum = 1),
                                       0) id_transp_ent_inst,
                                   ad_drmv.id_market,
                                   ad_drmv.version
                            -- decode FKS to dest_vals
                              FROM ad_disch_rea_transp_ent_inst ad_drtei
                              JOIN ad_discharge_reason ad_dr
                                ON ad_dr.id_discharge_reason = ad_drtei.id_discharge_reason
                              JOIN ad_discharge_reason_mrk_vrs ad_drmv
                                ON ad_drmv.id_discharge_reason = ad_dr.id_discharge_reason
                              JOIN ad_transp_entity ad_te
                                ON ad_te.id_transp_entity = ad_drtei.id_transp_entity
                              JOIN ad_transp_entity_mrk_vrs ad_temv
                                ON ad_temv.id_transp_entity = ad_te.id_transp_entity
                               AND ad_temv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_temv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                             WHERE ad_drtei.flg_available = g_flg_available
                               AND ad_drmv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_drmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_rank = 1
               AND def_data.id_transp_ent_inst > 0
               AND def_data.id_discharge_reason > 0
               AND NOT EXISTS (SELECT 0
                      FROM disch_rea_transp_ent_inst a_drtei
                     WHERE a_drtei.id_transp_ent_inst = def_data.id_transp_ent_inst
                       AND a_drtei.id_discharge_reason = def_data.id_discharge_reason
                       AND a_drtei.flg_available = g_flg_available);
    
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
        
    END set_disch_rea_te_inst_search;

    FUNCTION del_disch_rea_te_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete disch_rea_transp_ent_inst';
        g_func_name := upper('DISCH_REA_TRANSP_ENT_INST');
    
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
            UPDATE disch_rea_transp_ent_inst a_drtei
               SET a_drtei.flg_available = g_no
             WHERE a_drtei.flg_available = g_flg_available
               AND a_drtei.id_transp_ent_inst IN
                   (SELECT a_tei.id_transp_ent_inst
                      FROM transp_ent_inst a_tei
                     WHERE a_tei.id_institution = i_institution);
        
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
        
    END del_disch_rea_te_inst_search;

    FUNCTION set_disch_reas_dest_search
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
    
        g_func_name := upper('SET_DISCH_REAS_DEST_SEARCH');
    
        INSERT INTO disch_reas_dest
            (id_disch_reas_dest,
             id_discharge_reason,
             id_discharge_dest,
             flg_active,
             flg_diag,
             report_name,
             id_epis_type,
             type_screen,
             id_department,
             id_reports,
             flg_mcdt,
             flg_care_stage,
             flg_default,
             id_instit_param,
             id_software_param,
             rank,
             flg_specify_dest,
             flg_rep_notes,
             flg_def_disch_status,
             id_def_disch_status,
             flg_needs_overall_resp,
             flg_auto_presc_cancel)
            SELECT seq_disch_reas_dest.nextval,
                   def_data.id_discharge_reason,
                   def_data.id_discharge_dest,
                   def_data.flg_active,
                   def_data.flg_diag,
                   def_data.report_name,
                   def_data.id_epis_type,
                   def_data.type_screen,
                   def_data.id_department,
                   def_data.id_reports,
                   def_data.flg_mcdt,
                   def_data.flg_care_stage,
                   def_data.flg_default,
                   i_institution,
                   i_software(pos_soft),
                   def_data.rank,
                   def_data.flg_specify_dest,
                   def_data.flg_rep_notes,
                   def_data.flg_def_disch_status,
                   def_data.id_def_disch_status,
                   def_data.flg_needs_overall_resp,
                   def_data.flg_auto_presc_cancel
              FROM (SELECT temp_data.id_discharge_reason,
                           temp_data.id_discharge_dest,
                           temp_data.flg_active,
                           temp_data.flg_diag,
                           temp_data.report_name,
                           temp_data.id_epis_type,
                           temp_data.type_screen,
                           temp_data.id_department,
                           temp_data.id_reports,
                           temp_data.flg_mcdt,
                           temp_data.flg_care_stage,
                           temp_data.flg_default,
                           temp_data.rank,
                           temp_data.flg_specify_dest,
                           temp_data.flg_rep_notes,
                           temp_data.flg_def_disch_status,
                           temp_data.id_def_disch_status,
                           temp_data.flg_needs_overall_resp,
                           temp_data.flg_auto_presc_cancel,
                           row_number() over(PARTITION BY temp_data.id_discharge_reason, temp_data.id_discharge_dest ORDER BY temp_data.id_software_param DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_dr.id_discharge_reason
                                                FROM discharge_reason a_dr
                                                JOIN ad_discharge_reason ad_dr
                                                  ON ad_dr.id_content = a_dr.id_content
                                                 AND a_dr.flg_available = ad_dr.flg_available
                                               WHERE a_dr.flg_available = g_flg_available
                                                 AND ad_dr.id_discharge_reason = ad_drd.id_discharge_reason),
                                              0),
                                          nvl((SELECT a_dr.id_discharge_reason
                                                FROM discharge_reason a_dr
                                                JOIN ad_discharge_reason ad_dr
                                                  ON ad_dr.id_content = a_dr.id_content
                                                 AND a_dr.flg_available = ad_dr.flg_available
                                               WHERE a_dr.flg_available = g_flg_available
                                                 AND ad_dr.id_discharge_reason = ad_drd.id_discharge_reason
                                                 AND a_dr.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_discharge_reason,
                                   decode(ad_drd.id_discharge_dest,
                                          NULL,
                                          NULL,
                                          (nvl((SELECT a_dd.id_discharge_dest
                                                 FROM discharge_dest a_dd
                                                 JOIN ad_discharge_dest ad_dd
                                                   ON ad_dd.id_content = a_dd.id_content
                                                  AND a_dd.flg_available = ad_dd.flg_available
                                                WHERE a_dd.flg_available = g_flg_available
                                                  AND ad_dd.id_discharge_dest = ad_drd.id_discharge_dest),
                                               0))) id_discharge_dest,
                                   ad_drd.flg_active,
                                   ad_drd.flg_diag,
                                   ad_drd.report_name,
                                   ad_drd.id_epis_type,
                                   ad_drd.type_screen,
                                   ad_drd.id_department,
                                   ad_drd.id_reports,
                                   ad_drd.flg_mcdt,
                                   ad_drd.flg_care_stage,
                                   ad_drd.flg_default,
                                   ad_drd.rank,
                                   ad_drd.flg_specify_dest,
                                   ad_drd.flg_rep_notes,
                                   ad_drd.flg_def_disch_status,
                                   ad_drd.id_def_disch_status,
                                   ad_drd.flg_needs_overall_resp,
                                   ad_drd.flg_auto_presc_cancel,
                                   ad_drd.id_software_param,
                                   ad_drd.id_market,
                                   ad_drd.version
                            -- decode FKS to dest_vals
                              FROM ad_disch_reas_dest ad_drd
                              JOIN ad_discharge_reason_mrk_vrs ad_drmv
                                ON ad_drmv.id_discharge_reason = ad_drd.id_discharge_reason
                               AND ad_drmv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_drmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                              JOIN ad_discharge_dest_mrk_vrs ad_ddmv
                                ON ad_ddmv.id_discharge_dest = ad_drd.id_discharge_dest
                               AND ad_ddmv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_ddmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                             WHERE ad_drd.flg_active = g_flg_active
                               AND ad_drd.id_clinical_service IS NULL
                               AND ad_drd.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_drd.id_software_param IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_drd.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)) temp_data
                     WHERE (temp_data.id_discharge_dest > 0 OR temp_data.id_discharge_dest IS NULL)
                       AND temp_data.id_discharge_reason > 0) def_data
             WHERE def_data.records_rank = 1
               AND NOT EXISTS (SELECT 0
                      FROM disch_reas_dest a_drd
                     WHERE a_drd.id_discharge_reason = def_data.id_discharge_reason
                       AND ((a_drd.id_discharge_dest = def_data.id_discharge_dest) OR
                           (a_drd.id_discharge_dest IS NULL AND def_data.id_discharge_dest IS NULL))
                       AND a_drd.id_instit_param = i_institution
                       AND a_drd.id_software_param = i_software(pos_soft)
                       AND a_drd.flg_active = g_flg_active);
    
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
        
    END set_disch_reas_dest_search;

    FUNCTION del_disch_reas_dest_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete disch_reas_dest';
        g_func_name := upper('DEL_DISCH_REAS_DEST_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            UPDATE disch_reas_dest a_drd
               SET a_drd.flg_active = g_flg_inactive
             WHERE a_drd.id_instit_param = i_institution
               AND a_drd.id_software_param IN
                   (SELECT /*+ dynamic_sampling(2)*/
                     column_value
                      FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            UPDATE disch_reas_dest a_drd
               SET a_drd.flg_active = g_flg_inactive
             WHERE a_drd.id_instit_param = i_institution;
        
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
        
    END del_disch_reas_dest_search;

    FUNCTION set_profile_disch_rea_search
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
    
        g_func_name := upper('set_profile_disch_rea_search');
    
        INSERT INTO profile_disch_reason
            (id_profile_disch_reason,
             id_discharge_reason,
             id_profile_template,
             flg_available,
             id_discharge_flash_files,
             flg_access,
             rank,
             flg_default,
             id_institution)
            SELECT seq_profile_disch_reason.nextval,
                   def_data.id_discharge_reason,
                   def_data.id_profile_template,
                   def_data.flg_available,
                   def_data.id_discharge_flash_files,
                   def_data.flg_access,
                   def_data.rank,
                   def_data.flg_default,
                   i_institution
              FROM (SELECT temp_data.id_discharge_reason,
                           temp_data.id_profile_template,
                           temp_data.flg_available,
                           temp_data.id_discharge_flash_files,
                           temp_data.flg_access,
                           temp_data.rank,
                           temp_data.flg_default,
                           row_number() over(PARTITION BY temp_data.id_discharge_reason, temp_data.id_profile_template ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_dr.id_discharge_reason
                                                FROM discharge_reason a_dr
                                                JOIN ad_discharge_reason ad_dr
                                                  ON ad_dr.id_content = a_dr.id_content
                                                 AND a_dr.flg_available = ad_dr.flg_available
                                               WHERE a_dr.flg_available = g_flg_available
                                                 AND ad_dr.id_discharge_reason = ad_pdr.id_discharge_reason),
                                              0),
                                          nvl((SELECT a_dr.id_discharge_reason
                                                FROM discharge_reason a_dr
                                                JOIN ad_discharge_reason ad_dr
                                                  ON ad_dr.id_content = a_dr.id_content
                                                 AND a_dr.flg_available = ad_dr.flg_available
                                               WHERE a_dr.flg_available = g_flg_available
                                                 AND ad_dr.id_discharge_reason = ad_pdr.id_discharge_reason
                                                 AND a_dr.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_discharge_reason,
                                   ad_pdr.id_profile_template,
                                   ad_pdr.flg_available,
                                   ad_pdr.id_discharge_flash_files,
                                   ad_pdr.flg_access,
                                   ad_pdr.rank,
                                   ad_pdr.flg_default,
                                   ad_drmv.id_market,
                                   ad_drmv.version
                            -- decode FKS to dest_vals
                              FROM ad_profile_disch_reason ad_pdr
                              JOIN ad_discharge_reason_mrk_vrs ad_drmv
                                ON ad_pdr.id_discharge_reason = ad_drmv.id_discharge_reason
                             WHERE ad_pdr.flg_available = g_flg_available
                               AND ad_drmv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_drmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_discharge_reason > 0) def_data
             WHERE def_data.records_rank = 1
               AND NOT EXISTS (SELECT 0
                      FROM profile_disch_reason a_pdr
                     WHERE a_pdr.id_discharge_reason = def_data.id_discharge_reason
                       AND a_pdr.id_profile_template = def_data.id_profile_template
                       AND a_pdr.id_institution = i_institution
                       AND a_pdr.flg_available = g_flg_available);
    
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
        
    END set_profile_disch_rea_search;

    FUNCTION del_profile_disch_rea_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete profile_disch_reason';
        g_func_name := upper('DEL_PROFILE_DISCH_REA_SEARCH');
    
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
            DELETE FROM profile_disch_reason a_pdr
             WHERE a_pdr.id_institution = i_institution;
        
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
        
    END del_profile_disch_rea_search;

    -- frequent loader method
    FUNCTION set_discharge_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_id_content        IN table_varchar DEFAULT table_varchar(),
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_DISCHARGE_FREQ');
    
        INSERT INTO disch_reas_dest
            (id_disch_reas_dest,
             id_discharge_reason,
             id_discharge_dest,
             id_dep_clin_serv,
             flg_active,
             flg_diag,
             id_instit_param,
             id_software_param,
             report_name,
             id_epis_type,
             type_screen,
             id_reports,
             flg_mcdt,
             flg_care_stage,
             flg_default,
             rank,
             flg_specify_dest,
             flg_rep_notes,
             flg_def_disch_status,
             id_def_disch_status,
             flg_needs_overall_resp)
            SELECT seq_disch_reas_dest.nextval,
                   def_data.id_discharge_reason,
                   def_data.id_discharge_dest,
                   i_dep_clin_serv_out,
                   g_active,
                   def_data.flg_diag,
                   i_institution,
                   i_software(pos_soft),
                   def_data.report_name,
                   def_data.id_epis_type,
                   def_data.type_screen,
                   def_data.id_reports,
                   def_data.flg_mcdt,
                   def_data.flg_care_stage,
                   def_data.flg_default,
                   def_data.rank,
                   def_data.flg_specify_dest,
                   def_data.flg_rep_notes,
                   def_data.flg_def_disch_status,
                   def_data.id_def_disch_status,
                   def_data.flg_needs_overall_resp
              FROM (SELECT temp_data.id_discharge_reason,
                           temp_data.id_discharge_dest,
                           temp_data.flg_diag,
                           temp_data.report_name,
                           temp_data.id_epis_type,
                           temp_data.type_screen,
                           temp_data.id_reports,
                           temp_data.flg_mcdt,
                           temp_data.flg_care_stage,
                           temp_data.flg_default,
                           temp_data.rank,
                           temp_data.flg_specify_dest,
                           temp_data.flg_rep_notes,
                           temp_data.flg_def_disch_status,
                           temp_data.id_def_disch_status,
                           temp_data.flg_needs_overall_resp,
                           row_number() over(PARTITION BY temp_data.id_discharge_reason, temp_data.id_discharge_dest ORDER BY temp_data.id_software_param DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_dr.id_discharge_reason
                                                FROM discharge_reason a_dr
                                                JOIN ad_discharge_reason ad_dr
                                                  ON ad_dr.id_content = a_dr.id_content
                                                 AND a_dr.flg_available = ad_dr.flg_available
                                               WHERE a_dr.flg_available = g_flg_available
                                                 AND ad_dr.id_discharge_reason = ad_drs.id_discharge_reason),
                                              0),
                                          nvl((SELECT a_dr.id_discharge_reason
                                                FROM discharge_reason a_dr
                                                JOIN ad_discharge_reason ad_dr
                                                  ON ad_dr.id_content = a_dr.id_content
                                                 AND a_dr.flg_available = ad_dr.flg_available
                                               WHERE a_dr.flg_available = g_flg_available
                                                 AND ad_dr.id_discharge_reason = ad_drs.id_discharge_reason
                                                 AND a_dr.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_discharge_reason,
                                   nvl((SELECT a_dd.id_discharge_dest
                                         FROM discharge_dest a_dd
                                         JOIN ad_discharge_dest ad_dd
                                           ON ad_dd.id_content = a_dd.id_content
                                          AND ad_dd.flg_available = a_dd.flg_available
                                        WHERE ad_dd.id_discharge_dest = ad_drs.id_discharge_dest
                                          AND a_dd.flg_available = g_flg_available
                                          AND rownum = 1),
                                       0) id_discharge_dest,
                                   ad_drs.flg_diag,
                                   ad_drs.report_name,
                                   ad_drs.id_epis_type,
                                   ad_drs.type_screen,
                                   ad_drs.id_reports,
                                   ad_drs.flg_mcdt,
                                   ad_drs.flg_care_stage,
                                   ad_drs.flg_default,
                                   ad_drs.rank,
                                   ad_drs.flg_specify_dest,
                                   ad_drs.flg_rep_notes,
                                   ad_drs.flg_def_disch_status,
                                   ad_drs.id_def_disch_status,
                                   ad_drs.flg_needs_overall_resp,
                                   ad_drs.id_software_param,
                                   ad_drs.id_market,
                                   ad_drs.version
                              FROM ad_disch_reas_dest ad_drs
                             WHERE ad_drs.flg_active = g_active
                               AND ad_drs.id_software_param IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_drs.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_drs.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_drs.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                     WHERE temp_data.id_discharge_reason > 0
                       AND temp_data.id_discharge_dest > 0) def_data
             WHERE def_data.records_rank = 1
               AND NOT EXISTS (SELECT 0
                      FROM disch_reas_dest a_drd
                     WHERE a_drd.id_discharge_reason = def_data.id_discharge_reason
                       AND a_drd.id_discharge_dest = def_data.id_discharge_dest
                       AND a_drd.id_dep_clin_serv = i_dep_clin_serv_out
                       AND a_drd.id_software_param = i_software(pos_soft)
                       AND a_drd.id_instit_param = i_institution
                       AND a_drd.flg_active = g_active);
    
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
        
    END set_discharge_freq;
    -- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

END pk_discharge_prm;
/
