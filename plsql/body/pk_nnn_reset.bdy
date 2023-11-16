/*-- Last Change Revision: $Rev: 1662266 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-18 10:28:00 +0000 (ter, 18 nov 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_nnn_reset IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    FUNCTION reset_nnn_epis_care_plans
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'reset_nnn_epis_care_plans';
        l_nnn_epis_diagnosis      table_number;
        l_nnn_epis_diagnosis_eval table_number;
        l_nnn_epis_outcome        table_number;
        l_nnn_epis_indicator      table_number;
        l_nnn_epis_intervention   table_number;
        l_nnn_epis_activity       table_number;
        l_nnn_links               table_number;
        i                         PLS_INTEGER;
        l_ret                     BOOLEAN;
    
    BEGIN
    
        -- checks if the delete process can be executed
        IF i_patient.count = 0
           AND i_episode.count = 0
        THEN
            g_error := 'Empty arrays for i_patient and i_episode';
            pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            RETURN FALSE;
        END IF;
    
        -- Collect entries
    
        g_error := 'Collecting NNN_EPIS_DIAGNOSIS entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT ed.id_nnn_epis_diagnosis BULK COLLECT
          INTO l_nnn_epis_diagnosis
          FROM nnn_epis_diagnosis ed
         WHERE ed.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  t.column_value
                                   FROM TABLE(i_episode) t);
    
        g_error := 'Collecting NNN_EPIS_DIAG_EVAL entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT ede.id_nnn_epis_diag_eval BULK COLLECT
          INTO l_nnn_epis_diagnosis_eval
          FROM nnn_epis_diag_eval ede
         WHERE ede.id_nnn_epis_diagnosis IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(l_nnn_epis_diagnosis) t);
    
        g_error := 'Collecting NNN_EPIS_OUTCOME entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT eo.id_nnn_epis_outcome BULK COLLECT
          INTO l_nnn_epis_outcome
          FROM nnn_epis_outcome eo
         WHERE eo.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  t.column_value
                                   FROM TABLE(i_episode) t)
            OR eo.id_episode_origin IN (SELECT /*+opt_estimate (table t rows=1)*/
                                         t.column_value
                                          FROM TABLE(i_episode) t);
    
        g_error := 'Collecting NNN_EPIS_INDICATOR entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT ei.id_nnn_epis_indicator BULK COLLECT
          INTO l_nnn_epis_indicator
          FROM nnn_epis_indicator ei
         WHERE ei.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  t.column_value
                                   FROM TABLE(i_episode) t)
            OR ei.id_episode_origin IN (SELECT /*+opt_estimate (table t rows=1)*/
                                         t.column_value
                                          FROM TABLE(i_episode) t);
    
        g_error := 'Collecting NNN_EPIS_INTERVENTION entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT ei.id_nnn_epis_intervention BULK COLLECT
          INTO l_nnn_epis_intervention
          FROM nnn_epis_intervention ei
         WHERE ei.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  t.column_value
                                   FROM TABLE(i_episode) t);
    
        g_error := 'Collecting NNN_EPIS_ACTIVITY entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT ea.id_nnn_epis_activity BULK COLLECT
          INTO l_nnn_epis_activity
          FROM nnn_epis_activity ea
         WHERE ea.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  t.column_value
                                   FROM TABLE(i_episode) t)
            OR ea.id_episode_origin IN (SELECT /*+opt_estimate (table t rows=1)*/
                                         t.column_value
                                          FROM TABLE(i_episode) t);
    
        g_error := 'Collecting NNN_EPIS_LNK_DG_INTRV entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT lnkdi.id_nnn_epis_lnk_dg_intrv BULK COLLECT
          INTO l_nnn_links
          FROM nnn_epis_lnk_dg_intrv lnkdi
         WHERE lnkdi.id_nnn_epis_diagnosis IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                t.column_value
                                                 FROM TABLE(l_nnn_epis_diagnosis) t)
            OR lnkdi.id_nnn_epis_intervention IN
               (SELECT /*+opt_estimate (table t rows=1)*/
                 t.column_value
                  FROM TABLE(l_nnn_epis_intervention) t);
    
        g_error := 'Deleting NNN_EPIS_LNK_DG_INTRV_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_lnk_dg_intrv_h lnkdih
         WHERE lnkdih.id_nnn_epis_lnk_dg_intrv IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                    t.column_value
                                                     FROM TABLE(l_nnn_links) t);
    
        g_error := 'Deleting NNN_EPIS_LNK_DG_INTRV entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_lnk_dg_intrv lnkdi
         WHERE lnkdi.id_nnn_epis_lnk_dg_intrv IN (SELECT /*+opt_estimate (table t rows=5)*/
                                                   t.column_value
                                                    FROM TABLE(l_nnn_links) t);
    
        g_error := 'Collecting NNN_EPIS_LNK_DG_OUTC entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT lnkdo.id_nnn_epis_lnk_dg_outc BULK COLLECT
          INTO l_nnn_links
          FROM nnn_epis_lnk_dg_outc lnkdo
         WHERE lnkdo.id_nnn_epis_diagnosis IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                t.column_value
                                                 FROM TABLE(l_nnn_epis_diagnosis) t)
            OR lnkdo.id_nnn_epis_outcome IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(l_nnn_epis_outcome) t);
    
        g_error := 'Deleting NNN_EPIS_LNK_DG_OUTC_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE nnn_epis_lnk_dg_outc_h lnkdoh
         WHERE lnkdoh.id_nnn_epis_lnk_dg_outc IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                   t.column_value
                                                    FROM TABLE(l_nnn_links) t);
    
        g_error := 'Deleting NNN_EPIS_LNK_DG_OUTC entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE nnn_epis_lnk_dg_outc lnkdo
         WHERE lnkdo.id_nnn_epis_lnk_dg_outc IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                  t.column_value
                                                   FROM TABLE(l_nnn_links) t);
    
        g_error := 'Collecting NNN_EPIS_LNK_INT_ACTV entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT lnkia.id_nnn_epis_lnk_int_actv BULK COLLECT
          INTO l_nnn_links
          FROM nnn_epis_lnk_int_actv lnkia
         WHERE lnkia.id_nnn_epis_intervention IN
               (SELECT /*+opt_estimate (table t rows=1)*/
                 t.column_value
                  FROM TABLE(l_nnn_epis_intervention) t)
            OR lnkia.id_nnn_epis_activity IN (SELECT /*+opt_estimate (table t rows=1)*/
                                               t.column_value
                                                FROM TABLE(l_nnn_epis_activity) t);
    
        g_error := 'Deleting NNN_EPIS_LNK_INT_ACTV_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE nnn_epis_lnk_int_actv_h lnkiah
         WHERE lnkiah.id_nnn_epis_lnk_int_actv IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                    t.column_value
                                                     FROM TABLE(l_nnn_links) t);
    
        g_error := 'Deleting NNN_EPIS_LNK_INT_ACTV entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE nnn_epis_lnk_int_actv lnkia
         WHERE lnkia.id_nnn_epis_lnk_int_actv IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                   t.column_value
                                                    FROM TABLE(l_nnn_links) t);
    
        g_error := 'Collecting NNN_EPIS_LNK_OUTC_IND entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT lnkoi.id_nnn_epis_lnk_outc_ind BULK COLLECT
          INTO l_nnn_links
          FROM nnn_epis_lnk_outc_ind lnkoi
         WHERE lnkoi.id_nnn_epis_outcome IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(l_nnn_epis_outcome) t)
            OR lnkoi.id_nnn_epis_indicator IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                t.column_value
                                                 FROM TABLE(l_nnn_epis_indicator) t);
    
        g_error := 'Deleting NNN_EPIS_LNK_OUTC_IND_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE nnn_epis_lnk_outc_ind_h lnkoih
         WHERE lnkoih.id_nnn_epis_lnk_outc_ind IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                    t.column_value
                                                     FROM TABLE(l_nnn_links) t);
    
        g_error := 'Deleting NNN_EPIS_LNK_OUTC_IND entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE nnn_epis_lnk_outc_ind lnkoi
         WHERE lnkoi.id_nnn_epis_lnk_outc_ind IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                   t.column_value
                                                    FROM TABLE(l_nnn_links) t);
    
        g_error := 'Deleting NNN_EPIS_ACTV_DET_TSKH entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_actv_det_tskh eadth
         WHERE eadth.id_nnn_epis_activity_det IN
               (SELECT ead.id_nnn_epis_activity_det
                  FROM nnn_epis_activity_det ead
                 WHERE ead.id_nnn_epis_activity IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(l_nnn_epis_activity) t));
    
        g_error := 'Deleting NNN_EPIS_ACTV_DET_TASK entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_actv_det_task eadt
         WHERE eadt.id_nnn_epis_activity_det IN
               (SELECT ead.id_nnn_epis_activity_det
                  FROM nnn_epis_activity_det ead
                 WHERE ead.id_nnn_epis_activity IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(l_nnn_epis_activity) t));
    
        g_error := 'Deleting NNN_EPIS_ACTIVITY_DET_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_activity_det_h eadh
         WHERE eadh.id_nnn_epis_activity_det IN
               (SELECT ead.id_nnn_epis_activity_det
                  FROM nnn_epis_activity_det ead
                 WHERE ead.id_nnn_epis_activity IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(l_nnn_epis_activity) t));
    
        g_error := 'Deleting NNN_EPIS_ACTIVITY_DET entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_activity_det ead
         WHERE ead.id_nnn_epis_activity IN (SELECT /*+opt_estimate (table t rows=1)*/
                                             t.column_value
                                              FROM TABLE(l_nnn_epis_activity) t);
    
        g_error := 'Deleting NNN_EPIS_ACTIVITY_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_activity_h eah
         WHERE eah.id_nnn_epis_activity IN (SELECT /*+opt_estimate (table t rows=1)*/
                                             t.column_value
                                              FROM TABLE(l_nnn_epis_activity) t);
    
        g_error := 'Deleting NNN_EPIS_ACTIVITY entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_activity ea
         WHERE ea.id_nnn_epis_activity IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            t.column_value
                                             FROM TABLE(l_nnn_epis_activity) t);
    
        g_error := 'Deleting NNN_EPIS_INTERVENTION_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_intervention_h eih
         WHERE eih.id_nnn_epis_intervention IN
               (SELECT /*+opt_estimate (table t rows=1)*/
                 t.column_value
                  FROM TABLE(l_nnn_epis_intervention) t);
    
        g_error := 'Deleting NNN_EPIS_INTERVENTION entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_intervention ei
         WHERE ei.id_nnn_epis_intervention IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                t.column_value
                                                 FROM TABLE(l_nnn_epis_intervention) t);
    
        g_error := 'Deleting NNN_EPIS_IND_EVAL_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_ind_eval_h eieh
         WHERE eieh.id_nnn_epis_ind_eval IN
               (SELECT eie.id_nnn_epis_ind_eval
                  FROM nnn_epis_ind_eval eie
                 WHERE eie.id_nnn_epis_indicator IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                      t.column_value
                                                       FROM TABLE(l_nnn_epis_indicator) t));
    
        g_error := 'Deleting NNN_EPIS_IND_EVAL entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_ind_eval eie
         WHERE eie.id_nnn_epis_indicator IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(l_nnn_epis_indicator) t);
    
        g_error := 'Deleting NNN_EPIS_INDICATOR_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_indicator_h eih
         WHERE eih.id_nnn_epis_indicator IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(l_nnn_epis_indicator) t);
    
        g_error := 'Deleting NNN_EPIS_INDICATOR entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_indicator ei
         WHERE ei.id_nnn_epis_indicator IN (SELECT /*+opt_estimate (table t rows=1)*/
                                             t.column_value
                                              FROM TABLE(l_nnn_epis_indicator) t);
    
        g_error := 'Deleting NNN_EPIS_OUTCOME_EVAL_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_outcome_eval_h eoeh
         WHERE eoeh.id_nnn_epis_outcome_eval IN
               (SELECT eoe.id_nnn_epis_outcome_eval
                  FROM nnn_epis_outcome_eval eoe
                 WHERE eoe.id_nnn_epis_outcome IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                    t.column_value
                                                     FROM TABLE(l_nnn_epis_outcome) t));
    
        g_error := 'Deleting NNN_EPIS_OUTCOME_EVAL entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_outcome_eval eoe
         WHERE eoe.id_nnn_epis_outcome IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            t.column_value
                                             FROM TABLE(l_nnn_epis_outcome) t);
    
        g_error := 'Deleting NNN_EPIS_OUTCOME_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_outcome_h eoh
         WHERE eoh.id_nnn_epis_outcome IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            t.column_value
                                             FROM TABLE(l_nnn_epis_outcome) t);
    
        g_error := 'Deleting NNN_EPIS_OUTCOME entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_outcome eo
         WHERE eo.id_nnn_epis_outcome IN (SELECT /*+opt_estimate (table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(l_nnn_epis_outcome) t);
    
        g_error := 'Deleting NNN_EPIS_DIAG_DEFC_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_diag_defc_h eddch
         WHERE eddch.id_nnn_epis_diag_eval IN
               (SELECT /*+opt_estimate (table t rows=1)*/
                 t.column_value
                  FROM TABLE(l_nnn_epis_diagnosis_eval) t);
    
        g_error := 'Deleting NNN_EPIS_DIAG_DEFC entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_diag_defc eddc
         WHERE eddc.id_nnn_epis_diag_eval IN (SELECT /*+opt_estimate (table t rows=1)*/
                                               t.column_value
                                                FROM TABLE(l_nnn_epis_diagnosis_eval) t);
    
        g_error := 'Deleting NNN_EPIS_DIAG_RELF_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_diag_relf_h edrlfh
         WHERE edrlfh.id_nnn_epis_diag_eval IN
               (SELECT /*+opt_estimate (table t rows=1)*/
                 t.column_value
                  FROM TABLE(l_nnn_epis_diagnosis_eval) t);
    
        g_error := 'Deleting NNN_EPIS_DIAG_RELF entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_diag_relf edrlf
         WHERE edrlf.id_nnn_epis_diag_eval IN
               (SELECT /*+opt_estimate (table t rows=1)*/
                 t.column_value
                  FROM TABLE(l_nnn_epis_diagnosis_eval) t);
    
        g_error := 'Deleting NNN_EPIS_DIAG_RSKF_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_diag_rskf_h edrkfh
         WHERE edrkfh.id_nnn_epis_diag_eval IN
               (SELECT /*+opt_estimate (table t rows=1)*/
                 t.column_value
                  FROM TABLE(l_nnn_epis_diagnosis_eval) t);
    
        g_error := 'Deleting NNN_EPIS_DIAG_RSKF entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_diag_rskf edrkf
         WHERE edrkf.id_nnn_epis_diag_eval IN
               (SELECT /*+opt_estimate (table t rows=1)*/
                 t.column_value
                  FROM TABLE(l_nnn_epis_diagnosis_eval) t);
    
        g_error := 'Deleting NNN_EPIS_DIAG_EVAL_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_diag_eval_h edeh
         WHERE edeh.id_nnn_epis_diag_eval IN (SELECT /*+opt_estimate (table t rows=1)*/
                                               t.column_value
                                                FROM TABLE(l_nnn_epis_diagnosis_eval) t);
    
        g_error := 'Deleting NNN_EPIS_DIAG_EVAL entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_diag_eval ede
         WHERE ede.id_nnn_epis_diag_eval IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(l_nnn_epis_diagnosis_eval) t);
    
        g_error := 'Deleting NNN_EPIS_DIAGNOSIS_H entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_diagnosis_h edh
         WHERE edh.id_nnn_epis_diagnosis IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(l_nnn_epis_diagnosis) t);
    
        g_error := 'Deleting NNN_EPIS_DIAGNOSIS entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        DELETE FROM nnn_epis_diagnosis ed
         WHERE ed.id_nnn_epis_diagnosis IN (SELECT /*+opt_estimate (table t rows=1)*/
                                             t.column_value
                                              FROM TABLE(l_nnn_epis_diagnosis) t);
    
        g_error := 'Deleting Alert events for Nursing Outcomes';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        i := l_nnn_epis_outcome.first;
        WHILE i IS NOT NULL
        LOOP
            l_ret := pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_id_sys_alert => pk_nnn_constant.g_sys_alert_outcome,
                                                      i_id_record    => l_nnn_epis_outcome(i),
                                                      o_error        => o_error);
            i     := l_nnn_epis_outcome.next(i);
        END LOOP;
    
        g_error := 'Deleting Alert events for Nursing Indicators';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        i := l_nnn_epis_indicator.first;
        WHILE i IS NOT NULL
        LOOP
            l_ret := pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_id_sys_alert => pk_nnn_constant.g_sys_alert_indicator,
                                                      i_id_record    => l_nnn_epis_indicator(i),
                                                      o_error        => o_error);
            i     := l_nnn_epis_indicator.next(i);
        END LOOP;
    
        g_error := 'Deleting Alert events for Nursing Activities';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        i := l_nnn_epis_activity.first;
        WHILE i IS NOT NULL
        LOOP
            l_ret := pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_id_sys_alert => pk_nnn_constant.g_sys_alert_activity,
                                                      i_id_record    => l_nnn_epis_activity(i),
                                                      o_error        => o_error);
            i     := l_nnn_epis_activity.next(i);
        END LOOP;
    
        g_error := 'Clearing the priority info (NOC Outcomes/Indicators and NIC Activities) in grid tasks';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        UPDATE grid_task gt
           SET gt.noc_outcome = NULL, gt.noc_indicator = NULL, gt.nic_activity = NULL
         WHERE gt.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  t.column_value
                                   FROM TABLE(i_episode) t);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              k_function_name,
                                              o_error);
            RETURN FALSE;
        
    END reset_nnn_epis_care_plans;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_nnn_reset;
/
