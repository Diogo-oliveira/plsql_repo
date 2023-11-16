/*-- Last Change Revision: $Rev: 2053246 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-12-15 15:47:13 +0000 (qui, 15 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_surgery_request IS
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    g_exception EXCEPTION;

    /************************************************************************************
    *****************               global variables                     ****************
    *************************************************************************************/

    --CATEGORY physician, 
    g_category_physician CONSTANT category.id_category%TYPE := 1;

    --DEPARTMENT type - Surgery Room
    g_flg_type_department_s CONSTANT department.flg_type%TYPE := 'S';

    --SR_EPIS_INTERV 
    --type coded Procedure
    g_flg_code_type_c CONSTANT sr_epis_interv.flg_code_type%TYPE := 'C';
    --surgical procedure status
    g_surg_procedure_r CONSTANT sr_epis_interv.flg_status%TYPE := 'R'; --requested
    --
    g_surg_proc_type_s CONSTANT sr_epis_interv.flg_type%TYPE := 'S'; --secondary

    FUNCTION set_sr_pos_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_sr_pos_status    IN sr_pos_schedule.id_sr_pos_status%TYPE DEFAULT NULL,
        i_id_schedule_sr      IN sr_pos_schedule.id_schedule_sr%TYPE DEFAULT NULL,
        i_flg_status          IN sr_pos_schedule.flg_status%TYPE DEFAULT NULL,
        i_id_prof_reg         IN sr_pos_schedule.id_prof_reg%TYPE DEFAULT NULL,
        i_dt_reg              IN sr_pos_schedule.dt_reg%TYPE DEFAULT NULL,
        i_dt_pos_suggested    IN sr_pos_schedule.dt_pos_suggested%TYPE DEFAULT NULL,
        i_req_notes           IN sr_pos_schedule.req_notes%TYPE DEFAULT NULL,
        i_id_prof_req         IN sr_pos_schedule.id_prof_req%TYPE DEFAULT NULL,
        i_dt_req              IN sr_pos_schedule.dt_req%TYPE DEFAULT NULL,
        i_dt_valid            IN sr_pos_schedule.dt_valid%TYPE DEFAULT NULL,
        i_valid_days          IN sr_pos_schedule.valid_days%TYPE DEFAULT NULL,
        i_decision_notes      IN sr_pos_schedule.decision_notes%TYPE DEFAULT NULL,
        i_id_prof_decision    IN sr_pos_schedule.id_prof_decision%TYPE DEFAULT NULL,
        i_dt_decision         IN sr_pos_schedule.dt_decision%TYPE DEFAULT NULL,
        io_id_sr_pos_schedule IN OUT sr_pos_schedule.id_sr_pos_schedule%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sps_rec     sr_pos_schedule%ROWTYPE;
        l_sps_rec_bck sr_pos_schedule%ROWTYPE;
        l_rows        table_varchar;
        l_ret         BOOLEAN;
    BEGIN
        BEGIN
            g_error := 'GET RECORD';
            pk_alertlog.log_debug(g_error);
            SELECT sps.*
              INTO l_sps_rec_bck
              FROM sr_pos_schedule sps
             WHERE sps.id_sr_pos_schedule = io_id_sr_pos_schedule;
        EXCEPTION
            WHEN no_data_found THEN
                io_id_sr_pos_schedule            := ts_sr_pos_schedule.next_key;
                l_sps_rec_bck.id_sr_pos_schedule := NULL;
        END;
    
        g_error := 'PREPARE RECORD';
        pk_alertlog.log_debug(g_error);
        l_sps_rec.id_sr_pos_schedule := io_id_sr_pos_schedule;
        l_sps_rec.id_sr_pos_status   := nvl(i_id_sr_pos_status, l_sps_rec_bck.id_sr_pos_status);
        l_sps_rec.id_schedule_sr     := nvl(i_id_schedule_sr, l_sps_rec_bck.id_schedule_sr);
        -- Este campo não deve ser utilizado o histórico é feito na tabela his
        l_sps_rec.flg_status       := nvl(i_flg_status, l_sps_rec_bck.flg_status);
        l_sps_rec.id_prof_reg      := nvl(i_id_prof_reg, l_sps_rec_bck.id_prof_reg);
        l_sps_rec.dt_reg           := nvl(i_dt_reg, l_sps_rec_bck.dt_reg);
        l_sps_rec.dt_pos_suggested := nvl(i_dt_pos_suggested, l_sps_rec_bck.dt_pos_suggested);
        l_sps_rec.req_notes        := nvl(i_req_notes, l_sps_rec_bck.req_notes);
        l_sps_rec.id_prof_req      := nvl(i_id_prof_req, l_sps_rec_bck.id_prof_req);
        l_sps_rec.dt_req           := nvl(i_dt_req, l_sps_rec_bck.dt_req);
        l_sps_rec.dt_valid         := nvl(i_dt_valid, l_sps_rec_bck.dt_valid);
        l_sps_rec.valid_days       := nvl(i_valid_days, l_sps_rec_bck.valid_days);
        l_sps_rec.decision_notes   := nvl(i_decision_notes, l_sps_rec_bck.decision_notes);
        l_sps_rec.id_prof_decision := nvl(i_decision_notes, l_sps_rec_bck.decision_notes);
        l_sps_rec.dt_decision      := nvl(i_dt_decision, l_sps_rec_bck.dt_decision);
    
        IF l_ret
        THEN
            g_error := 'UPDATE OR INSERT RECORD';
            pk_alertlog.log_debug(g_error);
            ts_sr_pos_schedule.upd_ins(id_sr_pos_schedule_in => l_sps_rec.id_sr_pos_schedule,
                                       id_sr_pos_status_in   => l_sps_rec.id_sr_pos_status,
                                       id_schedule_sr_in     => l_sps_rec.id_schedule_sr,
                                       flg_status_in         => l_sps_rec.flg_status,
                                       id_prof_reg_in        => l_sps_rec.id_prof_reg,
                                       dt_reg_in             => l_sps_rec.dt_reg,
                                       dt_pos_suggested_in   => l_sps_rec.dt_pos_suggested,
                                       req_notes_in          => l_sps_rec.req_notes,
                                       id_prof_req_in        => l_sps_rec.id_prof_req,
                                       dt_req_in             => l_sps_rec.dt_req,
                                       dt_valid_in           => l_sps_rec.dt_valid,
                                       valid_days_in         => l_sps_rec.valid_days,
                                       decision_notes_in     => l_sps_rec.decision_notes,
                                       id_prof_decision_in   => l_sps_rec.id_prof_decision,
                                       dt_decision_in        => l_sps_rec.dt_decision,
                                       rows_out              => l_rows);
        
            IF (l_sps_rec_bck.id_sr_pos_schedule IS NOT NULL)
            THEN
                g_error := 'PROCESS UPDATE RECORD';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SR_POS_SCHEDULE',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
                l_rows := table_varchar();
            
                g_error := 'INSERT HISTORY';
                pk_alertlog.log_debug(g_error);
                ts_sr_pos_schedule_hist.ins(id_sr_pos_schedule_hist_in => ts_sr_pos_schedule_hist.next_key,
                                            id_sr_pos_schedule_in      => l_sps_rec_bck.id_sr_pos_schedule,
                                            id_sr_pos_status_in        => l_sps_rec_bck.id_sr_pos_status,
                                            id_schedule_sr_in          => l_sps_rec_bck.id_schedule_sr,
                                            flg_status_in              => l_sps_rec_bck.flg_status,
                                            id_prof_reg_in             => l_sps_rec_bck.id_prof_reg,
                                            dt_reg_in                  => l_sps_rec_bck.dt_reg,
                                            dt_pos_suggested_in        => l_sps_rec_bck.dt_pos_suggested,
                                            req_notes_in               => l_sps_rec_bck.req_notes,
                                            id_prof_req_in             => l_sps_rec_bck.id_prof_req,
                                            dt_req_in                  => l_sps_rec_bck.dt_req,
                                            dt_valid_in                => l_sps_rec_bck.dt_valid,
                                            valid_days_in              => l_sps_rec_bck.valid_days,
                                            decision_notes_in          => l_sps_rec_bck.decision_notes,
                                            id_prof_decision_in        => l_sps_rec_bck.id_prof_decision,
                                            dt_decision_in             => l_sps_rec_bck.dt_decision,
                                            rows_out                   => l_rows);
            
                g_error := 'PROCESS INSERT HISTORY';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SR_POS_SCHEDULE_HIST',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            ELSE
                g_error := 'PROCESS INSERT RECORD';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SR_POS_SCHEDULE',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
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
                                              'SET_SR_POS_SCHEDULE',
                                              o_error);
            RETURN FALSE;
    END set_sr_pos_schedule;

    FUNCTION get_department
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_cs    OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_dept_pref dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
    
        BEGIN
            SELECT dcs.id_department
              INTO l_prof_dept_pref
              FROM dep_clin_serv dcs
              JOIN department dpt
                ON dpt.id_department = dcs.id_department
              JOIN prof_dep_clin_serv pdcs
                ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
              JOIN software_dept sdt
                ON sdt.id_dept = dpt.id_dept
             WHERE pdcs.flg_default = pk_prof_utils.g_dcs_default
                  --AND sdt.id_software = i_prof.software
               AND dpt.flg_type = g_flg_type_department_s
               AND pdcs.flg_status = pk_prof_utils.g_dcs_selected
               AND pdcs.id_professional = i_prof.id
               AND dpt.id_institution = i_prof.institution
               AND rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        l_prof_dept_pref := 66004;
    
        g_error := 'GET CURSOR CLINICAL SERVICES';
        pk_alertlog.log_debug(g_error);
        OPEN o_cs FOR
            SELECT z.id_department,
                   z.name_department,
                   xmlelement("ADDITIONAL_INFO", xmlattributes(z.flg_default)).getclobval() addit_info
              FROM (SELECT DISTINCT d.id_department,
                                    pk_translation.get_translation(i_lang => i_lang, i_code_mess => d.code_department) name_department,
                                    decode(l_prof_dept_pref,
                                           d.id_department,
                                           pk_alert_constant.g_yes,
                                           pk_alert_constant.g_no) flg_default
                      FROM department d
                     INNER JOIN dep_clin_serv dcs
                        ON d.id_department = dcs.id_department
                     WHERE d.flg_type = g_flg_type_department_s
                       AND (i_inst IS NOT NULL AND d.id_institution = i_inst)
                       AND d.flg_available = pk_alert_constant.g_yes) z
             ORDER BY 2;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEPARTMENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_cs);
        
            RETURN FALSE;
        
    END get_department;

    FUNCTION get_dep_clin_serv_ds
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        i_dept  IN department.id_department%TYPE,
        o_cs    OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dept department.id_department%TYPE;
    BEGIN
    
        IF i_dept IS NULL
        THEN
        
            BEGIN
                SELECT dcs.id_department
                  INTO l_dept
                  FROM dep_clin_serv dcs
                  JOIN department dpt
                    ON dpt.id_department = dcs.id_department
                  JOIN prof_dep_clin_serv pdcs
                    ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                  JOIN software_dept sdt
                    ON sdt.id_dept = dpt.id_dept
                 WHERE pdcs.flg_default = pk_prof_utils.g_dcs_default
                      --AND sdt.id_software = i_prof.software
                   AND dpt.flg_type = g_flg_type_department_s
                   AND pdcs.flg_status = pk_prof_utils.g_dcs_selected
                   AND pdcs.id_professional = i_prof.id
                   AND dpt.id_institution = i_prof.institution
                   AND rownum = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        
        ELSE
            l_dept := i_dept;
        
        END IF;
    
        g_error := 'GET CURSOR CLINICAL SERVICES';
        pk_alertlog.log_debug(g_error);
        OPEN o_cs FOR
            SELECT dcs.id_dep_clin_serv id_dcs,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_dcs
              FROM department d, dep_clin_serv dcs, clinical_service cs
             WHERE d.flg_type = g_flg_type_department_s
               AND (i_inst IS NOT NULL AND d.id_institution = i_inst)
               AND dcs.id_department = d.id_department
               AND (l_dept IS NULL OR dcs.id_department = l_dept)
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND cs.flg_available = pk_alert_constant.g_yes
               AND d.flg_available = pk_alert_constant.g_yes
               AND cs.id_clinical_service = dcs.id_clinical_service
             ORDER BY 2;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEP_CLIN_SERV',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_cs);
        
            RETURN FALSE;
        
    END get_dep_clin_serv_ds;

    FUNCTION get_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_cs    OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR CLINICAL SERVICES';
        pk_alertlog.log_debug(g_error);
        OPEN o_cs FOR
            SELECT dcs.id_dep_clin_serv id_dcs,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_dcs
              FROM department d, dep_clin_serv dcs, clinical_service cs
             WHERE d.flg_type = g_flg_type_department_s
               AND (i_inst IS NOT NULL AND d.id_institution = i_inst)
               AND dcs.id_department = d.id_department
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND cs.flg_available = pk_alert_constant.g_yes
               AND d.flg_available = pk_alert_constant.g_yes
               AND cs.id_clinical_service = dcs.id_clinical_service
             ORDER BY 2;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEP_CLIN_SERV',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_cs);
        
            RETURN FALSE;
        
    END get_dep_clin_serv;

    FUNCTION get_surgeons_by_dep_clin_serv
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_inst     IN institution.id_institution%TYPE,
        i_id_dcs   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_surgeons OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_dcs IS NULL
        THEN
            g_error := 'OPEN O_SURGEONS 1';
            OPEN o_surgeons FOR
                SELECT t2.id_professional data,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, t2.id_professional) label,
                       pk_alert_constant.g_no flg_select,
                       2 order_field,
                       xmlelement("ADDITIONAL_INFO", xmlattributes(decode(i_prof.id, t2.id_professional, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default)).getclobval() addict_info
                  FROM (SELECT t1.id_professional
                          FROM (SELECT id_professional
                                  FROM (SELECT /*+ use_nl(dcs pdcs) */
                                         pdcs.id_professional,
                                         row_number() over(PARTITION BY pdcs.id_professional ORDER BY pdcs.id_professional) rn
                                          FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department d, prof_cat pc
                                         WHERE d.flg_type = g_flg_type_department_s
                                           AND ((i_inst IS NOT NULL AND d.id_institution = i_inst))
                                           AND dcs.id_department = d.id_department
                                           AND dcs.flg_available = pk_alert_constant.g_yes
                                           AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                                           AND pdcs.id_professional = pc.id_professional
                                           AND pc.id_category = g_category_physician) t
                                 WHERE t.rn = 1) t1
                         WHERE pk_prof_utils.is_internal_prof(i_lang,
                                                              i_prof,
                                                              t1.id_professional,
                                                              decode(i_inst, NULL, i_prof.institution, i_inst)) =
                               pk_alert_constant.g_yes
                           AND ((SELECT pk_prof_utils.get_prof_sub_category(i_lang,
                                                                            profissional(t1.id_professional,
                                                                                         decode(i_inst,
                                                                                                NULL,
                                                                                                i_prof.institution,
                                                                                                i_inst),
                                                                                         i_prof.software))
                                   FROM dual) IS NULL OR
                                (SELECT pk_prof_utils.get_prof_sub_category(i_lang,
                                                                            profissional(t1.id_professional,
                                                                                         decode(i_inst,
                                                                                                NULL,
                                                                                                i_prof.institution,
                                                                                                i_inst),
                                                                                         i_prof.software))
                                   FROM dual) != pk_alert_constant.g_na)) t2
                 ORDER BY label;
        
        ELSE
            g_error := 'OPEN O_SURGEONS 2';
            OPEN o_surgeons FOR
                SELECT t2.id_professional data,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, t2.id_professional) label,
                       pk_alert_constant.g_no flg_select,
                       2 order_field,
                       xmlelement("ADDITIONAL_INFO", xmlattributes(decode(i_prof.id, t2.id_professional, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default)).getclobval() addict_info
                  FROM (SELECT t1.id_professional
                          FROM (SELECT id_professional
                                  FROM (SELECT /*+ use_nl(dcs pdcs) */
                                         pdcs.id_professional,
                                         row_number() over(PARTITION BY pdcs.id_professional ORDER BY pdcs.id_professional) rn
                                          FROM prof_dep_clin_serv pdcs, prof_cat pc
                                         WHERE pdcs.id_dep_clin_serv = i_id_dcs
                                           AND ((i_inst IS NOT NULL AND pdcs.id_institution = i_inst))
                                           AND pdcs.id_professional = pc.id_professional
                                           AND pc.id_category = g_category_physician) t
                                 WHERE t.rn = 1) t1
                         WHERE pk_prof_utils.is_internal_prof(i_lang,
                                                              i_prof,
                                                              t1.id_professional,
                                                              decode(i_inst, NULL, i_prof.institution, i_inst)) =
                               pk_alert_constant.g_yes
                           AND ((SELECT pk_prof_utils.get_prof_sub_category(i_lang,
                                                                            profissional(t1.id_professional,
                                                                                         decode(i_inst,
                                                                                                NULL,
                                                                                                i_prof.institution,
                                                                                                i_inst),
                                                                                         i_prof.software))
                                   FROM dual) IS NULL OR
                                (SELECT pk_prof_utils.get_prof_sub_category(i_lang,
                                                                            profissional(t1.id_professional,
                                                                                         decode(i_inst,
                                                                                                NULL,
                                                                                                i_prof.institution,
                                                                                                i_inst),
                                                                                         i_prof.software))
                                   FROM dual) != pk_alert_constant.g_na)) t2
                 ORDER BY label;
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
                                              'GET_SURGEONS_BY_DEP_CLIN_SERV',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_surgeons);
        
            RETURN FALSE;
    END get_surgeons_by_dep_clin_serv;

    FUNCTION get_sr_expected_duration
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_sr_intervention IN table_number,
        o_duration           OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SR_EXPECTED_DURATION';
    BEGIN
    
        g_error := 'START EXECUTION';
        pk_alertlog.log_debug(g_error);
        IF i_id_sr_intervention.exists(1)
        THEN
        
            g_error := 'GET SUM TOTAL';
            pk_alertlog.log_debug(g_error);
            SELECT SUM(sid.avg_duration)
              INTO o_duration
              FROM sr_interv_duration sid
             WHERE sid.id_sr_intervention IN (SELECT column_value
                                                FROM TABLE(i_id_sr_intervention))
               AND sid.flg_available = pk_alert_constant.g_yes
               AND (sid.id_institution = 0 AND NOT EXISTS
                    (SELECT 1
                       FROM sr_interv_duration sid2
                      WHERE sid2.flg_available = pk_alert_constant.g_yes
                        AND sid2.id_institution = nvl(i_id_institution, i_prof.institution)))
                OR sid.id_institution = nvl(i_id_institution, i_prof.institution);
        
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
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_sr_expected_duration;

    FUNCTION get_wtl_urg_level_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_today_insttimezone TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'GET TODAY DATE';
        pk_alertlog.log_debug(g_error);
        l_today_insttimezone := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, 'DD');
    
        g_error := 'open o_list cursor';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT DISTINCT wul.id_wtl_urg_level,
                            nvl(wul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, wul.code)) wtl_urg_level_desc,
                            wul.duration,
                            pk_date_utils.date_send(i_lang, l_today_insttimezone, i_prof) start_date,
                            pk_date_utils.date_send(i_lang, l_today_insttimezone + to_number(wul.duration), i_prof) end_date
              FROM (SELECT w.duration, w.flg_available, w.id_wtl_urg_level, w.code, w.desc_wtl_urg_level, w.flg_status
                      FROM wtl_urg_level w
                     WHERE (w.id_institution = i_prof.institution OR
                           i_prof.institution IN (SELECT ig.id_institution
                                                     FROM institution_group ig
                                                    WHERE ig.id_group = w.id_group))
                    
                    ) wul
             WHERE (wul.flg_status IS NULL OR wul.flg_status <> pk_alert_constant.g_flg_status_c)
               AND wul.flg_available = pk_alert_constant.g_yes
             ORDER BY wtl_urg_level_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WTL_URG_LEVEL_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END get_wtl_urg_level_list;

    FUNCTION get_wtl_urg_level_list_ds
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_lvl_urg IN wtl_urg_level.id_wtl_urg_level%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_today_insttimezone TIMESTAMP WITH TIME ZONE;
    
    BEGIN
    
        g_error              := 'GET TODAY DATE';
        l_today_insttimezone := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, 'DD');
    
        g_error := 'open o_list cursor';
        OPEN o_list FOR
            SELECT t.id_wtl_urg_level,
                   t.wtl_urg_level_desc,
                   t.duration,
                   t.start_date,
                   t.end_date,
                   xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)).getclobval() addit_info,
                   decode(t.flg_default, pk_alert_constant.g_yes, pk_alert_constant.g_yes, pk_alert_constant.g_no) lvl_default
              FROM (SELECT DISTINCT wul.id_wtl_urg_level,
                                    nvl(wul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, wul.code)) wtl_urg_level_desc,
                                    wul.duration,
                                    pk_date_utils.date_send(i_lang, l_today_insttimezone, i_prof) start_date,
                                    pk_date_utils.date_send(i_lang,
                                                            l_today_insttimezone + to_number(wul.duration),
                                                            i_prof) end_date,
                                    decode(wul.id_wtl_urg_level,
                                           i_lvl_urg,
                                           pk_alert_constant.g_yes,
                                           pk_alert_constant.g_no) flg_default
                      FROM (SELECT w.duration,
                                   w.flg_available,
                                   w.id_wtl_urg_level,
                                   w.code,
                                   w.desc_wtl_urg_level,
                                   w.flg_status
                              FROM wtl_urg_level w
                             WHERE (w.id_institution = i_prof.institution OR
                                   i_prof.institution IN (SELECT ig.id_institution
                                                             FROM institution_group ig
                                                            WHERE ig.id_group = w.id_group
                                                              AND ig.flg_relation = 'INST_CNT'))) wul
                     WHERE (wul.flg_status IS NULL OR wul.flg_status <> pk_alert_constant.g_flg_status_c)
                       AND wul.flg_available = pk_alert_constant.g_yes
                     ORDER BY wtl_urg_level_desc) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WTL_URG_LEVEL_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END get_wtl_urg_level_list_ds;

    FUNCTION get_wtl_ptreason_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT NOCOPY pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_LIST';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT DISTINCT wp.id_wtl_ptreason, pk_translation.get_translation(i_lang, wp.code) label
              FROM wtl_ptreason wp
             WHERE wp.flg_available = pk_alert_constant.g_yes
               AND ((wp.id_institution = 0 AND NOT EXISTS
                    (SELECT 1
                        FROM wtl_ptreason wp2
                       WHERE wp2.id_institution = nvl(i_id_institution, i_prof.institution)
                         AND wp2.flg_available = pk_alert_constant.g_yes)) OR
                   (wp.id_institution = nvl(i_id_institution, i_prof.institution)))
             ORDER BY label;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SURGERY_REQUEST',
                                              'GET_WTL_PTREASON_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_wtl_ptreason_list;

    FUNCTION get_pos_decision_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT NOCOPY pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN O_LIST';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT DISTINCT sps.id_sr_pos_status,
                            pk_translation.get_translation(i_lang, sps.code) label,
                            sps.flg_type_approval
              FROM sr_pos_status sps
             WHERE sps.flg_available = pk_alert_constant.g_yes
               AND ((sps.id_institution = 0 AND NOT EXISTS
                    (SELECT 1
                        FROM sr_pos_status sps2
                       WHERE sps2.flg_available = pk_alert_constant.g_yes
                         AND sps2.id_institution = nvl(i_id_institution, i_prof.institution))) OR
                   (sps.id_institution = nvl(i_id_institution, i_prof.institution)))
             ORDER BY label;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SURGERY_REQUEST',
                                              'GET_POS_DECISION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_pos_decision_list;

    FUNCTION get_surg_req_grid_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_flg_context         IN VARCHAR2,
        o_grid_planned        OUT pk_types.cursor_type,
        o_grid_emergent       OUT pk_types.cursor_type,
        o_is_anesthesiologist OUT VARCHAR2,
        o_prof_editable       OUT VARCHAR2,
        o_prof_access_ok      OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(30) := 'GET_SURG_REQ_GRID_TYPE';
        l_sr_episodes          t_tbl_sr_episodes;
        l_sr_planned_episodes  t_tbl_sr_episodes;
        l_sr_emergent_episodes t_tbl_sr_episodes;
        l_num_records          PLS_INTEGER;
        l_num_planned_records  PLS_INTEGER := 0;
        l_num_emergent_records PLS_INTEGER := 0;
        l_task_type            task_type.id_task_type%TYPE := 27;
    BEGIN
        -- Call GET_SR_EPISODES
        g_error       := 'CALL FUNCTION GET_SR_EPISODES';
        l_sr_episodes := get_sr_episodes(i_lang, i_prof, i_id_patient, NULL, NULL);
    
        --If Aggregated
        IF i_flg_context = g_flg_context_aggregated_a
        THEN
        
            --Obtém cursor com os episódios de bloco
            g_error := 'GET CURSOR';
            pk_alertlog.log_debug(g_error);
            OPEN o_grid_planned FOR
                SELECT id_patient,
                       id_episode,
                       id_schedule_sr,
                       id_waiting_list,
                       surg_proc,
                       flg_status,
                       admiss_epis_done,
                       surgery_epis_done,
                       waiting_list_type,
                       adm_needed,
                       dt_surgery,
                       dt_surgery_str,
                       duration,
                       duration_minutes,
                       pos_status,
                       admiss_status,
                       oris_status,
                       sr_type,
                       sr_type_icon,
                       id_inst_surg,
                       inst_surg_name,
                       sr_status,
                       flg_pos_expired,
                       flg_surg_nat,
                       desc_surg_nat,
                       flg_priority,
                       desc_priority,
                       flg_sr_proc,
                       id_room,
                       desc_room,
                       flg_request_edit,
                       (SELECT COUNT(*) - 1
                          FROM wtl_unav un
                         WHERE un.id_waiting_list = t_grid.id_waiting_list) unav_number,
                       l_task_type task_type,
                       pk_sr_pos.check_pos_status(i_lang, i_prof, t_grid.id_episode) check_pos_status
                  FROM TABLE(l_sr_episodes) t_grid
                 ORDER BY oris_status, dt_surgery DESC;
        
            pk_types.open_my_cursor(o_grid_emergent);
        
            --If Categorized
        ELSE
            IF l_sr_episodes IS NULL
            THEN
                l_num_records := 0;
            ELSE
                l_num_records := l_sr_episodes.count;
            END IF;
        
            l_sr_planned_episodes  := t_tbl_sr_episodes();
            l_sr_emergent_episodes := t_tbl_sr_episodes();
        
            FOR i IN 1 .. l_num_records
            LOOP
                IF l_sr_episodes(i).sr_type != pk_alert_constant.g_no
                THEN
                    l_num_planned_records := l_num_planned_records + 1;
                    l_sr_planned_episodes.extend;
                    l_sr_planned_episodes(l_num_planned_records) := l_sr_episodes(i);
                ELSE
                    l_num_emergent_records := l_num_emergent_records + 1;
                    l_sr_emergent_episodes.extend;
                    l_sr_emergent_episodes(l_num_emergent_records) := l_sr_episodes(i);
                END IF;
            END LOOP;
        
            OPEN o_grid_planned FOR
                SELECT id_patient,
                       id_episode,
                       id_schedule_sr,
                       id_waiting_list,
                       surg_proc,
                       flg_status,
                       admiss_epis_done,
                       surgery_epis_done,
                       waiting_list_type,
                       adm_needed,
                       dt_surgery,
                       dt_surgery_str,
                       duration,
                       duration_minutes,
                       pos_status,
                       admiss_status,
                       oris_status,
                       sr_type,
                       sr_type_icon,
                       id_inst_surg,
                       inst_surg_name,
                       sr_status,
                       flg_pos_expired,
                       flg_surg_nat,
                       desc_surg_nat,
                       flg_priority,
                       desc_priority,
                       flg_sr_proc,
                       id_room,
                       desc_room,
                       flg_request_edit,
                       (SELECT COUNT(*) - 1
                          FROM wtl_unav un
                         WHERE un.id_waiting_list = t_grid.id_waiting_list) unav_number,
                       l_task_type task_type,
                       pk_sr_pos.check_pos_status(i_lang, i_prof, t_grid.id_episode) check_pos_status
                  FROM TABLE(l_sr_planned_episodes) t_grid
                 ORDER BY oris_status, dt_surgery DESC;
        
            OPEN o_grid_emergent FOR
                SELECT id_patient,
                       id_episode,
                       id_schedule_sr,
                       id_waiting_list,
                       surg_proc,
                       flg_status,
                       admiss_epis_done,
                       surgery_epis_done,
                       waiting_list_type,
                       adm_needed,
                       dt_surgery,
                       dt_surgery_str,
                       duration,
                       duration_minutes,
                       pos_status,
                       admiss_status,
                       oris_status,
                       sr_type,
                       sr_type_icon,
                       id_inst_surg,
                       inst_surg_name,
                       sr_status,
                       flg_pos_expired,
                       flg_surg_nat,
                       desc_surg_nat,
                       flg_priority,
                       desc_priority,
                       flg_sr_proc,
                       id_room,
                       desc_room,
                       (SELECT COUNT(*) - 1
                          FROM wtl_unav un
                         WHERE un.id_waiting_list = t_grid.id_waiting_list) unav_number,
                       l_task_type task_type
                  FROM TABLE(l_sr_emergent_episodes) t_grid
                 ORDER BY oris_status, dt_surgery DESC;
        END IF;
    
        -- Check if current professional is an anesthesiologist and if he/she has permissions to edit current surgery/admission request
        g_error := 'CALL TO PK_SURGERY_REQUEST.CHECK_EDIT_PERMISSIONS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_surgery_request.check_edit_permissions(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_type_request        => g_surgery_type_req,
                                                         o_is_anesthesiologist => o_is_anesthesiologist,
                                                         o_prof_editable       => o_prof_editable,
                                                         o_prof_access_ok      => o_prof_access_ok,
                                                         o_error               => o_error)
        THEN
            o_is_anesthesiologist := pk_alert_constant.g_no;
            o_prof_editable       := pk_alert_constant.g_no;
            o_prof_access_ok      := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_grid_planned);
            pk_types.open_my_cursor(o_grid_emergent);
            RETURN FALSE;
    END get_surg_req_grid_type;

    FUNCTION get_surg_req_grid_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start_date TIMESTAMP(6) WITH LOCAL TIME ZONE := NULL;
        l_end_date   TIMESTAMP(6) WITH LOCAL TIME ZONE := NULL;
    BEGIN
    
        --convert string to date format
        IF i_start_date IS NOT NULL
        THEN
            l_start_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_start_date, NULL);
        END IF;
        IF i_end_date IS NOT NULL
        THEN
            l_end_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_end_date, NULL);
        END IF;
    
        -- Call GET_SR_EPISODES
        g_error := 'CALL FUNCTION GET_SR_EPISODES';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT *
              FROM TABLE(get_sr_episodes_int(i_lang,
                                             i_prof,
                                             i_scope,
                                             i_flg_scope,
                                             l_start_date,
                                             l_end_date,
                                             i_cancelled,
                                             i_crit_type,
                                             i_flg_report)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SURG_REQ_GRID_REP',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_surg_req_grid_rep;

    FUNCTION get_pos_autorization
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_type_approval sr_pos_status.flg_type_approval%TYPE := pk_alert_constant.g_no;
        l_func_name     VARCHAR2(30) := 'GET_POS_AUTORIZATION';
        l_error         t_error_out;
    BEGIN
        g_error := 'GET TYPE APPROVAL';
        pk_alertlog.log_debug(g_error);
        SELECT p.flg_type_approval
          INTO l_type_approval
          FROM (SELECT pst.flg_type_approval
                  FROM schedule_sr sr
                 INNER JOIN sr_pos_schedule pos
                    ON pos.id_schedule_sr = sr.id_schedule_sr
                 INNER JOIN sr_pos_status pst
                    ON pst.id_sr_pos_status = pos.id_sr_pos_status
                 WHERE --pos.flg_status = pk_alert_constant.g_active
                 sr.id_episode = i_id_episode
                 ORDER BY pos.dt_req DESC, pos.dt_reg DESC) p
         WHERE rownum = 1;
    
        RETURN l_type_approval;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_type_approval;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RAISE g_exception;
    END get_pos_autorization;

    FUNCTION get_pos_decision
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_pos        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'GET_POS_DECISION';
    
    BEGIN
        g_error := 'GET POS DECISION';
        pk_alertlog.log_debug(g_error);
        OPEN o_pos FOR
            SELECT p.id_sr_pos_status, p.pos_decision
              FROM (SELECT pos.id_sr_pos_status, pk_translation.get_translation(i_lang, pst.code) pos_decision
                      FROM schedule_sr sr
                     INNER JOIN sr_pos_schedule pos
                        ON pos.id_schedule_sr = sr.id_schedule_sr
                     INNER JOIN sr_pos_status pst
                        ON pst.id_sr_pos_status = pos.id_sr_pos_status
                     WHERE sr.id_episode = i_id_episode
                    -- AND pos.flg_status = pk_alert_constant.g_active
                     ORDER BY pos.dt_req DESC, pos.dt_reg DESC) p
             WHERE rownum = 1;
        -- Return the current (active) POS decision
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_pos);
            RETURN FALSE;
    END get_pos_decision;

    FUNCTION get_pos_decision_string
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'GET_POS_DECISION_STRING';
        l_str_aux   VARCHAR2(2000) := NULL;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET POS DECISION';
        pk_alertlog.log_debug(g_error);
        SELECT pk_utils.concat_table(CAST(MULTISET (SELECT p.pos_decision
                                             FROM (SELECT pk_translation.get_translation(i_lang, pst.code) pos_decision
                                                     FROM schedule_sr sr
                                                    INNER JOIN sr_pos_schedule pos
                                                       ON pos.id_schedule_sr = sr.id_schedule_sr
                                                    INNER JOIN sr_pos_status pst
                                                       ON pst.id_sr_pos_status = pos.id_sr_pos_status
                                                    WHERE sr.id_episode = i_id_episode
                                                   -- AND pst.flg_status = pk_alert_constant.g_active
                                                    ORDER BY pos.dt_req DESC, pos.dt_reg DESC) p
                                            WHERE rownum = 1) AS table_varchar))
          INTO l_str_aux
          FROM dual;
    
        RETURN l_str_aux;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RAISE g_exception;
            -- RETURN NULL;
    END get_pos_decision_string;

    FUNCTION check_pos_requested
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name     VARCHAR2(30) := 'CHECK_POS_REQUESTED';
        l_pos_requested VARCHAR2(1) := pk_alert_constant.g_no;
        l_count         NUMBER := 0;
        l_error         t_error_out;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM schedule_sr sr
          JOIN sr_pos_schedule sps
            ON sps.id_schedule_sr = sr.id_schedule_sr
         WHERE sr.id_waiting_list = i_id_waiting_list
           AND sps.flg_status = pk_alert_constant.g_active
           AND sr.flg_status = pk_alert_constant.g_active
           AND sps.dt_pos_suggested IS NOT NULL;
    
        IF l_count > 0
        THEN
            l_pos_requested := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_pos_requested;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_pos_requested;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
    END check_pos_requested;

    FUNCTION get_duration
    (
        i_lang     IN language.id_language%TYPE,
        i_duration IN schedule_sr.duration%TYPE
    ) RETURN VARCHAR2 IS
        --
        l_num_hours   NUMBER(24) := 0;
        l_num_minutes NUMBER(24) := 0;
        --
        l_desc_minutes  VARCHAR2(20);
        l_duration_str  VARCHAR2(30);
        l_descript_mins VARCHAR2(30) := pk_message.get_message(i_lang, 'COMMON_M091');
        l_total_num_min NUMBER(24) := 60;
    
    BEGIN
    
        IF i_duration IS NOT NULL
        THEN
            -- Get number of hours
            g_error := 'GET HOURS';
            pk_alertlog.log_debug(g_error);
            l_num_hours := floor(i_duration / l_total_num_min);
        
            -- Get number of minutes
            g_error := 'GET MINUTES';
            pk_alertlog.log_debug(g_error);
            l_num_minutes := MOD(i_duration, l_total_num_min);
        
            -- Get string with number of minutes (if necessary puts an zero in the left)
            IF ((l_num_minutes IS NULL) OR (l_num_minutes = 0 AND l_num_hours = 0))
            THEN
                RETURN '';
            ELSIF l_num_minutes BETWEEN 1 AND 10
                  AND l_num_hours > 0
            THEN
                l_desc_minutes := '0' || l_num_minutes;
            ELSIF l_num_minutes = 0
                  AND l_num_hours > 0
            THEN
                l_desc_minutes := '';
            ELSE
                l_desc_minutes := l_num_minutes;
            END IF;
        
            IF l_num_minutes = 1
            THEN
                l_descript_mins := pk_message.get_message(i_lang, 'COMMON_M090');
            ELSIF l_num_minutes = 0
                  AND l_num_hours > 0
            THEN
                l_descript_mins := '';
            END IF;
        
            -- Get string with number of hours and minutes
            IF l_num_hours > 0
            THEN
                l_duration_str := l_num_hours || pk_message.get_message(i_lang, 'HOURS_SIGN') || ' ' || l_desc_minutes ||
                                  l_descript_mins;
            ELSE
                l_duration_str := l_desc_minutes || l_descript_mins;
            END IF;
        
        END IF;
    
        --
        RETURN l_duration_str;
    END get_duration;

    FUNCTION check_prof_pt_market
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_pt_professional OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_market NUMBER;
        l_func_name VARCHAR2(30) := 'CHECK_PROF_NL_MARKET';
    
    BEGIN
    
        --Obtém cursor com os episódios de bloco
        g_error := 'GET MARKET ID';
        pk_alertlog.log_debug(g_error);
        BEGIN
        
            SELECT i.id_market
              INTO l_id_market
              FROM institution i
             WHERE i.id_institution = i_prof.institution;
        
        EXCEPTION
            WHEN no_data_found THEN
                SELECT ptm.id_market
                  INTO l_id_market
                  FROM profile_template_market ptm, prof_profile_template ppt, profile_template pt
                 WHERE ppt.id_profile_template = pt.id_profile_template
                   AND ptm.id_profile_template = ppt.id_profile_template
                   AND ppt.id_software = pt.id_software
                   AND ppt.id_institution = i_prof.institution
                   AND ppt.id_professional = i_prof.id;
        END;
    
        -- Return if this professional is a PT professional
        IF (l_id_market = pk_alert_constant.g_id_market_pt)
        THEN
            o_pt_professional := pk_alert_constant.g_yes;
        ELSE
            o_pt_professional := pk_alert_constant.g_no;
        END IF;
    
        --o_pt_professional := pk_alert_constant.g_no;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END check_prof_pt_market;

    FUNCTION get_begin_end_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_epis_type    IN wtl_epis.id_epis_type%TYPE,
        o_dt_begin_null   OUT VARCHAR2,
        o_disch_null      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SURG_REQ_GRID';
        --
    BEGIN
        -- Get if episode has begun
        IF i_id_epis_type = pk_alert_constant.g_epis_type_operating
        THEN
            -- (it begins when sr_surgery_time_det.dt_surgery_time_det_tstz is not null)
            BEGIN
                g_error := 'GET IF EPISODE ALREADY BEGUN';
                pk_alertlog.log_debug(g_error);
                SELECT decode(std.dt_surgery_time_det_tstz, NULL, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                  INTO o_dt_begin_null
                  FROM episode epi
                 INNER JOIN wtl_epis we
                    ON (we.id_episode = epi.id_episode)
                 INNER JOIN waiting_list wl
                    ON (we.id_waiting_list = wl.id_waiting_list)
                 INNER JOIN sr_surgery_time_det std
                    ON (std.id_episode = epi.id_episode)
                 INNER JOIN sr_surgery_time st
                    ON st.id_sr_surgery_time = std.id_sr_surgery_time
                 WHERE we.id_epis_type = i_id_epis_type
                   AND wl.id_waiting_list = i_id_waiting_list
                   AND st.flg_type = 'EB'
                   AND std.flg_status = pk_alert_constant.g_active
                   AND rownum = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    -- if there is no admission episode (l_dt_begin_null = 'Y')
                    o_dt_begin_null := pk_alert_constant.g_yes;
            END;
        ELSE
            -- (it begins when the episode was already registered)
            BEGIN
                g_error := 'GET IF EPISODE HAD ALREADY BEEN REGISTERED';
                pk_alertlog.log_debug(g_error);
                SELECT decode(epi.flg_ehr,
                               pk_alert_constant.g_epis_ehr_schedule,
                               pk_alert_constant.g_yes,
                               CASE
                                   WHEN epi.dt_begin_tstz < current_timestamp THEN
                                    pk_alert_constant.g_no
                                   ELSE
                                    pk_alert_constant.g_yes
                               END)
                  INTO o_dt_begin_null
                  FROM episode epi
                 INNER JOIN wtl_epis we
                    ON (we.id_episode = epi.id_episode)
                 INNER JOIN waiting_list wl
                    ON (we.id_waiting_list = wl.id_waiting_list)
                 INNER JOIN adm_request ar
                    ON (ar.id_dest_episode = we.id_episode)
                 WHERE we.id_epis_type = i_id_epis_type
                   AND wl.id_waiting_list = i_id_waiting_list;
            EXCEPTION
                WHEN OTHERS THEN
                    -- if there is no admission episode (l_dt_begin_null = 'Y')
                    o_dt_begin_null := pk_alert_constant.g_yes;
            END;
        END IF;
    
        -- Get if episode has discharge (INP->administrative, ORIS ->active discharge or administrative discharge)
        BEGIN
            g_error := 'GET IF EPISODE ALREADY HAS DISCHARGE';
            pk_alertlog.log_debug(g_error);
            SELECT decode(COUNT(0), 0, pk_alert_constant.g_yes, pk_alert_constant.g_no)
              INTO o_disch_null
              FROM discharge dis
             INNER JOIN wtl_epis we
                ON (we.id_episode = dis.id_episode)
             INNER JOIN waiting_list wl
                ON (we.id_waiting_list = wl.id_waiting_list)
             WHERE we.id_epis_type = i_id_epis_type
               AND wl.id_waiting_list = i_id_waiting_list
               AND dis.flg_status = pk_alert_constant.g_active
               AND ((i_id_epis_type = pk_alert_constant.g_epis_type_operating AND
                   (dis.dt_med_tstz IS NOT NULL OR
                   (pk_discharge_core.check_admin_discharge(i_lang, NULL, dis.id_discharge, dis.flg_status_adm) =
                   pk_alert_constant.g_yes))) OR
                   (i_id_epis_type = pk_alert_constant.g_epis_type_inpatient AND
                   pk_discharge_core.check_admin_discharge(i_lang, NULL, dis.id_discharge, dis.flg_status_adm) =
                   pk_alert_constant.g_yes));
        EXCEPTION
            WHEN OTHERS THEN
                -- if there is no admission episode (l_disch_null = 'Y')
                o_disch_null := pk_alert_constant.g_yes;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_begin_end_episode;

    FUNCTION get_sr_pos_status_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_status      IN sr_pos_schedule.flg_status%TYPE,
        i_sr_pos_status   IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_schedule_sr  IN schedule_sr.id_schedule_sr%TYPE
    ) RETURN VARCHAR2 IS
    
        l_display_type     VARCHAR2(30) := '';
        l_back_color       VARCHAR2(30) := '';
        l_status_flg       VARCHAR2(30) := '';
        l_icon_color       VARCHAR2(30) := '';
        l_aux              VARCHAR2(200);
        l_date_begin       VARCHAR2(200);
        l_profile_template profile_template.id_profile_template%TYPE;
    
        l_prof_editable       VARCHAR2(1);
        l_prof_access_ok      VARCHAR2(1);
        l_is_anesthesiologist VARCHAR2(1);
        l_pos_flg_status      VARCHAR2(2);
    
        l_duration_str        VARCHAR2(4000);
        l_waiting_list_status VARCHAR2(2);
        l_error_out           t_error_out;
    
        CURSOR c_info IS
            SELECT NULL date_begin, -- dt_begin             
                   'SR_POS_STATUS.FLG_STATUS' desc_stat, -- l_aux             
                   pk_alert_constant.g_display_type_icon flg_text, -- l_display_type             
                   NULL color_status, -- l_back_color                               
                   sps.flg_status status_flg -- status_flg
              FROM sr_pos_status sps
             WHERE sps.id_sr_pos_status = i_sr_pos_status;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET PROFESSIONAL PROFILE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_clinical_notes.get_profile_template(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      o_profile_template => l_profile_template,
                                                      o_error            => l_error_out)
        THEN
            RAISE no_data_found;
        END IF;
    
        g_error := 'GET WAITING LIST STATUS STRING';
        pk_alertlog.log_debug(g_error);
        OPEN c_info;
        FETCH c_info
            INTO l_date_begin, l_aux, l_display_type, l_back_color, l_status_flg;
        CLOSE c_info;
    
        IF l_status_flg = pk_alert_constant.g_sr_pos_status_nd
        THEN
        
            -- Check if current professional is an anesthesiologist and if he/she has permissions to edit current surgery/admission request
            g_error := 'CALL TO PK_SURGERY_REQUEST.CHECK_EDIT_PERMISSIONS';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_surgery_request.check_edit_permissions(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_type_request        => pk_alert_constant.g_epis_type_operating,
                                                             o_is_anesthesiologist => l_is_anesthesiologist,
                                                             o_prof_editable       => l_prof_editable,
                                                             o_prof_access_ok      => l_prof_access_ok,
                                                             o_error               => l_error_out)
            THEN
                l_is_anesthesiologist := pk_alert_constant.g_no;
                l_prof_editable       := pk_alert_constant.g_no;
                l_prof_access_ok      := pk_alert_constant.g_no;
            END IF;
        
            SELECT wl.flg_status
              INTO l_waiting_list_status
              FROM waiting_list wl
             WHERE wl.id_waiting_list = i_id_waiting_list;
        
            -- If current professional can edit request, 
            IF l_is_anesthesiologist = pk_alert_constant.g_yes
               AND l_waiting_list_status <> pk_alert_constant.g_schedule_sr_status_c
            THEN
                l_back_color := pk_alert_constant.g_color_red;
            END IF;
        
            IF l_waiting_list_status IN (pk_alert_constant.g_wl_status_s, pk_alert_constant.g_wl_status_a)
            THEN
                l_aux          := 'WAITING_LIST.FLG_STATUS';
                l_display_type := pk_alert_constant.g_display_type_icon;
                l_status_flg   := l_waiting_list_status;
            END IF;
            -- validar se o episodio de especialidade do POS já está a decorrer.
            BEGIN
                SELECT flg_status
                  INTO l_pos_flg_status
                  FROM (SELECT (CASE --EXPIRED 
                                    WHEN sps.dt_valid < current_timestamp THEN
                                     pk_alert_constant.g_sr_pos_status_ex
                                    WHEN ss.flg_status = pk_alert_constant.g_schedule_sr_status_c THEN
                                     pk_alert_constant.g_sr_pos_status_c
                                    WHEN e.flg_status = pk_alert_constant.g_epis_status_inactive
                                         AND ei.flg_status NOT IN
                                         (pk_alert_constant.g_epis_physician_discharge,
                                              pk_alert_constant.g_epis_adm_discharge) THEN
                                     pk_alert_constant.g_sr_pos_status_nd
                                --ONGOING
                                    WHEN e.flg_status = pk_alert_constant.g_epis_status_active
                                         AND ei.flg_status <> pk_alert_constant.g_epis_pat_waiting THEN
                                     pk_alert_constant.g_sr_pos_status_u
                                --SCHEDULED
                                    WHEN e.flg_status = pk_alert_constant.g_epis_status_active
                                         AND ei.flg_status = pk_alert_constant.g_epis_pat_waiting THEN
                                     pk_alert_constant.g_sr_pos_status_s
                                --NÃO AGENDADO
                                    WHEN s.id_schedule IS NULL THEN
                                     pk_alert_constant.g_sr_pos_status_ns
                                --SCHEDULED
                                    WHEN (s.id_schedule IS NOT NULL AND ei.id_episode IS NULL) THEN
                                     pk_alert_constant.g_sr_pos_status_s
                                --DISCHARGE
                                    WHEN ei.flg_status IN (pk_alert_constant.g_epis_physician_discharge,
                                                           pk_alert_constant.g_epis_adm_discharge) THEN
                                     CASE
                                         WHEN spst.flg_status IS NOT NULL THEN
                                          spst.flg_status
                                         ELSE
                                          pk_alert_constant.g_sr_pos_status_nd
                                     END
                                    ELSE
                                     pk_alert_constant.g_sr_pos_status_nd
                                END) flg_status,
                               rank() over(ORDER BY sps.dt_reg DESC) origin_rank
                          FROM sr_pos_schedule sps
                         INNER JOIN schedule_sr ss
                            ON ss.id_schedule_sr = sps.id_schedule_sr
                          LEFT JOIN consult_req cr
                            ON cr.id_consult_req = sps.id_pos_consult_req
                          LEFT JOIN schedule s
                            ON s.id_schedule = cr.id_schedule
                           AND s.flg_status != pk_grid.g_sched_canc
                          LEFT JOIN epis_info ei
                            ON ei.id_schedule = s.id_schedule
                          LEFT JOIN episode e
                            ON e.id_episode = ei.id_episode
                          LEFT JOIN sr_pos_status spst
                            ON spst.id_sr_pos_status = sps.id_sr_pos_status
                           AND e.flg_status != pk_alert_constant.g_cancelled
                         WHERE sps.id_schedule_sr = i_id_schedule_sr)
                 WHERE origin_rank = 1;
            END;
        ELSE
            BEGIN
                SELECT flg_status
                  INTO l_pos_flg_status
                  FROM (SELECT (CASE --EXPIRED 
                                    WHEN sps.dt_valid < current_timestamp THEN
                                     pk_alert_constant.g_sr_pos_status_ex
                                    ELSE
                                     l_status_flg
                                END) flg_status,
                               rank() over(ORDER BY sps.dt_reg DESC) origin_rank
                          FROM sr_pos_schedule sps
                         INNER JOIN schedule_sr ss
                            ON ss.id_schedule_sr = sps.id_schedule_sr
                          LEFT JOIN consult_req cr
                            ON cr.id_consult_req = sps.id_pos_consult_req
                          LEFT JOIN schedule s
                            ON s.id_schedule = cr.id_schedule
                           AND s.flg_status != pk_grid.g_sched_canc
                          LEFT JOIN epis_info ei
                            ON ei.id_schedule = s.id_schedule
                          LEFT JOIN episode e
                            ON e.id_episode = ei.id_episode
                          LEFT JOIN sr_pos_status spst
                            ON spst.id_sr_pos_status = sps.id_sr_pos_status
                           AND e.flg_status != pk_alert_constant.g_cancelled
                         WHERE sps.id_schedule_sr = i_id_schedule_sr)
                 WHERE origin_rank = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    l_pos_flg_status := NULL;
            END;
        
        END IF;
    
        IF (l_pos_flg_status IS NOT NULL)
        THEN
            l_aux          := 'SR_POS_STATUS.FLG_STATUS';
            l_display_type := pk_alert_constant.g_display_type_icon;
            l_status_flg := CASE
                                WHEN i_flg_status = pk_alert_constant.g_cancelled THEN
                                 pk_alert_constant.g_cancelled
                                ELSE
                                 l_pos_flg_status
                            END;
        END IF;
    
        l_duration_str := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_display_type    => l_display_type,
                                                               i_flg_state       => l_status_flg,
                                                               i_value_text      => l_aux,
                                                               i_value_date      => l_date_begin,
                                                               i_value_icon      => l_aux,
                                                               i_shortcut        => NULL,
                                                               i_back_color      => l_back_color,
                                                               i_icon_color      => l_icon_color,
                                                               i_message_style   => NULL,
                                                               i_message_color   => NULL,
                                                               i_flg_text_domain => NULL,
                                                               i_dt_server       => current_timestamp);
        RETURN l_duration_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SR_POS_STATUS_STR',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END get_sr_pos_status_str;

    FUNCTION get_epis_done_state
    (
        i_lang            IN language.id_language%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_epis_type    IN epis_type.id_epis_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name     VARCHAR2(30) := 'GET_EPIS_DONE_STATE';
        l_dt_begin_null VARCHAR2(1);
        l_disch_null    VARCHAR2(1);
        l_epis_done     VARCHAR2(1);
        l_error_out     t_error_out;
    
    BEGIN
    
        -- Get if current episode already begun and if it as already medical and administrative discharge
        g_error := 'call get_begin_end_episode for id_waiting_list: ' || i_id_waiting_list;
        pk_alertlog.log_debug(g_error);
        IF NOT
            get_begin_end_episode(i_lang, i_id_waiting_list, i_id_epis_type, l_dt_begin_null, l_disch_null, l_error_out)
        THEN
            l_dt_begin_null := pk_alert_constant.g_no;
            l_disch_null    := pk_alert_constant.g_no;
        END IF;
    
        -- Change variable status
        IF l_disch_null = pk_alert_constant.g_no
        THEN
            l_epis_done := pk_alert_constant.g_yes;
        ELSE
            l_epis_done := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_epis_done;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN NULL;
    END get_epis_done_state;

    FUNCTION get_completwl_status_str
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        i_sch_sr_adm_needed IN schedule_sr.adm_needed%TYPE,
        i_sr_pos_flg_status IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_wtl_flg_type      IN waiting_list.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_display_type VARCHAR2(30) := '';
        l_back_color   VARCHAR2(30) := '';
        l_status_flg   VARCHAR2(30) := '';
        l_icon_color   VARCHAR2(30) := '';
        l_aux          VARCHAR2(200);
        l_date_begin   VARCHAR2(200);
    
        l_duration_str VARCHAR2(4000);
        l_error_out    t_error_out;
    
    BEGIN
    
        IF i_sch_sr_adm_needed = pk_alert_constant.g_no
        THEN
            l_date_begin   := NULL;
            l_aux          := 'SCHEDULE_SR.ADM_NEEDED';
            l_display_type := 'I';
            l_back_color   := NULL;
            l_status_flg   := pk_alert_constant.g_no;
        
            -- Call function to generate status string
            l_duration_str := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                                   i_prof            => i_prof,
                                                                   i_display_type    => l_display_type,
                                                                   i_flg_state       => l_status_flg,
                                                                   i_value_text      => l_aux,
                                                                   i_value_date      => l_date_begin,
                                                                   i_value_icon      => l_aux,
                                                                   i_shortcut        => NULL,
                                                                   i_back_color      => l_back_color,
                                                                   i_icon_color      => l_icon_color,
                                                                   i_message_style   => NULL,
                                                                   i_message_color   => NULL,
                                                                   i_flg_text_domain => NULL,
                                                                   i_dt_server       => current_timestamp);
        
        ELSE
            l_duration_str := get_wl_status_str(i_lang,
                                                i_prof,
                                                i_id_waiting_list,
                                                i_sch_sr_adm_needed,
                                                i_sr_pos_flg_status,
                                                i_id_epis_type,
                                                i_wtl_flg_type);
        
        END IF;
    
        RETURN l_duration_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_COMPLETWL_STATUS_STR',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_completwl_status_str;

    FUNCTION get_in_waiting_list_flg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_wl_flg_status   waiting_list.flg_status%TYPE,
        i_in_waiting_list VARCHAR2,
        i_disch_null      VARCHAR2,
        i_dt_begin_null   VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_flg_wl VARCHAR2(1);
    
    BEGIN
    
        g_error := 'SEARCH BY SLOT ID';
        pk_alertlog.log_debug(g_error);
        SELECT decode(i_in_waiting_list,
                      pk_alert_constant.g_yes,
                      'I', -- In Waiting list
                      decode(i_wl_flg_status,
                             pk_alert_constant.g_schedule_sr_status_a, -- 'A'
                             decode(i_disch_null,
                                    pk_alert_constant.g_no,
                                    'D', -- done
                                    decode(i_dt_begin_null,
                                           pk_alert_constant.g_yes,
                                           'S', --schedule
                                           'U')), --undergoing
                             pk_alert_constant.g_schedule_sr_status_s, -- 'S'
                             decode(i_disch_null,
                                    pk_alert_constant.g_no,
                                    'D', -- done
                                    decode(i_dt_begin_null,
                                           pk_alert_constant.g_yes,
                                           'S', --schedule
                                           'U')), --undergoing
                             pk_alert_constant.g_adm_req_status_pend,
                             decode(i_disch_null,
                                    pk_alert_constant.g_no,
                                    'D', -- done
                                    decode(i_dt_begin_null,
                                           pk_alert_constant.g_yes,
                                           'S', --schedule
                                           'U')), --undergoing
                             NULL))
          INTO l_flg_wl
          FROM dual;
    
        RETURN l_flg_wl;
    
    END get_in_waiting_list_flg;

    FUNCTION get_wl_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        i_sch_sr_adm_needed IN schedule_sr.adm_needed%TYPE,
        i_sr_pos_flg_status IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_wtl_flg_type      IN waiting_list.flg_type%TYPE,
        o_date_begin        OUT VARCHAR2,
        o_aux               OUT VARCHAR2,
        o_display_type      OUT VARCHAR2,
        o_back_color        OUT VARCHAR2,
        o_status_flg        OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_wl_flg_status   waiting_list.flg_status%TYPE;
        l_wl_flg_type     waiting_list.flg_type%TYPE;
        l_in_waiting_list VARCHAR2(1);
        l_dt_begin_null   VARCHAR2(1);
        l_disch_null      VARCHAR2(1);
    
        l_checked_mandatory VARCHAR2(1);
    
        l_flg_approval sr_pos_status.flg_type_approval%TYPE;
    
        l_pos_required   sys_config.value%TYPE;
        l_pos_req_status VARCHAR2(1) := NULL;
    
        CURSOR c_info
        (
            l_wl_flg_status     waiting_list.flg_status%TYPE,
            l_in_waiting_list   VARCHAR2,
            l_dt_begin_null     VARCHAR2,
            l_disch_null        VARCHAR2,
            l_wl_flg_type       waiting_list.flg_type%TYPE,
            l_checked_mandatory VARCHAR2
        ) IS
            SELECT
            
             NULL date_begin, -- dt_begin             
             decode(l_wl_flg_status,
                    pk_alert_constant.g_schedule_sr_status_i, -- 'I'
                    decode(l_wl_flg_type,
                           pk_wtl_prv_core.g_wtlist_type_bed,
                           'SCHEDULE_SR.FLG_STATUS',
                           decode(l_checked_mandatory,
                                  pk_alert_constant.g_no,
                                  'SCHEDULE_SR.FLG_STATUS',
                                  decode(l_flg_approval,
                                         pk_alert_constant.g_no,
                                         'ADM_REQUEST.FLG_STATUS',
                                         'SCHEDULE_SR.FLG_STATUS'))),
                    pk_alert_constant.g_schedule_sr_status_c, -- 'C'
                    'SCHEDULE_SR.FLG_STATUS',
                    'ADM_REQUEST.FLG_STATUS') desc_stat, -- l_aux             
             'I' flg_text, -- l_display_type             
             NULL color_status, -- l_back_color             
             decode(l_wl_flg_status,
                    pk_alert_constant.g_schedule_sr_status_i, -- 'I'
                    decode(l_wl_flg_type,
                           pk_wtl_prv_core.g_wtlist_type_bed,
                           pk_wtl_prv_core.g_incomplete_i,
                           decode(l_checked_mandatory,
                                  pk_alert_constant.g_no,
                                  pk_wtl_prv_core.g_incomplete_i,
                                  decode(l_flg_approval,
                                         pk_alert_constant.g_no,
                                         pk_wtl_prv_core.g_waiting_pos_decision_w,
                                         pk_wtl_prv_core.g_incomplete_i))),
                    pk_alert_constant.g_schedule_sr_status_c, -- 'C'
                    pk_wtl_prv_core.g_wl_canceled_c, -- Cancelled
                    decode(l_flg_approval,
                           pk_alert_constant.g_no,
                           decode(i_id_epis_type,
                                  pk_alert_constant.g_epis_type_operating,
                                  pk_wtl_prv_core.g_waiting_pos_decision_w, -- Waiting for the POS decision                                  
                                  get_in_waiting_list_flg(i_lang,
                                                          i_prof,
                                                          l_wl_flg_status,
                                                          l_in_waiting_list,
                                                          l_disch_null,
                                                          l_dt_begin_null)),
                           get_in_waiting_list_flg(i_lang,
                                                   i_prof,
                                                   l_wl_flg_status,
                                                   l_in_waiting_list,
                                                   l_disch_null,
                                                   l_dt_begin_null))) status_flg -- status_flg
              FROM dual;
    
    BEGIN
    
        l_pos_required := pk_sysconfig.get_config(i_code_cf => 'WTL_POS_REQUIRED', i_prof => i_prof);
    
        -- Get flg_status recorded in waiting_list.flg_status
        BEGIN
            g_error := 'GET ADM_REQUEST FLG_STATUS';
            pk_alertlog.log_debug(g_error);
            SELECT wl.flg_status, wl.flg_type
              INTO l_wl_flg_status, l_wl_flg_type
              FROM waiting_list wl
             WHERE wl.id_waiting_list = i_id_waiting_list;
        EXCEPTION
            WHEN OTHERS THEN
                -- there is no flg_status defined in this table (field is nullable)
                l_wl_flg_status := NULL;
        END;
    
        --Checks if all the required parameters for the surgery request have been inserted.
        --It checks if the Pre-operative assessment has been requested,
        --but ignores if there is still no response for it
        IF l_pos_required = pk_alert_constant.g_yes
           AND l_wl_flg_status <> pk_alert_constant.g_cancelled
           AND i_id_epis_type = pk_alert_constant.g_epis_type_operating
        THEN
            IF NOT pk_wtl_prv_core.get_ready_to_wtlist(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_id_wtlist        => i_id_waiting_list,
                                                       i_flg_type         => i_wtl_flg_type,
                                                       i_pos_confirmation => pk_alert_constant.g_yes,
                                                       i_adm_needed       => i_sch_sr_adm_needed,
                                                       i_chck_pos_req     => pk_alert_constant.g_yes,
                                                       o_flg_valid        => l_pos_req_status,
                                                       o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_pos_req_status = pk_alert_constant.g_yes
            THEN
                l_pos_req_status := pk_alert_constant.g_active;
            ELSE
                l_pos_req_status := pk_alert_constant.g_inactive;
            END IF;
        END IF;
    
        -- Get flg_type_approval. This flag (Y/N) is used to know what icon to use    
        IF l_pos_required = pk_alert_constant.g_yes
        THEN
            g_error := 'GET FLG_APROVAL';
            pk_alertlog.log_debug(g_error);
            pk_alertlog.log_debug('i_sr_pos_flg_status = ' || i_sr_pos_flg_status);
            BEGIN
                SELECT sps.flg_type_approval
                  INTO l_flg_approval
                  FROM sr_pos_status sps
                 WHERE sps.id_sr_pos_status = i_sr_pos_flg_status;
            EXCEPTION
                WHEN no_data_found THEN
                    l_flg_approval := pk_alert_constant.g_no;
            END;
        ELSE
            l_flg_approval := pk_alert_constant.g_yes;
        END IF;
    
        -- Get if episode is in the waiting list (l_in_waiting_list = 'Y')
        BEGIN
            g_error := 'GET IN WAITING LIST INFO';
            pk_alertlog.log_debug(g_error);
            SELECT pk_alert_constant.g_yes
              INTO l_in_waiting_list
              FROM waiting_list wl
             INNER JOIN wtl_epis we
                ON (we.id_waiting_list = wl.id_waiting_list)
             WHERE we.id_epis_type = i_id_epis_type
               AND we.flg_status IN
                   (pk_wtl_prv_core.g_wtl_epis_st_not_schedule, pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule)
               AND wl.flg_status IN (pk_alert_constant.g_wl_status_a, pk_alert_constant.g_wl_status_p)
               AND wl.id_waiting_list = i_id_waiting_list;
        EXCEPTION
            WHEN OTHERS THEN
                -- if there is no admission episode
                l_in_waiting_list := pk_alert_constant.g_no;
        END;
    
        g_error := 'call get_begin_end_episode for id_waiting_list: ' || i_id_waiting_list;
        pk_alertlog.log_debug(g_error);
        -- Get if current episode already begun and if it as already medical and administrative discharge
        IF NOT get_begin_end_episode(i_lang, i_id_waiting_list, i_id_epis_type, l_dt_begin_null, l_disch_null, o_error)
        THEN
            l_dt_begin_null := pk_alert_constant.g_no;
            l_disch_null    := pk_alert_constant.g_no;
        END IF;
    
        --check if all the mandatory fields to WL are filled (except POS decision)
        g_error := 'CALL PK_WTL_PRV_CORE.get_ready_to_wl_exc_pos with id_waiting_list: ' || i_id_waiting_list;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wtl_prv_core.get_ready_to_wl_exc_pos(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_wtlist    => i_id_waiting_list,
                                                       i_chck_pos     => pk_alert_constant.g_yes,
                                                       i_chck_pos_req => pk_alert_constant.g_yes,
                                                       o_flg_valid    => l_checked_mandatory,
                                                       o_error        => o_error)
        THEN
            --don't return false or else invalidates all the logic (Antonio.Neto 18-Feb-2011 [ALERT-158936])
            NULL;
        END IF;
    
        -- Get status string
        g_error := 'GET WAITING LIST STATUS STRING';
        pk_alertlog.log_debug(g_error);
    
        IF l_pos_required = pk_alert_constant.g_yes
           AND i_id_epis_type = pk_alert_constant.g_epis_type_operating
        THEN
            l_wl_flg_status := nvl(l_pos_req_status, l_wl_flg_status);
        END IF;
    
        OPEN c_info(l_wl_flg_status,
                    l_in_waiting_list,
                    l_dt_begin_null,
                    l_disch_null,
                    l_wl_flg_type,
                    l_checked_mandatory);
        FETCH c_info
            INTO o_date_begin, o_aux, o_display_type, o_back_color, o_status_flg;
        CLOSE c_info;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WL_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_wl_status;

    FUNCTION get_wl_status_icon
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_date_begin   OUT VARCHAR2,
        i_aux          OUT VARCHAR2,
        i_display_type OUT VARCHAR2,
        i_back_color   OUT VARCHAR2,
        i_status_flg   OUT VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_back_color VARCHAR2(30) := i_back_color;
        l_icon_color VARCHAR2(30) := '';
    
        l_prof_editable       VARCHAR2(1);
        l_prof_access_ok      VARCHAR2(1);
        l_is_anesthesiologist VARCHAR2(1);
    
        l_duration_str VARCHAR2(4000);
        l_error_out    t_error_out;
    
        l_internal_error EXCEPTION;
    
    BEGIN
    
        -- Only if l_status_flg = 'P' it is necessary analyse if current professional can edit this request
        IF (i_status_flg = pk_alert_constant.g_wl_status_i OR i_status_flg = pk_alert_constant.g_wl_status_p)
           AND i_aux = 'SCHEDULE_SR.FLG_STATUS'
        THEN
            -- Check if current professional is an anesthesiologist and if he/she has permissions to edit current surgery/admission request
            g_error := 'CALL TO PK_SURGERY_REQUEST.CHECK_EDIT_PERMISSIONS';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_surgery_request.check_edit_permissions(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_type_request        => CASE i_id_epis_type
                                                                                          WHEN
                                                                                           pk_alert_constant.g_epis_type_operating THEN
                                                                                           g_surgery_type_req
                                                                                          ELSE
                                                                                           g_admission_type_req
                                                                                      END,
                                                             o_is_anesthesiologist => l_is_anesthesiologist,
                                                             o_prof_editable       => l_prof_editable,
                                                             o_prof_access_ok      => l_prof_access_ok,
                                                             o_error               => l_error_out)
            THEN
                l_is_anesthesiologist := pk_alert_constant.g_no;
                l_prof_editable       := pk_alert_constant.g_no;
                l_prof_access_ok      := pk_alert_constant.g_no;
            END IF;
        
            -- If current professional can edit request, 
            IF l_prof_editable = pk_alert_constant.g_yes
            THEN
                l_back_color := pk_alert_constant.g_color_red;
            END IF;
        
        END IF;
    
        -- Call function to generate status string
        l_duration_str := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_display_type    => i_display_type,
                                                               i_flg_state       => i_status_flg,
                                                               i_value_text      => i_aux,
                                                               i_value_date      => i_date_begin,
                                                               i_value_icon      => i_aux,
                                                               i_shortcut        => NULL,
                                                               i_back_color      => l_back_color,
                                                               i_icon_color      => l_icon_color,
                                                               i_message_style   => NULL,
                                                               i_message_color   => NULL,
                                                               i_flg_text_domain => NULL,
                                                               i_dt_server       => current_timestamp);
    
        RETURN l_duration_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WL_STATUS_ICON',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_wl_status_icon;

    FUNCTION get_wl_status_str
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        i_sch_sr_adm_needed IN schedule_sr.adm_needed%TYPE,
        i_sr_pos_flg_status IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_wtl_flg_type      IN waiting_list.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_display_type VARCHAR2(30) := '';
        l_back_color   VARCHAR2(30) := '';
        l_status_flg   VARCHAR2(30) := '';
        l_icon_color   VARCHAR2(30) := '';
        l_aux          VARCHAR2(200);
        l_date_begin   VARCHAR2(200);
    
        l_prof_editable       VARCHAR2(1);
        l_prof_access_ok      VARCHAR2(1);
        l_is_anesthesiologist VARCHAR2(1);
    
        l_duration_str VARCHAR2(4000);
        l_error_out    t_error_out;
    
        l_internal_error EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL TO PK_SURGERY_REQUEST.GET_WL_STATUS';
        pk_alertlog.log_debug(g_error);
        IF NOT get_wl_status(i_lang              => i_lang,
                             i_prof              => i_prof,
                             i_id_waiting_list   => i_id_waiting_list,
                             i_sch_sr_adm_needed => i_sch_sr_adm_needed,
                             i_sr_pos_flg_status => i_sr_pos_flg_status,
                             i_id_epis_type      => i_id_epis_type,
                             i_wtl_flg_type      => i_wtl_flg_type,
                             o_date_begin        => l_date_begin,
                             o_aux               => l_aux,
                             o_display_type      => l_display_type,
                             o_back_color        => l_back_color,
                             o_status_flg        => l_status_flg,
                             o_error             => l_error_out)
        THEN
            RAISE l_internal_error;
        END IF;
    
        -- Only if l_status_flg = 'P' it is necessary analyse if current professional can edit this request
        IF (l_status_flg = pk_alert_constant.g_wl_status_i OR l_status_flg = pk_alert_constant.g_wl_status_p)
           AND l_aux = 'SCHEDULE_SR.FLG_STATUS'
        THEN
            -- Check if current professional is an anesthesiologist and if he/she has permissions to edit current surgery/admission request
            g_error := 'CALL TO PK_SURGERY_REQUEST.CHECK_EDIT_PERMISSIONS';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_surgery_request.check_edit_permissions(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_type_request        => CASE i_id_epis_type
                                                                                          WHEN
                                                                                           pk_alert_constant.g_epis_type_operating THEN
                                                                                           g_surgery_type_req
                                                                                          ELSE
                                                                                           g_admission_type_req
                                                                                      END,
                                                             o_is_anesthesiologist => l_is_anesthesiologist,
                                                             o_prof_editable       => l_prof_editable,
                                                             o_prof_access_ok      => l_prof_access_ok,
                                                             o_error               => l_error_out)
            THEN
                l_is_anesthesiologist := pk_alert_constant.g_no;
                l_prof_editable       := pk_alert_constant.g_no;
                l_prof_access_ok      := pk_alert_constant.g_no;
            END IF;
        
            -- If current professional can edit request, 
            IF l_prof_editable = pk_alert_constant.g_yes
            THEN
                l_back_color := pk_alert_constant.g_color_red;
            END IF;
        
        END IF;
    
        -- Call function to generate status string
        l_duration_str := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_display_type    => l_display_type,
                                                               i_flg_state       => l_status_flg,
                                                               i_value_text      => l_aux,
                                                               i_value_date      => l_date_begin,
                                                               i_value_icon      => l_aux,
                                                               i_shortcut        => NULL,
                                                               i_back_color      => l_back_color,
                                                               i_icon_color      => l_icon_color,
                                                               i_message_style   => NULL,
                                                               i_message_color   => NULL,
                                                               i_flg_text_domain => NULL,
                                                               i_dt_server       => current_timestamp);
    
        RETURN l_duration_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WL_STATUS_STR',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END get_wl_status_str;

    FUNCTION get_wl_status_msg
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_status_flg IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_status_str VARCHAR2(4000) := '';
        l_error_out  t_error_out;
    
        l_internal_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET STATUS_MSG FOR I_STATUS_FLG: ' || i_status_flg;
        pk_alertlog.log_debug(g_error);
        IF (i_status_flg = pk_alert_constant.g_wl_status_i OR i_status_flg = 'W')
        THEN
            l_status_str := pk_message.get_message(i_lang, 'INP_GRID_SR_T004');
        ELSIF (i_status_flg = pk_alert_constant.g_wl_status_s)
        THEN
            l_status_str := pk_message.get_message(i_lang, 'INP_GRID_SR_T003');
        ELSIF (i_status_flg = pk_alert_constant.g_wl_status_c)
        THEN
            l_status_str := pk_message.get_message(i_lang, 'INP_GRID_SR_T006');
        ELSIF (i_status_flg = 'U')
        THEN
            l_status_str := pk_message.get_message(i_lang, 'INP_GRID_SR_T002');
        ELSIF (i_status_flg = 'D')
        THEN
            l_status_str := pk_message.get_message(i_lang, 'INP_GRID_SR_T001');
        END IF;
    
        RETURN l_status_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WL_STATUS_STR',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_wl_status_msg;

    FUNCTION get_wl_status_flg
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        i_sch_sr_adm_needed IN schedule_sr.adm_needed%TYPE,
        i_sr_pos_flg_status IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_wtl_flg_type      IN waiting_list.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_display_type VARCHAR2(30) := '';
        l_back_color   VARCHAR2(30) := '';
        l_status_flg   VARCHAR2(30) := '';
        l_aux          VARCHAR2(200);
        l_date_begin   VARCHAR2(200);
    
        l_error_out t_error_out;
    
        l_internal_error EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL TO PK_SURGERY_REQUEST.GET_WL_STATUS';
        pk_alertlog.log_debug(g_error);
        IF NOT get_wl_status(i_lang              => i_lang,
                             i_prof              => i_prof,
                             i_id_waiting_list   => i_id_waiting_list,
                             i_sch_sr_adm_needed => i_sch_sr_adm_needed,
                             i_sr_pos_flg_status => i_sr_pos_flg_status,
                             i_id_epis_type      => i_id_epis_type,
                             i_wtl_flg_type      => i_wtl_flg_type,
                             o_date_begin        => l_date_begin,
                             o_aux               => l_aux,
                             o_display_type      => l_display_type,
                             o_back_color        => l_back_color,
                             o_status_flg        => l_status_flg,
                             o_error             => l_error_out)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN l_status_flg;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WL_STATUS_STR',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END get_wl_status_flg;

    FUNCTION get_wl_status_date_dtz
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_status_flg      IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_error_out t_error_out;
    
        l_date TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
    BEGIN
    
        --na waitign_list e undergoing -> episode.dt_start
        IF (i_status_flg = pk_alert_constant.g_wl_status_i OR i_status_flg = 'W')
        THEN
            g_error := 'SELECT DT_ADMISSION WITH ID_WAITING_LIST: ' || i_id_waiting_list;
            pk_alertlog.log_debug(g_error);
            SELECT wl.dt_admission
              INTO l_date
              FROM waiting_list wl
             WHERE wl.id_waiting_list = i_id_waiting_list;
        ELSIF (i_status_flg = pk_alert_constant.g_wl_status_s)
        THEN
            l_date := pk_schedule_inp.get_sch_dt_begin(i_lang, i_prof, i_id_episode);
        ELSIF (i_status_flg = pk_alert_constant.g_wl_status_c)
        THEN
            g_error := 'SELECT DT_CANCEL WITH ID_WAITING_LIST: ' || i_id_waiting_list;
            pk_alertlog.log_debug(g_error);
            SELECT wl.dt_cancel
              INTO l_date
              FROM waiting_list wl
             WHERE wl.id_waiting_list = i_id_waiting_list;
        
        ELSIF (i_status_flg = 'D')
        THEN
            g_error := 'SELECT DT_DISCHARGE WITH ID_EPISODE: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            SELECT pk_discharge_core.get_dt_admin(i_lang, i_prof, d.id_discharge)
              INTO l_date
              FROM discharge d
             WHERE d.id_episode = i_id_episode
               AND pk_discharge_core.check_admin_discharge(i_lang, i_prof, d.id_discharge, d.flg_status_adm) =
                   pk_alert_constant.g_yes
               AND rownum = 1;
        ELSE
            g_error := 'SELECT DT_BEGIN_TSTZ WITH ID_EPISODE: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            SELECT e.dt_begin_tstz
              INTO l_date
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        END IF;
    
        RETURN l_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            SELECT e.dt_begin_tstz
              INTO l_date
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        
            RETURN l_date;
        
    END get_wl_status_date_dtz;

    FUNCTION has_parent_in_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_profile_template IN profile_template.id_profile_template%TYPE,
        i_parents_list     IN table_number,
        i_flg_exclusive    IN VARCHAR2,
        o_flg_parent       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_parent_profile profile_template.id_parent%TYPE;
        l_flg_group      profile_template.flg_group%TYPE;
    
    BEGIN
    
        IF i_flg_exclusive = pk_alert_constant.g_no
        THEN
            BEGIN
                SELECT pt.id_parent, pt.flg_group
                  INTO l_parent_profile, l_flg_group
                  FROM profile_template pt
                 WHERE pt.id_profile_template = i_profile_template
                   AND ((pt.id_parent IS NOT NULL AND
                       pt.id_parent IN (SELECT *
                                            FROM TABLE(i_parents_list))) OR pt.id_parent IS NULL);
            EXCEPTION
                WHEN no_data_found THEN
                    l_parent_profile := NULL;
            END;
        ELSE
            BEGIN
                SELECT pt.id_parent, pt.flg_group
                  INTO l_parent_profile, l_flg_group
                  FROM profile_template pt
                 WHERE pt.id_profile_template = i_profile_template
                   AND ((pt.id_parent IS NOT NULL AND
                       pt.id_parent NOT IN (SELECT *
                                                FROM TABLE(i_parents_list))) OR pt.id_parent IS NULL);
            EXCEPTION
                WHEN no_data_found THEN
                    l_parent_profile := NULL;
            END;
        END IF;
    
        IF (l_parent_profile IS NOT NULL OR (l_parent_profile IS NULL AND l_flg_group != g_profile_grp_non_clin))
        THEN
            o_flg_parent := pk_alert_constant.g_yes;
        ELSE
            o_flg_parent := pk_alert_constant.g_no;
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
                                              'HAS_PARENT_IN_LIST',
                                              o_error);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN FALSE;
    END has_parent_in_list;

    FUNCTION check_edit_permissions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_type_request        IN VARCHAR2,
        o_is_anesthesiologist OUT VARCHAR2,
        o_prof_editable       OUT VARCHAR2,
        o_prof_access_ok      OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_profile_template profile_template.id_profile_template%TYPE;
        l_func_name        VARCHAR2(30) := 'CHECK_EDIT_PERMISSIONS';
        l_parents_list_inp table_number := table_number(600, 605, 610, 615);
        l_parents_list_adm table_number := table_number(6, 406, 630);
    
    BEGIN
    
        g_error := 'GET PROFESSIONAL PROFILE (CALL PK_CLINICAL_NOTES.GET_PROFILE_TEMPLATE)';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_clinical_notes.get_profile_template(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      o_profile_template => l_profile_template,
                                                      o_error            => o_error)
        THEN
            RAISE no_data_found;
        END IF;
    
        IF i_type_request = g_surgery_type_req
        THEN
            BEGIN
                g_error := 'CHECK EDIT POS VALIDATION';
                pk_alertlog.log_debug(g_error);
                IF NOT check_pos_permission(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_profile_template => l_profile_template,
                                            o_is_edit          => o_is_anesthesiologist,
                                            o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END;
        ELSE
            o_is_anesthesiologist := pk_alert_constant.g_no;
        END IF;
    
        pk_alertlog.log_debug('POS permission:' || o_is_anesthesiologist || ' ID_PROFESSIONAL' || i_prof.id);
    
        -- Get if current professional is not an physician
        o_prof_editable := pk_alert_constant.g_yes;
    
        -- Get if current professional is not an ORIS professional or an administrative professional.
        -- In that cases this professional should not have access to OK button in main GRID's,
        IF i_type_request = g_admission_type_req
        THEN
            g_error := 'CALL HAS_PARENT_IN_LIST with profile_template: ' || l_profile_template;
            pk_alertlog.log_debug(g_error);
            IF NOT has_parent_in_list(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      i_profile_template => l_profile_template,
                                      i_parents_list     => l_parents_list_inp,
                                      i_flg_exclusive    => pk_alert_constant.g_no,
                                      o_flg_parent       => o_prof_access_ok,
                                      o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        ELSE
            g_error := 'CALL HAS_PARENT_IN_LIST with profile_template: ' || l_profile_template;
            pk_alertlog.log_debug(g_error);
            IF NOT has_parent_in_list(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      i_profile_template => l_profile_template,
                                      i_parents_list     => l_parents_list_adm,
                                      i_flg_exclusive    => pk_alert_constant.g_yes,
                                      o_flg_parent       => o_prof_access_ok,
                                      o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END check_edit_permissions;

    FUNCTION check_pos_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_profile_template IN profile_template.id_profile_template%TYPE,
        o_is_edit          OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_profile_template        profile_template.id_profile_template%TYPE;
        l_func_name               VARCHAR2(30) := 'CHECK_POS_PERMISSION';
        l_anesthesiologist_prof   profile_template.id_profile_template%TYPE := g_anesthesiologist_prof;
        l_has_sys_func_permission NUMBER(24);
    
    BEGIN
    
        IF l_profile_template IS NULL
        THEN
            g_error := 'GET PROFESSIONAL PROFILE';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_clinical_notes.get_profile_template(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          o_profile_template => l_profile_template,
                                                          o_error            => o_error)
            THEN
                RAISE no_data_found;
            END IF;
        END IF;
    
        BEGIN
            SELECT pt.id_profile_template
              INTO l_anesthesiologist_prof
              FROM profile_template pt
             INNER JOIN prof_profile_template ppt
                ON (ppt.id_profile_template = pt.id_profile_template)
             WHERE pt.id_parent = g_anesthesiologist_prof
               AND ppt.id_professional = i_prof.id
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- IF anesthesiologist icon should have RED background
        IF l_profile_template = l_anesthesiologist_prof
        THEN
            o_is_edit := pk_alert_constant.g_yes;
        ELSE
            -- check if current professional have permission dor POS sys_functionality
        
            SELECT COUNT(0)
              INTO l_has_sys_func_permission
              FROM sys_functionality sf, prof_func pf
             WHERE pf.id_functionality = sf.id_functionality
               AND sf.flg_available = pk_alert_constant.g_yes
               AND sf.intern_name_func = pk_alert_constant.g_pos_intern_name_func
               AND sf.id_software = i_prof.software
               AND pf.id_professional = i_prof.id
               AND pf.id_institution = i_prof.institution;
        
            IF l_has_sys_func_permission = 0
            THEN
                o_is_edit := pk_alert_constant.g_no;
            ELSE
                o_is_edit := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END check_pos_permission;

    FUNCTION set_surgery_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_prof_cat    IN category.flg_type%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_episode_sr   IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_sysdate         IN TIMESTAMP WITH LOCAL TIME ZONE,
        -- Waiting list
        i_professionals    IN table_number,
        i_external_dcs     IN table_number,
        i_dep_clin_serv    IN table_number, -- (S) Specialty
        i_speciality       IN table_number,
        i_department       IN table_number,
        i_flg_pref_time    IN table_varchar, -- Preferred time
        i_reason_pref_time IN table_number, -- Reason for preferred time
        -- Interventions
        i_id_sr_intervention IN table_number,
        i_flg_type           IN table_varchar DEFAULT NULL,
        i_codification       IN table_number,
        i_flg_laterality     IN table_varchar,
        i_surgical_site      IN table_varchar,
        i_sp_notes           IN table_varchar, -- Surgical process notes
        -- Other data
        i_duration         IN schedule_sr.duration%TYPE,
        i_icu              IN schedule_sr.icu%TYPE,
        i_icu_pos          IN schedule_sr.icu_pos%TYPE,
        i_notes            IN schedule_sr.notes%TYPE,
        i_adm_needed       IN schedule_sr.adm_needed%TYPE,
        i_id_sr_pos_status IN sr_pos_status.id_sr_pos_status%TYPE, -- POS decision
        i_sr_pos_schedule  IN sr_pos_schedule.id_sr_pos_schedule%TYPE, -- POS decision
        i_dt_pos_suggested IN VARCHAR2, -- POS decision
        i_decision_notes   IN sr_pos_schedule.decision_notes%TYPE,
        i_pos_req_notes    IN sr_pos_schedule.req_notes%TYPE, -- POS decision
        -- Surgical supplies
        i_supply           IN table_table_number,
        i_supply_set       IN table_table_number,
        i_supply_qty       IN table_table_number,
        i_supply_loc       IN table_table_number,
        i_dt_return        IN table_table_varchar,
        i_supply_soft_inst IN table_table_number,
        i_flg_cons_type    IN table_table_varchar,
        --
        i_description_sp    IN table_varchar,
        i_id_sr_epis_interv IN table_number,
        i_id_req_reason     IN table_table_number,
        i_supply_notes      IN table_table_varchar,
        i_surgery_record    IN table_number DEFAULT NULL,
        i_prof_team         IN table_number DEFAULT NULL,
        i_tbl_prof          IN table_table_number DEFAULT NULL,
        i_tbl_catg          IN table_table_number DEFAULT NULL,
        i_tbl_status        IN table_table_varchar DEFAULT NULL,
        i_test              IN VARCHAR2 DEFAULT NULL,
        --Diagnosis descriptions
        i_diagnosis_surg_proc IN pk_edis_types.table_in_epis_diagnosis,
        i_diagnosis_contam    IN pk_edis_types.rec_in_epis_diagnosis,
        -- clinical decision rules
        i_id_cdr_call             IN cdr_call.id_cdr_call%TYPE,
        i_id_ct_io                IN table_table_varchar,
        i_clinical_question       IN table_table_number DEFAULT NULL,
        i_response                IN table_table_varchar DEFAULT NULL,
        i_clinical_question_notes IN table_table_clob DEFAULT NULL,
        i_id_inst_dest            IN institution.id_institution%TYPE DEFAULT NULL,
        i_global_anesth           IN VARCHAR2 DEFAULT NULL,
        i_local_anesth            IN VARCHAR2 DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'SET_SURGERY_REQUEST';
        l_data_error     EXCEPTION;
        l_internal_error EXCEPTION;
        l_action_error   EXCEPTION;
    
        l_rowids table_varchar := NULL;
    
        l_status_outdated CONSTANT VARCHAR2(1) := 'O';
    
        l_sysdate        TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_schedule_sr schedule_sr.id_schedule_sr%TYPE;
    
        l_desc_diagnosis         table_varchar := table_varchar();
        l_flg_final_type_diag_sr table_varchar := table_varchar();
    
        l_sr_pos_schedule sr_pos_schedule.id_sr_pos_schedule%TYPE;
    
        l_epis_inter_removed table_number;
        l_id_sr_epis_interv  table_number := table_number();
        l_id_sr_interv       table_number := table_number();
        l_num_sr_epis_interv PLS_INTEGER;
        l_num_sr_interv      PLS_INTEGER;
        l_num_sr             PLS_INTEGER;
    
        l_id_epis_diagnoses pk_edis_types.rec_in_epis_diagnoses;
        l_created_id_diag   pk_edis_types.table_out_epis_diags;
    
    BEGIN
    
        l_sysdate := nvl(i_sysdate, current_timestamp);
    
        g_error := 'GET ID_SCHEDULE_SR';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT ssr.id_schedule_sr
              INTO l_id_schedule_sr
              FROM schedule_sr ssr
             WHERE ssr.id_waiting_list = i_id_waiting_list
               AND ssr.id_episode = i_id_episode_sr;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'ID_SCHEDULE_SR NOT FOUND';
                --RAISE l_data_error;
                NULL;
        END;
    
        IF l_id_schedule_sr IS NOT NULL
        THEN
            g_error := 'UPDATE SCHEDULE_SR';
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_schedule_sr.upd(id_schedule_sr_in      => l_id_schedule_sr,
                               duration_in            => i_duration,
                               duration_nin           => FALSE,
                               id_waiting_list_in     => i_id_waiting_list,
                               id_waiting_list_nin    => FALSE,
                               icu_in                 => i_icu,
                               icu_nin                => FALSE,
                               icu_pos_in             => i_icu_pos,
                               icu_pos_nin            => FALSE,
                               notes_in               => i_notes,
                               notes_nin              => FALSE,
                               adm_needed_in          => i_adm_needed,
                               adm_needed_nin         => FALSE,
                               need_global_anesth_in  => i_global_anesth,
                               need_global_anesth_nin => FALSE,
                               need_local_anesth_in   => i_local_anesth,
                               need_local_anesth_nin  => FALSE,
                               rows_out               => l_rowids);
        
        END IF;
    
        g_error := 'CALL PK_SR_PLANNING.SET_EPIS_SURG_PROC_NOCOMMIT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_planning.set_epis_surg_proc_nocommit(i_lang                    => i_lang,
                                                          i_prof                    => i_prof,
                                                          i_id_episode              => i_id_episode,
                                                          i_id_episode_context      => i_id_episode_sr,
                                                          i_id_sr_epis_interv       => i_id_sr_epis_interv,
                                                          i_id_sr_intervention      => i_id_sr_intervention,
                                                          i_name_interv             => table_varchar(NULL),
                                                          i_notes_sp                => i_sp_notes,
                                                          i_description_sp          => i_description_sp,
                                                          i_flg_type                => i_flg_type,
                                                          i_codification            => i_codification,
                                                          i_laterality              => i_flg_laterality,
                                                          i_surgical_site           => i_surgical_site,
                                                          i_supply                  => i_supply,
                                                          i_supply_set              => i_supply_set,
                                                          i_supply_qty              => i_supply_qty,
                                                          i_supply_loc              => i_supply_loc,
                                                          i_dt_return               => i_dt_return,
                                                          i_supply_soft_inst        => i_supply_soft_inst,
                                                          i_flg_cons_type           => i_flg_cons_type,
                                                          i_id_req_reason           => i_id_req_reason,
                                                          i_notes                   => i_supply_notes,
                                                          i_surgery_record          => i_surgery_record,
                                                          i_prof_team               => i_prof_team,
                                                          i_tbl_prof                => i_tbl_prof,
                                                          i_tbl_catg                => i_tbl_catg,
                                                          i_tbl_status              => i_tbl_status,
                                                          i_test                    => i_test,
                                                          i_diagnosis_surg_proc     => i_diagnosis_surg_proc,
                                                          i_id_cdr_call             => i_id_cdr_call,
                                                          i_id_not_order_reason_ea  => table_number(),
                                                          i_id_ct_io                => i_id_ct_io,
                                                          i_clinical_question       => i_clinical_question,
                                                          i_response                => i_response,
                                                          i_clinical_question_notes => i_clinical_question_notes,
                                                          i_id_inst_dest            => i_id_inst_dest,
                                                          o_error                   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SCHEDULE_SR',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DURATION',
                                                                      'ID_WAITING_LIST',
                                                                      'ICU',
                                                                      'NOTES',
                                                                      'ADM_NEEDED'));
    
        -- Cancel existing interventions that were removed from the current selection.
        -- If all the selection was removed, then all interventions of the episode are cancelled.
        g_error := 'CANCEL INTERVENTIONS NOT IN SELECTION';
        pk_alertlog.log_debug(g_error);
    
        --remove duplicated
        IF i_id_sr_epis_interv IS NOT NULL
        THEN
            l_num_sr_epis_interv := i_id_sr_epis_interv.count;
            IF l_num_sr_epis_interv > 0
            THEN
                l_num_sr := 1;
                FOR l_epis_interv IN 1 .. l_num_sr_epis_interv
                LOOP
                    IF i_id_sr_epis_interv(l_epis_interv) IS NOT NULL
                    THEN
                        l_id_sr_epis_interv.extend();
                        l_id_sr_epis_interv(l_num_sr) := i_id_sr_epis_interv(l_epis_interv);
                        l_num_sr := l_num_sr + 1;
                    END IF;
                END LOOP;
                l_id_sr_epis_interv := SET(l_id_sr_epis_interv);
            END IF;
        
            l_num_sr_interv := i_id_sr_intervention.count;
            IF l_num_sr_interv > 0
            THEN
                l_num_sr := 1;
                FOR l_interv IN 1 .. l_num_sr_interv
                LOOP
                    IF i_id_sr_intervention(l_interv) IS NOT NULL
                    THEN
                        l_id_sr_interv.extend();
                        l_id_sr_interv(l_num_sr) := i_id_sr_intervention(l_interv);
                        l_num_sr := l_num_sr + 1;
                    END IF;
                END LOOP;
                l_id_sr_interv := SET(l_id_sr_interv);
            END IF;
        END IF;
    
        SELECT sei.id_sr_epis_interv
          BULK COLLECT
          INTO l_epis_inter_removed
          FROM sr_epis_interv sei
         WHERE sei.id_sr_epis_interv NOT IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                              t.column_value
                                               FROM TABLE(l_id_sr_epis_interv) t)
           AND sei.id_episode_context = i_id_episode_sr
           AND sei.flg_status <> pk_sr_planning.g_cancel
           AND sei.id_sr_intervention NOT IN (SELECT /*+opt_estimate(table,t1,scale_rows=0.0000001)*/
                                               t1.column_value
                                                FROM TABLE(l_id_sr_interv) t1);
    
        IF l_epis_inter_removed IS NOT NULL
           AND l_epis_inter_removed.count > 0
           AND i_id_sr_epis_interv.count > 0
        THEN
            g_error := 'CALL CANCEL_EPIS_SURG_REMOV_LIST FUNCTION FOR ORIS ID_EPISODE ' || i_id_episode_sr;
            pk_alertlog.log_debug(g_error);
            IF NOT cancel_epis_surg_remov_list(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_id_sr_epis_interv => l_epis_inter_removed,
                                               i_id_episode        => i_id_episode_sr,
                                               i_sysdate           => l_sysdate,
                                               o_error             => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        -- (WTL_DEP_CLIN_SERV) --> Set SPECIALTIES / EXTERNAL DISCIPLINES
        -- Set existing as outdated
        g_error := 'SET OUTDATED - WTL_DEP_CLIN_SERV';
        pk_alertlog.log_debug(g_error);
        ts_wtl_dep_clin_serv.upd(flg_status_in => l_status_outdated,
                                 where_in      => 'id_waiting_list = ' || i_id_waiting_list || ' AND id_episode = ' ||
                                                  i_id_episode_sr ||
                                                  ' AND flg_status = ''A'' AND flg_type IN (''S'',''D'')', -- (S) Specialties / (D) External disciplines
                                 rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE - WTL_DEP_CLIN_SERV';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'WTL_DEP_CLIN_SERV',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- Create new SPECIALTY
        IF i_dep_clin_serv.exists(1)
        THEN
            -- Loop for every specialty selected
            FOR i IN i_dep_clin_serv.first .. i_dep_clin_serv.last
            LOOP
                IF i_dep_clin_serv(i) IS NOT NULL
                THEN
                    g_error := 'INSERT WTL_DEP_CLIN_SERV (SPEC) - ' || i;
                    pk_alertlog.log_debug(g_error);
                    ts_wtl_dep_clin_serv.ins(id_wtl_dcs_in         => ts_wtl_dep_clin_serv.next_key,
                                             id_dep_clin_serv_in   => i_dep_clin_serv(i),
                                             id_waiting_list_in    => i_id_waiting_list,
                                             id_episode_in         => i_id_episode_sr,
                                             flg_type_in           => pk_alert_constant.g_wtl_dcs_flg_type_s,
                                             flg_status_in         => 'A',
                                             id_prof_speciality_in => i_speciality(i),
                                             id_ward_in            => i_department(i),
                                             rows_out              => l_rowids);
                END IF;
            END LOOP;
        END IF;
    
        -- Create new EXTERNAL DISCIPLINE
        IF i_external_dcs.exists(1)
        THEN
            -- Loop for every external discipline selected
            FOR i IN i_external_dcs.first .. i_external_dcs.last
            LOOP
                IF i_external_dcs(i) IS NOT NULL
                THEN
                    g_error := 'INSERT WTL_DEP_CLIN_SERV (EXT. DISC.) - ' || i;
                    pk_alertlog.log_debug(g_error);
                    ts_wtl_dep_clin_serv.ins(id_wtl_dcs_in       => ts_wtl_dep_clin_serv.next_key,
                                             id_dep_clin_serv_in => i_external_dcs(i),
                                             id_waiting_list_in  => i_id_waiting_list,
                                             id_episode_in       => i_id_episode_sr,
                                             flg_type_in         => pk_alert_constant.g_wtl_dcs_flg_type_d, -- !! 'D' = external disciplines
                                             flg_status_in       => 'A',
                                             rows_out            => l_rowids);
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'PROCESS INSERT - WTL_DEP_CLIN_SERV';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'WTL_DEP_CLIN_SERV',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- (WTL_PREF_TIME) --> Set PREFERRED TIME
        -- Set existing as outdated
        g_error := 'SET OUTDATED - WTL_PREF_TIME';
        pk_alertlog.log_debug(g_error);
        ts_wtl_pref_time.upd(flg_status_in => l_status_outdated,
                             where_in      => 'id_waiting_list = ' || i_id_waiting_list || ' AND flg_status = ''A''',
                             rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE - WTL_PREF_TIME';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'WTL_PREF_TIME',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- Create new
        g_error := 'CHECK FLG_PREF_TIME EXISTS';
        pk_alertlog.log_debug(g_error);
        IF i_flg_pref_time.exists(1)
        THEN
            FOR i IN i_flg_pref_time.first .. i_flg_pref_time.last
            LOOP
                IF i_flg_pref_time(i) IS NOT NULL
                THEN
                    g_error := 'SET NEW WTL_PREF_TIME - ' || i;
                    pk_alertlog.log_debug(g_error);
                    ts_wtl_pref_time.ins(id_wtl_pref_time_in => ts_wtl_pref_time.next_key,
                                         flg_value_in        => i_flg_pref_time(i),
                                         id_waiting_list_in  => i_id_waiting_list,
                                         flg_status_in       => 'A',
                                         rows_out            => l_rowids);
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'PROCESS INSERT - WTL_PREF_TIME';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'WTL_PREF_TIME',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- (WTL_PTREASON_WLIST) --> Set REASON FOR PREFERRED TIME
        -- Set existing as outdated
        g_error := 'SET OUTDATED - WTL_PTREASON_WTLIST';
        pk_alertlog.log_debug(g_error);
        ts_wtl_ptreason_wtlist.upd(flg_status_in => l_status_outdated,
                                   where_in      => 'id_waiting_list = ' || i_id_waiting_list ||
                                                    ' AND flg_status = ''A''',
                                   rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE - WTL_PTREASON_WTLIST';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'WTL_PTREASON_WTLIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- Create new
        IF i_reason_pref_time.exists(1)
        THEN
            FOR i IN i_reason_pref_time.first .. i_reason_pref_time.last
            LOOP
                IF i_reason_pref_time(i) IS NOT NULL
                THEN
                    g_error := 'SET NEW WTL_REASON - ' || i;
                    pk_alertlog.log_debug(g_error);
                    ts_wtl_ptreason_wtlist.ins(id_wtl_ptreason_in => i_reason_pref_time(i),
                                               id_waiting_list_in => i_id_waiting_list,
                                               flg_status_in      => 'A',
                                               rows_out           => l_rowids);
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'PROCESS INSERT - WTL_PTREASON_WTLIST';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'WTL_PTREASON_WTLIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- (WTL_PROF) --> Set PREFERRED SURGEONS
        -- Set existing as outdated
        g_error := 'SET OUTDATED - WTL_PROF';
        pk_alertlog.log_debug(g_error);
        ts_wtl_prof.upd(flg_status_in => l_status_outdated,
                        where_in      => 'id_waiting_list = ' || i_id_waiting_list || ' AND id_episode = ' ||
                                         i_id_episode_sr || ' AND flg_type = ''S'' AND flg_status = ''A''',
                        rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE - WTL_PROF';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'WTL_PROF',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- Create new
        IF i_professionals.exists(1)
        THEN
            -- Loop for every preferred surgeon selected
            FOR i IN i_professionals.first .. i_professionals.last
            LOOP
                IF i_professionals(i) IS NOT NULL
                THEN
                    g_error := 'INSERT WTL_PROF - ' || i;
                    pk_alertlog.log_debug(g_error);
                    ts_wtl_prof.ins(id_wtl_prof_in     => ts_wtl_prof.next_key,
                                    id_prof_in         => i_professionals(i),
                                    id_waiting_list_in => i_id_waiting_list,
                                    id_episode_in      => i_id_episode_sr,
                                    flg_type_in        => pk_alert_constant.g_wtl_prof_flg_type_s,
                                    flg_status_in      => 'A',
                                    rows_out           => l_rowids);
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'PROCESS INSERT - WTL_PROF';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'WTL_PROF',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- Set DANGER OF CONTAMINATION 
        -- Set existing as outdated
        g_error := 'SET OUTDATED - SR_DANGER_CONT';
        pk_alertlog.log_debug(g_error);
        ts_sr_danger_cont.upd(flg_status_in => l_status_outdated,
                              where_in      => 'id_episode = ' || i_id_episode_sr || ' AND id_patient = ' ||
                                               nvl(i_id_patient, -1) || ' AND flg_status = ''A''',
                              rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE - SR_DANGER_CONT';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SR_DANGER_CONT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        -- Create new
        g_error := 'SET SR_DANGER_CONT';
        pk_alertlog.log_debug(g_error);
    
        IF i_diagnosis_contam.tbl_diagnosis IS NOT NULL
        THEN
            IF i_diagnosis_contam.tbl_diagnosis.count > 0
            THEN
                IF i_diagnosis_contam.tbl_diagnosis(1).id_diagnosis IS NOT NULL
                THEN
                    -- Create/Update patient's diagnosis
                    g_error := 'CALL TO PK_DIAGNOSIS.SET_EPIS_DIAGNOSIS';
                    pk_alertlog.log_debug(g_error);
                
                    l_id_epis_diagnoses.epis_diagnosis            := i_diagnosis_contam;
                    l_id_epis_diagnoses.epis_diagnosis.id_episode := i_id_episode_sr;
                    IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_epis_diagnoses => l_id_epis_diagnoses,
                                                           o_params         => l_created_id_diag,
                                                           o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    FOR i IN l_created_id_diag.first .. l_created_id_diag.last
                    LOOP
                        g_error := 'INSERT SR_DANGER_CONT - ' || i;
                        pk_alertlog.log_debug(g_error);
                        ts_sr_danger_cont.ins(id_sr_danger_cont_in => ts_sr_danger_cont.next_key,
                                              id_episode_in        => i_id_episode_sr,
                                              id_patient_in        => i_id_patient,
                                              id_schedule_sr_in    => l_id_schedule_sr,
                                              id_prof_reg_in       => i_prof.id,
                                              id_epis_diagnosis_in => CASE
                                                                          WHEN l_created_id_diag IS NOT NULL
                                                                               AND l_created_id_diag.exists(i) THEN
                                                                           l_created_id_diag(i).id_epis_diagnosis
                                                                          ELSE
                                                                           NULL
                                                                      END,
                                              dt_reg_in            => l_sysdate,
                                              flg_status_in        => 'A',
                                              rows_out             => l_rowids);
                    END LOOP;
                
                    g_error := 'PROCESS INSERT - SR_DANGER_CONT';
                    pk_alertlog.log_debug(g_error);
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'SR_DANGER_CONT',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    l_rowids := NULL;
                
                END IF;
            END IF;
        END IF;
    
        -- SET POS DECISION
        l_sr_pos_schedule := i_sr_pos_schedule;
    
        g_error := 'CALL TO PK_SR_POS.SET_POS_SCHEDULE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_pos.set_pos_schedule(i_lang                => i_lang,
                                          i_prof                => i_prof,
                                          i_id_episode_sr       => i_id_episode_sr,
                                          i_id_waiting_list     => i_id_waiting_list,
                                          i_id_sr_pos_status    => i_id_sr_pos_status,
                                          i_dt_pos_suggested    => i_dt_pos_suggested,
                                          i_req_notes           => i_pos_req_notes,
                                          io_id_sr_pos_schedule => l_sr_pos_schedule,
                                          i_decision_notes      => i_decision_notes,
                                          o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --Call ALERT_INTER event update
        alert_inter.pk_ia_event_schedule.surgery_request_update(i_id_institution => i_prof.institution,
                                                                i_id_schedule_sr => l_id_schedule_sr);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_action_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_REQUEST_ERROR',
                                              'INVALID_REQUEST',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN l_data_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_DATA_ERROR',
                                              'INVALID DATA2',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_surgery_request;

    FUNCTION get_sr_interv_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_sr_intervention IN intervention.id_intervention%TYPE
    ) RETURN pk_translation.t_desc_translation IS
    
        l_interv_desc pk_translation.t_desc_translation;
    
    BEGIN
    
        g_error := 'GET SURGERY INTERVENTION DESCRIPTION';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT pk_translation.get_translation(i_lang, interv.code_intervention) AS desc_interv
          INTO l_interv_desc
          FROM intervention interv
         WHERE interv.id_intervention = i_sr_intervention;
    
        RETURN l_interv_desc;
    
    END get_sr_interv_description;

    FUNCTION set_epis_surg_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_episode_context   IN episode.id_episode%TYPE,
        i_sr_intervention   IN table_number,
        i_codification      IN table_number,
        i_laterality        IN table_varchar,
        i_surgical_site     IN table_varchar,
        i_diagnosis         IN table_number,
        i_prof              IN profissional,
        i_sp_notes          IN table_varchar,
        i_diag_status       IN table_varchar,
        i_spec_notes        IN table_varchar,
        i_diag_notes        IN table_varchar,
        i_dt_interv_start   IN table_varchar DEFAULT NULL,
        i_dt_interv_end     IN table_varchar DEFAULT NULL,
        i_dt_req            IN table_varchar DEFAULT NULL,
        i_flg_type          IN table_varchar DEFAULT NULL,
        i_flg_status        IN table_varchar DEFAULT NULL,
        i_flg_surg_request  IN table_varchar DEFAULT NULL,
        i_flg_add_problem   IN table_varchar,
        i_diag_desc_sp      IN table_varchar, --desc diagnosis from surgical procedure
        o_id_sr_epis_interv OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name       VARCHAR2(30) := 'SET_EPIS_SURG_INTERV';
        l_diagnosis_surg_proc pk_edis_types.rec_in_epis_diagnosis;
    
    BEGIN
        -- building object to save diagnoses
        g_error := 'CALL TO PK_DIAGNOSIS.GET_DIAG_REC';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        l_diagnosis_surg_proc := pk_diagnosis.get_diag_rec(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_patient   => NULL,
                                                           i_episode   => nvl(i_episode_context, i_episode),
                                                           i_diagnosis => i_diagnosis,
                                                           i_desc_diag => i_diag_desc_sp);
    
        g_error := 'call set_epis_surg_interv_no_commit for id_episode: ' || i_episode_context;
        pk_alertlog.log_debug(g_error);
        IF NOT set_epis_surg_interv_no_commit(i_lang                => i_lang,
                                              i_episode             => i_episode,
                                              i_episode_context     => i_episode_context,
                                              i_sr_intervention     => i_sr_intervention,
                                              i_codification        => i_codification,
                                              i_laterality          => i_laterality,
                                              i_surgical_site       => i_surgical_site,
                                              i_prof                => i_prof,
                                              i_sp_notes            => i_sp_notes,
                                              i_dt_interv_start     => i_dt_interv_start,
                                              i_dt_interv_end       => i_dt_interv_end,
                                              i_dt_req              => i_dt_req,
                                              i_flg_type            => i_flg_type,
                                              i_flg_status          => i_flg_status,
                                              i_flg_surg_request    => i_flg_surg_request,
                                              i_diagnosis_surg_proc => l_diagnosis_surg_proc, --TODO
                                              i_id_not_order_reason => NULL,
                                              o_id_sr_epis_interv   => o_id_sr_epis_interv,
                                              o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_SURG_INTERV',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END set_epis_surg_interv;

    FUNCTION get_surgery_request_ds
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        --speciality  
        o_surg_date            OUT schedule_sr.dt_target_tstz%TYPE,
        o_surg_spec_id         OUT NUMBER,
        o_surg_spec_desc       OUT VARCHAR2,
        o_surg_speciality      OUT NUMBER,
        o_surg_speciality_desc OUT VARCHAR2,
        o_surg_department      OUT NUMBER,
        o_surg_department_desc OUT VARCHAR2,
        --surg preferential
        o_surg_pref_id   OUT table_number,
        o_surg_pref_desc OUT table_varchar,
        --surg procedure
        o_surg_proc OUT VARCHAR2,
        --external speciality
        o_surg_spec_ext_id   OUT table_number,
        o_surg_spec_ext_desc OUT table_varchar,
        --danger contamination
        o_surg_danger_cont OUT VARCHAR2,
        --surg_prefered_time
        o_surg_pref_time_id   OUT table_number,
        o_surg_pref_time_desc OUT table_varchar,
        o_surg_pref_time_flg  OUT table_varchar,
        --surg_prefered_time_reason
        o_surg_pref_reason_id   OUT NUMBER,
        o_surg_pref_reason_desc OUT VARCHAR2,
        -- duration
        o_surg_duration OUT NUMBER,
        --icu
        o_surg_icu      OUT VARCHAR2,
        o_surg_desc_icu OUT VARCHAR2,
        --icu_pos
        o_surg_icu_pos      OUT VARCHAR2,
        o_surg_desc_icu_pos OUT VARCHAR2,
        --notes
        o_surg_notes OUT VARCHAR2,
        --surg need
        o_surg_need      OUT VARCHAR2,
        o_surg_need_desc OUT VARCHAR2,
        --surg institution
        o_surg_institution          OUT NUMBER,
        o_surg_institution_desc     OUT VARCHAR2,
        o_procedures                OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_danger_cont               OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        --anesthesia
        o_global_anesth_desc OUT VARCHAR2,
        o_global_anesth_id   OUT VARCHAR2,
        o_local_anesth_desc  OUT VARCHAR2,
        o_local_anesth_id    OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SURGERY_REQUEST';
        l_runtime_error EXCEPTION;
    
        l_tbl_id_surg_pref   table_number := table_number();
        l_tbl_desc_surg_pref table_varchar := table_varchar();
    
        l_tbl_id_ext_serv table_number := table_number();
    
        l_id_wtlist table_number;
    
    BEGIN
    
        l_id_wtlist := table_number(i_id_waiting_list);
    
        IF i_id_episode IS NOT NULL
        THEN
        
            BEGIN
                -- 1 - Surgery specialty(ies)
                g_error := 'GET get_dep_clin_servs <- Surgery specialty(ies)';
                SELECT dcs.id_dep_clin_serv,
                       -- wdcs.flg_type,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_desc
                  INTO o_surg_spec_id, o_surg_spec_desc
                  FROM wtl_dep_clin_serv wdcs, dep_clin_serv dcs, clinical_service cs
                 WHERE wdcs.id_waiting_list = i_id_waiting_list
                   AND wdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND (i_id_episode IS NULL OR wdcs.id_episode = i_id_episode)
                   AND wdcs.flg_type = pk_wtl_pbl_core.g_wtl_dcs_type_specialty
                   AND wdcs.flg_status = pk_surgery_request.g_sr_crit_type_all_a;
            EXCEPTION
                WHEN no_data_found THEN
                    o_surg_spec_id   := NULL;
                    o_surg_spec_desc := NULL;
            END;
        
            BEGIN
                -- 1 - Surgery specialty(ies)
                g_error := 'GET get_dep_clin_servs <- Surgery specialty(ies)';
                SELECT s.id_speciality,
                       pk_translation.get_translation(i_lang, s.code_speciality) speciality_desc,
                       d.id_department,
                       pk_translation.get_translation(i_lang, d.code_department) department_desc
                  INTO o_surg_speciality, o_surg_speciality_desc, o_surg_department, o_surg_department_desc
                  FROM wtl_dep_clin_serv wdcs, dep_clin_serv dcs, clinical_service cs, department d, speciality s
                 WHERE wdcs.id_waiting_list = i_id_waiting_list
                   AND wdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND dcs.id_clinical_service = cs.id_clinical_service
                   AND d.id_department = wdcs.id_ward
                   AND s.id_speciality = wdcs.id_prof_speciality
                   AND (i_id_episode IS NULL OR wdcs.id_episode = i_id_episode)
                   AND wdcs.flg_type = pk_wtl_pbl_core.g_wtl_dcs_type_specialty
                   AND wdcs.flg_status = pk_surgery_request.g_sr_crit_type_all_a;
            EXCEPTION
                WHEN no_data_found THEN
                    o_surg_speciality      := NULL;
                    o_surg_speciality_desc := NULL;
                    o_surg_department      := NULL;
                    o_surg_department_desc := NULL;
            END;
        
            -- 2 - Preferred surgeon(s)
            g_error := 'GET get_professionals <- Preferred surgeon(s)';
        
            SELECT wtlp.id_prof,
                   --wtlp.flg_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, wtlp.id_prof) prof_name
              BULK COLLECT
              INTO o_surg_pref_id, o_surg_pref_desc
              FROM wtl_prof wtlp
             WHERE wtlp.id_waiting_list = i_id_waiting_list
               AND (i_id_episode IS NULL OR wtlp.id_episode = i_id_episode)
               AND wtlp.flg_type = pk_wtl_pbl_core.g_wtl_prof_type_surgeon
               AND wtlp.flg_status = pk_surgery_request.g_sr_crit_type_all_a;
        
            /*TODO tratar cirurgioes preferenciais*/
        
            /*TODO tratar procedimentos cirurgicos*/
        
            -- 3 - Surgical procedure(s) and laterality
            g_error := 'GET get_surgical_procedures';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wtl_pbl_core.get_surgical_procedures(i_lang                      => i_lang,
                                                           i_prof                      => i_prof,
                                                           i_id_wtlist                 => l_id_wtlist,
                                                           o_procedures                => o_procedures,
                                                           o_interv_clinical_questions => o_interv_clinical_questions,
                                                           o_interv_supplies           => o_interv_supplies,
                                                           o_error                     => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        
            -- 6 - External discipline(s)
            g_error := 'GET get_dep_clin_servs <- External discipline(s)';
            pk_alertlog.log_debug(g_error);
        
            SELECT s.id_dep_clin_serv, pk_translation.get_translation(i_lang, cs.code_clinical_service)
              BULK COLLECT
              INTO o_surg_spec_ext_id, o_surg_spec_ext_desc
              FROM wtl_dep_clin_serv s
             INNER JOIN dep_clin_serv dcs
                ON s.id_dep_clin_serv = dcs.id_dep_clin_serv
             INNER JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
             WHERE s.id_waiting_list = i_id_waiting_list
               AND (i_id_episode IS NULL OR s.id_episode = i_id_episode)
               AND s.flg_type = pk_wtl_pbl_core.g_wtl_dcs_type_ext_disc
               AND s.flg_status = pk_surgery_request.g_sr_crit_type_all_a;
        
            -- 7 - Danger of contamination
            g_error := 'GET get_danger_cont';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wtl_pbl_core.get_danger_cont(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_episode      => i_id_episode,
                                                   i_id_waiting_list => i_id_waiting_list,
                                                   o_danger_cont     => o_danger_cont,
                                                   o_error           => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        
            -- 8 - Preferred time
            -- The default flg_status is 'A' - Active
            g_error := 'GET get_preferred_time';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT prf.id_wtl_pref_time,
                       (SELECT pk_sysdomain.get_domain('WTL_PREF_TIME.FLG_VALUE', prf.flg_value, i_lang)
                          FROM dual) pref_time_desc,
                       prf.flg_value
                  BULK COLLECT
                  INTO o_surg_pref_time_id, o_surg_pref_time_desc, o_surg_pref_time_flg
                  FROM wtl_pref_time prf
                 WHERE prf.id_waiting_list IN (SELECT *
                                                 FROM TABLE(l_id_wtlist))
                   AND prf.flg_status = pk_surgery_request.g_sr_crit_type_all_a
                 ORDER BY 1;
            EXCEPTION
                WHEN no_data_found THEN
                    o_surg_pref_time_id   := NULL;
                    o_surg_pref_time_desc := NULL;
            END;
            -- 9 - Reason for preferred time
            g_error := 'GET get_surgical_procedures';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT pftr.id_wtl_ptreason, pk_translation.get_translation(i_lang, wp.code) pref_time_reason_desc
                  INTO o_surg_pref_reason_id, o_surg_pref_reason_desc
                  FROM wtl_ptreason_wtlist pftr, wtl_ptreason wp
                 WHERE pftr.id_wtl_ptreason = wp.id_wtl_ptreason
                   AND pftr.id_waiting_list = i_id_waiting_list
                   AND pftr.flg_status = pk_surgery_request.g_sr_crit_type_all_a
                 ORDER BY 1;
            EXCEPTION
                WHEN no_data_found THEN
                    o_surg_pref_reason_id   := NULL;
                    o_surg_pref_reason_desc := NULL;
            END;
            -- 10 - POS decision
            g_error := 'GET get_pos_decision';
            pk_alertlog.log_debug(g_error);
        
            g_error := 'OPEN CURSOR o_surg_request';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT s.duration, -- 4 - Expected duration
                       s.icu, -- 5 - Intensive care unit (ICU)
                       pk_sysdomain.get_domain('SCHEDULE_SR.ICU', s.icu, i_lang),
                       s.notes, -- 11 - Notes
                       s.adm_needed, -- Admission Needed
                       pk_sysdomain.get_domain('SCHEDULE_SR.ADM_NEEDED', s.adm_needed, i_lang),
                       s.id_institution id_institution,
                       pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || s.id_institution),
                       s.dt_target_tstz,
                       pk_sysdomain.get_domain('YES_NO', s.need_global_anesth, i_lang),
                       s.need_global_anesth,
                       pk_sysdomain.get_domain('YES_NO', s.need_local_anesth, i_lang),
                       s.need_local_anesth,
                       s.icu_pos,
                       pk_sysdomain.get_domain('YES_NO', s.icu_pos, i_lang)
                  INTO o_surg_duration,
                       o_surg_icu,
                       o_surg_desc_icu,
                       o_surg_notes,
                       o_surg_need,
                       o_surg_need_desc,
                       o_surg_institution,
                       o_surg_institution_desc,
                       o_surg_date,
                       o_global_anesth_desc,
                       o_global_anesth_id,
                       o_local_anesth_desc,
                       o_local_anesth_id,
                       o_surg_icu_pos,
                       o_surg_desc_icu_pos
                  FROM schedule_sr s
                  JOIN wtl_epis we
                    ON we.id_episode = s.id_episode
                   AND we.id_waiting_list = s.id_waiting_list
                 WHERE s.id_waiting_list = i_id_waiting_list
                   AND (s.id_episode = i_id_episode OR i_id_episode IS NULL);
            EXCEPTION
                WHEN no_data_found THEN
                    o_surg_duration         := NULL;
                    o_surg_icu              := NULL;
                    o_surg_desc_icu         := NULL;
                    o_surg_notes            := NULL;
                    o_surg_need             := NULL;
                    o_surg_need_desc        := NULL;
                    o_surg_institution      := NULL;
                    o_surg_institution_desc := NULL;
            END;
        
        ELSE
            g_error := 'OPEN CURSORS';
            pk_alertlog.log_debug(g_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_runtime_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_surgery_request_ds;

    FUNCTION get_surg_request_by_oris_epis
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        o_prof_resp                 OUT professional.name%TYPE,
        o_procedures                OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dummy_cursor pk_types.cursor_type;
        l_waiting_list waiting_list.id_waiting_list%TYPE;
        l_exception EXCEPTION;
        l_epis_type epis_type.id_epis_type%TYPE;
    
    BEGIN
    
        IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                        i_id_epis   => i_id_episode,
                                        o_epis_type => l_epis_type,
                                        o_error     => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_epis_type != pk_alert_constant.g_epis_type_operating
        THEN
            RETURN TRUE;
        ELSE
            BEGIN
                SELECT a.id_waiting_list
                  INTO l_waiting_list
                  FROM wtl_epis a
                 WHERE a.id_episode = i_id_episode;
            EXCEPTION
                WHEN OTHERS THEN
                    l_waiting_list := NULL;
            END;
        END IF;
    
        SELECT a.id_professional
          INTO o_prof_resp
          FROM professional a
         INNER JOIN sr_epis_interv b
            ON a.id_professional = b.id_prof_req
         WHERE b.id_episode_context = i_id_episode
           AND b.flg_status != 'C'
           AND b.flg_type = pk_alert_constant.g_wl_status_p;
    
        IF l_waiting_list IS NOT NULL
        THEN
            IF NOT pk_surgery_request.get_surgery_request(i_lang                      => i_lang,
                                                          i_prof                      => i_prof,
                                                          i_id_episode                => i_id_episode,
                                                          i_id_waiting_list           => l_waiting_list,
                                                          o_surg_specs                => l_dummy_cursor,
                                                          o_pref_surg                 => l_dummy_cursor,
                                                          o_procedures                => o_procedures,
                                                          o_ext_disc                  => l_dummy_cursor,
                                                          o_danger_cont               => l_dummy_cursor,
                                                          o_preferred_time            => l_dummy_cursor,
                                                          o_pref_time_reason          => l_dummy_cursor,
                                                          o_pos                       => l_dummy_cursor,
                                                          o_surg_request              => l_dummy_cursor,
                                                          o_interv_clinical_questions => o_interv_clinical_questions,
                                                          o_error                     => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            IF NOT pk_sr_planning.get_summ_interv(i_lang                      => i_lang,
                                                  i_prof                      => i_prof,
                                                  i_episode                   => i_id_episode,
                                                  o_interv                    => o_procedures,
                                                  o_labels                    => l_dummy_cursor,
                                                  o_interv_supplies           => l_dummy_cursor,
                                                  o_interv_clinical_questions => o_interv_clinical_questions,
                                                  o_error                     => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    END get_surg_request_by_oris_epis;

    FUNCTION get_surgery_request
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_waiting_list           IN waiting_list.id_waiting_list%TYPE,
        o_surg_specs                OUT pk_types.cursor_type,
        o_pref_surg                 OUT pk_types.cursor_type,
        o_procedures                OUT pk_types.cursor_type,
        o_ext_disc                  OUT pk_types.cursor_type,
        o_danger_cont               OUT pk_types.cursor_type,
        o_preferred_time            OUT pk_types.cursor_type,
        o_pref_time_reason          OUT pk_types.cursor_type,
        o_pos                       OUT pk_types.cursor_type,
        o_surg_request              OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SURGERY_REQUEST';
        l_runtime_error EXCEPTION;
        l_dummy_cursor pk_types.cursor_type;
    
        l_id_wtlist table_number;
    
    BEGIN
    
        l_id_wtlist := table_number(i_id_waiting_list);
    
        IF i_id_episode IS NOT NULL
        THEN
            -- 1 - Surgery specialty(ies)
            g_error := 'GET get_dep_clin_servs <- Surgery specialty(ies)';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wtl_pbl_core.get_dep_clin_servs(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_waiting_list => i_id_waiting_list,
                                                      i_id_episode      => i_id_episode,
                                                      i_flg_type        => pk_wtl_pbl_core.g_wtl_dcs_type_specialty,
                                                      i_all             => pk_alert_constant.g_no,
                                                      o_dcs             => o_surg_specs,
                                                      o_error           => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        
            -- 2 - Preferred surgeon(s)
            g_error := 'GET get_professionals <- Preferred surgeon(s)';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wtl_pbl_core.get_professionals(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_waiting_list => i_id_waiting_list,
                                                     i_id_episode      => i_id_episode,
                                                     i_flg_type        => pk_wtl_pbl_core.g_wtl_prof_type_surgeon,
                                                     i_all             => pk_alert_constant.g_no,
                                                     o_professionals   => o_pref_surg,
                                                     o_error           => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        
            -- 3 - Surgical procedure(s) and laterality
            g_error := 'GET get_surgical_procedures';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wtl_pbl_core.get_surgical_procedures(i_lang                      => i_lang,
                                                           i_prof                      => i_prof,
                                                           i_id_wtlist                 => l_id_wtlist,
                                                           o_procedures                => o_procedures,
                                                           o_interv_clinical_questions => o_interv_clinical_questions,
                                                           o_interv_supplies           => l_dummy_cursor,
                                                           o_error                     => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        
            -- 6 - External discipline(s)
            g_error := 'GET get_dep_clin_servs <- External discipline(s)';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wtl_pbl_core.get_dep_clin_servs(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_waiting_list => i_id_waiting_list,
                                                      i_id_episode      => i_id_episode,
                                                      i_flg_type        => pk_wtl_pbl_core.g_wtl_dcs_type_ext_disc,
                                                      i_all             => pk_alert_constant.g_no,
                                                      o_dcs             => o_ext_disc,
                                                      o_error           => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        
            -- 7 - Danger of contamination
            g_error := 'GET get_danger_cont';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wtl_pbl_core.get_danger_cont(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_episode      => i_id_episode,
                                                   i_id_waiting_list => i_id_waiting_list,
                                                   o_danger_cont     => o_danger_cont,
                                                   o_error           => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        
            -- 8 - Preferred time
            -- The default flg_status is 'A' - Active
            g_error := 'GET get_preferred_time';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wtl_pbl_core.get_preferred_time(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_wtlist      => l_id_wtlist,
                                                      o_preferred_time => o_preferred_time,
                                                      o_error          => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        
            -- 9 - Reason for preferred time
            g_error := 'GET get_surgical_procedures';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wtl_pbl_core.get_ptime_reason(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_id_wtlist        => i_id_waiting_list,
                                                    o_pref_time_reason => o_pref_time_reason,
                                                    o_error            => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        
            -- 10 - POS decision
            g_error := 'GET get_pos_decision';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_surgery_request.get_pos_decision(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_id_episode => i_id_episode,
                                                       o_pos        => o_pos,
                                                       o_error      => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        
            g_error := 'OPEN CURSOR o_surg_request';
            pk_alertlog.log_debug(g_error);
            OPEN o_surg_request FOR
                SELECT s.duration exp_dur, -- 4 - Expected duration
                       s.icu, -- 5 - Intensive care unit (ICU)
                       pk_sysdomain.get_domain('SCHEDULE_SR.ICU', s.icu, i_lang) desc_icu,
                       s.icu_pos, -- 5 - Intensive care unit (ICU)
                       pk_sysdomain.get_domain('SCHEDULE_SR.ICU', s.icu_pos, i_lang) desc_icu_pos,
                       s.notes, -- 11 - Notes
                       s.adm_needed, -- Admission Needed
                       pk_sysdomain.get_domain('SCHEDULE_SR.ADM_NEEDED', s.adm_needed, i_lang) desc_adm_needed,
                       we.flg_status waiting_list_status,
                       s.id_institution id_institution,
                       pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || s.id_institution) desc_institution,
                       pk_sysdomain.get_domain('SCHEDULE_SR.NEED_GLOBAL_ANESTH', s.need_global_anesth, i_lang) desc_need_global_anesth,
                       pk_sysdomain.get_domain('SCHEDULE_SR.NEED_LOCAL_ANESTH', s.need_local_anesth, i_lang) desc_need_local_anesth,
                       CASE
                            WHEN s.duration IS NULL THEN
                             NULL
                            WHEN s.duration <= 60 THEN
                             (s.duration / 60) || ' ' ||
                             pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M122')
                            ELSE
                             (s.duration / 60) || ' ' ||
                             pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M123')
                        END desc_exp_dur
                  FROM schedule_sr s
                  JOIN wtl_epis we
                    ON we.id_episode = s.id_episode
                   AND we.id_waiting_list = s.id_waiting_list
                 WHERE s.id_waiting_list = i_id_waiting_list
                   AND (s.id_episode = i_id_episode OR i_id_episode IS NULL);
        
        ELSE
            g_error := 'OPEN CURSORS';
            pk_alertlog.log_debug(g_error);
            pk_types.open_my_cursor(o_surg_request);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_runtime_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_surg_specs);
            pk_types.open_my_cursor(o_pref_surg);
            pk_types.open_my_cursor(o_procedures);
            pk_types.open_my_cursor(o_ext_disc);
            pk_types.open_my_cursor(o_danger_cont);
            pk_types.open_my_cursor(o_preferred_time);
            pk_types.open_my_cursor(o_pref_time_reason);
            pk_types.open_my_cursor(o_pos);
            pk_types.open_my_cursor(o_surg_request);
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_surg_specs);
            pk_types.open_my_cursor(o_pref_surg);
            pk_types.open_my_cursor(o_procedures);
            pk_types.open_my_cursor(o_ext_disc);
            pk_types.open_my_cursor(o_danger_cont);
            pk_types.open_my_cursor(o_preferred_time);
            pk_types.open_my_cursor(o_pref_time_reason);
            pk_types.open_my_cursor(o_pos);
            pk_types.open_my_cursor(o_surg_request);
            RETURN FALSE;
    END get_surgery_request;

    FUNCTION get_surg_proc_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_sr_epis_interv     IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_desc_type             IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB IS
    
        l_description CLOB;
    
        l_desc_interv CLOB;
        l_diag        CLOB;
        l_type        CLOB;
        l_notes       CLOB;
        l_flg_type    VARCHAR2(1 CHAR);
    
        l_tbl_desc_condition table_varchar;
        l_code               interv_codification.standard_code%TYPE;
    BEGIN
    
        SELECT desc_interv, diag, flg_type, notes, standard_code
          INTO l_desc_interv, l_diag, l_flg_type, l_notes, l_code
          FROM (SELECT pk_translation.get_translation(i_lang,
                                                      'INTERVENTION.CODE_INTERVENTION.' || sei.id_sr_intervention) desc_interv,
                       pk_prog_notes_in.get_diagnosis_desc(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_id_episode            => sei.id_episode,
                                                           i_id_epis_diagnosis     => sei.id_epis_diagnosis,
                                                           i_flg_description       => 'C',
                                                           i_description_condition => 'DIAG_DESC') diag,
                       sei.flg_type,
                       sei.notes,
                       ic.standard_code
                  FROM sr_epis_interv sei
                  LEFT JOIN interv_codification ic
                    ON ic.id_interv_codification = sei.id_interv_codification
                 WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv) t;
    
        IF i_desc_type = 'C'
        THEN
            IF i_description_condition IS NOT NULL
            THEN
                l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            
                <<lup_thru_cond>>
                FOR i IN 1 .. l_tbl_desc_condition.last
                LOOP
                    IF l_tbl_desc_condition(i) = 'INTERV_DESC'
                    THEN
                        IF l_desc_interv IS NOT NULL
                        THEN
                            IF l_description IS NOT NULL
                            THEN
                                l_description := l_description || ', ' || l_desc_interv;
                            ELSE
                                l_description := l_desc_interv;
                            END IF;
                        END IF;
                    ELSIF l_tbl_desc_condition(i) = 'NOTES'
                    THEN
                        IF l_notes IS NOT NULL
                        THEN
                            IF l_description IS NOT NULL
                            THEN
                                l_description := l_description || ', ' || l_notes;
                            ELSE
                                l_description := l_notes;
                            END IF;
                        END IF;
                    ELSIF l_tbl_desc_condition(i) = 'CODE'
                    THEN
                        IF l_code IS NOT NULL
                        THEN
                            IF l_code IS NOT NULL
                            THEN
                                l_description := l_description || '/ ' || l_code;
                            ELSE
                                l_description := l_code;
                            END IF;
                        END IF;
                    END IF;
                END LOOP lup_thru_cond;
            ELSE
                IF l_flg_type = 'P'
                THEN
                    l_type := pk_message.get_message(i_lang, 'ID_PRIMARY');
                ELSE
                    l_type := pk_message.get_message(i_lang, 'ID_SECONDARY');
                END IF;
            
                l_description := l_desc_interv;
            
                IF l_type IS NOT NULL
                THEN
                    l_description := l_description || ', ' || l_type;
                END IF;
                IF l_diag IS NOT NULL
                THEN
                    l_description := l_description || ', ' || l_diag;
                END IF;
            END IF;
        ELSE
            l_description := l_desc_interv;
        END IF;
    
        RETURN l_description;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_surg_proc_description;

    FUNCTION get_surgery_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_schedule_sr        IN schedule_sr.id_schedule_sr%TYPE,
        i_desc_type             IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB IS
    
        l_type_request  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T009');
        l_type_record   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T041');
        l_emergent      sys_domain.desc_val%TYPE := pk_sysdomain.get_domain('SR_SURGERY_RECORD.FLG_URGENCY',
                                                                            'U',
                                                                            i_lang);
        l_surg_proc     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SURGICAL_PROCEDURES_T001');
        l_description   CLOB;
        l_error_out     t_error_out;
        l_type_request2 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T042');
    
    BEGIN
    
        IF i_desc_type = 'C'
        THEN
            -- last hour before version ending... todo
            BEGIN
                SELECT type_desc || interv_desc
                  INTO l_description
                  FROM (SELECT l_surg_proc || ': ' type_desc,
                               
                               pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                        ssr.id_episode,
                                                                        i_prof,
                                                                        pk_alert_constant.g_no) interv_desc
                        
                          FROM schedule_sr ssr
                          LEFT JOIN waiting_list wl
                            ON wl.id_waiting_list = ssr.id_waiting_list
                          LEFT JOIN sr_pos_schedule pos
                            ON pos.id_schedule_sr = ssr.id_schedule_sr
                          LEFT JOIN wtl_dep_clin_serv wdcs
                            ON wdcs.id_waiting_list = wl.id_waiting_list
                           AND wdcs.flg_status = pk_alert_constant.g_sr_pos_status_a
                           AND wdcs.flg_type = pk_alert_constant.g_wtl_dcs_flg_type_s
                          LEFT JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = wdcs.id_dep_clin_serv
                          LEFT JOIN clinical_service cs
                            ON cs.id_clinical_service = dcs.id_clinical_service
                         WHERE ssr.id_schedule_sr = i_id_schedule_sr
                              -- AND wdcs.flg_type = pk_alert_constant.g_wtl_dcs_flg_type_s
                           AND nvl(ssr.adm_needed, pk_alert_constant.g_no) <> pk_alert_constant.g_yes) t;
            EXCEPTION
                WHEN no_data_found THEN
                    l_description := NULL;
            END;
        
        ELSE
            BEGIN
                SELECT t.type_desc || interv_desc ||
                       decode(t.clinical_service_desc, '', '', ', ' || t.clinical_service_desc) ||
                       decode(t.id_waiting_list, NULL, ', ' || l_emergent, '') ||
                       decode(i_desc_type,
                              pk_prog_notes_constants.g_desc_type_s,
                              nvl2(pk_date_utils.dt_chr_tsz(i_lang, dt_surgery, i_prof.institution, i_prof.software),
                                   ',' ||
                                   pk_date_utils.date_char_tsz(i_lang, dt_surgery, i_prof.institution, i_prof.software),
                                   ''),
                              '') || ', ' || t.status_desc
                  INTO l_description
                  FROM (SELECT decode(wl.id_waiting_list,
                                      NULL,
                                      l_type_record,
                                      decode(i_desc_type,
                                             pk_prog_notes_constants.g_desc_type_s,
                                             l_type_request2,
                                             l_type_request)) || ': ' type_desc,
                               wl.id_waiting_list,
                               pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                        ssr.id_episode,
                                                                        i_prof,
                                                                        pk_alert_constant.g_no) interv_desc,
                               pk_translation.get_translation(i_lang, cs.code_clinical_service) clinical_service_desc,
                               decode(ssr.dt_target_tstz,
                                      NULL,
                                      decode(wl.dt_surgery, NULL, NULL, wl.dt_surgery),
                                      ssr.dt_target_tstz) dt_surgery,
                               pk_surgery_request.get_wl_status_msg(i_lang,
                                                                    i_prof,
                                                                    decode(wl.id_waiting_list,
                                                                           NULL,
                                                                           pk_alert_constant.g_wl_status_s,
                                                                           pk_surgery_request.get_wl_status_flg(i_lang,
                                                                                                                i_prof,
                                                                                                                wl.id_waiting_list,
                                                                                                                decode(wl.flg_type,
                                                                                                                       pk_alert_constant.g_wl_status_a,
                                                                                                                       pk_alert_constant.g_yes,
                                                                                                                       pk_alert_constant.g_no),
                                                                                                                pos.id_sr_pos_status,
                                                                                                                pk_alert_constant.g_epis_type_operating,
                                                                                                                wl.flg_type))) status_desc
                          FROM schedule_sr ssr
                          LEFT JOIN waiting_list wl
                            ON wl.id_waiting_list = ssr.id_waiting_list
                          LEFT JOIN sr_pos_schedule pos
                            ON pos.id_schedule_sr = ssr.id_schedule_sr
                          LEFT JOIN wtl_dep_clin_serv wdcs
                            ON wdcs.id_waiting_list = wl.id_waiting_list
                           AND wdcs.flg_status = pk_alert_constant.g_sr_pos_status_a
                          LEFT JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = wdcs.id_dep_clin_serv
                          LEFT JOIN clinical_service cs
                            ON cs.id_clinical_service = dcs.id_clinical_service
                         WHERE ssr.id_schedule_sr = i_id_schedule_sr
                           AND wdcs.flg_type = pk_alert_constant.g_wtl_dcs_flg_type_s
                           AND nvl(ssr.adm_needed, pk_alert_constant.g_no) <> pk_alert_constant.g_yes) t;
            EXCEPTION
                WHEN no_data_found THEN
                    l_description := NULL;
            END;
        END IF;
    
        RETURN l_description;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SURGERY_DESCRIPTION',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_surgery_description;

    FUNCTION get_wtl_started_state
    (
        i_lang            IN language.id_language%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name     VARCHAR2(30) := 'GET_WTL_STARTED_STATE';
        l_dt_begin_null VARCHAR2(1);
        l_disch_null    VARCHAR2(1);
        l_epis_done     VARCHAR2(1) := pk_alert_constant.g_no;
        l_error_out     t_error_out;
    
        wtl_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'Get if waiting list inpatient episode already begun';
        pk_alertlog.log_debug(g_error);
        IF NOT get_begin_end_episode(i_lang,
                                     i_id_waiting_list,
                                     pk_alert_constant.g_epis_type_inpatient,
                                     l_dt_begin_null,
                                     l_disch_null,
                                     l_error_out)
        THEN
            RAISE wtl_exception;
        END IF;
    
        IF l_dt_begin_null = pk_alert_constant.g_no
        THEN
            l_epis_done := pk_alert_constant.g_yes;
        END IF;
    
        IF l_epis_done = pk_alert_constant.g_no
        THEN
            g_error := 'Get if waiting list oris episode already begun';
            pk_alertlog.log_debug(g_error);
            IF NOT get_begin_end_episode(i_lang,
                                         i_id_waiting_list,
                                         pk_alert_constant.g_epis_type_operating,
                                         l_dt_begin_null,
                                         l_disch_null,
                                         l_error_out)
            THEN
                RAISE wtl_exception;
            END IF;
        
            IF l_dt_begin_null = pk_alert_constant.g_no
            THEN
                l_epis_done := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN l_epis_done;
    
    EXCEPTION
        WHEN wtl_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error_out.ora_sqlcode,
                                              l_error_out.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error_out);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error_out);
    END get_wtl_started_state;

    FUNCTION check_running_oris_epis(i_id_episode IN schedule_sr.id_episode%TYPE) RETURN VARCHAR2 IS
    
        l_char VARCHAR2(1);
    
    BEGIN
    
        BEGIN
            SELECT decode(std.dt_surgery_time_det_tstz, NULL, pk_alert_constant.g_yes, pk_alert_constant.g_no)
              INTO l_char
              FROM schedule_sr ss
             INNER JOIN sr_surgery_time_det std
                ON std.id_episode = ss.id_episode
             INNER JOIN sr_surgery_time st
                ON st.id_sr_surgery_time = std.id_sr_surgery_time
             WHERE ss.id_episode = i_id_episode
               AND st.flg_type = pk_sr_visit.g_sst_flg_type_eb
               AND std.flg_status = pk_alert_constant.g_active;
        EXCEPTION
            WHEN no_data_found THEN
                l_char := pk_alert_constant.g_no;
        END;
    
        RETURN l_char;
    
    END check_running_oris_epis;

    FUNCTION set_epis_surg_interv_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_episode_context  IN episode.id_episode%TYPE,
        i_sr_intervention  IN table_number,
        i_codification     IN table_number,
        i_laterality       IN table_varchar,
        i_surgical_site    IN table_varchar,
        i_prof             IN profissional,
        i_sp_notes         IN table_varchar,
        i_dt_interv_start  IN table_varchar DEFAULT NULL,
        i_dt_interv_end    IN table_varchar DEFAULT NULL,
        i_dt_req           IN table_varchar DEFAULT NULL,
        i_flg_type         IN table_varchar DEFAULT NULL,
        i_flg_status       IN table_varchar DEFAULT NULL,
        i_flg_surg_request IN table_varchar DEFAULT NULL,
        -- team
        i_surgery_record          IN table_number DEFAULT NULL,
        i_prof_team               IN table_number DEFAULT NULL,
        i_tbl_prof                IN table_table_number DEFAULT NULL,
        i_tbl_catg                IN table_table_number DEFAULT NULL,
        i_tbl_status              IN table_table_varchar DEFAULT NULL,
        i_test                    IN VARCHAR2 DEFAULT NULL,
        i_diagnosis_surg_proc     IN pk_edis_types.rec_in_epis_diagnosis,
        i_id_cdr_call             IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        i_id_not_order_reason     IN not_order_reason.id_not_order_reason%TYPE,
        i_id_ct_io                IN table_table_varchar DEFAULT NULL,
        i_clinical_question       IN table_number DEFAULT NULL,
        i_response                IN table_varchar DEFAULT NULL,
        i_clinical_question_notes IN table_clob DEFAULT NULL,
        o_id_sr_epis_interv       OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sr_epis_interv sr_epis_interv%ROWTYPE;
        l_internal_error EXCEPTION;
        l_dt_req_tstz         sr_epis_interv.dt_req_tstz%TYPE;
        l_dt_interv_start     sr_epis_interv.dt_interv_start_tstz%TYPE;
        l_dt_interv_end       sr_epis_interv.dt_interv_end_tstz%TYPE;
        l_flg_type            sr_epis_interv.flg_type%TYPE;
        l_flg_status          sr_epis_interv.flg_status%TYPE;
        l_interv_codification interv_codification.id_interv_codification%TYPE;
        l_flg_surg_request    sr_epis_interv.flg_surg_request%TYPE;
        l_flg_add_problem     epis_diagnosis.flg_add_problem%TYPE;
    
        l_flg_show  VARCHAR2(1);
        l_msg_title sys_message.desc_message%TYPE;
        l_msg_text  sys_message.desc_message%TYPE;
        l_button    VARCHAR2(1);
    
        l_tbl_id_epis_diagnoses pk_edis_types.rec_in_epis_diagnoses;
        l_created_id_diag       pk_edis_types.table_out_epis_diags;
        l_id_ct_io              table_table_varchar;
    
        l_clinical_question       table_number := table_number();
        l_response                table_varchar := table_varchar();
        l_clinical_question_notes table_varchar := table_varchar();
        l_aux                     table_varchar2;
    
    BEGIN
    
        l_id_ct_io := i_id_ct_io;
    
        IF l_id_ct_io IS NULL
        THEN
            l_id_ct_io := table_table_varchar(table_varchar());
        END IF;
    
        FOR i IN 1 .. i_sr_intervention.count
        LOOP
            g_error := 'INSERT INTO SR_EPIS_INTERV';
            pk_alertlog.log_debug(g_error);
            l_sr_epis_interv := NULL;
            g_sysdate_tstz   := current_timestamp;
        
            IF i_dt_req IS NOT NULL
               AND i_dt_req.count > 0
            THEN
                l_dt_req_tstz := nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_req(i), NULL),
                                     current_timestamp);
            ELSE
                l_dt_req_tstz := g_sysdate_tstz;
            END IF;
        
            IF i_dt_interv_start IS NOT NULL
               AND i_dt_interv_start.count > 0
            THEN
                l_dt_interv_start := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_interv_start(i), NULL);
            ELSE
                l_dt_interv_start := NULL;
            
                g_error := 'CALL pk_sr_surg_record.get_surgery_time start date: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_surg_record.get_surgery_time(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_episode      => i_episode,
                                                          i_flg_type        => pk_sr_surg_record.g_type_surg_begin,
                                                          o_dt_surgery_time => l_dt_interv_start,
                                                          o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            IF i_dt_interv_end IS NOT NULL
               AND i_dt_interv_start.count > 0
            THEN
                l_dt_interv_end := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_interv_end(i), NULL);
            ELSE
                l_dt_interv_end := NULL;
            
                g_error := 'CALL pk_sr_surg_record.get_surgery_time end date: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_surg_record.get_surgery_time(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_episode      => i_episode,
                                                          i_flg_type        => pk_sr_surg_record.g_type_surg_end,
                                                          o_dt_surgery_time => l_dt_interv_end,
                                                          o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            IF i_flg_type IS NOT NULL
               AND i_flg_type.count > 0
            THEN
                l_flg_type := i_flg_type(i);
            ELSE
                l_flg_type := g_surg_proc_type_s;
            END IF;
        
            IF i_flg_status IS NOT NULL
               AND i_flg_status.count > 0
            THEN
                l_flg_status := i_flg_status(i);
            ELSE
                l_flg_status := g_surg_procedure_r;
            END IF;
        
            IF i_flg_surg_request IS NOT NULL
               AND i_flg_status.count > 0
            THEN
                l_flg_surg_request := i_flg_surg_request(i);
            ELSE
                l_flg_surg_request := pk_alert_constant.g_no;
            END IF;
        
            BEGIN
                SELECT ic.id_interv_codification
                  INTO l_interv_codification
                  FROM interv_codification ic
                 WHERE ic.id_codification = i_codification(i)
                   AND ic.id_intervention = i_sr_intervention(i)
                   AND ic.flg_available = pk_alert_constant.g_available;
            EXCEPTION
                WHEN no_data_found THEN
                    l_interv_codification := NULL;
            END;
        
            g_error := 'BUILDING DIAGNOSIS OBJECT';
            pk_alertlog.log_debug(g_error);
            IF i_diagnosis_surg_proc.tbl_diagnosis IS NOT NULL
               AND i_diagnosis_surg_proc.tbl_diagnosis.count > 0
            THEN
                l_tbl_id_epis_diagnoses.epis_diagnosis := i_diagnosis_surg_proc;
                IF i_diagnosis_surg_proc.tbl_diagnosis(i).flg_add_problem IS NULL
                THEN
                    l_tbl_id_epis_diagnoses.epis_diagnosis.tbl_diagnosis(i).flg_add_problem := pk_alert_constant.g_no;
                END IF;
            
                IF i_diagnosis_surg_proc.tbl_diagnosis(i).flg_status IS NULL
                THEN
                    l_tbl_id_epis_diagnoses.epis_diagnosis.tbl_diagnosis(i).flg_status := pk_diagnosis.g_ed_flg_status_d;
                END IF;
            
                IF i_diagnosis_surg_proc.flg_type IS NULL
                THEN
                    l_tbl_id_epis_diagnoses.epis_diagnosis.flg_type := pk_diagnosis.g_flg_final_type_p;
                END IF;
            
                l_tbl_id_epis_diagnoses.epis_diagnosis.id_episode := nvl(i_episode_context, i_episode);
            
                -- Create/Update patient's diagnosis
                g_error := 'CALL TO PK_DIAGNOSIS.SET_EPIS_DIAGNOSIS';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_epis_diagnoses => l_tbl_id_epis_diagnoses,
                                                       o_params         => l_created_id_diag,
                                                       o_error          => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            l_sr_epis_interv.dt_req_tstz            := l_dt_req_tstz;
            l_sr_epis_interv.id_prof_req            := i_prof.id;
            l_sr_epis_interv.id_sr_intervention     := i_sr_intervention(i);
            l_sr_epis_interv.flg_code_type          := g_flg_code_type_c;
            l_sr_epis_interv.id_episode             := i_episode;
            l_sr_epis_interv.flg_type               := l_flg_type;
            l_sr_epis_interv.flg_status := CASE
                                               WHEN i_id_not_order_reason IS NOT NULL THEN
                                                pk_sr_planning.g_sei_flg_status_n
                                               ELSE
                                                l_flg_status
                                           END;
            l_sr_epis_interv.id_episode_context     := nvl(i_episode_context, i_episode);
            l_sr_epis_interv.id_interv_codification := l_interv_codification;
            l_sr_epis_interv.laterality             := i_laterality(i);
            l_sr_epis_interv.surgical_site          := i_surgical_site(i);
            l_sr_epis_interv.flg_surg_request       := l_flg_surg_request;
            l_sr_epis_interv.id_epis_diagnosis := CASE
                                                      WHEN l_created_id_diag IS NOT NULL
                                                           AND l_created_id_diag.exists(1) THEN
                                                       l_created_id_diag(1).id_epis_diagnosis
                                                      ELSE
                                                       NULL
                                                  END;
            l_sr_epis_interv.notes                  := i_sp_notes(i);
            l_sr_epis_interv.dt_interv_start_tstz   := l_dt_interv_start;
            l_sr_epis_interv.dt_interv_end_tstz     := l_dt_interv_end;
            l_sr_epis_interv.id_cdr_call            := i_id_cdr_call;
            l_sr_epis_interv.id_not_order_reason    := i_id_not_order_reason;
        
            SELECT seq_sr_epis_interv.nextval
              INTO l_sr_epis_interv.id_sr_epis_interv
              FROM dual;
        
            o_id_sr_epis_interv := l_sr_epis_interv.id_sr_epis_interv;
        
            g_error := 'call pk_sr_output.insert_sr_epis_interv for id_episode : ' ||
                       l_sr_epis_interv.id_episode_context;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_output.insert_sr_epis_interv(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_sr_epis_interv => l_sr_epis_interv,
                                                      i_id_ct_io       => l_id_ct_io(i),
                                                      o_error          => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_EPIS_SURG_INTERV_NO_COMMIT',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            IF i_id_not_order_reason IS NULL
            THEN
                IF NOT pk_sr_tools.set_sr_prof_team_det_no_commit(i_lang              => i_lang,
                                                                  i_prof              => i_prof,
                                                                  i_surgery_record    => i_surgery_record(i),
                                                                  i_episode           => i_episode,
                                                                  i_episode_context   => i_episode_context,
                                                                  i_prof_team         => i_prof_team(i),
                                                                  i_tbl_prof          => i_tbl_prof(i),
                                                                  i_tbl_catg          => i_tbl_catg(i),
                                                                  i_tbl_status        => i_tbl_status(i),
                                                                  i_test              => i_test,
                                                                  i_id_sr_epis_interv => l_sr_epis_interv.id_sr_epis_interv,
                                                                  o_flg_show          => l_flg_show,
                                                                  o_msg_title         => l_msg_title,
                                                                  o_msg_text          => l_msg_text,
                                                                  o_button            => l_button,
                                                                  o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'Create suggestions for nursing interventions';
                IF NOT pk_sr_planning.create_assoc_icnp_interv(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_id_episode         => i_episode_context,
                                                               i_id_sr_epis_interv  => l_sr_epis_interv.id_sr_epis_interv,
                                                               i_id_sr_intervention => i_sr_intervention(i),
                                                               o_error              => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'SET_EPIS_SURG_INTERV_NO_COMMIT',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            END IF;
        
            IF i_clinical_question.count != 0
            THEN
                FOR i IN 1 .. i_clinical_question.count
                LOOP
                    IF i_clinical_question(i) IS NOT NULL
                    THEN
                        g_error := 'INSERT INTO INTERV_QUESTION_RESPONSE';
                        INSERT INTO sr_interv_quest_response
                            (id_sr_interv_quest_response,
                             id_episode,
                             id_sr_epis_interv,
                             flg_time,
                             id_questionnaire,
                             id_response,
                             notes,
                             id_prof_last_update,
                             dt_last_update_tstz)
                        VALUES
                            (seq_interv_question_response.nextval,
                             i_episode,
                             l_sr_epis_interv.id_sr_epis_interv,
                             pk_procedures_constant.g_interv_cq_on_order,
                             i_clinical_question(i),
                             i_response(i),
                             i_clinical_question_notes(i),
                             i_prof.id,
                             g_sysdate_tstz);
                    
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
    
        IF i_sr_intervention.count > 0
        THEN
            g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
            pk_alertlog.log_debug(g_error);
            g_sysdate_tstz := current_timestamp;
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_EPIS_SURG_INTERV_NO_COMMIT',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_SURG_INTERV_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_surg_interv_no_commit;

    FUNCTION cancel_epis_surg_remov_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN table_number,
        i_id_episode        IN episode.id_episode%TYPE,
        i_sysdate           IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name          VARCHAR2(30 CHAR) := 'CANCEL_EPIS_SURG_REMOV_LIST';
        l_empty_array_number table_number := table_number();
        l_id_supply          table_number;
        l_id_supply_workflow table_number;
        l_found              VARCHAR2(1 CHAR);
        l_excep EXCEPTION;
        l_id_cancel_reason   cancel_reason.id_cancel_reason%TYPE;
        l_id_sr_intervention intervention.id_intervention%TYPE;
        l_rowids             table_varchar;
        l_flg_status_old     sr_epis_interv.flg_status%TYPE;
    
    BEGIN
        g_error := 'GET CANCEL REASON DEFAUT DEFINED IN SYSCONFIG';
        pk_alertlog.log_debug(g_error);
        l_id_cancel_reason := to_number(pk_sysconfig.get_config('SR_CANCEL_REASON_SURG_SUPPLIES', i_prof));
    
        FOR i IN i_id_sr_epis_interv.first .. i_id_sr_epis_interv.last
        LOOP
        
            g_error := 'GET INTERVENTION TO BE CANCELLED';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT sei.id_sr_intervention
                  INTO l_id_sr_intervention
                  FROM sr_epis_interv sei
                 WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv(i)
                   AND sei.flg_status <> pk_sr_planning.g_cancel
                   AND sei.id_sr_intervention IS NOT NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_sr_intervention := NULL;
            END;
        
            g_error := 'GET old flg_status';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT sei.flg_status
                  INTO l_flg_status_old
                  FROM sr_epis_interv sei
                 WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv(i)
                   AND sei.flg_status <> pk_sr_planning.g_cancel
                   AND sei.id_episode_context = i_id_episode;
            EXCEPTION
                WHEN dup_val_on_index THEN
                    l_flg_status_old := NULL;
            END;
            IF l_flg_status_old IS NOT NULL
            THEN
                -- Cancel existing interventions that were removed from the current selection.
                -- If all the selection was removed, then all interventions of the episode are cancelled.
                g_error := 'CANCEL INTERVENTIONS NOT IN SELECTION';
                pk_alertlog.log_debug(g_error);
                ts_sr_epis_interv.upd(flg_status_in           => pk_sr_planning.g_cancel,
                                      dt_cancel_tstz_in       => i_sysdate,
                                      notes_cancel_in         => NULL,
                                      notes_cancel_nin        => FALSE,
                                      id_prof_cancel_in       => i_prof.id,
                                      id_sr_cancel_reason_in  => NULL,
                                      id_sr_cancel_reason_nin => FALSE,
                                      where_in                => 'id_sr_epis_interv = ' || i_id_sr_epis_interv(i) ||
                                                                 ' AND flg_status <> ''' || pk_sr_planning.g_cancel ||
                                                                 ''' AND id_episode_context = ' || i_id_episode,
                                      rows_out                => l_rowids);
            
                g_error := 'call t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SR_EPIS_INTERV',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'call pk_sr_output.set_ia_event_prescription';
                IF NOT pk_sr_output.set_ia_event_prescription(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_flg_action        => 'U',
                                                              i_id_sr_epis_interv => i_id_sr_epis_interv(i),
                                                              i_flg_status_new    => pk_sr_planning.g_cancel,
                                                              i_flg_status_old    => l_flg_status_old,
                                                              o_error             => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        
            IF l_id_sr_intervention IS NOT NULL
            THEN
                IF NOT pk_sr_planning.cancel_assoc_icnp_interv(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_sr_epis_interv => i_id_sr_epis_interv(i),
                                                               o_error             => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'CANCEL_EPIS_SURG_REMOV_LIST',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            END IF;
        
            g_error := 'CALL PK_SUPPLIES_EXTERNAL_API_DB.GET_INF_SUPPLY_WORKFLOW FOR ID_CONTEXT: ' ||
                       i_id_sr_epis_interv(i);
            pk_alertlog.log_debug(g_error);
            --get the id_supply_workflows 
            IF NOT pk_supplies_external_api_db.get_inf_supply_workflow(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_id_context         => i_id_sr_epis_interv(i),
                                                                       i_flg_context        => pk_supplies_constant.g_context_surgery,
                                                                       i_id_supply          => l_empty_array_number,
                                                                       i_flg_status         => pk_supplies_constant.g_flg_status_can_cancel,
                                                                       o_has_supplies       => l_found,
                                                                       o_id_supply_workflow => l_id_supply_workflow,
                                                                       o_id_supply          => l_id_supply,
                                                                       o_error              => o_error)
            THEN
                RAISE l_excep;
            END IF;
        
            IF l_found = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL pk_supplies_api_db.set_cancel_supply for id_episode: ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                --cancel supplies associated with the surgical procedure
                IF NOT pk_supplies_api_db.cancel_supply_order(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_supplies         => l_id_supply_workflow,
                                                              i_id_prof_cancel   => NULL,
                                                              i_cancel_notes     => to_clob(NULL),
                                                              i_id_cancel_reason => l_id_cancel_reason,
                                                              i_dt_cancel        => NULL,
                                                              o_error            => o_error)
                THEN
                    RAISE l_excep;
                END IF;
            
            END IF;
        
            g_error := 'CALL PK_SUPPLIES_EXTERNAL_API_DB.GET_INF_SUPPLY_WORKFLOW FOR INDEPENDENT SUPPLIES for id_context: ' ||
                       i_id_sr_epis_interv(i) || 'and flg_context: ' || pk_supplies_constant.g_context_surgery;
            pk_alertlog.log_debug(g_error);
            --get the id_supply_workflows 
            IF NOT pk_supplies_external_api_db.get_inf_supply_workflow(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_id_context         => i_id_sr_epis_interv(i),
                                                                       i_flg_context        => pk_supplies_constant.g_context_surgery,
                                                                       i_id_supply          => l_empty_array_number,
                                                                       i_flg_status         => pk_supplies_constant.g_flg_status_cannot_cancel,
                                                                       o_has_supplies       => l_found,
                                                                       o_id_supply_workflow => l_id_supply_workflow,
                                                                       o_id_supply          => l_id_supply,
                                                                       o_error              => o_error)
            THEN
                RAISE l_excep;
            END IF;
        
            IF l_found = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL PK_SUPPLIES_EXTERNAL_API_DB.SET_INDEPENDENT_SUPPLY';
                pk_alertlog.log_debug(g_error);
                --put independent supplies (remove the association surgical procedure)
                IF NOT pk_supplies_external_api_db.set_independent_supply(i_lang               => i_lang,
                                                                          i_prof               => i_prof,
                                                                          i_id_supply_workflow => l_id_supply_workflow,
                                                                          o_error              => o_error)
                THEN
                    RAISE l_excep;
                END IF;
            END IF;
        
            l_id_supply_workflow := l_empty_array_number; -- reset variable
            l_id_supply          := l_empty_array_number; -- reset variable
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_excep THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_epis_surg_remov_list;

    FUNCTION get_sr_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_start_dt IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt   IN TIMESTAMP WITH TIME ZONE DEFAULT NULL
    ) RETURN t_tbl_sr_episodes IS
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'Call timeframe GET_SR_EPISODES';
        RETURN get_sr_episodes_int(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_scope      => i_patient,
                                   i_flg_scope  => pk_alert_constant.g_scope_type_patient,
                                   i_start_date => i_start_dt,
                                   i_end_date   => i_end_dt,
                                   i_cancelled  => pk_alert_constant.g_yes,
                                   i_crit_type  => g_sr_crit_type_all_a,
                                   i_flg_report => pk_alert_constant.g_no);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SR_EPISODES',
                                              l_error);
            RETURN NULL;
    END get_sr_episodes;

    FUNCTION get_sr_episodes_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN TIMESTAMP WITH TIME ZONE,
        i_end_date   IN TIMESTAMP WITH TIME ZONE,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2
    ) RETURN t_tbl_sr_episodes IS
    
        l_tbl_sr_epis t_tbl_sr_episodes;
    
        l_grid_date_format sys_message.desc_message%TYPE;
        l_error            t_error_out;
    
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_patient patient.id_patient%TYPE;
    
        e_invalid_argument EXCEPTION;
    
    BEGIN
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_flg_scope,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => l_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        -- GET institution date format string
        l_grid_date_format := pk_message.get_message(i_lang, g_grid_date_format);
    
        SELECT t_rec_sr_episodes(id_patient,
                                  id_episode,
                                  id_schedule_sr,
                                  id_waiting_list,
                                  surg_proc,
                                  flg_status,
                                  admiss_epis_done,
                                  surgery_epis_done,
                                  waiting_list_type,
                                  adm_needed,
                                  pk_date_utils.to_char_insttimezone(i_lang, i_prof, dt_surgery, l_grid_date_format),
                                  pk_date_utils.date_send_tsz(i_lang, dt_surgery, i_prof),
                                  duration,
                                  duration_minutes,
                                  pos_status,
                                  admiss_status,
                                  oris_status,
                                  sr_type,
                                  sr_type_icon,
                                  id_inst_surg,
                                  inst_surg_name,
                                  sr_status,
                                  flg_pos_expired,
                                  pk_translation.get_translation(i_lang,
                                                                 (SELECT i.code_institution
                                                                    FROM institution i
                                                                   WHERE i.id_institution = tbl_info.id_dest_inst)),
                                  id_dest_inst,
                                  id_adm_request,
                                  dt_admission_tsz,
                                  id_prof_req,
                                  id_dest_prof,
                                  sr_status,
                                  id_dep_clin_serv,
                                  id_schedule,
                                  pk_admission_request.get_all_diagnosis_str(i_lang, tbl_info.id_episode),
                                  id_dest_inst,
                                  --
                                  flg_surg_nat,
                                  desc_surg_nat,
                                  flg_priority,
                                  CASE
                                      WHEN sr_type = pk_alert_constant.g_no THEN
                                       pk_sysdomain.get_domain('SR_SURGERY_RECORD.FLG_URGENCY', 'U', i_lang)
                                      ELSE
                                       NULL
                                  END,
                                  flg_sr_proc,
                                  id_room,
                                  desc_room,
                                  CASE
                                      WHEN flg_status IN (pk_alert_constant.g_adm_req_status_pend, pk_alert_constant.g_adm_req_status_sche) THEN
                                       pk_alert_constant.get_no
                                      WHEN flg_status_pos NOT IN (pk_consult_req.g_sched_pend, pk_consult_req.g_sched_canc) THEN
                                       pk_alert_constant.get_no
                                      ELSE
                                       pk_alert_constant.get_yes
                                  END,
                                  id_prev_episode)
          BULK COLLECT
          INTO l_tbl_sr_epis
          FROM (SELECT t.id_patient,
                        t.id_episode,
                        t.id_schedule_sr,
                        t.id_waiting_list,
                        t.surg_proc,
                        decode(admiss_epis_done,
                               pk_alert_constant.g_yes,
                               pk_alert_constant.g_adm_req_status_done,
                               decode(surgery_epis_done,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_adm_req_status_done,
                                      t.flg_status)) flg_status,
                        t.admiss_epis_done,
                        t.surgery_epis_done,
                        t.waiting_list_type,
                        t.adm_needed,
                        decode(t.flg_epis_status,
                               'C',
                               t.dt_cancel,
                               decode(t.dt_target_tstz,
                                      NULL,
                                      decode(t.dt_surgery, NULL, NULL, t.dt_surgery),
                                      t.dt_target_tstz)) dt_surgery,
                        t.duration,
                        t.duration_minutes,
                        t.pos_status,
                        t.admiss_status,
                        t.oris_status,
                        t.sr_type,
                        t.sr_type_icon,
                        t.id_inst_surg,
                        t.inst_surg_name,
                        pk_surgery_request.get_wl_status_msg(i_lang, i_prof, t.flg_epis_status) sr_status,
                        t.flg_pos_expired,
                        decode(t.flg_epis_status,
                               'C',
                               t.dt_cancel,
                               decode(t.dt_target_tstz,
                                      NULL,
                                      decode(t.dt_surgery, NULL, NULL, t.dt_surgery),
                                      t.dt_target_tstz)) dt_admission_tsz,
                        
                        t.id_dest_prof,
                        t.id_prof_req,
                        t.id_adm_request,
                        t.id_dep_clin_serv,
                        t.id_schedule,
                        t.id_dest_inst,
                        t.flg_surg_nat,
                        t.desc_surg_nat,
                        t.flg_priority,
                        t.flg_sr_proc,
                        t.id_room,
                        t.desc_room,
                        t.flg_status_pos,
                        t.id_prev_episode
                   FROM (SELECT ssr.id_patient,
                                ssr.id_episode,
                                ssr.id_schedule_sr,
                                ssr.id_waiting_list,
                                pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                         ssr.id_episode,
                                                                         i_prof,
                                                                         pk_alert_constant.g_no) surg_proc,
                                wtl.flg_status,
                                pk_surgery_request.get_epis_done_state(i_lang,
                                                                       wtl.id_waiting_list,
                                                                       pk_alert_constant.g_epis_type_inpatient) admiss_epis_done,
                                pk_surgery_request.get_epis_done_state(i_lang,
                                                                       wtl.id_waiting_list,
                                                                       pk_alert_constant.g_epis_type_operating) surgery_epis_done,
                                wtl.flg_type waiting_list_type,
                                nvl(ssr.adm_needed, pk_alert_constant.g_no) adm_needed,
                                pk_surgery_request.get_duration(i_lang, ssr.duration) duration,
                                ssr.duration duration_minutes,
                                get_sr_pos_status_str(i_lang,
                                                      i_prof,
                                                      pos.flg_status,
                                                      pos.id_sr_pos_status,
                                                      wtl.id_waiting_list,
                                                      pos.id_schedule_sr) pos_status,
                                pk_surgery_request.get_completwl_status_str(i_lang,
                                                                            i_prof,
                                                                            wtl.id_waiting_list,
                                                                            nvl(ssr.adm_needed, pk_alert_constant.g_no),
                                                                            pos.id_sr_pos_status,
                                                                            pk_alert_constant.g_epis_type_inpatient,
                                                                            wtl.flg_type) admiss_status,
                                pk_surgery_request.get_wl_status_str(i_lang,
                                                                     i_prof,
                                                                     wtl.id_waiting_list,
                                                                     nvl(ssr.adm_needed, pk_alert_constant.g_no),
                                                                     pos.id_sr_pos_status,
                                                                     pk_alert_constant.g_epis_type_operating,
                                                                     wtl.flg_type) oris_status,
                                pk_alert_constant.g_active sr_type,
                                pk_sysdomain.get_img(i_lang, 'SCHEDULE_SR.FLG_SCHED', pk_alert_constant.g_active) sr_type_icon,
                                ssr.id_institution id_inst_surg,
                                pk_translation.get_translation(i_lang, i.code_institution) inst_surg_name,
                                decode(ssr.flg_sched,
                                       pk_alert_constant.g_active,
                                       pk_message.get_message(i_lang, 'INP_GRID_SR_T003'),
                                       pk_message.get_message(i_lang, 'INP_GRID_SR_T004')) sr_status,
                                pk_surgery_request.get_wl_status_flg(i_lang,
                                                                     i_prof,
                                                                     wtl.id_waiting_list,
                                                                     nvl(ssr.adm_needed, pk_alert_constant.g_no),
                                                                     pos.id_sr_pos_status,
                                                                     pk_alert_constant.g_epis_type_operating,
                                                                     wtl.flg_type) flg_epis_status,
                                ssr.dt_target_tstz,
                                wtl.dt_surgery,
                                wtl.dt_cancel,
                                (CASE
                                     WHEN (wtl.dt_cancel IS NOT NULL) THEN
                                      pk_alert_constant.g_no
                                     WHEN (check_running_oris_epis(ssr.id_episode) = pk_alert_constant.g_yes) THEN
                                      pk_alert_constant.g_no
                                     WHEN (pk_sr_pos.check_pos_is_expired(i_lang, i_prof, pos.dt_valid, sps.flg_status) =
                                          pk_alert_constant.g_yes) THEN
                                      pk_alert_constant.g_yes
                                     WHEN sps.flg_status = pk_alert_constant.g_sr_pos_status_na THEN
                                      pk_alert_constant.g_yes
                                     WHEN sps.flg_status = pk_alert_constant.g_sr_pos_status_no THEN
                                      pk_alert_constant.g_yes
                                     ELSE
                                      pk_alert_constant.g_no
                                 END) flg_pos_expired,
                                rank() over(PARTITION BY ssr.id_schedule_sr ORDER BY pos.dt_req DESC, pos.dt_reg DESC) origin_rank,
                                NULL id_dest_prof, --ar.id_dest_prof,
                                NULL id_prof_req, --wl.id_prof_req,
                                NULL id_adm_request, --ar.id_adm_request,
                                NULL id_dep_clin_serv, --ar.id_dep_clin_serv,
                                ssr.id_schedule,
                                NULL id_dest_inst, --ar.id_dest_inst
                                srsr.flg_surg_nat,
                                pk_sysdomain.get_domain('SR_SURGERY_RECORD.FLG_SURG_NAT', srsr.flg_surg_nat, i_lang) desc_surg_nat,
                                srsr.flg_priority,
                                srsr.flg_sr_proc,
                                ro.id_room,
                                nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)) desc_room,
                                cr.flg_status flg_status_pos,
                                epis.id_prev_episode
                           FROM schedule_sr ssr
                          INNER JOIN waiting_list wtl
                             ON wtl.id_waiting_list = ssr.id_waiting_list
                           LEFT JOIN sr_pos_schedule pos
                             ON pos.id_schedule_sr = ssr.id_schedule_sr
                           LEFT JOIN (SELECT id_sr_pos_status, flg_status
                                       FROM (SELECT sps1.id_sr_pos_status,
                                                    sps1.flg_status,
                                                    rank() over(ORDER BY sps1.id_institution DESC) origin_rank
                                               FROM sr_pos_status sps1
                                              WHERE sps1.id_institution IN (0, i_prof.institution))
                                      WHERE origin_rank = 1) sps
                             ON sps.id_sr_pos_status = pos.id_sr_pos_status
                           LEFT JOIN consult_req cr
                             ON cr.id_consult_req = pos.id_pos_consult_req
                          INNER JOIN institution i
                             ON i.id_institution = ssr.id_institution
                          INNER JOIN sr_surgery_record srsr
                             ON ssr.id_schedule_sr = srsr.id_schedule_sr
                           LEFT OUTER JOIN room_scheduled rs
                             ON ssr.id_schedule = rs.id_schedule
                            AND rs.flg_status = pk_alert_constant.g_active
                           LEFT OUTER JOIN room ro
                             ON rs.id_room = ro.id_room
                          INNER JOIN (SELECT *
                                       FROM episode t
                                      WHERE t.id_episode = l_id_episode
                                        AND i_flg_scope = pk_alert_constant.g_scope_type_episode
                                     UNION ALL
                                     SELECT *
                                       FROM episode t
                                      WHERE t.id_patient = l_id_patient
                                        AND i_flg_scope = pk_alert_constant.g_scope_type_patient
                                     UNION ALL
                                     SELECT *
                                       FROM episode t
                                      WHERE t.id_visit = l_id_visit
                                        AND i_flg_scope = pk_alert_constant.g_scope_type_visit) epis
                             ON ssr.id_episode = epis.id_episode
                          WHERE (
                                --if not report show all
                                 i_flg_report = pk_alert_constant.g_no OR
                                --if report and not to show cancellations
                                 (i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                                 wtl.flg_status <> pk_alert_constant.g_cancelled AND
                                 (pos.flg_status <> pk_alert_constant.g_cancelled OR pos.flg_status IS NULL)) OR
                                --if report and show cancellations
                                 (i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes))
                            AND (nvl(ssr.dt_target_tstz, wtl.dt_surgery) IS NULL OR
                                (nvl(ssr.dt_target_tstz, wtl.dt_surgery) BETWEEN
                                nvl(i_start_date, nvl(ssr.dt_target_tstz, wtl.dt_surgery)) AND
                                nvl(i_end_date, nvl(ssr.dt_target_tstz, wtl.dt_surgery))))) t
                  WHERE t.origin_rank = 1
                 UNION
                 SELECT t_epis.id_patient,
                        t_epis.id_episode,
                        t_epis.id_schedule_sr,
                        t_epis.id_waiting_list,
                        t_epis.surg_proc,
                        t_epis.flg_status,
                        t_epis.admiss_epis_done,
                        t_epis.surgery_epis_done,
                        t_epis.waiting_list_type,
                        t_epis.adm_needed,
                        t_epis.dt_surgery_int    dt_surgery,
                        t_epis.duration,
                        t_epis.duration_minutes,
                        t_epis.pos_status,
                        t_epis.admiss_status,
                        t_epis.oris_status,
                        t_epis.sr_type,
                        t_epis.sr_type_icon,
                        t_epis.id_inst_surg,
                        t_epis.inst_surg_name,
                        t_epis.sr_status,
                        t_epis.flg_pos_expired,
                        dt_surgery_int           dt_admission_tsz,
                        NULL                     id_dest_prof,
                        NULL                     id_prof_req,
                        NULL                     id_adm_request,
                        t_epis.id_dep_clin_serv,
                        NULL                     id_schedule,
                        t_epis.id_dest_inst,
                        t_epis.flg_surg_nat,
                        t_epis.desc_surg_nat,
                        t_epis.flg_priority,
                        t_epis.flg_sr_proc,
                        t_epis.id_room,
                        t_epis.desc_room,
                        NULL                     flg_status_pos,
                        t_epis.id_prev_episode
                   FROM (SELECT DISTINCT e.id_patient,
                                          e.id_episode,
                                          ss.id_schedule_sr,
                                          NULL id_waiting_list,
                                          pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                                   e.id_episode,
                                                                                   i_prof,
                                                                                   pk_alert_constant.g_no) surg_proc,
                                          
                                          decode(e.flg_status,
                                                  pk_alert_constant.g_epis_status_cancel,
                                                  pk_alert_constant.g_adm_req_status_canc,
                                                  decode(pk_sr_approval.get_status_surg_proc(i_lang, i_prof, e.id_episode),
                                                          --for the emergency episodes ORIS, we've put another status only for the grid information
                                                      --because flash controls if is scheduled we cannot cancel episodes and for this episodes
                                                      --is necessary have the same behaviour than ORIS episode for the PT market
                                                      g_schedule_emergency_ep,
                                                      pk_sr_approval.g_scheduled,
                                                      decode((SELECT decode(COUNT(0),
                                                                           0,
                                                                           pk_alert_constant.g_yes,
                                                                           pk_alert_constant.g_no)
                                                               FROM discharge dis
                                                              WHERE dis.id_episode = e.id_episode
                                                                AND dis.flg_status = pk_alert_constant.g_active
                                                                AND dis.dt_med_tstz IS NOT NULL
                                                                AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                                            i_prof,
                                                                                                            dis.id_discharge,
                                                                                                            dis.flg_status_adm) =
                                                                    pk_alert_constant.g_yes),
                                                             pk_alert_constant.g_yes,
                                                             pk_alert_constant.g_adm_req_status_unde,
                                                             pk_alert_constant.g_adm_req_status_done))) flg_status,
                                        
                                        decode((SELECT decode(COUNT(0), 0, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                                                 FROM discharge dis
                                                WHERE dis.id_episode = e.id_episode
                                                  AND dis.flg_status = pk_alert_constant.g_active
                                                  AND dis.dt_med_tstz IS NOT NULL
                                                  AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                              i_prof,
                                                                                              dis.id_discharge,
                                                                                              dis.flg_status_adm) =
                                                      pk_alert_constant.g_yes),
                                               pk_alert_constant.g_yes,
                                               pk_alert_constant.g_no,
                                               pk_alert_constant.g_yes) admiss_epis_done,
                                        
                                        decode((SELECT decode(COUNT(0), 0, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                                                 FROM discharge dis
                                                WHERE dis.id_episode = e.id_episode
                                                  AND dis.flg_status = pk_alert_constant.g_active
                                                  AND dis.dt_med_tstz IS NOT NULL
                                                  AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                              i_prof,
                                                                                              dis.id_discharge,
                                                                                              dis.flg_status_adm) =
                                                      pk_alert_constant.g_yes),
                                               pk_alert_constant.g_yes,
                                               pk_alert_constant.g_no,
                                               pk_alert_constant.g_yes) surgery_epis_done,
                                        NULL waiting_list_type,
                                        NULL adm_needed,
                                        decode(decode(e.flg_status,
                                                      pk_alert_constant.g_epis_status_cancel,
                                                      pk_alert_constant.g_adm_req_status_canc,
                                                      (decode((SELECT decode(COUNT(0),
                                                                            0,
                                                                            pk_alert_constant.g_yes,
                                                                            pk_alert_constant.g_no)
                                                                FROM discharge dis
                                                               WHERE dis.id_episode = e.id_episode
                                                                 AND dis.flg_status = pk_alert_constant.g_active
                                                                 AND dis.dt_med_tstz IS NOT NULL
                                                                 AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                                             i_prof,
                                                                                                             dis.id_discharge,
                                                                                                             dis.flg_status_adm) =
                                                                     pk_alert_constant.g_yes),
                                                              pk_alert_constant.g_yes,
                                                              pk_alert_constant.g_adm_req_status_unde,
                                                              pk_alert_constant.g_adm_req_status_done))),
                                               pk_alert_constant.g_adm_req_status_canc,
                                               ss.dt_target_tstz,
                                               pk_alert_constant.g_adm_req_status_unde,
                                               nvl(ss.dt_target_tstz, e.dt_begin_tstz),
                                               pk_alert_constant.g_adm_req_status_done,
                                               (SELECT pk_discharge_core.get_dt_admin(i_lang, i_prof, d.id_discharge)
                                                  FROM discharge d
                                                 WHERE d.id_episode = e.id_episode)) dt_surgery_int,
                                        pk_surgery_request.get_duration(i_lang, ss.duration) duration,
                                        ss.duration duration_minutes,
                                        pk_utils.get_status_string_immediate(i_lang,
                                                                             i_prof,
                                                                             'I',
                                                                             decode(pk_sr_approval.get_status_surg_proc(i_lang,
                                                                                                                        i_prof,
                                                                                                                        e.id_episode),
                                                                                    pk_sr_approval.g_scheduled,
                                                                                    pk_alert_constant.g_adm_req_status_notneed,
                                                                                    pk_alert_constant.g_active),
                                                                             'SR_POS_STATUS.FLG_STATUS',
                                                                             'SR_POS_STATUS.FLG_STATUS',
                                                                             decode(pk_sr_approval.get_status_surg_proc(i_lang,
                                                                                                                        i_prof,
                                                                                                                        e.id_episode),
                                                                                    pk_sr_approval.g_scheduled,
                                                                                    'SCHEDULE_SR.ADM_NEEDED',
                                                                                    'SR_POS_STATUS.FLG_STATUS'),
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             current_timestamp) pos_status,
                                        pk_utils.get_status_string_immediate(i_lang,
                                                                             i_prof,
                                                                             'I',
                                                                             decode((SELECT COUNT(0)
                                                                                      FROM episode ep
                                                                                     WHERE ep.id_episode =
                                                                                           e.id_prev_episode
                                                                                       AND ep.id_visit = e.id_visit
                                                                                       AND ep.id_epis_type =
                                                                                           pk_alert_constant.g_epis_type_inpatient),
                                                                                    1,
                                                                                    decode((SELECT decode(COUNT(0),
                                                                                                         0,
                                                                                                         pk_alert_constant.g_yes,
                                                                                                         pk_alert_constant.g_no)
                                                                                             FROM discharge dis
                                                                                            WHERE dis.id_episode =
                                                                                                  e.id_episode
                                                                                              AND dis.flg_status =
                                                                                                  pk_alert_constant.g_active
                                                                                              AND dis.dt_med_tstz IS NOT NULL
                                                                                              AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                                                                          i_prof,
                                                                                                                                          dis.id_discharge,
                                                                                                                                          dis.flg_status_adm) =
                                                                                                  pk_alert_constant.g_yes),
                                                                                           pk_alert_constant.g_yes,
                                                                                           pk_alert_constant.g_adm_req_status_unde,
                                                                                           pk_alert_constant.g_adm_req_status_done),
                                                                                    pk_alert_constant.g_adm_req_status_notneed),
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             current_timestamp) admiss_status,
                                        pk_utils.get_status_string_immediate(i_lang,
                                                                             i_prof,
                                                                             'I',
                                                                             decode(e.flg_status,
                                                                                    pk_alert_constant.g_epis_status_cancel,
                                                                                    pk_alert_constant.g_adm_req_status_canc,
                                                                                    decode(pk_sr_approval.get_status_surg_proc(i_lang,
                                                                                                                               i_prof,
                                                                                                                               e.id_episode),
                                                                                           pk_sr_approval.g_scheduled,
                                                                                           pk_sr_approval.g_scheduled,
                                                                                           decode((SELECT decode(COUNT(0),
                                                                                                                0,
                                                                                                                pk_alert_constant.g_yes,
                                                                                                                pk_alert_constant.g_no)
                                                                                                    FROM discharge dis
                                                                                                   WHERE dis.id_episode =
                                                                                                         e.id_episode
                                                                                                     AND dis.flg_status =
                                                                                                         pk_alert_constant.g_active
                                                                                                     AND dis.dt_med_tstz IS NOT NULL
                                                                                                     AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                                                                                 i_prof,
                                                                                                                                                 dis.id_discharge,
                                                                                                                                                 dis.flg_status_adm) =
                                                                                                         pk_alert_constant.g_yes),
                                                                                                  pk_alert_constant.g_yes,
                                                                                                  pk_alert_constant.g_adm_req_status_unde,
                                                                                                  pk_alert_constant.g_adm_req_status_done))),
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             current_timestamp) oris_status,
                                        pk_alert_constant.g_no sr_type,
                                        pk_sysdomain.get_img(i_lang, 'SCHEDULE_SR.FLG_SCHED', pk_alert_constant.g_no) sr_type_icon,
                                        e.id_institution id_inst_surg,
                                        pk_translation.get_translation(i_lang, i.code_institution) inst_surg_name,
                                        decode(decode(e.flg_status,
                                                      pk_alert_constant.g_epis_status_cancel,
                                                      pk_alert_constant.g_adm_req_status_canc,
                                                      (decode(pk_sr_approval.get_status_surg_proc(i_lang,
                                                                                                  i_prof,
                                                                                                  e.id_episode),
                                                              pk_sr_approval.g_scheduled,
                                                              pk_sr_approval.g_scheduled,
                                                              (decode((SELECT decode(COUNT(0),
                                                                                    0,
                                                                                    pk_alert_constant.g_yes,
                                                                                    pk_alert_constant.g_no)
                                                                        FROM discharge dis
                                                                       WHERE dis.id_episode = e.id_episode
                                                                         AND dis.flg_status = pk_alert_constant.g_active
                                                                         AND dis.dt_med_tstz IS NOT NULL
                                                                         AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                                                     i_prof,
                                                                                                                     dis.id_discharge,
                                                                                                                     dis.flg_status_adm) =
                                                                             pk_alert_constant.g_yes),
                                                                      pk_alert_constant.g_yes,
                                                                      pk_alert_constant.g_adm_req_status_unde,
                                                                      pk_alert_constant.g_adm_req_status_done))))),
                                               pk_alert_constant.g_adm_req_status_canc,
                                               pk_message.get_message(i_lang, 'INP_GRID_SR_T006'),
                                               pk_alert_constant.g_adm_req_status_unde,
                                               pk_message.get_message(i_lang, 'INP_GRID_SR_T002'),
                                               pk_alert_constant.g_adm_req_status_done,
                                               pk_message.get_message(i_lang, 'INP_GRID_SR_T001'),
                                               pk_sr_approval.g_scheduled,
                                               pk_message.get_message(i_lang, 'INP_GRID_SR_T003')) sr_status,
                                        pk_alert_constant.g_no flg_pos_expired,
                                        ei.id_dep_clin_serv,
                                        e.id_institution id_dest_inst,
                                        srsr.flg_surg_nat,
                                        pk_sysdomain.get_domain('SR_SURGERY_RECORD.FLG_SURG_NAT',
                                                                srsr.flg_surg_nat,
                                                                i_lang) desc_surg_nat,
                                        srsr.flg_priority,
                                        srsr.flg_sr_proc,
                                        ro.id_room,
                                        nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)) desc_room,
                                        e.id_prev_episode
                          FROM (SELECT *
                                  FROM episode t
                                 WHERE t.id_episode = l_id_episode
                                   AND i_flg_scope = pk_alert_constant.g_scope_type_episode
                                UNION ALL
                                SELECT *
                                  FROM episode t
                                 WHERE t.id_patient = l_id_patient
                                   AND i_flg_scope = pk_alert_constant.g_scope_type_patient
                                UNION ALL
                                SELECT *
                                  FROM episode t
                                 WHERE t.id_visit = l_id_visit
                                   AND i_flg_scope = pk_alert_constant.g_scope_type_visit) e
                         INNER JOIN epis_info ei
                            ON ei.id_episode = e.id_episode
                         INNER JOIN schedule_sr ss
                            ON ss.id_episode = e.id_episode
                         INNER JOIN institution i
                            ON i.id_institution = e.id_institution
                         INNER JOIN sr_surgery_record srsr
                            ON ss.id_schedule_sr = srsr.id_schedule_sr
                          LEFT OUTER JOIN room_scheduled rs
                            ON ss.id_schedule = rs.id_schedule
                           AND rs.flg_status = pk_alert_constant.g_active
                          LEFT OUTER JOIN room ro
                            ON rs.id_room = ro.id_room
                         WHERE e.id_epis_type = pk_alert_constant.g_epis_type_operating
                           AND (
                               --if report and not to show cancellations
                                (i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                                e.flg_status = pk_alert_constant.g_active) OR
                               --if report and show cancellations
                                (i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                               --if not report show all
                                i_flg_report = pk_alert_constant.g_no)
                           AND e.dt_begin_tstz BETWEEN nvl(i_start_date, e.dt_begin_tstz) AND
                               nvl(i_end_date, e.dt_begin_tstz)
                         START WITH e.id_patient IN
                                    (SELECT t.id_patient
                                       FROM episode t
                                      WHERE t.id_episode = l_id_episode
                                        AND i_flg_scope = pk_alert_constant.g_scope_type_episode
                                     UNION ALL
                                     SELECT t.id_patient
                                       FROM episode t
                                      WHERE t.id_patient = l_id_patient
                                        AND i_flg_scope = pk_alert_constant.g_scope_type_patient
                                     UNION ALL
                                     SELECT t.id_patient
                                       FROM episode t
                                      WHERE t.id_visit = l_id_visit
                                        AND i_flg_scope = pk_alert_constant.g_scope_type_visit)
                        CONNECT BY PRIOR e.id_prev_episode = e.id_episode) t_epis
                 WHERE id_episode NOT IN (SELECT ssr.id_episode
                                            FROM schedule_sr ssr
                                           INNER JOIN waiting_list wtl
                                              ON wtl.id_waiting_list = ssr.id_waiting_list
                                            LEFT JOIN sr_pos_schedule pos
                                              ON pos.id_schedule_sr = ssr.id_schedule_sr
                                           INNER JOIN (SELECT *
                                                        FROM episode t
                                                       WHERE t.id_episode = l_id_episode
                                                         AND i_flg_scope = pk_alert_constant.g_scope_type_episode
                                                      UNION ALL
                                                      SELECT *
                                                        FROM episode t
                                                       WHERE t.id_patient = l_id_patient
                                                         AND i_flg_scope = pk_alert_constant.g_scope_type_patient
                                                      UNION ALL
                                                      SELECT *
                                                        FROM episode t
                                                       WHERE t.id_visit = l_id_visit
                                                         AND i_flg_scope = pk_alert_constant.g_scope_type_visit) e
                                              ON ssr.id_patient = e.id_patient)
                 ORDER BY oris_status, dt_surgery DESC) tbl_info;
    
        RETURN l_tbl_sr_epis;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SR_EPISODES_INT',
                                              l_error);
            RETURN NULL;
    END get_sr_episodes_int;

    FUNCTION get_fe_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret   sys_message.desc_message%TYPE;
        l_count NUMBER(12);
    
    BEGIN
    
        l_count := pk_episode.count_oris_inp_visit_epis(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_episode => i_id_episode);
    
        IF l_count = 1
        THEN
            l_ret := pk_message.get_message(i_lang, i_prof, 'ORIS_FE_T001');
        ELSE
            l_ret := pk_message.get_message(i_lang, i_prof, 'ORIS_FE_T002');
        END IF;
    
        RETURN l_ret;
    
    END get_fe_desc;

    FUNCTION get_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_subject       IN action.subject%TYPE,
        i_from_state    IN action.from_state%TYPE,
        i_id_episode_sr IN episode.id_episode%TYPE,
        o_actions       OUT pk_action.p_action_cur,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
    
        OPEN o_actions FOR
            SELECT /*+opt_estimate(table,act,scale_rows=0.0001)*/
             act.id_action,
             act.id_parent,
             act.level_nr AS "LEVEL", --used to manage the shown' items by Flash
             act.from_state,
             act.to_state, --destination state flag
             act.desc_action, --action's description
             act.icon, --action's icon
             act.flg_default, --default action
             CASE
                  WHEN act.action = 'ADM_REQUEST' THEN
                   CASE
                       WHEN pk_admission_request.get_can_admit(i_lang, i_prof, i_id_episode_sr) = pk_alert_constant.g_yes THEN
                        pk_alert_constant.g_active
                       ELSE
                        pk_alert_constant.g_inactive
                   END
                  ELSE
                   act.flg_active
              END flg_active, --action's state
             act.action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, i_subject, i_from_state)) act;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
            RETURN FALSE;
    END;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_surgery_request;
/
