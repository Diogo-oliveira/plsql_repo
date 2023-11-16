/*-- Last Change Revision: $Rev: 2027585 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_module AS

    g_error         VARCHAR2(4000);
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    /**
    * Checks to see if the schedule is completed
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_schedule       Schedule identifier to be associated to the referral   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   06-01-2010
    */
    FUNCTION is_completed
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
    
        -- search flg_ehr value in EPISODE table: IF 'N' then the registration process was started (schedule 'completed')
        CURSOR c_sch(x_id_schedule IN schedule.id_schedule%TYPE) IS
            SELECT flg_ehr
              FROM schedule s
              JOIN ref_map r
                ON s.id_schedule = r.id_schedule
              JOIN episode e
                ON e.id_episode = r.id_episode
             WHERE r.id_schedule = x_id_schedule
               AND r.flg_status = pk_ref_constant.g_active
               AND s.flg_status = pk_ref_constant.g_active;
    
        l_flg_ehr episode.flg_ehr%TYPE;
        l_result  VARCHAR2(2 CHAR);
    BEGIN
        -- CIRCLE UK: ALERT-27343
        g_error  := 'Init is_completed / ID_SCHEDULE=' || i_schedule;
        l_result := pk_ref_constant.g_no;
    
        -- search flg_ehr value in EPISODE table: IF 'N' then the registration process was started (schedule 'completed')
        OPEN c_sch(i_schedule);
        FETCH c_sch
            INTO l_flg_ehr;
        g_found := c_sch%FOUND;
        CLOSE c_sch;
    
        IF l_flg_ehr = pk_alert_constant.g_flg_ehr_n
        THEN
            -- registration process was started
            l_result := pk_ref_constant.g_yes;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_ref_constant.g_no;
    END is_completed;
    /**
    * Checks if is the first time that the referral is scheduled
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_ref_row        Referral data
    * @param   o_flg_status_new Referral new flag status
    * @param   o_error          An error message, set when return=false
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2010-01-22
    */
    FUNCTION get_referral_new_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_row        IN p1_external_request%ROWTYPE,
        o_flg_status_new OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_ref_map_sch(x_id_ext_req IN ref_map.id_external_request%TYPE) IS
            SELECT id_schedule
              FROM ref_map r
             WHERE r.id_external_request = x_id_ext_req
               AND r.id_schedule IS NOT NULL
               AND flg_status = pk_ref_constant.g_active;
    
        l_id_schedule_tab table_number;
        l_flg_status_s    PLS_INTEGER;
        l_flg_status_m    PLS_INTEGER;
        l_flg_status_e    PLS_INTEGER;
    BEGIN
        g_error := 'Init get_referral_new_status / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status;
        pk_alertlog.log_debug(g_error);
    
        l_flg_status_s := 0;
        l_flg_status_m := 0;
        l_flg_status_e := 0;
    
        -------------------------------
        -- Gets the new referral status 
        -------------------------------
        -- Algorithm changed because of issue ALERT-69182
        -- Referral status is 
        -- 'S' -  if there is at least one schedule associated
        -- 'M' -  if there is at least one notified schedule associated
        -- 'E' -  if there is at least one registered schedule associated
        -------------------------------   
    
        -- checking if status should be changed to 'S' or 'A'
        g_error := 'OPEN c_ref_map_sch / ID_REF=' || i_ref_row.id_external_request;
        OPEN c_ref_map_sch(i_ref_row.id_external_request);
        FETCH c_ref_map_sch BULK COLLECT
            INTO l_id_schedule_tab;
        CLOSE c_ref_map_sch;
    
        IF l_id_schedule_tab.count > 0
        THEN
        
            FOR i IN 1 .. l_id_schedule_tab.count
            LOOP
                IF is_completed(i_lang => i_lang, i_prof => i_prof, i_schedule => l_id_schedule_tab(i)) =
                   pk_ref_constant.g_yes
                THEN
                    -- this schedule is registred 
                    l_flg_status_e := 1;
                
                ELSIF pk_schedule.is_notified(i_lang => i_lang, i_prof => i_prof, i_id_schedule => l_id_schedule_tab(i)) =
                      pk_ref_constant.g_yes
                THEN
                    -- this schedule is mailed
                    l_flg_status_m := 1;
                ELSE
                    -- this schedule is only scheduled
                    l_flg_status_s := 1;
                END IF;
            END LOOP;
        
            g_error := 'l_flg_status_s=' || l_flg_status_s || ' l_flg_status_m=' || l_flg_status_m ||
                       ' l_flg_status_e=' || l_flg_status_e;
            pk_alertlog.log_debug(g_error);
        
            IF l_flg_status_s = 1
            THEN
                o_flg_status_new := pk_ref_constant.g_p1_status_s;
            ELSIF l_flg_status_m = 1
            THEN
                o_flg_status_new := pk_ref_constant.g_p1_status_m;
            ELSIF l_flg_status_e = 1
            THEN
                o_flg_status_new := pk_ref_constant.g_p1_status_e;
            ELSE
                g_error := 'get_referral_new_status / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                           i_ref_row.flg_status || ' FLG_NEW_STATUS=' || o_flg_status_new;
                RAISE g_exception;
            END IF;
        ELSE
            -- there are no schedules, set flg_status to 'A'
            o_flg_status_new := pk_ref_constant.g_p1_status_a;
        END IF;
    
        -- if the new status = current status then there is no need to change referral status
        g_error := 'ID_REF=' || i_ref_row.id_external_request || ' CURRENT STATUS=' || i_ref_row.flg_status ||
                   ' NEW STATUS=' || o_flg_status_new;
        pk_alertlog.log_debug(g_error);
        IF i_ref_row.flg_status = o_flg_status_new
        THEN
            o_flg_status_new := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_flg_status_new := NULL;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_NEW_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_referral_new_status;

    /**
    * Checks if is the first time that the referral is scheduled
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_ref_row        Referral data
    * @param   o_result         Flag indicating if is the first schedule or not. {*} Y - first schedule  {*} N - otherwise
    * @param   o_error          An error message, set when return=false
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-01-2010
    */
    FUNCTION is_first_schedule
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ref_row IN p1_external_request%ROWTYPE,
        o_result  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init is_first_schedule / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status;
        pk_alertlog.log_debug(g_error);
    
        IF i_ref_row.flg_status IN
           (pk_ref_constant.g_p1_status_s, pk_ref_constant.g_p1_status_m, pk_ref_constant.g_p1_status_e)
        THEN
            o_result := pk_ref_constant.g_no;
        ELSE
            o_result := pk_ref_constant.g_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_result := pk_ref_constant.g_no;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'IS_FIRST_SCHEDULE',
                                              o_error    => o_error);
            RETURN FALSE;
    END is_first_schedule;

    /**
    * Gets referral detail according to module circle
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_prof_data              Professional info: profile_template, category and functionality     
    * @param   i_ref_row                P1_EXTERNAL_REQUEST rowtype    
    * @param   o_notes_status           Status info: status, timestamp and professional
    * @param   o_notes_status_det       Status info detail    
    * @param   o_error                  An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-11-2009    
    */
    FUNCTION get_referral_circle
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_data        IN t_rec_prof_data,
        i_ref_row          IN p1_external_request%ROWTYPE,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_wf_status_info table_varchar;
        l_tracking_crit  table_table_number;
        TYPE t_coll_tracking IS TABLE OF p1_tracking%ROWTYPE INDEX BY BINARY_INTEGER;
        l_tracking_tab t_coll_tracking;
        l_crit         PLS_INTEGER;
    
        l_ref_detail_t016 sys_message.desc_message%TYPE;
        l_ref_detail_t017 sys_message.desc_message%TYPE;
        l_ref_detail_t018 sys_message.desc_message%TYPE;
        l_ref_detail_t019 sys_message.desc_message%TYPE;
        l_ref_detail_t020 sys_message.desc_message%TYPE;
        l_ref_detail_t021 sys_message.desc_message%TYPE;
    
        l_p1_detail_t011 sys_message.desc_message%TYPE;
        l_p1_detail_t012 sys_message.desc_message%TYPE;
        l_p1_detail_t050 sys_message.desc_message%TYPE;
        l_p1_detail_t055 sys_message.desc_message%TYPE;
        l_p1_detail_t056 sys_message.desc_message%TYPE;
        l_p1_detail_t049 sys_message.desc_message%TYPE;
    
        l_ref_detail_ubrn     sys_message.desc_message%TYPE;
        l_ref_detail_req_item sys_message.desc_message%TYPE;
    
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------    
        g_error           := 'Init get_referral_circle / Get labels';
        l_ref_detail_t016 := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_ref_detail_t016); -- Request was accepted
        l_ref_detail_t017 := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_ref_detail_t017); -- Request is awaiting acceptance
        l_ref_detail_t018 := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_ref_detail_t018); -- Request is provisionally accepted
        l_ref_detail_t019 := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_ref_detail_t019); -- Request was completed
        l_ref_detail_t020 := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_ref_detail_t020); -- Request was stopped
        l_ref_detail_t021 := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_ref_detail_t021); -- Request was rejected
        l_p1_detail_t011  := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_p1_detail_t011);
        l_p1_detail_t012  := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_p1_detail_t012);
        l_p1_detail_t050  := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_p1_detail_t050);
        l_p1_detail_t055  := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_p1_detail_t055);
        l_p1_detail_t056  := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_p1_detail_t056);
        l_p1_detail_t049  := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_p1_detail_t049);
    
        l_ref_detail_ubrn     := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => pk_ref_constant.g_sm_ref_detail_ubrn);
        l_ref_detail_req_item := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => pk_ref_constant.g_sm_ref_detail_req_item);
    
        ----------------------
        -- FUNC
        ----------------------     
        g_error          := 'Call pk_ref_core.init_param_tab';
        l_wf_status_info := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_ext_req            => i_ref_row.id_external_request,
                                                       i_id_patient         => i_ref_row.id_patient,
                                                       i_id_inst_orig       => i_ref_row.id_inst_orig,
                                                       i_id_inst_dest       => i_ref_row.id_inst_dest,
                                                       i_id_dep_clin_serv   => i_ref_row.id_dep_clin_serv,
                                                       i_id_speciality      => i_ref_row.id_speciality,
                                                       i_flg_type           => i_ref_row.flg_type,
                                                       i_decision_urg_level => i_ref_row.decision_urg_level,
                                                       i_id_prof_requested  => i_ref_row.id_prof_requested,
                                                       i_id_prof_redirected => i_ref_row.id_prof_redirected,
                                                       i_id_prof_status     => i_ref_row.id_prof_status,
                                                       i_external_sys       => i_ref_row.id_external_sys,
                                                       i_location           => pk_ref_constant.g_location_detail,
                                                       i_flg_status         => i_ref_row.flg_status);
    
        -- Criterias are:
        --   1- Status: New (N)
        --   2- Status: Scheduled (S)
        --   3- Status: Awaiting Acceptance (U), Provisionally Accepted (Q), To be scheduled (A), Performed (E), Declined(X) and Cancelled (C)
        g_error         := 'Init l_tracking_crit';
        l_tracking_crit := table_table_number(table_number(), table_number(), table_number());
    
        -- fetching all p1_tracking records into a collection
        g_error := 'SELECT P1_TRACKING / ID_EXT_REQ=' || i_ref_row.id_external_request;
        pk_alertlog.log_debug(g_error);
        SELECT * BULK COLLECT
          INTO l_tracking_tab
          FROM p1_tracking t
         WHERE t.id_external_request = i_ref_row.id_external_request
           AND t.flg_type = pk_ref_constant.g_tracking_type_s
           AND t.ext_req_status IN (pk_ref_constant.g_p1_status_n,
                                    pk_ref_constant.g_p1_status_s,
                                    pk_ref_constant.g_p1_status_u,
                                    pk_ref_constant.g_p1_status_q,
                                    pk_ref_constant.g_p1_status_a,
                                    pk_ref_constant.g_p1_status_x,
                                    pk_ref_constant.g_p1_status_e,
                                    pk_ref_constant.g_p1_status_c);
    
        -- dividing l_tracking_tab into "criterias"     
        g_error := 'l_tracking_tab.COUNT=' || l_tracking_tab.count || ' / ID_EXT_REQ=' || i_ref_row.id_external_request;
        pk_alertlog.log_debug(g_error);
        IF l_tracking_tab.count > 0
        THEN
            FOR i IN l_tracking_tab.first .. l_tracking_tab.last
            LOOP
            
                l_crit := NULL;
            
                IF l_tracking_tab(i).ext_req_status = pk_ref_constant.g_p1_status_n
                THEN
                    -- 1- Status: New (N)
                    l_crit := 1;
                
                ELSIF l_tracking_tab(i).ext_req_status = pk_ref_constant.g_p1_status_s
                THEN
                
                    -- 2- Status: Scheduled (S)
                    l_crit := 2;
                
                ELSIF l_tracking_tab(i).ext_req_status IN (pk_ref_constant.g_p1_status_u,
                                          pk_ref_constant.g_p1_status_q,
                                          pk_ref_constant.g_p1_status_a,
                                          pk_ref_constant.g_p1_status_e,
                                          pk_ref_constant.g_p1_status_x,
                                          pk_ref_constant.g_p1_status_x)
                THEN
                
                    -- 3- Status: Awaiting Acceptance (U), Provisionally Accepted (Q), To be scheduled (A), Performed (E), Declined(X) and Cancelled (C)
                    l_crit := 3;
                
                END IF;
            
                IF l_crit IS NOT NULL
                THEN
                    g_error := 'l_tracking_crit(' || l_crit || ').EXTEND';
                    l_tracking_crit(l_crit).extend;
                    l_tracking_crit(l_crit)(l_tracking_crit(l_crit).last) := l_tracking_tab(i).id_tracking;
                END IF;
            
            END LOOP;
        END IF;
    
        -- o_notes_status (MED+ADM)
        g_error := 'OPEN O_NOTES_STATUS CIRCLE / ID_EXT_REQ=' || i_ref_row.id_external_request;
        OPEN o_notes_status FOR
            SELECT id_tracking,
                   pk_workflow.get_status_desc(i_lang,
                                               i_prof,
                                               i_ref_row.id_workflow,
                                               pk_ref_status.convert_status_n(t.ext_req_status),
                                               i_prof_data.id_category,
                                               i_prof_data.id_profile_template,
                                               i_prof_data.id_functionality,
                                               l_wf_status_info) title,
                   NULL text,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, p.id_professional, id_institution) prof_spec,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) dt_insert,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_tracking_tstz, i_prof) dt
              FROM p1_tracking t
              JOIN professional p
                ON (t.id_professional = p.id_professional)
             WHERE t.id_external_request = i_ref_row.id_external_request
               AND t.flg_type IN (pk_ref_constant.g_tracking_type_s,
                                  pk_ref_constant.g_tracking_type_c,
                                  pk_ref_constant.g_tracking_type_p)
             ORDER BY t.dt_tracking_tstz DESC;
    
        -- rank: 1- Motivo | 2- Profissional | 3- Instituicao actual | 4- Departamento | 5- servico clinico | 6- Prioridade | 7- Notas | null - resto
        -- rank used to rank records having the same id_traking
        g_error := 'OPEN O_NOTES_STATUS_DET CIRCLE / ID_EXT_REQ=' || i_ref_row.id_external_request;
        OPEN o_notes_status_det FOR
            SELECT rank, id_tracking, title, text
              FROM (
                    -- 1- Status: New (N)                
                    -- Medico
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     2 rank,
                      t.id_tracking,
                      l_p1_detail_t055 title,
                      pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) text
                      FROM p1_tracking t
                      JOIN p1_external_request exr
                        ON (t.id_external_request = exr.id_external_request)
                      JOIN professional p1
                        ON (p1.id_professional = exr.id_prof_requested)
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 1                        
                    UNION ALL
                    -- Instituicao
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     3 rank,
                      t.id_tracking,
                      l_p1_detail_t012 title,
                      pk_translation.get_translation(i_lang, i.code_institution) text
                      FROM p1_tracking t
                      JOIN p1_external_request exr
                        ON (t.id_external_request = exr.id_external_request)
                      JOIN institution i
                        ON (exr.id_inst_orig = i.id_institution)
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                    UNION ALL
                    -- Notas                        
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     7 rank, t.id_tracking, l_p1_detail_t049 title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_note
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     8 rank, t.id_tracking, l_ref_detail_req_item title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_item
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     8 rank, t.id_tracking, l_ref_detail_ubrn title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_ubrn
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    -- 2- Status: Scheduled (S)
                    -- schedule date
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     NULL rank,
                      t.id_tracking,
                      l_p1_detail_t056 title,
                      pk_date_utils.dt_chr_tsz(i_lang, s.dt_begin_tstz, i_prof) || ' ' ||
                      pk_date_utils.dt_chr_hour_tsz(i_lang, s.dt_begin_tstz, i_prof) text
                      FROM schedule s
                      JOIN p1_tracking t
                        ON (t.id_schedule = s.id_schedule)
                      JOIN TABLE(CAST(l_tracking_crit(2) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 2
                    UNION ALL
                    -- department 
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     4 rank,
                      t.id_tracking,
                      l_p1_detail_t050 title,
                      pk_translation.get_translation(i_lang, d.code_department) text
                      FROM schedule s
                      JOIN p1_tracking t
                        ON (t.id_schedule = s.id_schedule)
                      JOIN TABLE(CAST(l_tracking_crit(2) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                      JOIN dep_clin_serv dcs
                        ON (s.id_dcs_requested = dcs.id_dep_clin_serv)
                      JOIN department d
                        ON (dcs.id_department = d.id_department)
                    UNION ALL
                    -- clinical service
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     5 rank,
                      t.id_tracking,
                      l_p1_detail_t011 title,
                      pk_translation.get_translation(i_lang, cs.code_clinical_service) text
                      FROM schedule s
                      JOIN p1_tracking t
                        ON (t.id_schedule = s.id_schedule)
                      JOIN TABLE(CAST(l_tracking_crit(2) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                      JOIN dep_clin_serv dcs
                        ON (s.id_dcs_requested = dcs.id_dep_clin_serv)
                      JOIN clinical_service cs
                        ON (dcs.id_clinical_service = cs.id_clinical_service)
                    UNION ALL
                    -- Notas                        
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     7 rank, t.id_tracking, l_p1_detail_t049 title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(2) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_note
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     7 rank, t.id_tracking, l_ref_detail_req_item title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(2) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_item
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     7 rank, t.id_tracking, l_ref_detail_ubrn title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(2) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_ubrn
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    -- 3- Status: Awaiting Acceptance (U), Provisionally Accepted (Q), To be scheduled (A), Performed (E), Declined(X) and Cancelled (C)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     1 rank,
                      t.id_tracking,
                      NULL title,
                      decode(t.ext_req_status,
                             pk_ref_constant.g_p1_status_q,
                             l_ref_detail_t018,
                             pk_ref_constant.g_p1_status_u,
                             l_ref_detail_t017,
                             pk_ref_constant.g_p1_status_a,
                             l_ref_detail_t016,
                             pk_ref_constant.g_p1_status_e,
                             l_ref_detail_t019,
                             pk_ref_constant.g_p1_status_x,
                             l_ref_detail_t021,
                             pk_ref_constant.g_p1_status_c,
                             l_ref_detail_t020,
                             NULL) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 3       
                    UNION ALL
                    -- Notas                        
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     7 rank, t.id_tracking, l_p1_detail_t049 title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_note
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    -- Notas                        
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     7 rank, t.id_tracking, l_ref_detail_req_item title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_item
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    -- Notas                        
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     7 rank, t.id_tracking, l_ref_detail_ubrn title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_ubrn
                       AND d.flg_status = pk_ref_constant.g_detail_status_a)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_CIRCLE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_referral_circle;

    /**
    * Changes referral status after scheduling according to module circle for referral types S (ORIS) and N (INP)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_ref_row        P1_EXTERNAL_REQUEST rowtype    
    * @param   i_schedule       Schedule identifier to be associated to the referral
    * @param   i_episode        Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-12-2009    
    */
    FUNCTION set_ref_scheduled_circle_sn
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_ref_row  IN p1_external_request%ROWTYPE,
        i_schedule IN p1_external_request.id_schedule%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_map_row   ref_map%ROWTYPE;
        l_id_ref_map    ref_map.id_ref_map%TYPE;
        l_update        PLS_INTEGER;
        l_flg_first_sch VARCHAR2(1 CHAR);
    
        CURSOR c_ref_map_epis
        (
            x_id_ref     IN ref_map.id_external_request%TYPE,
            x_id_episode IN ref_map.id_episode%TYPE
        ) IS
            SELECT *
              FROM ref_map
             WHERE id_external_request = x_id_ref
               AND id_episode = x_id_episode
               AND flg_status = pk_ref_constant.g_active;
    
        CURSOR c_ref_map_sch(x_id_schedule IN ref_map.id_schedule%TYPE) IS
            SELECT *
              FROM ref_map
             WHERE id_schedule = x_id_schedule
               AND flg_status = pk_ref_constant.g_active;
    BEGIN
        -- CIRCLE UK: ALERT-27343
        g_error := 'Init set_ref_scheduled_circle_sn / ID_REF=' || i_ref_row.id_external_request || ' FLG_TYPE=' ||
                   i_ref_row.flg_type || ' ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
        pk_alertlog.log_debug(g_error);
        l_update := 0;
    
        -- is the first time that the referral is scheduled? (see referral flg_status)
        g_error  := 'Call is_first_schedule / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                    i_ref_row.flg_status;
        g_retval := is_first_schedule(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_ref_row => i_ref_row,
                                      o_result  => l_flg_first_sch,
                                      o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_first_sch = pk_ref_constant.g_no
        THEN
            ----------------------------
            -- not the first schedule
            g_error := 'Not the first schedule / ID_REF=' || i_ref_row.id_external_request || ' ID_EPISODE=' ||
                       i_episode;
            pk_alertlog.log_debug(g_error);
        
            IF i_episode IS NULL
            THEN
                -- (called by OUTP/EXAMs)
                -- associating INP/ORIS Referral type to an OUTP/EXAM episode id (new REF_MAP record)
            
                -- check if exists any record with ID_SCHEULE=i_schedule. If so, cancel this record.
                OPEN c_ref_map_sch(i_schedule);
                FETCH c_ref_map_sch
                    INTO l_ref_map_row;
                g_found := c_ref_map_sch%FOUND;
                CLOSE c_ref_map_sch;
            
                IF g_found
                THEN
                    g_error  := 'Call pk_ref_api.create_ref_map / ID_REF=' || i_ref_row.id_external_request ||
                                ' ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
                    g_retval := pk_ref_api.cancel_ref_map(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_ref_map_row => l_ref_map_row,
                                                          o_error       => o_error);
                
                    IF NOT g_retval
                    THEN
                        g_error := 'Error: ' || g_error || ' ID_REF_MAP=' || l_id_ref_map;
                        RAISE g_exception_np;
                    END IF;
                
                    -- cleaning l_ref_map_row
                    g_error       := 'cleaning l_ref_map_row';
                    l_ref_map_row := NULL;
                
                END IF;
            
                -- create the new record
                g_error  := 'Call pk_ref_api.create_ref_map / ID_REF=' || i_ref_row.id_external_request ||
                            ' ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
                g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_id_ref      => i_ref_row.id_external_request,
                                                      i_id_schedule => i_schedule,
                                                      i_id_episode  => i_episode,
                                                      o_id_ref_map  => l_id_ref_map,
                                                      o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    g_error := 'Error: ' || g_error || ' ID_REF_MAP=' || l_id_ref_map;
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                -- (called by INP/ORIS)
                -- associating INP/ORIS Referral type to an ORIS/INP episode id (update REF_MAP record)
            
                -- updating ID_SCHEDULE of an existing association: ID_EPISODE=param in,ID_REF=param in,ID_SCHEDULE IS NULL,FLG_STATUS='A'
                g_error := 'Not the first schedule / Updating REF_MAP association / SET ID_SCHEDULE=' || i_schedule ||
                           ' WHERE ID_REF=' || i_ref_row.id_external_request || ' ID_EPISODE=' || i_episode ||
                           ' FLG_STATUS=A';
                pk_alertlog.log_debug(g_error);
                l_update := 1;
            
            END IF;
        
        ELSE
            ----------------------------
            -- first schedule
            -- (called by INP/ORIS)
        
            -- updating ID_SCHEDULE of an existing association: ID_EPISODE=param in,ID_REF=param in,ID_SCHEDULE IS NULL,FLG_STATUS='A'
            g_error := 'First schedule / Updating REF_MAP association / SET ID_SCHEDULE=' || i_schedule ||
                       ' WHERE ID_REF=' || i_ref_row.id_external_request || ' ID_EPISODE=' || i_episode ||
                       ' FLG_STATUS=A';
            pk_alertlog.log_debug(g_error);
            l_update := 1;
        
        END IF;
    
        -----------------------------------------------
        -- update
        -----------------------------------------------
        IF l_update = 1
        THEN
        
            -- updating ID_SCHEDULE of an existing association: ID_EPISODE=param in,ID_REF=param in,ID_SCHEDULE IS NULL,FLG_STATUS='A'
            g_error := 'OPEN c_ref_map_epis / ID_REF=' || i_ref_row.id_external_request || ' ID_EPISODE=' || i_episode;
            pk_alertlog.log_debug(g_error);
            OPEN c_ref_map_epis(i_ref_row.id_external_request, i_episode);
            FETCH c_ref_map_epis
                INTO l_ref_map_row;
            g_found := c_ref_map_epis%FOUND;
            CLOSE c_ref_map_epis;
        
            IF NOT g_found
            THEN
                g_error := 'REF_MAP record not found for ID_REF=' || i_ref_row.id_external_request || ' ID_EPISODE=' ||
                           i_episode;
                RAISE g_exception;
            END IF;
        
            IF l_ref_map_row.id_schedule IS NOT NULL
            THEN
                -- ID_SCHEDULE is not null, this cannot happen: return error
                g_error := 'ID_SCHEDULE IS NOT NULL for REF_MAP record / ID_REF_MAP=' || l_ref_map_row.id_ref_map ||
                           ' ID_REF=' || i_ref_row.id_external_request || ' ID_EPISODE=' || i_episode ||
                           ' ID_SCHEDULE=' || l_ref_map_row.id_schedule || ' FLG_TYPE=' || i_ref_row.flg_type;
                RAISE g_exception;
            END IF;
        
            g_error                   := 'ID_SCHEDULE=' || i_schedule;
            l_ref_map_row.id_schedule := i_schedule;
        
            g_error := 'Call PK_API_REF.set_ref_map / ID_EXT_REQ=' || l_ref_map_row.id_external_request ||
                       ' ID_SCHEDULE=' || l_ref_map_row.id_schedule || ' ID_EPISODE=' || l_ref_map_row.id_episode ||
                       ' FLG_STATUS=' || l_ref_map_row.flg_status;
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_ref_map(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_ref_map    => l_ref_map_row,
                                               o_id_ref_map => l_id_ref_map,
                                               o_error      => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error || ' ID_REF_MAP=' || l_id_ref_map;
                RAISE g_exception_np;
            END IF;
        
        END IF;
        -----------------------------------------------        
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_SCHEDULED_CIRCLE_SN',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_scheduled_circle_sn;

    /**
    * Changes referral status after scheduling according to module circle for referral types E (Exams) and C (Visits)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_ref_row        P1_EXTERNAL_REQUEST rowtype    
    * @param   i_schedule       Schedule identifier to be associated to the referral
    * @param   i_episode        Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   i_date           Status change date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-12-2009    
    */
    FUNCTION set_ref_scheduled_circle_ec
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_ref_row  IN p1_external_request%ROWTYPE,
        i_schedule IN p1_external_request.id_schedule%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_map_row   ref_map%ROWTYPE;
        l_id_ref_map    ref_map.id_ref_map%TYPE;
        l_sysdate       p1_tracking.dt_tracking_tstz%TYPE;
        o_track         table_number;
        l_ref_old_row   p1_external_request%ROWTYPE;
        l_prof_data     t_rec_prof_data; -- professional data
        l_flg_first_sch VARCHAR2(1 CHAR);
    
        l_param table_varchar;
    
        CURSOR c_ref_map_epis
        (
            x_id_ref     IN ref_map.id_external_request%TYPE,
            x_id_episode IN ref_map.id_episode%TYPE
        ) IS
            SELECT *
              FROM ref_map
             WHERE id_external_request = x_id_ref
               AND id_episode = x_id_episode
               AND flg_status = pk_ref_constant.g_active;
    
        CURSOR c_ref_map_sch(x_id_schedule IN ref_map.id_schedule%TYPE) IS
            SELECT *
              FROM ref_map
             WHERE id_schedule = x_id_schedule
               AND flg_status = pk_ref_constant.g_active;
    
    BEGIN
        g_error := 'Init set_ref_scheduled_circle_ec / ID_REF=' || i_ref_row.id_external_request || ' FLG_TYPE=' ||
                   i_ref_row.flg_type || ' ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
        pk_alertlog.log_debug(g_error);
        l_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        ----------------------
        -- OUTP/EXAMs
        ----------------------    
    
        -------------------------
        -- check if exists any record with ID_SCHEULE=i_schedule. If so, cancel this record.
        g_error := 'OPEN c_ref_map_sch / ID_SCHEDULE=' || i_schedule;
        pk_alertlog.log_debug(g_error);
        OPEN c_ref_map_sch(i_schedule);
        FETCH c_ref_map_sch
            INTO l_ref_map_row;
        g_found := c_ref_map_sch%FOUND;
        CLOSE c_ref_map_sch;
    
        IF g_found
        THEN
        
            -------------------------------------------
            -- we have to cancel old referral schedule (cancel REF_MAP and change FLG_STATUS for old referral only if 
            -- there is no schedules associated to this referral)
        
            g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || l_ref_map_row.id_external_request ||
                       ' ID_EPISODE=' || i_episode || ' ID_SCHEDULE=' || l_ref_map_row.id_schedule;
            pk_alertlog.log_debug(g_error);
            g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                           i_prof   => i_prof,
                                                           i_id_ref => l_ref_map_row.id_external_request,
                                                           o_rec    => l_ref_old_row,
                                                           o_error  => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'Error: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
            -- getting professional data
            g_error  := 'Calling pk_ref_core.get_prof_data / ID_REF=' || l_ref_map_row.id_external_request;
            g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_dcs       => l_ref_map_row.id_external_request,
                                                  o_prof_data => l_prof_data,
                                                  o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'Error: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
            g_error  := 'Call PK_REF_CORE.process_transition / ID_REF=' || l_ref_old_row.id_external_request ||
                        ' ACTION=' || pk_ref_constant.g_ref_action_csh || ' L_SYSDATE=' ||
                        pk_date_utils.to_char_insttimezone(i_prof, l_sysdate, 'YYYYMMDDHH24MISS');
            g_retval := pk_ref_core.process_transition2(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_prof_data  => l_prof_data,
                                                        i_ref_row    => l_ref_old_row,
                                                        i_action     => pk_ref_constant.g_ref_action_csh, -- CANCEL_SCH                                                         
                                                        i_status_end => NULL,
                                                        i_schedule   => i_schedule,
                                                        i_date       => l_sysdate,
                                                        io_param     => l_param,
                                                        io_track     => o_track,
                                                        o_error      => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
            g_error := g_error || ' NOT FOUND';
            pk_alertlog.log_debug(g_error);
        END IF;
    
        -------------------------
        -- is the first time that the referral is scheduled? (see referral flg_status)
        g_error  := 'Call is_first_schedule / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                    i_ref_row.flg_status;
        g_retval := is_first_schedule(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_ref_row => i_ref_row,
                                      o_result  => l_flg_first_sch,
                                      o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_first_sch = pk_ref_constant.g_no
        THEN
            ----------------------------
            -- not the first schedule
            g_error := 'Not the first schedule / ID_REF=' || i_ref_row.id_external_request || ' ID_EPISODE=' ||
                       i_episode;
            pk_alertlog.log_debug(g_error);
        
            IF i_episode IS NULL
            THEN
                ----------------------------------------------
                -- (called by OUTP/EXAMs)                                        
            
                ----------------------------------------------
                -- associating OUTP/EXAMs Referral type to an OUTP/EXAM episode id (new REF_MAP record)
                g_error  := 'Call pk_ref_api.create_ref_map / ID_REF=' || i_ref_row.id_external_request ||
                            ' ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
                g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_id_ref      => i_ref_row.id_external_request,
                                                      i_id_schedule => i_schedule,
                                                      i_id_episode  => i_episode,
                                                      o_id_ref_map  => l_id_ref_map,
                                                      o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    g_error := 'Error: ' || g_error || ' ID_REF_MAP=' || l_id_ref_map;
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                ----------------------------------------------
                -- (called by INP/ORIS)
                -- associating OUTP/EXAMs Referral type to an ORIS/INP episode id (update REF_MAP record)
            
                -- updating ID_SCHEDULE of an existing association: ID_EPISODE=param in,ID_REF=param in,FLG_STATUS='A'
                g_error := 'Not the first schedule / Updating REF_MAP association / SET ID_SCHEDULE=' || i_schedule ||
                           ' WHERE ID_REF=' || i_ref_row.id_external_request || ' ID_EPISODE=' || i_episode ||
                           ' FLG_STATUS=A';
                pk_alertlog.log_debug(g_error);
            
                -- updating ID_SCHEDULE of an existing association: ID_EPISODE=param in,ID_REF=param in,ID_SCHEDULE IS NULL,FLG_STATUS='A'              
                OPEN c_ref_map_epis(i_ref_row.id_external_request, i_episode);
                FETCH c_ref_map_epis
                    INTO l_ref_map_row;
                g_found := c_ref_map_epis%FOUND;
                CLOSE c_ref_map_epis;
            
                IF NOT g_found
                THEN
                    g_error := 'REF_MAP record not found for ID_REF=' || i_ref_row.id_external_request ||
                               ' ID_EPISODE=' || i_episode;
                    RAISE g_exception;
                END IF;
            
                IF l_ref_map_row.id_schedule IS NOT NULL
                THEN
                    -- ID_SCHEDULE is not null, this cannot happen: return error
                    g_error := 'ID_SCHEDULE IS NOT NULL for REF_MAP record / ID_REF_MAP=' || l_ref_map_row.id_ref_map ||
                               ' ID_REF=' || i_ref_row.id_external_request || ' ID_EPISODE=' || i_episode ||
                               ' ID_SCHEDULE=' || l_ref_map_row.id_schedule || ' FLG_TYPE=' || i_ref_row.flg_type;
                    RAISE g_exception;
                END IF;
            
                g_error                   := 'ID_SCHEDULE=' || i_schedule;
                l_ref_map_row.id_schedule := i_schedule;
            
                g_error := 'Call PK_API_REF.set_ref_map / ID_EXT_REQ=' || l_ref_map_row.id_external_request ||
                           ' ID_SCHEDULE=' || l_ref_map_row.id_schedule || ' ID_EPISODE=' || l_ref_map_row.id_episode ||
                           ' FLG_STATUS=' || l_ref_map_row.flg_status;
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_api.set_ref_map(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_ref_map    => l_ref_map_row,
                                                   o_id_ref_map => l_id_ref_map,
                                                   o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    g_error := 'ERROR: ' || g_error || ' ID_REF_MAP=' || l_id_ref_map;
                    RAISE g_exception_np;
                END IF;
            
            END IF;
        
        ELSE
            ----------------------------
            -- first schedule
            -- (called by OUTP/EXAMs)
        
            g_error  := 'Call pk_ref_api.create_ref_map / ID_REF=' || i_ref_row.id_external_request || ' ID_SCHEDULE=' ||
                        i_schedule || ' ID_EPISODE=NULL FLG_STATUS=A';
            g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_id_ref      => i_ref_row.id_external_request,
                                                  i_id_schedule => i_schedule,
                                                  i_id_episode  => NULL,
                                                  o_id_ref_map  => l_id_ref_map,
                                                  o_error       => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'Error: ' || g_error || ' ID_REF_MAP=' || l_id_ref_map;
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_SCHEDULED_CIRCLE_EC',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_scheduled_circle_ec;

    /**
    * Changes referral status after scheduling according to module circle
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_ref_row        P1_EXTERNAL_REQUEST rowtype    
    * @param   i_schedule       Schedule identifier to be associated to the referral
    * @param   i_episode        Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   i_date           Status change date
    * @param   o_flg_status_new New referral flag status. If NULL the referral does not need  to change status.
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-11-2009    
    */
    FUNCTION set_ref_scheduled_circle
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_schedule       IN p1_external_request.id_schedule%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_flg_status_new OUT p1_external_request.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sysdate p1_tracking.dt_tracking_tstz%TYPE;
    BEGIN
        g_error := 'Init set_ref_scheduled_circle / ID_REF=' || i_ref_row.id_external_request || ' FLG_TYPE=' ||
                   i_ref_row.flg_type || ' ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
        pk_alertlog.log_debug(g_error);
        --l_sysdate := nvl(i_date, current_timestamp);
        l_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
    
        -- checking type of referral
        ----------------------
        -- INP/ORIS
        ----------------------
        IF i_ref_row.flg_type IN (pk_ref_constant.g_p1_type_s, pk_ref_constant.g_p1_type_n)
        THEN
        
            g_error  := 'Call set_ref_scheduled_circle_sn / ID_REF=' || i_ref_row.id_external_request || ' FLG_TYPE=' ||
                        i_ref_row.flg_type || ' ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
            g_retval := set_ref_scheduled_circle_sn(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_ref_row  => i_ref_row,
                                                    i_schedule => i_schedule,
                                                    i_episode  => i_episode,
                                                    o_error    => o_error);
        
        ELSE
            ----------------------
            -- OUTP/EXAMs
            ----------------------    
        
            g_error  := 'Call set_ref_scheduled_circle_ec / ID_REF=' || i_ref_row.id_external_request || ' FLG_TYPE=' ||
                        i_ref_row.flg_type || ' ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
            g_retval := set_ref_scheduled_circle_ec(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_ref_row  => i_ref_row,
                                                    i_schedule => i_schedule,
                                                    i_episode  => i_episode,
                                                    i_date     => l_sysdate,
                                                    o_error    => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -------------------------------
        -- Gets the new referral status 
        -------------------------------
        g_error := 'Call get_referral_new_status / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status;
        pk_alertlog.log_debug(g_error);
        g_retval := get_referral_new_status(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_ref_row        => i_ref_row,
                                            o_flg_status_new => o_flg_status_new,
                                            o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_SCHEDULED_CIRCLE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_scheduled_circle;

    /**
    * Changes referral status after scheduling according to module generic
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_prof_data      Profile_template, functionality, and category ids   
    * @param   i_ref_row        P1_EXTERNAL_REQUEST rowtype    
    * @param   i_dcs            Department and service schedule
    * @param   i_schedule       Schedule identifier to be associated to the referral    
    * @param   i_date           Status change date
    * @param   o_track          Array of ID_TRACKING transitions 
    * @param   o_flg_status_new New referral flag status. If NULL the referral does not need  to change status.   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009    
    */
    FUNCTION set_ref_scheduled_generic
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_schedule       IN p1_external_request.id_schedule%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track          OUT table_number,
        o_flg_status_new OUT p1_external_request.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params         VARCHAR2(1000 CHAR);
        l_sysdate        p1_tracking.dt_tracking_tstz%TYPE;
        l_p1_skip_triage sys_config.value%TYPE;
        l_ref_status     p1_external_request.flg_status%TYPE;
        l_track_row      p1_tracking%ROWTYPE;
        l_param          table_varchar;
        l_param_aux      table_varchar;
        l_track_tab      table_number;
    
        CURSOR c_exr IS
            SELECT *
              FROM p1_external_request exr
             WHERE exr.id_schedule = i_schedule
               AND exr.flg_status IN (pk_ref_constant.g_p1_status_s, pk_ref_constant.g_p1_status_m);
    BEGIN
        l_params := 'ID_REF=' || i_ref_row.id_external_request || ' FLG_TYPE=' || i_ref_row.flg_type ||
                    ' ID_DEP_CLIN_SERV=' || i_dcs;
        g_error  := 'Init set_ref_scheduled_generic / ' || l_params;
        pk_alertlog.log_debug(g_error);
        l_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        l_params := l_params || ' L_SYSDATE=' ||
                    pk_date_utils.to_char_insttimezone(i_prof, l_sysdate, 'YYYYMMDDHH24MISS');
    
        l_p1_skip_triage := pk_sysconfig.get_config('P1_SKIP_TRIAGE', i_prof);
    
        -- If there are referrals associated with this schedule, they must be canceled
        g_error := 'Call cancel_schedule';
        FOR l_row IN c_exr
        LOOP
        
            l_track_tab := table_number();
            g_error     := 'Call PK_REF_CORE.process_transition / CURR_ID_REF=' || l_row.id_external_request ||
                           ' ACTION=' || pk_ref_constant.g_ref_action_csh || ' / ' || l_params;
            g_retval    := pk_ref_core.process_transition2(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_prof_data  => i_prof_data,
                                                           i_ref_row    => l_row,
                                                           i_action     => pk_ref_constant.g_ref_action_csh, -- CANCEL_SCH 
                                                           i_status_end => NULL,
                                                           i_schedule   => NULL,
                                                           i_date       => l_sysdate,
                                                           io_param     => l_param_aux,
                                                           io_track     => l_track_tab,
                                                           o_error      => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_row.id_external_request = i_ref_row.id_external_request
            THEN
                -- fill l_param if is i_ref_row.id_external_request
                l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_ext_req            => l_row.id_external_request,
                                                      i_id_patient         => l_row.id_patient,
                                                      i_id_inst_orig       => l_row.id_inst_orig,
                                                      i_id_inst_dest       => l_row.id_inst_dest,
                                                      i_id_dep_clin_serv   => l_row.id_dep_clin_serv,
                                                      i_id_speciality      => l_row.id_speciality,
                                                      i_flg_type           => l_row.flg_type,
                                                      i_decision_urg_level => l_row.decision_urg_level,
                                                      i_id_prof_requested  => l_row.id_prof_requested,
                                                      i_id_prof_redirected => l_row.id_prof_redirected,
                                                      i_id_prof_status     => l_row.id_prof_status,
                                                      i_external_sys       => l_row.id_external_sys,
                                                      i_flg_status         => l_row.flg_status);
            
                o_track := o_track MULTISET UNION l_track_tab;
            END IF;
        
        END LOOP;
    
        IF l_param IS NULL
        THEN
            g_error := 'Call pk_ref_core.init_param_tab / ' || l_params;
            l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_ext_req            => i_ref_row.id_external_request,
                                                  i_id_patient         => i_ref_row.id_patient,
                                                  i_id_inst_orig       => i_ref_row.id_inst_orig,
                                                  i_id_inst_dest       => i_ref_row.id_inst_dest,
                                                  i_id_dep_clin_serv   => i_ref_row.id_dep_clin_serv,
                                                  i_id_speciality      => i_ref_row.id_speciality,
                                                  i_flg_type           => i_ref_row.flg_type,
                                                  i_decision_urg_level => i_ref_row.decision_urg_level,
                                                  i_id_prof_requested  => i_ref_row.id_prof_requested,
                                                  i_id_prof_redirected => i_ref_row.id_prof_redirected,
                                                  i_id_prof_status     => i_ref_row.id_prof_status,
                                                  i_external_sys       => i_ref_row.id_external_sys,
                                                  i_flg_status         => i_ref_row.flg_status);
        END IF;
    
        l_params := l_params || ' io_param=' || pk_utils.to_string(l_param);
    
        -- Se está em estado Emitido é porque foi agendado directamente sem passa por "Triagem"
        -- do not triage the referral if sys_config = 'N'
        IF l_p1_skip_triage = pk_ref_constant.g_yes
        THEN
            IF i_ref_row.flg_status = pk_ref_constant.g_p1_status_i
            THEN
                g_error                         := 'UPDATE STATUS T';
                l_track_row.id_external_request := i_ref_row.id_external_request;
                l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_t;
                l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                l_track_row.dt_tracking_tstz    := l_sysdate - INTERVAL '2' SECOND;
            
                g_error  := 'CALL pk_ref_status.update_status / EXT_REQ_STATUS=' || l_track_row.ext_req_status || ' / ' ||
                            l_params;
                g_retval := pk_ref_status.update_status(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_track_row => l_track_row,
                                                        io_param    => l_param,
                                                        o_track     => l_track_tab,
                                                        o_error     => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                l_ref_status := pk_ref_constant.g_p1_status_t;
                o_track      := o_track MULTISET UNION l_track_tab;
            
            END IF;
        
            -- Se está em estado de Triagem é porque foi agendado directamente sem passa por "para Agendar"
            IF i_ref_row.flg_status = pk_ref_constant.g_p1_status_t
               OR i_ref_row.flg_status = pk_ref_constant.g_p1_status_r
               OR l_ref_status = pk_ref_constant.g_p1_status_t
            THEN
                g_error                         := 'UPDATE STATUS A';
                l_track_row.id_external_request := i_ref_row.id_external_request;
                l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_a;
                l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                l_track_row.id_dep_clin_serv    := i_dcs;
                l_track_row.dt_tracking_tstz    := l_sysdate - INTERVAL '1' SECOND;
                l_track_row.decision_urg_level  := pk_ref_constant.g_decision_urg_level_normal;
            
                g_error  := 'CALL pk_ref_status.update_status / EXT_REQ_STATUS=' || l_track_row.ext_req_status ||
                            ' ID_DEP_CLIN_SERV=' || l_track_row.id_dep_clin_serv || ' / ' || l_params;
                g_retval := pk_ref_status.update_status(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_track_row => l_track_row,
                                                        io_param    => l_param,
                                                        o_track     => l_track_tab,
                                                        o_error     => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                o_track := o_track MULTISET UNION l_track_tab;
            
            END IF;
        END IF; -- IF l_p1_skip_triage = pk_ref_constant.g_yes THEN 
    
        -- changes referral status to 'S'
        o_flg_status_new := pk_ref_constant.g_p1_status_s;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_SCHEDULED_GENERIC',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_scheduled_generic;

    /**
    * Cancels a previous appointment according to module circle
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids   
    * @param   i_ref_row        Referral info 
    * @param   i_schedule       Schedule identifier   
    * @param   o_flg_status_new New referral flag status. If NULL the referral does not need  to change status.
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-11-2009
    */
    FUNCTION set_ref_cancel_sch_circle
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_schedule       IN schedule.id_schedule%TYPE,
        o_flg_status_new OUT p1_external_request.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_ref_map
        (
            x_id_ext_req IN ref_map.id_external_request%TYPE,
            x_id_sch     ref_map.id_schedule%TYPE
        ) IS
            SELECT *
              FROM ref_map r
             WHERE r.id_external_request = x_id_ext_req
               AND r.id_schedule = x_id_sch
               AND flg_status = pk_ref_constant.g_active;
    
        l_ref_map_row     ref_map%ROWTYPE;
        l_id_ref_map      ref_map.id_ref_map%TYPE;
        l_ref_map_new_row ref_map%ROWTYPE;
        l_sch_type        schedule.flg_sch_type%TYPE;
    BEGIN
        -- remove association between referral and schedule
        g_error := 'Init set_ref_cancel_sch_circle / OPEN c_ref_map / ID_EXT_REQ=' || i_ref_row.id_external_request ||
                   ' ID_SCHEDULE=' || i_schedule;
        pk_alertlog.log_debug(g_error);
    
        OPEN c_ref_map(i_ref_row.id_external_request, i_schedule);
        FETCH c_ref_map
            INTO l_ref_map_row;
        g_found := c_ref_map%FOUND;
        CLOSE c_ref_map;
    
        IF NOT g_found
        THEN
            g_error := g_error || ' / NOT FOUND';
            RAISE g_exception;
        END IF;
    
        -----------------------
        -- Cancels active line
        g_error := 'Call PK_API_REF.cancel_ref_map / ID_EXT_REQ=' || l_ref_map_row.id_external_request ||
                   ' ID_SCHEDULE=' || l_ref_map_row.id_schedule || ' ID_EPISODE=' || l_ref_map_row.id_episode ||
                   ' FLG_STATUS=' || l_ref_map_row.flg_status;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_api.cancel_ref_map(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_ref_map_row => l_ref_map_row,
                                              o_error       => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error || ' ID_REF_MAP=' || l_id_ref_map;
            RAISE g_exception;
        END IF;
    
        -----------------------
        -- IF id_episode is not null, must insert active line with referral and episode ids (because these were the conditions before schedule)
        -- only if schedule type is ORIS/INP
    
        -- get schedule type
        g_error := 'Call PK_SCHEDULE.get_sch_type / ID_EXT_REQ=' || l_ref_map_new_row.id_external_request ||
                   ' ID_SCHEDULE=' || i_schedule;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_schedule.get_sch_type(i_lang     => i_lang,
                                             i_prof     => i_prof,
                                             i_id_sch   => i_schedule,
                                             o_sch_type => l_sch_type,
                                             o_error    => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error || ' SCH_TYPE=' || l_sch_type;
            RAISE g_exception_np;
        END IF;
    
        -- setting conditions before schedule 
        IF l_sch_type IN
           (pk_schedule_common.g_sch_dept_flg_dep_type_sr, pk_schedule_common.g_sch_dept_flg_dep_type_inp)
        THEN
        
            g_error := 'SCH_TYPE=' || l_sch_type || ' ID_EPISODE=' || l_ref_map_row.id_episode;
            IF l_ref_map_row.id_episode IS NOT NULL
            THEN
                l_ref_map_new_row.id_external_request := l_ref_map_row.id_external_request;
                l_ref_map_new_row.id_episode          := l_ref_map_row.id_episode;
                l_ref_map_new_row.flg_status          := pk_ref_constant.g_active;
            
                g_error := 'Call PK_API_REF.set_ref_map / ID_EXT_REQ=' || l_ref_map_new_row.id_external_request ||
                           ' ID_SCHEDULE=' || l_ref_map_new_row.id_schedule || ' ID_EPISODE=' ||
                           l_ref_map_new_row.id_episode || ' FLG_STATUS=' || l_ref_map_new_row.flg_status;
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_api.set_ref_map(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_ref_map    => l_ref_map_new_row,
                                                   o_id_ref_map => l_id_ref_map,
                                                   o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    g_error := 'ERROR: ' || g_error || ' ID_REF_MAP=' || l_id_ref_map;
                    RAISE g_exception_np;
                END IF;
            END IF;
        END IF;
    
        -------------------------------
        -- Gets the new referral status 
        -------------------------------
        g_error := 'Call get_referral_new_status / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status;
        pk_alertlog.log_debug(g_error);
        g_retval := get_referral_new_status(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_ref_row        => i_ref_row,
                                            o_flg_status_new => o_flg_status_new,
                                            o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_CANCEL_SCH_CIRCLE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_cancel_sch_circle;

    /**
    * Notifies the patient about the schedule
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids   
    * @param   i_ref_row        Referral info    
    * @param   o_flg_status_new New referral flag status. If NULL the referral does not need  to change status.
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-12-2009
    */
    FUNCTION set_ref_mailed_circle
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_row        IN p1_external_request%ROWTYPE,
        o_flg_status_new OUT p1_external_request.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Init set_ref_mailed_circle / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status;
        pk_alertlog.log_debug(g_error);
    
        -------------------------------
        -- Gets the new referral status 
        -------------------------------
        g_error := 'Call get_referral_new_status / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status;
        pk_alertlog.log_debug(g_error);
        g_retval := get_referral_new_status(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_ref_row        => i_ref_row,
                                            o_flg_status_new => o_flg_status_new,
                                            o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_MAILED_CIRCLE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_mailed_circle;

    /**
    * Sets the effectivation of the referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids   
    * @param   i_ref_row        Referral info    
    * @param   o_flg_status_new New referral flag status. If NULL the referral does not need  to change status.
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-12-2009
    */
    FUNCTION set_ref_efectv_circle
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_row        IN p1_external_request%ROWTYPE,
        o_flg_status_new OUT p1_external_request.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Init set_ref_efectv_circle / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status;
        pk_alertlog.log_debug(g_error);
    
        -- Gets the new referral status 
        g_error := 'Call get_referral_new_status / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status;
        pk_alertlog.log_debug(g_error);
        g_retval := get_referral_new_status(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_ref_row        => i_ref_row,
                                            o_flg_status_new => o_flg_status_new,
                                            o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_EFECTV_CIRCLE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_efectv_circle;

    /**
    * Gets referral detail according to generic module
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_prof_data              Professional info: profile_template, category and functionality     
    * @param   i_ref_row                P1_EXTERNAL_REQUEST rowtype    
    * @param   i_can_view_clin_data     Indicates if this professional can view clinical data {Y} can view clinical data {N} otherwise    
    * @param   o_notes_status           Status info: status, timestamp and professional
    * @param   o_notes_status_det       Status info detail
    * @param   o_error                  An error message, set when return=false
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-11-2009    
    */
    FUNCTION get_referral_generic
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_prof_data          IN t_rec_prof_data,
        i_ref_row            IN p1_external_request%ROWTYPE,
        i_can_view_clin_data IN VARCHAR2,
        o_notes_status       OUT pk_types.cursor_type,
        o_notes_status_det   OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_wf_status_info table_varchar;
        l_tracking_crit  table_table_number;
    
        TYPE t_rec_tracking IS RECORD(
            id_tracking    p1_tracking.id_tracking%TYPE,
            ext_req_status p1_tracking.ext_req_status%TYPE,
            flg_type       p1_tracking.flg_type%TYPE);
    
        TYPE t_coll_tracking IS TABLE OF t_rec_tracking INDEX BY BINARY_INTEGER;
        l_tracking_tab t_coll_tracking;
    
        l_crit PLS_INTEGER;
    
        l_can_view_clin_data VARCHAR2(1 CHAR);
        l_ref_waiting_time   sys_config.value%TYPE;
        l_ref_adw_column     sys_config.value%TYPE;
        l_wait_days_label    sys_message.desc_message%TYPE;
    
        -- sys_messages
        l_code_msg_arr        table_varchar;
        l_desc_message_ibt    pk_ref_constant.ibt_varchar_varchar;
        l_sm_clinical_service sys_message.desc_message%TYPE; -- clinical service
        l_sm_speciality       sys_message.desc_message%TYPE; -- p1_speciality
        l_sm_sub_speciality   sys_message.desc_message%TYPE; -- sub-speciality (referral creation)
        l_var                 VARCHAR2(50 CHAR);
        l_var_spec            VARCHAR2(50 CHAR);
        l_var_reason          VARCHAR2(50 CHAR);
        l_var_cs              VARCHAR2(50 CHAR);
        l_var_dep             VARCHAR2(50 CHAR);
    BEGIN
        ----------------------
        -- CONFIG
        ----------------------
        g_error := 'Init get_referral_generic / ID_REF=' || i_ref_row.id_external_request;
        pk_alertlog.log_debug(g_error);
    
        l_var        := pk_ref_constant.g_institution_code;
        l_var_spec   := pk_ref_constant.g_p1_speciality_code;
        l_var_reason := pk_ref_constant.g_p1_reason_code;
        l_var_cs     := pk_ref_constant.g_clinical_service_code;
        l_var_dep    := pk_ref_constant.g_department_code;
    
        l_can_view_clin_data := nvl(i_can_view_clin_data, pk_ref_constant.g_no);
        l_ref_adw_column     := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                            i_id_sys_config => pk_ref_constant.g_sc_ref_adw_column);
        l_ref_waiting_time   := nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                i_id_sys_config => pk_ref_constant.g_ref_waiting_time),
                                    pk_ref_constant.g_no);
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- getting sys_messages
        l_sm_speciality       := pk_ref_constant.g_sm_p1_detail_t011; -- p1_speciality
        l_sm_sub_speciality   := pk_ref_constant.g_sm_ref_grid_t025; -- sub-speciality (refers to the clinical service)
        l_sm_clinical_service := pk_ref_constant.g_sm_ref_grid_t025; -- clinical service
    
        g_error        := 'Fill l_code_msg_arr / ID_REF=' || i_ref_row.id_external_request;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_p1_detail_t004,
                                        pk_ref_constant.g_sm_p1_detail_t011,
                                        pk_ref_constant.g_sm_p1_detail_t012,
                                        pk_ref_constant.g_sm_p1_detail_t037,
                                        pk_ref_constant.g_sm_p1_detail_t038,
                                        pk_ref_constant.g_sm_p1_detail_t039,
                                        pk_ref_constant.g_sm_p1_detail_t045,
                                        pk_ref_constant.g_sm_p1_detail_t046,
                                        pk_ref_constant.g_sm_p1_detail_t047,
                                        pk_ref_constant.g_sm_p1_detail_t048,
                                        pk_ref_constant.g_sm_p1_detail_t049,
                                        pk_ref_constant.g_sm_p1_detail_t050,
                                        pk_ref_constant.g_sm_p1_detail_t051,
                                        pk_ref_constant.g_sm_p1_detail_t052,
                                        pk_ref_constant.g_sm_p1_detail_t053,
                                        pk_ref_constant.g_sm_p1_detail_t054,
                                        pk_ref_constant.g_sm_p1_detail_t055,
                                        pk_ref_constant.g_sm_p1_detail_t056,
                                        pk_ref_constant.g_sm_p1_detail_t057,
                                        pk_ref_constant.g_sm_p1_detail_t058,
                                        pk_ref_constant.g_sm_p1_detail_t060,
                                        pk_ref_constant.g_sm_p1_detail_t061,
                                        pk_ref_constant.g_sm_p1_detail_t062,
                                        pk_ref_constant.g_sm_ref_detail_t020,
                                        pk_ref_constant.g_sm_ref_detail_t032,
                                        pk_ref_constant.g_sm_ref_detail_t025,
                                        pk_ref_constant.g_sm_ref_detail_t081, -- patient missed
                                        pk_ref_constant.g_sm_ref_transfresp_t051,
                                        pk_ref_constant.g_sm_ref_grid_t025,
                                        pk_ref_constant.g_sm_ref_waitingtime_t012,
                                        pk_ref_constant.g_sm_ref_waitingtime_t013,
                                        pk_ref_constant.g_sm_ref_waitingtime_t014,
                                        pk_ref_constant.g_sm_ref_waitingtime_t015,
                                        pk_ref_constant.g_sm_common_m20,
                                        pk_ref_constant.g_sm_ref_detail_t048,
                                        pk_ref_constant.g_sm_ref_detail_t062,
                                        l_sm_speciality,
                                        l_sm_sub_speciality,
                                        l_sm_clinical_service,
                                        pk_ref_constant.g_sm_ref_detail_t063,
                                        pk_ref_constant.g_sm_ref_detail_t064,
                                        pk_ref_constant.g_sm_bdnp_alert_m001,
                                        pk_ref_constant.g_sm_alert_m0104,
                                        pk_ref_constant.g_sm_alert_m0103,
                                        pk_ref_constant.g_sm_alert_m0106,
                                        pk_ref_constant.g_sm_alert_m0107,
                                        pk_ref_constant.g_sm_bdnp_alert_w_m001,
                                        pk_ref_constant.g_sm_alert_m0108,
                                        pk_ref_constant.g_sm_bdnp_alert_e_m001,
                                        pk_ref_constant.g_sm_ref_detail_t065,
                                        pk_ref_constant.g_sm_ref_detail_t066,
                                        pk_ref_constant.g_sm_ref_detail_t067,
                                        pk_ref_constant.g_sm_ref_detail_t068);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / l_code_msg_arr.COUNT=' || l_code_msg_arr.count || ' ID_REF=' ||
                    i_ref_row.id_external_request;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_waiting_time = pk_ref_constant.g_yes
        THEN
            -- l_wait_days_label
            IF l_ref_adw_column = pk_ref_constant.g_wait_time_avg_dd
            THEN
                l_wait_days_label := l_desc_message_ibt(pk_ref_constant.g_sm_ref_waitingtime_t015);
            ELSE
                l_wait_days_label := l_desc_message_ibt(pk_ref_constant.g_sm_ref_waitingtime_t014);
            END IF;
        
        ELSE
            l_ref_adw_column  := NULL;
            l_wait_days_label := NULL;
        END IF;
    
        g_error          := 'Call pk_ref_core.init_param_tab / ID_REF=' || i_ref_row.id_external_request;
        l_wf_status_info := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_ext_req            => i_ref_row.id_external_request,
                                                       i_id_patient         => i_ref_row.id_patient,
                                                       i_id_inst_orig       => i_ref_row.id_inst_orig,
                                                       i_id_inst_dest       => i_ref_row.id_inst_dest,
                                                       i_id_dep_clin_serv   => i_ref_row.id_dep_clin_serv,
                                                       i_id_speciality      => i_ref_row.id_speciality,
                                                       i_flg_type           => i_ref_row.flg_type,
                                                       i_decision_urg_level => i_ref_row.decision_urg_level,
                                                       i_id_prof_requested  => i_ref_row.id_prof_requested,
                                                       i_id_prof_redirected => i_ref_row.id_prof_redirected,
                                                       i_id_prof_status     => i_ref_row.id_prof_status,
                                                       i_external_sys       => i_ref_row.id_external_sys,
                                                       i_location           => pk_ref_constant.g_location_detail,
                                                       i_flg_status         => i_ref_row.flg_status);
        -- Criterias are:
        --   1- Status: Canceled (C),  Bureaucratic Decline (B), Declined (D), Mailed (M), Executed (E),Refused (X),  
        --             (F)ailed, (P)rinted, (H) Refused (Clinical Director), (J) For approval (Clinical Director),
        --             (V) Approved (Clinical Director), (Z) Request Cancellation
        --   2- Status: Answered (W) and Aknowledge (K)
        --   3- Status: New (N)
        --   4- Status: to Schedule (A)
        --   5- Status: Scheduled (S)
        --   6- Status: Forwarded and Triage (T, R and flg_type=C)
        --   7- Status: Forwarded to triage physician (T, flg_type=P)
        --   8- Status: Triage (T) and Issued (I)
        --   9- Status: Specimen collection in progress (G)
        --  10- Status: b(L)ocked
        --  11- Migrated results
        --  12- Tracking type: T - Transf. Resp.
    
        g_error         := 'Init l_tracking_crit';
        l_tracking_crit := table_table_number(table_number(),
                                              table_number(),
                                              table_number(),
                                              table_number(),
                                              table_number(),
                                              table_number(),
                                              table_number(),
                                              table_number(),
                                              table_number(),
                                              table_number(),
                                              table_number(),
                                              table_number());
    
        -- fetching all p1_tracking records into a collection
        g_error := 'SELECT P1_TRACKING / ID_REF=' || i_ref_row.id_external_request;
        SELECT t.id_tracking, t.ext_req_status, t.flg_type BULK COLLECT
          INTO l_tracking_tab
          FROM p1_tracking t
         WHERE t.id_external_request = i_ref_row.id_external_request
           AND t.flg_type != pk_ref_constant.g_tracking_type_r; -- criterias defined above
    
        -- dividing l_tracking_tab into "criterias"     
        g_error := 'l_tracking_tab.COUNT=' || l_tracking_tab.count || ' / ID_REF=' || i_ref_row.id_external_request;
        IF l_tracking_tab.count > 0
        THEN
            FOR i IN l_tracking_tab.first .. l_tracking_tab.last
            LOOP
            
                l_crit := NULL;
            
                IF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_s
                    AND l_tracking_tab(i)
                   .ext_req_status IN (pk_ref_constant.g_p1_status_c,
                                       pk_ref_constant.g_p1_status_b,
                                       pk_ref_constant.g_p1_status_d,
                                       pk_ref_constant.g_p1_status_y,
                                       pk_ref_constant.g_p1_status_m,
                                       pk_ref_constant.g_p1_status_e,
                                       pk_ref_constant.g_p1_status_x,
                                       pk_ref_constant.g_p1_status_f,
                                       pk_ref_constant.g_p1_status_p,
                                       pk_ref_constant.g_p1_status_h,
                                       pk_ref_constant.g_p1_status_j,
                                       pk_ref_constant.g_p1_status_v,
                                       pk_ref_constant.g_p1_status_z)
                THEN
                    -- 1- Status: Canceled (C),  Bureaucratic Decline (B), Declined (D), Mailed (M), Executed (E), 
                    -- Refused (X), (F)ailed, (P)rinted, (H) Refused (Clinical Director), (J) For approval (Clinical Director),
                    -- (V) Approved (Clinical Director), (Z) Request Cancellation
                    l_crit := 1;
                
                ELSIF l_tracking_tab(i)
                 .flg_type = pk_ref_constant.g_tracking_type_s
                       AND l_tracking_tab(i)
                      .ext_req_status IN (pk_ref_constant.g_p1_status_w, pk_ref_constant.g_p1_status_k)
                THEN
                
                    -- 2- Status: Answered (W) and Aknowledge (K)
                    l_crit := 2;
                
                ELSIF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_s
                       AND l_tracking_tab(i).ext_req_status = pk_ref_constant.g_p1_status_n
                THEN
                
                    -- 3- Status: New (N)
                    l_crit := 3;
                
                ELSIF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_s
                       AND l_tracking_tab(i).ext_req_status = pk_ref_constant.g_p1_status_a
                THEN
                
                    -- 4- Status: to Schedule (A)
                    l_crit := 4;
                
                ELSIF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_s
                       AND l_tracking_tab(i).ext_req_status = pk_ref_constant.g_p1_status_s
                THEN
                
                    -- 5- Status: Scheduled (S)
                    l_crit := 5;
                
                ELSIF l_tracking_tab(i)
                 .flg_type = pk_ref_constant.g_tracking_type_c
                       AND l_tracking_tab(i)
                      .ext_req_status IN (pk_ref_constant.g_p1_status_t, pk_ref_constant.g_p1_status_r)
                THEN
                
                    -- 6- Status: Forwarded and Triage (T, R and flg_type=C)
                    l_crit := 6;
                
                ELSIF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_p
                       AND l_tracking_tab(i).ext_req_status = pk_ref_constant.g_p1_status_r
                THEN
                
                    -- 7- Status: Forwarded to triage physician (T, flg_type=P)
                    l_crit := 7;
                
                ELSIF l_tracking_tab(i)
                 .flg_type = pk_ref_constant.g_tracking_type_s
                       AND l_tracking_tab(i)
                      .ext_req_status IN (pk_ref_constant.g_p1_status_i, pk_ref_constant.g_p1_status_t)
                THEN
                
                    -- 8- Status: Triage (T) and Issued (I)
                    l_crit := 8;
                
                ELSIF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_s
                       AND l_tracking_tab(i).ext_req_status = pk_ref_constant.g_p1_status_g
                THEN
                    -- 9- Status: Specimen collection in progress (G)
                    l_crit := 9;
                ELSIF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_s
                       AND l_tracking_tab(i).ext_req_status = pk_ref_constant.g_p1_status_l
                THEN
                    -- 10- Status: b(L)ocked
                    l_crit := 10;
                ELSIF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_m
                THEN
                    -- 11- Migrated results
                    l_crit := 11;
                
                ELSIF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_t
                THEN
                    -- 12- Tracking type: T - Transf. Resp.
                    l_crit := 12;
                
                END IF;
            
                IF l_crit IS NOT NULL
                THEN
                    l_tracking_crit(l_crit).extend;
                    l_tracking_crit(l_crit)(l_tracking_crit(l_crit).last) := l_tracking_tab(i).id_tracking;
                END IF;
            
            END LOOP;
        END IF;
    
        -- o_notes_status (MED+ADM)
        g_error := 'OPEN O_NOTES_STATUS / ID_REF=' || i_ref_row.id_external_request;
        OPEN o_notes_status FOR
            SELECT id_tracking,
                   title,
                   decode(ext_req_status,
                          pk_ref_constant.g_p1_status_m,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t045),
                          pk_ref_constant.g_p1_status_e,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t046),
                          pk_ref_constant.g_p1_status_t,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t047),
                          pk_ref_constant.g_p1_status_i,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t048),
                          pk_ref_constant.g_p1_status_p,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t053),
                          pk_ref_constant.g_p1_status_j,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t061),
                          pk_ref_constant.g_p1_status_h,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t062),
                          pk_ref_constant.g_p1_status_v,
                          l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t025),
                          pk_ref_constant.g_p1_status_f,
                          l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t081), -- patient missed
                          pk_ref_constant.g_p1_status_z,
                          l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t032),
                          pk_ref_constant.g_p1_status_c,
                          l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t020),
                          pk_ref_constant.g_p1_status_x, -- because of BR market
                          l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t065),
                          pk_ref_constant.g_p1_status_d, -- because of BR market
                          l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t066),
                          pk_ref_constant.g_p1_status_n, -- because of BR market
                          l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t067),
                          pk_ref_constant.g_p1_status_q, -- because of BR market
                          l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t068),
                          NULL) text,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) prof_name,
                   pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, id_professional, id_institution) prof_spec,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_insert, i_prof) dt_insert,
                   pk_date_utils.date_send_tsz(i_lang, dt_insert, i_prof) dt
              FROM (
                    -- 1- Status: Canceled (C),  Bureaucratic Decline (B), Declined (D), Mailed (M), Executed (E), 
                    -- Refused (X), (F)ailed, (P)rinted, (H) Refused (Clinical Director), (J) For approval (Clinical Director),
                    -- (V) Approved (Clinical Director), (Z) Request Cancellation
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     10 rank,
                      t.ext_req_status,
                      pk_workflow.get_status_desc(i_lang,
                                                  i_prof,
                                                  nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp),
                                                  pk_ref_status.convert_status_n(t.ext_req_status),
                                                  i_prof_data.id_category,
                                                  i_prof_data.id_profile_template,
                                                  i_prof_data.id_functionality,
                                                  l_wf_status_info) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 1
                    UNION ALL
                    -- 2- Status: Answered (W) and Aknowledge (K)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     10 rank,
                      t.ext_req_status,
                      pk_workflow.get_status_desc(i_lang,
                                                  i_prof,
                                                  nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp),
                                                  pk_ref_status.convert_status_n(t.ext_req_status),
                                                  i_prof_data.id_category,
                                                  i_prof_data.id_profile_template,
                                                  i_prof_data.id_functionality,
                                                  l_wf_status_info) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(2) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 2                     
                    UNION ALL
                    -- 3- Status: New (N)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     decode(l_can_view_clin_data, pk_ref_constant.g_yes, 10, 20) rank,
                      t.ext_req_status,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t037) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 3                                            
                    UNION ALL
                    -- 4- Status: to Schedule (A)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     20 rank,
                      t.ext_req_status,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t039) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(4) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 4                                        
                    UNION ALL
                    -- 5- Status: Scheduled (S)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     20 rank,
                      t.ext_req_status,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t038) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(5) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 5                                        
                    UNION ALL
                    -- 6- Status: Forwarded and Triage (T, R and flg_type=C)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     20 rank,
                      t.ext_req_status,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t004) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(6) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 6
                    UNION ALL
                    -- 7- Status: Forwarded to triage physician (T, flg_type=P)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     20 rank,
                      t.ext_req_status,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t004) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(7) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 7
                    UNION ALL
                    -- 8- Status: Triage (T) and Issued (I)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     10 rank,
                      t.ext_req_status,
                      decode(t.ext_req_status,
                             pk_ref_constant.g_p1_status_i,
                             l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t051),
                             pk_ref_constant.g_p1_status_t,
                             l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t052)) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(8) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 8
                    UNION ALL
                    -- 9- Status: Specimen collection in progress (G)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     10 rank,
                      t.ext_req_status,
                      pk_workflow.get_status_desc(i_lang,
                                                  i_prof,
                                                  nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp),
                                                  pk_ref_status.convert_status_n(t.ext_req_status),
                                                  i_prof_data.id_category,
                                                  i_prof_data.id_profile_template,
                                                  i_prof_data.id_functionality,
                                                  l_wf_status_info) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(9) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 9                                                
                    UNION ALL
                    -- 10- Status: b(L)ocked
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     10 rank,
                      t.ext_req_status,
                      pk_workflow.get_status_desc(i_lang,
                                                  i_prof,
                                                  nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp),
                                                  pk_ref_status.convert_status_n(t.ext_req_status),
                                                  i_prof_data.id_category,
                                                  i_prof_data.id_profile_template,
                                                  i_prof_data.id_functionality,
                                                  l_wf_status_info) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(10) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 10                    
                    UNION ALL
                    -- 11- Migrated records
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     10 rank,
                      t.ext_req_status,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t063) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(11) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 11 
                    
                    UNION ALL
                    -- 12- Tracking type: T - Transf. Resp.
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     10 rank,
                      t.ext_req_status,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_transfresp_t051) title,
                      t.id_tracking,
                      t.id_professional,
                      t.id_institution,
                      nvl(t.dt_create, t.dt_tracking_tstz) dt_insert,
                      t.dt_tracking_tstz
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(12) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 12
                    )
             ORDER BY dt_tracking_tstz DESC, rank ASC;
    
        -- rank: 5- Especialidade P1 | 10- Motivo | 20- Profissional | 30- Instituicao actual | 40- Departamento | 50- servico clinico | 
        -- 60- Prioridade | 70- Notas | 90- Especialidade P1 | 95- Schedule date | 100- data real da operacao | null - resto
        -- rank used to rank records having the same id_traking
        g_error := 'OPEN O_NOTES_STATUS_DET / ID_REF=' || i_ref_row.id_external_request;
        OPEN o_notes_status_det FOR
            SELECT rank, id_tracking, title, text
              FROM (
                    -- 1- Status: Canceled (C),  Bureaucratic Decline (B), Declined (D), Mailed (M), Executed (E), 
                    -- Refused (X), (F)ailed, (P)rinted, (H) Refused (Clinical Director), (J) For approvalS (Clinical Director),
                    -- (V) Approved (Clinical Director), (Z) Request Cancellation
                    -- Motivo       
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     10 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t054) title,
                      pk_translation.get_translation(i_lang, l_var_reason || t.id_reason_code) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 1                    
                     WHERE t.id_reason_code IS NOT NULL
                    UNION ALL
                    -- Notes (if registrar)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     70 rank, t.id_tracking, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t049) title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type IN (pk_ref_constant.g_detail_type_ntri,
                                          pk_ref_constant.g_detail_type_ndec,
                                          pk_ref_constant.g_detail_type_ncan,
                                          pk_ref_constant.g_detail_type_bdcl,
                                          pk_ref_constant.g_detail_type_miss,
                                          pk_ref_constant.g_detail_type_req_can,
                                          pk_ref_constant.g_detail_type_req_can_answ,
                                          pk_ref_constant.g_detail_type_ndec_cd)
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                       AND t.ext_req_status IN (pk_ref_constant.g_p1_status_c,
                                                pk_ref_constant.g_p1_status_b,
                                                pk_ref_constant.g_p1_status_m,
                                                pk_ref_constant.g_p1_status_f,
                                                pk_ref_constant.g_p1_status_z,
                                                pk_ref_constant.g_p1_status_y,
                                                pk_ref_constant.g_p1_status_d,
                                                pk_ref_constant.g_p1_status_x)
                       AND l_can_view_clin_data = pk_ref_constant.g_no
                    UNION ALL
                    -- Notes (if physician)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     70 rank, t.id_tracking, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t049) title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type IN (pk_ref_constant.g_detail_type_ntri,
                                          pk_ref_constant.g_detail_type_ndec,
                                          pk_ref_constant.g_detail_type_ncan,
                                          pk_ref_constant.g_detail_type_bdcl,
                                          pk_ref_constant.g_detail_type_miss,
                                          pk_ref_constant.g_detail_type_req_can,
                                          pk_ref_constant.g_detail_type_req_can_answ,
                                          pk_ref_constant.g_detail_type_ndec_cd)
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                       AND l_can_view_clin_data = pk_ref_constant.g_yes
                    UNION ALL
                    -- Referral speciality
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     5 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_speciality) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_spec || t.id_speciality) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 1
                     WHERE t.id_speciality IS NOT NULL
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(1) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 1
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    --   2- Status: Answered (W) and Aknowledge (K)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     NULL rank,
                      t.id_tracking,
                      NULL title,
                      decode(t.ext_req_status,
                             pk_ref_constant.g_p1_status_w,
                             l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t057),
                             pk_ref_constant.g_p1_status_k,
                             l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t058)) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(2) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 2                         
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(2) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 2
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    --   3- Status: New (N)                        
                    -- notas ao administrativo
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     70 rank, t.id_tracking, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t049) title, d.text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 3
                     WHERE d.flg_type IN (pk_ref_constant.g_detail_type_nadm,
                                          pk_ref_constant.g_detail_type_req_can,
                                          pk_ref_constant.g_detail_type_req_can_answ)
                       AND d.flg_status = pk_ref_constant.g_detail_status_a -- Notas ao administrativo                           
                    UNION ALL
                    -- Referral speciality
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     50 rank,
                      t1.id_tracking,
                      l_desc_message_ibt(l_sm_speciality) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_spec || t1.id_speciality) text
                      FROM (SELECT t.id_tracking, nvl(t.id_speciality, exr.id_speciality) id_speciality
                               FROM p1_tracking t
                               JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                                 ON (t.id_tracking = tt.column_value)
                               JOIN p1_external_request exr
                                 ON (exr.id_external_request = t.id_external_request)) t1
                    UNION ALL
                    -- Referral sub-speciality
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     60 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_sub_speciality) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_cs || dcs.id_clinical_service) text
                      FROM p1_tracking t
                      JOIN dep_clin_serv dcs
                        ON (t.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                    -------------
                    UNION ALL
                    -- inst_type
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     61 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_waitingtime_t012) title,
                      (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_type_ins, pdi.flg_type_ins, i_lang)
                         FROM dual) text
                      FROM p1_external_request exr
                      JOIN p1_tracking t
                        ON (t.id_external_request = exr.id_external_request)
                      JOIN p1_dest_institution pdi
                        ON (pdi.id_inst_orig = exr.id_inst_orig AND pdi.id_inst_dest = exr.id_inst_dest AND
                           pdi.flg_type = exr.flg_type)
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE exr.id_external_request = i_ref_row.id_external_request
                       AND l_ref_waiting_time = pk_ref_constant.g_yes
                       AND t.id_inst_dest IS NOT NULL
                    UNION ALL
                    -- flg_ref_line
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     62 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_waitingtime_t013) title,
                      (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_ref_line, rdis.flg_ref_line, i_lang)
                         FROM dual) text
                      FROM p1_external_request exr
                      JOIN p1_tracking t
                        ON (t.id_external_request = exr.id_external_request)
                      JOIN p1_dest_institution pdi
                        ON (pdi.id_inst_orig = exr.id_inst_orig AND pdi.id_inst_dest = exr.id_inst_dest AND
                           pdi.flg_type = exr.flg_type)
                      JOIN ref_dest_institution_spec rdis
                        ON (rdis.id_dest_institution = pdi.id_dest_institution AND exr.id_speciality = rdis.id_speciality)
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE exr.id_external_request = i_ref_row.id_external_request
                       AND l_ref_waiting_time = pk_ref_constant.g_yes
                       AND t.id_inst_dest IS NOT NULL
                    UNION ALL
                    -- waiting_time
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     63                rank,
                      t.id_tracking,
                      l_wait_days_label title,
                      -- text
                      nvl2(
                           -- string
                           (SELECT pk_ref_waiting_time.get_waiting_time(i_lang,
                                                                        i_prof,
                                                                        l_ref_adw_column,
                                                                        nvl(t.id_inst_dest_track, t.id_inst_dest),
                                                                        t.id_speciality)
                              FROM dual),
                           --value_if_NOT_null 
                           (SELECT pk_ref_waiting_time.get_waiting_time(i_lang,
                                                                        i_prof,
                                                                        l_ref_adw_column,
                                                                        nvl(t.id_inst_dest_track, t.id_inst_dest),
                                                                        t.id_speciality)
                              FROM dual) || ' ' || l_desc_message_ibt(pk_ref_constant.g_sm_common_m20),
                           -- value_if_null 
                           NULL) text
                      FROM (SELECT ti.id_tracking, ti.id_inst_dest id_inst_dest_track, exr.id_inst_dest, exr.id_speciality
                               FROM p1_external_request exr
                               JOIN p1_tracking ti
                                 ON (ti.id_external_request = exr.id_external_request)
                               JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                                 ON (ti.id_tracking = tt.column_value)
                              WHERE exr.id_external_request = i_ref_row.id_external_request
                                AND l_ref_waiting_time = pk_ref_constant.g_yes
                                AND ti.id_inst_dest IS NOT NULL) t
                    -------------
                    UNION ALL
                    -- Instituicao
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     30 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t012) title,
                      pk_translation.get_translation(i_lang, l_var || t.id_inst_dest) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE t.id_inst_dest IS NOT NULL
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(3) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 3
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    --   4- Status: to Schedule (A)
                    --  Servico a agendar
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     40 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t050) title,
                      pk_translation.get_translation(i_lang, l_var_dep || dcs.id_department) text
                      FROM p1_tracking t
                      JOIN dep_clin_serv dcs
                        ON (t.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN TABLE(CAST(l_tracking_crit(4) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 4
                    UNION ALL
                    -- Especialidade a agendar
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     50 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_clinical_service) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_cs || dcs.id_clinical_service) text
                      FROM p1_tracking t
                      JOIN dep_clin_serv dcs
                        ON (t.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN TABLE(CAST(l_tracking_crit(4) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                    UNION ALL
                    -- Professional to whom the referral was scheduled
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     20 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t055) title,
                      pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_dest) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(4) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE t.id_prof_dest IS NOT NULL
                    UNION ALL
                    -- Prioridade atribuida
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     60 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t048) title,
                      pk_sysdomain.get_domain('P1_TRIAGE_LEVEL.MED_HS_1',
                                              t.decision_urg_level, -- JS: 2007-04-26, using p1_tracking record because of re-schedules
                                              i_lang) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(4) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE t.decision_urg_level IS NOT NULL
                    
                    UNION ALL
                    -- Reason code
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     60 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t054) title,
                      pk_translation.get_translation(i_lang, l_var_reason || t.id_reason_code) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(4) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE t.id_reason_code IS NOT NULL
                    
                    UNION ALL
                    -- Notas da decisao                                                                      
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     70 rank, t.id_tracking, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t049) title, d.text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON t.id_tracking = d.id_tracking
                      JOIN TABLE(CAST(l_tracking_crit(4) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type IN (pk_ref_constant.g_detail_type_ndec,
                                          pk_ref_constant.g_detail_type_req_can,
                                          pk_ref_constant.g_detail_type_req_can_answ)
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    -- Referral speciality
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     90 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_speciality) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_spec || t.id_speciality) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(4) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 4
                     WHERE t.id_speciality IS NOT NULL
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(4) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 4
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    -- 5- Status: Scheduled (S)
                    -- schedule date
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     95 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t056) title,
                      pk_date_utils.dt_chr_tsz(i_lang, s.dt_begin_tstz, i_prof) || ' ' ||
                      pk_date_utils.dt_chr_hour_tsz(i_lang, s.dt_begin_tstz, i_prof) text
                      FROM schedule s
                      JOIN p1_tracking t
                        ON (t.id_schedule = s.id_schedule)
                      JOIN TABLE(CAST(l_tracking_crit(5) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 5
                    UNION ALL
                    -- department 
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     40 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t050) title,
                      pk_translation.get_translation(i_lang, l_var_dep || dcs.id_department) text
                      FROM schedule s
                      JOIN p1_tracking t
                        ON (t.id_schedule = s.id_schedule)
                      JOIN TABLE(CAST(l_tracking_crit(5) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                      JOIN dep_clin_serv dcs
                        ON (s.id_dcs_requested = dcs.id_dep_clin_serv)
                    UNION ALL
                    -- clinical service
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     50 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_clinical_service) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_cs || dcs.id_clinical_service) text
                      FROM schedule s
                      JOIN p1_tracking t
                        ON (t.id_schedule = s.id_schedule)
                      JOIN TABLE(CAST(l_tracking_crit(5) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                      JOIN dep_clin_serv dcs
                        ON (s.id_dcs_requested = dcs.id_dep_clin_serv)
                    UNION ALL
                    -- profissional
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     20 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t055) title,
                      pk_prof_utils.get_name_signature(i_lang, i_prof, spo.id_professional) text
                      FROM schedule s
                      JOIN p1_tracking t
                        ON (t.id_schedule = s.id_schedule)
                      JOIN TABLE(CAST(l_tracking_crit(5) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                      JOIN schedule_outp so
                        ON (s.id_schedule = so.id_schedule)
                      LEFT JOIN sch_prof_outp spo
                        ON (so.id_schedule_outp = spo.id_schedule_outp)
                     WHERE spo.id_professional IS NOT NULL
                    UNION ALL
                    -- Referral speciality
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     90 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_speciality) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_spec || t.id_speciality) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(5) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 5
                     WHERE t.id_speciality IS NOT NULL
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(5) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 5
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    --   6- Status: Forwarded and Triage (T, R and flg_type=C)
                    -- servico
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     40 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t050) title,
                      pk_translation.get_translation(i_lang, l_var_dep || dcs.id_department) text
                      FROM p1_tracking t
                      JOIN dep_clin_serv dcs
                        ON (t.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN TABLE(CAST(l_tracking_crit(6) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 6
                    UNION ALL
                    -- especialidade
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     50 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_clinical_service) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_cs || dcs.id_clinical_service) text
                      FROM p1_tracking t
                      JOIN dep_clin_serv dcs
                        ON (t.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN TABLE(CAST(l_tracking_crit(6) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                    UNION ALL
                    -- decision notes - only for physicians
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     70 rank, t.id_tracking, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t049) title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (t.id_tracking = d.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(6) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type IN (pk_ref_constant.g_detail_type_ndec,
                                          pk_ref_constant.g_detail_type_req_can,
                                          pk_ref_constant.g_detail_type_req_can_answ)
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                       AND l_can_view_clin_data = pk_ref_constant.g_yes
                    UNION ALL
                    -- Referral speciality
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     90 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_speciality) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_spec || t.id_speciality) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(6) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 6
                     WHERE t.id_speciality IS NOT NULL
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(6) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 6
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    -- 7- Status: Forwarded to triage physician (T, flg_type=P)
                    -- medico                        
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     20 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t055) title,
                      pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_dest) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(7) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 7
                     WHERE t.id_prof_dest IS NOT NULL
                    UNION ALL
                    -- decision notes - only for physicians              
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     70 rank, t.id_tracking, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t049) title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (t.id_tracking = d.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(7) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type IN (pk_ref_constant.g_detail_type_ndec,
                                          pk_ref_constant.g_detail_type_req_can,
                                          pk_ref_constant.g_detail_type_req_can_answ)
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                       AND l_can_view_clin_data = pk_ref_constant.g_yes
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(7) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 7
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    -- 8- Status: Triage (T) and Issued (I)
                    -- instituicao actual                       
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     30 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t012) title,
                      pk_translation.get_translation(i_lang, l_var || t.id_inst_dest) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(8) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 8                       
                     WHERE t.id_inst_dest IS NOT NULL
                    UNION ALL
                    -- js, 2008-05-02: Departamento
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     40 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t050) title,
                      pk_translation.get_translation(i_lang, l_var_dep || dcs.id_department) text
                      FROM p1_tracking t
                      JOIN dep_clin_serv dcs
                        ON (t.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN TABLE(CAST(l_tracking_crit(8) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                    UNION ALL
                    -- js, 2008-05-02: serviço actual (especialidade)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     50 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_clinical_service) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_cs || dcs.id_clinical_service) text
                      FROM p1_tracking t
                      JOIN dep_clin_serv dcs
                        ON (t.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN TABLE(CAST(l_tracking_crit(8) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                    UNION ALL
                    -- Reason code
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     60 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t054) title,
                      pk_translation.get_translation(i_lang, l_var_reason || t.id_reason_code) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(8) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE t.id_reason_code IS NOT NULL
                    UNION ALL
                    -- Notas
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     70 rank, t.id_tracking, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t049) title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(8) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value)
                     WHERE d.flg_type IN (pk_ref_constant.g_detail_type_nadm,
                                          pk_ref_constant.g_detail_type_ntri,
                                          pk_ref_constant.g_detail_type_admi,
                                          pk_ref_constant.g_detail_type_ndec,
                                          pk_ref_constant.g_detail_type_req_can,
                                          pk_ref_constant.g_detail_type_req_can_answ,
                                          pk_ref_constant.g_detail_type_dcl_r)
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    -- Referral speciality
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     90 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_speciality) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_spec || t.id_speciality) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(8) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 8 
                     WHERE t.id_speciality IS NOT NULL
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(8) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 8
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    --   9- Status: Specimen collection in progress (G)
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     NULL rank, t.id_tracking, NULL title, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t060) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(9) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 9
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(9) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 9
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    -- 10- Status: b(L)ocked
                    -- Notas
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     70 rank, t.id_tracking, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t049) title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(10) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 10
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_nblc
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(10) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 10
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    -- 11- Status: migrated results
                    --  New institution
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     10 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t012) title,
                      pk_translation.get_translation(i_lang, l_var || t.id_inst_dest) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(11) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 11                   
                     WHERE t.id_inst_dest IS NOT NULL
                    UNION ALL
                    -- Service
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     40 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t050) title,
                      pk_translation.get_translation(i_lang, l_var_dep || dcs.id_department) text
                      FROM p1_tracking t
                      JOIN dep_clin_serv dcs
                        ON (t.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN TABLE(CAST(l_tracking_crit(11) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 11
                    UNION ALL
                    -- Clinical service
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     50 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_clinical_service) title, -- ALERT-203474
                      pk_translation.get_translation(i_lang, l_var_cs || dcs.id_clinical_service) text
                      FROM p1_tracking t
                      JOIN dep_clin_serv dcs
                        ON (t.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN TABLE(CAST(l_tracking_crit(11) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 11
                    UNION ALL
                    -- Referral speciality
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     90 rank,
                      t.id_tracking,
                      l_desc_message_ibt(l_sm_speciality) title,
                      pk_translation.get_translation(i_lang, l_var_spec || t.id_speciality) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(11) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 11   
                     WHERE t.id_speciality IS NOT NULL
                    UNION ALL
                    --  System notes
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     70 rank, t.id_tracking, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t049) title, d.text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON t.id_tracking = d.id_tracking
                      JOIN TABLE(CAST(l_tracking_crit(11) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 11
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_system
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    -- schedule date
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     95 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t056) title,
                      pk_date_utils.dt_chr_tsz(i_lang, s.dt_begin_tstz, i_prof) || ' ' ||
                      pk_date_utils.dt_chr_hour_tsz(i_lang, s.dt_begin_tstz, i_prof) text
                      FROM schedule s
                      JOIN p1_tracking t
                        ON (t.id_schedule = s.id_schedule)
                      JOIN TABLE(CAST(l_tracking_crit(11) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 11
                    UNION ALL
                    -- professional
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     20 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t055) title,
                      pk_prof_utils.get_name_signature(i_lang, i_prof, spo.id_professional) text
                      FROM schedule s
                      JOIN p1_tracking t
                        ON (t.id_schedule = s.id_schedule)
                      JOIN TABLE(CAST(l_tracking_crit(11) AS table_number)) tt -- using criteria 11
                        ON (t.id_tracking = tt.column_value)
                      JOIN schedule_outp so
                        ON (s.id_schedule = so.id_schedule)
                      LEFT JOIN sch_prof_outp spo
                        ON (so.id_schedule_outp = spo.id_schedule_outp)
                     WHERE spo.id_professional IS NOT NULL
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(11) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 11
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower
                    UNION ALL
                    -- 12- Tracking type: T - Transf. Resp.
                    -- inst_orig
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     10 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t012) title,
                      pk_translation.get_translation(i_lang, l_var || t.id_inst_orig) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(12) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 12
                     WHERE t.id_inst_orig IS NOT NULL
                    UNION ALL
                    -- medico
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     20 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t055) title,
                      pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_dest) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(12) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 12
                     WHERE t.id_prof_dest IS NOT NULL
                    UNION ALL
                    -- Reason code
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     60 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t054) title,
                      pk_translation.get_translation(i_lang, l_var_reason || t.id_reason_code) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(12) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 12                    
                    UNION ALL
                    -- Notes
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     70 rank, t.id_tracking, l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t049) title, d.text text
                      FROM p1_tracking t
                      JOIN p1_detail d
                        ON (d.id_tracking = t.id_tracking)
                      JOIN TABLE(CAST(l_tracking_crit(12) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 12
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_transresp
                       AND d.flg_status = pk_ref_constant.g_detail_status_a
                    UNION ALL
                    -- Operation event
                    SELECT /*+OPT_ESTIMATE(TABLE, tt,SCALE_ROWS=0.0000000001)*/
                     100 rank,
                      t.id_tracking,
                      l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t064) title,
                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tracking_tstz, i_prof) text
                      FROM p1_tracking t
                      JOIN TABLE(CAST(l_tracking_crit(12) AS table_number)) tt
                        ON (t.id_tracking = tt.column_value) -- using criteria 12
                     WHERE t.dt_create IS NOT NULL
                       AND pk_ref_utils.compare_tsz_min(t.dt_tracking_tstz, t.dt_create) = pk_ref_constant.g_date_lower)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_GENERIC',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_notes_status);
            pk_types.open_my_cursor(o_notes_status_det);
            RETURN FALSE;
    END get_referral_generic;

    /**
    * Gets referral id associated to given schedule id
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_schedule            Schedule Id 
    * @param   o_id_external_request    Referral Id    
    * @param   o_error                  An error message, set when return=false
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author Joana Barroso
    * @version 1.0
    * @since   14-12-2009    
    */
    FUNCTION get_ref_sch_to_cancel
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num_req p1_external_request.num_req%TYPE;
    BEGIN
    
        g_error := 'Call get_ref_sch / ID_SCHEDULE=' || i_id_schedule;
        pk_alertlog.log_debug(g_error);
        RETURN get_ref_sch(i_lang                => i_lang,
                           i_prof                => i_prof,
                           i_id_schedule         => i_id_schedule,
                           o_id_external_request => o_id_external_request,
                           o_num_req             => l_num_req,
                           o_error               => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_SCH_TO_CANCEL',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END get_ref_sch_to_cancel;

    /**
    * Gets referral id associated to given schedule id
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_schedule            Schedule Id 
    * @param   o_id_external_request    Referral Id    
    * @param   o_num_req                Referral num req
    * @param   o_error                  An error message, set when return=false
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author Joana Barroso
    * @version 1.0
    * @since   14-12-2009    
    */
    FUNCTION get_ref_sch
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_num_req             OUT p1_external_request.num_req%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_generic IS
            SELECT per.id_external_request, per.num_req
              FROM p1_external_request per
             WHERE per.id_schedule = i_id_schedule
            --AND per.flg_status IN (pk_ref_constant.g_p1_status_s,
            --                       pk_ref_constant.g_p1_status_m,
            --                       pk_ref_constant.g_p1_status_e,
            --                       pk_ref_constant.g_p1_status_w)
            ;
    
        CURSOR c_circle IS
            SELECT rm.id_external_request, p.num_req
              FROM ref_map rm
              JOIN p1_external_request p
                ON (p.id_external_request = rm.id_external_request)
             WHERE rm.id_schedule = i_id_schedule
               AND rm.flg_status = pk_ref_constant.g_active;
    
        l_module sys_config.value%TYPE; -- specifies referral module
    BEGIN
    
        g_error  := 'Call pk_sysconfig.get_config SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module;
        l_module := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, i_prof);
    
        g_error := 'MODULE =' || l_module;
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                g_error := 'Open c_circle';
                OPEN c_circle;
            
                g_error := 'Fetch c_circle';
                FETCH c_circle
                    INTO o_id_external_request, o_num_req;
            
                g_error := 'Close c_circle';
                CLOSE c_circle;
            
            ELSE
            
                g_error := 'Open c_generic';
                OPEN c_generic;
            
                g_error := 'Fetch c_generic';
                FETCH c_generic
                    INTO o_id_external_request, o_num_req;
            
                g_error := 'Close c_generic';
                CLOSE c_generic;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_SCH',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END get_ref_sch;

    /**
    * Gets referral active schedule identifier associated to GENERIC module
    *
    * @param   i_lang                   Language identifier
    * @param   i_prof                   Professional, institution and software ids     
    * @param   i_id_ref                 Referral identifier
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-12-2009    
    */
    FUNCTION get_ref_sch_generic
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN schedule.id_schedule%TYPE IS
    
        CURSOR c_generic IS
            SELECT p.id_schedule
              FROM p1_external_request p
              JOIN schedule s
                ON s.id_schedule = p.id_schedule
             WHERE id_external_request = i_id_ref
               AND s.flg_status = pk_ref_constant.g_active;
    
        l_sch schedule.id_schedule%TYPE;
    BEGIN
        g_error := 'Init get_ref_sch_generic / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
    
        OPEN c_generic;
        FETCH c_generic
            INTO l_sch;
        CLOSE c_generic;
    
        RETURN l_sch;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'GET_REF_SCH_GENERIC / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END get_ref_sch_generic;

    /**
    * Gets referral active schedule date associated to GENERIC module
    *
    * @param   i_lang                   Language identifier
    * @param   i_prof                   Professional, institution and software ids     
    * @param   i_id_ref                 Referral identifier
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Ana Monteiro
    * @version 1.0
    * @since   12-01-2010    
    */
    FUNCTION get_ref_sch_dt_generic
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN schedule.dt_begin_tstz%TYPE IS
    
        CURSOR c_generic IS
            SELECT s.dt_begin_tstz
              FROM p1_external_request p
              JOIN schedule s
                ON s.id_schedule = p.id_schedule
             WHERE id_external_request = i_id_ref
               AND s.flg_status = pk_ref_constant.g_active;
    
        l_sch schedule.dt_begin_tstz%TYPE;
    BEGIN
        g_error := 'Init get_ref_sch_dt_generic / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
    
        OPEN c_generic;
        FETCH c_generic
            INTO l_sch;
        CLOSE c_generic;
    
        RETURN l_sch;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'GET_REF_SCH_DT_GENERIC / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END get_ref_sch_dt_generic;

    /**
    * Gets referral external schedule identifier
    *
    * @param   i_lang                   Language identifier
    * @param   i_prof                   Professional, institution and software ids     
    * @param   i_id_ref                 Referral identifier
    *    
    * @RETURN  Referral external schedule identifier 
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-11-2010    
    */

    FUNCTION get_ref_sch_ext
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_sch  IN schedule.id_schedule%TYPE
    ) RETURN sch_api_map_ids.id_schedule_ext%TYPE IS
    
        CURSOR c_sch IS
            SELECT id_schedule_ext
              FROM sch_api_map_ids
             WHERE id_schedule_pfh = i_sch;
    
        l_sch sch_api_map_ids.id_schedule_ext%TYPE;
    BEGIN
    
        g_error := 'Init get_ref_sch_ext / I_SCH=' || i_sch;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'OPEN c_sch';
        OPEN c_sch;
    
        g_error := 'FETCH c_sch';
        FETCH c_sch
            INTO l_sch;
    
        g_error := 'CLOSE c_sch';
        CLOSE c_sch;
    
        g_error := 'Init get_ref_sch_ext / L_SCH=' || l_sch;
        pk_alertlog.log_debug(g_error);
        RETURN l_sch;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'GET_REF_SCH_EXT / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END get_ref_sch_ext;

    /**
    * Checks if referral is associated to the schedule identifier. If it is, then return i_id_schedule, otherwise return null
    *
    * @param   i_lang                   Language identifier
    * @param   i_prof                   Professional, institution and software ids     
    * @param   i_id_ref                 Referral identifier
    * @param   i_id_schedule            Schedule identifier   
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-12-2009
    */
    FUNCTION check_ref_sch_circle
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN schedule.id_schedule%TYPE IS
    
        CURSOR c_circle IS
            SELECT COUNT(1)
              FROM ref_map rm
             WHERE rm.id_schedule = i_id_schedule
               AND rm.id_external_request = i_id_ref
               AND rm.flg_status = pk_ref_constant.g_active;
    
        l_count PLS_INTEGER;
    BEGIN
    
        g_error := 'Init check_ref_sch_circle / ID_REF=' || i_id_ref || ' ID_SCHEDULE=' || i_id_schedule;
        pk_alertlog.log_debug(g_error);
    
        OPEN c_circle;
        FETCH c_circle
            INTO l_count;
        CLOSE c_circle;
    
        g_error := 'COUNT=' || l_count;
        IF l_count > 0
        THEN
            RETURN i_id_schedule;
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'CHECK_REF_SCH_CIRCLE / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END check_ref_sch_circle;

    /**
    * Gets labels to be shown in referral detail
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_module         Referral module
    * @param   o_label_spec     Referral speciality label
    * @param   o_label_sub_spec Referral sub-speciality label (when creating the referral)
    * @param   o_label_cs       Referral clinical service label 
    * @param   o_error          An error message, set when return=false
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2012-05-25
    */
    FUNCTION get_label_specialities
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_module         IN sys_config.value%TYPE,
        o_label_spec     OUT sys_message.code_message%TYPE,
        o_label_sub_spec OUT sys_message.code_message%TYPE,
        o_label_cs       OUT sys_message.code_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_label_specialities';
        pk_alertlog.log_debug(g_error);
    
        CASE i_module
            WHEN pk_ref_constant.g_sc_ref_module_acss THEN
                o_label_spec     := pk_ref_constant.g_sm_p1_detail_t011; -- p1_speciality
                o_label_sub_spec := pk_ref_constant.g_sm_ref_grid_t025; -- sub-speciality (refers to the clinical service)
                o_label_cs       := pk_ref_constant.g_sm_ref_grid_t025; -- clinical service        
            ELSE
                o_label_spec     := pk_ref_constant.g_sm_ref_detail_t062; -- p1_speciality
                o_label_sub_spec := pk_ref_constant.g_sm_ref_grid_t025; -- sub-speciality (referral creation)           
                o_label_cs       := pk_ref_constant.g_sm_p1_detail_t011; -- clinical service
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_LABEL_SPECIALITIES',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_label_specialities;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_module;
/
