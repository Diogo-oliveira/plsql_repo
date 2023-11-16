/*-- Last Change Revision: $Rev: 2026941 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_demo AS

    -- ##########################################################################################

    /********************************************************************************************
    *
    * Contrary to all previous verions of the WR demo, this function aims to use only patients that are loaded 
    * on the grids. This way we make sure that WR will not display patients that have nothing to do with those 
    * visible in the grid.
    *
    * @param i_lang          ID language
    * @param i_prof          Registar's ID 
    * @param i_episode       Episode ID
    * @param o_error         Error output
    * 
    * @return                         true or false 
    *
    * @author                          Ricardo Nuno Almeida
    * @version                         0.1
    * @since                           2009/02/20
    *
    **********************************************************************************************/
    FUNCTION create_context_wps
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num NUMBER;
    BEGIN
    
        g_error := 'INSERT PATIENT';
    
        SELECT COUNT(1)
          INTO l_num
          FROM wl_patient_sonho wl
         WHERE wl.id_episode = i_episode;
    
        IF l_num = 0
        THEN
            INSERT INTO wl_patient_sonho
                (patient_id, clin_prof_id, consult_id, prof_id, id_institution, id_episode, dt_consult_tstz)
                SELECT sg.id_patient,
                       nvl(ei.id_professional, ei.sch_prof_outp_id_prof),
                       cs.id_clinical_service,
                       i_prof.id id_prof,
                       i_prof.institution institution,
                       epis.id_episode,
                       current_timestamp dt_cons
                  FROM schedule_outp sp
                  JOIN sch_group sg
                    ON sg.id_schedule = sp.id_schedule
                  LEFT JOIN epis_info ei
                    ON ei.id_schedule = sp.id_schedule
                  LEFT JOIN episode epis
                    ON epis.id_episode = ei.id_episode
                  LEFT JOIN clinical_service cs
                    ON cs.id_clinical_service = epis.id_cs_requested
                 WHERE ei.id_episode = i_episode;
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
                                              'CREATE_CONTEXT_WPS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END create_context_wps;

    /********************************************************************************************
    *
    * Contrary to all previous verions of the WR demo, this function aims to use only patients that are loaded 
    * on the grids. This way we make sure that WR will not display patients that have nothing to do with those 
    * visible in the grid.
    *
    * @param i_lang      ID language
    * @param i_prof      Registar's ID 
    * @param o_error     Error output
    *
    * @return                         true or false 
    *
    * @author                          Ricardo Nuno Almeida
    * @version                         0.1
    * @since                           2009/02/20
    *
    **********************************************************************************************/
    FUNCTION create_context_wps
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_error    := 'GET DATES';
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof,
                                                       nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, NULL, NULL),
                                                           current_timestamp));
        l_dt_end   := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
    
        g_error := 'INSERT PATIENT';
        INSERT INTO wl_patient_sonho
            (patient_id, clin_prof_id, consult_id, prof_id, id_institution, id_episode, dt_consult_tstz)
        
            SELECT id_patient, id_clin_prof, id_cs_requested, id_prof, institution, id_episode, dt_cons
              FROM (SELECT ppp.id_patient,
                           ppp.id_clin_prof,
                           ppp.id_cs_requested,
                           ppp.id_prof,
                           ppp.institution,
                           ppp.id_episode,
                           ppp.dt_cons
                      FROM (SELECT pats.id_patient,
                                   pats.id_clin_prof,
                                   pats.id_clinical_service id_cs_requested,
                                   pats.id_prof,
                                   pats.institution,
                                   pats.id_episode,
                                   pats.dt_cons,
                                   (current_timestamp - nvl((SELECT MAX(wl.dt_begin_tstz)
                                                              FROM wl_waiting_line wl
                                                             WHERE wl.id_patient = pats.id_patient),
                                                            current_timestamp)) maxtime
                              FROM (
                                    
                                    SELECT sg.id_patient,
                                            cs.id_clinical_service,
                                            nvl(ei.id_professional, ei.sch_prof_outp_id_prof) id_clin_prof,
                                            i_prof.id id_prof,
                                            i_prof.institution institution,
                                            epis.id_episode,
                                            current_timestamp dt_cons
                                      FROM schedule_outp sp,
                                            sch_group sg,
                                            patient pat,
                                            clinical_service cs,
                                            professional p,
                                            epis_info ei,
                                            episode epis,
                                            prof_dep_clin_serv pdcs,
                                            sys_domain sd,
                                            professional p1,
                                            (SELECT sd2.val, sd2.img_name
                                               FROM sys_domain sd2
                                              WHERE sd2.code_domain = 'SCHEDULE_OUTP.FLG_STATE'
                                                AND sd2.domain_owner = pk_sysdomain.k_default_schema
                                                AND sd2.id_language = i_lang) sd2,
                                            institution i
                                    -- JS, 2007-09-11 - Timezone
                                     WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                       AND sp.flg_state NOT IN (g_flg_state_m, g_flg_state_d) --SS 2006/08/09: os pacientes com alta apareciam repetidos pq tb eram "apanhados" neste SELECT
                                       AND sp.id_software = i_prof.software
                                       AND sp.id_epis_type NOT IN (g_flg_epis_type_nurse_care,
                                                                   g_flg_epis_type_nurse_outp,
                                                                   g_flg_epis_type_nurse_pp)
                                       AND nvl(ei.flg_sch_status, g_flg_status_a) != g_flg_status_c
                                       AND ei.id_instit_requested = i_prof.institution
                                       AND i.id_institution = ei.id_instit_requested
                                       AND pdcs.id_dep_clin_serv = ei.id_dcs_requested
                                       AND pdcs.id_professional = i_prof.id
                                       AND pdcs.flg_status = g_flg_select_s
                                       AND p.id_professional(+) = ei.sch_prof_outp_id_prof
                                       AND sg.id_schedule = sp.id_schedule
                                       AND pat.id_patient = sg.id_patient
                                       AND cs.id_clinical_service = epis.id_cs_requested
                                       AND ei.id_schedule(+) = sp.id_schedule
                                       AND p1.id_professional(+) = ei.id_professional -- CRS 2006/07/11
                                       AND epis.id_episode(+) = ei.id_episode
                                       AND epis.flg_status(+) != g_flg_status_c
                                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
                                       AND epis.flg_ehr(+) != g_flg_ehr
                                          -- CRS 2006/04/19 alterações devido a performance
                                       AND (nvl(ei.id_schedule, 0) = 0 -- agendamentos s/ episódio = ñ efectivados
                                           -- JS, 2007-09-11 - Timezone
                                           OR (epis.dt_end_tstz IS NULL AND ei.dt_first_obs_tstz IS NULL AND
                                           ei.dt_first_nurse_obs_tstz IS NULL)) -- agendamentos efectivados s/ atendimento clínico
                                       AND sd.code_domain(+) = 'SCHEDULE_OUTP.FLG_SCHED'
                                       AND sd.domain_owner(+) = pk_sysdomain.k_default_schema
                                       AND sd.val(+) = sp.flg_sched
                                       AND sd.id_language(+) = i_lang
                                          --             AND sd2.code_domain(+) = g_schdl_outp_state_domain -- LG 2006-09-19 INCLUDE FLG_STATE ICON
                                       AND sd2.val(+) = sp.flg_state
                                    --              AND sd2.id_language(+) = i_lang
                                    UNION
                                    SELECT sg.id_patient,
                                            cs.id_clinical_service,
                                            nvl(ei.id_professional, ei.sch_prof_outp_id_prof) id_clin_prof,
                                            i_prof.id id_prof,
                                            i_prof.institution institution,
                                            epis.id_episode,
                                            current_timestamp dt_cons
                                      FROM schedule_outp      sp,
                                            sch_group          sg,
                                            patient            pat,
                                            clinical_service   cs,
                                            professional       p,
                                            epis_info          ei,
                                            episode            epis,
                                            discharge          d,
                                            disch_reas_dest    drt,
                                            dep_clin_serv      dcs1,
                                            discharge_reason   drn,
                                            clinical_service   cs1,
                                            prof_dep_clin_serv pdcs,
                                            institution        i,
                                            sys_domain         sd,
                                            professional       p1
                                    -- JS, 2007-09-11 - Timezone
                                     WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                       AND sp.id_software = i_prof.software
                                       AND sp.id_epis_type NOT IN (g_flg_epis_type_nurse_care,
                                                                   g_flg_epis_type_nurse_outp,
                                                                   g_flg_epis_type_nurse_pp)
                                       AND ei.flg_sch_status != g_flg_status_c
                                       AND ei.id_schedule = sp.id_schedule
                                       AND ei.id_instit_requested = i_prof.institution
                                       AND pdcs.id_dep_clin_serv = ei.id_dcs_requested
                                       AND pdcs.id_professional = i_prof.id
                                       AND pdcs.flg_status = g_flg_select_s
                                       AND p.id_professional(+) = ei.sch_prof_outp_id_prof
                                       AND sg.id_schedule = sp.id_schedule
                                       AND pat.id_patient = sg.id_patient
                                       AND cs.id_clinical_service = epis.id_cs_requested
                                       AND p1.id_professional(+) = ei.id_professional -- CRS 2006/07/11
                                       AND epis.id_episode = ei.id_episode
                                       AND epis.flg_status != g_flg_status_c
                                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
                                       AND epis.flg_ehr != g_flg_ehr
                                       AND d.id_episode = ei.id_episode -- episódios c/ alta
                                          -- JS, 2007-09-11 - Timezone
                                       AND d.flg_status NOT IN
                                           (pk_discharge_core.g_disch_status_cancel,
                                            pk_discharge_core.g_disch_status_reopen)
                                       AND pk_discharge_core.check_admin_discharge(i_lang, i_prof, NULL, d.flg_status_adm) =
                                           pk_alert_constant.g_no -- s/ alta administrativa
                                       AND drt.id_disch_reas_dest = d.id_disch_reas_dest
                                       AND dcs1.id_dep_clin_serv(+) = drt.id_dep_clin_serv -- alta para dep. dentro da instituição
                                       AND cs1.id_clinical_service(+) = dcs1.id_clinical_service
                                       AND drn.id_discharge_reason(+) = drt.id_discharge_reason
                                       AND i.id_institution(+) = drt.id_institution
                                       AND sd.code_domain(+) = 'SCHEDULE_OUTP.FLG_SCHED'
                                       AND sd.domain_owner(+) = pk_sysdomain.k_default_schema
                                       AND sd.val(+) = sp.flg_sched
                                       AND sd.id_language(+) = i_lang
                                    
                                    ) pats
                             ORDER BY maxtime DESC) ppp
                      LEFT JOIN wl_patient_sonho wps
                        ON wps.patient_id = ppp.id_patient
                      LEFT JOIN wl_patient_sonho wpse
                        ON wpse.id_episode = ppp.id_episode
                     WHERE wps.patient_id IS NULL
                       AND wpse.patient_id IS NULL
                     ORDER BY ppp.maxtime DESC)
             WHERE rownum = 1;
    
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
                                              'CREATE_CONTEXT_WPS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END create_context_wps;

    -- ##########################################################################################

    -- **********************************************************************

    -- ##########################################################################################

    -- ##########################################################################################

    FUNCTION create_wl_waiting_line
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_mach IN wl_machine.id_wl_machine%TYPE,
        i_queues  IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error             VARCHAR2(4000);
        l_wwl               wl_waiting_line%ROWTYPE;
        l_num_waiting_lines NUMBER;
        l_queue             wl_queue%ROWTYPE;
        l_flg_wl_status     wl_waiting_line.flg_wl_status%TYPE;
    BEGIN
        l_num_waiting_lines := 5;
    
        l_error := 'FOR EACH QUEUE';
        FOR i IN i_queues.first .. i_queues.last
        LOOP
        
            l_error := 'GET WL_QUEUE';
            SELECT *
              INTO l_queue
              FROM wl_queue
             WHERE id_wl_queue = i_queues(i);
        
            FOR j IN 1 .. l_num_waiting_lines
            LOOP
            
                l_error := 'GET ID_WL_WAITING_LINE';
                SELECT seq_wl_waiting_line.nextval
                  INTO l_wwl.id_wl_waiting_line
                  FROM dual;
            
                l_wwl.dt_begin_tstz := current_timestamp;
                l_wwl.char_queue    := l_queue.char_queue;
                l_wwl.number_queue  := l_queue.num_queue + j;
                l_wwl.flg_wl_status := l_flg_wl_status;
                l_wwl.id_wl_queue   := l_queue.id_wl_queue;
            
                l_error := 'INSERT WL_WAITING_LINE';
                INSERT INTO wl_waiting_line
                VALUES l_wwl;
            
            END LOOP;
        
            UPDATE wl_queue
               SET num_queue = num_queue + l_num_waiting_lines
             WHERE id_wl_queue = l_queue.id_wl_queue;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- JC 09/03/2009 ALERT-17261
            DECLARE
                l_error_desc VARCHAR2(4000) := pk_message.get_message(i_lang, g_error_msg_code) || chr(10) || l_error;
            
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  l_error_desc,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'CREATE_WL_WAITING_LINE',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
        
    END create_wl_waiting_line;

-- **********************************************************************
-- ****************************  CONSTRUCTOR  ***************************
-- **********************************************************************
BEGIN
    -- JC 09/03/2009 ALERT-17261
    pk_alertlog.who_am_i(g_package_owner, g_package_name);

    xpl                        := '''';
    xsp                        := chr(32);
    pk_e_status                := 'E';
    pk_a_status                := 'A';
    pk_x_status                := 'X';
    pk_adm_mode                := 1;
    pk_med_mode                := 2;
    pk_nur_mode                := 3;
    pk_wl_id_sonho             := 'WL_ID_SONHO';
    pk_wl_lang                 := 'WL_LANG';
    pk_nur_flg_type            := 'N';
    pk_nurse_queue             := 'WL_ID_NURSE_QUEUE';
    pk_id_department           := 'WL_ID_DEPARTMENT';
    g_flg_ehr                  := 'E';
    pk_id_software             := pk_wlcore.get_id_software();
    g_flg_epis_type_nurse_care := 14;
    g_flg_epis_type_nurse_outp := 16;
    g_flg_epis_type_nurse_pp   := 17;
    g_flg_status_c             := 'C';
    g_flg_status_a             := 'A';
    g_flg_select_s             := 'S';
    g_flg_state_d              := 'D';
    g_flg_state_m              := 'M';
    g_yes                      := 'Y';

    g_flg_type_queue_doctor   := 'D';
    g_flg_type_queue_nurse    := 'N';
    g_flg_type_queue_registar := 'A';
    g_flg_type_queue_nur_cons := 'C';

    g_rownum         := 2;
    g_error_msg_code := 'COMMON_M001';
    g_counter        := 0;

--L_RET:=PK_SYSCONFIG.GET_CONFIG( I_CODE_CF => PK_WL_LANG, O_MSG_CF => G_LANGUAGE_NUM);
END;
/
