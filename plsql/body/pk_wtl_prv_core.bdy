/*-- Last Change Revision: $Rev: 2015419 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-05-30 09:31:54 +0100 (seg, 30 mai 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wtl_prv_core IS

    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    FUNCTION get_type_dyn_screen
    (
        i_internal_name IN VARCHAR2,
        i_screen        IN VARCHAR2
    ) RETURN VARCHAR2 AS
    
    BEGIN
        CASE
            WHEN i_internal_name IN ('ADM_INDIC', 'ADM_LOCATION', 'ADM_SERVICE', 'ADM_SPEC', 'ADM_EXP_DUR') THEN
                RETURN 'I';
            WHEN i_internal_name IN ('SURG_SPEC', 'SURG_PROC', 'SURG_EXP_DUR', 'POS_AUTH') THEN
                RETURN 'O';
            ELSE
                RETURN 'A';
        END CASE;
    END get_type_dyn_screen;

    FUNCTION get_intern_name_dyn_screen
    (
        i_internal_name IN VARCHAR2,
        i_screen        IN VARCHAR2
    ) RETURN VARCHAR2 AS
    
    BEGIN
    
        IF i_screen IS NULL
           OR i_screen = 'I'
        THEN
            CASE i_internal_name
                WHEN 'ADM_INDIC' THEN
                    RETURN 'RI_REASON_ADMISSION';
                WHEN 'ADM_LOCATION' THEN
                    RETURN 'RI_LOC_INT';
                WHEN 'ADM_SERVICE' THEN
                    RETURN 'RI_SERV_ADM';
                WHEN 'ADM_SPEC' THEN
                    RETURN 'RI_ESP_INT';
                WHEN 'ADM_EXP_DUR' THEN
                    RETURN 'RI_DURANTION';
                WHEN 'SURG_SPEC' THEN
                    RETURN 'RS_CLIN_SERVICE';
                WHEN 'SURG_PROC' THEN
                    RETURN 'RS_PROC_SURG';
                WHEN 'SURG_EXP_DUR' THEN
                    RETURN 'RS_PREV_DURATION';
                WHEN 'POS_AUTH' THEN
                    RETURN '';
                WHEN 'SCH_START' THEN
                    RETURN 'RSP_BEGIN_SCHED';
                WHEN 'SCH_END' THEN
                    RETURN 'RSP_END_SCHED';
                WHEN 'URG_LVL' THEN
                    RETURN 'RSP_LVL_URG';
                WHEN 'BARTHEL_IDX' THEN
                    RETURN '';
                ELSE
                    RETURN NULL;
            END CASE;
        ELSE
            CASE i_internal_name
                WHEN 'SURG_SPEC' THEN
                    RETURN 'RS_CLIN_SERVICE_P';
                WHEN 'SURG_PROC' THEN
                    RETURN 'RS_PROC_SURG_P';
                WHEN 'SURG_EXP_DUR' THEN
                    RETURN 'RS_PREV_DURATION_P';
                WHEN 'POS_AUTH' THEN
                    RETURN '';
                WHEN 'SCH_START' THEN
                    RETURN 'RSP_BEGIN_SCHED_P';
                WHEN 'SCH_END' THEN
                    RETURN 'RSP_END_SCHED_P';
                WHEN 'URG_LVL' THEN
                    RETURN 'RSP_LVL_URG_P';
                WHEN 'BARTHEL_IDX' THEN
                    RETURN '';
                ELSE
                    RETURN NULL;
            END CASE;
        END IF;
    
    END get_intern_name_dyn_screen;

    FUNCTION get_surg_adm_req_mand_core
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_wtl          IN waiting_list%ROWTYPE,
        i_chck_pos     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_adm_needed   IN schedule_sr.adm_needed%TYPE DEFAULT NULL,
        i_chck_pos_req IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_screen       IN VARCHAR2 DEFAULT 'I',
        o_idwchk       OUT table_number,
        o_desc         OUT table_varchar,
        o_check        OUT table_varchar,
        o_flg_ready    OUT VARCHAR2,
        o_int_name     OUT table_varchar,
        o_type_flg     OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_surg_dur VARCHAR2(1);
        l_surg_dcs VARCHAR2(1);
        l_surg_prc VARCHAR2(1);
        l_surg_pos VARCHAR2(1);
        l_has_eval VARCHAR2(1);
    
        l_o_idwchk        table_number := table_number();
        l_o_desc          table_varchar := table_varchar();
        l_o_check         table_varchar := table_varchar();
        l_o_internal_name table_varchar := table_varchar();
        l_o_type_flg      table_varchar := table_varchar();
        l_adm_req         adm_request%ROWTYPE;
    
        l_last_epis_doc      epis_documentation.id_epis_documentation%TYPE;
        l_last_date_epis_doc epis_documentation.dt_creation_tstz%TYPE;
        l_epis_doc_count     NUMBER;
        l_pos_required       sys_config.value%TYPE;
    
    BEGIN
    
        l_pos_required := pk_sysconfig.get_config(i_code_cf => 'WTL_POS_REQUIRED', i_prof => i_prof);
    
        o_flg_ready := pk_alert_constant.g_yes;
    
        g_error := 'LOAD CHKLIST ARRAYS';
        pk_alertlog.log_debug(g_error);
        SELECT r.id_wtl_checklist, r.desc_item, r.internal_name, r.type_flg
          BULK COLLECT
          INTO l_o_idwchk, l_o_desc, l_o_internal_name, l_o_type_flg
          FROM (SELECT wc.id_wtl_checklist,
                       pk_translation.get_translation(i_lang, wc.code_desc) desc_item,
                       wc.rank,
                       get_intern_name_dyn_screen(wc.internal_name, i_screen) internal_name,
                       get_type_dyn_screen(wc.internal_name, i_screen) type_flg
                
                  FROM wtl_checklist wc
                  LEFT JOIN wtl_sort_key wsk
                    ON wsk.id_wtl_checklist = wc.id_wtl_checklist
                 WHERE wsk.id_wtl_sort_key IS NULL
                UNION ALL
                SELECT DISTINCT wc.id_wtl_checklist,
                                pk_translation.get_translation(i_lang, wc.code_desc) desc_item,
                                wc.rank,
                                get_intern_name_dyn_screen(wc.internal_name, i_screen) internal_name,
                                get_type_dyn_screen(wc.internal_name, i_screen) type_flg
                  FROM wtl_checklist wc
                 INNER JOIN TABLE(pk_wtl_prv_core.get_sort_keys_core(i_lang, i_prof, pk_utils.get_institution_parent(i_lang, i_prof, i_prof.institution))) wsk
                    ON wc.id_wtl_checklist = wsk.id_wtl_checklist) r
         WHERE l_pos_required = pk_alert_constant.get_yes
            OR (l_pos_required = pk_alert_constant.get_no AND r.id_wtl_checklist <> pk_wtl_pbl_core.g_wtl_chk_pos_aut)
         ORDER BY r.rank;
    
        g_error := 'GET CURRENT AR RECORD';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT t.*
              INTO l_adm_req
              FROM (SELECT ar.*
                      FROM adm_request ar
                     INNER JOIN wtl_epis we
                        ON we.id_episode = ar.id_dest_episode
                       AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                     WHERE we.id_waiting_list = i_wtl.id_waiting_list
                     ORDER BY ar.dt_upd DESC) t
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'LOAD SURGERY VARS';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT decode((SELECT wldcs.id_dep_clin_serv
                            FROM wtl_dep_clin_serv wldcs
                           WHERE wldcs.id_waiting_list = wle.id_waiting_list
                             AND wldcs.id_episode = wle.id_episode
                             AND wldcs.flg_type = pk_alert_constant.g_wtl_dcs_flg_type_s
                             AND wldcs.flg_status = pk_alert_constant.g_active
                             AND rownum <= 1),
                          NULL,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_dcs,
                   decode((SELECT sei.id_sr_epis_interv
                            FROM sr_epis_interv sei
                           WHERE sei.flg_status != pk_wtl_prv_core.g_sr_epis_interv_status_c
                             AND sei.id_episode_context = wle.id_episode
                             AND rownum <= 1),
                          NULL,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_sei,
                   decode((SELECT ss.duration
                            FROM schedule_sr ss
                           WHERE ss.id_waiting_list = wle.id_waiting_list
                                --AND ss.flg_status = pk_alert_constant.g_active
                             AND ss.duration IS NOT NULL
                             AND rownum <= 1),
                          NULL,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_duration,
                   decode(i_chck_pos_req,
                          pk_alert_constant.g_no,
                          pk_surgery_request.get_pos_autorization(i_lang, i_prof, wle.id_episode),
                          pk_surgery_request.check_pos_requested(i_lang, i_prof, wle.id_waiting_list)) flg_pos_auth
              INTO l_surg_dcs, l_surg_prc, l_surg_dur, l_surg_pos
              FROM wtl_epis wle
             WHERE wle.id_waiting_list = i_wtl.id_waiting_list
               AND wle.id_epis_type = pk_alert_constant.g_epis_type_operating;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'START LOOP ';
        pk_alertlog.log_debug(g_error);
        FOR i IN l_o_idwchk.first .. l_o_idwchk.last
        LOOP
            g_error := 'ROUND ' || i;
            pk_alertlog.log_debug(g_error);
        
            l_o_check.extend;
        
            --Indication for admission
            IF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_ind_adm
               AND nvl(i_adm_needed, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
            THEN
                IF l_adm_req.id_adm_indication IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := pk_alert_constant.g_yes;
                ELSE
                    l_o_check(l_o_check.last) := pk_alert_constant.g_no;
                    o_flg_ready := pk_alert_constant.g_no;
                END IF;
            
                --Admission location
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_adm_loc
                  AND nvl(i_adm_needed, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
            THEN
                IF l_adm_req.id_dest_inst IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := pk_alert_constant.g_yes;
                ELSE
                    l_o_check(l_o_check.last) := pk_alert_constant.g_no;
                    o_flg_ready := pk_alert_constant.g_no;
                END IF;
            
                --Admission service
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_adm_spc
                  AND nvl(i_adm_needed, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
            THEN
                IF l_adm_req.id_dep_clin_serv IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := pk_alert_constant.g_yes;
                ELSE
                    l_o_check(l_o_check.last) := pk_alert_constant.g_no;
                    o_flg_ready := pk_alert_constant.g_no;
                END IF;
            
                --Admission specialty
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_adm_srv
                  AND nvl(i_adm_needed, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
            THEN
                IF l_adm_req.id_department IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := pk_alert_constant.g_yes;
                ELSE
                    l_o_check(l_o_check.last) := pk_alert_constant.g_no;
                    o_flg_ready := pk_alert_constant.g_no;
                END IF;
            
                --Expected duration of admission
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_adm_dur
                  AND nvl(i_adm_needed, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
            THEN
                IF l_adm_req.expected_duration IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := pk_alert_constant.g_yes;
                ELSE
                    l_o_check(l_o_check.last) := pk_alert_constant.g_no;
                    o_flg_ready := pk_alert_constant.g_no;
                END IF;
            
                --Surgery Specialty
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_srg_spc
            THEN
                IF l_surg_dcs IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := l_surg_dcs;
                    IF l_surg_dcs = pk_alert_constant.g_no
                    THEN
                        o_flg_ready := pk_alert_constant.g_no;
                    END IF;
                END IF;
            
                -- Surgery procedure
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_srg_prc
            THEN
                IF l_surg_prc IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := l_surg_prc;
                    IF l_surg_prc = pk_alert_constant.g_no
                    THEN
                        o_flg_ready := pk_alert_constant.g_no;
                    END IF;
                END IF;
            
                -- Expected duration of surgery
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_srg_dur
            THEN
                IF l_surg_dur IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := l_surg_dur;
                    IF l_surg_dur = pk_alert_constant.g_no
                    THEN
                        o_flg_ready := pk_alert_constant.g_no;
                    END IF;
                END IF;
            
                --POS authorization
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_pos_aut
                  AND i_chck_pos = pk_alert_constant.g_yes
            THEN
                IF l_surg_pos IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := l_surg_pos;
                    IF l_surg_pos = pk_alert_constant.g_no
                    THEN
                        o_flg_ready := pk_alert_constant.g_no;
                    END IF;
                END IF;
            
                --Scheduling period start                             
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_sch_str
            THEN
                IF i_wtl.dt_dpb IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := pk_alert_constant.g_yes;
                ELSE
                    l_o_check(l_o_check.last) := pk_alert_constant.g_no;
                    o_flg_ready := pk_alert_constant.g_no;
                END IF;
            
                --Scheduling period end
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_sch_end
            THEN
                IF i_wtl.dt_dpa IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := pk_alert_constant.g_yes;
                ELSE
                    l_o_check(l_o_check.last) := pk_alert_constant.g_no;
                    o_flg_ready := pk_alert_constant.g_no;
                END IF;
            
                --Urgency Level
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_urg_lvl
            THEN
                IF i_wtl.id_wtl_urg_level IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := pk_alert_constant.g_yes;
                ELSE
                    l_o_check(l_o_check.last) := pk_alert_constant.g_no;
                    o_flg_ready := pk_alert_constant.g_no;
                END IF;
            
                --Barthel 
            ELSIF l_o_idwchk(i) = pk_wtl_pbl_core.g_wtl_chk_barthel
            THEN
                IF NOT pk_wtl_pbl_core.check_wtl_func_eval_pat(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_patient            => i_wtl.id_patient,
                                                               i_doc_area           => NULL,
                                                               i_doc_template       => NULL,
                                                               o_flg_val            => l_has_eval,
                                                               o_last_epis_doc      => l_last_epis_doc,
                                                               o_last_date_epis_doc => l_last_date_epis_doc,
                                                               o_epis_doc_count     => l_epis_doc_count,
                                                               o_error              => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF i_wtl.func_eval_score IS NOT NULL
                THEN
                    l_o_check(l_o_check.last) := pk_alert_constant.g_yes;
                ELSE
                    l_o_check(l_o_check.last) := pk_alert_constant.g_no;
                    o_flg_ready := pk_alert_constant.g_no;
                END IF;
            END IF;
        END LOOP;
    
        o_check    := l_o_check;
        o_idwchk   := l_o_idwchk;
        o_desc     := l_o_desc;
        o_int_name := l_o_internal_name;
        o_type_flg := l_o_type_flg;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_SURG_ADM_REQ_MANDATORY',
                                              o_error);
        
            RETURN FALSE;
    END get_surg_adm_req_mand_core;

    FUNCTION get_surg_adm_req_mand_core
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_wtl       IN waiting_list.id_waiting_list%TYPE,
        i_chck_pos     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_adm_needed   IN schedule_sr.adm_needed%TYPE DEFAULT NULL,
        i_chck_pos_req IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_idwchk       OUT table_number,
        o_desc         OUT table_varchar,
        o_check        OUT table_varchar,
        o_flg_ready    OUT VARCHAR2,
        o_int_name     OUT table_varchar,
        o_type_flg     OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_wtl waiting_list%ROWTYPE;
    
    BEGIN
    
        g_error := 'GET CURRENT WTL RECORD';
        pk_alertlog.log_debug(g_error);
        SELECT wtl.*
          INTO l_wtl
          FROM waiting_list wtl
         WHERE wtl.id_waiting_list = i_id_wtl;
    
        g_error := 'CALL CORE';
        pk_alertlog.log_debug(g_error);
        IF NOT get_surg_adm_req_mand_core(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_wtl          => l_wtl,
                                          i_chck_pos     => i_chck_pos,
                                          i_adm_needed   => i_adm_needed,
                                          i_chck_pos_req => i_chck_pos_req,
                                          o_idwchk       => o_idwchk,
                                          o_desc         => o_desc,
                                          o_check        => o_check,
                                          o_flg_ready    => o_flg_ready,
                                          o_int_name     => o_int_name,
                                          o_type_flg     => o_type_flg,
                                          o_error        => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_SURG_ADM_REQ_MAND_CORE',
                                              o_error);
        
            RETURN FALSE;
    END get_surg_adm_req_mand_core;

    FUNCTION check_changes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_wtl     IN waiting_list%ROWTYPE,
        i_wtl_old IN waiting_list%ROWTYPE,
        o_result  OUT BOOLEAN,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF nvl(to_char(i_wtl.id_patient), 'null') = nvl(to_char(i_wtl_old.id_patient), 'null')
           AND nvl(to_char(i_wtl.id_prof_req), 'null') = nvl(to_char(i_wtl_old.id_prof_req), 'null')
           AND nvl(to_char(i_wtl.dt_placement), 'null') = nvl(to_char(i_wtl_old.dt_placement), 'null')
           AND nvl(to_char(i_wtl.flg_type), 'null') = nvl(to_char(i_wtl_old.flg_type), 'null')
           AND nvl(to_char(i_wtl.flg_status), 'null') = nvl(to_char(i_wtl_old.flg_status), 'null')
           AND nvl(to_char(i_wtl.dt_dpb), 'null') = nvl(to_char(i_wtl_old.dt_dpb), 'null')
           AND nvl(to_char(i_wtl.dt_dpa), 'null') = nvl(to_char(i_wtl_old.dt_dpa), 'null')
           AND nvl(to_char(i_wtl.dt_surgery), 'null') = nvl(to_char(i_wtl_old.dt_surgery), 'null')
           AND nvl(to_char(i_wtl.dt_admission), 'null') = nvl(to_char(i_wtl_old.dt_admission), 'null')
           AND nvl(to_char(i_wtl.min_inform_time), 'null') = nvl(to_char(i_wtl_old.min_inform_time), 'null')
           AND nvl(to_char(i_wtl.id_wtl_urg_level), 'null') = nvl(to_char(i_wtl_old.id_wtl_urg_level), 'null')
           AND nvl(to_char(i_wtl.id_prof_reg), 'null') = nvl(to_char(i_wtl_old.id_prof_reg), 'null')
           AND nvl(to_char(i_wtl.dt_reg), 'null') = nvl(to_char(i_wtl_old.dt_reg), 'null')
           AND nvl(to_char(i_wtl.id_cancel_reason), 'null') = nvl(to_char(i_wtl_old.id_cancel_reason), 'null')
           AND nvl(to_char(i_wtl.notes_cancel), 'null') = nvl(to_char(i_wtl_old.notes_cancel), 'null')
           AND nvl(to_char(i_wtl.id_prof_cancel), 'null') = nvl(to_char(i_wtl_old.id_prof_cancel), 'null')
           AND nvl(to_char(i_wtl.dt_cancel), 'null') = nvl(to_char(i_wtl_old.dt_cancel), 'null')
           AND nvl(to_char(i_wtl.id_external_request), 'null') = nvl(to_char(i_wtl_old.id_external_request), 'null')
           AND nvl(to_char(i_wtl.func_eval_score), 'null') = nvl(to_char(i_wtl_old.func_eval_score), 'null')
           AND nvl(to_char(i_wtl.notes_edit), 'null') = nvl(to_char(i_wtl_old.notes_edit), 'null')
        THEN
            o_result := FALSE;
        ELSE
            o_result := TRUE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'CHECK_CHANGES',
                                                     o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_changes;

    FUNCTION get_wtlist_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_wtlist    IN waiting_list.id_waiting_list%TYPE,
        i_adm_needed   IN schedule_sr.adm_needed%TYPE DEFAULT NULL,
        i_chck_pos_req IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_status       OUT waiting_list.flg_status%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_wtlist_type   waiting_list.flg_type%TYPE;
        l_wtlist_status waiting_list.flg_status%TYPE;
    
        l_flg_valid VARCHAR(1);
    
        l_schedule_surgery       NUMBER := 0;
        l_schedule_inpatient     NUMBER := 0;
        l_not_schedule_surgery   NUMBER := 0;
        l_not_schedule_inpatient NUMBER := 0;
    
        CURSOR c_wtl_epis IS
            SELECT wtle.flg_status, wtle.id_epis_type, COUNT(*) counter
              FROM wtl_epis wtle
             WHERE wtle.id_waiting_list = i_id_wtlist
             GROUP BY wtle.flg_status, wtle.id_epis_type;
    
        r_wtl_epis c_wtl_epis%ROWTYPE;
    
    BEGIN
    
        g_error := 'GET WAITING LIST TYPE AND STATUS';
        SELECT wtl.flg_type, wtl.flg_status
          INTO l_wtlist_type, l_wtlist_status
          FROM waiting_list wtl
         WHERE wtl.id_waiting_list = i_id_wtlist;
    
        /*
        *  Status workflow 
        *  A --> P,S,I
        *  P --> A,S
        *  S --> A,P
        *  I --> A
        *  C --> nothing
        */
    
        -- if waiting list is on Active, Partial or Schedule status 
        IF l_wtlist_status = g_wtlist_status_active
           OR l_wtlist_status = g_wtlist_status_partial
           OR l_wtlist_status = g_wtlist_status_schedule
        THEN
            g_error := 'COUNT SCHEDULE AND NOT SCHEDULE EPISODES';
        
            FOR r_wtl_epis IN c_wtl_epis
            LOOP
                IF r_wtl_epis.flg_status = g_wtl_epis_st_schedule
                THEN
                    IF (r_wtl_epis.id_epis_type = g_id_epis_type_surgery)
                    THEN
                        l_schedule_surgery := r_wtl_epis.counter;
                    END IF;
                    IF (r_wtl_epis.id_epis_type = g_id_epis_type_inpatient)
                    THEN
                        l_schedule_inpatient := r_wtl_epis.counter;
                    END IF;
                END IF;
            
                IF r_wtl_epis.flg_status = g_wtl_epis_st_not_schedule
                   OR r_wtl_epis.flg_status = g_wtl_epis_st_cancel_schedule
                THEN
                    IF (r_wtl_epis.id_epis_type = g_id_epis_type_surgery)
                    THEN
                        l_not_schedule_surgery := r_wtl_epis.counter;
                    END IF;
                    IF (r_wtl_epis.id_epis_type = g_id_epis_type_inpatient)
                    THEN
                        l_not_schedule_inpatient := r_wtl_epis.counter;
                    END IF;
                END IF;
            END LOOP;
        
            g_error := 'VERIFY STATUS';
        
            IF l_schedule_surgery > 0
               OR l_schedule_inpatient > 0
            THEN
                IF l_not_schedule_surgery > 0
                   OR l_not_schedule_inpatient > 0
                THEN
                    o_status := g_wtlist_status_partial;
                ELSE
                    o_status := g_wtlist_status_schedule;
                END IF;
            ELSE
                o_status := g_wtlist_status_active;
            END IF;
        END IF;
    
        -- if Active or Inactive 
        IF l_wtlist_status = g_wtlist_status_active
           OR l_wtlist_status = g_wtlist_status_inactive
        THEN
            g_error := 'READY TO WAITING LIST';
            IF get_ready_to_wtlist(i_lang             => i_lang,
                                   i_prof             => i_prof,
                                   i_id_wtlist        => i_id_wtlist,
                                   i_flg_type         => l_wtlist_type,
                                   i_pos_confirmation => pk_alert_constant.g_yes,
                                   i_chck_pos_req     => i_chck_pos_req,
                                   i_adm_needed       => i_adm_needed,
                                   o_flg_valid        => l_flg_valid,
                                   o_error            => o_error)
            THEN
                IF l_flg_valid = pk_alert_constant.g_no
                THEN
                    IF NOT (o_status = g_wtlist_status_partial OR o_status = g_wtlist_status_schedule)
                    THEN
                        o_status := g_wtlist_status_inactive;
                    END IF;
                END IF;
            
                IF l_wtlist_status = g_wtlist_status_inactive
                   AND l_flg_valid = pk_alert_constant.g_yes
                THEN
                    o_status := g_wtlist_status_active;
                END IF;
            ELSE
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WTLIST_STATUS',
                                              o_error);
        
            RETURN FALSE;
    END get_wtlist_status;

    FUNCTION get_ready_to_wtlist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_wtlist        IN waiting_list.id_waiting_list%TYPE,
        i_flg_type         IN waiting_list.flg_type%TYPE,
        i_pos_confirmation IN VARCHAR2 DEFAULT 'Y',
        i_adm_needed       IN schedule_sr.adm_needed%TYPE DEFAULT NULL,
        i_chck_pos_req     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_flg_valid        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_valid VARCHAR2(1);
        l_dummy_tn  table_number := table_number();
        l_dummy_tv  table_varchar := table_varchar();
        l_int_name  table_varchar := table_varchar();
        l_type_flg  table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'CALL CORE';
        pk_alertlog.log_debug(g_error);
        IF NOT get_surg_adm_req_mand_core(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_id_wtl       => i_id_wtlist,
                                          i_adm_needed   => i_adm_needed,
                                          i_chck_pos_req => i_chck_pos_req,
                                          o_idwchk       => l_dummy_tn,
                                          o_desc         => l_dummy_tv,
                                          o_check        => l_dummy_tv,
                                          o_flg_ready    => l_flg_valid,
                                          o_int_name     => l_int_name,
                                          o_type_flg     => l_type_flg,
                                          o_error        => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        o_flg_valid := l_flg_valid;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_READY_TO_WTLIST',
                                              o_error);
        
            RETURN FALSE;
    END get_ready_to_wtlist;

    FUNCTION get_ready_to_wl_exc_pos
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_wtlist    IN waiting_list.id_waiting_list%TYPE,
        i_chck_pos     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_chck_pos_req IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_flg_valid    OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_valid VARCHAR2(1);
    
        l_dummy_tn table_number := table_number();
        l_dummy_tv table_varchar := table_varchar();
        l_int_name table_varchar := table_varchar();
        l_type_flg table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'CALL CORE';
        pk_alertlog.log_debug(g_error);
        IF NOT get_surg_adm_req_mand_core(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_id_wtl       => i_id_wtlist,
                                          i_chck_pos     => i_chck_pos,
                                          i_chck_pos_req => i_chck_pos_req,
                                          o_idwchk       => l_dummy_tn,
                                          o_desc         => l_dummy_tv,
                                          o_check        => l_dummy_tv,
                                          o_flg_ready    => l_flg_valid,
                                          o_int_name     => l_int_name,
                                          o_type_flg     => l_type_flg,
                                          o_error        => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        o_flg_valid := l_flg_valid;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_READY_TO_WL_EXC_POS',
                                              o_error);
        
            RETURN FALSE;
    END get_ready_to_wl_exc_pos;

    FUNCTION check_adm_req_mandatory
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE,
        o_flg_valid OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CHECK ADM REQ MANDATORY';
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO o_flg_valid
              FROM adm_request ar
             INNER JOIN wtl_epis wtle
                ON wtle.id_episode = ar.id_dest_episode
             WHERE ar.id_adm_request IS NOT NULL
               AND ar.id_adm_indication IS NOT NULL
               AND ar.id_dest_inst IS NOT NULL
               AND ar.id_department IS NOT NULL
               AND ar.id_dep_clin_serv IS NOT NULL
               AND ar.expected_duration IS NOT NULL
               AND wtle.id_epis_type = pk_alert_constant.g_epis_type_inpatient
               AND ar.flg_status != pk_alert_constant.g_adm_req_status_canc
               AND wtle.id_waiting_list = i_id_wtlist;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_valid := pk_alert_constant.g_no;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_ADM_REQ_MANDATORY',
                                              o_error);
            RETURN FALSE;
    END check_adm_req_mandatory;

    FUNCTION check_surg_req_mandatory
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_wtlist        IN waiting_list.id_waiting_list%TYPE,
        i_pos_confirmation IN VARCHAR2 DEFAULT 'Y',
        o_flg_valid        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
    BEGIN
    
        g_error := 'GET SURGERY EPISODE';
        BEGIN
            SELECT wtle.id_episode
              INTO l_id_episode
              FROM wtl_epis wtle
             WHERE wtle.id_epis_type = pk_alert_constant.g_epis_type_operating
               AND wtle.id_waiting_list = i_id_wtlist;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_episode := NULL;
        END;
    
        -- check expected duration
        g_error := 'EXPECTED DURATION';
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO o_flg_valid
              FROM schedule_sr sr
             WHERE sr.id_waiting_list = i_id_wtlist
               AND sr.id_episode = l_id_episode
                  --AND sr.flg_status = pk_alert_constant.g_active
               AND sr.duration IS NOT NULL;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_valid := pk_alert_constant.g_no;
        END;
    
        IF o_flg_valid = pk_alert_constant.g_yes
        THEN
            -- LMAIA 05-05-2009
            -- For grid information it is not necessary to kcnow what is POS_AUTORIZATION state
            IF i_pos_confirmation = pk_alert_constant.g_yes
            THEN
                --POS autorization
                g_error     := 'POS AUTORIZATION';
                o_flg_valid := pk_surgery_request.get_pos_autorization(i_lang, i_prof, l_id_episode);
            END IF;
        ELSE
            IF o_flg_valid = pk_alert_constant.g_yes
            THEN
                --Surgery Specialty
                g_error := 'SURGERY SPECIALTY';
                BEGIN
                    SELECT pk_alert_constant.g_yes
                      INTO o_flg_valid
                      FROM wtl_dep_clin_serv wdcs
                     WHERE wdcs.flg_status = pk_alert_constant.g_active
                       AND wdcs.flg_type = g_wtl_dcs_type_specialty
                       AND wdcs.id_episode = l_id_episode
                       AND wdcs.id_waiting_list = i_id_wtlist
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        o_flg_valid := pk_alert_constant.g_no;
                END;
            
            ELSE
                IF o_flg_valid = pk_alert_constant.g_yes
                THEN
                    --Surgical Procedure
                    g_error := 'SURGICAL PROCEDURE';
                    BEGIN
                        SELECT pk_alert_constant.g_yes
                          INTO o_flg_valid
                          FROM sr_epis_interv sei
                         WHERE sei.id_episode_context = l_id_episode
                           AND sei.flg_status != g_sr_epis_interv_status_c
                           AND sei.flg_surg_request = pk_alert_constant.g_yes
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            o_flg_valid := pk_alert_constant.g_no;
                    END;
                
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_SURG_REQ_MANDATORY',
                                              o_error);
            RETURN FALSE;
    END check_surg_req_mandatory;

    FUNCTION check_surg_adm_req_mandatory
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE,
        o_flg_valid OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CHECK SURG ADM REQ MANDATORY';
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO o_flg_valid
              FROM waiting_list wtl
             WHERE wtl.dt_dpb IS NOT NULL
               AND wtl.dt_dpa IS NOT NULL
               AND wtl.id_waiting_list = i_id_wtlist;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_valid := pk_alert_constant.g_no;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_SURG_ADM_REQ_MANDATORY',
                                              o_error);
            RETURN FALSE;
    END check_surg_adm_req_mandatory;

    FUNCTION get_list_number_csv(i_list VARCHAR2) RETURN table_number IS
    
        l_delimiter     VARCHAR2(1) := ',';
        l_len_delimiter PLS_INTEGER;
        l_idx           PLS_INTEGER;
        l_list          VARCHAR2(32767) := i_list;
        l_aux           VARCHAR2(32767);
        l_ret           table_number := table_number();
        l_ret_idx       PLS_INTEGER := 0;
        l_out           BOOLEAN := FALSE;
    
    BEGIN
    
        IF i_list IS NOT NULL
        THEN
            l_len_delimiter := length(l_delimiter);
        
            LOOP
                EXIT WHEN l_out;
            
                l_idx     := instr(l_list, l_delimiter);
                l_ret_idx := l_ret_idx + 1;
            
                IF l_idx > 0
                THEN
                    l_ret.extend;
                    l_aux := substr(l_list, 1, l_idx - 1);
                    l_ret(l_ret_idx) := trunc(to_number(l_aux,
                                                        translate(l_aux, '1234567890', '9999999999'),
                                                        ' NLS_NUMERIC_CHARACTERS = '',.'''),
                                              g_max_decimal_prec);
                    l_list := substr(l_list, l_idx + l_len_delimiter);
                ELSE
                    l_ret.extend;
                    l_ret(l_ret_idx) := trunc(to_number(l_list,
                                                        translate(l_list, '1234567890', '9999999999'),
                                                        ' NLS_NUMERIC_CHARACTERS = '',.'''),
                                              g_max_decimal_prec);
                
                    l_out := TRUE;
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    
    END get_list_number_csv;

    FUNCTION get_list_string_csv(i_list VARCHAR2) RETURN table_varchar IS
    
        l_delimiter     VARCHAR2(1) := ',';
        l_len_delimiter PLS_INTEGER;
        l_idx           PLS_INTEGER;
        l_list          VARCHAR2(32767) := i_list;
        l_ret           table_varchar := table_varchar();
        l_ret_idx       PLS_INTEGER := 0;
        l_out           BOOLEAN := FALSE;
    
    BEGIN
    
        IF i_list IS NOT NULL
        THEN
            l_len_delimiter := length(l_delimiter);
        
            LOOP
                EXIT WHEN l_out;
            
                l_idx     := instr(l_list, l_delimiter);
                l_ret_idx := l_ret_idx + 1;
            
                IF l_idx > 0
                THEN
                    l_ret.extend;
                    l_ret(l_ret_idx) := substr(l_list, 1, l_idx - 1);
                    l_list := substr(l_list, l_idx + l_len_delimiter);
                ELSE
                    l_ret.extend;
                    l_ret(l_ret_idx) := l_list;
                    l_out := TRUE;
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    
    END get_list_string_csv;

    FUNCTION check_unav_period_overlap
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_wtl_unav     IN wtl_unav.id_wtl_unav%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_unav_start_date IN wtl_unav.dt_unav_start%TYPE,
        i_unav_end_date   IN wtl_unav.dt_unav_end%TYPE
    ) RETURN NUMBER IS
    
        l_count NUMBER(6) := 0;
    
    BEGIN
    
        g_error := 'CHECK PERIOD OVERLAP';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(*)
          INTO l_count
          FROM wtl_unav wunav
         WHERE wunav.id_waiting_list = i_id_waiting_list
           AND -- 1) New start date between an existing period
               ((wunav.dt_unav_start <= i_unav_start_date AND wunav.dt_unav_end > i_unav_start_date) OR
               -- 2) New end date between an existing period
               (wunav.dt_unav_start < i_unav_end_date AND wunav.dt_unav_end >= i_unav_end_date) OR
               -- 3) New start and end dates between an existing period
               (wunav.dt_unav_start > i_unav_start_date AND wunav.dt_unav_end < i_unav_end_date))
           AND wunav.flg_status = 'A'
           AND ((wunav.id_wtl_unav <> i_id_wtl_unav AND i_id_wtl_unav IS NOT NULL) OR (i_id_wtl_unav IS NULL));
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END check_unav_period_overlap;

    FUNCTION set_waiting_list_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        -- Common data: Scheduling period
        i_id_wtl_urg_level      IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_dt_sched_period_start IN VARCHAR2,
        i_dt_sched_period_end   IN VARCHAR2,
        i_min_inform_time       IN waiting_list.min_inform_time%TYPE,
        i_dt_surgery            IN VARCHAR2,
        i_dt_admission          IN VARCHAR2,
        -- Common data: Unavailability period
        i_unav_period_start IN table_varchar,
        i_unav_period_end   IN table_varchar,
        --
        o_msg_error   OUT VARCHAR2,
        o_title_error OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_args_error         EXCEPTION;
        l_unav_error         EXCEPTION;
        l_unav_overlap_error EXCEPTION;
        l_sched_period_error EXCEPTION;
    
        l_rowids table_varchar := NULL;
    
        l_dt_unav_start wtl_unav.dt_unav_start%TYPE;
        l_dt_unav_end   wtl_unav.dt_unav_end%TYPE;
    
        l_dt_sched_period_start waiting_list.dt_dpb%TYPE;
        l_dt_sched_period_end   waiting_list.dt_dpa%TYPE;
        l_dt_surgery            waiting_list.dt_surgery%TYPE;
        l_dt_admission          waiting_list.dt_admission%TYPE;
    
        l_status_outdated CONSTANT VARCHAR2(1) := 'O';
    
    BEGIN
    
        g_error := 'i_lang:' || i_lang || ' i_prof.id:' || i_prof.id || ' i_prof.institution:' || i_prof.institution ||
                   ' i_prof.software:' || i_prof.software || ' i_id_patient:' || i_id_patient || ' i_id_waiting_list:' ||
                   i_id_waiting_list || ' i_id_wtl_urg_level:' || i_id_wtl_urg_level || ' i_dt_sched_period_start:' ||
                   i_dt_sched_period_start || '  i_dt_sched_period_end:' || i_dt_sched_period_end ||
                   ' i_min_inform_time:' || i_min_inform_time || '  i_dt_surgery:' || i_dt_surgery ||
                   ' i_dt_admission:' || i_dt_admission;
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => g_package_name,
                              sub_object_name => 'SET_WAITING_LIST_INFO');
    
        -- Process scheduling period
        g_error := 'CONFIGURE DATES (1)';
        pk_alertlog.log_debug(g_error);
        l_dt_sched_period_start := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_sched_period_start, NULL);
        l_dt_sched_period_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_sched_period_end, NULL);
        l_dt_surgery            := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_surgery, NULL);
        l_dt_admission          := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_admission, NULL);
    
        -- Validate scheduling period dates
        IF l_dt_sched_period_start IS NOT NULL
           AND l_dt_sched_period_end IS NOT NULL
        THEN
            -- Check scheduling period dates
            IF l_dt_sched_period_start > l_dt_sched_period_end
            THEN
                g_error := 'INVALID SCHEDULING PERIOD DATES';
                pk_alertlog.log_debug(g_error);
                o_title_error := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ADM_REQUEST_T059');
                o_msg_error   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ADM_REQUEST_T091');
            
                RETURN TRUE;
            
            ELSIF l_dt_surgery IS NOT NULL
                  AND (l_dt_surgery < l_dt_sched_period_start OR l_dt_surgery > l_dt_sched_period_end) -- Check suggested surgery date
            THEN
                g_error := 'INVALID SUGGESTED SURGERY DATE';
                pk_alertlog.log_debug(g_error);
                o_title_error := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ADM_REQUEST_T059');
                o_msg_error   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ADM_REQUEST_T094');
            
                RETURN TRUE;
            
            ELSIF l_dt_surgery IS NOT NULL
                  AND l_dt_admission IS NOT NULL
                  AND trunc(l_dt_admission) > trunc(l_dt_surgery)
            THEN
                g_error := 'INVALID SUGGESTED SURGERY DATE';
                pk_alertlog.log_debug(g_error);
                o_title_error := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ADM_REQUEST_T059');
                o_msg_error   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ADM_REQUEST_T092');
            
                RETURN TRUE;
            END IF;
        END IF;
    
        -- Set scheduling period info
        -- On the call to SET_WAITING_LIST we alredy created a new waiting list, 
        -- so there's no need to outdate the current record.
        g_error := 'UPDATE WAITING LIST';
        pk_alertlog.log_debug(g_error);
        ts_waiting_list.upd(id_waiting_list_in   => i_id_waiting_list,
                            dt_dpb_in            => l_dt_sched_period_start,
                            dt_dpb_nin           => FALSE,
                            dt_dpa_in            => l_dt_sched_period_end,
                            dt_dpa_nin           => FALSE,
                            dt_surgery_in        => l_dt_surgery,
                            dt_surgery_nin       => FALSE,
                            dt_admission_in      => l_dt_admission,
                            dt_admission_nin     => FALSE,
                            min_inform_time_in   => i_min_inform_time,
                            min_inform_time_nin  => FALSE,
                            id_wtl_urg_level_in  => i_id_wtl_urg_level,
                            id_wtl_urg_level_nin => FALSE,
                            rows_out             => l_rowids);
    
        g_error := 'PROCESS UPDATE - WAITING_LIST';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'WAITING_LIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- Process unavailability periods --
        -- Set existing as outdated
        ts_wtl_unav.upd(flg_status_in => l_status_outdated,
                        where_in      => 'id_waiting_list = ' || i_id_waiting_list || ' AND flg_status = ''A''',
                        rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE - WTL_UNAV';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'WTL_UNAV',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- Create new
        IF i_unav_period_start.exists(1)
        THEN
            g_error := 'VALIDATE ARGUMENTS - UNAV. PERIODS';
            pk_alertlog.log_debug(g_error);
        
            DELETE FROM wtl_unav a
             WHERE a.id_waiting_list = i_id_waiting_list;
        
            IF i_unav_period_start.count <> i_unav_period_end.count
            THEN
                RAISE l_args_error;
            END IF;
        
            -- Start inserting unavailability periods
            FOR i IN i_unav_period_start.first .. i_unav_period_start.last
            LOOP
            
                g_error := 'CONFIGURE DATES (2) - ' || i;
                pk_alertlog.log_debug(g_error);
                l_dt_unav_start := pk_date_utils.get_string_tstz(i_lang, i_prof, i_unav_period_start(i), NULL);
                l_dt_unav_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_unav_period_end(i), NULL);
            
                -- LMAIA 01-05-2009
                --
                -- TODO: If one or two dates are NULL, dates are ignored
                --
                IF l_dt_unav_start IS NOT NULL
                   AND l_dt_unav_end IS NOT NULL
                THEN
                    -- LMAIA 01-05-2009
                    -- l_dt_unav_start and l_dt_unav_end can be NULL
                    IF l_dt_unav_start > l_dt_unav_end -- Check if start date is after end date (dates can be equal)
                       AND l_dt_unav_start IS NOT NULL
                       AND l_dt_unav_end IS NOT NULL
                    THEN
                        g_error := 'END DATE BEFORE START DATE OR NULL VALUE FOUND - ' || i;
                        pk_alertlog.log_debug(g_error);
                        RAISE l_unav_error;
                    
                    ELSE
                        g_error := 'INSERT INTO WTL_UNAV - ' || i;
                        pk_alertlog.log_debug(g_error);
                        ts_wtl_unav.ins(id_wtl_unav_in     => ts_wtl_unav.next_key,
                                        id_waiting_list_in => i_id_waiting_list,
                                        dt_unav_start_in   => l_dt_unav_start,
                                        dt_unav_end_in     => l_dt_unav_end,
                                        flg_status_in      => 'A',
                                        rows_out           => l_rowids);
                    
                        g_error := 'PROCESS INSERT - WTL_UNAV';
                        pk_alertlog.log_debug(g_error);
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'WTL_UNAV',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                        l_rowids := NULL;
                    END IF;
                END IF;
            
                -- reset variables
                l_dt_unav_start := NULL;
                l_dt_unav_end   := NULL;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_args_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_PARAM_ERROR',
                                              'INVALID_ARGUMENTS',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WAITING_LIST_INFO',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN l_sched_period_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_DATA_ERROR',
                                              'INVALID_SCHEDULING_PERIOD',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WAITING_LIST_INFO',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN l_unav_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_DATA_ERROR',
                                              'INVALID_UNAVAILABILITY_PERIOD(S)',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WAITING_LIST_INFO',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN l_unav_overlap_error THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_ret           BOOLEAN;
                l_error_message VARCHAR2(200);
            BEGIN
                l_error_message := g_error || chr(10) || chr(10) ||
                                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, l_dt_unav_start, i_prof) || ' - ' ||
                                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, l_dt_unav_end, i_prof);
            
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_WAITING_LIST_INFO',
                                   NULL,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WAITING_LIST_INFO',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_waiting_list_info;

    FUNCTION set_wtl_epis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_schedule     IN schedule.id_schedule%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids    table_varchar;
        l_count     NUMBER(6) := 0;
        l_epis_type epis_type.id_epis_type%TYPE;
    
    BEGIN
    
        g_error := 'CHECK WTL_EPIS';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(*)
          INTO l_count
          FROM wtl_epis wepi
         WHERE wepi.id_episode = i_id_episode
           AND wepi.id_waiting_list = i_id_waiting_list;
    
        IF l_count = 0
        THEN
            g_error := 'GET EPIS TYPE';
            pk_alertlog.log_debug(g_error);
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        
            g_error := 'CREATE WTL_EPIS';
            pk_alertlog.log_debug(g_error);
            ts_wtl_epis.ins(id_waiting_list_in => i_id_waiting_list,
                            id_episode_in      => i_id_episode,
                            id_epis_type_in    => l_epis_type,
                            id_schedule_in     => i_id_schedule,
                            flg_status_in      => 'N', -- Not scheduled
                            rows_out           => l_rowids);
        
            g_error := 'PROCESS INSERT - WTL_EPIS';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'WTL_EPIS',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            l_rowids := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WTL_EPIS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_wtl_epis;

    FUNCTION get_unavailability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_waiting_list  IN waiting_list.id_waiting_list%TYPE,
        i_all              IN VARCHAR2 DEFAULT 'Y',
        o_unavailabilities OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'FILL OUTPUT CURSOR';
        OPEN o_unavailabilities FOR
            SELECT u.id_wtl_unav,
                   pk_date_utils.date_send_tsz(i_lang, u.dt_unav_start, i_prof) dt_unav_start_send,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, u.dt_unav_start, i_prof.institution, i_prof.software) dt_unav_start_char,
                   -- duration in MINUTES
                   -- Add one day (24*60), so it returns "2" (days) when we have a period like 1-JAN to 2-JAN.
                   (round(pk_date_utils.get_timestamp_diff(u.dt_unav_end, u.dt_unav_start)) * 24 * 60) + 24 * 60 duration,
                   pk_date_utils.date_send_tsz(i_lang, u.dt_unav_end, i_prof) dt_unav_end_send,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, u.dt_unav_end, i_prof.institution, i_prof.software) dt_unav_end_char,
                   pk_admission_request.get_duration_desc(i_lang,
                                                          i_prof,
                                                          ((round(pk_date_utils.get_timestamp_diff(u.dt_unav_end,
                                                                                                   u.dt_unav_start)) * 24) + 24)) desc_duration
              FROM wtl_unav u
             WHERE u.id_waiting_list = i_id_waiting_list
               AND (i_all = pk_alert_constant.g_yes OR u.flg_status = pk_alert_constant.g_active);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_UNAVAILABILITY',
                                              o_error);
            pk_types.open_my_cursor(o_unavailabilities);
            RETURN FALSE;
    END get_unavailability;

    FUNCTION get_sort_keys
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_sort_keys OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_default_id PLS_INTEGER := 0;
    
    BEGIN
    
        g_error := 'OPEN CURSOR';
        OPEN o_sort_keys FOR
            SELECT wsk.id_wtl_sort_key,
                   pk_translation.get_translation(i_lang, wsk.code_desc) desc_wsk,
                   t_wskis.rank,
                   wsk.internal_name
              FROM wtl_sort_key wsk
             INNER JOIN (SELECT *
                           FROM TABLE(pk_wtl_prv_core.get_sort_keys_core(i_lang, i_prof, i_inst))) t_wskis
                ON wsk.id_wtl_sort_key = t_wskis.id_wtl_sort_key
             WHERE wsk.id_wtl_s_key_parent IS NULL
               AND wsk.flg_show_req = pk_alert_constant.g_yes
             ORDER BY t_wskis.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SORT_KEYS',
                                              o_error);
            pk_types.open_my_cursor(o_sort_keys);
            RETURN FALSE;
    END get_sort_keys;

    FUNCTION get_sort_keys_core
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_inst     IN institution.id_institution%TYPE,
        i_children IN VARCHAR2 DEFAULT 'N',
        i_wtlsk    IN wtl_sort_key.id_wtl_sort_key%TYPE DEFAULT NULL
    ) RETURN t_table_wtl_skis IS
    
        l_tn         t_table_wtl_skis := t_table_wtl_skis();
        l_err        t_error_out;
        l_default_id software.id_software%TYPE := 0;
    
    BEGIN
    
        g_error := 'COLLECT IDS';
        FOR l_rec IN (SELECT wskis.id_wtl_sort_key, wskis.rank, wsk.id_wtl_checklist, wsk.value, wsk.internal_name
                      
                        FROM wtl_sort_key wsk
                       INNER JOIN wtl_sort_key_inst_soft wskis
                          ON wsk.id_wtl_sort_key = wskis.id_wtl_sort_key
                         AND (wskis.id_institution = i_inst OR
                             (wskis.id_institution = l_default_id AND NOT EXISTS
                              (SELECT 1
                                  FROM wtl_sort_key_inst_soft nwskis
                                 WHERE nwskis.id_institution = i_inst)))
                         AND (wskis.id_software = i_prof.software OR
                             (wskis.id_software = l_default_id AND NOT EXISTS
                              (SELECT 1
                                  FROM wtl_sort_key_inst_soft nwskis
                                 WHERE nwskis.id_software = i_prof.software)))
                         AND wskis.flg_available = pk_alert_constant.g_yes
                       WHERE ((wsk.id_wtl_s_key_parent IS NULL AND i_children = pk_alert_constant.g_no) OR
                             i_children = pk_alert_constant.g_yes)
                         AND ((i_wtlsk IS NOT NULL AND wsk.id_wtl_sort_key = i_wtlsk) OR i_wtlsk IS NULL)
                       ORDER BY wskis.rank)
        LOOP
            l_tn.extend();
            l_tn(l_tn.last) := t_rec_wtl_skis(l_rec.id_wtl_sort_key,
                                              l_rec.rank,
                                              l_rec.id_wtl_checklist,
                                              l_rec.value,
                                              l_rec.internal_name);
        
        END LOOP;
    
        RETURN l_tn;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SORT_KEYS_CORE',
                                              l_err);
            RETURN NULL;
    END get_sort_keys_core;

    FUNCTION get_surg_adm_req_mandatory
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_wtl        IN waiting_list%ROWTYPE,
        i_adm_needed IN schedule_sr.adm_needed%TYPE DEFAULT NULL,
        i_screen     IN VARCHAR2 DEFAULT 'I',
        o_required   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_o_idwchk  table_number := table_number();
        l_o_desc    table_varchar := table_varchar();
        l_o_check   table_varchar := table_varchar();
        l_flg_ready VARCHAR2(1 CHAR);
        l_int_name  table_varchar := table_varchar();
        l_type_flg  table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'CALL CORE';
        pk_alertlog.log_debug(g_error);
        IF NOT get_surg_adm_req_mand_core(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_wtl       => i_wtl,
                                          i_screen    => i_screen,
                                          o_idwchk    => l_o_idwchk,
                                          o_desc      => l_o_desc,
                                          o_check     => l_o_check,
                                          o_flg_ready => l_flg_ready,
                                          o_int_name  => l_int_name,
                                          o_type_flg  => l_type_flg,
                                          o_error     => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_required FOR
            SELECT t_chk_id.value   id_wtl_checklist,
                   t_chk_desc.value desc_item,
                   t_chk_chk.value  flg_check,
                   t_chk_int.value  internal_name,
                   t_chk_typ.value  type_flg
              FROM (SELECT rownum rnum, column_value VALUE
                      FROM TABLE(l_o_idwchk)) t_chk_id
             INNER JOIN (SELECT rownum rnum, column_value VALUE
                           FROM TABLE(l_o_desc)) t_chk_desc
                ON t_chk_id.rnum = t_chk_desc.rnum
             INNER JOIN (SELECT rownum rnum, column_value VALUE
                           FROM TABLE(l_int_name)) t_chk_int
                ON t_chk_id.rnum = t_chk_int.rnum
             INNER JOIN (SELECT rownum rnum, column_value VALUE
                           FROM TABLE(l_type_flg)) t_chk_typ
                ON t_chk_id.rnum = t_chk_typ.rnum
              LEFT JOIN (SELECT rownum rnum, column_value VALUE
                           FROM TABLE(l_o_check)) t_chk_chk
                ON t_chk_chk.rnum = t_chk_desc.rnum;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_SURG_ADM_REQ_MANDATORY',
                                              o_error);
            pk_types.open_my_cursor(o_required);
            RETURN FALSE;
    END get_surg_adm_req_mandatory;

    FUNCTION get_sort_keys_children
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        i_wtlsk IN wtl_sort_key.id_wtl_sort_key%TYPE,
        o_list  OUT t_table_wtl_skis,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_default_id PLS_INTEGER := 0;
        l_list       t_table_wtl_skis := t_table_wtl_skis();
    
    BEGIN
    
        g_error := 'GET THE RANK VALUE';
        FOR l_cur IN (SELECT wsk.id_wtl_sort_key, wsk.value, wsk.id_wtl_checklist, wskis.rank
                        FROM wtl_sort_key wsk
                       INNER JOIN TABLE(pk_wtl_prv_core.get_sort_keys_core(i_lang, i_prof, nvl(i_inst, i_prof.institution), pk_alert_constant.g_yes)) wskis
                          ON wskis.id_wtl_sort_key = wsk.id_wtl_sort_key
                       WHERE wsk.id_wtl_s_key_parent = i_wtlsk
                       ORDER BY wskis.rank)
        LOOP
            l_list.extend();
            l_list(l_list.last) := t_rec_wtl_skis(l_cur.id_wtl_sort_key,
                                                  l_cur.rank,
                                                  l_cur.id_wtl_checklist,
                                                  l_cur.value,
                                                  NULL);
        
        END LOOP;
    
        o_list := l_list;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLCODE);
            dbms_output.put_line(SQLERRM);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SORT_KEYS_CHILDREN',
                                              o_error);
            RETURN FALSE;
    END get_sort_keys_children;

    FUNCTION get_sort_keys_children
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        i_wtlsk IN wtl_sort_key.id_wtl_sort_key%TYPE
    ) RETURN t_table_wtl_skis IS
    
        l_err t_error_out;
        l_rez t_table_wtl_skis := t_table_wtl_skis();
    
    BEGIN
    
        IF NOT pk_wtl_prv_core.get_sort_keys_children(i_lang  => i_lang,
                                                      i_prof  => i_prof,
                                                      i_inst  => i_inst,
                                                      i_wtlsk => i_wtlsk,
                                                      o_list  => l_rez,
                                                      o_error => l_err)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_rez;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SORT_KEYS_CHILDREN',
                                              l_err);
            RETURN NULL;
    END get_sort_keys_children;

    FUNCTION check_wtl_active_recs
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_flg_exist OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CHECK RECORDS';
        SELECT decode(COUNT(wtl.id_waiting_list), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO o_flg_exist
          FROM waiting_list wtl
         INNER JOIN wtl_epis we
            ON wtl.id_waiting_list = we.id_waiting_list
           AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient
         INNER JOIN adm_request ar
            ON ar.id_dest_episode = we.id_episode
           AND pk_utils.get_institution_parent(i_lang, i_prof, ar.id_dest_inst) = i_inst
         WHERE wtl.flg_status IN ('P', 'A');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_WTL_ACTIVE_RECS',
                                              o_error);
            RETURN FALSE;
    END check_wtl_active_recs;

    FUNCTION check_wtl_active_recs
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_inst IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
    
        l_err t_error_out;
        l_flg VARCHAR2(1);
    
    BEGIN
    
        IF NOT check_wtl_active_recs(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_inst      => i_inst,
                                     o_flg_exist => l_flg,
                                     o_error     => l_err)
        THEN
            RETURN pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_flg;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_WTL_ACTIVE_RECS',
                                              l_err);
            RETURN NULL;
    END check_wtl_active_recs;

    FUNCTION set_wtl_epis_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_waiting_list  IN waiting_list.id_waiting_list%TYPE DEFAULT NULL,
        i_id_schedule      IN wtl_epis.id_schedule%TYPE DEFAULT NULL,
        i_dt_wtl_epis_hist IN wtl_epis_hist.dt_wtl_epis_hist%TYPE DEFAULT current_timestamp,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_wtl_epis IS
            SELECT we.id_episode, we.id_waiting_list, we.id_epis_type, we.id_schedule, we.flg_status
              FROM wtl_epis we
             WHERE (we.id_episode = i_id_episode OR i_id_episode IS NULL)
               AND (we.id_waiting_list = i_id_waiting_list OR i_id_waiting_list IS NULL)
               AND (we.id_schedule = i_id_schedule OR i_id_schedule IS NULL);
    
        l_rec_wtl_epis c_wtl_epis%ROWTYPE;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        g_error := 'Get wtl epis info to send to the history table';
        pk_alertlog.log_debug(g_error);
        OPEN c_wtl_epis;
        LOOP
            FETCH c_wtl_epis
                INTO l_rec_wtl_epis;
            EXIT WHEN c_wtl_epis%NOTFOUND;
        
            g_error := 'Insert into history table.';
            pk_alertlog.log_debug(g_error);
            ts_wtl_epis_hist.ins(id_episode_in       => l_rec_wtl_epis.id_episode,
                                 dt_wtl_epis_hist_in => i_dt_wtl_epis_hist,
                                 id_waiting_list_in  => l_rec_wtl_epis.id_waiting_list,
                                 id_epis_type_in     => l_rec_wtl_epis.id_epis_type,
                                 id_schedule_in      => l_rec_wtl_epis.id_schedule,
                                 flg_status_in       => l_rec_wtl_epis.flg_status,
                                 rows_out            => l_rows_out);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WTL_EPIS_HIST',
                                              o_error);
            RETURN FALSE;
    END set_wtl_epis_hist;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    ix_out_names(ix_out_relative_urgency) := 'relative_urgency';
    ix_out_names(ix_out_id_patient) := 'id_patient';
    ix_out_names(ix_out_pat_name) := 'pat_name';
    ix_out_names(ix_out_id_dcs) := 'id_dep_clin_serv';
    ix_out_names(ix_out_dcs_name) := 'dcs_name';
    ix_out_names(ix_out_id_prof) := 'id_professional';
    ix_out_names(ix_out_prof_name) := 'prof_name';
    ix_out_names(ix_out_id_procedure) := 'id_sr_intervention';
    ix_out_names(ix_out_proc_name) := 'SURGERY_REQUEST_T001';
    ix_out_names(ix_out_id_ward) := 'id_ward';
    ix_out_names(ix_out_ward_name) := 'ward_name';
    ix_out_names(ix_out_adm_location) := 'ADM_REQUEST_T008';
    ix_out_names(ix_out_id_ind_adm) := 'id_ind_adm';
    ix_out_names(ix_out_id_ind_adm_name) := 'ADM_REQUEST_T001';
    ix_out_names(ix_out_dt_surgery) := 'SURG_ADM_REQUEST_T007';
    ix_out_names(ix_out_adm_service) := 'ADM_REQUEST_T009';
    ix_out_names(ix_out_diagnosis) := 'ADM_REQUEST_T028';
    ix_out_names(ix_out_adm_speciality) := 'ADM_REQUEST_T029';
    ix_out_names(ix_out_adm_physic) := 'ADM_REQUEST_T030';
    ix_out_names(ix_out_adm_type) := 'ADM_REQUEST_T031';
    ix_out_names(ix_out_adm_exp_duration) := 'ADM_REQUEST_T032';
    ix_out_names(ix_out_preparation) := 'ADM_REQUEST_T033';
    ix_out_names(ix_out_room_type) := 'ADM_REQUEST_T034';
    ix_out_names(ix_out_mix_nurs) := 'ADM_REQUEST_T035';
    ix_out_names(ix_out_bed_type) := 'ADM_REQUEST_T036';
    ix_out_names(ix_out_pref_room) := 'ADM_REQUEST_T037';
    ix_out_names(ix_out_nurs_int_need) := 'ADM_REQUEST_T038';
    ix_out_names(ix_out_sugg_int_date) := 'ADM_REQUEST_T039';
    ix_out_names(ix_out_notes) := 'ADM_REQUEST_T040';
    ix_out_names(ix_out_nurs_int_loc) := 'ADM_REQUEST_T052';
    ix_out_names(ix_out_sch_per_start) := 'SURG_ADM_REQUEST_T002';
    ix_out_names(ix_out_urg_level) := 'SURG_ADM_REQUEST_T003';
    ix_out_names(ix_out_sch_per_end) := 'SURG_ADM_REQUEST_T004';
    ix_out_names(ix_out_min_time_infor) := 'SURG_ADM_REQUEST_T005';
    ix_out_names(ix_out_sugg_surg_date) := 'SURG_ADM_REQUEST_T006';
    ix_out_names(ix_out_adm_date) := 'SURG_ADM_REQUEST_T008';
    ix_out_names(ix_out_unav_start) := 'SURG_ADM_REQUEST_T010';
    ix_out_names(ix_out_unav_end) := 'SURG_ADM_REQUEST_T011';
    ix_out_names(ix_out_duration) := 'SURG_ADM_REQUEST_T013';
    ix_out_names(ix_out_sug_adm_date) := 'SURG_ADM_REQUEST_T014';
    ix_out_names(ix_out_rec_num) := 'SURG_ADM_REQUEST_T037';
    ix_out_names(ix_out_surg_spec) := 'SURGERY_REQUEST_T010';
    ix_out_names(ix_out_pref_surgeon) := 'SURGERY_REQUEST_T011';
    ix_out_names(ix_out_surg_exp_duration) := 'SURGERY_REQUEST_T012';
    ix_out_names(ix_out_icu) := 'SURGERY_REQUEST_T013';
    ix_out_names(ix_out_ext_disc) := 'SURGERY_REQUEST_T014';
    ix_out_names(ix_out_dang_contam) := 'SURGERY_REQUEST_T015';
    ix_out_names(ix_out_pref_time) := 'SURGERY_REQUEST_T016';
    ix_out_names(ix_out_pref_time_reason) := 'SURGERY_REQUEST_T017';
    ix_out_names(ix_out_pos_decision) := 'SURGERY_REQUEST_T018';
    ix_out_names(ix_out_surg_notes) := 'SURGERY_REQUEST_T019';
    ix_out_names(ix_out_surg_needed) := 'SURGERY_REQUEST_T034';
    ix_out_names(ix_out_surg_location) := 'surgery location';
    ix_out_names(ix_out_surg_room) := 'surgery room';
    ix_out_names(ix_out_pat_gender) := 'patient gender';
    ix_out_names(ix_out_pat_age) := 'patient age';
    ix_out_names(ix_out_dt_dpa) := 'don''t perform after date';
    ix_out_names(ix_out_clin_serv) := 'clinical service';
    ix_out_names(ix_out_adm_needed) := 'admission needed';
    ix_out_names(ix_out_flg_type) := 'flg_type';
    ix_out_names(ix_out_flg_status) := 'flg_status';
    ix_out_names(ix_out_dt_dpb) := 'don''t perform before date';
    ix_out_names(ix_out_dt_cancel_date) := 'cancel date';
    ix_out_names(ix_out_cancel_reason) := 'cancel reason';
    ix_out_names(ix_out_id_dcs_inp) := 'id_dep_clin_serv inp';
    ix_out_names(ix_out_barthel_num) := 'ix_out_barthel_num';
    ix_out_names(ix_out_pos_validation) := 'SR_POS_M002';
    ix_out_names(ix_out_pos_validation_notes) := 'SR_POS_M004';
    ix_out_names(ix_out_surg_proc_id_content) := 'surgery procedures content ids';
    ix_out_names(ix_out_ward_list) := 'ADM_REQUEST_T065';
    ix_out_names(ix_out_ward_list_flg_esc) := 'flg_escape';
    ix_out_names(ix_out_id_adm_service) := 'admission service id';
    ix_out_names(ix_out_id_adm_type) := 'admission type id';
    ix_out_names(ix_out_id_room_type) := 'room type id';
    ix_out_names(ix_out_id_bed_type) := 'bed type id';
    ix_out_names(ix_out_id_pref_room) := 'preferred room id';
    ix_out_names(ix_out_ids_pref_surgeons) := 'preferred surgeons ids';
    ix_out_names(ix_out_id_adm_phys) := 'admission physician id';
    ix_out_names(ix_out_id_location) := 'institution id to which the request was made';

    ix_out_names(ix_out_id_regim) := 'DS_COMPONENT.CODE_DS_COMPONENT.686';
    ix_out_names(ix_out_id_benef) := 'DS_COMPONENT.CODE_DS_COMPONENT.687';
    ix_out_names(ix_out_id_precau) := 'DS_COMPONENT.CODE_DS_COMPONENT.688';
    ix_out_names(ix_out_id_contact) := 'DS_COMPONENT.CODE_DS_COMPONENT.689';
    ix_out_names(ix_out_clinical_q) := 'PROCEDURES_T163';
    ix_out_names(ix_out_proc_surgeon) := 'SURG_ADM_REQUEST_T052';
    ix_out_names(ix_out_proc_diagnosis) := 'ADM_REQUEST_T028';

END pk_wtl_prv_core;
/
