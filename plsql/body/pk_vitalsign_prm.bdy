/*-- Last Change Revision: $Rev: 1960245 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-08-05 11:42:17 +0100 (qua, 05 ago 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_vitalsign_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_VITALSIGN_PRM';
    pos_soft        NUMBER := 1;
    -- g_table_name    t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_vs_soft_inst_search
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
    
        l_cnt       table_varchar := i_id_content;
        l_flg_view  VARCHAR2(3);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_VITALSIGN_SEARCH');
    
        IF l_cnt.count != 0
        THEN
            l_flg_view  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO vs_soft_inst
            (id_vs_soft_inst,
             id_vital_sign,
             id_unit_measure,
             flg_view,
             color_grafh,
             color_text,
             box_type,
             rank,
             id_institution,
             id_software)
            SELECT seq_vs_soft_inst.nextval,
                   def_data.id_vital_sign,
                   def_data.id_unit_measure,
                   def_data.flg_view,
                   def_data.color_grafh,
                   def_data.color_text,
                   def_data.box_type,
                   def_data.rank,
                   i_institution,
                   i_software(pos_soft)
              FROM (SELECT temp_data.id_vital_sign,
                           temp_data.id_unit_measure,
                           temp_data.flg_view,
                           temp_data.color_grafh,
                           temp_data.color_text,
                           temp_data.box_type,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_vital_sign, temp_data.flg_view ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_vs.id_vital_sign
                                                FROM vital_sign a_vs
                                               WHERE a_vs.id_vital_sign = ad_vsi.id_vital_sign
                                                 AND a_vs.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_vs.id_vital_sign
                                                FROM vital_sign a_vs
                                               WHERE a_vs.id_vital_sign = ad_vsi.id_vital_sign
                                                 AND a_vs.flg_available = g_flg_available
                                                 AND a_vs.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                              0)) id_vital_sign,
                                   ad_vsi.id_unit_measure,
                                   ad_vsi.flg_view,
                                   ad_vsi.color_grafh,
                                   ad_vsi.color_text,
                                   ad_vsi.box_type,
                                   ad_vsi.rank,
                                   ad_vsi.id_software,
                                   ad_vsi.id_market,
                                   ad_vsi.version
                            -- decode FKS to dest_vals
                              FROM ad_vs_soft_inst ad_vsi
                             WHERE ad_vsi.flg_view = nvl(l_flg_view, ad_vsi.flg_view)
                               AND ad_vsi.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_vsi.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_vsi.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_vital_sign != 0
               AND NOT EXISTS (SELECT 0
                      FROM vs_soft_inst a_vsi
                     WHERE a_vsi.id_software = i_software(pos_soft)
                       AND a_vsi.id_institution = i_institution
                       AND a_vsi.id_vital_sign = def_data.id_vital_sign
                       AND a_vsi.flg_view = def_data.flg_view);
    
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
        
    END set_vs_soft_inst_search;

    FUNCTION del_vs_soft_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete vs_soft_inst';
        g_func_name := upper('del_vs_soft_inst_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM vs_soft_inst a_vsi
             WHERE a_vsi.id_institution = i_institution
               AND a_vsi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM vs_soft_inst a_vsi
             WHERE a_vsi.id_institution = i_institution;
        
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
        
    END del_vs_soft_inst_search;

    FUNCTION set_vital_sign_um_search
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
    
        l_cnt       table_varchar := i_id_content;
        l_flg_view  VARCHAR2(3);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_VITAL_SIGN_UM_SEARCH');
    
        IF l_cnt.count != 0
        THEN
            l_flg_view  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO vital_sign_unit_measure
            (id_vital_sign_unit_measure,
             id_vital_sign,
             id_unit_measure,
             val_min,
             val_max,
             format_num,
             decimals,
             id_institution,
             id_software,
             age_min,
             age_max)
            SELECT seq_vital_sign_unit_measure.nextval,
                   def_data.id_vital_sign,
                   def_data.i_unit_measure,
                   def_data.val_min,
                   def_data.val_max,
                   def_data.format_num,
                   def_data.decimals,
                   i_institution,
                   i_software(pos_soft),
                   def_data.age_min,
                   def_data.age_max
              FROM (SELECT temp_data.id_vital_sign,
                           temp_data.i_unit_measure,
                           temp_data.val_min,
                           temp_data.val_max,
                           temp_data.format_num,
                           temp_data.decimals,
                           temp_data.age_min,
                           temp_data.age_max,
                           row_number() over(PARTITION BY temp_data.id_vital_sign, temp_data.i_unit_measure, temp_data.age_min, temp_data.age_max ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_vs.id_vital_sign
                                                FROM vital_sign a_vs
                                               WHERE a_vs.id_vital_sign = ad_vsum.id_vital_sign
                                                 AND a_vs.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_vs.id_vital_sign
                                                FROM vital_sign a_vs
                                               WHERE a_vs.id_vital_sign = ad_vsum.id_vital_sign
                                                 AND a_vs.flg_available = g_flg_available
                                                 AND a_vs.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                              0)) id_vital_sign,
                                   decode(ad_vsum.id_unit_measure,
                                          NULL,
                                          NULL,
                                          (nvl((SELECT a_um.id_unit_measure
                                                 FROM unit_measure a_um
                                                WHERE a_um.id_unit_measure = ad_vsum.id_unit_measure
                                                  AND a_um.flg_available = g_flg_available),
                                               0))) i_unit_measure,
                                   ad_vsum.val_min,
                                   ad_vsum.val_max,
                                   ad_vsum.format_num,
                                   ad_vsum.decimals,
                                   ad_vsum.age_min,
                                   ad_vsum.age_max,
                                   ad_vsum.id_market,
                                   ad_vsum.id_software,
                                   ad_vsum.version
                            -- decode FKS to dest_vals
                              FROM ad_vital_sign_unit_measure ad_vsum
                             INNER JOIN vital_sign vs
                                ON (vs.id_vital_sign = ad_vsum.id_vital_sign)
                             WHERE vs.flg_available = g_flg_available
                               AND ad_vsum.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_vsum.id_market IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_vsum.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_vital_sign != 0
               AND (def_data.i_unit_measure > 0 OR def_data.i_unit_measure IS NULL)
               AND NOT EXISTS
             (SELECT 0
                      FROM vital_sign_unit_measure a_vsum
                     WHERE a_vsum.id_vital_sign = def_data.id_vital_sign
                       AND a_vsum.id_institution = i_institution
                       AND a_vsum.id_software = i_software(pos_soft)
                       AND (a_vsum.age_min = def_data.age_min OR (a_vsum.age_min IS NULL AND def_data.age_min IS NULL))
                       AND (a_vsum.age_max = def_data.age_max OR (a_vsum.age_max IS NULL AND def_data.age_max IS NULL))
                       AND (a_vsum.id_unit_measure = def_data.i_unit_measure OR
                           a_vsum.id_unit_measure IS NULL AND def_data.i_unit_measure IS NULL));
    
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
        
    END set_vital_sign_um_search;

    FUNCTION del_vital_sign_um_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete vital_sign_unit_measure';
        g_func_name := upper('DEL_VITAL_SIGN_UM_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM vital_sign_unit_measure a_vsum
             WHERE a_vsum.id_institution = i_institution
               AND a_vsum.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM vital_sign_unit_measure a_vsum
             WHERE a_vsum.id_institution = i_institution;
        
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
        
    END del_vital_sign_um_search;

    FUNCTION set_vital_sign_sa_search
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
    
        l_cnt       table_varchar := i_id_content;
        l_flg_view  VARCHAR2(3);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_VITAL_SIGN_SA_SEARCH');
    
        IF l_cnt.count != 0
        THEN
            l_flg_view  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO vital_sign_scales_access
            (id_vital_sign_scales_access,
             id_vital_sign_scales,
             id_institution,
             id_software,
             flg_available,
             adw_last_update)
            SELECT seq_vital_sign_scales_access.nextval,
                   def_data.id_vital_sign_scales,
                   i_institution,
                   i_software(pos_soft),
                   g_flg_available,
                   SYSDATE
              FROM (SELECT temp_data.id_vital_sign_scales,
                           row_number() over(PARTITION BY temp_data.id_vital_sign_scales ORDER BY temp_data.id_software) records_count
                      FROM (SELECT ad_vssa.rowid l_row,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_vss.id_vital_sign_scales
                                                FROM vital_sign a_vs
                                                JOIN vital_sign_scales a_vss
                                                  ON a_vss.id_vital_sign = a_vs.id_vital_sign
                                                 AND a_vss.flg_available = g_flg_available
                                               WHERE ad_vssa.id_vital_sign_scales = a_vss.id_vital_sign_scales
                                                 AND a_vs.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_vss.id_vital_sign_scales
                                                FROM vital_sign a_vs
                                                JOIN vital_sign_scales a_vss
                                                  ON a_vss.id_vital_sign = a_vs.id_vital_sign
                                                 AND a_vss.flg_available = g_flg_available
                                               WHERE ad_vssa.id_vital_sign_scales = a_vss.id_vital_sign_scales
                                                 AND a_vs.flg_available = g_flg_available
                                                 AND a_vs.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                              0)) id_vital_sign_scales,
                                   ad_vssa.id_software
                              FROM ad_vital_sign_scales_access ad_vssa
                             WHERE ad_vssa.id_software IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_vssa.flg_available = g_flg_available) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_vital_sign_scales != 0
               AND NOT EXISTS (SELECT 0
                      FROM vital_sign_scales_access a_vssa
                     WHERE a_vssa.id_vital_sign_scales = def_data.id_vital_sign_scales
                       AND a_vssa.id_institution = i_institution
                       AND a_vssa.id_software = i_software(pos_soft)
                       AND a_vssa.flg_available = g_flg_available);
    
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
        
    END set_vital_sign_sa_search;
    -- frequent loader method

    FUNCTION del_vital_sign_sa_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete vital_sign_scales_access';
        g_func_name := upper('DEL_VITAL_SIGN_SA_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM vital_sign_scales_access a_vssa
             WHERE a_vssa.id_institution = i_institution
               AND a_vssa.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM vital_sign_scales_access a_vssa
             WHERE a_vssa.id_institution = i_institution;
        
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
        
    END del_vital_sign_sa_search;

    PROCEDURE set_vs_content
    (
        i_id_vital_sign          vital_sign.id_vital_sign%TYPE,
        i_intern_name_vital_sign vital_sign.intern_name_vital_sign%TYPE,
        i_flg_fill_type          vital_sign.flg_fill_type%TYPE,
        i_id_content             vital_sign.id_content%TYPE
    ) IS
    
        l_count NUMBER(12);
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM vital_sign a_vs
         WHERE a_vs.id_vital_sign = i_id_vital_sign;
    
        IF l_count = 0
        THEN
            INSERT INTO vital_sign
                (id_vital_sign,
                 intern_name_vital_sign,
                 code_vital_sign,
                 flg_fill_type,
                 flg_mandatory,
                 flg_available,
                 rank,
                 flg_show,
                 code_vs_short_desc,
                 flg_vs,
                 flg_wizard,
                 id_content)
            VALUES
                (i_id_vital_sign,
                 i_intern_name_vital_sign,
                 'VITAL_SIGN.CODE_VITAL_SIGN.' || i_id_vital_sign,
                 i_flg_fill_type,
                 'N',
                 'Y',
                 0,
                 'Y',
                 'VITAL_SIGN.CODE_VS_SHORT_DESC.' || i_id_vital_sign,
                 'VS',
                 'Y',
                 i_id_content);
        
        ELSE
            UPDATE vital_sign a_vs
               SET a_vs.id_content             = i_id_content,
                   a_vs.flg_fill_type          = i_flg_fill_type,
                   a_vs.intern_name_vital_sign = i_intern_name_vital_sign
             WHERE a_vs.id_vital_sign = i_id_vital_sign
               AND (nvl(a_vs.id_content, 'A') <> nvl(i_id_content, 'A') OR a_vs.flg_fill_type <> i_flg_fill_type OR
                   a_vs.intern_name_vital_sign <> i_intern_name_vital_sign);
        
        END IF;
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            raise_application_error(-20001, 'vital_sign: Configuration already exists');
        
    END set_vs_content;
    --
    PROCEDURE set_vs_content_vsi
    (
        i_id_vs_soft_inst alert_default.vs_soft_inst.id_vs_soft_inst%TYPE,
        i_id_vital_sign   alert_default.vs_soft_inst.id_vital_sign%TYPE,
        i_id_market       alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software     alert_default.vs_soft_inst.id_software%TYPE,
        i_version         alert_default.vs_soft_inst.version%TYPE,
        i_flg_view        alert_default.vs_soft_inst.flg_view%TYPE,
        i_id_unit_measure alert_default.vs_soft_inst.id_unit_measure%TYPE,
        i_color_grafh     alert_default.vs_soft_inst.color_grafh%TYPE,
        i_color_text      alert_default.vs_soft_inst.color_text%TYPE,
        i_box_type        alert_default.vs_soft_inst.box_type%TYPE,
        i_rank            alert_default.vs_soft_inst.rank%TYPE,
        i_flg_add_remove  VARCHAR2
    ) IS
    
    BEGIN
    
        alert_default.pk_vital_sign_default.set_vs_content_vsi(i_id_vs_soft_inst => i_id_vs_soft_inst,
                                                               i_id_vital_sign   => i_id_vital_sign,
                                                               i_id_unit_measure => i_id_unit_measure,
                                                               i_id_software     => i_id_software,
                                                               i_flg_view        => i_flg_view,
                                                               i_color_grafh     => i_color_grafh,
                                                               i_color_text      => i_color_text,
                                                               i_box_type        => i_box_type,
                                                               i_id_market       => i_id_market,
                                                               i_version         => i_version,
                                                               i_rank            => i_rank,
                                                               i_flg_add_remove  => i_flg_add_remove);
    END set_vs_content_vsi;
    --
    PROCEDURE set_vs_content_vsum
    (
        i_id_vital_sign_unit_measure alert_default.vital_sign_unit_measure.id_vital_sign_unit_measure%TYPE,
        i_id_vital_sign              alert_default.vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_market                  alert_default.vital_sign_unit_measure.id_market%TYPE,
        i_id_software                alert_default.vital_sign_unit_measure.id_software%TYPE,
        i_version                    alert_default.vital_sign_unit_measure.version%TYPE,
        i_id_unit_measure            alert_default.vital_sign_unit_measure.id_unit_measure%TYPE,
        i_val_min                    alert_default.vital_sign_unit_measure.val_min%TYPE,
        i_val_max                    alert_default.vital_sign_unit_measure.val_max%TYPE,
        i_format_num                 alert_default.vital_sign_unit_measure.format_num%TYPE,
        i_decimals                   alert_default.vital_sign_unit_measure.decimals%TYPE,
        i_age_min                    alert_default.vital_sign_unit_measure.age_min%TYPE,
        i_age_max                    alert_default.vital_sign_unit_measure.age_max%TYPE,
        i_flg_add_remove             VARCHAR2
    ) IS
    BEGIN
        alert_default.pk_vital_sign_default.set_vs_content_vsum(i_id_vital_sign_unit_measure => i_id_vital_sign_unit_measure,
                                                                i_id_vital_sign              => i_id_vital_sign,
                                                                i_id_unit_measure            => i_id_unit_measure,
                                                                i_id_software                => i_id_software,
                                                                i_val_min                    => i_val_min,
                                                                i_val_max                    => i_val_max,
                                                                i_format_num                 => i_format_num,
                                                                i_decimals                   => i_decimals,
                                                                i_id_market                  => i_id_market,
                                                                i_version                    => i_version,
                                                                i_age_min                    => i_age_min,
                                                                i_age_max                    => i_age_max,
                                                                i_flg_add_remove             => i_flg_add_remove);
    END set_vs_content_vsum;
    --
    PROCEDURE set_vs_content_desc
    (
        i_id_vital_sign_desc vital_sign_desc.id_vital_sign_desc%TYPE,
        i_id_vital_sign      vital_sign_desc.id_vital_sign%TYPE,
        i_id_market          vital_sign_desc.id_market%TYPE,
        i_id_content         vital_sign_desc.id_content%TYPE,
        i_rank               vital_sign_desc.rank%TYPE,
        i_value              vital_sign_desc.value%TYPE,
        i_icon               vital_sign_desc.icon%TYPE,
        i_flg_add_remove     VARCHAR2
    ) IS
        l_count NUMBER(12);
    BEGIN
        IF i_flg_add_remove = 'R'
        THEN
            UPDATE vital_sign_desc vsd
               SET vsd.flg_available = pk_alert_constant.g_no
             WHERE vsd.id_vital_sign_desc = i_id_vital_sign_desc;
        ELSE
            SELECT COUNT(1)
              INTO l_count
              FROM vital_sign_desc vsd
             WHERE vsd.id_vital_sign_desc = i_id_vital_sign_desc;
        
            IF l_count = 0
            THEN
                INSERT INTO vital_sign_desc
                    (id_vital_sign_desc,
                     id_vital_sign,
                     id_market,
                     id_content,
                     rank,
                     VALUE,
                     icon,
                     flg_available,
                     code_vital_sign_desc,
                     code_abbreviation)
                VALUES
                    (i_id_vital_sign_desc,
                     i_id_vital_sign,
                     i_id_market,
                     i_id_content,
                     i_rank,
                     i_value,
                     i_icon,
                     pk_alert_constant.g_yes,
                     'VITAL_SIGN_DESC.CODE_VITAL_SIGN_DESC.' || i_id_vital_sign_desc,
                     'VITAL_SIGN_DESC.CODE_ABBREVIATION.' || i_id_vital_sign_desc);
            ELSE
                UPDATE vital_sign_desc vsd
                   SET vsd.id_vital_sign = i_id_vital_sign,
                       vsd.id_market     = i_id_market,
                       vsd.id_content    = i_id_content,
                       vsd.rank          = i_rank,
                       vsd.value         = i_value,
                       vsd.icon          = i_icon
                 WHERE vsd.id_vital_sign_desc = i_id_vital_sign_desc;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            raise_application_error(-20001, 'vital_sign_desc: Configuration already exists');
        
    END set_vs_content_desc;
    --
    PROCEDURE set_vs_content_all
    (
        i_id_vital_sign          vital_sign.id_vital_sign%TYPE,
        i_intern_name_vital_sign vital_sign.intern_name_vital_sign%TYPE,
        i_flg_fill_type          vital_sign.flg_fill_type%TYPE,
        i_id_content_vs          vital_sign.id_content%TYPE,
        -- vsi
        i_id_vs_soft_inst table_number,
        i_id_market       alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software     table_number,
        i_version         alert_default.vs_soft_inst.version%TYPE,
        i_flg_view        table_varchar,
        i_id_unit_measure alert_default.vs_soft_inst.id_unit_measure%TYPE,
        i_color_grafh     alert_default.vs_soft_inst.color_grafh%TYPE,
        i_color_text      alert_default.vs_soft_inst.color_text%TYPE,
        i_box_type        alert_default.vs_soft_inst.box_type%TYPE,
        i_rank_vsi        alert_default.vs_soft_inst.rank%TYPE,
        -- vsum
        i_id_vital_sign_unit_measure table_number,
        i_val_min                    alert_default.vital_sign_unit_measure.val_min%TYPE,
        i_val_max                    alert_default.vital_sign_unit_measure.val_max%TYPE,
        i_format_num                 alert_default.vital_sign_unit_measure.format_num%TYPE,
        i_decimals                   alert_default.vital_sign_unit_measure.decimals%TYPE,
        i_age_min                    alert_default.vital_sign_unit_measure.age_min%TYPE,
        i_age_max                    alert_default.vital_sign_unit_measure.age_max%TYPE,
        --vs desc
        i_id_vital_sign_desc table_number,
        i_id_content_vsd     table_varchar,
        i_rank_vsd           table_number,
        i_value              table_varchar,
        i_icon               table_varchar,
        -- VSI Script type ('I' - insert, 'U' - update, 'D' - Delete)
        i_flg_script_type IN VARCHAR2 DEFAULT 'I'
    ) IS
        l_exception_ids_vsi  EXCEPTION;
        l_exception_ids_vsum EXCEPTION;
        l_exception_ids_vsd  EXCEPTION;
    BEGIN
    
        --i_id_vs_soft_inst.count must be i_id_software.count * i_flg_view.count
        IF i_flg_script_type = g_flg_script_type_ins
           AND i_id_vs_soft_inst.exists(1)
        THEN
            IF i_id_vs_soft_inst.count <> i_id_software.count * i_flg_view.count
            THEN
                RAISE l_exception_ids_vsi;
            END IF;
        END IF;
    
        --i_id_vs_soft_inst.count must be i_id_software.count
        IF i_id_vital_sign_unit_measure.exists(1)
        THEN
            IF i_id_vital_sign_unit_measure.count <> i_id_software.count
            THEN
                RAISE l_exception_ids_vsum;
            END IF;
        END IF;
    
        --vital sign desc arrays must be all the same size
        IF i_id_vital_sign_desc.exists(1)
        THEN
            IF i_id_vital_sign_desc.count <> i_id_content_vsd.count
               OR i_id_vital_sign_desc.count <> i_rank_vsd.count
               OR i_id_vital_sign_desc.count <> i_value.count
               OR i_id_vital_sign_desc.count <> i_icon.count
            THEN
                RAISE l_exception_ids_vsd;
            END IF;
        END IF;
    
        -- set VS
        IF i_flg_script_type IN (g_flg_script_type_ins, g_flg_script_type_upd)
        THEN
            set_vs_content(i_id_vital_sign          => i_id_vital_sign,
                           i_intern_name_vital_sign => i_intern_name_vital_sign,
                           i_flg_fill_type          => i_flg_fill_type,
                           i_id_content             => i_id_content_vs);
        END IF;
    
        -- set VSI
        IF i_flg_script_type = g_flg_script_type_ins
        THEN
            FOR i IN 1 .. i_id_software.count
            LOOP
                FOR j IN 1 .. i_flg_view.count
                LOOP
                    alert_default.pk_vital_sign_default.set_vs_content_vsi(i_id_vs_soft_inst => i_id_vs_soft_inst(i * j),
                                                                           i_id_vital_sign   => i_id_vital_sign,
                                                                           i_id_unit_measure => i_id_unit_measure,
                                                                           i_id_software     => i_id_software(i),
                                                                           i_flg_view        => i_flg_view(j),
                                                                           i_color_grafh     => i_color_grafh,
                                                                           i_color_text      => i_color_text,
                                                                           i_box_type        => i_box_type,
                                                                           i_id_market       => i_id_market,
                                                                           i_version         => i_version,
                                                                           i_rank            => i_rank_vsi,
                                                                           i_flg_add_remove  => 'A');
                END LOOP;
            END LOOP;
        ELSIF i_flg_script_type = g_flg_script_type_upd
        THEN
            FOR i IN 1 .. i_id_vs_soft_inst.count
            LOOP
                alert_default.pk_vital_sign_default.set_vs_content_vsi(i_id_vs_soft_inst => i_id_vs_soft_inst(i),
                                                                       i_id_vital_sign   => NULL,
                                                                       i_id_unit_measure => i_id_unit_measure,
                                                                       i_id_software     => NULL,
                                                                       i_flg_view        => NULL,
                                                                       i_color_grafh     => i_color_grafh,
                                                                       i_color_text      => i_color_text,
                                                                       i_box_type        => i_box_type,
                                                                       i_id_market       => NULL,
                                                                       i_version         => NULL,
                                                                       i_rank            => i_rank_vsi,
                                                                       i_flg_add_remove  => 'A');
            END LOOP;
        ELSIF i_flg_script_type = g_flg_script_type_del
        THEN
            FOR i IN 1 .. i_id_vs_soft_inst.count
            LOOP
                alert_default.pk_vital_sign_default.set_vs_content_vsi(i_id_vs_soft_inst => i_id_vs_soft_inst(i),
                                                                       i_id_vital_sign   => NULL,
                                                                       i_id_unit_measure => NULL,
                                                                       i_id_software     => NULL,
                                                                       i_flg_view        => NULL,
                                                                       i_color_grafh     => NULL,
                                                                       i_color_text      => NULL,
                                                                       i_box_type        => NULL,
                                                                       i_id_market       => NULL,
                                                                       i_version         => NULL,
                                                                       i_rank            => NULL,
                                                                       i_flg_add_remove  => 'R');
            END LOOP;
        END IF;
    
        -- set VSUM
        IF i_flg_script_type IN (g_flg_script_type_ins, g_flg_script_type_upd)
        THEN
            FOR i IN 1 .. i_id_vital_sign_unit_measure.count
            LOOP
                alert_default.pk_vital_sign_default.set_vs_content_vsum(i_id_vital_sign_unit_measure => i_id_vital_sign_unit_measure(i),
                                                                        i_id_vital_sign              => i_id_vital_sign,
                                                                        i_id_unit_measure            => i_id_unit_measure,
                                                                        i_id_software                => i_id_software(i),
                                                                        i_val_min                    => i_val_min,
                                                                        i_val_max                    => i_val_max,
                                                                        i_format_num                 => i_format_num,
                                                                        i_decimals                   => i_decimals,
                                                                        i_id_market                  => i_id_market,
                                                                        i_version                    => i_version,
                                                                        i_age_min                    => i_age_min,
                                                                        i_age_max                    => i_age_max,
                                                                        i_flg_add_remove             => 'A');
            END LOOP;
        END IF;
    
        -- set VSDESC
        IF i_flg_script_type IN (g_flg_script_type_ins, g_flg_script_type_upd)
        THEN
            FOR i IN 1 .. i_id_vital_sign_desc.count
            LOOP
                set_vs_content_desc(i_id_vital_sign_desc => i_id_vital_sign_desc(i),
                                    i_id_vital_sign      => i_id_vital_sign,
                                    i_id_market          => i_id_market,
                                    i_id_content         => i_id_content_vsd(i),
                                    i_rank               => i_rank_vsd(i),
                                    i_value              => i_value(i),
                                    i_icon               => i_icon(i),
                                    i_flg_add_remove     => 'A');
            END LOOP;
        
            -- update other descriptions flg_available to 'N'
            FOR vsd IN (SELECT v.id_vital_sign_desc
                          FROM vital_sign_desc v
                         WHERE v.id_vital_sign = i_id_vital_sign
                           AND v.flg_available = pk_alert_constant.g_yes
                           AND v.id_market = i_id_market
                           AND v.id_vital_sign_desc NOT IN
                               (SELECT t.column_value
                                  FROM TABLE(i_id_vital_sign_desc) t))
            LOOP
                set_vs_content_desc(i_id_vital_sign_desc => vsd.id_vital_sign_desc,
                                    i_id_vital_sign      => NULL,
                                    i_id_market          => NULL,
                                    i_id_content         => NULL,
                                    i_rank               => NULL,
                                    i_value              => NULL,
                                    i_icon               => NULL,
                                    i_flg_add_remove     => 'R');
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN l_exception_ids_vsi THEN
            raise_application_error(-20001, 'i_id_vs_soft_inst.count must be i_id_software.count * i_flg_view.count');
        
        WHEN l_exception_ids_vsum THEN
            raise_application_error(-20001, 'i_id_vs_soft_inst.count must be i_id_software.count');
        
        WHEN l_exception_ids_vsd THEN
            raise_application_error(-20001, 'vital sign desc arrays must be all the same size');
        
    END set_vs_content_all;
    --
    PROCEDURE set_vs_content_rel
    (
        i_id_vital_sign_relation vital_sign_relation.id_vital_sign_relation%TYPE,
        i_id_vital_sign_parent   vital_sign_relation.id_vital_sign_parent%TYPE,
        i_id_vital_sign_detail   vital_sign_relation.id_vital_sign_detail%TYPE,
        i_relation_domain        vital_sign_relation.relation_domain%TYPE,
        i_rank                   vital_sign_relation.rank%TYPE,
        i_flg_add_remove         VARCHAR2
    ) IS
        l_count NUMBER(12);
    BEGIN
        IF i_flg_add_remove = 'R'
        THEN
            UPDATE vital_sign_relation vsrel
               SET vsrel.flg_available = pk_alert_constant.g_no
             WHERE vsrel.id_vital_sign_relation = i_id_vital_sign_relation;
        ELSE
            SELECT COUNT(1)
              INTO l_count
              FROM vital_sign_relation vsrel
             WHERE vsrel.id_vital_sign_relation = i_id_vital_sign_relation;
        
            IF l_count = 0
            THEN
                INSERT INTO vital_sign_relation
                    (id_vital_sign_relation,
                     id_vital_sign_parent,
                     id_vital_sign_detail,
                     relation_domain,
                     flg_available,
                     rank)
                VALUES
                    (i_id_vital_sign_relation,
                     i_id_vital_sign_parent,
                     i_id_vital_sign_detail,
                     i_relation_domain,
                     pk_alert_constant.g_yes,
                     i_rank);
            ELSE
                UPDATE vital_sign_relation vsrel
                   SET vsrel.id_vital_sign_parent = i_id_vital_sign_parent,
                       vsrel.id_vital_sign_detail = i_id_vital_sign_detail,
                       vsrel.relation_domain      = i_relation_domain,
                       vsrel.rank                 = i_rank
                 WHERE vsrel.id_vital_sign_relation = i_id_vital_sign_relation;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            raise_application_error(-20001, 'vital_sign_relation: Configuration already exists');
        
    END set_vs_content_rel;
    --
    PROCEDURE set_vs_content_bp
    (
        i_id_vital_sign_relation table_number,
        i_id_vital_sign_parent   table_number,
        i_id_vital_sign_detail   table_number,
        i_rank                   table_number
    ) IS
        l_exception_ids_vsrel EXCEPTION;
    BEGIN
    
        --vital sign relation arrays must be all the same size
        IF i_id_vital_sign_relation.exists(1)
        THEN
            IF i_id_vital_sign_relation.count <> i_id_vital_sign_parent.count
               OR i_id_vital_sign_relation.count <> i_id_vital_sign_detail.count
               OR i_id_vital_sign_relation.count <> i_rank.count
            THEN
                RAISE l_exception_ids_vsrel;
            END IF;
        END IF;
    
        FOR i IN 1 .. i_id_vital_sign_relation.count
        LOOP
            set_vs_content_rel(i_id_vital_sign_relation => i_id_vital_sign_relation(i),
                               i_id_vital_sign_parent   => i_id_vital_sign_parent(i),
                               i_id_vital_sign_detail   => i_id_vital_sign_detail(i),
                               i_relation_domain        => pk_alert_constant.g_vs_rel_conc,
                               i_rank                   => i_rank(i),
                               i_flg_add_remove         => pk_alert_constant.g_yes);
        END LOOP;
    
    EXCEPTION
    
        WHEN l_exception_ids_vsrel THEN
            raise_application_error(-20001, 'vital sign relation arrays must be all the same size');
        
    END set_vs_content_bp;
    --
    PROCEDURE set_vs_content_glasgow
    (
        i_id_vital_sign_relation table_number,
        i_id_vital_sign_parent   table_number,
        i_id_vital_sign_detail   table_number,
        i_rank                   table_number
    ) IS
        l_exception_ids_vsrel EXCEPTION;
    BEGIN
    
        --vital sign relation arrays must be all the same size
        IF i_id_vital_sign_relation.exists(1)
        THEN
            IF i_id_vital_sign_relation.count <> i_id_vital_sign_parent.count
               OR i_id_vital_sign_relation.count <> i_id_vital_sign_detail.count
               OR i_id_vital_sign_relation.count <> i_rank.count
            THEN
                RAISE l_exception_ids_vsrel;
            END IF;
        END IF;
    
        FOR i IN 1 .. i_id_vital_sign_relation.count
        LOOP
            set_vs_content_rel(i_id_vital_sign_relation => i_id_vital_sign_relation(i),
                               i_id_vital_sign_parent   => i_id_vital_sign_parent(i),
                               i_id_vital_sign_detail   => i_id_vital_sign_detail(i),
                               i_relation_domain        => pk_alert_constant.g_vs_rel_sum,
                               i_rank                   => i_rank(i),
                               i_flg_add_remove         => pk_alert_constant.g_yes);
        END LOOP;
    
    EXCEPTION
    
        WHEN l_exception_ids_vsrel THEN
            raise_application_error(-20001, 'vital sign relation arrays must be all the same size');
        
    END set_vs_content_glasgow;
    --
    PROCEDURE set_vs_content_scale
    (
        i_id_vital_sign_scales vital_sign_scales.id_vital_sign_scales%TYPE,
        i_id_vital_sign        vital_sign_scales.id_vital_sign%TYPE,
        i_internal_name        vital_sign_scales.internal_name%TYPE,
        i_flg_add_remove       VARCHAR2
    ) IS
        l_count NUMBER(12);
    BEGIN
        IF i_flg_add_remove = 'R'
        THEN
            UPDATE vital_sign_scales vss
               SET vss.flg_available = pk_alert_constant.g_no
             WHERE vss.id_vital_sign_scales = i_id_vital_sign_scales;
        ELSE
            SELECT COUNT(1)
              INTO l_count
              FROM vital_sign_scales vss
             WHERE vss.id_vital_sign_scales = i_id_vital_sign_scales;
        
            IF l_count = 0
            THEN
                INSERT INTO vital_sign_scales
                    (id_vital_sign_scales,
                     id_vital_sign,
                     code_vital_sign_scales,
                     internal_name,
                     flg_available,
                     code_vital_sign_scales_short)
                VALUES
                    (i_id_vital_sign_scales,
                     i_id_vital_sign,
                     'VITAL_SIGN_SCALES.CODE_VITAL_SIGN_SCALES.' || i_id_vital_sign_scales,
                     i_internal_name,
                     pk_alert_constant.g_yes,
                     'VITAL_SIGN_SCALES.CODE_VITAL_SIGN_SCALES_SHORT.' || i_id_vital_sign_scales);
            
            ELSE
                UPDATE vital_sign_scales vss
                   SET vss.id_vital_sign = i_id_vital_sign, vss.internal_name = i_internal_name
                 WHERE vss.id_vital_sign_scales = i_id_vital_sign_scales;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            raise_application_error(-20001, 'vital_sign_scales: Configuration already exists');
        
    END set_vs_content_scale;
    --
    PROCEDURE set_vs_content_vsse
    (
        i_id_vs_scales_element vital_sign_scales_element.id_vs_scales_element%TYPE,
        i_id_vital_sign_scales vital_sign_scales_element.id_vital_sign_scales%TYPE,
        i_internal_name        vital_sign_scales_element.internal_name%TYPE,
        i_value                vital_sign_scales_element.value%TYPE,
        i_min_value            vital_sign_scales_element.min_value%TYPE,
        i_max_value            vital_sign_scales_element.max_value%TYPE,
        i_id_unit_measure      vital_sign_scales_element.id_unit_measure%TYPE,
        i_icon                 vital_sign_scales_element.icon%TYPE,
        i_flg_add_remove       VARCHAR2
    ) IS
        l_count NUMBER(12);
    BEGIN
        IF i_flg_add_remove = 'R'
        THEN
            UPDATE vital_sign_scales_element vsse
               SET vsse.flg_available = pk_alert_constant.g_no
             WHERE vsse.id_vs_scales_element = i_id_vs_scales_element;
        ELSE
            SELECT COUNT(1)
              INTO l_count
              FROM vital_sign_scales_element vss
             WHERE vss.id_vs_scales_element = i_id_vs_scales_element;
        
            IF l_count = 0
            THEN
                INSERT INTO vital_sign_scales_element
                    (id_vs_scales_element,
                     id_vital_sign_scales,
                     internal_name,
                     VALUE,
                     min_value,
                     max_value,
                     flg_available,
                     code_vss_element,
                     id_unit_measure,
                     icon,
                     code_vss_element_title)
                VALUES
                    (i_id_vs_scales_element,
                     i_id_vital_sign_scales,
                     i_internal_name,
                     i_value,
                     i_min_value,
                     i_max_value,
                     pk_alert_constant.g_yes,
                     'VITAL_SIGN_SCALES_ELEMENT.CODE_VSS_ELEMENT.' || i_id_vs_scales_element,
                     i_id_unit_measure,
                     i_icon,
                     'VITAL_SIGN_SCALES_ELEMENT.CODE_VSS_ELEMENT_TITLE.' || i_id_vs_scales_element);
            
            ELSE
                UPDATE vital_sign_scales_element vsse
                   SET vsse.id_vital_sign_scales = i_id_vital_sign_scales,
                       vsse.internal_name        = i_internal_name,
                       vsse.value                = i_value,
                       vsse.min_value            = i_min_value,
                       vsse.max_value            = i_max_value,
                       vsse.id_unit_measure      = i_id_unit_measure,
                       vsse.icon                 = i_icon
                 WHERE vsse.id_vs_scales_element = i_id_vs_scales_element;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            raise_application_error(-20001, 'vital_sign_scales_element: Configuration already exists');
        
    END set_vs_content_vsse;
    --
    PROCEDURE set_vs_content_vssa
    (
        i_id_vital_sign_scales_access alert_default.vital_sign_scales_access.id_vital_sign_scales_access%TYPE,
        i_id_vital_sign_scales        alert_default.vital_sign_scales_access.id_vital_sign_scales%TYPE,
        i_id_software                 alert_default.vital_sign_scales_access.id_software%TYPE,
        i_flg_add_remove              VARCHAR2
    ) IS
    BEGIN
        alert_default.pk_vital_sign_default.set_vs_content_vssa(i_id_vital_sign_scales_access => i_id_vital_sign_scales_access,
                                                                i_id_vital_sign_scales        => i_id_vital_sign_scales,
                                                                i_id_software                 => i_id_software,
                                                                i_flg_add_remove              => i_flg_add_remove);
    END set_vs_content_vssa;
    --
    PROCEDURE set_vs_content_attribute
    (
        i_id_vs_attribute vs_attribute.id_vs_attribute%TYPE,
        i_id_parent       vs_attribute.id_parent%TYPE,
        i_flg_free_text   vs_attribute.flg_free_text%TYPE,
        i_id_content      vs_attribute.id_content%TYPE
    ) IS
        l_count NUMBER(12);
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM vs_attribute va
         WHERE va.id_vs_attribute = i_id_vs_attribute;
    
        IF l_count = 0
        THEN
            INSERT INTO vs_attribute
                (id_vs_attribute, id_parent, code_vs_attribute, flg_free_text, id_content)
            VALUES
                (i_id_vs_attribute,
                 i_id_parent,
                 'VS_ATTRIBUTE.CODE_VS_ATTRIBUTE.' || i_id_vs_attribute,
                 i_flg_free_text,
                 i_id_content);
        ELSE
            UPDATE vs_attribute va
               SET va.id_content = i_id_content, va.flg_free_text = i_flg_free_text, va.id_parent = i_id_parent
             WHERE va.id_vs_attribute = i_id_vs_attribute;
        END IF;
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            raise_application_error(-20001, 'vs_attribute: Configuration already exists');
        
    END set_vs_content_attribute;
    --
    PROCEDURE set_vs_content_vsasi
    (
        i_id_vs_attribute vs_attribute_soft_inst.id_vs_attribute%TYPE,
        i_id_vital_sign   vs_attribute_soft_inst.id_vital_sign%TYPE,
        i_id_market       vs_attribute_soft_inst.id_market%TYPE,
        i_id_institution  vs_attribute_soft_inst.id_institution%TYPE,
        i_id_software     vs_attribute_soft_inst.id_software%TYPE,
        i_rank            vs_attribute_soft_inst.rank%TYPE,
        i_flg_add_remove  VARCHAR2
    ) IS
        l_count NUMBER(12);
    BEGIN
        IF i_flg_add_remove = 'R'
        THEN
            DELETE FROM vs_attribute_soft_inst vsasi
             WHERE vsasi.id_vs_attribute = i_id_vs_attribute
               AND vsasi.id_vital_sign = i_id_vital_sign
               AND vsasi.id_market = i_id_market
               AND vsasi.id_institution = i_id_institution
               AND vsasi.id_software = i_id_software;
        ELSE
        
            SELECT COUNT(1)
              INTO l_count
              FROM vs_attribute_soft_inst vsasi
             WHERE vsasi.id_vs_attribute = i_id_vs_attribute
               AND vsasi.id_vital_sign = i_id_vital_sign
               AND vsasi.id_market = i_id_market
               AND vsasi.id_institution = i_id_institution
               AND vsasi.id_software = i_id_software;
        
            IF l_count = 0
            THEN
                INSERT INTO vs_attribute_soft_inst
                    (id_vs_attribute, id_vital_sign, id_institution, id_software, id_market, rank)
                VALUES
                    (i_id_vs_attribute, i_id_vital_sign, i_id_institution, i_id_software, i_id_market, i_rank);
            ELSE
                UPDATE vs_attribute_soft_inst vsasi
                   SET vsasi.rank = i_rank
                 WHERE vsasi.id_vs_attribute = i_id_vs_attribute
                   AND vsasi.id_vital_sign = i_id_vital_sign
                   AND vsasi.id_market = i_id_market
                   AND vsasi.id_institution = i_id_institution
                   AND vsasi.id_software = i_id_software;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            raise_application_error(-20001, 'vs_attribute_soft_inst: Configuration already exists');
        
    END set_vs_content_vsasi;
    --
    FUNCTION tf_vs_prm
    (
        i_lang          IN language.id_language%TYPE,
        i_id_vital_sign IN vital_sign.id_vital_sign%TYPE DEFAULT NULL
    ) RETURN t_coll_vs_prm IS
        l_out t_coll_vs_prm := t_coll_vs_prm();
    BEGIN
        SELECT t_rec_vs_prm(t.id_content,
                            t.id_vital_sign,
                            t.flg_fill_type,
                            t.desc_flg_fill_type,
                            t.intern_name_vital_sign,
                            t.desc_vital_sign,
                            t.desc_short_vital_sign)
          BULK COLLECT
          INTO l_out
          FROM (SELECT vs.id_content,
                       vs.id_vital_sign,
                       vs.flg_fill_type,
                       pk_sysdomain.get_domain(i_code_dom => 'VITAL_SIGN.FLG_FILL_TYPE',
                                               i_val      => vs.flg_fill_type,
                                               i_lang     => i_lang) desc_flg_fill_type,
                       vs.intern_name_vital_sign,
                       pk_translation.get_translation(i_lang, vs.code_vital_sign) desc_vital_sign,
                       pk_translation.get_translation(i_lang, vs.code_vs_short_desc) desc_short_vital_sign
                  FROM vital_sign vs
                 WHERE nvl(i_id_vital_sign, vs.id_vital_sign) = vs.id_vital_sign
                 ORDER BY desc_vital_sign) t;
    
        RETURN l_out;
    END tf_vs_prm;
    --
    FUNCTION tf_vsi_prm
    (
        i_lang          IN language.id_language%TYPE,
        i_id_vital_sign alert_default.vs_soft_inst.id_vital_sign%TYPE,
        i_id_market     alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software   alert_default.vs_soft_inst.id_software%TYPE DEFAULT NULL,
        i_flg_view      alert_default.vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        i_version       alert_default.vs_soft_inst.version%TYPE DEFAULT NULL
    ) RETURN t_coll_vsi_prm IS
        l_out t_coll_vsi_prm := t_coll_vsi_prm();
    BEGIN
        SELECT t_rec_vsi_prm(t.id_vs_soft_inst,
                             t.id_vital_sign,
                             t.desc_vital_sign,
                             t.desc_market,
                             t.id_market,
                             t.desc_software,
                             t.id_software,
                             t.version,
                             t.desc_flg_view,
                             t.flg_view,
                             t.desc_unit_measure,
                             t.id_unit_measure,
                             t.color_grafh,
                             t.color_text,
                             t.box_type,
                             t.desc_box_type,
                             t.rank)
          BULK COLLECT
          INTO l_out
          FROM (SELECT vsi.id_vs_soft_inst,
                       vsi.id_vital_sign,
                       pk_translation.get_translation(i_lang, vs.code_vital_sign) || ' (' || vsi.id_vital_sign || ')' desc_vital_sign,
                       pk_translation.get_translation(i_lang, m.code_market) || ' (' || m.id_market || ')' desc_market,
                       m.id_market,
                       s.name || ' (' || s.id_software || ')' desc_software,
                       s.id_software,
                       vsi.version,
                       pk_sysdomain.get_domain(i_code_dom => 'VS_SOFT_INST.FLG_VIEW',
                                               i_val      => vsi.flg_view,
                                               i_lang     => i_lang) || ' (' || vsi.flg_view || ')' desc_flg_view,
                       vsi.flg_view,
                       nvl2(vsi.id_unit_measure,
                            pk_translation.get_translation(i_lang, um.code_unit_measure) || ' (' || vsi.id_unit_measure || ')',
                            NULL) desc_unit_measure,
                       vsi.id_unit_measure,
                       vsi.color_grafh,
                       vsi.color_text,
                       vsi.box_type,
                       pk_sysdomain.get_domain(i_code_dom => 'VS_SOFT_INST.BOX_TYPE',
                                               i_val      => vsi.box_type,
                                               i_lang     => i_lang) || ' (' || vsi.box_type || ')' desc_box_type,
                       vsi.rank
                  FROM alert_default.vs_soft_inst vsi
                  JOIN vital_sign vs
                    ON vsi.id_vital_sign = vs.id_vital_sign
                  JOIN market m
                    ON m.id_market = vsi.id_market
                  JOIN software s
                    ON s.id_software = vsi.id_software
                  LEFT JOIN unit_measure um
                    ON um.id_unit_measure = vsi.id_unit_measure
                 WHERE vsi.id_market = i_id_market
                   AND (vsi.id_vital_sign = i_id_vital_sign OR i_id_vital_sign IS NULL)
                   AND (vsi.id_software = i_id_software OR i_id_software IS NULL)
                   AND (vsi.flg_view = i_flg_view OR i_flg_view IS NULL)
                   AND (vsi.version = i_version OR i_version IS NULL)
                 ORDER BY vsi.id_software, vsi.flg_view, vsi.version, vsi.rank) t;
    
        RETURN l_out;
    END tf_vsi_prm;
    --
    FUNCTION tf_software(i_screen_name sys_button_prop.screen_name%TYPE) RETURN t_coll_software IS
        l_out t_coll_software := t_coll_software();
    BEGIN
        SELECT t_rec_software(t.soft_name, t.id_software)
          BULK COLLECT
          INTO l_out
          FROM (SELECT DISTINCT s.name soft_name, s.id_software
                  FROM sys_button_prop sbp
                  JOIN profile_templ_access pta
                    ON pta.id_sys_button_prop = sbp.id_sys_button_prop
                   AND pta.flg_add_remove = pk_alert_constant.g_active
                  JOIN software s
                    ON s.id_software = pta.id_software
                 WHERE sbp.screen_name = i_screen_name
                 ORDER BY s.name ASC) t;
    
        RETURN l_out;
    END tf_software;
    --
    FUNCTION tf_vsum_prm
    (
        i_lang            IN language.id_language%TYPE,
        i_id_vital_sign   alert_default.vs_soft_inst.id_vital_sign%TYPE,
        i_id_market       alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software     alert_default.vs_soft_inst.id_software%TYPE DEFAULT NULL,
        i_version         alert_default.vs_soft_inst.version%TYPE DEFAULT NULL,
        i_id_unit_measure alert_default.vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL
    ) RETURN t_coll_vsum_prm IS
        l_out t_coll_vsum_prm := t_coll_vsum_prm();
    BEGIN
        SELECT t_rec_vsum_prm(t.id_vital_sign_unit_measure,
                              t.id_vital_sign,
                              t.desc_vital_sign,
                              t.id_market,
                              t.desc_market,
                              t.id_software,
                              t.desc_software,
                              t.version,
                              t.id_unit_measure,
                              t.desc_unit_measure,
                              t.val_min,
                              t.val_max,
                              t.format_num,
                              t.decimals,
                              t.age_min,
                              t.age_max)
          BULK COLLECT
          INTO l_out
          FROM (SELECT vsum.id_vital_sign_unit_measure,
                       vsum.id_vital_sign,
                       pk_translation.get_translation(i_lang, vs.code_vital_sign) || ' (' || vsum.id_vital_sign || ')' desc_vital_sign,
                       vsum.id_market,
                       pk_translation.get_translation(i_lang, m.code_market) || ' (' || m.id_market || ')' desc_market,
                       vsum.id_software,
                       s.name || ' (' || s.id_software || ')' desc_software,
                       vsum.version,
                       vsum.id_unit_measure,
                       pk_translation.get_translation(i_lang, um.code_unit_measure) || ' (' || vsum.id_unit_measure || ')' desc_unit_measure,
                       vsum.val_min,
                       vsum.val_max,
                       vsum.format_num,
                       vsum.decimals,
                       vsum.age_min,
                       vsum.age_max
                  FROM alert_default.vital_sign_unit_measure vsum
                  JOIN vital_sign vs
                    ON vsum.id_vital_sign = vs.id_vital_sign
                  JOIN market m
                    ON m.id_market = vsum.id_market
                  JOIN software s
                    ON s.id_software = vsum.id_software
                  JOIN unit_measure um
                    ON um.id_unit_measure = vsum.id_unit_measure
                 WHERE vsum.id_market = i_id_market
                   AND (vsum.id_vital_sign = i_id_vital_sign OR i_id_vital_sign IS NULL)
                   AND (vsum.id_software = i_id_software OR i_id_software IS NULL)
                   AND (vsum.version = i_version OR i_version IS NULL)
                   AND nvl(vsum.id_unit_measure, 0) = nvl(i_id_unit_measure, 0)
                 ORDER BY vsum.id_software) t;
    
        RETURN l_out;
    END tf_vsum_prm;
    --
    FUNCTION tf_vsum_prm
    (
        i_lang            IN language.id_language%TYPE,
        i_id_vital_sign   alert_default.vs_soft_inst.id_vital_sign%TYPE,
        i_id_market       alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software_tab table_number,
        i_version         alert_default.vs_soft_inst.version%TYPE DEFAULT NULL,
        i_id_unit_measure alert_default.vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL
    ) RETURN t_coll_vsum_prm IS
        l_out t_coll_vsum_prm := t_coll_vsum_prm();
    BEGIN
        SELECT t_rec_vsum_prm(t.id_vital_sign_unit_measure,
                              t.id_vital_sign,
                              t.desc_vital_sign,
                              t.id_market,
                              t.desc_market,
                              t.id_software,
                              t.desc_software,
                              t.version,
                              t.id_unit_measure,
                              t.desc_unit_measure,
                              t.val_min,
                              t.val_max,
                              t.format_num,
                              t.decimals,
                              t.age_min,
                              t.age_max)
          BULK COLLECT
          INTO l_out
          FROM (SELECT vsum.id_vital_sign_unit_measure,
                       vsum.id_vital_sign,
                       pk_translation.get_translation(i_lang, vs.code_vital_sign) || ' (' || vsum.id_vital_sign || ')' desc_vital_sign,
                       vsum.id_market,
                       pk_translation.get_translation(i_lang, m.code_market) || ' (' || m.id_market || ')' desc_market,
                       vsum.id_software,
                       s.name || ' (' || s.id_software || ')' desc_software,
                       vsum.version,
                       vsum.id_unit_measure,
                       pk_translation.get_translation(i_lang, um.code_unit_measure) || ' (' || vsum.id_unit_measure || ')' desc_unit_measure,
                       vsum.val_min,
                       vsum.val_max,
                       vsum.format_num,
                       vsum.decimals,
                       vsum.age_min,
                       vsum.age_max
                  FROM alert_default.vital_sign_unit_measure vsum
                  JOIN vital_sign vs
                    ON vsum.id_vital_sign = vs.id_vital_sign
                  JOIN market m
                    ON m.id_market = vsum.id_market
                  JOIN software s
                    ON s.id_software = vsum.id_software
                  JOIN unit_measure um
                    ON um.id_unit_measure = vsum.id_unit_measure
                 WHERE vsum.id_market = i_id_market
                   AND (vsum.id_vital_sign = i_id_vital_sign OR i_id_vital_sign IS NULL)
                   AND vsum.id_software IN (SELECT column_value /*+opt_estimate(TABLE, t, rows = 1)*/
                                              FROM TABLE(i_id_software_tab) t)
                   AND (vsum.version = i_version OR i_version IS NULL)
                   AND nvl(vsum.id_unit_measure, 0) = nvl(i_id_unit_measure, 0)
                 ORDER BY vsum.id_software) t;
    
        RETURN l_out;
    END tf_vsum_prm;

    /*********************************************************************************************
    * Get the next id_value available for inserts
    * @param      i_table
    * @param      i_column       column that we want to check (normally the table PK)
    * @param      i_id_max       limits the id (DEFAULT 9999999)
    * @param      i_dblink       searchs on the specified db_link besides QC1 and DEV (dblinks based on dev)
    *
    * @author     Nuno Alves
    * @since      06/Jan/2015
    *********************************************************************************************/
    FUNCTION get_new_id
    (
        i_table  IN VARCHAR2,
        i_column IN VARCHAR2 DEFAULT NULL,
        i_id_max IN NUMBER DEFAULT 999999999,
        i_dblink IN VARCHAR2 DEFAULT NULL,
        i_owner  IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        l_all_max_ids table_number := table_number();
        l_max_id      NUMBER;
        l_counter     NUMBER := 1;
        l_column      VARCHAR2(30);
        l_owner_dot   VARCHAR2(100);
    BEGIN
        IF i_column IS NULL
        THEN
            BEGIN
                SELECT ucc.column_name
                  INTO l_column
                  FROM user_constraints uc
                  JOIN user_cons_columns ucc
                    ON uc.constraint_name = ucc.constraint_name
                   AND uc.owner = ucc.owner
                 WHERE uc.constraint_type = 'P'
                   AND uc.owner = nvl(upper(i_owner), uc.owner)
                   AND uc.table_name = upper(i_table);
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN NULL;
            END;
        ELSE
            l_column := i_column;
        END IF;
    
        BEGIN
            IF i_owner IS NOT NULL
            THEN
                l_owner_dot := i_owner || '.';
            ELSE
                l_owner_dot := NULL;
            END IF;
        
            IF i_dblink IS NOT NULL
            THEN
                EXECUTE IMMEDIATE 'SELECT MAX(t.' || l_column || ' ) FROM ' || l_owner_dot || i_table || i_dblink ||
                                  ' t WHERE t.' || l_column || ' <= ' || i_id_max
                    INTO l_max_id;
                l_all_max_ids.extend;
                l_all_max_ids(l_counter) := l_max_id;
                l_counter := l_counter + 1;
            END IF;
        
            EXECUTE IMMEDIATE 'SELECT MAX(t.' || l_column || ' ) FROM ' || l_owner_dot || i_table || ' t WHERE t.' ||
                              l_column || ' <= ' || i_id_max
                INTO l_max_id;
            l_all_max_ids.extend;
            l_all_max_ids(l_counter) := l_max_id;
            l_counter := l_counter + 1;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END;
    
        FOR i IN l_all_max_ids.first .. l_all_max_ids.last
        LOOP
            IF (l_all_max_ids(i) > l_max_id)
            THEN
                l_max_id := l_all_max_ids(i);
            END IF;
        END LOOP;
    
        l_max_id := l_max_id + 1;
        IF l_max_id > i_id_max
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_max_id;
    END get_new_id;

    /*********************************************************************************************
    * Get the script for versioning through the set_vs_content_all API
    *
    * @author     Nuno Alves
    * @since      06/Mar/2015
    *********************************************************************************************/
    FUNCTION get_script_vs_content_all
    (
        i_id_vital_sign          IN VARCHAR2,
        i_intern_name_vital_sign IN VARCHAR2,
        i_flg_fill_type          IN VARCHAR2,
        i_id_content_vs          IN VARCHAR2,
        i_id_market              IN VARCHAR2,
        i_id_vs_soft_inst        IN VARCHAR2 DEFAULT NULL,
        i_id_software            IN VARCHAR2 DEFAULT NULL,
        i_version                IN VARCHAR2 DEFAULT NULL,
        i_flg_view               IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure        IN VARCHAR2 DEFAULT NULL,
        i_color_grafh            IN VARCHAR2 DEFAULT NULL,
        i_color_text             IN VARCHAR2 DEFAULT NULL,
        i_box_type               IN VARCHAR2 DEFAULT NULL,
        i_rank_vsi               IN VARCHAR2 DEFAULT NULL,
        i_val_min                IN VARCHAR2 DEFAULT NULL,
        i_val_max                IN VARCHAR2 DEFAULT NULL,
        i_format_num             IN VARCHAR2 DEFAULT NULL,
        i_decimals               IN VARCHAR2 DEFAULT NULL,
        i_age_min                IN VARCHAR2 DEFAULT NULL,
        i_age_max                IN VARCHAR2 DEFAULT NULL,
        i_num_id_vital_sign_desc IN VARCHAR2 DEFAULT NULL,
        i_id_vital_sign_desc     IN VARCHAR2 DEFAULT NULL,
        i_id_content_vsd         IN VARCHAR2 DEFAULT NULL,
        i_rank_vsd               IN VARCHAR2 DEFAULT NULL,
        i_value                  IN VARCHAR2 DEFAULT NULL,
        i_icon                   IN VARCHAR2 DEFAULT NULL,
        i_flg_script_type        IN VARCHAR2 DEFAULT 'I'
    ) RETURN CLOB IS
        l_id_vital_sign VARCHAR2(4000) := nvl(i_id_vital_sign,
                                              pk_vitalsign_prm.get_new_id(i_table  => 'VITAL_SIGN',
                                                                          i_column => 'ID_VITAL_SIGN',
                                                                          i_dblink => '@QC1_DSV',
                                                                          i_owner  => 'ALERT'));
    
        l_intern_name_vital_sign VARCHAR2(4000) := nvl(i_intern_name_vital_sign, 'NULL');
        l_flg_fill_type          VARCHAR2(4000) := nvl(i_flg_fill_type, 'NULL');
        l_id_content_vs          VARCHAR2(4000) := nvl(i_id_content_vs, 'NULL');
        -- vsi
        l_id_vs_soft_inst VARCHAR2(4000) := nvl(i_id_vs_soft_inst, 'table_number()');
        l_id_market       VARCHAR2(4000) := nvl(i_id_market, 'NULL');
        l_id_software     VARCHAR2(4000) := 'table_number()';
        l_version         VARCHAR2(4000) := nvl(i_version, 'NULL');
        l_flg_view        VARCHAR2(4000) := 'table_varchar()';
        l_id_unit_measure VARCHAR2(4000) := nvl(i_id_unit_measure, 'NULL');
        l_color_grafh     VARCHAR2(4000) := nvl(TRIM(leading '#' FROM i_color_grafh), 'NULL');
        l_color_text      VARCHAR2(4000) := nvl(i_color_text, 'NULL');
        l_box_type        VARCHAR2(4000) := nvl(i_box_type, 'NULL');
        l_rank_vsi        VARCHAR2(4000) := nvl(i_rank_vsi, 'NULL');
        -- vsum
        l_id_vital_sign_um VARCHAR2(4000) := 'table_number()';
        l_val_min          VARCHAR2(4000) := nvl(i_val_min, 'NULL');
        l_val_max          VARCHAR2(4000) := nvl(i_val_max, 'NULL');
        l_format_num       VARCHAR2(4000) := nvl(i_format_num, 'NULL');
        l_decimals         VARCHAR2(4000) := nvl(i_decimals, 'NULL');
        l_age_min          VARCHAR2(4000) := nvl(i_age_min, 'NULL');
        l_age_max          VARCHAR2(4000) := nvl(i_age_max, 'NULL');
        --vs desc
        l_id_vital_sign_desc VARCHAR2(4000) := nvl(i_id_vital_sign_desc, 'table_number()');
        l_id_content_vsd     VARCHAR2(4000) := nvl(i_id_content_vsd, 'table_varchar()');
        l_rank_vsd           VARCHAR2(4000) := nvl(i_rank_vsd, 'table_number()');
        l_value              VARCHAR2(4000) := nvl(i_value, 'table_varchar()');
        l_icon               VARCHAR2(4000) := nvl(i_icon, 'table_varchar()');
    
        -- Aux var for ids handling
        l_id_software_tab         table_varchar := table_varchar();
        l_flg_view_tab            table_varchar := table_varchar();
        l_id_vital_sign_um_tab    table_varchar := table_varchar();
        l_next_id_vs_soft_inst    NUMBER;
        l_next_id_vital_sign_um   NUMBER;
        l_next_id_vital_sign_desc NUMBER;
    
        -- Final Script to return
        l_script CLOB;
    
        -- aux vars
        l_id_soft_dist_tab  table_number;
        l_flg_view_dist_tab table_varchar;
    
        l_table_desc_info_ranked t_table_desc_info_ranked;
        l_id_soft_vsum_edit_new  table_number;
    
        -- Aux function for ids handling
        FUNCTION generate_ids_tab_num_str
        (
            l_starting_id NUMBER,
            l_num_ids     NUMBER,
            l_just_ids    BOOLEAN
        ) RETURN VARCHAR2 AS
            l_result VARCHAR2(4000);
        BEGIN
            IF l_just_ids
            THEN
                l_result := l_starting_id;
            ELSE
                l_result := 'table_number(' || l_starting_id;
            END IF;
        
            FOR i IN 1 .. (l_num_ids - 1)
            LOOP
                l_result := l_result || ',' || (l_starting_id + i);
            END LOOP;
            l_result := l_result || ')';
            RETURN l_result;
        END generate_ids_tab_num_str;
    
        -- Aux function for enclosing varchars in ' '
        FUNCTION enclose_str_in_quotes(str VARCHAR2) RETURN VARCHAR2 AS
            l_result VARCHAR2(4000);
        BEGIN
            IF str = 'NULL'
            THEN
                l_result := str;
            ELSE
                l_result := '''' || str || '''';
            END IF;
            RETURN l_result;
        END enclose_str_in_quotes;
    
    BEGIN
        -- vsi
        IF i_flg_script_type = g_flg_script_type_del
        THEN
            l_id_vs_soft_inst := 'table_number(' || REPLACE(i_id_vs_soft_inst, ':', ',') || ')';
        ELSIF (i_id_software IS NOT NULL)
        THEN
        
            l_id_software_tab := pk_string_utils.str_split(i_list => i_id_software, i_delim => ':');
        
            SELECT DISTINCT t.column_value
              BULK COLLECT
              INTO l_id_soft_dist_tab
              FROM TABLE(l_id_software_tab) t;
        
            IF i_flg_view IS NOT NULL
            THEN
                l_flg_view_tab := pk_string_utils.str_split(i_list => i_flg_view, i_delim => ':');
            
                SELECT DISTINCT t.column_value
                  BULK COLLECT
                  INTO l_flg_view_dist_tab
                  FROM TABLE(l_flg_view_tab) t;
            
                l_flg_view := 'table_varchar(''' ||
                              pk_utils.concat_table(i_tab => l_flg_view_dist_tab, i_delim => ''',''') || ''')';
            
                IF i_id_vs_soft_inst IS NULL
                THEN
                    l_next_id_vs_soft_inst := pk_vitalsign_prm.get_new_id(i_table  => 'VS_SOFT_INST',
                                                                          i_column => 'ID_VS_SOFT_INST',
                                                                          i_dblink => '@QC1_DSV',
                                                                          i_owner  => 'ALERT_DEFAULT');
                
                    l_id_vs_soft_inst := generate_ids_tab_num_str(l_next_id_vs_soft_inst,
                                                                  (l_id_soft_dist_tab.count * l_flg_view_dist_tab.count),
                                                                  FALSE);
                ELSE
                    l_id_vs_soft_inst := 'table_number(' || REPLACE(i_id_vs_soft_inst, ':', ',') || ')';
                END IF;
            END IF;
        
            -- vsum
            IF i_flg_script_type = g_flg_script_type_ins
            THEN
                l_next_id_vital_sign_um := pk_vitalsign_prm.get_new_id(i_table  => 'VITAL_SIGN_UNIT_MEASURE',
                                                                       i_column => 'ID_VITAL_SIGN_UNIT_MEASURE',
                                                                       i_dblink => '@QC1_DSV',
                                                                       i_owner  => 'ALERT_DEFAULT');
            
                l_id_vital_sign_um := generate_ids_tab_num_str(l_next_id_vital_sign_um, l_id_soft_dist_tab.count, FALSE); -- table_number
            ELSIF i_flg_script_type = g_flg_script_type_upd
            THEN
                SELECT t_rec_desc_info_ranked(id        => t.id_vital_sign_unit_measure,
                                              desc_info => NULL,
                                              num_rank  => t.id_software,
                                              tstz_rank => NULL,
                                              signature => NULL)
                  BULK COLLECT
                  INTO l_table_desc_info_ranked
                  FROM TABLE(pk_vitalsign_prm.tf_vsum_prm(i_lang            => NULL,
                                                          i_id_vital_sign   => i_id_vital_sign,
                                                          i_id_market       => i_id_market,
                                                          i_id_software_tab => l_id_soft_dist_tab,
                                                          i_id_unit_measure => i_id_unit_measure)) t;
            
                SELECT t.column_value
                  BULK COLLECT
                  INTO l_id_soft_vsum_edit_new
                  FROM TABLE(l_id_soft_dist_tab) t
                 WHERE t.column_value NOT IN (SELECT t_edit.num_rank
                                                FROM TABLE(l_table_desc_info_ranked) t_edit);
            
                IF l_id_soft_vsum_edit_new.exists(1)
                THEN
                    l_next_id_vital_sign_um := pk_vitalsign_prm.get_new_id(i_table  => 'VITAL_SIGN_UNIT_MEASURE',
                                                                           i_column => 'ID_VITAL_SIGN_UNIT_MEASURE',
                                                                           i_dblink => '@QC1_DSV',
                                                                           i_owner  => 'ALERT_DEFAULT');
                    FOR i IN 1 .. l_id_soft_vsum_edit_new.count
                    LOOP
                        l_table_desc_info_ranked.extend;
                        l_table_desc_info_ranked(l_table_desc_info_ranked.count) := t_rec_desc_info_ranked(id        => l_next_id_vital_sign_um,
                                                                                                           desc_info => NULL,
                                                                                                           num_rank  => l_id_soft_vsum_edit_new(i),
                                                                                                           tstz_rank => NULL,
                                                                                                           signature => NULL);
                        l_next_id_vital_sign_um := l_next_id_vital_sign_um + 1;
                    END LOOP;
                
                END IF;
            
                -- guarantee table_number indexes relation
                SELECT t.id, t.num_rank
                  BULK COLLECT
                  INTO l_id_vital_sign_um_tab, l_id_soft_dist_tab
                  FROM TABLE(l_table_desc_info_ranked) t
                 ORDER BY t.num_rank ASC;
            
                l_id_vital_sign_um := 'table_number(' ||
                                      pk_utils.concat_table(i_tab => l_id_vital_sign_um_tab, i_delim => ',') || ')';
            
            END IF;
        
            l_id_software := 'table_number(' || pk_utils.concat_table(i_tab => l_id_soft_dist_tab, i_delim => ',') || ')';
        END IF;
    
        --vs desc
        IF i_id_vital_sign_desc IS NULL
        THEN
            IF i_num_id_vital_sign_desc > 0
            THEN
                l_next_id_vital_sign_desc := pk_vitalsign_prm.get_new_id(i_table  => 'VITAL_SIGN_DESC',
                                                                         i_column => 'ID_VITAL_SIGN_DESC',
                                                                         i_dblink => '@QC1_DSV',
                                                                         i_owner  => 'ALERT');
            
                l_id_vital_sign_desc := generate_ids_tab_num_str(l_next_id_vital_sign_desc,
                                                                 i_num_id_vital_sign_desc,
                                                                 FALSE);
            END IF;
        ELSE
            IF i_num_id_vital_sign_desc > 0
            THEN
                l_next_id_vital_sign_desc := pk_vitalsign_prm.get_new_id(i_table  => 'VITAL_SIGN_DESC',
                                                                         i_column => 'ID_VITAL_SIGN_DESC',
                                                                         i_dblink => '@QC1_DSV',
                                                                         i_owner  => 'ALERT');
            
                l_id_vital_sign_desc := substr(l_id_vital_sign_desc, 0, length(l_id_vital_sign_desc) - 1) || ',';
            
                l_id_vital_sign_desc := l_id_vital_sign_desc || generate_ids_tab_num_str(l_next_id_vital_sign_desc,
                                                                                         i_num_id_vital_sign_desc,
                                                                                         TRUE);
            END IF;
        END IF;
        -- Enclose in ' ' the VARCHAR fields
        l_intern_name_vital_sign := enclose_str_in_quotes(l_intern_name_vital_sign);
        l_flg_fill_type          := enclose_str_in_quotes(l_flg_fill_type);
        l_id_content_vs          := enclose_str_in_quotes(l_id_content_vs);
        l_version                := enclose_str_in_quotes(l_version);
        l_color_grafh            := enclose_str_in_quotes(l_color_grafh);
        l_color_text             := enclose_str_in_quotes(l_color_text);
        l_box_type               := enclose_str_in_quotes(l_box_type);
        l_format_num             := enclose_str_in_quotes(l_format_num);
    
        -- Final script
        l_script := 'pk_vitalsign_prm.set_vs_content_all(i_id_vital_sign              => ' || l_id_vital_sign || ',
                                            i_intern_name_vital_sign     => ' ||
                    l_intern_name_vital_sign || ',
                                            i_flg_fill_type              => ' || l_flg_fill_type || ',
                                            i_id_content_vs              => ' || l_id_content_vs || ',
                                            i_id_vs_soft_inst            => ' || l_id_vs_soft_inst || ',
                                            i_id_market                  => ' || l_id_market || ',
                                            i_id_software                => ' || l_id_software || ',
                                            i_version                    => ' || l_version || ',
                                            i_flg_view                   => ' || l_flg_view || ',
                                            i_id_unit_measure            => ' || l_id_unit_measure || ',
                                            i_color_grafh                => ' || l_color_grafh || ',
                                            i_color_text                 => ' || l_color_text || ',
                                            i_box_type                   => ' || l_box_type || ',
                                            i_rank_vsi                   => ' || l_rank_vsi || ',
                                            i_id_vital_sign_unit_measure => ' || l_id_vital_sign_um || ',
                                            i_val_min                    => ' || l_val_min || ',
                                            i_val_max                    => ' || l_val_max || ',
                                            i_format_num                 => ' || l_format_num || ',
                                            i_decimals                   => ' || l_decimals || ',
                                            i_age_min                    => ' || l_age_min || ',
                                            i_age_max                    => ' || l_age_max || ',
                                            i_id_vital_sign_desc         => ' ||
                    l_id_vital_sign_desc || ',
                                            i_id_content_vsd             => ' || l_id_content_vsd || ',
                                            i_rank_vsd                   => ' || l_rank_vsd || ',
                                            i_value                      => ' || l_value || ',
                                            i_icon                       => ' || l_icon || ',
                                            i_flg_script_type            => ''' || i_flg_script_type ||
                    ''');';
    
        RETURN l_script;
    END get_script_vs_content_all;

    /*********************************************************************************************
    * Get the most frequent config values for a vital sign
    *
    * @author     Nuno Alves
    * @since      02/Jun/2015
    *********************************************************************************************/
    FUNCTION get_vs_most_freq_config
    (
        i_lang          language.id_language%TYPE,
        i_id_vital_sign alert_default.vs_soft_inst.id_vital_sign%TYPE,
        i_id_market     alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software   alert_default.vs_soft_inst.id_software%TYPE DEFAULT NULL,
        i_flg_view      alert_default.vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        i_version       alert_default.vs_soft_inst.version%TYPE DEFAULT NULL
    ) RETURN t_rec_vs_freq_config IS
        -- vital_sign
        l_rec_vs_prm  t_rec_vs_prm;
        l_coll_vs_prm t_coll_vs_prm;
    
        -- vs_soft_inst
        l_rec_vsi_prm  t_rec_vsi_prm;
        l_coll_vsi_prm t_coll_vsi_prm;
    
        -- vital_sign_unit_measure
        l_rec_vsum_prm  t_rec_vsum_prm;
        l_coll_vsum_prm t_coll_vsum_prm;
    
        -- Configs to return
        l_rec_vs_freq_config t_rec_vs_freq_config;
    
    BEGIN
    
        l_coll_vs_prm := pk_vitalsign_prm.tf_vs_prm(i_lang => i_lang, i_id_vital_sign => i_id_vital_sign);
        l_rec_vs_prm  := l_coll_vs_prm(1);
    
        l_coll_vsi_prm := pk_vitalsign_prm.tf_vsi_prm(i_lang          => i_lang,
                                                      i_id_vital_sign => i_id_vital_sign,
                                                      i_id_market     => i_id_market);
    
        WITH vsi_counter AS
         (SELECT t.id_unit_measure,
                 COUNT(t.id_unit_measure) over(PARTITION BY t.id_unit_measure) AS unit_mea_cnt,
                 t.color_grafh,
                 COUNT(t.color_grafh) over(PARTITION BY t.color_grafh) AS color_grafh_cnt,
                 t.color_text,
                 COUNT(t.color_text) over(PARTITION BY t.color_text) AS color_text_cnt,
                 t.box_type,
                 COUNT(t.box_type) over(PARTITION BY t.box_type) AS box_type_cnt
            FROM TABLE(l_coll_vsi_prm) t)
        SELECT t_rec_vsi_prm(id_vs_soft_inst   => NULL,
                             id_vital_sign     => NULL,
                             desc_vital_sign   => NULL,
                             desc_market       => NULL,
                             id_market         => NULL,
                             desc_software     => NULL,
                             id_software       => NULL,
                             version           => NULL,
                             desc_flg_view     => NULL,
                             flg_view          => NULL,
                             desc_unit_measure => NULL,
                             id_unit_measure   => MAX(c.id_unit_measure) keep(dense_rank LAST ORDER BY c.unit_mea_cnt),
                             color_grafh       => MAX(c.color_grafh) keep(dense_rank LAST ORDER BY c.color_grafh_cnt),
                             color_text        => MAX(c.color_text) keep(dense_rank LAST ORDER BY c.color_text_cnt),
                             box_type          => MAX(c.box_type) keep(dense_rank LAST ORDER BY c.box_type_cnt),
                             desc_box_type     => NULL,
                             rank              => NULL)
          INTO l_rec_vsi_prm
          FROM vsi_counter c;
    
        l_coll_vsum_prm := pk_vitalsign_prm.tf_vsum_prm(i_lang            => i_lang,
                                                        i_id_vital_sign   => i_id_vital_sign,
                                                        i_id_market       => i_id_market,
                                                        i_id_unit_measure => l_rec_vsi_prm.id_unit_measure);
        WITH vsum_counter AS
         (SELECT t.val_min,
                 COUNT(t.val_min) over(PARTITION BY t.val_min) AS val_min_cnt,
                 t.val_max,
                 COUNT(t.val_max) over(PARTITION BY t.val_max) AS val_max_cnt,
                 t.format_num,
                 COUNT(t.format_num) over(PARTITION BY t.format_num) AS format_num_cnt,
                 t.decimals,
                 COUNT(t.decimals) over(PARTITION BY t.decimals) AS decimals_cnt,
                 t.age_min,
                 COUNT(t.age_min) over(PARTITION BY t.age_min) AS age_min_cnt,
                 t.age_max,
                 COUNT(t.age_max) over(PARTITION BY t.age_max) AS age_max_cnt
            FROM TABLE(l_coll_vsum_prm) t)
        SELECT t_rec_vsum_prm(id_vital_sign_unit_measure => NULL,
                              id_vital_sign              => NULL,
                              desc_vital_sign            => NULL,
                              id_market                  => NULL,
                              desc_market                => NULL,
                              id_software                => NULL,
                              desc_software              => NULL,
                              version                    => NULL,
                              id_unit_measure            => NULL,
                              desc_unit_measure          => NULL,
                              val_min                    => MAX(c.val_min) keep(dense_rank LAST ORDER BY c.val_min_cnt),
                              val_max                    => MAX(c.val_max) keep(dense_rank LAST ORDER BY c.val_max_cnt),
                              format_num                 => MAX(c.format_num)
                                                            keep(dense_rank LAST ORDER BY c.format_num_cnt),
                              decimals                   => MAX(c.decimals) keep(dense_rank LAST ORDER BY c.decimals_cnt),
                              age_min                    => MAX(c.age_min) keep(dense_rank LAST ORDER BY c.age_min_cnt),
                              age_max                    => MAX(c.age_max) keep(dense_rank LAST ORDER BY c.age_max_cnt))
          INTO l_rec_vsum_prm
          FROM vsum_counter c;
    
        l_rec_vs_freq_config.intern_name_vital_sign := l_rec_vs_prm.intern_name_vital_sign;
        l_rec_vs_freq_config.flg_fill_type          := l_rec_vs_prm.flg_fill_type;
        l_rec_vs_freq_config.id_content_vs          := l_rec_vs_prm.id_content;
        l_rec_vs_freq_config.id_unit_measure        := l_rec_vsi_prm.id_unit_measure;
        l_rec_vs_freq_config.color_grafh            := l_rec_vsi_prm.color_grafh;
        l_rec_vs_freq_config.color_text             := l_rec_vsi_prm.color_text;
        l_rec_vs_freq_config.box_type               := l_rec_vsi_prm.box_type;
        l_rec_vs_freq_config.val_min                := l_rec_vsum_prm.val_min;
        l_rec_vs_freq_config.val_max                := l_rec_vsum_prm.val_max;
        l_rec_vs_freq_config.format_num             := l_rec_vsum_prm.decimals;
        l_rec_vs_freq_config.decimals               := l_rec_vsum_prm.decimals;
        l_rec_vs_freq_config.age_min                := l_rec_vsum_prm.age_min;
        l_rec_vs_freq_config.age_max                := l_rec_vsum_prm.age_max;
    
        RETURN l_rec_vs_freq_config;
    END;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_vitalsign_prm;
/
/
