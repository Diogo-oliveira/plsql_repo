/*-- Last Change Revision: $Rev: 1933271 $*/
/*-- Last Change by: $Author: vitor.sa $*/
/*-- Date of last change: $Date: 2020-01-27 16:42:43 +0000 (seg, 27 jan 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hhc_discharge IS

    -- Private variable declarations
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        l_tbl_result       t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_id_hhc_discharge epis_hhc_discharge.id_hhc_discharge%TYPE;
    BEGIN
    
        IF i_tbl_id_pk.exists(1)
        THEN
            l_id_hhc_discharge := i_tbl_id_pk(1);
        ELSE
            l_id_hhc_discharge := NULL;
        END IF;
    
        IF l_id_hhc_discharge IS NOT NULL -- if l_id_hhc_discharge is not null, it means it is an edition
           AND i_action = g_action_edit
        THEN
            l_tbl_result := get_edit_values(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_id_hhc_discharge => l_id_hhc_discharge,
                                            i_root_name        => i_root_name,
                                            o_error            => o_error);
        ELSIF i_action = pk_dyn_form_constant.get_submit_action()
        THEN
            -- if it gets here and action = submit, it means it is a final submit (OK button clicked) and no extra validation is needed
            -- also there is no need to return any data
            NULL;
        ELSE
            -- if it gets here, it means we ane initializing the HHC_REQUEST
            -- and it is needed to return the default values
        
            l_tbl_result := get_add_values(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_root_name => i_root_name,
                                           o_error     => o_error);
            NULL;
        END IF;
    
        RETURN l_tbl_result;
    
    END;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_edit_values
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_root_name        IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        l_tbl_result       t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_tbl_tree_configs t_dyn_tree_table;
    
    BEGIN
    
        l_tbl_tree_configs := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_patient        => NULL,
                                                      i_component_name => i_root_name,
                                                      i_action         => NULL);
        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => mkt.id_ds_cmpt_mkt_rel,
                                   id_ds_component    => mkt.id_ds_component_child,
                                   internal_name      => mkt.internal_name_child,
                                   VALUE              => CASE
                                                             WHEN hdt.flg_type = g_hhc_det_type_dt THEN
                                                              pk_date_utils.date_send_tsz(i_lang, ehdd.hhc_date_time, i_prof)
                                                             ELSE
                                                              ehdd.hhc_value
                                                         END,
                                   desc_value         => CASE
                                                             WHEN hdt.flg_type = g_hhc_det_type_dt THEN
                                                              (SELECT pk_date_utils.date_char_tsz(i_lang, ehdd.hhc_date_time, i_prof.institution, i_prof.software)
                                                                 FROM dual)
                                                             ELSE
                                                              ehdd.hhc_value
                                                         END,
                                   min_value => null,
                                   max_value => null,
                                   desc_clob          => ehdd.hhc_text,
                                   value_clob         => ehdd.hhc_value,
                                   id_unit_measure    => NULL,
                                   desc_unit_measure  => NULL,
                                   flg_validation     => 'Y',
                                   err_msg            => NULL,
                                   flg_event_type     => 'NA',
                                   flg_multi_status   => NULL,
                                   idx                => 1)
          BULK COLLECT
          INTO l_tbl_result
          FROM epis_hhc_disch_det ehdd
          JOIN hhc_det_type hdt
            ON ehdd.id_hhc_det_type = hdt.id_hhc_det_type
          JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                 t.internal_name_child, t.rank, t.id_ds_cmpt_mkt_rel, t.id_ds_component_child
                  FROM TABLE(l_tbl_tree_configs) t) mkt
            ON mkt.internal_name_child = hdt.internal_name
         WHERE ehdd.id_hhc_discharge = i_id_hhc_discharge
         ORDER BY mkt.rank;
    
        RETURN l_tbl_result;
    
    END get_edit_values;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_add_values
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        l_tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    BEGIN
    
        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                  id_ds_component    => t.id_ds_component_child,
                                  internal_name      => t.internal_name_child,
                                  VALUE              => t.value,
                                  min_value => null,
                                  max_value => null,
                                  value_clob         => NULL,
                                  desc_value         => t.value,
                                  desc_clob          => NULL,
                                  id_unit_measure    => NULL,
                                  desc_unit_measure  => NULL,
                                  flg_validation     => 'Y',
                                  err_msg            => NULL,
                                  flg_event_type     => t.flg_event_type,
                                  flg_multi_status   => NULL,
                                  idx                => 1)
          BULK COLLECT
          INTO l_tbl_result
          FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                       dc.id_ds_component_child,
                       dc.internal_name_child,
                       CASE dc.internal_name_child
                           WHEN g_ds_hhc_discharge_goals THEN
                            'M'
                           WHEN g_ds_hhc_discharge_reason THEN
                            'C'
                           WHEN g_ds_hhc_pat_continue_under THEN
                            'N'
                       END VALUE,
                       dc.flg_event_type
                  FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_patient        => NULL,
                                                     i_component_name => i_root_name,
                                                     i_action         => NULL)) dc) t
         WHERE t.value IS NOT NULL;
    
        RETURN l_tbl_result;
    
    END get_add_values;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_discharge_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_disch_list      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_disch_list FOR
            SELECT ehd.id_hhc_discharge,
                   pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => ehd.id_prof_discharge) prof_discharge,
                   pk_sysdomain.get_domain(i_code_dom => g_sd_hhc_discharge_reason,
                                           i_val      => ehdd.hhc_value,
                                           i_lang     => i_lang) AS reason_discharge_desc,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang => i_lang,
                                                      i_date => ehd.dt_discharge,
                                                      i_inst => i_prof.institution,
                                                      i_soft => i_prof.software) date_time,
                   pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_display_type => pk_alert_constant.g_display_type_icon,
                                                        i_flg_state    => ehd.flg_status,
                                                        i_value_icon   => 'EPIS_HHC_DISCHARGE.FLG_STATUS') icon_str,
                   ehd.flg_status
              FROM epis_hhc_discharge ehd
              JOIN epis_hhc_req ehr
                ON ehr.id_epis_hhc_req = ehd.id_epis_hhc_req
              LEFT JOIN epis_hhc_disch_det ehdd
                ON ehdd.id_hhc_discharge = ehd.id_hhc_discharge
               AND ehdd.id_hhc_det_type = g_id_disch_reason_det_type
             WHERE ehr.id_epis_hhc_req = i_id_epis_hhc_req
             ORDER BY ehd.dt_discharge DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCHARGE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_disch_list);
            RETURN FALSE;
    END get_discharge_list;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_actions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        o_actions          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_actions        t_coll_action;
        l_hhc_flg_status epis_hhc_discharge.flg_status%TYPE;
    BEGIN
        SELECT ehd.flg_status
          INTO l_hhc_flg_status
          FROM epis_hhc_discharge ehd
         WHERE ehd.id_hhc_discharge = i_id_hhc_discharge;
    
        l_actions := pk_action.tf_get_actions(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_subject    => 'HHC_DISCHARGE',
                                              i_from_state => NULL);
    
        OPEN o_actions FOR
            SELECT *
              FROM (SELECT /*+opt_estimate (table t rows=1)*/
                     t.id_action,
                     t.id_parent,
                     t.level_nr AS "LEVEL",
                     t.from_state,
                     t.to_state,
                     t.desc_action,
                     t.icon,
                     t.flg_default,
                     CASE
                          WHEN t.action = 'HHC_DISCH_ADD' THEN
                           pk_alert_constant.g_inactive
                          WHEN t.action IN ('HHC_DISCH_EDIT') THEN
                           CASE
                               WHEN l_hhc_flg_status = g_disch_status_active THEN
                                pk_alert_constant.g_active
                               ELSE
                                pk_alert_constant.g_inactive
                           END
                          ELSE
                           pk_alert_constant.g_inactive
                      END flg_active,
                     t.action
                      FROM TABLE(CAST(l_actions AS t_coll_action)) t) t
             WHERE t.flg_active = pk_alert_constant.g_active
             ORDER BY t.desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTIONS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tab_dd_data_rank      t_tab_dd_data_rank := t_tab_dd_data_rank();
        l_tab_dd_data_rank_temp t_tab_dd_data_rank := t_tab_dd_data_rank();
        l_rec_dd_data_rank      t_rec_dd_data_rank;
    
        l_flg_status        epis_hhc_discharge.flg_status%TYPE;
        l_id_prof_discharge epis_hhc_discharge.id_prof_discharge%TYPE;
        l_dt_discharge      epis_hhc_discharge.dt_discharge%TYPE;
        l_id_cancel_reason  epis_hhc_discharge.id_cancel_reason%TYPE;
        l_cancel_notes      epis_hhc_discharge.cancel_notes%TYPE;
    
        l_hist_counter NUMBER := 0;
    
        l_val      VARCHAR2(4000 CHAR);
        l_val_list table_varchar := table_varchar();
    
        --------------------------------------------------------------------------------------
        FUNCTION get_hhd_disch_det_val
        (
            i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
            i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE,
            i_flg_type         IN hhc_det_type.flg_type%TYPE
        ) RETURN VARCHAR2 IS
            l_ret VARCHAR2(4000 CHAR);
        BEGIN
            SELECT CASE
                       WHEN i_flg_type = g_hhc_det_type_dt THEN
                        pk_date_utils.date_send_tsz(i_lang, ehdd.hhc_date_time, i_prof)
                       ELSE
                        ehdd.hhc_value
                   END
              INTO l_ret
              FROM epis_hhc_disch_det ehdd
             WHERE ehdd.id_hhc_discharge = i_id_hhc_discharge
               AND ehdd.id_hhc_det_type = i_id_hhc_det_type
               AND rownum = 1;
        
            RETURN l_ret;
        END get_hhd_disch_det_val;
    
        --------------------------------------------------------------------------------------
        FUNCTION get_hhd_disch_det_list
        (
            i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
            i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE
        ) RETURN table_varchar IS
            l_ret table_varchar := table_varchar();
        BEGIN
            SELECT pk_sysdomain.get_domain(i_code_dom => hdt.type_name, i_val => ehdd.hhc_value, i_lang => i_lang)
              BULK COLLECT
              INTO l_ret
              FROM epis_hhc_disch_det ehdd
              JOIN hhc_det_type hdt
                ON hdt.id_hhc_det_type = ehdd.id_hhc_det_type
             WHERE ehdd.id_hhc_discharge = i_id_hhc_discharge
               AND ehdd.id_hhc_det_type = i_id_hhc_det_type
             ORDER BY ehdd.id_hhc_disch_det;
        
            RETURN l_ret;
        END get_hhd_disch_det_list;
    
    BEGIN
        ------------------------------------------------------------------
        -- obtain some data from hhc_discharge
        SELECT ehd.flg_status,
               CASE
                    WHEN ehd.flg_status = g_disch_status_active THEN
                     ehd.id_prof_discharge
                    ELSE
                     ehd.id_prof_cancel
                END id_prof,
               CASE
                    WHEN ehd.flg_status = g_disch_status_active THEN
                     ehd.dt_discharge
                    ELSE
                     ehd.dt_cancel
                END dt,
               id_cancel_reason,
               cancel_notes
          INTO l_flg_status, l_id_prof_discharge, l_dt_discharge, l_id_cancel_reason, l_cancel_notes
          FROM epis_hhc_discharge ehd
         WHERE ehd.id_hhc_discharge = i_id_hhc_discharge;
    
        ------------------------------------------------------------------
        -- add status to detail
        l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
        l_rec_dd_data_rank.descr        := pk_sysdomain.get_domain(i_code_dom => 'EPIS_HHC_DISCHARGE.FLG_STATUS',
                                                                   i_val      => l_flg_status,
                                                                   i_lang     => i_lang);
        l_rec_dd_data_rank.type         := g_det_level_1;
        l_rec_dd_data_rank.rank_content := 0;
        l_tab_dd_data_rank.extend;
        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
    
        ------------------------------------------------------------------
        -- add discharge detail
        FOR l_rec IN (SELECT pk_message.get_message(i_lang, ds.code_component_child) ds_desc,
                             --ehdd.hhc_value,
                             hdt.flg_type,
                             hdt.id_hhc_det_type,
                             hdt.type_name,
                             ds.flg_component_type_child,
                             rank
                        FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_patient        => NULL,
                                                           i_component_name => 'DS_HHC_DISCHARGE',
                                                           i_action         => NULL)) ds
                        LEFT JOIN hhc_det_type hdt
                          ON hdt.internal_name = ds.internal_name_child
                       WHERE ds.flg_component_type_child != 'R' -- root
                       ORDER BY id_ds_cmpt_mkt_rel)
        LOOP
            l_rec_dd_data_rank := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
            l_val              := NULL;
            l_val_list         := table_varchar();
        
            IF l_rec.flg_component_type_child = 'N' -- if its a node
            THEN
                /*l_rec_dd_data_rank.type         := g_det_white_line;
                l_rec_dd_data_rank.rank_content := l_rec.rank - 1;
                l_tab_dd_data_rank.extend;
                l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;*/
            
                l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
                l_rec_dd_data_rank.descr        := l_rec.ds_desc;
                l_rec_dd_data_rank.type         := g_det_level_2;
                l_rec_dd_data_rank.rank_content := l_rec.rank;
            
                l_tab_dd_data_rank.extend;
                l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
            ELSE
                -- if its not a node
                IF l_rec.flg_type IN ('T', 'DT') -- if det type is Text and has a value then add it to the detail
                THEN
                    l_val := get_hhd_disch_det_val(i_id_hhc_discharge, l_rec.id_hhc_det_type, l_rec.flg_type);
                    IF l_val IS NOT NULL
                    THEN
                        l_rec_dd_data_rank.descr        := l_rec.ds_desc || ':';
                        l_rec_dd_data_rank.val := CASE
                                                      WHEN l_rec.flg_type = g_hhc_det_type_dt THEN
                                                       pk_date_utils.date_char_tsz(i_lang,
                                                                                   pk_date_utils.get_string_tstz(i_lang, i_prof, l_val, NULL),
                                                                                   i_prof.institution,
                                                                                   i_prof.software)
                                                      ELSE
                                                       l_val
                                                  END;
                        l_rec_dd_data_rank.type         := g_det_level_3b;
                        l_rec_dd_data_rank.rank_content := l_rec.rank;
                    
                        l_tab_dd_data_rank.extend;
                        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
                    END IF;
                ELSIF l_rec.flg_type IN ('D') -- if det type is Data and has a value then
                THEN
                    l_val_list := get_hhd_disch_det_list(i_id_hhc_discharge, l_rec.id_hhc_det_type);
                    IF l_val_list.exists(1)
                    THEN
                        l_rec_dd_data_rank.descr := l_rec.ds_desc || ':';
                        IF l_val_list.count = 1 -- if only one record in the list, add it as a normal value
                        THEN
                            l_rec_dd_data_rank.val := l_val_list(1);
                        END IF;
                        l_rec_dd_data_rank.type         := g_det_level_3b;
                        l_rec_dd_data_rank.rank_content := l_rec.rank;
                    
                        l_tab_dd_data_rank.extend;
                        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
                    
                        IF l_val_list.count > 1 -- if list has more than one record, then add all the records in different lines
                        THEN
                            FOR i IN l_val_list.first .. l_val_list.last
                            LOOP
                                l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
                                l_rec_dd_data_rank.val          := l_val_list(i);
                                l_rec_dd_data_rank.type         := g_det_level_4;
                                l_rec_dd_data_rank.rank_content := l_rec.rank + i;
                            
                                l_tab_dd_data_rank.extend;
                                l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
                            END LOOP;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        ------------------------------------------------------------------
        -- add cancel information
        IF l_flg_status = g_disch_status_canceled
        THEN
            l_tab_dd_data_rank_temp := get_detail_cancel(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_cancel_reason => l_id_cancel_reason,
                                                         i_cancel_notes     => l_cancel_notes,
                                                         o_error            => o_error);
            IF l_tab_dd_data_rank_temp.exists(1)
            THEN
                l_tab_dd_data_rank := l_tab_dd_data_rank MULTISET UNION l_tab_dd_data_rank_temp;
            END IF;
        END IF;
    
        ------------------------------------------------------------------
        -- add professional to detail
        SELECT COUNT(1)
          INTO l_hist_counter
          FROM epis_hhc_discharge_h ehdh
         WHERE ehdh.id_hhc_discharge = i_id_hhc_discharge;
    
        l_tab_dd_data_rank_temp := t_tab_dd_data_rank();
        l_tab_dd_data_rank_temp := get_detail_doc_prof(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_prof_discharge => l_id_prof_discharge,
                                                       i_dt_discharge      => l_dt_discharge,
                                                       i_flg_use_upd       => CASE
                                                                                  WHEN l_hist_counter > 1 THEN
                                                                                   pk_alert_constant.g_yes
                                                                                  ELSE
                                                                                   pk_alert_constant.g_no
                                                                              END,
                                                       o_error             => o_error);
        IF l_tab_dd_data_rank_temp.exists(1)
        THEN
            l_tab_dd_data_rank := l_tab_dd_data_rank MULTISET UNION l_tab_dd_data_rank_temp;
        END IF;
    
        OPEN o_detail FOR
            SELECT t.descr,
                   t.val,
                   t.type                 flg_type,
                   pk_alert_constant.g_no flg_html,
                   NULL                   val_clob,
                   pk_alert_constant.g_no flg_clob
              FROM TABLE(l_tab_dd_data_rank) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DETAIL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_detail;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_detail_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tab_dd_data_rank      t_tab_dd_data_rank := t_tab_dd_data_rank();
        l_tab_dd_data_rank_temp t_tab_dd_data_rank := t_tab_dd_data_rank();
    
        l_min_id_goup epis_hhc_discharge_h.id_group%TYPE;
    
    BEGIN
        SELECT MIN(id_group)
          INTO l_min_id_goup
          FROM epis_hhc_discharge_h ehd
         WHERE ehd.id_hhc_discharge = i_id_hhc_discharge;
    
        FOR l_rec IN (SELECT ehd.id_hhc_discharge, ehd.id_group
                        FROM epis_hhc_discharge_h ehd
                       WHERE ehd.id_hhc_discharge = i_id_hhc_discharge
                       ORDER BY ehd.id_group DESC)
        LOOP
            l_tab_dd_data_rank_temp := t_tab_dd_data_rank();
            l_tab_dd_data_rank_temp := get_detail_hist_group(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_id_hhc_discharge => l_rec.id_hhc_discharge,
                                                             i_id_group         => l_rec.id_group,
                                                             i_first_element    => CASE
                                                                                       WHEN l_rec.id_group = l_min_id_goup THEN
                                                                                        pk_alert_constant.g_yes
                                                                                       ELSE
                                                                                        pk_alert_constant.g_no
                                                                                   END,
                                                             o_error            => o_error);
            IF l_tab_dd_data_rank_temp.exists(1)
            THEN
                l_tab_dd_data_rank := l_tab_dd_data_rank MULTISET UNION l_tab_dd_data_rank_temp;
            END IF;
        END LOOP;
    
        OPEN o_detail FOR
            SELECT t.descr,
                   t.val,
                   t.type                 flg_type,
                   pk_alert_constant.g_no flg_html,
                   NULL                   val_clob,
                   pk_alert_constant.g_no flg_clob
              FROM TABLE(l_tab_dd_data_rank) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DETAIL_HIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_detail_hist;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_detail_hist_group
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_group         IN epis_hhc_discharge_h.id_group%TYPE,
        i_first_element    IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN t_tab_dd_data_rank IS
    
        l_tab_dd_data_rank      t_tab_dd_data_rank := t_tab_dd_data_rank();
        l_tab_dd_data_rank_temp t_tab_dd_data_rank := t_tab_dd_data_rank();
        l_rec_dd_data_rank      t_rec_dd_data_rank;
    
        l_flg_status        epis_hhc_discharge.flg_status%TYPE;
        l_id_prof_discharge epis_hhc_discharge.id_prof_discharge%TYPE;
        l_dt_discharge      epis_hhc_discharge.dt_discharge%TYPE;
        l_id_cancel_reason  epis_hhc_discharge.id_cancel_reason%TYPE;
        l_cancel_notes      epis_hhc_discharge.cancel_notes%TYPE;
    
        l_internal_name_parent_list table_varchar := table_varchar();
        l_val_diff_new              table_varchar := table_varchar();
        l_val_diff_delete           table_varchar := table_varchar();
    
        l_new_msg     VARCHAR2(100 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_code_mess => 'COMMON_M152');
        l_updated_msg VARCHAR2(100 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_code_mess => 'COMMON_M153');
        l_deleted_msg VARCHAR2(100 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_code_mess => 'COMMON_M154');
    
        --------------------------------------------------------------------------------------
        FUNCTION get_internal_name_parent
        (
            i_id_hhc_discharge epis_hhc_discharge.id_hhc_discharge%TYPE,
            i_id_group         epis_hhc_discharge_h.id_group%TYPE
        ) RETURN table_varchar IS
            l_ret table_varchar := table_varchar();
        BEGIN
            SELECT DISTINCT pn.internal_name_parent
              BULK COLLECT
              INTO l_ret
              FROM (SELECT l.val,
                           lag(l.val) over(PARTITION BY id_hhc_det_type ORDER BY id_group) AS val_old,
                           internal_name,
                           id_group
                      FROM (SELECT listagg(hhc_value, ',') within GROUP(ORDER BY ehdd.id_group) val,
                                   hdt.internal_name,
                                   ehdd.id_group,
                                   ehdd.id_hhc_det_type
                              FROM epis_hhc_disch_det_h ehdd
                              JOIN hhc_det_type hdt
                                ON hdt.id_hhc_det_type = ehdd.id_hhc_det_type
                             WHERE ehdd.id_hhc_discharge = i_id_hhc_discharge
                             GROUP BY ehdd.id_group, hdt.id_hhc_det_type, hdt.internal_name, ehdd.id_hhc_det_type) l) v
              JOIN (SELECT internal_name_child, internal_name_parent
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => 'DS_HHC_DISCHARGE',
                                                         i_action         => NULL)) ds) pn
                ON pn.internal_name_child = v.internal_name
             WHERE nvl(val, '_N') != nvl(val_old, '_N')
               AND id_group = i_id_group;
        
            RETURN l_ret;
        END get_internal_name_parent;
    BEGIN
        SELECT ehd.flg_status, --ehd.id_prof_discharge, ehd.dt_discharge, 
               CASE
                    WHEN ehd.flg_status = g_disch_status_active THEN
                     ehd.id_prof_discharge
                    ELSE
                     ehd.id_prof_cancel
                END id_prof,
               CASE
                    WHEN ehd.flg_status = g_disch_status_active THEN
                     ehd.dt_discharge
                    ELSE
                     ehd.dt_cancel
                END dt,
               ehd.id_cancel_reason,
               ehd.cancel_notes
          INTO l_flg_status, l_id_prof_discharge, l_dt_discharge, l_id_cancel_reason, l_cancel_notes
          FROM epis_hhc_discharge_h ehd
         WHERE ehd.id_hhc_discharge = i_id_hhc_discharge
           AND ehd.id_group = i_id_group;
    
        ------------------------------------------------------------------
        -- add status to detail
        l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
        l_rec_dd_data_rank.descr        := pk_sysdomain.get_domain(i_code_dom => 'EPIS_HHC_DISCHARGE.FLG_STATUS',
                                                                   i_val      => l_flg_status,
                                                                   i_lang     => 8);
        l_rec_dd_data_rank.type         := g_det_level_1;
        l_rec_dd_data_rank.rank_content := 0;
        l_tab_dd_data_rank.extend;
        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
    
        ------------------------------------------------------------------
        l_internal_name_parent_list := get_internal_name_parent(i_id_hhc_discharge, i_id_group);
    
        ------------------------------------------------------------------
        FOR l_rec IN (SELECT pk_message.get_message(8, pn.code_component_child) ds_desc,
                             pk_utils.str_split_c(v.val) vall,
                             pk_utils.str_split_c(v.val_old) vall_old,
                             v.val,
                             v.val_old,
                             v.flg_type,
                             v.type_name,
                             v.id_hhc_det_type,
                             pn.flg_component_type_child,
                             pn.rank
                        FROM (SELECT *
                                FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_patient        => NULL,
                                                                   i_component_name => 'DS_HHC_DISCHARGE',
                                                                   i_action         => NULL)) ds) pn
                        LEFT JOIN (SELECT l.val,
                                         lag(l.val) over(PARTITION BY id_hhc_det_type ORDER BY id_group) AS val_old,
                                         id_group,
                                         id_hhc_det_type,
                                         internal_name,
                                         flg_type,
                                         type_name
                                    FROM (SELECT CASE
                                                      WHEN hdt.flg_type = g_hhc_det_type_dt THEN
                                                       listagg(pk_date_utils.date_send_tsz(i_lang,
                                                                                           ehdd.hhc_date_time,
                                                                                           i_prof),
                                                               ',') within GROUP(ORDER BY ehdd.id_group)
                                                      ELSE
                                                       listagg(ehdd.hhc_value, ',') within GROUP(ORDER BY ehdd.id_group)
                                                  END val,
                                                 ehdd.id_group,
                                                 hdt.id_hhc_det_type,
                                                 hdt.internal_name,
                                                 hdt.flg_type,
                                                 hdt.type_name
                                            FROM epis_hhc_disch_det_h ehdd
                                            JOIN hhc_det_type hdt
                                              ON hdt.id_hhc_det_type = ehdd.id_hhc_det_type
                                           WHERE ehdd.id_hhc_discharge = i_id_hhc_discharge
                                           GROUP BY ehdd.id_group,
                                                    hdt.id_hhc_det_type,
                                                    hdt.internal_name,
                                                    hdt.flg_type,
                                                    hdt.type_name) l
                                   ORDER BY id_group DESC, id_hhc_det_type) v
                          ON v.internal_name = pn.internal_name_child
                       WHERE (nvl(val, '_N') != nvl(val_old, '_N') AND id_group = i_id_group)
                          OR pn.internal_name_child IN
                             (SELECT column_value internal_name_child
                                FROM TABLE(l_internal_name_parent_list))
                       ORDER BY pn.rank)
        LOOP
            l_rec_dd_data_rank := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
        
            IF l_rec.flg_component_type_child = 'N' -- if its a node
            THEN
                /*l_rec_dd_data_rank.type         := g_det_white_line;
                l_rec_dd_data_rank.rank_content := l_rec.rank - 1;
                l_tab_dd_data_rank.extend;
                l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;*/
            
                l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
                l_rec_dd_data_rank.descr        := l_rec.ds_desc;
                l_rec_dd_data_rank.type         := g_det_level_2;
                l_rec_dd_data_rank.rank_content := l_rec.rank;
            
                l_tab_dd_data_rank.extend;
                l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
            ELSE
                IF l_rec.flg_type IN ('D') -- 
                THEN
                    l_val_diff_new    := table_varchar();
                    l_val_diff_delete := table_varchar();
                
                    l_val_diff_new    := l_rec.vall MULTISET except l_rec.vall_old; -- elements are in the l_val but not in the l_val_old
                    l_val_diff_delete := l_rec.vall_old MULTISET except l_rec.vall; -- elements are in the l_val_old but not in the l_val
                
                    ---------------------------- for new elements
                    IF l_val_diff_new.exists(1)
                       AND l_val_diff_new(1) IS NOT NULL
                    THEN
                        IF i_first_element = pk_alert_constant.g_yes
                        THEN
                            l_rec_dd_data_rank.descr := l_rec.ds_desc || ':';
                            l_rec_dd_data_rank.type  := g_det_level_3b;
                        ELSE
                            l_rec_dd_data_rank.descr := l_rec.ds_desc || l_new_msg || ':'; -- ver questão do 1º registo
                            l_rec_dd_data_rank.type  := g_det_level_3n;
                        END IF;
                        IF l_val_diff_new.count = 1
                        THEN
                            l_rec_dd_data_rank.val := pk_sysdomain.get_domain(i_code_dom => l_rec.type_name,
                                                                              i_val      => l_val_diff_new(1),
                                                                              i_lang     => i_lang);
                        END IF;
                        l_rec_dd_data_rank.rank_content := l_rec.rank;
                    
                        l_tab_dd_data_rank.extend;
                        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
                    
                        IF l_val_diff_new.count > 1 -- if list has more than one record, then add all the records in different lines
                        THEN
                            FOR i IN l_val_diff_new.first .. l_val_diff_new.last
                            LOOP
                                l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
                                l_rec_dd_data_rank.val          := pk_sysdomain.get_domain(i_code_dom => l_rec.type_name,
                                                                                           i_val      => l_val_diff_new(i),
                                                                                           i_lang     => i_lang);
                                l_rec_dd_data_rank.type := CASE
                                                               WHEN i_first_element = pk_alert_constant.g_yes THEN
                                                                g_det_level_4
                                                               ELSE
                                                                g_det_level_4n
                                                           END;
                                l_rec_dd_data_rank.rank_content := l_rec.rank + i;
                            
                                l_tab_dd_data_rank.extend;
                                l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
                            END LOOP;
                        END IF;
                    END IF;
                    ---------------------------- for deleted elements
                    l_rec_dd_data_rank := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
                    IF l_val_diff_delete.exists(1)
                       AND l_val_diff_delete(1) IS NOT NULL
                    THEN
                        IF i_first_element = pk_alert_constant.g_yes
                        THEN
                            l_rec_dd_data_rank.descr := l_rec.ds_desc || ':';
                            l_rec_dd_data_rank.type  := g_det_level_3b;
                        ELSE
                            l_rec_dd_data_rank.descr := l_rec.ds_desc || l_deleted_msg || ':';
                            l_rec_dd_data_rank.type  := g_det_level_3n;
                        END IF;
                        IF l_val_diff_delete.count = 1 -- if only one record in the list, add it as a normal value
                        THEN
                            l_rec_dd_data_rank.val := pk_sysdomain.get_domain(i_code_dom => l_rec.type_name,
                                                                              i_val      => l_val_diff_delete(1),
                                                                              i_lang     => i_lang);
                        END IF;
                        l_rec_dd_data_rank.rank_content := l_rec.rank;
                    
                        l_tab_dd_data_rank.extend;
                        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
                    
                        IF l_val_diff_delete.count > 1 -- if list has more than one record, then add all the records in different lines
                        THEN
                            FOR i IN l_val_diff_delete.first .. l_val_diff_delete.last
                            LOOP
                                l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
                                l_rec_dd_data_rank.val          := pk_sysdomain.get_domain(i_code_dom => l_rec.type_name,
                                                                                           i_val      => l_val_diff_delete(i),
                                                                                           i_lang     => i_lang);
                                l_rec_dd_data_rank.type := CASE
                                                               WHEN i_first_element = pk_alert_constant.g_yes THEN
                                                                g_det_level_4
                                                               ELSE
                                                                g_det_level_4n
                                                           END;
                                l_rec_dd_data_rank.rank_content := l_rec.rank + i;
                            
                                l_tab_dd_data_rank.extend;
                                l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
                            END LOOP;
                        END IF;
                    END IF;
                    ----------------------------
                ELSIF l_rec.flg_type IN ('T', 'DT') -- if det type is Text and has a value then add it to the detail
                THEN
                    IF l_rec.val IS NOT NULL
                       OR l_rec.val_old IS NOT NULL
                    THEN
                        IF l_rec.flg_type = g_hhc_det_type_dt
                        THEN
                            l_rec.val     := pk_date_utils.date_char_tsz(i_lang,
                                                                         pk_date_utils.get_string_tstz(i_lang,
                                                                                                       i_prof,
                                                                                                       l_rec.val,
                                                                                                       NULL),
                                                                         i_prof.institution,
                                                                         i_prof.software);
                            l_rec.val_old := pk_date_utils.date_char_tsz(i_lang,
                                                                         pk_date_utils.get_string_tstz(i_lang,
                                                                                                       i_prof,
                                                                                                       l_rec.val_old,
                                                                                                       NULL),
                                                                         i_prof.institution,
                                                                         i_prof.software);
                        END IF;
                    
                        IF i_first_element = pk_alert_constant.g_yes
                        THEN
                            l_rec_dd_data_rank.descr := l_rec.ds_desc || ':';
                            l_rec_dd_data_rank.type  := g_det_level_3b;
                            l_rec_dd_data_rank.val   := l_rec.val;
                        ELSIF l_rec.val_old IS NULL
                        THEN
                            l_rec_dd_data_rank.descr := l_rec.ds_desc || l_new_msg || ':';
                            l_rec_dd_data_rank.type  := g_det_level_3n;
                            l_rec_dd_data_rank.val   := l_rec.val;
                        ELSIF l_rec.val IS NULL
                        THEN
                            l_rec_dd_data_rank.descr := l_rec.ds_desc || l_deleted_msg || ':';
                            l_rec_dd_data_rank.type  := g_det_level_3n;
                            l_rec_dd_data_rank.val   := l_rec.val_old;
                        ELSE
                            l_rec_dd_data_rank.descr := l_rec.ds_desc || l_updated_msg || ':';
                            l_rec_dd_data_rank.type  := g_det_level_3n;
                            l_rec_dd_data_rank.val   := l_rec.val;
                        END IF;
                    
                        l_rec_dd_data_rank.rank_content := l_rec.rank;
                    
                        l_tab_dd_data_rank.extend;
                        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        ------------------------------------------------------------------
        -- add cancel information
        IF l_flg_status = g_disch_status_canceled
        THEN
            l_tab_dd_data_rank_temp := get_detail_cancel(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_cancel_reason => l_id_cancel_reason,
                                                         i_cancel_notes     => l_cancel_notes,
                                                         o_error            => o_error);
            IF l_tab_dd_data_rank_temp.exists(1)
            THEN
                l_tab_dd_data_rank := l_tab_dd_data_rank MULTISET UNION l_tab_dd_data_rank_temp;
            END IF;
        END IF;
    
        ------------------------------------------------------------------
        -- add professional to detail
        l_tab_dd_data_rank_temp := t_tab_dd_data_rank();
        l_tab_dd_data_rank_temp := get_detail_doc_prof(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_prof_discharge => l_id_prof_discharge,
                                                       i_dt_discharge      => l_dt_discharge,
                                                       o_error             => o_error);
        IF l_tab_dd_data_rank_temp.exists(1)
        THEN
            l_tab_dd_data_rank := l_tab_dd_data_rank MULTISET UNION l_tab_dd_data_rank_temp;
        END IF;
    
        ------------------------------------------------------------------
        -- add white line in the end
        l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
        l_rec_dd_data_rank.type         := g_det_white_line;
        l_rec_dd_data_rank.rank_content := 1001;
        l_tab_dd_data_rank.extend;
        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
    
        RETURN l_tab_dd_data_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DETAIL_HIST_GROUP',
                                              o_error    => o_error);
    END get_detail_hist_group;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_detail_cancel
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cancel_reason IN epis_hhc_discharge.id_cancel_reason%TYPE,
        i_cancel_notes     IN epis_hhc_discharge.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN t_tab_dd_data_rank IS
    
        l_tab_dd_data_rank t_tab_dd_data_rank := t_tab_dd_data_rank();
        l_rec_dd_data_rank t_rec_dd_data_rank;
    
    BEGIN
        ------------------------------------------------------------------
        -- add cancel information
        /*l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
        l_rec_dd_data_rank.type         := g_det_white_line;
        l_rec_dd_data_rank.rank_content := 500;
        l_tab_dd_data_rank.extend;
        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;*/
        ----
        l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
        l_rec_dd_data_rank.descr        := pk_message.get_message(i_lang, 'CANCEL_SCREEN_LABELS_M001');
        l_rec_dd_data_rank.type         := g_det_level_2;
        l_rec_dd_data_rank.rank_content := 510;
        l_tab_dd_data_rank.extend;
        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
        ----
        l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
        l_rec_dd_data_rank.descr        := pk_message.get_message(i_lang, 'CANCEL_SCREEN_LABELS_T003');
        l_rec_dd_data_rank.val          := pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                   i_prof             => i_prof,
                                                                                   i_id_cancel_reason => i_id_cancel_reason);
        l_rec_dd_data_rank.type         := g_det_level_3b;
        l_rec_dd_data_rank.rank_content := 520;
        l_tab_dd_data_rank.extend;
        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
        ----
        IF i_cancel_notes IS NOT NULL
        THEN
            l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
            l_rec_dd_data_rank.descr        := pk_message.get_message(i_lang, 'CANCEL_SCREEN_LABELS_T004');
            l_rec_dd_data_rank.val          := to_char(i_cancel_notes);
            l_rec_dd_data_rank.type         := g_det_level_3b;
            l_rec_dd_data_rank.rank_content := 530;
            l_tab_dd_data_rank.extend;
            l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
        END IF;
    
        RETURN l_tab_dd_data_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DETAIL_CANCEL',
                                              o_error    => o_error);
    END get_detail_cancel;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_detail_doc_prof
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_discharge IN epis_hhc_discharge.id_prof_discharge%TYPE,
        i_dt_discharge      IN epis_hhc_discharge.dt_discharge%TYPE,
        i_flg_use_upd       IN VARCHAR DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN t_tab_dd_data_rank IS
    
        l_tab_dd_data_rank t_tab_dd_data_rank := t_tab_dd_data_rank();
        l_rec_dd_data_rank t_rec_dd_data_rank;
    
    BEGIN
        ------------------------------------------------------------------
        -- add cancel information
        l_rec_dd_data_rank              := t_rec_dd_data_rank(NULL, NULL, NULL, NULL, NULL);
        l_rec_dd_data_rank.descr := CASE
                                        WHEN i_flg_use_upd = pk_alert_constant.g_yes THEN
                                         pk_message.get_message(i_lang, 'COMMON_M127')
                                        ELSE
                                         pk_message.get_message(i_lang, 'COMMON_M107')
                                    END;
        l_rec_dd_data_rank.val          := pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                                              i_prof                => i_prof,
                                                                              i_id_episode          => NULL,
                                                                              i_date_last_change    => NULL,
                                                                              i_id_prof_last_change => i_id_prof_discharge) ||
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       i_dt_discharge,
                                                                       i_prof.institution,
                                                                       i_prof.software);
        l_rec_dd_data_rank.type         := g_det_level_prof;
        l_rec_dd_data_rank.rank_content := 1000;
        l_tab_dd_data_rank.extend;
        l_tab_dd_data_rank(l_tab_dd_data_rank.last) := l_rec_dd_data_rank;
    
        RETURN l_tab_dd_data_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_detail_doc_prof',
                                              o_error    => o_error);
    END get_detail_doc_prof;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_report_data
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_REPORT_DATA';
    
        l_id_hhc_discharge epis_hhc_discharge.id_hhc_discharge%TYPE;
    BEGIN
        -- do episódio agregador só há (no máximo) um request activo, e desse request activo só há (no máximo) um discharge activo
        --------------------------------------------------------------
        SELECT id_hhc_discharge
          INTO l_id_hhc_discharge
          FROM (SELECT rownum rn, ehd.id_hhc_discharge
                  FROM epis_hhc_req ehr
                  JOIN epis_hhc_discharge ehd
                    ON ehd.id_epis_hhc_req = ehr.id_epis_hhc_req
                 WHERE ehr.id_epis_hhc_req = i_id_epis_hhc_req
                   AND ehd.flg_status = g_disch_status_active
                 ORDER BY ehd.dt_discharge DESC)
         WHERE rn = 1;
    
        --------------------------------------------------------------
        RETURN get_report_data(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_hhc_discharge => l_id_hhc_discharge,
                               o_detail           => o_detail,
                               o_error            => o_error);
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_detail);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REPORT_DATA',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_report_data;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_report_data
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_REPORT_DATA';
    
        l_id_epis_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        l_id_epis_hhc     epis_hhc_req.id_epis_hhc%TYPE;
    
        l_first_dt schedule_outp.dt_target_tstz%TYPE;
        l_last_dt  schedule_outp.dt_target_tstz%TYPE;
    BEGIN
        --------------------------------------------------------------
        SELECT ehr.id_epis_hhc_req, ehr.id_epis_hhc
          INTO l_id_epis_hhc_req, l_id_epis_hhc
          FROM epis_hhc_discharge ehd
          JOIN epis_hhc_req ehr
            ON ehr.id_epis_hhc_req = ehd.id_epis_hhc_req
         WHERE ehd.id_hhc_discharge = i_id_hhc_discharge;
    
        --------------------------------------------------------------
        IF NOT pk_hhc_core.get_visit_information(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_epis_hhc_req => l_id_epis_hhc_req,
                                                 o_first_dt        => l_first_dt,
                                                 o_last_dt         => l_last_dt,
                                                 o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --------------------------------------------------------------    
        OPEN o_detail FOR
            SELECT pk_date_utils.date_send_tsz(i_lang => i_lang,
                                               i_date => pk_hhc_core.get_hhc_dt_admission(i_lang       => i_lang,
                                                                                          i_prof       => i_prof,
                                                                                          i_id_episode => l_id_epis_hhc),
                                               i_prof => i_prof) date_admission,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => ehd.dt_discharge, i_prof => i_prof) date_discharge,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_first_dt, i_prof => i_prof) date_first_visit,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_last_dt, i_prof => i_prof) date_last_visit,
                   pk_hhc_discharge.get_val_d(ehd.id_hhc_discharge, 50) services_received,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 51) services_specify,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 52) pat_caregiver_education,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 53) summary_care_provided,
                   pk_hhc_discharge.get_val_d(ehd.id_hhc_discharge, 54) discharge_goals,
                   pk_hhc_discharge.get_val_d(ehd.id_hhc_discharge, 55) discharge_reason,
                   pk_date_utils.date_send_tsz(i_lang => i_lang,
                                               i_date => pk_hhc_discharge.get_val_dt(ehd.id_hhc_discharge, 56),
                                               i_prof => i_prof) date_time_death,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 57) place_death,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 58) pat_condition_summary,
                   pk_hhc_discharge.get_val_d(ehd.id_hhc_discharge, 59) pat_caregiver_evaluation,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 60) specify_independence,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 61) specify_knowledge,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 62) specify_other,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 63) action_criteria_not_met,
                   pk_hhc_discharge.get_val_d(ehd.id_hhc_discharge, 64) pat_continue_under,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 65) medication_on_discharge,
                   pk_hhc_discharge.get_val_t(ehd.id_hhc_discharge, 66) other_notes,
                   ehd.id_hhc_discharge
              FROM epis_hhc_discharge ehd
             WHERE ehd.id_hhc_discharge = i_id_hhc_discharge;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REPORT_DATA',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_report_data;

    -----------------------------------------------------------
    -----------------------------------------------------------
    PROCEDURE l_________________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION set_cancel_hhd_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_cancel_reason IN epis_out_on_pass.id_cancel_reason%TYPE,
        i_cancel_notes     IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret               BOOLEAN := FALSE;
        l_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_id_group          NUMBER := seq_hhc_disch_det_grp.nextval;
        l_id_epis_hhc_req   epis_hhc_req.id_epis_hhc_req%TYPE;
    BEGIN
    
        IF i_id_hhc_discharge IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        l_ret := upd_hhc_discharge(i_id_hhc_discharge => i_id_hhc_discharge,
                                   i_flg_status       => g_disch_status_canceled,
                                   i_id_prof_cancel   => i_prof.id,
                                   i_id_cancel_reason => i_id_cancel_reason,
                                   i_cancel_notes     => i_cancel_notes,
                                   i_dt_cancel        => l_current_timestamp,
                                   i_id_prof_creation => i_prof.id,
                                   i_dt_creation      => l_current_timestamp,
                                   i_id_group         => l_id_group);
    
        ----------------------------------------------------------------
        -- undo request
        SELECT ehr.id_epis_hhc_req
          INTO l_id_epis_hhc_req
          FROM epis_hhc_discharge ehd
          JOIN epis_hhc_req ehr
            ON ehr.id_epis_hhc_req = ehd.id_epis_hhc_req
         WHERE ehd.id_hhc_discharge = i_id_hhc_discharge;
    
        IF l_ret
        THEN
            IF NOT pk_hhc_core.set_status_undo(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_id_epis_hhc_req => l_id_epis_hhc_req,
                                               i_id_reason       => i_id_cancel_reason,
                                               i_reason          => i_cancel_notes,
                                               o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        -- end activity of team is reseted;
        l_ret := pk_prof_teams.set_team_end_of_activity(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_hhc_req => l_id_epis_hhc_req,
                                                        i_dt_end  => NULL,
                                                        o_error   => o_error);
        IF NOT l_ret
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_CANCEL_HHD_DISCHARGE',
                                              o_error);
            RETURN FALSE;
    END set_cancel_hhd_discharge;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION save_hhc_discharge
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        id_epis_hhc_req       IN epis_hhc_req.id_epis_hhc_req%TYPE,
        id_epis_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_tbl_mkt_rel         IN table_number,
        i_value               IN table_table_varchar,
        i_value_clob          IN table_clob,
        o_result              OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN := FALSE;
    
        l_internal_names table_varchar;
        l_id_types       table_number;
    
        --l_alert_error t_error_out;
    
        e_wrong_args_exception EXCEPTION;
    
        l_func_name VARCHAR2(1000) := 'save_hhc_discharge';
    
        --------------------------------------------------------------------------------------
        FUNCTION get_internal_name_childs(i_tbl_mkt_rel IN table_number) RETURN table_varchar IS
            l_ret table_varchar;
        BEGIN
            SELECT dcm.internal_name_child
              BULK COLLECT
              INTO l_ret
              FROM v_ds_cmpt_mkt_rel dcm
              JOIN (SELECT /*+ opt_estimate(table dc rows=1)  */
                     rownum rn, column_value id
                      FROM TABLE(i_tbl_mkt_rel) dc) tmr
                ON tmr.id = dcm.id_ds_cmpt_mkt_rel
             ORDER BY tmr.rn;
        
            RETURN l_ret;
        END get_internal_name_childs;
    
        --------------------------------------------------------------------------------------
        FUNCTION get_types(i_internal_name_childs IN table_varchar) RETURN table_number IS
            l_ret table_number;
        BEGIN
        
            SELECT hdt.id_hhc_det_type
              BULK COLLECT
              INTO l_ret
              FROM hhc_det_type hdt
              JOIN (SELECT /*+ opt_estimate(table dc rows=1)  */
                     rownum rn, column_value internal_name
                      FROM TABLE(i_internal_name_childs) dcinc) inc
                ON inc.internal_name = hdt.internal_name
             ORDER BY inc.rn;
        
            RETURN l_ret;
        END get_types;
    
    BEGIN
        l_internal_names := get_internal_name_childs(i_tbl_mkt_rel);
    
        l_id_types := get_types(l_internal_names);
    
        l_ret := set_hhc_discharge(i_lang,
                                   i_prof,
                                   id_epis_hhc_req,
                                   id_epis_hhc_discharge,
                                   l_internal_names,
                                   i_value,
                                   i_value_clob,
                                   l_id_types,
                                   o_result,
                                   o_error);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN e_wrong_args_exception THEN
            g_error := 'Wrong args';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SAVE_HHC_DISCHARGE',
                                              o_error);
            RETURN FALSE;
    END save_hhc_discharge;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION set_hhc_discharge
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_hhc_req       IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_epis_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_internal_name_childs  IN table_varchar,
        i_value                 IN table_table_varchar,
        i_value_clob            IN table_clob,
        i_id_types              IN table_number,
        o_id_epis_hhc_discharge OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN := FALSE;
    
        l_current_timestamp CONSTANT TIMESTAMP WITH TIME ZONE := current_timestamp;
        l_error t_error_out;
    
        l_id_epis_hhc_discharge epis_hhc_discharge.id_hhc_discharge%TYPE := i_id_epis_hhc_discharge;
        l_id_episode            episode.id_episode%TYPE;
        l_id_group              NUMBER := seq_hhc_disch_det_grp.nextval;
    
        l_schedule_list        table_number := table_number();
        l_transaction_id       VARCHAR2(4000);
        l_id_sch_cancel_reason sch_cancel_reason.id_sch_cancel_reason%TYPE := 1548; -- Patient discharged from home health care
    BEGIN
        IF i_id_epis_hhc_req IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_id_epis_hhc_discharge IS NULL
        THEN
            -- we are creatin a new discharge
            l_id_epis_hhc_discharge := seq_epis_hhc_discharge.nextval;
        
            l_ret := ins_hhc_discharge(i_id_hhc_discharge  => l_id_epis_hhc_discharge,
                                       i_id_epis_hhc_req   => i_id_epis_hhc_req,
                                       i_flg_status        => g_disch_status_active,
                                       i_id_prof_discharge => i_prof.id,
                                       i_dt_discharge      => l_current_timestamp,
                                       i_id_group          => l_id_group);
        
            l_ret := set_hhc_disch_det(i_lang                  => i_lang,
                                       i_prof                  => i_prof,
                                       i_dt_creation           => l_current_timestamp,
                                       i_id_epis_hhc_discharge => l_id_epis_hhc_discharge,
                                       i_internal_name_childs  => i_internal_name_childs,
                                       i_value                 => i_value,
                                       i_value_clob            => i_value_clob,
                                       i_id_types              => i_id_types,
                                       i_id_group              => l_id_group);
        
            ----------------------------------------------------------------
            -- alert "Home health care team discharge" 
            l_id_episode := pk_hhc_core.get_id_epis_hhc_by_hhc_req(i_id_hhc_req => i_id_epis_hhc_req);
        
            l_ret := set_hhc_team_discharge_alert(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                  i_episode         => l_id_episode,
                                                  o_error           => o_error);
        
            -- end activity of team;
            l_ret := pk_prof_teams.set_team_end_of_activity(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_hhc_req => i_id_epis_hhc_req,
                                                            i_dt_end  => l_current_timestamp,
                                                            o_error   => o_error);
            IF NOT l_ret
            THEN
                RAISE g_exception;
            END IF;
        
            ----------------------------------------------------------------
            -- cancel schecules
            -- get schedules list
            SELECT column_value id_schedule
              BULK COLLECT
              INTO l_schedule_list
              FROM TABLE(pk_hhc_core.tf_hhc_next_schedules(i_lang, i_prof, i_id_epis_hhc_req, l_current_timestamp));
        
            IF l_schedule_list.exists(1)
            THEN
                -- get transation id
                l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
            
                IF NOT pk_schedule_api_upstream.cancel_schedules(i_lang                 => i_lang,
                                                                 i_prof                 => i_prof,
                                                                 i_transaction_id       => l_transaction_id,
                                                                 i_ids_schedule         => l_schedule_list,
                                                                 i_id_sch_cancel_reason => l_id_sch_cancel_reason,
                                                                 o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            ----------------------------------------------------------------
            -- close request
            IF NOT pk_hhc_core.set_status_close(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                o_error           => l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            -- if id_epis_hhc_discharge is not null it means it's an edition
            l_ret := upd_hhc_discharge(i_id_hhc_discharge  => l_id_epis_hhc_discharge,
                                       i_flg_status        => g_disch_status_active,
                                       i_id_prof_discharge => i_prof.id,
                                       i_dt_discharge      => l_current_timestamp,
                                       i_id_prof_creation  => i_prof.id,
                                       i_dt_creation       => l_current_timestamp,
                                       i_id_group          => l_id_group);
        
            l_ret := set_hhc_disch_det(i_lang                  => i_lang,
                                       i_prof                  => i_prof,
                                       i_flg_ins_upd           => g_flg_upd,
                                       i_dt_creation           => l_current_timestamp,
                                       i_id_epis_hhc_discharge => l_id_epis_hhc_discharge,
                                       i_internal_name_childs  => i_internal_name_childs,
                                       i_value                 => i_value,
                                       i_value_clob            => i_value_clob,
                                       i_id_types              => i_id_types,
                                       i_id_group              => l_id_group);
            NULL;
        END IF;
    
        o_id_epis_hhc_discharge := l_id_epis_hhc_discharge;
    
        -- if transition exists an no error ocurred then commit
        IF l_transaction_id IS NOT NULL
           AND l_ret
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        ELSIF NOT l_ret
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_HHC_DISCHARGE',
                                              o_error);
            RETURN FALSE;
    END set_hhc_discharge;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION set_hhc_disch_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_flg_ins_upd           IN VARCHAR2 DEFAULT g_flg_ins,
        i_dt_creation           IN epis_hhc_disch_det.dt_creation%TYPE,
        i_id_epis_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_internal_name_childs  IN table_varchar,
        i_value                 IN table_table_varchar,
        i_value_clob            IN table_clob,
        i_id_types              IN table_number,
        i_id_group              IN epis_hhc_disch_det_h.id_group%TYPE
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
    
        --------------------------------------------------
        PROCEDURE del_req_det(i_id_hhc_discharge IN epis_hhc_disch_det.id_hhc_discharge%TYPE) IS
        BEGIN
            DELETE epis_hhc_disch_det ehdd
             WHERE ehdd.id_hhc_discharge = i_id_hhc_discharge;
        END del_req_det;
    
    BEGIN
        IF i_flg_ins_upd = g_flg_upd
        THEN
            del_req_det(i_id_epis_hhc_discharge);
        END IF;
    
        FOR i IN 1 .. i_internal_name_childs.count
        LOOP
            l_ret := ins_hhc_disch_det(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_hhc_discharge => i_id_epis_hhc_discharge,
                                       i_id_hhc_det_type  => i_id_types(i),
                                       i_value            => i_value(i),
                                       i_hhc_text         => i_value_clob(i),
                                       i_id_prof_creation => i_prof.id,
                                       i_dt_creation      => i_dt_creation,
                                       i_id_group         => i_id_group);
        END LOOP;
    
        RETURN l_ret;
    
    END set_hhc_disch_det;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION ins_hhc_discharge
    (
        i_id_hhc_discharge  IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_epis_hhc_req   IN epis_hhc_discharge.id_epis_hhc_req%TYPE,
        i_flg_status        IN epis_hhc_discharge.flg_status%TYPE,
        i_id_prof_discharge IN epis_hhc_discharge.id_prof_discharge%TYPE,
        i_dt_discharge      IN epis_hhc_discharge.dt_discharge%TYPE,
        i_id_prof_cancel    IN epis_hhc_discharge.id_prof_cancel%TYPE DEFAULT NULL,
        i_id_cancel_reason  IN epis_hhc_discharge.id_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_notes      IN epis_hhc_discharge.cancel_notes%TYPE DEFAULT NULL, -- CLOB
        i_dt_cancel         IN epis_hhc_discharge.dt_cancel%TYPE DEFAULT NULL,
        i_id_group          IN epis_hhc_disch_det_h.id_group%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
    
        ins_upd_hhc_disc_internal(i_id_hhc_discharge  => i_id_hhc_discharge,
                                  i_id_epis_hhc_req   => i_id_epis_hhc_req,
                                  i_flg_status        => i_flg_status,
                                  i_id_prof_discharge => i_id_prof_discharge,
                                  i_dt_discharge      => i_dt_discharge,
                                  i_id_prof_cancel    => i_id_prof_cancel,
                                  i_id_cancel_reason  => i_id_cancel_reason,
                                  i_cancel_notes      => i_cancel_notes,
                                  i_dt_cancel         => i_dt_cancel,
                                  i_id_group          => i_id_group);
    
        ins_upd_hhc_disc_internal(i_flg_hist          => pk_alert_constant.g_yes, -- this insert will insert in history table
                                  i_id_hhc_discharge  => i_id_hhc_discharge,
                                  i_id_epis_hhc_req   => i_id_epis_hhc_req,
                                  i_flg_status        => i_flg_status,
                                  i_id_prof_discharge => i_id_prof_discharge,
                                  i_dt_discharge      => i_dt_discharge,
                                  i_id_prof_cancel    => i_id_prof_cancel,
                                  i_id_cancel_reason  => i_id_cancel_reason,
                                  i_cancel_notes      => i_cancel_notes,
                                  i_dt_cancel         => i_dt_cancel,
                                  i_id_group          => i_id_group);
    
        RETURN TRUE;
    
    END ins_hhc_discharge;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION upd_hhc_discharge
    (
        i_id_hhc_discharge  IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_epis_hhc_req   IN epis_hhc_discharge.id_epis_hhc_req%TYPE DEFAULT NULL,
        i_flg_status        IN epis_hhc_discharge.flg_status%TYPE DEFAULT NULL,
        i_id_prof_discharge IN epis_hhc_discharge.id_prof_discharge%TYPE DEFAULT NULL,
        i_dt_discharge      IN epis_hhc_discharge.dt_discharge%TYPE DEFAULT NULL,
        i_id_prof_cancel    IN epis_hhc_discharge.id_prof_cancel%TYPE DEFAULT NULL,
        i_id_cancel_reason  IN epis_hhc_discharge.id_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_notes      IN epis_hhc_discharge.cancel_notes%TYPE DEFAULT NULL,
        i_dt_cancel         IN epis_hhc_discharge.dt_cancel%TYPE DEFAULT NULL,
        i_id_prof_creation  IN epis_hhc_discharge_h.id_prof_creation%TYPE DEFAULT NULL,
        i_dt_creation       IN epis_hhc_discharge_h.dt_creation%TYPE DEFAULT NULL,
        i_id_group          IN epis_hhc_disch_det_h.id_group%TYPE
    ) RETURN BOOLEAN IS
    
        l_row epis_hhc_discharge%ROWTYPE;
    BEGIN
        -- insert in regular record
        ins_upd_hhc_disc_internal(i_flg_ins_upd       => g_flg_upd,
                                  i_id_hhc_discharge  => i_id_hhc_discharge,
                                  i_id_epis_hhc_req   => i_id_epis_hhc_req,
                                  i_flg_status        => i_flg_status,
                                  i_id_prof_discharge => i_id_prof_discharge,
                                  i_dt_discharge      => i_dt_discharge,
                                  i_id_prof_cancel    => i_id_prof_cancel,
                                  i_id_cancel_reason  => i_id_cancel_reason,
                                  i_cancel_notes      => i_cancel_notes,
                                  i_dt_cancel         => i_dt_cancel,
                                  i_id_group          => i_id_group);
    
        SELECT *
          INTO l_row
          FROM epis_hhc_discharge ehd
         WHERE ehd.id_hhc_discharge = i_id_hhc_discharge;
    
        -- insert in history record
        ins_upd_hhc_disc_internal(i_flg_hist          => pk_alert_constant.g_yes,
                                  i_id_hhc_discharge  => l_row.id_hhc_discharge,
                                  i_id_epis_hhc_req   => l_row.id_epis_hhc_req,
                                  i_flg_status        => l_row.flg_status,
                                  i_id_prof_discharge => l_row.id_prof_discharge,
                                  i_dt_discharge      => l_row.dt_discharge,
                                  i_id_prof_cancel    => l_row.id_prof_cancel,
                                  i_id_cancel_reason  => l_row.id_cancel_reason,
                                  i_cancel_notes      => l_row.cancel_notes,
                                  i_dt_cancel         => l_row.dt_cancel,
                                  i_id_prof_creation  => i_id_prof_creation,
                                  i_dt_creation       => i_dt_creation,
                                  i_id_group          => i_id_group);
    
        RETURN TRUE;
    
    END upd_hhc_discharge;

    /*******************************************************************************************
    *******************************************************************************************/
    PROCEDURE ins_upd_hhc_disc_internal
    (
        i_flg_ins_upd       IN VARCHAR2 DEFAULT g_flg_ins,
        i_flg_hist          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_hhc_discharge  IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_epis_hhc_req   IN epis_hhc_discharge.id_epis_hhc_req%TYPE,
        i_flg_status        IN epis_hhc_discharge.flg_status%TYPE,
        i_id_prof_discharge IN epis_hhc_discharge.id_prof_discharge%TYPE,
        i_dt_discharge      IN epis_hhc_discharge.dt_discharge%TYPE,
        i_id_prof_cancel    IN epis_hhc_discharge.id_prof_cancel%TYPE DEFAULT NULL,
        i_id_cancel_reason  IN epis_hhc_discharge.id_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_notes      IN epis_hhc_discharge.cancel_notes%TYPE DEFAULT NULL, -- CLOB
        i_dt_cancel         IN epis_hhc_discharge.dt_cancel%TYPE DEFAULT NULL,
        i_id_prof_creation  IN epis_hhc_discharge_h.id_prof_creation%TYPE DEFAULT NULL,
        i_dt_creation       IN epis_hhc_discharge_h.dt_creation%TYPE DEFAULT NULL,
        i_id_group          IN epis_hhc_disch_det_h.id_group%TYPE
    ) IS
    BEGIN
        IF i_flg_hist = pk_alert_constant.g_no
        THEN
            IF i_flg_ins_upd = g_flg_ins
            THEN
                INSERT INTO epis_hhc_discharge
                    (id_hhc_discharge,
                     id_epis_hhc_req,
                     flg_status,
                     id_prof_discharge,
                     dt_discharge,
                     id_prof_cancel,
                     id_cancel_reason,
                     cancel_notes,
                     dt_cancel)
                VALUES
                    (i_id_hhc_discharge,
                     i_id_epis_hhc_req,
                     i_flg_status,
                     i_id_prof_discharge,
                     i_dt_discharge,
                     i_id_prof_cancel,
                     i_id_cancel_reason,
                     i_cancel_notes,
                     i_dt_cancel);
            ELSIF i_flg_ins_upd = g_flg_upd
            THEN
                UPDATE epis_hhc_discharge ehd
                   SET ehd.id_epis_hhc_req   = nvl(i_id_epis_hhc_req, ehd.id_epis_hhc_req),
                       ehd.flg_status        = nvl(i_flg_status, ehd.flg_status),
                       ehd.id_prof_discharge = nvl(i_id_prof_discharge, ehd.id_prof_discharge),
                       ehd.dt_discharge      = nvl(i_dt_discharge, ehd.dt_discharge),
                       ehd.id_prof_cancel    = nvl(i_id_prof_cancel, ehd.id_prof_cancel),
                       ehd.id_cancel_reason  = nvl(i_id_cancel_reason, ehd.id_cancel_reason),
                       ehd.cancel_notes      = nvl(i_cancel_notes, ehd.cancel_notes),
                       ehd.dt_cancel         = nvl(i_dt_cancel, ehd.dt_cancel)
                 WHERE ehd.id_hhc_discharge = i_id_hhc_discharge;
            END IF;
        ELSIF i_flg_hist = pk_alert_constant.g_yes
        THEN
            INSERT INTO epis_hhc_discharge_h
                (id_hhc_discharge,
                 id_epis_hhc_req,
                 flg_status,
                 id_prof_discharge,
                 dt_discharge,
                 id_prof_cancel,
                 id_cancel_reason,
                 cancel_notes,
                 dt_cancel,
                 id_prof_creation,
                 dt_creation,
                 id_group)
            VALUES
                (i_id_hhc_discharge,
                 i_id_epis_hhc_req,
                 i_flg_status,
                 i_id_prof_discharge,
                 i_dt_discharge,
                 i_id_prof_cancel,
                 i_id_cancel_reason,
                 i_cancel_notes,
                 i_dt_cancel,
                 nvl(i_id_prof_creation, i_id_prof_discharge),
                 nvl(i_dt_creation, current_timestamp),
                 i_id_group);
        END IF;
    END ins_upd_hhc_disc_internal;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION ins_hhc_disch_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_disch_det.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE,
        i_value            IN table_varchar,
        i_hhc_text         IN epis_hhc_disch_det.hhc_text%TYPE,
        i_id_prof_creation IN epis_hhc_disch_det.id_prof_creation%TYPE,
        i_dt_creation      IN epis_hhc_disch_det.dt_creation%TYPE,
        i_id_group         IN epis_hhc_disch_det_h.id_group%TYPE
    ) RETURN BOOLEAN IS
    
        l_flg_type         hhc_det_type.flg_type%TYPE;
        l_id_hhc_disch_det epis_hhc_disch_det.id_hhc_disch_det%TYPE;
    
    BEGIN
        SELECT hdt.flg_type
          INTO l_flg_type
          FROM hhc_det_type hdt
         WHERE hdt.id_hhc_det_type = i_id_hhc_det_type;
    
        FOR i IN i_value.first .. i_value.last
        LOOP
            l_id_hhc_disch_det := seq_epis_hhc_disch_det.nextval;
        
            ins_hhc_disch_det_internal(i_id_hhc_disch_det => l_id_hhc_disch_det,
                                       i_id_hhc_discharge => i_id_hhc_discharge,
                                       i_id_hhc_det_type  => i_id_hhc_det_type,
                                       i_hhc_value        => CASE
                                                                 WHEN l_flg_type = g_hhc_det_type_dt THEN
                                                                  NULL
                                                                 ELSE
                                                                  i_value(i)
                                                             END,
                                       i_hhc_text         => i_hhc_text,
                                       i_hhc_date_time    => CASE
                                                                 WHEN l_flg_type = g_hhc_det_type_dt THEN
                                                                  pk_date_utils.get_string_tstz(i_lang, i_prof, i_value(i), NULL)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       i_id_prof_creation => i_id_prof_creation,
                                       i_dt_creation      => i_dt_creation);
        
            ins_hhc_disch_det_hist(i_id_hhc_disch_det => l_id_hhc_disch_det,
                                   i_id_hhc_discharge => i_id_hhc_discharge,
                                   i_id_hhc_det_type  => i_id_hhc_det_type,
                                   i_hhc_value        => CASE
                                                             WHEN l_flg_type = g_hhc_det_type_dt THEN
                                                              NULL
                                                             ELSE
                                                              i_value(i)
                                                         END,
                                   i_hhc_text         => i_hhc_text,
                                   i_hhc_date_time    => CASE
                                                             WHEN l_flg_type = g_hhc_det_type_dt THEN
                                                              pk_date_utils.get_string_tstz(i_lang, i_prof, i_value(i), NULL)
                                                             ELSE
                                                              NULL
                                                         END,
                                   i_id_prof_creation => i_id_prof_creation,
                                   i_dt_creation      => i_dt_creation,
                                   id_group           => i_id_group);
        END LOOP;
    
        RETURN TRUE;
    
    END ins_hhc_disch_det;

    /*******************************************************************************************
    *******************************************************************************************/
    PROCEDURE ins_hhc_disch_det_internal
    (
        i_id_hhc_disch_det IN epis_hhc_disch_det.id_hhc_disch_det%TYPE,
        i_id_hhc_discharge IN epis_hhc_disch_det.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE,
        i_hhc_value        IN epis_hhc_disch_det.hhc_value%TYPE,
        i_hhc_text         IN epis_hhc_disch_det.hhc_text%TYPE,
        i_hhc_date_time    IN epis_hhc_disch_det.hhc_date_time%TYPE,
        i_id_prof_creation IN epis_hhc_disch_det.id_prof_creation%TYPE,
        i_dt_creation      IN epis_hhc_disch_det.dt_creation%TYPE
    ) IS
    
    BEGIN
    
        INSERT INTO epis_hhc_disch_det
            (id_hhc_disch_det,
             id_hhc_discharge,
             id_hhc_det_type,
             hhc_value,
             hhc_text,
             hhc_date_time,
             id_prof_creation,
             dt_creation)
        VALUES
            (i_id_hhc_disch_det,
             i_id_hhc_discharge,
             i_id_hhc_det_type,
             i_hhc_value,
             i_hhc_text,
             i_hhc_date_time,
             i_id_prof_creation,
             i_dt_creation);
    
    END ins_hhc_disch_det_internal;

    /*******************************************************************************************
    *******************************************************************************************/
    PROCEDURE ins_hhc_disch_det_hist
    (
        i_id_hhc_disch_det IN epis_hhc_disch_det_h.id_hhc_disch_det%TYPE,
        i_id_hhc_discharge IN epis_hhc_disch_det_h.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det_h.id_hhc_det_type%TYPE,
        i_hhc_value        IN epis_hhc_disch_det_h.hhc_value%TYPE,
        i_hhc_text         IN epis_hhc_disch_det_h.hhc_text%TYPE,
        i_hhc_date_time    IN epis_hhc_disch_det.hhc_date_time%TYPE,
        i_id_prof_creation IN epis_hhc_disch_det_h.id_prof_creation%TYPE,
        i_dt_creation      IN epis_hhc_disch_det_h.dt_creation%TYPE,
        id_group           IN epis_hhc_disch_det_h.id_group%TYPE
    ) IS
    
    BEGIN
    
        INSERT INTO epis_hhc_disch_det_h
            (id_hhc_disch_det,
             id_hhc_discharge,
             id_hhc_det_type,
             hhc_value,
             hhc_text,
             hhc_date_time,
             id_prof_creation,
             dt_creation,
             id_group)
        VALUES
            (i_id_hhc_disch_det,
             i_id_hhc_discharge,
             i_id_hhc_det_type,
             i_hhc_value,
             i_hhc_text,
             i_hhc_date_time,
             i_id_prof_creation,
             i_dt_creation,
             id_group);
    
    END ins_hhc_disch_det_hist;

    FUNCTION set_hhc_team_discharge_alert
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN NUMBER,
        i_episode         IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
    BEGIN
    
        l_ret := pk_hhc_core.set_hhc_alert_general(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_epis_hhc_req    => i_id_epis_hhc_req,
                                                   i_episode         => i_episode,
                                                   i_id_sys_alert    => pk_hhc_constant.k_hhc_team_discharge_alert,
                                                   i_alert_msg       => pk_hhc_constant.k_hhc_team_dicharge_msg,
                                                   i_id_professional => i_prof.id,
                                                   o_error           => o_error);
    
        RETURN l_ret;
    
    END set_hhc_team_discharge_alert;

    FUNCTION get_episode_by_id_epis_hhc_req
    (
        i_lang            IN language.id_language%TYPE,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN episode.id_episode%TYPE IS
        l_id_episode episode.id_episode%TYPE;
    BEGIN
    
        SELECT ehr.id_episode
          INTO l_id_episode
          FROM epis_hhc_req ehr
         WHERE ehr.id_epis_hhc_req = i_id_epis_hhc_req
           AND rownum = 1;
    
        RETURN l_id_episode;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_episode_by_id_epis_hhc_req;

    -----------------------------------------------------------
    -----------------------------------------------------------
    PROCEDURE l__________________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    --------------------------------------------------------------------------------------
    FUNCTION get_val_t
    (
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000 CHAR);
    BEGIN
        SELECT ehdd.hhc_value
          INTO l_ret
          FROM epis_hhc_disch_det ehdd
         WHERE ehdd.id_hhc_discharge = i_id_hhc_discharge
           AND ehdd.id_hhc_det_type = i_id_hhc_det_type
           AND rownum = 1;
    
        RETURN l_ret;
    END get_val_t;

    --------------------------------------------------------------------------------------
    FUNCTION get_val_dt
    (
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_ret TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        SELECT ehdd.hhc_date_time
          INTO l_ret
          FROM epis_hhc_disch_det ehdd
         WHERE ehdd.id_hhc_discharge = i_id_hhc_discharge
           AND ehdd.id_hhc_det_type = i_id_hhc_det_type
           AND rownum = 1;
    
        RETURN l_ret;
    END get_val_dt;

    --------------------------------------------------------------------------------------
    FUNCTION get_val_d
    (
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE
    ) RETURN table_varchar IS
        l_ret table_varchar := table_varchar();
    BEGIN
        SELECT ehdd.hhc_value
          BULK COLLECT
          INTO l_ret
          FROM epis_hhc_disch_det ehdd
        /*JOIN hhc_det_type hdt
        ON hdt.id_hhc_det_type = ehdd.id_hhc_det_type*/
         WHERE ehdd.id_hhc_discharge = i_id_hhc_discharge
           AND ehdd.id_hhc_det_type = i_id_hhc_det_type
         ORDER BY ehdd.id_hhc_disch_det;
    
        RETURN l_ret;
    END get_val_d;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);

END pk_hhc_discharge;
/
